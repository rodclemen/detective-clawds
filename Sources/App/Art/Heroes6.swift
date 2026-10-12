import Foundation

// Heroes: the Justice Society of America. Every one of them is Clawd in costume: masks, helmets, hoods and capes drawn
// over (and around) the blocky body. Where the hero shows a face, it's Clawd's own orange.

let heroes6: [Companion: Persona] = [
    .alanScott: Persona(name: "Alan Scott", weapon: .magic, motion: .fly, magic: Magic(core: C(0xD8FFD0), glow: C(0x2ADB4A), jagged: false),
                  headTop: 22, signature: 3.0, callout: "The dark things cannot stand the light!",
                  draw: drawAlanScott),
    .doctorFate: Persona(name: "Doctor Fate", weapon: .magic, motion: .hover, magic: Magic(core: C(0xFFF4C0), glow: C(0xFFC21E), jagged: false),
                  headTop: 17, signature: 3.2, callout: "Order shall prevail.",
                  draw: drawDoctorFate),
    .hourman: Persona(name: "Hourman", weapon: .melee, headTop: 20, signature: 3.0, callout: "One hour. That's all I need.",
                  draw: drawHourman),
    .stargirl: Persona(name: "Stargirl", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xFFFFFF), glow: C(0x6AB8FF)),
                  muzzle: (56, 34), headTop: 20, signature: 3.0, callout: "Stars and stripes forever!",
                  draw: drawStargirl),
    .wildcat: Persona(name: "Wildcat", weapon: .melee, headTop: 22, signature: 2.6, callout: "Come on, put 'em up!",
                  draw: drawWildcat),
    .atomSmasher: Persona(name: "Atom Smasher", weapon: .melee, armoured: true, pivot: smasherShoulder, bulk: 4, headTop: 15,
                  signature: 3.2, callout: "Time to go big!",
                  draw: drawAtomSmasher),
    .cyclone: Persona(name: "Cyclone", weapon: .magic, motion: .fly, magic: Magic(core: C(0xF4FFFF), glow: C(0xBFE8F0), jagged: false),
                  headTop: 20, signature: 3.0, callout: "Let's whip up a storm!",
                  draw: drawCyclone),
    .doctorMidnite: Persona(name: "Doctor Mid-Nite", weapon: .melee, headTop: 20, signature: 3.2, callout: "Lights out.",
                  draw: drawDoctorMidnite),
    .sandman: Persona(name: "Sandman", weapon: .ranged, shot: .energy(core: C(0xE8FFE0), glow: C(0x8AD86A)),
                  muzzle: (48, 31), headTop: 17, signature: 3.0, callout: "There is no escape from the Sandman!",
                  draw: drawSandman),
    .mrTerrific: Persona(name: "Mister Terrific", weapon: .melee, headTop: 22, signature: 3.2, callout: "Fair play.",
                  draw: drawMrTerrific),
]

// MARK: - Alan Scott

/// Alan Scott: the golden-age Green Lantern. Clawd under slicked black hair and a green domino mask, the red shirt
/// with the lantern emblem and the tall purple collar, a purple cape, green trousers and red boots. His power battery
/// (an old railway lantern) hangs from his left hand, and the ring on his right burns green when he casts. In flight he
/// leans in, ring fist first. Signature: he holds the lantern up and charges the ring at it, green light pouring out.
private func drawAlanScott(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redDark = C(0x8A1218), green = C(0x2A8A3A), greenDark = C(0x1C5A26)
    let purple = C(0x6A2A8A), purpleDark = C(0x4A1A62), hair = C(0x1A1A22)
    let charge = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let charging = charge > 0.05
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: purple, edge: purpleDark)
            for lx in [21, 31] {
                c.rect(lx, 36, 4, 6, green); c.rect(lx + 3, 36, 1, 6, greenDark); c.rect(lx, 40, 4, 2, red)
            }
        } else {
            drawCape(c, t: p.t, speed: p.capeSpeed, color: purple, edge: purpleDark)
            drawLegs(c, Look(leg: green), step: p.step)
            drawBoots(c, red, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        let up = p.flying ? 0 : (charging ? 4 : p.armRaise)
        drawBody(c, Look(arm: red), armRight: up)
        // Hair, slicked back.
        c.pattern(18, 22, [
            ".....HHHHHHHHHH.....",
            "...HHHHHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHHHHHH.",
            "HHHHHHHHHHHHHHHHHHHH",
            "HHHHHHHh.....HHHHHHH",
            "HH.................H",
        ], ["H": hair, "h": C(0x34343F)])
        // Green domino mask.
        c.pattern(19, 28, [
            ".MMMMMM....MMMMMM.",
            "MMM..MMMMMMM..MMMM",
            ".MM..MM....M..MMM.",
            "..MMMM......MMMM..",
        ], ["M": green])
        c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
        // Shirt, emblem, trousers' waist.
        c.rect(18, 33, 20, 5, red)
        c.rect(37, 33, 1, 5, redDark)
        c.pattern(25, 33, [".YYY.", "YGGGY", "YGgGY", ".YYY."], ["Y": C(0xE8C030), "G": C(0x2A8A3A), "g": C(0x8AFF9A)])
        c.rect(18, 37, 20, 1, green)
        // The tall purple collar.
        c.pattern(16, 28, [
            "P......................P",
            "PP....................PP",
            ".PPp................pPP.",
            "..PPp..............pPP..",
            "...PP..............PP...",
        ], ["P": purple, "p": purpleDark])
        if p.flying {
            c.rect(38, 31, 4, 3, red)
            ringGlow(c, x: 41.5, y: 32, r: 1.8)
            drawLantern(c, x: 11, y: 35, glow: 0)
            return
        }
        if charging {
            // Lantern held up in front, ring hand on it, light pouring out.
            c.ellipse(42, 33, Int(4 + 6 * charge), Int(3 + 5 * charge), C(0x2ADB4A, 0.18 * charge))
            drawLantern(c, x: 39, y: 30, glow: charge)
            for i in 0..<4 {
                let f = frac(p.t * 0.9 + Double(i) * 0.25)
                let x = 42 + Int(sin(Double(i) * 2.3 + f * 6) * (3 + 5 * f)), y = 30 - Int(f * 14)
                twinkle(c, x, y, C(0x8AFF9A, (1 - f) * charge))
            }
            c.rect(38, 28, 3, 3, red); ringGlow(c, x: 40.5, y: 29.5, r: 1.2 + 1.2 * charge)
            return
        }
        drawLantern(c, x: seatedPose ? 9 : 11, y: seatedPose ? 33 : 35, glow: 0.25)
        let hy = 34.5 - Double(up)
        c.px(40, Int(hy), C(0x5CFF7A))
        if p.zap != nil || p.ready { ringGlow(c, x: 40.5, y: hy, r: 1.6) }
    }
}

private func ringGlow(_ c: PixelCanvas, x: Double, y: Double, r: Double) {
    c.glowLine(x, y, x, y, core: C(0xD8FFD0), glow: C(0x2ADB4A), coreR: 0.6, glowR: r)
}

/// Alan Scott's power battery: an old railway lantern, its glass glowing green (`glow` 0…1 brighter).
private func drawLantern(_ c: PixelCanvas, x: Int, y: Int, glow: Double) {
    let metal = C(0x2A6A34), metalDark = C(0x163A1C), glass = C(0x7AF08A), light = C(0xE8FFE8)
    c.pattern(x, y, [
        "..kk..",
        ".k..k.",
        "MMMMMM",
        ".GLGG.",
        ".GGGG.",
        ".GGGG.",
        "MMMMMM",
        ".mmmm.",
    ], ["k": metalDark, "M": metal, "m": metalDark, "G": glass, "L": light])
    if glow > 0 {
        let cx = Double(x) + 3, cy = Double(y) + 4.5
        c.glowLine(cx, cy, cx, cy, core: light.alpha(0.6 * glow), glow: C(0x2ADB4A).alpha(0.7 * glow), coreR: 0.6, glowR: 1.5 + 2.5 * glow)
    }
}

// MARK: - Doctor Fate

/// Doctor Fate: Clawd sealed inside the golden Helm of Nabu, only the eyes showing through it, the blue suit with
/// gold gloves, boots and belt, a gold cape and the Amulet of Anubis (an ankh) at his throat. He floats; casting, a
/// small golden ankh burns over his hand. Signature: both hands come up, his eyes blaze and he traces a huge
/// golden ankh in the air beside him.
private func drawDoctorFate(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A4AB0), blueDark = C(0x1C3280), gold = C(0xE8B830), goldDark = C(0xA87E1A), goldLight = C(0xFFE07A)
    let sig = p.signature
    let power = sig.map { habitArc($0, hold: 0.6) } ?? 0
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.7, color: C(0xC88418), edge: C(0x7A4A0E), extra: 1.5)
    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, gold, step: p.step, rows: 2)
    c.oy += p.breathe
    let lift = power > 0.05 ? 4 : 0
    drawBody(c, Look(body: blue, shade: blueDark, arm: gold, eye: nil), armLeft: lift, armRight: max(p.armRaise, lift))
    let eyes = power > 0.3 ? C(0xFFFFFF) : C(0xF4F0D0)
    c.pattern(17, 18, [
        "........GGGGGG........",
        "......GGGGGGGGGG......",
        ".....GGGGLLGGGGGG.....",
        "....GGGGLLGGGGGGGG....",
        "...GGGGLLGGGGGGGGGG...",
        "..GGGGGGGGGGGGGGGGGg..",
        ".GGGGGGGGGGGGGGGGGGGg.",
        ".GGGGGGGGGGGGGGGGGGGg.",
        ".GGgGGGGGGGGGGGGGgGGg.",
        ".GGGgKKKKGGGGKKKKgGGg.",
        ".GGGGKWWKGGGGKWWKGGGg.",
        ".GGGGGKWKGGGGKWKGGGGg.",
        ".GGGGGGKKGGGGKKGGGGGg.",
        ".gGGGGGGGGGGGGGGGGGGg.",
        "..gggggggggggggggggg..",
    ], ["G": gold, "g": goldDark, "L": goldLight, "K": C(0x2A1E10), "W": eyes])
    if power > 0.3 {
        for x in [23.5, 31.5] { c.glowLine(x, 28.5, x, 28.5, core: white, glow: C(0xFFC21E), coreR: 0.6, glowR: 1.2 + 1.4 * power) }
    }
    // Gold shoulder clasps, the amulet, the belt.
    c.rect(18, 33, 4, 2, gold); c.rect(34, 33, 4, 2, gold)
    c.rect(18, 37, 20, 1, gold)
    c.pattern(26, 33, [".YY.", "Y..Y", ".YY.", "YYYY", ".YY."], ["Y": goldLight])
    if power > 0.05, let s = sig {
        let k = min(1, max(0, (s - 0.08) / 0.45))
        let fade = s > 0.82 ? max(0, 1 - (s - 0.82) / 0.16) : 1
        drawAnkh(c, cx: 51, cy: 27, s: 4, k: k, core: C(0xFFF4C0, fade), glow: C(0xFFC21E, 0.9 * fade))
    } else if p.zap != nil {
        drawAnkh(c, cx: 41.5, cy: 31 - Double(p.armRaise), s: 1.1, k: 1, core: C(0xFFF4C0, 0.9), glow: C(0xFFC21E, 0.7))
    }
}

/// A glowing ankh traced in the air, centred on its crossbar at (`cx`, `cy`), `s` its scale, `k` 0…1 how much of it
/// has been drawn yet (loop first, then the bar, then the stem).
private func drawAnkh(_ c: PixelCanvas, cx: Double, cy: Double, s: Double, k: Double, core: Px, glow: Px) {
    let rx: Double = 1.25 * s, ry: Double = 1.8 * s
    let ly: Double = cy - 0.4 * s - ry
    let n = 16
    let shown = Int((Double(n) * min(1, k / 0.5)).rounded())
    for i in 0..<shown {
        let a0: Double = Double.pi / 2 + Double(i) / Double(n) * 2 * Double.pi
        let a1: Double = Double.pi / 2 + Double(i + 1) / Double(n) * 2 * Double.pi
        c.glowLine(cx + cos(a0) * rx, ly + sin(a0) * ry, cx + cos(a1) * rx, ly + sin(a1) * ry,
                   core: core, glow: glow, coreR: 0.45, glowR: 1.5)
    }
    if k > 0.5 {
        let f: Double = min(1, (k - 0.5) / 0.2)
        let hw: Double = 2.2 * s * f
        c.glowLine(cx - hw, cy - 0.2 * s, cx + hw, cy - 0.2 * s, core: core, glow: glow, coreR: 0.45, glowR: 1.5)
    }
    if k > 0.7 {
        let f: Double = min(1, (k - 0.7) / 0.3)
        let y0: Double = cy - 0.4 * s
        c.glowLine(cx, y0, cx, y0 + 4 * s * f, core: core, glow: glow, coreR: 0.45, glowR: 1.5)
    }
}

// MARK: - Hourman

/// Hourman (Rex Tyler): Clawd in the black cowl, a yellow shirt with the black hourglass on the chest, black gloves
/// and trousers, yellow boots and a gold cape. He fights with his fists. Signature: he holds up his hourglass and
/// watches the sand run through, then the Miraclo kicks in: arms up, flexing, a golden glow round him for his hour.
private func drawHourman(_ c: PixelCanvas, _ p: Pose) {
    let yellow = C(0xF2C21E), yellowDark = C(0xC8961A), black = C(0x1E1E26), blackLight = C(0x3A3A46)
    let cape = C(0xD8901A), capeEdge = C(0x9A5A10)
    let sig = p.signature
    let sand = sig.flatMap { $0 > 0.06 && $0 < 0.42 ? ($0 - 0.06) / 0.36 : nil }
    let power: Double = sig.map { $0 >= 0.42 ? habitArc(($0 - 0.42) / 0.56, hold: 0.55) : 0 } ?? 0
    if power > 0.05 {
        c.oy += p.breathe
        let flick: Double = 0.85 + 0.15 * sin(p.t * 30)
        c.ellipse(28, 30, Int(14 * power), Int(15 * power), C(0xFFC81E, 0.16 * power * flick))
        c.ellipse(28, 31, Int(11 * power), Int(12 * power), C(0xFFE27A, 0.2 * power * flick))
        c.oy -= p.breathe
    }
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge)
    drawLegs(c, Look(leg: black), step: p.step)
    drawBoots(c, yellow, step: p.step, rows: 3)
    c.oy += p.breathe
    let flex = power > 0.05 ? 5 : 0
    drawBody(c, Look(body: yellow, shade: yellowDark, arm: black), armLeft: flex, armRight: sand != nil ? 4 : flex)
    // Black cowl, the face showing below the eyes.
    c.pattern(17, 20, [
        "......KKKKKKKKKK......",
        "....KKKKKKKKKKKKKK....",
        "...KKKKKkKKKKKKKKKK...",
        "..KKKKkKKKKKKKKKKKKK..",
        "..KKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KKKKWEKKKKKKKKWEKKKK.",
        ".KKKKWEKKKKKKKKWEKKKK.",
        ".KKKSSSSSSSSSSSSSSKKK.",
        ".KKKKSSSSSkkSSSSSKKKK.",
    ], ["K": black, "k": blackLight, "S": clawdOrange, "E": ink, "W": white])
    c.px(27, 32, clawdShade); c.px(28, 32, clawdShade)
    // The hourglass on the chest.
    let glowing = power > 0.3
    c.pattern(26, 33, ["KKKKK", ".KYK.", "..K..", ".KYK.", "KKKKK"],
              ["K": glowing ? C(0x8A5A10) : black, "Y": glowing ? C(0xFFF4C0) : yellow])
    c.rect(18, 37, 20, 1, yellowDark)
    if let f = sand {
        // Holding the hourglass up, the sand running through.
        c.rect(38, 29, 3, 3, black)
        drawHourglass(c, x: 38, y: 22, f: min(1, f * 1.1))
        return
    }
    if power > 0.05 {
        // Flexing: fists up both sides, sparks of gold.
        c.rect(14, 27, 4, 4, black); c.rect(38, 27, 4, 4, black)
        if power > 0.4 {
            let i = Int(p.t * 18)
            for k in 0..<4 {
                let a: Double = noise(i * 3 + k) * 2 * Double.pi, r: Double = 10 + noise(i * 5 + k) * 5
                c.px(28 + Int(cos(a) * r), 30 + Int(sin(a) * r), k % 2 == 0 ? white : C(0xFFD040))
            }
        }
        return
    }
    drawPunch(c, angle: p.melee, trail: p.trail, arm: yellow, fist: black)
}

/// Hourman's hourglass, 5 × 7 from (`x`, `y`), `f` 0…1 how much sand has run through.
private func drawHourglass(_ c: PixelCanvas, x: Int, y: Int, f: Double) {
    let frame = C(0xB8862A), sand = C(0xF0D070), glass = C(0xCFE8F8, 0.55)
    c.rect(x, y, 5, 1, frame); c.rect(x, y + 6, 5, 1, frame)
    c.rect(x, y + 1, 1, 5, frame); c.rect(x + 4, y + 1, 1, 5, frame)
    c.rect(x + 1, y + 1, 3, 1, f < 0.5 ? sand : glass)
    c.px(x + 2, y + 2, f < 0.88 ? sand : glass)
    c.px(x + 2, y + 3, f > 0.02 && f < 0.98 ? sand : glass)
    c.px(x + 2, y + 4, f > 0.12 ? sand : glass)
    c.rect(x + 1, y + 5, 3, 1, f > 0.5 ? sand : glass)
}

// MARK: - Stargirl

/// Stargirl (Courtney Whitmore): Clawd with a blonde ponytail and a dark-blue domino mask, the blue top with the big
/// white star, red-and-white stripes below, white leggings and red boots, and the Cosmic Staff, a gold rod with a
/// glowing star on the end: planted at her side, levelled to shoot, and ridden like a surfboard when she flies.
/// Signature: she twirls the staff over her head, then points it at the sky and a starburst pops off the end.
private func drawStargirl(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A3FA0), blueDark = C(0x1C2A70), red = C(0xD0202A), wht = C(0xF2F2F4)
    let hair = C(0xF0D060), hairDark = C(0xC0A03A)
    if p.flying {
        // Riding the staff, star first, sparks off the back end.
        drawStaff(c, at: (28.5, 44.5), angle: 0, glow: 1)
        let i = Int(p.t * 20)
        for k in 0..<4 {
            let x = 16 - k * 3 - Int(noise(i + k) * 3), y = 44 + Int((noise(i * 3 + k) - 0.5) * 3)
            c.px(x, y, k % 2 == 0 ? white : C(0x9AD0FF, 0.7))
        }
    }
    let look = Look(leg: wht, arm: blue)
    drawLegs(c, look, step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 38 - (lifted ? 1 : 0), 2, 1, red)
        }
    }
    drawBoots(c, red, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, look)
    // Ponytail behind, then the hair.
    let swish = Int((sin(p.t * 3) * 1).rounded())
    c.pattern(11 + swish, 22, [".HHH", "HHHH", "HHHh", "HHh.", "Hh..", "H..."], ["H": hair, "h": hairDark])
    c.pattern(17, 20, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHhHHHHHHhHHHHH..",
        "..HHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHh...hHHHHHHH.",
        ".HHHh.............HHH.",
        ".HHH...............HH.",
        ".HH................HH.",
        ".Hh................hH.",
    ], ["H": hair, "h": hairDark])
    c.pattern(19, 28, [
        ".MMMMMM....MMMMMM.",
        "MMM..MMMMMMM..MMMM",
        ".MM..MM....M..MMM.",
        "..MMMM......MMMM..",
    ], ["M": blueDark])
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    // Blue top with the star, the stripes, the belt.
    c.rect(18, 33, 20, 3, blue)
    c.rect(37, 33, 1, 3, blueDark)
    c.pattern(25, 32, ["..W..", "WWWWW", ".WWW.", "W...W"], ["W": wht])
    for x in stride(from: 18, to: 38, by: 2) { c.rect(x, 36, 1, 2, red); c.rect(x + 1, 36, 1, 2, wht) }
    c.rect(18, 35, 20, 1, C(0xE8C040))
    c.rect(15, 33, 3, 3, red)

    if p.flying {
        c.rect(38, 31, 3, 3, red)
        return
    }
    if let s = p.signature, s > 0.06, s < 0.94 {
        if s < 0.55 {
            // Twirled overhead: three turns, quick in the middle.
            let k = (s - 0.06) / 0.49
            let a: Double = -90 + 1080 * (0.5 - 0.5 * cos(k * Double.pi))
            c.rect(38, 29, 3, 3, red)
            for i in 1...2 { drawStaff(c, at: (40.5, 27.5), angle: a - Double(i) * 30, glow: 0.4, alpha: 0.3 / Double(i)) }
            drawStaff(c, at: (40.5, 27.5), angle: a, glow: 0.4)
        } else {
            // Pointed at the sky: a starburst.
            c.rect(38, 30, 3, 3, red)
            drawStaff(c, at: (40.5, 25.5), angle: -90, glow: 1, centred: false)
            let b = (s - 0.55) / 0.39
            if b > 0.1 {
                let r: Double = 2 + 9 * b
                let fade: Double = 1 - b * b
                for i in 0..<8 {
                    let a: Double = Double(i) / 8 * 2 * Double.pi
                    let x = 40.5 + cos(a) * r, y = 13.5 + sin(a) * r * 0.8
                    twinkle(c, Int(x), Int(y), (i % 2 == 0 ? C(0xFFFFFF) : C(0x9AD0FF)).alpha(fade))
                }
                twinkle(c, 40, 13, C(0xFFE27A).alpha(fade))
            }
        }
        return
    }
    let aiming = p.fire != nil || p.ready || p.gunLift > 0 || p.smoke != nil
    if aiming {
        c.oy += p.gunY
        drawStaff(c, at: (42.5, 34.5), angle: 0, glow: p.fire != nil ? 1 : 0.5, centred: false)
        c.rect(38, 33, 3, 3, red)
        return
    }
    drawStaff(c, at: (42.5, seatedPose ? 30.5 : 33.5), angle: -90, glow: 0.3, centred: false)
    c.rect(38, 33, 3, 3, red)
}

/// The Cosmic Staff: a gold rod with a glowing star on its end, held at `at` along `angle`. `centred`: held by the
/// middle (twirling, riding it); otherwise by its lower end, the star a long way out.
private func drawStaff(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, glow: Double, alpha: Double = 1,
                       centred: Bool = true) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        let gold = C(0xE8C040), goldDark = C(0xA8862A)
        let x0 = centred ? 8 : 15
        s.rect(x0, 20, 32 - x0, 1, gold)
        for x in stride(from: x0 + 2, to: 32, by: 4) { s.px(x, 20, goldDark) }
        s.pattern(31, 17, ["..Y..", "..Y..", "YYWYY", ".YYY.", ".Y.Y."], ["Y": C(0xF4D050), "W": white])
        if glow > 0 {
            s.glowLine(33.5, 19.5, 33.5, 19.5, core: C(0xFFFFFF, 0.8 * glow), glow: C(0x6AB8FF, glow), coreR: 0.4, glowR: 1.5 + 1.5 * glow)
        }
    }
}

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

// MARK: - Wildcat

/// Wildcat (Ted Grant): Clawd in the black cat suit, the cowl with its pointed ears and white-rimmed eye holes, his
/// jaw showing in a cocky grin, and a pair of red boxing gloves. He fights like the heavyweight he was. Signature: up
/// on his toes, shadow-boxing: jab, jab, hook, uppercut.
private func drawWildcat(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1C1C24), suitLight = C(0x3A3A48), glove = C(0xC8202A), gloveDark = C(0x8A1218)
    let sig = p.signature.flatMap { $0 > 0.06 && $0 < 0.94 ? ($0 - 0.06) / 0.88 : nil }
    let look = Look(body: suit, shade: C(0x101016), leg: suit, arm: suit, eye: nil)
    drawLegs(c, look, step: p.step)
    if let k = sig { c.oy -= Int(k * 16) % 2 }                       // bouncing on his toes
    c.oy += p.breathe
    drawBody(c, look)
    c.pattern(18, 21, [
        ".K................K.",
        ".KK..............KK.",
        ".KLK............KLK.",
        ".KKKKKKKKKKKKKKKKKK.",
        "KKKKKKLLLLLLLLKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKWWWWKKKKKKKKWWWWKK",
        "KKWEEWKKKKKKKKWEEWKK",
        "KKWEEWKKKKKKKKWEEWKK",
        "KKKKSSSSSSSSSSSSKKKK",
        "KKKKKSSDSSSSDSSKKKKK",
        "KKKKKKSSDDDDSSKKKKKK",
    ], ["K": suit, "L": suitLight, "W": C(0xE8E8F0), "E": ink, "S": clawdOrange, "D": clawdShade])
    c.rect(18, 34, 20, 1, suitLight)
    c.rect(27, 35, 2, 2, suitLight)
    if let k = sig {
        // Four punches, one per quarter: jab, jab, hook, uppercut.
        let beat = min(3, Int(k * 4)), f = k * 4 - Double(beat)
        let angles: [Double] = [0, -4, -35, -72]
        let reach: Double = 3 + 6 * sin(f * Double.pi)
        drawGlove(c, x: 14, y: 28, glove, gloveDark)                    // guard up
        if f > 0.25 && f < 0.75 {
            let e = along(angles[beat], reach + 2)
            for d in [3.0, 5.0] { c.px(Int(e.x - d), Int(e.y) - 2, white.alpha(0.6)); c.px(Int(e.x - d), Int(e.y) + 2, white.alpha(0.6)) }
        }
        drawPunch(c, angle: angles[beat], trail: [], arm: suit, fist: glove, reach: reach, size: 4)
        return
    }
    if p.melee != nil {
        drawGlove(c, x: 14, y: 29, glove, gloveDark)
        drawPunch(c, angle: p.melee, trail: p.trail, arm: suit, fist: glove, reach: 7, size: 4)
        return
    }
    drawGlove(c, x: 14, y: 32, glove, gloveDark)
    drawGlove(c, x: 38, y: 32, glove, gloveDark)
}

private func drawGlove(_ c: PixelCanvas, x: Int, y: Int, _ glove: Px, _ dark: Px) {
    c.rect(x, y, 4, 4, glove); c.rect(x, y + 3, 4, 1, dark); c.px(x + 1, y, C(0xE85A5A))
}

// MARK: - Atom Smasher

private let smasherShoulder = (x: 40.5, y: 24.5)

/// Atom Smasher (Al Rothstein): a big, broad Clawd in red with blue shoulders, gloves and trunks, a red helmet with a
/// blue crest and visor and white lenses, his jaw showing under it, and thick legs. One huge arm hangs at his side
/// and the other swings from the shoulder. Signature: he grows, half as big again, the ground shaking, and shrinks back.
private func drawAtomSmasher(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.05, s < 0.95 else { atomSmasher(c, p); return }
    var q = p
    q.signature = nil; q.breathe = 0
    let k = habitArc((s - 0.05) / 0.9, hold: 0.45)
    let shake = k > 0.9 ? (Int(p.t * 30) % 2 == 0 ? 1 : 0) : 0
    stamp(c, offscreen { atomSmasher($0, q) }, scale: 1 + 0.5 * k, to: (28 + Double(shake), 43.5))
    if k > 0.6 {
        // Dust kicked up round his feet.
        let i = Int(p.t * 12)
        for d in 0..<6 {
            let x = 6 + d * 9 + Int(noise(i + d) * 4), y = 42 - Int(noise(i * 2 + d) * 3)
            c.rect(x, y, 3, 2, C(0xC8B8A0, 0.5 * k))
        }
    }
}

private func atomSmasher(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redDark = C(0x8A1218), blue = C(0x2A4AB0), blueDark = C(0x1C3280)
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, blue); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 3, lifted ? 7 : 8, blue)
        c.rect(lx + 2, 38, 1, lifted ? 5 : 6, blueDark)
        c.rect(lx, lifted ? 40 : 41, 3, 3, red)
    }
    c.oy += p.breathe
    // Left arm hanging at his side.
    c.rect(10, 21, 5, 10, red); c.rect(10, 21, 1, 10, redDark); c.rect(14, 21, 1, 10, redDark)
    c.rect(9, 30, 6, 6, blue); c.rect(9, 35, 6, 1, blueDark)
    c.rect(15, 19, 26, 19, red)
    c.pattern(15, 15, [
        "........RRRRRRRRRR........",
        ".....RRRRRRBBBBRRRRRR.....",
        "...RRRRRRRRBBBBRRRRRRRR...",
        "..RRRRRRRRRBBBBRRRRRRRRR..",
        "RRRRRRRRRRRBBBBRRRRRRRRRRr",
        "RRRRRRRRRRRBBBBRRRRRRRRRRr",
        "RRRRRRRRRRRBBBBRRRRRRRRRRr",
        "RRRBBBBBBBBBBBBBBBBBBBRRRr",
        "RRRBWWWWWBBBBBBBWWWWWBRRRr",
        "RRRBBWWWWBBBBBBBWWWWBBRRRr",
        "RRRRBBBBBBBBBBBBBBBBBRRRRr",
        "RRRRSSSSSSSSSSSSSSSSSRRRRr",
        "RRRRSSSSSSSSSSSSSSSSSRRRRr",
        "RRRRRSSSSSSkkkSSSSSSRRRRRr",
        "BBBBBRRRRRRRRRRRRRRRRRBBBb",
        "BBBBRRRRRRRRRRRRRRRRRRRBBb",
        "BBBRRRRRRRRRRRRRRRRRRRRRBb",
        "BBBRRRRRRRRWWRRRRRRRRRRRBb",
        "BBBRRRRRRWWRRWWRRRRRRRRRBb",
        "BBBRRRRRRRRWWRRRRRRRRRRRBb",
        "BBBRRRRRRRRRRRRRRRRRRRRRBb",
        "KKKKKKKKKKKKKKKKKKKKKKKKKK",
        "BBBBBBBBBBBBBBBBBBBBBBBBBb",
    ], ["R": red, "r": redDark, "B": blue, "b": blueDark, "W": white, "S": clawdOrange, "k": clawdShade,
        "K": C(0x1E1E26)])
    let angle = p.melee ?? 82
    for (i, ta) in p.trail.enumerated() { drawSmasherArm(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
    drawSmasherArm(c, angle: angle)
}

/// Atom Smasher's right arm, swung from the shoulder, a big blue fist on the end.
private func drawSmasherArm(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: smasherShoulder, angle: angle, alpha: alpha) { s in
        let red = C(0xC8202A), redDark = C(0x8A1218), blue = C(0x2A4AB0), blueDark = C(0x1C3280)
        s.rect(18, 18, 9, 5, red)
        s.rect(18, 22, 9, 1, redDark)
        s.rect(26, 17, 6, 7, blue)
        s.rect(31, 18, 1, 5, blueDark); s.rect(26, 23, 6, 1, blueDark)
        s.px(28, 18, blueDark); s.px(28, 20, blueDark)
    }
}

// MARK: - Cyclone

/// Cyclone (Maxine Hunkel): Clawd with red pigtails tied in white ribbons, a red-and-white dress with a flared striped
/// skirt, white stockings and red boots, and a red-and-white parasol held up over her shoulder. Wind curls round her
/// casting hand; she flies on a little whirlwind. Signature: she spins up a full tornado round herself and rides it
/// up off the ground.
private func drawCyclone(_ c: PixelCanvas, _ p: Pose) {
    let spin = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    if spin > 0.05 {
        let h = 30 * spin
        drawTwister(c, bottom: 44, height: h, t: p.t, front: false, alpha: spin)
        var q = p
        q.signature = nil
        let o = offscreen { cyclone($0, q) }
        if spin > 0.6 && Int(p.t * 8) % 2 == 1 { _ = o.mirror(aboutX: Sprite.bodyCenterX) }
        let rise = Int((5 * spin).rounded())
        c.oy -= rise
        stamp(c, o)
        c.oy += rise
        drawTwister(c, bottom: 44, height: h, t: p.t, front: true, alpha: spin)
        return
    }
    if p.flying {
        layer(c, lean: 4) { c in
            drawTwister(c, bottom: 50, height: 6, t: p.t, front: false, alpha: 0.7)
            cyclone(c, p)
            drawTwister(c, bottom: 50, height: 6, t: p.t, front: true, alpha: 0.7)
        }
        return
    }
    cyclone(c, p)
}

private func cyclone(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD02838), redDark = C(0x8A1222), wht = C(0xF4F4F6), whtShade = C(0xC8CCD8)
    let hair = C(0xA8201A), hairDark = C(0x6A1210)
    // The parasol over her left shoulder.
    let bob = p.flying ? 0 : p.breathe
    c.oy += bob
    c.glowLine(15.5, 34, 12.5, 16, core: C(0x6A4A2A), glow: C(0, 0), coreR: 0.5, glowR: 0.6)
    for dy in 0...4 {
        let w = Int((8.5 * sqrt(1 - pow(Double(4 - dy) / 4.6, 2))).rounded())
        for x in (12 - w)...(12 + w) {
            let seg = (x - 12 + 20) / 3 % 2
            c.px(x, 11 + dy, seg == 0 ? red : wht)
        }
    }
    c.rect(3, 15, 19, 1, redDark)
    c.px(12, 10, C(0x6A4A2A))
    c.oy -= bob
    if p.flying {
        for lx in [22, 31] { c.rect(lx, 38, 3, 4, wht); c.rect(lx, 41, 3, 2, red) }
    } else {
        drawLegs(c, Look(leg: wht), step: p.step)
        drawBoots(c, red, step: p.step, rows: 2)
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: wht), armRight: p.armRaise)
    // Pigtails with ribbons, then the hair.
    for (x, flip) in [(13, false), (38, true)] {
        let wag = Int((sin(p.t * 4 + (flip ? 1 : 0)) * 0.8).rounded())
        let rows: [String] = ["WW..", "HHH.", "HHHH", ".HHh", "..Hh"]
        c.pattern(x, 26 + wag, flip ? rows.map { String($0.reversed()) } : rows, ["H": hair, "h": hairDark, "W": wht])
    }
    c.pattern(17, 20, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHhHHHHHHhHHHHH..",
        "..HHHHHHHHHHHHHHHHHHH.",
        ".HHHHhHHHhHHHhHHHHHHH.",
        ".HHH.H...H...H....HHH.",
        ".HH................HH.",
    ], ["H": hair, "h": hairDark])
    c.px(25, 32, C(0xE87A6A)); c.px(30, 32, C(0xE87A6A))           // freckles, near enough
    // The dress: red bodice with a white collar, the flared skirt in stripes.
    c.rect(18, 33, 20, 2, red)
    c.pattern(23, 33, ["WWW..WWW", ".WWWWWW."], ["W": wht])
    let flutter = Int((sin(p.t * (p.flying ? 14 : 3)) * 0.9).rounded())
    c.pattern(16 + flutter, 35, [
        "..RRWWRRWWRRWWRRWWRRWW..",
        ".RRWWRRWWRRWWRRWWRRWWRR.",
        "RRWWRRWWRRWWRRWWRRWWRRWW",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
    ], ["R": red, "W": wht, "S": whtShade])
    c.rect(15, 33, 3, 3, wht)
    if p.zap != nil {
        let hand = (x: Sprite.hand.x, y: Sprite.hand.y - Double(p.armRaise))
        for k in 0..<2 {
            var prev: (Double, Double)? = nil
            for i in 0...6 {
                let a: Double = p.t * 9 + Double(k) * Double.pi + Double(i) * 0.5
                let r: Double = 1.5 + Double(i) * 0.45
                let pt = (hand.x + cos(a) * r, hand.y + sin(a) * r * 0.6)
                if let pv = prev { c.glowLine(pv.0, pv.1, pt.0, pt.1, core: C(0xF4FFFF, 0.9), glow: C(0xBFE8F0, 0.5), coreR: 0.3, glowR: 1) }
                prev = pt
            }
        }
    }
}

/// A whirlwind funnel standing on `bottom`, `height` tall, widening as it goes up: streaks of wind running round it.
/// `front`: the half that passes in front of whoever's inside it.
private func drawTwister(_ c: PixelCanvas, bottom: Int, height: Double, t: Double, front: Bool, alpha: Double) {
    guard height >= 2 else { return }
    let top = Double(bottom) - height
    var y = Double(bottom)
    var row = 0
    while y >= top {
        let k: Double = (Double(bottom) - y) / max(height, 1)
        let w: Double = 2 + k * (4 + height * 0.42)
        for i in 0..<4 {
            let a: Double = t * 9 + Double(row) * 0.7 + Double(i) * 1.5708
            let isFront = sin(a) > 0
            guard isFront == front else { continue }
            let x = Sprite.bodyCenterX + cos(a) * w
            let len: Double = 2 + k * 3
            c.glowLine(x - len, y, x + len * 0.5, y, core: C(0xF4FFFF, 0.9 * alpha), glow: C(0xBFE8F0, 0.4 * alpha),
                       coreR: 0.3, glowR: 0.8)
        }
        y -= 2
        row += 1
    }
}

// MARK: - Doctor Mid-Nite

/// Doctor Mid-Nite: Clawd in the midnight-blue cowl and suit with a short dark cape, round red infrared goggles and a
/// white crescent moon on the chest. Hooty the owl rides on his left shoulder. He fights with his fists. Signature: he
/// lobs a blackout bomb, a cloud of black smoke swallows the space in front of him, his goggles light up in the dark,
/// and Hooty takes off for a loop round his head.
private func drawDoctorMidnite(_ c: PixelCanvas, _ p: Pose) {
    let navy = C(0x2A3472), navyDark = C(0x1A2250), navyLight = C(0x4A5AA0)
    let cape = C(0x0E0E16), capeEdge = C(0x2A3058)
    let sig = p.signature
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge, extra: -1)
    drawLegs(c, Look(leg: navy), step: p.step)
    drawBoots(c, C(0x0E0E14), step: p.step, rows: 3)
    c.oy += p.breathe
    let throwing = sig.map { $0 > 0.04 && $0 < 0.2 } ?? false
    drawBody(c, Look(body: navy, shade: navyDark, arm: navy, eye: nil), armRight: throwing ? 4 : 0)
    c.pattern(17, 21, [
        ".......NNNNNNNN.......",
        ".....NNNNNNNNNNNN.....",
        "....NNNNNNLLNNNNNN....",
        "...NNNNNNNNNNNNNNNN...",
        "..NNNNNNNNNNNNNNNNNN..",
        ".NNNNNNNNNNNNNNNNNNNN.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".NKGGGGKKKKKKGGGGKNNN.",
        ".NGRRrRGKKKKGRRrRGNNN.",
        ".NGRRRRGNNNNGRRRRGNNN.",
        ".NKGGGGKNNNNKGGGGKNNN.",
        ".NNNNSSSSSSSSSSSSNNNN.",
        ".NNNNSSSSSkkSSSSSNNNN.",
    ], ["N": navy, "L": navyLight, "K": C(0x0E0E14), "G": C(0x5A5E68), "R": C(0xD8302A), "r": C(0xFF9A8A),
        "S": clawdOrange, "k": clawdShade])
    // Crescent moon on the chest.
    c.pattern(21, 34, [".WW", "W..", "W..", ".WW"], ["W": C(0xE8ECF4)])
    c.rect(37, 33, 1, 5, navyDark)
    // Signature timeline.
    let cloud: Double = sig.map { $0 > 0.18 ? habitArc(($0 - 0.18) / 0.78, hold: 0.5) : 0 } ?? 0
    if cloud > 0.4 {
        for x in [23.5, 32.5] { c.glowLine(x, 29.5, x, 29.5, core: C(0xFFD0C8), glow: C(0xFF3A2A), coreR: 0.8, glowR: 2.4) }
    }
    if let s = sig, s > 0.04, s < 0.24 {
        // The pellet, lobbed in an arc.
        let f = (s - 0.04) / 0.2
        let x = 41 + f * 12, y = 30 - sin(f * Double.pi) * 6 + f * 4
        c.rect(Int(x), Int(y), 2, 2, C(0x0E0E14)); c.px(Int(x), Int(y), C(0x5A5E68))
    }
    if cloud > 0.02 {
        let i = Int(p.t * 6)
        for k in 0..<7 {
            let a: Double = Double(k) / 7 * 2 * Double.pi + p.t * 0.8
            let r: Double = 6 * cloud
            let x = 52 + Int(cos(a) * r), y = 34 + Int(sin(a) * r * 0.7)
            c.circle(x, y, Int(3 + 3 * cloud + noise(i + k) * 1.5), C(0x0A0A10, 0.55 * cloud))
        }
        c.circle(52, 34, Int(7 * cloud), C(0x050508, 0.7 * cloud))
    }
    // Hooty: on the shoulder, or out on a loop.
    if let s = sig, s > 0.22, s < 0.86 {
        let f = (s - 0.22) / 0.64
        let a: Double = Double.pi + f * 2 * Double.pi
        let x = 28 + cos(a) * 18 * sin(f * Double.pi), y = 20 + sin(a) * 6 - sin(f * Double.pi) * 6
        drawHooty(c, x: Int(x) - 3, y: Int(y) - 3, flap: Int(p.t * 12) % 2 + 1, facingLeft: f > 0.5)
    } else {
        drawHooty(c, x: 16, y: 18, flap: 0, facingLeft: false)
    }
    if throwing { return }
    if p.melee == nil { c.rect(38, 33, 3, 3, navy); return }
    drawPunch(c, angle: p.melee, trail: p.trail, arm: navy, fist: navyDark)
}

/// Hooty, Doctor Mid-Nite's owl, from (`x`, `y`): `flap` 0 wings folded, 1 up, 2 down.
private func drawHooty(_ c: PixelCanvas, x: Int, y: Int, flap: Int, facingLeft: Bool) {
    let brown = C(0x8A5A30), dark = C(0x5A3A1E), chest = C(0xD8B888), eye = C(0xFFD040), beak = C(0xE8A030)
    var rows: [String] = [
        "b....b",
        "bBBBBb",
        "BYKYKB",
        "BBBoBB",
        "bBccBb",
        ".BccB.",
        "..ff..",
    ]
    if facingLeft { rows = rows.map { String($0.reversed()) } }
    c.pattern(x, y, rows, ["B": brown, "b": dark, "Y": eye, "K": ink, "o": beak, "c": chest, "f": beak])
    if flap == 1 {
        c.pattern(x - 3, y + 1, ["bb.", ".bB", "..B"], ["b": dark, "B": brown])
        c.pattern(x + 6, y + 1, [".bb", "Bb.", "B.."], ["b": dark, "B": brown])
    } else if flap == 2 {
        c.pattern(x - 3, y + 4, ["..B", ".bB", "bb."], ["b": dark, "B": brown])
        c.pattern(x + 6, y + 4, ["B..", "Bb.", ".bb"], ["b": dark, "B": brown])
    }
}

// MARK: - Sandman

/// Sandman (Wesley Dodds): Clawd in a green suit with a white shirt and red tie, a short purple cape, a dark fedora
/// and the gas mask, two round goggle lenses and the filter snout hanging over his chest, and his gas gun with its
/// green canister. Signature: he sprays a cloud of sleeping gas ahead of him and the Zs drift up out of it.
private func drawSandman(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E6A3A), greenDark = C(0x1E4A28), cape = C(0x5A2A7A), capeEdge = C(0x3A1A52)
    let hat = C(0x2E2E36), hatDark = C(0x1C1C22), mask = C(0x7A8A72), maskDark = C(0x56644E)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge, extra: -1)
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, C(0x1A1A1E), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: mask, shade: maskDark, arm: green, eye: nil))
    // Fedora.
    c.pattern(15, 17, [
        "........HHHHHHHH........",
        ".......HHHHHhhHHHH......",
        "......HHHHHHHHHHHHH.....",
        "......HHHHHHHHHHHHH.....",
        "......BBBBBBBBBBBBB.....",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHh",
        "...dddddddddddddddddd...",
    ], ["H": hat, "h": hatDark, "B": C(0x6A2A2A), "d": hatDark])
    // Mask: lenses and the snout.
    c.pattern(18, 25, [
        "MMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMM",
        "MMKKKKKMMMMMMKKKKKMM",
        "MKLLWLLKMMMMKLLWLLKM",
        "MKLLLLLKMMMMKLLLLLKM",
        "MKLLLLLKMMMMKLLLLLKM",
        "MMKKKKKMMMMMMKKKKKMM",
        "MMMMMMMMmmmmMMMMMMMM",
        "MMMMMMMmFFFFmMMMMMMM",
    ], ["M": mask, "m": maskDark, "K": C(0x2A2E28), "L": C(0xC8D890), "W": white, "F": C(0x3A443A)])
    // Suit, shirt and tie, the filter canister hanging in front.
    c.rect(18, 34, 20, 4, green)
    c.rect(37, 34, 1, 4, greenDark)
    c.pattern(25, 34, ["WW..WW", ".WRRW.", "..RR..", "..RR.."], ["W": C(0xF0F0EC), "R": C(0xB02A2A)])
    c.pattern(26, 33, [".FF.", "FffF", ".FF."], ["F": C(0x3A443A), "f": C(0x8A9488)])
    c.rect(15, 33, 3, 3, green)
    let sig = p.signature
    let spraying = sig.map { $0 > 0.08 && $0 < 0.9 } ?? false
    c.oy += spraying ? -1 : p.gunY
    c.pattern(40, 29, ["..gg....", "KKKKKKKK", "KKTKKKK.", "KK......", "KK......"],
              ["K": C(0x2A2A30), "T": C(0x8A8F9C), "g": C(0x8AD86A)])
    c.rect(38, 33, 3, 3, green)
    c.oy -= spraying ? -1 : p.gunY
    guard let s = sig, s > 0.08 else { return }
    // The gas cloud, rolling out from the muzzle and thinning.
    let f = min(1, (s - 0.08) / 0.5)
    let fade: Double = s > 0.75 ? max(0, 1 - (s - 0.75) / 0.25) : 1
    for k in 0..<6 {
        let u = min(1, f * 1.3 - Double(k) * 0.08)
        guard u > 0 else { continue }
        let x = 49 + Int(u * 14 * (0.5 + noise(k * 7) * 0.6)), y = 30 - Int(u * 6 * noise(k * 3)) + (k % 2) * 3
        c.circle(x, y, 2 + Int(u * 3), C(0x8AD86A, 0.35 * fade))
        c.circle(x, y, 1 + Int(u * 2), C(0xC8F0B0, 0.3 * fade))
    }
    if s > 0.35 {
        for k in 0..<3 {
            let z = frac((s - 0.35) * 1.8 - Double(k) * 0.3)
            guard z > 0 && z < 0.95 else { continue }
            let x = 52 + k * 5 + Int(sin(z * 6) * 1.5), y = 26 - Int(z * 16)
            c.pattern(x, y, ["ZZZZ", "..Z.", ".Z..", "ZZZZ"], ["Z": C(0xE8FFE0, (1 - z) * fade)])
        }
    }
}

// MARK: - Mister Terrific

/// Mister Terrific (Michael Holt): bald Clawd with the black T-mask across his eyes and down his nose, white lenses,
/// a black jacket with a white collar and a silver zip, and three silver T-spheres floating round his head. He fights
/// with his fists. Signature: he raises a hand, the T-spheres fly out into a triangle and throw up a holographic
/// screen of data between them.
private func drawMrTerrific(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x18181E), blackLight = C(0x3A3A46), wht = C(0xF2F2F4)
    let sig = p.signature
    let holo: Double = sig.map { habitArc($0, hold: 0.55) } ?? 0
    drawLegs(c, Look(leg: C(0x2A2A32)), step: p.step)
    drawBoots(c, black, step: p.step, rows: 2)
    c.oy += p.breathe
    let up = holo > 0.05 ? 4 : 0
    drawBody(c, Look(arm: black), armRight: up)
    // The T-mask.
    c.rect(19, 28, 18, 2, black); c.rect(20, 30, 4, 1, black); c.rect(32, 30, 4, 1, black)
    c.rect(27, 30, 2, 3, black)
    c.rect(22, 28, 2, 1, wht); c.rect(32, 28, 2, 1, wht)
    c.rect(20, 26, 4, 1, C(0xE89A7A))                                 // shine on the bald head
    // Jacket, open at the collar, a silver zip.
    c.rect(18, 34, 20, 4, black)
    c.rect(37, 34, 1, 4, C(0x0E0E12))
    c.rect(26, 34, 4, 1, C(0x5A5E68))
    c.px(24, 34, wht); c.px(25, 35, wht); c.px(31, 34, wht); c.px(30, 35, wht)
    c.rect(28, 35, 1, 3, C(0xA8AEB8))
    c.rect(19, 36, 2, 1, blackLight); c.rect(34, 36, 2, 1, blackLight)
    c.rect(15, 33, 3, 3, black)
    // The T-spheres: orbiting, or flown out to hold the screen.
    let targets: [(Double, Double)] = [(45, 13), (59, 13), (52, 29)]
    var spots: [(Double, Double)] = []
    for i in 0..<3 {
        let a: Double = p.lt * 1.6 + Double(i) * 2.0944
        let ox: Double = 28 + cos(a) * 15, oy: Double = 17 + sin(a) * 2.5
        let tx = targets[i].0, ty = targets[i].1
        spots.append((ox + (tx - ox) * holo, oy + (ty - oy) * holo))
    }
    if holo > 0.6 {
        let k = (holo - 0.6) / 0.4
        // The hologram between them: a pale blue screen with scrolling lines and a T.
        c.rect(46, 15, 13, 12, C(0x6AC8FF, 0.18 * k))
        for r in 0..<4 {
            let y = 16 + (r * 3 + Int(p.t * 6)) % 11
            c.rect(47, y, 4 + Int(noise(r + Int(p.t * 2)) * 6), 1, C(0xBFE8FF, 0.6 * k))
        }
        c.rect(53, 17, 5, 1, C(0xE8F8FF, 0.8 * k)); c.rect(55, 18, 1, 5, C(0xE8F8FF, 0.8 * k))
        for i in 0..<3 {
            c.glowLine(spots[i].0, spots[i].1, spots[(i + 1) % 3].0, spots[(i + 1) % 3].1,
                       core: C(0xBFE8FF, 0.5 * k), glow: C(0x6AC8FF, 0.25 * k), coreR: 0.3, glowR: 1)
        }
    }
    for (x, y) in spots { drawTSphere(c, x: Int(x.rounded()) - 2, y: Int(y.rounded()) - 2, t: p.t) }
    if up > 0 { return }
    if p.melee == nil { c.rect(38, 33, 3, 3, black); return }
    drawPunch(c, angle: p.melee, trail: p.trail, arm: black, fist: black)
}

/// A T-sphere: a little silver ball with a blue light and a dark T on it, 4 × 4 from (`x`, `y`).
private func drawTSphere(_ c: PixelCanvas, x: Int, y: Int, t: Double) {
    c.pattern(x, y, [".SS.", "SWTS", "STTd", ".dd."], ["S": C(0xB8BEC8), "W": white, "T": C(0x2A2A32), "d": C(0x7A808C)])
    if Int(t * 3 + Double(x)) % 3 != 0 { c.px(x + 3, y + 1, C(0x6AC8FF)) }
}

// MARK: - Shared helpers

private let clear = C(0x000000, 0)

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from the hand along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * Double.pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// A punch: the arm thrown out along `angle` (nil: nothing, the arm stays a nub), a fist on the end and faint
/// fists where a fast swing just was.
private func drawPunch(_ c: PixelCanvas, angle: Double?, trail: [Double], arm: Px, fist: Px, reach: Double = 7,
                       size: Int = 3, from h: (x: Double, y: Double) = Sprite.hand) {
    guard let angle else { return }
    for (i, a) in trail.enumerated() {
        let e = along(a, reach, from: h)
        c.rect(Int(e.x.rounded()) - size / 2, Int(e.y.rounded()) - size / 2, size, size, fist.alpha(0.35 / Double(i + 1)))
    }
    let e = along(angle, reach, from: h)
    bar(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - size / 2, Int(e.y.rounded()) - size / 2, size, size, fist)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
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

/// Draws `art` on a fresh canvas of sprite size, its origin at (0, 0).
private func offscreen(_ art: (PixelCanvas) -> Void) -> PixelCanvas {
    let o = PixelCanvas(Sprite.width, Sprite.height)
    art(o)
    return o
}

/// `o` drawn onto `c`, scaled by `scale` so that its point `from` lands on `to`.
private func stamp(_ c: PixelCanvas, _ o: PixelCanvas, scale: Double = 1,
                   from: (x: Double, y: Double) = (28, 43.5), to: (x: Double, y: Double)? = nil) {
    let to = to ?? from
    for y in 0..<o.h {
        for x in 0..<o.w {
            let sx = Int(floor(from.x + (Double(x) + 0.5 - to.x) / scale))
            let sy = Int(floor(from.y + (Double(y) + 0.5 - to.y) / scale))
            guard sx >= 0, sy >= 0, sx < o.w, sy < o.h else { continue }
            let i = (sy * o.w + sx) * 4
            guard o.buf[i + 3] > 0 else { continue }
            c.px(x, y, unpremultiplied(o, i))
        }
    }
}
