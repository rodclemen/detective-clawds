import Foundation

/// Anyone in the cast: a villain or a hero. Any of them can be a session (drawn large) or an agent (drawn small).
/// Ids match `StatusStore`: villains < 100, heroes 100 + Companion.
enum Cast: Hashable {
    case villain(Leader)
    case hero(Companion)

    init(id: Int) {
        if id >= StatusStore.heroBase {
            self = .hero(Companion(rawValue: (id - StatusStore.heroBase) % Companion.allCases.count) ?? .superman)
        } else {
            self = .villain(Leader(index: id))
        }
    }

    /// An agent's character (records from before the shared cast only have a hero index).
    static func of(_ a: AgentRecord) -> Cast { Cast(id: a.cast ?? StatusStore.heroBase + a.character) }

    var id: Int {
        switch self {
        case .villain(let l): return l.rawValue
        case .hero(let h): return StatusStore.heroBase + h.rawValue
        }
    }

    var name: String { persona.name }
    var weapon: Weapon { persona.weapon }
    var isDark: Bool { if case .villain = self { return true } else { return false } }

    var home: Location {
        switch self { case .villain(let l): return Location.home(of: l); case .hero(let h): return Location.home(of: h) }
    }

    /// Top row of the head on the 72×52 canvas (for labels).
    var headTop: Int { persona.headTop }
    /// Where its shots leave from (canvas pixels).
    var muzzle: (x: Double, y: Double) { persona.muzzle }
    /// Where its weapon swings from (canvas pixels).
    var weaponPivot: (x: Double, y: Double) { persona.pivot }
    /// Shots ricochet off it (armour, metal, rock).
    var armoured: Bool { persona.armoured }
    /// What it says now and then while leading a session.
    var callout: String? { persona.callout }

    /// Draw this character. `asSession` = it's a whole Claude/Codex session (it has moods: idle, thinking,
    /// waiting…); agents are always at work. `airborne`: a flyer on its way somewhere.
    func draw(_ c: PixelCanvas, t: Double, mode: CrewMode, walking: Bool, role: FightRole,
              urgent: Bool = false, sitting: Bool = false, asSession: Bool, airborne: Bool = false, aloft: Bool = false) {
        // Idle habits (`Habits.swift`): only an idle session standing about, not fighting, walking or sitting.
        var idle = asSession && mode == .idle && !walking && !sitting
        switch role { case .none, .rest: break; default: idle = false }
        let play = idle ? habit(at: t) : nil
        idleHabit = play
        defer {
            idleHabit = nil
            if let play { applyHabitTransform(c, play) }
        }
        drawPersona(c, self, t: t, mode: asSession ? mode : .working, walking: walking, role: role,
                    urgent: asSession && urgent, sitting: asSession && sitting, airborne: airborne, aloft: aloft)
    }
}

extension Cast {
    private static var measuredTops: [String: Int] = [:]

    /// The top row of this character as drawn at rest, standing or sitting, within 14 px of its body's centre: the
    /// hand-measured `headTop` misses some (horns, wings) and doesn't know a seated character sits lower, and
    /// the band leaves out what floats above (a raised hammer). Standing, never lower than `headTop`
    /// says; sitting, as much lower as the sprite really drops (nothing, for those that don't sit). Measured once per
    /// character and pose; name tags sit just above it.
    /// Its outline from above, standing at rest: for each column within 14 px of the body's centre, the top row drawn
    /// there (`Sprite.height` where nothing is, and outside that band). What a name tag must clear.
    func drawnProfile() -> [Int] {
        if let hit = Self.profiles[id] { return hit }
        let c = PixelCanvas(Sprite.width, Sprite.height)
        draw(c, t: 0, mode: .idle, walking: false, role: .none, asSession: true)
        let mid = Int(Sprite.bodyCenterX)
        let profile = (0..<Sprite.width).map { x -> Int in
            guard abs(x - mid) <= 14 else { return Sprite.height }
            return (0..<c.h).first { c.buf[($0 * c.w + x) * 4 + 3] > 0 } ?? Sprite.height
        }
        Self.profiles[id] = profile
        return profile
    }
    private static var profiles: [Int: [Int]] = [:]

    func drawnTop(sitting: Bool = false) -> Int {
        let key = "\(id)/\(sitting)"
        if let hit = Self.measuredTops[key] { return hit }
        func measure(_ seated: Bool) -> Int {
            let c = PixelCanvas(Sprite.width, Sprite.height)
            draw(c, t: 0, mode: .idle, walking: false, role: .none, sitting: seated, asSession: true)
            let mid = Int(Sprite.bodyCenterX)
            for y in 0..<c.h { for x in (mid - 14)...(mid + 14) where c.buf[(y * c.w + x) * 4 + 3] > 0 { return y } }
            return c.h
        }
        let standing = measure(false)
        let result = min(standing, headTop) + (sitting ? max(0, measure(true) - standing) : 0)
        Self.measuredTops[key] = result
        return result
    }
}
