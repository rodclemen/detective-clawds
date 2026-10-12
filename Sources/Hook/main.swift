import Foundation

// Hook entry point for Claude Code, Codex, Qwen Code, Gemini CLI and Copilot CLI. Reads the hook JSON from stdin, records it, prints nothing,
// and always exits 0 so it can never block or disturb either.

let input = FileHandle.standardInput.readDataToEndOfFile()
// `--assistant codex|qwen|gemini|copilot` for the other AIs (Claude Code's hooks pass nothing), plus
// `--event <name>` where the payload doesn't name the event or uses that AI's own names.
let args = CommandLine.arguments
func value(_ flag: String) -> String? { args.firstIndex(of: flag).flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil } }
let assistant = value("--assistant") ?? "claude"
if let json = (try? JSONSerialization.jsonObject(with: input)) as? [String: Any] {
    StatusStore.apply(event: StatusStore.normalize(json, assistant: assistant, event: value("--event")), assistant: assistant)
}
exit(0)
