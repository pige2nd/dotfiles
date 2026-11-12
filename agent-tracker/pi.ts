import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { join } from "node:path";

export default function (pi: ExtensionAPI) {
  if (!process.env.TMUX || !process.env.TMUX_PANE) return;
  const bridge = join(homedir(), "dotfiles/agent-tracker/bridge.py");
  let summary = "Pi task";
  let result = "Pi: Turn finished";

  async function report(command: string, text = "") {
    await pi.exec("python3", [bridge, "pi", JSON.stringify({ command, summary: text })], { timeout: 2000 });
  }

  pi.on("before_agent_start", async (event) => {
    summary = "Pi: " + event.prompt.replace(/\s+/g, " ").slice(0, 140);
  });
  pi.on("agent_start", async () => {
    result = "Pi: Turn finished";
    await report("start_task", summary);
  });
  pi.on("agent_end", async (event) => {
    const last = [...event.messages].reverse().find((message) => message.role === "assistant");
    if (!last || last.role !== "assistant") return;
    if (last.stopReason === "aborted") result = "interrupted";
    else if (last.stopReason === "error") result = "Pi error: " + (last.errorMessage || "request failed");
    else result = "Pi: " + last.content.filter((block) => block.type === "text")
      .map((block) => block.text).join(" ").slice(0, 140);
  });
  // agent_end can be followed by automatic retries or queued follow-ups.
  pi.on("agent_settled", async (_event, ctx) => {
    if (ctx.isIdle()) await report("finish_task", result);
  });
  pi.on("session_shutdown", async () => {
    await report("delete_task");
  });
}
