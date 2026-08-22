import { FileFinder, type FileFinderApi, type GrepCursor, type GrepMatch, type GrepMode } from "@ff-labs/fff-bun"
import { Plugin } from "@opencode-ai/plugin"
import { execFile } from "node:child_process"
import { realpath, stat } from "node:fs/promises"
import { homedir } from "node:os"
import path from "node:path"
import { promisify } from "node:util"

const execFileAsync = promisify(execFile)

const RESULT_LIMIT = 100
const GREP_TIMEOUT_MS = 1_500
const INDEX_TIMEOUT_MS = 10_000
const AUXILIARY_LIMIT = 3
const AUXILIARY_IDLE_MS = 5 * 60_000
const GIT_TIMEOUT_MS = 5_000

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

type GlobArguments = {
  pattern: string
  path?: string
}

type GrepArguments = {
  pattern: string
  additionalPatterns?: string[]
  mode?: string
  path?: string
  include?: string
}

function posix(value: string) {
  return value.replaceAll(path.sep, "/")
}

function contains(root: string, target: string) {
  const relative = path.relative(root, target)
  return relative === "" || (!relative.startsWith(`..${path.sep}`) && relative !== ".." && !path.isAbsolute(relative))
}

function displayPath(target: Target) {
  return target.constraint ? path.join(target.root, target.constraint) : target.root
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
  // FFF indexes hidden files/dirs only when git2 can discover a git repo above
  // the root; non-git roots skip hidden entries hard-coded (no option to change).
  // node_modules and similar are excluded via .gitignore (git roots) or FFF's
  // built-in ignore list (non-git roots).
  const result = FileFinder.create({
    basePath: root,
    aiMode: true,
    enableHomeDirScanning: root === homedir(),
  })
  if (!result.ok) throw new Error(`Failed to initialize FFF for ${root}: ${result.error}`)
  return result.value
}

async function waitUntilReady(finder: Finder, root: string) {
  const ready = await finder.waitForScan(INDEX_TIMEOUT_MS)
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

async function gitRoot(directory: string) {
  try {
    const { stdout } = await execFileAsync("git", ["rev-parse", "--show-toplevel"], {
      cwd: directory,
      timeout: GIT_TIMEOUT_MS,
    })
    const root = stdout.trim()
    return root ? await realpath(root) : directory
  } catch {
    return directory
  }
}

export default Plugin.define({
  id: "divaltor.fff-tools",
  setup: async (ctx) => {
    if (!FileFinder.isAvailable()) throw new Error("The native FFF library is unavailable")

    const finders = new Map<string, FinderEntry>()
    const scopes = new Map<string, Promise<{ directory: string; worktree: string }>>()

    function destroyEntry(entry: FinderEntry) {
      if (entry.timer) clearTimeout(entry.timer)
      entry.finder.destroy()
      finders.delete(entry.root)
    }

    function evictOne() {
      const idle = [...finders.values()]
        .filter((entry) => entry.active === 0)
        .sort((a, b) => a.lastUsed - b.lastUsed)[0]
      if (idle) destroyEntry(idle)
      return Boolean(idle)
    }

    function acquire(root: string) {
      if (root === homedir() || root === path.parse(root).root) {
        throw new Error(`FFF cannot index the home directory or filesystem root; use a smaller directory: ${root}`)
      }
      let entry = finders.get(root)
      if (!entry) {
        const retained = finders.size < AUXILIARY_LIMIT || evictOne()
        entry = { root, finder: makeFinder(root), active: 0, lastUsed: Date.now(), retained }
        finders.set(root, entry)
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

    async function scopeFor(sessionID: string) {
      const pending = scopes.get(sessionID)
      if (pending) return pending
      const promise = (async () => {
        const session = await ctx.session.get({ sessionID })
        const directory = await realpath(session.location.directory)
        const worktree = await gitRoot(directory)
        return { directory, worktree }
      })()
      // Cache the scope for the session lifetime, but evict rejections: a
      // single transient session-store failure must not poison every later
      // glob/grep call for this session.
      promise.catch(() => scopes.delete(sessionID))
      scopes.set(sessionID, promise)
      return promise
    }

    async function resolveTarget(rawPath: string | undefined, directory: string, worktree: string) {
      const requested = path.resolve(directory, rawPath ?? ".")
      const info = await stat(requested).catch(() => undefined)
      if (!info) throw new Error(`Search path does not exist: ${requested}`)
      if (!info.isDirectory() && !info.isFile()) throw new Error(`Search path must be a file or directory: ${requested}`)

      const target = await realpath(requested)
      if (!contains(directory, target) && !contains(worktree, target)) {
        throw new Error(
          `Search path is outside the workspace: ${target}. V2 plugin tools cannot request external directory access; move the session directory or use a path inside the project.`,
        )
      }
      if (target === homedir() || target === path.parse(target).root) {
        throw new Error(`FFF cannot index the home directory or filesystem root; use a smaller directory: ${target}`)
      }

      if (info.isDirectory()) return { root: target, kind: "directory" } satisfies Target
      return { root: path.dirname(target), constraint: path.basename(target), kind: "file" } satisfies Target
    }

    async function withFinder<T>(target: Target, run: (finder: Finder) => T) {
      const lease = acquire(target.root)
      try {
        await waitUntilReady(lease.finder, target.root)
        return run(lease.finder)
      } finally {
        lease.release()
      }
    }

    await ctx.tool.transform((tools) => {
      tools.add({
        name: "glob",
        options: { codemode: false, permission: "glob" },
        description:
          "Use this tool to find workspace files by name or path when the exact path is unknown. Give pattern a glob such as '**/*.ts' or '**/config.*'; use path to limit the search to a directory. Prefer this to shell find or ls for file discovery. Returns absolute paths ordered by relevance.",
        input: {
          type: "object",
          properties: {
            pattern: {
              type: "string",
              minLength: 1,
              description: "Glob pattern for file paths, for example '**/*.ts' or '**/package.json'",
            },
            path: {
              type: "string",
              description: "Directory to search; defaults to the current workspace directory",
            },
          },
          required: ["pattern"],
          additionalProperties: false,
        },
        execute: async (raw, context) => {
          const args = raw as GlobArguments
          if (typeof args.pattern !== "string" || args.pattern.length === 0) {
            throw new Error("A glob pattern is required")
          }
          const scope = await scopeFor(context.sessionID)
          const target = await resolveTarget(args.path, scope.directory, scope.worktree)
          if (target.kind !== "directory") throw new Error(`Glob path must be a directory: ${args.path}`)
          await context.progress({ title: displayPath(target) })

          const result = await withFinder(target, (finder) =>
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
            content: output.join("\n"),
            metadata: { count: items.length, more: truncated },
          }
        },
      })

      tools.add({
        name: "grep",
        options: { codemode: false, permission: "grep" },
        description:
          "Use this tool to search workspace file contents for symbols, imports, error text, or other code. Prefer this to shell grep or rg. Use regex mode for regular expressions, plain for exact literal text, fuzzy for approximate text, and multi for literal OR searches with additionalPatterns. Narrow with path or include when possible.",
        input: {
          type: "object",
          properties: {
            pattern: {
              type: "string",
              minLength: 1,
              description: "Text or regular expression to find in file contents",
            },
            additionalPatterns: {
              type: "array",
              items: { type: "string", minLength: 1 },
              description: "Additional literal alternatives; set mode to 'multi' when using this field",
            },
            mode: {
              type: "string",
              enum: ["regex", "plain", "fuzzy", "multi"],
              description: "Search interpretation: regex, exact literal plain text, fuzzy text, or literal multi-pattern OR",
            },
            path: {
              type: "string",
              description: "File or directory to search; defaults to the current workspace directory",
            },
            include: {
              type: "string",
              description: 'File glob filter, for example "*.ts" or "*.{ts,tsx}"',
            },
          },
          required: ["pattern"],
          additionalProperties: false,
        },
        execute: async (raw, context) => {
          const args = raw as GrepArguments
          if (typeof args.pattern !== "string" || args.pattern.length === 0) {
            throw new Error("A search pattern is required")
          }
          const patterns = [args.pattern, ...(args.additionalPatterns ?? [])]
          const mode = args.mode ?? "regex"
          if (mode !== "regex" && mode !== "plain" && mode !== "fuzzy" && mode !== "multi") {
            throw new Error(`Unsupported search mode: ${mode}`)
          }
          if (mode !== "multi" && (args.additionalPatterns?.length ?? 0) > 0) {
            throw new Error("additionalPatterns can only be used in multi mode")
          }

          const scope = await scopeFor(context.sessionID)
          const target = await resolveTarget(args.path, scope.directory, scope.worktree)
          await context.progress({ title: displayPath(target) })
          const pathConstraint = target.kind === "file" ? normalizeFileConstraint(target.constraint) : undefined
          const includeConstraint = normalizeFileConstraint(args.include)
          const constraints = [pathConstraint, includeConstraint].filter((value): value is string => Boolean(value))

          const result = await withFinder(target, (finder) => {
            const runPage = (cursor: GrepCursor | null) => {
              // One match past RESULT_LIMIT is enough to prove truncation for
              // any target; fff ignores pageSize when capping a single file's
              // lines, so an explicit per-file cap bounds allocation.
              const page = {
                cursor,
                maxMatchesPerFile: RESULT_LIMIT + 1,
                pageSize: RESULT_LIMIT,
                timeBudgetMs: GREP_TIMEOUT_MS,
              }
              if (mode === "multi") {
                return finder.multiGrep({
                  patterns,
                  constraints: constraints.join(" ") || undefined,
                  ...page,
                })
              }
              return finder.grep([...constraints, args.pattern].join(" "), {
                mode: mode as GrepMode,
                ...page,
              })
            }

            const first = runPage(null)
            if (!first.ok || target.kind !== "file") return first

            // A file target searches from its parent directory with a
            // "**/<basename>" constraint, which also matches files of the same
            // name deeper in the tree (fff has no exact-file constraint form).
            // Any returned target matches are complete up to the per-file
            // sentinel, so only paginate while the target has not appeared.
            // A no-match result requires exhausting same-named siblings.
            const items = first.value.items.filter((match) => match.relativePath === target.constraint)
            let searched = first.value.totalFilesSearched
            let cursor = first.value.nextCursor
            while (cursor && items.length === 0) {
              const next = runPage(cursor)
              if (!next.ok) return next
              items.push(...next.value.items.filter((match) => match.relativePath === target.constraint))
              searched += next.value.totalFilesSearched
              cursor = next.value.nextCursor
            }
            // filteredFileCount is a whole-query count repeated on every page;
            // totalMatched must equal items.length per the GrepResult contract.
            return {
              ok: true as const,
              value: {
                ...first.value,
                items,
                totalMatched: items.length,
                totalFilesSearched: searched,
                filteredFileCount: first.value.filteredFileCount,
                // The native cursor addresses same-named siblings, not more
                // matches from the requested file. The sentinel carries the
                // only relevant truncation signal for an exact-file target.
                nextCursor: null,
              },
            }
          })
          if (!result.ok) throw new Error(result.error)
          if (result.value.regexFallbackError && mode === "regex") {
            throw new Error(`Invalid regular expression: ${result.value.regexFallbackError}`)
          }

          const items = result.value.items.slice(0, RESULT_LIMIT)
          const more = result.value.items.length > items.length || result.value.nextCursor !== null
          return {
            content: formatMatches(target.root, items, more),
            metadata: {
              matches: items.length,
              mode,
              more,
              totalFilesSearched: result.value.totalFilesSearched,
              filteredFileCount: result.value.filteredFileCount,
            },
          }
        },
      })
    })

    return async () => {
      for (const entry of finders.values()) destroyEntry(entry)
      finders.clear()
    }
  },
})
