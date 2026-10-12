import Foundation

// Villains: the other Corps, the androids and the alien conquerors. Every one is Clawd in costume (Dex-Starr is a cat
// on Clawd's legs, Parallax and Starro are what Clawd would look like if fear or a starfish got hold of him). The
// ring-slingers fire steady beams in their Corps colour and build constructs in it.

let villains5: [Leader: Persona] = [
    .sinestro: Persona(name: "Sinestro", weapon: .magic, motion: .fly, magic: Magic(core: C(0xFFFFD0), glow: C(0xFFD81E), jagged: false),
                  headTop: 23, signature: 3.2, callout: "Beware your fears made into light!",
                  draw: drawSinestro),
    .atrocitus: Persona(name: "Atrocitus", weapon: .magic, motion: .fly, magic: Magic(core: C(0xFFE0D0), glow: C(0xE81E1E), jagged: false),
                  pivot: atrocitusHand, bulk: 4, headTop: 17, signature: 3.0, callout: "With blood and rage!",
                  draw: drawAtrocitus),
    .larfleeze: Persona(name: "Larfleeze", weapon: .magic, motion: .fly, magic: Magic(core: C(0xFFF0D0), glow: C(0xFF8A1E), jagged: false),
                  headTop: 16, signature: 3.0, callout: "Mine! It's all mine!",
                  draw: drawLarfleeze),
    .parallax: Persona(name: "Parallax", weapon: .magic, motion: .hover, magic: Magic(core: C(0xFFFFD0), glow: C(0xFFD81E)),
                  canSit: false, pivot: parallaxMouth, bulk: 8, headTop: 8, signature: 3.0,
                  draw: drawParallax),
    .manhunter: Persona(name: "Manhunter", weapon: .ranged, shot: .energy(core: C(0xFFF0F0), glow: C(0xFF3A3A)), armoured: true,
                  muzzle: (52, 32), headTop: 20, signature: 2.6, callout: "You will be judged.",
                  draw: drawManhunter),
    .dexStarr: Persona(name: "Dex-Starr", weapon: .melee, motion: .fly, bulk: 9, headTop: 19, signature: 2.6,
                  draw: drawDexStarr),
    .amazo: Persona(name: "Amazo", weapon: .melee, motion: .fly, armoured: true, pivot: amazoShoulder, headTop: 23, signature: 4.4,
                  callout: "I have all of your powers.",
                  draw: drawAmazo),
    .starro: Persona(name: "Starro", weapon: .magic, motion: .hover, magic: Magic(core: C(0xF0E0FF), glow: C(0xB84AE8), jagged: false),
                  canSit: false, pivot: starroTip, bulk: 6, headTop: 10, signature: 3.2, callout: "Join us.",
                  draw: drawStarro),
    .despero: Persona(name: "Despero", weapon: .magic, magic: Magic(core: C(0xFFE0F0), glow: C(0xFF4AA8), jagged: false),
                  pivot: desperoHand, bulk: 4, headTop: 6, signature: 3.0, callout: "Your minds are mine.",
                  draw: drawDespero),
    .eclipso: Persona(name: "Eclipso", weapon: .magic, motion: .fly, magic: Magic(core: C(0xF0E0FF), glow: C(0x6A2AD8)),
                  pivot: eclipsoDiamond, headTop: 20, signature: 3.4, callout: "Darkness falls.",
                  draw: drawEclipso),
]

// MARK: - Helpers

private let clear = C(0, 0)

/// A solid line `r` thick: limbs, horns, ears, tails.
private func stick(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// A hard-light construct stroke: a pale core in a glow of the Corps colour.
private func construct(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, core: Px, glow: Px,
                       alpha: Double = 1, r: Double = 0.6) {
    c.glowLine(x0, y0, x1, y1, core: core.alpha(alpha), glow: glow.alpha(alpha), coreR: r, glowR: r + 1.4)
}

/// A soft glowing dot: rings, eyes, gems.
private func glowDot(_ c: PixelCanvas, _ x: Double, _ y: Double, core: Px, glow: Px, r: Double = 0.5, glowR: Double = 2,
                     strength: Double = 1) {
    c.glowLine(x, y, x, y, core: core, glow: glow, coreR: r, glowR: glowR, strength: strength)
}

/// Faint smears behind a fast melee swing, `from`…`to` pixels out from `pivot`.
private func swingTrail(_ c: PixelCanvas, _ pivot: (x: Double, y: Double), _ trail: [Double], from: Double, to: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(pivot.x + cos(r) * from, pivot.y + sin(r) * from, pivot.x + cos(r) * to, pivot.y + sin(r) * to,
                   core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// A ring of dots `rx` × `ry` round (`cx`, `cy`): shockwaves and telepathic rings.
private func ringOutline(_ c: PixelCanvas, _ cx: Double, _ cy: Double, rx: Double, ry: Double, _ col: Px) {
    let n = max(12, Int((rx + ry) * 2.2))
    for k in 0..<n {
        let a = Double(k) / Double(n) * 2 * .pi
        c.px(Int((cx + cos(a) * rx).rounded(.down)), Int((cy + sin(a) * ry).rounded(.down)), col)
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

/// Legs held together and trailing, for flight: `boot` on the last rows.
private func flightLegs(_ c: PixelCanvas, _ col: Px, boot: Px, shade: Px) {
    for lx in [21, 31] {
        c.rect(lx, 36, 4, 5, col); c.rect(lx, 39, 4, 2, boot); c.rect(lx + 3, 36, 1, 5, shade)
    }
}

/// Thick legs for the big ones (folded when sitting, like everyone's).
private func thickLegs(_ c: PixelCanvas, _ p: Pose, _ col: Px, boot: Px, shade: Px) {
    if p.flying {
        for lx in [20, 31] { c.rect(lx, 36, 5, 5, col); c.rect(lx, 39, 5, 2, boot); c.rect(lx + 4, 36, 1, 5, shade) }
        return
    }
    for (i, lx) in [17, 22, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, boot); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 3, lifted ? 7 : 8, col)
        c.rect(lx + 2, 38, 1, lifted ? 5 : 6, shade)
        c.rect(lx, lifted ? 40 : 41, 3, 2, boot)
    }
}

/// Streaks of Corps-coloured light trailing behind a flyer.
private func auraStreaks(_ c: PixelCanvas, t: Double, _ col: Px, y0: Int = 26, y1: Int = 40) {
    let i = Int(t * 16)
    for k in 0..<5 {
        let y = y0 + Int(noise(i * 7 + k * 3) * Double(y1 - y0))
        let len = 4 + Int(noise(i * 5 + k) * 8)
        let x = 15 - len - Int(noise(k * 11 + i) * 4)
        c.rect(x, y, len, 1, col.alpha(0.35 + 0.3 * noise(i + k * 13)))
    }
}

/// A cape streaming out behind (to the left) in flight.
private func drawFlyingCape(_ c: PixelCanvas, t: Double, color: Px, edge: Px) {
    for x in 3...20 {
        let k = Double(20 - x) / 17
        let mid = 29 + k * 4 + sin(t * 9 - k * 5) * k * 1.6
        let half = 3 + k * 2
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, color)
        c.px(x, top, edge); c.px(x, bottom, edge)
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`, and
/// leaning forward one pixel every `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, dx: Int = 0, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = dx + (lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0)
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
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

/// "MINE!" in a tiny pixel font, its top-left at (x, y).
private func drawMine(_ c: PixelCanvas, x: Int, y: Int, _ col: Px) {
    c.pattern(x, y, [
        "M...M.III.N..N.EEE.!",
        "MM.MM..I..NN.N.E...!",
        "M.M.M..I..N.NN.EE..!",
        "M...M..I..N..N.E....",
        "M...M.III.N..N.EEE.!",
    ], ["M": col, "I": col, "N": col, "E": col, "!": col])
}

// MARK: - Sinestro

/// Sinestro: a lean magenta Clawd with the black widow's peak slicked back off a high forehead, mean slanted brows and
/// the pencil moustache, in the black Sinestro Corps uniform with yellow shoulders, boots and chest emblem, the
/// yellow ring on his casting hand. In flight he leans in, ring fist first, trailing yellow light. Signature: he
/// raises the ring and a yellow construct broadsword grows out of his fist, swings down to point at you, and fades.
private func drawSinestro(_ c: PixelCanvas, _ p: Pose) {
    layer(c, lean: p.flying ? 4 : 0) { drawSinestroBody($0, p) }
}

private func drawSinestroBody(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xC8407E), skinDark = C(0x962A5C), hair = C(0x18141C)
    let suit = C(0x1E1E26), suitDark = C(0x101016), yellow = C(0xF4D02A), yellowDark = C(0xB8961A)
    let ringCore = C(0xFFFFD0), ringGlow = C(0xFFD81E)
    let look = Look(body: skin, shade: skinDark, leg: suit, arm: suit, eye: nil)
    if p.flying {
        auraStreaks(c, t: p.t, ringGlow)
        flightLegs(c, suit, boot: yellow, shade: suitDark)
    } else {
        drawLegs(c, look, step: p.step)
        drawBoots(c, yellow, step: p.step, rows: 2)
    }
    c.oy += p.breathe

    // Signature: the construct sword (angle, length, fade).
    var raise = p.armRaise
    var sword: (angle: Double, len: Double, alpha: Double)?
    if let s = p.signature {
        raise = Int((habitArc(s, hold: 0.7) * 6).rounded())
        let grow = min(1, max(0, (s - 0.12) / 0.2))
        let sw = min(1, max(0, (s - 0.45) / 0.14))
        let e = sw * sw * (3 - 2 * sw)
        let fade = s > 0.82 ? max(0, (0.97 - s) / 0.15) : 1
        if grow > 0 && fade > 0 { sword = (-90 + 88 * e, 17 * grow, fade) }
    }
    if p.flying { raise = 0 }

    drawBody(c, look, armRight: raise)
    // The slicked-back hair with its sharp widow's peak, over a high forehead.
    c.pattern(18, 23, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHsHHHHHHHHHHHHH.",
        "HHHHsHHHHHHHHHHHHHHH",
        "HHH.....HHHH.....HHH",
        "HH.......HH.......HH",
    ], ["H": hair, "s": C(0x3A3444)])
    c.rect(37, 27, 1, 2, skinDark)
    // Mean slanted brows, narrow eyes, the pencil moustache.
    c.pattern(20, 28, ["KK..........KK", "..KK......KK..", "..KK......KK.."], ["K": ink])
    c.rect(22, 31, 2, 1, skinDark); c.rect(32, 31, 2, 1, skinDark)
    c.rect(23, 32, 4, 1, hair); c.rect(29, 32, 4, 1, hair)
    c.rect(26, 33, 4, 1, skinDark)
    // The Sinestro Corps uniform.
    c.rect(18, 34, 20, 4, suit)
    c.rect(37, 34, 1, 4, suitDark)
    c.pattern(18, 34, ["YYY..............YYY", "yY................Yy"], ["Y": yellow, "y": yellowDark])
    c.pattern(26, 34, [".YYY.", "Y.Y.Y", ".YYY."], ["Y": yellow])      // the emblem
    c.rect(18, 37, 20, 1, yellowDark)
    c.rect(15, 33, 3, 1, yellow)

    if p.flying {
        // The ring fist thrust out ahead.
        c.rect(38, 31, 5, 3, suit); c.rect(38, 31, 5, 1, yellow)
        glowDot(c, 43, 32.5, core: ringCore, glow: ringGlow, r: 0.6, glowR: 2.2)
        return
    }
    c.rect(38, 33 - raise, 3, 1, yellow)
    let lit = p.zap != nil || sword != nil
    glowDot(c, 40.5, 34.5 - Double(raise), core: ringCore, glow: ringGlow, r: 0.5, glowR: lit ? 2.2 : 1.4, strength: lit ? 1 : 0.7)
    if let sw = sword {
        let hx = 40.5, hy = 33.5 - Double(raise)
        let r = sw.angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
        let a = sw.alpha
        construct(c, hx, hy, hx + ux * 2, hy + uy * 2, core: ringCore, glow: ringGlow, alpha: a, r: 0.5)
        let gx = hx + ux * 2.5, gy = hy + uy * 2.5
        construct(c, gx - nx * 3, gy - ny * 3, gx + nx * 3, gy + ny * 3, core: ringCore, glow: ringGlow, alpha: a, r: 0.5)
        if sw.len > 3 {
            let tip = (x: gx + ux * sw.len, y: gy + uy * sw.len)
            construct(c, gx + ux, gy + uy, tip.x - ux * 2, tip.y - uy * 2, core: ringGlow, glow: ringGlow, alpha: a * 0.55, r: 1.1)
            construct(c, gx + ux + nx * 1.2, gy + uy + ny * 1.2, tip.x - ux * 2 + nx * 1.2, tip.y - uy * 2 + ny * 1.2,
                      core: ringCore, glow: ringGlow, alpha: a, r: 0.35)
            construct(c, gx + ux - nx * 1.2, gy + uy - ny * 1.2, tip.x - ux * 2 - nx * 1.2, tip.y - uy * 2 - ny * 1.2,
                      core: ringCore, glow: ringGlow, alpha: a, r: 0.35)
            construct(c, tip.x - ux * 2 + nx * 1.2, tip.y - uy * 2 + ny * 1.2, tip.x, tip.y, core: ringCore, glow: ringGlow, alpha: a, r: 0.35)
            construct(c, tip.x - ux * 2 - nx * 1.2, tip.y - uy * 2 - ny * 1.2, tip.x, tip.y, core: ringCore, glow: ringGlow, alpha: a, r: 0.35)
        }
    }
}

// MARK: - Atrocitus

private let atrocitusHand = (x: 43.5, y: 32.5)

/// Atrocitus: a huge, bald, blood-red Clawd with a heavy scarred brow, glowing eyes and a snarl dripping blood, in
/// black armour with spiked shoulders and the Red Lantern emblem on his chest; the red ring on his fist. In flight he
/// leans in, blood drops streaming off behind. Signature: he rears back and spews burning napalm blood in an arc
/// onto the floor, where it burns.
private func drawAtrocitus(_ c: PixelCanvas, _ p: Pose) {
    layer(c, lean: p.flying ? 4 : 0) { drawAtrocitusBody($0, p) }
}

private func drawAtrocitusBody(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xA8242A), skinDark = C(0x701418), skinLight = C(0xD04840)
    let armour = C(0x2A2428), armourDark = C(0x18141A), armourLight = C(0x4E464C)
    let red = C(0xE81E1E), hot = C(0xFFD8C8), blood = C(0xC8101A)
    if p.flying {
        let i = Int(p.t * 14)
        for k in 0..<5 {                                                   // blood shed in flight
            let f = frac(p.t * 1.6 + Double(k) / 5)
            c.rect(14 - Int(f * 12), 26 + Int(noise(k * 7 + i / 6) * 10) + Int(f * 3), 2, 1, blood.alpha(1 - f * 0.7))
        }
        auraStreaks(c, t: p.t, red)
    }
    thickLegs(c, p, armour, boot: armourDark, shade: armourDark)
    c.oy += p.breathe

    // Signature timing: rear back, then the stream, then the fire on the floor.
    var rear = 0, stream = 0.0, fire = 0.0
    if let s = p.signature {
        if s < 0.18 { rear = s > 0.06 ? -1 : 0 }
        if s >= 0.18 && s < 0.78 { stream = min(1, (s - 0.18) / 0.12) * (s > 0.68 ? (0.78 - s) / 0.1 : 1) }
        if s > 0.4 { fire = min(1, (s - 0.4) / 0.1) * (s > 0.85 ? max(0, (1 - s) / 0.15) : 1) }
    }
    let raise = p.flying ? 0 : p.armRaise

    // The left arm hangs, a big fist.
    c.rect(12, 29, 4, 6, skin); c.rect(11, 34, 5, 4, skin); c.rect(11, 37, 5, 1, skinDark); c.rect(12, 29, 1, 6, skinDark)
    // The big body, its bald head and the scarred dome.
    c.rect(16, 22, 24, 16, skin)
    c.rect(39, 22, 1, 9, skinDark)
    c.oy += rear
    c.pattern(16, 17, [
        "......SSSSSSSSSSSS......",
        "...SSSSSLLSSSSSSSSSSS...",
        ".SSSSSLLSSSSSdSSSSSSSSS.",
        "SSSSSSSSSSSSSSdSSSSSSSSS",
        "SSSSSdSSSSSSSdSSSSSSSSSs",
    ], ["S": skin, "L": skinLight, "d": skinDark])
    c.pattern(18, 23, [
        ".dddddddd..dddddddd.",
        "dddddddddddddddddddd",
        "...................d",
    ], ["d": skinDark])
    c.rect(27, 25, 2, 3, skinDark)                                     // the nose ridge
    let eyeGlow = 0.6 + 0.4 * (p.zap != nil || stream > 0 ? 1 : sin(p.lt * 4) * 0.5 + 0.5)
    for ex in [21.5, 33.5] {
        c.rect(Int(ex) - 1, 25, 4, 2, red)
        glowDot(c, ex + 0.5, 25.5, core: hot, glow: red, r: 0.6, glowR: 2.2, strength: eyeGlow)
    }
    // The snarl, fangs and blood (wider open while he spews).
    let open = stream > 0 ? 1 : 0
    c.pattern(21, 28, ["KKKKKKKKKKKKKK", "KWKKWKKKKWKKWK"], ["K": C(0x2A0608), "W": C(0xF0E6D0)])
    if open > 0 { c.rect(22, 30, 12, 1, C(0x2A0608)); c.rect(23, 30, 10, 1, blood) }
    let drip = Int(p.lt * 3) % 4
    c.rect(23, 30 + open, 1, 1 + drip / 2, blood); c.rect(31, 30 + open, 1, 1 + (drip + 2) % 4 / 2, blood)
    c.oy -= rear
    // Black armour with spiked shoulders and the Red Lantern emblem.
    c.rect(16, 31, 24, 7, armour)
    c.rect(16, 31, 24, 1, armourLight)
    c.rect(39, 31, 1, 7, armourDark)
    c.pattern(12, 26, ["A.......................", "AA......................", "AAAA....................", ".AAAAA.................."],
              ["A": armourLight])
    c.pattern(24, 31, ["..RRRRR..", ".R.....R.", "R..RRR..R", "R.......R", ".R.....R.", "..RRRRR..", "....R...."],
              ["R": red])
    c.rect(16, 37, 24, 1, armourDark)

    // The ring fist.
    if p.flying {
        c.rect(40, 29, 5, 4, skin); c.rect(40, 32, 5, 1, skinDark)
        glowDot(c, 45, 30.5, core: hot, glow: red, r: 0.6, glowR: 2.4)
    } else {
        c.rect(40, 30 - raise, 4, 5, skin); c.rect(40, 34 - raise, 4, 1, skinDark)
        glowDot(c, 43.5, 32.5 - Double(raise), core: hot, glow: red, r: 0.5, glowR: p.zap != nil ? 2.4 : 1.5,
                strength: p.zap != nil ? 1 : 0.8)
    }

    // The napalm blood: an arc from his mouth to the floor, and the fire where it lands.
    if fire > 0 {
        let i = Int(p.t * 18)
        for k in 0..<7 {
            let x = 52 + k * 2, h = 2 + Int(noise(i + k * 5) * 4 * fire)
            c.rect(x, 43 - h, 2, h, C(0xFF7A1A).alpha(0.85 * fire))
            c.rect(x, 44 - h, 1, max(1, h - 2), C(0xFFE27A).alpha(fire))
        }
        c.rect(50, 43, 16, 1, blood.alpha(fire))
    }
    if stream > 0 {
        var prev = (x: 33.0, y: 29.5)
        let n = 10
        for k in 1...n {
            let u = Double(k) / Double(n) * stream
            let wob = sin(p.t * 25 + Double(k)) * 0.5
            let q = (x: 33 + u * 26, y: 29.5 + u * u * 13 + wob)
            c.glowLine(prev.x, prev.y, q.x, q.y, core: C(0xFF8A3A), glow: blood, coreR: 0.8, glowR: 2.0)
            prev = q
        }
    }
}

// MARK: - Larfleeze

/// Larfleeze: a grubby, hunched orange-brown creature with long droopy ears swept back, beady eyes and a wide grin
/// of crooked teeth, the Orange Lantern emblem on his chest, and his Orange Lantern (the power battery) never out of
/// his other hand. Signature: he snatches the lantern to his chest and hugs it, eyes darting, and "MINE!" pops up.
private func drawLarfleeze(_ c: PixelCanvas, _ p: Pose) {
    layer(c, lean: p.flying ? 4 : 0) { drawLarfleezeBody($0, p) }
}

private func drawLarfleezeBody(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xC0763A), furDark = C(0x8A4A22), furLight = C(0xDC9A5A)
    let orange = C(0xFF8A1E), orangeLight = C(0xFFD08A), rag = C(0x3A2A20), teeth = C(0xF0E2B0)
    let look = Look(body: fur, shade: furDark, leg: furDark, arm: fur, eye: nil)
    if p.flying {
        auraStreaks(c, t: p.t, orange)
        flightLegs(c, furDark, boot: furDark, shade: C(0x6A3418))
    } else {
        drawLegs(c, look, step: p.step)
        if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, p.step >= 0 && (lx == 19 || lx == 31 ? 0 : 1) == p.step ? 42 : 43, ink) } }
    }
    c.oy += p.breathe
    let hug = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let raise = p.flying ? 0 : p.armRaise

    // The ears: long, pointed and drooping down his back.
    let flap = sin(p.lt * (p.flying ? 14 : 2.5)) * (p.flying ? 1.5 : 0.6)
    let ears: [[(Double, Double)]] = [
        [(23, 25), (17, 20), (11, 21 + flap), (7, 27 + flap)],
        [(31, 24), (25, 17), (17, 16 + flap), (11, 19 + flap * 1.4)],
    ]
    for (n, e) in ears.enumerated() {
        let r: [Double] = [2.0, 1.5, 0.9]
        for i in 0..<3 { stick(c, e[i].0, e[i].1, e[i + 1].0, e[i + 1].1, n == 0 ? furDark : fur, r[i]) }
        stick(c, e[1].0, e[1].1 + 0.5, e[2].0, e[2].1 + 0.5, n == 0 ? C(0x6A3418) : furLight, 0.4)
    }
    // The hunched body: a lumpy head on top.
    drawBody(c, look, armLeft: 0, armRight: hug > 0.3 ? 0 : raise)
    c.pattern(18, 23, [
        ".....FFFFFFFFFF.....",
        "...FFFFFFlFFFFFFF...",
        ".FFFFFFFFFFFFFFFFFF.",
    ], ["F": fur, "l": furLight])
    c.rect(37, 25, 1, 3, furDark)
    // Beady eyes under a lumpy brow (darting about while he hugs his lantern).
    let dart = hug > 0.4 ? (sin(p.t * 9) > 0 ? 1 : 0) : 1
    c.rect(22, 27, 4, 1, furDark); c.rect(31, 27, 4, 1, furDark)
    c.rect(23, 28, 2, 2, C(0xFFE8A0)); c.rect(32, 28, 2, 2, C(0xFFE8A0))
    c.px(23 + dart, 29, ink); c.px(32 + dart, 29, ink)
    // The grin: wide, crooked teeth.
    c.pattern(21, 31, ["KKKKKKKKKKKKKK", "KTKTTKTKKTTKTK", ".KKKKKKKKKKKK."], ["K": C(0x2A120A), "T": teeth])
    c.px(36, 30, furDark); c.px(20, 30, furDark)
    // A dirty rag round his waist and the Orange Lantern emblem.
    c.rect(18, 35, 20, 3, rag)
    for x in stride(from: 19, to: 37, by: 3) { c.px(x, 37, fur) }
    c.pattern(26, 34, [".OOO.", "OoOoO", ".OOO."], ["O": orange, "o": orangeLight])

    // The Orange Lantern: at his side, or hugged to his chest.
    let lx = 9 + Int((hug * 16).rounded()), ly = 29 - Int((hug * 2).rounded())
    let pulse = 0.6 + 0.4 * sin(p.t * 5)
    glowDot(c, Double(lx) + 2.5, Double(ly) + 4.5, core: clear, glow: orange, r: 0, glowR: 4 + 2 * hug, strength: 0.45 * pulse)
    c.pattern(lx, ly, [
        "..h..",
        ".h.h.",
        "CCCCC",
        "OoooO",
        "OoWoO",
        "OoooO",
        "CCCCC",
        ".CCC.",
    ], ["h": C(0x8A8F9C), "C": C(0xB85A10), "O": orange, "o": orangeLight, "W": C(0xFFF8E0)])
    if hug > 0.3 {
        // Both arms clamped round it.
        c.rect(lx - 2, 33, 3, 3, fur); c.rect(lx + 4, 33, 3, 3, fur)
        if let s = p.signature, s > 0.25, s < 0.92 {
            let f = (s - 0.25) / 0.67
            let bob = Int(p.t * 8) % 2
            drawMine(c, x: 19, y: 9 - Int(f * 3) - bob, orange.alpha(min(1, (0.92 - s) / 0.15)))
            for k in 0..<3 {
                let g = frac(p.t * 1.5 + Double(k) / 3)
                c.px(lx + 2 + Int(sin(Double(k) * 2.1 + g * 6) * 5), ly - Int(g * 6), orangeLight.alpha(1 - g))
            }
        }
    } else {
        c.rect(12, 33, 4, 3, fur)                                          // the hand round its handle
    }
    if p.flying {
        c.rect(38, 31, 4, 3, fur)
        glowDot(c, 42, 32.5, core: C(0xFFF0D0), glow: orange, r: 0.6, glowR: 2.2)
    } else if hug <= 0.3 {
        glowDot(c, 40.5, 34.5 - Double(raise), core: C(0xFFF0D0), glow: orange, r: 0.5, glowR: p.zap != nil ? 2.2 : 1.4,
                strength: p.zap != nil ? 1 : 0.7)
    }
}

// MARK: - Parallax

private let parallaxMouth = (x: 51.5, y: 24.5)

/// Parallax: the yellow fear entity as a giant insect, Clawd's block become a segmented yellow thorax, a horned,
/// beaked head with burning eyes and pincer mandibles thrust forward, spindly jointed legs dangling, buzzing wings
/// and a segmented tail with a stinger. It hovers, and its fear pours from its jaws. Signature: it rears up, jaws
/// wide, and shrieks; rings of yellow fear roll out from it.
private func drawParallax(_ c: PixelCanvas, _ p: Pose) {
    let shell = C(0xE8BE2A), shellDark = C(0xA8801A), shellLight = C(0xFFE27A), deep = C(0x5A3E0E)
    let pale = C(0xF4E8C0), eyeHot = C(0xFFF4B0), eyeGlow = C(0xFF8A1A)
    let k = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let rear = Int((k * 3).rounded()) + p.armRaise
    let t = p.lt
    // Its own faint glow.
    glowDot(c, 28, 30, core: clear, glow: C(0xFFD81E), r: 0, glowR: 14, strength: 0.18 + 0.1 * k)
    // Wings, buzzing.
    let buzz = Int(p.t * 30) % 2
    c.ellipse(17, 22 - buzz, 8, 3 + buzz, C(0xFFE88A, 0.4))
    c.ellipse(21, 20 - buzz, 7, 3, C(0xFFF4C0, 0.3))
    // The tail: segments curling back and down to a stinger.
    let sw = sin(t * 2.2)
    let segs: [(Double, Double, Int)] = [(15, 33, 4), (10, 36 + sw * 0.5, 3), (6, 39 + sw, 3), (3.5, 42 + sw * 1.5, 2)]
    for (i, sg) in segs.enumerated().reversed() {
        c.ellipse(Int(sg.0), Int(sg.1), sg.2, sg.2 - (i == 0 ? 1 : 0), i % 2 == 0 ? shellDark : shell)
        c.px(Int(sg.0) - 1, Int(sg.1) - sg.2 + 1, shellLight)
    }
    stick(c, 3, 42 + sw * 1.5, 0, 45 + sw * 1.5, pale, 0.6)
    // Spindly legs hanging under it.
    let legs: [[(Double, Double)]] = [
        [(21, 37), (17, 41), (18, 46)],
        [(27, 37), (25, 42), (27, 47)],
        [(33, 37), (37, 41), (36, 46)],
    ]
    for (i, l) in legs.enumerated() {
        let s = sin(t * 3 + Double(i) * 1.7) * 0.8
        stick(c, l[0].0, l[0].1, l[1].0 + s, l[1].1, shellDark, 0.7)
        stick(c, l[1].0 + s, l[1].1, l[2].0 + s * 1.5, l[2].1, shellDark, 0.5)
        c.px(Int(l[2].0 + s * 1.5), Int(l[2].1), pale)
    }
    // The thorax: Clawd's block, plated.
    c.rect(18, 26, 20, 12, shell)
    c.rect(18, 37, 20, 1, shellDark)
    for x in [22, 27, 32] { c.rect(x, 26, 1, 12, shellDark); c.rect(x + 1, 27, 1, 9, shellLight) }
    c.rect(18, 26, 20, 1, shellLight)
    c.rect(18, 34, 20, 1, deep.alpha(0.5))
    c.rect(15, 32, 3, 3, shellDark)                                         // a stub of a foreleg on the far side
    c.rect(38, 33, 4, 2, shellDark); c.rect(41, 34, 2, 3, pale)            // a clawed foreleg
    // The head, reared up `rear` px.
    let hy = 15 - rear
    stick(c, 37, Double(hy) + 2, 30, Double(hy) - 4, shellDark, 0.6)        // antennae swept back
    stick(c, 30, Double(hy) - 4, 23, Double(hy) - 4 + sin(t * 3), shellDark, 0.45)
    stick(c, 40, Double(hy) + 1, 36, Double(hy) - 7, shellDark, 0.6)
    stick(c, 36, Double(hy) - 7, 29, Double(hy) - 9 + sin(t * 3 + 1), shellDark, 0.45)
    c.rect(33, hy + 9, 6, 26 - (hy + 9), shellDark)                          // the neck
    c.pattern(31, hy, [
        "....dSSSSd.......",
        "..dSSLLSSSSd.....",
        ".dSLLSSSSSSSSd...",
        "dSSSSSSSSSSSSSSd.",
        "dSSSSSSSSSSSSSSSd",
        "SSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSd",
        "dSSSSSSSSSSSSSSd.",
        ".dSSSSSSSSSSSdd..",
        "..ddSSSSSSSdd....",
        "....ddddddd......",
    ], ["S": shell, "d": shellDark, "L": shellLight])
    // Burning eyes and the beak.
    stick(c, 35, Double(hy) + 3.5, 44, Double(hy) + 5.5, deep, 0.7)        // the cruel brow
    for (ex, ey) in [(36, hy + 5), (41, hy + 6)] {
        c.rect(ex, ey, 3, 2, eyeGlow); c.px(ex + 1, ey, eyeHot)
        glowDot(c, Double(ex) + 1.5, Double(ey) + 1, core: eyeHot, glow: eyeGlow, r: 0.4, glowR: 2.2, strength: 0.6 + 0.4 * k)
    }
    c.pattern(44, hy + 6, ["SSSd", "SSSSd", "SSSd."], ["S": shell, "d": shellDark])
    // The mandibles: two pincers, opening wide when it shrieks or casts.
    let gape = k * 30 + (p.zap == true ? 12 : 0) + sin(t * 4) * 4
    let mx = 45.0, my = Double(hy) + 9
    for side in [-1.0, 1.0] {
        let a = (side * (10 + gape) + 20) * .pi / 180
        let bx = mx + cos(a) * 4, by = my + sin(a) * 4
        stick(c, mx, my, bx, by, pale, 0.8)
        let a2 = a - side * 0.9
        stick(c, bx, by, bx + cos(a2) * 3, by + sin(a2) * 3, pale, 0.5)
        c.px(Int(bx), Int(by), shellDark)
    }
    if k > 0.2 {
        // The shriek: rings of fear rolling out.
        for n in 0..<3 {
            let f = frac(p.t * 1.4 + Double(n) / 3)
            let col = C(0xFFEC6A).alpha((1 - f * 0.7) * k)
            ringOutline(c, 46, Double(hy) + 9, rx: 3 + f * 18, ry: 2 + f * 13, col)
        }
    }
}

// MARK: - Manhunter

/// A Manhunter: the Guardians' first police, an android with a smooth red face (black eye slits, a carved mouth and
/// a seam down the middle) inside a blue hood, a blue body with a gold belt and a red mantle, red boots, and a
/// energy baton. Signature: its eyes flare and a red scanning beam fans out, sweeping you top to bottom.
private func drawManhunter(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8302A), redDark = C(0x8A1A18), redLight = C(0xE45A48)
    let blue = C(0x2A4AB0), blueDark = C(0x1A3078), blueLight = C(0x4A6AD0), gold = C(0xE8B530), goldDark = C(0xB0861E)
    let metal = C(0x3E424C), metalDark = C(0x22242A)
    let look = Look(body: red, shade: redDark, leg: blue, arm: blue, eye: nil)
    drawLegs(c, look, step: p.step)
    drawBoots(c, red, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, look)
    // The face: smooth, with a seam, eye slits and a carved mouth.
    c.rect(27, 26, 1, 8, redDark)
    c.rect(20, 28, 5, 1, redLight); c.rect(31, 28, 5, 1, redLight)
    let scan = p.signature.map { $0 > 0.12 && $0 < 0.9 } ?? false
    let eye = scan || p.fire != nil ? C(0xFFE0D0) : ink
    c.rect(21, 30, 4, 1, eye); c.rect(31, 30, 4, 1, eye)
    if scan { for ex in [23.0, 33.0] { glowDot(c, ex, 30.5, core: C(0xFFF0F0), glow: C(0xFF3A3A), r: 0.5, glowR: 2) } }
    c.pattern(24, 32, ["KKKKKKK", ".K.K.K."], ["K": redDark])
    // The blue hood round it.
    c.pattern(15, 20, [
        ".......BBBBBBBBBBBB.......",
        ".....BBBBBBBBBBBBBBBB.....",
        "....BBBBbBBBBBBBBBBBBB....",
        "...BBBBBBBBBBBBBBBBBBBB...",
        "...BBBBBBBBBBBBBBBBBBBB...",
        "..BBBBBBBBBBBBBBBBBBBBBB..",
        "..BBBb..............bBBB..",
        "..BBB................BBB..",
        "..BB..................BB..",
        "..BB..................BB..",
        "..BB..................BB..",
        "..BB..................BB..",
        "..BBB................BBB..",
        "...BB................BB...",
    ], ["B": blue, "b": blueLight])
    c.rect(18, 25, 20, 1, gold)                                              // the gold band across the brow
    c.rect(27, 25, 2, 1, C(0xFFE08A))
    // The blue body, the gold belt, the mantle over the shoulders.
    c.rect(18, 34, 20, 4, blue)
    c.rect(37, 34, 1, 4, blueDark)
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 1, goldDark)
    c.pattern(18, 34, ["RRR..............RRR", ".RRR............RRR.", "..R..............R.."], ["R": red])   // the mantle's edges
    c.rect(26, 34, 4, 2, blueLight); c.rect(27, 34, 2, 2, gold)              // the Guardians' badge
    c.rect(15, 33, 3, 3, blue)
    // The energy baton, held level.
    let y = 32 + p.gunY
    c.rect(38, y + 1, 3, 3, blue)
    c.rect(40, y - 1, 11, 3, metal); c.rect(40, y + 1, 11, 1, metalDark); c.rect(41, y - 1, 8, 1, C(0x6A6E7A))
    c.rect(42, y + 2, 2, 2, metalDark)
    c.rect(47, y - 2, 2, 5, gold)
    c.rect(51, y - 1, 1, 3, p.fire != nil ? C(0xFFE0E0) : red)
    if scan, let s = p.signature {
        // The scan: a red fan from its eyes, sweeping down and back up.
        let f = (s - 0.12) / 0.78
        let sy = 20 + 24 * (0.5 - 0.5 * cos(f * 2 * .pi))
        let flick = 0.7 + 0.3 * noise(Int(p.t * 30))
        for e in [-4.0, 4.0] {
            c.glowLine(35, 30.5, 70, sy + e, core: C(0xFF8A8A, 0.85 * flick), glow: C(0xFF2A2A, 0.45), coreR: 0.35, glowR: 1.2)
        }
        for x in stride(from: 40.0, to: 70, by: 2) {
            let f = (x - 35) / 35
            c.px(Int(x), Int(30.5 + (sy - 30.5) * f), C(0xFF4A4A, 0.3 * flick))
        }
        c.glowLine(67, sy - 4, 67, sy + 4, core: C(0xFFC8C8, flick), glow: C(0xFF2A2A, 0.5), coreR: 0.5, glowR: 1.6)
    }
}

// MARK: - Dex-Starr

/// Dex-Starr: the Red Lantern cat, a blue house cat on Clawd's legs with pointed ears, glowing red eyes, a bloody
/// snarl, the Red Lantern emblem on his side and the red ring round his tail. He fights with red construct claws
/// raked off his forepaw, and flies stretched out like a cape-less superhero. Signature: he arches his back, every
/// hair on end and his tail bottle-brushed, hisses, and spits a gob of napalm blood that sizzles on the floor.
private func drawDexStarr(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x6E8ED0), furDark = C(0x4A68A8), furLight = C(0xA8C0EA), belly = C(0xC8D8F4)
    let red = C(0xE81E1E), hot = C(0xFFD8C8), blood = C(0xC8101A)
    let hiss = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let arch = Int((hiss * 4).rounded())
    let t = p.lt

    if p.flying {
        auraStreaks(c, t: p.t, red, y0: 28, y1: 38)
        c.rect(12, 34, 7, 2, fur); c.rect(12, 35, 2, 1, furDark)            // hind legs stretched back
        c.rect(14, 36, 6, 2, furDark)
    } else if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 39, 4, 2, fur) }
    } else {
        for (i, lx) in [20, 24, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 37, 2, lifted ? 5 : 6, i % 2 == 0 ? furDark : fur)
            c.rect(lx, lifted ? 41 : 42, 2, 1, belly)
        }
    }
    c.oy += p.breathe + (seatedPose ? 1 : 0)
    // The tail, with the ring on it: up and curling, or bottle-brushed straight up.
    let wave = sin(t * (p.walking ? 6 : 2)) * 2
    let tail: [(Double, Double)] = p.flying
        ? [(19, 31), (13, 30), (8, 29 + wave * 0.5), (4, 31 + wave)]
        : hiss > 0.3 ? [(19, 30), (17, 25), (16, 19), (17, 13)]
        : [(19, 31), (14, 28), (12, 22 + wave * 0.3), (14 + wave * 0.5, 17)]
    let tr = hiss > 0.3 ? 1.8 : 1.1
    for i in 0..<3 { stick(c, tail[i].0, tail[i].1, tail[i + 1].0, tail[i + 1].1, i == 2 ? furDark : fur, tr) }
    let rg = (x: (tail[1].0 + tail[2].0) / 2, y: (tail[1].1 + tail[2].1) / 2)
    stick(c, rg.x - 1.4, rg.y, rg.x + 1.4, rg.y, red, 0.6)
    glowDot(c, rg.x, rg.y, core: hot, glow: red, r: 0.3, glowR: p.zap != nil || p.melee != nil ? 2 : 1.3, strength: 0.7)
    // The body (humped up when he arches) and the emblem.
    c.rect(18, 29 - arch, 20, 9 + arch, fur)
    if arch > 0 { c.rect(18, 29 - arch, 3, arch, clear); c.rect(35, 29 - arch, 3, arch, clear) }
    c.rect(18, 37, 20, 1, furDark)
    c.rect(18, 35, 20, 2, belly)
    for x in [21, 25, 29] { c.rect(x, 29 - arch, 1, 3, furDark) }           // tabby stripes
    if hiss > 0.3 { for x in stride(from: 21, to: 35, by: 2) { c.px(x, 28 - arch, furDark); c.px(x + 1, 27 - arch, fur) } }
    c.pattern(24, 30 - arch / 2, [".RRR.", "R.R.R", "RRRRR", "R.R.R", ".RRR."], ["R": red])
    // The head, out front, with pointed ears.
    let hy = 19 - arch / 2 + (p.flying ? 3 : 0)
    c.pattern(33, hy, [
        "..F........F...",
        "..FF......FFF..",
        "..FlF....FlFF..",
        ".FFFFFFFFFFFFF.",
        "FFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFBBBB",
        "dFFFFFFFFFFBBBB.",
        ".dFFFFFFFFFFFF..",
        "..ddddddddddd...",
    ], ["F": fur, "l": C(0xE8A0B0), "d": furDark, "B": belly])
    c.rect(33, hy + 5, 1, 4, furDark)
    // Glowing red eyes, slitted.
    for ex in [37, 43] {
        c.rect(ex, hy + 5, 2, 2, red)
        glowDot(c, Double(ex) + 1, Double(hy) + 6, core: hot, glow: red, r: 0.4, glowR: 1.6, strength: 0.7)
        c.px(ex + 1, hy + 5, ink)
    }
    c.px(46, hy + 8, C(0xE86A8A))                                            // the nose
    // The snarl: fangs and a drip of blood.
    if hiss > 0.3 {
        c.pattern(41, hy + 9, ["KKKKK", "WKKKW", "KKKK."], ["K": C(0x2A0608), "W": white])
    } else {
        c.pattern(42, hy + 10, ["KKKK", "W..W"], ["K": C(0x2A0608), "W": white])
    }
    if Int(t * 2) % 3 != 0 { c.px(45, hy + 12, blood) }
    // Whiskers.
    c.px(47, hy + 7, furLight); c.px(48, hy + 6, furLight); c.px(47, hy + 9, furLight); c.px(48, hy + 10, furLight)

    if p.flying {
        // Forepaws out in front.
        c.rect(38, 33, 7, 2, fur); c.rect(44, 33, 1, 2, belly)
        return
    }
    if hiss > 0.5, let s = p.signature, s > 0.42 {
        // The spat gob of blood, arcing off and sizzling where it lands.
        let f = min(1, (s - 0.42) / 0.2)
        let x = 47 + f * 13, y = Double(hy) + 11 + f * f * 22
        if f < 1 {
            glowDot(c, x, y, core: C(0xFF6A3A), glow: blood, r: 0.8, glowR: 1.8)
        } else {
            let i = Int(p.t * 20)
            c.rect(57, 43, 6, 1, blood)
            for k in 0..<3 where noise(i + k) > 0.4 { c.px(57 + k * 2, 42 - Int(noise(i * 3 + k) * 3), C(0xFFB07A, 0.7)) }
        }
    }
    // The forepaw, and the red construct claws raked from it.
    if let a = p.melee {
        let pv = Sprite.hand
        swingTrail(c, pv, p.trail, from: 3, to: 12, red)
        c.rect(38, 32, 4, 3, fur); c.rect(41, 32, 2, 3, belly)
        let r = a * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
        for k in [-2.4, 0.0, 2.4] {
            // Each claw a thin hooked blade of red light.
            let x0 = pv.x + ux * 3 + nx * k, y0 = pv.y + uy * 3 + ny * k
            let xm = pv.x + ux * 9 + nx * (k * 1.2 + 0.6), ym = pv.y + uy * 9 + ny * (k * 1.2 + 0.6)
            let x1 = pv.x + ux * 12 + nx * (k * 1.3 + 2.2), y1 = pv.y + uy * 12 + ny * (k * 1.3 + 2.2)
            c.glowLine(x0, y0, xm, ym, core: C(0xFF9A8A, 0.92), glow: red, coreR: 0.4, glowR: 1.0)
            c.glowLine(xm, ym, x1, y1, core: C(0xFF9A8A, 0.92), glow: red, coreR: 0.35, glowR: 0.9)
        }
    } else if p.armRaise > 0 {
        c.rect(38, 33 - p.armRaise, 3, 3, fur)
    }
}

// MARK: - Amazo

private let amazoShoulder = (x: 39.5, y: 31.5)

/// Amazo: the android built to copy the Justice League, a green-skinned Clawd with pointed ears, slicked black hair
/// and red eyes, in a dark maroon suit with Wonder Woman's gold bracelets and a Lantern's green ring; he punches
/// with Superman's fist and flies like him, fist first. Signature: he runs through the League's powers one after
/// another: heat vision, a green ring construct, the Flash's lightning and afterimages, then the golden lasso.
private func drawAmazo(_ c: PixelCanvas, _ p: Pose) {
    // Which power (0 heat vision, 1 the ring, 2 speed, 3 the lasso) and how far through it.
    var power = -1, phase = 0.0
    if let s = p.signature {
        let bounds: [Double] = [0, 0.33, 0.6, 0.82, 1]
        for i in 0..<4 where s >= bounds[i] && s < bounds[i + 1] {
            power = i; phase = (s - bounds[i]) / (bounds[i + 1] - bounds[i])
        }
    }
    if power == 2 {
        // The Flash: afterimages smeared out behind, lightning crackling.
        layer(c, alpha: 0.25, dx: -6) { drawAmazoBody($0, p, power: -1, phase: 0) }
        layer(c, alpha: 0.45, dx: -3) { drawAmazoBody($0, p, power: -1, phase: 0) }
    }
    layer(c, lean: p.flying ? 4 : 0) { drawAmazoBody($0, p, power: power, phase: phase) }
    if power == 2 {
        let i = Int(p.t * 24)
        for b in 0..<2 {
            var prev = (x: 16.0 + noise(i + b) * 20, y: 22.0 + noise(i * 3 + b) * 6)
            for k in 1...3 {
                let q = (x: prev.x + (noise(i * 5 + k + b * 9) - 0.5) * 8, y: prev.y + 4)
                c.glowLine(prev.x, prev.y, q.x, q.y, core: C(0xFFF8C0), glow: C(0xFFC81E), coreR: 0.4, glowR: 1.4)
                prev = q
            }
        }
    }
}

private func drawAmazoBody(_ c: PixelCanvas, _ p: Pose, power: Int, phase: Double) {
    let skin = C(0x5AA84A), skinDark = C(0x3A7A30), skinLight = C(0x86C870), hair = C(0x16161B)
    let suit = C(0x6A1A28), suitDark = C(0x461018), gold = C(0xE8B530), goldDark = C(0xA8801E)
    let red = C(0xFF3A2A), hot = C(0xFFE0D0), green = C(0x3AE05A), greenCore = C(0xE0FFE0)
    let look = Look(body: skin, shade: skinDark, leg: suit, arm: suit, eye: nil)
    let k = power >= 0 ? habitArc(phase, hold: 0.6) : 0
    if p.flying {
        flightLegs(c, suit, boot: suitDark, shade: suitDark)
    } else {
        drawLegs(c, look, step: p.step)
        drawBoots(c, suitDark, step: p.step, rows: 2)
    }
    c.oy += p.breathe
    drawBody(c, look)
    // Slicked black hair and the pointed ears.
    c.pattern(18, 23, [
        "...HHHHHHHHHHHHHH...",
        ".HHHHHHsHHHHHHHHHHH.",
        "HHHHHHsHHHHHHHHHHHHH",
        "HHH..............HHH",
    ], ["H": hair, "s": C(0x3A3A44)])
    c.pattern(15, 27, ["S....................S", "SS..................SS", ".S..................S."], ["S": skinLight])
    c.rect(37, 27, 1, 6, skinDark)
    // Red eyes, a hard mouth.
    let eyeCol = power == 0 && k > 0.2 ? hot : red
    c.rect(22, 29, 2, 2, eyeCol); c.rect(32, 29, 2, 2, eyeCol)
    c.rect(21, 28, 3, 1, skinDark); c.rect(32, 28, 3, 1, skinDark)
    c.rect(25, 32, 6, 1, skinDark)
    // The maroon suit, a gold belt.
    c.rect(18, 34, 20, 4, suit)
    c.rect(37, 34, 1, 4, suitDark)
    c.pattern(18, 33, ["SS................SS", ".SS..............SS."], ["S": suit])
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 1, goldDark)
    c.rect(15, 33, 3, 3, skin); c.rect(15, 33, 3, 1, gold)                   // the left fist, a bracelet

    // Heat vision.
    if power == 0 && k > 0.2 {
        glowDot(c, 23, 30, core: hot, glow: red, r: 0.5, glowR: 2, strength: k)
        c.glowLine(33, 29.5, 70, 35.5, core: hot.alpha(k), glow: red.alpha(k), coreR: 0.4, glowR: 1.5)
        c.glowLine(33, 30.5, 70, 37, core: hot.alpha(k), glow: red.alpha(k * 0.7), coreR: 0.3, glowR: 1.2)
    }
    // The right arm: Superman's fist, swung from the shoulder.
    if p.flying {
        drawAmazoArm(c, angle: -8, ring: true)
        return
    }
    var angle = p.melee ?? 70
    if power == 1 { angle = -20 * k + 70 * (1 - k) }
    if power == 3 { angle = -100 * k + 70 * (1 - k) }
    for (i, ta) in p.trail.enumerated() where p.melee != nil { drawAmazoArm(c, angle: ta, ring: false, alpha: 0.35 / Double(i + 1)) }
    drawAmazoArm(c, angle: angle, ring: p.melee == nil || power == 1)
    if power == 1 && k > 0.2 {
        // A Green Lantern construct: a giant green fist flying out of the ring.
        let x = 50 + (1 - k) * -6
        let a = k
        construct(c, x - 4, 25, x + 4, 25, core: greenCore, glow: green, alpha: a, r: 0.4)
        construct(c, x + 4, 25, x + 4, 33, core: greenCore, glow: green, alpha: a, r: 0.4)
        construct(c, x + 4, 33, x - 4, 33, core: greenCore, glow: green, alpha: a, r: 0.4)
        construct(c, x - 4, 33, x - 4, 25, core: greenCore, glow: green, alpha: a, r: 0.4)
        for dy in [27.0, 29.0, 31.0] { construct(c, x + 1, dy, x + 4, dy, core: greenCore, glow: green, alpha: a * 0.7, r: 0.3) }
        construct(c, x - 4, 29, x - 9, 29, core: greenCore, glow: green, alpha: a, r: 0.5)
    }
    if power == 3 && k > 0.3 {
        // The lasso, twirled overhead in a glowing loop.
        let hx = 39.5 + cos(-100 * .pi / 180) * 9, hy = 31.5 + sin(-100 * .pi / 180) * 9
        let lasso = C(0xFFD84A), lassoCore = C(0xFFF4C0)
        let cx = hx + 2, cy = hy - 6
        ringOutline(c, cx, cy, rx: 9 * k, ry: 3 * k, lasso)
        ringOutline(c, cx, cy - 0.5, rx: 9 * k, ry: 3 * k, lasso.alpha(0.5))
        c.glowLine(hx, hy, cx + cos(p.t * 9) * 9 * k, cy + sin(p.t * 9) * 3 * k, core: lassoCore, glow: lasso, coreR: 0.3, glowR: 1.2)
    }
}

/// Amazo's right arm swung from the shoulder: a maroon sleeve, a gold bracelet and a green fist, `ring` lit on it.
private func drawAmazoArm(_ c: PixelCanvas, angle: Double, ring: Bool, alpha: Double = 1) {
    prop(c, at: amazoShoulder, angle: angle, alpha: alpha) { s in
        s.rect(19, 19, 6, 3, C(0x6A1A28))
        s.rect(25, 19, 2, 3, C(0xE8B530))
        s.rect(27, 18, 4, 5, C(0x5AA84A))
        s.rect(27, 22, 4, 1, C(0x3A7A30))
        s.px(30, 19, C(0x3A7A30)); s.px(30, 21, C(0x3A7A30))
    }
    if ring {
        let r = angle * .pi / 180
        glowDot(c, amazoShoulder.x + cos(r) * 8.5, amazoShoulder.y + sin(r) * 8.5, core: C(0xE0FFE0), glow: C(0x3AE05A),
                r: 0.4, glowR: 1.4, strength: 0.8 * alpha)
    }
}

// MARK: - Starro

private let starroTip = (x: 46.5, y: 22.5)

/// Starro the Conqueror: a giant violet starfish hanging in the air, Clawd's block become its central disc, five
/// fat arms curling at the tips, pale spots along them, and one huge staring eye in the middle. Its mind control
/// streams from the tip of its forward arm. Signature: its eye narrows and it buds off little spore starfish that
/// spin away to find faces to land on.
private func drawStarro(_ c: PixelCanvas, _ p: Pose) {
    let body = C(0x6A5AC8), dark = C(0x463A94), light = C(0x9A8AE8), spot = C(0xD8C8FF)
    let t = p.lt
    let sig = p.signature
    let squint = sig.map { habitArc($0, hold: 0.7) } ?? 0
    let cx = 28.0, cy = 27.0
    // The five arms: angle, length, how far each curls.
    let arms: [(a: Double, l: Double, curl: Double)] = [
        (-92, 17, 20 * sin(t * 1.3)),
        (-12, 19, -12 - Double(p.armRaise) * 4 + 6 * sin(t * 1.7)),
        (58, 17, 30 + 8 * sin(t * 1.1)),
        (122, 17, -30 + 8 * sin(t * 1.4)),
        (192, 19, 20 + 12 * sin(t * 1.6)),
    ]
    func path(_ arm: (a: Double, l: Double, curl: Double)) -> [(Double, Double, Double)] {
        var pts: [(Double, Double, Double)] = []
        var x = cx, y = cy
        let n = 8
        for i in 0...n {
            let f = Double(i) / Double(n)
            let a = (arm.a + arm.curl * f * f) * .pi / 180
            if i > 0 { x += cos(a) * arm.l / Double(n); y += sin(a) * arm.l / Double(n) }
            pts.append((x, y, 5.2 - 4.5 * f))
        }
        return pts
    }
    let paths = arms.map(path)
    for pts in paths {
        for i in 1..<pts.count { stick(c, pts[i - 1].0, pts[i - 1].1, pts[i].0, pts[i].1, dark, pts[i].2 + 0.9) }
    }
    for pts in paths {
        for i in 1..<pts.count { stick(c, pts[i - 1].0, pts[i - 1].1, pts[i].0, pts[i].1, body, pts[i].2) }
    }
    for pts in paths {
        for i in stride(from: 2, to: pts.count - 1, by: 2) { c.px(Int(pts[i].0), Int(pts[i].1), spot) }
        c.px(Int(pts[1].0 - 1), Int(pts[1].1 - 1), light)
    }
    // The central disc.
    c.ellipse(28, 27, 9, 8, body)
    c.rect(36, 23, 1, 9, dark)
    c.rect(22, 20, 5, 1, light); c.rect(20, 22, 1, 3, light)
    // The eye.
    let lid = Int((squint * 2).rounded())
    c.ellipse(29, 27, 6, 4, C(0x2A1E5A))
    c.ellipse(29, 27, 5, max(1, 3 - lid), C(0xF4ECD8))
    c.ellipse(30, 27, 3, max(1, 3 - lid), C(0xE8402A))
    c.rect(30, 26 + lid / 2, 2, max(1, 3 - lid), ink)
    if lid < 2 { c.px(31, 26, white) }
    c.rect(23, 22 + lid, 13, 1, dark)                                        // the brow over it
    if squint > 0.3 { glowDot(c, 30, 27, core: clear, glow: C(0xFF5A3A), r: 0, glowR: 4, strength: 0.4 * squint) }
    // The casting tip glows.
    if p.zap != nil {
        let tip = paths[1].last!
        glowDot(c, tip.0, tip.1, core: C(0xF0E0FF), glow: C(0xB84AE8), r: 0.6, glowR: 2.2)
    }
    if let s = sig, s > 0.15, s < 0.95 {
        // Spores: little starfish budding off and spinning away.
        for n in 0..<4 {
            let f = (s - 0.15 - Double(n) * 0.12) / 0.45
            guard f > 0, f < 1 else { continue }
            let x = 34 + f * 34, y = 24 - sin(f * .pi) * 10 + Double(n % 2) * 6
            let star: [String] = Int(f * 10) % 2 == 0 ? [".S.", "SSS", "S.S"] : ["S.S", ".S.", "S.S"]
            c.pattern(Int(x) - 1, Int(y) - 1, star, ["S": n % 2 == 0 ? light : body])
            c.px(Int(x), Int(y), spot)
        }
    }
}

// MARK: - Despero

private let desperoHand = (x: 44.5, y: 32.5)

/// Despero: a huge pink Clawd under his tall ridged head fin, the third eye in the middle of his forehead over two
/// mean yellow ones, a lipless grimace, in dark violet armour with gold trim and big pink fists. Signature: the third
/// eye opens wide and blazes, his fin flushes, and rings of telepathic force pulse out of his head.
private func drawDespero(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE07AAA), skinDark = C(0xB04E80), skinLight = C(0xF4A8CC)
    let fin = C(0xC84A86), finDark = C(0x8A2A5A), finHot = C(0xFF7AC0)
    let armour = C(0x2E2A5A), armourDark = C(0x1C1A3C), armourLight = C(0x4E4A8A), gold = C(0xE8B530)
    let k = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    thickLegs(c, p, armour, boot: armourDark, shade: armourDark)
    c.oy += p.breathe
    // The left fist hanging.
    c.rect(12, 29, 4, 6, skin); c.rect(11, 34, 5, 4, skin); c.rect(11, 37, 5, 1, skinDark)
    c.rect(12, 29, 4, 2, armourLight)
    // The big body.
    c.rect(16, 21, 24, 17, skin)
    c.rect(39, 21, 1, 10, skinDark)
    // The fin: tall, ridged, swept back.
    let fc = k > 0.3 ? finHot : fin
    c.pattern(15, 6, [
        "FF................",
        ".FFF..............",
        "..FFFF............",
        "..FdFFF...........",
        "...FdFFFF.........",
        "...FFdFFFF........",
        "....FdFFdFF.......",
        "....FFdFFdFF......",
        ".....FdFFdFFF.....",
        ".....FFdFFdFFF....",
        "......FdFFdFFdF...",
        "......FFdFFdFFdF..",
        ".......FdFFdFFdFF.",
        ".......FFFFFFFFFFF",
    ], ["F": fc, "d": finDark])
    c.rect(18, 20, 20, 1, skin); c.rect(17, 21, 1, 1, skin)
    c.rect(19, 21, 4, 1, skinLight)
    // Three eyes: the third one in the forehead opens wide with the signature.
    c.rect(19, 27, 6, 1, skinDark); c.rect(31, 27, 6, 1, skinDark)
    c.rect(20, 28, 4, 2, C(0xFFE04A)); c.rect(32, 28, 4, 2, C(0xFFE04A))
    c.rect(22, 28, 2, 2, ink); c.rect(34, 28, 2, 2, ink)
    let open = Int((k * 2).rounded())
    c.rect(25, 23 - open / 2, 6, 2 + open, skinDark)
    c.rect(26, 23 - open / 2, 4, 1 + open, C(0xFFE04A))
    c.rect(27, 23, 2, 1 + open / 2, C(0xC81E3A))
    if k > 0.2 || p.zap != nil {
        glowDot(c, 28, 23.5, core: C(0xFFE0F0), glow: C(0xFF4AA8), r: 0.6, glowR: 2.4 + 2 * k, strength: 0.7 + 0.3 * k)
    }
    c.rect(27, 26, 2, 3, skinDark)                                           // the nose ridge
    c.pattern(22, 31, ["KKKKKKKKKKKK", "KWKWWKKWWKWK", ".KKKKKKKKKK."], ["K": C(0x3A0A24), "W": C(0xF0E6D0)])
    // Violet armour with gold trim.
    c.rect(16, 34, 24, 4, armour)
    c.rect(16, 34, 24, 1, gold)
    c.rect(39, 34, 1, 4, armourDark)
    c.pattern(24, 35, ["..GG..", ".GaaG.", "..GG.."], ["G": gold, "a": armourLight])
    c.rect(16, 37, 24, 1, armourDark)
    c.pattern(12, 30, ["AAAA.", "AAAAA", ".AAAA"], ["A": armourLight])
    // The right fist, raised to cast.
    let r = p.armRaise
    c.rect(40, 30 - r, 5, 5, skin); c.rect(40, 34 - r, 5, 1, skinDark); c.rect(40, 30 - r, 2, 2, armourLight)
    if k > 0.2 {
        // Telepathic rings pulsing out of his head.
        for n in 0..<3 {
            let f = frac(p.t * 1.2 + Double(n) / 3)
            ringOutline(c, 28, 23.5, rx: 4 + f * 20, ry: 3 + f * 13, C(0xFF9AD8).alpha((1 - f * 0.8) * k))
        }
    }
}

// MARK: - Eclipso

private let eclipsoDiamond = (x: 41.5, y: 32.5)

/// Eclipso: the god of vengeance, a Clawd whose face is split down the middle, pale on one side and night-dark on
/// the other with a burning yellow eye, spiked black hair, a high-collared dark violet cloak and suit, and the Black
/// Diamond (the Heart of Darkness) in his casting hand. Signature: he lifts the Black Diamond and an eclipse comes
/// over above him, the moon sliding across a blazing sun, while the dark half spreads over his whole face.
private func drawEclipso(_ c: PixelCanvas, _ p: Pose) {
    let sig = p.signature
    if let s = sig, s > 0.08, s < 0.95 {
        // The eclipse overhead: a corona, and the moon sliding over it.
        let f = (s - 0.08) / 0.87
        let k = habitArc(f, hold: 0.5)
        let sx = 46.0, sy = 9.0
        glowDot(c, sx, sy, core: C(0xFFF8D0).alpha(k), glow: C(0xFFC84A).alpha(k), r: 3.2, glowR: 6.5)
        // The moon only shows where it covers the sun.
        let mx = sx - 9 + f * 18
        for y in Int(sy) - 4...Int(sy) + 4 {
            for x in Int(sx) - 4...Int(sx) + 4 {
                let px = Double(x) + 0.5, py = Double(y) + 0.5
                guard hypot(px - mx, py - sy) < 3.6, hypot(px - sx, py - sy) < 4.2 else { continue }
                c.px(x, y, C(0x0C0814).alpha(min(1, k * 1.5)))
            }
        }
    }
    layer(c, lean: p.flying ? 4 : 0) { drawEclipsoBody($0, p) }
}

private func drawEclipsoBody(_ c: PixelCanvas, _ p: Pose) {
    let pale = C(0xD8D0E4), paleDark = C(0xA8A0BC), night = C(0x231A44), nightEdge = C(0x3A2A6A)
    let suit = C(0x4A2A80), suitDark = C(0x2E1858), cloak = C(0x2A1450), cloakEdge = C(0x6A3AB0), hair = C(0x100C18)
    let eyeHot = C(0xFFF4B0), eyeGlow = C(0xFFB01E)
    let dark = p.signature.map { s -> Double in
        let f = (s - 0.08) / 0.87
        return f > 0.3 && f < 0.75 ? 1 : 0
    } ?? 0
    if p.flying {
        drawFlyingCape(c, t: p.t, color: cloak, edge: cloakEdge)
        flightLegs(c, suitDark, boot: hair, shade: hair)
    } else {
        drawCape(c, t: p.lt, speed: p.capeSpeed, color: cloak, edge: cloakEdge)
        drawLegs(c, Look(leg: suit), step: p.step)
        drawBoots(c, hair, step: p.step, rows: 2)
    }
    c.oy += p.breathe
    let raise = p.flying ? 0 : p.signature.map { Int((habitArc($0, hold: 0.7) * 7).rounded()) } ?? p.armRaise
    drawBody(c, Look(body: pale, shade: paleDark, arm: suit, eye: nil), armRight: raise)
    // The dark half of the face (all of it at the height of the eclipse).
    c.rect(dark > 0 ? 18 : 28, 26, dark > 0 ? 20 : 10, 8, night)
    if dark == 0 { c.rect(28, 26, 1, 8, nightEdge) }
    c.rect(22, 29, 2, 3, dark > 0 ? eyeHot : ink)
    if dark > 0 { glowDot(c, 23, 30.5, core: eyeHot, glow: eyeGlow, r: 0.5, glowR: 2) }
    c.rect(32, 29, 2, 3, eyeHot)
    glowDot(c, 33, 30.5, core: eyeHot, glow: eyeGlow, r: 0.5, glowR: 2.2, strength: 0.8)
    c.rect(24, 33, 4, 1, dark > 0 ? nightEdge : paleDark); c.rect(28, 33, 4, 1, nightEdge)
    c.rect(21, 28, 3, 1, dark > 0 ? nightEdge : paleDark); c.rect(31, 28, 4, 1, nightEdge)
    // Spiked black hair.
    c.pattern(17, 20, [
        "..H....H.....H....H...",
        "..HH..HHH...HHH..HH...",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHH..HHHHHHHH..HHHHH",
        "HH..............HH..HH",
    ], ["H": hair])
    // The high collar and the suit.
    c.pattern(15, 26, ["C......................C", "CC....................CC", "CCC..................CCC",
                       ".CCC................CCC.", "..CC................CC.."], ["C": cloakEdge])
    c.rect(18, 34, 20, 4, suit)
    c.rect(37, 34, 1, 4, suitDark)
    c.pattern(25, 34, ["KKKKKK", ".KKKK.", "..KK.."], ["K": hair])
    c.rect(18, 37, 20, 1, suitDark)
    // The Black Diamond in his hand.
    let hx = p.flying ? 42 : 40, hy = p.flying ? 30 : 31 - raise
    if p.flying { c.rect(38, 31, 4, 3, suit) }
    c.pattern(hx, hy, [".D.", "DdD", "DDD", ".D."], ["D": C(0x0C0814), "d": C(0x8A5AE8)])
    if p.zap != nil || raise > 2 {
        glowDot(c, Double(hx) + 1.5, Double(hy) + 1.5, core: clear, glow: C(0x6A2AD8), r: 0, glowR: 3.5, strength: 0.7)
    }
}
