import Foundation

// Villains: the Flash's Rogues and the evil speedsters. Every one is Clawd in costume: cowls, parkas, goggles, fur
// and armour drawn over and around the blocky body; where a face shows, it's Clawd's own orange. Speedsters crackle
// with lightning in their own colour and smear when they strike.

let villains6: [Leader: Persona] = [
    .reverseFlash: Persona(name: "Reverse-Flash", weapon: .melee, headTop: 21, signature: 2.6,
                  callout: "Always one step ahead, Flash.",
                  draw: drawReverseFlash),
    .zoom: Persona(name: "Zoom", weapon: .melee, headTop: 21, signature: 2.8, callout: "I am Zoom.",
                  draw: drawZoom),
    .captainCold: Persona(name: "Captain Cold", weapon: .ranged, shot: .ice, muzzle: (53, 33), headTop: 19,
                  signature: 3.2, callout: "Chill out, Flash.",
                  draw: drawCaptainCold),
    .heatWave: Persona(name: "Heat Wave", weapon: .ranged, shot: .fire, muzzle: (53, 33), headTop: 19,
                  signature: 3.0, callout: "Burn, baby, burn!",
                  draw: drawHeatWave),
    .mirrorMaster: Persona(name: "Mirror Master", weapon: .ranged, shot: .energy(core: C(0xF0FFFF), glow: C(0x6AE8E8)),
                  muzzle: (51, 33), headTop: 20, signature: 3.4, callout: "Look into the mirror, Flash.",
                  draw: drawMirrorMaster),
    .gorillaGrodd: Persona(name: "Gorilla Grodd", weapon: .magic, magic: Magic(core: C(0xFFF0FF), glow: C(0xD86AE8), jagged: false),
                  pivot: (40.5, 26.5), bulk: 5, headTop: 15, signature: 3.0, callout: "Bow before Grodd!",
                  draw: drawGorillaGrodd),
    .weatherWizard: Persona(name: "Weather Wizard", weapon: .magic, magic: Magic(core: C(0xF4F8FF), glow: C(0x7FB2FF)),
                  pivot: (44.5, 24.5), headTop: 19, signature: 3.4, callout: "Forecast: pain.",
                  draw: drawWeatherWizard),
    .captainBoomerang: Persona(name: "Captain Boomerang", weapon: .ranged, shot: .thrown(C(0xC8A86A)), muzzle: (45, 31),
                  handGun: false, headTop: 19, signature: 3.0, callout: "Oi! Heads up, mate!",
                  draw: drawCaptainBoomerang),
    .trickster: Persona(name: "The Trickster", weapon: .ranged, motion: .fly, shot: .thrown(C(0xFF6AA8)), muzzle: (45, 32),
                  handGun: false, headTop: 19, signature: 3.0, callout: "Ha! Gotcha!",
                  draw: drawTrickster),
    .savitar: Persona(name: "Savitar", weapon: .melee, armoured: true, pivot: (40.5, 30.5), bulk: 4, headTop: 12,
                  signature: 3.0, callout: "I am the god of speed!",
                  draw: drawSavitar),
    .goldenGlider: Persona(name: "Golden Glider", weapon: .melee, motion: .fly, pivot: (36.5, 37.5), headTop: 18,
                  signature: 2.8, callout: "Shall we dance, Flash?",
                  draw: drawGoldenGlider),
]

// MARK: - Shared bits

private let clear = C(0, 0)

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from `h` along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r: Double = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`, leaning
/// forward one pixel every `lean` rows above the feet (0: upright), and only the sprite rows `rows` (nil: all of it).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, dx: Int = 0, rows: Range<Int>? = nil,
                   _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY, top = c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        if let rows, !rows.contains(y - top) { continue }
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

/// Boots `rows` tall ending on the feet's row `bottom`, following the walk; tucked under when sitting.
private func boots(_ c: PixelCanvas, _ p: Pose, rows: Int, bottom: Int = 43, _ col: Px) {
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 39, 4, 1, col) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, (lifted ? bottom - 1 : bottom) - rows + 1, 2, rows, col)
    }
}

/// A puff of smoke, steam or air at (`x`, `y`), `k` 0…1 through its life: it swells and fades.
private func puff(_ c: PixelCanvas, x: Double, y: Double, k: Double, _ col: Px) {
    guard k > 0, k < 1 else { return }
    let r = Int((1 + k * 2).rounded())
    c.circle(Int(x.rounded()), Int(y.rounded()), r, col.alpha(0.7 * (1 - k)))
}

/// An ellipse outline of single pixels.
private func ring(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px, n: Int = 40) {
    for i in 0..<n {
        let a: Double = Double(i) / Double(n) * 2 * .pi
        c.px(Int((cx + cos(a) * rx).rounded()), Int((cy + sin(a) * ry).rounded()), col)
    }
}

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

/// A short forked bolt from (x, y), `n` jagged steps of about `step` pixels heading `angle` degrees.
private func bolt(_ c: PixelCanvas, x: Double, y: Double, angle: Double, step: Double, n: Int, seed: Int, core: Px, glow: Px,
                  strength: Double = 1) {
    var px: Double = x, py: Double = y
    let r: Double = angle * .pi / 180
    for j in 0..<n {
        let wob: Double = (noise(seed * 7 + j) - 0.5) * step * 1.4
        let nx: Double = px + cos(r) * step - sin(r) * wob
        let ny: Double = py + sin(r) * step + cos(r) * wob
        c.glowLine(px, py, nx, ny, core: core, glow: glow, coreR: 0.4, glowR: 1.4, strength: strength)
        px = nx; py = ny
    }
}

/// Lightning crackling round a speedster: `n` little forked arcs flickering over and around the body.
private func crackle(_ c: PixelCanvas, t: Double, seed: Int, core: Px, glow: Px, n: Int,
                     area: (x: Double, y: Double, w: Double, h: Double) = (13, 21, 30, 22)) {
    let i = Int(t * 16)
    for k in 0..<n {
        let s = i * 13 + k * 101 + seed
        guard noise(s) > 0.3 else { continue }
        let x: Double = area.x + noise(s + 1) * area.w, y: Double = area.y + noise(s + 2) * area.h
        bolt(c, x: x, y: y, angle: noise(s + 3) * 360, step: 2.5, n: 3, seed: s, core: core, glow: glow)
    }
}

/// Speed lines streaming off behind a running speedster, with a thread of its lightning through them.
private func speedLines(_ c: PixelCanvas, t: Double, core: Px, glow: Px) {
    let i = Int(t * 20)
    for (k, y) in [26, 30, 34, 38, 41].enumerated() {
        let len = 4 + Int(noise(i + k * 7) * 8)
        let x0 = 15 - len - Int(noise(i * 3 + k) * 4)
        c.rect(x0, y, len, 1, core.alpha(0.5))
    }
    bolt(c, x: 16, y: 29 + noise(i) * 8, angle: 180, step: 3, n: 4, seed: i, core: core, glow: glow)
}

/// A speedster's punches: the arm out along `angle` with a fist on the end, blurred extra fists flickering round it
/// and, on a fast swing, a lightning smear where the fist just was.
private func speedPunch(_ c: PixelCanvas, angle: Double, trail: [Double], t: Double, arm: Px, fist: Px, core: Px, glow: Px) {
    let h = Sprite.hand
    let k = Int(t * 24)
    for j in 0..<2 {
        let a: Double = angle + (noise(k * 3 + j) - 0.5) * 60
        let e = along(a, 4 + noise(k * 5 + j) * 4)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist.alpha(0.35))
    }
    for (i, a) in trail.enumerated() {
        let e = along(a, 6), e0 = along(a, 2)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist.alpha(0.4 / Double(i + 1)))
        c.glowLine(e0.x, e0.y, e.x, e.y, core: core, glow: glow, coreR: 0.5, glowR: 1.8, strength: 0.6 / Double(i + 1))
    }
    let e = along(angle, 6)
    bar(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist)
    if !trail.isEmpty { bolt(c, x: e.x, y: e.y, angle: angle + 150, step: 2.5, n: 3, seed: k, core: core, glow: glow) }
}

/// Tiny 3×5 letters (the Trickster's flag).
private let glyphs: [Character: [String]] = [
    "B": ["XX.", "X.X", "XX.", "X.X", "XX."],
    "A": [".X.", "X.X", "XXX", "X.X", "X.X"],
    "N": ["X..X", "XX.X", "X.XX", "X..X", "X..X"],
    "G": [".XX", "X..", "X.X", "X.X", ".XX"],
    "!": ["X", "X", "X", ".", "X"],
]

private func tinyText(_ c: PixelCanvas, x: Int, y: Int, _ text: String, _ col: Px) {
    var cx = x
    for ch in text {
        guard let g = glyphs[ch] else { cx += 4; continue }
        c.pattern(cx, y, g, ["X": col])
        cx += g[0].count + 1
    }
}

// MARK: - Reverse-Flash

/// Reverse-Flash (Eobard Thawne): the Flash's suit in negative, yellow with red boots, red lightning-bolt ear wings,
/// a red belt and the red bolt in a black circle on his chest, glowing red eyes in the cowl. Red lightning crackles
/// round him and his punches are a blur. Signature: he's everywhere at once, a dash forward, a dash back past where
/// he started and home again, red lightning and fading yellow afterimages strung out behind.
private func drawReverseFlash(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { reverseFlashArt(c, p); return }
    func pos(_ u: Double) -> Int {
        let keys: [(Double, Double)] = [(0, 0), (0.1, 0), (0.2, 14), (0.38, 14), (0.5, -12), (0.68, -12), (0.8, 0), (1, 0)]
        for i in 1..<keys.count where u < keys[i].0 {
            let (u0, x0) = keys[i - 1], (u1, x1) = keys[i]
            return Int((x0 + (x1 - x0) * (u - u0) / (u1 - u0)).rounded())
        }
        return 0
    }
    let now = pos(s)
    var seen: Set<Int> = [now]
    for k in stride(from: 5, through: 1, by: -1) {
        let x = pos(s - Double(k) * 0.025)
        guard !seen.contains(x) else { continue }
        seen.insert(x)
        layer(c, alpha: 0.45 / Double(k) + 0.1, dx: x) { reverseFlashArt($0, p, ghost: true) }
    }
    let was = pos(s - 0.12)
    if was != now {
        bolt(c, x: 28 + Double(was), y: 31, angle: now > was ? 0 : 180, step: Double(abs(now - was)) / 4, n: 4,
             seed: Int(p.t * 20), core: C(0xFFE0D8), glow: C(0xFF2A2A))
    }
    layer(c, dx: now) { reverseFlashArt($0, p) }
}

private func reverseFlashArt(_ c: PixelCanvas, _ p: Pose, ghost: Bool = false) {
    let yellow = ghost ? C(0xFFE27A) : C(0xF2C21E), yellowDark = ghost ? C(0xE0B04A) : C(0xC0901A)
    let yellowLight = C(0xFFE88A), red = C(0xD8202A), redDark = C(0x941620), black = C(0x18181E)
    let core = C(0xFFE0D8), glow = C(0xFF2A2A)
    let look = Look(body: yellow, shade: yellowDark, leg: yellow, arm: yellow, eye: nil)
    if p.walking && !ghost { speedLines(c, t: p.t, core: core, glow: glow) }
    drawLegs(c, look, step: p.step)
    boots(c, p, rows: 3, red)
    c.oy += p.breathe
    // The red lightning ear wings, swept back off the cowl.
    let wing = ["R...", "RR..", ".RRR", "..RR", ".RR.", "RR.."]
    c.pattern(14, 21, wing, ["R": red])
    c.pattern(38, 21, wing.map { String($0.reversed()) }, ["R": red])
    drawBody(c, look)
    c.pattern(18, 22, [
        "....YYYYYYYYYYYY....",
        "..YYYLLYYYYYYYYYYY..",
        ".YYLLYYYYYYYYYYYYYd.",
        "YYYYYYYYYYYYYYYYYYYd",
    ], ["Y": yellow, "L": yellowLight, "d": yellowDark])
    // The cowl leaves his mouth and chin bare; the eyes glow red.
    c.rect(21, 31, 14, 2, clawdOrange)
    c.rect(25, 32, 6, 1, clawdShade); c.px(31, 31, clawdShade)                // the smirk
    for x in [22, 32] {
        c.rect(x - 1, 28, 4, 3, redDark)
        if !ghost { c.glowLine(Double(x) + 1, 29.5, Double(x) + 1, 29.5, core: C(0xFFD0C8), glow: glow, coreR: 0.8, glowR: 2) }
        c.rect(x, 29, 2, 1, C(0xFF6A5A))
    }
    // Chest: the red bolt in a black circle, a red belt.
    c.rect(18, 36, 20, 1, red)
    c.pattern(25, 33, [".KKKK.", "KKKRRK", "KKRRKK", "KRRKKK", ".KKKK."], ["K": black, "R": red])
    c.rect(15, 33, 3, 3, yellow)
    if let a = p.melee, !ghost {
        speedPunch(c, angle: a, trail: p.trail, t: p.t, arm: yellow, fist: yellow, core: core, glow: glow)
    }
    if !ghost {
        crackle(c, t: p.t, seed: 11, core: core, glow: glow, n: p.trail.isEmpty ? 1 : 3)
    }
}

// MARK: - Zoom

/// Zoom (Hunter Zolomon, by way of the series): the speedster in black, a full black cowl with a stitched grille
/// over the mouth, cold blue eyes, grey ear wings and the blue bolt on a dark emblem; blue lightning crackles round
/// him. Signature: his face vibrates, the head blurring into a ghostly smear round those blue eyes.
private func drawZoom(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { zoomArt(c, p, buzz: 0); return }
    let k = habitArc(s, hold: 0.6)
    let amp = Int((k * 3).rounded())
    let i = Int(p.t * 30)
    if amp > 0 {
        for j in 0..<2 {
            let dx = (j == 0 ? -1 : 1) * (2 + Int(noise(i * 3 + j) * Double(amp)))
            layer(c, alpha: 0.6, dx: dx, rows: 0..<33) { zoomArt($0, p, buzz: k, ghost: true) }
        }
    }
    let jitter = amp > 0 ? Int(noise(i) * 3) - 1 : 0
    layer(c, rows: 33..<52) { zoomArt($0, p, buzz: k) }
    layer(c, dx: jitter, rows: 0..<33) { zoomArt($0, p, buzz: k) }
}

private func zoomArt(_ c: PixelCanvas, _ p: Pose, buzz: Double, ghost: Bool = false) {
    let black = ghost ? C(0x4A6AB8) : C(0x1C1C24), blackDark = C(0x0E0E14), sheen = C(0x3A3A48), grey = C(0x5A5E6A), greyLight = C(0x9AA0AE)
    let core = C(0xE8F4FF), glow = C(0x3A7AFF)
    let look = Look(body: black, shade: blackDark, leg: black, arm: black, eye: nil)
    if p.walking { speedLines(c, t: p.t, core: core, glow: glow) }
    drawLegs(c, look, step: p.step)
    boots(c, p, rows: 3, blackDark)
    c.oy += p.breathe
    let wing = ["G...", "GG..", ".GGG", "..GG", ".GG.", "GG.."]
    c.pattern(14, 21, wing, ["G": grey])
    c.pattern(38, 21, wing.map { String($0.reversed()) }, ["G": grey])
    drawBody(c, look)
    c.pattern(18, 22, [
        "....KKKKKKKKKKKK....",
        "..KKKSSKKKKKKKKKKK..",
        ".KKSSKKKKKKKKKKKKKd.",
        "KKKKKKKKKKKKKKKKKKKd",
    ], ["K": black, "S": sheen, "d": blackDark])
    // Narrow blue eyes under a hard brow.
    for x in [22, 32] {
        c.glowLine(Double(x) + 1, 29.5, Double(x) + 1, 29.5, core: core, glow: glow, coreR: 0.7, glowR: 1.6 + buzz * 0.6,
                   strength: 0.6 + 0.3 * buzz)
        c.rect(x, 29, 2, 2, C(0x8AC8FF)); c.px(x + (x < 28 ? 1 : 0), 29, white)
    }
    c.rect(21, 28, 5, 1, sheen); c.rect(31, 28, 5, 1, sheen)
    // The stitched grille over his mouth.
    c.pattern(22, 31, ["G.G.G.G.G.G.", "GGGGGGGGGGGG", "G.G.G.G.G.G."], ["G": grey])
    // Chest: the blue bolt on a dark grey disc, grey belt.
    c.rect(18, 36, 20, 1, grey)
    c.pattern(25, 33, [".GGGG.", "GGGBBG", "GGBBGG", "GBBGGG", ".GGGG."], ["G": C(0x34343E), "B": C(0x5AA0FF)])
    c.px(26, 33, greyLight)
    c.rect(15, 33, 3, 3, black)
    if let a = p.melee {
        speedPunch(c, angle: a, trail: p.trail, t: p.t, arm: sheen, fist: grey, core: core, glow: glow)
    }
    if !ghost { crackle(c, t: p.t, seed: 23, core: core, glow: glow, n: buzz > 0.3 ? 3 : (p.trail.isEmpty ? 1 : 3)) }
}

// MARK: - Captain Cold

/// Captain Cold (Leonard Snart): the blue parka with its white fur-lined hood, dark snow goggles, dark trousers and
/// boots, and the chunky white cold gun with its blue coils; a little fog on his breath. Signature: he points the cold
/// gun at the sky and fires, and snow comes drifting down all round him.
private func drawCaptainCold(_ c: PixelCanvas, _ p: Pose) {
    let parka = C(0x3A7AC8), parkaDark = C(0x285A98), parkaLight = C(0x6A9ADC), fur = C(0xEEF0F4), furShade = C(0xB8C0CC)
    let trousers = C(0x26304A), boot = C(0x1A1A20)
    drawLegs(c, Look(leg: trousers), step: p.step)
    boots(c, p, rows: 2, boot)
    c.oy += p.breathe
    drawBody(c, Look(body: parka, shade: parkaDark, arm: parka, eye: nil))
    // The hood, trimmed with fur round the face.
    c.pattern(15, 20, [
        "........PPPPPPPPPP........",
        "......PPPPLLPPPPPPPP......",
        "....PPPPLLPPPPPPPPPPPP....",
        "...PPPPPPPPPPPPPPPPPPPPd..",
        "..PPPPFFFFFFFFFFFFFFPPPd..",
        "..PPPFFfFFFfFFFFfFFFFPPd..",
        ".PPPFF............FFFPPd..",
        ".PPPF..............FFPPd..",
        ".PPPF..............FFPPd..",
        ".PPPF..............FFPPd..",
        ".PPPFF............FFFPPd..",
        "..PPPFFFfFFFFFFfFFFFPPd...",
        "...PPPFFFFFFFFFFFFFFPPd...",
    ], ["P": parka, "d": parkaDark, "L": parkaLight, "F": fur, "f": furShade])
    // His face, the goggles across it.
    c.rect(20, 26, 15, 5, clawdOrange)
    c.rect(20, 26, 15, 1, C(0x2A2A30))
    c.pattern(20, 27, ["KKKKKKKKKKKKKKK", "KGGGGK...KGGGGK", "KGgGGK...KGgGGK"], ["K": C(0x2A2A30), "G": C(0x4A5A6A), "g": C(0xC8E8FF)])
    c.rect(25, 30, 5, 1, C(0x2A2A30))
    c.rect(24, 31, 7, 1, clawdShade)                                           // a flat, unimpressed mouth
    // The parka's front: zip, fur hem, pockets.
    c.rect(27, 33, 1, 5, parkaDark)
    c.rect(18, 37, 20, 1, furShade)
    c.rect(20, 35, 4, 1, parkaDark); c.rect(31, 35, 4, 1, parkaDark)
    c.rect(15, 33, 3, 3, parka)
    // Fog on his breath now and then.
    let fog = frac(p.lt / 3.1)
    if fog < 0.3 { puff(c, x: 37 + fog * 10, y: 31 - fog * 6, k: fog / 0.3, C(0xE8F4FF)) }

    var angle = 0.0, beam = 0.0, snow = 0.0
    if let s = p.signature {
        angle = -62 * habitArc(min(1, s / 0.9), hold: 0.7)
        if s > 0.2 && s < 0.5 { beam = 1 }
        snow = s > 0.3 ? min(1, (s - 0.3) / 0.15) * (s > 0.85 ? (1 - s) / 0.15 : 1) : 0
    }
    let hand = (x: Sprite.hand.x, y: Sprite.hand.y + Double(p.gunY))
    prop(c, at: hand, angle: angle) { s in drawColdGun(s, firing: p.fire != nil || beam > 0) }
    c.rect(38, 33 + p.gunY, 3, 3, parka); c.rect(40, 34 + p.gunY, 2, 2, C(0x2A2A30))   // the arm and glove on the grip
    if beam > 0 {
        let r: Double = angle * .pi / 180
        let mx: Double = hand.x + cos(r) * 12 + sin(r) * 1.5, my: Double = hand.y + sin(r) * 12 - cos(r) * 1.5
        c.glowLine(mx, my, mx + cos(r) * 40, my + sin(r) * 40, core: C(0xE8FAFF), glow: C(0x7FD8FF), coreR: 0.6, glowR: 2,
                   strength: 0.85 + 0.15 * sin(p.t * 40))
    }
    if snow > 0 {
        for n in 0..<16 {
            let f = frac(p.lt * 0.35 + noise(n * 3))
            let x = 4 + Int(noise(n * 5) * 60) + Int((sin(p.lt * 2 + Double(n)) * 1.5).rounded())
            let y = Int(f * 46) - 2
            c.px(x, y, white.alpha(snow * (n % 3 == 0 ? 1 : 0.7)))
            if n % 4 == 0 { c.px(x + 1, y, white.alpha(snow * 0.4)); c.px(x, y + 1, white.alpha(snow * 0.4)) }
        }
        c.rect(19, 20, 4, 1, white.alpha(snow)); c.rect(27, 19, 6, 1, white.alpha(snow))   // snow settling on the hood
    }
}

/// The cold gun, pointing right from (20, 20): a white body, blue cooling coils, a frosted barrel tip.
private func drawColdGun(_ s: PixelCanvas, firing: Bool) {
    s.pattern(18, 17, [
        "....WWWWWWW....",
        "..WWBWBWBWWWWW.",
        "..WWWWWWWWWWWWF",
        "..wwwwwwwwWWWW.",
        "..KK.K.........",
        "..KK...........",
    ], ["W": C(0xE4E8EE), "w": C(0xA8B0BC), "B": C(0x4AA8F0), "K": C(0x2A2A30), "F": firing ? C(0xE8FAFF) : C(0x7FD8FF)])
}

// MARK: - Heat Wave

/// Heat Wave (Mick Rory): a red fire-proof suit and hood, a broad silver visor across his eyes, orange gauntlets and
/// boots, a fuel tank on his back and the heat gun with its flared copper nozzle and a pilot flame. Signature: he
/// spreads his arms and a ring of fire roars up round his feet, firelight in his visor, then dies down.
private func drawHeatWave(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xB8321E), suitDark = C(0x82200F), suitLight = C(0xD8583A), orange = C(0xF08A2A), orangeDark = C(0xB8601A)
    let visor = C(0xC8CCD4), visorLight = C(0xF4F6F8), visorDark = C(0x7A808C), tank = C(0x6A6E78)
    let ringK = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    if ringK > 0 { flames(c, t: p.lt, k: ringK, back: true) }
    // The fuel tank on his back.
    c.oy += p.breathe
    c.pattern(12, 26, [".TT.", "TttT", "TttT", "TttT", "TttT", "TttT", "TttT", "TTTT", ".dd."],
              ["T": tank, "t": C(0x9AA0AA), "d": C(0x3A3A40)])
    c.oy -= p.breathe
    drawLegs(c, Look(leg: suit), step: p.step)
    boots(c, p, rows: 3, orange)
    c.oy += p.breathe
    drawBody(c, Look(body: suit, shade: suitDark, arm: suit, eye: nil), armLeft: ringK > 0.2 ? 4 : 0)
    c.pattern(17, 21, [
        "......SSSSSSSSSS......",
        "....SSSLLSSSSSSSSS....",
        "...SSLLSSSSSSSSSSSSd..",
        "..SSSSSSSSSSSSSSSSSSd.",
        ".SSSSSSSSSSSSSSSSSSSd.",
    ], ["S": suit, "L": suitLight, "d": suitDark])
    // The visor, firelight playing on it while the ring burns.
    c.rect(19, 27, 18, 4, visorDark)
    c.rect(20, 28, 16, 2, visor)
    c.rect(21, 28, 4, 1, visorLight); c.rect(31, 28, 2, 1, visorLight)
    if ringK > 0.2 {
        let fl = noise(Int(p.t * 14)) > 0.5
        c.rect(20, 29, 16, 1, (fl ? C(0xFFB02A) : C(0xFF6A1E)).alpha(ringK))
    }
    // The bare lower face: stubble and a scowl (a grin while it burns).
    c.rect(22, 31, 12, 2, clawdOrange)
    for x in stride(from: 22, to: 34, by: 2) { c.px(x, 32, clawdShade) }
    if ringK > 0.3 { c.rect(25, 31, 6, 1, C(0x5A1A10)); c.rect(26, 31, 4, 1, white) } else { c.rect(25, 31, 6, 1, clawdShade) }
    // Suit: harness straps, an orange belt, gauntlets.
    c.rect(18, 33, 20, 1, suitDark)
    c.rect(21, 33, 2, 3, C(0x3A3A40)); c.rect(33, 33, 2, 3, C(0x3A3A40))
    c.rect(18, 36, 20, 1, orange); c.rect(27, 36, 2, 1, orangeDark)
    c.rect(15, 33 - (ringK > 0.2 ? 4 : 0), 3, 3, orange)
    // The heat gun: raised high in the ring of fire, else at the hand with its pilot flame.
    let lift = Int((ringK * 6).rounded())
    let y = 31 + p.gunY - lift
    c.rect(38, y + 2, 3, 3, orange)
    c.pattern(40, y, [
        "..DDDDDD.....",
        ".DGGGGGGDNN..",
        "DGGGGGGGGNNN.",
        ".DDDDDDDDNN..",
        "..KK.........",
        "..KK.........",
    ], ["D": C(0x2E2E36), "G": C(0x5A5E68), "N": C(0xC8783A), "K": C(0x2A2A30)])
    c.rect(41, y + 1, 3, 1, C(0x8A8F9C))
    if p.fire == nil {
        let fl = noise(Int(p.t * 14)) > 0.5
        c.px(52, y + 2, fl ? C(0xFFD23A) : C(0xFF7A1E)); c.px(53, y + 1 + (fl ? 0 : 1), C(0xFF6A1E).alpha(0.7))
    }
    if ringK > 0 { flames(c, t: p.lt, k: ringK, back: false) }
}

/// Heat Wave's ring of fire, `k` 0…1 grown: tall flames behind him (`back`) or low ones licking in front.
private func flames(_ c: PixelCanvas, t: Double, k: Double, back: Bool) {
    let i = Int(t * 12)
    let xs: [Int] = back ? Array(stride(from: 6, through: 50, by: 4)) : [9, 13, 42, 46, 50]
    for (n, x) in xs.enumerated() {
        let tall: Double = back ? 6 + noise(i * 5 + n) * 8 : 3 + noise(i * 7 + n) * 4
        let h = Int((tall * k).rounded())
        guard h > 0 else { continue }
        let base = 44, sway = noise(i * 3 + n) > 0.5 ? 1 : 0
        // A tongue of flame: wide and red at the root, narrowing to a flickering tip, yellow inside.
        c.rect(x - 1, base - h / 2, 5, h / 2, C(0xE83A14, 0.9))
        c.rect(x, base - h, 3, h - h / 2, C(0xFF5A1A, 0.9))
        c.rect(x + sway, base - h - 2, 1, 2, C(0xFF7A1E, 0.8))
        if h > 3 { c.rect(x, base - h / 2 - 1, 3, h / 2 + 1, C(0xFF9A2A)) }
        if h > 5 { c.rect(x + 1, base - h / 2, 1, h / 2, C(0xFFE07A)) }
        if noise(i * 11 + n) > 0.7 { c.px(x + 1, base - h - 4, C(0xFFB02A, 0.7)) }   // an ember
    }
}

// MARK: - Mirror Master

/// Mirror Master: a green bodysuit with orange gloves, boots and belt, a green helmet-cowl with big round mirrored
/// goggles, and the mirror gun, a pistol with a silvered dish on the front. Signature: a mirror opens in front of
/// him and he steps into it and is gone, then steps out of another one behind and the mirrors wink out.
private func drawMirrorMaster(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { mirrorMasterArt(c, p); return }
    // Two mirrors: the way in (in front), the way out (behind). Each grows, holds and shrinks.
    let inK = s < 0.08 ? s / 0.08 : s < 0.42 ? 1 : max(0, 1 - (s - 0.42) / 0.08)
    let outK = s < 0.45 ? 0 : s < 0.53 ? (s - 0.45) / 0.08 : s < 0.88 ? 1 : max(0, 1 - (s - 0.88) / 0.08)
    if s < 0.42 {
        // Stepping in: forward, fading into the glass.
        let f = max(0, (s - 0.12) / 0.3)
        layer(c, alpha: 1 - f, dx: Int((f * 16).rounded())) { mirrorMasterArt($0, p) }
    } else if s > 0.55 {
        // Stepping out of the one behind.
        let f = min(1, (s - 0.55) / 0.28)
        layer(c, alpha: f, dx: -Int(((1 - f) * 16).rounded())) { mirrorMasterArt($0, p) }
    }
    // The glass is drawn over him, so he's seen going into it and coming out of it.
    if outK > 0 { drawMirror(c, x: 9, k: outK, t: p.t) }
    if inK > 0 { drawMirror(c, x: 47, k: inK, t: p.t); drawMirrorFrameGlint(c, x: 47, k: inK, t: p.t) }
}

private func mirrorMasterArt(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E9A4A), greenDark = C(0x1E6A32), greenLight = C(0x5AC06A)
    let orange = C(0xF08A2A), orangeDark = C(0xB8601A), glass = C(0xD8F4F8), glassDark = C(0x6AB8C8)
    drawLegs(c, Look(leg: green), step: p.step)
    boots(c, p, rows: 3, orange)
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil))
    c.pattern(18, 22, [
        "....GGGGGGGGGGGG....",
        "..GGGLLGGGGGGGGGGG..",
        ".GGLLGGGGGGGGGGGGGd.",
        "GGGGGGGGGGGGGGGGGGGd",
    ], ["G": green, "L": greenLight, "d": greenDark])
    // The bare lower face and a sly grin.
    c.rect(21, 32, 14, 1, clawdOrange)
    c.rect(24, 32, 8, 1, clawdShade); c.px(32, 31, clawdShade)
    // The big round mirror goggles on an orange band.
    c.rect(18, 29, 20, 1, orangeDark)
    for x in [20, 30] {
        c.pattern(x, 27, [".OOOO.", "OGGGGO", "OGWGGO", "OGGGgO", ".OOOO."], ["O": orange, "G": glass, "W": white, "g": glassDark])
    }
    // Orange belt with a mirror buckle, orange gloves.
    c.rect(18, 36, 20, 1, orange)
    c.rect(26, 35, 4, 3, orangeDark); c.rect(27, 36, 2, 1, glass)
    c.rect(15, 33, 3, 3, orange)
    // The mirror gun.
    let y = 31 + p.gunY
    c.rect(38, 33 + p.gunY, 3, 3, orange)
    c.pattern(40, y, [
        "..........OO.",
        "..SSSSSSSOGWO",
        ".SSSSSSSSOGGO",
        "..KKs....OGgO",
        "..KK......OO.",
    ], ["S": C(0x9AA0AA), "s": C(0x6A707C), "K": C(0x2A2A30), "O": orangeDark, "G": glass, "W": white, "g": glassDark])
}

/// A tall oval mirror standing on the floor at `x`, `k` 0…1 grown (it opens from a line), the glass rippling.
private func drawMirror(_ c: PixelCanvas, x: Int, k: Double, t: Double) {
    let hw = max(1, Int((7 * k).rounded())), top = 22, bottom = 43
    for y in top...bottom {
        let f: Double = Double(y - top) / Double(bottom - top) * 2 - 1
        let w = Int((Double(hw) * (1 - f * f * 0.45)).rounded())
        let cx = x + 7
        c.rect(cx - w, y, w * 2, 1, C(0xB8ECF4, 0.72))
        c.px(cx - w - 1, y, C(0xF08A2A)); c.px(cx + w, y, C(0xB8601A))
        let ripple = Int((sin(t * 9 + Double(y) * 0.6) * 1.5).rounded())
        if (y + ripple) % 5 == 0 { c.px(cx + ripple, y, white.alpha(0.8)) }
    }
    c.rect(x + 7 - hw, top - 1, hw * 2, 1, C(0xF08A2A)); c.rect(x + 7 - hw, bottom + 1, hw * 2, 1, C(0xB8601A))
}

/// The glint sliding down the mirror he's stepping into, and its rim drawn over him.
private func drawMirrorFrameGlint(_ c: PixelCanvas, x: Int, k: Double, t: Double) {
    let hw = max(1, Int((7 * k).rounded())), cx = x + 7
    let g = Int(frac(t * 0.8) * 20) + 22
    c.glowLine(Double(cx - hw + 2), Double(g), Double(cx + hw - 2), Double(g) - 3, core: white.alpha(0.8), glow: C(0x6AE8E8, 0.5),
               coreR: 0.4, glowR: 1.2)
    for y in 22...43 {
        let f: Double = Double(y - 22) / 21 * 2 - 1
        let w = Int((Double(hw) * (1 - f * f * 0.45)).rounded())
        c.px(cx - w - 1, y, C(0xF08A2A))
    }
}

// MARK: - Gorilla Grodd

/// Gorilla Grodd: a huge charcoal-furred gorilla, a domed crest, a heavy brow over small fierce eyes, a grey muzzle
/// with fangs, long arms down to his knuckles. Telepathic: he lifts a hand to his temple and a pink ray of thought
/// streams from his head. Signature: both hands to his temples, his eyes blaze and rings of psychic force pulse out.
private func drawGorillaGrodd(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x3C3A42), furDark = C(0x26242C), furLight = C(0x5E5C66), skin = C(0x6E6670), skinDark = C(0x4E4852)
    let skinLight = C(0x8E8690), psy = C(0xD86AE8)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let think = p.armRaise > 0 || p.zap != nil || k > 0.1
    // Thick, short legs.
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, fur); c.rect(lx - 1, 39, 5, 1, skinDark); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 4, lifted ? 7 : 8, fur)
        c.rect(lx, lifted ? 42 : 43, 4, 1, skinDark)
        c.rect(lx + 3, 37, 1, lifted ? 4 : 5, furDark)
    }
    c.oy += p.breathe
    // The left arm: hanging to its knuckles, or up at his temple.
    if k > 0.1 {
        c.rect(10, 22, 5, 10, fur); c.rect(10, 22, 1, 10, furDark)
        c.rect(12, 18, 6, 6, skinDark); c.rect(12, 18, 6, 1, skin)
    } else {
        c.rect(10, 23, 5, 14, fur); c.rect(10, 23, 1, 14, furDark)
        c.rect(9, 36, 7, 5, fur); c.rect(9, 40, 7, 2, skinDark)
        if seatedPose { c.rect(9, 38, 7, 1, skinDark) }
    }
    // The great body, crested head and silvered back.
    c.pattern(14, 14, [
        "...........FF...............",
        ".........FFFFFF.............",
        ".......FFFFFFFFFF...........",
        ".....FFLLFFFFFFFFFF.........",
        "...FFFLLFFFFFFFFFFFFFF......",
        "..FFFLFFFFFFFFFFFFFFFFFF....",
        ".FFFFFFFFFFFFFFFFFFFFFFFFF..",
        "FFFFFFFFFFFFFFFFFFFFFFFFFFd.",
    ], ["F": fur, "L": furLight, "d": furDark])
    c.rect(14, 22, 27, 16, fur)
    c.rect(40, 21, 1, 17, furDark)
    c.rect(15, 23, 2, 9, furLight)                                             // the silver on his back
    c.rect(14, 37, 27, 1, furDark)
    // The face: a heavy brow, small eyes, the broad muzzle.
    c.pattern(19, 22, [
        "..SSSSSSSSSSSSSS...",
        ".BBBBBBBBBBBBBBBBB.",
        "BBBBBBBBBBBBBBBBBBB",
        ".SSEESSSSSSSSSEESS.",
        ".SSEESSSSSSSSSEESS.",
        ".SSSSSSnnnnnSSSSSS.",
        "..SSSSnnKnKnnSSSS..",
        "..MMMMMMMMMMMMMMM..",
        ".MMMMMMMMMMMMMMMMM.",
        ".MKKKKKKKKKKKKKKKM.",
        ".MMWMMMMMMMMMMWMMM.",
        "..MMMMMMMMMMMMMMM..",
    ], ["S": skin, "B": furDark, "E": ink, "n": skinDark, "K": ink, "M": skinLight, "W": white])
    let glare = think ? max(0.5, k) : 0
    for x in [22, 32] {
        if glare > 0 {
            c.glowLine(Double(x) + 1, 25.5, Double(x) + 1, 25.5, core: C(0xFFF0FF), glow: psy, coreR: 0.8, glowR: 1.8 + k * 1.5,
                       strength: glare)
        } else {
            c.px(x + 1, 25, C(0xE8C83A))
        }
    }
    // A broad, bare chest.
    c.pattern(20, 34, ["nnnnnnn..nnnnnnn", ".nnnnn....nnnnn."], ["n": skinDark])
    // The right arm: up at his temple when he's thinking hard, else down to his knuckles.
    if think {
        c.rect(38, 27, 5, 8, fur); c.rect(42, 27, 1, 8, furDark)
        c.rect(40, 21, 4, 8, fur)
        c.rect(37, 20, 6, 5, skinDark); c.rect(37, 20, 6, 1, skin)
    } else {
        c.rect(38, 23, 6, 13, fur); c.rect(43, 23, 1, 13, furDark)
        c.rect(39, 35, 7, 6, fur); c.rect(39, 39, 7, 2, skinDark); c.rect(45, 35, 1, 4, furDark)
    }
    if k > 0.1, let s = p.signature {
        // Rings of thought pulsing out from his head.
        for n in 0..<3 {
            let f = frac(s * 3 + Double(n) / 3)
            let r = 6 + f * 22
            ring(c, 28, 22, r, r * 0.55, psy.alpha(k * (1 - f)), n: 60)
        }
        c.glowLine(28, 20, 28, 20, core: clear, glow: psy, coreR: 0, glowR: 5 * k, strength: 0.5)
    }
}

// MARK: - Weather Wizard

/// Weather Wizard (Mark Mardon): a green bodysuit with a purple cape, purple domino mask, gloves and boots, a white
/// cloud and bolt on the chest, slicked dark hair, and the silver weather wand topped with a stormy crystal; his magic
/// is the lightning it calls down. Signature: he holds the wand up, a raincloud gathers over him, rain pours and a
/// bolt cracks down onto the floor in front of him.
private func drawWeatherWizard(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E8A4A), greenDark = C(0x1E5E32), purple = C(0x6A3A9A), purpleDark = C(0x4A2470)
    let hair = C(0x2A1E1A), hairLight = C(0x4A3628), silver = C(0xC8CCD4)
    let sig = p.signature
    let k = sig.map { habitArc($0, hold: 0.7) } ?? 0
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: purpleDark, edge: C(0x2E1448))
    drawLegs(c, Look(leg: green), step: p.step)
    boots(c, p, rows: 3, purple)
    c.oy += p.breathe
    let raise = max(p.armRaise, Int((k * 8).rounded()))
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: green, eye: nil), armRight: raise)
    c.pattern(17, 21, [
        ".....HHHHHHHHHHHH.....",
        "...HHHhHHHHHHHHHHHH...",
        "..HHhHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HH................HH.",
    ], ["H": hair, "h": hairLight])
    // The purple domino mask.
    c.pattern(20, 28, ["MMMMMMMMMMMMMMMM", "MMKKMMM..MMMKKMM", ".MKKM......MKKM."], ["M": purple, "K": ink])
    c.rect(25, 32, 6, 1, clawdShade)
    // Suit and chest emblem.
    c.rect(18, 33, 20, 5, green)
    c.rect(37, 33, 1, 5, greenDark)
    c.pattern(25, 33, [".WWWW.", "WWWWWW", "..YY..", ".YY...", "..Y..."], ["W": C(0xEEF0F4), "Y": C(0xF2C21E)])
    c.rect(18, 37, 20, 1, purpleDark)
    c.rect(15, 33, 3, 3, purple)
    // The weather wand, held up by its grip.
    let hy = 33 - raise
    c.rect(38, hy, 3, 3, purple)
    bar(c, 41.5, Double(hy + 4), 44.5, Double(hy - 6), silver, 0.6)
    let tip = (x: 44.5, y: Double(hy - 8))
    c.pattern(43, hy - 10, [".C.", "CBC", "CBC", ".C."], ["C": C(0x8AA8C8), "B": C(0xE8F4FF)])
    if p.zap != nil || k > 0.3 {
        c.glowLine(tip.x, tip.y, tip.x, tip.y, core: white, glow: C(0x7FB2FF), coreR: 0.6, glowR: 2.2,
                   strength: 0.7 + 0.3 * noise(Int(p.t * 20)))
    }
    guard let s = sig, k > 0.05 else { return }
    // The raincloud gathering overhead, rain pouring, and one bolt.
    let cloudK = min(1, k * 1.4)
    let cy = 8
    let puffs: [(Int, Int, Int)] = [(-8, 1, 3), (-3, -1, 5), (3, 0, 4), (9, 1, 3)]
    for b in puffs {
        let r = Int((Double(b.2) * cloudK).rounded())
        c.circle(36 + b.0, cy + b.1, r, C(0x5A6070))
        c.circle(36 + b.0 - 1, cy + b.1 - 1, max(0, r - 2), C(0x8A90A0))
    }
    c.rect(26, cy + 2, 21, Int((3 * cloudK).rounded()), C(0x434957))
    if s > 0.25 && s < 0.85 {
        for n in 0..<14 {
            let f = frac(p.t * 2.2 + noise(n * 7))
            let x = 27 + Int(noise(n * 3) * 20) - Int(f * 3)
            let y = cy + 4 + Int(f * 30)
            c.rect(x, y, 1, 2, C(0x9AC8FF, 0.75))
        }
    }
    if s > 0.44 && s < 0.62 {
        let f = (s - 0.44) / 0.18
        bolt(c, x: 44, y: Double(cy + 4), angle: 80, step: 7, n: 5, seed: Int(s * 40), core: white, glow: C(0x7FB2FF),
             strength: 1 - f * 0.5)
        if f < 0.4 { c.glowLine(50, 43, 50, 43, core: white, glow: C(0xC8E0FF), coreR: 1.5, glowR: 5) }
    }
}

// MARK: - Captain Boomerang

/// Captain Boomerang (Digger Harkness): a long blue coat printed with white boomerangs, a blue knitted toque, a
/// stubbly sneer, brown trousers and boots, a wooden boomerang in his hand (gone while it's in the air). Signature:
/// the big throw, one boomerang sailing out in a wide loop and back, and he catches it.
private func drawCaptainBoomerang(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x2A4A9A), coatDark = C(0x1C3270), coatLight = C(0x4A6AB8), print = C(0xE8ECF4)
    let trousers = C(0x6A4A2E), boot = C(0x3A2A1E), wood = C(0xC8A86A), woodDark = C(0x8A6A3A)
    drawLegs(c, Look(leg: trousers), step: p.step)
    boots(c, p, rows: 2, boot)
    c.oy += p.breathe
    // The coat's long skirt, split at the front.
    if !seatedPose {
        c.rect(17, 36, 22, 4, coat)
        c.rect(27, 37, 2, 3, clear)
        c.rect(17, 39, 10, 1, coatDark); c.rect(29, 39, 10, 1, coatDark)
    } else {
        c.rect(16, 37, 24, 2, coat)
    }
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: coat, eye: ink))
    // The toque, rolled brim.
    c.pattern(17, 20, [
        "......TTTTTTTTTT......",
        "....TTTLLTTTTTTTTT....",
        "...TTLLTTTTTTTTTTTT...",
        "..TTTTTTTTTTTTTTTTTTd.",
        ".RRRRRRRRRRRRRRRRRRRR.",
        ".RRRRRRRRRRRRRRRRRRRR.",
    ], ["T": coat, "L": coatLight, "d": coatDark, "R": C(0x223C80)])
    // Stubble and a sneer.
    for (x, y) in [(21, 32), (23, 33), (26, 33), (29, 33), (32, 33), (34, 32), (20, 31), (35, 31)] { c.px(x, y, clawdShade) }
    c.rect(25, 31, 6, 1, C(0x8A3A28)); c.px(31, 30, C(0x8A3A28))
    // The coat, with boomerangs printed on it, and a white collar.
    c.rect(18, 33, 20, 5, coat)
    c.rect(37, 33, 1, 5, coatDark)
    c.rect(27, 33, 2, 5, coatDark)
    for (x, y) in [(19, 34), (31, 35), (23, 36), (34, 33)] {
        c.px(x, y, print); c.px(x + 1, y + 1, print); c.px(x + 2, y, print)
    }
    c.pattern(20, 32, ["WW............WW", ".WW..........WW."], ["W": print])
    c.rect(15, 33, 3, 3, coat)

    // The boomerang: in the air during the big throw and just after a shot, else in his hand.
    var inAir = false
    if let f = p.fire, frac(f.t / shotPeriod) < 0.5 { inAir = true }
    var throwArm = false
    if let s = p.signature {
        if s > 0.12 && s < 0.86 {
            inAir = true
            let u = (s - 0.12) / 0.74
            let a: Double = u * 2 * .pi
            let x: Double = 42 + sin(a / 2) * 24, y: Double = 30 - sin(a) * 9
            prop(c, at: (x, y), angle: s * 2400) { drawBoomerang($0, wood, woodDark) }
            throwArm = s < 0.3 || s > 0.75
        }
        if s > 0.86 && s < 0.95 { c.rect(26, 31, 4, 1, white) }                     // a grin on the catch
    }
    if inAir || throwArm {
        c.rect(38, 30, 5, 3, coat); c.rect(42, 30, 2, 2, clawdOrange)              // arm out, hand open
    } else {
        c.rect(38, 33 + p.gunY, 3, 3, coat)
        prop(c, at: (41.5, 32.5 + Double(p.gunY)), angle: -30) { drawBoomerang($0, wood, woodDark) }
        c.rect(40, 33 + p.gunY, 2, 2, clawdOrange)
    }
}

/// A boomerang, its elbow at (20, 20), arms swept back.
private func drawBoomerang(_ s: PixelCanvas, _ wood: Px, _ dark: Px) {
    s.pattern(15, 17, ["WW.....", ".WWW...", "...WWWW", ".WWW...", "WD....."], ["W": wood, "D": dark])
}

// MARK: - The Trickster

/// The Trickster (James Jesse): a red acrobat's suit with yellow diamonds, a pointed yellow collar, a shock of blond
/// hair, a manic grin, and the yellow airwalker boots he runs on thin air with (he flies, legs striding over little puffs).
/// A pink yo-yo dangles from his hand between throws of his trick toys. Signature: the joke gun, he pulls the trigger
/// and out pops a BANG! flag.
private func drawTrickster(_ c: PixelCanvas, _ p: Pose) {
    layer(c, lean: p.flying ? 6 : 0) { c in tricksterArt(c, p) }
}

private func tricksterArt(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD8283A), redDark = C(0x9A1A28), yellow = C(0xF2C81E), yellowDark = C(0xC09A14)
    let hair = C(0xF0D878), hairDark = C(0xC8A84A), pink = C(0xFF6AA8)
    if p.flying {
        // Striding on air: one leg forward, one back, a puff under each sole.
        let stride = Int(p.t * 6) % 2
        let front = stride == 0 ? 3 : -2, backL = -front
        for (lx, d) in [(20, backL), (24, backL), (31, front), (35, front)] {
            c.rect(lx + d, 36, 2, 6, red)
            c.rect(lx + d - 1, 41, 4, 2, yellow); c.rect(lx + d - 1, 43, 4, 1, yellowDark)
        }
        for (n, x) in [20 + backL, 32 + front].enumerated() {
            let f = frac(p.t * 3 + Double(n) * 0.5)
            puff(c, x: Double(x) + 1, y: 45 + f * 2, k: f, C(0xF4F8FF))
        }
    } else {
        drawLegs(c, Look(leg: red), step: p.step)
        if seatedPose {
            for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, yellow) }
        } else {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let lifted = p.step >= 0 && i % 2 == p.step
                let b = lifted ? 42 : 43
                c.rect(lx - 1, b - 2, 4, 3, yellow); c.rect(lx - 1, b, 4, 1, yellowDark)
            }
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: red, eye: ink))
    // A shock of blond hair.
    c.pattern(17, 20, [
        "...H...H.....H........",
        "...HH.HHH..HHH..H.....",
        "..HHHHHHHHHHHHHHHH....",
        ".HHHhHHHHHHhHHHHHHH...",
        "HHHHHHHHHHHHHHHHHHHHH.",
        ".HHH.HHH....HHHH.HHHH.",
        ".HH................HH.",
    ], ["H": hair, "h": hairDark])
    // A manic grin.
    c.pattern(23, 32, ["K........K", ".KWWWWWWK."], ["K": C(0x5A1A10), "W": white])
    // The suit: red, yellow diamonds, the pointed collar.
    c.rect(18, 33, 20, 5, red)
    c.rect(37, 33, 1, 5, redDark)
    for (x, y) in [(20, 35), (25, 36), (30, 35), (35, 36)] {
        c.px(x, y - 1, yellow); c.rect(x - 1, y, 3, 1, yellow); c.px(x, y + 1, yellow)
    }
    c.pattern(18, 33, ["YYYYYYYYYYYYYYYYYYYY", ".YY.YY.YY..YY.YY.YY.", "..Y..Y..Y..Y..Y..Y.."], ["Y": yellow])
    c.rect(15, 33, 3, 3, red)

    if let s = p.signature {
        // The joke gun, and the BANG! flag popping out of it.
        let k = habitArc(s, hold: 0.6)
        c.rect(38, 31, 4, 3, red)
        c.pattern(41, 29, ["GGGGGGG", "GGPGGG.", "GG.....", "GG....."], ["G": C(0x8A5ACA), "P": pink])
        if s > 0.25 {
            // The flag on its stick springs up out of the barrel and unrolls.
            let out = min(1, (s - 0.25) / 0.08) * k
            let len = Int((out * 9).rounded())
            c.rect(48, 30 - len, 1, len, C(0x8A8F9C))
            if out > 0.6 {
                let w = Int((min(1, (out - 0.6) / 0.3) * 21).rounded())
                let fx = 49, fy = 21
                c.rect(fx, fy, w, 8, white)
                c.rect(fx, fy, w, 1, C(0xD8D8E0)); c.rect(fx, fy + 7, w, 1, C(0xD8D8E0))
                if w >= 21 { tinyText(c, x: fx + 2, y: fy + 2, "BANG!", red) }
            }
        }
        return
    }
    // The yo-yo, bobbing on its string (gone while a toy is in the air).
    var throwing = false
    if let f = p.fire, frac(f.t / shotPeriod) < 0.3 { throwing = true }
    if throwing {
        c.rect(38, 31, 5, 3, red); c.rect(42, 31, 2, 2, clawdOrange)
        return
    }
    c.rect(38, 33 + p.gunY, 3, 3, red)
    let drop = 3 + (sin(p.lt * 5) * 3)
    let yy = 36 + p.gunY + Int(drop.rounded())
    c.rect(40, 36 + p.gunY, 1, yy - 36 - p.gunY, C(0xE8E8EE, 0.8))
    c.pattern(39, yy, [".P.", "PWP", ".P."], ["P": pink, "W": C(0xFFD0E4)])
}

// MARK: - Savitar

/// Savitar, the god of speed: a towering speedster sealed in jagged chrome-white armour, a spiked crown of a helmet
/// with a black faceplate and slit eyes glowing blue, blade-plated shoulders, and long claws on his right hand that
/// leave blue lightning when they slash. Armoured (shots ring off). Signature: the seams of his armour blaze with
/// blue light, his eyes flare white and a storm of lightning breaks out all over him.
private func drawSavitar(_ c: PixelCanvas, _ p: Pose) {
    let silver = C(0xD4D8E0), mid = C(0x9AA0AC), dark = C(0x5A606C), deep = C(0x23262E)
    let core = C(0xF0FAFF), glow = C(0x5AB8FF)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    if p.walking { speedLines(c, t: p.t, core: core, glow: glow) }
    // Thick armoured legs with spiked knees.
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, mid); c.rect(lx - 1, 38, 5, 1, silver); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 3, lifted ? 7 : 8, mid)
        c.rect(lx + 2, 37, 1, lifted ? 6 : 7, dark)
        c.rect(lx, 38, 3, 1, silver); c.px(lx + 1, 37, silver)
        c.rect(lx, lifted ? 42 : 43, 3, 1, deep)
    }
    c.oy += p.breathe
    // The left arm, behind, claws hanging.
    c.rect(10, 25, 5, 10, mid); c.rect(10, 25, 1, 10, dark)
    c.pattern(9, 34, ["SSSSSS", "S.S.S.", "S.S.S.", "..S..."], ["S": silver])
    // The armoured trunk.
    c.rect(15, 22, 26, 16, mid)
    c.rect(40, 22, 1, 16, dark)
    c.pattern(15, 31, [
        "dSSSSSSSSSSSd..dSSSSSSSSSd",
        ".dSSSSSSSSSd....dSSSSSSSd.",
        "..dddddddddd....dddddddd..",
        "...........d....d.........",
        "dSdSdSdSdSd......dSdSdSdSd",
        "..........................",
        "dddddddddddddddddddddddddd",
    ], ["S": silver, "d": dark])
    // The blue core seam down his chest.
    let seam = 0.5 + 0.5 * k
    c.glowLine(28, 31, 28, 37, core: core, glow: glow, coreR: 0.5, glowR: 1.6 + k * 1.5, strength: seam)
    // The helmet: a spiked crown, a black faceplate with slit eyes.
    c.pattern(13, 10, [
        "....S.....S.....S.....S.....",
        "....SS...SS.....SS...SS.....",
        ".....SS.SSS.....SSS.SS......",
        ".....SSSSSSS...SSSSSSS......",
        "......SSSSSSSSSSSSSSSS......",
        "...SSSSSSSSSSSSSSSSSSSSSS...",
        "..SSSSSSSSSSSSSSSSSSSSSSSSd.",
        "..SSSSSSSSSSSSSSSSSSSSSSSSd.",
        "..SSSSSSSSSSSSSSSSSSSSSSSSd.",
        ".SSSSS.SSSSSSSSSSSSSS.SSSSd.",
        "SSSSS..SSSSSSSSSSSSSS..SSSSd",
        "SSSS...SSSSSSSSSSSSSS...SSSd",
    ], ["S": silver, "d": dark])
    c.pattern(19, 21, [
        "KKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKK",
        "KEEEKKKKKKKKKKEEEK",
        "KKEEEKKKKKKKKEEEKK",
        ".KKKKKKKKKKKKKKKK.",
        ".KKdKKdKKKKdKKdKK.",
        "..KKKKKKKKKKKKKK..",
        "...KKKKKKKKKKKK...",
    ], ["K": deep, "E": k > 0.3 ? white : C(0x8AD8FF), "d": dark])
    for x in [22.0, 33.0] {
        c.glowLine(x, 23.5, x + 1, 24, core: clear, glow: glow, coreR: 0, glowR: 1.6 + k * 0.6, strength: 0.5 + 0.3 * k)
    }
    // Shoulder blades.
    c.pattern(11, 19, ["S.....", "SS....", ".SSS..", "..SSSS", "...SSS"], ["S": silver])
    c.pattern(39, 19, [".....S", "....SS", "..SSS.", "SSSS..", "SSS..."], ["S": silver])
    // The right arm and its claws.
    let shoulder = (x: 40.5, y: 30.5)
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            let e = along(ta, 10, from: shoulder), e0 = along(ta, 4, from: shoulder)
            c.glowLine(e0.x, e0.y, e.x, e.y, core: core, glow: glow, coreR: 0.6, glowR: 2.2, strength: 0.6 / Double(i + 1))
        }
        prop(c, at: shoulder, angle: a) { s in savitarArm(s, silver, mid, dark) }
        if !p.trail.isEmpty {
            let e = along(a, 11, from: shoulder)
            bolt(c, x: e.x, y: e.y, angle: a + 160, step: 3, n: 3, seed: Int(p.t * 24), core: core, glow: glow)
        }
    } else {
        prop(c, at: shoulder, angle: 70) { s in savitarArm(s, silver, mid, dark) }
    }
    if k > 0.1 {
        // The armour's seams ablaze and lightning everywhere.
        for (x0, y0, x1, y1) in [(16.0, 33.5, 26.0, 33.5), (31.0, 33.5, 39.0, 33.5), (16.0, 35.5, 25.0, 35.5), (33.0, 35.5, 39.0, 35.5)] {
            c.glowLine(x0, y0, x1, y1, core: core, glow: glow, coreR: 0.3, glowR: 1.2, strength: k)
        }
        crackle(c, t: p.t, seed: 41, core: core, glow: glow, n: Int((k * 6).rounded()), area: (8, 8, 40, 36))
    } else {
        crackle(c, t: p.t, seed: 41, core: core, glow: glow, n: p.trail.isEmpty ? 1 : 3, area: (10, 12, 36, 30))
    }
}

/// Savitar's right arm from the shoulder at (20, 20): an armoured forearm and three long claws.
private func savitarArm(_ s: PixelCanvas, _ silver: Px, _ mid: Px, _ dark: Px) {
    s.rect(19, 18, 7, 5, mid); s.rect(19, 22, 7, 1, dark); s.rect(19, 18, 7, 1, silver)
    s.rect(25, 19, 3, 3, dark)
    for (dy, len) in [(-1, 5), (1, 6), (3, 4)] {
        s.rect(28, 19 + dy, len, 1, silver)
    }
}

// MARK: - Golden Glider

/// Golden Glider (Lisa Snart): a gold skating costume and gold domino mask, a dark ponytail, white ice skates with
/// silver blades. She glides through the air on a ribbon of golden ice, leaning into it with one leg back, and fights
/// with high kicks of her razor skates. Signature: a pirouette, spinning on one blade inside a ring of glittering ice.
private func drawGoldenGlider(_ c: PixelCanvas, _ p: Pose) {
    if let s = p.signature, s > 0.1, s < 0.9 {
        // The spin: front, side, back, side, faster in the middle.
        let u = (s - 0.1) / 0.8
        let turns: Double = 4 * (u - sin(u * 2 * .pi) / (2 * .pi))
        let phase = Int((turns * 4).rounded(.down)) % 4
        let k = habitArc(u, hold: 0.7)
        for n in 0..<10 {
            let a: Double = Double(n) / 10 * 2 * .pi + turns * 2
            let x = 28 + cos(a) * 15, y = 42 + sin(a) * 2.5
            c.glowLine(x, y, x, y, core: C(0xF4FCFF, k), glow: C(0xA8E0F8, k * 0.6), coreR: 0.5, glowR: 1.4)
        }
        ring(c, 28, 43, 13, 1.6, C(0xC8ECFF, 0.7 * k))
        var q = p; q.step = -1
        switch phase {
        case 0: gliderArt(c, q, spin: true)
        case 2:
            let o = PixelCanvas(c.w, c.h); o.ox = c.ox; o.oy = c.oy; o.baseY = c.baseY
            gliderArt(o, q, spin: true)
            o.mirror(aboutX: Sprite.bodyCenterX + Double(c.ox))
            c.paste(o, x: -c.ox, y: -c.oy - c.baseY)
        default:
            squeezed(c, 0.55) { gliderArt($0, q, spin: true) }
        }
        if Int(s * 30) % 3 == 0 { twinkle(c, 14 + Int(noise(Int(s * 30)) * 28), 20 + Int(noise(Int(s * 31)) * 20), C(0xFFE48A)) }
        return
    }
    if p.flying {
        // Skating on air: a trail of gold ice behind, the whole figure leaning in.
        for x in 2...38 {
            let y = 44 + Int(Double(38 - x) / 7)
            c.rect(x, y, 1, 2, C(0xF6E08A, 0.85))
            c.px(x, y, C(0xFFF6D0))
            if x % 6 == 0 { c.px(x, y + 1, C(0xC8A030)) }
        }
        layer(c, lean: 7) { gliderArt($0, p, spin: false) }
        return
    }
    gliderArt(c, p, spin: false)
}

/// Draws `art` squashed horizontally to `sx` of its width about the body's centre (a figure turned side-on).
private func squeezed(_ c: PixelCanvas, _ sx: Double, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    let cx = Sprite.bodyCenterX + Double(ox)
    for y in 0..<s.h {
        for x in 0..<s.w {
            let src = Int(floor(cx + (Double(x) + 0.5 - cx) / sx))
            guard src >= 0, src < s.w else { continue }
            let i = (y * s.w + src) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x, y, unpremultiplied(s, i))
        }
    }
}

private func gliderArt(_ c: PixelCanvas, _ p: Pose, spin: Bool) {
    let gold = C(0xF0C030), goldDark = C(0xB88A1E), goldLight = C(0xFFE48A)
    let hair = C(0x5A341E), hairLight = C(0x7A4A2A), skate = C(0xF4F4F8), skateShade = C(0xC8CCD8), blade = C(0xB0B8C4)
    let kick = p.melee
    // Legs: gold tights into white skates, silver blades underneath. In flight one leg is swept back.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, skate); c.rect(lx - 1, 40, 4, 1, blade) }
    } else if p.flying {
        for lx in [19, 23] { c.rect(lx, 36, 2, 4, gold) }
        c.pattern(7, 35, ["B...........", "BSSSGGGGG...", "BSSSGGGGGGGG", "B.......GGGG"], ["B": blade, "S": skate, "G": gold])
        for lx in [31, 35] { c.rect(lx, 36, 2, 5, gold); c.rect(lx, 40, 2, 3, skate); c.rect(lx - 1, 43, 4, 1, blade) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            if kick != nil && lx == 35 { continue }
            if spin && (lx == 23 || lx == 31) { continue }
            let lifted = p.step >= 0 && i % 2 == p.step
            let b = lifted ? 42 : 43
            c.rect(lx, 36, 2, b - 36 - 2, gold)
            c.rect(lx, b - 3, 2, 3, skate); c.px(lx + 1, b - 3, skateShade)
            c.rect(lx - 1, b, 4, 1, blade)
        }
        if spin {
            // One leg tucked up against the other.
            c.rect(26, 37, 2, 3, gold); c.rect(28, 37, 3, 3, skate); c.rect(31, 36, 1, 3, blade)
        }
    }
    c.oy += p.breathe
    // The ponytail behind, swinging.
    let swing = Int((sin(p.lt * 3) * 1).rounded())
    c.pattern(12 + swing, 22, ["...HHH", ".HHHHH", "HHHhH.", "HHH...", "HH....", "H....."], ["H": hair, "h": hairLight])
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: gold, eye: ink), armLeft: spin ? 6 : 0, armRight: spin ? 6 : 0)
    c.pattern(17, 21, [
        ".....HHHHHHHHHHHH.....",
        "...HHHhhHHHHHHHHHHH...",
        "..HHhHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHH..............HHH.",
        ".HH................HH.",
    ], ["H": hair, "h": hairLight])
    // The gold domino mask, a smile.
    c.pattern(20, 28, ["MMMMMMMMMMMMMMMM", "MMKKMMM..MMMKKMM", ".MKKM......MKKM."], ["M": gold, "K": ink])
    c.rect(26, 32, 4, 1, C(0xB8402A))
    // The skating costume: gold, a sparkle of sequins, a little skirt.
    c.rect(18, 33, 20, 5, gold)
    c.rect(37, 33, 1, 5, goldDark)
    c.pattern(18, 33, ["DD..............DD", "..L....L....L....."], ["D": goldDark, "L": goldLight])
    if !seatedPose && !p.flying { c.pattern(17, 37, ["GGGGGGGGGGGGGGGGGGGGGG", "G.G.G.G.G.G.G.G.G.G.G."], ["G": goldDark]) }
    if spin { c.rect(15, 26, 3, 2, gold); c.rect(38, 26, 3, 2, gold) }
    // The kick: her front leg swung up from the hip, the razor blade leading.
    if let a = kick {
        let hip = (x: 36.5, y: 37.5)
        for (i, ta) in p.trail.enumerated() {
            let e = along(ta, 9, from: hip), e0 = along(ta, 4, from: hip)
            c.glowLine(e0.x, e0.y, e.x, e.y, core: C(0xF4FCFF), glow: C(0xFFE48A), coreR: 0.5, glowR: 1.8, strength: 0.5 / Double(i + 1))
        }
        c.oy -= p.breathe
        prop(c, at: hip, angle: a) { s in
            s.rect(20, 19, 6, 2, gold)
            s.rect(26, 18, 3, 3, skate); s.px(26, 18, skateShade)
            s.rect(29, 17, 1, 5, blade)
        }
    }
}
