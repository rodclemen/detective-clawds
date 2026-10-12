import Foundation

// Idle habits: a session that's done doesn't just stand there. Every 11–19 s (its own rhythm) its character does
// something small for a second or two: looks over its shoulder, shifts its weight, or handles its weapon the way it
// would, a sword or staff swung round, a gun raised and the smoke blown off, magic crackling in a raised hand.
// Only while idle and still standing: once it sits down (2 min) it's just resting.

enum IdleHabit {
    case glance        // looks back over its shoulder
    case shuffle       // shifts its weight from foot to foot
    case bounce        // a little bounce on the spot (the unarmed ones)
    case flourish      // melee weapon swung up, round once and back down
    case checkWeapon   // gun raised to eye level, then the smoke blown off the barrel
    case crackle       // magic flickering between the fingers, hand raised
    case signature     // its own thing, drawn by its own drawing code (`Cast.hasSignature`)

    var length: Double {
        switch self {
        case .glance: return 1.6
        case .shuffle: return 1.2
        case .bounce: return 0.9
        case .flourish: return 1.8
        case .checkWeapon: return 2.2
        case .crackle: return 1.4
        case .signature: return 2.6
        }
    }
}

/// The habit being played right now, `e` seconds in. Set while a session's character is drawn (like `seatedPose`).
struct HabitPlay {
    let kind: IdleHabit
    let e: Double
    var length: Double
    var p: Double { min(1, e / length) }

    init(kind: IdleHabit, e: Double, length: Double? = nil) {
        self.kind = kind; self.e = e; self.length = length ?? kind.length
    }
}

var idleHabit: HabitPlay?

/// Previews and the docs renderer: play this habit instead of the scheduled one.
var forcedHabit: HabitPlay?

extension Cast {
    /// What this character does when idle: its weapon habit (if it handles one by hand) comes up twice as often.
    var habits: [IdleHabit] {
        var weaponHabit: IdleHabit?
        switch weapon {
        case .melee: weaponHabit = .flourish
        case .ranged: if persona.handGun { weaponHabit = .checkWeapon }
        case .magic: weaponHabit = .crackle
        case .none: break
        }
        var list: [IdleHabit] = [.glance, .shuffle]
        list += weaponHabit.map { [$0, $0] } ?? [.bounce]
        if hasSignature { list += [.signature, .signature] }
        return list
    }

    /// How long its own move takes, for characters that have one (`Persona.signature`).
    var signatureLength: Double? { persona.signature }

    var hasSignature: Bool { signatureLength != nil }

    /// The signature move playing right now, 0…1 through it (nil: not playing).
    static var signatureProgress: Double? {
        guard let h = idleHabit, h.kind == .signature else { return nil }
        return h.p
    }

    /// The habit playing at `t`, if any: one per cycle, picked afresh each cycle.
    func habit(at t: Double) -> HabitPlay? {
        if let forced = forcedHabit { return forced }
        let period = 11 + 8 * noise(id * 7 + 3)
        let lt = t + Double(id) * 3.1
        let cycle = floor(lt / period), e = lt - cycle * period
        let list = habits
        guard !list.isEmpty else { return nil }
        let kind = list[min(list.count - 1, Int(noise(Int(cycle) * 31 + id) * Double(list.count)))]
        let length = kind == .signature ? signatureLength ?? kind.length : kind.length
        return e < length ? HabitPlay(kind: kind, e: e, length: length) : nil
    }
}

/// Smooth 0→1→0 over `p` 0…1, held at 1 through the middle `hold` share.
func habitArc(_ p: Double, hold: Double = 0.4) -> Double {
    let ramp = (1 - hold) / 2
    if p < ramp { return 0.5 - 0.5 * cos(p / ramp * .pi) }
    if p > 1 - ramp { return 0.5 - 0.5 * cos((1 - p) / ramp * .pi) }
    return 1
}

/// The whole-sprite habits, applied after the character is drawn.
func applyHabitTransform(_ c: PixelCanvas, _ play: HabitPlay) {
    switch play.kind {
    case .glance:
        // Mirrored about the body's centre; skipped for anyone too wide to turn round inside the canvas.
        if play.p > 0.15 && play.p < 0.85 { c.mirror(aboutX: Sprite.bodyCenterX) }
    case .shuffle:
        c.shift(dx: Int(play.e / 0.3) % 2 == 0 ? 0 : (Int(play.e / 0.6) % 2 == 0 ? 1 : -1), dy: 0)
    case .bounce:
        c.shift(dx: 0, dy: sin(play.p * .pi * 2) > 0.3 ? -2 : 0)
    default:
        break
    }
}

/// Smoke blown off a barrel at (`x`, `y`): three puffs drifting up and fading, `k` 0…1 through it.
func drawBarrelSmoke(_ c: PixelCanvas, x: Double, y: Double, _ k: Double) {
    for i in 0..<3 {
        let f = k * 1.6 - Double(i) * 0.3
        guard f > 0, f < 1 else { continue }
        let px = Int((x + sin(f * 8) * 1.5).rounded()), py = Int((y - 2 - f * 9).rounded())
        let col = C(0xE0E0E0).alpha(0.85 * (1 - f))
        c.rect(px, py, 2, 2, col)
        c.px(px - 1, py, col.alpha(0.5))
    }
}

/// A sweep of light across chrome: a diagonal band moving left to right, `p` 0…1, only over what's drawn left of
/// `maxX` (so it catches the armour, not the gun).
func drawGlint(_ c: PixelCanvas, p: Double, maxX: Int = 40) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    let k = -10 + p * 70
    for y in 0..<c.h {
        for x in 0...min(maxX, c.w - 1) where c.isDrawn(x, y) {
            let d = abs(Double(x) + Double(y) * 0.5 - k)
            if d < 2.5 { c.px(x, y, C(0xFFFFFF).alpha(d < 1 ? 0.8 : 0.4)) }
        }
    }
}
