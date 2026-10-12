import Foundation

// Heroes: the Super-family and Metropolis. Clawd in costume as ever: the top of the block is the face (Clawd orange
// where they show skin), the S-shields, capes, hair and suits drawn over it. Krypto is a dog, a small white one.

let heroes3: [Companion: Persona] = [
    .supergirl: Persona(name: "Supergirl", weapon: .ranged, motion: .fly, shot: .beam(core: C(0xFFF4D0), glow: C(0xFF3A1E)),
                  muzzle: (34, 30), handGun: false, headTop: 20, signature: 3.2, callout: "Hope, help and compassion.",
                  draw: drawSupergirl),
    .superboy: Persona(name: "Superboy", weapon: .melee, motion: .fly, headTop: 21, signature: 2.8,
                  callout: "Clone. Yeah. I know.",
                  draw: drawSuperboy),
    .powerGirl: Persona(name: "Power Girl", weapon: .melee, motion: .fly, headTop: 20, signature: 3.2,
                  draw: drawPowerGirl),
    .steel: Persona(name: "Steel", weapon: .melee, motion: .fly, armoured: true, bulk: 1, headTop: 20, signature: 3.0,
                  callout: "Man of Steel? Man OF steel.",
                  draw: drawSteel),
    .jonKent: Persona(name: "Jon Kent", weapon: .ranged, motion: .fly, shot: .beam(core: C(0xFFF4D0), glow: C(0xFF3A1E)),
                  muzzle: (34, 30), handGun: false, headTop: 20, signature: 3.0, callout: "Up, up and away!",
                  draw: drawJonKent),
    .loisLane: Persona(name: "Lois Lane", headTop: 20, signature: 3.2, callout: "Lois Lane, Daily Planet.",
                  draw: drawLoisLane),
    .jimmyOlsen: Persona(name: "Jimmy Olsen", headTop: 20, signature: 2.6, callout: "Jeepers!",
                  draw: drawJimmyOlsen),
    .alfred: Persona(name: "Alfred", headTop: 24, signature: 3.4, callout: "Tea, sir?",
                  draw: drawAlfred),
    .luciusFox: Persona(name: "Lucius Fox", headTop: 22, signature: 3.4, callout: "Does it come in black?",
                  draw: drawLuciusFox),
    .krypto: Persona(name: "Krypto", weapon: .melee, motion: .fly, bulk: 3, headTop: 23, signature: 2.8,
                  draw: drawKrypto),
]

// MARK: - Shared pieces

private let clear = C(0x000000, 0)
private let suitBlue = C(0x2A4FB0), suitBlueDark = C(0x1C3478)
private let capeRed = C(0xC8202A), capeRedDark = C(0x8A1218), shieldYellow = C(0xF2C830)

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from `h` along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// A punch: the arm thrown out along `angle`, a fist on the end and faint fists where a fast swing just was.
private func drawPunch(_ c: PixelCanvas, angle: Double, trail: [Double], arm: Px, fist: Px, reach: Double = 6) {
    let h = Sprite.hand
    for (i, a) in trail.enumerated() {
        let e = along(a, reach)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist.alpha(0.35 / Double(i + 1)))
    }
    let e = along(angle, reach)
    bar(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist)
}

/// Legs standing or walking with boots in `boot` (the bottom `rows`), or swept back in flight.
private func drawSuitLegs(_ c: PixelCanvas, _ p: Pose, _ leg: Px, boot: Px, rows: Int) {
    if p.flying {
        let sweep: [(Int, Int)] = [(0, 36), (0, 37), (-1, 38), (-2, 39), (-3, 40), (-4, 41)]
        for lx in [19, 23, 31, 35] {
            for (i, s) in sweep.enumerated() {
                c.rect(lx + s.0, s.1, 2, 1, i >= sweep.count - rows ? boot : leg)
            }
        }
        return
    }
    drawLegs(c, Look(leg: leg), step: p.step)
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx + 1, 38, 2, 2, boot) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, (lifted ? 42 : 43) - rows + 1, 2, rows, boot)
    }
}

/// The S-shield, its top-left at (`x`, `y`): a 7×5 pentagon, the S in `s` on a `field` ground (clear: just the S).
private func drawSShield(_ c: PixelCanvas, x: Int, y: Int, field: Px, s: Px = capeRed) {
    c.pattern(x, y, [
        "FSSSSSF",
        "SFFFFFS",
        ".SSSSS.",
        "..FFS..",
        "...S...",
    ], ["F": field, "S": s])
    c.px(x + 1, y + 1, s)
}

/// Eyes burning with heat vision, `k` 0…1 how hot.
private func heatEyes(_ c: PixelCanvas, _ k: Double, t: Double) {
    guard k > 0.02 else { return }
    let flick = 0.85 + 0.15 * sin(t * 47)
    for x in [22.5, 32.5] {
        c.glowLine(x, 29.5, x, 30.5, core: C(0xFFF4D0).alpha(k), glow: C(0xFF3A1E).alpha(k * flick), coreR: 0.7, glowR: 2)
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

/// A flickering jet flame pointing down from (`x`, `y`), `w` wide.
private func drawJet(_ c: PixelCanvas, x: Int, y: Int, w: Int, t: Double, seed: Int) {
    let len = 2 + Int(noise(Int(t * 30) + seed) * 3)
    c.rect(x, y, w, len + 1, C(0xFF9A2A, 0.85))
    c.rect(x + (w > 2 ? 1 : 0), y, max(1, w - 2), len, C(0xFFE27A))
    c.rect(x, y, w, 1, C(0xF4FCFF))
}

/// A cape hanging down the back, seen from the side: it shows past the shoulder blade and between the legs, so the
/// legs still read in front of it. Its hem sways at `speed`.
private func drawBackCape(_ c: PixelCanvas, t: Double, speed: Double, color: Px, edge: Px) {
    for y in 27...43 where y + c.oy <= 43 {
        let k = Double(y - 27) / 16
        let sway = sin(t * speed + k * 2.2) * k * 1.6
        let l = Int((15.5 - k * 3.5 + sway).rounded())
        let r = 24 + Int((k * 2).rounded())
        c.rect(l, y, r - l + 1, 1, color)
        c.px(l, y, edge)
    }
}

/// A cape streaming out behind (to the left) in flight.
private func drawFlyingCape(_ c: PixelCanvas, t: Double, color: Px, edge: Px, top y0: Double = 29) {
    for x in 3...20 {
        let k = Double(20 - x) / 17
        let mid = y0 + k * 4 + sin(t * 9 - k * 5) * k * 1.6
        let half = 3 + k * 2
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, color)
        c.px(x, top, edge); c.px(x, bottom, edge)
    }
}

/// A four-pointed twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] as [(Int, Int)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, and leaning
/// forward one pixel every `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x + shift, y, unpremultiplied(s, i).alpha(alpha))
        }
    }
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

/// Long blonde hair over the head and down both sides of the face (Supergirl), lifted `up` pixels.
private func drawLongHair(_ c: PixelCanvas, up: Int, hair: Px, dark: Px) {
    c.pattern(16, 20 - up, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHHHhHHHHHHHHHH...",
        "..HHHhHHHHHHHHHHhHHHHH..",
        "..HHHHHHHHHHHhHHHHHHHH..",
        ".HHHHHHHHHh.....hHHHHH..",
        ".HHHHh...........hHHHH..",
    ], ["H": hair, "h": dark])
    c.pattern(15, 27, [
        ".HHHh..............hHHH.",
        "HHHh................hHH.",
        "HHHh................hHH.",
        "HHHH.................HH.",
        "HHh..................hH.",
        "HHh..................hH.",
        "HH....................H.",
        "H.......................",
    ], ["H": hair, "h": dark])
}

// MARK: - Supergirl

/// Supergirl: Clawd with long blonde hair, the blue top with the S-shield, a red skirt, red cape and red boots. Her
/// heat vision comes from her eyes, and in flight she leans into it, one fist forward, cape and hair streaming.
/// Signature: she floats up off the ground, cape billowing, takes a breath and blows a frosty gust of super-breath,
/// snowflakes and all, then settles back down.
private func drawSupergirl(_ c: PixelCanvas, _ p: Pose) {
    let blue = suitBlue, blueDark = suitBlueDark, red = capeRed, redDark = capeRedDark
    let hair = C(0xF2D470), hairDark = C(0xC8A440)
    let rise = p.signature.map { Int((6 * habitArc($0, hold: 0.55)).rounded()) } ?? 0
    let blow = p.signature.map { s -> Double in s > 0.32 && s < 0.78 ? habitArc((s - 0.32) / 0.46, hold: 0.5) : 0 } ?? 0
    if rise > 2 { drawAirWash(c, t: p.t) }
    c.oy -= rise
    let firing = p.fire != nil
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: red, edge: redDark)
        } else {
            drawBackCape(c, t: p.t, speed: rise > 0 ? 4 : p.capeSpeed, color: red, edge: redDark)
        }
        drawSuitLegs(c, p, clawdOrange, boot: red, rows: 3)
        c.oy += p.breathe
        drawBody(c, Look(arm: blue))
        drawLongHair(c, up: rise > 3 ? 1 : 0, hair: hair, dark: hairDark)
        // Blue top, the shield, a gold belt and the red skirt flaring over the legs.
        c.rect(18, 33, 20, 4, blue)
        c.rect(37, 33, 1, 4, blueDark)
        c.rect(18, 37, 20, 1, C(0xE8B830))
        drawSShield(c, x: 25, y: 33, field: shieldYellow)
        c.rect(17, 38, 22, 1, red)
        if !seatedPose { c.rect(16, 39, 24, 1, red); for x in [20, 25, 30, 35] { c.px(x, 39, redDark) } }
        heatEyes(c, firing ? 1 : (p.ready ? 0.4 : 0), t: p.t)
        if blow > 0.05 {
            // Cheeks puffed, a frosty gust from the lips.
            c.rect(35, 32, 2, 1, C(0x7A2A1A))
            let reach = 8 + 18 * blow
            c.glowLine(37, 32.5, 37 + reach, 34, core: C(0xF4FCFF, 0.8 * blow), glow: C(0x9AD8FF, 0.6 * blow), coreR: 0.6, glowR: 2.2)
            for i in 0..<5 {
                let f = frac(p.t * 1.7 + Double(i) * 0.21)
                let x = 39 + Int(f * reach), y = 32 + Int(sin(Double(i) * 2.1 + p.t * 6) * 2.5 + f * 2)
                twinkle(c, x, y, C(0xCFEFFF, blow * (1 - f * 0.5)))
            }
        }
        c.rect(15, 33, 3, 3, blue)
        if p.flying {
            c.rect(38, 31, 3, 3, blue); c.rect(41, 31, 2, 3, clawdOrange)
            return
        }
        if p.cheering {
            c.rect(38, 28, 3, 3, blue); c.rect(39, 26, 2, 2, clawdOrange)
        } else {
            c.rect(38, 33, 3, 3, blue); c.rect(40, 34, 1, 2, clawdOrange)
        }
    }
}

// MARK: - Superboy

/// Superboy (Conner Kent): Clawd with short black hair, a black tee with the red S on it, the brown leather jacket
/// over it, jeans and boots. No cape. He fights with his fists and flies fist-first. Signature: he cracks his
/// knuckles, jumps and punches the ground, and it cracks open under him in a puff of dust (tactile telekinesis).
private func drawSuperboy(_ c: PixelCanvas, _ p: Pose) {
    let tee = C(0x24242C), leather = C(0x6A3E24), leatherDark = C(0x4A2A18), denim = C(0x3A5A8A), boot = C(0x2A2A30)
    let hair = C(0x16161B), red = C(0xD8202A)
    let s = p.signature ?? -1
    // 0…0.3 knuckles, 0.3…0.45 the jump, 0.45 the punch lands, then the cracks spread and the dust settles.
    let jump = s >= 0.3 && s < 0.45 ? Int((-4 * sin((s - 0.3) / 0.15 * .pi)).rounded()) : 0
    let landed = s >= 0.45
    if landed {
        let k = min(1, (s - 0.45) / 0.2), fade = s > 0.8 ? (1 - s) / 0.2 : 1
        let crack = C(0x16161B, fade)
        let len = Int(4 + 10 * k)
        for (dx, dir) in [(0, 1), (0, -1)] as [(Int, Int)] {
            var x = 44 + dx, y = 44
            for i in 0..<len {
                x += dir; if noise(i * 7 + dir) > 0.6 { y += 1 }
                c.px(x, min(y, 47), crack)
            }
        }
        if s < 0.8 {
            for i in 0..<6 {
                let f = min(1, (s - 0.45) / 0.35)
                let x = 44 + Int((noise(i * 3) - 0.5) * 18 * f), y = 43 - Int(noise(i * 5 + 1) * 5 * f)
                c.rect(x, y, 2, 1, C(0xB8A890, 0.7 * (1 - f)))
            }
        }
    }
    c.oy += jump
    layer(c, lean: p.flying ? 4 : 0) { c in
        drawSuitLegs(c, p, denim, boot: boot, rows: 2)
        c.oy += p.breathe
        drawBody(c, Look(arm: leather))
        c.pattern(18, 21, [
            "...K..K.K..KK.K.....",
            "..KKKKKKKKKKKKKKKK..",
            ".KKKKKKKKKKKKKKKKKK.",
            "KKKKKKKKKKKKKKKKKKKK",
            "KKKK.KK.KK.KKKK.KKKK",
            "KK..............K.KK",
            "K..................K",
        ], ["K": hair])
        c.rect(18, 33, 20, 5, tee)
        drawSShield(c, x: 25, y: 33, field: clear, s: red)
        c.rect(18, 33, 4, 5, leather); c.rect(34, 33, 4, 5, leather)
        c.rect(21, 34, 1, 4, leatherDark); c.rect(34, 34, 1, 4, leatherDark)
        c.rect(37, 33, 1, 5, leatherDark)
        c.px(22, 33, leather); c.px(33, 33, leather)                         // the lapels
        c.rect(15, 33, 3, 3, leather)
        if p.flying {
            c.rect(38, 31, 3, 3, leather); c.rect(41, 31, 2, 3, clawdOrange)
            return
        }
        if s >= 0 && s < 0.3 {
            // Knuckles: both fists together in front of his chest, a little pop on every crack.
            c.rect(36, 32, 4, 3, clawdOrange); c.rect(38, 31, 1, 1, clawdShade)
            if frac(s / 0.1) < 0.3 { twinkle(c, 41, 30, C(0xFFF4D0)) }
        } else if s >= 0.3 && s < 0.45 {
            c.rect(38, 27, 3, 3, leather); c.rect(38, 24, 3, 3, clawdOrange)          // fist up
        } else if landed && s < 0.8 {
            bar(c, 39, 34, 43, 41, leather, 1.2); c.rect(42, 40, 3, 3, clawdOrange)   // fist in the ground
        } else if let a = p.melee {
            drawPunch(c, angle: a, trail: p.trail, arm: leather, fist: clawdOrange)
        } else if p.cheering {
            c.rect(38, 28, 3, 3, leather); c.rect(38, 25, 3, 3, clawdOrange)
        } else {
            c.rect(38, 33, 3, 3, leather); c.rect(40, 34, 1, 2, clawdOrange)
        }
    }
}

// MARK: - Power Girl

/// Power Girl: Clawd with a short blonde bob, the white suit with blue gloves and tall blue boots, a gold clasp at
/// her collar and a red cape. Fists, and she flies. Signature: she hauls a steel girder up over her head one-handed,
/// bends it into a horseshoe, and drops it.
private func drawPowerGirl(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xF2F2F4), suitShade = C(0xC8CCD6), blue = suitBlue, gold = C(0xE8B830)
    let hair = C(0xF2D470), hairDark = C(0xC8A440)
    let s = p.signature ?? -1
    let lifting = s > 0.04 && s < 0.96
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: capeRed, edge: capeRedDark)
        } else {
            drawBackCape(c, t: p.t, speed: p.capeSpeed, color: capeRed, edge: capeRedDark)
        }
        drawSuitLegs(c, p, clawdOrange, boot: blue, rows: 4)
        c.oy += p.breathe
        drawBody(c, Look(arm: blue))
        // The bob: a straight fringe, cut level at the jaw.
        c.pattern(16, 20, [
            ".....HHHHHHHHHHHH.......",
            "...HHHHHHHHHHHHHHHH.....",
            "..HHHHHhHHHHHHHHHHHH....",
            ".HHHHHHHHHHHHHHHHHHHH...",
            ".HHHHHHHHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHHHHHHHHH..",
            "HHHHhhhhhhhhhhhhhhhHHH..",
            "HHHh...............hHH..",
            "HHHh................HH..",
            "HHHh................hH..",
            "HHHh................hH..",
            "HHhh................hh..",
        ], ["H": hair, "h": hairDark])
        c.rect(18, 33, 20, 5, suit)
        c.rect(37, 33, 1, 5, suitShade)
        c.rect(18, 37, 20, 1, suitShade)
        c.rect(18, 33, 4, 2, capeRed); c.rect(34, 33, 4, 2, capeRed)        // the cape over her shoulders
        c.px(21, 34, gold); c.px(34, 34, gold)                              // and its clasps
        c.rect(18, 37, 20, 1, blue)                                          // a blue belt
        c.rect(15, 33, 3, 3, blue)
        if p.flying {
            c.rect(38, 31, 5, 3, blue)
            return
        }
        if lifting {
            let up = min(1, (s - 0.04) / 0.2)
            let bend = s < 0.3 ? 0 : min(1, (s - 0.3) / 0.35)
            let drop = s > 0.82 ? (s - 0.82) / 0.14 : 0
            let hy = 33 - 13 * up + 15 * drop * drop
            c.rect(38, Int(hy) + 2, 3, 33 - Int(hy), blue)
            drawGirder(c, cx: 40, cy: hy - 1, bend: bend)
            if bend > 0 && bend < 1 && Int(p.t * 20) % 2 == 0 { twinkle(c, 40, Int(hy) - 3, C(0xFFE8A0)) }
        } else if let a = p.melee {
            drawPunch(c, angle: a, trail: p.trail, arm: blue, fist: blue)
        } else if p.cheering {
            c.rect(38, 26, 3, 5, blue)
        } else {
            c.rect(38, 33, 3, 3, blue)
        }
    }
}

/// A steel I-beam held across the hand at (`cx`, `cy`), bent down at both ends by `bend` (0 straight, 1 a horseshoe).
private func drawGirder(_ c: PixelCanvas, cx: Double, cy: Double, bend: Double) {
    let steel = C(0xB8502A), dark = C(0x7A3018), rivet = C(0xE8A070)
    let half: Double = 11
    for side in [-1.0, 1.0] {
        var prev = (x: cx, y: cy)
        let n = 6
        for i in 1...n {
            let f = Double(i) / Double(n)
            let a: Double = bend * 1.9 * f
            let step: Double = half / Double(n)
            let q = (x: prev.x + side * cos(a) * step, y: prev.y + sin(a) * step)
            bar(c, prev.x, prev.y, q.x, q.y, steel, 1.3)
            prev = q
        }
        c.px(Int(prev.x.rounded()), Int(prev.y.rounded()), dark)
    }
    c.rect(Int(cx) - 1, Int(cy) - 1, 3, 1, dark)
    c.px(Int(cx) - 4, Int(cy), rivet); c.px(Int(cx) + 4, Int(cy), rivet)
}

// MARK: - Steel

/// Steel (John Henry Irons): Clawd in grey steel armour with rivets down the plates, a full helmet with a narrow
/// visor, the red S-shield on the chest and a red cape; rocket boots for flying. The big sledgehammer is the weapon,
/// head-down by his hand when he's not swinging it. Signature: he tosses a rivet up, winds back and smacks it off
/// across the screen, red hot.
private func drawSteel(_ c: PixelCanvas, _ p: Pose) {
    let steel = C(0x8A929E), dark = C(0x5A626E), light = C(0xC8CED6), visor = C(0x1A1E26)
    let s = p.signature ?? -1
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: capeRed, edge: capeRedDark)
            for lx in [21, 31] {
                c.rect(lx, 36, 4, 5, steel); c.rect(lx + 3, 36, 1, 5, dark); c.rect(lx, 39, 4, 2, dark)
                drawJet(c, x: lx, y: 41, w: 4, t: p.t, seed: lx)
            }
        } else {
            drawBackCape(c, t: p.t, speed: p.capeSpeed, color: capeRed, edge: capeRedDark)
            drawLegs(c, Look(leg: steel), step: p.step)
            drawBoots(c, dark, step: p.step, rows: 3)
            if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 38, 2, 1, light) } }
        }
        c.oy += p.breathe
        drawBody(c, Look(body: steel, shade: dark, arm: steel, eye: nil))
        // Helmet: a domed cap with a crest, the visor slit and a grille at the mouth.
        c.pattern(17, 20, [
            ".......LLLLLLLL.......",
            ".....LLSSSSSSSSSS.....",
            "....LSSSSSSSSSSSSSD...",
            "...LSSSSSSSSSSSSSSSD..",
            "..LSSSSSSSSSSSSSSSSSD.",
            "..SSSSSSSSSSSSSSSSSSD.",
            ".SSSSSSSSSSSSSSSSSSSD.",
        ], ["S": steel, "L": light, "D": dark])
        c.rect(19, 28, 19, 3, visor)
        c.rect(21, 29, 3, 1, C(0xFF5A3A)); c.rect(31, 29, 3, 1, C(0xFF5A3A))
        c.rect(19, 27, 19, 1, light)
        for x in stride(from: 26, through: 32, by: 2) { c.px(x, 32, dark) }
        // Chest plate with the shield, rivets down the edges.
        c.rect(18, 33, 20, 1, dark)
        drawSShield(c, x: 25, y: 34, field: light)
        for y in [34, 36] { c.px(19, y, light); c.px(36, y, light) }
        c.rect(15, 33, 3, 3, dark)
        if p.flying {
            c.rect(38, 31, 4, 3, steel)
            drawHammer(c, at: (41.5, 32.5), angle: -15)
            return
        }
        if s > 0.04 && s < 0.96 {
            // The rivet goes up from his left hand, comes down, and gets hit.
            let swing: Double = s < 0.42 ? -60 - 100 * min(1, (s - 0.04) / 0.3) : (s < 0.5 ? -160 + 165 * (s - 0.42) / 0.08 : 5)
            if s < 0.5 {
                let k = (s - 0.04) / 0.46
                let ry = 30 - 18 * sin(k * .pi)
                c.rect(Int(39 + 4 * k), Int(ry), 2, 2, C(0xFF7A2A))
                c.px(Int(39 + 4 * k), Int(ry), C(0xFFE8A0))
            } else {
                let f = (s - 0.5) / 0.46
                let rx = 46 + f * 30
                c.glowLine(rx - 8, 30, rx, 30 - f * 4, core: C(0xFFE8A0), glow: C(0xFF5A1E), coreR: 0.6, glowR: 1.8)
                if f < 0.15 { drawSparks(c, x: 47, y: 31, t: p.t, size: 3) }
            }
            let trail: [Double] = s > 0.42 && s < 0.52 ? [swing - 40, swing - 80] : []
            for (i, a) in trail.enumerated() { drawHammer(c, at: Sprite.hand, angle: a, alpha: 0.35 / Double(i + 1)) }
            drawHammer(c, at: Sprite.hand, angle: swing)
        } else if let a = p.melee {
            for (i, ta) in p.trail.enumerated() { drawHammer(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) }
            drawHammer(c, at: Sprite.hand, angle: a)
        } else {
            c.rect(38, 33, 3, 3, steel)
            drawHammer(c, at: (40.5, seatedPose ? 28.5 : 31.5), angle: 90)   // standing on its head by his hand
        }
    }
}

/// Steel's sledgehammer, its grip in the hand at `at`, head out along `angle` degrees.
private func drawHammer(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        let grip = C(0x3A2A20), shaft = C(0x6A707C), head = C(0x7A828E), light = C(0xC8CED6), dark = C(0x464C58)
        s.rect(17, 20, 3, 1, grip)
        s.rect(20, 20, 8, 1, shaft)
        s.rect(28, 16, 6, 9, head)
        s.rect(28, 16, 6, 1, light); s.rect(28, 16, 1, 9, light)
        s.rect(33, 17, 1, 8, dark); s.rect(29, 24, 5, 1, dark)
        s.rect(28, 19, 6, 1, dark); s.rect(28, 21, 6, 1, dark)
    }
}

// MARK: - Jon Kent

/// Jon Kent: Clawd as the young Superboy, messy black hair, a blue tee with the S-shield under an open maroon hoodie
/// (the red cape fastened to it), rolled jeans and red sneakers. Heat vision from the eyes.
/// Signature: he squints, his eyes sputter and fizz, a stray blast scorches the ground in front of him, and he
/// scratches his head over the little smoking spot.
private func drawJonKent(_ c: PixelCanvas, _ p: Pose) {
    let tee = suitBlue, hoodie = C(0x8A1E2A), hoodieDark = C(0x5A1018), denim = C(0x4A6A9A), sneaker = C(0xD82A2A)
    let hair = C(0x1A1A22)
    let s = p.signature ?? -1
    let sputter = s > 0.05 && s < 0.5
    let blast = s >= 0.5 && s < 0.66
    let sheepish = s >= 0.66
    if s >= 0.56 {
        // The scorch mark, smoking.
        let fade = s > 0.9 ? (1 - s) / 0.1 : 1
        c.rect(52, 43, 5, 1, C(0x2A1A10, fade)); c.px(53, 42, C(0xFF7A2A, fade * 0.8))
        for i in 0..<3 {
            let f = frac((s - 0.56) * 3 + Double(i) / 3)
            c.px(54 + Int(sin(f * 6 + Double(i)) * 1.5), 41 - Int(f * 8), C(0xB8B8C0, 0.6 * (1 - f) * fade))
        }
    }
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: capeRed, edge: capeRedDark)
        } else {
            drawBackCape(c, t: p.t, speed: p.capeSpeed, color: capeRed, edge: capeRedDark)
        }
        drawSuitLegs(c, p, denim, boot: sneaker, rows: 2)
        if !p.flying && !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let lifted = p.step >= 0 && i % 2 == p.step
                c.rect(lx, lifted ? 40 : 41, 2, 1, C(0x8AAACA))      // the rolled-up cuffs
            }
        }
        c.oy += p.breathe
        drawBody(c, Look(arm: hoodie))
        c.pattern(17, 20, [
            ".....K..KK..K..K......",
            "...KKKKKKKKKKKKKKK....",
            "..KKKKKKKKKKKKKKKKKK..",
            ".KKKKKKKKKKKKKKKKKKKK.",
            ".KKKKKKKKKKKKKKKKKKKK.",
            ".KKK.KKKK.K....K.KKKK.",
            ".KK.....K.........KK..",
        ], ["K": hair])
        c.px(29, 26, hair); c.px(30, 27, hair)                           // the curl over his brow
        c.rect(18, 33, 20, 5, tee)
        drawSShield(c, x: 25, y: 33, field: shieldYellow)
        c.rect(18, 33, 4, 5, hoodie); c.rect(35, 33, 3, 5, hoodie)
        c.rect(21, 34, 1, 4, hoodieDark); c.rect(35, 34, 1, 4, hoodieDark)
        c.rect(18, 37, 20, 1, C(0x2A3A6A))                                   // jeans' waistband
        c.rect(18, 37, 4, 1, hoodie); c.rect(35, 37, 3, 1, hoodie)
        heatEyes(c, p.fire != nil ? 1 : (blast ? 1 : (p.ready ? 0.4 : 0)), t: p.t)
        if sputter {
            let on = noise(Int(p.t * 18)) > 0.45
            heatEyes(c, on ? 0.8 : 0.15, t: p.t)
            if on { c.px(35 + Int(noise(Int(p.t * 25)) * 4), 28 + Int(noise(Int(p.t * 25) + 3) * 4), C(0xFFB02A)) }
            c.rect(22, 29, 2, 1, clawdOrange); c.rect(32, 29, 2, 1, clawdOrange)   // squinting
        }
        if blast {
            let k = (s - 0.5) / 0.16
            c.glowLine(34, 30.5, 34 + 20 * min(1, k * 2), 30.5 + 13 * min(1, k * 2),
                       core: C(0xFFF4D0), glow: C(0xFF3A1E), coreR: 0.6, glowR: 2)
        }
        c.rect(15, 33, 3, 3, hoodie)
        if p.flying {
            c.rect(38, 31, 3, 3, hoodie); c.rect(41, 31, 2, 3, clawdOrange)
            return
        }
        if sheepish {
            c.rect(37, 25, 3, 5, hoodie); c.rect(36, 23, 3, 2, clawdOrange)   // scratching his head
        } else if p.cheering {
            c.rect(38, 28, 3, 3, hoodie); c.rect(38, 25, 3, 3, clawdOrange)
        } else {
            c.rect(38, 33, 3, 3, hoodie); c.rect(40, 34, 1, 2, clawdOrange)
        }
    }
}

// MARK: - Lois Lane

/// Lois Lane: Clawd with dark shoulder-length hair parted at the side, a pencil behind her ear, a purple suit jacket
/// over a white blouse, a pencil skirt and dark tights. She doesn't fight: in a fight she cheers with her notepad.
/// Signature: the pencil comes out, she scribbles furiously, then tears off the page and holds up the scoop.
private func drawLoisLane(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x6A3A8A), jacketDark = C(0x4A2466), blouse = C(0xF2F2F4), skirt = C(0x3A2A4A), tights = C(0x2E2A34)
    let hair = C(0x3A2418), hairDark = C(0x241410), pencil = C(0xF2C830), paper = C(0xF4F2E8), line = C(0x8A8AA0)
    let s = p.signature ?? -1
    let scribble = s > 0.06 && s < 0.6
    let scoop = s >= 0.6 && s < 0.96
    drawLegs(c, Look(leg: tights), step: p.step)
    drawBoots(c, C(0x16161B), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket))
    c.pattern(16, 20, [
        "......HHHHHHHHHH........",
        "....HHHHHHHHHHHHHH......",
        "...HHHHHHHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHhhHHHH...",
        "..HHHHHHHHHHHHh...hHHH..",
        ".HHHHHHHHHHHh......hHH..",
        ".HHHHhh.............HH..",
        ".HHHh...............hH..",
        ".HHH................hH..",
        ".HHH.................H..",
        "HHHh.................H..",
        "HHH.....................",
        "HHh.....................",
    ], ["H": hair, "h": hairDark])
    if !scribble { bar(c, 36, 23, 39, 21, pencil, 0.5); c.px(39, 21, C(0x2A2A30)) }   // behind her ear
    c.rect(18, 32, 20, 4, jacket)
    c.pattern(25, 32, ["WWWWWW", ".WWWW.", "..WW.."], ["W": blouse])
    c.rect(37, 32, 1, 4, jacketDark)
    c.rect(22, 34, 1, 2, jacketDark); c.rect(33, 34, 1, 2, jacketDark)
    c.rect(18, 36, 20, 2, skirt)
    c.rect(19, 38, 18, 1, skirt)
    c.rect(15, 33, 3, 3, jacket)
    if scribble {
        // Notepad up in front of her, the pencil going like mad.
        c.rect(38, 31, 3, 3, jacket)
        c.rect(40, 27, 6, 7, paper); c.rect(40, 27, 6, 1, C(0xC8202A))
        let rows = Int((s - 0.06) / 0.54 * 9)
        for r in 0..<min(rows, 5) {
            let w = 2 + Int(noise(r * 3) * 3)
            c.rect(41, 29 + r, w, 1, line)
        }
        let k = Int(p.t * 22) % 3
        bar(c, Double(42 + k), Double(29 + min(rows, 4)), Double(46 + k), Double(26 + min(rows, 4)), pencil, 0.5)
    } else if scoop {
        // The page held up high: got it.
        let k = min(1, (s - 0.6) / 0.08)
        let y = 27 - Int(7 * k)
        c.rect(38, y + 5, 3, 33 - y - 5, jacket)
        c.rect(38, y - 2, 6, 7, paper)
        for r in 0..<4 { c.rect(39, y + r, 2 + (r % 2) * 2, 1, line) }
        c.rect(38, y - 2, 6, 1, C(0xC8202A))
        if k >= 1 {
            c.rect(46, y - 4, 1, 4, C(0xFFD25A)); c.px(46, y + 1, C(0xFFD25A))
            if Int(p.t * 8) % 2 == 0 { twinkle(c, 35, y - 4, C(0xFFD25A)) }
        }
    } else if p.cheering {
        c.rect(38, 27, 3, 4, jacket)
        c.rect(38, 22, 5, 6, paper); c.rect(38, 22, 5, 1, C(0xC8202A))
    } else {
        c.rect(38, 33, 3, 3, jacket)
        c.rect(40, 32, 4, 5, paper); c.rect(40, 32, 4, 1, C(0xC8202A))
        c.rect(41, 34, 2, 1, line)
    }
}

// MARK: - Jimmy Olsen

/// Jimmy Olsen: Clawd with a red mop of hair and freckles, a green jacket over a white shirt, the green bow tie, and
/// his camera hanging round his neck. He doesn't fight; he cheers with the camera. Signature: up goes the camera, he
/// lines up the shot, and the flash goes off.
private func drawJimmyOlsen(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x3A7A44), jacketDark = C(0x285A30), shirt = C(0xF2F2F4), tie = C(0x2A8A3A), slacks = C(0x6A6A74)
    let hair = C(0xD0602A), hairDark = C(0xA0401A), freckle = C(0xB8502E)
    let s = p.signature ?? -1
    let shooting = s > 0.08 && s < 0.9
    drawLegs(c, Look(leg: slacks), step: p.step)
    drawBoots(c, C(0x4A2A1A), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket))
    c.pattern(17, 20, [
        "....HH.HHHH.HH........",
        "..HHHHHHHHHHHHHHH.....",
        ".HHHHHHHHHHHHHHHHHH...",
        "HHHHHHHHHHHHHHHHHHHH..",
        "HHHHHHhHHHHHHHhHHHHHH.",
        "HHHh..hHH..H..hHHhHHH.",
        ".HH...........h...HH..",
    ], ["H": hair, "h": hairDark])
    for (x, y) in [(20, 31), (22, 32), (24, 31), (31, 31), (33, 32), (35, 31)] as [(Int, Int)] { c.px(x, y, freckle) }
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, shirt)
    c.rect(37, 33, 1, 5, jacketDark)
    c.pattern(25, 32, ["TT..TT", "TTTTTT", "TT..TT"], ["T": tie])
    c.rect(15, 33, 3, 3, jacket)
    if shooting {
        // Camera up to his eye; the flash at the middle.
        let up = min(1, (s - 0.08) / 0.15)
        let cy = Int(36 - 7 * up)
        c.rect(36, cy, 7, 5, C(0x24242C)); c.rect(36, cy, 7, 1, C(0x4A4A56))
        c.rect(42, cy + 1, 2, 3, C(0x5A5A68)); c.px(43, cy + 2, C(0x9AD0FF))
        c.rect(37, cy - 1, 2, 1, C(0x8A8A96))
        c.rect(38, cy + 4, 3, 33 - cy, jacket)
        let f = s - 0.45
        if f > 0 && f < 0.12 {
            let k = 1 - f / 0.12
            c.ellipse(41, cy - 1, Int(4 + 10 * k), Int(3 + 8 * k), C(0xFFFFFF, 0.35 * k))
            c.glowLine(41, Double(cy) - 1, 41, Double(cy) - 1, core: white, glow: C(0xFFF6C8, k), coreR: 1.5, glowR: 4 + 3 * k)
            for i in 0..<6 {
                let a: Double = Double(i) * .pi / 3
                c.glowLine(41 + cos(a) * 4, Double(cy) - 1 + sin(a) * 4, 41 + cos(a) * (6 + 6 * k), Double(cy) - 1 + sin(a) * (6 + 6 * k),
                           core: C(0xFFFFFF, k), glow: C(0xFFF6C8, 0.5 * k), coreR: 0.4, glowR: 1)
            }
        } else if f > 0 {
            c.rect(41, cy - 2, 2, 1, C(0xFFF6C8, 0.6))           // the flash cooling
        } else {
            c.rect(41, cy - 2, 2, 1, C(0xE8E8F0))
        }
        return
    }
    // The camera on its strap.
    let cheerUp = p.cheering ? 8 : 0
    if !p.cheering { bar(c, 24, 32, 26, 35, C(0x2A2A30), 0.4); bar(c, 32, 32, 30, 35, C(0x2A2A30), 0.4) }
    c.rect(25, 35 - cheerUp, 7, 4, C(0x24242C)); c.rect(25, 35 - cheerUp, 7, 1, C(0x4A4A56))
    c.rect(27, 36 - cheerUp, 3, 2, C(0x5A5A68)); c.px(28, 36 - cheerUp, C(0x9AD0FF))
    if p.cheering {
        c.rect(32, 27, 3, 3, jacket); c.rect(38, 26, 3, 5, jacket)
    } else {
        c.rect(38, 33, 3, 3, jacket)
    }
}

// MARK: - Alfred

/// Alfred Pennyworth: Clawd balding on top, grey at the sides, a neat grey moustache, the black tailcoat with its
/// tails behind him, a white shirt front and bow tie, and a silver tray with the tea things on his hand. He doesn't
/// fight; he lifts the tray in a dignified cheer. Signature: he pours a cup, steam and all, and offers it.
private func drawAlfred(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x1E1E26), coatLight = C(0x34343E), shirt = C(0xF4F4F6), grey = C(0xB8BCC4), greyDark = C(0x8A8E98)
    let trousers = C(0x2A2A32)
    let s = p.signature ?? -1
    // The tails, behind.
    if !seatedPose { c.pattern(15, 36 + p.breathe, ["TTTT", "TTT.", "TTT.", "TT..", "T..."], ["T": coat]) }
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, C(0x0E0E12), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(arm: coat))
    // Bald on top (a little shine), grey above the ears, brows and a clipped moustache.
    c.px(24, 27, C(0xF0A080)); c.rect(25, 26, 2, 1, C(0xF0A080))
    c.pattern(17, 26, ["GGG................GG", "GGGG..............GGG", "GGG...............GGG", ".GG................GG"],
              ["G": grey])
    c.rect(21, 28, 4, 1, greyDark); c.rect(31, 28, 4, 1, greyDark)
    c.pattern(25, 32, [".MMMMMM.", "MM....MM"], ["M": grey])
    // Tailcoat over a starched shirt front and a black bow tie.
    c.rect(18, 34, 20, 4, coat)
    c.rect(26, 34, 4, 4, shirt)
    c.pattern(25, 34, ["KK.KKK", ".KKKK."], ["K": ink])
    c.rect(28, 35, 1, 1, ink); c.px(27, 37, C(0xC8CCD6))
    c.rect(37, 34, 1, 4, coatLight)
    c.rect(15, 33, 3, 3, coat); c.rect(15, 35, 3, 1, shirt)
    // The tray on his right hand, higher when he cheers.
    let lift = p.cheering ? 6 : 0
    let ty = 34 - lift
    let silver = C(0xD8DCE4), silverDark = C(0x9AA0AC)
    c.rect(38, ty + 1, 3, max(2, 36 - ty - 1), coat); c.rect(38, ty + 1, 3, 1, shirt)
    c.rect(38, ty, 13, 1, silver); c.rect(39, ty + 1, 11, 1, silverDark)
    // 0.1…0.25 the pot comes up, 0.25…0.6 it pours, 0.6…0.7 back down; then the cup is offered, steaming.
    let up: Double = s < 0.1 ? 0 : (s < 0.25 ? (s - 0.1) / 0.15 : (s < 0.6 ? 1 : max(0, 1 - (s - 0.6) / 0.1)))
    let pour = s > 0.25 && s < 0.6
    let full = s < 0.3 ? 0 : min(1, (s - 0.3) / 0.25)
    // The cup and saucer, filling.
    let cx = 46
    c.rect(cx - 1, ty - 1, 5, 1, C(0xC8CCD6))
    c.rect(cx, ty - 3, 3, 2, white); c.px(cx + 3, ty - 3, white); c.px(cx + 3, ty - 2, C(0xC8CCD6))
    if full > 0.5 { c.rect(cx, ty - 3, 3, 1, C(0x8A5A2A)) }
    if s >= 0.55 {
        for i in 0..<2 {
            let f = frac(p.t * 0.9 + Double(i) * 0.5)
            c.px(cx + 1 + Int(sin(f * 7 + Double(i)) * 1.2), ty - 5 - Int(f * 6), C(0xFFFFFF, 0.6 * (1 - f)))
        }
    }
    // The teapot, lifted and tipped over the cup.
    let at = (x: 42.5 - up, y: Double(ty) - 0.5 - 7 * up)
    let ang: Double = 45 * up
    prop(c, at: at, angle: ang) { s in
        let pot = C(0xE8ECF2), potShade = C(0xB8BEC8), gold = C(0xD8B040)
        s.rect(18, 17, 5, 4, pot); s.rect(18, 20, 5, 1, potShade)
        s.rect(19, 16, 3, 1, pot); s.px(20, 15, gold)
        s.rect(18, 18, 5, 1, gold)
        s.px(23, 18, pot); s.px(24, 17, pot)                                        // spout
        s.px(17, 17, potShade); s.px(16, 18, potShade); s.px(17, 19, potShade)      // handle
    }
    if pour {
        let r = ang * .pi / 180
        let tip = (x: at.x + 4 * cos(r) + 4 * sin(r), y: at.y + 4 * sin(r) - 4 * cos(r))
        bar(c, tip.x, tip.y + 0.5, Double(cx) + 1.5, Double(ty) - 3, C(0x9A6A3A), 0.4)
    }
}

// MARK: - Lucius Fox

/// Lucius Fox: Clawd with close-cropped grey hair and a trim grey beard, round glasses, a charcoal suit with a white
/// shirt and a burgundy tie, and a tablet in his hand. He doesn't fight. Signature: he taps the tablet and a little
/// drone lifts off it, loops round his head blinking, and lands back on the screen.
private func drawLuciusFox(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x3A3E4A), suitDark = C(0x2A2E38), shirt = C(0xF2F2F4), tie = C(0x7A1E2A), grey = C(0xC0C2C8)
    let greyDark = C(0x8E9098), frame = C(0xE8D8A0)
    let s = p.signature ?? -1
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, C(0x16161B), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(arm: suit))
    c.pattern(18, 24, [
        "...GgGGGgGGGGgGGG...",
        ".GGGGGGGGGGGGGGGGGG.",
        "GGGGGGGGGGGGGGGGGGGG",
        "G..................G",
    ], ["G": grey, "g": greyDark])
    // Glasses round the eyes, and the beard along the jaw.
    for x in [21, 31] {
        c.rect(x, 28, 4, 1, frame); c.rect(x, 32, 4, 1, frame); c.rect(x, 29, 1, 3, frame); c.rect(x + 3, 29, 1, 3, frame)
    }
    c.rect(25, 29, 6, 1, frame)
    c.pattern(18, 30, ["G..................G", "G..................G", "GG................GG", "GGGGGGGG...GGGGGGGGG",
                       ".GGGGGGGGGGGGGGGGGG."], ["G": grey])
    c.rect(26, 33, 3, 1, C(0x7A3A2A))
    c.rect(18, 35, 20, 3, suit)
    c.pattern(24, 35, ["WWWTWWW", ".WWTWW.", "..WTW.."], ["W": shirt, "T": tie])
    c.rect(37, 35, 1, 3, suitDark)
    c.rect(15, 33, 3, 3, suit)
    // The tablet, held up to tap or to show off; a cheer waves it.
    let up = p.cheering ? 7 : (s > 0 ? 2 : 0)
    let tx = 39, ty = 30 - up
    c.rect(38, ty + 3, 3, 36 - ty - 3, suit)
    c.rect(tx, ty, 6, 5, C(0x1A1A20))
    let lit = s > 0 || p.ready || p.cheering
    c.rect(tx + 1, ty + 1, 4, 3, lit ? C(0x6FD8FF) : C(0x3A4A5A))
    if lit { c.px(tx + 2, ty + 2, white) }
    if s > 0.1 && s < 0.92 {
        // The drone: off the screen, a loop round his head, back down.
        let k = (s - 0.1) / 0.82
        var dx: Double = 42, dy: Double = Double(ty) - 1
        if k < 0.2 {
            dy -= 10 * (k / 0.2)
        } else if k < 0.8 {
            let a: Double = (k - 0.2) / 0.6 * 2 * .pi
            dx = 28 + 14 * cos(a); dy = Double(ty) - 11 + sin(a) * 6 - 4
        } else {
            dy -= 10 * (1 - (k - 0.8) / 0.2)
        }
        let x = Int(dx.rounded()), y = Int(dy.rounded())
        c.rect(x - 2, y, 5, 1, C(0x2A2A34)); c.rect(x - 1, y + 1, 3, 1, C(0x4A4E5A))
        let blade = Int(p.t * 30) % 2 == 0
        c.rect(x - 3, y - 1, blade ? 2 : 1, 1, C(0xC8CCD6, 0.7)); c.rect(x + 2, y - 1, blade ? 2 : 1, 1, C(0xC8CCD6, 0.7))
        if Int(p.t * 6) % 2 == 0 { c.px(x, y + 1, C(0xFF3A3A)) }
    }
}

// MARK: - Krypto

/// Krypto the Superdog: a small white dog with floppy ears, a black nose and a curly tail, the red cape tied at his
/// collar with a little gold S tag. He fights by biting (the jaw drops and he lunges) and flies like his master,
/// front paws out, cape streaming. Signature: tail going like mad, he barks twice, then sits up and begs.
private func drawKrypto(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xF4F4F6), shade = C(0xCACED8), ear = C(0xD8D0C4), nose = C(0x16161B)
    let s = p.signature ?? -1
    var open: Double = p.melee.map { a in max(0, 1 - abs(a + 20) / 50) } ?? 0
    var bark = false
    if s > 0.1 && s < 0.55 {
        let b = frac((s - 0.1) / 0.225)
        bark = b < 0.4
        open = bark ? 1 : 0
    }
    if p.cheering { open = Int(p.t * 6) % 2 == 0 ? 1 : 0 }
    let beg = s >= 0.6 && s < 0.95
    let lunge = p.melee != nil ? Int((2 * open).rounded()) : 0
    let flying = p.flying
    // In flight the cape streams out behind everything.
    if flying { drawFlyingCape(c, t: p.t, color: capeRed, edge: capeRedDark, top: 29) }
    // Legs: stubby, swept back in flight, folded when sitting.
    if flying {
        c.rect(13, 36, 6, 2, shade); c.rect(14, 38, 5, 1, fur)               // hind legs stretched back
        c.rect(36, 38, 7, 2, fur); c.px(42, 39, shade)                         // front paws out ahead
    } else if seatedPose || beg {
        c.rect(20, 40, 6, 2, fur); c.rect(30, 40, 4, 2, fur)
    } else {
        for (i, lx) in [21, 25, 32, 36].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx + (i >= 2 ? lunge : 0), 37, 2, lifted ? 5 : 6, i % 2 == 0 ? shade : fur)
        }
    }
    c.oy += p.breathe
    // Begging: sat back, upright, paws up.
    if beg {
        c.pattern(17, 30, ["....RR", "...RRR", "..RRRR", ".RRRRR", "RRRRRR", "RRRRRR", "rRRRR.", ".rRR.."],
                  ["R": capeRed, "r": capeRedDark])
        c.rect(22, 30, 11, 11, fur); c.rect(22, 30, 1, 11, shade)
        c.rect(31, 31, 3, 2, fur); c.rect(33, 31, 2, 2, fur)
        c.rect(32, 29, 2, 2, fur); c.rect(34, 30, 2, 2, fur)
        drawKryptoTail(c, x: 21, y: 37, t: p.t, fast: true, fur: fur)
        drawKryptoHead(c, x: 27, y: 19, open: 0, fur: fur, shade: shade, ear: ear, nose: nose, happy: true)
        c.rect(26, 29, 8, 1, capeRed)
        return
    }
    c.ox += lunge
    // Body: a white block with a darker underside, the tail up behind.
    let by = flying ? 31 : 30
    c.rect(19, by, 18, 8, fur)
    c.rect(19, by + 7, 18, 1, shade)
    c.rect(20, by - 1, 15, 1, fur)
    if !flying {
        // The cape draped over his back from the collar, its hem swinging past his rump.
        let rows: [(Int, Int)] = [(22, 31), (19, 30), (18, 29), (17, 27), (16, 25), (15, 23), (15, 21)]
        for (j, r) in rows.enumerated() {
            let sway = j >= 3 ? Int((sin(p.t * p.capeSpeed + Double(j)) * Double(j - 2) * 0.5).rounded()) : 0
            c.rect(r.0 + sway, by - 1 + j, r.1 - r.0 - sway + 1, 1, capeRed)
            c.px(r.0 + sway, by - 1 + j, capeRedDark)
        }
    }
    drawKryptoTail(c, x: flying ? 19 : 16, y: by + 1, t: p.t, fast: s > 0, fur: fur)
    drawKryptoHead(c, x: 31, y: by - 9, open: open, fur: fur, shade: shade, ear: ear, nose: nose, happy: s > 0 && !bark)
    // Collar, cape knot and the gold tag.
    c.rect(31, by - 1, 6, 1, capeRed)
    c.px(35, by, C(0xF2C830))
    c.ox -= lunge
    if bark {
        let k = frac((s - 0.1) / 0.225) / 0.4
        for i in 0..<3 {
            let a: Double = -0.6 + Double(i) * 0.6
            let r: Double = 4 + 4 * k
            c.glowLine(49 + cos(a) * r, Double(by) - 2 + sin(a) * r, 49 + cos(a) * (r + 2), Double(by) - 2 + sin(a) * (r + 2),
                       core: C(0xFFFFFF, 1 - k), glow: C(0xFFFFFF, 0), coreR: 0.5, glowR: 0.6)
        }
    }
}

/// Krypto's head: its top-left at (`x`, `y`), facing right, the jaw dropped by `open` (0…1).
private func drawKryptoHead(_ c: PixelCanvas, x: Int, y: Int, open: Double, fur: Px, shade: Px, ear: Px, nose: Px,
                            happy: Bool) {
    let o = Int((3 * open).rounded())
    c.rect(x, y + 2, 10, 7, fur)
    c.rect(x + 1, y + 1, 8, 1, fur)
    c.rect(x + 8, y + 5, 6, 3, fur)                    // muzzle
    c.rect(x + 8, y + 7, 6, 1, shade)
    c.rect(x + 13, y + 4, 2, 2, nose)
    // The floppy ear.
    c.rect(x + 1, y + 1, 3, 6, ear); c.rect(x + 2, y + 7, 2, 1, ear)
    c.px(x + 1, y, ear)
    if happy {
        c.px(x + 7, y + 4, ink); c.px(x + 8, y + 3, ink); c.px(x + 9, y + 4, ink)
    } else {
        c.rect(x + 7, y + 3, 2, 2, ink); c.px(x + 7, y + 3, white)
    }
    if o > 0 {
        c.rect(x + 9, y + 8, 5, o, C(0x8A2A3A))
        c.rect(x + 9, y + 8 + o, 5, 1, fur)
        c.px(x + 13, y + 8, white); c.px(x + 10, y + 8, white)
        c.px(x + 11, y + 8 + o - 1, C(0xF07A9A))
    } else {
        c.rect(x + 10, y + 8, 3, 1, shade)
    }
}

/// Krypto's tail, curling up from (`x`, `y`), wagging (faster when he's excited).
private func drawKryptoTail(_ c: PixelCanvas, x: Int, y: Int, t: Double, fast: Bool, fur: Px) {
    let wag = Int((sin(t * (fast ? 30 : 6)) * 1.5).rounded())
    c.rect(x - 2, y, 2, 2, fur)
    c.rect(x - 3 + wag, y - 2, 2, 2, fur)
    c.rect(x - 3 + wag * 2, y - 4, 2, 2, fur)
}
