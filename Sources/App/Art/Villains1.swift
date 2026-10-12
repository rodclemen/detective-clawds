import Foundation

// Villains: Batman's rogues. Clawd in costume, except Killer Croc, who keeps only a hint of him.

let villains1: [Leader: Persona] = [
    .joker: Persona(name: "The Joker", weapon: .ranged, shot: .bullet, muzzle: (51, 31.5), headTop: 19, signature: 3.0,
                  callout: "Why so serious?",
                  draw: drawJoker),
    .harleyQuinn: Persona(name: "Harley Quinn", weapon: .melee, headTop: 17, signature: 2.8, callout: "Hiya, Puddin'!",
                  draw: drawHarleyQuinn),
    .penguin: Persona(name: "The Penguin", weapon: .ranged, shot: .bullet, muzzle: (57, 33.5), headTop: 14, signature: 3.0,
                  callout: "Wak! Wak! Wak!",
                  draw: drawPenguin),
    .riddler: Persona(name: "The Riddler", weapon: .melee, headTop: 19, signature: 3.0, callout: "Riddle me this!",
                  draw: drawRiddler),
    .twoFace: Persona(name: "Two-Face", weapon: .ranged, shot: .bullet, muzzle: (47, 32), headTop: 22, signature: 2.8,
                  callout: "Heads or tails?",
                  draw: drawTwoFace),
    .scarecrow: Persona(name: "Scarecrow", weapon: .magic, magic: Magic(core: C(0xF0FFD0), glow: C(0xA8C82A), jagged: false),
                  headTop: 12, signature: 3.2, callout: "Have a taste of fear.",
                  draw: drawScarecrow),
    .poisonIvy: Persona(name: "Poison Ivy", weapon: .magic, magic: Magic(core: C(0xE8FFD0), glow: C(0x4AC82A), jagged: false),
                  headTop: 18, signature: 3.2, callout: "Pucker up.",
                  draw: drawPoisonIvy),
    .mrFreeze: Persona(name: "Mr. Freeze", weapon: .ranged, shot: .ice, armoured: true, muzzle: (56, 32), headTop: 17,
                  signature: 3.2, callout: "Everybody... freeze!",
                  draw: drawMrFreeze),
    .bane: Persona(name: "Bane", weapon: .melee, pivot: baneShoulder, bulk: 4, headTop: 16, signature: 3.0,
                  callout: "I will break you.",
                  draw: drawBane),
    .killerCroc: Persona(name: "Killer Croc", weapon: .melee, armoured: true, pivot: crocShoulder, bulk: 5, headTop: 18,
                  signature: 2.8, callout: "Fresh meat.",
                  draw: drawKillerCroc),
    .rasAlGhul: Persona(name: "Ra's al Ghul", weapon: .melee, headTop: 21, signature: 3.2, callout: "Greetings, Detective.",
                  draw: drawRasAlGhul),
]

// MARK: - Helpers

private let clear = C(0, 0)

/// A solid line `r` thick: staffs, shafts, ropes, tubes.
private func stick(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// A filled circle.
private func disc(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double, _ col: Px) {
    let x0 = Int(floor(cx - r)), x1 = Int(ceil(cx + r)), y0 = Int(floor(cy - r)), y1 = Int(ceil(cy + r))
    for y in y0...y1 {
        for x in x0...x1 {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            if dx * dx + dy * dy <= r * r { c.px(x, y, col) }
        }
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

/// Thick legs for the big ones (Bane, Croc): `leg` above, `foot` on the bottom `footRows`.
private func drawBigLegs(_ c: PixelCanvas, _ p: Pose, leg: Px, foot: Px, footRows: Int) {
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, leg); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        let bottom = lifted ? 42 : 43
        c.rect(lx, 36, 3, bottom - 35, leg)
        c.rect(lx, bottom - footRows + 1, 3, footRows, foot)
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

/// Tints a scatter of everything drawn so far: a shimmer running over the sprite.
private func shimmer(_ c: PixelCanvas, _ col: Px, amount: Double, seed: Int) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<c.h {
        for x in 0..<c.w where c.isDrawn(x, y) && noise(seed * 977 + y * 72 + x) < amount {
            c.px(x, y, col.alpha(0.7))
        }
    }
}

/// A tiny 3×5 pixel font, just the letters these villains need.
private let glyphs: [Character: [String]] = [
    "B": ["XX.", "X.X", "XX.", "X.X", "XX."],
    "A": [".X.", "X.X", "XXX", "X.X", "X.X"],
    "N": ["X.X", "XXX", "XXX", "XXX", "X.X"],
    "G": [".XX", "X..", "X.X", "X.X", ".XX"],
    "H": ["X.X", "X.X", "XXX", "X.X", "X.X"],
    "!": ["X", "X", "X", ".", "X"],
    " ": ["."],
]

/// `text` in the tiny font, its top-left at (x, y).
private func drawText(_ c: PixelCanvas, x: Int, y: Int, _ text: String, _ col: Px) {
    var cx = x
    for ch in text {
        guard let g = glyphs[ch] else { continue }
        c.pattern(cx, y, g, ["X": col])
        cx += g[0].count + 1
    }
}

/// A big 5×7 question mark (or exclamation mark), its top-left at (x, y).
private func drawBigMark(_ c: PixelCanvas, x: Int, y: Int, bang: Bool, _ col: Px) {
    let q = [".QQQ.", "Q...Q", "....Q", "...Q.", "..Q..", ".....", "..Q.."]
    let b = ["..Q..", "..Q..", "..Q..", "..Q..", "..Q..", ".....", "..Q.."]
    c.pattern(x, y, bang ? b : q, ["Q": col])
}

// MARK: - The Joker

/// The Joker: chalk-white Clawd with slicked-back green hair, dark-ringed eyes and a wide red grin, in the purple suit
/// with a green waistcoat, orange tie and a squirting flower in the lapel. He shoots a long-barrelled revolver.
/// Signature: he aims, pulls the trigger, and out pops a flag on a stick: BANG!
private func drawJoker(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x6A2E9A), purpleDark = C(0x48206E), purpleLight = C(0x9058C0)
    let green = C(0x3AA84A), greenDark = C(0x247A30), face = C(0xF2F0EA), faceShade = C(0xC8C4CC)
    let red = C(0xD8222E), orange = C(0xF08A2A)
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, C(0x2A2A30), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(body: face, shade: faceShade, arm: purple, eye: nil))
    c.pattern(21, 28, ["dddd......dddd", "dKKd......dKKd", "dKKd......dKKd"], ["d": C(0x9A8AA8), "K": ink])
    let laughing = p.signature.map { $0 > 0.25 && $0 < 0.85 } ?? false
    if laughing {
        c.pattern(19, 30, ["R................R", ".RRRRRRRRRRRRRRRR.", ".RWWWWWWWWWWWWWWR.", "..RKKKKKKKKKKKKR.."],
                  ["R": red, "W": white, "K": C(0x4A0A14)])
    } else {
        c.pattern(19, 30, ["R................R", ".RRRRRRRRRRRRRRRR.", ".RWWWWWWWWWWWWWWR.", "..RRRRRRRRRRRRRR.."],
                  ["R": red, "W": white])
    }
    // The purple suit, green waistcoat, orange tie and the flower.
    c.rect(18, 34, 20, 4, purple)
    c.rect(37, 34, 1, 4, purpleDark); c.rect(18, 37, 20, 1, purpleDark)
    c.rect(24, 34, 8, 3, green); c.rect(24, 36, 8, 1, greenDark)
    c.rect(23, 34, 1, 4, purpleLight); c.rect(32, 34, 1, 4, purpleLight)
    c.rect(27, 34, 2, 3, orange)
    for (x, y) in [(20, 35), (22, 35), (21, 34), (21, 36)] { c.px(x, y, white) }
    c.px(21, 35, C(0xFFD23A))
    // Green hair, slicked back.
    c.pattern(14, 19, [
        "...........LL...........",
        "....GG...GGGGG..GGG.....",
        "..GGGGGGGGLGGGGGGGGGG...",
        ".GGGGGGLGGGGGGLGGGGGGG..",
        "GGGGgGGGGGgGGGGGGGgGGGG.",
        "..GGGGgGGGGGGgGGGGGGGGGG",
        ".GGGGGGGGGgGGGGGGGgGGGGG",
        "GGGgGG...........GGgGGGG",
        ".GGGG.............GG.GGG",
        "..GG...............G..G.",
        "...G....................",
    ], ["G": green, "g": greenDark, "L": C(0x7AD87A)])
    c.rect(15, 33, 3, 3, purple)

    // The revolver, and the flag that pops out of it.
    let gy = p.gunY
    c.pattern(38, 31 + gy, [
        "...SSSSSSSSSS",
        "..KCCKKKKKKKK",
        "..KCCK.......",
        "..KK.........",
        "..KK.........",
    ], ["S": C(0xB8BCC8), "K": C(0x3A3A44), "C": C(0x7A7E8A)])
    c.rect(38, 33, 3, 3, purple)
    if let s = p.signature {
        let out: Double = s < 0.12 ? 0 : s < 0.22 ? (s - 0.12) / 0.1 : s < 0.86 ? 1 : max(0, 1 - (s - 0.86) / 0.1)
        guard out > 0 else { return }
        let y = 31 + gy
        let len = Int((out * 20).rounded())
        c.rect(51, y, len, 1, C(0x8A6A3A))
        if len > 2 {
            let flutter = Int(p.t * 10) % 2
            c.rect(52, y + 1, len - 1, 6, C(0xF4F0E8))
            for x in stride(from: 52 + flutter, to: 51 + len, by: 2) { c.px(x, y + 7, C(0xF4F0E8)) }
            if out >= 1 { drawText(c, x: 53, y: y + 2, "BANG!", red) }
        }
    }
}

// MARK: - Harley Quinn

/// Harley Quinn, the classic jester: white face and a black domino mask, the two-pointed red and black cowl with
/// white pompoms, a harlequin bodysuit split down the middle with a white ruff, and a giant mallet.
/// Signature: she blows a pink bubblegum bubble until it pops all over her face.
private func drawHarleyQuinn(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD8282E), redDark = C(0xA01A20), black = C(0x1C1C22), blackLight = C(0x3A3A44)
    let face = C(0xF4F0EC), faceShade = C(0xCCC6C4)
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let col = lx < 28 ? red : black
        if seatedPose { c.rect(lx - 1, 38, 4, 2, col); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 2, lifted ? 7 : 8, col)
        c.rect(lx, lifted ? 41 : 42, 2, 2, lx < 28 ? black : red)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: face, shade: faceShade, arm: red, eye: nil))
    c.rect(38, 33, 3, 3, black)
    c.pattern(20, 28, [".KKKKK....KKKKK.", "KKBBKK....KKBBKK", "KKBBKKKKKKKKBBKK", ".KKKK......KKKK."],
              ["K": ink, "B": C(0xA8D8FF)])
    c.rect(26, 33, 4, 1, red)
    // The harlequin suit and the ruff.
    c.rect(18, 34, 10, 4, red); c.rect(28, 34, 10, 4, black)
    c.rect(18, 37, 10, 1, redDark); c.rect(37, 34, 1, 4, blackLight)
    c.pattern(21, 35, [".K.", "KKK", ".K."], ["K": black])
    c.pattern(31, 35, [".R.", "RRR", ".R."], ["R": red])
    c.rect(18, 34, 20, 1, white)
    for x in stride(from: 19, to: 38, by: 2) { c.px(x, 35, white) }

    // The cowl's two floppy points, then the cowl itself.
    let sway = sin(p.lt * 3) * 1.2
    stick(c, 20, 21, 13, 19 + sway * 0.5, red, 1.5); stick(c, 13, 19 + sway * 0.5, 10, 25 + sway, red, 1.0)
    stick(c, 36, 21, 43, 19 - sway * 0.5, black, 1.5); stick(c, 43, 19 - sway * 0.5, 46, 25 - sway, black, 1.0)
    c.pattern(17, 19, [
        ".....RRRRRRKKKKKK.....",
        "...RRRRRRRRKKKKKKKK...",
        "..RRRRRRRRRKKKKKKKKK..",
        ".RRRRRRRRRRKKKKKKKKKK.",
        "RRRrRRRRRRRKKKKKKKKKKK",
        "RRrRRRRRRRRKKKKKKKKKKK",
        "RRRRRRRRRRRKKKKKKKKKKK",
        "RRR................KKK",
        "RRR................KKK",
        "RRR................KKK",
        "RR..................KK",
        "RR..................KK",
    ], ["R": red, "r": C(0xF05A5A), "K": black])
    for (x, y) in [(9.0, 25.0 + sway), (45.0, 25.0 - sway)] as [(Double, Double)] {
        c.rect(Int(x), Int(y.rounded()), 3, 3, white); c.px(Int(x) + 2, Int(y.rounded()) + 2, faceShade)
    }

    // The bubble.
    if let s = p.signature {
        let pink = C(0xFF8AC8), light = C(0xFFD8EE)
        if s < 0.7 {
            let r = 0.8 + min(1, s / 0.62) * 4.2
            disc(c, 28.5, 33.0 - r * 0.5, r, pink.alpha(0.9))
            c.px(Int(28.5 - r * 0.5), Int(33.0 - r), light)
        } else if s < 0.82 {
            let f = (s - 0.7) / 0.12
            for n in 0..<8 {
                let a = Double(n) * .pi / 4
                c.px(28 + Int(cos(a) * (2 + f * 4)), 32 + Int(sin(a) * (2 + f * 3)), pink)
            }
        } else {
            for (x, y) in [(25, 32), (27, 33), (30, 32), (31, 34), (24, 30), (33, 31)] { c.px(x, y, pink) }
        }
    }

    // The mallet, swung, or held up at the ready.
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawMallet(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawMallet(c, angle: a)
    } else {
        drawMallet(c, angle: -78)
    }
}

/// Harley's giant mallet at `angle`: a wooden handle and a big red and black head with white bands.
private func drawMallet(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: Sprite.hand, angle: angle, alpha: alpha) { s in
        stick(s, 17, 20.5, 31, 20.5, C(0x8A5A2E), 0.75)
        s.rect(17, 20, 2, 1, C(0x2A2A30))
        s.rect(31, 14, 7, 6, C(0xD8282E)); s.rect(31, 21, 7, 6, C(0x1C1C22))
        s.rect(31, 20, 7, 1, white)
        s.rect(31, 14, 7, 1, C(0xC8C8D0)); s.rect(31, 26, 7, 1, C(0xC8C8D0))
        s.rect(32, 15, 1, 4, C(0xF07A7A))
    }
}

// MARK: - The Penguin

/// The Penguin: a squat Clawd with a beaky nose, a monocle and a cigarette holder, a black top hat with a purple
/// band, and a tuxedo stretched over a round white shirtfront, on short legs in white spats. His umbrella is a gun.
/// Signature: he pops the umbrella open over his head, twirls it and floats up a little.
private func drawPenguin(_ c: PixelCanvas, _ p: Pose) {
    let tux = C(0x1C1C24), tuxLight = C(0x3A3A48), skin = C(0xE8C4A8), skinDark = C(0xC09A80)
    let shirt = C(0xF4F4F0), purple = C(0x6A3A8A), gold = C(0xE8C860)
    var lift = 0, open = 0.0
    if let s = p.signature {
        open = habitArc(s, hold: 0.6)
        lift = Int((habitArc(min(1, max(0, (s - 0.15) / 0.75)), hold: 0.5) * 3).rounded())
    }
    c.oy -= lift
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 4, 2, tux); continue }
        let lifted = (p.step >= 0 && i % 2 == p.step) || lift > 0
        let bottom = lifted ? 42 : 43
        c.rect(lx, 40, 2, bottom - 39, tux)
        c.rect(lx, bottom - 1, 2, 1, shirt)
        c.rect(lx, bottom, 3, 1, ink)
    }
    c.oy += p.breathe
    // The face, then the round tuxedo body.
    c.rect(18, 26, 20, 8, skin)
    c.rect(37, 26, 1, 8, skinDark)
    c.rect(16, 34, 24, 6, tux)
    c.rect(17, 33, 22, 1, tux)
    c.rect(16, 39, 24, 1, C(0x101016))
    c.rect(23, 34, 10, 5, shirt)
    c.rect(22, 34, 1, 5, purple); c.rect(33, 34, 1, 5, purple)
    c.pattern(25, 33, ["KK.KK", ".KKK.", "KK.KK"], ["K": ink])
    c.rect(18, 26, 2, 3, tux); c.rect(36, 26, 2, 2, tux)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 2, ink)
    c.pattern(31, 28, ["YYYY", "Y..Y", "Y..Y", "Y..Y", "YYYY"], ["Y": gold])
    c.px(32, 31, C(0xDFF2FF, 0.8)); c.px(33, 31, C(0xDFF2FF, 0.8))
    c.px(34, 33, gold); c.px(35, 34, gold)
    c.pattern(26, 28, [".Nn..", ".NNn.", "NNNNn", "NNNNNn", "...Nn."], ["N": C(0xE89C84), "n": C(0xB07060)])
    c.rect(23, 33, 3, 1, skinDark)
    // The cigarette holder, with a wisp of smoke.
    stick(c, 23.5, 33.5, 17.5, 32, ink, 0.4)
    c.px(16, 31, C(0xFF7A3A))
    let f = frac(p.lt * 0.7)
    c.px(16 + Int(sin(f * 7) * 1.5), 30 - Int(f * 6), C(0xE0E0E0).alpha(0.8 * (1 - f)))
    // The top hat.
    c.rect(21, 14, 14, 10, tux); c.rect(22, 15, 1, 6, tuxLight)
    c.rect(21, 21, 14, 2, purple)
    c.rect(17, 24, 22, 2, tux); c.px(17, 23, tux); c.px(38, 23, tux)
    c.rect(13, 35, 3, 3, tux)

    if open > 0 {
        // The umbrella, open over his head.
        c.rect(39, 24, 3, 11, tux)
        c.rect(39, 22, 3, 3, C(0xD8D8E0))
        stick(c, 40.5, 23, 40.5, 10, C(0x7A5A3A), 0.5)
        let spin = Int(p.t * 10)
        for dy in 0..<6 {
            let half = Int((open * (5.0 + Double(dy) * 1.6)).rounded())
            guard half > 0 else { continue }
            for x in (40 - half)...(41 + half) {
                let panel = ((x + 60 + spin) / 3) % 2 == 0
                c.px(x, 6 + dy, panel ? tux : purple)
            }
        }
        if open > 0.9 { for x in stride(from: 31, to: 51, by: 3) { c.px(x, 12, tux) } }
        c.px(40, 5, C(0xC8C8D0)); c.px(41, 5, C(0xC8C8D0))
        return
    }
    // The umbrella gun, furled, held level.
    let y = 34 + p.gunY
    c.rect(40, y, 16, 1, C(0x5A5A64))
    for x in 44...53 {
        let half = (53 - x) / 4
        c.rect(x, y - half, 1, 2 * half + 1, x % 3 == 0 ? purple : tux)
    }
    c.rect(53, y, 4, 1, C(0xC8C8D0))
    c.pattern(38, y + 1, ["H..", "H..", ".HH"], ["H": C(0x7A5A3A)])
    c.rect(39, y - 1, 3, 3, C(0xD8D8E0))
}

// MARK: - The Riddler

/// The Riddler: Clawd with a purple domino mask and a ginger fringe under a green bowler with a purple band, a green
/// suit printed with black question marks, a purple tie, and the question-mark cane. Signature: he leans on the cane
/// and a big glowing question mark pops up over his head, then turns into an exclamation mark.
private func drawRiddler(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E9A3A), greenDark = C(0x1E6E28), greenLight = C(0x5AC85A), purple = C(0x6A2E9A)
    let skin = C(0xEAC4A4), skinDark = C(0xC49C7E), hair = C(0xB8501E)
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, C(0x2A2A30), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: green, eye: nil))
    c.pattern(20, 28, [".PPPPP....PPPPP.", "PPKKPPPPPPPPKKPP", "PPKKPP....PPKKPP", ".PPPP......PPPP."], ["P": purple, "K": ink])
    c.rect(25, 32, 6, 1, skinDark); c.px(31, 31, skinDark)
    // The suit.
    c.rect(18, 33, 20, 5, green)
    c.rect(37, 33, 1, 5, greenDark); c.rect(18, 37, 20, 1, greenDark)
    c.rect(26, 33, 4, 1, white)
    c.rect(27, 33, 2, 4, purple)
    for x in [19, 32] { c.pattern(x, 33, ["KK.", "..K", ".K.", "...", ".K."], ["K": ink]) }
    c.rect(18, 26, 2, 2, hair); c.rect(36, 26, 2, 2, hair)
    c.pattern(18, 19, [
        "......GGGGGGGG......",
        ".....GGGLGGGGGG.....",
        "....GGGLGGGGGGGG....",
        "....GGGGGGGGGGGG....",
        "....GGGGGGGGGGGG....",
        "....PPPPPPPPPPPP....",
        "GGGGGGGGGGGGGGGGGGGG",
    ], ["G": green, "L": greenLight, "P": purple])
    c.px(17, 24, green); c.px(38, 24, green)
    c.rect(15, 33, 3, 3, green)

    if let s = p.signature {
        let k = habitArc(s, hold: 0.6)
        if k > 0.05 {
            let bang = s > 0.6
            let pulse = 0.7 + 0.3 * sin(p.t * 10)
            c.glowLine(28, 10, 28, 10, core: clear, glow: greenLight, coreR: 0, glowR: 6 * k, strength: 0.45 * pulse)
            drawBigMark(c, x: 26, y: 6 + Int(((1 - k) * 4).rounded()), bang: bang, C(0x5AE85A).alpha(k))
            for n in 0..<2 {
                let f = frac(s * 2 + Double(n) * 0.5)
                c.pattern(n == 0 ? 15 : 39, 16 - Int(f * 8), [".Q.", "..Q", ".Q.", "...", ".Q."], ["Q": greenLight.alpha(1 - f)])
            }
        }
    }

    if let a = p.melee {
        let pv = Sprite.hand, r = a * .pi / 180
        for (i, ta) in p.trail.enumerated() {
            let tr = ta * .pi / 180
            c.glowLine(pv.x + cos(tr) * 4, pv.y + sin(tr) * 4, pv.x + cos(tr) * 16, pv.y + sin(tr) * 16,
                       core: greenLight, glow: greenLight, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
        }
        let tip = (pv.x + cos(r) * 12, pv.y + sin(r) * 12)
        stick(c, pv.x - cos(r) * 2, pv.y - sin(r) * 2, tip.0, tip.1, C(0x3A3A40), 0.6)
        drawCaneHead(c, x: Int(tip.0.rounded()) - 2, y: Int(tip.1.rounded()) - 5)
    } else {
        // Leaning on it.
        stick(c, 41.5, 34, 42.5, 43, C(0x3A3A40), 0.6)
        drawCaneHead(c, x: 39, y: 29)
    }
    c.rect(38, 33, 3, 3, green)
}

/// The gold question mark on the end of the Riddler's cane, its top-left at (x, y).
private func drawCaneHead(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [".GGG.", "G...G", "....G", "...G.", "..G..", "..G.."], ["G": C(0xE8B530)])
    c.px(x + 1, y, C(0xFFE08A))
}

// MARK: - Two-Face

/// Two-Face: split down the middle. The left half is Harvey Dent (neat brown hair, a white suit), the front half is
/// the scarred side: purple-pink burnt skin, a bulging red eye, bared teeth, wild white hair and a black suit. He
/// shoots a pistol. Signature: he flips his coin, high, catches it, and looks.
private func drawTwoFace(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE8BE9C), skinDark = C(0xC09878), scar = C(0x9A5A78), scarDark = C(0x6E3A56), scarGreen = C(0x7A8A5A)
    let light = C(0xE4E4E8), lightDark = C(0xB0B0B8), black = C(0x1E1E24), blackLight = C(0x3A3A44)
    let brown = C(0x4A3426), wild = C(0xD8D8D0)
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let col = lx < 28 ? light : black
        if seatedPose { c.rect(lx - 1, 38, 4, 2, col); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 2, lifted ? 7 : 8, col)
        c.rect(lx, lifted ? 42 : 43, 2, 1, lx < 28 ? C(0x5A3A2A) : ink)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: black, eye: nil))
    c.rect(15, 33, 3, 3, light)
    for y in 26...33 {
        let e = 28 + (y % 3 == 0 ? -1 : 0) + (y == 31 ? 1 : 0)
        c.rect(e, y, 38 - e, 1, scar)
    }
    c.rect(37, 26, 1, 8, scarDark)
    for (x, y) in [(30, 27), (35, 27), (29, 31), (36, 32), (34, 26)] { c.px(x, y, scarGreen) }
    c.rect(21, 28, 3, 1, brown)
    c.rect(22, 29, 2, 3, ink)
    c.pattern(31, 28, [".WWW.", "WWRRW", "WWRRW", ".WWW."], ["W": C(0xF4F0E0), "R": C(0xC8202A)])
    c.rect(23, 33, 4, 1, skinDark)
    c.pattern(28, 32, ["DDDDDD", "WKWKWD"], ["D": scarDark, "W": C(0xF4F0E0), "K": ink])
    // Hair: combed on the good side, wild on the other.
    c.pattern(17, 22, [
        "...bbbbbbbb.........",
        ".bbbBbbbbbb..W.W.W..",
        "bbbBbbbbbbbWWWWWWWW.",
        "bbbbbbbbbbbWWWWWWWWW",
        "bb.........WW..W..WW",
        "b..................W",
    ], ["b": brown, "B": C(0x6A5040), "W": wild])
    // The suit: white on one side, black on the other.
    c.rect(18, 34, 10, 4, light); c.rect(28, 34, 10, 4, black)
    c.rect(18, 37, 10, 1, lightDark); c.rect(37, 34, 1, 4, blackLight)
    c.rect(25, 34, 2, 3, white); c.rect(28, 34, 2, 3, C(0x8A8A90))
    c.rect(27, 34, 1, 3, C(0x2A2A30)); c.rect(28, 34, 1, 3, C(0xC8202A))

    if let s = p.signature {
        // The coin: up it goes, spinning, and back into his palm.
        c.rect(38, 32, 3, 3, scar)
        let silver = C(0xE0E0E8), edge = C(0x8A8A94)
        if s < 0.72 {
            let u = max(0, (s - 0.06) / 0.66)
            let y = 30 - Int((sin(u * .pi) * 18).rounded())
            let frame = Int(p.t * 16) % 3
            let w = [3, 1, 2][frame]
            c.rect(41 - w / 2, y, w, 2, frame == 1 ? edge : silver)
        } else {
            let start = Int((p.lt - s * 2.8).rounded())
            let scarred = noise(start * 13) > 0.5
            c.pattern(39, 29, [".SS.", "SSSS", "SSSS", ".SS."], ["S": scarred ? C(0xB0A8A0) : silver])
            if scarred { c.px(40, 30, scarDark); c.px(41, 31, scarDark); c.px(41, 30, scarDark) }
            else { c.px(40, 30, white) }
        }
        return
    }
    drawPistol(c, x: 40, y: 31 + p.gunY)
    c.rect(38, 33, 3, 3, scar)
}

// MARK: - Scarecrow

/// Scarecrow: a stitched burlap sack for a face with ragged eye holes and a sewn-up mouth, a floppy pointed hat, a
/// hangman's noose round his neck, a patched coat and straw poking out of his sleeves; fear gas pours from his
/// hand. Signature: his eyes burn red and a cloud of fear gas billows up all round him.
private func drawScarecrow(_ c: PixelCanvas, _ p: Pose) {
    let burlap = C(0xB89A6A), burlapDark = C(0x8E7448), hat = C(0x5A4430), hatDark = C(0x3E2E20)
    let coat = C(0x4A4632), coatDark = C(0x302E20), straw = C(0xE8C860), rope = C(0xC8A870), ropeDark = C(0x9A7E50)
    let k = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    drawLegs(c, Look(leg: C(0x3A3426)), step: p.step)
    drawBoots(c, burlapDark, step: p.step, rows: 2)
    c.oy += p.breathe
    let raise = p.armRaise
    drawBody(c, Look(body: burlap, shade: burlapDark, arm: coat, eye: nil), armRight: raise)
    for y in stride(from: 27, to: 34, by: 2) {
        for x in stride(from: 19 + (y / 2) % 2, to: 37, by: 3) { c.px(x, y, burlapDark) }
    }
    let eye = k > 0.3 ? C(0xFF3A2A) : C(0xD8F04A)
    c.pattern(21, 28, [".KK........KK.", "KKKK......KKKK", "KEEK......KEEK", ".KK........KK."], ["K": ink, "E": eye])
    if k > 0.3 {
        for x in [22.5, 32.5] as [Double] {
            c.glowLine(x, 30.5, x + 1, 30.5, core: clear, glow: C(0xFF3A2A), coreR: 0, glowR: 2.2, strength: 0.6 * k)
        }
    }
    c.rect(23, 32, 10, 1, ink)
    for x in stride(from: 23, to: 33, by: 2) { c.px(x, 31, ink); c.px(x, 33, ink) }
    // The noose and the coat.
    c.rect(18, 34, 20, 1, rope)
    for x in stride(from: 19, to: 38, by: 2) { c.px(x, 34, ropeDark) }
    c.rect(18, 35, 20, 3, coat)
    c.rect(37, 35, 1, 3, coatDark)
    for x in stride(from: 18, to: 38, by: 3) { c.px(x, 38, coat) }
    c.rect(20, 36, 3, 2, C(0x6A5A3A)); c.px(21, 36, coatDark)
    c.rect(29, 34, 3, 4, rope); c.rect(29, 35, 3, 1, ropeDark); c.rect(29, 37, 3, 1, ropeDark)
    c.rect(30, 38, 1, 2, rope)
    // Straw out of the sleeves.
    c.px(14, 34, straw); c.px(14, 36, straw); c.px(15, 37, straw)
    c.px(41, 33 - raise, straw); c.px(41, 35 - raise, straw); c.px(42, 34 - raise, straw)
    c.px(39, 32 - raise, C(0x8AD83A))
    // The floppy hat, its tip bent back.
    for y in 13...23 {
        let f = Double(y - 13) / 10
        let half = 1 + f * 8, centre = 24 + f * 4
        c.rect(Int((centre - half).rounded()), y, Int((half * 2).rounded()), 1, hat)
    }
    c.rect(21, 12, 3, 2, hat); c.px(20, 13, hat)
    c.rect(19, 21, 18, 2, hatDark)
    c.rect(14, 24, 28, 2, hat)
    c.px(12, 25, hat); c.px(13, 25, hat); c.px(42, 25, hat); c.px(43, 26, hat)
    c.rect(28, 17, 3, 3, C(0x7A6040)); c.px(29, 17, hatDark)
    for (x, y) in [(17, 26), (19, 27), (36, 26), (38, 27), (18, 27)] { c.px(x, y, straw) }

    if k > 0.02 {
        // Fear gas, billowing up round him.
        for n in 0..<10 {
            let f = frac(p.t * 0.5 + Double(n) / 10)
            let side = noise(n * 7) - 0.5
            let x = 28 + side * 34 + sin(f * 6 + Double(n)) * 2
            let y = 42 - f * 30
            disc(c, x, y, 2 + f * 3, C(0xB8FF4A).alpha(k * 0.42 * (1 - f * 0.7)))
            c.px(Int(x), Int(y - 1 - f * 2), C(0xF0FFD0).alpha(k * 0.5 * (1 - f)))
        }
    }
}

// MARK: - Poison Ivy

/// Poison Ivy: pale green-tinged skin, a great mane of red hair with a leaf in it, green eyes and red lips, a bodice
/// of leaves and green tights twined with vines. Vines pour from her hand. Signature: vines sprout from the floor on
/// either side of her, curl up, and bloom into red roses.
private func drawPoisonIvy(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xEAF2DC), skinDark = C(0xC4D4B0), leaf = C(0x3A9A3A), leafDark = C(0x24702A), leafLight = C(0x6AC85A)
    let hair = C(0xC8321E), hairDark = C(0x8A1E14), hairLight = C(0xE8603A)
    if let s = p.signature {
        drawIvyVines(c, s: s, t: p.lt)
    }
    drawLegs(c, Look(leg: leafDark), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let off = p.step >= 0 && i % 2 == p.step ? -1 : 0
            c.px(lx, 37 + off, leafLight); c.px(lx + 1, 39 + off, leafLight); c.px(lx, 41 + off, leafLight)
        }
    }
    c.oy += p.breathe
    // Long hair down her back, in waves.
    for y in 26...37 {
        let w = 4 + (y / 2) % 2
        c.rect(15 - (y / 3) % 2, y, w, 1, hair)
        if y % 3 == 0 { c.px(15, y, hairDark) }
    }
    c.rect(37, 26, 4, 7, hair); c.rect(40, 27, 1, 5, hairDark)
    drawBody(c, Look(body: skin, shade: skinDark, arm: skin, eye: nil), armRight: p.armRaise)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(23, 30, leafLight); c.px(33, 30, leafLight)
    c.px(21, 29, ink); c.px(34, 29, ink)
    c.rect(26, 33, 4, 1, C(0xC82A3A))
    // The leaf bodice.
    c.rect(18, 35, 20, 3, leaf)
    for x in stride(from: 18, to: 38, by: 3) { c.px(x + 1, 34, leaf); c.px(x, 36, leafDark); c.px(x + 2, 37, leafLight) }
    c.rect(37, 35, 1, 3, leafDark)
    c.pattern(15, 19, [
        ".....hHHHHHHHHHHHHh.......",
        "...HHHHLHHHHHHHHHHHHHH....",
        "..HHHLHHHHHHHHLHHHHHHHH...",
        ".HHHLHHHHHHHHLHHHHHHHHHH..",
        "HHHHHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHdHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHH....HHHHH",
        "HHHH..HHHHHHHH........HHHH",
        "HHH.........HH.........HHH",
    ], ["H": hair, "h": hairDark, "d": hairDark, "L": hairLight])
    c.pattern(18, 18, ["LL.", "LLL", ".Ld"], ["L": leafLight, "d": leafDark])
    // Vines round her wrist.
    c.px(38, 33 - p.armRaise, leaf); c.px(40, 35 - p.armRaise, leaf); c.px(39, 34 - p.armRaise, leafDark)
}

/// Ivy's signature: two vines climbing from the floor beside her, leafing out and blooming into roses.
private func drawIvyVines(_ c: PixelCanvas, s: Double, t: Double) {
    let grow = habitArc(s, hold: 0.55)
    let vine = C(0x2E7A2E), leaf = C(0x5AC04A), rose = C(0xD8202E), roseDark = C(0x8A101C)
    for (n, base) in [10.0, 46.0].enumerated() {
        let h = grow * 18
        guard h > 1 else { continue }
        var prev = (x: base, y: 43.0)
        let steps = Int(h)
        for i in 1...steps {
            let y = 43 - Double(i)
            let x = base + sin(Double(i) * 0.45 + t * 2 + Double(n) * 2) * 2.2
            stick(c, prev.x, prev.y, x, y, vine, 0.6)
            if i % 4 == 2 { c.px(Int(x) + (i % 8 == 2 ? 1 : -2), Int(y), leaf); c.px(Int(x) + (i % 8 == 2 ? 2 : -1), Int(y) - 1, leaf) }
            prev = (x, y)
        }
        if grow > 0.85 {
            let r = (grow - 0.85) / 0.15
            let cx = Int(prev.x.rounded()), cy = Int(prev.y.rounded()) - 1
            if r > 0.5 { c.pattern(cx - 2, cy - 2, [".RR.", "RDRR", "RRDR", ".RR."], ["R": rose, "D": roseDark]) }
            else { c.rect(cx - 1, cy - 1, 2, 2, rose) }
        }
    }
}

// MARK: - Mr. Freeze

/// Mr. Freeze: a pale blue, bald Clawd in red goggles under a glass dome, a silver cryo-suit with glowing blue coolant
/// lines and heavy boots, and the big freeze gun. Signature: the gun goes down and he holds up his snow globe, a
/// tiny ballerina inside, snow swirling round her.
private func drawMrFreeze(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xC8D0D8), suitDark = C(0x8A949E), suitLight = C(0xEEF2F6), blue = C(0x5AC8FF), blueHot = C(0xD8F4FF)
    let skin = C(0xC8E4F4), skinDark = C(0x9CC0D8), red = C(0xE0302A)
    drawLegs(c, Look(leg: suitDark), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx - 1, bottom - 2, 4, 3, suit); c.rect(lx - 1, bottom - 2, 4, 1, suitLight)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: suit, eye: nil))
    // The bald head inside the dome.
    c.pattern(19, 21, ["....SSSSSSSSSS....", "..SSSLSSSSSSSSSS..", ".SSSLSSSSSSSSSSSd.", "SSSSSSSSSSSSSSSSdd", "SSSSSSSSSSSSSSSSdd"],
              ["S": skin, "L": C(0xE8F6FF), "d": skinDark])
    c.rect(18, 25, 20, 1, skin); c.rect(37, 25, 1, 1, skinDark)
    c.rect(18, 30, 20, 1, C(0x3A3A44))
    c.pattern(21, 29, ["RRRR......RRRR", "RHRR......RHRR", "RRRR......RRRR"], ["R": red, "H": C(0xFFB0A0)])
    c.rect(25, 33, 6, 1, skinDark)
    // The cryo-suit.
    c.rect(16, 34, 24, 4, suit)
    c.rect(16, 34, 24, 1, suitLight)
    c.rect(39, 34, 1, 4, suitDark); c.rect(16, 37, 24, 1, suitDark)
    c.rect(24, 35, 8, 2, suitDark)
    let pulse = 0.6 + 0.4 * sin(p.t * 5)
    c.rect(25, 35, 6, 1, blue.alpha(pulse)); c.px(27, 35, blueHot)
    c.px(19, 36, blue); c.px(36, 36, blue)
    // The dome.
    for y in 17...33 {
        let dy = Double(33 - y) / 16.5
        let half = Int((11.5 * sqrt(max(0, 1 - dy * dy))).rounded())
        let l = 28 - half, r = 27 + half
        c.rect(l, y, r - l + 1, 1, C(0xBFEFFF, y < 26 ? 0.22 : 0.1))
        c.px(l, y, C(0xD8F6FF, 0.8)); c.px(r, y, C(0xD8F6FF, 0.8))
        if y == 17 { c.rect(l, y, r - l + 1, 1, C(0xD8F6FF, 0.8)) }
    }
    c.rect(20, 19, 3, 1, C(0xFFFFFF, 0.75)); c.rect(19, 20, 1, 3, C(0xFFFFFF, 0.75))
    for n in 0..<3 {
        let f = frac(p.lt * 0.4 + Double(n) / 3)
        c.px(23 + n * 5, 25 - Int(f * 6), C(0xFFFFFF, 0.5 * (1 - f)))
    }
    c.rect(16, 33, 24, 1, suitDark)
    c.rect(13, 34, 3, 3, suit)

    if let s = p.signature {
        // The snow globe.
        let k = habitArc(s, hold: 0.6)
        let hy = 33 - Int((k * 6).rounded())
        c.rect(38, hy, 3, 36 - hy, suit)
        if k > 0.3 {
            let cx = 40.5, cy = Double(hy) - 3.5
            c.rect(38, hy - 1, 6, 2, C(0xC8A040))
            disc(c, cx + 0.5, cy, 3.5, C(0xBFEFFF, 0.45))
            c.pattern(40, Int(cy) - 1, [".P", "PP", ".P"], ["P": C(0xF0A8C8)])
            c.px(39, Int(cy) - 2, white)
            for n in 0..<4 {
                let a = p.t * 3 + Double(n) * 1.6
                c.px(Int(cx + cos(a) * 2.4), Int(cy + sin(a * 1.3) * 2.2), white)
            }
        }
        return
    }
    // The freeze gun.
    let y = 30 + p.gunY
    c.rect(41, y + 1, 13, 3, suit)
    c.rect(41, y + 1, 13, 1, suitLight)
    c.rect(41, y + 3, 13, 1, suitDark)
    c.rect(53, y, 3, 5, suitDark); c.rect(53, y, 3, 1, suit)
    for x in stride(from: 43, to: 51, by: 2) { c.px(x, y + 2, blue.alpha(pulse)) }
    c.px(55, y + 2, blueHot)
    c.rect(42, y + 4, 3, 3, suitDark)
    stick(c, 39, 37, 43, Double(y) + 5.5, C(0x5A6A7A), 0.5)
    c.rect(38, y + 3, 4, 3, suit)
}

// MARK: - Bane

private let baneShoulder = (x: 40.5, y: 24.5)

/// Bane: a huge Clawd, bare-chested in black combat trousers, under the black luchador mask with its grey stitching
/// and mouth grille; green Venom tubes run from the back of his head to the pump on his wrist. He punches.
/// Signature: he cranks the Venom dial, the tubes glow, he swells up and flexes.
private func drawBane(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xC8956A), skinDark = C(0xA0724E), mask = C(0x1E1E26), maskLight = C(0x4A4A58)
    let pants = C(0x2A2A32), venom = C(0x3AC84A), venomHot = C(0xC8FF8A)
    let k = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let sw = k > 0.35 ? 1 : 0
    let tube = k > 0.2 && Int(p.t * 8) % 2 == 0 ? venomHot : venom
    drawBigLegs(c, p, leg: pants, foot: C(0x14141A), footRows: 2)
    c.oy += p.breathe
    // The left arm, hanging, with the Venom pump on the wrist.
    c.rect(10 - sw, 21, 5, 11, skin); c.rect(10 - sw, 21, 1, 11, skinDark)
    c.rect(9 - sw, 31, 6, 6, mask); c.rect(9 - sw, 31, 6, 1, maskLight)
    c.rect(10 - sw, 32, 2, 2, tube)
    // The body: a bare chest under the mask.
    c.rect(15 - sw, 19 - sw, 26 + 2 * sw, 19 + sw, skin)
    c.rect(40 + sw, 19, 1, 19, skinDark)
    c.rect(18, 31, 8, 1, skinDark); c.rect(30, 31, 8, 1, skinDark)
    c.rect(27, 30, 1, 6, skinDark)
    c.rect(23, 33, 3, 1, skinDark); c.rect(30, 33, 3, 1, skinDark)
    if k > 0.35 {
        for (x, y) in [(18, 33), (19, 35), (35, 32), (36, 34), (12, 24), (11, 27)] { c.px(x - (x < 15 ? sw : 0), y, venom) }
    }
    c.rect(15 - sw, 36, 26 + 2 * sw, 2, C(0x3A3A44))
    c.rect(26, 36, 4, 2, C(0x9A9AA4))
    c.pattern(15 - sw, 16 - sw, [
        "......MMMMMMMMMMMMMM......",
        "...MMMMMMMMMMMMMMMMMMMM...",
        ".MMMMMMMMMMMMMMMMMMMMMMMM.",
        "MMMMMMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMMMMMM",
        "MMMMMMMMMMMMMMMMMMMMMMMMMM",
        ".MMMMMMMMMMMMMMMMMMMMMMMM.",
        "...MMMMMMMMMMMMMMMMMMMM...",
    ], ["M": mask])
    c.rect(28, 16 - sw, 1, 5, maskLight)
    c.pattern(18, 21, ["LLLLLLL....LLLLLLL", "LSKKSSL....LSSKKSL", "LSKKSSL....LSSKKSL", "LLLLLLL....LLLLLLL"],
              ["L": maskLight, "S": skin, "K": ink])
    c.rect(23, 26, 10, 2, maskLight)
    for x in stride(from: 24, to: 33, by: 2) { c.px(x, 26, mask); c.px(x, 27, mask) }
    // The Venom tubes.
    stick(c, 17, 18, 13, 22, tube, 0.6); stick(c, 13, 22, 9.5, 30, tube, 0.6)
    stick(c, 39, 19, 42, 22, tube, 0.6)
    if k > 0.1 {
        for (x, y) in [(13.0, 22.0), (41.0, 21.0), (10.5, 32.5)] as [(Double, Double)] {
            c.glowLine(x, y, x, y, core: clear, glow: venomHot, coreR: 0, glowR: 3 * k, strength: 0.5)
        }
    }

    // The right arm: a punch, or a flex in the signature.
    if k > 0.5 {
        drawBaneArm(c, angle: -70, swell: sw)
        return
    }
    for (i, ta) in p.trail.enumerated() { drawBaneArm(c, angle: ta, swell: sw, alpha: 0.35 / Double(i + 1)) }
    drawBaneArm(c, angle: p.melee ?? 82, swell: sw)
}

/// Bane's right arm swung from the shoulder, a black-gloved fist on the end.
private func drawBaneArm(_ c: PixelCanvas, angle: Double, swell: Int, alpha: Double = 1) {
    prop(c, at: baneShoulder, angle: angle, alpha: alpha) { s in
        let skin = C(0xC8956A), shade = C(0xA0724E), glove = C(0x1E1E26)
        s.rect(18, 18 - swell, 9, 5 + swell, skin)
        s.rect(18, 22, 9, 1, shade)
        s.rect(26, 16, 7, 8, glove)
        s.rect(26, 16, 7, 1, C(0x4A4A58))
        s.px(29, 18, C(0x3A3A44)); s.px(29, 20, C(0x3A3A44))
    }
}

// MARK: - Killer Croc

private let crocShoulder = (x: 40.5, y: 29.5)

/// Killer Croc: a hulking green scaly brute with a long toothy snout, yellow slit eyes, a pale belly, ragged
/// trousers and a thick tail; he fights with clawed fists, and bullets bounce off his hide. Signature: his jaws
/// snap twice, then he roars and thumps his tail.
private func drawKillerCroc(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x5A7A3A), dark = C(0x3A5426), light = C(0x8AA85A), belly = C(0xC8C890), bellyDark = C(0xA0A070)
    let pants = C(0x6A5A44), pantsDark = C(0x4A3E2E), mouth = C(0x8A2A3A), tooth = C(0xF0ECE0)
    let sig = p.signature
    var open: Double = p.melee.map { a in max(0, 1 - abs(a - 5) / 50) } ?? 0
    var thump = 0.0
    if let s = sig {
        if s < 0.5 { open = abs(sin(s / 0.5 * .pi * 2)) }
        else if s < 0.9 { open = 1 }
        if s > 0.55 && s < 0.9 { thump = sin((s - 0.55) / 0.35 * .pi * 3) }
    }
    drawBigLegs(c, p, leg: green, foot: dark, footRows: 1)
    if !seatedPose {
        for lx in [16, 21, 31, 36] { c.rect(lx, 36, 3, 3, pants); c.px(lx + 1, 39, pants) }
    }
    c.oy += p.breathe
    // The tail, low behind him.
    for x in 2...16 {
        let f = Double(16 - x) / 14
        let mid = 38 + f * 2 - thump * f * f * 5 + sin(p.lt * 1.6 + f * 3) * f * 0.8
        let half = 3.0 - f * 2.2
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, green)
        c.px(x, bottom, dark)
        if x % 3 == 0 { c.px(x, top - 1, dark) }
    }
    // The left arm, hanging, claws out.
    c.rect(10, 22, 5, 10, green); c.rect(10, 22, 1, 10, dark)
    c.rect(9, 31, 6, 5, green)
    for x in [9, 11, 13] { c.px(x, 36, tooth) }
    // The body: scales over the top, the pale belly underneath.
    c.rect(15, 19, 26, 19, green)
    c.rect(40, 19, 1, 19, dark)
    for y in stride(from: 20, to: 30, by: 2) {
        for x in stride(from: 16 + (y / 2) % 2 * 2, to: 40, by: 4) { c.px(x, y, dark); c.px(x + 1, y, light) }
    }
    for x in stride(from: 17, to: 40, by: 3) { c.rect(x, 18, 2, 1, dark) }
    c.rect(20, 28, 15, 8, belly)
    for y in [30, 32, 34] { c.rect(20, y, 15, 1, bellyDark) }
    c.rect(15, 36, 26, 2, pants)
    for x in stride(from: 15, to: 41, by: 3) { c.px(x, 38, pants); c.px(x + 1, 37, pantsDark) }
    c.pattern(21, 22, ["YYY.......YYY", "YKY.......YKY"], ["Y": C(0xF0D02A), "K": ink])
    c.rect(20, 21, 5, 1, dark); c.rect(30, 21, 5, 1, dark)
    // The snout: the upper jaw, then the lower one dropped open by `o`.
    let o = Int((3 * open).rounded())
    c.pattern(37, 21, [
        "GGGGGGGGGGGN.",
        "GGGGGGGGGGGGG",
        "GgGGgGGgGGgGG",
        "GTgTgTgTgTgT.",
    ], ["G": green, "g": dark, "N": ink, "T": tooth])
    if o > 0 { c.rect(39, 25, 10, o, mouth) }
    c.pattern(37, 25 + o, ["GtGtGtGtGtG.", "GGGGGGGGGGG.", "BBBBBBBBBB.."], ["G": green, "t": tooth, "B": belly])
    if let s = sig, s > 0.5, s < 0.9 {
        let n = Int(p.lt * 12) % 3
        for i in 0..<3 where (i + n) % 3 != 0 {
            let r = 4 + i * 3
            for d in -1...1 { c.px(49 + r, 26 + d * (1 + i), C(0xFFFFFF, 0.7)) }
        }
    }

    for (i, ta) in p.trail.enumerated() { drawCrocArm(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
    drawCrocArm(c, angle: p.melee ?? 84)
}

/// Croc's right arm swung from the shoulder, a clawed green fist on the end.
private func drawCrocArm(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: crocShoulder, angle: angle, alpha: alpha) { s in
        let green = C(0x5A7A3A), dark = C(0x3A5426)
        s.rect(18, 18, 9, 5, green)
        s.rect(18, 22, 9, 1, dark)
        s.rect(26, 16, 6, 8, green)
        s.rect(26, 23, 6, 1, dark)
        for y in [16, 19, 22] { s.rect(32, y, 2, 1, C(0xF0ECE0)) }
    }
}

// MARK: - Ra's al Ghul

/// Ra's al Ghul: black hair swept back with grey at the temples, hard brows, a moustache and a pointed beard, green
/// robes with a gold sash and a dark green cloak, and a curved sword (sheathed at his hip when he isn't using it).
/// Signature: the green light of the Lazarus Pit rises round him; while it burns his temples go black again.
private func drawRasAlGhul(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x2E6E3E), robeDark = C(0x1E4A2A), gold = C(0xD8B040), skin = C(0xC8986E), skinDark = C(0xA07450)
    let hair = C(0x1A1A1E), grey = C(0xB8B8C0), lazarus = C(0x5AF07A)
    let k = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    if k > 0.02 {
        for n in 0..<8 {
            let f = frac(p.t * 0.8 + Double(n) / 8)
            let x = 14 + noise(n * 5) * 28
            c.glowLine(x, 43 - f * 26, x, 43 - f * 26, core: clear, glow: lazarus, coreR: 0, glowR: 2.5, strength: k * 0.6 * (1 - f))
        }
    }
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: robeDark, edge: C(0x12321C))
    drawLegs(c, Look(leg: C(0x2A2A22)), step: p.step)
    drawBoots(c, C(0x4A3A28), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: robe, eye: nil))
    c.pattern(21, 28, ["HHHH......HHHH", ".KK........KK.", ".KK........KK."], ["H": hair, "K": ink])
    if k > 0.4 { c.px(22, 29, lazarus); c.px(32, 29, lazarus) }
    c.pattern(23, 32, ["HHHHHHHHHH", "HH.HHHH.HH", "...HgHH...", "....HH....", "....H....."], ["H": hair, "g": grey])
    // The robes, the sash and a skirt over the legs.
    c.rect(18, 34, 20, 4, robe)
    c.rect(37, 34, 1, 4, robeDark)
    c.pattern(24, 34, ["G......G", ".G....G.", "..G..G.."], ["G": gold])
    c.rect(18, 37, 20, 1, gold)
    if !seatedPose {
        c.rect(18, 38, 20, 2, robe)
        c.rect(18, 40, 20, 1, gold)
        c.rect(27, 38, 1, 3, robeDark)
    }
    // Swept-back hair, grey at the temples (black again in the Pit's light).
    let temple = k > 0.5 ? hair : grey
    c.pattern(17, 21, [
        "......HHHHHHHHHH......",
        "...HHHhhHHHHHHHHHHH...",
        ".HHHHHHHhhHHHHHHHHHHH.",
        "HHHHHHHHHHhhHHHHHHHHHH",
        "TTHHHHHHHHHHHhhHHHHHTT",
        "TTTHHHHHH...HHHHHHHTTT",
        "TTTT.......H.......TTT",
        "TT...................T",
    ], ["H": hair, "h": C(0x4A4A56), "T": temple])
    c.rect(15, 33, 3, 3, robe)

    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawScimitar(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawScimitar(c, angle: a)
    } else {
        stick(c, 18, 37, 9, 41, C(0x3A2A1E), 1.0)
        c.rect(18, 35, 2, 3, gold); c.px(20, 36, gold)
    }
    c.rect(38, 33, 3, 3, robe)
    if k > 0.3 { shimmer(c, lazarus, amount: 0.05 * k, seed: Int(p.t * 12)) }
}

/// Ra's al Ghul's scimitar at `angle`: a gold hilt and a curved steel blade.
private func drawScimitar(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: Sprite.hand, angle: angle, alpha: alpha) { s in
        let steel = C(0xC8CCD4), steelLight = C(0xF0F2F6), gold = C(0xD8B040)
        s.rect(16, 20, 4, 1, C(0x5A3A22))
        s.rect(20, 18, 1, 5, gold)
        for x in 21...35 {
            let u = Double(x - 21) / 14
            let y = 20 - Int((u * u * 3).rounded())
            s.rect(x, y, 1, x < 33 ? 2 : 1, steel)
            s.px(x, y, steelLight)
        }
    }
}
