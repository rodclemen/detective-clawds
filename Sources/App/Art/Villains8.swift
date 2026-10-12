import Foundation

// Villains: Shazam's foes, a cult leader, the JSA's undead and a few of the Legion of Doom's old guard. Clawd in
// costume again, except Mister Mind (a worm) and Monsieur Mallah (a gorilla), who are at least blocky ones.

let villains8: [Leader: Persona] = [
    .blackAdam: Persona(name: "Black Adam", weapon: .magic, motion: .fly, magic: Magic(core: C(0xFFF8D0), glow: C(0xFFD21E)),
                  headTop: 21, signature: 3.2, callout: "Shazam!",
                  draw: drawBlackAdam),
    .doctorSivana: Persona(name: "Doctor Sivana", weapon: .ranged, shot: .energy(core: C(0xF0FFF0), glow: C(0x6AE86A)),
                  muzzle: (51, 32), headTop: 22, signature: 3.0, callout: "Curse that Big Red Cheese!",
                  draw: drawDoctorSivana),
    .mrMind: Persona(name: "Mister Mind", weapon: .magic, magic: Magic(core: C(0xF0FFE0), glow: C(0xA8E83A), jagged: false),
                  canSit: false, pivot: (44.5, 33.5), headTop: 20, signature: 2.8,
                  draw: drawMrMind),
    .brotherBlood: Persona(name: "Brother Blood", weapon: .magic, magic: Magic(core: C(0xFFE0D0), glow: C(0xE81E1E), jagged: false),
                  headTop: 11, signature: 3.2, callout: "Hail Brother Blood!",
                  draw: drawBrotherBlood),
    .solomonGrundy: Persona(name: "Solomon Grundy", weapon: .melee, pivot: grundyShoulder, bulk: 5, headTop: 16, signature: 3.6,
                  callout: "Solomon Grundy, born on a Monday!",
                  draw: drawSolomonGrundy),
    .vandalSavage: Persona(name: "Vandal Savage", weapon: .melee, headTop: 20, signature: 3.0,
                  callout: "I have walked this earth for fifty thousand years.",
                  draw: drawVandalSavage),
    .felixFaust: Persona(name: "Felix Faust", weapon: .magic, magic: Magic(core: C(0xF0E0FF), glow: C(0x8A4AD8)),
                  headTop: 13, signature: 3.2, callout: "By the dark gods of old!",
                  draw: drawFelixFaust),
    .klarion: Persona(name: "Klarion", weapon: .magic, motion: .hover, magic: Magic(core: C(0xFFE0F0), glow: C(0xE84A8A), jagged: false),
                  headTop: 15, signature: 3.2, callout: "I'm bored!",
                  draw: drawKlarion),
    .monsieurMallah: Persona(name: "Monsieur Mallah", weapon: .ranged, shot: .bullet, muzzle: (56, 32), bulk: 2, headTop: 18,
                  signature: 3.0, callout: "Pour la Confrérie du Mal!",
                  draw: drawMonsieurMallah),
    .gentlemanGhost: Persona(name: "Gentleman Ghost", weapon: .ranged, motion: .hover, shot: .bullet, canSit: false,
                  muzzle: (52, 31), headTop: 13, signature: 3.4, callout: "Charmed, I'm sure.",
                  draw: drawGentlemanGhost),
    .blackMask: Persona(name: "Black Mask", weapon: .ranged, shot: .bullet, muzzle: (47, 32), headTop: 22, signature: 2.8,
                  callout: "Everybody wears a mask.",
                  draw: drawBlackMask),
]

// MARK: - Helpers

private let clear = C(0, 0)

/// A solid line `r` thick: staffs, horns, blades, straps.
private func stick(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from `h` along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// `a` washed towards `b` by `k` (0…1), keeping `a`'s opacity.
private func mix(_ a: Px, _ b: Px, _ k: Double) -> Px {
    let r: Double = Double(a.r) + (Double(b.r) - Double(a.r)) * k
    let g: Double = Double(a.g) + (Double(b.g) - Double(a.g)) * k
    let bl: Double = Double(a.b) + (Double(b.b) - Double(a.b)) * k
    return Px(r: UInt8(r), g: UInt8(g), b: UInt8(bl), a: a.a)
}

private func unpremultiplied(_ s: PixelCanvas, _ i: Int) -> Px {
    let a = s.buf[i + 3], m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a)
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, washed towards
/// `tint`'s colour by its amount, leaning forward one pixel every `lean` rows above the feet (0: upright), and cut off
/// below canvas row `keepAbove` (something sinking into the floor).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, tint: (Px, Double)? = nil, keepAbove: Int? = nil,
                   _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        if let cut = keepAbove, y > cut { break }
        let shift = lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
            var col = unpremultiplied(s, i)
            if let t = tint { col = mix(col, t.0, t.1) }
            c.px(x + shift, y, col.alpha(alpha))
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

/// A straight blade in the hand at `angle`: grip, guard, blade with a bright edge, and a smear for a fast swing.
private func drawBlade(_ c: PixelCanvas, angle: Double, trail: [Double], length: Double, blade: Px, edge: Px, grip: Px,
                       guardCol: Px, width: Double = 0.9) {
    let h = Sprite.hand
    for (i, a) in trail.enumerated() {
        let s = along(a, 3), e = along(a, 3 + length)
        c.glowLine(s.x, s.y, e.x, e.y, core: edge.alpha(0.5), glow: edge.alpha(0.5), coreR: 0.4, glowR: 1.5,
                   strength: 0.45 / Double(i + 1))
    }
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    stick(c, h.x - ux * 2.5, h.y - uy * 2.5, h.x + ux * 1.5, h.y + uy * 1.5, grip, 0.8)
    stick(c, h.x + ux * 2 - nx * 2.2, h.y + uy * 2 - ny * 2.2, h.x + ux * 2 + nx * 2.2, h.y + uy * 2 + ny * 2.2, guardCol, 0.6)
    stick(c, h.x + ux * 2.6, h.y + uy * 2.6, h.x + ux * (2.5 + length), h.y + uy * (2.5 + length), blade, width)
    stick(c, h.x + ux * 3 + nx * 0.4, h.y + uy * 3 + ny * 0.4, h.x + ux * (1.5 + length), h.y + uy * (1.5 + length), edge, 0.4)
}

/// Capital letters in a tiny 3×5 pixel font (only the ones the cast needs), the first one's top-left at (x, y).
private func drawWord(_ c: PixelCanvas, _ word: String, x: Int, y: Int, _ col: Px) {
    let glyphs: [Character: [String]] = [
        "S": ["###", "#..", "###", "..#", "###"],
        "H": ["#.#", "#.#", "###", "#.#", "#.#"],
        "A": ["###", "#.#", "###", "#.#", "#.#"],
        "Z": ["###", "..#", ".#.", "#..", "###"],
        "M": ["#.#", "###", "###", "#.#", "#.#"],
        "E": ["###", "#..", "##.", "#..", "###"],
        "!": [".#.", ".#.", ".#.", "...", ".#."],
    ]
    var cx = x
    for ch in word {
        if let g = glyphs[ch] { c.pattern(cx, y, g, ["#": col]) }
        cx += 4
    }
}

/// A small heart, its top-left at (x, y).
private func drawHeart(_ c: PixelCanvas, x: Int, y: Int, _ col: Px) {
    c.pattern(x, y, [".HH.HH.", "HHHHHHH", ".HHHHH.", "..HHH..", "...H..."], ["H": col])
    c.px(x + 1, y + 1, white.alpha(Double(col.a) / 255 * 0.7))
}

// MARK: - Black Adam

/// Black Adam: Clawd in the black suit with the gold lightning bolt on the chest, a gold sash, gold bracers and
/// boots, and black hair swept back to a widow's peak over a hard scowl. He flies fist first and throws gold
/// lightning. Signature: he raises a fist and shouts the word, SHAZAM goes up in gold and the magic lightning
/// strikes him, leaving him crackling.
private func drawBlackAdam(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1C1C24), suitDark = C(0x0E0E14), gold = C(0xF0C030), goldDark = C(0xB88A1E), goldLight = C(0xFFE68A)
    let hair = C(0x101014)
    var raise = p.armRaise
    var strike: Double?, charge = 0.0
    if let s = p.signature {
        raise = Int((habitArc(s, hold: 0.6) * 10).rounded())
        if s > 0.26 && s < 0.5 { strike = (s - 0.26) / 0.24 }
        if s > 0.3 { charge = s < 0.55 ? 1 : max(0, 1 - (s - 0.55) / 0.4) }
    }
    let flash = strike.map { $0 < 0.6 ? 0.75 * (1 - $0 / 0.6) : 0 } ?? 0
    layer(c, lean: p.flying ? 4 : 0, tint: flash > 0 ? (C(0xFFF8D8), flash) : nil) { c in
        let look = Look(body: clawdOrange, shade: clawdShade, leg: suit, arm: suit)
        drawLegs(c, look, step: p.step)
        drawBoots(c, gold, step: p.step, rows: 3)
        if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, p.step >= 0 && (lx == 19 || lx == 31) == (p.step == 0) ? 40 : 41, goldLight) } }
        c.oy += p.breathe
        drawBody(c, look, armRight: p.flying ? 0 : raise)
        // Hair: black, swept back, a sharp widow's peak.
        c.pattern(17, 21, [
            "......KKKKKKKKKK......",
            "...KKKKKKKKKKKKKKKK...",
            "..KKKKKKKkkKKKKKKKKK..",
            ".KKKKKKkkKKKKKKKKKKKK.",
            ".KKKKKKKKKKKKKKKKKKKK.",
            ".KKKKKKKKKKKKKKKKKKKK.",
            ".KK.....KKKKKK.....KK.",
            ".KK......KKKK......KK.",
            ".K..................K.",
        ], ["K": hair, "k": C(0x3A3A48)])
        c.px(21, 27, hair); c.rect(22, 28, 2, 1, hair)                   // the scowl
        c.rect(32, 28, 2, 1, hair); c.px(34, 27, hair)
        c.rect(25, 32, 6, 1, clawdShade)
        // The suit, the bolt and the sash.
        c.rect(18, 33, 20, 5, suit)
        c.rect(37, 33, 1, 5, suitDark)
        c.pattern(24, 33, [
            "....GGL",
            "...GGG.",
            "..GGGGG",
            "....GG.",
        ], ["G": gold, "L": goldLight])
        c.rect(18, 37, 20, 1, gold); c.rect(36, 37, 2, 1, goldDark)
        c.rect(15, 33, 3, 3, suit); c.rect(15, 35, 3, 1, gold)             // left fist, gold bracer
        if p.flying {
            // Fist first.
            c.rect(38, 31, 3, 3, suit); c.rect(41, 31, 1, 3, gold); c.rect(42, 31, 2, 3, suit)
            return
        }
        if raise > 0 { c.rect(38, 36 - raise, 3, raise, suit) }
        c.rect(38, 35 - raise, 3, 1, gold)
    }
    if p.flying {
        // Air torn past him, and a crackle of the old magic.
        let i = Int(p.t * 20)
        for k in 0..<3 {
            let y = 26 + k * 6 + Int(noise(i + k) * 3), x = 2 + Int(noise(i * 3 + k) * 6)
            c.rect(x, y, 5 + Int(noise(i + k * 7) * 4), 1, C(0xE8F0FF, 0.45))
        }
        if noise(i * 5) > 0.5 { c.px(12 + Int(noise(i + 9) * 4), 33 + Int(noise(i + 11) * 4), goldLight) }
    }
    guard let s = p.signature else { return }
    c.oy += p.breathe
    let fist = (x: 39.5, y: Double(32 - raise))
    if s > 0.14 && s < 0.78 {
        // The word, in gold.
        let a = min(1, (s - 0.14) / 0.08) * min(1, (0.78 - s) / 0.1)
        drawWord(c, "SHAZAM", x: 15, y: 6, (s > 0.26 && s < 0.4 ? C(0xFFF8D8) : gold).alpha(a))
    }
    if let f = strike {
        // The bolt from the sky onto his fist.
        let seed = Int(p.t * 24)
        var prev = (x: fist.x + (noise(seed) - 0.5) * 6, y: -2.0)
        let n = 5
        for k in 1...n {
            let y = -2 + (fist.y + 2) * Double(k) / Double(n)
            let next = (x: k == n ? fist.x : fist.x + (noise(seed + k) - 0.5) * 8, y: y)
            c.glowLine(prev.x, prev.y, next.x, next.y, core: C(0xFFFCE8), glow: C(0xFFD21E), coreR: 0.6, glowR: 2.2,
                       strength: f < 0.7 ? 1 : (1 - f) / 0.3)
            prev = next
        }
        c.glowLine(fist.x, fist.y, fist.x, fist.y, core: white, glow: C(0xFFD21E), coreR: 1.2, glowR: 4.5, strength: 1 - f * 0.6)
    }
    if charge > 0 {
        // Left crackling with it.
        let seed = Int(p.t * 18)
        for k in 0..<3 where noise(seed * 7 + k) < charge {
            let a = noise(seed + k * 13) * 2 * .pi, r0 = 10.0, r1 = 13.0 + noise(seed + k) * 3
            let cx = 28.0, cy = 31.0
            c.glowLine(cx + cos(a) * r0, cy + sin(a) * r0 * 0.8, cx + cos(a + 0.3) * r1, cy + sin(a + 0.3) * r1 * 0.8,
                       core: goldLight, glow: C(0xFFD21E), coreR: 0.4, glowR: 1.3, strength: charge)
        }
    }
}

// MARK: - Doctor Sivana

/// Doctor Sivana: a small, bald Clawd with jug ears and thick round glasses that magnify his eyes, in a white lab
/// coat over a green tie, holding a finned ray gun that fires green. Signature: he pockets the ray gun, rubs his
/// hands together, his glasses flash and he cackles.
private func drawDoctorSivana(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xE8ECEE), coatShade = C(0xB4BCC4), trousers = C(0x3A3644), frame = C(0x1E1E24), lens = C(0xD8ECF4)
    let k = p.signature.map { $0 > 0.08 && $0 < 0.92 } ?? false
    let s = p.signature ?? 0
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, ink, step: p.step, rows: 1)
    c.oy += p.breathe
    // The coat's skirts over his thighs.
    if seatedPose {
        c.rect(17, 38, 22, 1, coat)
    } else {
        c.rect(17, 38, 22, 3, coat); c.rect(17, 40, 22, 1, coatShade); c.rect(27, 38, 1, 3, coatShade)
        c.rect(38, 38, 1, 3, coatShade)
    }
    // The bald dome and the ears.
    c.pattern(18, 22, [
        "......OOOOOOOO......",
        "...OOOOOOOOOOOOOO...",
        ".OOOOOOOOOOOOOOOOOO.",
        "OOOOOOOOOOOOOOOOOOOO",
    ], ["O": clawdOrange])
    c.rect(37, 24, 1, 2, clawdShade)
    c.rect(16, 28, 2, 4, clawdOrange); c.px(16, 29, clawdShade); c.px(16, 30, clawdShade)
    c.rect(38, 28, 2, 4, clawdOrange); c.px(39, 29, clawdShade); c.px(39, 30, clawdShade)
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: k ? clear : coat, eye: nil))
    c.rect(22, 23, 4, 1, C(0xF0A080)); c.rect(21, 24, 2, 1, C(0xF0A080))   // the shine on his head
    c.rect(24, 26, 8, 1, clawdShade)                                     // a furrowed brow
    // The glasses: thick frames, magnified eyes.
    c.pattern(20, 28, [
        ".FFFF......FFFF.",
        "FLLLLFFFFFFLLLLF",
        "FLKKLF....FLKKLF",
        "FLKKLF....FLKKLF",
        ".FFFF......FFFF.",
    ], ["F": frame, "L": lens, "K": ink])
    c.rect(18, 29, 2, 1, frame); c.rect(36, 29, 2, 1, frame)
    // A glint crosses the lenses (the whole time he's cackling).
    let glint = k ? Int(s * 30) % 6 : Int(p.lt * 0.7 * 6) % 40
    if glint < 4 {
        for lx in [21, 31] { c.px(lx + glint, 29, white); if glint > 0 { c.px(lx + glint - 1, 30, white) } }
    }
    // The mouth: a mean little smirk, or wide open cackling.
    let laughing = k && Int(s * 24) % 2 == 0
    if laughing {
        c.rect(24, 33, 8, 2, C(0x3A0E10)); c.rect(25, 33, 6, 1, C(0xF0E8D8))
    } else {
        c.rect(24, 33, 7, 1, ink); c.px(31, 32, ink)
    }
    // The coat, lapels open on a shirt and green tie.
    c.rect(18, 35, 20, 3, coat)
    c.rect(37, 35, 1, 3, coatShade)
    c.pattern(24, 35, ["cWTTWc", ".cTTc.", "..cc.."], ["c": coatShade, "W": C(0xF8F4EA), "T": C(0x2A7A3A)])
    c.rect(15, 33, 3, 3, coat)
    if k {
        // Rubbing his hands together.
        let j = Int(s * 26) % 2
        c.rect(15, 33, 3, 3, clear)
        c.rect(22, 34 + j, 4, 2, coat); c.rect(25, 34 + j, 2, 2, clawdOrange)
        c.rect(30, 35 - j, 4, 2, coat); c.rect(29, 35 - j, 2, 2, clawdOrange)
        for n in 0..<2 {
            let f = frac(s * 2.2 + Double(n) * 0.5)
            guard f < 0.8 || s < 0.85 else { continue }
            let y = 18 - Int(f * 8), x = 38 + n * 5 + Int(sin(f * 9) * 1.5)
            drawWord(c, "HEH", x: x, y: y, C(0xF8F0D0, 1 - f * 0.8))
        }
        return
    }
    c.oy += p.gunY
    drawRayGun(c, x: 39, y: 30)
}

/// Sivana's ray gun, its top-left at (x, y): a fat silver barrel with red rings, fins on top and a green tip.
private func drawRayGun(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "...d.d.d....",
        ".MMMMMMMMMMg",
        ".MLMLMMMLMgG",
        "..KKm.......",
        "..KK........",
    ], ["M": C(0xA8B0BC), "L": C(0xC83A2A), "d": C(0x5A606C), "m": C(0x6A707C), "K": C(0x2A2A30),
        "g": C(0x3AB84A), "G": C(0xB8FFB0)])
    c.rect(x - 1, y + 3, 3, 2, clawdOrange)
}

// MARK: - Mister Mind

/// Mister Mind: a little green worm (a blocky one) inching along on his belly, his big head in round spectacles, and
/// the radio talk box he speaks through hung round his neck; his mind-control waves come out of its speaker. Signature:
/// he rears up tall and broadcasts, sound rings booming out of the talk box.
private func drawMrMind(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x84CC3E), dark = C(0x58922A), belly = C(0xD0EC94), frame = C(0x22222A), box = C(0x7A808C)
    var hump = p.step == 0 ? 2 : 0
    var lift = p.armRaise
    var boom: Double?
    if let s = p.signature {
        let k = habitArc(s, hold: 0.6)
        lift = Int((k * 6).rounded())
        hump = 0
        if s > 0.25 && s < 0.85 { boom = (s - 0.25) / 0.6 }
    }
    if p.walking { hump = Int((2 + 2 * sin(p.t * 8)).rounded()) }
    // The tail: blocky segments on the floor, fatter towards the head; walking arches the middle.
    let segs: [(x: Int, w: Int, h: Int)] = [(11, 4, 3), (15, 4, 4), (19, 4, 5), (23, 4, 5), (27, 5, 6)]
    for (i, sg) in segs.enumerated() {
        let up = Int((Double(hump) * sin(Double(i + 1) / 5 * .pi)).rounded())
        let top = 43 - sg.h - up
        c.rect(sg.x, top, sg.w, sg.h, green)
        c.rect(sg.x, top + sg.h - 1, sg.w, 1, belly)
        c.rect(sg.x + sg.w - 1, top, 1, sg.h - 1, dark)
        if up > 0 { c.rect(sg.x, top + sg.h, sg.w, up, green.alpha(0)) }
    }
    c.oy += p.breathe
    // The neck: a column of segments rising off the floor.
    let neckTop = 30 - lift
    c.rect(31, neckTop, 7, 43 - neckTop, green)
    c.rect(36, neckTop, 2, 43 - neckTop, belly)
    for y in stride(from: 42, to: neckTop, by: -3) { c.rect(31, y, 5, 1, dark) }
    // The head: big and blocky, with a little Clawd face behind round spectacles.
    let hy = 19 - lift
    c.pattern(27, hy, [
        "..GGGGGGGGGGG..",
        ".GGGGGGGGGGGGG.",
        "GGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGd",
        ".GGGGGGGGGGGGd.",
        "..ddddddddddd..",
    ], ["G": green, "d": dark])
    c.rect(29, hy + 1, 3, 1, C(0xB8E880))
    c.pattern(28, hy + 3, [
        ".FFFF.FFFF.",
        "FLKKLFLKKLF",
        "FLKKLFLKKLF",
        "FLLLLFLLLLF",
        ".FFFF.FFFF.",
    ], ["F": frame, "L": C(0xE8F4F8), "K": ink])
    c.rect(39, hy + 4, 2, 1, frame)                                    // the arm of his specs
    if boom != nil {
        c.rect(32, hy + 8, 5, 2, C(0x2A3A10))                          // mouth open, talking
    } else {
        c.rect(32, hy + 8, 4, 1, dark); c.px(36, hy + 7, dark)
    }
    // The talk box on its strap.
    let by = 31 - lift
    stick(c, 37.5, Double(hy) + 10, 39.5, Double(by), C(0x3A2A1E), 0.4)
    c.rect(38, by, 6, 5, box)
    c.rect(38, by + 4, 6, 1, C(0x4E545E))
    c.rect(43, by, 1, 5, C(0x4E545E))
    for yy in [by + 1, by + 3] { c.px(39, yy, ink); c.px(41, yy, ink) }
    c.px(42, by + 1, C(0xFF4A3A))
    if let f = boom {
        // Sound rings booming out.
        for n in 0..<3 {
            let g = frac(f * 3 + Double(n) / 3)
            let r = 2 + g * 12, cx = 44.0, cy = Double(by) + 2.5
            for a in stride(from: -50.0, through: 50.0, by: 12.5) {
                let rr = a * .pi / 180
                c.px(Int(cx + cos(rr) * r), Int(cy + sin(rr) * r), C(0xD8FF9A, 0.9 * (1 - g)))
            }
        }
    }
}

// MARK: - Brother Blood

/// Brother Blood: the cult leader in red robes with a white yoke and hem, a red hood round his face and the great
/// white skull headdress on top, a red cape behind; he casts red. Signature: both hands go up, a blood-red ritual
/// circle lights under him, his eyes burn red and droplets rise.
private func drawBrotherBlood(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB81E24), redDark = C(0x7A1018), redEdge = C(0x4A0A0E), robeWhite = C(0xF2EEE6), whiteShade = C(0xC8C0B4)
    let bone = C(0xEEE6D2), boneDark = C(0xB0A68E)
    let k = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    if k > 0 {
        // The ritual circle, behind him.
        let seed = Int(p.t * 12)
        for i in 0..<28 {
            let a = Double(i) / 28 * 2 * .pi + p.t * 0.6
            let x = 28 + cos(a) * 19 * k, y = 42.5 + sin(a) * 2.5 * k
            c.glowLine(x, y, x, y, core: C(0xFF6A5A, k), glow: C(0xE81E1E, k), coreR: 0.4, glowR: 1.4,
                       strength: 0.7 + 0.3 * noise(seed + i))
        }
    }
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: redDark, edge: redEdge)
    drawLegs(c, Look(leg: C(0x2A1A1C)), step: p.step)
    c.oy += p.breathe
    // The robe's skirt, white-hemmed.
    if seatedPose {
        c.rect(17, 38, 22, 2, red); c.rect(17, 39, 22, 1, robeWhite)
    } else {
        c.rect(17, 38, 22, 4, red); c.rect(17, 41, 22, 1, robeWhite); c.rect(26, 38, 4, 3, robeWhite)
        c.rect(38, 38, 1, 4, redDark)
    }
    let up = k > 0.15
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: up ? clear : red, eye: k > 0.4 ? C(0xFF2A2A) : ink),
             armRight: p.armRaise)
    if k > 0.4 {
        for x in [22, 32] { c.glowLine(Double(x) + 1, 30.5, Double(x) + 1, 30.5, core: C(0xFFB0A0), glow: C(0xFF2A2A), coreR: 0.6, glowR: 2.2, strength: k) }
    }
    c.rect(25, 33, 6, 1, C(0x7A2A1E))
    // The hood, then the skull riding on top of it.
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
        "BBB....................BBB",
    ], ["B": red, "b": redDark])
    c.pattern(20, 10, [
        "....BBBBBBBB....",
        "..BBBBBBBBBBBB..",
        ".BBBBBBBBBBBBBBd",
        "BBBBBBBBBBBBBBBd",
        "BBKKKBBBBBBKKKBd",
        "BKKKKKBBBBKKKKKd",
        "BBKKKBBKKBBKKKBd",
        ".BBBBBBKKBBBBBd.",
        "..BKBKBKBKBKBd..",
        "...dddddddddd...",
    ], ["B": bone, "d": boneDark, "K": ink])
    if k > 0.4 { c.px(23, 15, C(0xFF2A2A)); c.px(32, 15, C(0xFF2A2A)) }
    // The robe: red, a white yoke and a white panel down the front.
    c.rect(18, 34, 20, 4, red)
    c.rect(18, 34, 20, 1, robeWhite); c.rect(18, 35, 20, 1, whiteShade)
    c.rect(26, 34, 4, 4, robeWhite); c.rect(27, 36, 2, 1, red)
    c.rect(37, 34, 1, 4, redDark)
    if up {
        // Both arms flung up, outside the hood.
        let reach = 4 + k * 6
        for side in [-1.0, 1.0] {
            let sx = side < 0 ? 16.5 : 39.5, ex = sx + side * 4, ey = 34 - reach
            stick(c, sx, 34.5, ex, ey, red, 1.3)
            stick(c, ex - side * 0.3, ey + 1, ex, ey, robeWhite, 1.2)
            c.rect(Int(ex) - 1, Int(ey) - 2, 3, 2, clawdOrange)
        }
    }
    if k > 0.3 {
        // Droplets rising round him.
        for n in 0..<5 {
            let f = frac(p.t * 0.9 + Double(n) / 5)
            let x = 12 + n * 9 + Int(sin(f * 6 + Double(n)) * 2), y = 42 - Int(f * 22)
            c.px(x, y, C(0xD81E24, k * (1 - f))); c.px(x, y - 1, C(0xFF6A5A, k * (1 - f) * 0.6))
        }
    }
}

// MARK: - Solomon Grundy

private let grundyShoulder = (x: 40.5, y: 27.5)

/// Solomon Grundy: a huge, chalk-white zombie Clawd with stringy black hair, sunken eyes, a stitched mouth and a
/// tattered old suit over a torn shirt; one big arm hangs, the other swings a fist from the shoulder. Signature: he
/// sinks into the swamp and claws his way back out of it, fist first.
private func drawSolomonGrundy(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { grundy(c, p, reach: false); return }
    var sink = 0.0
    if s < 0.42 { sink = 0.5 - 0.5 * cos(s / 0.42 * .pi) }
    else if s < 0.55 { sink = 1 }
    else if s < 0.92 { sink = 0.5 + 0.5 * cos((s - 0.55) / 0.37 * .pi) }
    let mud = habitArc(s, hold: 0.8)
    let ground = 43 + c.oy + c.baseY
    let mudCol = C(0x3A4A2A), mudDark = C(0x26321C), mudLight = C(0x5A6A3A)
    layer(c, keepAbove: ground) { c in
        c.oy += Int((sink * 34).rounded())
        grundy(c, p, reach: s > 0.5)
    }
    // The swamp, opening round him.
    let w = Int((mud * 18).rounded())
    if w > 0 {
        c.rect(28 - w, 42, w * 2 + 1, 2, mudCol)
        c.rect(28 - w + 2, 41, max(1, w * 2 - 3), 1, mudCol)
        c.rect(28 - w, 43, w * 2 + 1, 1, mudDark)
        c.rect(28 - w + 4, 41, max(1, w - 3), 1, mudLight)
        let seed = Int(p.t * 6)
        for n in 0..<3 where mud > 0.6 {
            let f = frac(p.t * 1.4 + Double(n) / 3)
            let x = 28 + Int((noise(seed + n * 11) - 0.5) * Double(w) * 1.6)
            c.px(x, 40 - Int(f * 2), mudLight.alpha(1 - f))
        }
    }
}

private func grundy(_ c: PixelCanvas, _ p: Pose, reach: Bool) {
    let skin = C(0xDCE0D4), shade = C(0xB0B6A8), deep = C(0x7E8676), hair = C(0x141418)
    let jacket = C(0x4E463C), jacketDark = C(0x342E26), shirt = C(0xBEB8A4), trousers = C(0x3A3630)
    // Thick legs in torn trousers, bare grey feet.
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, trousers); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        let bottom = lifted ? 42 : 43
        c.rect(lx, 36, 3, bottom - 35, trousers)
        c.rect(lx, bottom - 1, 3, 2, shade)
        c.px(lx + (i % 2), bottom - 2, skin)
    }
    c.oy += p.breathe
    // The left arm hangs in its ragged sleeve.
    c.rect(10, 25, 5, 9, jacket); c.rect(10, 25, 1, 9, jacketDark)
    c.px(10, 34, jacket); c.px(13, 34, jacket)
    c.rect(9, 34, 6, 5, skin); c.rect(9, 36, 6, 1, shade); c.rect(9, 38, 6, 1, deep)
    // The big body.
    c.rect(15, 22, 26, 16, skin)
    c.rect(40, 22, 1, 16, shade)
    c.pattern(14, 16, [
        ".....K..KK.....K.KK.......",
        "...KKKKKKKKKKKKKKKKKKK....",
        "..KKKKKKKKKKKKKKKKKKKKKK..",
        ".KKKKKKKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKKKKKKK",
        ".KKK.KK.KKKK.KK..KKK.K.KKK",
        ".KK...K..K.K..K...K.....KK",
        ".KK.......K...........K.KK",
        ".K........................",
        ".K........................",
    ], ["K": hair])
    // The face: a heavy brow, sunken eyes, a stitched scar and the sewn-up mouth.
    c.pattern(19, 24, [
        "ddd.............ddd",
        "dddd...........dddd",
        "ssKKs.........sKKs.",
        "ssKKs.........sKKs.",
        ".sKKs.........sKK..",
        "..ss...........ss..",
    ], ["d": deep, "s": shade, "K": ink])
    c.rect(26, 22, 1, 4, deep)
    for y in [22, 24] { c.px(25, y, deep); c.px(27, y, deep) }
    c.rect(23, 31, 10, 1, C(0x3A3A36))
    for x in [24, 26, 28, 30, 32] { c.rect(x, 30, 1, 3, deep) }
    // The tattered suit: an open jacket over a torn shirt.
    c.rect(15, 33, 26, 5, jacket)
    c.rect(15, 37, 26, 1, jacketDark)
    c.pattern(23, 33, [
        "jSSSSSSSSj",
        ".jSSSSSSj.",
        "..SSsSSS..",
        "..SSSSsS..",
        "...S.SS...",
    ], ["S": shirt, "s": shade, "j": jacketDark])
    c.rect(40, 33, 1, 5, jacketDark)
    if !seatedPose { for x in [15, 18, 22, 33, 37, 39] { c.px(x, 38, jacket) } }
    // The right arm.
    let angle = reach ? -95 : (p.melee ?? 80)
    for (i, ta) in p.trail.enumerated() { drawGrundyArm(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
    drawGrundyArm(c, angle: angle)
}

/// Grundy's right arm, swung from the shoulder: a ragged sleeve and a big pale fist.
private func drawGrundyArm(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: grundyShoulder, angle: angle, alpha: alpha) { s in
        let skin = C(0xDCE0D4), shade = C(0xB0B6A8), jacket = C(0x4E463C), jacketDark = C(0x342E26)
        s.rect(18, 18, 8, 5, jacket)
        s.rect(18, 22, 8, 1, jacketDark)
        s.px(25, 17, jacket); s.px(24, 23, jacket)
        s.rect(26, 17, 7, 7, skin)
        s.rect(32, 18, 1, 5, shade); s.rect(26, 23, 7, 1, shade)
        s.px(29, 18, shade); s.px(29, 20, shade); s.px(29, 22, shade)
    }
}

// MARK: - Vandal Savage

/// Vandal Savage: the immortal caveman turned conqueror, a thick black mane and full black beard round Clawd's face,
/// a fur tunic with a leather belt, fur boots and a broad bronze sword (in its scabbard at his hip when put away).
/// Signature: he holds up a shard of the meteor that made him immortal, and it glows; so do his eyes.
private func drawVandalSavage(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x18161C), hairSheen = C(0x34303C), fur = C(0x8A6A44), furDark = C(0x5E462C), furLight = C(0xB8946A)
    let leather = C(0x4A3020), trousers = C(0x2E2A26), bronze = C(0xC8984A), bronzeLight = C(0xF4D898), gold = C(0xE8B830)
    let k = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let showSword = p.melee != nil
    if !showSword {
        // The scabbard at his left hip, angled back.
        stick(c, 17, 37.5, 7, 41.5, leather, 1.0)
        stick(c, 7, 41.5, 8, 41.1, C(0x2A1A10), 1.0)
    }
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, fur, step: p.step, rows: 3)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, p.step >= 0 && (lx == 19 || lx == 31) == (p.step == 0) ? 40 : 41, furLight) } }
    c.oy += p.breathe
    let raise = Int((k * 11).rounded())
    let eye = k > 0.5 ? C(0xC8FF6A) : ink
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: clawdOrange, eye: eye), armRight: raise)
    if raise > 0 { c.rect(38, 36 - raise, 3, raise, clawdOrange) }
    // The mane.
    c.pattern(16, 20, [
        ".....KKKKKKKKKKKK.....",
        "...KKKKKKKKKKKKKKKK...",
        "..KKKKKKKkKKKKKKKKKK..",
        ".KKKKKKkkKKKKKKKKKKKK.",
        "KKKKKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKKKK",
        "KKK..K.K.KK.K.K..K.KKK",
        "KKK................KKK",
        "KK..................KK",
        "KK..................KK",
        "KK..................K.",
    ], ["K": hair, "k": hairSheen])
    c.rect(21, 28, 4, 1, hair); c.rect(31, 28, 4, 1, hair)            // heavy brows
    // The fur tunic, ragged at the hem, and the belt.
    c.rect(18, 34, 20, 4, fur)
    for x in [20, 25, 29, 34] { c.px(x, 35, furLight); c.px(x + 1, 36, furDark) }
    c.rect(37, 34, 1, 4, furDark)
    if !seatedPose { for x in [18, 21, 24, 27, 30, 33, 36] { c.px(x, 38, fur); c.px(x + 1, 38, furDark) } }
    c.rect(18, 37, 20, 1, leather); c.rect(27, 37, 2, 1, gold)
    if !showSword { stick(c, 17, 37.5, 19.5, 34, leather, 0.6); stick(c, 16.5, 35, 19.5, 37, gold, 0.5); c.px(19, 33, gold) }
    // The beard, over everything below the eyes.
    c.pattern(18, 30, [
        "KK................KK",
        "KKK..............KKK",
        "KKKK..KKKKKKK..KKKK.",
        "KKKKKKKK...KKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKK.",
        "..KKKKKKKKKKKKKKKK..",
        "....KKKKKKkKKKKK....",
        "......KKKKKKKK......",
    ], ["K": hair, "k": hairSheen])
    c.px(27, 33, C(0x5A1E14)); c.px(28, 33, C(0x5A1E14))
    if k > 0.05 {
        // The meteor shard, held high and glowing.
        let hy = 33 - raise
        let pulse = 0.75 + 0.25 * sin(p.t * 8)
        c.glowLine(40, Double(hy) - 2, 40, Double(hy) - 2, core: clear, glow: C(0x9AFF4A), coreR: 0, glowR: 6 * k, strength: 0.55 * pulse)
        c.pattern(38, hy - 4, [".RRR", "RRgR", "RgRR", ".RR."], ["R": C(0x3A3A34), "g": C(0xC8FF6A)])
        if k > 0.5 {
            for n in 0..<3 {
                let f = frac(p.t * 1.2 + Double(n) / 3)
                c.px(39 + n, hy - 5 - Int(f * 6), C(0xC8FF6A, 1 - f))
            }
        }
        return
    }
    if let a = p.melee {
        drawBlade(c, angle: a, trail: p.trail, length: 15, blade: bronze, edge: bronzeLight, grip: leather, guardCol: gold, width: 1.1)
    }
}

// MARK: - Felix Faust

/// Felix Faust: the sorcerer in a purple robe trimmed in gold, a long grey beard, and a bronze helm with two curling
/// horns; a spellbook under his left arm, purple lightning from his right hand. Signature: the book floats up in
/// front of him and falls open, its pages riffle and purple runes rise off them.
private func drawFelixFaust(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x4E2A80), robeDark = C(0x341A5C), gold = C(0xE0B040)
    let beard = C(0xCCCCD2), beardDark = C(0x9A9AA4), helm = C(0xB8863A), helmLight = C(0xE8C070), helmDark = C(0x7A5420)
    let horn = C(0xE8E0C8), hornDark = C(0xB0A88E)
    let sig = p.signature
    let k = sig.map { habitArc($0, hold: 0.55) } ?? 0
    drawLegs(c, Look(leg: robeDark), step: p.step)
    drawBoots(c, C(0x1A1420), step: p.step, rows: 1)
    c.oy += p.breathe
    if seatedPose {
        c.rect(16, 38, 24, 2, robe); c.rect(16, 39, 24, 1, gold)
    } else {
        c.rect(17, 38, 22, 4, robe); c.rect(17, 41, 22, 1, gold); c.rect(38, 38, 1, 4, robeDark)
        c.rect(27, 38, 2, 3, gold)
    }
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: robe, eye: k > 0.4 ? C(0xC89AFF) : ink),
             armRight: p.armRaise)
    // The horns, then the helm over their roots.
    let horns: [[(Double, Double)]] = [
        [(20, 23), (15, 20), (13, 16), (14, 12)],
        [(36, 23), (41, 20), (43, 16), (42, 12)],
    ]
    for h in horns {
        let widths: [Double] = [1.4, 1.1, 0.7]
        for i in 0..<(h.count - 1) { stick(c, h[i].0, h[i].1, h[i + 1].0, h[i + 1].1, horn, widths[i]) }
        stick(c, h[0].0, h[0].1 + 1, h[1].0, h[1].1 + 1, hornDark, 0.5)
    }
    c.pattern(17, 19, [
        "......HHHHHHHHHH......",
        "....HHLLHHHHHHHHHH....",
        "...HHLLHHHHHHHHHHHH...",
        "..HHLHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        ".DDDDDDDDDDDDDDDDDDDD.",
        ".HHGHHHGHHHHHHGHHHGHH.",
        ".DD................DD.",
        ".DD................DD.",
    ], ["H": helm, "L": helmLight, "D": helmDark, "G": gold])
    c.rect(27, 20, 2, 5, helmDark)                                     // the crest ridge
    c.rect(27, 20, 1, 4, helmLight)
    c.rect(21, 27, 4, 1, beardDark); c.rect(31, 27, 4, 1, beardDark)   // bushy grey brows
    // The robe body.
    c.rect(18, 34, 20, 4, robe)
    c.rect(37, 34, 1, 4, robeDark)
    c.rect(18, 37, 20, 1, gold)
    // The beard, long and pointed, down over the robe.
    c.pattern(19, 31, [
        "B.................",
        "BBB..BBBBBBB...BB.",
        "BBBBBBBBBBBBBBBBB.",
        ".BBBBBbBBBBBbBBBB.",
        "..BBBBBBBBBBBBBB..",
        "...BBBBbBBBBBBB...",
        ".....BBBBBbBB.....",
        "......BBBBBB......",
        ".......BBBB.......",
        "........BB........",
    ], ["B": beard, "b": beardDark])
    c.rect(26, 32, 3, 1, C(0x6A2A1E))
    // The spellbook: under his left arm, or floating open in front of him.
    if k < 0.05 {
        c.pattern(11, 32, ["bbbbbb", "bggggb", "bgbbgb", "bggggb", "bbbbbb", "pppppp"],
                  ["b": C(0x5A2A1E), "g": gold, "p": C(0xE8DCC0)])
        c.rect(15, 33, 3, 3, robe)
        return
    }
    let bx = 40, by = 30 - Int((k * 8).rounded())
    c.glowLine(Double(bx) + 4, Double(by) + 2, Double(bx) + 4, Double(by) + 2, core: clear, glow: C(0x8A4AD8), coreR: 0, glowR: 7 * k,
               strength: 0.4)
    if k > 0.6 {
        let flip = Int((sig ?? 0) * 20) % 3
        c.pattern(bx, by, ["bppp.ppPb", "bpLp.pLpb", "bppp.pppb", "bpLp.pLpb", "bbbbbbbbb"],
                  ["b": C(0x5A2A1E), "p": C(0xF0E6CC), "L": C(0x8A6AB8), "P": C(0xF0E6CC)])
        c.rect(bx + 4, by, 1, 4, C(0x5A2A1E))
        if flip == 0 { c.rect(bx + 5, by - 2, 2, 4, C(0xF8F0DC)) } else if flip == 1 { c.rect(bx + 4, by - 3, 1, 4, C(0xF8F0DC)) }
        for n in 0..<4 {
            let f = frac(p.t * 0.8 + Double(n) / 4)
            let x = bx + 1 + n * 2 + Int(sin(f * 7 + Double(n)) * 2), y = by - 2 - Int(f * 13)
            let col = (n % 2 == 0 ? C(0xC89AFF) : C(0xF0E0FF)).alpha(1 - f)
            c.pattern(x, y, n % 2 == 0 ? ["R.", ".R", "R."] : [".R", "RR", "R."], ["R": col])
        }
    } else {
        c.pattern(bx, by + 1, ["bbbbbb", "bggggb", "bgbbgb", "bggggb", "bbbbbb"], ["b": C(0x5A2A1E), "g": gold])
    }
}

// MARK: - Klarion

/// Klarion the Witch Boy: a pale-faced Clawd with red eyes, black hair swept up into two horns, a black Puritan coat
/// with a broad white collar and buckled shoes; he hovers, with his familiar Teekl the cat on his shoulder, and casts
/// in pink. Signature: Teekl leaps down in front of him, arches up hissing with glowing eyes, then hops back.
private func drawKlarion(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x1C1C26), coatLight = C(0x34344A), collar = C(0xF2F0EA), collarShade = C(0xC8C4BC), hair = C(0x101016)
    let skin = C(0xE8A884), skinShade = C(0xC88A6A), gold = C(0xE8C040)
    drawLegs(c, Look(leg: C(0x2A2A34)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 1, 3, 2, ink); c.px(lx + 1, bottom - 1, gold)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinShade, arm: coat, eye: C(0xD81E30)), armRight: p.armRaise)
    c.px(22, 29, C(0xFF8A8A)); c.px(32, 29, C(0xFF8A8A))
    // A wicked little grin.
    let grin = p.signature.map { $0 > 0.2 && $0 < 0.8 } ?? false
    if grin {
        c.rect(24, 33, 8, 1, ink); c.px(23, 32, ink); c.px(32, 32, ink); c.rect(25, 33, 6, 1, ink)
        c.rect(26, 34, 4, 1, C(0x5A1E24))
    } else {
        c.rect(25, 33, 5, 1, ink); c.px(30, 32, ink)
    }
    // Hair: black, two horns swept up.
    let horns: [[(Double, Double)]] = [[(21, 22), (17, 19), (15, 15), (16, 12)], [(35, 22), (39, 19), (41, 15), (40, 12)]]
    for h in horns {
        let widths: [Double] = [1.6, 1.1, 0.6]
        for n in 0..<(h.count - 1) { stick(c, h[n].0, h[n].1, h[n + 1].0, h[n + 1].1, hair, widths[n]) }
    }
    c.pattern(16, 20, [
        "......KKKKKKKKKKKK......",
        "....KKKKKKKKKKKKKKKK....",
        "...KKKKkKKKKKKKKKKKKK...",
        "..KKKKkKKKKKKKKKKKKKKK..",
        "..KKKKKKKKKKKKKKKKKKKK..",
        "..KKKK.KKKKK.KKKKK.KKK..",
        "..KKK...K.K....K....KK..",
        "..KK................K...",
        "..K.....................",
    ], ["K": hair, "k": C(0x3A3A50)])
    // The coat and the broad white collar.
    c.rect(18, 34, 20, 4, coat)
    c.rect(37, 34, 1, 4, C(0x0E0E14))
    c.rect(18, 37, 20, 1, coatLight)
    c.pattern(19, 34, ["CCCCCCCCCCCCCCCCCC", ".cCCCCCCCCCCCCCCc.", "...cCCCc..cCCCc..."], ["C": collar, "c": collarShade])
    c.rect(15, 33, 3, 3, coat)

    // Teekl: on his shoulder, or down in front of him for the signature.
    var cat = (x: 7, y: 25, arch: false, glow: false)
    if let s = p.signature, s > 0.05, s < 0.95 {
        if s < 0.2 {
            let f = (s - 0.05) / 0.15
            cat = (7 + Int(f * 37), 25 + Int(f * 12) - Int(sin(f * .pi) * 10), false, false)
        } else if s < 0.78 {
            cat = (44, 37, true, s > 0.3 && s < 0.7)
        } else {
            let f = (s - 0.78) / 0.17
            cat = (44 - Int(f * 37), 37 - Int(f * 12) - Int(sin(f * .pi) * 10), false, false)
        }
    }
    drawTeekl(c, x: cat.x, y: cat.y, arch: cat.arch, glow: cat.glow, t: p.t)
}

/// Teekl the cat sitting facing right, its top-left at (x, y) (10×8); `arch`: back up and fur on end, hissing.
private func drawTeekl(_ c: PixelCanvas, x: Int, y: Int, arch: Bool, glow: Bool, t: Double) {
    let fur = C(0xF0A848), stripe = C(0xB8681E), eye = glow ? C(0xFF3A3A) : C(0x4AE04A)
    if arch {
        c.pattern(x - 2, y - 2, [
            "...TTTT.....T.T",
            "..TTsTTTT...TTT",
            "TTTTTTTsTT.TTeT",
            "T.TTsTTTTTTTTTn",
            "..TT.......TTT.",
            "..TT.......T.T.",
        ], ["T": fur, "s": stripe, "e": eye, "n": C(0xE87A8A)])
        if glow {
            c.glowLine(Double(x) + 11.5, Double(y) + 0.5, Double(x) + 11.5, Double(y) + 0.5, core: eye, glow: C(0xFF3A3A), coreR: 0.3, glowR: 1.6)
            if Int(t * 10) % 2 == 0 { c.px(x + 14, y + 2, white.alpha(0.8)); c.px(x + 15, y + 1, white.alpha(0.6)) }
        }
        return
    }
    c.pattern(x, y, [
        "......T.T.",
        "......TTTT",
        "T.....TeTT",
        "T....TTTTn",
        "T...TTsTT.",
        ".T.TTsTTT.",
        "..TTTsTTT.",
        "..TT.T.T..",
    ], ["T": fur, "s": stripe, "e": eye, "n": C(0xE87A8A)])
}

// MARK: - Monsieur Mallah

/// Monsieur Mallah: a big, blocky gorilla in a red beret with an ammunition bandolier across his chest, long arms
/// and a drum-fed machine gun at his hip. Signature: he sets the gun aside and holds up his beloved Brain, a pink
/// brain in a glass dome on a little robot box, and a heart floats up.
private func drawMonsieurMallah(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x3A302A), furLight = C(0x5A4A3E), furDark = C(0x241E1A), face = C(0xA8968A), faceDark = C(0x6A5C52)
    let beret = C(0xC8202A), beretDark = C(0x8A121A), strap = C(0x6A4A2A), brass = C(0xE0B848)
    let s = p.signature
    let holding = s.map { $0 > 0.08 && $0 < 0.92 } ?? false
    // Short, thick legs.
    for (i, lx) in [17, 22, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, fur); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 37, 3, lifted ? 5 : 6, fur)
        c.rect(lx, lifted ? 41 : 42, 3, 1, furDark)
    }
    c.oy += p.breathe
    // The long left arm, knuckles nearly on the floor.
    c.rect(10, 26, 6, 13, fur); c.rect(10, 26, 1, 13, furDark)
    c.rect(9, 37, 7, 3, faceDark); c.rect(9, 39, 7, 1, furDark)
    // The body: broad, furry, a lighter chest.
    c.rect(15, 23, 26, 15, fur)
    c.rect(40, 23, 1, 15, furDark)
    c.pattern(15, 21, ["....FFFFFFFFFFFFFFFF....", "..FFFFFFFFFFFFFFFFFFFF.."], ["F": fur])
    for (x, y) in [(17, 26), (38, 27), (16, 31), (39, 33), (20, 36), (35, 36)] { c.px(x, y, furLight) }
    c.rect(19, 34, 18, 3, furLight)
    // The face: a pale leathery mask with a heavy brow and a big muzzle.
    c.pattern(19, 25, [
        "..FFFFFFFFFFFFFF..",
        ".FFFFFFFFFFFFFFFF.",
        "FFFFFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFFFFFFF",
        "FFFFFFFFFFFFFFFFFF",
        ".FFFFFFFFFFFFFFFF.",
        "..FFFFFFFFFFFFFF..",
        "...FFFFFFFFFFFF...",
    ], ["F": face])
    c.rect(20, 26, 16, 1, furDark); c.rect(21, 27, 5, 1, faceDark); c.rect(30, 27, 5, 1, faceDark)   // the brow ridge
    c.rect(22, 28, 2, 3, ink); c.rect(32, 28, 2, 3, ink)
    c.px(26, 30, faceDark); c.px(29, 30, faceDark)                     // nostrils
    if holding {
        c.rect(24, 32, 8, 1, faceDark); c.px(23, 31, faceDark); c.px(32, 31, faceDark)
    } else {
        c.rect(24, 32, 8, 1, faceDark)
    }
    // The beret, cocked over one side, with its little stalk.
    c.pattern(17, 18, [
        ".............b.......",
        "....BBBBBBBBBBBBB....",
        "..BBBBBBBBBBBBBBBBB..",
        ".BBBBBBBBBBBBBBBBBBBB",
        "BBBBBBBBBBBBBBBBBBBBd",
        ".dddddddddddddddddd..",
    ], ["B": beret, "b": beretDark, "d": beretDark])
    c.rect(20, 20, 3, 1, C(0xE84A50))
    // The bandolier, left shoulder to right hip.
    for i in 0..<9 {
        let x = 16 + i * 2 + i / 2, y = 33 + (i * 5) / 8
        c.rect(x, y, 3, 2, strap)
        if i % 2 == 0 { c.px(x + 1, y, brass) }
    }
    if holding, let s {
        // Up goes the Brain, in both arms.
        let k = habitArc((s - 0.08) / 0.84, hold: 0.6)
        let by = 30 - Int((k * 6).rounded())
        c.rect(36, by + 6, 6, 4, fur); c.rect(30, by + 7, 7, 3, fur)
        c.pattern(39, by - 4, [
            "..gggggg..",
            ".gPPpPPPg.",
            "gPPpPPpPPg",
            "gPpPPpPPPg",
            "gggggggggg",
            "MMMMMMMMMM",
            "MMRMMMMDMM",
            "MMMMMMMMMM",
            "MDMDMDMDMm",
            "mmmmmmmmmm",
        ], ["g": C(0xBCE4F0, 0.85), "P": C(0xF09AB0), "p": C(0xC8607A), "M": C(0x8A909C), "m": C(0x5A606C),
            "R": Int(p.t * 3) % 2 == 0 ? C(0xFF3A3A) : C(0x8A1A1A), "D": C(0x3A3E48)])
        c.rect(38, by + 4, 3, 4, fur); c.rect(48, by + 4, 2, 4, fur)
        if k > 0.7 {
            let f = frac(p.t * 0.7)
            drawHeart(c, x: 33 + Int(sin(f * 6) * 2), y: 16 - Int(f * 10), C(0xF04A7A, 1 - f))
        }
        return
    }
    // The machine gun, at the hip.
    c.oy += p.gunY
    c.pattern(34, 29, [
        "......KK..........",
        "WWWWKKKKKKKKKKKKKKKKK",
        "WWWKKKKKKKKKKKgKgKgKK",
        "WW...KDDDK.WWW.......",
        "......DDDD..WW.......",
        "......DDDD...........",
        ".......DD............",
    ], ["W": C(0x7A4A28), "K": C(0x2A2A30), "g": C(0x4A4A54), "D": C(0x1E1E24)])
    c.rect(53, 30, 1, 1, C(0x4A4A54))
    c.rect(38, 32, 4, 3, fur); c.rect(38, 34, 4, 1, furDark)          // his hand on the grip
}

// MARK: - Gentleman Ghost

/// Gentleman Ghost: the highwayman's ghost, a white tailcoat and cravat under a dark high-collared cloak, a top hat
/// and a monocle floating where his head should be (there's nothing there), and a coat that trails off into wisps
/// instead of legs; he shoots a flintlock. Signature: he doffs his hat and fades clean away, leaving the hat and the
/// monocle hanging in the air, then comes back and puts it on.
private func drawGentlemanGhost(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature
    var hatLift = 0, fade = 1.0, doff = false
    if let s {
        if s < 0.2 { hatLift = Int((s / 0.2 * 5).rounded()); doff = true }
        else if s < 0.8 { hatLift = 5; doff = s < 0.3 || s > 0.7; fade = 1 - 0.92 * habitArc((s - 0.2) / 0.6, hold: 0.4) }
        else { hatLift = Int(((1 - s) / 0.2 * 5).rounded()); doff = true }
    }
    let bob = sin(p.lt * 2.4) > 0 ? 0 : 1
    layer(c, alpha: fade) { c in ghostBody(c, p, doff: doff, bob: bob) }
    // The hat and the monocle, which don't fade.
    c.oy += p.breathe
    let hy = 13 - hatLift + bob
    let hat = C(0x1A1A22), hatSheen = C(0x3A3A4A), band = C(0x6A2A3A)
    c.rect(21, hy, 14, 9, hat)
    c.rect(22, hy + 1, 1, 7, hatSheen)
    c.rect(21, hy + 6, 14, 2, band)
    c.rect(18, hy + 9, 20, 1, hat); c.rect(17, hy + 9, 1, 1, hatSheen); c.rect(38, hy + 9, 1, 1, hatSheen)
    let my = 26 + bob - hatLift / 2
    c.pattern(30, my, [".GGG.", "GLLLG", "GLwLG", "GLLLG", ".GGG."], ["G": C(0xE0B848), "L": C(0xC8E8F0, 0.55), "w": white])
    if fade > 0.5 { for n in 0..<4 { c.px(31 - n / 2, my + 5 + n, C(0xE0B848, 0.8)) } }
}

private func ghostBody(_ c: PixelCanvas, _ p: Pose, doff: Bool, bob: Int) {
    let coat = C(0xE6E8F0), coatShade = C(0xAEB4C8), cloak = C(0x262A44), cloakEdge = C(0x4A5074)
    let wood = C(0x6A4428), steel = C(0x8A909C), brass = C(0xD8A840)
    // The cloak, billowing out behind him.
    for y in 28...41 {
        let k = Double(y - 28) / 13
        let back = Int((3 + k * 7 + sin(p.lt * p.capeSpeed + k * 3) * k * 2).rounded())
        c.rect(18 - back, y + p.breathe, back + 4, 1, cloak)
        c.px(18 - back, y + p.breathe, cloakEdge)
    }
    // No legs: the coat thins into wisps.
    for y in 37...44 {
        let k = Double(y - 37) / 7
        let half = Int((10 - k * 6).rounded())
        let sway = Int((sin(p.lt * 3 + k * 3) * k * 2).rounded())
        c.rect(28 - half + sway, y, half * 2, 1, coat.alpha(1 - k * 0.85))
        if y > 39 { c.px(28 - half + sway + Int(noise(Int(p.lt * 6) + y) * Double(half * 2)), y, coatShade.alpha(0.5)) }
    }
    c.oy += p.breathe
    // A faint glow where the head should be.
    c.rect(20, 23 + bob, 16, 8, C(0xC8F0E0, 0.12))
    // The high cloak collar, the coat and cravat.
    c.pattern(16, 27, [
        "LL....................LL",
        "LLL..................LLL",
        ".LLL................LLL.",
        ".LLLL..............LLLL.",
    ], ["L": cloak])
    c.rect(18, 30, 20, 8, coat)
    c.rect(37, 30, 1, 8, coatShade)
    c.pattern(23, 29, [".WWWWWWWW.", "WWWWwwWWWW", ".WWwWWwWW.", "..WWwWWW..", "...WWWW...", "....ww...."],
              ["W": white, "w": C(0xD0D4E0)])
    c.rect(20, 31, 1, 6, coatShade); c.rect(35, 31, 1, 6, coatShade)  // lapels
    c.rect(25, 34, 6, 4, C(0x8A90B4)); c.rect(25, 37, 6, 1, C(0x6A7094))   // the waistcoat
    for y in [34, 36] { c.px(27, y, brass) }
    c.rect(15, 33, 3, 3, coat); c.rect(15, 35, 3, 1, white)
    if doff {
        // The right hand up at the hat brim.
        c.rect(38, 24, 3, 12, coat); c.rect(38, 24, 3, 1, white)
        return
    }
    c.rect(38, 33, 3, 3, coat)
    // The flintlock.
    c.oy += p.gunY
    c.pattern(39, 30, [
        "...bBSSSSSSSSSs",
        "..WWWSSSSSSSSSS",
        ".WWW.r.........",
        "WWW............",
        "WW.............",
    ], ["W": wood, "S": steel, "s": C(0xC8CCD4), "b": brass, "B": C(0x3A3A40), "r": brass])
    c.rect(40, 33, 2, 2, white)
}

// MARK: - Black Mask

/// Black Mask: Roman Sionis, his whole head a glossy black skull (hollow eyes with pinprick pupils, a nose hole and
/// bared teeth), in a sharp white suit over a black shirt and red tie, a pistol in each hand. Signature: he twirls
/// both pistols round his fingers and finishes with them raised beside his head.
private func drawBlackMask(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xECEAE4), suitShade = C(0xB8B4AC), mask = C(0x24242C), maskLight = C(0x46465A), maskDark = C(0x121218)
    let shirt = C(0x16161B), tie = C(0x6A6A78)
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, ink, step: p.step, rows: 1)
    if !seatedPose { for lx in [21, 33] { c.rect(lx, 36, 1, 6, suitShade) } }
    c.oy += p.breathe
    drawBody(c, Look(body: mask, shade: maskDark, arm: suit, eye: nil))
    // The skull's dome and cheekbones.
    c.pattern(18, 23, [
        "...MMMMMMMMMMMMMM...",
        ".MMMLLMMMMMMMMMMMM..",
        "MMMLMMMMMMMMMMMMMMMd",
    ], ["M": mask, "L": maskLight, "d": maskDark])
    c.rect(20, 26, 2, 1, maskLight)
    c.pattern(20, 28, [
        ".KKKK.....KKKK.",
        "KKKKKK...KKKKKK",
        "KKwKKK...KKKwKK",
        ".KKKK.....KKKK.",
    ], ["K": C(0x050507), "w": C(0xF0F0F0)])
    c.pattern(26, 32, ["K.K", ".K."], ["K": C(0x050507)])
    c.rect(20, 32, 2, 1, maskLight); c.rect(34, 32, 2, 1, maskLight)
    c.pattern(22, 33, ["TKTKTKTKTKT", ".KTKTKTKTK."], ["K": C(0x050507), "T": C(0x8A8A96)])
    c.rect(18, 33, 2, 2, maskDark); c.rect(36, 33, 2, 2, maskDark)
    // The white suit, black shirt, red tie.
    c.rect(18, 35, 20, 3, suit)
    c.rect(37, 35, 1, 3, suitShade)
    c.pattern(24, 35, ["sKKTKKs", ".sKTKs.", "..sTs.."], ["s": suitShade, "K": shirt, "T": tie])
    c.rect(15, 33, 3, 3, suit)

    if let s = p.signature, s > 0.06, s < 0.94 {
        if s < 0.62 {
            // Twirling both pistols.
            let f = (s - 0.06) / 0.56
            let a = -1080 * (0.5 - 0.5 * cos(f * .pi))
            drawPistolProp(c, at: (16.5, 34.5), angle: 180 - a)
            c.rect(38, 33, 3, 3, suit)
            drawPistolProp(c, at: Sprite.hand, angle: a)
        } else {
            // Raised beside his head, muzzles up.
            c.rect(38, 29, 3, 7, suit); c.rect(15, 29, 3, 7, suit)
            drawPistolProp(c, at: (39.5, 28.5), angle: -90)
            drawPistolProp(c, at: (16.5, 28.5), angle: -90)
        }
        return
    }
    c.rect(38, 33, 3, 3, suit)
    drawPistol(c, x: 40, y: 31 + p.gunY, body: C(0x2A2A30), trim: C(0x9AA0AC))
}

/// One of Black Mask's pistols as a prop, its grip at `at`, barrel along `angle`.
private func drawPistolProp(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double) {
    prop(c, at: at, angle: angle) { s in
        s.pattern(19, 19, ["KKKKKKK", "KKTKKK.", "KK.....", "KK....."], ["K": C(0x2A2A30), "T": C(0x9AA0AC)])
    }
}
