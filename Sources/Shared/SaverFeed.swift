import Foundation

/// What the screen saver shows, published by the running app about once a second (`~/Library/Application Support/
/// Justice League: Clawd Wars/screensaver.json`). The saver runs sandboxed in macOS's screen saver host, so it reads this one file
/// rather than working anything out itself; when the file goes stale, Justice League: Clawd Wars isn't running and the saver says so.
struct SaverFeed: Codable {
    var at: Double                 // when it was written: older than `staleAfter` means the app isn't running
    var location: String           // `Location.rawValue`
    var sessions: [Session]
    var events: [Event]

    struct Session: Codable {
        var id: String
        var cast: Int              // `Cast.id`
        var assistant: String      // "claude", "codex"… (its outline colour)
        var project: String
        var remote: String?        // "GitHub", "Local"…
        var accent: UInt32?        // the project's colour, as in the app
        var mood: String           // "working", "thinking", "waiting", "idle"
        var urgent = false         // waiting and ignored for a while
        var asleep = false         // idle for a long time
        var sitting = false
        var unknown = false        // no hooks: we can't tell what it's doing
        var focused: Bool?         // its terminal is the one in front (the project you're in)
        var since: Double          // when the current mood began
        var activity: String?      // "Edit WindowMode.swift"
        var prompt: String?        // your last prompt
        var agents: [Agent]
    }

    struct Agent: Codable {
        var id: String
        var cast: Int
        var task: String
    }

    struct Event: Codable {
        var at: Double
        var text: String
    }

    static let staleAfter = 5.0

    /// The real home folder: inside the screen saver's sandbox `NSHomeDirectory()` and `$HOME` point at its container.
    static var home: String {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir { return String(cString: dir) }
        return NSHomeDirectory()
    }

    static var url: URL {
        URL(fileURLWithPath: home + "/Library/Application Support/Justice League Clawd Wars/screensaver.json")
    }

    /// The saver as installed for this user, or for everyone.
    static var installedSaver: URL? {
        [home + "/Library/Screen Savers/Justice League Clawd Wars.saver", "/Library/Screen Savers/Justice League Clawd Wars.saver"]
            .map { URL(fileURLWithPath: $0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func load() -> SaverFeed? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SaverFeed.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? FileManager.default.createDirectory(at: Self.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: Self.url, options: .atomic)
    }
}
