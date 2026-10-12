import Darwin
import Foundation

/// A project's name and where its remote lives, read from the repo's `.git/config` on disk (no network needed).
struct GitRemote {
    let name: String    // the repo name from the remote's URL, e.g. "justice-league-clawd-wars"
    let host: String    // "GitHub", "GitLab", "Bitbucket", "Codeberg", or the bare host name

    private struct Entry { var remote: GitRemote?; var checked: Double; var used: Double; var refreshing = false }
    private static var cache: [String: Entry] = [:]
    private static var lastPrune = 0.0
    private static let lock = NSLock()
    private static let queue = DispatchQueue(label: "GitRemote", qos: .utility)
    /// How long an answer is trusted: a project that gets a remote later is picked up within this.
    static let recheck: Double = 5
    /// Entries nobody asked about for this long are dropped (closed sessions, renamed folders).
    static let forget: Double = 10 * 60

    /// The remote of the repo containing `cwd` (origin, else the first one), or nil if it has none or isn't a repo.
    /// Only the first lookup of a folder reads the disk on the caller's thread; after that the cached answer is
    /// returned at once and re-read in the background when it's older than `recheck`.
    static func of(_ cwd: String, now: Double = Date().timeIntervalSince1970) -> GitRemote? {
        lock.lock()
        if now - lastPrune > 60 {
            lastPrune = now
            cache = cache.filter { now - $0.value.used < forget }
        }
        if var hit = cache[cwd] {
            hit.used = now
            let stale = now - hit.checked >= recheck && !hit.refreshing
            if stale { hit.refreshing = true }
            cache[cwd] = hit
            lock.unlock()
            if stale {
                queue.async {
                    let remote = read(cwd)
                    lock.lock()
                    cache[cwd]?.remote = remote
                    cache[cwd]?.checked = Date().timeIntervalSince1970
                    cache[cwd]?.refreshing = false
                    lock.unlock()
                }
            }
            return hit.remote
        }
        lock.unlock()
        let remote = read(cwd)
        lock.lock()
        cache[cwd] = Entry(remote: remote, checked: now, used: now)
        lock.unlock()
        return remote
    }

    private static func read(_ cwd: String) -> GitRemote? {
        guard let text = configPath(from: cwd).flatMap(readText), let url = remoteURL(config: text) else { return nil }
        return parse(resolve(url, config: text, globalConfigs: globalConfigs()))
    }

    /// Only regular files are read: a FIFO or device named `.git` or `config` would block the read.
    private static func readText(_ path: String) -> String? {
        guard kind(path) == S_IFREG else { return nil }
        return try? String(contentsOfFile: path, encoding: .utf8)
    }

    /// The file type bits (S_IFREG, S_IFDIR…) of `path`, following symlinks; nil if it doesn't exist.
    private static func kind(_ path: String) -> mode_t? {
        var st = stat()
        guard stat(path, &st) == 0 else { return nil }
        return st.st_mode & S_IFMT
    }

    /// The user's own git config, where `url.<base>.insteadOf` aliases usually live.
    private static func globalConfigs() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [".gitconfig", ".config/git/config"].compactMap { readText(home.appendingPathComponent($0).path) }
    }

    /// The shared `config` of the repo containing `cwd`, walking up from it. Handles worktrees and
    /// submodules, whose `.git` is a file pointing at the real git dir.
    static func configPath(from cwd: String) -> String? {
        var dir = URL(fileURLWithPath: cwd).standardizedFileURL
        while true {
            let dotGit = dir.appendingPathComponent(".git")
            if let type = kind(dotGit.path), type == S_IFDIR || type == S_IFREG {
                var gitDir = dotGit
                if type == S_IFREG {   // "gitdir: <path>"
                    guard let text = readText(dotGit.path),
                          let line = text.split(separator: "\n").first(where: { $0.hasPrefix("gitdir:") }) else { return nil }
                    let path = line.dropFirst("gitdir:".count).trimmingCharacters(in: .whitespaces)
                    gitDir = URL(fileURLWithPath: path, relativeTo: dir).standardizedFileURL
                }
                // A worktree's git dir names the main repo's in "commondir"; that's where the config is.
                if let common = readText(gitDir.appendingPathComponent("commondir").path) {
                    gitDir = URL(fileURLWithPath: common.trimmingCharacters(in: .whitespacesAndNewlines),
                                 relativeTo: gitDir.appendingPathComponent("")).standardizedFileURL
                }
                let config = gitDir.appendingPathComponent("config").path
                return kind(config) == S_IFREG ? config : nil
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { return nil }
            dir = parent
        }
    }

    /// Every `key = value` in a git config, with its section ("remote", "url") and subsection ("origin").
    /// Keys and section names are case-insensitive in git, so they come back lowercased.
    static func entries(_ config: String) -> [(section: String, sub: String?, key: String, value: String)] {
        var out: [(String, String?, String, String)] = []
        var section = "", sub: String?
        for raw in config.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("[") {
                // [remote "origin"], the subsection is quoted and may hold "]", so look for the bracket after it.
                let quoted = line.split(separator: "\"", omittingEmptySubsequences: false)
                let close = quoted.count >= 3 ? line.lastIndex(of: "]") : line.firstIndex(of: "]")
                let header = line[line.index(after: line.startIndex)..<(close ?? line.endIndex)]
                let parts = header.split(separator: "\"", omittingEmptySubsequences: false)
                section = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
                sub = parts.count >= 2 ? String(parts[1]) : nil
            } else if !line.hasPrefix("#"), !line.hasPrefix(";"), let eq = line.firstIndex(of: "=") {
                let key = line[..<eq].trimmingCharacters(in: .whitespaces).lowercased()
                out.append((section, sub, key, value(line[line.index(after: eq)...])))
            }
        }
        return out
    }

    /// A config value without its quotes or a trailing `; comment` / `# comment`.
    static func value(_ raw: Substring) -> String {
        var out = "", quoted = false, escaped = false
        for c in raw {
            if escaped { out.append(c); escaped = false; continue }
            switch c {
            case "\\": escaped = true
            case "\"": quoted.toggle()
            case ";", "#":
                if !quoted { return out.trimmingCharacters(in: .whitespaces) }
                out.append(c)
            default: out.append(c)
            }
        }
        return out.trimmingCharacters(in: .whitespaces)
    }

    /// origin's url, else the first remote's.
    static func remoteURL(config: String) -> String? {
        let urls = entries(config).filter { $0.section == "remote" && $0.sub != nil && $0.key == "url" }
        return (urls.first { $0.sub == "origin" } ?? urls.first)?.value
    }

    /// Applies `[url "<base>"] insteadOf = <alias>` rewrites (the longest matching alias wins, like git),
    /// from the repo's config and the user's global ones.
    static func resolve(_ url: String, config: String = "", globalConfigs: [String] = []) -> String {
        let rules = ([config] + globalConfigs).flatMap(entries)
            .filter { $0.section == "url" && $0.key == "insteadof" && $0.sub != nil && !$0.value.isEmpty }
        guard let best = rules.filter({ url.hasPrefix($0.value) }).max(by: { $0.value.count < $1.value.count }),
              let base = best.sub else { return url }
        return base + url.dropFirst(best.value.count)
    }

    /// `git@github.com:me/repo.git`, `https://gitlab.com/group/sub/repo`, `ssh://git@host:22/me/repo.git`…
    /// Remotes on disk (`/srv/repo.git`, `file://…`) aren't remote, so they give nil.
    static func parse(_ url: String) -> GitRemote? {
        var host: String?, path: String?
        if url.contains("://") {
            guard let c = URLComponents(string: url), c.scheme != "file" else { return nil }
            host = c.host
            path = c.path
        } else if let colon = url.firstIndex(of: ":"), !url[..<colon].contains("/") {   // scp-like: [user@]host:path
            let left = url[..<colon]
            host = String(left.split(separator: "@").last ?? left)
            path = String(url[url.index(after: colon)...])
        }
        guard let host, !host.isEmpty, let path else { return nil }
        var name = (path as NSString).lastPathComponent
        if name.hasSuffix(".git") { name = String(name.dropLast(4)) }
        guard !name.isEmpty, name != "/" else { return nil }
        return GitRemote(name: name, host: label(host.lowercased()))
    }

    static func label(_ host: String) -> String {
        let known = ["github": "GitHub", "gitlab": "GitLab", "bitbucket": "Bitbucket", "codeberg": "Codeberg",
                     "dev.azure": "Azure DevOps", "visualstudio": "Azure DevOps", "sr.ht": "SourceHut"]
        if let hit = known.first(where: { host.contains($0.key) }) { return hit.value }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
