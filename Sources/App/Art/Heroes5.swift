import Foundation

// Heroes: the speedsters and the Teen Titans. Every one is Clawd in costume: cowls, helmets, hair and hoods drawn over
// the blocky body; where a face shows, it's Clawd's own orange (Starfire's a shade more golden). The speedsters fight
// with a blur of punches, lightning crackling off them, and leave speed lines behind when they run.

let heroes5: [Companion: Persona] = [
    .wallyWest: Persona(name: "Wally West", weapon: .melee, headTop: 21, signature: 2.6, callout: "I'm the fastest man alive.",
                  draw: drawWallyWest),
    .jayGarrick: Persona(name: "Jay Garrick", weapon: .melee, headTop: 17, signature: 2.8,
                  draw: drawJayGarrick),
    .impulse: Persona(name: "Impulse", weapon: .melee, headTop: 9, signature: 3.2,
                  draw: drawImpulse),
    .jesseQuick: Persona(name: "Jesse Quick", weapon: .melee, headTop: 20, signature: 3.2, callout: "3X2(9YZ)4A!",
                  draw: drawJesseQuick),
    .raven: Persona(name: "Raven", weapon: .magic, motion: .hover, magic: Magic(core: C(0xF0D8FF), glow: C(0x7A2AD8), jagged: false),
                  headTop: 19, signature: 3.4, callout: "Azarath Metrion Zinthos!",
                  draw: drawRaven),
    .beastBoy: Persona(name: "Beast Boy", weapon: .melee, headTop: 20, signature: 3.4, callout: "Dude!",
                  draw: drawBeastBoy),
    .starfire: Persona(name: "Starfire", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xEFFFD0), glow: C(0x6AE83A)),
                  muzzle: (43, 34), handGun: false, headTop: 18, signature: 3.0, callout: "Glorious!",
                  draw: drawStarfire),
    .wonderGirl: Persona(name: "Wonder Girl", weapon: .melee, motion: .fly, headTop: 19, signature: 3.0, callout: "Titans, together!",
                  draw: drawWonderGirl),
    .aqualad: Persona(name: "Aqualad", weapon: .melee, headTop: 22, signature: 3.2,
                  draw: drawAqualad),
    .arsenal: Persona(name: "Arsenal", weapon: .ranged, shot: .arrow, muzzle: (46, 34), handGun: false, headTop: 15, signature: 3.0,
                  draw: drawArsenal),
]

// MARK: - Speedster pieces

/// What every speedster does round its own art: speed lines streaming off behind while it runs, lightning crackling
/// off it while it runs or fights.
private func speedster(_ c: PixelCanvas, _ p: Pose, lines: [Px], seed: Int, _ art: (PixelCanvas) -> Void) {
    if p.walking { drawSpeedLines(c, t: p.t, cols: lines) }
    art(c)
    if p.walking || (p.mode == .working && p.melee != nil) { drawCrackle(c, t: p.t, seed: seed) }
}

/// Lightning crackling off a speedster: `n` short forked sparks flickering round the body.
private func drawCrackle(_ c: PixelCanvas, t: Double, seed: Int, n: Int = 2,
                         core: Px = C(0xFFFBE0), glow: Px = C(0xFFC81E)) {
    let f = Int(t * 15) * 13 + seed * 101
    for b in 0..<n {
        let i = f + b * 37
        var x: Double = 12 + noise(i + 1) * 32, y: Double = 19 + noise(i + 2) * 21
        for k in 0..<3 {
            let nx: Double = x + (noise(i + 3 + k) - 0.5) * 5
            let ny: Double = y + 0.5 + noise(i + 7 + k) * 2
            c.glowLine(x, y, nx, ny, core: core, glow: glow, coreR: 0.3, glowR: 1)
            x = nx; y = ny
        }
    }
}

/// Speed lines streaming off behind a running speedster, in its colours.
private func drawSpeedLines(_ c: PixelCanvas, t: Double, cols: [Px]) {
    let ys: [Int] = [24, 28, 32, 36, 40]
    for (i, y) in ys.enumerated() {
        let len = 5 + Int(noise(Int(t * 20) + i * 3) * 9)
        c.rect(15 - len, y, len, 1, cols[i % cols.count].alpha(0.65))
    }
}

/// A speedster's punches: the arm out along `angle` with a fist on the end, faint fists where the swing just was,
/// a couple of blurred extra fists flickering round it and speed lines behind.
private func drawFlurry(_ c: PixelCanvas, angle: Double, trail: [Double], t: Double, arm: Px, fist: Px, blur: Px) {
    let h = Sprite.hand
    let k = Int(t * 24)
    for j in 0..<2 {
        let a: Double = angle + (noise(k * 3 + j) - 0.5) * 60
        let e = along(a, 4 + noise(k * 5 + j) * 4)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, blur.alpha(0.4))
    }
    for (i, a) in trail.enumerated() {
        let e = along(a, 6)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, blur.alpha(0.4 / Double(i + 1)))
    }
    let e = along(angle, 6)
    bar(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist)
    let r: Double = angle * .pi / 180
    let ux = cos(r), uy = sin(r)
    for j in [-1.0, 1.0] {
        let sx: Double = e.x - ux * 3 - uy * 2.5 * j, sy: Double = e.y - uy * 3 + ux * 2.5 * j
        bar(c, sx, sy, sx - ux * 3, sy - uy * 3, C(0xFFFFFF, 0.6), 0.4)
    }
}

// MARK: - Wally West

/// Wally West: the Flash in red, the cowl with yellow lightning-bolt wings over the ears, the jaw and eyes showing,
/// the white circle with the yellow bolt on his chest, a yellow belt and yellow boots. Fights with a blur of punches.
/// Signature: he vibrates his molecules, shaking into a red smear of afterimages that crackle with lightning, nearly
/// see-through at the peak, then settles.
private func drawWallyWest(_ c: PixelCanvas, _ p: Pose) {
    let yellow = C(0xF4C430)
    guard let s = p.signature, s > 0.06, s < 0.94 else {
        speedster(c, p, lines: [C(0xC8202A), yellow], seed: 1) { wallyArt($0, p) }
        return
    }
    let k = habitArc((s - 0.06) / 0.88, hold: 0.5)
    let j = Int(p.t * 60) % 2 == 0 ? 1 : -1
    let spread = Int((k * 3).rounded())
    if spread > 0 {
        layer(c, alpha: 0.3 * k, dx: -spread * j) { wallyArt($0, p) }
        layer(c, alpha: 0.3 * k, dx: spread * j) { wallyArt($0, p) }
    }
    layer(c, alpha: 1 - 0.3 * k, dx: k > 0.3 ? j : 0) { wallyArt($0, p) }
    drawCrackle(c, t: p.t, seed: 1, n: 1 + Int((k * 3).rounded()))
}

private func wallyArt(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redDark = C(0x8A141C), yellow = C(0xF4C430), yellowDark = C(0xC8961E)
    let look = Look(body: red, shade: redDark, leg: red, arm: red, eye: nil)
    drawLegs(c, look, step: p.step)
    drawBoots(c, yellow, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, look)
    // The cowl's dome, and the lightning wings over the ears.
    c.pattern(18, 23, ["...RRRRRRRRRRRRRR...", ".RRRRRRRRRRRRRRRRRr.", "RRRRRRRRRRRRRRRRRRRr"], ["R": red, "r": redDark])
    let ear: [String] = ["Y.....", ".YY...", "..YYY.", ".YYYYY", "...yYY", ".....y"]
    c.pattern(12, 22, ear, ["Y": yellow, "y": yellowDark])
    c.pattern(38, 22, ear.map { String($0.reversed()) }, ["Y": yellow, "y": yellowDark])
    // Eyes through the cowl, the jaw and a grin.
    c.rect(21, 28, 4, 4, clawdOrange); c.rect(31, 28, 4, 4, clawdOrange)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 32, 14, 2, clawdOrange); c.rect(21, 33, 14, 1, clawdShade)
    c.rect(26, 32, 4, 1, clawdShade)
    // The emblem and the belt.
    c.pattern(25, 34, [".WWWW.", "WWYYWW", "WYYWWW", ".WWWW."], ["W": white, "Y": yellow])
    c.rect(18, 37, 20, 1, yellow); c.rect(37, 37, 1, 1, yellowDark)
    c.rect(15, 35, 3, 1, yellow)
    if let a = p.melee {
        drawFlurry(c, angle: a, trail: p.trail, t: p.t, arm: red, fist: red, blur: C(0xFFD25A))
    } else {
        c.rect(38, 35, 3, 1, yellow)
    }
}

// MARK: - Jay Garrick

/// Jay Garrick: the first Flash, in his winged Mercury helmet (a silver bowl with little wings on the sides), no mask,
/// a red shirt with the yellow lightning bolt across it, blue trousers and red boots. Fights with a blur of punches.
/// Signature: a gentleman's hat-tip, he lifts the helmet off his grey hair, it catches the light, and he puts it back.
private func drawJayGarrick(_ c: PixelCanvas, _ p: Pose) {
    speedster(c, p, lines: [C(0xC02028), C(0xF4C430), C(0x2A4A9A)], seed: 2) { jayArt($0, p) }
}

private func jayArt(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC02028), redDark = C(0x841418), blue = C(0x2A4A9A), yellow = C(0xF4C430)
    let silver = C(0xC0C4CC), light = C(0xEEF0F4), dark = C(0x7A808C), hair = C(0xB4B0A8), hairDark = C(0x86827A)
    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, red, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: red))
    let tip = p.signature.flatMap { $0 > 0.06 && $0 < 0.94 ? habitArc(($0 - 0.06) / 0.88, hold: 0.45) : nil } ?? 0
    let up = Int((tip * 6).rounded())
    if up > 1 {
        // Grey hair, neatly combed, under the helmet.
        c.pattern(18, 22, sym(["....HHHHHH", "..HHHhHHHH", ".HHHHHHHHH", "HHHH......"]), ["H": hair, "h": hairDark])
    }
    c.pattern(11, 17 - up, sym([
        "............SSSSS",
        ".........SSSSSLLS",
        "........SSSSLLSSS",
        "...WW...SSSLSSSSS",
        "....WWWwSSSSSSSSS",
        ".....WWwSSSSSSSSS",
        "......wwSSSSSSSSS",
        "...dddddddddddddd",
    ]), ["S": silver, "L": light, "W": light, "w": dark, "d": dark])
    if tip > 0.85 { twinkle(c, 22, 18 - up) }
    c.rect(26, 33, 4, 1, clawdShade)
    // Red shirt with the bolt.
    c.rect(18, 34, 20, 4, red)
    c.pattern(18, 34, ["YYYYYY..............", "...YYYYYYYY.........", "........YYY.........", ".........YYYYYYYYYY."], ["Y": yellow])
    c.rect(18, 37, 20, 1, redDark)
    c.rect(37, 34, 1, 3, redDark)
    if tip > 0.05 {
        // The hand up at the brim.
        bar(c, 39, 34, 40.5, Double(25 - up), red, 1.2)
        c.rect(39, 23 - up, 3, 3, red)
        return
    }
    if let a = p.melee {
        drawFlurry(c, angle: a, trail: p.trail, t: p.t, arm: red, fist: red, blur: C(0xFFD25A))
    }
}

// MARK: - Impulse

/// Impulse (Bart Allen): an enormous mop of brown hair bursting out of the top of his mask, a red mask with yellow
/// lenses, a white top with a red bolt, red arms and legs and big white boots. Fights with a blur of punches.
/// Signature: bored already, he tears off round the block, a red-and-white streak looping round where he stood twice,
/// and he's back with a giant soda, slurping, hair even wilder.
private func drawImpulse(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), whiteSuit = C(0xF0F0F4)
    guard let s = p.signature, s > 0.08, s < 0.96 else {
        speedster(c, p, lines: [red, whiteSuit], seed: 3) { impulseArt($0, p) }
        return
    }
    if s < 0.55 {
        // Gone: a puff of dust where he stood, and the streak looping round it.
        let k = (s - 0.08) / 0.47
        if k < 0.4 {
            let d = k / 0.4
            for i in 0..<5 { c.px(19 + i * 4 + Int(d * 3), 42 - Int(d * 4) - i % 2, C(0xD8D0C0).alpha(0.8 * (1 - d))) }
        }
        let head: Double = k * 4 * .pi
        for i in 0..<14 {
            let a: Double = head - Double(i) * 0.12
            let x: Double = 28 + cos(a) * 24, y: Double = 33 + sin(a) * 9
            let col = i < 2 ? C(0x7A4A2A) : (i % 3 == 0 ? red : whiteSuit)
            c.glowLine(x, y, x, y, core: col.alpha(1 - Double(i) / 15), glow: C(0xFFC81E, 0.4 * (1 - Double(i) / 14)),
                       coreR: 1.2, glowR: 2)
        }
        return
    }
    impulseArt(c, p, soda: (s - 0.55) / 0.41)
}

private func impulseArt(_ c: PixelCanvas, _ p: Pose, soda: Double? = nil) {
    let red = C(0xC8202A), redDark = C(0x8A141C), suit = C(0xF0F0F4), suitShade = C(0xC0C4CC), lens = C(0xF4D040)
    let hair = C(0x7A4A2A), hairDark = C(0x52301A), hairLight = C(0x9A6A3E)
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, suit, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: red))
    // The hair: an explosion of it.
    let wild = soda != nil && Int(p.t * 10) % 2 == 0 ? 1 : 0
    c.pattern(8 - wild, 11 - wild, [
        "..........H....H.....H..........",
        ".......H...HH...HH...HHH........",
        "....H...HHHHHHHHHHHHHHHHH.......",
        "..HHHHHHHHHHHHHHHHHHHHHHHHH.....",
        "HHHHHHHHHHHHhhHHHHHHHHlHHHHH....",
        "..HHHHHllHHHHHHHHHHHHHHHHHHHH...",
        "HHHHHHHHHHHHHHHHHHHhhHHHHHHHHH..",
        ".HHHHHHHHhhHHHHHHHHHHHHHlHHHHH..",
        "HHHHHHHHHHHHHHHllHHHHHHHHHHHHHH.",
        "..HHHhhHHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHhhHHHHHHHHHH",
        ".HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHhhHHHHHHHHHHHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHHHHHHHHHHHH..",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHH.H...H....H...HHHH...",
        "HHHHHHHH....................H...",
        "..HHHHH.........................",
        ".HHHHH..........................",
        "...HHH..........................",
        "....H...........................",
    ], ["H": hair, "h": hairDark, "l": hairLight])
    // Mask across the eyes, yellow lenses.
    c.rect(18, 28, 20, 4, red)
    c.rect(21, 29, 4, 2, lens); c.rect(31, 29, 4, 2, lens)
    c.px(22, 29, white); c.px(32, 29, white)
    c.rect(26, 33, 4, 1, clawdShade)
    // White top with the red bolt.
    c.rect(18, 34, 20, 4, suit)
    c.pattern(25, 34, ["..RR", ".RR.", "RRRR", ".RR."], ["R": red])
    c.rect(37, 34, 1, 4, suitShade)
    c.rect(18, 37, 20, 1, redDark)
    if let k = soda {
        // The giant soda, slurped.
        c.rect(38, 30, 3, 3, red)
        c.rect(39, 25, 5, 7, white); c.rect(39, 27, 5, 2, red); c.rect(43, 25, 1, 7, suitShade)
        c.rect(39, 24, 5, 1, suitShade)
        bar(c, 40, 24, 31, 32.5, C(0xF07AA0), 0.5)
        if Int(k * 12) % 2 == 0 { c.px(32, 31, C(0xFFFFFF, 0.8)); c.px(33, 29, C(0xFFFFFF, 0.6)) }
        return
    }
    if let a = p.melee {
        drawFlurry(c, angle: a, trail: p.trail, t: p.t, arm: red, fist: red, blur: C(0xFFF0F0))
    }
}

// MARK: - Jesse Quick

/// Jesse Quick: a blonde ponytail streaming out behind, a gold suit with a red lightning bolt and red shoulders, red
/// gloves and legs, gold boots. Fights with a blur of punches. Signature: she says the speed formula, and it lights up
/// over her head one glowing symbol at a time, 3X2(9YZ)4A, then lightning runs all over her.
private func drawJesseQuick(_ c: PixelCanvas, _ p: Pose) {
    speedster(c, p, lines: [C(0xE8B030), C(0xB81E28)], seed: 4) { jesseArt($0, p) }
    guard let s = p.signature, s > 0.06, s < 0.96 else { return }
    let n = Int(min(10, (s - 0.06) / 0.5 * 10))
    let fade: Double = s > 0.86 ? (0.96 - s) / 0.1 : 1
    let flare = s > 0.6 && s < 0.86
    drawFormula(c, count: n, x: 10, y: 8 + p.breathe, alpha: fade, bright: flare)
    if s > 0.56 { drawCrackle(c, t: p.t, seed: 4, n: 3) }
}

private func jesseArt(_ c: PixelCanvas, _ p: Pose) {
    let gold = C(0xE8B030), goldDark = C(0xB08020), red = C(0xB81E28), redDark = C(0x7A1018)
    let hair = C(0xF0D070), hairDark = C(0xC0A040)
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, gold, step: p.step, rows: 3)
    c.oy += p.breathe
    // The ponytail, out behind her.
    let flick = Int(p.t * 8) % 2
    c.pattern(7, 21, flick == 0 || !p.walking
              ? ["...HHHH...", ".HHHHHHHH.", "HHHhhHHHHH", "..HHHHhh..", "....hHH...", "......h..."]
              : ["..........", "HHHHHHHHH.", "HhhHHHHHHH", ".HHHHHhh..", "...hHHH...", "..........."],
              ["H": hair, "h": hairDark])
    drawBody(c, Look(arm: gold))
    c.pattern(16, 20, [
        "......HHHHHHHHHH........",
        "....HHHHHHHHHHHHHH......",
        "...HHHHHhHHHHHHHHHHH....",
        "..HHHHHHHHHHHhHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHH..",
        ".HHHHH.HHH.......hHHHH..",
        ".HHH...............HHH..",
        ".HHh...............hHH..",
        ".HH.................HH..",
        "..H.................H...",
    ], ["H": hair, "h": hairDark])
    c.rect(18, 26, 20, 1, C(0xC8202A))                     // a red headband
    // Talking (the formula), or a grin.
    if let s = p.signature, s > 0.06, s < 0.56, Int(p.t * 9) % 2 == 0 {
        c.rect(27, 32, 2, 2, ink)
    } else {
        c.rect(26, 33, 4, 1, clawdShade)
    }
    // Gold suit, red shoulders, the bolt.
    c.rect(18, 34, 20, 4, gold)
    c.pattern(26, 34, ["..RR", ".RR.", "RRRR", ".R.."], ["R": red])
    c.rect(37, 34, 1, 4, goldDark)
    c.rect(18, 37, 20, 1, redDark)
    c.rect(15, 35, 3, 1, red)
    if let a = p.melee {
        drawFlurry(c, angle: a, trail: p.trail, t: p.t, arm: gold, fist: red, blur: C(0xFFE07A))
    } else {
        c.rect(38, 35, 3, 1, red)
    }
}

/// The speed formula over her head: the first `count` of its symbols, glowing gold.
private func drawFormula(_ c: PixelCanvas, count: Int, x: Int, y: Int, alpha: Double, bright: Bool) {
    let glyphs: [Character: [String]] = [
        "3": ["XXX", "..X", ".XX", "..X", "XXX"], "X": ["X.X", "X.X", ".X.", "X.X", "X.X"],
        "2": ["XXX", "..X", "XXX", "X..", "XXX"], "(": [".X", "X.", "X.", "X.", ".X"],
        "9": ["XXX", "X.X", "XXX", "..X", "XXX"], "Y": ["X.X", "X.X", ".X.", ".X.", ".X."],
        "Z": ["XXX", "..X", ".X.", "X..", "XXX"], ")": ["X.", ".X", ".X", ".X", "X."],
        "4": ["X.X", "X.X", "XXX", "..X", "..X"], "A": [".X.", "X.X", "XXX", "X.X", "X.X"],
    ]
    let core = (bright ? C(0xFFFBE0) : C(0xFFE07A)).alpha(alpha * 0.97)
    let glow = C(0xFFA81E).alpha(alpha * (bright ? 0.3 : 0.15))
    var cx = x
    for (i, ch) in "3X2(9YZ)4A".enumerated() {
        guard let g = glyphs[ch] else { continue }
        if i < count {
            let w = Double(g[0].count)
            c.glowLine(Double(cx) + w / 2, Double(y) + 2.5, Double(cx) + w / 2, Double(y) + 2.5,
                       core: C(0, 0), glow: glow, coreR: 0, glowR: 3)
            c.pattern(cx, y, g, ["X": core])
        }
        cx += g[0].count + 1
    }
}

// MARK: - Raven

/// Raven: the deep blue hooded cloak drawn round her and pinned at the throat with a red gem, her face in the hood with
/// the red chakra gem on her brow, the cloak hanging below her as she hovers. Her magic is dark violet energy from the
/// raised hand. Signature: Azarath Metrion Zinthos, her eyes go white, both hands come up and her soul-self rises out of
/// her, a huge dark raven spreading its wings over her head, then sinks back.
private func drawRaven(_ c: PixelCanvas, _ p: Pose) {
    let cloak = C(0x2C2E7A), cloakDark = C(0x1C1C50), leo = C(0x1E1E3A), gem = C(0xE0203A), gold = C(0xC8A040)
    let soul = p.signature.flatMap { $0 > 0.05 && $0 < 0.95 ? habitArc(($0 - 0.05) / 0.9, hold: 0.45) : nil } ?? 0
    if soul > 0.02 {
        c.oy += p.breathe
        drawSoulSelf(c, k: soul, t: p.t)
        c.oy -= p.breathe
    }
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.7, color: cloak, edge: cloakDark, extra: 1.5)
    drawLegs(c, Look(leg: leo), step: p.step)
    drawBoots(c, cloak, step: p.step, rows: 2)
    c.oy += p.breathe
    let up = soul > 0.1 ? 4 : 0
    drawBody(c, Look(arm: cloak), armLeft: up, armRight: max(p.armRaise, up))
    drawHood(c, cloak, cloakDark)
    c.rect(19, 19, 2, 1, C(0x4446A0)); c.rect(17, 21, 1, 3, C(0x4446A0))   // light on the hood
    c.rect(27, 27, 2, 1, gem)                                              // the chakra gem
    if soul > 0.25 {
        c.rect(22, 29, 2, 3, white); c.rect(32, 29, 2, 3, white)
        c.glowLine(23, 30.5, 33, 30.5, core: C(0, 0), glow: C(0xF0D8FF, 0.5 * soul), coreR: 0, glowR: 2)
    }
    // The cloak closed at the throat over the leotard, the gem belt.
    c.rect(18, 33, 20, 5, cloak)
    c.rect(28, 34, 1, 4, cloakDark); c.rect(18, 37, 20, 1, cloakDark)
    c.rect(26, 33, 4, 1, gold); c.rect(27, 33, 2, 1, gem)
    if p.zap != nil || soul > 0.1 {
        let hand = (x: Sprite.hand.x, y: Sprite.hand.y - Double(max(p.armRaise, up)))
        c.glowLine(hand.x, hand.y, hand.x, hand.y, core: C(0xF0D8FF, 0.8), glow: C(0x7A2AD8), coreR: 0.6, glowR: 2.2)
        if soul > 0.1 { c.glowLine(16.5, 30.5, 16.5, 30.5, core: C(0xF0D8FF, 0.8), glow: C(0x7A2AD8), coreR: 0.6, glowR: 2.2) }
    }
}

/// Raven's soul-self: a great dark raven, white-eyed, rising over her and spreading its wings as `k` goes 0…1.
private func drawSoulSelf(_ c: PixelCanvas, k: Double, t: Double) {
    let dark = C(0x1A0A30).alpha(0.88 * k), edge = C(0x9A4AFF).alpha(0.55 * k)
    let rise: Double = (1 - k) * 14
    let cx = 28.0, cy: Double = 11 + rise
    let span: Double = 4 + 22 * k, beat: Double = sin(t * 5) * 2 * k
    // Wings, each a pair of triangles, feathered at the tips.
    for side in [-1.0, 1.0] {
        let root = (cx + side * 3, cy - 1), tip = (cx + side * span, cy - 7 * k + beat)
        let back = (cx + side * span * 0.55, cy + 6), low = (cx + side * 3, cy + 5)
        tri(c, root, tip, back, dark); tri(c, root, back, low, dark)
        c.glowLine(root.0, root.1, tip.0, tip.1, core: edge, glow: edge.alpha(0.4), coreR: 0.4, glowR: 1.4)
        for f in 0..<3 {
            let u: Double = 0.55 + Double(f) * 0.15
            let fx: Double = cx + side * span * u, fy: Double = cy - 7 * k * u + beat * u + 2
            bar(c, fx, fy, fx - side * 1.5, fy + 4, dark, 0.7)
        }
    }
    // Body, tail, head and beak.
    c.ellipse(Int(cx), Int(cy) + 1, 4, 6, dark)
    tri(c, (cx - 3, cy + 6), (cx + 3, cy + 6), (cx, cy + 11), dark)
    c.ellipse(Int(cx) + 1, Int(cy) - 6, 3, 3, dark)
    tri(c, (cx + 3, cy - 7), (cx + 3, cy - 4), (cx + 7, cy - 5), dark)
    c.glowLine(cx + 2, cy - 7, cx + 2, cy - 7, core: C(0xFFFFFF, k), glow: C(0xD8B0FF, 0.7 * k), coreR: 0.6, glowR: 1.8)
}

// MARK: - Beast Boy

/// Beast Boy: green all over, spiky dark green hair, pointed ears and a fang, the purple and black Titans suit and grey
/// boots. In a fight his arm turns into a tiger's paw and swipes. Signature: in a puff he turns into a green tiger,
/// stripes and all, roars, and puffs back into himself.
private func drawBeastBoy(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.04, s < 0.96 else { beastBoyArt(c, p); return }
    let puffIn = s < 0.16, puffOut = s > 0.84
    if puffIn || puffOut {
        let k = puffIn ? (s - 0.04) / 0.12 : (s - 0.84) / 0.12
        if (puffIn && k < 0.5) || (puffOut && k > 0.5) { beastBoyArt(c, p) } else { drawTiger(c, p, roar: false) }
        drawPuff(c, k: k, t: p.t)
        return
    }
    drawTiger(c, p, roar: s > 0.42 && s < 0.66)
}

private func beastBoyArt(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x5AB040), greenDark = C(0x3E8A2A), hair = C(0x2A5A1A), hairLight = C(0x3E7A28)
    let purple = C(0x6A2E9A), purpleDark = C(0x4A1C70), black = C(0x1E1E26), boot = C(0x8A8E98)
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: purple))
    // Pointed ears and spiky hair.
    c.pattern(14, 25, ["G...", "GG..", ".GG.", "..GG"], ["G": green])
    c.pattern(38, 25, ["...G", "..GG", ".GG.", "GG.."], ["G": green])
    c.pattern(16, 19, [
        "...H...H....H....H......",
        "...HH..HH..HHH..HH..H...",
        "..HHHHHHHHHHHHHHHHHHH...",
        ".HHHHlHHHHHlHHHHHlHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHH.H...H.....H..HHH..",
        "..HH................H...",
    ], ["H": hair, "l": hairLight])
    // A grin with a fang.
    c.rect(25, 32, 6, 1, C(0x2A4A1A)); c.px(29, 33, white)
    // The suit: purple with black down the sides and a black belt.
    c.rect(18, 34, 20, 4, purple)
    c.rect(18, 34, 3, 4, black); c.rect(35, 34, 3, 4, black)
    c.rect(18, 37, 20, 1, black)
    c.rect(27, 34, 2, 3, purpleDark)
    c.rect(15, 33, 3, 3, purple); c.rect(15, 35, 3, 1, green)
    if let a = p.melee {
        drawPaw(c, angle: a, trail: p.trail)
    } else {
        c.rect(38, 35, 3, 1, green)
    }
}

/// The arm turned tiger's paw: green, striped, claws out, swung from the shoulder; a fast swing leaves claw marks.
private func drawPaw(_ c: PixelCanvas, angle: Double, trail: [Double]) {
    let s = (x: 38.5, y: 34.5)
    for (i, a) in trail.enumerated() {
        let e = along(a, 8, from: s)
        for k in [-1.5, 0.0, 1.5] {
            let r: Double = a * .pi / 180
            let nx: Double = -sin(r) * k, ny: Double = cos(r) * k
            c.glowLine(e.x + nx - cos(r) * 2, e.y + ny - sin(r) * 2, e.x + nx + cos(r) * 2, e.y + ny + sin(r) * 2,
                       core: white.alpha(0.4 / Double(i + 1)), glow: C(0xAAF07A).alpha(0.3 / Double(i + 1)), coreR: 0.3, glowR: 1)
        }
    }
    prop(c, at: s, angle: angle) { s in
        let green = C(0x5AB040), dark = C(0x2E6A20)
        s.rect(19, 19, 6, 3, green)
        s.px(21, 19, dark); s.px(23, 21, dark)
        s.rect(25, 18, 4, 5, green); s.rect(25, 22, 4, 1, dark)
        for y in [18, 20, 22] { s.px(29, y, white) }
    }
}

/// Beast Boy's green tiger, facing right: striped body, four legs, the tail curling up behind; `roar` opens its jaws.
private func drawTiger(_ c: PixelCanvas, _ p: Pose, roar: Bool) {
    let green = C(0x5AB040), dark = C(0x2E6A20), belly = C(0x9AD07A), shade = C(0x4A9434)
    let seated = seatedPose
    // Legs (tucked under when it lies down).
    if seated {
        c.rect(16, 40, 30, 3, green); c.rect(40, 41, 8, 2, green); c.rect(46, 42, 2, 1, dark)
    } else {
        let lx: [Int] = [17, 21, 36, 40]
        for (i, x) in lx.enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(x, 37, 3, lifted ? 5 : 6, i % 2 == 0 ? shade : green)
            c.rect(x, lifted ? 41 : 42, 3, 1, dark)
        }
    }
    c.oy += p.breathe + (seated ? 3 : 0)
    // The tail, curling up behind.
    c.pattern(7, 20, [".TTT.", "TT.TT", "TT...", "TTT..", ".TTT.", "..TTT", "...TTT", "....TTT", ".....TT"], ["T": green])
    c.rect(8, 20, 3, 1, dark); c.px(7, 22, dark); c.px(10, 24, dark); c.px(12, 26, dark)
    // Body, striped.
    c.rect(15, 28, 26, 10, green)
    c.rect(15, 28, 26, 1, shade)
    c.rect(17, 35, 22, 3, belly)
    c.rect(15, 37, 26, 1, shade)
    for x in [18, 23, 28, 33] {
        c.rect(x, 28, 3, 1, dark); c.rect(x + 1, 29, 2, 2, dark); c.rect(x + 2, 31, 1, 2, dark)
    }
    // Head: ears, striped brow, eye, cheek ruff, muzzle, nose and jaw.
    c.pattern(37, 18, [
        ".GG.......GG....",
        "GdGG.....GGdG...",
        "GGGGGGGGGGGGG...",
        "GGdGGdGGdGGGGG..",
        "GGGdGGdGGGGGGGG.",
        "GGGGGGGGKKGGGGG.",
        "GGGGGGGGKwGGMMMM",
        "dGGGGGGGGGGMMMMN",
        "GdGGGGGGGGGMMMMM",
        "WGGGGGGGGGGMMMMM",
        "WWGGGGGGGGGGMMMM",
        "WWWGGGGGGGGGGGG.",
        ".WWWGGGGGGGG....",
    ], ["G": green, "d": dark, "K": ink, "w": white, "M": belly, "N": ink, "W": belly])
    if roar {
        c.rect(48, 28, 5, 3, C(0x6A1A1A)); c.px(49, 28, white); c.px(52, 28, white)
        c.rect(48, 31, 5, 1, belly)
        for i in 0..<3 where Int(p.lt * 12 + Double(i)) % 3 != 0 {
            let r = 4 + i * 3
            for d in -1...1 { c.px(53 + r, 28 + d * (1 + i), C(0xFFFFFF, 0.7)) }
        }
    } else {
        c.rect(48, 28, 5, 1, dark)
    }
}

/// A puff of green-white smoke, the shape-change: billowing out and thinning as `k` goes 0…1.
private func drawPuff(_ c: PixelCanvas, k: Double, t: Double) {
    let r: Double = 4 + k * 14
    for i in 0..<9 {
        let a: Double = Double(i) * 0.7 + 0.3
        let x: Double = 30 + cos(a) * r * 1.2, y: Double = 32 + sin(a) * r * 0.7
        let col = (i % 2 == 0 ? C(0xE8F4E0) : C(0xAAD89A)).alpha(0.85 * (1 - k * k))
        c.ellipse(Int(x), Int(y), 3 + Int(noise(i) * 2), 2 + Int(noise(i + 9) * 2), col)
    }
}

// MARK: - Starfire

/// Starfire: golden-orange skin, a mane of long red hair flowing down past her waist, glowing green eyes, a silver
/// gorget with a green gem, a purple top and skirt, purple boots and silver bracers. Starbolts from her fists. In
/// flight she goes fist first, hair streaming. Signature: her eyes and hands blaze, she gathers a big starbolt over her
/// head and hurls it up and away.
private func drawStarfire(_ c: PixelCanvas, _ p: Pose) {
    let sig = p.signature.flatMap { $0 > 0.05 && $0 < 0.97 ? ($0 - 0.05) / 0.92 : nil }
    layer(c, lean: p.flying ? 4 : 0) { c in starfireArt(c, p, sig: sig) }
}

private func starfireArt(_ c: PixelCanvas, _ p: Pose, sig: Double?) {
    let skin = C(0xF0A048), skinShade = C(0xC87A30), hair = C(0xC8302A), hairDark = C(0x8A1C1A), hairLight = C(0xE85A3A)
    let purple = C(0x7A2AA8), purpleDark = C(0x521A74), silver = C(0xC8CCD4), green = C(0x6AE83A)
    let bolt = (core: C(0xEFFFD0), glow: C(0x6AE83A))
    // The hair behind her: falling down her back, or streaming out in flight.
    if p.flying {
        for y in 20...32 {
            let len = 7 + (y % 3) * 2 + Int((sin(p.t * 14 + Double(y)) * 1.5).rounded())
            c.rect(17 - len, y + p.breathe, len + 2, 1, y % 3 == 0 ? hairDark : hair)
        }
    } else {
        let tress: [String] = [
            ".HHHH", "HHHHH", "HHhHH", "HHHHH", "HhHHH", "HHHHh", "HHHHH", "HHhHH", ".HHHH", "HHHhH",
            ".HHHH", ".HHHH", "..HHH", "..HH.", "...H.",
        ]
        c.pattern(13, 25 + p.breathe, tress, ["H": hair, "h": hairDark])
        c.pattern(38, 25 + p.breathe, tress.map { String($0.reversed()) }, ["H": hair, "h": hairDark])
        }
    drawSuitLegs(c, p, purple, boot: purpleDark, bootRows: 4)
    c.oy += p.breathe
    var power = 0.0
    if let s = sig { power = s < 0.2 ? s / 0.2 : s < 0.85 ? 1 : max(0, 1 - (s - 0.85) / 0.15) }
    let throwing = sig.map { $0 > 0.7 } ?? false
    let up = power > 0.1 ? 5 : 0
    drawBody(c, Look(body: skin, shade: skinShade, arm: skin, eye: nil), armLeft: up, armRight: up)
    c.pattern(15, 19, [
        "........HHHHHHHHHH........",
        ".....HHHHHHllHHHHHHHH.....",
        "...HHHHHHHHHHHHHllHHHHH...",
        "..HHHllHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHH.HHHH.....hHHHHHHHH",
        "HHHh...............hHHHHHH",
        "HHH..................HHHH.",
        "HH....................HH..",
    ], ["H": hair, "h": hairDark, "l": hairLight])
    // Green eyes, brighter with her power up.
    let eye = power > 0.3 ? C(0xE8FFD0) : green
    c.rect(22, 29, 2, 3, eye); c.rect(32, 29, 2, 3, eye)
    if power > 0.3 {
        c.glowLine(23, 30, 23, 30, core: C(0, 0), glow: green.alpha(0.6), coreR: 0, glowR: 2.2)
        c.glowLine(33, 30, 33, 30, core: C(0, 0), glow: green.alpha(0.6), coreR: 0, glowR: 2.2)
    }
    c.rect(26, 32, 4, 1, skinShade)
    // Silver gorget with the gem, the purple top and skirt.
    c.rect(21, 33, 14, 1, silver); c.rect(27, 33, 2, 1, green)
    c.rect(19, 34, 18, 2, purple)
    c.rect(18, 36, 20, 2, purple); c.rect(18, 37, 20, 1, purpleDark)
    c.px(17, 37, purple); c.px(38, 37, purple)
    c.rect(15, 35 - up, 3, 1, silver)
    if power > 0.1 {
        c.rect(38, 35 - up, 3, 1, silver)
        for x in [16.5, 39.5] {
            c.glowLine(x, 33.5 - Double(up), x, 33.5 - Double(up), core: bolt.core, glow: bolt.glow, coreR: 0.8, glowR: 2.2)
        }
        guard let s = sig else { return }
        // The starbolt: gathered over her head, then hurled.
        if !throwing {
            let r: Double = 1 + 4 * power
            let y: Double = 14 - 2 * power
            c.glowLine(28, y, 28, y, core: bolt.core, glow: bolt.glow, coreR: r * 0.6, glowR: r + 2)
            for i in 0..<4 {
                let a: Double = p.t * 9 + Double(i) * .pi / 2
                c.px(Int(28 + cos(a) * (r + 3)), Int(y + sin(a) * (r + 3)), bolt.core)
            }
        } else {
            let k = min(1, (s - 0.7) / 0.18)
            let x: Double = 28 + k * 42, y: Double = 12 - k * 16
            c.glowLine(x - 6, y + 2.5, x, y, core: bolt.core, glow: bolt.glow, coreR: 2, glowR: 4)
        }
        return
    }
    if p.flying {
        c.rect(38, 31, 5, 3, skin); c.rect(38, 33, 3, 1, silver)
        c.glowLine(43, 32, 43, 32, core: bolt.core, glow: bolt.glow, coreR: 0.8, glowR: 2.4)
        return
    }
    c.oy += p.gunY
    c.rect(38, 35, 3, 1, silver)
    if p.fire != nil || p.ready || p.cheering {
        c.glowLine(41.5, 34.5, 41.5, 34.5, core: bolt.core, glow: bolt.glow, coreR: 0.7, glowR: 2.2)
    }
}

// MARK: - Wonder Girl

/// Wonder Girl (Cassie Sandsmark): long blonde hair, a red top with the gold double-W eagle, silver bracelets, blue
/// jeans and red boots, and the golden Lasso of Lightning, coiled at her hip until she lashes with it. She flies fist
/// first. Signature: she twirls the lasso in a wide ring over her head, crackling with Zeus' lightning, and cracks it
/// out in front of her.
private func drawWonderGirl(_ c: PixelCanvas, _ p: Pose) {
    layer(c, lean: p.flying ? 4 : 0) { c in wonderGirlArt(c, p) }
}

private func wonderGirlArt(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redDark = C(0x8A141C), gold = C(0xF0C040), jeans = C(0x3A5A9A), jeansDark = C(0x2A4278)
    let hair = C(0xF0D070), hairDark = C(0xC0A040), silver = C(0xD4D8E0)
    if p.flying {
        for y in 21...31 {
            let len = 5 + (y % 3) * 2 + Int((sin(p.t * 14 + Double(y)) * 1.2).rounded())
            c.rect(17 - len, y + p.breathe, len + 2, 1, y % 3 == 0 ? hairDark : hair)
        }
    } else {
        let tress: [String] = ["HHHH", "HHHH", "HhHH", "HhHH", "HhHH", "HHhH", "HHhH", "HHHH", ".HHH", ".HhH", "..HH", "..H."]
        c.pattern(14, 25 + p.breathe, tress, ["H": hair, "h": hairDark])
        c.pattern(38, 25 + p.breathe, tress.map { String($0.reversed()) }, ["H": hair, "h": hairDark])
    }
    drawSuitLegs(c, p, jeans, boot: red, bootRows: 3)
    c.oy += p.breathe
    let sig = p.signature.flatMap { $0 > 0.05 && $0 < 0.95 ? ($0 - 0.05) / 0.9 : nil }
    drawBody(c, Look(arm: red))
    c.pattern(15, 19, [
        ".......HHHHHHHHHHH........",
        ".....HHHHHHHHHHHHHHHH.....",
        "...HHHHHHhHHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHhHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHhHHHHHHHHHHHHHHHH",
        "HHHHH.HH.........hHHHHHHHH",
        "HHHh..................HHHH",
        "HHH....................HHH",
    ], ["H": hair, "h": hairDark])
    c.rect(26, 33, 4, 1, clawdShade)
    // Red top with the gold double W, a gold belt over the jeans.
    c.rect(18, 34, 20, 4, red)
    c.pattern(22, 34, ["G.G.GG.G.G", "GGGG..GGGG", ".G.G..G.G."], ["G": gold])
    c.rect(18, 37, 20, 1, jeansDark); c.rect(27, 37, 2, 1, gold)
    c.rect(37, 34, 1, 3, redDark)
    c.rect(15, 35, 3, 1, silver)
    if let s = sig {
        drawLassoTwirl(c, s: s, t: p.t)
        return
    }
    if let a = p.melee {
        drawLasso(c, angle: a, trail: p.trail, t: p.t)
        c.rect(38, 35, 3, 1, silver)
        return
    }
    drawCoil(c, x: 35, y: 35)
    if p.flying {
        c.rect(38, 31, 5, 3, red); c.rect(38, 33, 3, 1, silver)
        return
    }
    c.rect(38, 35, 3, 1, silver)
}

/// The lasso coiled at her hip: two gold loops.
private func drawCoil(_ c: PixelCanvas, x: Int, y: Int) {
    let gold = C(0xF0C040), dark = C(0xB08A20)
    c.pattern(x, y, [".GGG.", "G.d.G", "GdGdG", ".GGG."], ["G": gold, "d": dark])
}

/// The Lasso of Lightning lashed out from the hand along `angle`: a gold rope with a slight wave, the loop on the end,
/// faint arcs where it just was.
private func drawLasso(_ c: PixelCanvas, angle: Double, trail: [Double], t: Double, len: Double = 12) {
    let h = Sprite.hand
    let core = C(0xFFE890), glow = C(0xF0B020)
    for (i, a) in trail.enumerated() {
        let e = along(a, len)
        c.glowLine(h.x, h.y, e.x, e.y, core: glow.alpha(0.3 / Double(i + 1)), glow: glow.alpha(0.2 / Double(i + 1)),
                   coreR: 0.4, glowR: 1.4)
    }
    let r: Double = angle * .pi / 180
    let ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    var prev = (x: h.x, y: h.y)
    let n = 8
    for i in 1...n {
        let f = Double(i) / Double(n)
        let wave: Double = sin(f * .pi * 2 + t * 18) * 1.2 * f
        let q = (x: h.x + ux * len * f + nx * wave, y: h.y + uy * len * f + ny * wave)
        c.glowLine(prev.x, prev.y, q.x, q.y, core: core, glow: glow.alpha(0.6), coreR: 0.45, glowR: 1.3)
        prev = q
    }
    ring(c, prev.x + ux * 2.5, prev.y + uy * 2.5, 2.5, 2.5, core, n: 16)
    c.rect(38, 33, 3, 3, C(0xC8202A))
}

/// Wonder Girl's signature, `s` 0…1: the hand up, the lasso twirled in a ring over her head, then cracked forward.
private func drawLassoTwirl(_ c: PixelCanvas, s: Double, t: Double) {
    let red = C(0xC8202A), core = C(0xFFE890), glow = C(0xF0B020)
    if s < 0.72 {
        bar(c, 39.5, 34, 39.5, 22, red, 1)
        c.rect(38, 24, 3, 1, C(0xD4D8E0)); c.rect(38, 20, 3, 3, red)
        let k = habitArc(min(1, s / 0.72), hold: 0.6)
        let rx: Double = 4 + 9 * k, ry: Double = 1.5 + 1.5 * k, cx = 32.0, cy: Double = 13
        ring(c, cx, cy, rx, ry, core, n: 40)
        let a: Double = t * 16
        c.glowLine(39.5, 20.5, cx + cos(a) * rx, cy + sin(a) * ry, core: core, glow: glow.alpha(0.6), coreR: 0.45, glowR: 1.3)
        c.glowLine(cx + cos(a) * rx, cy + sin(a) * ry, cx + cos(a) * rx, cy + sin(a) * ry, core: white, glow: glow, coreR: 0.6, glowR: 2)
        if k > 0.7 {
            // Zeus' lightning running round the rope.
            for i in 0..<3 where noise(Int(t * 20) * 3 + i) > 0.35 {
                let b: Double = a + 1.4 + Double(i) * 1.6
                let x: Double = cx + cos(b) * rx, y: Double = cy + sin(b) * ry
                c.glowLine(x, y, x + 1, y - 2, core: C(0xF4F8FF), glow: C(0x7FB2FF), coreR: 0.3, glowR: 1.1)
            }
        }
        return
    }
    // Cracked out in front, a snap of sparks at the end.
    let k = (s - 0.72) / 0.28
    let reach: Double = 8 + 18 * min(1, k * 2)
    drawLasso(c, angle: -6, trail: [], t: t, len: reach)
    if k > 0.4 && k < 0.8 { drawSparks(c, x: 42 + reach, y: 31, t: t, size: 3) }
}

// MARK: - Aqualad

/// Aqualad (Kaldur'ahm): a pale blond buzz cut, gills on his neck, a black wetsuit with a red top, bare arms with
/// glowing blue Atlantean tattoos, and the water-bearers, two silver hilts at his hips that shape water into blades
/// when he fights. Signature: he raises both hilts and pulls water up out of the air in spirals into a big floating
/// globe, a little fish swimming in it, then lets it splash down.
private func drawAqualad(_ c: PixelCanvas, _ p: Pose) {
    let skin = clawdOrange, black = C(0x1E2228), blackLight = C(0x34383F), red = C(0xB0202A), redDark = C(0x781418)
    let hair = C(0xE8DCA0), hairDark = C(0xC0B070), tattoo = C(0x6AD8FF)
    drawLegs(c, Look(leg: black), step: p.step)
    drawBoots(c, blackLight, step: p.step, rows: 2)
    c.oy += p.breathe
    let sig = p.signature.flatMap { $0 > 0.05 && $0 < 0.96 ? ($0 - 0.05) / 0.91 : nil }
    let up = sig.map { $0 < 0.8 ? 5 : 0 } ?? 0
    drawBody(c, Look(arm: skin), armLeft: up, armRight: up)
    c.pattern(18, 24, sym(["..hHHhHHhH", "HHHHHHHHHH"]), ["H": hair, "h": hairDark])
    c.rect(18, 26, 20, 1, hairDark); c.rect(18, 27, 1, 2, hairDark); c.rect(37, 27, 1, 2, hairDark)
    // Gills, a level mouth.
    c.rect(19, 32, 1, 2, clawdShade); c.rect(36, 32, 1, 2, clawdShade)
    c.rect(26, 33, 4, 1, clawdShade)
    // Red top, black wetsuit, the tattoos on both arms.
    c.rect(18, 34, 20, 4, black)
    c.rect(18, 34, 20, 1, red); c.rect(20, 35, 16, 1, red); c.rect(23, 36, 10, 1, redDark)
    c.rect(18, 37, 20, 1, blackLight)
    for x in [16, 39] { c.rect(x, 33 - up, 1, 3, tattoo) }
    c.glowLine(16.5, 34.5 - Double(up), 16.5, 34.5 - Double(up), core: C(0, 0), glow: tattoo.alpha(0.35), coreR: 0, glowR: 1.6)
    c.glowLine(39.5, 34.5 - Double(up), 39.5, 34.5 - Double(up), core: C(0, 0), glow: tattoo.alpha(0.35), coreR: 0, glowR: 1.6)
    if let s = sig {
        drawHilt(c, at: (16.5, 31.5 - Double(up)), angle: -90)
        drawHilt(c, at: (39.5, 31.5 - Double(up)), angle: -90)
        drawWaterGlobe(c, s: s, t: p.t)
        return
    }
    // The left hilt at his hip; the right one in hand, or at the hip too.
    c.rect(16, 36, 2, 2, C(0x8A909C))
    if let a = p.melee {
        drawWaterBlade(c, angle: a, trail: p.trail, t: p.t)
    } else {
        c.rect(38, 36, 2, 2, C(0x8A909C))
    }
}

/// A water-bearer's silver hilt, held at `at`, pointing along `angle`.
private func drawHilt(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double) {
    prop(c, at: at, angle: angle) { s in
        s.rect(17, 20, 5, 1, C(0x8A909C)); s.rect(17, 19, 1, 3, C(0xC8CCD4)); s.px(21, 20, C(0xD4D8E0))
    }
}

/// A blade of water from the right hilt along `angle`: a pale core in a blue glow, drops flicking off its edge.
private func drawWaterBlade(_ c: PixelCanvas, angle: Double, trail: [Double], t: Double) {
    let core = C(0xD8F6FF), glow = C(0x3A9AE8)
    for (i, a) in trail.enumerated() {
        let s = along(a, 4), e = along(a, 18)
        c.glowLine(s.x, s.y, e.x, e.y, core: glow.alpha(0.35 / Double(i + 1)), glow: glow.alpha(0.3 / Double(i + 1)),
                   coreR: 0.6, glowR: 1.8)
    }
    let s = along(angle, 4), e = along(angle, 18)
    c.glowLine(s.x, s.y, e.x, e.y, core: core.alpha(0.9), glow: glow.alpha(0.8), coreR: 0.7, glowR: 2)
    let seed = Int(t * 20)
    for i in 0..<3 {
        let d = along(angle, 6 + noise(seed + i) * 12)
        c.px(Int(d.x + (noise(seed * 3 + i) - 0.5) * 6), Int(d.y + noise(seed * 7 + i) * 3), core.alpha(0.8))
    }
    drawHilt(c, at: Sprite.hand, angle: angle + 180)
    c.rect(38, 33, 3, 3, clawdOrange)
}

/// Aqualad's water globe, `s` 0…1: spirals of water up from both hands into a growing globe with a fish in it, then
/// the splash.
private func drawWaterGlobe(_ c: PixelCanvas, s: Double, t: Double) {
    let core = C(0xD8F6FF), glow = C(0x3A9AE8), cx = 28.0, cy = 11.0
    if s < 0.8 {
        let k = min(1, s / 0.6)
        let r: Double = 1 + 6 * k
        // Two spirals of water rising.
        for (hx, side) in [(16.5, 1.0), (39.5, -1.0)] {
            for i in 0..<10 {
                let f = Double(i) / 10
                let y: Double = 26 - f * (26 - cy - r)
                let x: Double = hx + (cx - hx) * f + sin(f * 9 - t * 10) * 2 * side
                c.glowLine(x, y, x, y, core: core.alpha(0.8), glow: glow.alpha(0.6), coreR: 0.5, glowR: 1.4)
            }
        }
        c.glowLine(cx, cy, cx, cy, core: glow.alpha(0.45), glow: glow.alpha(0.5), coreR: r, glowR: r + 1.6)
        ring(c, cx, cy, r, r, core.alpha(0.85), n: 28)
        c.px(Int(cx - r * 0.5), Int(cy - r * 0.5), white)
        if r > 4 {
            let fx = Int(cx + sin(t * 3) * (r - 3)), dir = cos(t * 3) > 0 ? 1 : -1
            c.rect(fx - 1, Int(cy), 3, 2, C(0xFF8A2A)); c.px(fx - 2 * dir, Int(cy), C(0xFFB05A)); c.px(fx - 2 * dir, Int(cy) + 1, C(0xFFB05A))
            c.px(fx + dir, Int(cy), ink)
        }
        return
    }
    // The splash: drops falling and spreading.
    let k = (s - 0.8) / 0.2
    for i in 0..<12 {
        let a: Double = Double(i) / 12 * 2 * .pi
        let x: Double = cx + cos(a) * (4 + k * 14), y: Double = cy + sin(a) * 3 + k * k * 30
        c.px(Int(x), Int(y), core.alpha(1 - k * 0.6)); c.px(Int(x), Int(y) - 1, glow.alpha(0.6 * (1 - k)))
    }
}

// MARK: - Arsenal

/// Arsenal (Roy Harper): red hair under a red Robin Hood cap with a feather, a black domino mask, a red tunic with the
/// quiver strap across it, black gloves and trousers, red boots, the quiver on his back and a red bow. Signature: a
/// trick arrow with a boxing glove for a head, drawn, loosed, and POW.
private func drawArsenal(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC02028), redDark = C(0x841418), black = C(0x1E1E24), strap = C(0x6A4428)
    let hair = C(0xC8482A), hairDark = C(0x8A2E1A), feather = C(0xF0E8D0)
    let sig = p.signature
    c.oy += p.breathe
    c.pattern(12, 20, [
        "R.R.....",
        "RwRw....",
        ".wRwR...",
        "..QQQQ..",
        "..QQQQ..",
        "...QQQq.",
        "...QQQQ.",
        "....QQQQ",
        "....QQQq",
        ".....QQq",
    ], ["R": C(0xE0303A), "w": feather, "Q": C(0x4A2E1E), "q": C(0x2E1C12)])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: black), step: p.step)
    drawBoots(c, red, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: red))
    // Hair, the cap and its feather.
    c.pattern(16, 21, [
        "..HHHHHHHHHHHHHHHHHHH...",
        ".HHHHhHHHHHHHHHHHhHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHhHHHHHHHhHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHH..",
        ".HHHh..............HHH..",
        "..H.................H...",
    ], ["H": hair, "h": hairDark])
    c.pattern(13, 13, [
        "F.........................",
        ".F........................",
        "..F.........RRR...........",
        "...F.....RRRRRRRR.........",
        "....F..RRRRRRRRRRRRR......",
        "....FRRRRRRRRRRRRRRRRR....",
        "....RRRRRRRRRRRRRRRRRRRr..",
        "..RRRRRRRRRRRRRRRRRRRRRRr.",
        "...dddddddddddddddddddddd.",
    ], ["R": red, "r": redDark, "d": redDark, "F": feather])
    // Domino mask, white eyes.
    c.pattern(20, 28, [".KKKKKK....KKKKKK..", "KKWWKKKKKKKKWWKKKK.", "KKWWKK......WWKKK..", ".KKKK.......KKKK..."],
              ["K": black, "W": white])
    c.rect(26, 33, 4, 1, clawdShade)
    // Tunic, the quiver strap across it, black belt.
    c.rect(18, 34, 20, 4, red)
    bar(c, 19, 33, 30, 37, strap, 0.6)
    c.rect(18, 37, 20, 1, black); c.rect(27, 37, 2, 1, C(0xC8A040))
    c.rect(37, 34, 1, 3, redDark)
    c.rect(15, 35, 3, 1, black)

    // The bow, as Kate's: drawn and held for the trick arrow, or the usual shooting and aiming.
    let drawing = sig.map { $0 > 0.06 && $0 < 0.4 } ?? false
    var pull = 0
    if let s = sig, drawing { pull = Int((4 * min(1, (s - 0.06) / 0.14)).rounded()) }
    let firing = p.fire.map { frac($0.t / shotPeriod) < 0.45 } ?? false
    if let f = p.fire, frac(f.t / shotPeriod) > 0.6 { pull = Int(((frac(f.t / shotPeriod) - 0.6) / 0.4 * 3).rounded()) }
    let raise = drawing ? -1 : seatedPose ? -3 : 0
    c.oy += p.gunY + raise
    drawBow(c, pull: pull, limb: C(0x9A1A22), grip: black)
    let nocked = drawing || p.ready || (p.fire != nil && !firing)
    if nocked {
        let tail = 41 - pull
        c.rect(tail, 34, 47 - tail, 1, C(0x5A4A3A))
        if drawing {
            c.rect(47, 33, 3, 3, C(0xD02020)); c.px(49, 33, C(0xFF6A5A))
        } else {
            c.px(47, 34, C(0xC8CCD4)); c.px(48, 34, C(0xE8ECF4))
        }
        c.px(tail, 33, red); c.px(tail, 35, red)
    }
    c.rect(38 - pull, 33, 3, 3, black)
    c.oy -= p.gunY + raise
    if let s = sig, s >= 0.4 { drawGloveArrow(c, s: s, t: p.t) }
}

/// Arsenal's boxing-glove arrow after it leaves the string (`s` 0.4…1): out across the canvas, then POW.
private func drawGloveArrow(_ c: PixelCanvas, s: Double, t: Double) {
    let glove = C(0xD02020), shine = C(0xFF6A5A)
    let f = min(1, (s - 0.4) / 0.16)
    let x: Double = 47 + f * 10
    for k in 0..<8 { c.px(Int(x) - k - 1, 34, C(0x5A4A3A)) }
    c.px(Int(x) - 9, 33, C(0xE0303A)); c.px(Int(x) - 9, 35, C(0xE0303A))
    let pop = s > 0.56
    c.rect(Int(x), pop ? 32 : 33, pop ? 5 : 3, pop ? 5 : 3, glove)
    c.px(Int(x) + 1, pop ? 32 : 33, shine)
    guard pop else { return }
    // POW: a yellow burst, white star lines, fading out.
    let k = (s - 0.56) / 0.44
    let cx: Double = x + 6, cy = 34.0
    let r: Double = 3 + k * 4
    for i in 0..<8 {
        let a: Double = Double(i) * .pi / 4 + 0.4
        let len: Double = i % 2 == 0 ? r + 2 : r
        c.glowLine(cx + cos(a) * 2, cy + sin(a) * 2, cx + cos(a) * len, cy + sin(a) * len,
                   core: C(0xFFF6C8).alpha(1 - k), glow: C(0xFFC81E).alpha(0.7 * (1 - k)), coreR: 0.5, glowR: 1.4)
    }
}

/// A recurve bow gripped at the hand; `pull` draws the string back that many pixels.
private func drawBow(_ c: PixelCanvas, pull: Int, limb: Px, grip: Px) {
    let string = C(0xE0E0E8)
    for y in 25...43 {
        let d = abs(y - 34)
        let x = d <= 2 ? 44 : d <= 5 ? 43 : d <= 7 ? 42 : 41
        c.px(x, y, d <= 1 ? grip : limb)
        if d == 9 { c.px(x + 1, y, limb) }
    }
    for y in 26...42 {
        let d = Double(abs(y - 34)) / 8
        c.px(41 - Int((Double(pull) * (1 - d)).rounded()), y, string)
    }
}

// MARK: - Shared helpers

/// Rows drawn for the left half, mirrored onto the right.
private func sym(_ rows: [String]) -> [String] { rows.map { $0 + String($0.reversed()) } }

/// Legs, standing or walking (with boots in `boot`), or swept back in flight.
private func drawSuitLegs(_ c: PixelCanvas, _ p: Pose, _ leg: Px, boot: Px? = nil, bootRows: Int = 2) {
    if p.flying {
        let sweep: [(Int, Int)] = [(0, 36), (0, 37), (-1, 38), (-2, 39), (-3, 40)]
        for lx in [19, 23, 31, 35] {
            for (i, s) in sweep.enumerated() {
                let col = boot != nil && i >= sweep.count - bootRows ? boot! : leg
                c.rect(lx + s.0, s.1, 2, 1, col)
            }
        }
        return
    }
    drawLegs(c, Look(leg: leg), step: p.step)
    if let boot { drawBoots(c, boot, step: p.step, rows: bootRows) }
}

/// A filled triangle.
private func tri(_ c: PixelCanvas, _ a: (Double, Double), _ b: (Double, Double), _ d: (Double, Double), _ col: Px) {
    let minX = Int(floor(min(a.0, b.0, d.0))), maxX = Int(ceil(max(a.0, b.0, d.0)))
    let minY = Int(floor(min(a.1, b.1, d.1))), maxY = Int(ceil(max(a.1, b.1, d.1)))
    func side(_ p: (Double, Double), _ q: (Double, Double), _ r: (Double, Double)) -> Double {
        (q.0 - p.0) * (r.1 - p.1) - (q.1 - p.1) * (r.0 - p.0)
    }
    for y in minY...maxY {
        for x in minX...maxX {
            let pt = (Double(x) + 0.5, Double(y) + 0.5)
            let s1 = side(a, b, pt), s2 = side(b, d, pt), s3 = side(d, a, pt)
            if (s1 >= 0 && s2 >= 0 && s3 >= 0) || (s1 <= 0 && s2 <= 0 && s3 <= 0) { c.px(x, y, col) }
        }
    }
}

/// An outline ellipse, `n` dots round it.
private func ring(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px, n: Int = 40) {
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        c.px(Int((cx + cos(a) * rx).rounded()), Int((cy + sin(a) * ry).rounded()), col)
    }
}

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from `h` (the hand) along `angle` degrees.
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

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int) {
    c.px(x, y, white)
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] as [(Int, Int)] { c.px(x + dx, y + dy, C(0xFFFFFF, 0.6)) }
}

private func unpremultiplied(_ s: PixelCanvas, _ i: Int) -> Px {
    let a = s.buf[i + 3], m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a)
}
