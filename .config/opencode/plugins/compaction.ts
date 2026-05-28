import type { PluginInput, Hooks } from "@opencode-ai/plugin"

export default async function compactionPlugin(input: PluginInput): Promise<Hooks> {
  return {
    "experimental.session.compacting": async (hookInput, output) => {
      // Hybrid approach: Codex's fresh "handoff summary" framing + opencode's
      // previous-summary context preservation.
      //
      // Why not fully fresh: opencode hides old compaction pairs from the
      // compaction LLM's conversation history. Without injecting the previous
      // summary, context from the middle of the conversation (between head and
      // tail splits) is lost entirely.
      //
      // Why not anchor ("update the previous summary"): anchoring causes drift —
      // stale details accumulate across compactions because the LLM must diff
      // against the old summary instead of grounding in the actual conversation.
      //
      // Solution: include the previous summary as REFERENCE CONTEXT (not as an
      // anchor to update), and ask the LLM to create a fresh summary from
      // scratch. This preserves knowledge without inheriting errors.

      const previousSummary = await getPreviousSummary(input, hookInput.sessionID)

      const sections = [
        `You are performing a CONTEXT CHECKPOINT COMPACTION. Create a handoff summary for another LLM that will resume this task.

Include:
- Current progress and key decisions made
- Important context, constraints, or user preferences
- What remains to be done (clear next steps)
- Any critical data, file paths, error strings, commands, or references needed to continue

Be concise, structured, and focused on helping the next LLM seamlessly continue the work.
Do not mention the summary process or that context was compacted.`,
      ]

      if (previousSummary) {
        sections.push(
          `For reference, here is the summary from the previous compaction. Use it as background context — incorporate details that are still relevant, discard anything stale, but do NOT treat it as a template to update. Your summary should be grounded in the conversation history above.

<previous-summary>
${previousSummary}
</previous-summary>`,
        )
      }

      output.prompt = [...sections, ...output.context].join("\n\n")
    },
  }
}

async function getPreviousSummary(input: PluginInput, sessionID: string): Promise<string | undefined> {
  const result = await input.client.session.messages({ path: { id: sessionID } })
  const messages = result.data
  if (!messages) return undefined

  // Messages are returned in chronological order (oldest first).
  // Iterate from the end to find the most recent summary.
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i]
    if (msg.info.role !== "assistant" || !msg.info.summary) continue
    const textPart = msg.parts.find((p) => p.type === "text")
    if (textPart?.type === "text") return textPart.text
  }
  return undefined
}
