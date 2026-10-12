import Foundation

// All sprites are variations of Clawd (Claude Code's pixel mascot): a blocky orange body,
// two eyes, arm nubs and four legs. Every character shares this 72x52 canvas layout, facing right:
//   body x 18...37, y 26...37 · legs y 38...43 · right hand pivot (41.5, 34.5)
// Characters facing left are drawn mirrored by the view.

enum Sprite {
    static let width = 72
    static let height = 52
    static let bodyCenterX = 28.0
    static let hand = (x: 41.5, y: 34.5)
}


// MARK: - Palette

let clawdOrange = C(0xD97757)
let clawdShade = C(0xB85F40)
let ink = C(0x16161B)
let outline = C(0x2A2A33)
let white = C(0xFFFFFF)

/// Deterministic noise in 0..<1 (sparks and lightning change every frame without true randomness).
func noise(_ i: Int) -> Double {
    let v = sin(Double(i) * 12.9898 + 78.233) * 43758.5453
    return v - floor(v)
}

// MARK: - Melee choreography

struct Key { let a, dx, dy, dur: Double; let fast: Bool; var clash = false }

private func play(_ keys: [Key], start: Double, _ t: Double) -> (angle: Double, dx: Double, dy: Double, clash: Bool) {
    let length = keys.reduce(0) { $0 + $1.dur }
    var tt = t.truncatingRemainder(dividingBy: length)
    if tt < 0 { tt += length }
    var prev = (a: start, dx: 0.0, dy: 0.0)
    for k in keys {
        if tt < k.dur {
            let f = tt / k.dur
            let e = k.fast ? 1 - pow(1 - f, 3) : f * f * (3 - 2 * f)
            return (prev.a + (k.a - prev.a) * e, prev.dx + (k.dx - prev.dx) * e, prev.dy + (k.dy - prev.dy) * e,
                    k.clash && (!k.fast || f > 0.8))
        }
        tt -= k.dur
        prev = (k.a, k.dx, k.dy)
    }
    return (start, 0, 0, false)
}

/// Solo practice kata. Angles in degrees, 0 = forward, -90 = straight up (y grows down).
/// The final key is the opening guard (-60) plus one full turn, so the loop is seamless.
private let kata: [Key] = [
    Key(a: -120, dx: -1, dy: 0, dur: 0.40, fast: false),   // wind up overhead
    Key(a: 40, dx: 1, dy: -2, dur: 0.13, fast: true),      // downward slash with a hop
    Key(a: 30, dx: 1, dy: 0, dur: 0.25, fast: false),      // follow through
    Key(a: -150, dx: -1, dy: -1, dur: 0.30, fast: true),   // rising backhand
    Key(a: -160, dx: -1, dy: 0, dur: 0.20, fast: false),   // high block
    Key(a: 0, dx: 2, dy: 0, dur: 0.14, fast: true),        // horizontal cut
    Key(a: 5, dx: 2, dy: 0, dur: 0.25, fast: false),       // thrust
    Key(a: 300, dx: 0, dy: -1, dur: 0.55, fast: false),    // full twirl
    Key(a: 300, dx: 0, dy: 0, dur: 0.35, fast: false),     // back to guard
]

/// Duel exchange. Both fighters run it in sync, mirrored, so their blades meet on the midline.
private let duel: [Key] = [
    Key(a: -125, dx: -1, dy: 0, dur: 0.35, fast: false),
    Key(a: -30, dx: 2, dy: 0, dur: 0.12, fast: true, clash: true),    // high strike
    Key(a: -32, dx: 2, dy: 0, dur: 0.30, fast: false, clash: true),   // bind
    Key(a: -140, dx: -1, dy: -1, dur: 0.35, fast: false),
    Key(a: 12, dx: 2, dy: 0, dur: 0.12, fast: true, clash: true),     // low strike
    Key(a: 14, dx: 2, dy: 0, dur: 0.28, fast: false, clash: true),    // bind
    Key(a: -95, dx: 0, dy: -2, dur: 0.25, fast: false),
    Key(a: -20, dx: 3, dy: 0, dur: 0.10, fast: true, clash: true),    // lunge
    Key(a: -20, dx: 3, dy: 0, dur: 0.22, fast: false, clash: true),
    Key(a: -70, dx: 0, dy: 0, dur: 0.35, fast: false),
]

func kataPose(_ t: Double) -> (angle: Double, dx: Double, dy: Double) {
    let p = play(kata, start: -60, t)
    return (p.angle, p.dx, p.dy)
}

func duelPose(_ t: Double) -> (angle: Double, dx: Double, dy: Double, clash: Bool) {
    play(duel, start: -70, t)
}

func swingTrail(_ t: Double, speed: Double = 1, pose: @escaping (Double) -> Double = { kataPose($0).angle }) -> [Double] {
    let now = pose(t * speed)
    let prev = pose((t - 0.035) * speed)
    guard abs(now - prev) > 6 else { return [] }   // only trail fast swings
    return [prev, pose((t - 0.07) * speed)]
}

// MARK: - Shared drawing helpers

struct Look {
    var body = clawdOrange
    var shade = clawdShade
    var leg = clawdOrange
    var arm = clawdOrange
    var eye: Px? = ink
    var legs = true
}

/// Legs are drawn without the body's breathing offset so a 1px bob never leaves a gap.
/// `step` alternates which pair of legs is lifted while walking (-1 = standing).
/// Set while drawing a seated character: legs fold forward onto the ground (the body is drawn 4 px lower).
var seatedPose = false

func drawLegs(_ c: PixelCanvas, _ look: Look, step: Int = -1) {
    guard look.legs else { return }
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, look.leg) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = step >= 0 && i % 2 == step
        c.rect(lx, 36, 2, lifted ? 7 : 8, look.leg)
    }
}

func drawBody(_ c: PixelCanvas, _ look: Look, armLeft: Int = 0, armRight: Int = 0) {
    c.rect(18, 26, 20, 12, look.body)
    c.rect(18, 37, 20, 1, look.shade)
    c.rect(37, 26, 1, 12, look.shade)
    c.rect(15, 33 - armLeft, 3, 3, look.arm)
    c.rect(38, 33 - armRight, 3, 3, look.arm)
    if let eye = look.eye {
        c.rect(22, 29, 2, 3, eye)
        c.rect(32, 29, 2, 3, eye)
    }
}

func drawBlade(_ c: PixelCanvas, t: Double, angle: Double, core: Px, glow: Px, lit: Bool,
               trail: [Double] = [], length: Double = 20, crossguard: Bool = false, unstable: Bool = false) {
    let hx = Sprite.hand.x, hy = Sprite.hand.y
    if lit {
        for (i, a) in trail.enumerated() {
            let r = a * .pi / 180
            c.glowLine(hx + cos(r) * 3, hy + sin(r) * 3, hx + cos(r) * (3 + length), hy + sin(r) * (3 + length),
                       core: glow, glow: glow, coreR: 0.5, glowR: 1.8, strength: 0.32 / Double(i + 1))
        }
    }
    let r = angle * .pi / 180
    let ux = cos(r), uy = sin(r)
    c.glowLine(hx - ux * 2, hy - uy * 2, hx + ux * 2.5, hy + uy * 2.5,
               core: C(0xB9BEC8), glow: C(0x000000, 0), coreR: 0.85, glowR: 0.9)
    c.px(Int(hx - ux * 0.5), Int(hy - uy * 0.5), C(0x2A2A2F))
    guard lit else { return }
    let flicker = unstable ? 0.75 + 0.25 * noise(Int(t * 30)) : 0.92 + 0.08 * sin(t * 40)
    c.glowLine(hx + ux * 3, hy + uy * 3, hx + ux * (3 + length), hy + uy * (3 + length),
               core: core, glow: glow, glowR: unstable ? 2.4 + noise(Int(t * 25)) : 2.4, strength: flicker)
    if crossguard {
        // A crossguard's quillons jut sideways from the hilt.
        let bx = hx + ux * 3.5, by = hy + uy * 3.5
        for side in [-1.0, 1.0] {
            c.glowLine(bx, by, bx - uy * 3.5 * side, by + ux * 3.5 * side,
                       core: core, glow: glow, coreR: 0.5, glowR: 1.6, strength: flicker)
        }
    }
}

/// Little blinking stars above the head of whoever is cheering.
func drawCheerSparkles(_ c: PixelCanvas, t: Double) {
    for i in 0..<3 {
        let f = (t * 1.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
        let x = 20 + i * 8 + Int(sin(f * 7 + Double(i)) * 2), y = 16 - Int(f * 12)
        let col = (i % 2 == 0 ? C(0xFFD25A) : C(0xFF7AC8)).alpha(1 - f)
        c.px(x, y, col); c.px(x - 1, y, col.alpha(0.5)); c.px(x + 1, y, col.alpha(0.5))
        c.px(x, y - 1, col.alpha(0.5)); c.px(x, y + 1, col.alpha(0.5))
    }
}

/// Hop height while cheering: bounces twice a second.
func cheerHop(_ t: Double) -> Int { sin(t * 2 * .pi * 2) > 0 ? -2 : 0 }


func walkStep(_ t: Double, _ walking: Bool) -> Int { walking ? Int(t * 8) % 2 : -1 }

func drawHood(_ c: PixelCanvas, _ main: Px, _ dark: Px) {
    c.pattern(15, 19, [
        ".......BBBBBBBBBBBB.......",
        ".....BBBBBBBBBBBBBBBB.....",
        "....BBBBbBBBBBBBBBbBBB....",
        "...BBBBBBBBBBBBBBBBBBBB...",
        "...BBBBBBBBBBBBBBBBBBBB...",
        "..BBBBBBBBBBBBBBBBBBBBBB..",
        "..BBBb..............bBBB..",
        ".BBBB................BBBB.",
        ".BBB..................BBB.",
        ".BBB..................BBB.",
        "BBBB..................BBBB",
        "BBB....................BBB",
        "BBB....................BBB",
    ], ["B": main, "b": dark])
}


/// A small pistol in the right hand; its muzzle is at (x + 7, y + 1).
func drawPistol(_ c: PixelCanvas, x: Int, y: Int, body: Px = C(0x2A2A30), trim: Px = C(0x8A8F9C)) {
    c.pattern(x, y, ["KKKKKKK", "KKTKKK.", "KK.....", "KK....."], ["K": body, "T": trim])
}
