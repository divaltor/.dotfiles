import { tool, type Plugin } from "@opencode-ai/plugin"

const EXA_MCP_URL = "https://mcp.exa.ai/mcp"
const REQUEST_TIMEOUT_MS = 30_000

type McpResponse = {
  error?: {
    code?: number
    message?: string
  }
  result?: {
    isError?: boolean
    content?: Array<{
      type?: string
      text?: string
    }>
  }
}

function parsePayload(payload: string): string | undefined {
  const trimmed = payload.trim()
  if (!trimmed.startsWith("{")) return

  const response = JSON.parse(trimmed) as McpResponse
  if (response.error) {
    throw new Error(response.error.message ?? `Exa MCP error ${response.error.code ?? "unknown"}`)
  }

  const output = response.result?.content
    ?.filter((item) => item.type === "text" && item.text)
    .map((item) => item.text)
    .join("\n\n")

  if (response.result?.isError) throw new Error(output || "Exa MCP web fetch failed")
  return output || undefined
}

function parseResponse(body: string): string {
  const direct = parsePayload(body)
  if (direct) return direct

  for (const line of body.split("\n")) {
    if (!line.startsWith("data:")) continue
    const output = parsePayload(line.slice(5))
    if (output) return output
  }

  throw new Error("Exa MCP returned no webpage content")
}

export default (async () => ({
  tool: {
    webfetch: tool({
      description:
        "Read a webpage as clean markdown. Use after websearch when search highlights are insufficient or when full content is needed.",
      args: {
        url: tool.schema.string().url().describe("URL to read"),
        maxCharacters: tool.schema
          .number()
          .int()
          .positive()
          .optional()
          .describe("Maximum characters to extract per page (default: 3000)"),
      },
      async execute(args, context) {
        await context.ask({
          permission: "webfetch",
          patterns: [args.url],
          always: ["*"],
          metadata: args,
        })

        const controller = new AbortController()
        const abort = () => controller.abort(context.abort.reason)
        const timeout = setTimeout(() => controller.abort(new Error("Exa MCP web fetch timed out")), REQUEST_TIMEOUT_MS)
        context.abort.addEventListener("abort", abort, { once: true })

        try {
          const apiKey = process.env.EXA_API_KEY
          const response = await fetch(EXA_MCP_URL, {
            method: "POST",
            headers: {
              Accept: "application/json, text/event-stream",
              "Content-Type": "application/json",
              ...(apiKey ? { "x-api-key": apiKey } : {}),
            },
            body: JSON.stringify({
              jsonrpc: "2.0",
              id: 1,
              method: "tools/call",
              params: {
                name: "web_fetch_exa",
                arguments: {
                  urls: [args.url],
                  maxCharacters: args.maxCharacters,
                },
              },
            }),
            signal: controller.signal,
          })

          if (!response.ok) {
            throw new Error(`Exa MCP request failed: ${response.status} ${response.statusText}`)
          }

          return {
            title: args.url,
            output: parseResponse(await response.text()),
            metadata: { url: args.url },
          }
        } finally {
          clearTimeout(timeout)
          context.abort.removeEventListener("abort", abort)
        }
      },
    }),
  },
})) satisfies Plugin
