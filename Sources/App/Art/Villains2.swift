import Foundation

// Villains: more of Gotham's worst, and the League's assassins.

let villains2: [Leader: Persona] = [
    .talia: Persona(name: "Talia al Ghul", weapon: .melee, headTop: 20, signature: 2.8, callout: "Beloved.",
                  draw: drawTalia),
    .deathstroke: Persona(name: "Deathstroke", weapon: .melee, headTop: 21, signature: 3.2, callout: "Contract's a contract.",
                  draw: drawDeathstroke),
    .madHatter: Persona(name: "Mad Hatter", weapon: .magic, magic: Magic(core: C(0xFFF0E0), glow: C(0xE88A2A), jagged: false),
                  headTop: 5, signature: 3.0, callout: "We're all mad here.",
                  draw: drawMadHatter),
    .clayface: Persona(name: "Clayface", weapon: .melee, pivot: clayShoulder, bulk: 2, headTop: 15, signature: 3.6,
                  callout: "I can be anyone.",
                  draw: drawClayface),
    .hush: Persona(name: "Hush", weapon: .ranged, shot: .bullet, muzzle: (47, 32), headTop: 21, signature: 2.6,
                  callout: "Hush now.",
                  draw: drawHush),
    .zsasz: Persona(name: "Victor Zsasz", weapon: .melee, headTop: 21, signature: 3.0, callout: "Another one for the count.",
                  draw: drawZsasz),
    .firefly: Persona(name: "Firefly", weapon: .ranged, motion: .fly, shot: .fire, muzzle: (51, 32), headTop: 20,
                  signature: 2.8, callout: "Let it burn!",
                  draw: drawFirefly),
    .manBat: Persona(name: "Man-Bat", weapon: .melee, motion: .fly, headTop: 11, signature: 2.6, callout: "Skreeeee!",
                  draw: drawManBat),
    .ventriloquist: Persona(name: "The Ventriloquist", weapon: .ranged, shot: .bullet, muzzle: (60, 30), headTop: 18,
                  signature: 3.0, callout: "Youse mugs are goin' down!",
                  draw: drawVentriloquist),
    .talon: Persona(name: "Talon", weapon: .melee, headTop: 17, signature: 2.8, callout: "Beware the Court of Owls.",
                  draw: drawTalon),
    .calendarMan: Persona(name: "Calendar Man", weapon: .melee, headTop: 21, signature: 2.8, callout: "Mark your calendars.",
                  draw: drawCalendarMan),
    .jokerGoon: Persona(name: "Joker Goon", weapon: .ranged, shot: .bullet, muzzle: (47, 32), headTop: 21, signature: 2.4,
                  draw: drawJokerGoon),
]

// MARK: - Helpers

private let clear = C(0, 0)
private let hand = Sprite.hand

/// A solid round-ended stroke: blades, limbs, hoses.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.05)
}

/// The point `d` pixels from `h` along `angle` degrees.
private func reach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// Faint smears behind a fast melee swing, `from`…`to` pixels out from `pivot`.
private func smear(_ c: PixelCanvas, _ pivot: (x: Double, y: Double), _ trail: [Double], from: Double, to: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let p0 = reach(pivot, a, from), p1 = reach(pivot, a, to)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// A sword held at `h` pointing `angle` degrees: a grip behind the hand, a guard across, and a blade `length` long,
/// bending back `curve` degrees towards the tip (a katana, a scimitar).
private func drawSword(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double, length: Double, steel: Px, light: Px,
                       grip: Px, guardCol: Px, guardHalf: Double = 2, curve: Double = 0) {
    let g0 = reach(h, angle, -3), g1 = reach(h, angle, 1)
    bar(c, g0.x, g0.y, g1.x, g1.y, grip, r: 0.8)
    var prev = reach(h, angle, 2)
    let n = 6
    for i in 1...n {
        let f = Double(i) / Double(n)
        let a: Double = angle - curve * f * f
        let q = reach(prev, a, (length - 2) / Double(n))
        bar(c, prev.x, prev.y, q.x, q.y, steel, r: i == n ? 0.5 : 0.7)
        if i > 1 && i < n { c.px(Int(prev.x.rounded(.down)), Int(prev.y.rounded(.down)), light) }
        prev = q
    }
    let gc = reach(h, angle, 1.6)
    let a = reach(gc, angle - 90, guardHalf), b = reach(gc, angle + 90, guardHalf)
    bar(c, a.x, a.y, b.x, b.y, guardCol, r: 0.6)
}

/// Claws fanning from a tip at (`x`, `y`) pointing `angle` degrees.
private func claws(_ c: PixelCanvas, _ x: Double, _ y: Double, angle: Double, spread: Double = 28, length: Double = 3.5,
                   _ col: Px, n: Int = 3) {
    for k in 0..<n {
        let e = reach((x, y), angle + (Double(k) - Double(n - 1) / 2) * spread, length)
        bar(c, x, y, e.x, e.y, col, r: 0.5)
    }
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A long coat flaring round the legs from the waist down to `bottom` (shorter when sitting).
private func drawCoatTails(_ c: PixelCanvas, _ p: Pose, _ col: Px, _ edge: Px, bottom: Int = 41) {
    let end = seatedPose ? 39 : bottom
    guard end >= 38 else { return }
    for y in 38...end {
        let out = (y - 37) / 2 + (p.step == 0 ? 1 : 0)
        c.rect(18 - out, y, 4 + out, 1, col); c.px(18 - out, y, edge)
        c.rect(34, y, 4 + out, 1, col); c.px(37 + out, y, edge)
    }
}

/// A flickering jet flame pointing down from (`x`, `y`), `w` wide, `long` adding to its length.
private func drawJet(_ c: PixelCanvas, x: Int, y: Int, w: Int, t: Double, seed: Int, long: Int = 0) {
    let len = 2 + long + Int(noise(Int(t * 30) + seed) * 3)
    c.rect(x, y, w, len + 1, C(0xFF9A2A, 0.85))
    c.rect(x + (w > 2 ? 1 : 0), y, max(1, w - 2), len, C(0xFFE27A))
    c.rect(x, y, w, 1, C(0xF4FCFF))
}

/// A little four-pointed sparkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px, big: Bool = false) {
    c.px(x, y, col)
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
        c.px(x + dx, y + dy, col.alpha(0.6))
        if big { c.px(x + 2 * dx, y + 2 * dy, col.alpha(0.3)) }
    }
}

/// A filled triangle (wing membranes).
private func fillTri(_ c: PixelCanvas, _ a: (x: Double, y: Double), _ b: (x: Double, y: Double), _ d: (x: Double, y: Double), _ col: Px) {
    let minX = Int(floor(min(a.x, b.x, d.x))), maxX = Int(ceil(max(a.x, b.x, d.x)))
    let minY = Int(floor(min(a.y, b.y, d.y))), maxY = Int(ceil(max(a.y, b.y, d.y)))
    func side(_ p: (x: Double, y: Double), _ q: (x: Double, y: Double), _ x: Double, _ y: Double) -> Double {
        (q.x - p.x) * (y - p.y) - (q.y - p.y) * (x - p.x)
    }
    for y in minY...maxY {
        for x in minX...maxX {
            let cx = Double(x) + 0.5, cy = Double(y) + 0.5
            let s1 = side(a, b, cx, cy), s2 = side(b, d, cx, cy), s3 = side(d, a, cx, cy)
            if (s1 >= 0 && s2 >= 0 && s3 >= 0) || (s1 <= 0 && s2 <= 0 && s3 <= 0) { c.px(x, y, col) }
        }
    }
}

/// Copies what was drawn on `s` (same size and offsets as `c`) onto `c`, squashed down towards the feet to `k` of its
/// height, with a share `tint` of its pixels turned to `col`/`colDark` (Clayface slumping into a puddle).
private func squash(_ c: PixelCanvas, _ s: PixelCanvas, k: Double, tint: Double, _ col: Px, _ colDark: Px) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    let feet = 43 + by
    for y in 0...feet {
        let sy = feet - Int((Double(feet - y) / k).rounded())
        guard sy >= 0 else { continue }
        for x in 0..<s.w where s.isDrawn(x, sy) {
            let i = (sy * s.w + x) * 4, a = s.buf[i + 3], m = 255 / Double(a)
            let orig = Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
                          b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a)
            c.px(x, y, noise(x * 31 + sy * 7) < tint ? (noise(x + sy * 3) > 0.5 ? col : colDark) : orig)
        }
    }
}

// MARK: - Talia al Ghul

/// Talia al Ghul: olive skin, long dark hair down her back, the League's dark green bodysuit with a gold collar and
/// sash, and a curved sword sheathed at her hip. Signature: she holds up a vial of Lazarus Pit water, glowing green,
/// and swirls it.
private func drawTalia(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E4A32), suitDark = C(0x123222), gold = C(0xD8A83A), goldLight = C(0xF4D47A)
    let skin = C(0xC8966E), skinShade = C(0xA67652), hair = C(0x22140E), hairLight = C(0x46281C)
    let steel = C(0xD0D4DC), steelLight = C(0xF4F6FA)
    drawLegs(c, Look(leg: suitDark), step: p.step)
    drawBoots(c, C(0x16110E), step: p.step, rows: 3)
    c.oy += p.breathe
    // Long hair falling down her back.
    c.rect(15, 24, 4, 13, hair); c.rect(14, 30, 2, 6, hair); c.px(16, 37, hair)
    c.rect(16, 26, 1, 8, hairLight)
    // Scabbard behind her hip when the sword is put away.
    if p.melee == nil {
        let tip = seatedPose ? (x: 10.0, y: 38.0) : (x: 9.0, y: 41.0)
        bar(c, 18, 35, tip.x, tip.y, C(0x2A1E16), r: 0.9); c.px(Int(tip.x), Int(tip.y), gold)
    }
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil))
    // Hair over the top of her head, a side part, locks framing the face.
    c.pattern(17, 21, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHHHhHHHHHHHHH.",
        "HHHHHHHhHHHHHHHHHHHH",
        "HHHHHhHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHH",
        "HHHHH.......HHHHHHHHH",
        "HHHH...........HHHHH.",
        "HHH..............HHH.",
        "HH................HH.",
        "HH................H..",
        "H....................",
    ], ["H": hair, "h": hairLight])
    // Eyes with dark liner, and red lips.
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.px(21, 28, ink); c.px(34, 28, ink)
    c.rect(27, 32, 3, 1, C(0x9A2A2E))
    // The bodysuit: gold collar, a gold sash across the waist.
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, suitDark)
    c.rect(18, 33, 20, 1, gold); c.rect(26, 33, 4, 1, goldLight)
    c.pattern(25, 34, ["G....G", ".GGGG."], ["G": gold])
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 1, goldLight)
    c.rect(15, 33, 3, 3, suit)

    if let a = p.melee {
        smear(c, hand, p.trail, from: 3, to: 16, steel)
        drawSword(c, at: hand, angle: a, length: 16, steel: steel, light: steelLight, grip: C(0x2A1E16), guardCol: gold,
                  curve: 14)
        return
    }
    // The hilt at her hip.
    bar(c, 19, 34, 22, 32, C(0x2A1E16), r: 0.7); c.px(18, 35, gold); c.px(19, 35, gold)
    guard let s = p.signature else { return }
    // The Lazarus vial, raised up to her eyes and swirled.
    let k = habitArc(s, hold: 0.6)
    let hy = 33 - Int((k * 8).rounded())
    c.rect(38, hy, 3, 3, suit)
    guard k > 0.25 else { return }
    let swirl = sin(p.lt * 14) > 0 ? 1 : 0
    let pulse = 0.65 + 0.35 * sin(p.lt * 9)
    c.glowLine(41, Double(hy) - 2, 41, Double(hy) - 2, core: clear, glow: C(0x5AFF7A), coreR: 0, glowR: 5 * k, strength: 0.45 * pulse)
    c.pattern(40, hy - 5, [".W.", "W.W", "GLG", "GLG", "GGG"], ["W": C(0xE8F4EC), "G": C(0x2ED85A), "L": C(0xC8FFD0)])
    c.px(40 + swirl * 2, hy - 2, C(0xC8FFD0))
    for i in 0..<2 {
        let f = frac(p.lt * 1.2 + Double(i) * 0.5)
        c.px(41 + (i == 0 ? -1 : 1), hy - 6 - Int(f * 5), C(0x8AFFA0).alpha(1 - f))
    }
    c.rect(32, 29, 2, 2, C(0x3AB858).alpha(0.5 * k))
}

// MARK: - Deathstroke

/// Deathstroke: the mask split down the middle, black with his one white eye on one side and blank orange on the
/// other, dark blue-grey armour over chain mail, an ammo belt, and a katana across his back. Signature: he draws the
/// katana over his shoulder and takes aim along it, a glint running down the blade, then sheathes it.
private func drawDeathstroke(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0x2E3E5E), armourDark = C(0x1C2742), armourLight = C(0x4A5C82), mail = C(0x5A6272)
    let orange = C(0xE8781E), orangeDark = C(0xB4561A), black = C(0x16161B), blackLight = C(0x34343E)
    let steel = C(0xD0D4DC), steelLight = C(0xFFFFFF), grip = C(0x1A1A1E), tsuba = C(0x6A6E7A)
    // Where the katana is this frame: drawn over the shoulder, levelled at aim, sheathed.
    var swordAngle = p.melee
    var swordHand = hand
    var aimGlint: Double?
    if swordAngle == nil, let s = p.signature {
        if s < 0.18 {
            let f = s / 0.18
            swordHand = (41.5 - 4 * (1 - f), 34.5 - 10 * (1 - f))
            swordAngle = -125 + 20 * f
        } else if s < 0.3 {
            let f = (s - 0.18) / 0.12
            let e: Double = f * f * (3 - 2 * f)
            swordHand = (41.5, 34.5 - 4 * e)
            swordAngle = -105 + 100 * e
        } else if s < 0.82 {
            swordHand = (41.5, 30.5)
            swordAngle = -5
            if s > 0.42 && s < 0.74 { aimGlint = (s - 0.42) / 0.32 }
        } else if s < 0.94 {
            let f = (s - 0.82) / 0.12
            swordHand = (41.5 - 4 * f, 30.5 - 6 * f)
            swordAngle = -5 - 120 * f
        }
    }
    let sheathed = swordAngle == nil
    drawLegs(c, Look(leg: armourDark), step: p.step)
    drawBoots(c, black, step: p.step, rows: 3)
    c.oy += p.breathe
    // The scabbard across his back, the katana's hilt over his shoulder when it's in it.
    bar(c, 13, 22, 23, 38, black, r: 0.9)
    c.px(23, 38, mail)
    if sheathed {
        bar(c, 10, 17, 13, 22, grip, r: 0.9)
        c.px(11, 18, mail); c.px(12, 20, mail)
        bar(c, 12, 23, 15, 21, tsuba, r: 0.7)
    }
    drawBody(c, Look(body: black, shade: C(0x0C0C10), arm: armour, eye: nil))
    // The mask: black behind, orange in front, split down the middle.
    c.pattern(18, 22, [
        "...BBBBBBBOOOOOOO...",
        ".BBBBBBBBBOOOOOOOOO.",
        "BBBBBBBBBBOOOOOOOOOO",
        "BBBBBBBBBBOOOOOOOOOO",
    ], ["B": black, "O": orange])
    c.rect(28, 26, 10, 7, orange)
    c.rect(37, 22, 1, 11, orangeDark)
    c.rect(19, 23, 3, 1, blackLight); c.rect(29, 23, 3, 1, C(0xF4A050))
    c.rect(28, 22, 1, 11, orangeDark)                                   // the seam
    // His one eye: a white slit on the black side.
    c.pattern(21, 28, ["WWWW", "WWW."], ["W": C(0xF0F0F0)])
    c.px(24, 29, C(0x8A8F9C))
    if let g = aimGlint, g > 0.6 { twinkle(c, 23, 28, white) }
    // Armour: chain mail at the chest, plates over the shoulders, the ammo belt.
    c.rect(18, 33, 20, 5, armour)
    for y in 33...35 { for x in stride(from: 21 + (y % 2), to: 35, by: 2) { c.px(x, y, mail) } }
    c.rect(18, 33, 3, 2, armourLight); c.rect(35, 33, 3, 2, armourLight)
    c.rect(18, 36, 20, 1, C(0x3A3A40))
    for x in [20, 24, 31, 34] { c.rect(x, 36, 2, 2, C(0x2A2A30)); c.px(x, 36, mail) }
    c.rect(27, 36, 2, 1, orange)
    c.rect(18, 37, 20, 1, armourDark)
    c.rect(15, 33, 3, 3, armour)

    guard let a = swordAngle else { return }
    if p.melee != nil { smear(c, hand, p.trail, from: 3, to: 19, steel) }
    drawSword(c, at: swordHand, angle: a, length: 19, steel: steel, light: steelLight, grip: grip, guardCol: tsuba,
              guardHalf: 1.5, curve: 4)
    c.rect(Int(swordHand.x) - 3, Int(swordHand.y) - 1, 3, 3, armour)
    if let g = aimGlint {
        let q = reach(swordHand, a, 4 + g * 14)
        twinkle(c, Int(q.x), Int(q.y), steelLight, big: true)
    }
}

// MARK: - Mad Hatter

/// The Mad Hatter: little Jervis Tetch under an enormous green top hat with a 10/6 card in its band, a mop of orange
/// hair, buck teeth, a green tailcoat, yellow waistcoat and red bow tie; a mind-control card in his casting hand.
/// Signature: he raises a cup of tea, sips it and smacks his lips, his hat bobbing.
private func drawMadHatter(_ c: PixelCanvas, _ p: Pose) {
    let hat = C(0x2E6A3A), hatDark = C(0x1E4A28), hatLight = C(0x4A8A52), band = C(0xD8A040)
    let coat = C(0x3E8A4A), coatDark = C(0x2A6234), vest = C(0xE8C83A), tie = C(0xC82A3A)
    let skin = C(0xF0D8C0), skinShade = C(0xD0B49C), hair = C(0xE8722A), hairDark = C(0xB8501A)
    let trousers = C(0x6A4A8A)
    let sip = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, C(0x5A3A22), step: p.step, rows: 2)
    c.oy += p.breathe
    // Tufts of orange hair sticking out under the hat.
    c.pattern(14, 24, ["HHHH..................HHHH", ".HHHh................hHHH.", "HHHh..................hHHH",
                       ".HH....................HH.", "..H....................H.."], ["H": hair, "h": hairDark])
    drawBody(c, Look(body: skin, shade: skinShade, arm: coat, eye: nil), armRight: p.armRaise)
    // Big round eyes, a beaky nose, buck teeth.
    c.rect(22, 28, 3, 3, white); c.rect(31, 28, 3, 3, white)
    c.rect(23, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.rect(27, 30, 2, 1, skinShade)
    c.rect(25, 31, 7, 1, ink)
    c.rect(27, 32, 3, 1, white); c.px(28, 32, C(0xC8C0B0))
    // Tailcoat, waistcoat and bow tie.
    c.rect(18, 34, 20, 4, coat)
    c.rect(37, 34, 1, 4, coatDark); c.rect(18, 37, 20, 1, coatDark)
    c.rect(24, 34, 8, 4, vest); c.px(28, 36, C(0x8A6A1A))
    c.pattern(25, 33, ["T...T", "TTTTT", "T...T"], ["T": tie])
    c.px(27, 34, tie); c.px(29, 34, tie)
    c.rect(15, 33, 3, 3, coat)
    // Tails of the coat behind him.
    if !seatedPose { c.rect(15, 36, 3, 5, coatDark); c.px(15, 41, coatDark) }

    // The enormous hat, flaring at the top; it bobs as he sips.
    let bob = sip > 0.5 ? -1 : 0
    c.pattern(15, 5 + bob, [
        "...hhhhhhhhhhhhhhhhhhh....",
        "...HHHHHHHHHHHHHHHHHHH....",
        "...LHHHHHHHHHHHHHHHHHD....",
        "....LHHHHHHHHHHHHHHHD.....",
        "....LHHHHHHHHHHHHHHHD.....",
        "....LHHHHHHHHHHHHHHHD.....",
        "....LHHHHHHHHHHHHHHHD.....",
        ".....LHHHHHHHHHHHHHD......",
        ".....LHHHHHHHHHHHHHD......",
        ".....LHHHHHHHHHHHHHD......",
        ".....LHHHHHHHHHHHHHD......",
        ".....LHHHHHHHHHHHHHD......",
        ".....BBBBBBBBBBBBBBB......",
        ".....BBBBBBBBBBBBBBB......",
        ".....LHHHHHHHHHHHHHD......",
        ".....LHHHHHHHHHHHHHD......",
        ".....LHHHHHHHHHHHHHD......",
        ".DDHHHHHHHHHHHHHHHHHHHHDD.",
        "DD.......................D",
    ], ["H": hat, "D": hatDark, "L": hatLight, "B": band, "h": hatDark])
    // The 10/6 card tucked in the band.
    c.pattern(29, 13 + bob, ["WWWW", "WRWW", "WWKW", "WRWK", "WWWW"], ["W": C(0xF4F0E4), "R": tie, "K": ink])

    // A mind-control card in his casting hand.
    let r = p.armRaise
    if sip == 0 {
        c.pattern(40, 30 - r, ["WWW", "WRW", "WWW", "WRW"], ["W": C(0xF4F0E4), "R": tie])
        return
    }
    // The teacup, lifted to his lips.
    let cy = 34 - Int((sip * 2).rounded()), cx = 38 - Int((sip * 3).rounded())
    c.rect(cx + 1, cy + 1, 3, 2, coat)
    c.pattern(cx - 1, cy - 2, ["CCCC.", "CPPCc", "CCCCc", ".CC.."], ["C": white, "P": C(0xF4D0E0), "c": C(0xD8D8E0)])
    c.rect(cx - 2, cy + 2, 6, 1, C(0xD8D8E0))
    if sip > 0.6 {
        for i in 0..<2 {
            let f = frac(p.lt * 1.4 + Double(i) * 0.5)
            c.px(cx + i + Int(sin(f * 7) * 1.2), cy - 3 - Int(f * 5), C(0xF4F4F8).alpha(0.8 * (1 - f)))
        }
    }
}

// MARK: - Clayface

/// Where Clayface's swinging arm hangs from (the fight effects use it too).
private let clayShoulder = (x: 42.5, y: 32.5)

/// Clayface: a great slumped heap of brown clay in roughly Clawd's shape, a sagging face with deep sockets and pale
/// yellow eyes, drips running off him. In a fight his arm swells into a clay mallet. Signature: he melts down into a
/// puddle, eyes peering up out of it, then pulls himself back up.
private func drawClayface(_ c: PixelCanvas, _ p: Pose) {
    let melt = p.signature.map { habitArc($0, hold: 0.25) } ?? 0
    guard melt > 0 else { drawClayfaceFigure(c, p); return }
    let clay = C(0x9A6A44), clayDark = C(0x74482C)
    let tmp = PixelCanvas(c.w, c.h)
    tmp.ox = c.ox; tmp.oy = c.oy; tmp.baseY = c.baseY
    drawClayfaceFigure(tmp, p)
    let k = max(0.12, 1 - pow(melt, 1.6) * 0.88)
    squash(c, tmp, k: k, tint: melt * 0.5, clay, clayDark)
    // The puddle spreading out round his feet.
    let w = Int((melt * 9).rounded())
    c.rect(14 - w, 42, 28 + 2 * w, 2, clay)
    c.rect(14 - w, 43, 28 + 2 * w, 1, clayDark)
    c.px(13 - w, 43, clayDark); c.px(42 + w, 43, clayDark)
    if melt > 0.85 {
        // Eyes peering up out of the puddle.
        c.rect(24, 40, 2, 1, C(0xF4E07A)); c.rect(31, 40, 2, 1, C(0xF4E07A))
    }
}

private func drawClayfaceFigure(_ c: PixelCanvas, _ p: Pose) {
    let clay = C(0x9A6A44), clayDark = C(0x74482C), clayLight = C(0xB88A5E), eye = C(0xF4E07A)
    // Thick lumpy legs, splaying into blobs of feet.
    for (i, lx) in [16, 22, 30, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 6, 2, clay); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 35, 4, lifted ? 7 : 8, clay)
        c.rect(lx - 1, lifted ? 41 : 42, 6, 2, clay)
        c.rect(lx + 3, 35, 1, 6, clayDark)
    }
    c.oy += p.breathe
    // A mallet swung back over his shoulder goes behind him.
    if let a = p.melee, cos(a * .pi / 180) < -0.2 { drawClayMallet(c, angle: a, trail: p.trail) }
    // The great slumped body.
    c.pattern(13, 15, [
        ".......CCCCCCCCCCCCCC.......",
        ".....CCCCLLLLCCCCCCCCCC.....",
        "...CCCCLLCCCCCCCCCCCCCCC....",
        "..CCCCLCCCCCCCCCCCCCCCCCCC..",
        ".CCCCCCCCCCCCCCCCCCCCCCCCCC.",
        ".CCCCCCCCCCCCCCCCCCCCCCCCCCD",
    ], ["C": clay, "L": clayLight, "D": clayDark])
    c.rect(14, 21, 27, 17, clay)
    c.rect(13, 21, 1, 15, clay)
    c.rect(40, 20, 1, 18, clayDark)
    c.rect(14, 37, 27, 1, clayDark)
    // Lumps and creases in the clay.
    for (x, y, w) in [(16, 24, 3), (17, 31, 4), (35, 34, 3), (20, 35, 3)] { c.rect(x, y, w, 1, clayDark) }
    c.rect(15, 22, 1, 5, clayLight)
    // The sagging face: deep sockets, glowing eyes, a drooping mouth.
    c.rect(21, 23, 5, 4, clayDark); c.rect(31, 23, 5, 4, clayDark)
    c.rect(22, 24, 3, 2, C(0x3A2416)); c.rect(32, 24, 3, 2, C(0x3A2416))
    c.rect(23, 24, 2, 2, eye); c.rect(33, 24, 2, 2, eye)
    c.rect(20, 22, 6, 1, clayLight); c.rect(30, 22, 6, 1, clayLight)
    c.pattern(22, 29, ["..DDDDDDDDD..", ".DKKKKKKKKKD.", "DKKKKKKKKKKD.", "DKKKKKKKKKD..", "D.DKKKKKKD...", "D..D.KK.D....",
                       "....D.K......"],
              ["D": clayDark, "K": C(0x2A180E)])
    // Drips running off him, sliding slowly down.
    for i in 0..<4 {
        let x = [14, 19, 33, 39][i]
        let f = frac(p.lt * 0.35 + Double(i) * 0.27)
        let y = 26 + i * 2 + Int(f * 9)
        c.rect(x, y, 1, 2, clayDark)
        if f > 0.7 { c.px(x, y + 3, clay.alpha(1 - f)) }
    }
    // The back arm, a drooping lump.
    c.rect(10, 28, 4, 8, clay); c.rect(10, 35, 3, 2, clayDark)
    // The front arm: hanging and dripping, or swollen into a mallet in a fight.
    guard let a = p.melee else {
        c.rect(41, 28, 4, 9, clay); c.rect(44, 28, 1, 9, clayDark)
        c.rect(41, 37, 4, 1, clayDark); c.px(42, 38 + Int(frac(p.lt * 0.5) * 3), clayDark)
        return
    }
    if cos(a * .pi / 180) >= -0.2 { drawClayMallet(c, angle: a, trail: p.trail) }
}

/// Clayface's arm swollen into a clay mallet, swung out along `angle` from his shoulder.
private func drawClayMallet(_ c: PixelCanvas, angle a: Double, trail: [Double]) {
    let clay = C(0x9A6A44), clayDark = C(0x74482C), clayLight = C(0xB88A5E)
    let sh = clayShoulder
    smear(c, sh, trail, from: 8, to: 17, clay)
    let e = reach(sh, a, 10)
    bar(c, sh.x - 1, sh.y, e.x, e.y, clay, r: 2.0)
    let m = reach(sh, a, 14)
    let m0 = reach(m, a - 90, 4), m1 = reach(m, a + 90, 4)
    bar(c, m0.x, m0.y, m1.x, m1.y, clay, r: 3.0)
    let lt = reach(m, a + 180, 2)
    bar(c, lt.x + (m0.x - m.x) * 0.6, lt.y + (m0.y - m.y) * 0.6, lt.x, lt.y, clayLight, r: 0.5)
    let d = reach(m, a + 90, 5)
    c.px(Int(d.x), Int(d.y) + 1, clayDark)
}

// MARK: - Hush

/// Hush: Tommy Elliot, his head wrapped all over in white bandages with dark eye holes, a black trench coat with the
/// collar up over a dark suit, a pistol in each hand. Signature: he raises a finger to his bandaged lips. Shh.
private func drawHush(_ c: PixelCanvas, _ p: Pose) {
    let bandage = C(0xE8E2D4), bandageShade = C(0xB8AE9C), coat = C(0x2C2826), coatLight = C(0x48423E)
    let coatDark = C(0x18161A), suit = C(0x1A1A20), gun = C(0x2A2A30), gunTrim = C(0x9A9EA8)
    let shh = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, C(0x0E0E10), step: p.step, rows: 2)
    c.oy += p.breathe
    // The second pistol, held low in his back hand (it comes up for the shh).
    if shh < 0.2 {
        c.pattern(13, 35, ["KK", "KK", "KT", "KK", ".K", ".K"], ["K": gun, "T": gunTrim])
    }
    drawBody(c, Look(body: bandage, shade: bandageShade, arm: coat, eye: nil))
    // The wrapped head: a dome of bandage, the wraps running across it.
    c.pattern(18, 22, ["...BBBBBBBBBBBBBB...", ".BBBBBBBBBBBBBBBBBB.", "BBBBBBBBBBBBBBBBBBBB", "BBBBBBBBBBBBBBBBBBBB"],
              ["B": bandage])
    c.rect(37, 23, 1, 4, bandageShade)
    for (i, y) in [23, 26, 31].enumerated() {
        for x in 18...37 where (x + i * 3) % 7 != 0 { c.px(x, y + (x + i) % 5 / 3, bandageShade) }
    }
    // Dark eye holes, and a loose bandage end trailing behind.
    c.rect(21, 28, 4, 1, bandageShade); c.rect(31, 28, 4, 1, bandageShade)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.rect(26, 32, 4, 1, bandageShade)
    let flap = sin(p.lt * 3) > 0 ? 1 : 0
    c.pattern(14, 27 + flap, ["BBBB", "B...", ".B.."], ["B": bandageShade])
    // Trench coat with the collar up, over a dark suit and tie.
    c.rect(18, 33, 20, 5, coat)
    c.rect(25, 33, 6, 5, suit); c.rect(27, 33, 2, 4, C(0x4A1A20))
    c.pattern(18, 30, ["CC................CC", "CCC..............CCC", "CCCCC..........CCCCC", "..CCCCC......CCCCC.."],
              ["C": coatLight])
    c.rect(37, 33, 1, 5, coatDark); c.rect(18, 37, 20, 1, coatDark)
    drawCoatTails(c, p, coat, coatDark)
    c.rect(15, 33, 3, 3, coat)

    if shh > 0.2 {
        // The back hand comes up across his face, one finger to the lips.
        let k = min(1, (shh - 0.2) / 0.6)
        let hx = 16 + Int((k * 10).rounded()), hy = 34 - Int((k * 2).rounded())
        let glove = C(0x0E0E10)
        c.rect(hx, hy, 3, 3, glove)
        c.rect(hx + 1, hy - 1 - Int((k * 3).rounded()), 1, 1 + Int((k * 3).rounded()), glove)
        if k > 0.9 {
            let f = frac(p.lt * 1.5)
            c.px(30 + Int(f * 4), 30 - Int(f * 3), C(0xF4F4F8).alpha(0.7 * (1 - f)))
            c.px(31 + Int(f * 4), 32 - Int(f * 2), C(0xF4F4F8).alpha(0.5 * (1 - f)))
        }
    }
    c.rect(38, 33, 3, 3, coat)
    drawPistol(c, x: 40, y: 31 + p.gunY, body: gun, trim: gunTrim)
}

// MARK: - Victor Zsasz

/// Victor Zsasz: bald and deathly pale, shirtless, every inch of him scored with red tally marks, black trousers and
/// a hunting knife kept at his belt until he wants it. Signature: he draws the knife and carves one more tally on
/// his chest, and grins.
private func drawZsasz(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE4D6CC), skinShade = C(0xC2B0A4), scar = C(0xB83A3A), scarDark = C(0x8A2A2A)
    let trousers = C(0x1A1A1E), steel = C(0xD0D4DC), handle = C(0x2A2A30)
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, C(0x0E0E10), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: skin, eye: nil))
    // A bald dome.
    c.pattern(18, 22, ["....SSSSSSSSSSSS....", "..SSSLLSSSSSSSSSSS..", ".SSLLSSSSSSSSSSSSSS.", "SSSSSSSSSSSSSSSSSSSS"],
              ["S": skin, "L": C(0xF8F0EA)])
    c.rect(37, 24, 1, 2, skinShade)
    // Sunken, ringed eyes and a thin smile.
    let socket = C(0x9A8478)
    c.rect(21, 28, 4, 3, socket); c.rect(31, 28, 4, 3, socket)
    c.rect(22, 29, 2, 1, ink); c.rect(32, 29, 2, 1, ink)
    c.px(22, 29, C(0xE8E0D8)); c.px(33, 29, C(0xE8E0D8))
    c.pattern(20, 26, ["KK.........KK", "..KK.....KK.."], ["K": C(0x6A5A52)])
    // Tally marks: groups of four struck through, all over.
    func tally(_ x: Int, _ y: Int, _ n: Int = 4, strike: Bool = true) {
        for k in 0..<n { c.rect(x + k * 2, y, 1, 3, scar) }
        if strike { for k in 0..<7 { c.px(x - 1 + k, y + 2 - k * 3 / 7, scarDark) } }
    }
    tally(19, 34); tally(28, 34)
    for k in 0..<3 { c.rect(31 + k * 2, 24, 1, 2, scar.alpha(0.7)) }
    c.rect(15, 33, 1, 3, scar); c.rect(17, 33, 1, 3, scar)
    c.rect(38, 33, 1, 3, scar)
    c.rect(18, 37, 20, 1, trousers)
    c.rect(18, 37, 20, 1, C(0x2A2A30))

    let s = p.signature
    let carve = s.map { $0 > 0.2 && $0 < 0.85 } ?? false
    // The grin widens while he carves.
    if carve {
        c.pattern(24, 31, ["K.......K", ".KKKKKKK."], ["K": ink])
    } else {
        c.rect(24, 32, 8, 1, C(0x5A3A3A)); c.px(23, 31, C(0x5A3A3A)); c.px(32, 31, C(0x5A3A3A))
    }
    if let a = p.melee {
        smear(c, hand, p.trail, from: 3, to: 10, steel)
        drawSword(c, at: hand, angle: a, length: 10, steel: steel, light: white, grip: handle, guardCol: C(0x5A5E68), guardHalf: 1)
        return
    }
    if let s, s > 0.08, s < 0.95 {
        // Carving: the knife drawn across his chest, a new stroke appearing behind its point.
        let f = carve ? min(1, (s - 0.2) / 0.55) : 0
        let tipX = 36.0 - 6 * f, tipY = 33.5
        if carve {
            let len = Int((f * 4).rounded())
            if len > 0 { c.rect(37 - len, 35, len, 1, scar) }
            c.rect(36, 34, 1, 3, scar)
        }
        let hx = tipX + 6, hy = tipY - 3
        drawSword(c, at: (hx, hy), angle: 155, length: 8, steel: C(0x8A909C), light: white, grip: handle,
                  guardCol: C(0x3A3E48), guardHalf: 1)
        c.rect(Int(hx) - 1, Int(hy) - 1, 3, 3, skin)
        if carve { c.px(Int(tipX), Int(tipY) + 1, C(0xFF5A4A)) }
        return
    }
    // The knife sheathed at his back hip.
    c.rect(16, 37, 2, 4, C(0x3A2A20)); c.rect(16, 36, 2, 1, C(0x5A5E68)); c.rect(16, 34, 2, 2, handle)
}

// MARK: - Firefly

/// Firefly: Garfield Lynns in his olive flight suit with orange flame stripes, a steel helmet with great round
/// green-gold goggles, a finned jetpack on his back and a flamethrower in his hand, its hose running back to the
/// tanks. Signature: he points the flamethrower at the sky and lets loose a roaring column of fire.
private func drawFirefly(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x5E6E3E), suitDark = C(0x3E4A28), flame = C(0xF07A1E), flameLight = C(0xFFC83A)
    let steel = C(0x8A909C), steelDark = C(0x5A606C), steelLight = C(0xC0C6D0)
    let lens = C(0xC8E83A), lensLight = C(0xF4FFB0), tank = C(0xA83A1E)
    let blast = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    // Jetpack on his back: two tanks and fins, the jets lit in flight.
    c.oy += p.breathe
    c.pattern(10, 23, [
        "..FF.....",
        ".FFFF....",
        "FFTTTT...",
        ".TTTTTS..",
        ".TtTTTS..",
        ".TtTTTS..",
        ".TtTTTS..",
        ".TtTTTS..",
        ".TTTTTS..",
        ".TTTTTS..",
        ".SSSSSS..",
        "FF.SS....",
        "F........",
    ], ["F": steelDark, "T": tank, "t": C(0xD8603A), "S": steel])
    if p.flying || p.signature != nil && blast > 0.3 {
        drawJet(c, x: 12, y: 35, w: 3, t: p.t, seed: 3, long: p.flying ? 4 : 1)
    }
    c.oy -= p.breathe
    if p.flying {
        // Legs swept back behind him.
        for lx in [19, 23, 31, 35] {
            let x = Double(lx) + 1
            bar(c, x, 37, x - 4, 41, suitDark, r: 0.8)
            bar(c, x - 4, 41, x - 5, 42, steelDark, r: 0.8)
        }
    } else {
        drawLegs(c, Look(leg: suitDark), step: p.step)
        drawBoots(c, steelDark, step: p.step, rows: 3)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: suit, shade: suitDark, arm: suit, eye: nil))
    // Flame stripes up the suit.
    c.pattern(18, 32, ["F.....F......F......", "FF...FFF....FFF...F.", "FfF.FFfFF..FFfFF.FF.", "FFFFFFFFFFFFFFFFFFFF"],
              ["F": flame, "f": flameLight])
    c.rect(18, 36, 20, 1, C(0x2A2A20)); c.rect(27, 36, 2, 1, steelLight)
    c.rect(18, 37, 20, 1, suitDark)
    // The helmet with its great round goggles.
    c.pattern(17, 20, [
        "......SSSSSSSSSS......",
        "....SSSSLLSSSSSSSS....",
        "...SSSLLSSSSSSSSSSS...",
        "..SSSSSSSSSSSSSSSSSSS.",
        "..SSSRRRRSSSSSSRRRRSS.",
        "..SSRGGGGRSSSSRGGGGRS.",
        "..SRGWGGGGRSSRGWGGGGR.",
        "..SRGGGGGGRSSRGGGGGGR.",
        "..SRGGGGGGRSSRGGGGGGR.",
        "..SSRGGGGRSSSSRGGGGRS.",
        "..DSSRRRRSSSSSSRRRRSD.",
        "...DDSSSSSSSSSSSSSSDD.",
    ], ["S": steel, "L": steelLight, "D": steelDark, "R": C(0x3A3E46), "G": lens, "W": lensLight])
    c.rect(26, 31, 4, 1, C(0x3A3E46))                                         // the breather
    c.rect(15, 33, 3, 3, suit)

    // The flamethrower, the hose looping back to the tanks.
    if p.signature != nil && blast > 0 {
        // Pointed straight up, the fire roaring out of it.
        let lift = Int((blast * 3).rounded())
        c.rect(38, 32 - lift, 3, 3, suit)
        c.rect(39, 20 - lift, 2, 12, steel); c.rect(39, 20 - lift, 1, 12, steelLight)
        c.rect(38, 29 - lift, 4, 3, steelDark)
        bar(c, 16, 36, 37, 36, C(0x2A2A20), r: 0.5)
        if blast > 0.4 {
            // Puffs of fire billowing up, hot and yellow at the nozzle, red and ragged at the top.
            let i = Int(p.t * 30)
            let top = 19.0 - Double(lift)
            let cols: [Int] = [0xFFF2B0, 0xFFD25A, 0xFFA02A, 0xFF7A1A, 0xE8401A, 0xA8281A]
            for k in 0..<6 {
                let f = Double(k) / 5
                let y = top - 1 - f * 10 - noise(i + k) * 2
                let x = 40 + (noise(i * 3 + k) - 0.5) * (1 + f * 4)
                c.glowLine(x, y, x, y, core: C(UInt32(cols[k]), 0.95), glow: C(0xFF5A1A, 0.8), coreR: 1.3 + f * 1.6,
                           glowR: 2.4 + f * 2.4, strength: 1 - f * 0.3)
            }
        }
        return
    }
    let y = 31 + p.gunY
    bar(c, 16, 34, 30, 37, C(0x2A2A20), r: 0.5); bar(c, 30, 37, 39, Double(y) + 2.5, C(0x2A2A20), r: 0.5)
    c.rect(38, 33, 3, 3, suit)
    c.pattern(39, y, ["..SSSSSSSSSDD", "SSSLLLLLLLLSD", "TTTSSSSSSSSDD", ".TT.D........", "..T.........."],
              ["S": steel, "L": steelLight, "D": steelDark, "T": tank])
    // The pilot flame flickering at the nozzle.
    if Int(p.lt * 12) % 3 != 0 { c.px(52, y + 1, flameLight); c.px(53, y + 1, flame.alpha(0.6)) }
}

// MARK: - Man-Bat

/// Man-Bat: Kirk Langstrom gone wrong, a hunched brown-furred bat with tall pointed ears, a pug snout, fangs and
/// glaring red eyes, great leathery wings folded down his back like a cloak. He flies with them spread and beating,
/// and fights with his claws. Signature: he throws his wings wide and shrieks, sound rings pulsing out.
private func drawManBat(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x5A4636), furDark = C(0x3E2E22), furLight = C(0x7A6250), skin = C(0xB08A7A), skinDark = C(0x7A5A4E)
    let eye = C(0xFF4A2A), claw = C(0xE8DCC0)
    let shriek = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    var spread = shriek
    if p.flying { spread = 0.7 + 0.3 * sin(p.t * 10) }
    if p.flying { c.oy += sin(p.t * 10) > 0 ? 0 : -1 }
    c.oy += p.breathe
    if spread > 0.15 { drawBatWing(c, root: (34, 28), spread: spread, far: true) }
    c.oy -= p.breathe
    // Bent, clawed legs; tucked up and trailing in flight.
    if p.flying {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.rect(lx - 2 + i / 2, 36, 2, 5, furDark)
            claws(c, Double(lx - 1 + i / 2), 41.5, angle: 110, spread: 30, length: 2, claw, n: 2)
        }
    } else {
        drawLegs(c, Look(leg: furDark), step: p.step)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let b = p.step >= 0 && i % 2 == p.step ? 42 : 43
                c.px(lx + 2, b, claw); c.px(lx - 1, b, claw)
            }
        }
    }
    c.oy += p.breathe
    drawBatWing(c, root: (21, 29), spread: spread, far: false)
    drawBody(c, Look(body: fur, shade: furDark, arm: fur, eye: nil))
    // Tall pointed ears.
    c.pattern(18, 11, [
        "..F..........F......",
        "..FF.........FF.....",
        "..FF........FFF.....",
        ".FFF........FsF.....",
        ".FsF.......FFsF.....",
        ".FsFF......FssF.....",
        ".FssF......FssFF....",
        "FFssF.....FFssFF....",
        "FFssFF....FFsssF....",
        "FFsssF....FFsssFF...",
        "FFFFFFFFFFFFFFFFFF..",
        "FFFFFFFFFFFFFFFFFFF.",
        "FFFFFFFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFFFFFFFFF",
    ], ["F": fur, "s": skinDark])
    c.rect(37, 21, 1, 5, furDark)
    c.rect(22, 22, 4, 1, furLight); c.rect(19, 23, 1, 3, furLight)
    // Red eyes under a heavy brow.
    c.rect(21, 26, 5, 1, furDark); c.rect(30, 26, 5, 1, furDark)
    c.rect(22, 27, 3, 2, eye); c.rect(31, 27, 3, 2, eye)
    c.px(23, 27, C(0xFFD0A0)); c.px(32, 27, C(0xFFD0A0))
    // The pug snout, and the mouth: fangs, gaping when he shrieks.
    c.pattern(25, 29, [".SSSSSS.", "SSKSSKSS", ".SSSSSS."], ["S": skin, "K": C(0x2A1A16)])
    let gape = Int((shriek * 3).rounded())
    c.rect(23, 32, 10, 1 + gape, C(0x3A0E10))
    if gape > 1 { c.rect(25, 33, 6, gape - 1, C(0x8A2A2A)) }
    c.px(24, 33, white); c.px(31, 33, white)
    if gape > 1 { c.px(24, 32 + gape, white); c.px(31, 32 + gape, white) }
    // A paler furry belly.
    c.rect(23, 35, 10, 2, furLight)
    c.rect(18, 37, 20, 1, furDark)
    c.rect(15, 33, 3, 3, fur)
    // Claws: a raking slash in a fight, curled at his side otherwise.
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            for k in -1...1 {
                let q0 = reach(hand, ta, 4), q1 = reach(hand, ta, 10)
                bar(c, q0.x, q0.y + Double(k) * 2, q1.x, q1.y + Double(k) * 2, claw.alpha(0.3 / Double(i + 1)), r: 0.4)
            }
        }
        let e = reach(hand, a, 5)
        bar(c, hand.x - 2, hand.y, e.x, e.y, fur, r: 1.4)
        claws(c, e.x, e.y, angle: a, spread: 30, length: 4, claw)
    } else {
        c.rect(38, 33, 3, 3, fur)
        claws(c, 40.5, 35.5, angle: 80, spread: 30, length: 2.5, claw)
    }
    // Sound rings rolling out of the shriek.
    if shriek > 0.6 {
        for i in 0..<3 {
            let f = frac(p.lt * 2.2 + Double(i) / 3)
            let r = 9 + f * 15, cx = 30.0, cy = 33.0
            let col = C(0xF0E8FF).alpha(0.9 * (1 - f))
            for k in -4..<4 {
                let a0 = Double(k) * 0.14, a1 = Double(k + 1) * 0.14
                c.glowLine(cx + cos(a0) * r, cy + sin(a0) * r, cx + cos(a1) * r, cy + sin(a1) * r,
                           core: col, glow: clear, coreR: 0.5, glowR: 0.55)
            }
        }
    }
}

/// A leathery bat wing from the shoulder at `root`: folded down his back like a cloak (`spread` 0) to thrown wide and
/// up (1). `far`: the wing on the far side, darker, opening out to the right instead of the left.
private func drawBatWing(_ c: PixelCanvas, root: (x: Double, y: Double), spread s: Double, far: Bool) {
    let skin = far ? C(0x34261C) : C(0x4A3628), bone = far ? C(0x22160F) : C(0x2E2018)
    func lerp(_ a: Double, _ b: Double) -> Double { a + (b - a) * s }
    func side(_ a: Double) -> Double { far ? 180 - a : a }
    let armA = side(lerp(165, 228)), armL = lerp(7, 9)
    let wrist = reach(root, armA, armL)
    let folded: [Double] = [96, 110, 124], open: [Double] = [262, 212, 168]
    let lens: [Double] = [lerp(10, 13), lerp(11, 15), lerp(10, 11)]
    var tips: [(x: Double, y: Double)] = []
    for i in 0..<3 { tips.append(reach(wrist, side(lerp(folded[i], open[i])), lens[i])) }
    let hip = (x: root.x + (far ? -1 : 1), y: root.y + 9)
    // The membrane between the fingers, its trailing edge scalloped.
    func scallop(_ a: (x: Double, y: Double), _ b: (x: Double, y: Double)) -> (x: Double, y: Double) {
        let m = (x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        return (m.x + (wrist.x - m.x) * 0.25, m.y + (wrist.y - m.y) * 0.25)
    }
    fillTri(c, root, wrist, tips[0], skin)
    let edges: [((x: Double, y: Double), (x: Double, y: Double))] = [(tips[0], tips[1]), (tips[1], tips[2])]
    for (a, b) in edges {
        let m = scallop(a, b)
        fillTri(c, wrist, a, m, skin); fillTri(c, wrist, m, b, skin)
    }
    let m = scallop(tips[2], hip)
    fillTri(c, wrist, tips[2], m, skin); fillTri(c, wrist, m, hip, skin); fillTri(c, root, wrist, hip, skin)
    // Bones: the arm, then the long fingers.
    bar(c, root.x, root.y, wrist.x, wrist.y, bone, r: 0.9)
    for t in tips { bar(c, wrist.x, wrist.y, t.x, t.y, bone, r: 0.45) }
    let thumb = reach(wrist, armA + (far ? 40 : -40), 2)
    bar(c, wrist.x, wrist.y, thumb.x, thumb.y, C(0xE8DCC0), r: 0.4)
}

// MARK: - The Ventriloquist

/// The Ventriloquist: meek, balding Arnold Wesker in round glasses and a drab brown suit, and on his arm the real
/// boss: Scarface, a wooden gangster dummy in a pinstripe suit and fedora, scar down his cheek, with a tommy gun.
/// Signature: Scarface rounds on Wesker and chews him out, jaw clacking, while Wesker sweats.
private func drawVentriloquist(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x7A6248), suitDark = C(0x5A4632), skin = C(0xE8D0B8), skinShade = C(0xC8AE96), hair = C(0x9A948C)
    let yell = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    drawLegs(c, Look(leg: suitDark), step: p.step)
    drawBoots(c, C(0x2A1E16), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil))
    // Balding: a shiny pate, grey hair round the sides.
    c.pattern(18, 23, ["....SSSSSSSSSSSS....", "..SSSWWSSSSSSSSSSS..", "HSSSSSSSSSSSSSSSSSSH", "HHSSSSSSSSSSSSSSSSHH"],
              ["S": skin, "W": C(0xFFF4EA), "H": hair])
    c.rect(18, 27, 2, 4, hair); c.rect(36, 27, 2, 4, hair)
    // Round glasses, worried brows, a timid little mouth.
    c.pattern(20, 27, [".KKK....KKK..", "K...KKKK...K.", "K.E.K..K.E.K.", ".KKK....KKK.."],
                ["K": C(0x3A3A40), "E": ink])
    let worry = yell > 0.3 ? 1 : 0
    c.rect(21, 26 - worry, 3, 1, hair); c.rect(29, 26 - worry, 3, 1, hair)
    c.rect(27, 32, 3, 1, skinShade)
    if yell > 0.3 {
        // A bead of sweat.
        let f = frac(p.lt * 1.2)
        c.rect(19, 27 + Int(f * 4), 1, 2, C(0x9ADAFF).alpha(1 - f * 0.5))
    }
    // Drab suit, shirt and tie.
    c.rect(18, 33, 20, 5, suit)
    c.rect(26, 33, 5, 4, C(0xF0EEE6)); c.rect(28, 33, 1, 4, C(0x6A2A2A))
    c.pattern(24, 33, ["S.....S", ".S...S.", "..S.S.."], ["S": suitDark])
    c.rect(37, 33, 1, 5, suitDark); c.rect(18, 37, 20, 1, suitDark)
    c.rect(15, 33, 3, 3, suit)
    drawScarface(c, p, yell: yell)
}

/// Scarface on Wesker's arm, sitting up at shoulder height with the tommy gun out in front (it kicks with the shots).
private func drawScarface(_ c: PixelCanvas, _ p: Pose, yell: Double) {
    let wood = C(0xE8C8A0), woodShade = C(0xC0A078), pin = C(0x2A2A3E), stripe = C(0x8A8AA0), hat = C(0x26262C)
    let hatBand = C(0x8A2A2A), scar = C(0xB83A3A), gunMetal = C(0x2A2A30), stock = C(0x7A4A26)
    let gy = yell > 0.3 ? 0 : p.gunY
    let ox = 38, oy = 19 + gy
    // Wesker's arm up under him.
    c.rect(38, 30, 3, 6, C(0x7A6248))
    // The pinstripe body.
    c.rect(ox + 1, oy + 9, 8, 7, pin)
    for x in stride(from: ox + 2, to: ox + 9, by: 2) { c.rect(x, oy + 9, 1, 7, stripe.alpha(0.6)) }
    c.rect(ox + 4, oy + 9, 2, 3, C(0xF0EEE6)); c.px(ox + 4, oy + 10, C(0xC82A2A)); c.px(ox + 5, oy + 10, C(0xC82A2A))
    // Little legs dangling.
    c.rect(ox + 2, oy + 16, 2, 2, pin); c.rect(ox + 6, oy + 16, 2, 2, pin)
    c.rect(ox + 2, oy + 18, 2, 1, ink); c.rect(ox + 6, oy + 18, 2, 1, ink)
    // The head: square wooden jaw on hinges, a scar down the cheek, a fedora. Jaw clacks when he yells.
    let clack = yell > 0.3 && Int(p.lt * 10) % 2 == 0 ? 1 : 0
    let turn = yell > 0.3
    c.rect(ox + 1, oy + 2, 8, 5, wood)
    c.rect(ox + 1, oy + 7 + clack, 8, 2, wood)
    c.rect(ox + 1, oy + 6, 1, 3 + clack, woodShade); c.rect(ox + 8, oy + 6, 1, 3 + clack, woodShade)
    if clack > 0 { c.rect(ox + 2, oy + 7, 6, 1, C(0x3A0E10)) }
    c.rect(ox + 2, oy + 6, 6, 1, woodShade)
    if turn {
        // Glaring back at Wesker.
        c.px(ox + 2, oy + 4, ink); c.px(ox + 5, oy + 4, ink)
        c.rect(ox + 1, oy + 3, 3, 1, ink); c.rect(ox + 4, oy + 3, 3, 1, ink)
        c.rect(ox + 6, oy + 3, 1, 4, scar)
    } else {
        c.px(ox + 4, oy + 4, ink); c.px(ox + 7, oy + 4, ink)
        c.rect(ox + 3, oy + 3, 2, 1, ink); c.rect(ox + 6, oy + 3, 2, 1, ink)
        c.rect(ox + 3, oy + 3, 1, 4, scar)
        c.px(ox + 9, oy + 5, wood)
    }
    c.pattern(ox - 1, oy - 2, ["..HHHHHH...", ".HHHHHHHH..", ".BBBBBBBB..", "HHHHHHHHHHH"], ["H": hat, "B": hatBand])
    if turn {
        // His fury, in the air above him.
        let f = Int(p.lt * 8) % 2
        c.pattern(ox - 4 + f, oy - 7, ["K.K.K", "KKKKK", ".K.K.", "KKKKK", "K.K.K"], ["K": C(0xFF4A3A)])
    }
    // The tommy gun: stock, drum magazine, finned barrel; waved about while he yells.
    let gx = ox + 6, gyy = oy + 11 + (turn ? clack : 0)
    c.pattern(gx, gyy, [
        "SS.MMMMMMMMMMMM.",
        "SSMMMMMMMMMMMMMM",
        ".SS.DDD.MM......",
        "....DDD.........",
        ".....D..........",
    ], ["S": stock, "M": gunMetal, "D": C(0x3A3A42)])
    c.rect(gx + 9, gyy, 1, 1, C(0x5A5A62)); c.rect(gx + 11, gyy, 1, 1, C(0x5A5A62))
    c.rect(ox + 8, oy + 12, 2, 2, wood)
}

// MARK: - Talon

/// Talon: an undead assassin of the Court of Owls in black leather and brass buckles, the owl mask with its ear tufts,
/// little beak and great round gold goggles, and a bandolier of throwing knives across his chest. He fights with a
/// long knife. Signature: he cocks his head one way and the other like an owl, his goggles flaring.
private func drawTalon(_ c: PixelCanvas, _ p: Pose) {
    let leather = C(0x2A2626), leatherLight = C(0x463E3A), leatherDark = C(0x181414), brass = C(0xC8963A)
    let mask = C(0x3E3836), maskLight = C(0x5A524E), lens = C(0xFFB42A), lensLight = C(0xFFF0B0)
    let steel = C(0xD0D4DC)
    let sig = p.signature
    var tilt = 0
    var glow = 0.0
    if let s = sig {
        let k = habitArc(s, hold: 0.7)
        tilt = s < 0.5 ? Int((k * 2).rounded()) : -Int((k * 2).rounded())
        glow = k
    }
    drawLegs(c, Look(leg: leatherDark), step: p.step)
    drawBoots(c, C(0x0C0A0A), step: p.step, rows: 3)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 39, brass) } }
    c.oy += p.breathe
    drawBody(c, Look(body: mask, shade: C(0x2A2624), arm: leather, eye: nil))
    // The owl mask. When he cocks his head one side rises and the other drops: ear tufts, brows and goggles with it.
    c.pattern(17, 20, [
        "...MMMMMMMMMMMMMMM....",
        ".MMMMLLMMMMMMMMMMMMM..",
        "MMMLLMMMMMMMMMMMMMMMM.",
        "MMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMM",
    ], ["M": mask, "L": maskLight])
    for (i, ex) in [19, 31].enumerated() {
        let dy = i == 0 ? -tilt : tilt
        let ear: [String] = i == 0 ? ["M...", "MM..", "MMM.", "MMMM"] : ["...M", "..MM", ".MMM", "MMMM"]
        c.pattern(ex, 16 + dy, ear, ["M": mask])
        if dy > 0 { c.rect(ex, 20, 4, dy, mask) }
        if dy < 0 { c.rect(ex, 19 + dy, 4, 1 - dy, mask) }
        let brow: [String] = i == 0 ? ["LL....", ".LLL..", "...LLL"] : ["....LL", "..LLL.", "LLL..."]
        c.pattern(i == 0 ? 19 : 31, 25 + dy, brow, ["L": maskLight])
        // The goggles: brass rims, gold lenses, flaring when he looks round.
        let gx = i == 0 ? 20 : 30, gy = 27 + dy
        c.pattern(gx, gy, [".BBBB.", "BLLLLB", "BLWLLB", "BLLLLB", ".BBBB."], ["B": brass, "L": lens, "W": lensLight])
        if glow > 0.2 {
            c.glowLine(Double(gx) + 3, Double(gy) + 2.5, Double(gx) + 3, Double(gy) + 2.5, core: clear, glow: lens,
                       coreR: 0, glowR: 2 + 2.5 * glow, strength: 0.6 * glow)
        }
    }
    // The beak.
    c.pattern(27, 30, ["BB", "BB", ".B"], ["B": C(0xD8CCB0)])
    // Black leather below, the bandolier of knives across the chest.
    c.rect(18, 33, 20, 5, leather)
    c.rect(18, 33, 20, 1, leatherLight)
    for k in 0..<6 {
        let x = 20 + k * 3, y = 37 - k
        c.px(x, y, leatherLight); c.px(x + 1, y, leatherLight)
        if k > 0 && k < 5 { c.rect(x + 1, y - 2, 1, 2, steel); c.px(x + 1, y, brass) }
    }
    c.rect(18, 37, 20, 1, leatherDark)
    c.rect(26, 36, 3, 2, brass)
    drawCoatTails(c, p, leather, leatherDark, bottom: 42)
    c.rect(15, 33, 3, 3, leather)
    if let s = sig, s > 0.3, s < 0.8 {
        // A loose feather drifting down.
        let f = (s - 0.3) / 0.5
        c.px(12 + Int(sin(f * 9) * 2), 22 + Int(f * 18), maskLight)
        c.px(13 + Int(sin(f * 9) * 2), 23 + Int(f * 18), mask)
    }
    if let a = p.melee {
        smear(c, hand, p.trail, from: 3, to: 13, steel)
        drawSword(c, at: hand, angle: a, length: 13, steel: steel, light: white, grip: leatherDark, guardCol: brass, guardHalf: 1.5)
    } else {
        // A knife reversed along the forearm, ready.
        c.rect(38, 33, 3, 3, leather)
        bar(c, 39.5, 35.5, 38.5, 41, steel, r: 0.5)
        c.px(39, 33, brass)
    }
}

// MARK: - Calendar Man

/// Calendar Man: Julian Day, bald, with dates inked over his scalp, in a maroon suit whose whole front is one big
/// calendar page (a red month header over a grid of days, today ringed in red). He clubs people with a rolled-up wall
/// calendar. Signature: he peels today's page off his chest and lets it flutter away, revealing tomorrow.
private func drawCalendarMan(_ c: PixelCanvas, _ p: Pose) {
    let page = C(0xF4F2EC), pageShade = C(0xC8C4BA), grid = C(0xA8A49C), red = C(0xC83A3A)
    let suit = C(0x7A2A3A), suitDark = C(0x561C28)
    let skin = C(0xE8D4C0), skinShade = C(0xC8B0A0)
    let s = p.signature
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, C(0x16161B), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil))
    // Bald, the dates inked over his scalp in rows.
    c.pattern(18, 22, ["....SSSSSSSSSSSS....", "..SSSSSSSSSSSSSSSS..", ".SSSSSSSSSSSSSSSSSS.", "SSSSSSSSSSSSSSSSSSSS"],
              ["S": skin])
    let tattoo = ink.alpha(0.45)
    for (x, y) in [(23, 23), (27, 23), (31, 23), (21, 25), (25, 25), (29, 25), (33, 25)] {
        c.px(x, y, tattoo); c.px(x + 1, y, tattoo); c.px(x + 1, y - 1, tattoo)
    }
    // Small smug eyes, one brow cocked, a smirk.
    c.rect(22, 27, 2, 2, ink); c.rect(32, 27, 2, 2, ink)
    c.rect(21, 26, 3, 1, skinShade); c.rect(31, 25, 3, 1, skinShade)
    c.rect(26, 29, 4, 1, skinShade); c.px(30, 28, skinShade)
    // The suit round the page: a high maroon collar and sides.
    c.rect(18, 30, 20, 8, suit)
    c.rect(37, 30, 1, 8, suitDark); c.rect(18, 37, 20, 1, suitDark)
    // The calendar page: red header with the month, the grid of days, today ringed.
    let torn = s.map { $0 > 0.42 } ?? false
    c.rect(20, 30, 16, 8, page)
    c.rect(20, 30, 16, 2, red)
    for x in stride(from: 22, to: 34, by: 2) { c.px(x, 30, C(0xF8D0C8)) }
    for x in stride(from: 22, to: 35, by: 3) { c.rect(x, 32, 1, 6, grid) }
    c.rect(20, 34, 16, 1, grid)
    for x in stride(from: 20, to: 35, by: 3) { c.px(x + 1, 33, ink.alpha(0.55)); c.px(x + 1, 36, ink.alpha(0.55)) }
    let ring = torn ? 26 : 23
    c.pattern(ring - 1, 35, [".RR.", "R..R", ".RR."], ["R": red])
    c.rect(15, 33, 3, 3, suit)

    if let a = p.melee {
        // The rolled-up wall calendar as a club.
        smear(c, hand, p.trail, from: 3, to: 13, page)
        let e0 = reach(hand, a, -2), e1 = reach(hand, a, 13)
        bar(c, e0.x, e0.y, e1.x, e1.y, page, r: 1.3)
        for d in [4.0, 7.0] { let q = reach(hand, a, d); c.px(Int(q.x), Int(q.y), grid) }
        let b0 = reach(hand, a, 10), b1 = reach(hand, a, 12)
        bar(c, b0.x, b0.y, b1.x, b1.y, red, r: 1.35)
        c.rect(38, 33, 3, 3, suit)
        return
    }
    if let s, s > 0.12, s < 0.95 {
        if s < 0.42 {
            // Peeling: his hand pinches the top corner and folds it down, the back of the page showing.
            let f = (s - 0.12) / 0.3
            let peel = 1 + Int((f * 5).rounded())
            for k in 0..<peel { c.rect(36 - peel + k, 30 + k, peel - k, 1, pageShade) }
            c.rect(36 - peel, 28 + Int(f * 2), 3, 3, suit)
        } else {
            // The page fluttering away, turning over as it goes.
            let f = (s - 0.42) / 0.53
            let fx = 40 + Int(f * 16 + sin(f * 12) * 2), fy = 28 + Int(f * 12)
            let flip = Int(f * 10) % 2 == 0
            c.pattern(fx, fy, flip ? ["RRRRR", "WgWgW", "WWWWW", "WgWgW"] : ["RR", "WW", "Wg", "WW", "Wg"],
                      ["R": red, "W": page, "g": grid])
            c.rect(38, 31, 3, 3, suit)
        }
        return
    }
    // The rolled calendar tucked under his back arm.
    bar(c, 9, 36, 19, 32, page, r: 1.2)
    c.rect(10, 34, 2, 2, red)
    c.rect(38, 33, 3, 3, suit)
}

// MARK: - Joker Goon

/// A Joker goon: a hired heavy in a purple hoodie under a grinning clown mask (white face, red nose and smile, green
/// fright wig), with a pistol. Signature: he pushes the mask up to scratch his nose, then pulls it back down.
private func drawJokerGoon(_ c: PixelCanvas, _ p: Pose) {
    let hoodie = C(0x5A3A8A), hoodieDark = C(0x3E2862), maskWhite = C(0xF4F2F0), maskShade = C(0xC8C4C0)
    let red = C(0xD8282E), wig = C(0x3AB84A), wigDark = C(0x248A34), jeans = C(0x2A3448)
    let lift = p.signature.map { Int((habitArc($0, hold: 0.5) * 7).rounded()) } ?? 0
    drawLegs(c, Look(leg: jeans), step: p.step)
    drawBoots(c, C(0x16161B), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: hoodie, eye: ink))
    // The hood up round his head.
    c.pattern(17, 22, ["....HHHHHHHHHHHHH.....", "..HHHHHHHHHHHHHHHHH...", ".HHHHHHHHHHHHHHHHHHH..", "HHHHHHHHHHHHHHHHHHHHH."],
              ["H": hoodie])
    c.rect(17, 26, 2, 7, hoodie); c.rect(37, 26, 1, 7, hoodieDark)
    if lift > 0 {
        // His plain face underneath: a bored look.
        c.rect(25, 33 - 1, 6, 1, clawdShade)
    }
    // The mask, pushed up `lift` pixels.
    let my = 26 - lift
    c.oy += 0
    c.pattern(19, my - 3, [".WW..W.W...W.W..WW.", "WWWWWWWWWWWWWWWWWWW"], ["W": wig])
    c.rect(19, my - 2, 2, 5, wig); c.rect(35, my - 2, 2, 5, wig); c.px(18, my, wigDark); c.px(37, my, wigDark)
    c.rect(19, my, 17, 8, maskWhite)
    c.rect(19, my + 7, 17, 1, maskShade)
    // Diamond eyes, a red nose and a huge red grin.
    c.pattern(21, my + 1, [".B.......B.", "BKB.....BKB", ".B.......B."], ["B": C(0x2A5AC8), "K": ink])
    c.rect(27, my + 3, 2, 2, red)
    c.pattern(21, my + 5, ["R...........R", ".RRRRRRRRRRR.", "..RRRRRRRRR.."].map { String($0.prefix(15)) },
              ["R": red])
    if lift > 3 {
        // The hand scratching the nose under it.
        c.rect(30, my + 9, 3, 3, hoodie); c.px(30, my + 8, clawdOrange)
    }
    // Hoodie body, a pouch pocket.
    c.rect(18, 34, 20, 4, hoodie)
    c.rect(22, 35, 12, 2, hoodieDark)
    c.rect(37, 34, 1, 4, hoodieDark); c.rect(18, 37, 20, 1, hoodieDark)
    c.rect(15, 33, 3, 3, hoodie)
    c.rect(38, 33, 3, 3, hoodie)
    drawPistol(c, x: 40, y: 31 + p.gunY)
}
