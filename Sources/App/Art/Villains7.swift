import Foundation

// Villains: Wonder Woman's and Aquaman's foes, from Themyscira's enemies to the things at the bottom of the sea.

let villains7: [Leader: Persona] = [
    .cheetah: Persona(name: "Cheetah", weapon: .melee, headTop: 22, signature: 2.8, callout: "Run, little Amazon.",
                  draw: drawCheetah),
    .ares: Persona(name: "Ares", weapon: .melee, armoured: true, bulk: 1, headTop: 13, signature: 3.2,
                  callout: "I am the god of war!",
                  draw: drawAres),
    .circe: Persona(name: "Circe", weapon: .magic, magic: Magic(core: C(0xF0E0FF), glow: C(0x8A4AD8), jagged: false),
                  headTop: 18, signature: 3.4, callout: "Swine, the lot of you.",
                  draw: drawCirce),
    .maxwellLord: Persona(name: "Maxwell Lord", weapon: .magic, magic: Magic(core: C(0xFFF0FF), glow: C(0xE86AE8), jagged: false),
                  pivot: (41.5, 30.5), headTop: 22, signature: 3.0, callout: "Life is good, but it can be better!",
                  draw: drawMaxwellLord),
    .doctorPoison: Persona(name: "Doctor Poison", weapon: .ranged, shot: .energy(core: C(0xF0FFD0), glow: C(0x8AE82A)),
                  muzzle: (49, 31), headTop: 19, signature: 3.0, callout: "One drop is all it takes.",
                  draw: drawDoctorPoison),
    .giganta: Persona(name: "Giganta", weapon: .melee, pivot: gigantaShoulder, bulk: 3, headTop: 15, signature: 3.4,
                  callout: "Who are you calling small?",
                  draw: drawGiganta),
    .silverSwan: Persona(name: "Silver Swan", weapon: .magic, motion: .fly,
                  magic: Magic(core: C(0xF4F8FF), glow: C(0xA8C4F0), jagged: false),
                  pivot: (38.5, 35.5), headTop: 18, signature: 3.0,
                  draw: drawSilverSwan),
    .blackManta: Persona(name: "Black Manta", weapon: .ranged, shot: .beam(core: C(0xFFE0E0), glow: C(0xFF2A2A)), armoured: true,
                  muzzle: (36, 23), handGun: false, headTop: 13, signature: 2.8, callout: "This is for my father.",
                  draw: drawBlackManta),
    .oceanMaster: Persona(name: "Ocean Master", weapon: .magic, magic: Magic(core: C(0xE0FFFF), glow: C(0x2AC8D8)),
                  pivot: (41.5, 19.5), headTop: 17, signature: 3.2, callout: "I am the Ocean Master!",
                  draw: drawOceanMaster),
    .trench: Persona(name: "The Trench", weapon: .melee, canSit: false, headTop: 16, signature: 2.8,
                  draw: drawTrench),
]

// MARK: - Helpers

private let clear = C(0, 0)

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// A single glowing dot.
private func dot(_ c: PixelCanvas, _ x: Double, _ y: Double, core: Px, glow: Px, r: Double = 0.5, g: Double = 1.6, strength: Double = 1) {
    c.glowLine(x, y, x, y, core: core, glow: glow, coreR: r, glowR: g, strength: strength)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
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

/// Draws `art` on a fresh canvas of sprite size, its origin at (0, 0).
private func offscreen(_ art: (PixelCanvas) -> Void) -> PixelCanvas {
    let o = PixelCanvas(Sprite.width, Sprite.height)
    art(o)
    return o
}

/// `o` drawn onto `c`, scaled by `scale` about its point `from` (the feet, by default), which stays put.
private func stamp(_ c: PixelCanvas, _ o: PixelCanvas, scale: Double = 1, from: (x: Double, y: Double) = (28, 43.5)) {
    for y in 0..<o.h {
        for x in 0..<o.w {
            let sx = Int(floor(from.x + (Double(x) + 0.5 - from.x) / scale))
            let sy = Int(floor(from.y + (Double(y) + 0.5 - from.y) / scale))
            guard sx >= 0, sy >= 0, sx < o.w, sy < o.h else { continue }
            let i = (sy * o.w + sx) * 4
            guard o.buf[i + 3] > 0 else { continue }
            c.px(x, y, unpremultiplied(o, i))
        }
    }
}

/// A flyer on the move: the whole figure leant forward into its flight by `degrees`.
private func tilted(_ c: PixelCanvas, _ degrees: Double, _ art: (PixelCanvas) -> Void) {
    let o = offscreen(art)
    stamp(c, o.rotated(degrees, about: (28, 34), into: o.w, o.h, at: (28, 34)))
}

/// Tints a scatter of everything drawn so far: a magical shimmer running over the sprite.
private func shimmer(_ c: PixelCanvas, _ col: Px, amount: Double, seed: Int) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<c.h {
        for x in 0..<c.w where c.isDrawn(x, y) && noise(seed * 977 + y * 72 + x) < amount {
            c.px(x, y, col.alpha(0.8))
        }
    }
}

/// A puff of smoke round (`x`, `y`), `k` 0…1 through it: it swells and thins out.
private func puff(_ c: PixelCanvas, x: Int, y: Int, k: Double, _ col: Px, seed: Int) {
    let a = 0.85 * (1 - k)
    for i in 0..<5 {
        let dx = Int(((noise(seed + i) - 0.5) * 8 * (0.5 + k)).rounded())
        let dy = Int(((noise(seed + i + 9) - 0.5) * 5 * (0.5 + k)).rounded()) - Int(k * 3)
        c.circle(x + dx, y + dy, 1 + Int(k * 2.5), col.alpha(a))
    }
}

/// Sound rings spreading right from (`x`, `y`): `n` arcs, `reach` pixels at their furthest.
private func soundRings(_ c: PixelCanvas, x: Double, y: Double, t: Double, reach: Double, n: Int = 3, _ col: Px, spread: Double = 45) {
    for j in 0..<n {
        let f = frac(t * 2.5 + Double(j) / Double(n))
        let r = 2 + f * reach
        var a = -spread
        while a <= spread {
            let rad = a * .pi / 180
            c.px(Int((x + cos(rad) * r).rounded()), Int((y + sin(rad) * r * 0.9).rounded()), col.alpha(1 - f))
            a += 60 / max(r, 3)
        }
    }
}

/// A forearm and three hooked claws out from the hand along `angle` degrees. `ghost`: only the claws, as a smear.
private func drawClaws(_ c: PixelCanvas, at: (x: Double, y: Double) = Sprite.hand, angle: Double, alpha: Double = 1,
                       arm: Px, claw: Px, tip: Px, ghost: Bool = false, long: Int = 0) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        if !ghost { s.rect(15, 19, 7, 3, arm) }
        for dy in [-1, 0, 1] {
            let len = (dy == 0 ? 5 : 4) + long
            for k in 0..<len { s.px(22 + k, 20 + dy * (1 + k / 3) + (k == len - 1 ? 1 : 0), k == len - 1 ? tip : claw) }
        }
    }
}

// MARK: - Cheetah

/// Cheetah (Barbara Minerva): a golden Clawd covered in black spots, pointed cat ears, green slit eyes with the
/// black tear marks running down past a cream muzzle, a long spotted tail and hooked claws on both hands. She fights
/// with the claws, leaving a gold smear. Signature: she drops into a crouch with her tail lashing and fangs bared, then
/// pounces with a raking swipe that leaves three slashes hanging in the air.
private func drawCheetah(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xE2A83C), furDark = C(0xB4781E), furLight = C(0xF6D27E), spot = C(0x3A2412)
    let cream = C(0xF6E6C4), green = C(0x9AE84A), inner = C(0x8A4A3A)
    let sig = p.signature
    let crouch = Int(((sig.map { $0 < 0.5 ? habitArc($0 / 0.5, hold: 0.5) : 0 } ?? 0) * 2).rounded())
    let swipe: Double? = sig.flatMap { $0 >= 0.42 && $0 < 0.58 ? ($0 - 0.42) / 0.16 : nil }
    let snarl = crouch > 0 || swipe != nil || p.melee != nil && !p.walking || p.hit

    drawLegs(c, Look(leg: fur), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx + (i % 2), 38 + i % 2, spot)
            c.px(lx + 2, bottom, cream)                                   // toe claws
        }
    }
    c.oy += p.breathe + crouch

    // The tail, curling up behind her; it lashes faster when she's about to pounce.
    let lash = sig != nil ? 9.0 : 2.4, sway = sin(p.lt * lash) * (sig != nil ? 2.5 : 1.4)
    var prev = (x: 18.5, y: 35.0)
    for i in 1...9 {
        let f = Double(i) / 9, a = f * .pi / 2
        let q = (x: 18.5 - 10 * sin(a) + sway * f * f, y: 35 - 10 * (1 - cos(a)))
        bar(c, prev.x, prev.y, q.x, q.y, i == 9 ? spot : (i % 3 == 1 ? spot : fur), i < 5 ? 0.9 : 0.75)
        prev = q
    }

    drawBody(c, Look(body: fur, shade: furDark, arm: fur, eye: nil))
    for x in [19, 32] {                                                   // ears
        c.pattern(x, 22, ["..F..", ".FFF.", ".FpF.", "FFpFF"], ["F": fur, "p": inner])
    }
    c.px(21, 22, spot); c.px(34, 22, spot)
    let spots: [(Int, Int)] = [(19, 27), (22, 26), (25, 27), (30, 26), (33, 27), (36, 26), (36, 29), (19, 31),
                               (19, 34), (21, 36), (24, 35), (33, 36), (36, 34), (35, 32), (27, 36), (30, 34), (22, 33)]
    for (x, y) in spots { c.px(x, y, spot) }
    c.rect(19, 26, 3, 1, furLight)
    // Face: slit eyes, the tear marks, muzzle and nose.
    c.rect(22, 29, 2, 3, green); c.rect(32, 29, 2, 3, green)
    c.rect(22, 29, 2, 1, spot); c.rect(32, 29, 2, 1, spot)
    c.rect(23, 30, 1, 2, ink); c.rect(33, 30, 1, 2, ink)
    c.rect(24, 31, 1, 2, spot); c.rect(31, 31, 1, 2, spot)
    c.rect(25, 32, 6, 3, cream)
    c.rect(27, 32, 2, 1, C(0x3A1A14))
    if snarl {
        c.rect(26, 34, 4, 1, C(0x5A1414)); c.px(26, 34, white); c.px(29, 34, white)
    } else {
        c.px(27, 33, spot); c.px(28, 33, spot)
    }
    c.rect(15, 33, 3, 3, fur); c.px(14, 35, cream); c.px(14, 33, cream)

    if let k = swipe {
        let e = 1 - pow(1 - k, 3), a = -115 + 165 * e
        for i in 1...2 { drawClaws(c, angle: a - Double(i) * 30, alpha: 0.4 / Double(i), arm: fur, claw: furLight, tip: furLight, ghost: true) }
        drawClaws(c, angle: a, arm: fur, claw: cream, tip: white)
    } else if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            drawClaws(c, angle: ta, alpha: 0.4 / Double(i + 1), arm: fur, claw: furLight, tip: furLight, ghost: true)
        }
        drawClaws(c, angle: a, arm: fur, claw: cream, tip: white)
    } else if crouch > 0 {
        c.rect(38, 30, 3, 3, fur)                                        // claw cocked back by her face
        for dy in 0..<3 { c.px(41, 29 + dy, cream); c.px(42, 28 + dy, white) }
    } else {
        c.rect(38, 33, 3, 3, fur)
        for dy in 0..<3 { c.px(41, 33 + dy, cream) }
    }
    if let s = sig, s >= 0.54, s < 0.96 {
        // Three raking slashes left hanging in the air.
        let f = (s - 0.54) / 0.42, a = min(1, 2 * (1 - f))
        for i in 0..<3 {
            let x0 = 43.0 + Double(i) * 3, y0 = 25.0 + Double(i)
            c.glowLine(x0, y0, x0 + 5, y0 + 12, core: white.alpha(a), glow: furLight.alpha(a), coreR: 0.4, glowR: 1.3)
        }
    }
}

// MARK: - Ares

/// Ares: the god of war in black iron, the full helmet with its crown of spikes, a T-shaped visor with red fire
/// behind it, spiked pauldrons, a tattered blood-red cape and a broad black-hilted sword (on his back when he's not
/// swinging it). Signature: he raises the sword, the blade catches fire, his eyes blaze and a red haze of war rises
/// round him.
private func drawAres(_ c: PixelCanvas, _ p: Pose) {
    let iron = C(0x3A3A46), ironDark = C(0x24242C), ironLight = C(0x5E5E6C), edge = C(0x8A8A9A)
    let red = C(0xFF3A1A), hot = C(0xFFD0A0), cape = C(0x6A1616), capeDark = C(0x3A0C0C)
    let k = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: cape, edge: capeDark)
    if k > 0.05 {
        // The haze of war rising round him.
        for i in 0..<7 {
            let f = frac(p.lt * 0.7 + Double(i) / 7)
            let x = 14 + Double(i) * 4.3 + sin(p.lt * 3 + Double(i)) * 1.5, y = 43 - f * 30
            dot(c, x, y, core: C(0xFF6A3A).alpha(k * (1 - f)), glow: C(0x8A0A0A).alpha(k * (1 - f)), r: 0.6, g: 2.4)
        }
    }
    drawLegs(c, Look(leg: C(0x4A4A56)), step: p.step)
    drawBoots(c, ironLight, step: p.step, rows: 4)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx + 2, bottom - 3, edge)                                // greave spikes
            c.px(lx, bottom - 3, ironLight)
        }
    }
    c.oy += p.breathe

    // Sitting, the sword is on his back: hilt over the left shoulder, blade hidden behind him.
    let swordOut = p.melee != nil || k > 0.02
    if !swordOut && seatedPose { drawAresSword(c, at: (16.5, 23.5), angle: 50) }

    drawBody(c, Look(body: iron, shade: ironDark, arm: iron, eye: nil))
    c.pattern(17, 13, [
        "..........EE..........",
        "..........SS..........",
        "......E...SS...E......",
        "......S..SSSS..S......",
        "..E...SS.SSSS.SS...E..",
        "..S..SSSSSSSSSSSS..S..",
        "..SS.SSSSSSSSSSSS.SS..",
        ".SSSSSSSSSSSSSSSSSSSS.",
        "SSSSLLLLLLLLLLLLLLSSSS",
        "SSLSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSS",
        "SSDDDDDDDDDDDDDDDDDDSS",
        "SSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSD",
    ], ["S": iron, "D": ironDark, "L": ironLight, "E": edge])
    c.rect(17, 26, 1, 7, iron); c.rect(38, 26, 1, 7, ironDark)          // cheek guards
    // The T visor, with fire behind it.
    c.rect(20, 29, 16, 2, ink)
    c.rect(27, 31, 2, 3, ink)
    let blaze = 0.55 + 0.45 * k
    for ex in [22.5, 32.5] {
        dot(c, ex, 29.8, core: hot.alpha(blaze), glow: red.alpha(blaze), r: 0.7, g: 1.6 + 1.6 * k)
        c.rect(Int(ex) - 1, 29, 3, 1, red)
    }
    c.rect(19, 28, 18, 1, ironLight)
    // Chest plate and belt.
    c.rect(18, 34, 20, 4, ironDark)
    c.rect(19, 34, 18, 1, ironLight)
    c.rect(27, 34, 2, 3, iron)
    c.rect(18, 36, 20, 1, C(0x4A1E1A)); c.rect(27, 36, 2, 1, red)
    // Spiked pauldrons.
    c.pattern(13, 28, ["E.E..", "SESE.", "SSSSS", "SSSSD"], ["S": iron, "E": edge, "D": ironDark])
    c.pattern(38, 28, ["..E.E", ".ESES", "SSSSS", "DSSSS"], ["S": iron, "E": edge, "D": ironDark])
    c.rect(15, 33, 3, 3, iron)

    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawAresSword(c, at: Sprite.hand, angle: ta, alpha: 0.32 / Double(i + 1)) }
        drawAresSword(c, at: Sprite.hand, angle: a)
        c.rect(38, 33, 3, 3, iron)
    } else if k > 0.02 {
        let a = 60 - 150 * k
        drawAresSword(c, at: Sprite.hand, angle: a)
        c.rect(38, 33, 3, 3, iron)
        if k > 0.7 {
            // The blade burns.
            let r = a * .pi / 180, f = (k - 0.7) / 0.3
            for i in 0..<6 {
                let d = 5 + Double(i) * 2.6, n = noise(Int(p.t * 24) + i * 7)
                let bx = Sprite.hand.x + cos(r) * d, by = Sprite.hand.y + sin(r) * d
                dot(c, bx - 1 + n * 2, by - n * 2, core: C(0xFFE08A).alpha(f), glow: C(0xFF4A1A).alpha(f), r: 0.6, g: 1.8 + n)
            }
        }
    } else if seatedPose {
        c.rect(38, 33, 3, 3, iron)
    } else {
        // Leaning on it, point down on the floor, a hand on the pommel.
        drawAresSword(c, at: (43.5, 24.5 - Double(p.breathe)), angle: 90)
        c.rect(41, 21, 4, 3, iron); c.rect(41, 23, 4, 1, ironDark)
        c.rect(38, 32, 3, 3, iron)
    }
}

/// Ares's broadsword, grip in the hand at `at`, blade out along `angle`.
private func drawAresSword(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        let blade = C(0xB4BAC6), bright = C(0xE8ECF2), fuller = C(0x6A707C), dark = C(0x2A2A32), blood = C(0x8A1E1E)
        s.rect(16, 20, 4, 1, C(0x1A1A1E))
        s.px(15, 20, blood)
        s.rect(20, 17, 2, 7, dark); s.px(20, 16, dark); s.px(20, 24, dark)
        s.rect(22, 19, 16, 3, blade)
        s.rect(22, 19, 16, 1, bright)
        s.rect(23, 20, 12, 1, fuller)
        s.px(38, 20, blade); s.px(39, 20, bright)
    }
}

// MARK: - Circe

/// Circe: the sorceress, Clawd with a huge mane of purple hair, a gold tiara with a green stone, violet eye shadow
/// and lips, and a long emerald gown with a gold neckline and hem. She casts violet sorcery from her raised hand.
/// Signature: she points, a violet bolt flies out, and in a puff of smoke a little pink pig appears, snorts about,
/// and poofs away again.
private func drawCirce(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x8A3AC8), hairDark = C(0x5E2296), hairLight = C(0xB86AF0)
    let gown = C(0x1E7A4A), gownDark = C(0x145A34), gold = C(0xE8B530), goldLight = C(0xFFE08A)
    let violet = C(0xC88AFF), lips = C(0x9A2A6A)
    let sig = p.signature

    // The gown, flaring to the floor (gathered round her knees when she sits).
    if seatedPose {
        c.rect(15, 36, 26, 4, gown); c.rect(15, 39, 26, 1, gold); c.rect(40, 36, 1, 4, gownDark)
    } else {
        let sway = p.step < 0 ? 0 : (p.step == 0 ? 1 : -1)
        for y in 36...42 {
            let f = (y - 36) / 2, s = y > 39 ? sway : 0
            let l = 18 - f + s, r = 37 + f + s
            c.rect(l, y, r - l + 1, 1, gown)
            c.px(r, y, gownDark)
            if y % 2 == 0 { c.px(26 + s, y, gownDark) }
        }
        c.rect(15 + sway, 42, 26, 1, gold)
        c.rect(23, 43, 3, 1, gold); c.rect(31, 43, 3, 1, gold)
    }
    c.oy += p.breathe

    // The mane falls behind her, past her shoulders.
    for y in 26...38 {
        let w = y < 34 ? 4 : max(1, 4 - (y - 33))
        let wave = Int((sin(p.lt * 2 + Double(y) * 0.5) * 0.6).rounded())
        c.rect(18 - w + wave, y, w, 1, y % 3 == 0 ? hairDark : hair)
        c.rect(38 + wave, y, w, 1, y % 3 == 1 ? hairDark : hair)
    }
    drawBody(c, Look(arm: clawdOrange, eye: nil))
    c.pattern(14, 18, [
        "........HHHHHHHHHHHH........",
        ".....HHHHHHHHhHHHHHHHHH.....",
        "...HHHHHLLHHHHHHHHHhHHHHH...",
        "..HHHHLLHHHHHHHHHHHHHHhHHH..",
        ".HHHHLHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHGGGGGGGgGGGGGGGGHHHHHH",
        "HHHHHhhh............hhhHHHHH",
        "HHHHh..................hHHHH",
    ], ["H": hair, "h": hairDark, "L": hairLight, "G": gold, "g": C(0x3AE07A)])
    c.px(26, 25, goldLight)
    // Eyes under violet lids, and violet lips.
    let casting = p.zap != nil || sig != nil
    c.rect(21, 28, 4, 1, violet); c.rect(31, 28, 4, 1, violet)
    if casting {
        c.rect(22, 29, 2, 3, violet); c.rect(32, 29, 2, 3, violet)
        c.px(22, 29, white); c.px(32, 29, white)
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    c.px(21, 29, ink); c.px(34, 29, ink)
    c.rect(26, 33, 4, 1, lips)
    // The bodice: emerald, a gold neckline.
    c.rect(18, 35, 20, 3, gown)
    c.pattern(18, 34, ["GG................GG", "gGGGGGGG....GGGGGGGg"], ["G": gold, "g": goldLight])
    c.rect(37, 35, 1, 3, gownDark)
    c.rect(15, 33, 3, 3, clawdOrange)
    c.rect(15, 35, 3, 1, gold)

    // The casting hand.
    var raise = p.armRaise
    if let s = sig { raise = Int((habitArc(min(1, s / 0.5), hold: 0.6) * 4).rounded()) }
    c.rect(38, 33 - raise, 3, 3, clawdOrange)
    c.rect(38, 35 - raise, 3, 1, gold)
    guard let s = sig else { return }
    if s > 0.05 && s < 0.24 {
        // The bolt flies out to where the pig will be.
        let f = (s - 0.05) / 0.19, hx = 41.0, hy = 33.5 - Double(raise)
        let x = hx + (49 - hx) * f, y = hy + (38 - hy) * f
        c.glowLine(x - 2, y - 0.8, x, y, core: C(0xF0E0FF), glow: C(0x8A4AD8), coreR: 0.7, glowR: 2)
        dot(c, hx, hy, core: C(0xF0E0FF), glow: C(0x8A4AD8), r: 0.5, g: 1.8)
    }
    if s >= 0.24 && s < 0.86 {
        let f = (s - 0.24) / 0.62
        drawPig(c, x: 44, y: 36, t: p.lt, hop: Int(f * 12) % 4 == 0 ? -1 : 0)
    }
    if s >= 0.2 && s < 0.36 { puff(c, x: 49, y: 39, k: (s - 0.2) / 0.16, C(0xC8A0F0), seed: 11) }
    if s >= 0.82 && s < 0.98 { puff(c, x: 49, y: 39, k: (s - 0.82) / 0.16, C(0xC8A0F0), seed: 23) }
}

/// One of Circe's little pigs, facing her, its top-left at (`x`, `y`) and its trotters on the floor.
private func drawPig(_ c: PixelCanvas, x: Int, y: Int, t: Double, hop: Int) {
    let snort = Int(t * 5) % 3 == 0
    c.pattern(x, y + hop, [
        "..p.p.......",
        ".PPPPPPPPP..",
        "SPkPPPPPPPP.",
        snort ? "SSPPPPPPPPPc" : "NSPPPPPPPPPc",
        "SSPPPPPPPPPP",
        ".PPPPPPPPPPc",
        "..dP....dP..",
        "..dd....dd..",
    ], ["P": C(0xF4A8BE), "p": C(0xD87A98), "S": C(0xE88AA8), "N": C(0x8A3A4A), "k": ink,
        "c": C(0xD87A98), "d": C(0xC86A88)])
    if snort { c.px(x - 1, y + 3 + hop, C(0xFFFFFF, 0.6)); c.px(x - 2, y + 2 + hop, C(0xFFFFFF, 0.4)) }
}

// MARK: - Maxwell Lord

/// Maxwell Lord: the smiling businessman in a charcoal suit, white shirt and red tie, slicked dark hair and a neat
/// moustache and goatee. He pushes his will into people with two fingers to his temple, eyes glowing pink.
/// Signature: fingers to his temple, pink psychic rings pulse out of his head, and the strain shows as a nosebleed.
private func drawMaxwellLord(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x3A3E4A), suitDark = C(0x262A34), shirt = C(0xF0F0F4), tie = C(0xB0202A)
    let hair = C(0x2A2220), beard = C(0x3A2A22), pink = C(0xFF7AE8), pinkCore = C(0xFFE0FF)
    let sig = p.signature
    let k = sig.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, ink, step: p.step, rows: 2)
    c.oy += p.breathe
    let push = p.zap != nil || p.armRaise > 0 || k > 0.1

    if k > 0.1, let s = sig {
        // Rings of will spreading out of his head.
        for j in 0..<3 {
            let f = frac(s * 5 + Double(j) / 3), r = 4 + f * 15
            var a = 0.0
            while a < 360 {
                let rad = a * .pi / 180
                c.px(Int((28 + cos(rad) * r).rounded()), Int((29 + sin(rad) * r * 0.8).rounded()), pink.alpha(k * (1 - f) * 0.8))
                a += 50 / r
            }
        }
    }
    drawBody(c, Look(arm: suit, eye: nil))
    c.pattern(17, 22, [
        "....HHHHHHHHHHHHH.....",
        "..HHHHHHHHHHhHHHHHH...",
        ".HHHHHHHHHHHhHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHH...........HHHHH.",
        ".HH...............HHH.",
    ], ["H": hair, "h": C(0x4A3A34)])
    c.rect(21, 28, 3, 1, hair); c.rect(32, 28, 3, 1, hair)
    if push && (k > 0.3 || p.zap != nil) {
        for ex in [23.0, 33.0] { dot(c, ex, 30.5, core: pinkCore, glow: pink, r: 0.8, g: 2) }
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    // Moustache, goatee and the salesman's smile.
    c.rect(25, 31, 6, 1, beard)
    c.px(24, 31, clawdShade); c.px(31, 31, clawdShade)
    c.rect(26, 32, 4, 1, C(0xF0E6E0))
    c.rect(26, 33, 4, 1, beard)
    if let s = sig, s > 0.5 {
        // The nosebleed trickles down.
        let len = min(4, Int((s - 0.5) / 0.08) + 1)
        c.rect(29, 31, 1, len, C(0xC81E1E))
        if len == 4 && Int(p.t * 3) % 2 == 0 { c.px(29, 35, C(0xC81E1E)) }
    }
    // Suit, shirt and tie.
    c.rect(18, 34, 20, 4, suit)
    c.pattern(18, 34, ["SSSSSWWWWTTWWWWSSSSS", "SSSSSSdWWTTWWdSSSSSS", "SSSSSSSdWTTWdSSSSSSS", "SSSSSSSSdTTdSSSSSSSS"],
              ["S": suit, "d": suitDark, "W": shirt, "T": tie])
    c.rect(37, 35, 1, 3, suitDark)
    c.rect(15, 33, 3, 3, suit)
    if push {
        // Two fingers to his temple.
        c.rect(38, 31, 3, 4, suit)
        c.rect(38, 28, 3, 3, clawdOrange)
        c.px(37, 28, clawdOrange); c.px(37, 29, clawdShade)
    } else {
        c.rect(38, 33, 3, 3, suit)
        c.px(40, 35, clawdOrange)
    }
}

// MARK: - Doctor Poison

/// Doctor Poison (Isabel Maru): dark hair scraped back into a bun, the porcelain half mask over her scarred jaw, an
/// olive military greatcoat with a high collar and black gloves, and a gas pistol with a glowing green canister.
/// Signature: she holds up a vial of her latest brew, swirls it till it bubbles, and a little green skull of gas
/// rises off it.
private func drawDoctorPoison(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x4E5A36), coatDark = C(0x36402A), coatLight = C(0x6A7A4A), hair = C(0x2A1E1A)
    let mask = C(0xE8DECE), maskDark = C(0xB0A490), glove = C(0x1E1E22), toxic = C(0x8AE82A), toxicLight = C(0xE0FFB0)
    let sig = p.signature
    drawLegs(c, Look(leg: C(0x2A2A26)), step: p.step)
    drawBoots(c, glove, step: p.step, rows: 3)
    c.oy += p.breathe
    // Coat skirts over the legs.
    if !seatedPose {
        c.rect(17, 37, 22, 3, coat); c.rect(17, 39, 22, 1, coatDark); c.rect(27, 37, 1, 3, coatDark)
    } else {
        c.rect(16, 37, 24, 2, coat)
    }
    drawBody(c, Look(arm: coat, eye: nil))
    c.pattern(17, 19, [
        ".........hHHh.........",
        "........HHHHHH........",
        "........hHHHHh........",
        "......HHHHHHHHHH......",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHhHHHHHHHHH.",
        ".HHHH...........HHHHH.",
        ".HHH..............HHH.",
    ], ["H": hair, "h": C(0x4A3A30)])
    c.rect(21, 28, 3, 1, hair); c.rect(32, 28, 3, 1, hair)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    // The half mask over her left cheek and jaw.
    c.pattern(18, 30, [
        "MMMMMMm.",
        "MMMMMMMm",
        "MMMMMMMm",
        "MMmMMmMm",
        "MMMMMMMm",
    ], ["M": mask, "m": maskDark])
    c.px(22, 32, ink); c.px(23, 32, maskDark)
    c.rect(28, 33, 3, 1, C(0x8A3A3A))
    // The greatcoat: high collar, brass buttons.
    c.rect(18, 34, 20, 4, coat)
    c.pattern(18, 34, ["LL................LL", "cLL..............LLc"], ["L": coatLight, "c": coatDark])
    c.rect(27, 34, 1, 4, coatDark)
    for y in [35, 37] { c.px(25, y, C(0xC8A040)); c.px(30, y, C(0xC8A040)) }
    c.rect(18, 36, 20, 1, C(0x2A2218))
    c.rect(37, 34, 1, 4, coatDark)
    c.rect(15, 33, 3, 3, glove)

    if let s = sig {
        // The vial held up: green brew bubbling, a skull of gas floating off it.
        let k = habitArc(s, hold: 0.7), lift = Int((k * 8).rounded())
        c.rect(38, 33 - lift, 3, 3 + lift, coat)
        c.rect(38, 31 - lift, 3, 3, glove)
        let vx = 39, vy = 25 - lift, swirl = Int(p.t * 10) % 2
        c.pattern(vx, vy, [".C.", ".G.", "GgG", "gGg", ".g."], ["C": C(0x8A5A3A), "G": C(0xC8E8D8, 0.8), "g": toxic])
        if s > 0.3 { c.px(vx + swirl, vy + 2, toxicLight) }
        dot(c, Double(vx) + 1.5, Double(vy) + 3, core: clear, glow: toxic, r: 0, g: 3, strength: 0.4 + 0.4 * k)
        if s > 0.35 {
            let f = min(1, (s - 0.35) / 0.55), a = (1 - f) * 0.9
            let sy = vy - 4 - Int(f * 8)
            c.pattern(vx - 1, sy, [".GGG.", "GKGKG", "GGGGG", ".GKG.", ".G.G."],
                      ["G": toxic.alpha(a), "K": C(0x2A5A0A, a)])
            for i in 0..<3 { c.px(vx + 1 + Int(sin(p.t * 8 + Double(i)) * 1.5), vy - 1 - i, toxicLight.alpha(0.7)) }
        }
        return
    }
    c.rect(38, 33, 3, 3, glove)
    c.oy += p.gunY
    c.pattern(40, 29, [
        "..GG.....",
        "..Gg.....",
        "KKKKKKKKK",
        "KKTKKKk..",
        "KK.......",
        "KK.......",
    ], ["G": toxic, "g": toxicLight, "K": C(0x2A2A30), "T": C(0x8A8F9C), "k": coatDark])
}

// MARK: - Giganta

private let gigantaShoulder = (x: 40.5, y: 28.5)

/// Giganta (Doris Zuel): a big, broad Clawd with a wild red mane, a one-shouldered leopard-skin dress and gold
/// bracelets; she fights with one huge swinging fist. Signature: she grows, and grows, the ground shaking under her
/// feet, then shrinks back to merely enormous.
private func drawGiganta(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { gigantaArt(c, p, grin: false); return }
    let grow = habitArc(s, hold: 0.5)
    let o = offscreen { gigantaArt($0, p, grin: grow > 0.3) }
    stamp(c, o, scale: 1 + 0.5 * grow)
    if grow > 0.1 {
        // The floor shakes.
        let i = Int(p.t * 14)
        for (n, x) in [6, 10, 46, 51].enumerated() {
            let up = Int(noise(i + n * 5) * 3)
            c.rect(x, 42 - up, 3, 2, C(0xC8B8A0, 0.6 * grow))
        }
    }
}

private func gigantaArt(_ c: PixelCanvas, _ p: Pose, grin: Bool) {
    let skin = clawdOrange, shade = clawdShade, hair = C(0xB0261A), hairDark = C(0x7A160E), hairLight = C(0xE04A2E)
    let hide = C(0xE8C070), hideDark = C(0xC09A48), spot = C(0x5A3416), gold = C(0xF0C040)
    // Thick legs.
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, skin); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 37, 3, lifted ? 6 : 7, skin)
        c.rect(lx + 2, 38, 1, lifted ? 5 : 6, shade)
    }
    c.oy += p.breathe
    // The mane, behind her.
    c.pattern(11, 16, [
        "......hHHHHHHHHHHHHHHHh.......",
        "....HHHHHHHHHHHHHHHHHHHHHH....",
        "..HHHHHLLHHHHHHHHHHHHHHHHHHH..",
        ".HHHHLLHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHH......................HHHH",
        "HHHh......................hHHH",
        "HHH........................HHH",
        "hHH........................HHh",
        "HHH........................HH.",
        ".HH........................HH.",
        "HHh........................hH.",
        ".H..........................H.",
        "hH..........................h.",
    ], ["H": hair, "h": hairDark, "L": hairLight])
    // The left arm hangs at her side.
    c.rect(10, 27, 5, 9, skin); c.rect(10, 27, 1, 9, shade)
    c.rect(10, 33, 5, 1, gold)
    c.rect(9, 35, 6, 4, skin); c.rect(9, 38, 6, 1, shade)
    // The big body.
    c.rect(15, 22, 26, 16, skin)
    c.rect(40, 22, 1, 16, shade)
    c.pattern(15, 18, [
        "...hHHHHHHHHHHHHHHHHHHh...",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHhHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHhHHHHHHH",
        "HHHHhh............hhHHHHHH",
        "HHh...................hHHH",
        "HH.....................HHH",
    ], ["H": hair, "h": hairDark])
    // Face: lashes, eyes, red lips.
    c.rect(20, 25, 4, 1, ink); c.rect(32, 25, 4, 1, ink)
    c.rect(21, 26, 2, 3, ink); c.rect(33, 26, 2, 3, ink)
    if grin {
        c.pattern(24, 30, ["RRRRRRRR", "RWWWWWWR", ".RRRRRR."], ["R": C(0xC0283A), "W": white])
    } else {
        c.rect(25, 30, 6, 1, C(0xC0283A)); c.px(24, 29, C(0xC0283A)); c.px(31, 29, C(0xC0283A))
    }
    // The leopard-skin dress, over one shoulder.
    for x in stride(from: 15, to: 41, by: 4) { c.rect(x, 32, 2, 1, hide) }
    c.rect(15, 33, 26, 6, hide)
    c.rect(15, 38, 26, 1, hideDark)
    let spots: [(Int, Int)] = [(17, 34), (22, 33), (27, 35), (33, 34), (38, 33), (19, 37), (24, 36), (30, 37), (36, 36)]
    for (x, y) in spots { c.px(x, y, spot); c.px(x + 1, y, hideDark) }
    if !seatedPose {
        for x in stride(from: 15, to: 41, by: 3) { c.px(x, 39, hide); c.px(x + 1, 39, hideDark) }
    }
    // The fist.
    let angle = p.melee ?? 85
    for (i, ta) in p.trail.enumerated() { drawGigantaArm(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
    drawGigantaArm(c, angle: angle)
}

/// Giganta's right arm, swung from the shoulder: a gold bracelet and a big fist on the end.
private func drawGigantaArm(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: gigantaShoulder, angle: angle, alpha: alpha) { s in
        s.rect(18, 18, 8, 5, clawdOrange)
        s.rect(18, 22, 8, 1, clawdShade)
        s.rect(24, 18, 2, 5, C(0xF0C040))
        s.rect(26, 17, 6, 7, clawdOrange)
        s.rect(31, 18, 1, 5, clawdShade); s.rect(26, 23, 6, 1, clawdShade)
        s.px(29, 18, clawdShade); s.px(29, 20, clawdShade)
    }
}

// MARK: - Silver Swan

/// Silver Swan: Clawd in a silver suit and swan cowl, a feathered crest swept back over her head, a dark visor with
/// pale blue lenses and red lips, and two great white wings folded down her back. She attacks with a sonic scream.
/// In flight she leans into it, wings beating. Signature: she spreads her wings wide and screams, rings of sound
/// rolling off across the room.
private func drawSilverSwan(_ c: PixelCanvas, _ p: Pose) {
    if p.flying {
        tilted(c, 18) { swanArt($0, p, spread: 0.85 + 0.15 * sin(p.t * 10), flap: sin(p.t * 10), scream: false) }
        return
    }
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let scream = p.zap != nil || (p.signature.map { $0 > 0.3 && $0 < 0.85 } ?? false)
    swanArt(c, p, spread: max(k, p.zap == true ? 0.3 : 0), flap: 0, scream: scream)
    if let s = p.signature, s > 0.3, s < 0.85 {
        soundRings(c, x: 37, y: Double(33 + p.breathe), t: p.lt, reach: 30, n: 4, C(0xD8E8FF), spread: 35)
    } else if p.zap != nil {
        soundRings(c, x: 37, y: Double(33 + p.breathe), t: p.lt, reach: 7, n: 2, C(0xD8E8FF), spread: 40)
    }
}

private func swanArt(_ c: PixelCanvas, _ p: Pose, spread: Double, flap: Double, scream: Bool) {
    let silver = C(0xC4CAD6), silverDark = C(0x8A92A2), silverLight = C(0xEEF2F8), blue = C(0x9AC8F0)
    swanWing(c, spread: spread, flap: flap, far: true, lift: p.breathe)
    drawLegs(c, Look(leg: silverDark), step: p.step)
    drawBoots(c, silverLight, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: silver, shade: silverDark, arm: silver, eye: nil))
    // The cowl, with a feathered crest swept back.
    c.pattern(13, 17, [
        "..............WW.......",
        "...........WWWWW.......",
        "........WWWWWWw........",
        "WWWWWWWWWWWWw..........",
        ".wWWWWWSSSSSSSSSSSS....",
        "...wWSSSSSSSSSSSSSSSS..",
        ".....SSSSLLLLSSSSSSSSS.",
        ".....SSSSSSSSSSSSSSSSS.",
        ".....SSSSSSSSSSSSSSSSS.",
        ".....SS..............S.",
    ], ["W": white, "w": silverDark, "S": silver, "L": silverLight])
    // The visor, and the lower face bare.
    c.rect(19, 28, 19, 4, C(0x2A2E3A))
    c.rect(21, 29, 4, 2, blue); c.rect(31, 29, 4, 2, blue)
    c.px(21, 29, white); c.px(31, 29, white)
    c.rect(19, 32, 18, 3, clawdOrange)
    c.rect(36, 32, 1, 3, clawdShade)
    if scream {
        c.pattern(26, 32, ["RRRR", "RKKR", "RKKR", ".RR."], ["R": C(0xD0283A), "K": C(0x3A0A14)])
    } else {
        c.rect(27, 33, 3, 1, C(0xD0283A))
    }
    // The suit: a pale blue swan's neck curving down the chest.
    c.rect(18, 35, 20, 3, silver)
    c.rect(37, 35, 1, 3, silverDark)
    c.pattern(24, 35, ["..BB..", ".B..B.", "B....B"], ["B": blue])
    c.rect(18, 37, 20, 1, silverDark)
    swanWing(c, spread: spread, flap: flap, far: false, lift: 0)
    c.rect(15, 33, 3, 3, silver)
    c.rect(38, 33, 3, 3, silver)
}

/// One of Silver Swan's wings, eight white feathers fanned from the shoulder: folded down her back (`spread` 0) or
/// raised wide behind her (1); `flap` swings it in flight. The far wing is greyer and sits higher.
private func swanWing(_ c: PixelCanvas, spread k: Double, flap: Double, far: Bool, lift: Int) {
    let root = far ? (x: 22.0, y: 27.0 + Double(lift)) : (x: 19.0, y: 29.0 + Double(lift))
    let feather = far ? C(0xB4BCCA) : C(0xF4F6FA), shade = far ? C(0x8A92A2) : C(0xC8D0DC), tip = far ? C(0x7A8494) : C(0xA8B4C8)
    for i in 0..<8 {
        let fi = Double(i)
        let folded = 100 + fi * 4, open = (far ? 214 : 204) + fi * 6 + flap * 22
        let a = (folded + (open - folded) * k) * .pi / 180
        let len = 9 + k * ((far ? 4 : 6) + fi * 1.7)
        let end = (x: root.x + cos(a) * len, y: root.y + sin(a) * len)
        bar(c, root.x, root.y, end.x, end.y, i % 2 == 0 ? feather : shade, 1.0)
        c.px(Int(end.x.rounded()), Int(end.y.rounded()), tip)
    }
}

// MARK: - Black Manta

/// Black Manta: a short black wetsuit Clawd almost swallowed by the giant round helmet, its two great red eye lenses,
/// a grille below them and a breathing hose round the back. The eyes fire red beams. Signature: the lenses go dark,
/// red light swirls into them as they charge, and two beams scorch the floor ahead before they cool.
private func drawBlackManta(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E1E24), suitLight = C(0x3A3A46), helm = C(0x24242C), helmLight = C(0x4A4A5A), shine = C(0x8A8A9C)
    let red = C(0xFF2A2A), redDark = C(0x6A0A0A), hot = C(0xFFD8D0)
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, suitLight, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: suit, shade: C(0x121216), arm: suit, eye: nil))
    // Chest harness and belt.
    c.rect(18, 33, 20, 4, suitLight)
    c.rect(20, 34, 16, 1, helm); c.rect(27, 33, 2, 4, helm)
    c.rect(18, 36, 20, 1, C(0x5A1A1A)); c.rect(27, 36, 2, 1, red)
    // The hose round the back.
    bar(c, 16.5, 25, 14.5, 30, helmLight, 0.9); bar(c, 14.5, 30, 17, 34.5, helmLight, 0.9)
    for y in [27, 30, 33] { c.px(15, y, shine) }
    // The helmet.
    c.ellipse(28, 23, 13, 10, C(0x101014))
    c.ellipse(28, 23, 12, 9, helm)
    c.rect(18, 16, 6, 1, shine); c.rect(17, 17, 2, 2, helmLight); c.rect(20, 15, 8, 1, helmLight)
    c.rect(26, 13, 4, 1, helmLight)
    // The grille.
    for x in stride(from: 24, through: 32, by: 2) { c.rect(x, 28, 1, 3, helmLight) }
    c.rect(24, 31, 9, 1, C(0x101014))

    var glow = 0.45, lens = red
    var swirl: Double?, fire: Double?
    if let s = p.signature {
        if s < 0.2 { lens = redDark; glow = 0 }
        else if s < 0.6 { let f = (s - 0.2) / 0.4; glow = f; lens = f > 0.5 ? red : redDark; swirl = f }
        else if s < 0.82 { glow = 1.4; fire = (s - 0.6) / 0.22 }
        else { glow = 0.45 * (s - 0.82) / 0.18 }
    }
    if p.fire != nil || p.ready { glow = max(glow, 0.9) }
    for ex in [21, 31] {
        c.pattern(ex, 19, [".LLLL.", "LLhLLL", "LhLLLL", "LLLLLL", "LLLLLd", ".LLdd."],
                  ["L": lens, "h": glow > 0.5 ? hot : C(0xFF8A7A), "d": redDark])
        if glow > 0 {
            dot(c, Double(ex) + 3, 22, core: clear, glow: red, r: 0, g: 3 + glow * 2, strength: 0.4 * min(1, glow))
        }
    }
    if let f = swirl {
        let n = Int(p.t * 40)
        for i in 0..<6 {
            let a = noise(n + i) * 2 * .pi, r = 7 * (1 - frac(f * 3 + Double(i) / 6))
            let cx: Double = i % 2 == 0 ? 24 : 34
            c.px(Int(cx + cos(a) * r), Int(22 + sin(a) * r), C(0xFF6A5A))
        }
    }
    if let f = fire {
        let tx = 47 + f * 10
        for ex in [24.0, 34.0] {
            c.glowLine(ex, 22, tx + (ex - 34) * 0.3, 43, core: C(0xFFE0E0), glow: red, coreR: 0.6, glowR: 2)
        }
        drawSparks(c, x: tx, y: 42.5, t: p.t, size: 3)
    }
    c.rect(15, 33, 3, 3, suit)
    if p.fire != nil || p.ready {
        c.rect(38, 32, 4, 3, suit); c.rect(41, 32, 1, 3, suitLight)
    } else {
        c.rect(38, 33, 3, 3, suit)
    }
}

// MARK: - Ocean Master

/// Ocean Master (Orm Marius): the purple scale-armoured suit, a silver mask across his eyes with a crown of points
/// above it, a sea-green cape and a gold trident whose prongs throw his sea magic. Signature: he raises the trident
/// and a waterspout spirals up round him from the floor.
private func drawOceanMaster(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x5E2E86), purpleDark = C(0x3E1A5E), purpleLight = C(0x7E4AA8)
    let green = C(0x1E7A5E), greenDark = C(0x125040), silver = C(0xC8CCD4), silverDark = C(0x8A8F9C)
    let gold = C(0xE8B530), goldLight = C(0xFFE08A), cyan = C(0x6AF0F0)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawCape(c, t: p.lt, speed: p.capeSpeed + 4 * k, color: green, edge: greenDark, extra: 2 * k)
    if k > 0.02 { waterspout(c, t: p.lt, k: k, front: false) }
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, green, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: purple, shade: purpleDark, arm: purple, eye: nil))
    // Crown and mask.
    c.pattern(18, 19, [
        "..G....G..G....G....",
        "..G...GG..GG...GG...",
        ".GG...GGGGGG...GG...",
        ".GGG.GGGGGGGG.GGG...",
        "GGGGGGGGLLGGGGGGGGGG",
        "SSSSSSSSSSSSSSSSSSSS",
        "SSLLSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSS",
    ], ["G": gold, "L": goldLight, "S": purpleLight])
    c.rect(18, 27, 20, 5, silver)
    c.rect(18, 31, 20, 1, silverDark)
    c.rect(27, 27, 2, 6, silverDark)
    c.rect(21, 29, 4, 2, ink); c.rect(31, 29, 4, 2, ink)
    c.px(23, 29, cyan); c.px(33, 29, cyan)
    c.rect(24, 34, 7, 1, purpleDark)                                     // the stern mouth
    // Scale armour, belt.
    for y in [35, 37] { for x in stride(from: 19 + (y % 4 == 1 ? 0 : 1), to: 37, by: 3) { c.px(x, y, purpleLight) } }
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 1, cyan)
    c.rect(15, 33, 3, 3, purple)

    // The trident.
    let r = p.armRaise + Int((k * 7).rounded())
    bar(c, 41.5, Double(21 - r), 41.5, Double((seatedPose ? 38 : 42) - r), gold, 0.55)
    c.pattern(39, 16 - r, ["L.L.L", "G.G.G", "G.G.G", "GGGGG", "..G.."], ["G": gold, "L": goldLight])
    c.rect(38, 33 - r, 3, 3, purple)
    c.rect(38, 35 - r, 3, 1, green)
    if k > 0.5 { dot(c, 41.5, Double(18 - r), core: C(0xE0FFFF), glow: C(0x2AC8D8), r: 0.6, g: 2.5 * k) }
    if k > 0.02 { waterspout(c, t: p.lt, k: k, front: true) }
}

/// A spiral of water climbing round Ocean Master: the back half (behind him) or the front half.
private func waterspout(_ c: PixelCanvas, t: Double, k: Double, front: Bool) {
    let n = 56
    for i in 0..<n {
        let f = Double(i) / Double(n)
        guard f < k else { continue }
        let a = f * .pi * 6 + t * 7
        let inFront = sin(a) > 0
        guard inFront == front else { continue }
        let x = 28 + cos(a) * (13 - f * 4), y = 43 - f * 28
        dot(c, x, y, core: inFront ? C(0xE8FFFF) : C(0x9AE0E8), glow: C(0x2AC8D8), r: 0.5, g: 1.4, strength: inFront ? 1 : 0.6)
    }
    if front {
        let i = Int(t * 12)
        for j in 0..<5 { c.px(14 + j * 7 + Int(noise(i + j) * 3), 43 - Int(noise(i + j + 5) * 2), C(0xE8FFFF, 0.8 * k)) }
    }
}

// MARK: - The Trench

/// The Trench: a hunched deep-sea monster in blue-black scales, a spiny fin crest, blind milky eyes, a huge jaw of
/// needle teeth, gill slits, glowing blue-green spots and an angler's lure dangling a light in front of its face; it
/// rakes with webbed, hooked claws. Signature: the lure brightens and sways, hypnotic, then the jaws gape and it
/// shrieks.
private func drawTrench(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x1E3A4E), dark = C(0x10222E), light = C(0x3A6278), belly = C(0x5A7A80)
    let glow = C(0x5AF0E0), eye = C(0xDCE8D0), gum = C(0x4A1424), tooth = C(0xF0F0E0)
    let sig = p.signature
    let shriek = sig.map { $0 > 0.6 && $0 < 0.92 } ?? false
    let gape = shriek || p.hit || (p.melee != nil && !p.walking && !p.resting)
    let lureK = sig.map { $0 < 0.65 ? habitArc($0 / 0.65, hold: 0.5) : 0 } ?? 0

    drawLegs(c, Look(leg: skin), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx - 1, bottom, 4, 1, dark)                            // webbed feet
            c.px(lx + 3, bottom, tooth)
            c.px(lx, 38, light)
        }
    }
    c.oy += p.breathe
    // The fin crest, behind the head and down the back.
    c.pattern(14, 18, [
        "......F...F...F.......",
        ".....FmF.FmF.FmF......",
        "....FmmFFmmFFmmmF.....",
        "...FmmmmmmmmmmmmmF....",
        "..FmmmmmmmmmmmmmmmF...",
        ".FFmmmmmmmmmmmmmmmmF..",
        "FFmm..................",
        "Fmm...................",
        "Fm....................",
        "F.....................",
    ], ["F": dark, "m": C(0x2E5468)])
    drawBody(c, Look(body: skin, shade: dark, arm: skin, eye: nil))
    c.rect(18, 26, 20, 1, light)
    // Scales and glowing spots.
    let scales: [(Int, Int)] = [(20, 27), (24, 27), (29, 27), (34, 27), (19, 36), (33, 36), (36, 30)]
    for (x, y) in scales { c.px(x, y, light); c.px(x + 1, y + 1, dark) }
    let pulse = 0.6 + 0.4 * sin(p.lt * 3)
    for (x, y) in [(19, 34), (21, 36), (35, 34), (37, 32), (25, 37), (31, 37)] as [(Int, Int)] { c.px(x, y, glow.alpha(pulse)) }
    for x in [19, 21] { c.rect(x, 31, 1, 3, dark) }                          // gill slits
    // Blind eyes.
    for ex in [21, 32] {
        c.rect(ex, 28, 3, 3, eye); c.px(ex, 28, white); c.px(ex + 2, 30, C(0xA8B8A0))
        c.rect(ex - 1, 27, 5, 1, dark)
    }
    // The jaw.
    if gape {
        c.rect(22, 31, 15, 6, gum)
        for x in stride(from: 22, through: 36, by: 2) { c.px(x, 31, tooth); c.px(x, 32, tooth); c.px(x + 1, 36, tooth); c.px(x + 1, 35, tooth) }
        c.rect(23, 34, 13, 1, C(0x2A0A12))
    } else {
        c.rect(22, 33, 15, 1, ink)
        for x in stride(from: 22, through: 36, by: 2) { c.px(x, 32, tooth); c.px(x + 1, 34, tooth) }
        c.rect(23, 35, 13, 2, belly)
    }
    // The lure on its stalk.
    let swing = sig != nil && lureK > 0 ? sin(p.lt * 6) * 3 * lureK : sin(p.lt * 2) * 0.8
    let bx = 40 + swing, by = 21 + sin(p.lt * 3) * 0.8
    bar(c, 29, 25, 33, 16, dark, 0.6)
    bar(c, 33, 16, 38, 15, dark, 0.55)
    bar(c, 38, 15, bx, by - 1.5, dark, 0.45)
    let bright = 0.7 + 0.3 * sin(p.lt * 5) + 0.6 * lureK
    dot(c, bx, by, core: C(0xE8FFF8), glow: glow, r: 0.9, g: 2.2 + 2.5 * lureK, strength: min(1, bright))
    if shriek {
        soundRings(c, x: 38, y: 33, t: p.lt, reach: 20, n: 3, glow, spread: 40)
    }
    // Claws.
    c.rect(15, 33, 3, 3, skin); c.px(14, 35, tooth); c.px(14, 33, tooth)
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            drawClaws(c, angle: ta, alpha: 0.4 / Double(i + 1), arm: skin, claw: glow, tip: glow, ghost: true, long: 1)
        }
        drawClaws(c, angle: a, arm: skin, claw: C(0xC8D0C0), tip: tooth, long: 1)
    } else if shriek {
        c.rect(38, 29, 3, 3, skin)
        for dy in 0..<3 { c.px(41, 28 + dy, tooth); c.px(42, 27 + dy, tooth) }
    } else {
        c.rect(38, 33, 3, 3, skin)
        for dy in 0..<3 { c.px(41, 34 + dy, tooth) }
    }
}
