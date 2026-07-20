import { FileFinder, type FileFinderApi, type GrepMatch } from "@ff-labs/fff-bun"
import { tool, type Plugin, type ToolContext } from "@opencode-ai/plugin"
import { realpath, stat } from "node:fs/promises"
import { homedir } from "node:os"
import path from "node:path"

const RESULT_LIMIT = 100
const GREP_TIMEOUT_MS = 1_500
const INDEX_TIMEOUT_MS = 5_000
const AUXILIARY_LIMIT = 3
const AUXILIARY_IDLE_MS = 5 * 60_000

type Finder = FileFinderApi
type FinderEntry = {
  root: string
  finder: Finder
  active: number
  lastUsed: number
  retained: boolean
  timer?: ReturnType<typeof setTimeout>
}

type Target = {
  root: string
  constraint?: string
  kind: "file" | "directory"
}

function posix(value: string) {
  return value.replaceAll(path.sep, "/")
}

function contains(root: string, target: string) {
  const relative = path.relative(root, target)
  return relative === "" || (!relative.startsWith(`..${path.sep}`) && relative !== ".." && !path.isAbsolute(relative))
}

function abortError(signal: AbortSignal) {
  return signal.reason instanceof Error ? signal.reason : new Error("FFF search aborted")
}

function assertNotAborted(signal: AbortSignal) {
  if (signal.aborted) throw abortError(signal)
}

function normalizeFileConstraint(value: string | undefined) {
  if (!value) return
  const normalized = posix(value.trim())
  if (!normalized) return
  if (/\s/.test(normalized)) throw new Error(`FFF file constraints cannot contain whitespace: ${value}`)
  if (normalized.includes("/") || normalized.includes("{") || normalized.startsWith("*.")) return normalized
  return `**/${normalized}`
}

function makeFinder(root: string) {
  if (root === path.parse(root).root) throw new Error("FFF will not index the filesystem root")
  const result = FileFinder.create({
    basePath: root,
    aiMode: true,
    enableHomeDirScanning: root === homedir(),
  })
  if (!result.ok) throw new Error(`Failed to initialize FFF for ${root}: ${result.error}`)
  return result.value
}

async function waitUntilReady(finder: Finder, root: string, signal: AbortSignal) {
  assertNotAborted(signal)
  const ready = await finder.waitForScan(INDEX_TIMEOUT_MS)
  assertNotAborted(signal)
  if (!ready.ok) throw new Error(`FFF failed to index ${root}: ${ready.error}`)
  if (!ready.value) throw new Error(`FFF did not finish indexing ${root} within ${INDEX_TIMEOUT_MS}ms`)
}

function formatMatches(root: string, items: GrepMatch[], more: boolean) {
  if (items.length === 0) return "No files found"

  const output = [`Found ${items.length} matches${more ? " (more files available)" : ""}`]
  let current = ""
  for (const match of items) {
    const file = path.resolve(root, match.relativePath)
    if (file !== current) {
      if (current) output.push("")
      current = file
      output.push(`${file}:`)
    }
    const text = match.lineContent.length > 2_000 ? `${match.lineContent.slice(0, 2_000)}...` : match.lineContent
    output.push(`  Line ${match.lineNumber}: ${text}`)
  }
  if (more) output.push("", "(Results truncated. Use a more specific path, include pattern, or search expression.)")
  return output.join("\n")
}

export default (async ({ directory, worktree }) => {
  if (!FileFinder.isAvailable()) throw new Error("The native FFF library is unavailable")

  const canonicalDirectory = await realpath(directory)
  const canonicalWorktree = worktree === path.parse(worktree).root ? canonicalDirectory : await realpath(worktree)
  const workspaceRoot = canonicalDirectory
  const workspaceFinder = makeFinder(workspaceRoot)
  const initialScan = await workspaceFinder.waitForScan(INDEX_TIMEOUT_MS)
  if (!initialScan.ok || !initialScan.value) {
    workspaceFinder.destroy()
    throw new Error(
      initialScan.ok
        ? `FFF did not finish indexing ${workspaceRoot} within ${INDEX_TIMEOUT_MS}ms`
        : `FFF failed to index ${workspaceRoot}: ${initialScan.error}`,
    )
  }
  const auxiliary = new Map<string, FinderEntry>()

  function destroyEntry(entry: FinderEntry) {
    if (entry.timer) clearTimeout(entry.timer)
    entry.finder.destroy()
    auxiliary.delete(entry.root)
  }

  function evictOne() {
    const idle = [...auxiliary.values()]
      .filter((entry) => entry.active === 0)
      .sort((a, b) => a.lastUsed - b.lastUsed)[0]
    if (idle) destroyEntry(idle)
    return Boolean(idle)
  }

  function acquire(root: string) {
    if (root === workspaceRoot) return { finder: workspaceFinder, release() { } }

    let entry = auxiliary.get(root)
    if (!entry) {
      const retained = auxiliary.size < AUXILIARY_LIMIT || evictOne()
      entry = { root, finder: makeFinder(root), active: 0, lastUsed: Date.now(), retained }
      auxiliary.set(root, entry)
    }

    if (entry.timer) clearTimeout(entry.timer)
    entry.active++
    entry.lastUsed = Date.now()
    return {
      finder: entry.finder,
      release() {
        entry!.active--
        entry!.lastUsed = Date.now()
        if (!entry!.retained) {
          if (entry!.active === 0) destroyEntry(entry!)
          return
        }
        entry!.timer = setTimeout(() => {
          if (entry!.active === 0 && Date.now() - entry!.lastUsed >= AUXILIARY_IDLE_MS) destroyEntry(entry!)
        }, AUXILIARY_IDLE_MS)
      },
    }
  }

  async function resolveTarget(rawPath: string | undefined, context: ToolContext) {
    const requested = path.resolve(context.directory, rawPath ?? ".")
    const info = await stat(requested).catch(() => undefined)
    if (!info) throw new Error(`Search path does not exist: ${requested}`)
    if (!info.isDirectory() && !info.isFile()) throw new Error(`Search path must be a file or directory: ${requested}`)

    const target = await realpath(requested)
    const inDirectory = contains(canonicalDirectory, target)
    const inWorktree = worktree !== path.parse(worktree).root && contains(canonicalWorktree, target)
    if (!inDirectory && !inWorktree) {
      const parentDir = info.isDirectory() ? target : path.dirname(target)
      const pattern = posix(path.join(parentDir, "*"))
      await context.ask({
        permission: "external_directory",
        patterns: [pattern],
        always: [pattern],
        metadata: { filepath: target, parentDir },
      })
    }

    if (info.isDirectory()) return { root: target, kind: "directory" } satisfies Target
    return { root: path.dirname(target), constraint: path.basename(target), kind: "file" } satisfies Target
  }

  async function withFinder<T>(target: Target, signal: AbortSignal, run: (finder: Finder) => T) {
    const lease = acquire(target.root)
    try {
      await waitUntilReady(lease.finder, target.root, signal)
      assertNotAborted(signal)
      const result = run(lease.finder)
      assertNotAborted(signal)
      return result
    } finally {
      lease.release()
    }
  }

  return {
    dispose: async () => {
      for (const entry of auxiliary.values()) destroyEntry(entry)
      workspaceFinder.destroy()
    },
    tool: {
      glob: tool({
        description:
          "Find files by glob pattern. Returns absolute paths ordered by FFF. Use path to narrow the search to a directory.",
        args: {
          pattern: tool.schema.string().min(1).describe("The glob pattern to match files against"),
          path: tool.schema.string().optional().describe("Directory to search, relative to the current directory by default"),
        },
        async execute(args, context) {
          await context.ask({
            permission: "glob",
            patterns: [args.pattern],
            always: ["*"],
            metadata: args,
          })

          const target = await resolveTarget(args.path, context)
          if (target.kind !== "directory") throw new Error(`Glob path must be a directory: ${args.path}`)
          const result = await withFinder(target, context.abort, (finder) =>
            finder.glob(args.pattern, { pageIndex: 0, pageSize: RESULT_LIMIT + 1 }),
          )
          if (!result.ok) throw new Error(result.error)

          const items = result.value.items.slice(0, RESULT_LIMIT)
          const truncated = result.value.totalMatched > items.length
          const output = items.map((item) => path.resolve(target.root, item.relativePath))
          if (output.length === 0) output.push("No files found")
          if (truncated) {
            output.push("", `(Results are truncated: showing first ${RESULT_LIMIT} results. Use a more specific path or pattern.)`)
          }
          return {
            output: output.join("\n"),
            metadata: { count: items.length, more: truncated },
          }
        },
      }),
      grep: tool({
        description:
          "Search file contents with FFF. Regex mode is the default; plain and fuzzy search one pattern, while multi searches the primary pattern and additionalPatterns with literal OR semantics.",
        args: {
          pattern: tool.schema.string().min(1).describe("Primary search pattern; also shown in the native grep tool card"),
          additionalPatterns: tool.schema
            .array(tool.schema.string().min(1))
            .optional()
            .describe("Additional literal OR patterns used only in multi mode"),
          mode: tool.schema
            .enum(["regex", "plain", "fuzzy", "multi"])
            .default("regex")
            .describe("FFF search mode; multi uses literal OR matching"),
          path: tool.schema.string().optional().describe("File or directory to search, relative to the current directory by default"),
          include: tool.schema.string().optional().describe('File glob to include, such as "*.ts" or "*.{ts,tsx}"'),
        },
        async execute(args, context) {
          const patterns = [args.pattern, ...(args.additionalPatterns ?? [])]
          if (args.mode !== "multi" && args.additionalPatterns?.length) {
            throw new Error("additionalPatterns can only be used in multi mode")
          }
          await context.ask({
            permission: "grep",
            patterns,
            always: ["*"],
            metadata: args,
          })

          const target = await resolveTarget(args.path, context)
          const pathConstraint = target.kind === "file" ? normalizeFileConstraint(target.constraint) : undefined
          const includeConstraint = normalizeFileConstraint(args.include)
          const constraints = [pathConstraint, includeConstraint].filter((value): value is string => Boolean(value))

          const result = await withFinder(target, context.abort, (finder) => {
            if (args.mode === "multi") {
              return finder.multiGrep({
                patterns,
                constraints: constraints.join(" ") || undefined,
                maxMatchesPerFile: RESULT_LIMIT,
                pageSize: RESULT_LIMIT,
                timeBudgetMs: GREP_TIMEOUT_MS,
              })
            }
            return finder.grep([...constraints, args.pattern].join(" "), {
              mode: args.mode,
              maxMatchesPerFile: RESULT_LIMIT,
              pageSize: RESULT_LIMIT,
              timeBudgetMs: GREP_TIMEOUT_MS,
            })
          })
          if (!result.ok) throw new Error(result.error)
          if (result.value.regexFallbackError && args.mode === "regex") {
            throw new Error(`Invalid regular expression: ${result.value.regexFallbackError}`)
          }

          const items = result.value.items.slice(0, RESULT_LIMIT)
          const more = result.value.items.length > items.length || result.value.nextCursor !== null
          return {
            output: formatMatches(target.root, items, more),
            metadata: {
              matches: items.length,
              mode: args.mode,
              more,
              totalFilesSearched: result.value.totalFilesSearched,
              filteredFileCount: result.value.filteredFileCount,
            },
          }
        },
      }),
    },
  }
}) satisfies Plugin
