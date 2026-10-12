import AppKit
import ApplicationServices

/// Brings the terminal or editor hosting a Claude session to the front.
/// - Terminal.app / iTerm2: selects the exact tab by its tty.
/// - Anything else (VS Code, Cursor, …): raises the window whose title names the session's project
///   (needs Accessibility permission; without it, the app is just activated).
enum Jump {
    /// Set by the `--jump=` diagnostic to trace each step.
    static var log: ((String) -> Void)?

    static func toSession(pid: Int32) {
        guard let app = hostApp(of: pid) else { log?("no host app for \(pid)"); NSSound.beep(); return }
        log?("host \(app.bundleIdentifier ?? "?") pid \(app.processIdentifier); cwd \(ClaudeProcesses.cwd(pid) ?? "?")")
        let tty = ttyPath(pid)
        let cwd = ClaudeProcesses.cwd(pid) ?? ""
        // Every component up to and including each folder, so the editor fallback opens exactly that folder.
        let components = cwd.split(separator: "/").map(String.init)
        let folders = components.indices
            .filter { !["Users", "Volumes", NSUserName()].contains(components[$0]) }
            .map { (name: components[$0], path: "/" + components[...$0].joined(separator: "/")) }
        func editor() {
            log?("folders (deepest first): \(folders.reversed().map(\.name))")
            raiseWindow(of: app, matching: folders.reversed())
        }

        let script: String?
        switch app.bundleIdentifier {
        case "com.apple.Terminal": script = tty.map(terminalScript)
        case "com.googlecode.iterm2": script = tty.map(iTermScript)
        default: script = nil
        }
        guard let script else { editor(); return }
        // Apple Events wait on the terminal (and on the Automation prompt): keep them off the main thread.
        scriptQueue.async {
            let ok = run(script)
            DispatchQueue.main.async { if !ok { editor() } }
        }
    }

    private static let scriptQueue = DispatchQueue(label: "justice-league-clawd-wars.jump.applescript")

    /// Host app per session pid, with the session's start time so a reused pid is looked up again.
    private static var hostCache: [Int32: (started: Double?, host: pid_t)] = [:]

    /// Which of these sessions is the one you're looking at: its host app is frontmost and, when several
    /// sessions share that app (VS Code windows or native tabs), the focused window's title names its project.
    static func focusedSession(among sessions: [(pid: Int32, project: String)]) -> Int32? {
        guard let front = NSWorkspace.shared.frontmostApplication else { return nil }
        let live = Set(sessions.map(\.pid))
        hostCache = hostCache.filter { live.contains($0.key) }
        let inFront = sessions.filter { s in
            let started = startTime(s.pid)
            if let cached = hostCache[s.pid], cached.started == started { return cached.host == front.processIdentifier }
            guard let app = hostApp(of: s.pid) else { return false }
            hostCache[s.pid] = (started, app.processIdentifier)
            return app.processIdentifier == front.processIdentifier
        }
        if inFront.count <= 1 { return inFront.first?.pid }
        guard AXIsProcessTrusted() else { return nil }
        let axApp = axApplication(front.processIdentifier)
        guard let window = attribute(axApp, kAXFocusedWindowAttribute) else { return nil }
        let title = attribute(window as! AXUIElement, kAXTitleAttribute) as? String
        return inFront.first { titleNames(title, $0.project) }?.pid
    }

    /// Accessibility element for an app, with a short messaging timeout: a hung editor can't stall the main
    /// thread for the default ~6 s per query. The same timeout is set globally, for the windows and tabs
    /// queried through it.
    private static let globalAXTimeout: Void = { AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.25) }()

    private static func axApplication(_ pid: pid_t) -> AXUIElement {
        _ = globalAXTimeout
        let el = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(el, 0.25)
        return el
    }

    private static func startTime(_ pid: Int32) -> Double? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        let st = info.kp_proc.p_starttime
        return Double(st.tv_sec) + Double(st.tv_usec) / 1e6
    }

    /// First GUI app up the process tree (e.g. Code Helper → Visual Studio Code).
    private static func hostApp(of pid: Int32) -> NSRunningApplication? {
        var current: Int32? = pid
        for _ in 0..<12 {
            guard let p = current else { return nil }
            if let app = NSRunningApplication(processIdentifier: p), app.activationPolicy == .regular { return app }
            current = ClaudeProcesses.parent(p)
        }
        return nil
    }

    private static func ttyPath(_ pid: Int32) -> String? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return nil }
        let dev = info.kp_eproc.e_tdev
        guard dev != -1, let name = devname(dev, S_IFCHR) else { return nil }
        return "/dev/" + String(cString: name)
    }

    /// Asks for Accessibility once per launch (the system prompt), then just checks.
    private static var askedForAccessibility = false

    private static func raiseWindow(of app: NSRunningApplication, matching folders: [(name: String, path: String)]) {
        let trusted: Bool
        if askedForAccessibility {
            trusted = AXIsProcessTrusted()
        } else {
            askedForAccessibility = true
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            trusted = AXIsProcessTrustedWithOptions(options)
        }
        guard trusted else { log?("not trusted"); activate(app); return }

        let axApp = axApplication(app.processIdentifier)
        let windows = (attribute(axApp, kAXWindowsAttribute) as? [AXUIElement]) ?? []

        // Native window tabs (e.g. VS Code with "window.nativeTabs"): every project is a tab in a shared
        // window, and only the selected tab's title is the window title.
        var tabs: [(tab: AXUIElement, window: AXUIElement, title: String)] = []
        for w in windows {
            for group in descendants(of: w, role: kAXTabGroupRole, depth: 3) {
                for tab in (attribute(group, kAXChildrenAttribute) as? [AXUIElement]) ?? []
                where (attribute(tab, kAXRoleAttribute) as? String) == kAXRadioButtonRole {
                    tabs.append((tab, w, attribute(tab, kAXTitleAttribute) as? String ?? ""))
                }
            }
        }
        let titled = windows.map { (window: $0, title: attribute($0, kAXTitleAttribute) as? String ?? "") }
        log?("windows: \(titled.map(\.title)); tabs: \(tabs.map(\.title))")

        // Exact title segment for every folder (deepest first) before any substring match; short folder
        // names ("src", "app") only count as a whole segment.
        for exact in [true, false] {
            for folder in folders where exact || folder.name.count >= 4 {
                func matches(_ title: String) -> Bool { exact ? titleNames(title, folder.name) : title.contains(folder.name) }
                if let hit = tabs.first(where: { matches($0.title) }) {
                    selectTab(hit.tab, window: hit.window, app: app, axApp: axApp, folder: folder.name,
                              reopen: exact ? folder.path : nil)
                    return
                }
                if let hit = titled.first(where: { matches($0.title) }) {
                    bringForward(hit.window, in: axApp)
                    activate(app)
                    return
                }
            }
        }
        activate(app)
    }

    /// Electron apps ignore AXPress on a native tab while they're in the background, so: bring the app
    /// forward, press the tab, and if the window still shows another project, ask the app to open that
    /// project folder (`reopen`, only given for an exact title match), which, because it's already open
    /// in that tab, just focuses the tab.
    private static func selectTab(_ tab: AXUIElement, window: AXUIElement, app: NSRunningApplication,
                                  axApp: AXUIElement, folder: String, reopen: String?) {
        func selected() -> Bool { titleNames(attribute(window, kAXTitleAttribute) as? String, folder) }
        activate(app)
        AXUIElementSetAttributeValue(axApp, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let r = AXUIElementPerformAction(tab, kAXPressAction as CFString)
            log?("pressed tab \(folder) after activating → \(r.rawValue)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if selected() { log?("tab selected via AX"); bringForward(window, in: axApp); return }
                // Fall back: reopen the folder (only the exact folder whose name is an open tab's title).
                guard let path = reopen, let appURL = app.bundleURL else { return }
                log?("AX press ignored; opening \(path) in \(appURL.lastPathComponent)")
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.open([URL(fileURLWithPath: path)], withApplicationAt: appURL, configuration: config)
            }
        }
    }

    private static func bringForward(_ window: AXUIElement, in app: AXUIElement) {
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(app, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
    }

    /// Whether a VS Code-style title ("file.swift (project) Visual Studio Code") has `folder` as a whole
    /// segment. Tested against the title itself rather than split parts, so a folder like "- CODE -" that
    /// contains a separator still matches.
    private static func titleNames(_ title: String?, _ folder: String) -> Bool {
        guard let title = title?.trimmingCharacters(in: .whitespaces), !folder.isEmpty else { return false }
        if title == folder { return true }
        // Window titles separate the folder with an em dash (written as an escape here) or a hyphen.
        return [" \u{2014} ", " - "].contains { sep in
            title.hasPrefix(folder + sep) || title.hasSuffix(sep + folder) || title.contains(sep + folder + sep)
        }
    }

    private static func attribute(_ el: AXUIElement, _ name: String) -> CFTypeRef? {
        var v: CFTypeRef?
        return AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success ? v : nil
    }

    private static func descendants(of el: AXUIElement, role: String, depth: Int) -> [AXUIElement] {
        guard depth > 0 else { return [] }
        var found: [AXUIElement] = []
        for child in (attribute(el, kAXChildrenAttribute) as? [AXUIElement]) ?? [] {
            if (attribute(child, kAXRoleAttribute) as? String) == role { found.append(child) }
            found += descendants(of: child, role: role, depth: depth - 1)
        }
        return found
    }

    /// Diagnostics (`--ax-dump=<pid> <file>`): what the Accessibility API exposes for the app hosting a session.
    static func dump(pid: Int32) -> String {
        var out = "trusted: \(AXIsProcessTrusted())\n"
        guard let app = hostApp(of: pid) else { return out + "no host app\n" }
        out += "host: \(app.localizedName ?? "?") \(app.bundleIdentifier ?? "")\n"
        out += "cwd: \(ClaudeProcesses.cwd(pid) ?? "?")\n"
        let axApp = axApplication(app.processIdentifier)
        for w in (attribute(axApp, kAXWindowsAttribute) as? [AXUIElement]) ?? [] {
            out += "window: \(attribute(w, kAXTitleAttribute) as? String ?? "?")\n"
            for group in descendants(of: w, role: kAXTabGroupRole, depth: 3) {
                for tab in (attribute(group, kAXChildrenAttribute) as? [AXUIElement]) ?? [] {
                    out += "   tab [\(attribute(tab, kAXRoleAttribute) as? String ?? "?")]: \(attribute(tab, kAXTitleAttribute) as? String ?? "?")\n"
                }
            }
        }
        return out
    }

    private static func activate(_ app: NSRunningApplication) {
        guard let url = app.bundleURL else { app.activate(); return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: config)
    }

    private static func run(_ source: String) -> Bool {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        return error == nil && result?.booleanValue == true
    }

    private static func terminalScript(_ tty: String) -> String {
        """
        tell application "Terminal"
            repeat with w in windows
                repeat with t in tabs of w
                    if tty of t is "\(tty)" then
                        set selected of t to true
                        set index of w to 1
                        activate
                        return true
                    end if
                end repeat
            end repeat
        end tell
        return false
        """
    }

    private static func iTermScript(_ tty: String) -> String {
        """
        tell application "iTerm2"
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        if tty of s is "\(tty)" then
                            select w
                            tell t to select
                            tell s to select
                            activate
                            return true
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        return false
        """
    }
}
