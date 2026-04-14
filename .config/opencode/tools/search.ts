import { spawn } from "node:child_process"
import path from "node:path"

import { tool } from "@opencode-ai/plugin"

type CommandResult = {
  exitCode: number | null
  stdout: string
  stderr: string
}

function resolveSearchPath(inputPath: string, directory: string) {
  return path.isAbsolute(inputPath) ? inputPath : path.resolve(directory, inputPath)
}

function runColgrep(args: string[], cwd: string, signal: AbortSignal) {
  return new Promise<CommandResult>((resolve, reject) => {
    const child = spawn("colgrep", args, {
      cwd,
      env: process.env,
      signal,
    })

    let stdout = ""
    let stderr = ""

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString()
    })

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString()
    })

    child.on("error", (error) => {
      reject(error)
    })

    child.on("close", (exitCode) => {
      resolve({ exitCode, stdout, stderr })
    })
  })
}

export default tool({
  description:
    "Search code with colgrep semantic search. Prefer this for natural-language feature discovery, cross-cutting implementation lookups, hybrid regex+semantic queries, and scoped file/path searches. When looking for a specific feature, scope `paths` to the most likely source folders or packages first, and use `excludeDir` to skip `test`, `tests`, `__tests__`, `spec`, `specs`, `docs`, and examples unless the user explicitly wants them.",
  args: {
    query: tool.schema
      .string()
      .min(1)
      .describe("Natural-language search query to send to colgrep. Describe the behavior, feature, or implementation you want to find."),
    paths: tool.schema
      .array(tool.schema.string().min(1))
      .default(["."])
      .describe("Files or directories to search. Relative paths are resolved from the current session directory. Prefer the narrowest likely source folders or packages instead of searching the whole repo."),
    pattern: tool.schema
      .string()
      .optional()
      .describe("Optional text pattern for hybrid regex/text pre-filtering before semantic ranking."),
    include: tool.schema
      .array(tool.schema.string().min(1))
      .optional()
      .describe("Only search files matching these glob patterns."),
    exclude: tool.schema
      .array(tool.schema.string().min(1))
      .optional()
      .describe("Exclude files matching these glob patterns."),
    excludeDir: tool.schema
      .array(tool.schema.string().min(1))
      .optional()
      .describe("Exclude directories by literal name or glob pattern. Use this to skip tests, docs, examples, generated output, or other irrelevant areas when narrowing implementation searches."),
    results: tool.schema
      .number()
      .int()
      .positive()
      .max(50)
      .default(10)
      .describe("Maximum number of results to return."),
    lines: tool.schema
      .number()
      .int()
      .positive()
      .max(50)
      .default(10)
      .describe("Context lines to show around each result. Default: 10"),
    filesOnly: tool.schema
      .boolean()
      .default(false)
      .describe("Return only matching filenames, without result snippets."),
    content: tool.schema
      .boolean()
      .default(false)
      .describe("Show the matched function or class body instead of short context snippets."),
  },
  async execute(args, context) {
    const command = ["--yes", "--results", String(args.results)]

    if (args.lines) command.push("--lines", String(args.lines))
    if (args.pattern) command.push("--pattern", args.pattern)
    if (args.filesOnly) command.push("--files-only")
    if (args.content) command.push("--content")

    for (const include of args.include ?? []) command.push("--include", include)
    for (const exclude of args.exclude ?? []) command.push("--exclude", exclude)
    for (const excludeDir of args.excludeDir ?? []) command.push("--exclude-dir", excludeDir)

    const searchPaths = (args.paths.length ? args.paths : ["."]).map((searchPath) =>
      resolveSearchPath(searchPath, context.directory),
    )

    command.push("--", args.query, ...searchPaths)

    context.metadata({
      title: `Search: ${args.query}`,
      metadata: {
        command: ["colgrep", ...command].join(" "),
        paths: searchPaths,
      },
    })

    let result: CommandResult

    try {
      result = await runColgrep(command, context.directory, context.abort)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      if (message.includes("ENOENT")) {
        return "colgrep is not installed or not available in PATH. Install it first, for example with `brew install lightonai/tap/colgrep`."
      }
      if (context.abort.aborted) {
        return "Search aborted."
      }
      return `Failed to run colgrep: ${message}`
    }

    const stdout = result.stdout.trim()
    const stderr = result.stderr.trim()

    if (!stdout && !stderr) {
      if (result.exitCode === 0) return "No output returned by colgrep."
      return `colgrep exited with code ${result.exitCode ?? "unknown"} and returned no output.`
    }

    if (!stdout) {
      return stderr
    }

    if (!stderr) {
      return stdout
    }

    if (result.exitCode === 0) {
      return `${stderr}\n\n${stdout}`
    }

    return `${stderr}\n\n${stdout}\n\n[colgrep exit code: ${result.exitCode ?? "unknown"}]`
  },
})
