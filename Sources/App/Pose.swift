import Foundation

// Every character is drawn the same way: `drawPersona` works out what it's doing this frame (a `Pose`: walking,
// fighting, idle habits, waiting for you…), its `Persona.draw` draws the costume and weapon in that pose, and
// `drawPersona` adds the shared effects on top (muzzle flash and solo practice shots, magic streams, smoke).
//
// Writing a character's drawing function (`(PixelCanvas, Pose) -> Void`), facing right on the 72×52 canvas:
//   - the canvas origin (`c.ox`, `c.oy`) is already shifted by `p.dx`, `p.hop` (fight footwork, hops, sitting);
//   - legs: `drawLegs(c, look, step: p.step)` (they fold up by themselves when it's sitting);
//   - then the body and everything above the legs `p.breathe` (0 or -1) higher: `c.oy += p.breathe`;
//   - a melee weapon at `p.melee` degrees (0 forward, -90 straight up), pivoting on `Persona.pivot`; nil = put away
//     (on its back, at its belt, shield on the arm); `p.trail` holds earlier angles of a fast swing, for a smear;
//   - a held gun `p.gunY` higher or lower than its resting place (recoil, raised to check it);
//   - a magic caster's hand raised `p.armRaise` pixels; the stream itself is drawn for you;
//   - `p.flying`: on the move through the air, draw it in flight; `p.signature`: 0…1 through its signature move.
// Restore nothing: `drawPersona` resets the canvas offsets afterwards.

struct Pose {
    let who: Cast
    let t: Double              // the shared clock (both sides of a fight are in step on it)
    let lt: Double             // its own clock, so solo moves aren't in lockstep with everyone else's
    let mode: CrewMode
    let role: FightRole
    let walking: Bool
    var flying = false         // a flyer on the move: draw it in flight
    var seated = false
    var urgent = false
    var step = -1              // walk cycle for `drawLegs`: -1 standing, 0/1 which legs are lifted
    var breathe = 0            // -1 or 0: the upper body's breathing bob
    var dx = 0, hop = 0        // whole-sprite shift, already applied to the canvas origin
    var melee: Double?         // melee weapon angle in degrees; nil = put away
    var trail: [Double] = []   // earlier angles of a fast swing
    var fire: (t: Double, bolt: Bool)?   // ranged: firing on this clock (`bolt`: the shot is drawn in-canvas too)
    var recoil = 0             // 1 as the gun kicks
    var gunLift = 0            // idle habit: weapon raised to eye level
    var smoke: Double?         // idle habit: 0…1 through blowing the smoke off the barrel
    var zap: Bool?             // magic: true = casting (stream drawn in-canvas), false = crackling in the hand
    var armRaise = 0           // casting hand raised this many pixels
    var signature: Double?     // 0…1 through its signature move
    var capeSpeed = 1.6        // how hard a cape billows

    /// Doing nothing in particular: weapon lowered or put away.
    var resting: Bool {
        if walking { return false }
        switch role {
        case .rest: return true
        case .none: return mode == .idle || mode == .thinking
        default: return false
        }
    }
    /// Waiting for you: weapon held up (waved and hopping when `urgent`).
    var ready: Bool {
        if case .ready = role { return true }
        if case .none = role { return mode == .waiting && !walking }
        return false
    }
    var cheering: Bool { if case .cheer = role { return true } else { return false } }
    var hit: Bool { if case .hit = role { return true } else { return false } }
    /// Where to draw a held gun relative to its resting height: recoil and the idle check lift it.
    var gunY: Int { -recoil - gunLift }
}

/// Draw `who` this frame. `airborne`: a flyer on the move (the renderer lifts it off the ground too).
/// `aloft`: lifted off the ground in place (a flyer's sortie, or fighting from the air): it gets an air wash under its feet.
func drawPersona(_ c: PixelCanvas, _ who: Cast, t: Double, mode: CrewMode, walking: Bool, role: FightRole,
                 urgent: Bool = false, sitting: Bool = false, airborne: Bool = false, aloft: Bool = false) {
    let persona = who.persona
    var role = role
    // A session's mood becomes a role: waiting for you holds the weapon up, the rest is resting.
    var mode = mode
    if case .rest = role { mode = .idle }
    if case .ready(let u) = role { mode = .waiting; role = .none; _ = u }
    let lt = t + Double(who.id) * 0.77
    var p = Pose(who: who, t: t, lt: lt, mode: mode, role: role, walking: walking)
    p.flying = airborne || (walking && persona.motion == .fly)
    p.urgent = urgent
    p.step = p.flying ? -1 : walkStep(t, walking)
    p.breathe = walking ? (p.step == 0 ? -1 : 0) : (sin(lt * 2 * .pi / 2.6) > 0.35 ? -1 : 0)
    var unengaged = false
    if case .none = role { unengaged = true }
    if case .rest = role { unengaged = true }
    p.seated = sitting && persona.canSit && !walking && unengaged && (mode == .idle || mode == .standGuard)

    if walking {
        if mode != .idle && mode != .thinking && persona.weapon == .melee { p.melee = -60 }
    } else {
        switch mode {
        case .idle, .thinking:
            if case .rest = role {} else if case .none = role {} else { break }
            guard mode == .idle, let h = idleHabit else { break }
            switch h.kind {
            case .flourish:
                // Weapon swung up, round once and back down.
                if h.p > 0.08 && h.p < 0.92 {
                    let len = h.length, start = t - h.e
                    let spin = { (u: Double) -> Double in
                        let s = min(1, max(0, ((u - start) / len - 0.25) / 0.5))
                        return -70 - 360 * (0.5 - 0.5 * cos(s * .pi))
                    }
                    p.melee = spin(t)
                    if h.p > 0.25 && h.p < 0.75 { p.trail = swingTrail(t, pose: spin) }
                }
            case .checkWeapon:
                p.gunLift = Int((2 * habitArc(min(1, h.p / 0.55), hold: 0.5)).rounded())
                if h.p > 0.45 { p.smoke = (h.p - 0.45) / 0.55 }
            case .crackle:
                p.zap = false; p.armRaise = 2
            case .signature:
                p.signature = h.p
            default: break
            }
        case .waiting:
            p.melee = urgent ? -90 + 25 * sin(t * 12) : -90 + 2 * sin(t * 3)
            if persona.weapon == .ranged { p.gunLift = 1 }
            if persona.weapon == .magic { p.zap = false; p.armRaise = 2 }
            if urgent { p.hop = cheerHop(t * 1.5); p.breathe = 0 }
        case .standGuard:
            p.melee = -65 + 3 * sin(t * 2.2)
            p.capeSpeed = 2.2
        case .working:
            p.capeSpeed = 4.5
            switch role {
            case .duel:
                let d = duelPose(t)
                p.melee = d.angle; p.dx = Int(d.dx.rounded()); p.hop = Int(d.dy.rounded()); p.breathe = 0
                p.trail = swingTrail(t, pose: { duelPose($0).angle })
            case .deflect:
                p.melee = deflectAngle(t)
                p.trail = swingTrail(t, pose: deflectAngle)
            case .block:
                p.melee = -60 + 2 * sin(t * 37)
                p.dx = -1
            case .shoot(let offset):
                p.fire = (t + offset, false)
            case .zap:
                p.zap = false; p.armRaise = 2      // the stream between the two is drawn by the fight layer
            case .hit:
                p.dx = noise(Int(t * 30)) > 0.5 ? 1 : -1
                p.hop = noise(Int(t * 30) + 7) > 0.6 ? -1 : 0
            case .cheer:
                p.hop = cheerHop(t); p.breathe = 0
                switch persona.weapon {
                case .melee: p.melee = -95 + 18 * sin(t * 9)
                case .magic: p.zap = false; p.armRaise = 2
                case .ranged: p.gunLift = -cheerHop(t) + 1
                case .none: break
                }
            case .none, .rest, .ready:
                switch persona.weapon {
                case .melee:
                    let k = kataPose(lt)
                    p.melee = k.angle; p.dx = Int(k.dx.rounded()); p.hop = Int(k.dy.rounded()); p.breathe = 0
                    p.trail = swingTrail(lt)
                case .ranged: p.fire = (lt, true)
                case .magic: p.zap = true; p.armRaise = 2
                case .none: break
                }
            }
        }
    }
    if let fire = p.fire { p.recoil = shotRecoil(t: fire.t) }
    if p.seated { p.hop += 4 }
    // Hovering: a few pixels off the ground, bobbing gently (not when sitting down, or flying past).
    var float = 0
    if persona.motion == .hover && !p.seated && !p.flying { float = -3 + (sin(lt * 2.4) > 0 ? -1 : 0) }

    if p.cheering, !walking { drawCheerSparkles(c, t: t) }
    if aloft, !p.flying { drawAirWash(c, t: t) }
    seatedPose = p.seated
    let baseY = c.baseY
    c.baseY += float
    c.ox = p.dx; c.oy = p.hop
    persona.draw(c, p)

    // Shared effects, from the same origin the art used for its upper body.
    c.ox = p.dx; c.oy = p.hop + p.breathe
    switch persona.weapon {
    case .ranged:
        if let fire = p.fire {
            drawMuzzleShot(c, t: fire.t, muzzle: persona.muzzle, style: persona.shot, bolt: fire.bolt, gunY: p.gunY)
        }
        if let smoke = p.smoke { drawBarrelSmoke(c, x: persona.muzzle.x, y: persona.muzzle.y + Double(p.gunY), smoke) }
    case .magic:
        let hand = (persona.pivot.x, persona.pivot.y - Double(p.armRaise))
        if p.zap == true {
            drawMagic(c, persona.magic, from: hand, to: (70, hand.1 - 2), t: t)
        } else if p.zap == false {
            let i = Int(t * 20)
            c.px(Int(hand.0) + Int(noise(i) * 3) - 1, Int(hand.1) + Int(noise(i + 1) * 3) - 1, persona.magic.glow)
            c.px(Int(hand.0) + Int(noise(i + 2) * 3) - 1, Int(hand.1) + Int(noise(i + 3) * 3) - 1, persona.magic.core)
        }
    default: break
    }
    c.ox = 0; c.oy = 0; c.baseY = baseY
    seatedPose = false
}

extension Cast {
    var persona: Persona {
        switch self { case .villain(let l): return l.persona; case .hero(let h): return h.persona }
    }
    var motion: Motion { persona.motion }
}

// MARK: - Flight

/// How high (0…1 of `flightHeight`) a flyer is on a sortie at `t`: now and then it takes off, hangs in the air and comes
/// back down. Ranged and magic flyers do it in fights too, more often, and keep shooting from up there; melee flyers
/// stay down to duel. `seed` (0…1) keeps everyone on their own schedule. Stateless, so the screen saver can use it.
func sortieAir(_ who: Cast, seed: Double, fighting: Bool, t: Double) -> Double {
    guard who.motion == .fly else { return 0 }
    if fighting && !(who.weapon == .ranged || who.weapon == .magic) { return 0 }
    let period = fighting ? 9.0 : 26.0, share = fighting ? 0.4 : 0.15
    let f = frac(t / period + seed)
    guard f < share else { return 0 }
    let k = f / share, ramp = 0.2
    if k < ramp { return 0.5 - 0.5 * cos(k / ramp * .pi) }
    if k > 1 - ramp { return 0.5 - 0.5 * cos((1 - k) / ramp * .pi) }
    return 1
}

/// Air pushed down under someone hanging in the air: a few pale streaks flickering below the feet.
func drawAirWash(_ c: PixelCanvas, t: Double) {
    let i = Int(t * 18)
    for k in 0..<3 {
        let x = 20 + k * 6 + Int(noise(i + k * 5) * 3), y = 45 + Int(noise(i * 3 + k) * 4)
        c.rect(x, y, 3 + Int(noise(i + k) * 3), 1, C(0xE8F4FF, 0.35 + 0.3 * noise(i * 7 + k)))
    }
}

// MARK: - Shots

/// 1 while a gun on clock `t` is kicking back from a shot.
func shotRecoil(t: Double) -> Int { frac(t / shotPeriod) < 0.15 ? 1 : 0 }

/// Muzzle flash, and (solo practice) the shot flying off to the canvas edge.
func drawMuzzleShot(_ c: PixelCanvas, t: Double, muzzle: (x: Double, y: Double), style: ShotStyle, bolt: Bool, gunY: Int) {
    let f = frac(t / shotPeriod)
    let mx = muzzle.x, my = muzzle.y + Double(gunY)
    var flash = true                     // no flash from a bow, a beam or an ice stream
    switch style { case .beam, .ice, .arrow: flash = false; default: break }
    if flash, f < 0.08 {
        c.rect(Int(mx), Int(my) - 1, 2, 3, C(0xFFE27A))
        c.px(Int(mx) + 2, Int(my), C(0xFFF6C8))
    }
    guard bolt, f < 0.4 else { return }
    let x = mx + 2 + f / 0.4 * (Double(Sprite.width) - mx)
    drawProjectile(c, style, from: (mx + 2, my + 0.5), head: (x, my + 0.5), t: t)
}

/// A shot `style` in flight: its head at `head`, fired from `from`. `alpha` fades it.
func drawProjectile(_ c: PixelCanvas, _ style: ShotStyle, from a: (x: Double, y: Double), head h: (x: Double, y: Double),
                    t: Double, alpha: Double = 1) {
    let len = max(hypot(h.x - a.x, h.y - a.y), 0.01)
    let ux = (h.x - a.x) / len, uy = (h.y - a.y) / len
    switch style {
    case .energy(let core, let glow):
        c.glowLine(h.x - ux * 5, h.y - uy * 5, h.x, h.y, core: core.alpha(alpha), glow: glow.alpha(alpha), coreR: 0.6, glowR: 1.8)
    case .beam(let core, let glow):
        let flicker = 0.85 + 0.15 * sin(t * 50)
        c.glowLine(a.x, a.y, h.x, h.y, core: core.alpha(alpha), glow: glow.alpha(alpha), coreR: 0.7, glowR: 2.2,
                   strength: flicker)
    case .bullet:
        c.glowLine(h.x - ux * 3, h.y - uy * 3, h.x, h.y, core: C(0xFFF6D0).alpha(alpha), glow: C(0xFFB02A).alpha(alpha * 0.7),
                   coreR: 0.4, glowR: 1)
    case .arrow:
        let shaft = C(0x6A4A2A).alpha(alpha), tip = C(0xC8CCD4).alpha(alpha), fletch = C(0xC83A2A).alpha(alpha)
        for k in 0..<7 { c.px(Int((h.x - ux * Double(k)).rounded()), Int((h.y - uy * Double(k)).rounded()), k == 0 ? tip : shaft) }
        c.px(Int((h.x + ux).rounded()), Int((h.y + uy).rounded()), tip)
        c.px(Int((h.x - ux * 7).rounded()), Int((h.y - uy * 7 - 1).rounded()), fletch)
        c.px(Int((h.x - ux * 7).rounded()), Int((h.y - uy * 7 + 1).rounded()), fletch)
    case .fire:
        let flick = noise(Int(t * 30))
        c.glowLine(h.x - ux * 6, h.y - uy * 6, h.x - ux * 2, h.y - uy * 2, core: C(0xFFB02A).alpha(alpha * 0.6),
                   glow: C(0xFF4A1A).alpha(alpha * 0.5), coreR: 0.6, glowR: 1.6)
        c.glowLine(h.x, h.y, h.x, h.y, core: C(0xFFF2B0).alpha(alpha), glow: C(0xFF7A1A).alpha(alpha),
                   coreR: 1.2, glowR: 2.4 + flick)
    case .ice:
        c.glowLine(a.x, a.y, h.x, h.y, core: C(0xE8FAFF).alpha(alpha * 0.8), glow: C(0x7FD8FF).alpha(alpha * 0.6),
                   coreR: 0.5, glowR: 1.6)
        c.rect(Int(h.x) - 1, Int(h.y) - 1, 3, 3, C(0xE8FAFF).alpha(alpha))
    case .thrown(let col):
        let spin = Int(t * 24) % 2
        if spin == 0 { c.rect(Int(h.x) - 1, Int(h.y), 3, 1, col.alpha(alpha)) } else { c.rect(Int(h.x), Int(h.y) - 1, 1, 3, col.alpha(alpha)) }
        c.px(Int(h.x), Int(h.y), white.alpha(alpha * 0.8))
    }
}

/// A magic or energy stream from `a` to `b`: forked like lightning, or a steady wavering ray.
func drawMagic(_ c: PixelCanvas, _ m: Magic, from a: (Double, Double), to b: (Double, Double), t: Double) {
    let seed = Int(t * 20)
    let dx = b.0 - a.0, dy = b.1 - a.1
    let len = max(sqrt(dx * dx + dy * dy), 0.01)
    let nx = -dy / len, ny = dx / len
    if !m.jagged {
        let n = 8
        var prev = a
        for i in 1...n {
            let f = Double(i) / Double(n)
            let off = i == n ? 0 : sin(f * 9 + t * 14) * 1.4
            let q = (a.0 + dx * f + nx * off, a.1 + dy * f + ny * off)
            c.glowLine(prev.0, prev.1, q.0, q.1, core: m.core, glow: m.glow, coreR: 0.7, glowR: 2.2,
                       strength: 0.85 + 0.15 * noise(seed + i))
            prev = q
        }
        return
    }
    for bolt in 0..<2 {
        var prev = a
        let n = 6
        for i in 1...n {
            let f = Double(i) / Double(n)
            let off = i == n ? 0 : (noise(seed * 31 + bolt * 7 + i) - 0.5) * 7
            let q = (a.0 + dx * f + nx * off, a.1 + dy * f + ny * off)
            c.glowLine(prev.0, prev.1, q.0, q.1, core: m.core, glow: m.glow, coreR: 0.5, glowR: 1.8,
                       strength: bolt == 0 ? 1 : 0.6)
            prev = q
        }
    }
}

// MARK: - A stand-in

/// Plain Clawd in a costume colour, holding something that says how it fights. For a character whose art isn't
/// drawn yet.
func drawStandIn(_ c: PixelCanvas, _ p: Pose, body: Px, trim: Px) {
    let look = Look(body: body, shade: trim, leg: trim, arm: body)
    drawLegs(c, look, step: p.step)
    c.oy += p.breathe
    drawBody(c, look, armRight: p.armRaise)
    c.rect(18, 26, 20, 3, trim)
    switch p.who.weapon {
    case .melee:
        let r = (p.melee ?? 75) * .pi / 180
        c.glowLine(Sprite.hand.x, Sprite.hand.y, Sprite.hand.x + cos(r) * 12, Sprite.hand.y + sin(r) * 12,
                   core: C(0xC8CCD4), glow: C(0x000000, 0), coreR: 0.8, glowR: 0.9)
    case .ranged:
        c.oy += p.gunY
        c.rect(40, 31, 9, 2, C(0x2A2A30)); c.rect(40, 33, 2, 2, C(0x2A2A30))
    default: break
    }
}
