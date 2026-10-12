import Foundation

let scenes4: [Location: Place] = [
    .nandaParbat: Place(name: "Nanda Parbat", panel: 0x141A28, still: Scenes.nandaParbat, moving: Scenes.nandaLife),
    .houseOfMystery: Place(name: "House of Mystery", panel: 0x150E20, still: Scenes.houseOfMystery, moving: Scenes.mysteryLife),
    .rockOfEternity: Place(name: "Rock of Eternity", panel: 0x1A1510, still: Scenes.rockOfEternity, moving: Scenes.eternityLife),
    .newGenesis: Place(name: "New Genesis", panel: 0x1C2836, still: Scenes.newGenesis, moving: Scenes.genesisLife),
    .thanagar: Place(name: "Thanagar", panel: 0x22140F, still: Scenes.thanagar, moving: Scenes.thanagarLife),
    .kandor: Place(name: "Kandor", panel: 0x0C1C1A, still: Scenes.kandor, moving: Scenes.kandorLife),
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// String art drawn with every character `s` pixels square.
    static func scenes4Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes4Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// Something crossing the canvas left to right at `speed` pixels a second, wrapping round with `margin` to spare.
    static func scenes4Slide(_ t: Double, speed: Double, phase: Double, w: Int, margin: Int) -> Int {
        let span = Double(w + 2 * margin)
        let v = (phase * span + t * speed).truncatingRemainder(dividingBy: span)
        return Int(v < 0 ? v + span : v) - margin
    }

    /// A trapezoid centred on `cx` standing on row `b`: `wb` wide at the foot, `wt` at the top, `h` tall.
    static func scenes4Taper(_ c: PixelCanvas, _ cx: Int, _ b: Int, _ wb: Int, _ wt: Int, _ h: Int, _ col: Px) {
        guard h > 0 else { return }
        for k in 0..<h {
            let wk = wb + (wt - wb) * k / h
            c.rect(cx - wk / 2, b - 1 - k, wk, 1, col)
        }
    }

    /// A one-pixel line, `t` pixels thick.
    static func scenes4Line(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ col: Px, t: Int = 1) {
        let n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in 0...n {
            let x = x0 + (x1 - x0) * i / n, y = y0 + (y1 - y0) * i / n
            c.rect(x - t / 2, y - t / 2, t, t, col)
        }
    }

    /// A jagged bolt from one point to another, the same shape all through one `seed`, drawn as glowing segments.
    static func scenes4Bolt(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, seed: Int, jag: Double,
                            core: Px, glow: Px, width: Double, strength: Double = 1) {
        let n = 9
        var px = Double(x0), py = Double(y0)
        for i in 1...n {
            let k = Double(i) / Double(n)
            let off: Double = i == n ? 0 : (noise(seed * 37 + i) - 0.5) * 2 * jag
            let dx = Double(x1 - x0), dy = Double(y1 - y0), len = max(1, (dx * dx + dy * dy).squareRoot())
            let nx = Double(x0) + dx * k - dy / len * off, ny = Double(y0) + dy * k + dx / len * off
            c.glowLine(px, py, nx, ny, core: core, glow: glow, coreR: width * 0.5, glowR: width * 2, strength: strength)
            px = nx; py = ny
        }
    }
}

// MARK: - Nanda Parbat

extension Scenes {
    /// The monastery's centre, the foot of its crag and the size of one of its units.
    static func nandaFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, b: Int, u: Int) {
        (Int(Double(c.w) * 0.24), g, unit(g) * (isTall(c) ? 3 : 1))
    }

    /// The Lazarus Pit: the centre of its basin, its surface row, its half width and its unit.
    static func nandaPit(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, rx: Int, u: Int) {
        let u = unit(g) * (isTall(c) ? 2 : 1)
        return (Int(Double(c.w) * 0.76), g - 6 * u, 16 * u, u)
    }

    /// Where the cliff above the pit tops out.
    static func nandaCliffTop(_ c: PixelCanvas, _ g: Int) -> Int {
        isTall(c) ? g - g * 36 / 100 : g - 40 * unit(g)
    }

    /// The strings of prayer flags, as start and end points.
    static func nandaFlagLines(_ c: PixelCanvas, _ g: Int) -> [(x0: Int, y0: Int, x1: Int, y1: Int)] {
        let f = nandaFrame(c, g), tall = isTall(c)
        let roof = f.b - 43 * f.u
        let poleX = c.w / 2, poleTop = tall ? g - g * 44 / 100 : g - 46 * unit(g)
        let cliff = nandaCliffTop(c, g)
        return [
            (f.x + 2 * f.u, roof, poleX, poleTop),
            (poleX, poleTop, Int(Double(c.w) * 0.93), cliff - 12 * f.u / (tall ? 3 : 1)),
            (f.x - 2 * f.u, roof, -10, roof + 14 * f.u),
        ]
    }

    /// Nanda Parbat at dusk: snow peaks of the high Himalaya under a cold violet sky, the white-and-red monastery stacked
    /// on its crag at the left with gold roofs, strings of prayer flags running from its roof to a mast and on to the
    /// cliff, and under that cliff, in the mouth of a cave, the Lazarus Pit in its stone basin, glowing green.
    static func nandaParbat(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x121A36), C(0x7A7AA2), bands: 8)
        c.stars(0, g / 2, density: tall ? 80 : 55, seed: 41)
        if tall { nandaHigh(c, g) }
        // the far range
        let farBase = g - 10 * s
        var i = 0, x = -30 * s
        while x < c.w + 40 * s {
            let w = (54 + Int(noise(i * 5 + 4100) * 50)) * s * (tall ? 2 : 1)
            let h = tall ? Int(Double(g) * (0.22 + noise(i * 5 + 4101) * 0.2)) : (24 + Int(noise(i * 5 + 4101) * 22)) * s
            nandaPeak(c, x + w / 2, farBase, w, h, rock: C(0x3C4466), snow: C(0xC4CCE4), shade: C(0x8C96BA), seed: i)
            x += w * 3 / 5; i += 1
        }
        c.rect(0, farBase - 6 * s, c.w, 6 * s, C(0x9A9AC0, 0.22))
        // the near ridge behind the courtyard
        c.dunes(base: g - 9 * s, amp: Double(3 * s), freq: 0.035, phase: 1.1, bottom: g, C(0x2A2E46), shade: C(0xB8C0D8))
        c.dunes(base: g - 4 * s, amp: Double(2 * s), freq: 0.06, phase: 2.6, bottom: g, C(0x23263A))
        nandaCliff(c, g)
        nandaMonastery(c, g)
        // the mast in the middle
        for l in nandaFlagLines(c, g).prefix(1) {
            c.rect(l.x1, l.y1, s, g - l.y1, C(0x2A2420))
            c.rect(l.x1 - s, l.y1 - 2 * s, 3 * s, 2 * s, C(0xD8A838))
        }
        for l in nandaFlagLines(c, g) { nandaString(c, l, C(0x2A2430, 0.8)) }
        nandaPitDraw(c, g)
        // the snowy courtyard
        c.ground(g, C(0x4A4E66), edge: C(0xE2E8F4), speck: C(0x5C6080), seed: 41)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + 2, s, c.h - g - 2, C(0x3E4258)) }
        for k in 0..<(c.w / (30 * s)) {
            let x = Int(noise(k * 3 + 4150) * Double(c.w)), y = g + 2 + Int(noise(k * 3 + 4151) * Double(max(1, c.h - g - 4)))
            c.ellipse(x, y, (4 + Int(noise(k * 3 + 4152) * 6)) * s, s, C(0xE8EEF8, 0.45))
        }
        let p = nandaPit(c, g)
        c.ellipse(p.x, g + 2 * s, p.rx + 8 * p.u, 3 * s, C(0x5AFF8A, 0.12))
    }

    /// A snow peak standing on row `b`: the side left of the summit catches the light, the right is in shadow.
    static func nandaPeak(_ c: PixelCanvas, _ x: Int, _ b: Int, _ w: Int, _ h: Int, rock: Px, snow: Px, shade: Px, seed: Int) {
        let half = max(2, w / 2)
        let skew = Int((noise(seed * 13 + 1) - 0.5) * Double(half) * 0.5)
        let rockDark = lerp(rock, C(0x0A0C18), 0.25)
        for dx in -half...half {
            let left = dx < skew
            let side = Double(left ? half + skew : half - skew)
            let u = min(1, Double(abs(dx - skew)) / max(1, side))
            let fx = Double(dx) / Double(max(8, half / 4)), sd = Double(seed)
            let jag = Int((abs(sin(fx * 2.1 + sd)) * 0.7 + abs(sin(fx * 5.3 + sd * 2)) * 0.3) * Double(h) / 12 * u)
            let top = b - h + Int(pow(u, 0.85) * Double(h)) + jag
            guard top < b else { continue }
            c.rect(x + dx, top, 1, b - top, left ? rock : rockDark)
            let wave: Double = 0.1 * sin(fx * 1.7 + sd * 3) + 0.06 * sin(fx * 4.9 + sd)
            let ridge = max(0, abs(sin(fx * 1.3 + sd * 5)) - 0.8) * 0.8            // dark ribs of rock running up into the snow
            let line = b - h + Int(Double(h) * (0.5 + wave - ridge * (1 - u)))
            if top < line { c.rect(x + dx, top, 1, line - top, left ? snow : shade) }
            if dx == skew || dx == skew - 1 { c.rect(x + dx, top, 1, max(1, line - top), lerp(snow, white, 0.4)) }
        }
    }

    /// Full screen: the great peak of Nanda Parbat behind everything, the moon and long streaks of cloud.
    static func nandaHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let mx = Int(Double(c.w) * 0.86), my = g / 9, mr = g / 22
        c.circle(mx, my, mr + 4 * s, C(0xD8DCF0, 0.10)); c.circle(mx, my, mr, C(0xE8EAF4))
        c.circle(mx - mr / 3, my + mr / 4, max(1, mr / 4), C(0xC8CCDE))
        nandaPeak(c, Int(Double(c.w) * 0.56), g - 10 * s, Int(Double(c.w) * 0.8), g * 80 / 100,
                  rock: C(0x2E3456), snow: C(0xB0B8D6), shade: C(0x6E7698), seed: 77)
        nandaPeak(c, Int(Double(c.w) * 0.1), g - 10 * s, Int(Double(c.w) * 0.5), g * 58 / 100,
                  rock: C(0x343A5C), snow: C(0xB4BCD8), shade: C(0x747CA0), seed: 78)
        for i in 0..<5 {
            wisp(c, Int(noise(i + 4170) * Double(c.w)), Int(Double(g) * (0.3 + Double(i) * 0.07)), (70 + i * 18) * s,
                 C(0xB8BCDA, 0.3), s: s)
        }
    }

    /// The cliff on the right with the cave mouth the pit sits in.
    static func nandaCliff(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), p = nandaPit(c, g), top = nandaCliffTop(c, g)
        let x0 = p.x - p.rx - 36 * s
        for x in x0..<c.w {
            let d = x - x0
            let y = max(top + Int(noise(x / (2 * s) + 4190) * 4.0) * s, g - d * 2 + Int(noise(d / (3 * s) + 4191) * 8.0) * s)
            guard y < g else { continue }
            c.rect(x, y, 1, g - y, (x / (3 * s)) % 7 == 0 ? C(0x23263A) : C(0x2C3048))
            c.rect(x, y, 1, 2 * s, C(0xD8E0F0))
        }
        for k in 0..<(c.w - x0) / (9 * s) {                      // ledges of snow on the face
            let x = x0 + 20 * s + Int(noise(k * 3 + 4195) * Double(c.w - x0)), y = top + Int(noise(k * 3 + 4196) * Double(g - top))
            if y > g - (x - x0) * 2 + 2 * s { c.rect(x, y, (4 + Int(noise(k * 3 + 4197) * 6)) * s, s, C(0xC8D0E4, 0.7)) }
        }
        // the cave mouth
        let ry = min(g - top - 6 * s, 26 * p.u)
        c.ellipse(p.x, g, p.rx + 12 * p.u, ry + 2 * s, C(0x3A4058))
        c.ellipse(p.x, g, p.rx + 11 * p.u, ry, C(0x0C1018))
        c.ellipse(p.x, g, p.rx + 6 * p.u, ry * 2 / 3, C(0x2AFF7A, 0.07))
        c.ellipse(p.x, g, p.rx + 2 * p.u, ry / 2, C(0x2AFF7A, 0.08))
    }

    /// The monastery on its crag: a battered white lower wall, a white middle storey and the red palace on top under
    /// little gold roofs, with a white stupa beside it.
    static func nandaMonastery(_ c: PixelCanvas, _ g: Int) {
        let f = nandaFrame(c, g), u = f.u, x = f.x, b = f.b
        let wall = C(0xD8D4C8), wallShade = C(0xA8A4A0), red = C(0x8A2C24), brown = C(0x4A2018), gold = C(0xD8A838)
        for dx in -42...42 {                                         // the crag
            let k = Double(abs(dx)) / 42
            let top = b - Int(((1 - k * k) * 9.0 + noise(dx + 4200) * 2.0) * Double(u))
            c.rect(x + dx * u, top, u, b - top, dx < -28 ? C(0x4A5070) : C(0x2E3248))
            c.rect(x + dx * u, top, u, u, C(0xC8D0E4))
        }
        for k in 0..<4 {                                             // steps zigzagging up it
            let y = b - 2 * u - k * 2 * u, sx = x - 40 * u + (k % 2 == 0 ? k * 3 : 12 - k * 3) * u
            c.rect(sx, y, 10 * u, u, C(0x8A8698))
        }
        var y0 = b - 7 * u
        scenes4Taper(c, x, y0, 60 * u, 54 * u, 12 * u, wall)
        scenes4Taper(c, x + 22 * u, y0, 14 * u, 10 * u, 12 * u, wallShade)
        for (j, wy) in [y0 - 9 * u, y0 - 5 * u].enumerated() {
            for k in 0..<9 {
                let wx = x - 24 * u + k * 6 * u
                c.rect(wx, wy, u, 2 * u, C(0x2A1A18)); c.rect(wx - u, wy - u, 3 * u, u, brown)
                if noise(j * 9 + k + 4210) > 0.6 { c.rect(wx, wy, u, 2 * u, C(0xFFC860)) }
            }
        }
        c.rect(x - 27 * u, y0 - 12 * u, 54 * u, u, brown)
        y0 -= 12 * u
        scenes4Taper(c, x, y0, 44 * u, 40 * u, 10 * u, wall)
        scenes4Taper(c, x + 16 * u, y0, 10 * u, 8 * u, 10 * u, wallShade)
        for k in 0..<7 {
            let wx = x - 18 * u + k * 6 * u
            c.rect(wx, y0 - 7 * u, 2 * u, 3 * u, C(0x2A1A18)); c.rect(wx - u, y0 - 8 * u, 4 * u, u, brown)
            if noise(k + 4220) > 0.5 { c.rect(wx, y0 - 6 * u, 2 * u, 2 * u, C(0xFFC860)) }
        }
        c.rect(x - 20 * u, y0 - 10 * u, 40 * u, 2 * u, brown)
        y0 -= 10 * u
        scenes4Taper(c, x, y0, 26 * u, 22 * u, 10 * u, red)              // the red palace
        c.rect(x - 11 * u, y0 - 10 * u, 22 * u, 2 * u, brown)
        c.rect(x - 11 * u, y0 - 10 * u, 22 * u, u, C(0x6A3020))
        for k in 0..<4 {
            let wx = x - 8 * u + k * 5 * u
            c.rect(wx - u, y0 - 7 * u, 3 * u, 4 * u, C(0xE8E0D0)); c.rect(wx, y0 - 6 * u, u, 3 * u, C(0x1A0E0C))
        }
        c.rect(x - 2 * u, y0 - 3 * u, 4 * u, 3 * u, C(0x2A120E))
        y0 -= 10 * u
        for (dx, wb) in [(-7, 8), (7, 8), (0, 12)] {                       // the gold roofs and their finials
            let hh = wb == 12 ? 3 : 2
            scenes4Taper(c, x + dx * u, y0, wb * u, 4 * u, hh * u, gold)
            c.rect(x + dx * u - wb * u / 2, y0 - u, wb * u, u, C(0xA87A28))
            c.rect(x + dx * u, y0 - (hh + 3) * u, u, 3 * u, C(0xF0C850))
        }
        // the stupa on the right of the crag
        let sx = x + 36 * u, sb = b - 6 * u
        c.rect(sx - 4 * u, sb - 3 * u, 8 * u, 3 * u, wall)
        c.ellipse(sx, sb - 6 * u, 3 * u, 3 * u, wall)
        c.rect(sx - u, sb - 13 * u, 2 * u, 5 * u, gold)
        c.rect(sx, sb - 15 * u, u, 2 * u, C(0xF0C850))
    }

    /// A flag string's sagging line.
    static func nandaPoints(_ l: (x0: Int, y0: Int, x1: Int, y1: Int), step: Int) -> [(x: Int, y: Int)] {
        let dx = Double(l.x1 - l.x0), dy = Double(l.y1 - l.y0)
        let len = (dx * dx + dy * dy).squareRoot(), n = max(2, Int(len) / max(1, step))
        let sag = len * 0.08
        var out: [(x: Int, y: Int)] = []
        for i in 0...n {
            let k = Double(i) / Double(n)
            out.append((l.x0 + Int(dx * k), l.y0 + Int(dy * k + sag * 4 * k * (1 - k))))
        }
        return out
    }

    static func nandaString(_ c: PixelCanvas, _ l: (x0: Int, y0: Int, x1: Int, y1: Int), _ col: Px) {
        for p in nandaPoints(l, step: 1) { c.px(p.x, p.y, col) }
    }

    /// The stone basin of the pit and its glowing surface.
    static func nandaPitDraw(_ c: PixelCanvas, _ g: Int) {
        let p = nandaPit(c, g), u = p.u
        for k in 0..<4 { c.ellipse(p.x, p.y - k * 3 * u, p.rx + (5 - k) * 3 * u, (4 + k) * u, C(0x3AFF7A, 0.05)) }
        c.rect(p.x - p.rx - 3 * u, p.y, (p.rx + 3 * u) * 2, g - p.y, C(0x4A4C5C))
        for k in 0..<((p.rx * 2 + 6 * u) / (5 * u)) {
            c.rect(p.x - p.rx - 3 * u + k * 5 * u, p.y + (k % 2) * 3 * u, u, 3 * u, C(0x34363F))
        }
        c.rect(p.x - p.rx - 3 * u, p.y + 3 * u, (p.rx + 3 * u) * 2, u, C(0x34363F))
        c.ellipse(p.x, p.y, p.rx + 3 * u, 3 * u, C(0x6A6E80))
        c.ellipse(p.x, p.y, p.rx, 2 * u, C(0x2AD86A))
        c.ellipse(p.x, p.y, p.rx * 2 / 3, u, C(0x8AFFAA))
        c.rect(p.x - p.rx - 3 * u, p.y + u, (p.rx + 3 * u) * 2, u, C(0x5AFF8A, 0.25))
    }

    /// The prayer flags fluttering, the pit bubbling and breathing out green vapour, and snow drifting down.
    static func nandaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), fs = s * (tall ? 2 : 1)
        let colours: [Px] = [C(0x3A6AD8), C(0xF0F0F0), C(0xD83A2A), C(0x3AA84A), C(0xE8C83A)]
        for (li, l) in nandaFlagLines(c, g).enumerated() {
            for (i, p) in nandaPoints(l, step: 5 * fs).enumerated() where i > 0 {
                let col = colours[(i + li) % colours.count]
                let wave = Int((sin(t * 5.0 + Double(i) * 0.9 + Double(li)) * 1.2).rounded()) * fs
                c.rect(p.x, p.y + 1, 3 * fs, 2 * fs, col)
                c.rect(p.x + wave, p.y + 1 + 2 * fs, 3 * fs, 2 * fs, col.alpha(0.9))
            }
        }
        let p = nandaPit(c, g), u = p.u
        let pulse = 0.5 + 0.5 * sin(t * 1.7)
        c.ellipse(p.x, p.y, p.rx, 2 * u, C(0x9AFFB8, 0.15 * pulse))
        c.ellipse(p.x, p.y - 6 * u, p.rx + 6 * u, 8 * u, C(0x5AFF8A, 0.05 + 0.05 * pulse))
        for i in 0..<6 {
            let ph = scenes4Phase(t, 1.4 + noise(i + 4250) * 1.2, offset: noise(i + 4251) * 3)
            let bx = p.x + Int((noise(i + 4252) - 0.5) * Double(p.rx) * 1.6)
            if ph < 0.7 {
                c.circle(bx, p.y, max(0, Int(ph * 3) * u / 2), C(0xC8FFD8))
            } else {
                c.px(bx - 2 * u, p.y - 2 * u, C(0xC8FFD8, 0.8)); c.px(bx + 2 * u, p.y - 2 * u, C(0xC8FFD8, 0.8))
            }
        }
        for i in 0..<8 {                                                // vapour curling up
            let ph = scenes4Phase(t, 4, offset: Double(i) * 0.5)
            let vx = p.x + Int((noise(i + 4260) - 0.5) * Double(p.rx) * 1.5 + sin(t * 1.3 + Double(i)) * 3 * Double(u))
            let vy = p.y - Int(ph * Double(24 * u))
            c.ellipse(vx, vy, (3 + Int(ph * 4)) * u, u, C(0x7AFFA0, 0.18 * (1 - ph)))
        }
        for i in 0..<(c.w * g / 900) {                                  // snow
            let speed = 6.0 + noise(i * 3 + 4270) * 8
            let y = Int((noise(i * 3 + 4271) * Double(g) + t * speed * Double(s)).truncatingRemainder(dividingBy: Double(g)))
            let x = Int(noise(i * 3 + 4272) * Double(c.w) + sin(t * 0.8 + Double(i)) * 3 * Double(s))
            c.rect(x, y, s, s, C(0xF4F6FF, noise(i + 4273) > 0.5 ? 0.85 : 0.5))
        }
    }
}

// MARK: - House of Mystery

extension Scenes {
    /// One storey or tower of the house, in units from the house's foot: left and right, bottom, height, how far its
    /// top leans over, and a roof (0 none, else its height; `spike` for a witch's-hat, else a gable).
    struct MysteryBlock { let x0, x1, v, h, lean, roof: Int; let spike: Bool }

    static let mysteryBlocks: [MysteryBlock] = [
        MysteryBlock(x0: -26, x1: -15, v: 0, h: 34, lean: -2, roof: 14, spike: true),
        MysteryBlock(x0: -22, x1: 18, v: 0, h: 13, lean: 0, roof: 0, spike: false),
        MysteryBlock(x0: -17, x1: 12, v: 13, h: 11, lean: 3, roof: 0, spike: false),
        MysteryBlock(x0: 11, x1: 19, v: 13, h: 19, lean: 3, roof: 10, spike: true),
        MysteryBlock(x0: -10, x1: 9, v: 24, h: 9, lean: 4, roof: 9, spike: false),
    ]

    /// The house's foot (centre and row) and unit.
    static func mysteryFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, b: Int, u: Int) {
        let s = unit(g), tall = isTall(c)
        return (Int(Double(c.w) * 0.66), g - (tall ? g / 4 : 13 * s), s * (tall ? 3 : 1))
    }

    /// Every window of the house, in canvas pixels.
    static func mysteryWindows(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let f = mysteryFrame(c, g), u = f.u
        var out: [(x: Int, y: Int, w: Int, h: Int)] = []
        for (bi, b) in mysteryBlocks.enumerated() {
            let wide = b.x1 - b.x0
            for v in stride(from: b.v + 3, to: b.v + b.h - 4, by: 6) {
                for (k, wx) in stride(from: b.x0 + 2, to: b.x1 - 3, by: wide < 12 ? 4 : 6).enumerated() {
                    if bi == 1 && v < 8 && wx > -6 && wx < 3 { continue }            // the front door
                    if noise(bi * 40 + v * 3 + k + 4300) < 0.2 { continue }
                    let lean = b.lean * (v - b.v) * u / max(1, b.h)
                    out.append((f.x + wx * u + lean, f.b - (v + 4) * u, 3 * u, 4 * u))
                }
            }
        }
        return out
    }

    /// The House of Mystery on its hill at midnight: a crooked pile of storeys and witch's-hat towers all leaning
    /// different ways, black against an enormous pale moon with a smaller green moon off to the left, dead trees
    /// clawing at the sky, a winding path and gravestones down the slope.
    static func houseOfMystery(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = mysteryFrame(c, g), u = f.u
        c.gradient(0, g, C(0x0A0616), C(0x40284E), bands: 7)
        c.stars(0, g * 2 / 3, density: tall ? 70 : 50, seed: 43)
        // the moons
        let mx = f.x + 12 * u, my = f.b - 38 * u, mr = 15 * u
        for k in 0..<3 { c.circle(mx, my, mr + (3 - k) * 4 * s, C(0xF0E2B0, 0.07)) }
        c.circle(mx, my, mr, C(0xF2E8C4))
        c.circle(mx - mr / 3, my - mr / 4, mr / 4, C(0xE0D4AA)); c.circle(mx + mr / 3, my + mr / 3, mr / 5, C(0xE4D8B0))
        c.circle(mx + mr / 2, my - mr / 2, mr / 7, C(0xE0D4AA))
        let gx = Int(Double(c.w) * 0.2), gy = tall ? g / 5 : 14 * s, gr = tall ? g / 20 : 7 * s
        c.circle(gx, gy, gr + 3 * s, C(0xA8E07A, 0.10)); c.circle(gx, gy, gr, C(0xB8E890))
        c.circle(gx + gr / 3, gy - gr / 4, max(1, gr / 3), C(0x9ACC7A))
        if tall {
            for i in 0..<4 {
                wisp(c, Int(noise(i + 4310) * Double(c.w)), Int(Double(g) * (0.15 + Double(i) * 0.12)), (90 + i * 20) * s,
                     C(0x5A4070, 0.45), s: s)
            }
        }
        // the far hills
        c.dunes(base: g - 18 * s - (tall ? g / 8 : 0), amp: Double(5 * s), freq: 0.02, phase: 0.6, bottom: g, C(0x22183A))
        c.dunes(base: g - 10 * s - (tall ? g / 16 : 0), amp: Double(3 * s), freq: 0.035, phase: 2.0, bottom: g, C(0x1C1430))
        // the hill
        let half = Double(tall ? c.w / 3 : 95 * s)
        for x in 0..<c.w {
            let d = Double(x - f.x) / half
            let top = f.b + Int(Double(g - f.b) * min(1, d * d)) + Int(noise(x / (3 * s) + 4320) * 2.0) * s
            if top < g { c.rect(x, top, 1, g - top, C(0x17111F)); c.px(x, top, C(0x3A2E4A)) }
        }
        for y in f.b..<g {                                                // the path down
            let k = Double(y - f.b) / Double(max(1, g - f.b))
            let px = f.x - 2 * u + Int(sin(k * 5) * 10 * Double(u) * k) - Int(k * k * 30 * Double(s))
            c.rect(px, y, (2 + Int(k * 4)) * s, 1, C(0x2E2434))
        }
        mysteryTree(c, f.x - 34 * u, f.b + 3 * u, 22 * u, seed: 1)
        mysteryTree(c, f.x + 30 * u, f.b + 4 * u, 18 * u, seed: 2)
        mysteryTree(c, Int(Double(c.w) * 0.08), g, tall ? g / 3 : 34 * s, seed: 3)
        mysteryHouse(c, g)
        // gravestones
        for i in 0..<(c.w / (40 * s)) {
            let x = Int(noise(i * 3 + 4330) * Double(c.w)), b = g - Int(noise(i * 3 + 4331) * 3.0) * s
            if abs(x - f.x) < 20 * u { continue }
            let h = (5 + Int(noise(i * 3 + 4332) * 4)) * s
            c.rect(x, b - h, 4 * s, h, C(0x3A3446)); c.rect(x + s, b - h - s, 2 * s, s, C(0x3A3446))
            c.rect(x, b - h, s, h, C(0x5A5068))
            if noise(i + 4333) > 0.5 { c.rect(x + s, b - h + 2 * s, 2 * s, s, C(0x24202C)) }
        }
        c.ground(g, C(0x1E1828), edge: C(0x4A3E5A), speck: C(0x2A2236), seed: 43)
        for i in 0..<(c.w / (6 * s)) {                                  // dead grass
            let x = Int(noise(i + 4340) * Double(c.w))
            c.rect(x, g - s, s, s, C(0x4A4046)); if i % 3 == 0 { c.rect(x + s, g - 2 * s, s, s, C(0x3A3240)) }
        }
    }

    /// A bare tree: a crooked trunk and a few clawing branches.
    static func mysteryTree(_ c: PixelCanvas, _ x: Int, _ b: Int, _ h: Int, seed: Int) {
        let col = C(0x0C0812), lean = Int((noise(seed * 11) - 0.5) * Double(h) * 0.4)
        let tw = max(1, h / 12)
        scenes4Line(c, x, b, x + lean, b - h, col, t: tw)
        for k in 0..<5 {
            let at = 0.35 + Double(k) * 0.13, side = k % 2 == 0 ? -1 : 1
            let sx = x + Int(Double(lean) * at), sy = b - Int(Double(h) * at)
            let ex = sx + side * Int(Double(h) * (0.25 + noise(seed * 7 + k) * 0.2)), ey = sy - Int(Double(h) * (0.15 + noise(seed * 5 + k) * 0.2))
            scenes4Line(c, sx, sy, ex, ey, col, t: max(1, tw / 2))
            scenes4Line(c, ex, ey, ex + side * h / 10, ey - h / 8, col)
            scenes4Line(c, (sx + ex) / 2, (sy + ey) / 2, (sx + ex) / 2 + side * h / 14, (sy + ey) / 2 - h / 6, col)
        }
    }

    /// The crooked house itself.
    static func mysteryHouse(_ c: PixelCanvas, _ g: Int) {
        let f = mysteryFrame(c, g), u = f.u
        let wall = C(0x2E2238), siding = C(0x221A2C), lit = C(0x5A4868), roof = C(0x18121F), roofEdge = C(0x4A3A58)
        for b in mysteryBlocks {
            let rows = b.h * u
            for r in 0..<rows {
                let off = b.lean * r / max(1, b.h)
                let y = f.b - b.v * u - r - 1, x0 = f.x + b.x0 * u + off
                c.rect(x0, y, (b.x1 - b.x0) * u, 1, (r / u) % 3 == 2 ? siding : wall)
                c.px(x0, y, lit)
                c.px(x0 + (b.x1 - b.x0) * u - 1, y, C(0x150F1C))
            }
            let topY = f.b - (b.v + b.h) * u, x0 = f.x + b.x0 * u + b.lean * u - u, x1 = f.x + b.x1 * u + b.lean * u + u
            if b.roof > 0 {
                let rh = b.roof * u, apex = (x0 + x1) / 2 + (b.spike ? b.lean * u * 2 : b.lean * u)
                for r in 0..<rh {
                    let k = Double(r) / Double(rh)
                    let l = x0 + Int(Double(apex - x0) * k), rr = x1 - Int(Double(x1 - apex) * k)
                    c.rect(l, topY - r - 1, max(1, rr - l), 1, roof)
                    c.px(l, topY - r - 1, roofEdge)
                    if r % (2 * u) == 0 { c.rect(l, topY - r - 1, max(1, rr - l), 1, C(0x221A2A)) }
                }
                c.rect(apex, topY - rh - 3 * u, max(1, u / 2 + 1), 3 * u, roofEdge)
            } else {
                c.rect(x0, topY - u, x1 - x0, u, roof); c.rect(x0, topY - u, x1 - x0, max(1, u / 2), roofEdge)
            }
        }
        // chimneys at odd angles
        for (cx, v, lean) in [(-4, 33, 2), (6, 33, -1), (-21, 13, 0)] {
            for r in 0..<(6 * u) { c.rect(f.x + cx * u + lean * r / 6 + 4 * u, f.b - v * u - r - 1, 2 * u, 1, C(0x3A2228)) }
        }
        // the porch along the ground floor
        c.rect(f.x - 23 * u, f.b - 7 * u, 42 * u, u, roof); c.rect(f.x - 23 * u, f.b - 7 * u, 42 * u, max(1, u / 2), roofEdge)
        for k in 0..<8 { c.rect(f.x - 22 * u + k * 6 * u, f.b - 6 * u, max(1, u / 2 + 1), 6 * u, C(0x4A3A52)) }
        c.rect(f.x - 23 * u, f.b - u, 42 * u, u, C(0x3A2E40))
        c.rect(f.x - 4 * u, f.b - 6 * u, 5 * u, 6 * u, C(0x0E0810)); c.rect(f.x - 5 * u, f.b - 7 * u, 7 * u, u, C(0x5A4868))
        for w in mysteryWindows(c, g) {
            c.rect(w.x - max(1, u / 2), w.y - max(1, u / 2), w.w + 2 * max(1, u / 2), w.h + 2 * max(1, u / 2), C(0x4A3C56))
            c.rect(w.x, w.y, w.w, w.h, C(0x0C0812))
        }
    }

    /// Windows lighting up in odd colours one after another, the door glowing now and then, and bats looping
    /// around the house.
    static func mysteryLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = mysteryFrame(c, g), u = f.u
        let colours: [Px] = [C(0xFFD060), C(0x7AFF8A), C(0xFF6A3A), C(0xC08AFF), C(0x8AE0FF), C(0xFFD060)]
        for (i, w) in mysteryWindows(c, g).enumerated() {
            let step = Int(t * (0.4 + noise(i + 4350) * 0.6) + noise(i + 4351) * 10)
            guard noise(step * 17 + i * 5) > 0.45 else { continue }
            let col = colours[Int(noise(step * 13 + i) * Double(colours.count)) % colours.count]
            c.rect(w.x - u, w.y - u, w.w + 2 * u, w.h + 2 * u, col.alpha(0.18))
            c.rect(w.x, w.y, w.w, w.h, col.alpha(0.85))
            c.rect(w.x + w.w / 2, w.y, max(1, u / 2), w.h, C(0x2A1A30))
            c.rect(w.x, w.y + w.h / 2, w.w, max(1, u / 2), C(0x2A1A30))
            if noise(step * 7 + i) > 0.85 {                               // someone looking out
                c.rect(w.x + w.w / 2 - u / 2 - 1, w.y + u, max(2, u * 3 / 2), max(2, u * 3 / 2), C(0x0C0812))
            }
        }
        let door = scenes4Phase(t, 7, offset: 2)
        if door < 0.4 { c.rect(f.x - 4 * u, f.b - 6 * u, 5 * u, 6 * u, C(0xFFB040, 0.25 + 0.4 * sin(door * .pi / 0.4))) }
        let up: [String] = ["b.....b", "bb.b.bb", ".bbbbb.", "...b..."]
        let down: [String] = ["...b...", ".bbbbb.", "bb.b.bb", "b.....b"]
        let bs = max(1, u * 2 / 3 + (isTall(c) ? 0 : 0)) * s
        for i in 0..<(isTall(c) ? 9 : 6) {
            let a = t * (0.6 + noise(i + 4360) * 0.5) + noise(i + 4361) * 6.28
            let rx = Double((26 + Int(noise(i + 4362) * 20)) * u), ry = Double((10 + Int(noise(i + 4363) * 8)) * u)
            let x = f.x + Int(cos(a) * rx), y = f.b - 30 * u + Int(sin(a * 2) * ry)
            let frame = Int(t * 8 + Double(i)) % 2 == 0 ? up : down
            scenes4Stamp(c, x, y, frame, ["b": C(0x07040C)], s: bs)
        }
    }
}

// MARK: - Rock of Eternity

extension Scenes {
    static let eternityStatueSpots: [Double] = [0.06, 0.17, 0.28, 0.39, 0.71, 0.82, 0.93]
    static let eternityTorchSpots: [Double] = [0.115, 0.225, 0.335, 0.465, 0.635, 0.765, 0.875]

    /// The size of one unit of the cave's furniture.
    static func eternityUnit(_ c: PixelCanvas, _ g: Int) -> Int { unit(g) * (isTall(c) ? 2 : 1) }

    /// The torch flames, as the point the flame sits on.
    static func eternityTorches(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let u = eternityUnit(c, g)
        return eternityTorchSpots.map { (f: Double) in (Int(Double(c.w) * f), g - 24 * u) }
    }

    /// Each statue's eyes: the point between them.
    static func eternityEyes(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let u = eternityUnit(c, g)
        var out: [(x: Int, y: Int)] = []
        for (i, f) in eternityStatueSpots.enumerated() where i != 6 {
            let hunch = i == 1 ? 2 : 0, low = i == 1 || i == 5 ? 1 : 0, bh = i == 5 ? 13 : 16
            out.append((Int(Double(c.w) * f) + hunch * u, g - 4 * u - bh * u - 3 * u + low * u))
        }
        return out
    }

    /// The Rock of Eternity: the wizard Shazam's cavern deep in the rock that floats at the centre of everything.
    /// Stalactites hang from a vaulted ceiling, the seven Deadly Enemies of Man stand in their niches along the
    /// walls as stone statues (Pride crowned, Envy hunched, Greed with his sack, Anger horned with fists raised,
    /// Selfishness arms folded, Laziness slumped and fat, Injustice hooded with a sword), torches burn between
    /// them, and the great stone throne with its gold lightning bolt waits on its dais. Full screen, a rent in the
    /// upper wall looks out on the violet void.
    static func rockOfEternity(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), u = eternityUnit(c, g), tall = isTall(c)
        c.gradient(0, g, C(0x0C0907), C(0x3A2E24), bands: 7)
        for i in 0..<(c.w * g / 160) {                               // the rough rock
            let x = Int(noise(i * 4 + 4400) * Double(c.w)), y = Int(noise(i * 4 + 4401) * Double(g))
            let r = (1 + Int(noise(i * 4 + 4402) * 4)) * s
            c.ellipse(x, y, r * 2, r, noise(i * 4 + 4403) > 0.5 ? C(0x5A4A3A, 0.18) : C(0x080604, 0.25))
        }
        for k in 0..<(g / (9 * s)) {                                  // strata
            let y = k * 9 * s + Int(noise(k + 4410) * 4.0) * s
            c.dunes(base: y, amp: Double(s), freq: 0.05, phase: Double(k), bottom: y + s, C(0x0A0806, 0.3))
        }
        if tall { eternityHigh(c, g) }
        for p in eternityTorches(c, g) {                              // torchlight pooling on the back wall
            c.circle(p.x, p.y, 14 * u, C(0xFF9A40, 0.05)); c.circle(p.x, p.y, 8 * u, C(0xFFA850, 0.06))
        }
        // a carved round halo behind the throne
        let tx = Int(Double(c.w) * 0.55)
        c.circle(tx, g - 30 * u, 22 * u, C(0x4A3E32)); c.circle(tx, g - 30 * u, 20 * u, C(0x2A221A))
        c.circle(tx, g - 30 * u, 17 * u, C(0x3A3026))
        for k in 0..<16 {
            let a: Double = Double(k) / 16 * 2 * Double.pi
            c.rect(tx + Int(cos(a) * 21 * Double(u)), g - 30 * u + Int(sin(a) * 21 * Double(u)), u, u, C(0xC8A040, 0.6))
        }
        for (i, f) in eternityStatueSpots.enumerated() { eternityStatue(c, Int(Double(c.w) * f), g, u, kind: i) }
        for p in eternityTorches(c, g) {                              // torch brackets
            c.rect(p.x - u / 2, p.y + u, max(1, u), 5 * u, C(0x2A2420))
            c.rect(p.x - 2 * u, p.y, 4 * u, 2 * u, C(0x4A3C30)); c.rect(p.x - 2 * u, p.y, 4 * u, max(1, u / 2), C(0x8A7458))
            c.rect(p.x - u, p.y - u, 2 * u, u, C(0x1A1008))
        }
        eternityThrone(c, g)
        var x = 0, i = 0                                              // stalactites
        while x < c.w {
            let len = Int(Double(tall ? g / 6 : 13 * s) * (0.3 + noise(i * 3 + 4420) * 0.7))
            let w = (3 + Int(noise(i * 3 + 4421) * 6)) * s * (tall ? 2 : 1)
            for k in 0..<len {
                let wk = max(1, w * (len - k) / max(1, len))
                c.rect(x + (w - wk) / 2, k, wk, 1, C(0x15100C))
                c.px(x + (w - wk) / 2, k, C(0x4A3E30))
            }
            x += w + Int(noise(i * 3 + 4422) * 6.0) * s; i += 1
        }
        c.ground(g, C(0x2E2620), edge: C(0x7A6A54), speck: C(0x231D18), seed: 44)
        for k in 0..<(c.w / (14 * s) + 1) { c.rect(k * 14 * s + (k % 2) * 7 * s, g + 1, s, c.h - g - 1, C(0x221C16)) }
        c.rect(0, g + (c.h - g) / 2, c.w, s, C(0x221C16))
        c.ellipse(tx, g + 2 * s, 30 * u, 2 * s, C(0xFFD860, 0.06))
    }

    /// One of the Seven Deadly Enemies of Man in stone, on its pedestal in a niche.
    static func eternityStatue(_ c: PixelCanvas, _ x: Int, _ b: Int, _ u: Int, kind: Int) {
        let stone = C(0x726A5E), lit = C(0xA49A86), dark = C(0x3E3830), side = C(0x544C42), niche = C(0x140F0B)
        c.rect(x - 9 * u, b - 34 * u, 18 * u, 34 * u, niche)
        c.ellipse(x, b - 34 * u, 9 * u, 6 * u, niche)
        c.rect(x - 10 * u, b - 34 * u, u, 34 * u, C(0x4A3E32)); c.rect(x + 9 * u, b - 34 * u, u, 34 * u, C(0x2A221A))
        c.rect(x - 6 * u, b - 4 * u, 12 * u, 4 * u, dark); c.rect(x - 6 * u, b - 4 * u, 12 * u, u, lit)
        c.rect(x - 3 * u, b - 2 * u, 6 * u, u, C(0x2A2420))
        let fb = b - 4 * u, wide = kind == 5 ? 2 : (kind == 4 ? 1 : 0), bh = (kind == 5 ? 13 : 16) * u
        let hunch = kind == 1 ? 2 : 0, wb = (10 + wide * 2) * u, wt = (7 + wide * 2) * u
        scenes4Taper(c, x, fb, wb, wt, bh, stone)
        scenes4Taper(c, x + (3 + wide) * u, fb, 3 * u, 2 * u, bh, side)
        for r in 0..<bh { c.px(x - wb / 2 + (wb - wt) * r / bh / 2, fb - 1 - r, lit) }
        let hx = x + hunch * u, hy = fb - bh - 3 * u
        switch kind {
        case 0:                                                       // Pride: crowned
            c.circle(hx, hy, 3 * u, stone)
            for k in 0..<3 { c.rect(hx - 3 * u + k * 2 * u + u / 2, hy - 5 * u, u, 2 * u, lit) }
            c.rect(hx - 3 * u, hy - 3 * u, 6 * u, u, lit)
        case 1:                                                       // Envy: hunched, a hand at the mouth
            c.rect(x - u, fb - bh - u, 4 * u, 2 * u, stone)
            c.circle(hx, hy + u, 3 * u, stone)
            c.rect(hx - u, hy + 3 * u, 2 * u, 3 * u, lit)
        case 2:                                                       // Greed: clutching a sack
            c.circle(hx, hy, 3 * u, stone)
            c.circle(x + 2 * u, fb - bh / 2, 3 * u, lit); c.rect(x + u, fb - bh / 2 - 4 * u, 2 * u, u, dark)
        case 3:                                                       // Anger: horns, fists raised
            c.circle(hx, hy, 3 * u, stone)
            scenes4Line(c, hx - 2 * u, hy - 2 * u, hx - 4 * u, hy - 6 * u, lit, t: max(1, u))
            scenes4Line(c, hx + 2 * u, hy - 2 * u, hx + 4 * u, hy - 6 * u, stone, t: max(1, u))
            c.rect(x - 7 * u, fb - bh - 6 * u, 2 * u, 7 * u, stone); c.rect(x + 5 * u, fb - bh - 6 * u, 2 * u, 7 * u, side)
            c.rect(x - 8 * u, fb - bh - 8 * u, 3 * u, 3 * u, lit); c.rect(x + 5 * u, fb - bh - 8 * u, 3 * u, 3 * u, stone)
        case 4:                                                       // Selfishness: arms folded tight
            c.circle(hx, hy, 3 * u, stone)
            c.rect(x - 5 * u, fb - bh + 4 * u, 10 * u, 2 * u, lit); c.rect(x - 5 * u, fb - bh + 6 * u, 10 * u, u, dark)
        case 5:                                                       // Laziness: slumped and fat
            c.ellipse(x, fb - bh / 2, 7 * u, 5 * u, stone); c.ellipse(x - 2 * u, fb - bh / 2 - u, 3 * u, 2 * u, lit)
            c.circle(hx, hy + u, 3 * u, stone); c.rect(hx - 3 * u, hy + 3 * u, 6 * u, u, dark)
        default:                                                      // Injustice: hooded, a sword held down
            scenes4Taper(c, hx, hy + 3 * u, 8 * u, 2 * u, 8 * u, stone)
            c.rect(hx - 2 * u, hy - u, 4 * u, 3 * u, dark)
            c.rect(x, fb - bh + 2 * u, u, bh - 2 * u, lit); c.rect(x - 2 * u, fb - bh + 4 * u, 5 * u, u, lit)
        }
        if kind != 6 {
            let ey = hy + (kind == 1 || kind == 5 ? u : 0)
            c.rect(hx - 2 * u, ey, u, u, dark); c.rect(hx + u, ey, u, u, dark)
        }
    }

    /// The throne of the wizard on its stepped dais.
    static func eternityThrone(_ c: PixelCanvas, _ g: Int) {
        let u = eternityUnit(c, g), x = Int(Double(c.w) * 0.55)
        for k in 0..<3 {
            let w = (44 - k * 8) * u
            c.rect(x - w / 2, g - (k + 1) * 2 * u, w, 2 * u, C(0x4A4238)); c.rect(x - w / 2, g - (k + 1) * 2 * u, w, max(1, u / 2), C(0x8A7E68))
        }
        let seat = g - 6 * u, stone = C(0x5E564A), lit = C(0x9A8E78)
        c.rect(x - 10 * u, seat - 30 * u, 20 * u, 30 * u, stone)
        scenes4Taper(c, x, seat - 30 * u, 20 * u, 2 * u, 8 * u, stone)
        c.rect(x - 10 * u, seat - 30 * u, u, 30 * u, lit)
        c.rect(x + 9 * u, seat - 30 * u, u, 30 * u, C(0x3A342C))
        c.rect(x - 7 * u, seat - 27 * u, 14 * u, 20 * u, C(0x3A332A))
        scenes4Stamp(c, x - 6 * u, seat - 26 * u, [
            "...yyy",
            "..yyy.",
            ".yyy..",
            "yyyyy.",
            "..yyy.",
            ".yyy..",
            ".yy...",
            "yy....",
        ], ["y": C(0xE8C040)], s: 2 * u)
        c.rect(x - 9 * u, seat - 6 * u, 18 * u, 6 * u, C(0x4E463C)); c.rect(x - 9 * u, seat - 6 * u, 18 * u, u, lit)
        for side in [-1, 1] {                                          // the arms
            let ax = x + side * 12 * u - 2 * u
            c.rect(ax, seat - 12 * u, 4 * u, 12 * u, stone)
            c.ellipse(ax + 2 * u, seat - 12 * u, 3 * u, 2 * u, lit)
            c.rect(ax + u, seat - 9 * u, 2 * u, 2 * u, C(0xC8A040))
        }
    }

    /// Full screen: a rent in the upper wall of the cavern opening on the void, violet and starry, with broken rocks
    /// drifting in it.
    static func eternityHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), cx = c.w / 2, cy = g * 30 / 100, rx = c.w * 30 / 100, ry = g * 16 / 100
        for dy in -ry...ry {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int(Double(rx) * k.squareRoot()) + Int((noise((dy + ry) / (3 * s) + 4450) - 0.5) * 16) * s
            guard half > 0 else { continue }
            let y = cy + dy, col = lerp(C(0x1A0A30), C(0x4A1A6A), Double(dy + ry) / Double(2 * ry))
            c.rect(cx - half - 2 * s, y, half * 2 + 4 * s, 1, C(0x5A4A3A))
            c.rect(cx - half, y, half * 2, 1, col)
        }
        c.stars(cy - ry, cy + ry, density: 30, seed: 45, x0: cx - rx, x1: cx + rx) { x, y in
            let dx = Double(x - cx) / Double(rx), dy = Double(y - cy) / Double(ry)
            return dx * dx + dy * dy < 0.8
        }
        c.ellipse(cx + rx / 4, cy, rx / 2, ry / 4, C(0xC86AE0, 0.12))
        c.ellipse(cx - rx / 5, cy - ry / 4, rx / 3, ry / 6, C(0x6A8AFF, 0.12))
        for i in 0..<6 {                                              // drifting rocks
            let x = cx + Int((noise(i + 4460) - 0.5) * Double(rx) * 1.4), y = cy + Int((noise(i + 4461) - 0.5) * Double(ry))
            let r = (2 + Int(noise(i + 4462) * 5)) * s
            c.ellipse(x, y, r + s, r, C(0x1A1214)); c.ellipse(x - s, y - r / 2, r, max(1, r / 3), C(0x6A4A7A))
        }
    }

    /// Torches flickering, lightning cracking across the vault and down into the throne, the statues' eyes flaring
    /// red in the flash, and sparks crawling over the throne's bolt.
    static func eternityLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let u = eternityUnit(c, g), tall = isTall(c), tx = Int(Double(c.w) * 0.55)
        for (i, p) in eternityTorches(c, g).enumerated() {
            let f = noise(Int(t * 10) + i * 31), f2 = noise(Int(t * 10) + i * 31 + 7)
            c.circle(p.x, p.y - 2 * u, (6 + Int(f * 2)) * u, C(0xFF9A3A, 0.10))
            c.rect(p.x - 2 * u, p.y - 3 * u, 4 * u, 2 * u, C(0xE85A1A))
            c.rect(p.x - u, p.y - (5 + Int(f * 2)) * u, 2 * u, (3 + Int(f * 2)) * u, C(0xFF8A2A))
            c.rect(p.x - u / 2, p.y - (3 + Int(f2 * 2)) * u, max(1, u), (2 + Int(f2 * 2)) * u, C(0xFFE070))
        }
        let period = 3.7, ph = scenes4Phase(t, period, offset: 2.6), n = Int((t + 2.6) / period)
        if ph < 0.12 {
            let strong = ph < 0.035 || (ph > 0.06 && ph < 0.09)
            let k: Double = strong ? 1 : 0.45
            if strong { c.rect(0, 0, c.w, g, C(0xFFF0C8, 0.06)) }
            let y0 = tall ? g * 30 / 100 : 5 * u, x0 = Int(noise(n * 3 + 4470) * Double(c.w) * 0.3)
            let x1 = c.w - Int(noise(n * 3 + 4471) * Double(c.w) * 0.3), mx = (x0 + x1) / 2
            let core = C(0xFFFFF0), glow = C(0xFFE060), jag = Double(6 * u), wd = Double(u)
            scenes4Bolt(c, x0, y0, mx, y0 + 6 * u, seed: n * 2, jag: jag, core: core, glow: glow, width: wd, strength: k)
            scenes4Bolt(c, mx, y0 + 6 * u, x1, y0 + Int(noise(n + 4472) * 8.0) * u, seed: n * 2 + 1, jag: jag, core: core, glow: glow, width: wd, strength: k)
            scenes4Bolt(c, mx, y0 + 6 * u, tx, g - 36 * u, seed: n * 2 + 5, jag: jag * 0.7, core: core, glow: glow, width: wd, strength: k)
            for e in eternityEyes(c, g) {
                c.rect(e.x - 2 * u, e.y, u, u, C(0xFF3A2A)); c.rect(e.x + u, e.y, u, u, C(0xFF3A2A))
                c.circle(e.x, e.y, 3 * u, C(0xFF3A2A, 0.15 * k))
            }
        }
        let seat = g - 6 * u                                         // sparks over the bolt on the throne
        for i in 0..<3 {
            let m = Int(t * 9) * 3 + i
            let sx = tx - 4 * u + Int(noise(m * 2 + 4480) * 12.0) * u, sy = seat - 26 * u + Int(noise(m * 2 + 4481) * 16.0) * u
            let ex = Double(sx + Int((noise(m + 4482) - 0.5) * 8.0) * u), ey = Double(sy - 3 * u)
            c.glowLine(Double(sx), Double(sy), ex, ey, core: C(0xFFF8D0), glow: C(0xFFD040),
                       coreR: 0.4 * Double(u), glowR: 1.4 * Double(u), strength: 0.8)
        }
    }
}

// MARK: - New Genesis

extension Scenes {
    static let genesisSky = C(0xC8E4F8)

    /// The Boom Tube's centre and full radius.
    static func genesisTube(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        isTall(c) ? (Int(Double(c.w) * 0.8), g * 44 / 100, g / 9) : (Int(Double(c.w) * 0.84), g * 40 / 100, 14 * unit(g))
    }

    /// New Genesis: a golden city of domes and spires riding on a floating island in a bright, high sky, smaller
    /// islands drifting further off in the haze, a sea of cloud below, and the crew out on a gold-and-ivory terrace
    /// with its balustrade. Full screen, the island hangs higher with waterfalls pouring off its rim.
    static func newGenesis(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x3A88D8), C(0xE4F2FC), bands: 8)
        let sx = Int(Double(c.w) * 0.62), sy = tall ? g / 10 : 6 * s
        for k in 0..<4 { c.circle(sx, sy, (tall ? g / 6 : 22 * s) * (4 - k) / 4, C(0xFFF8E0, 0.12)) }
        c.circle(sx, sy, tall ? g / 30 : 4 * s, C(0xFFFCF0))
        for i in 0..<(tall ? 8 : 4) {
            cloud(c, Int(noise(i * 3 + 4500) * Double(c.w)), Int(Double(g) * (0.12 + noise(i * 3 + 4501) * 0.5)),
                  (3 + Int(noise(i * 3 + 4502) * 3)) * s * (tall ? 2 : 1), seed: i + 450, top: C(0xF4FAFF, 0.8), base: C(0xD4E6F4, 0.8))
        }
        if tall {
            genesisIsland(c, Int(Double(c.w) * 0.1), g * 22 / 100, 30 * s, 16 * s, k: s, haze: 0.6, seed: 1)
            genesisIsland(c, Int(Double(c.w) * 0.66), g * 16 / 100, 36 * s, 20 * s, k: s, haze: 0.55, seed: 2)
            genesisIsland(c, Int(Double(c.w) * 0.95), g * 55 / 100, 26 * s, 14 * s, k: s, haze: 0.45, seed: 3)
            genesisIsland(c, Int(Double(c.w) * 0.4), g * 34 / 100, c.w * 22 / 100, g * 28 / 100, k: 3 * s, haze: 0, seed: 4)
            for i in 0..<10 {                                         // a lower bank of cloud the falls vanish into
                cloud(c, Int(Double(i) / 10 * Double(c.w)) + Int(noise(i + 4505) * 30.0) * s, g * 74 / 100 + Int(noise(i + 4506) * 16.0) * s,
                      (6 + Int(noise(i + 4507) * 4)) * s, seed: i + 470, top: C(0xF8FCFF, 0.9), base: C(0xDCEAF6, 0.9))
            }
            genesisIsland(c, Int(Double(c.w) * 0.15), g * 62 / 100, 22 * s, 10 * s, k: s, haze: 0.35, seed: 5)
        } else {
            genesisIsland(c, Int(Double(c.w) * 0.07), g * 34 / 100, 16 * s, 8 * s, k: s, haze: 0.55, seed: 1)
            genesisIsland(c, Int(Double(c.w) * 0.64), g * 24 / 100, 20 * s, 9 * s, k: s, haze: 0.45, seed: 2)
            genesisIsland(c, Int(Double(c.w) * 0.36), g * 44 / 100, 56 * s, 20 * s, k: s, haze: 0, seed: 4)
        }
        // the cloud sea
        c.dunes(base: g - 14 * s, amp: Double(3 * s), freq: 0.05, phase: 0.3, bottom: g, C(0xE8F2FA), shade: C(0xFFFFFF))
        for i in 0..<(c.w / (24 * s)) {
            c.ellipse(Int(noise(i + 4510) * Double(c.w)), g - 12 * s + Int(noise(i + 4511) * 6.0) * s, (10 + Int(noise(i + 4512) * 10)) * s, 3 * s, C(0xFFFFFF, 0.8))
        }
        c.dunes(base: g - 8 * s, amp: Double(2 * s), freq: 0.08, phase: 1.6, bottom: g, C(0xD8E6F2))
        // the terrace balustrade
        let ry = g - 7 * s
        c.rect(0, ry, c.w, s, C(0xF8EED0)); c.rect(0, ry + s, c.w, s, C(0xC8A858))
        for x in stride(from: 0, to: c.w, by: 4 * s) {
            c.rect(x + s, ry + 2 * s, 2 * s, 5 * s, C(0xF0E2BC)); c.rect(x + 2 * s, ry + 2 * s, s, 5 * s, C(0xD0BC90))
        }
        for x in stride(from: 0, to: c.w, by: 48 * s) {
            c.rect(x, ry - 3 * s, 4 * s, 10 * s, C(0xF4E8C8)); c.rect(x, ry - 4 * s, 4 * s, s, C(0xE8B840))
            c.circle(x + 2 * s, ry - 5 * s, s, C(0xFFD860))
        }
        c.ground(g, C(0xE2CE9C), edge: C(0xFFF2C8), speck: C(0xCCB482), seed: 46)
        for x in stride(from: 0, to: c.w, by: 20 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0xC8A858)) }
        c.rect(0, g + (c.h - g) / 2, c.w, s, C(0xC8A858))
    }

    /// A floating island with the city on top: rocky underside tapering to a point, a green rim, then domes,
    /// spires and towers in ivory and gold, all washed toward the sky by `haze`.
    static func genesisIsland(_ c: PixelCanvas, _ x: Int, _ y: Int, _ hw: Int, _ depth: Int, k: Int, haze: Double, seed: Int) {
        func hz(_ col: Px) -> Px { lerp(col, genesisSky, haze) }
        for dx in -hw...hw {
            let u = Double(abs(dx)) / Double(hw)
            let bot = y + Int(Double(depth) * pow(max(0, 1 - u * u), 0.8)) + Int(noise(seed * 50 + (dx + hw) / 2) * Double(depth) / 5)
            c.rect(x + dx, y, 1, max(1, bot - y), hz(dx < 0 ? C(0xB88E5A) : C(0x9A7448)))
            c.rect(x + dx, y + (bot - y) * 3 / 5, 1, max(1, (bot - y) * 2 / 5), hz(C(0x6A4E34)))
            c.px(x + dx, y, hz(C(0x7AC060)))
        }
        c.rect(x - hw, y + 1, hw * 2, max(1, k), hz(C(0x5A9A48)))
        if depth > 40 {                                               // waterfalls off the rim
            for i in 0..<4 {
                let wx = x - hw + Int(noise(seed * 9 + i) * Double(hw * 2))
                c.rect(wx, y + 2, 2 * k / 3 + 1, depth + 40, C(0xF0F8FF, 0.45))
                c.rect(wx, y + 2, 1, depth + 40, C(0xFFFFFF, 0.5))
            }
        }
        let ivory = hz(C(0xF4EAD0)), ivoryShade = hz(C(0xD2C098)), gold = hz(C(0xE8B840)), goldLit = hz(C(0xFFE890))
        var bx = x - hw + 4 * k, i = 0
        while bx < x + hw - 4 * k {
            let d = Double(abs(bx - x)) / Double(hw)
            let h = max(4 * k, Int((1 - d * 0.6) * Double(18 * k) * (0.5 + noise(seed * 50 + i + 20) * 0.6)))
            switch Int(noise(seed * 50 + i + 40) * 3) {
            case 0:
                c.ellipse(bx, y - h / 2, 3 * k, 3 * k, gold); c.rect(bx - 2 * k, y - h / 2 - 2 * k, max(1, k), 2 * k, goldLit)
                c.rect(bx - 3 * k, y - h / 2, 6 * k, h / 2, ivory); c.rect(bx + k, y - h / 2, 2 * k, h / 2, ivoryShade)
                c.rect(bx, y - h / 2 - 5 * k, max(1, k / 2 + 1), 2 * k, gold)
            case 1:
                scenes4Taper(c, bx, y, 3 * k, k, h, ivory)
                c.rect(bx - k, y - h * 2 / 3, 2 * k + 1, k, gold)
                c.circle(bx, y - h, k, goldLit)
            default:
                c.rect(bx - 2 * k, y - h * 2 / 3, 4 * k, h * 2 / 3, ivory); c.rect(bx + k, y - h * 2 / 3, k, h * 2 / 3, ivoryShade)
                scenes4Taper(c, bx, y - h * 2 / 3, 5 * k, k, 3 * k, gold)
                for wy in stride(from: y - h * 2 / 3 + 2 * k, to: y - k, by: 3 * k) { c.rect(bx - k, wy, max(1, k), max(1, k), hz(C(0x8AB8E0))) }
            }
            bx += (5 + Int(noise(seed * 50 + i + 60) * 4)) * k; i += 1
        }
        if hw > 30 * k {                                              // the great dome in the middle
            c.ellipse(x, y - 13 * k, 10 * k, 9 * k, gold)
            c.ellipse(x - 4 * k, y - 17 * k, 3 * k, 3 * k, goldLit)
            c.rect(x - 10 * k, y - 13 * k, 20 * k, 13 * k, ivory)
            for cx in stride(from: x - 9 * k, to: x + 10 * k, by: 3 * k) { c.rect(cx, y - 12 * k, max(1, k), 12 * k, ivoryShade) }
            c.rect(x - 11 * k, y - 13 * k, 22 * k, k, gold)
            scenes4Taper(c, x, y - 22 * k, 2 * k, 1, 8 * k, goldLit)
        }
    }

    /// The Boom Tube tearing open in the sky, holding, then closing; glints on the gold; a cloud drifting by.
    static func genesisLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), b = genesisTube(c, g)
        for i in 0..<3 {
            let x = scenes4Slide(t, speed: 3.0 + Double(i) * 1.5, phase: noise(i + 4530), w: c.w, margin: 40 * s)
            c.ellipse(x, Int(Double(g) * (0.2 + Double(i) * 0.18)), (14 + i * 4) * s, 2 * s, C(0xFFFFFF, 0.45))
            c.ellipse(x + 6 * s, Int(Double(g) * (0.2 + Double(i) * 0.18)) - s, (6 + i * 2) * s, s, C(0xFFFFFF, 0.5))
        }
        let ph = (t + 0.7).truncatingRemainder(dividingBy: 9)
        let k: Double = ph < 0.6 ? ph / 0.6 : (ph < 4.6 ? 1 : (ph < 5.2 ? 1 - (ph - 4.6) / 0.6 : 0))
        if k > 0 {
            let r = max(1, Int(Double(b.r) * k))
            c.circle(b.x, b.y, r + 4 * s, C(0xFFF4B0, 0.2))
            c.circle(b.x, b.y, r + 2 * s, C(0xFFF4B0, 0.35))
            c.circle(b.x, b.y, r, C(0xFFFFFF))
            for j in 1..<5 {
                let rr = r * (5 - j) / 5
                c.circle(b.x, b.y, rr, j % 2 == 1 ? lerp(C(0xFFE070), C(0x5A3AB0), Double(j) / 5) : lerp(C(0xFFFFFF), C(0x8A7AE0), Double(j) / 5))
            }
            c.circle(b.x, b.y, max(1, r / 6), C(0x1A1048))
            for a in 0..<8 {
                let ang: Double = Double(a) * Double.pi / 4 + t * 2.5
                let r0 = Double(r) * 0.3, r1 = Double(r) * 0.85
                c.glowLine(Double(b.x) + cos(ang) * r0, Double(b.y) + sin(ang) * r0, Double(b.x) + cos(ang + 0.5) * r1,
                           Double(b.y) + sin(ang + 0.5) * r1, core: C(0xFFFFFF, 0.6), glow: C(0xFFF0A0), coreR: 0.4, glowR: 1.2, strength: 0.6)
            }
            for i in 0..<10 {
                let ang: Double = noise(Int(t * 12) * 10 + i) * 2 * Double.pi
                let d = Double(r + 3 * s) + noise(Int(t * 12) * 10 + i + 5) * Double(4 * s)
                c.rect(b.x + Int(cos(ang) * d), b.y + Int(sin(ang) * d), s, s, C(0xFFFFE0))
            }
        }
        for i in 0..<5 {                                              // glints on the gold
            guard noise(Int(t * 3) * 7 + i) > 0.6 else { continue }
            let x = Int(noise(i * 3 + 4540) * Double(c.w)), y = Int(noise(i * 3 + 4541) * Double(g) * 0.6)
            c.px(x, y, white); c.px(x - 1, y, C(0xFFFFFF, 0.5)); c.px(x + 1, y, C(0xFFFFFF, 0.5))
            c.px(x, y - 1, C(0xFFFFFF, 0.5)); c.px(x, y + 1, C(0xFFFFFF, 0.5))
        }
    }
}

// MARK: - Thanagar

extension Scenes {
    /// One of Thanagar's towers: where it stands, how wide and tall, which layer, and whether it carries wings.
    struct ThanagarTower { let x, w, h: Int; let near: Bool; let wings: Bool; let seed: Int }

    /// The towers, far layer then near.
    static func thanagarTowers(_ c: PixelCanvas, _ g: Int) -> [ThanagarTower] {
        let s = unit(g), tall = isTall(c)
        var out: [ThanagarTower] = []
        for (layer, gap) in [(0, 14), (1, 34)] {
            var x = -6 * s, i = 0
            while x < c.w + 10 * s {
                let n = noise(i * 7 + layer * 300 + 4600)
                let h: Int
                if tall { h = Int(Double(g) * (layer == 0 ? 0.25 + n * 0.35 : 0.35 + n * 0.5)) }
                else { h = (layer == 0 ? 22 + Int(n * 24) : 34 + Int(n * 28)) * s }
                let w = (layer == 0 ? 4 + Int(noise(i * 7 + 1 + layer * 300) * 4) : 6 + Int(noise(i * 7 + 1 + layer * 300) * 5)) * s * (tall && layer == 1 ? 2 : 1)
                out.append(ThanagarTower(x: x, w: w, h: h, near: layer == 1, wings: noise(i * 7 + 2 + layer * 300) > 0.55, seed: i + layer * 100))
                x += (gap / 2 + Int(noise(i * 7 + 3 + layer * 300) * Double(gap))) * s; i += 1
            }
        }
        return out
    }

    /// Thanagar at sunset: an amber sky with the planet's rings sweeping across it in a great arc, a pale sun low on
    /// the left, and a forest of needle towers with swept-back wing vanes, bridges and amber windows; the crew on a
    /// bronze-edged plaza. Full screen adds the planet's moons.
    static func thanagar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x24102E), C(0xE88A40), bands: 9)
        c.stars(0, g / 3, density: tall ? 90 : 70, seed: 47)
        if tall {
            c.circle(Int(Double(c.w) * 0.2), g / 7, g / 14 + 3 * s, C(0xF0C8A0, 0.12)); c.circle(Int(Double(c.w) * 0.2), g / 7, g / 14, C(0xC89A80))
            c.circle(Int(Double(c.w) * 0.2) + g / 40, g / 7 - g / 50, g / 40, C(0xB08670))
            c.circle(Int(Double(c.w) * 0.32), g / 12, g / 40, C(0xE8D8C8))
        }
        // the rings
        let cx = Double(c.w) * 0.58, cy = Double(g) * (tall ? 1.1 : 1.25)
        let rx = Double(c.w) * 0.75, ry = Double(g) * (tall ? 0.95 : 1.05), thick = tall ? 26 * s : 9 * s
        let alphas: [Double] = [0.35, 0.55, 0.6, 0.3, 0.05, 0.45, 0.5, 0.25, 0.4, 0.15]
        for x in 0..<c.w {
            let dx = (Double(x) - cx) / rx
            guard abs(dx) < 1 else { continue }
            let top = Int(cy - ry * (1 - dx * dx).squareRoot() + (Double(x) - cx) * 0.06)
            for (k, a) in alphas.enumerated() {
                let y0 = top + thick * k / alphas.count, y1 = top + thick * (k + 1) / alphas.count
                c.rect(x, y0, 1, max(1, y1 - y0), C(k % 3 == 1 ? 0xF8D0A8 : 0xFFE8C8, a))
            }
        }
        // the sun low on the left
        let sx = Int(Double(c.w) * 0.12), sy = g - (tall ? g / 5 : 16 * s)
        for k in 0..<4 { c.circle(sx, sy, (tall ? 30 : 14) * s * (4 - k) / 4, C(0xFFE0A0, 0.12)) }
        c.circle(sx, sy, (tall ? 9 : 5) * s, C(0xFFF4D8))
        c.rect(0, g - 10 * s, c.w, 10 * s, C(0xF0A050, 0.2))
        let towers = thanagarTowers(c, g)
        for t in towers where !t.near { thanagarTower(c, t, g - 4 * s, C(0x8A4A44), edge: C(0xC87A50), win: C(0xFFD080, 0.5)) }
        c.rect(0, g - 14 * s, c.w, 14 * s, C(0xE89048, 0.15))
        let near = towers.filter { $0.near }
        for (i, t) in near.enumerated() where i + 1 < near.count && noise(t.seed + 4620) > 0.5 {     // bridges
            let n = near[i + 1], y = g - min(t.h, n.h) / 2
            c.rect(t.x + t.w / 2, y, n.x - t.x, 2 * s, C(0x2A1620)); c.rect(t.x + t.w / 2, y, n.x - t.x, max(1, s / 2), C(0xC8804A))
        }
        for t in near { thanagarTower(c, t, g, C(0x2C1620), edge: C(0xD08A50), win: C(0xFFC060, 0.85)) }
        c.ground(g, C(0x34201C), edge: C(0xD08A50), speck: C(0x2A1814), seed: 47)
        for x in stride(from: 0, to: c.w, by: 24 * s) {
            c.rect(x, g + 1, s, c.h - g - 1, C(0x5A3424))
            c.rect(x + 10 * s, g + 3 * s, 4 * s, s, C(0x8A5A34))
        }
    }

    /// A needle tower: a tapering shaft, a disc platform, a thin spire, rows of lit windows, and on some a pair of
    /// swept wing vanes near the top.
    static func thanagarTower(_ c: PixelCanvas, _ t: ThanagarTower, _ b: Int, _ col: Px, edge: Px, win: Px) {
        let s = max(1, t.w / 8), shaftH = t.h * 82 / 100, cx = t.x + t.w / 2
        scenes4Taper(c, cx, b, t.w, max(2, t.w / 2), shaftH, col)
        for r in 0..<shaftH { c.px(cx - (t.w - (t.w - max(2, t.w / 2)) * r / shaftH) / 2, b - 1 - r, edge) }
        let top = b - shaftH
        c.ellipse(cx, b - shaftH * 7 / 10, t.w * 3 / 4, max(1, t.w / 6), col)
        c.rect(cx - t.w * 3 / 4, b - shaftH * 7 / 10, t.w * 3 / 2, 1, edge)
        scenes4Taper(c, cx, top, max(2, t.w / 2), 1, t.h - shaftH, col)
        c.px(cx, b - t.h, edge)
        if t.wings {
            let wy = top + shaftH / 10, span = t.w * 3 / 2
            for side in [-1, 1] {
                for k in 0..<span {
                    let x = cx + side * (t.w / 4 + k), drop = k * 2 / 3
                    c.rect(x, wy + drop, 1, max(1, (span - k) * 2 / 3), col)
                    c.px(x, wy + drop, edge)
                }
            }
        }
        for (j, y) in stride(from: top + shaftH / 4, to: b - 3 * s, by: 3 * s).enumerated() where noise(t.seed * 31 + j) > 0.35 {
            c.rect(cx - s / 2, y, max(1, s), max(1, s), win)
        }
    }

    /// Winged Thanagarians gliding and beating across the sunset, and the beacons on the near towers.
    static func thanagarLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c)
        let up: [String] = [
            "ee.........ee",
            "wwe.......eww",
            ".wwwe.h.ewww.",
            "..wwwwbwwww..",
            "....wbbbw....",
            ".....bbb.....",
            ".....b.b.....",
        ]
        let down: [String] = [
            ".............",
            "......h......",
            "....eebee....",
            "..ewwwbwwwe..",
            ".www.bbb.www.",
            "ww...b.b...ww",
            "e...........e",
        ]
        let glide: [String] = [
            ".............",
            ".............",
            "......h......",
            "eeeeeebeeeeee",
            "wwwwwwbwwwwww",
            "..wwwbbbwww..",
            ".....b.b.....",
        ]
        let pal: [Character: Px] = ["w": C(0xD8C4A0), "e": C(0x7A5A44), "b": C(0x24100E), "h": C(0xF0B840)]
        for i in 0..<(tall ? 8 : 5) {
            let big = noise(i + 4650) > 0.6, gs = s * (big ? 2 : 1) * (tall ? 2 : 1)
            let speed = (big ? 22.0 : 12.0) * Double(s) * (tall ? 2 : 1)
            var x = scenes4Slide(t, speed: speed, phase: noise(i + 4651), w: c.w, margin: 30 * gs)
            let left = noise(i + 4652) > 0.5
            if left { x = c.w - x }
            let y = Int(Double(tall ? g * 6 / 10 : 34 * s) * (0.15 + noise(i + 4653) * 0.85)) + Int(sin(t * 0.9 + Double(i)) * 2 * Double(gs))
            let beat = scenes4Phase(t, 3.0, offset: noise(i + 4654) * 3)
            let rows = beat < 0.6 ? glide : (Int(t * 6) % 2 == 0 ? up : down)
            scenes4Stamp(c, x, y, rows, pal, s: gs)
        }
        for tw in thanagarTowers(c, g) where tw.near && noise(tw.seed + 4660) > 0.4 {
            if scenes4Phase(t, 2.2, offset: noise(tw.seed + 4661) * 2.2) < 0.25 {
                let cx = tw.x + tw.w / 2
                c.rect(cx - s / 2, g - tw.h - s, max(1, s), max(1, s), C(0xFF5A3A))
                c.circle(cx, g - tw.h, 2 * s, C(0xFF5A3A, 0.3))
            }
        }
    }
}

// MARK: - Kandor

extension Scenes {
    /// The glass bell: the centre of its rim on the floor, and its radii.
    static func kandorBell(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, rx: Int, ry: Int) {
        isTall(c) ? (c.w / 2, g, c.w * 40 / 100, g * 80 / 100) : (c.w / 2, g, c.w * 47 / 100, g * 135 / 100)
    }

    /// Half the bell's width at row `y` (0 above it).
    static func kandorHalf(_ b: (x: Int, y: Int, rx: Int, ry: Int), _ y: Int) -> Int {
        let d = Double(b.y - y) / Double(b.ry)
        guard d < 1, y <= b.y else { return 0 }
        return Int(Double(b.rx) * (1 - d * d).squareRoot())
    }

    /// The crystal towers inside the bell: where, how wide and tall, and front or back.
    static func kandorTowers(_ c: PixelCanvas, _ g: Int) -> [(x: Int, w: Int, h: Int, front: Bool)] {
        let s = unit(g), b = kandorBell(c, g), tall = isTall(c)
        var out: [(x: Int, w: Int, h: Int, front: Bool)] = []
        for layer in 0..<2 {
            var x = b.x - b.rx * 9 / 10, i = 0
            while x < b.x + b.rx * 9 / 10 {
                let d = Double(abs(x - b.x)) / Double(b.rx)
                let roof = b.y - Int(Double(b.ry) * max(0, 1 - d * d).squareRoot())
                let room = g - roof - (tall ? 14 : 6) * s
                let n = noise(i * 5 + layer * 200 + 4700)
                let want = Double(tall ? g * 55 / 100 : 50 * s) * (1 - d * 0.7) * (layer == 0 ? 0.6 + n * 0.5 : 0.35 + n * 0.45)
                let w = (layer == 0 ? 5 : 6) * s * (tall ? 2 : 1) + Int(noise(i * 5 + 1 + layer * 200) * 4.0) * s
                let h = min(room, Int(want))
                if h > 6 * s { out.append((x, w, h, layer == 1)) }
                x += w + Int(noise(i * 5 + 2 + layer * 200) * 8.0) * s; i += 1
            }
        }
        // the great central spire
        out.insert((b.x - 4 * s * (tall ? 2 : 1), 8 * s * (tall ? 2 : 1), Int(Double(g - (b.y - b.ry)) * 0.85), false), at: out.count / 2)
        return out
    }

    /// The face looming outside the glass on tall canvases: its centre and size, and its eyes.
    static func kandorFace(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, rx: Int, ry: Int) {
        (c.w / 2, g * 30 / 100, c.w * 24 / 100, g * 27 / 100)
    }

    /// Kandor, the bottle city: a Kryptonian city of pale crystal spires under its glass bell, its little sky glowing
    /// amber, the curve of the bell catching the light, and outside it the green gloom of Brainiac's ship. Full
    /// screen, the whole bell shows, and Brainiac's huge green face leans over it.
    static func kandor(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), b = kandorBell(c, g)
        c.gradient(0, g, C(0x041210), C(0x0E2C28), bands: 6)
        for i in 0..<(c.w * g / 900) {                                 // the ship's circuitry
            let x = Int(noise(i * 4 + 4720) * Double(c.w)), y = Int(noise(i * 4 + 4721) * Double(g))
            let l = (6 + Int(noise(i * 4 + 4722) * 20)) * s
            if noise(i * 4 + 4723) > 0.5 { c.rect(x, y, l, 1, C(0x2AC88A, 0.14)) } else { c.rect(x, y, 1, l, C(0x2AC88A, 0.14)) }
            c.rect(x - s, y - s, 2 * s, 2 * s, C(0x5AF0A8, 0.25))
        }
        if tall { kandorBrainiac(c, g) }
        // inside the bell
        let top = max(0, b.y - b.ry)
        for y in top..<g {
            let half = kandorHalf(b, y)
            guard half > 0 else { continue }
            let k = Double(y - (b.y - b.ry)) / Double(b.ry)
            let a = tall ? 0.1 + 0.85 * k * k : 0.45 + 0.5 * k
            c.rect(b.x - half, y, half * 2, 1, lerp(C(0x4A6A78), C(0xF0A060), k).alpha(a))
        }
        // the sun of Kandor
        let sy = b.y - b.ry * (tall ? 55 : 72) / 100
        c.circle(b.x + b.rx / 3, sy, (tall ? 22 : 12) * s, C(0xFF8A4A, 0.12)); c.circle(b.x + b.rx / 3, sy, (tall ? 7 : 4) * s, C(0xFFB878))
        for t in kandorTowers(c, g) { kandorSpire(c, t.x, g - 2 * s, t.w, t.h, haze: t.front ? 0 : 0.4) }
        for i in 0..<(b.rx / (10 * s)) {                               // low domes
            let x = b.x - b.rx * 8 / 10 + i * 20 * s + Int(noise(i + 4730) * 8.0) * s, r = (4 + Int(noise(i + 4731) * 3)) * s
            c.ellipse(x, g - 2 * s, r, r * 2 / 3, C(0x9AC8D8)); c.ellipse(x - r / 3, g - 2 * s - r / 3, r / 3, r / 4, C(0xE8F8FF))
        }
        // the glass rim and its highlights
        let n = (b.rx + b.ry) * 4
        for i in 0...n {
            let a: Double = Double(i) / Double(n) * Double.pi
            let x = b.x + Int(cos(a) * Double(b.rx)), y = b.y - Int(sin(a) * Double(b.ry))
            c.rect(x - s, y, 2 * s, 2 * s, C(0xBFF4F0, 0.55))
            if a > 2.0 && a < 2.7 {
                c.rect(b.x + Int(cos(a) * Double(b.rx) * 0.93), b.y - Int(sin(a) * Double(b.ry) * 0.93), 2 * s, 2 * s, C(0xFFFFFF, 0.35))
            }
            if a > 0.5 && a < 0.75 {
                c.rect(b.x + Int(cos(a) * Double(b.rx) * 0.95), b.y - Int(sin(a) * Double(b.ry) * 0.95), s, s, C(0xFFFFFF, 0.3))
            }
        }
        if tall {
            c.rect(b.x - s, b.y - b.ry - 8 * s, 2 * s, 8 * s, C(0x8AB0B0))
            c.circle(b.x, b.y - b.ry - 10 * s, 4 * s, C(0xBFE8E8)); c.circle(b.x - s, b.y - b.ry - 11 * s, s, white)
        }
        // the metal base of the bell, outside the glass
        for y in (g - 5 * s)..<g {
            let half = kandorHalf(b, y)
            c.rect(0, y, b.x - half - s, 1, C(0x2A3A38)); c.rect(b.x + half + s, y, c.w - b.x - half - s, 1, C(0x2A3A38))
        }
        c.ground(g, C(0x22303C), edge: C(0x9AD4E4), speck: C(0x2C3C4A), seed: 48)
        for x in stride(from: 0, to: c.w, by: 10 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x2C3E4E)) }
        c.rect(0, g + (c.h - g) / 2, c.w, s, C(0x2C3E4E))
    }

    /// A crystal spire: lit face on the left, shaded face on the right, darkening toward its foot, coming to a point.
    static func kandorSpire(_ c: PixelCanvas, _ x: Int, _ b: Int, _ w: Int, _ h: Int, haze: Double) {
        let sky = C(0xE8A070)
        let lit = lerp(C(0xDCF6FA), sky, haze), shade = lerp(C(0x7AB4CC), sky, haze), foot = lerp(C(0x22405A), sky, haze * 0.6)
        let point = max(2, w)
        for r in 0..<h {
            let k = min(1, Double(r) / Double(h) * 1.6)
            let wk = r < h - point ? w : max(1, w * (h - r) / point)
            let x0 = x + (w - wk) / 2
            c.rect(x0, b - 1 - r, wk / 2, 1, lerp(foot, lit, k))
            c.rect(x0 + wk / 2, b - 1 - r, wk - wk / 2, 1, lerp(foot, shade, k))
        }
        if h > 20 { c.rect(x + w / 4, b - h * 2 / 3, max(1, w / 6), h / 3, lit.alpha(0.6)) }
    }

    /// Brainiac's face beyond the glass: green, bald, with the three nodes on his crown and red eyes.
    static func kandorBrainiac(_ c: PixelCanvas, _ g: Int) {
        let f = kandorFace(c, g), s = unit(g)
        let skin = C(0x4E9A44), dark = C(0x2E6A2A), lit = C(0x7AC060)
        c.ellipse(f.x, f.y + f.ry * 2, f.rx * 17 / 10, f.ry * 8 / 10, C(0x4A2058))          // the shoulders
        c.ellipse(f.x, f.y + f.ry * 13 / 10, f.rx * 9 / 10, f.ry / 3, C(0x6A2A7A))          // the collar
        c.rect(f.x - f.rx / 2, f.y + f.ry * 7 / 10, f.rx, f.ry * 6 / 10, C(0x3A6A34))      // the neck
        for side in [-1, 1] { c.ellipse(f.x + side * f.rx, f.y + f.ry / 8, f.rx / 9, f.ry / 5, dark) }
        c.ellipse(f.x, f.y, f.rx, f.ry, skin)
        c.ellipse(f.x + f.rx / 4, f.y + f.ry / 10, f.rx * 3 / 4, f.ry * 85 / 100, C(0x2E6A2A, 0.35))
        c.ellipse(f.x - f.rx / 3, f.y - f.ry / 2, f.rx / 4, f.ry / 7, lit.alpha(0.6))
        let nodes: [(Int, Int)] = [(-f.rx / 2, -f.ry * 62 / 100), (0, -f.ry * 82 / 100), (f.rx / 2, -f.ry * 62 / 100)]
        for (dx, dy) in nodes {
            c.circle(f.x + dx, f.y + dy, f.rx / 11, C(0x5A2A80)); c.circle(f.x + dx, f.y + dy, f.rx / 16, C(0xB88AE0))
            c.circle(f.x + dx, f.y + dy, max(1, f.rx / 40), C(0xF0E0FF))
        }
        c.rect(f.x - f.rx * 6 / 10, f.y - f.ry / 7, f.rx * 12 / 10, 3 * s, dark)
        for e in kandorEyes(c, g) {
            c.ellipse(e.x, e.y, e.rx + 2 * s, e.ry + 2 * s, C(0x1E3A18))
            c.ellipse(e.x, e.y, e.rx, e.ry, C(0x8A1A2A)); c.ellipse(e.x, e.y, e.rx / 2, e.ry * 2 / 3, C(0xE04A5A))
        }
        scenes4Line(c, f.x + 2 * s, f.y + f.ry / 10, f.x + f.rx / 10, f.y + f.ry * 35 / 100, dark, t: 2 * s)
        c.rect(f.x - f.rx / 10, f.y + f.ry * 38 / 100, f.rx / 5, 2 * s, dark)
        c.rect(f.x - f.rx / 4, f.y + f.ry * 6 / 10, f.rx / 2, 2 * s, C(0x1E4A1A))
        c.rect(f.x - f.rx / 4 - 2 * s, f.y + f.ry * 6 / 10 + 2 * s, 2 * s, 2 * s, C(0x1E4A1A))
        c.rect(f.x + f.rx / 4, f.y + f.ry * 6 / 10 + 2 * s, 2 * s, 2 * s, C(0x1E4A1A))
    }

    static func kandorEyes(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, rx: Int, ry: Int)] {
        let f = kandorFace(c, g)
        return [-1, 1].map { (side: Int) in (f.x + side * f.rx * 32 / 100, f.y, f.rx / 7, f.ry / 12) }
    }

    /// Little craft zipping between the spires, glints running up the crystal and, full screen, Brainiac's eyes
    /// burning brighter, darting about and blinking, and the nodes on his head flickering.
    static func kandorLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), b = kandorBell(c, g)
        let top = max(0, b.y - b.ry)
        for i in 0..<(tall ? 9 : 6) {
            let y = top + Int(Double(g - top) * (tall ? 0.35 + noise(i + 4750) * 0.5 : 0.15 + noise(i + 4750) * 0.6))
            let half = kandorHalf(b, y) - 6 * s
            guard half > 0 else { continue }
            var x = scenes4Slide(t, speed: (14 + noise(i + 4751) * 18) * Double(s), phase: noise(i + 4752), w: half * 2, margin: 0)
            let left = i % 2 == 0
            if left { x = half * 2 - x }
            x += b.x - half
            c.rect(x, y, 3 * s, s, C(0xFFF4E0)); c.px(x + (left ? 3 * s : -1), y, C(0x8AE8FF))
            c.rect(left ? x + 3 * s : x - 6 * s, y, 6 * s, s, C(0xFFE0B0, 0.25))
        }
        let towers = kandorTowers(c, g)
        for i in 0..<4 where !towers.isEmpty {
            let tw = towers[Int(noise(Int(t * 0.8) * 5 + i) * Double(towers.count)) % towers.count]
            let k = scenes4Phase(t, 1.25, offset: Double(i) * 0.3)
            let y = g - 2 * s - Int(Double(tw.h) * k)
            c.rect(tw.x + tw.w / 4, y, max(1, tw.w / 4), 2 * s, C(0xFFFFFF, 0.5 * (1 - k)))
        }
        guard tall else { return }
        let f = kandorFace(c, g), pulse = 0.5 + 0.5 * sin(t * 1.4)
        let blink = scenes4Phase(t, 6, offset: 1) > 0.96
        let look = Int(sin(t * 0.35) * Double(f.rx) / 18)
        for e in kandorEyes(c, g) {
            if blink {
                c.ellipse(e.x, e.y, e.rx + 2 * s, e.ry + 2 * s, C(0x3E8A36)); c.rect(e.x - e.rx, e.y, e.rx * 2, s, C(0x1E3A18))
            } else {
                c.circle(e.x + look, e.y, e.rx + 4 * s, C(0xFF3A4A, 0.08 + 0.1 * pulse))
                c.ellipse(e.x + look, e.y, e.rx / 2, e.ry * 2 / 3, C(0xFF8A8A, 0.5 + 0.4 * pulse))
                c.rect(e.x + look - s, e.y - s, 2 * s, 2 * s, C(0xFFE0E0))
            }
        }
        let nodes: [(Int, Int)] = [(-f.rx / 2, -f.ry * 62 / 100), (0, -f.ry * 82 / 100), (f.rx / 2, -f.ry * 62 / 100)]
        for (i, n) in nodes.enumerated() where scenes4Phase(t, 1.8, offset: Double(i) * 0.6) < 0.3 {
            c.circle(f.x + n.0, f.y + n.1, f.rx / 16, C(0xF0D8FF, 0.8))
        }
    }
}
