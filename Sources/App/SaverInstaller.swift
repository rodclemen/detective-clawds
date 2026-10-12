import AppKit

/// The screen saver carried inside the app (`Contents/Resources/Justice League Clawd Wars.saver`, see build.sh): installing it,
/// keeping the installed copy as new as the app, and removing it.
enum SaverInstaller {
    static var bundled: URL? { Bundle.main.url(forResource: "Justice League: Clawd Wars", withExtension: "saver") }
    private static var userCopy: URL { URL(fileURLWithPath: SaverFeed.home + "/Library/Screen Savers/Justice League Clawd Wars.saver") }

    static var isInstalled: Bool { SaverFeed.installedSaver != nil }

    /// Copies the saver into this user's Screen Savers folder and opens the settings where it's picked. (Opening the
    /// bundle instead lets macOS ask "this user or everyone?", and "everyone" puts it in /Library, where the app can't
    /// keep it up to date and System Settings didn't list it until restarted.)
    static func install() throws {
        guard let bundled else { throw CocoaError(.fileNoSuchFile) }
        try FileManager.default.createDirectory(at: userCopy.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: userCopy.path) { try FileManager.default.removeItem(at: userCopy) }
        try FileManager.default.copyItem(at: bundled, to: userCopy)
        restartHost()
    }

    /// Screen savers are picked in Wallpaper settings on macOS 15 and later, in their own pane before that.
    static func openSettings() {
        let pane = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15
            ? "com.apple.Wallpaper-Settings.extension" : "com.apple.ScreenSaver-Settings.extension"
        if let url = URL(string: "x-apple.systempreferences:" + pane) { NSWorkspace.shared.open(url) }
    }

    /// A copy installed for all users (/Library) can only go with an admin's password.
    static var installedForEveryone: Bool { FileManager.default.fileExists(atPath: "/Library/Screen Savers/Justice League Clawd Wars.saver") }

    static func removeForEveryone() -> Bool {
        let script = "do shell script \"rm -rf '/Library/Screen Savers/Justice League Clawd Wars.saver'\" with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        if error == nil { restartHost() }
        return error == nil
    }

    /// After an app update, the installed copy is replaced with the new one (only a per-user copy: one installed for
    /// everyone needs an admin). The screen saver host keeps old bundles loaded, so it's restarted.
    static func refreshIfOutdated() {
        guard let bundled, FileManager.default.fileExists(atPath: userCopy.path),
              code(of: bundled) != code(of: userCopy) else { return }
        do {
            try FileManager.default.removeItem(at: userCopy)
            try FileManager.default.copyItem(at: bundled, to: userCopy)
            restartHost()
            NSLog("Justice League: Clawd Wars: updated the screen saver to \(version(of: bundled) ?? "?")")
        } catch {
            NSLog("Justice League: Clawd Wars: couldn't update the screen saver: \(error.localizedDescription)")
        }
    }

    /// Removes the saver (asking for an admin's password if it's installed for everyone) and the feed it read.
    static func remove() -> Bool {
        try? FileManager.default.removeItem(at: SaverFeed.url)
        if FileManager.default.fileExists(atPath: userCopy.path) {
            do { try FileManager.default.removeItem(at: userCopy) } catch { return false }
            restartHost()
        }
        return installedForEveryone ? removeForEveryone() : true
    }

    /// The saver's compiled code and the seal over its other files (thumbnail, Info.plist): compared rather than the
    /// version, which every local build of a release shares.
    private static func code(of saver: URL) -> [Data?] {
        ["Contents/MacOS/JusticeLeagueClawdWarsSaver", "Contents/_CodeSignature/CodeResources"]
            .map { try? Data(contentsOf: saver.appendingPathComponent($0)) }
    }

    private static func version(of saver: URL) -> String? {
        // Read from disk each time: `Bundle` caches what it loaded, and the copy may have just been replaced.
        NSDictionary(contentsOf: saver.appendingPathComponent("Contents/Info.plist"))?["CFBundleVersion"] as? String
    }

    /// macOS's screen saver host caches loaded bundles; it starts again by itself when next needed.
    private static func restartHost() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        p.arguments = ["legacyScreenSaver"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
    }
}
