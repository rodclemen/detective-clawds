import Foundation

// Heroes: the Green Lantern Corps and the Thanagarians, plus Adam Strange. Every one of them is Clawd in costume.
// The Lanterns share a uniform (green, black, the white emblem on the chest, the ring on the right hand) and tell
// themselves apart by hair, masks and attitude; their weapons are ring constructs: see-through green shapes with a
// bright rim, drawn by `construct`.

private let lanternMagic = Magic(core: C(0xD8FFD0), glow: C(0x2ADB4A), jagged: false)

let heroes4: [Companion: Persona] = [
    .johnStewart: Persona(name: "John Stewart", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xE8FFE0), glow: C(0x2ADB4A)),
                  muzzle: (50, 32), handGun: false, headTop: 23, signature: 3.2,
                  callout: "In brightest day, in blackest night…",
                  draw: drawJohnStewart),
    .guyGardner: Persona(name: "Guy Gardner", weapon: .melee, motion: .fly, headTop: 21, signature: 2.6,
                  callout: "Name's Guy Gardner. Remember it.",
                  draw: drawGuyGardner),
    .kyleRayner: Persona(name: "Kyle Rayner", weapon: .magic, motion: .fly, magic: lanternMagic, headTop: 20, signature: 3.4,
                  callout: "Let me sketch something.",
                  draw: drawKyleRayner),
    .jessicaCruz: Persona(name: "Jessica Cruz", weapon: .magic, motion: .fly, magic: lanternMagic, headTop: 21, signature: 2.8,
                  callout: "I can do this.",
                  draw: drawJessicaCruz),
    .simonBaz: Persona(name: "Simon Baz", weapon: .ranged, motion: .fly, shot: .bullet, muzzle: (47, 32), headTop: 22,
                  signature: 2.4,
                  draw: drawSimonBaz),
    .kilowog: Persona(name: "Kilowog", weapon: .melee, motion: .fly, pivot: kilowogShoulder, bulk: 5, headTop: 20, signature: 2.8,
                  callout: "Poozer!",
                  draw: drawKilowog),
    .tomarRe: Persona(name: "Tomar-Re", weapon: .magic, motion: .fly, magic: lanternMagic, headTop: 17, signature: 3.2,
                  draw: drawTomarRe),
    .chP: Persona(name: "Ch'p", weapon: .melee, motion: .fly, pivot: chpHand, headTop: 23, signature: 2.6,
                  draw: drawChP),
    .adamStrange: Persona(name: "Adam Strange", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xFFF0E0), glow: C(0xFF6A2A)),
                  muzzle: (51, 32), headTop: 18, signature: 3.0, callout: "Next stop, Rann.",
                  draw: drawAdamStrange),
    .hawkman: Persona(name: "Hawkman", weapon: .melee, motion: .fly, headTop: 17, signature: 2.8,
                  draw: drawHawkman),
    .hawkgirl: Persona(name: "Hawkgirl", weapon: .melee, motion: .fly, headTop: 17, signature: 2.8,
                  draw: drawHawkgirl),
]

// MARK: - The Corps' kit

private let clear = C(0x000000, 0)
private let glGreen = C(0x2E9E44), glGreenD = C(0x1E7432), glBlack = C(0x1E2026), glBlackD = C(0x121318)
private let ringCore = C(0xE8FFE0), ringGlow = C(0x2ADB4A)

/// Draws `shape` (any solid silhouette, drawn on a scratch canvas with the same offsets) as a ring construct: a
/// bright rim, a see-through green fill and a faint glow round the outside. Pixels drawn with a strong red channel
/// count as rim too, for lines inside the shape. Only columns left of `upTo` show (a construct being drawn).
private func construct(_ c: PixelCanvas, alpha: Double = 1, upTo: Int = 999, _ shape: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    shape(s)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    let limit = upTo + ox
    let rim = C(0xD4FFD6, 0.96 * alpha), fill = C(0x2ADB4A, 0.38 * alpha), halo = C(0x2ADB4A, 0.2 * alpha)
    for y in 0..<s.h {
        for x in 0..<min(s.w, limit) {
            let n = [s.isDrawn(x + 1, y), s.isDrawn(x - 1, y), s.isDrawn(x, y + 1), s.isDrawn(x, y - 1)]
            if s.isDrawn(x, y) {
                let line = s.buf[(y * s.w + x) * 4] > 128
                c.px(x, y, line || n.contains(false) ? rim : fill)
            } else if n.contains(true) {
                c.px(x, y, halo)
            }
        }
    }
}

/// Construct silhouettes are drawn in `shapeCol`; `lineCol` marks a rim line inside one.
private let shapeCol = C(0x00FF00), lineCol = C(0xFF0000)

/// The lantern emblem: a white disc with the green ring in it.
private func lanternEmblem(_ c: PixelCanvas, x: Int, y: Int, mark: Px = glGreenD) {
    c.pattern(x, y, [".WWWW.", "WWGGWW", "WGWWGW", "WWGGWW", ".WWWW."], ["W": C(0xF2F4F2), "G": mark])
}

/// The uniform across the chest (rows 33…37): `side` panels at the edges, `mid` down the middle, the emblem on it.
private func lanternChest(_ c: PixelCanvas, mid: Px, side: Px, emblem: Bool = true) {
    c.rect(18, 33, 20, 5, side)
    c.rect(21, 33, 14, 5, mid)
    c.rect(37, 33, 1, 5, glBlackD)
    if emblem { lanternEmblem(c, x: 25, y: 33) }
}

/// A gloved hand with the ring on it; `glow` (0…1) lights the ring up.
private func ringHand(_ c: PixelCanvas, x: Int, y: Int, glove: Px, glow: Double) {
    c.rect(x, y, 3, 3, glove)
    c.px(x + 2, y + 1, C(0x9CFFA8))
    if glow > 0 {
        c.glowLine(Double(x) + 2.5, Double(y) + 1.5, Double(x) + 2.5, Double(y) + 1.5, core: ringCore, glow: ringGlow,
                   coreR: 0.5, glowR: 1.2 + glow, strength: 0.6 + 0.4 * glow)
    }
}

/// A Lantern's legs: walking or standing on the ground, or held together and trailing in flight.
private func lanternLegs(_ c: PixelCanvas, _ p: Pose, leg: Px, boot: Px) {
    if p.flying {
        for lx in [21, 31] { c.rect(lx, 36, 3, 6, leg); c.rect(lx, 39, 3, 3, boot); c.rect(lx + 2, 36, 1, 3, glBlackD) }
        return
    }
    drawLegs(c, Look(leg: leg), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 3)
}

/// In flight: the ring fist thrust forward, blazing.
private func flightFist(_ c: PixelCanvas, glove: Px, t: Double) {
    c.rect(38, 31, 4, 3, glove)
    c.glowLine(42.5, 32, 42.5, 32, core: ringCore, glow: ringGlow, coreR: 0.8, glowR: 2.4, strength: 0.85 + 0.15 * sin(t * 30))
}

/// A green wake streaming out behind a flying Lantern.
private func emeraldTrail(_ c: PixelCanvas, t: Double) {
    for i in 0..<3 {
        let fi = Double(i)
        let y = 31 + fi * 3.5 + sin(t * 9 + fi * 2) * 0.7
        c.glowLine(3 + fi * 3, y + 1, 17, y, core: C(0xD8FFD0, 0.45), glow: C(0x2ADB4A, 0.4), coreR: 0.35, glowR: 1.3,
                   strength: 0.5 + 0.2 * noise(Int(t * 20) + i))
    }
}

/// A Lantern on the move: leant into the flight, the green wake behind.
private func lanternFlight(_ c: PixelCanvas, _ p: Pose, lean: Int = 4, _ art: @escaping (PixelCanvas, Pose) -> Void) -> Bool {
    guard p.flying else { return false }
    emeraldTrail(c, t: p.t)
    layer(c, lean: lean) { art($0, p) }
    return true
}

/// Two eyes lit green from within (John Stewart, and anyone the ring's power is pouring through).
private func glowingEyes(_ c: PixelCanvas, strength: Double = 1) {
    for x in [22, 32] {
        c.rect(x - 1, 28, 4, 5, C(0x2ADB4A, 0.3 * strength))
        c.rect(x, 29, 2, 3, C(0xB8FFB8))
        c.rect(x, 29, 2, 1, C(0xF0FFF0))
    }
}

/// A green spark of ring energy rising from the ring hand, `k` 0…1.
private func ringSparks(_ c: PixelCanvas, x: Double, y: Double, t: Double, count: Int = 4, spread: Double = 5) {
    for i in 0..<count {
        let f = frac(t * 1.3 + Double(i) / Double(count))
        let sx = x + (noise(i * 13 + Int(t * 1.3 + Double(i) / Double(count))) - 0.5) * spread * 2
        c.px(Int(sx.rounded()), Int((y - f * 10).rounded()), C(0xB8FFB8).alpha(1 - f))
    }
}

// MARK: - John Stewart

/// John Stewart: the architect and ex-marine, the Justice League's Lantern. A tight buzz cut, a stern brow, no mask,
/// just the eyes lit green by the ring; green shirt with black shoulders, black trousers, green boots and gloves. He
/// fights like a marine: the ring builds a rifle in his hands and he fires construct rounds from it. Signature: the
/// power battery appears before him, he holds the ring to it and recites the oath while the light pours in.
private func drawJohnStewart(_ c: PixelCanvas, _ p: Pose) {
    if lanternFlight(c, p, johnStewart) { return }
    johnStewart(c, p)
}

private func johnStewart(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x1C1816), hairL = C(0x3A322C)
    let charge = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    if charge > 0 { powerBattery(c, x: 43, y: 32, alpha: charge, light: charge > 0.95 ? 1 : 0, t: p.t) }
    lanternLegs(c, p, leg: glBlack, boot: glGreen)
    c.oy += p.breathe
    drawBody(c, Look(arm: glBlack, eye: nil))
    c.pattern(18, 24, [
        "..HHHhHHHHHHhHHHHH..",
        ".HhHHHHHhHHHHHHHhHH.",
        "HHHHHhHHHHHHhHHHHHHH",
        "HH................HH",
        "H..................H",
    ], ["H": hair, "h": hairL])
    c.rect(21, 28, 4, 1, clawdShade); c.rect(31, 28, 4, 1, clawdShade)   // a marine's frown
    glowingEyes(c, strength: 0.6 + 0.4 * charge)
    c.rect(26, 32, 4, 1, clawdShade)
    lanternChest(c, mid: glGreen, side: glBlack, emblem: false)
    c.rect(18, 33, 20, 1, glBlack)                                    // black across the shoulders
    lanternEmblem(c, x: 25, y: 33)
    c.rect(15, 33, 3, 3, glGreen)
    if p.flying { flightFist(c, glove: glGreen, t: p.t); return }
    if charge > 0 {
        // Arm out, ring to the battery's lens.
        let reach = Int((3 * charge).rounded())
        c.rect(38, 33, 2 + reach, 3, glBlack)
        ringHand(c, x: 39 + reach, y: 33, glove: glGreen, glow: charge)
        if charge > 0.95 { ringSparks(c, x: 28, y: 24, t: p.t, count: 6, spread: 10) }
        return
    }
    let armed = p.fire != nil || p.ready || p.gunLift != 0
    c.oy += p.gunY
    if armed {
        construct(c) { s in
            s.pattern(33, 31, [
                ".........XXXX....",
                "XXXXXXXXXXXXXXXXX",
                "XXXXXXXRXXXXXXXX.",
                "XXXXXXXXXXXXXX...",
                "......XXX........",
                "......XX.........",
            ], ["X": shapeCol, "R": lineCol])
        }
    }
    ringHand(c, x: 38, y: 33, glove: glGreen, glow: armed ? 1 : 0)
}

/// The green power battery, a lantern standing on the ground at (`x`, `y`) (its top), faded to `alpha`; `light`
/// sets its lens blazing.
private func powerBattery(_ c: PixelCanvas, x: Int, y: Int, alpha: Double, light: Double, t: Double) {
    let g = C(0x2E9E44).alpha(alpha), d = C(0x1A6A2C).alpha(alpha), l = C(0x6ADC7A).alpha(alpha)
    let lens = C(0xC8FFC8).alpha(alpha)
    c.pattern(x, y, [
        "..dGGd..",
        "..G..G..",
        ".dGGGGd.",
        "dGlGGGGd",
        ".dLLLLd.",
        ".dLLLLd.",
        ".dLLLLd.",
        ".dLLLLd.",
        "dGlGGGGd",
        ".dGGGGd.",
        "..dGGd..",
        ".dGGGGd.",
    ], ["G": g, "d": d, "l": l, "L": lens])
    if light > 0 {
        let flick = 0.8 + 0.2 * sin(t * 25)
        c.glowLine(Double(x) + 4, Double(y) + 6, Double(x) + 4, Double(y) + 6, core: ringCore, glow: ringGlow,
                   coreR: 1, glowR: 3, strength: flick * light * 0.45)
        for i in 0..<4 {
            let a = Double(i) * 0.8 - 1.2 + sin(t * 3) * 0.2
            c.glowLine(Double(x) + 4, Double(y) + 6, Double(x) + 4 + cos(a) * 9, Double(y) + 6 + sin(a) * 9,
                       core: C(0xD8FFD0, 0.5), glow: C(0x2ADB4A, 0.25), coreR: 0.3, glowR: 1, strength: light * flick)
        }
    }
}

// MARK: - Guy Gardner

/// Guy Gardner: the loudmouth. A red bowl cut down to his eyebrows, half-lidded eyes and a smirk; green shirt with a
/// black collar, black trousers. He fights with the ring's crudest constructs: a big green mallet. Signature: he cocks
/// his fist and a giant green boxing glove shoots out from the ring, punches the air and snaps back.
private func drawGuyGardner(_ c: PixelCanvas, _ p: Pose) {
    if lanternFlight(c, p, guyGardner) { return }
    guyGardner(c, p)
}

private func guyGardner(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xC8522A), hairD = C(0x9A3A1C), hairL = C(0xE07A44)
    lanternLegs(c, p, leg: glBlack, boot: glGreen)
    c.oy += p.breathe
    drawBody(c, Look(arm: glGreen, eye: nil))
    c.pattern(16, 21, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHlHHHHHHHHHH...",
        "..HHHHlHHHHHHHlHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHh",
        "HHHHHHHHHHHHHHHHHHHHHh",
        "HHHHHHHHHHHHHHHHHHHHHh",
        "hhhhhhhhhhhhhhhhhhhhhh",
        "HH..................hH",
        "HH..................hH",
        "Hh..................hH",
    ], ["H": hair, "h": hairD, "l": hairL])
    // Half-lidded, unimpressed, and the smirk.
    c.rect(22, 30, 2, 2, ink); c.rect(32, 30, 2, 2, ink)
    c.rect(22, 29, 2, 1, clawdShade); c.rect(32, 29, 2, 1, clawdShade)
    c.rect(28, 32, 4, 1, C(0x8A3A22)); c.px(32, 31, C(0x8A3A22))
    lanternChest(c, mid: glGreen, side: glGreen, emblem: false)
    c.pattern(18, 33, ["KKKKKK........KKKKKK", ".KKKK..........KKKK.", "..KK............KK.."], ["K": glBlack])
    lanternEmblem(c, x: 25, y: 33)
    c.rect(15, 33, 3, 3, glGreen)
    if p.flying { flightFist(c, glove: glGreen, t: p.t); return }
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { construct(c, alpha: 0.35 / Double(i + 1)) { guyMallet($0, angle: ta) } }
        construct(c) { guyMallet($0, angle: a) }
        ringHand(c, x: 38, y: 33, glove: glGreen, glow: 1)
        return
    }
    if let s = p.signature {
        // The glove: cocked back, then out like a piston and back.
        let wind = s < 0.25 ? habitArc(s / 0.25 * 0.5, hold: 0) : 0
        let out = s >= 0.25 ? habitArc((s - 0.25) / 0.75, hold: 0.35) : 0
        let reach = Int((14 * min(1, out * 1.6)).rounded())
        let hx = 38 - Int((2 * wind).rounded()) + min(reach, 3)
        if out > 0.02 {
            construct(c) { s in
                s.rect(hx + 2, 33, max(0, reach - 2), 3, shapeCol)                // the piston from the ring
                guyGlove(s, x: hx + reach, y: 27)
            }
        }
        ringHand(c, x: hx, y: 33, glove: glGreen, glow: max(wind, out))
        return
    }
    ringHand(c, x: 38, y: 33, glove: glGreen, glow: p.ready ? 1 : 0)
}

/// Guy's construct mallet in his fist at `angle`: a long handle and a big square head.
private func guyMallet(_ s: PixelCanvas, angle: Double) {
    prop(s, at: Sprite.hand, angle: angle) { m in
        m.rect(20, 20, 12, 2, shapeCol)
        m.rect(31, 15, 7, 12, shapeCol)
        m.rect(33, 15, 1, 12, lineCol)
    }
}

/// A giant boxing glove, its cuff's left edge at `x`, top at `y`.
private func guyGlove(_ s: PixelCanvas, x: Int, y: Int) {
    s.pattern(x, y - 1, [
        "..XXXXX.........",
        ".XXXXXXX........",
        "XXXXXXXXXXXXX...",
        "XXXXXXXXXXXXXXX.",
        "XRRRRRRRXXXXXXXX",
        "XXXXXXXXRXXXXXXX",
        "XXXXXXXXRXXXXXXX",
        "XXXXXXXXRXXXXXXX",
        "XXXXXXXXXXXXXXXX",
        "XXXXXXXXXXXXXXXX",
        ".XXXXXXXXXXXXXX.",
        "..XXXXXXXXXXXX..",
    ], ["X": shapeCol, "R": lineCol])
    s.rect(x - 4, y, 5, 11, shapeCol)                                    // the cuff
    s.rect(x, y, 1, 11, lineCol)
}

// MARK: - Kyle Rayner

/// Kyle Rayner: the artist Lantern. Shaggy dark hair, his own mask with fins sweeping up and back from the eyes,
/// a black suit with the green chest and his clawed emblem. He casts a steady green beam. Signature: he raises the
/// ring like a pen and draws a dragon in the air, line by line, then lets it fade.
private func drawKyleRayner(_ c: PixelCanvas, _ p: Pose) {
    if lanternFlight(c, p, kyleRayner) { return }
    kyleRayner(c, p)
}

private func kyleRayner(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x2A1E18), hairL = C(0x4A3628), mask = C(0x1A1C22), fin = C(0x2E9E44)
    lanternLegs(c, p, leg: glBlack, boot: glBlack)
    c.oy += p.breathe
    drawBody(c, Look(arm: glBlack, eye: nil))
    c.pattern(17, 20, [
        "......HHH.HHHHH.......",
        "....HHHHHHHHHHhHHH....",
        "..HHHHHHhHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHhHHHH.",
        "HHHHhHHHHHHHHHHHHHHHHH",
        "HHHHHHHHhhHHHHHhHHHHHH",
        "HHH.HHH...HH....HHHHHH",
        "HH.......H.........HHH",
    ], ["H": hair, "h": hairL])
    // The mask with its fins.
    c.pattern(14, 21, [
        "F........................F",
        "FF......................FF",
        ".FF....................FF.",
        ".fFF..................FFf.",
        "..fFF................FFf..",
        "...fFF..............FFf...",
        "....fFMMMMMMMMMMMMMMFf....",
        "....MMMMMMMMMMMMMMMMMM....",
        "....MMMMWWMMMMMMMMWWMM....",
        "....MMMMWKMMMMMMMMWKMM....",
        ".....MMMMMM.....MMMMM.....",
    ], ["F": fin, "f": glGreenD, "M": mask, "W": C(0xF2F4F2), "K": ink])
    c.rect(26, 32, 4, 1, clawdShade)
    lanternChest(c, mid: glGreen, side: glBlack, emblem: false)
    c.pattern(25, 33, ["W....W", "WW..WW", ".WWWW.", ".WKKW.", "..WW.."], ["W": C(0xF2F4F2), "K": glBlack])
    c.rect(15, 33, 3, 3, glBlack)
    if p.flying { flightFist(c, glove: glBlack, t: p.t); return }
    if let s = p.signature {
        // Ring up like a pen, the dragon drawn left to right, then held, then gone.
        let draw = min(1, max(0, (s - 0.1) / 0.5)), fade = s > 0.82 ? 1 - (s - 0.82) / 0.18 : 1
        let frontier = 42 + Int((20 * draw).rounded())
        if draw > 0 { construct(c, alpha: fade, upTo: frontier) { kyleDragon($0) } }
        let pen = (x: Double(min(frontier, 61)), y: 22 + sin(s * 40) * 3)
        let hand = s < 0.62 ? (x: 38 + (pen.x - 42) * 0.12, y: 27.0) : (x: 38.0, y: 28.0)
        c.rect(38, 31, 2, 3, glBlack)
        ringHand(c, x: Int(hand.x), y: Int(hand.y), glove: glBlack, glow: 1)
        if s > 0.1 && s < 0.6 {
            c.glowLine(hand.x + 2.5, hand.y + 1.5, pen.x, pen.y, core: C(0xD8FFD0, 0.7), glow: C(0x2ADB4A, 0.4),
                       coreR: 0.3, glowR: 1)
            c.glowLine(pen.x, pen.y, pen.x, pen.y, core: white, glow: ringGlow, coreR: 0.6, glowR: 1.8)
        }
        return
    }
    ringHand(c, x: 38, y: 33 - p.armRaise, glove: glBlack, glow: p.zap != nil ? 1 : 0)
}

/// Kyle's sketch: a dragon's head, jaws open, in front of him and above.
private func kyleDragon(_ s: PixelCanvas) {
    s.pattern(42, 12, [
        "...XX...............",
        "....XX..XX..........",
        ".....XXXXXX.........",
        "....XXXXXXXXXX......",
        "...XXXXRRXXXXXXXX...",
        "..XXXXXRRXXXXXXXXXXX",
        ".XXXXXXXXXXXXXXXXXXR",
        "XXXXXXXXXXXRXRXRXR..",
        "XXXXXXXXX...........",
        "XXXXXXXXXXR.R.R.....",
        "XXXXXXXXXXXXXXXXX...",
        ".XXXXXXXXXXXXXX.....",
        "..XXXXX.............",
        "..XXXX..............",
        "...XXX..............",
    ], ["X": shapeCol, "R": lineCol])
}

// MARK: - Jessica Cruz

/// Jessica Cruz: dark hair pulled back in a long ponytail, the green-and-black mask that frames her eyes, a green suit
/// with black sides. She casts a steady green beam. Signature: she takes a breath and a green bubble shield swells up
/// round her, holds, and pops in a shower of sparks.
private func drawJessicaCruz(_ c: PixelCanvas, _ p: Pose) {
    if lanternFlight(c, p, jessicaCruz) { return }
    jessicaCruz(c, p)
}

private func jessicaCruz(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x241A18), hairL = C(0x46342C), mask = C(0x1E7432)
    let sway = p.flying ? 2 : Int((sin(p.lt * 2.6) * 1.2).rounded())
    // The ponytail, behind her head, swinging.
    let sw = Double(sway)
    let tail: [(Double, Double)] = [(17, 23), (14, 25), (13 - sw * 0.4, 29), (13 - sw * 0.8, 33), (14 - sw, 36)]
    for i in 0..<tail.count - 1 {
        bar(c, tail[i].0, tail[i].1 + Double(p.breathe), tail[i + 1].0, tail[i + 1].1 + Double(p.breathe),
            i % 2 == 0 ? hair : hairL, 1.9 - Double(i) * 0.3)
    }
    c.rect(16, 22 + p.breathe, 3, 3, glGreen)                                // the band
    lanternLegs(c, p, leg: glBlack, boot: glGreen)
    c.oy += p.breathe
    drawBody(c, Look(arm: glGreen, eye: nil))
    c.pattern(17, 21, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHhHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHhHHHH..",
        ".HHHH...........HHHHH.",
        ".HHH.............HHHH.",
        ".HH...............HHH.",
    ], ["H": hair, "h": hairL])
    c.pattern(19, 28, ["..MMMMM....MMMMM..", ".MMWWMM....MMWWMMM", "MMMWWMMMMMMMMWWMM.", ".MMMMM......MMMM.."],
              ["M": mask, "W": C(0xF2F4F2)])
    c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)
    c.rect(27, 32, 3, 1, C(0xA84A3A))
    lanternChest(c, mid: glGreen, side: glBlack)
    c.rect(15, 33, 3, 3, glGreen)
    if p.flying { flightFist(c, glove: glGreen, t: p.t); return }
    if let s = p.signature {
        let k = habitArc(min(1, s / 0.88), hold: 0.5)
        c.rect(38, 30, 3, 3, glGreen); c.rect(15, 30, 3, 3, glGreen)       // both hands up
        ringHand(c, x: 38, y: 30, glove: glGreen, glow: 1)
        if s < 0.8 {
            let rx = Int((15 * k).rounded()), ry = Int((14 * k).rounded())
            if rx > 1 { construct(c, alpha: 0.7 + 0.3 * k) { $0.ellipse(28, 31, rx, ry, shapeCol) } }
        } else {
            let f = (s - 0.8) / 0.2                                          // pop
            for i in 0..<14 {
                let a = Double(i) / 14 * 2 * .pi
                let r = 14 + f * 5
                c.px(28 + Int((cos(a) * r).rounded()), 31 + Int((sin(a) * r * 0.95).rounded()), C(0xC8FFC8).alpha(1 - f))
            }
        }
        return
    }
    ringHand(c, x: 38, y: 33 - p.armRaise, glove: glGreen, glow: p.zap != nil ? 1 : 0)
}

// MARK: - Simon Baz

/// Simon Baz: the black balaclava under his mask, only the eyes showing, a green suit with black sides and a pistol
/// in his right hand alongside the ring on his left. Signature: he spins the pistol round his finger, twice, and
/// catches it.
private func drawSimonBaz(_ c: PixelCanvas, _ p: Pose) {
    if lanternFlight(c, p, simonBaz) { return }
    simonBaz(c, p)
}

private func simonBaz(_ c: PixelCanvas, _ p: Pose) {
    let hood = C(0x1A1B20), hoodL = C(0x34363E)
    lanternLegs(c, p, leg: glGreen, boot: glBlack)
    c.oy += p.breathe
    drawBody(c, Look(arm: glBlack, eye: nil))
    c.pattern(17, 22, [
        ".....KKKKKKKKKKKK.....",
        "...KKKKKKKKKKKKKKKK...",
        "..KKKKKkKKKKKKKKKKKK..",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KGGGGGGGKKKKGGGGGGGK.",
        ".KG.....GGGGGG.....GK.",
        ".KG.....GGGGGG.....GK.",
        ".KGGGGGGGKKKKGGGGGGGK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKkKKKKKKKKkKKKK.",
    ], ["K": hood, "k": hoodL, "G": glGreenD])
    c.rect(20, 29, 5, 2, clawdOrange); c.rect(31, 29, 5, 2, clawdOrange)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    lanternChest(c, mid: glGreen, side: glBlack)
    c.rect(18, 33, 20, 1, hood)
    lanternEmblem(c, x: 25, y: 33)
    ringHand(c, x: 15, y: 33, glove: glBlack, glow: p.ready || p.fire != nil ? 0.6 : 0)
    if p.flying { flightFist(c, glove: glBlack, t: p.t); return }
    if let s = p.signature, s > 0.08, s < 0.86 {
        let k = (s - 0.08) / 0.78
        let a = -720 * (0.5 - 0.5 * cos(k * .pi))
        let fast = sin(k * .pi)
        for i in 0..<12 where fast > 0.4 {                                // the blur of the spin
            let b = (a + Double(i) * 30) * .pi / 180
            c.px(Int((40.5 + cos(b) * 6).rounded(.down)), Int((33.5 + sin(b) * 6).rounded(.down)), C(0xC8CCD4, 0.35 * fast))
        }
        for i in 1...2 { prop(c, at: (40.5, 33.5), angle: a + Double(i) * 35, alpha: 0.4 / Double(i)) { simonPistol($0) } }
        prop(c, at: (40.5, 33.5), angle: a) { simonPistol($0) }
        c.rect(38, 33, 3, 3, glBlack)
        return
    }
    c.oy += p.gunY
    drawPistol(c, x: 40, y: 32)
    c.rect(38, 33, 3, 3, glBlack)
}

/// The pistol drawn for `prop`: its grip on the pivot.
private func simonPistol(_ s: PixelCanvas) {
    drawPistol(s, x: 19, y: 19)
}

// MARK: - Kilowog

private let kilowogShoulder = (x: 40.5, y: 28.5)

/// Kilowog: the Corps' drill sergeant from Bolovax Vik, a huge, broad, pink brute: bald, a heavy brow ridge, little
/// swept-back ears, a flat nose and a wide jaw, the uniform stretched over his barrel chest and thick legs. His right
/// arm swings from the shoulder with a green construct mallet in the fist. Signature: he points straight at you and
/// bellows "Poozer!".
private func drawKilowog(_ c: PixelCanvas, _ p: Pose) {
    if lanternFlight(c, p, lean: 5, kilowog) { return }
    kilowog(c, p)
}

private func kilowog(_ c: PixelCanvas, _ p: Pose) {
    let pink = C(0xDE9298), shade = C(0xBE747C), deep = C(0x9A5560)
    let yell = p.signature.map { $0 > 0.15 && $0 < 0.9 } ?? false
    // Thick legs.
    if p.flying {
        for lx in [17, 31] { c.rect(lx, 36, 6, 6, glBlack); c.rect(lx, 39, 6, 3, glGreen) }
    } else {
        for (i, lx) in [16, 21, 31, 36].enumerated() {
            if seatedPose { c.rect(lx - 1, 38, 5, 2, glBlack); continue }
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 3, lifted ? 7 : 8, glBlack)
            c.rect(lx, lifted ? 39 : 40, 3, 3, glGreen)
        }
    }
    c.oy += p.breathe
    if yell { c.ox += 1 }                                             // leaning into it
    // The left arm hangs at his side.
    c.rect(10, 26, 5, 8, glGreen); c.rect(10, 26, 1, 8, glGreenD)
    c.rect(9, 33, 6, 5, pink); c.rect(9, 37, 6, 1, shade)
    // The big body and head.
    c.rect(15, 22, 26, 16, pink)
    c.rect(40, 22, 1, 16, shade)
    c.pattern(15, 20, [
        ".....PPPPPPPPPPPPPPP......",
        "...PPPPPPPPPPPPPPPPPPPP...",
    ], ["P": pink])
    c.rect(17, 21, 3, 1, C(0xF0B8BC))                                // a shine on the dome
    c.pattern(12, 24, ["PP.", ".PPP", "..PP"], ["P": shade])          // ears, swept back
    c.pattern(41, 24, [".PP", "PPP.", "PP.."], ["P": shade])
    c.pattern(17, 25, [
        "dddddddddddddddddddddd",
        ".dddddd.......dddddd..",
        "..KKKW.........KKKW...",
        "..KKKK.........KKKK...",
        "..........ss..........",
        ".........ssss.........",
    ], ["d": deep, "K": ink, "W": white, "s": shade])
    if yell {
        c.pattern(21, 30, ["DDDDDDDDDDDDDD", "DWWWWWWWWWWWWD", "DrrrrrrrrrrrrD", "DrrWrrrrrrWrrD"],
                  ["D": deep, "W": C(0xF2F0E0), "r": C(0x5A1E26)])
        c.rect(17, 26, 22, 1, deep)                                   // brow down hard
    } else {
        c.pattern(21, 31, ["DDDDDDDDDDDDDD", ".W.DDDDDDDD.W.", "..ssssssssss.."], ["D": deep, "W": C(0xF2F0E0), "s": shade])
    }
    // The uniform over the barrel chest.
    c.rect(15, 34, 26, 4, glBlack)
    c.rect(19, 34, 18, 4, glGreen)
    c.rect(15, 37, 26, 1, glBlackD)
    lanternEmblem(c, x: 25, y: 33)
    if p.flying {
        prop(c, at: kilowogShoulder, angle: -8) { kilowogArm($0) }
        c.glowLine(52, 27.5, 52, 27.5, core: ringCore, glow: ringGlow, coreR: 1, glowR: 3)
        return
    }
    if yell {
        // Arm out straight, one big finger pointed at the poozer in question.
        prop(c, at: kilowogShoulder, angle: -4) { kilowogArm($0, point: true) }
        let k = Int(p.lt * 12) % 3
        for i in 0..<3 where (i + k) % 3 != 0 {
            let r = 6 + i * 3
            for d in -1...1 { c.px(40 + r, 32 + d * (1 + i), C(0xFFFFFF, 0.7)) }
        }
        return
    }
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { construct(c, alpha: 0.3 / Double(i + 1)) { kilowogMallet($0, angle: ta) } }
        construct(c) { kilowogMallet($0, angle: a) }
        prop(c, at: kilowogShoulder, angle: a) { kilowogArm($0) }
        return
    }
    prop(c, at: kilowogShoulder, angle: 82) { kilowogArm($0) }
}

/// Kilowog's right arm, swung from the shoulder: bare pink upper arm, green glove, the ring.
private func kilowogArm(_ s: PixelCanvas, point: Bool = false) {
    let pink = C(0xDE9298)
    s.rect(18, 18, 7, 5, glGreen); s.rect(18, 22, 7, 1, glGreenD)
    s.rect(25, 18, 3, 5, pink)
    s.rect(28, 17, 5, 7, glGreen); s.rect(28, 23, 5, 1, glGreenD)
    s.px(31, 19, C(0x9CFFA8))
    if point { s.rect(33, 18, 4, 2, glGreen); s.rect(33, 19, 4, 1, glGreenD) }
}

/// The construct mallet in Kilowog's fist: a short haft and a head the size of a crate.
private func kilowogMallet(_ s: PixelCanvas, angle: Double) {
    prop(s, at: kilowogShoulder, angle: angle) { m in
        m.rect(27, 16, 6, 9, shapeCol)                                 // round the fist
        m.rect(33, 18, 2, 5, shapeCol)
        m.rect(35, 9, 6, 23, shapeCol)
        m.rect(37, 9, 1, 23, lineCol)
    }
}

// MARK: - Tomar-Re

/// Tomar-Re of Xudar: a bird-headed Lantern. A crest of red feathers over a long, hooked yellow beak, round eyes in
/// pale rings, the uniform below. He casts a steady green beam. Signature: the scholar's trick: he holds up a little
/// construct star with a planet circling it, studying it as his crest fans up.
private func drawTomarRe(_ c: PixelCanvas, _ p: Pose) {
    if lanternFlight(c, p, tomarRe) { return }
    tomarRe(c, p)
}

private func tomarRe(_ c: PixelCanvas, _ p: Pose) {
    let crest = C(0xB8302A), crestD = C(0x82201C), crestL = C(0xE85A3A), beak = C(0xE8C24A), beakD = C(0xB08A2A)
    let study = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    lanternLegs(c, p, leg: glBlack, boot: glGreen)
    c.oy += p.breathe
    drawBody(c, Look(arm: glBlack, eye: nil))
    // The crest: swept back at rest, fanned up when he's interested.
    let up = Int((5 * study).rounded())
    for (i, x) in [18, 21, 24, 27, 30].enumerated() where up > 0 {      // the crest fanning up
        let h = up + (i == 2 ? 1 : 0) - abs(i - 2)
        if h > 0 { c.rect(x, 17 - h, 2, h, i % 2 == 0 ? crestL : crest) }
    }
    c.pattern(16, 17, [
        "....CC.CC.CC",
        "..CCcCCcCCcC..",
        ".CCCCCCCCCCCCC",
        "CCcCCcCCcCCcCC",
    ], ["C": crestL, "c": crest])
    c.pattern(17, 21, [
        "...cccccccccccc.....",
        ".ccccccccccccccccc..",
        "cccccDccccccDccccccc",
        "cccccccccccccccccccc",
        "cDcccccccccccccccDcc",
    ], ["c": crest, "D": crestD])
    // Eyes in pale rings, and the beak, long and hooked.
    c.pattern(21, 28, [".WW.......WW..", "WKKW.....WKKW.", "WKKW.....WKKW.", ".WW.......WW.."],
              ["W": C(0xF4E8C8), "K": ink])
    c.pattern(27, 29, [
        "BBBBBBBBBBBBB....",
        ".BBBBBBBBBBBBBBB.",
        "..bbbbbbbbbbbBBBB",
        ".......bbbbbbbbB.",
        "...............b.",
    ], ["B": beak, "b": beakD])
    lanternChest(c, mid: glGreen, side: glBlack)
    c.rect(15, 33, 3, 3, glGreen)
    if p.flying { flightFist(c, glove: glGreen, t: p.t); return }
    if study > 0 {
        let y = 33 - Int((8 * study).rounded())
        c.rect(38, y + 2, 2, 33 - y, glBlack)
        ringHand(c, x: 38, y: y, glove: glGreen, glow: study)
        if study > 0.6 {
            let cx = 41.5, cy = Double(y) - 6
            construct(c, alpha: study) { $0.circle(41, y - 6, 3, shapeCol) }
            let a = p.t * 4
            for k in 0..<10 {                                       // the orbit
                let b = Double(k) / 10 * 2 * .pi
                c.px(Int((cx + cos(b) * 8).rounded(.down)), Int((cy + sin(b) * 3).rounded(.down)), C(0x9CFFA8, 0.6 * study))
            }
            c.glowLine(cx + cos(a) * 8, cy + sin(a) * 3, cx + cos(a) * 8, cy + sin(a) * 3, core: ringCore, glow: ringGlow,
                       coreR: 0.6, glowR: 1.4)
        }
        return
    }
    ringHand(c, x: 38, y: 33 - p.armRaise, glove: glGreen, glow: p.zap != nil ? 1 : 0)
}

// MARK: - Ch'p

private let chpHand = (x: 37.5, y: 37.5)

/// Ch'p of H'lven: a squirrel Lantern, a head shorter than Clawd: brown fur, tufted ears, a big bushy tail curled up
/// behind, buck teeth, a tiny mask and uniform. He fights with a construct acorn on a stick. Signature: he pulls out a
/// real acorn and nibbles it, very fast, tail twitching.
private func drawChP(_ c: PixelCanvas, _ p: Pose) {
    if lanternFlight(c, p, lean: 5, chP) { return }
    chP(c, p)
}

private func chP(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x9A5E34), furD = C(0x6E3E20), furL = C(0xC88A5A), pale = C(0xEAD2AE)
    if seatedPose { c.oy -= 2 }
    let nibble = p.signature.map { $0 > 0.12 && $0 < 0.9 } ?? false
    let flick = nibble ? (Int(p.lt * 10) % 2 == 0 ? -1.0 : 1.0) : 0
    // The tail, a big curl behind him.
    let tail: [(Double, Double)] = [(23, 39), (18, 37), (14, 32), (13, 26), (15 + flick, 21), (19 + flick, 19)]
    for i in 0..<tail.count - 1 {
        bar(c, tail[i].0, tail[i].1, tail[i + 1].0, tail[i + 1].1, furL, 3)
    }
    for i in 0..<tail.count - 1 {
        bar(c, tail[i].0, tail[i].1, tail[i + 1].0, tail[i + 1].1, i % 2 == 0 ? fur : furD, 1.8)
    }
    // Little legs.
    if p.flying {
        for lx in [25, 31] { c.rect(lx, 40, 3, 3, glBlack) }
    } else if seatedPose {
        for lx in [24, 27, 30, 33] { c.rect(lx - 1, 41, 3, 2, fur) }
    } else {
        for (i, lx) in [24, 27, 30, 33].enumerated() {
            c.rect(lx, 40, 2, p.step >= 0 && i % 2 == p.step ? 3 : 4, i < 2 ? furD : fur)
        }
    }
    c.oy += p.breathe
    // Ears, head and body in one, like Clawd.
    c.pattern(23, 26, ["XX........XX", "XiX......XiX", "XiX......XiX", "XXX......XXX"], ["X": fur, "i": C(0xE0A0A0)])
    c.rect(23, 30, 12, 11, fur); c.rect(34, 30, 1, 11, furD)
    c.pattern(23, 32, [".MMMMMMMMMM.", "MMWKMMMMWKMM", "MMKKMMMMKKMM", ".MM......MM."], ["M": glGreenD, "W": white, "K": ink])
    c.rect(26, 36, 6, 2, pale)
    c.rect(28, 35, 2, 1, ink)                                                // nose
    let chew = nibble && Int(p.lt * 16) % 2 == 0
    c.rect(28, 37, 2, chew ? 1 : 2, white)                                     // buck teeth
    if nibble { c.rect(24, 36, 2, 2, furL); c.rect(32, 36, 2, 2, furL) }      // cheeks full
    c.rect(23, 38, 12, 3, glGreen); c.rect(23, 38, 2, 3, glBlack); c.rect(33, 38, 2, 3, glBlack)
    c.pattern(27, 38, [".WW.", "WGGW", ".WW."], ["W": C(0xF2F4F2), "G": glGreenD])
    c.rect(21, 37, 2, 2, fur)
    if p.flying {
        c.rect(35, 35, 3, 2, fur)
        c.glowLine(38, 36, 38, 36, core: ringCore, glow: ringGlow, coreR: 0.6, glowR: 2)
        return
    }
    if nibble {
        // Both paws up at the mouth, round the acorn.
        let y = 34 + (chew ? 1 : 0)
        c.pattern(27, y, ["..k..", ".ccc.", "ccccc", "aaaaa", ".aaa.", "..a.."], ["k": C(0x4A2E18), "c": C(0x4A2E18), "a": C(0xE8A858)])
        c.rect(24, 37, 2, 2, fur); c.rect(31, 37, 2, 2, fur)
        if chew { c.px(25 + Int(noise(Int(p.lt * 16)) * 8), 40, C(0xB8864A)) }
        return
    }
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { construct(c, alpha: 0.3 / Double(i + 1)) { chpAcorn($0, angle: ta) } }
        construct(c) { chpAcorn($0, angle: a) }
    }
    c.rect(35, 37, 2, 2, fur)
    c.px(36, 37, C(0x9CFFA8))
    if p.melee != nil || p.ready { c.glowLine(36.5, 37.5, 36.5, 37.5, core: ringCore, glow: ringGlow, coreR: 0.4, glowR: 1.4) }
}

/// Ch'p's construct: an acorn on a stick, big as his head.
private func chpAcorn(_ s: PixelCanvas, angle: Double) {
    prop(s, at: chpHand, angle: angle) { m in
        m.rect(20, 20, 6, 1, shapeCol)
        m.pattern(26, 16, [".XXXXX.", "XXXXXXX", "RRRRRRR", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..."],
                  ["X": shapeCol, "R": lineCol])
    }
}

// MARK: - Adam Strange

/// Adam Strange: the Earthman of Rann. The red flight suit with the white circle on the chest, the red helmet with its
/// white fins, a silver jetpack on his back and a ray gun. In flight the jetpack burns. Signature: the Zeta-beam takes
/// him: a column of white light, he shimmers away to nothing, and comes back.
private func drawAdamStrange(_ c: PixelCanvas, _ p: Pose) {
    if p.flying { layer(c, lean: 4) { adamStrange($0, p) }; return }
    guard let s = p.signature, s > 0.06, s < 0.94 else { adamStrange(c, p); return }
    // Zeta-beam: a dissolve to nothing and back, inside a column of light.
    let gone = s < 0.4 ? (s - 0.06) / 0.34 : s > 0.6 ? 1 - (s - 0.6) / 0.34 : 1
    var q = p
    q.signature = nil
    let o = offscreen { adamStrange($0, q) }
    let scan = Int(p.t * 30)
    for y in 0..<o.h {
        let band = (y + scan) % 4 == 0
        for x in 0..<o.w {
            guard let col = colour(o, x, y) else { continue }
            // Washed out to white, the light running up him in bands, then faded away.
            let w = min(1, gone * 1.6 + (band ? 0.25 : 0))
            let mix = Px(r: UInt8(Double(col.r) + (255 - Double(col.r)) * w), g: UInt8(Double(col.g) + (255 - Double(col.g)) * w),
                         b: UInt8(Double(col.b) + (255 - Double(col.b)) * w), a: col.a)
            c.px(x, y, mix.alpha(max(0, 1 - gone * 1.15)))
        }
    }
    let beam = sin(min(1, s / 0.94) * .pi)
    for x in 16...40 {
        let edge = min(Double(x - 16), Double(40 - x)) / 6
        let a = min(1, edge) * 0.22 * beam * (0.8 + 0.2 * noise(x + Int(p.t * 20)))
        c.rect(x, 0, 1, 44, C(0xDDEBFF, a))
    }
    for i in 0..<8 {
        let f = frac(p.t * 1.5 + Double(i) / 8)
        c.px(18 + Int(noise(i * 7) * 20), 44 - Int(f * 44), C(0xFFFFFF, beam * (1 - f)))
    }
}

private func adamStrange(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8262A), redD = C(0x8A161C), wht = C(0xEEF0F4), silver = C(0xB4BAC4), silverD = C(0x7E8590)
    // The jetpack on his back.
    let jy = 26 + p.breathe
    c.rect(12, jy, 7, 11, silver); c.rect(12, jy, 1, 11, silverD); c.rect(15, jy, 1, 11, silverD)
    c.rect(12, jy + 3, 7, 1, silverD); c.rect(12, jy + 8, 7, 1, silverD)
    c.rect(13, jy + 11, 2, 1, C(0x4A4E58)); c.rect(16, jy + 11, 2, 1, C(0x4A4E58))
    if p.flying || (p.ready && p.urgent) {
        drawJet(c, x: 13, y: jy + 12, w: 2, t: p.t, seed: 3); drawJet(c, x: 16, y: jy + 12, w: 2, t: p.t, seed: 9)
    }
    if p.flying {
        for lx in [21, 31] { c.rect(lx, 36, 3, 6, red); c.rect(lx, 39, 3, 3, wht); c.rect(lx + 2, 36, 1, 3, redD) }
    } else {
        drawLegs(c, Look(leg: red), step: p.step)
        drawBoots(c, wht, step: p.step, rows: 2)
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: red, eye: ink))
    c.pattern(15, 18, [
        "W......................W",
        "WW.....RRRRRRRRRR.....WW",
        ".WW..RRRRRRRWRRRRRR..WW.",
        ".WWWRRRRRRRRWRRRRRRRWWW.",
        "..WWRRRRRRRRWRRRRRRRWW..",
        "...WRRRRRRRRWRRRRRRRRW..",
        "...RRRRRRRRRWRRRRRRRRR..",
        "...RRRRRRRRRRRRRRRRRRR..",
        "...RRRRRRRRRRRRRRRRRRr..",
        "...rr..............rr...",
        "...rr..............rr...",
        "...rr..............rr...",
    ], ["R": red, "r": redD, "W": wht])
    c.rect(20, 19, 3, 1, C(0xF07A7A))                                    // shine
    c.rect(26, 32, 4, 1, clawdShade)
    c.rect(18, 33, 20, 5, red); c.rect(37, 33, 1, 5, redD); c.rect(18, 37, 20, 1, redD)
    c.pattern(25, 33, [".WWWW.", "WRRRRW", "WRWWRW", "WRRRRW", ".WWWW."], ["W": wht, "R": red])
    c.rect(15, 33, 3, 3, red)
    if p.flying {
        c.rect(38, 31, 4, 3, red)
        drawRayGun(c, x: 41, y: 30)
        return
    }
    c.oy += p.gunY
    drawRayGun(c, x: 39, y: 31)
    c.rect(38, 33, 3, 3, red)
}

/// Adam's ray gun: a silver barrel with rings, a red fin on top and an orange glowing tip at (`x` + 11, `y` + 1).
private func drawRayGun(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "...RR.......",
        "SSSSSSSSKSKO",
        ".SSSSSSSKSK.",
        ".GG.........",
        ".GG.........",
    ], ["S": C(0xC8CCD4), "K": C(0x6A707C), "R": C(0xC8262A), "G": C(0x3A3C44), "O": C(0xFF9A3A)])
}

// MARK: - Hawkman

/// Hawkman (Carter Hall): the golden hawk helmet with its beak down between the eyes and feathered flares at the
/// sides, bare chest under a red leather harness, green trousers and the great brown wings folded down his back;
/// an Nth metal mace. Flying, the wings spread wide and beat. Signature: he spreads his wings and beats them, rising
/// off the ground, and settles again.
private func drawHawkman(_ c: PixelCanvas, _ p: Pose) {
    if p.flying { tilted(c, 16) { hawkman($0, p, spread: 1) }; return }
    hawkman(c, p, spread: p.signature.map { habitArc($0, hold: 0.6) } ?? 0)
}

private func hawkman(_ c: PixelCanvas, _ p: Pose, spread: Double) {
    let gold = C(0xD8A830), goldD = C(0xA07A1C), goldL = C(0xF4D470), green = C(0x2E6A38), greenD = C(0x1E4A26)
    let strap = C(0x8A2A1E), boot = C(0x6A3A1E)
    let wing = (main: C(0x8A6444), dark: C(0x6A4A30), tip: C(0xD8C8A8))
    let beat = spread > 0.9 ? sin(p.lt * 14) : 0
    let rise = p.signature != nil ? Int((-4 * spread).rounded()) - (beat > 0.3 ? 1 : 0) : 0
    c.oy += rise
    hawkWing(c, spread: spread, flap: beat, far: true, lift: p.breathe, cols: wing)
    if p.flying {
        for lx in [21, 31] { c.rect(lx, 36, 3, 6, green); c.rect(lx, 39, 3, 3, boot) }
    } else if rise < 0 {
        for lx in [20, 24, 31, 35] { c.rect(lx, 36, 2, 6, green); c.rect(lx, 40, 2, 2, boot) }   // toes pointed, off the ground
    } else {
        drawLegs(c, Look(leg: green), step: p.step)
        drawBoots(c, boot, step: p.step, rows: 3)
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: clawdOrange, eye: ink))
    hawkHelmet(c, gold: gold, dark: goldD, light: goldL)
    // Harness across the bare chest, the belt, the trousers' top.
    c.rect(18, 36, 20, 2, green); c.rect(18, 37, 20, 1, greenD)
    c.rect(18, 35, 20, 1, strap)
    bar(c, 20, 32.5, 35, 35, strap, 0.6); bar(c, 35, 32.5, 20, 35, strap, 0.6)
    c.rect(27, 33, 2, 2, gold)
    hawkWing(c, spread: spread, flap: beat, far: false, lift: p.breathe, cols: wing)
    c.rect(15, 33, 3, 3, clawdOrange)
    hawkMaceInHand(c, p, head: C(0x8A8070), light: C(0xC8BC9C), dark: C(0x5A5446), crackle: false)
}

// MARK: - Hawkgirl

/// Hawkgirl (Shayera Hol): the golden hawk mask over a mane of red hair, a green top with the gold belt and straps,
/// grey wings with pale tips folded down her back; the Nth metal mace, which crackles with energy when she swings
/// it. Signature: she raises the mace high and it charges up, lightning crawling over the head.
private func drawHawkgirl(_ c: PixelCanvas, _ p: Pose) {
    if p.flying { tilted(c, 16) { hawkgirl($0, p, spread: 1) }; return }
    hawkgirl(c, p, spread: 0)
}

private func hawkgirl(_ c: PixelCanvas, _ p: Pose, spread: Double) {
    let gold = C(0xE0B438), goldD = C(0xA8821E), goldL = C(0xF8DC78), green = C(0x2E7A44), greenD = C(0x1E5430)
    let hair = C(0xC03A22), hairD = C(0x8A2614)
    let wing = (main: C(0x8E949E), dark: C(0x6A707A), tip: C(0xE8ECF0))
    let beat = spread > 0.9 ? sin(p.lt * 14) : 0
    hawkWing(c, spread: spread, flap: beat, far: true, lift: p.breathe, cols: wing)
    // The hair, falling down her back behind the near wing.
    c.pattern(14, 22 + p.breathe, [
        "..HHHH",
        ".HHHHH",
        "HHHhHH",
        "HHhHHH",
        "HHHHhH",
        "HhHHHH",
        "HHHHH.",
        "HHhHH.",
        "HHHH..",
        ".HhH..",
        ".HH...",
        "..H...",
    ], ["H": hair, "h": hairD])
    if p.flying {
        for lx in [21, 31] { c.rect(lx, 36, 3, 6, greenD); c.rect(lx, 39, 3, 3, gold) }
    } else {
        drawLegs(c, Look(leg: greenD), step: p.step)
        drawBoots(c, gold, step: p.step, rows: 3)
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: clawdOrange, eye: ink))
    c.pattern(15, 22, ["..HH", ".HHH", "HHHH", "HHH.", "HHH.", "HH.."], ["H": hair])
    c.pattern(36, 24, ["HH", "HHH", "HHH", "HH", "H"], ["H": hair])
    hawkHelmet(c, gold: gold, dark: goldD, light: goldL)
    c.rect(26, 32, 4, 1, C(0xB84A3A))
    c.rect(18, 33, 20, 5, green); c.rect(37, 33, 1, 5, greenD)
    c.rect(18, 36, 20, 1, gold); c.rect(18, 37, 20, 1, greenD)
    c.pattern(22, 33, ["G..........G", ".G........G.", "..GG....GG.."], ["G": gold])
    hawkWing(c, spread: spread, flap: beat, far: false, lift: p.breathe, cols: wing)
    c.rect(15, 33, 3, 3, clawdOrange)
    if let s = p.signature, s > 0.08, s < 0.94 {
        let k = habitArc((s - 0.08) / 0.86, hold: 0.6)
        let a = 90 - 180 * k                                          // from hanging down, up overhead
        c.rect(38, 33 - Int((3 * k).rounded()), 3, 3, clawdOrange)
        let hand = (x: 40.5, y: 34.5 - 3 * k)
        prop(c, at: hand, angle: a) { hawkMace($0, head: C(0x7A808C), light: C(0xC8D0DC), dark: C(0x4A4E58)) }
        if k > 0.9 {
            let r = a * .pi / 180
            let hx = hand.x + cos(r) * 11, hy = hand.y + sin(r) * 11
            drawMaceCrackle(c, x: hx, y: hy, t: p.t, size: 6)
        }
        return
    }
    hawkMaceInHand(c, p, head: C(0x7A808C), light: C(0xC8D0DC), dark: C(0x4A4E58), crackle: true)
}

// MARK: - Thanagarian kit

/// The hawk helmet, face on: a gold dome with feathered flares at the sides and the beak coming down between the eyes.
private func hawkHelmet(_ c: PixelCanvas, gold: Px, dark: Px, light: Px) {
    c.pattern(13, 17, [
        "F........................F",
        "FF.......GGGGGGGG.......FF",
        ".FF....GGGGGGGGGGGG....FF.",
        ".FFF.GGGGLLGGGGGGGGGG.FFF.",
        "..FFFGGGGGGGGGGGGGGGGFFF..",
        "..FFFGGGGGGGGGGGGGGGGGFF..",
        "...FFGGGGGGGGGGGGGGGGGFF..",
        "...FFGGGGGGGGGGGGGGGGGF...",
        "....FGGGGGGGGGGGGGGGGGF...",
        ".....GGGGGGGGGGGGGGGGGG...",
        ".....GGddGGGGGGGGGGddGG...",
        ".....GG..dGGGGGGGGd..GG...",
        ".....GG....dGGGGd....Gd...",
        ".....Gd......dd......d....",
        ".....d....................",
    ], ["G": gold, "d": dark, "L": light, "F": dark])
    // The beak's hooked tip over the mouth.
    c.pattern(26, 30, ["dd", "Gd", ".d"], ["G": gold, "d": dark])
}

/// One wing, as seven long feathers fanned from the shoulder: folded down the back (`spread` 0) or swept up and out
/// behind (1), `flap` (-1…1) beating it. The far wing is darker and sits a little higher.
private func hawkWing(_ c: PixelCanvas, spread k: Double, flap: Double, far: Bool,
                      lift: Int, cols: (main: Px, dark: Px, tip: Px)) {
    let root = far ? (x: 21.0, y: 25.0 + Double(lift)) : (x: 19.0, y: 26.0 + Double(lift))
    let dim = far ? 0.75 : 1.0
    for i in 0..<7 {
        let fi = Double(i)
        let folded: Double = 108 + fi * 4.5
        let open: Double = (far ? 214 : 200) + fi * 8 - flap * 22
        let a = (folded + (open - folded) * k) * .pi / 180
        let len = 14 + k * (far ? 6 : 9) - fi * k * 1.2 - (1 - k) * fi * 0.5
        let tip = (x: root.x + cos(a) * len, y: root.y + sin(a) * len)
        let col = i % 2 == 0 ? cols.main : cols.dark
        bar(c, root.x, root.y, tip.x, tip.y, Px(r: UInt8(Double(col.r) * dim), g: UInt8(Double(col.g) * dim),
                                                 b: UInt8(Double(col.b) * dim), a: 255), 1.0)
        let tipStart = (x: root.x + cos(a) * (len - 3), y: root.y + sin(a) * (len - 3))
        bar(c, tipStart.x, tipStart.y, tip.x, tip.y, cols.tip.alpha(far ? 0.7 : 1), 0.8)
    }
}

/// The mace in the right hand: swung at `p.melee`, or hanging head-down at his side.
private func hawkMaceInHand(_ c: PixelCanvas, _ p: Pose, head: Px, light: Px, dark: Px, crackle: Bool) {
    if p.flying {
        c.rect(38, 31, 4, 3, clawdOrange)
        prop(c, at: (40.5, 32.5), angle: -20) { hawkMace($0, head: head, light: light, dark: dark) }
        return
    }
    c.rect(38, 33, 3, 3, clawdOrange)
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            prop(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) { hawkMace($0, head: head, light: light, dark: dark) }
        }
        prop(c, at: Sprite.hand, angle: a) { hawkMace($0, head: head, light: light, dark: dark) }
        if crackle && !p.trail.isEmpty {
            let r = a * .pi / 180
            drawMaceCrackle(c, x: Sprite.hand.x + cos(r) * 11, y: Sprite.hand.y + sin(r) * 11, t: p.t, size: 4)
        }
        return
    }
    prop(c, at: (40.5, seatedPose ? 31.5 : 34.5), angle: seatedPose ? 20 : 80) { hawkMace($0, head: head, light: light, dark: dark) }
}

/// The Nth metal mace for `prop`: a wrapped haft and a flanged, spiked head.
private func hawkMace(_ s: PixelCanvas, head: Px, light: Px, dark: Px) {
    let haft = C(0x5A3A22)
    s.rect(18, 20, 9, 1, haft); s.rect(18, 21, 9, 1, C(0x3E2816))
    for x in [19, 21] { s.px(x, 20, C(0x8A6A4A)) }
    s.pattern(27, 17, [
        "..S.S..",
        ".HHHHH.",
        "SHLHHHS",
        "HHHHHHd",
        "SHHHHdS",
        ".HdddH.",
        "..S.S..",
    ], ["H": head, "L": light, "d": dark, "S": light])
}

/// Yellow-white energy crawling over the mace head at (`x`, `y`).
private func drawMaceCrackle(_ c: PixelCanvas, x: Double, y: Double, t: Double, size: Double) {
    let seed = Int(t * 24)
    for b in 0..<3 {
        var prev = (x: x, y: y)
        for i in 1...3 {
            let a = noise(seed * 7 + b * 13 + i) * 2 * .pi
            let next = (x: prev.x + cos(a) * size / 2.5, y: prev.y + sin(a) * size / 2.5)
            c.glowLine(prev.x, prev.y, next.x, next.y, core: C(0xFFFCE0), glow: C(0xFFC83A), coreR: 0.4, glowR: 1.3,
                       strength: 0.9 - Double(i) * 0.15)
            prev = next
        }
    }
}

// MARK: - Shared helpers

private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A flickering jet flame pointing down from (`x`, `y`), `w` wide.
private func drawJet(_ c: PixelCanvas, x: Int, y: Int, w: Int, t: Double, seed: Int) {
    let len = 2 + Int(noise(Int(t * 30) + seed) * 3)
    c.rect(x, y, w, len + 1, C(0xFF9A2A, 0.85))
    c.rect(x + (w > 2 ? 1 : 0), y, max(1, w - 2), len, C(0xFFE27A))
    c.rect(x, y, w, 1, C(0xF4FCFF))
}

/// A prop drawn pointing right from pixel (20, 20) of a scratch canvas, turned to `angle` degrees (0 forward, -90 up)
/// and placed with that point on `at`.
private func prop(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(41, 41)
    art(s)
    let r = s.rotated(angle, about: (20.5, 20.5), into: 41, 41, at: (20.5, 20.5))
    let x0 = Int(floor(at.x - 20.5)), y0 = Int(floor(at.y - 20.5))
    for y in 0..<r.h {
        for x in 0..<r.w {
            let i = (y * r.w + x) * 4
            guard r.buf[i + 3] > 0 else { continue }
            c.px(x0 + x, y0 + y, unpremultiplied(r, i).alpha(alpha))
        }
    }
}

private func unpremultiplied(_ s: PixelCanvas, _ i: Int) -> Px {
    let a = s.buf[i + 3], m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a)
}

/// Draws `art` on a fresh canvas of sprite size, its origin at (0, 0).
private func offscreen(_ art: (PixelCanvas) -> Void) -> PixelCanvas {
    let o = PixelCanvas(Sprite.width, Sprite.height)
    art(o)
    return o
}

/// The colour drawn at (`x`, `y`) on `o`, or nil where nothing is.
private func colour(_ o: PixelCanvas, _ x: Int, _ y: Int) -> Px? {
    guard x >= 0, y >= 0, x < o.w, y < o.h else { return nil }
    let i = (y * o.w + x) * 4
    guard o.buf[i + 3] > 0 else { return nil }
    return unpremultiplied(o, i)
}

/// `o` drawn onto `c` as it is (offsets apply as for any drawing).
private func stamp(_ c: PixelCanvas, _ o: PixelCanvas) {
    for y in 0..<o.h {
        for x in 0..<o.w {
            guard let col = colour(o, x, y) else { continue }
            c.px(x, y, col)
        }
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`, leaning forward one pixel every
/// `lean` rows above the feet.
private func layer(_ c: PixelCanvas, lean: Int, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = Int((Double(feet - y) / Double(lean)).rounded(.down))
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x + shift, y, unpremultiplied(s, i))
        }
    }
}

/// A flyer on the move: the whole figure leant forward into its flight by `degrees`.
private func tilted(_ c: PixelCanvas, _ degrees: Double, _ art: (PixelCanvas) -> Void) {
    let o = offscreen(art)
    stamp(c, o.rotated(degrees, about: (28, 34), into: o.w, o.h, at: (28, 34)))
}
