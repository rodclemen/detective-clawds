import Foundation

let scenes7: [Location: Place] = [
    .korugar: Place(name: "Korugar", panel: 0x1E1A0C, still: Scenes.korugar, moving: Scenes.korugarLife),
    .warworld: Place(name: "Warworld", panel: 0x1E0E0C, still: Scenes.warworld, moving: Scenes.warworldLife),
    .bludhaven: Place(name: "Blüdhaven", panel: 0x12141C, still: Scenes.bludhaven, moving: Scenes.bludhavenLife),
    .jsaHQ: Place(name: "JSA Headquarters", panel: 0x1E140E, still: Scenes.jsaHQ, moving: Scenes.jsaLife),
    .fawcettCity: Place(name: "Fawcett City", panel: 0x16202E, still: Scenes.fawcettCity, moving: Scenes.fawcettLife),
    .starLabs: Place(name: "S.T.A.R. Labs", panel: 0x111820, still: Scenes.starLabs, moving: Scenes.starLabsLife),
    .hallOfDoom: Place(name: "Hall of Doom", panel: 0x0E1410, still: Scenes.hallOfDoom, moving: Scenes.hallOfDoomLife),
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// String art drawn with every character `s` pixels square.
    static func scenes7Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes7Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// A straight line of `s`-pixel dots (use opaque colours, the dots overlap).
    static func scenes7Line(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ col: Px, s: Int = 1) {
        let n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in 0...n { c.rect(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, s, s, col) }
    }

    /// A blade of a spire: a point at `top` widening to `width` at `base`, its tip leaning `lean` pixels over.
    static func scenes7Spire(_ c: PixelCanvas, x: Int, base: Int, top: Int, width: Int, lean: Int, _ col: Px, edge: Px) {
        let hgt = base - top
        guard hgt > 0 else { return }
        for k in 0..<hgt {
            let f = Double(k) / Double(hgt)
            let half = Int(f * Double(width) / 2), cx = x + Int((1 - f) * Double(lean))
            c.rect(cx - half, top + k, half * 2 + 1, 1, col)
            c.px(cx + half, top + k, edge)
        }
    }

    /// A tiny blocky alphabet for the signs.
    static let scenes7Glyphs: [Character: [String]] = [
        "A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
        "D": ["##.", "#.#", "#.#", "#.#", "##."], "E": ["###", "#..", "##.", "#..", "###"],
        "H": ["#.#", "#.#", "###", "#.#", "#.#"], "I": ["###", ".#.", ".#.", ".#.", "###"],
        "J": ["..#", "..#", "..#", "#.#", ".#."], "L": ["#..", "#..", "#..", "#..", "###"],
        "N": ["#..#", "##.#", "#.##", "#..#", "#..#"], "O": [".#.", "#.#", "#.#", "#.#", ".#."],
        "P": ["##.", "#.#", "##.", "#..", "#.."], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
        "S": [".##", "#..", ".#.", "..#", "##."], "T": ["###", ".#.", ".#.", ".#.", ".#."],
        "U": ["#.#", "#.#", "#.#", "#.#", "###"], "W": ["#...#", "#...#", "#.#.#", "#.#.#", ".#.#."],
        "Y": ["#.#", "#.#", ".#.", ".#.", ".#."], "Z": ["###", "..#", ".#.", "#..", "###"],
        "K": ["#.#", "#.#", "##.", "#.#", "#.#"], ".": [".", ".", ".", ".", "#"],
    ]

    static func scenes7TextWidth(_ text: String, s: Int) -> Int {
        var n = 0
        for ch in text { n += (scenes7Glyphs[ch]?.first?.count ?? 2) + 1 }
        return max(0, n - 1) * s
    }

    static func scenes7Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, s: Int) {
        var cx = x
        for ch in text {
            guard let rows = scenes7Glyphs[ch] else { cx += 3 * s; continue }
            for (r, row) in rows.enumerated() {
                for (k, p) in row.enumerated() where p == "#" { c.rect(cx + k * s, y + r * s, s, s, col) }
            }
            cx += (rows[0].count + 1) * s
        }
    }
}

// MARK: - Korugar

extension Scenes {
    /// Sinestro's citadel: its centre column, half-width at the foot, top row and the row its emblem burns on.
    static func korugarCitadel(_ c: PixelCanvas, _ g: Int) -> (x: Int, hw: Int, top: Int, emblem: Int) {
        let s = unit(g), top = isTall(c) ? g / 8 : 1
        return (Int(Double(c.w) * 0.66), (isTall(c) ? 16 : 10) * s, top, top + (g - top) * 2 / 7)
    }

    /// The Sinestro Corps' sigil in a ring.
    static let korugarSigil: [String] = [
        "...yyyyy...",
        ".yy.....yy.",
        ".y.y...y.y.",
        "y..yy.yy..y",
        "y..yyyyy..y",
        "y...yyy...y",
        "y...yyy...y",
        "y....y....y",
        ".y...y...y.",
        ".yy.....yy.",
        "...yyyyy...",
    ]

    /// Korugar, Sinestro's homeworld: a sickly yellow sky with a swollen sun, a forest of angular alien spires leaning
    /// out of the haze, Sinestro's citadel rising over them with the Corps' sigil burning on its face, and the crew on
    /// a dark paved plaza behind a low wall with lit slits.
    static func korugar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x2A260A), C(0xD8B838), bands: tall ? 10 : 7)
        let sx = Int(Double(c.w) * 0.17), sy = tall ? g / 4 : g / 3, sr = max(5, g / 16)
        for k in 0..<4 { c.circle(sx, sy, sr + (4 - k) * 3 * s, C(0xFFF07A, 0.08)) }
        c.circle(sx, sy, sr, C(0xFFF4B0)); c.circle(sx - sr / 4, sy - sr / 4, max(1, sr / 2), C(0xFFFCE0))
        if tall {
            // a pale ringed moon and streaks of haze high up
            let mx = Int(Double(c.w) * 0.86), my = g / 7, mr = max(6, g / 22)
            c.ellipse(mx, my, mr * 2, max(1, mr / 3), C(0xF0E6A8, 0.35))
            c.circle(mx, my, mr, C(0xB0A058)); c.circle(mx - mr / 4, my - mr / 4, mr * 2 / 3, C(0xD0C47E))
            c.rect(mx - mr * 2, my + max(1, mr / 3) - s, mr * 4, s, C(0xF0E6A8, 0.5))
            for i in 0..<7 {
                wisp(c, Int(noise(i * 5 + 700) * Double(c.w)), g / 10 + Int(noise(i * 5 + 701) * Double(g / 3)),
                     (30 + Int(noise(i * 5 + 702) * 50)) * s, C(0xF0D870, 0.3), s: s)
            }
        }
        // the far spires, hazy in the yellow air
        var x = -6 * s, i = 0
        while x < c.w + 8 * s {
            let hgt = Int(Double(g) * (0.26 + noise(i * 7 + 11) * 0.38))
            let wid = max(6 * s, hgt / 8 + 3 * s + Int(noise(i * 7 + 12) * Double(hgt / 12))), lean = Int((noise(i * 7 + 13) - 0.5) * 10) * s
            scenes7Spire(c, x: x, base: g, top: g - hgt, width: wid, lean: lean, C(0xA88C34), edge: C(0xD8BC5A))
            x += (8 + Int(noise(i * 7 + 14) * 14)) * s; i += 1
        }
        for k in 0..<3 { c.rect(0, g - (k + 1) * 6 * s, c.w, 6 * s, C(0xD8B838, 0.12)) }
        // the low city: angular halls with slanted roofs, darker, so the crew stands out against them
        x = -8 * s; i = 0
        let hallH = tall ? g / 6 : g / 4
        while x < c.w {
            let bw = (16 + Int(noise(i * 5 + 31) * 20)) * s, bh = hallH / 2 + Int(noise(i * 5 + 32) * Double(hallH / 2))
            let slant = noise(i * 5 + 33) > 0.5 ? 1 : -1, roof = bw / 3
            let col = C(0x6A5620)
            for k in 0..<bw {
                let rise = slant > 0 ? k * roof / bw : (bw - k) * roof / bw
                c.rect(x + k, g - bh - rise, 1, bh + rise, col)
                c.px(x + k, g - bh - rise, C(0xC8A848))
            }
            for wy in stride(from: g - bh + 3 * s, to: g - 2 * s, by: 4 * s) {
                for wx in stride(from: x + 3 * s, to: x + bw - 3 * s, by: 5 * s) where noise(wx * 3 + wy) > 0.55 {
                    c.rect(wx, wy, 2 * s, s, C(0xFFE070, 0.7))
                }
            }
            x += bw + Int(noise(i * 5 + 34) * 4) * s; i += 1
        }
        korugarCitadelDraw(c, g)
        // nearer spires, dark against the glow, the Corps' light in their seams
        let cit = korugarCitadel(c, g), body = C(0x3A3012)
        x = -4 * s; i = 0
        while x < c.w + 8 * s {
            let hgt = Int(Double(g) * (0.2 + noise(i * 7 + 51) * (tall ? 0.42 : 0.5)))
            let wid = max(8 * s, hgt / 7 + 4 * s + Int(noise(i * 7 + 52) * Double(hgt / 12))), lean = Int((noise(i * 7 + 53) - 0.5) * 12) * s
            let top = g - hgt
            if abs(x - cit.x) > cit.hw + 26 * s && abs(x - sx) > 6 * s {
                scenes7Spire(c, x: x, base: g, top: top, width: wid, lean: lean, body, edge: C(0xE8C040))
                for f in 0..<2 where noise(i * 7 + 54 + f) > 0.35 {           // fins jutting out and up
                    let fy = top + hgt * (35 + f * 25) / 100, side = f == 0 ? -1 : 1
                    let kf = Double(fy - top) / Double(hgt)
                    let ex = x + Int((1 - kf) * Double(lean)) + side * Int(kf * Double(wid) / 2)
                    let len = (3 + Int(noise(i * 7 + 56 + f) * 4)) * s
                    for j in 0..<len { c.rect(ex + side * j, fy - j, 1, max(1, (len - j) / 2), body) }
                }
                if noise(i * 7 + 58) > 0.5 {                                  // a ring of platform round the blade
                    let ly = top + hgt * 3 / 5, lx = x + Int(0.4 * Double(lean)), lh = wid * 3 / 10 + 3 * s
                    c.rect(lx - lh, ly, lh * 2, 2 * s, body); c.rect(lx - lh, ly, lh * 2, max(1, s / 2), C(0xE8C040))
                    c.rect(lx - lh + s, ly + 2 * s, lh * 2 - 2 * s, s, C(0xFFD840, 0.5))
                }
                for k in 0..<3 where noise(i * 7 + 60 + k) > 0.4 {             // lit slits
                    let ky = g - hgt / 4 - k * hgt / 5
                    let kx = x + Int((1 - Double(ky - top) / Double(hgt)) * Double(lean))
                    c.rect(kx, ky, max(1, s), 2 * s, C(0xFFE060, 0.85))
                }
            }
            x += (14 + Int(noise(i * 7 + 55) * 20)) * s; i += 1
        }
        // a low wall round the plaza
        let wall = 5 * s
        c.rect(0, g - wall, c.w, wall, C(0x2A2410)); c.rect(0, g - wall, c.w, s, C(0x8A7020))
        for xx in stride(from: 4 * s, to: c.w, by: 16 * s) { c.rect(xx, g - wall + 2 * s, 5 * s, s, C(0xFFD840, 0.55)) }
        c.ground(g, C(0x2A2412), edge: C(0xD0A830), speck: C(0x3A3218), seed: 71)
        for xx in stride(from: 0, to: c.w + c.h, by: 24 * s) {                   // angular paving
            for y in (g + 1)..<c.h {
                let d = (y - g) * 2
                c.px(xx - d, y, C(0x463A18)); c.px(xx + 12 * s + d - (c.h - g) * 2, y, C(0x463A18))
            }
        }
        c.rect(0, g + (c.h - g) / 2, c.w, max(1, s), C(0xE8C040, 0.25))
    }

    /// Sinestro's citadel: a great blade flanked by four leaning ones, ledges down its shaft and the sigil on its face.
    static func korugarCitadelDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = korugarCitadel(c, g), m = isTall(c) ? 2 * s : s
        for k in 0..<6 { c.circle(f.x, f.emblem, (8 + k * 7) * m, C(0xFFE860, 0.05)) }
        let body = C(0x2E2610), lit = C(0xFFD840), hgt = g - f.top
        for side in [-1, 1] {
            scenes7Spire(c, x: f.x + side * f.hw * 18 / 10, base: g, top: f.top + hgt * 3 / 5, width: f.hw, lean: side * 10 * m, body, edge: lit)
            scenes7Spire(c, x: f.x + side * f.hw, base: g, top: f.top + hgt * 2 / 5, width: f.hw * 6 / 5, lean: side * 8 * m, body, edge: lit)
        }
        scenes7Spire(c, x: f.x, base: g, top: f.top, width: f.hw * 2, lean: 0, body, edge: lit)
        for y in stride(from: f.emblem + 9 * m, to: g - 6 * s, by: 7 * m) {
            let half = Int(Double(y - f.top) / Double(hgt) * Double(f.hw))
            c.rect(f.x - half - 2 * s, y, half * 2 + 4 * s + 1, s, C(0x4A3C16))
            c.rect(f.x - half + s, y + s, half * 2 - s, max(1, s), C(0xFFD840, 0.35))
        }
        c.rect(f.x, f.emblem + 8 * m, max(1, s), g - f.emblem - 8 * m, C(0xFFE060, 0.45))
        c.circle(f.x, f.emblem, 7 * m, C(0x1E1A08)); c.circle(f.x, f.emblem, 6 * m, C(0x2E2610))
        scenes7Stamp(c, f.x - 5 * m, f.emblem - 5 * m, korugarSigil, ["y": C(0xF0C838)], s: m)
    }

    /// The sigil pulsing on the citadel and Sinestro Corps members streaking across the sky in yellow light.
    static func korugarLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = korugarCitadel(c, g), tall = isTall(c), m = tall ? 2 * s : s
        let p = 0.5 + 0.5 * sin(t * 2.2)
        c.circle(f.x, f.emblem, (9 + Int(p * 3)) * m, C(0xFFE860, 0.08 + p * 0.08))
        scenes7Stamp(c, f.x - 5 * m, f.emblem - 5 * m, korugarSigil, ["y": C(0xFFFCC0, 0.3 + p * 0.6)], s: m)
        for i in 0..<(tall ? 7 : 4) {
            let period = 4.0 + noise(i * 5 + 1) * 5
            let ph = scenes7Phase(t, period, offset: noise(i * 5 + 2) * period)
            let dir: Double = noise(i * 5 + 3) > 0.5 ? 1 : -1
            let span = Double(c.w + 120 * s), u = Double(s)
            let x = dir > 0 ? -60.0 * u + ph * span : Double(c.w) + 60 * u - ph * span
            let climb = (noise(i * 5 + 5) - 0.5) * 0.25
            let y = Double(g) * (0.08 + noise(i * 5 + 4) * 0.42) + (ph - 0.5) * span * climb
            let len = (tall ? 30.0 : 20.0) * u
            c.glowLine(x - dir * len, y - climb * dir * len * dir, x, y, core: C(0xFFF4A0), glow: C(0xFFC820),
                       coreR: 0.5 * u, glowR: 1.8 * u, strength: 0.75)
            c.circle(Int(x), Int(y), s, C(0xFFFFE0))
            c.circle(Int(x), Int(y), 3 * s, C(0xFFE040, 0.25))
        }
    }
}

// MARK: - Warworld

extension Scenes {
    /// The stands: their top row, the arena wall's top row and the height of one tier.
    static func warworldStands(_ c: PixelCanvas, _ g: Int) -> (top: Int, wall: Int, tier: Int) {
        let s = unit(g)
        return (isTall(c) ? g * 3 / 5 : 17 * s, g - 20 * s, 4 * s)
    }

    /// Where the banners hang on the arena wall (clear of Mongul's box in the middle).
    static func warworldBanners(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let s = unit(g)
        return stride(from: 34 * s, to: c.w, by: 64 * s).filter { abs($0 - c.w / 2) > 30 * s }
    }

    /// Warworld, Mongul's planet-sized gladiator arena under a blood-red sky: the colosseum's arched crown, tier upon
    /// tier of roaring alien crowd, Mongul's gilded box over the arena wall, crimson banners with his gold sigil, iron
    /// gates and braziers along the wall, and the crew on the sand. On tall screens the planet's war machinery bristles
    /// on the horizon behind the crown, under a dim red sun.
    static func warworld(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), st = warworldStands(c, g)
        c.gradient(0, st.top, C(0x1A0606), C(0xB8341A), bands: tall ? 9 : 4)
        if tall {
            warworldHigh(c, g)
        } else {                                                      // the planet's towers just showing over the rim
            var x = 0, i = 0
            while x < c.w {
                let tw = (4 + Int(noise(i * 9 + 40) * 8)) * s, th = (2 + Int(noise(i * 9 + 41) * 8)) * s
                c.rect(x, st.top - 7 * s - th, tw, th, C(0x3A100C))
                if noise(i * 9 + 42) > 0.6 { c.rect(x + tw / 2, st.top - 9 * s - th, max(1, s), 3 * s, C(0x3A100C)) }
                x += tw + Int(noise(i * 9 + 44) * 10) * s; i += 1
            }
        }
        // the colosseum's crown: arches and spikes over the top row of seats
        let crownH = (tall ? 22 : 7) * s, cy = st.top - crownH
        c.rect(0, cy, c.w, crownH, C(0x3A1812))
        c.rect(0, cy, c.w, s, C(0x7A3A26))
        if tall {                                                   // two storeys of round arches
            for (k, sy) in [cy + 2 * s, cy + 12 * s].enumerated() {
                c.rect(0, sy + 9 * s, c.w, s, C(0x7A3A26))
                for x in stride(from: (k % 2) * 6 * s, to: c.w, by: 12 * s) {
                    c.rect(x + 3 * s, sy + 3 * s, 7 * s, 6 * s, k == 0 ? C(0xA8381E) : C(0x6A2014))
                    c.circle(x + 6 * s, sy + 3 * s, 3 * s, k == 0 ? C(0xA8381E) : C(0x6A2014))
                    c.rect(x + 2 * s, sy + 2 * s, s, 7 * s, C(0x5A2A1C))
                }
            }
        } else {
            for x in stride(from: 0, to: c.w, by: 8 * s) { c.rect(x + 2 * s, cy + 2 * s, 4 * s, crownH - 3 * s, C(0xC84A24, 0.55)) }
        }
        for x in stride(from: 4 * s, to: c.w, by: 24 * s) { scenes7Spire(c, x: x, base: cy, top: cy - (tall ? 10 : 4) * s, width: 4 * s, lean: 0, C(0x2A100C), edge: C(0x5A2A1C)) }
        // the stands
        c.rect(0, st.top, c.w, st.wall - st.top, C(0x2A120E))
        for (j, y) in stride(from: st.top, to: st.wall, by: st.tier).enumerated() {
            c.rect(0, y + st.tier - s, c.w, s, lerp(C(0x5A2C20), C(0x3A1A14), Double(j) / 12))
            if warworldPromenade(c, j) {                       // a promenade of arches between the decks
                c.rect(0, y - s, c.w, st.tier + s, C(0x4A2016)); c.rect(0, y - s, c.w, s, C(0x8A4A2E))
                for x in stride(from: 2 * s, to: c.w, by: 8 * s) { c.rect(x, y + s, 5 * s, st.tier - s, C(0x140806)); c.px(x + 2 * s, y + 2 * s, C(0xFF8A3A, 0.6)) }
            }
        }
        for x in stride(from: 45 * s, to: c.w, by: 90 * s) {          // the aisles
            c.rect(x - 2 * s, st.top, 4 * s, st.wall - st.top, C(0x4A2418))
            for y in stride(from: st.top, to: st.wall, by: 2 * s) { c.rect(x - 2 * s, y, 4 * s, max(1, s / 2), C(0x6A3424)) }
        }
        // the wall round the arena, gates and braziers
        let wh = g - st.wall
        c.rect(0, st.wall, c.w, wh, C(0x22100C))
        for (j, y) in stride(from: st.wall + 3 * s, to: g, by: 4 * s).enumerated() {
            c.rect(0, y, c.w, max(1, s / 2), C(0x180A08))
            for x in stride(from: (j % 2) * 6 * s, to: c.w, by: 12 * s) { c.rect(x, y, max(1, s / 2), 4 * s, C(0x180A08)) }
        }
        c.rect(0, st.wall, c.w, 2 * s, C(0x5A2C1E)); c.rect(0, st.wall, c.w, s, C(0x8A4A2E))
        let banners = warworldBanners(c, g)
        for b in banners {
            let gx = b + 32 * s
            guard gx < c.w + 10 * s, abs(gx - c.w / 2) > 30 * s else { continue }
            c.rect(gx - 6 * s, st.wall + 6 * s, 12 * s, wh - 6 * s, C(0x0A0404))
            c.ellipse(gx, st.wall + 6 * s, 6 * s, 3 * s, C(0x0A0404))
            for x in stride(from: gx - 5 * s, to: gx + 6 * s, by: 3 * s) { c.rect(x, st.wall + 5 * s, s, wh - 5 * s, C(0x3A2A24)) }
            c.rect(gx - 6 * s, st.wall + 10 * s, 12 * s, s, C(0x3A2A24))
            // the brazier over the gate
            c.rect(gx - s, st.wall - 4 * s, 2 * s, 4 * s, C(0x3A2A24))
            c.rect(gx - 3 * s, st.wall - 5 * s, 6 * s, 2 * s, C(0x5A4030))
        }
        warworldBox(c, g)
        c.ground(g, C(0x5E3620), edge: C(0x9A5A34), speck: C(0x4A2A18), seed: 81)
        for i in 0..<(c.w / 40) {
            c.ellipse(Int(noise(i * 3 + 900) * Double(c.w)), g + 2 * s + Int(noise(i * 3 + 901) * Double(c.h - g - 3 * s)),
                      (3 + Int(noise(i * 3 + 902) * 5)) * s, s, C(0x3A1C10, 0.6))
        }
    }

    /// Mongul's box over the middle of the wall: a gilded balcony under a purple canopy and his great throne.
    static func warworldBox(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), st = warworldStands(c, g), bx = c.w / 2, top = st.wall - 14 * s
        c.rect(bx - 18 * s, top, 36 * s, 14 * s, C(0x1A0A0A))
        c.rect(bx - 20 * s, top - 3 * s, 40 * s, 3 * s, C(0x4A1E5A)); c.rect(bx - 20 * s, top - 3 * s, 40 * s, s, C(0x8A5AA0))
        for x in stride(from: bx - 20 * s, to: bx + 20 * s, by: 4 * s) { c.rect(x, top, 2 * s, s, C(0x4A1E5A)) }
        c.rect(bx - 6 * s, top + 2 * s, 12 * s, 12 * s, C(0x6A4A14)); c.rect(bx - 4 * s, top + 4 * s, 8 * s, 10 * s, C(0x3A1A3E))
        c.rect(bx - 6 * s, top + 2 * s, 12 * s, s, C(0xE8B840))
        c.rect(bx - 8 * s, top + 8 * s, 2 * s, 6 * s, C(0xC89A30)); c.rect(bx + 6 * s, top + 8 * s, 2 * s, 6 * s, C(0xC89A30))
        c.rect(bx - 20 * s, st.wall, 40 * s, 3 * s, C(0x8A6A20)); c.rect(bx - 20 * s, st.wall, 40 * s, s, C(0xF0C850))
        for x in stride(from: bx - 18 * s, to: bx + 18 * s, by: 4 * s) { c.rect(x, st.wall + s, 2 * s, 2 * s, C(0x4A3010)) }
        c.circle(bx, st.wall + 7 * s, 4 * s, C(0x8A6A20)); c.circle(bx, st.wall + 7 * s, 3 * s, C(0x3A1A3E))
        c.rect(bx - s, st.wall + 4 * s, 2 * s, 7 * s, C(0xF0C850))
    }

    /// The tall screens' sky: the planet's war machinery bristling on the horizon, smoke and a dim red sun.
    static func warworldHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), st = warworldStands(c, g), hz = st.top - 22 * s
        c.stars(0, hz / 3, density: 120, seed: 81)
        let sx = Int(Double(c.w) * 0.22), sy = hz / 3, sr = max(10, g / 10)
        for k in 0..<4 { c.circle(sx, sy, sr + (4 - k) * 4 * s, C(0xFF6A3A, 0.06)) }
        c.circle(sx, sy, sr, C(0xE8583A)); c.circle(sx - sr / 5, sy - sr / 5, sr * 2 / 3, C(0xF8805A))
        for k in 0..<3 { c.rect(sx - sr - 6 * s, sy + k * 5 * s - 3 * s, sr * 2 + 12 * s, 2 * s, C(0x2A0A08, 0.5)) }
        // towers, domes and gun barrels of the planet
        var x = 0, i = 0
        while x < c.w {
            let tw = (8 + Int(noise(i * 9 + 40) * 14)) * s, th = (16 + Int(noise(i * 9 + 41) * Double(hz / 2))) * s / s
            let col = C(0x2A0C0A)
            if noise(i * 9 + 42) > 0.7 {
                c.ellipse(x + tw / 2, hz, tw, tw * 2 / 3, col)
            } else {
                c.rect(x, hz - th, tw, th, col)
                c.rect(x + tw / 3, hz - th - 8 * s, tw / 3, 8 * s, col)
                if noise(i * 9 + 43) > 0.5 { c.rect(x + tw / 2, hz - th - 6 * s, tw * 2, 2 * s, col) }
                for y in stride(from: hz - th + 3 * s, to: hz - 2 * s, by: 5 * s) where noise(y + i * 13) > 0.6 {
                    c.rect(x + 2 * s, y, tw - 4 * s, s, C(0xFF7A2A, 0.6))
                }
            }
            c.rect(x, hz - th, max(1, s), th, C(0x5A1E14))
            x += tw + Int(noise(i * 9 + 44) * 6) * s; i += 1
        }
        for i in 0..<5 {                                            // smoke from the forges
            let px = Int(noise(i * 7 + 60) * Double(c.w))
            for k in 0..<10 {
                c.ellipse(px + k * 4 * s, hz - 30 * s - k * 8 * s, (6 + k * 2) * s, (3 + k) * s, C(0x1A0606, 0.18))
            }
        }
    }

    /// Whether tier `j` of the stands is a promenade rather than seats (tall screens only).
    static func warworldPromenade(_ c: PixelCanvas, _ j: Int) -> Bool { isTall(c) && j % 8 == 7 }

    /// The crowd on its feet, banners stirring on the wall, the braziers burning and, on tall screens, searchlights
    /// sweeping the sky.
    static func warworldLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), st = warworldStands(c, g), bx = c.w / 2
        let skins: [Px] = [C(0xB87A5A), C(0x6A9A5A), C(0x8A6AB0), C(0xC8B060), C(0x5A8AB8), C(0xA85050), C(0xD0C8B8), C(0x4AA890), C(0x9A9AA0)]
        if isTall(c) {
            for i in 0..<3 {
                let base = Int(Double(c.w) * (0.2 + Double(i) * 0.3)), ang = sin(t * 0.4 + Double(i) * 2.1) * 0.6
                let top = st.top - 22 * s
                for y in stride(from: 0, to: top, by: 2 * s) {
                    let d = Double(top - y), x = base + Int(d * ang), half = Int(d * 0.06) + s
                    c.rect(x - half, y, half * 2, 2 * s, C(0xFFD8A0, 0.07))
                }
            }
        }
        for (j, y) in stride(from: st.top, to: st.wall, by: st.tier).enumerated() {
            for (i, x) in stride(from: (j % 2) * s, to: c.w, by: 3 * s).enumerated() {
                if (x + 45 * s) % (90 * s) < 5 * s { continue }
                if abs(x - bx) < 21 * s && y + st.tier > st.wall - 17 * s { continue }
                if warworldPromenade(c, j) { break }
                let n = noise(i * 13 + j * 101 + 5)
                guard n > 0.1 else { continue }
                let up = sin(t * (4 + n * 4) + n * 20) > 0.6 ? s : 0
                let col = lerp(skins[Int(n * 97) % skins.count], C(0x200C0A), 0.42 + Double(j) * 0.01)
                c.rect(x, y + st.tier - 3 * s - up, 2 * s, s, col)
                c.rect(x, y + st.tier - 2 * s - up, 2 * s, s + up, col.alpha(0.55))
                if up > 0, n > 0.8 { c.rect(x + (n > 0.9 ? 2 * s : -s), y + st.tier - 5 * s, s, 2 * s, col) }
            }
        }
        let len = g - st.wall - 5 * s
        for b in warworldBanners(c, g) {
            let seed = Double(b) * 0.13
            for k in 0..<len {
                let sway = Int(sin(t * 1.7 + Double(k) * 0.22 + seed) * Double(k) / Double(len) * 1.6 * Double(s))
                var w0 = 10 * s, x0 = b - 5 * s + sway
                if k > len - 4 * s { let cut = (k - (len - 4 * s)); w0 -= 2 * cut; x0 += cut }     // the swallowtail point
                guard w0 > 0 else { continue }
                c.rect(x0, st.wall + 2 * s + k, w0, 1, C(0x7A1410))
                c.px(x0, st.wall + 2 * s + k, C(0xE8B840)); c.px(x0 + w0 - 1, st.wall + 2 * s + k, C(0xE8B840))
            }
            let my = st.wall + 2 * s + len / 3
            let sway = Int(sin(t * 1.7 + Double(len / 3) * 0.22 + seed) * 0.5 * Double(s))
            c.circle(b + sway, my, 2 * s, C(0xE8B840)); c.rect(b + sway, my - 3 * s, max(1, s), 7 * s, C(0xE8B840))
            c.rect(b - 6 * s, st.wall + s, 12 * s, s, C(0x3A2A24))
        }
        for b in warworldBanners(c, g) {
            let gx = b + 32 * s
            guard gx < c.w + 10 * s, abs(gx - c.w / 2) > 30 * s else { continue }
            let fy = st.wall - 5 * s
            c.circle(gx, fy - 2 * s, 6 * s, C(0xFF8A2A, 0.10 + 0.05 * sin(t * 9 + Double(gx))))
            for k in 0..<3 {
                let hgt = (2 + Int(noise(Int(t * 10) * 7 + gx + k) * 4)) * s
                c.rect(gx - 2 * s + k * 2 * s, fy - hgt, max(1, s), hgt, k == 1 ? C(0xFFD860) : C(0xFF6A20))
            }
        }
    }
}

// MARK: - Blüdhaven

extension Scenes {
    /// The far quay's row: where the harbour water starts.
    static func bludhavenWater(_ g: Int) -> Int { g - 16 * unit(g) }

    /// One skyline building across the harbour.
    struct BludhavenBlock { let x, y, w, h: Int; let near: Bool }

    static func bludhavenBlocks(_ c: PixelCanvas, _ g: Int) -> [BludhavenBlock] {
        let s = unit(g), hz = bludhavenWater(g), tall = isTall(c)
        var out: [BludhavenBlock] = []
        let specs: [(lo: Double, hi: Double, seed: Int)] = tall ? [(0.12, 0.36, 5), (0.1, 0.28, 11)] : [(0.35, 0.75, 5), (0.3, 0.5, 11)]
        for (layer, spec) in specs.enumerated() {
            var x = -4 * s, i = 0
            while x < c.w {
                let bw = (8 + Int(noise(i * 7 + spec.seed * 131) * 14)) * s
                let bh = Int(Double(hz) * (spec.lo + noise(i * 7 + 1 + spec.seed * 131) * (spec.hi - spec.lo)))
                out.append(BludhavenBlock(x: x, y: hz - bh, w: bw, h: bh, near: layer == 1))
                x += bw + (layer == 0 ? 0 : Int(noise(i * 7 + 2 + spec.seed * 131) * 4) * s)
                i += 1
            }
        }
        return out
    }

    /// The neon signs: centre, top row, words and colour.
    static func bludhavenSigns(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, text: String, col: Px)] {
        let s = unit(g), hz = bludhavenWater(g), y = hz - (isTall(c) ? 30 : 15) * s
        return [(Int(Double(c.w) * 0.43), y, "HOTEL", C(0xFF4AA0)), (Int(Double(c.w) * 0.62), y + 4 * s, "BAR", C(0x4AE8FF)),
                (Int(Double(c.w) * 0.83), y - 3 * s, "PAWN", C(0xFFB040))]
    }

    /// Blüdhaven, Nightwing's grimy harbour city, at night in the rain: low cloud lit sodium-orange by the city, a
    /// cramped skyline of tired buildings with neon signs (a hotel, a bar, a pawn shop), gantry cranes and stacked
    /// containers on the far quay, black harbour water full of reflections, and the crew on a wet dock with a police
    /// cruiser parked at the end.
    static func bludhaven(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), hz = bludhavenWater(g)
        c.gradient(0, hz, C(0x07090F), C(0x2E2A34), bands: tall ? 9 : 5)
        for k in 0..<4 { c.rect(0, hz - 12 * s - k * 8 * s, c.w, 8 * s, C(0x8A5A2A, 0.07)) }
        if tall {
            for i in 0..<14 {                                    // heavy cloud lit from below
                let cx = Int(noise(i * 5 + 300) * Double(c.w)), cy = g / 20 + Int(noise(i * 5 + 301) * Double(g * 2 / 5))
                let r = (20 + Int(noise(i * 5 + 302) * 30)) * s
                c.ellipse(cx, cy, r * 2, r / 3, C(0x1E1E28, 0.8)); c.ellipse(cx + r / 3, cy + r / 4, r * 3 / 2, max(1, r / 6), C(0x4A3A3A, 0.5))
            }
            bludhavenBridge(c, g)
        }
        let blocks = bludhavenBlocks(c, g)
        for b in blocks where !b.near { bludhavenBuilding(c, b, C(0x171922), lit: C(0xC8C070, 0.35), seed: 1) }
        bludhavenCranes(c, g)
        for b in blocks where b.near { bludhavenBuilding(c, b, C(0x0D0F16), lit: C(0xD8A858, 0.55), seed: 2) }
        for sg in bludhavenSigns(c, g) {
            let tw = scenes7TextWidth(sg.text, s: s)
            c.rect(sg.x - tw / 2 - 3 * s, sg.y - 2 * s, tw + 6 * s, 9 * s, C(0x0A0A10))
            c.rect(sg.x - tw / 2 - 3 * s, sg.y - 2 * s, tw + 6 * s, s, C(0x3A3A44))
            c.rect(sg.x - s, sg.y + 7 * s, 2 * s, hz - sg.y - 7 * s, C(0x0A0A10))
        }
        // the far quay with its containers
        c.rect(0, hz - 3 * s, c.w, 3 * s, C(0x16161C)); c.rect(0, hz - 3 * s, c.w, s, C(0x3A3A40))
        let boxes: [Px] = [C(0x4A2018), C(0x163A3A), C(0x1E2A44), C(0x4A3A16)]
        var x = Int(Double(c.w) * 0.24), i = 0
        while x < Int(Double(c.w) * 0.38) {
            for k in 0..<(1 + Int(noise(i * 3 + 70) * 3)) {
                let col = boxes[(i + k) % boxes.count]
                c.rect(x, hz - 3 * s - (k + 1) * 4 * s, 12 * s, 4 * s, col)
                for xx in stride(from: x + s, to: x + 12 * s, by: 2 * s) { c.rect(xx, hz - 3 * s - (k + 1) * 4 * s + s, max(1, s / 2), 2 * s, lerp(col, C(0x000000), 0.4)) }
            }
            x += 13 * s; i += 1
        }
        // the harbour
        c.rect(0, hz, c.w, g - hz, C(0x080B12))
        for k in 0..<(g - hz) { if k % (2 * s) == 0 { c.rect(0, hz + k, c.w, max(1, s / 2), C(0x141A26, 0.6)) } }
        for b in blocks where b.near {
            for k in 0..<2 where noise(b.x * 7 + k) > 0.6 {
                let rx = b.x + Int(noise(b.x * 3 + k) * Double(b.w))
                for y in stride(from: hz + s, to: g - 2 * s, by: 2 * s) { c.rect(rx + Int(noise(y + rx) * 3) * s - s, y, 2 * s, max(1, s / 2), C(0xD8A858, 0.18)) }
            }
        }
        for sg in bludhavenSigns(c, g) {
            for y in stride(from: hz + s, to: g - 2 * s, by: 2 * s) {
                let wob = Int(noise(y * 3 + sg.x) * 4) * s - 2 * s
                c.rect(sg.x - 5 * s + wob, y, 10 * s, max(1, s / 2), sg.col.alpha(0.18))
            }
        }
        // the dock's edge, bollards, a lamp
        c.rect(0, g - 2 * s, c.w, 2 * s, C(0x1E1C1A)); c.rect(0, g - 2 * s, c.w, s, C(0x3A3630))
        for bx in stride(from: 20 * s, to: c.w - 50 * s, by: 70 * s) {
            c.rect(bx, g - 5 * s, 4 * s, 4 * s, C(0x14141A)); c.rect(bx - s, g - 6 * s, 6 * s, 2 * s, C(0x24242C))
        }
        let lx = Int(Double(c.w) * 0.12)
        c.rect(lx, g - (tall ? 40 : 30) * s, s, (tall ? 40 : 30) * s, C(0x1A1A20))
        c.rect(lx, g - (tall ? 40 : 30) * s, 5 * s, s, C(0x1A1A20))
        c.rect(lx + 4 * s, g - (tall ? 39 : 29) * s, 2 * s, s, C(0xFFC870))
        for k in 0..<3 { c.ellipse(lx + 5 * s, g - (tall ? 38 : 28) * s, (3 + k * 3) * s, (2 + k * 2) * s, C(0xFFB050, 0.06)) }
        bludhavenCruiser(c, g)
        c.ground(g, C(0x1E2028), edge: C(0x4A4E5A), speck: C(0x2A2C36), seed: 91)
        for i in 0..<(c.w / 30) {                                   // puddles
            let px = Int(noise(i * 3 + 950) * Double(c.w)), py = g + 2 * s + Int(noise(i * 3 + 951) * Double(max(1, c.h - g - 4 * s)))
            c.ellipse(px, py, (4 + Int(noise(i * 3 + 952) * 6)) * s, max(1, s), C(0x3A4258, 0.7))
        }
        c.ellipse(lx + 5 * s, g + 3 * s, 10 * s, 2 * s, C(0xFFB050, 0.12))
    }

    static func bludhavenBuilding(_ c: PixelCanvas, _ b: BludhavenBlock, _ col: Px, lit: Px, seed: Int) {
        c.rect(b.x, b.y, b.w, b.h, col)
        c.rect(b.x, b.y, b.w, 1, lerp(col, C(0x6A6A78), 0.3))
        if noise(b.x + seed * 13) > 0.6 {                          // rooftop water tower
            c.rect(b.x + b.w / 3, b.y - 4, 4, 3, col); c.rect(b.x + b.w / 3, b.y - 5, 4, 1, lerp(col, C(0x6A6A78), 0.3))
        }
        for (j, wy) in stride(from: b.y + 2, to: b.y + b.h - 1, by: 3).enumerated() {
            for (k, wx) in stride(from: b.x + 1, to: b.x + b.w - 1, by: 3).enumerated()
            where noise(b.x * 31 + j * 7 + k * 13 + seed * 977) > 0.78 {
                c.rect(wx, wy, 2, 1, lit)
            }
        }
    }

    /// Two gantry cranes on the far quay, booms reaching out over the water.
    static func bludhavenCranes(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), hz = bludhavenWater(g), col = C(0x3A2218), hi = C(0x7A4A2A)
        for (k, fx) in [0.04, 0.17].enumerated() {
            let x = Int(Double(c.w) * fx), top = hz - Int(Double(hz) * (k == 0 ? 0.85 : 0.72))
            for lx in [x, x + 14 * s] {
                c.rect(lx, top + 6 * s, 2 * s, hz - top - 6 * s, col)
                c.rect(lx, top + 6 * s, s, hz - top - 6 * s, hi)
            }
            for y in stride(from: top + 10 * s, to: hz - 4 * s, by: 10 * s) {
                scenes7Line(c, x, y, x + 14 * s, y + 10 * s, col, s: s); scenes7Line(c, x + 14 * s, y, x, y + 10 * s, col, s: s)
            }
            c.rect(x - 16 * s, top + 4 * s, 48 * s, 3 * s, col); c.rect(x - 16 * s, top + 4 * s, 48 * s, s, hi)
            c.rect(x + 2 * s, top, 10 * s, 5 * s, col)
            scenes7Line(c, x + 7 * s, top - 6 * s, x - 14 * s, top + 4 * s, col); scenes7Line(c, x + 7 * s, top - 6 * s, x + 30 * s, top + 4 * s, col)
            c.rect(x + 6 * s, top - 6 * s, 2 * s, 6 * s, col)
            c.rect(x + 24 * s, top + 7 * s, max(1, s / 2), 12 * s, C(0x3A3A40)); c.rect(x + 22 * s, top + 19 * s, 4 * s, 2 * s, col)
        }
    }

    /// A suspension bridge far off across the bay (tall screens).
    static func bludhavenBridge(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), hz = bludhavenWater(g), deck = hz - Int(Double(hz) * 0.42), col = C(0x2A2C3A)
        let x0 = Int(Double(c.w) * 0.35), x1 = Int(Double(c.w) * 1.05)
        c.rect(x0, deck, x1 - x0, 2 * s, col)
        for tx in [x0 + (x1 - x0) / 4, x0 + (x1 - x0) * 3 / 4] {
            c.rect(tx - s, deck - 40 * s, 3 * s, 40 * s + (hz - deck), col)
            c.rect(tx - s, deck - 41 * s, 3 * s, s, C(0xFF3A3A, 0.8))
        }
        let a = x0 + (x1 - x0) / 4, b = x0 + (x1 - x0) * 3 / 4
        for x in a...b {
            let u = Double(x - a) / Double(b - a) * 2 - 1, y = deck - 40 * s + Int(u * u * 38 * Double(s))
            c.px(x, y, col)
            if (x - a) % (4 * s) == 0 { c.rect(x, y, 1, deck - y, col.alpha(0.6)) }
        }
        for x in stride(from: x0, to: x1, by: 6 * s) { c.px(x, deck + s, C(0xFFD890, 0.6)) }
    }

    /// Where the cruiser is parked: its left edge and top row.
    static func bludhavenCruiserAt(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int) {
        let s = unit(g)
        return (c.w - 34 * s, g - 9 * s)
    }

    static func bludhavenCruiser(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), p = bludhavenCruiserAt(c, g)
        scenes7Stamp(c, p.x, p.y, [
            ".......aaaaaaaaa.........",
            "......awwwwawwwwwa.......",
            ".....awwwwwawwwwwwa......",
            ".ddddddddddddddddddddddd.",
            "dddWWWWWWWWWWWWWWWWWddddl",
            "ddWWWWWWWWWWWWWWWWWWWdddd",
            "ddddddddddddddddddddddddd",
            "..ttt..............ttt...",
            "..ttt..............ttt...",
        ], ["a": C(0x4A5262), "w": C(0x3A4A5E), "d": C(0x1E2128), "W": C(0xB8BCC6), "t": C(0x060608), "l": C(0xF0E0A0)], s: s)
        c.rect(p.x + 8 * s, p.y - s, 9 * s, s, C(0x2A2A30))
    }

    /// Rain slanting down, the neon buzzing (the hotel's flickers), the crane lights and the cruiser's lights
    /// throwing red and blue over the wet dock.
    static func bludhavenLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), hz = bludhavenWater(g)
        for (k, sg) in bludhavenSigns(c, g).enumerated() {
            let on = k == 0 ? (noise(Int(t * 11)) < 0.12 ? 0.2 : 1.0) : (k == 2 ? (noise(Int(t * 7) + 99) < 0.06 ? 0.3 : 1.0) : 1.0)
            let tw = scenes7TextWidth(sg.text, s: s)
            c.rect(sg.x - tw / 2 - 4 * s, sg.y - 3 * s, tw + 8 * s, 11 * s, sg.col.alpha(0.12 * on))
            scenes7Text(c, sg.x - tw / 2, sg.y, sg.text, sg.col.alpha(on), s: s)
        }
        for (k, fx) in [0.04, 0.17].enumerated() where scenes7Phase(t, 2.0, offset: Double(k) * 0.7) < 0.5 {
            let x = Int(Double(c.w) * fx) + 7 * s, top = hz - Int(Double(hz) * (k == 0 ? 0.85 : 0.72)) - 7 * s
            c.rect(x, top, s, s, C(0xFF3A3A)); c.circle(x, top, 2 * s, C(0xFF3A3A, 0.25))
        }
        // the cruiser's light bar
        let p = bludhavenCruiserAt(c, g), red = scenes7Phase(t, 0.6) < 0.5
        let lc = red ? C(0xFF2A3A) : C(0x3A6AFF)
        c.rect(p.x + (red ? 8 : 13) * s, p.y - s, 4 * s, s, lc)
        c.circle(p.x + (red ? 10 : 15) * s, p.y - 2 * s, 3 * s, lc.alpha(0.18))
        c.ellipse(p.x + 12 * s, g + 3 * s, 26 * s, 3 * s, lc.alpha(0.16))
        c.rect(p.x - 40 * s, p.y - 12 * s, 40 * s, 22 * s, lc.alpha(0.04))
        c.rect(0, hz, c.w, 2 * s, lc.alpha(0.03))
        // the rain
        let n = c.w * c.h / (isTall(c) ? 200 : 140)
        for i in 0..<n {
            let speed = 150.0 + noise(i * 3 + 7) * 70
            let y = (noise(i * 3 + 8) * Double(c.h) + t * speed).truncatingRemainder(dividingBy: Double(c.h + 10)) - 5
            let x = Int(noise(i * 3 + 9) * Double(c.w + 40)) - Int(y / 4)
            c.rect(x, Int(y), max(1, s / 2), 3 * s, C(0xA8B8D0, 0.3))
        }
        for i in 0..<(c.w / 20) where noise(Int(t * 10) * 31 + i) > 0.5 {
            let x = Int(noise(Int(t * 10) * 17 + i) * Double(c.w)), y = g + 1 + Int(noise(Int(t * 10) * 13 + i) * Double(c.h - g - 1))
            c.rect(x - s, y, 3 * s, max(1, s / 2), C(0xC8D0E0, 0.45))
        }
        for i in 0..<(c.w / 30) where noise(Int(t * 6) * 23 + i) > 0.55 {           // rings on the harbour
            let x = Int(noise(Int(t * 6) * 19 + i) * Double(c.w)), y = hz + s + Int(noise(Int(t * 6) * 29 + i) * Double(g - hz - 3 * s))
            c.rect(x - s, y, 3 * s, max(1, s / 2), C(0x8A9AB8, 0.35))
        }
    }
}

// MARK: - JSA Headquarters

extension Scenes {
    /// The trophy cases either side of the fireplace: centre column and what's inside.
    static func jsaCases(_ c: PixelCanvas, _ g: Int) -> [(x: Int, item: Int)] {
        let s = unit(g), cx = c.w / 2, d = isTall(c) ? 72 : 58
        return [(cx - d * s, 0), (cx + d * s, 1), (cx - d * 2 * s, 2), (cx + d * 2 * s, 3)]
    }

    /// The fireplace's opening: left edge, top row, width.
    static func jsaHearth(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, w: Int) {
        let s = unit(g), w = (isTall(c) ? 30 : 24) * s
        return (c.w / 2 - w / 2, g - (isTall(c) ? 20 : 16) * s, w)
    }

    /// The Justice Society's brownstone: a wood-panelled trophy room at night. A stone fireplace in the middle under a
    /// gilt JSA crest, glass cases on pedestals holding Jay Garrick's winged helmet, Alan Scott's lantern, Doctor
    /// Fate's helm and Hourman's hourglass, tall curtained windows and bookshelves further out, and a rug on the
    /// boards. Tall screens get the high ceiling: a row of portraits of the founding members and a chandelier.
    static func jsaHQ(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), cx = c.w / 2
        let dado = g - 18 * s
        c.rect(0, 0, c.w, dado, C(0x3E2418))
        for x in stride(from: 0, to: c.w, by: 8 * s) {                // striped wallpaper with a small figure
            c.rect(x, 0, 3 * s, dado, C(0x46291B))
            for y in stride(from: 4 * s, to: dado, by: 10 * s) { c.rect(x + 5 * s, y + (x / (8 * s) % 2) * 5 * s, s, s, C(0x6A4428, 0.6)) }
        }
        c.rect(0, 0, c.w, 2 * s, C(0x24140C)); c.rect(0, 2 * s, c.w, s, C(0x7A5232))
        if tall { jsaHigh(c, g) }
        c.rect(0, dado, c.w, g - dado, C(0x26150D))
        c.rect(0, dado, c.w, 2 * s, C(0x5A3A22)); c.rect(0, dado, c.w, s, C(0x8A6038))
        for x in stride(from: 3 * s, to: c.w, by: 16 * s) {
            c.rect(x, dado + 4 * s, 12 * s, g - dado - 6 * s, C(0x2E1A10)); c.rect(x, dado + 4 * s, 12 * s, s, C(0x1A0E08))
            c.rect(x, g - 3 * s, 12 * s, s, C(0x4A2E1C))
        }
        // windows and bookshelves out to the edges
        var off = (isTall(c) ? 190 : 150) * s, k = 0
        while cx - off > -30 * s {
            for side in [-1, 1] {
                if k % 2 == 0 { jsaWindow(c, g, cx + side * off) } else { jsaShelf(c, g, cx + side * off, seed: k * 2 + side) }
            }
            off += 44 * s; k += 1
        }
        jsaFireplace(c, g)
        for cs in jsaCases(c, g) { jsaCase(c, g, cs.x, cs.item) }
        // the floor: boards and a rug
        c.ground(g, C(0x3A2214), edge: C(0x7A5232), speck: C(0x2E1A0E), seed: 61)
        for (j, y) in stride(from: g + 2 * s, to: c.h, by: 3 * s).enumerated() {
            c.rect(0, y, c.w, max(1, s / 2), C(0x2A180C))
            for x in stride(from: (j % 3) * 14 * s, to: c.w, by: 40 * s) { c.rect(x, y, max(1, s / 2), 3 * s, C(0x2A180C)) }
        }
        let rw = 70 * s, ry = g + 2 * s
        c.rect(cx - rw, ry, rw * 2, c.h - ry - s, C(0x5A1418))
        c.rect(cx - rw, ry, rw * 2, s, C(0xC8963A)); c.rect(cx - rw, c.h - 2 * s, rw * 2, s, C(0xC8963A))
        c.rect(cx - rw + 3 * s, ry + 2 * s, rw * 2 - 6 * s, max(1, c.h - ry - 5 * s), C(0x3A1A3A, 0.5))
        let h = jsaHearth(c, g)
        c.rect(h.x - 6 * s, g + s, h.w + 12 * s, s, C(0x6A5E52))
    }

    static func jsaWindow(_ c: PixelCanvas, _ g: Int, _ x: Int) {
        let s = unit(g), top = isTall(c) ? g * 2 / 5 : 6 * s, bot = g - 22 * s, w = (isTall(c) ? 28 : 18) * s
        guard bot > top + 8 * s else { return }
        c.rect(x - w / 2 - 2 * s, top - 2 * s, w + 4 * s, bot - top + 4 * s, C(0x5A3A22))
        c.rect(x - w / 2, top, w, bot - top, C(0x0E1428))
        c.ellipse(x, top, w / 2, 4 * s, C(0x5A3A22)); c.ellipse(x, top + s, w / 2 - 2 * s, 3 * s, C(0x0E1428))
        c.stars(top, top + (bot - top) / 2, density: 14, seed: x, x0: x - w / 2, x1: x + w / 2)
        for k in 0..<3 {                                     // the brownstones across the street
            let bx = x - w / 2 + k * 6 * s, by = top + (bot - top) / 2 + Int(noise(x + k) * 6) * s
            c.rect(bx, by, 6 * s, bot - by, C(0x1E1820))
            if noise(x * 3 + k) > 0.3 { c.rect(bx + 2 * s, by + 3 * s, 2 * s, 2 * s, C(0xE8C070, 0.7)) }
        }
        c.rect(x - s / 2, top, max(1, s), bot - top, C(0x4A2E1C)); c.rect(x - w / 2, top + (bot - top) / 2, w, s, C(0x4A2E1C))
        c.rect(x - w / 2 - 4 * s, top - 4 * s, 5 * s, bot - top + 8 * s, C(0x5A1A1E)); c.rect(x + w / 2 - s, top - 4 * s, 5 * s, bot - top + 8 * s, C(0x5A1A1E))
        for k in 0..<2 { c.rect(x - w / 2 - 3 * s + k * 2 * s, top - 4 * s, max(1, s / 2), bot - top + 8 * s, C(0x3A0E12)) }
        c.rect(x - w / 2 - 6 * s, top - 5 * s, w + 12 * s, s, C(0xC8963A))
        c.rect(x - w / 2 - 2 * s, bot + 2 * s, w + 4 * s, s, C(0x7A5232))
    }

    static func jsaShelf(_ c: PixelCanvas, _ g: Int, _ x: Int, seed: Int) {
        let s = unit(g), hgt = min(g - 4 * s, (isTall(c) ? 90 : 46) * s), y0 = g - hgt
        let books: [Px] = [C(0x6A2A22), C(0x2A4A3A), C(0x7A5A2A), C(0x3A2A4A), C(0x8A6A4A), C(0x2A3A5A)]
        c.rect(x - 12 * s, y0, 24 * s, hgt, C(0x1E120B))
        c.rect(x - 13 * s, y0 - s, 26 * s, 2 * s, C(0x5A3A22))
        for (j, sy) in stride(from: y0 + 2 * s, to: g - 4 * s, by: 7 * s).enumerated() {
            var bx = x - 11 * s, n = 0
            while bx < x + 10 * s {
                let bw = (1 + Int(noise(j * 17 + n + seed * 7) * 2.0)) * s, bh = (4 + Int(noise(j * 13 + n * 3 + seed) * 2.0)) * s
                c.rect(bx, sy + 6 * s - bh, bw, bh, books[(j + n + seed) % books.count])
                bx += bw; n += 1
            }
            c.rect(x - 12 * s, sy + 6 * s, 24 * s, s, C(0x4A3020))
        }
    }

    /// The stone fireplace, its mantel and the JSA crest above it.
    static func jsaFireplace(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), h = jsaHearth(c, g), cx = c.w / 2, tall = isTall(c)
        let sw = h.w + 16 * s, mantel = h.y - 6 * s
        c.rect(cx - sw / 2 - 4 * s, 0, sw + 8 * s, g, C(0x46291C))                // the chimney breast
        c.rect(cx - sw / 2 - 4 * s, 0, s, g, C(0x5A3A24)); c.rect(cx + sw / 2 + 3 * s, 0, s, g, C(0x2A180E))
        c.rect(cx - sw / 2, mantel, sw, g - mantel, C(0x7A6A5A))
        for y in stride(from: mantel + 3 * s, to: g, by: 4 * s) { c.rect(cx - sw / 2, y, sw, max(1, s / 2), C(0x5E5044)) }
        c.rect(cx - sw / 2 - 3 * s, mantel - 3 * s, sw + 6 * s, 3 * s, C(0x3A2014)); c.rect(cx - sw / 2 - 3 * s, mantel - 3 * s, sw + 6 * s, s, C(0xC8963A))
        c.rect(h.x, h.y, h.w, g - h.y, C(0x0C0604))
        c.ellipse(cx, h.y, h.w / 2, 3 * s, C(0x7A6A5A)); c.ellipse(cx, h.y + s, h.w / 2 - 2 * s, 2 * s, C(0x0C0604))
        for y in stride(from: h.y + 2 * s, to: g - 3 * s, by: 3 * s) { c.rect(h.x + 2 * s, y, h.w - 4 * s, max(1, s / 2), C(0x2A0E08)) }
        c.rect(h.x + 3 * s, g - 3 * s, h.w - 6 * s, 2 * s, C(0x4A2A14)); c.rect(h.x + 5 * s, g - 4 * s, h.w - 10 * s, s, C(0x5A341A))
        c.rect(h.x + 2 * s, g - s, h.w - 4 * s, s, C(0x2A2A2E))
        // candlesticks and a clock on the mantel
        for side in [-1, 1] {
            let x = cx + side * (sw / 2 - s)
            c.rect(x - s, mantel - 8 * s, 2 * s, 5 * s, C(0xC8A040)); c.rect(x - s / 2, mantel - 11 * s, max(1, s), 3 * s, C(0xEDE2C8))
        }
        c.rect(cx - 3 * s, mantel - 8 * s, 6 * s, 5 * s, C(0x3A2014)); c.circle(cx, mantel - 6 * s, 2 * s, C(0xE8DCC0)); c.px(cx, mantel - 7 * s, C(0x1A0E08))
        // the crest
        let m = tall ? 3 * s : 2 * s, tw = scenes7TextWidth("JSA", s: m), ph = 5 * m + 6 * s
        let py = mantel - 14 * s - ph - (tall ? 10 * s : 0), pw = tw + 8 * s
        c.rect(cx - pw / 2 - s, py - s, pw + 2 * s, ph + 2 * s, C(0xC8963A))
        c.rect(cx - pw / 2, py, pw, ph, C(0x14204A))
        c.rect(cx - pw / 2 + s, py + s, pw - 2 * s, s, C(0x2A3A6A))
        scenes7Text(c, cx - tw / 2, py + 3 * s, "JSA", C(0xF0C850), s: m)
        c.rect(cx - pw / 2 - s, py + ph + s, pw + 2 * s, s, C(0x7A5A22))
        if tall {                                         // the team's portrait over the crest
            let gw = sw - 4 * s, gh = 40 * s, gx = cx - gw / 2, gy = py - gh - 14 * s
            c.rect(gx - 2 * s, gy - 2 * s, gw + 4 * s, gh + 4 * s, C(0xC8963A))
            c.rect(gx, gy, gw, gh, C(0x1E2A44)); c.rect(gx, gy + gh * 2 / 3, gw, gh / 3, C(0x2A2018))
            let suits: [Px] = [C(0xC83A2A), C(0x2E8A3A), C(0xC89A30), C(0x2A4A9A), C(0x1A1A22), C(0x3A8A4A)]
            for k in 0..<6 {
                let fx = gx + 4 * s + k * (gw - 8 * s) / 6 + 2 * s, fy = gy + gh / 3 + (k % 2) * 3 * s
                c.rect(fx, fy + 4 * s, 5 * s, gh * 2 / 3 - (k % 2) * 3 * s - 4 * s, suits[k])
                c.rect(fx + s, fy, 3 * s, 4 * s, C(0xD8A880))
            }
            c.rect(gx - 2 * s, gy - 2 * s, gw + 4 * s, s, C(0xF0C860))
        }
    }

    /// A trophy on a pedestal under glass: 0 Jay's helmet, 1 Alan's lantern, 2 Fate's helm, 3 Hourman's hourglass.
    static func jsaCase(_ c: PixelCanvas, _ g: Int, _ x: Int, _ item: Int) {
        let s = unit(g), top = g - 14 * s, gh = 16 * s
        c.rect(x - 6 * s, top, 12 * s, 14 * s, C(0x2E1A10)); c.rect(x - 7 * s, top, 14 * s, 2 * s, C(0x6A4A2C))
        c.rect(x - 7 * s, top, 14 * s, s, C(0xC8963A)); c.rect(x - 7 * s, g - 2 * s, 14 * s, 2 * s, C(0x4A2E1C))
        c.rect(x - 3 * s, top + 5 * s, 6 * s, 4 * s, C(0x8A6A2A)); c.rect(x - 2 * s, top + 6 * s, 4 * s, 2 * s, C(0x3A2A14))
        switch item {
        case 0:
            scenes7Stamp(c, x - 5 * s, top - 7 * s, [
                "...aaaaa...",
                "..abbbbba..",
                "w.abbbbbba.w",
                "wwabbbbbbaww",
                ".wwaaaaaaww.",
                "aaaaaaaaaaa.",
            ], ["a": C(0x7A7E86), "b": C(0xC8CCD4), "w": C(0xEEF0F2)], s: s)
        case 1:
            scenes7Stamp(c, x - 4 * s, top - 11 * s, [
                "..hhhhh..",
                ".h.....h.",
                "..rrrrr..",
                "..gGGGg..",
                ".rgGWGgr.",
                ".rgGWGgr.",
                ".rgGGGgr.",
                "..gGGGg..",
                "..rrrrr..",
                ".rrrrrrr.",
                ".rrrrrrr.",
            ], ["h": C(0x6A7A6A), "r": C(0x1E5A2A), "g": C(0x3ACA5A), "G": C(0x8AF09A), "W": C(0xE8FFE8)], s: s)
        case 2:
            scenes7Stamp(c, x - 5 * s, top - 11 * s, [
                "...yyyyy...",
                "..yYYYYYy..",
                ".yYYYYYYYy.",
                ".yYYYYYYYy.",
                ".ykkkkkkky.",
                ".yYYYkYYYy.",
                ".yYYYkYYYy.",
                ".yYYYkYYYy.",
                "..yYYYYYy..",
                "..yyyyyyy..",
                "...........",
            ], ["y": C(0xA87A18), "Y": C(0xE8B830), "k": C(0x0A0A14)], s: s)
        default:
            scenes7Stamp(c, x - 3 * s, top - 11 * s, [
                "fffffff",
                ".gsssg.",
                ".gsssg.",
                "..gsg..",
                "...s...",
                "..g.g..",
                ".g...g.",
                ".gsssg.",
                "fffffff",
            ], ["f": C(0xC8963A), "g": C(0xC8DCE8), "s": C(0xE8C870)], s: s)
            c.rect(x - 3 * s, top - 2 * s, 7 * s, 2 * s, C(0x8A6A2A))
        }
        c.rect(x - 7 * s, top - gh, 14 * s, gh, C(0xA8D0E8, 0.10))
        c.rect(x - 7 * s, top - gh, s, gh, C(0xC8E0F0, 0.4)); c.rect(x + 6 * s, top - gh, s, gh, C(0xC8E0F0, 0.3))
        c.rect(x - 5 * s, top - gh + 2 * s, s, gh / 2, C(0xFFFFFF, 0.18))
        c.rect(x - 7 * s, top - gh - 2 * s, 14 * s, 2 * s, C(0x3A2014)); c.rect(x - 7 * s, top - gh - 2 * s, 14 * s, s, C(0xC8963A))
    }

    /// The tall screens' upper wall: a picture rail, portraits of the founders and the chandelier's chain.
    static func jsaHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), y = g / 6, ph = 30 * s, pw = 22 * s
        c.rect(0, y - 6 * s, c.w, s, C(0x7A5232))
        let heroes: [(Px, Px)] = [(C(0xC83A2A), C(0xB8BCC6)), (C(0x3A8A3A), C(0x6A2A6A)), (C(0xC89A30), C(0x2A4A9A)),
                                  (C(0x2A6A3A), C(0xE8E0D0)), (C(0x1A1A22), C(0x4A4A5A)), (C(0xC8A040), C(0x2A6A3A)), (C(0x2A2A3A), C(0xC89A30))]
        var x = 14 * s, i = 0
        while x + pw < c.w {
            if abs(x + pw / 2 - c.w / 2) > 50 * s {
                let hero = heroes[i % heroes.count]
                c.rect(x - 2 * s, y - 2 * s, pw + 4 * s, ph + 4 * s, C(0xA87A2A))
                c.rect(x, y, pw, ph, C(0x2A1E18))
                c.ellipse(x + pw / 2, y + ph - 3 * s, pw / 2 - s, 8 * s, hero.0)
                c.circle(x + pw / 2, y + ph / 2 - s, 5 * s, C(0xD8A880))
                c.rect(x + pw / 2 - 5 * s, y + ph / 2 - 7 * s, 10 * s, 4 * s, hero.1)
                c.rect(x + pw / 2 - 3 * s, y + ph / 2 - s, 6 * s, s, hero.1.alpha(0.8))
                c.rect(x - 2 * s, y - 2 * s, pw + 4 * s, s, C(0xE8C060))
                c.rect(x + pw / 2 - s / 2, y - 8 * s, max(1, s), 6 * s, C(0x8A6A2A))
                i += 1
            }
            x += pw + 20 * s
        }
        c.rect(c.w / 2, 0, max(1, s), g / 4, C(0x8A6A2A))
        // framed front pages over the trophy cases, and a sconce over each
        for cs in jsaCases(c, g) {
            let ly = g - 100 * s
            for k in 0..<4 { c.circle(cs.x, ly, (6 + k * 5) * s, C(0xFFD890, 0.05)) }
            c.rect(cs.x - s, ly + 2 * s, 2 * s, 8 * s, C(0xA87A2A)); c.rect(cs.x - 3 * s, ly + 9 * s, 6 * s, 2 * s, C(0xC8963A))
            c.rect(cs.x - 4 * s, ly - 3 * s, 8 * s, 5 * s, C(0xF0D8A0)); c.rect(cs.x - 3 * s, ly - 3 * s, 6 * s, s, C(0xFFF0C8))
            let fx = cs.x - 12 * s, fy = g - 70 * s
            c.rect(fx - s, fy - s, 26 * s, 32 * s, C(0x2A180E)); c.rect(fx - s, fy - s, 26 * s, s, C(0xC8963A))
            c.rect(fx + s, fy + s, 22 * s, 28 * s, C(0xE8DEC4))
            c.rect(fx + 3 * s, fy + 3 * s, 18 * s, 3 * s, C(0x1A1A1A))
            c.rect(fx + 3 * s, fy + 8 * s, 9 * s, 8 * s, C(0x8A8070))
            for y in stride(from: fy + 8 * s, to: fy + 27 * s, by: 2 * s) { c.rect(fx + 14 * s, y, 7 * s, max(1, s / 2), C(0x6A6458)) }
            for y in stride(from: fy + 18 * s, to: fy + 27 * s, by: 2 * s) { c.rect(fx + 3 * s, y, 9 * s, max(1, s / 2), C(0x6A6458)) }
        }
    }

    /// The fire, sparks going up the chimney, Alan's lantern breathing green, a glint on Fate's helm and, on tall
    /// screens, the chandelier's candles.
    static func jsaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), h = jsaHearth(c, g), cx = c.w / 2
        c.ellipse(cx, h.y + (g - h.y) / 2, h.w, (g - h.y) / 2 + 4 * s, C(0xFF9A3A, 0.10 + 0.04 * sin(t * 7)))
        c.ellipse(cx, g + 3 * s, h.w * 2, 4 * s, C(0xFF9A3A, 0.10 + 0.04 * sin(t * 6)))
        let fireTop = g - 4 * s, maxH = g - h.y - 6 * s
        for x in stride(from: h.x + 4 * s, to: h.x + h.w - 4 * s, by: s) {
            let k = Double(x - h.x) / Double(h.w), bell = sin(k * .pi)
            let fh = Int(Double(maxH) * bell * (0.55 + 0.45 * noise(Int(t * 12) * 37 + x / s)))
            guard fh > 0 else { continue }
            c.rect(x, fireTop - fh, s, fh, C(0xE84A1A))
            c.rect(x, fireTop - fh * 2 / 3, s, fh * 2 / 3, C(0xFF9A2A))
            c.rect(x, fireTop - fh / 3, s, fh / 3, C(0xFFE07A))
        }
        for i in 0..<5 {
            let ph = scenes7Phase(t, 1.6 + noise(i) , offset: noise(i + 5) * 3)
            let x = cx + Int((noise(i * 3 + 1) - 0.5) * Double(h.w)) + Int(sin(t * 3 + Double(i)) * 2)
            let y = fireTop - Int(ph * Double(g - h.y + 4 * s))
            if y > h.y { c.px(x, y, C(0xFFC860, 1 - ph)) }
        }
        for cs in jsaCases(c, g) {
            if cs.item == 1 {
                let p = 0.5 + 0.5 * sin(t * 1.8)
                c.circle(cs.x, g - 20 * s, (5 + Int(p * 2)) * s, C(0x5AFF7A, 0.10 + p * 0.10))
                c.rect(cs.x - s, g - 21 * s, 2 * s, 2 * s, C(0xF0FFF0, 0.5 + p * 0.5))
                c.rect(cs.x - 7 * s, g - 30 * s, 14 * s, 16 * s, C(0x5AFF7A, 0.04 + p * 0.04))
            } else if cs.item == 2 {
                let ph = scenes7Phase(t, 5.0, offset: 1)
                if ph < 0.3 {
                    let gx = cs.x - 4 * s + Int(ph / 0.3 * 8) * s
                    c.rect(gx, g - 24 * s, s, s, C(0xFFF8D0)); c.circle(gx, g - 24 * s, s, C(0xFFE890, 0.4))
                }
            }
        }
        if isTall(c) {
            let y = g / 4, w = 40 * s
            c.rect(cx - w, y, w * 2, 2 * s, C(0x8A6A2A)); c.rect(cx - w / 2, y - 6 * s, w, 2 * s, C(0x8A6A2A))
            for k in 0...6 {
                let x = cx - w + k * w / 3, yy = k % 2 == 0 ? y : y - 6 * s
                guard abs(x - cx) <= (k % 2 == 0 ? w : w / 2) else { continue }
                c.rect(x - s / 2, yy - 3 * s, max(1, s), 3 * s, C(0xEDE2C8))
                let fl = noise(Int(t * 9) * 13 + k) > 0.3 ? 2 * s : s
                c.rect(x - s / 2, yy - 3 * s - fl, max(1, s), fl, C(0xFFD060))
                c.circle(x, yy - 4 * s, 3 * s, C(0xFFD890, 0.15))
            }
            c.circle(cx, y, 40 * s, C(0xFFD890, 0.04))
        }
    }
}

// MARK: - Fawcett City

extension Scenes {
    /// The broadcasting tower: its centre, the top of the building it stands on and its tip.
    static func fawcettTower(_ c: PixelCanvas, _ g: Int) -> (x: Int, base: Int, tip: Int) {
        let tall = isTall(c)
        return (Int(Double(c.w) * 0.78), g - Int(Double(g) * (tall ? 0.36 : 0.45)), tall ? g / 7 : 2)
    }

    /// Where the subway entrance is.
    static func fawcettSubway(_ c: PixelCanvas) -> Int { Int(Double(c.w) * 0.3) }

    /// Fawcett City on a bright Golden Age afternoon: a clear blue sky, cream, terracotta and brick art-deco blocks
    /// with stepped crowns, the Fawcett Broadcasting building with the WHIZ tower climbing over it in red and white,
    /// and on the sidewalk the green railings and globe lamps of the subway entrance where Billy Batson met the wizard.
    static func fawcettCity(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x3C7CD0), C(0xC4E2F6), bands: tall ? 8 : 6)
        let sx = Int(Double(c.w) * 0.1), sy = tall ? g / 8 : g / 4
        for k in 0..<3 { c.circle(sx, sy, (8 + k * 5) * s, C(0xFFF8D0, 0.12)) }
        c.circle(sx, sy, 5 * s, C(0xFFFCE8))
        if tall {
            for i in 0..<6 {
                wisp(c, Int(noise(i * 5 + 410) * Double(c.w)), g / 12 + Int(noise(i * 5 + 411) * Double(g / 4)),
                     (40 + Int(noise(i * 5 + 412) * 50)) * s, C(0xFFFFFF, 0.5), s: s)
            }
        }
        // far buildings in blue haze
        var x = -6 * s, i = 0
        while x < c.w {
            let bw = (10 + Int(noise(i * 7 + 520) * 14)) * s, bh = Int(Double(g) * ((tall ? 0.3 : 0.45) + noise(i * 7 + 521) * (tall ? 0.3 : 0.35)))
            let col = C(0x9AB4D4)
            c.rect(x, g - bh, bw, bh, col)
            c.rect(x + bw / 4, g - bh - 4 * s, bw / 2, 4 * s, col); c.rect(x + bw / 2 - s, g - bh - 10 * s, 2 * s, 6 * s, col)
            for wy in stride(from: g - bh + 3 * s, to: g, by: 4 * s) { c.rect(x + 2 * s, wy, bw - 4 * s, s, C(0x8AA4C8)) }
            x += bw + 2 * s; i += 1
        }
        // the near blocks
        let tw = fawcettTower(c, g), sub = fawcettSubway(c)
        let cols: [Px] = [C(0xE8D8B8), C(0xC8785A), C(0xA85A44), C(0xD8BC88), C(0xB8A890)]
        x = -10 * s; i = 0
        while x < c.w {
            let bw = (26 + Int(noise(i * 7 + 600) * 22)) * s
            let bh = Int(Double(g) * ((tall ? 0.22 : 0.3) + noise(i * 7 + 601) * (tall ? 0.3 : 0.25)))
            if x + bw > tw.x - 26 * s && x < tw.x + 26 * s { x = tw.x + 26 * s; continue }
            fawcettBlock(c, g, x, bw, g - bh, cols[i % cols.count], seed: i)
            x += bw + Int(noise(i * 7 + 602) * 6) * s; i += 1
        }
        fawcettStation(c, g)
        // the sidewalk and the subway entrance
        c.ground(g, C(0xA8A49A), edge: C(0xD8D4C8), speck: C(0x96928A), seed: 41)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x8A867E)) }
        c.rect(0, c.h - 2 * s, c.w, 2 * s, C(0x6A6660))
        let ew = 26 * s
        c.rect(sub - ew / 2, g + s, ew, c.h - g - s, C(0x1A1E1A))
        for (k, y) in stride(from: g + 2 * s, to: c.h, by: 2 * s).enumerated() { c.rect(sub - ew / 2 + 2 * s, y, ew - 4 * s, max(1, s / 2), C(0x3A3E38, 1 - Double(k) * 0.15)) }
        let green = C(0x2E6A3A), lgreen = C(0x5AA060)
        for side in [-1, 1] {
            let px = sub + side * (ew / 2)
            c.rect(px - s, g - 18 * s, 2 * s, 18 * s, green); c.rect(px - s, g - 18 * s, s, 18 * s, lgreen)
            c.circle(px, g - 21 * s, 3 * s, C(0xF4F0D8)); c.circle(px - s, g - 22 * s, s, C(0xFFFFFF))
            c.rect(px - 2 * s, g - 18 * s, 4 * s, s, green)
        }
        c.rect(sub - ew / 2, g - 8 * s, ew, s, green); c.rect(sub - ew / 2, g - 8 * s, ew, max(1, s / 2), lgreen)
        for x in stride(from: sub - ew / 2 + 2 * s, to: sub + ew / 2, by: 3 * s) { c.rect(x, g - 8 * s, max(1, s / 2) + s / 2, 8 * s, green) }
        let lw = scenes7TextWidth("SUBWAY", s: s)
        c.rect(sub - lw / 2 - 2 * s, g - 16 * s, lw + 4 * s, 7 * s, C(0x1E4A2A))
        c.rect(sub - lw / 2 - 2 * s, g - 16 * s, lw + 4 * s, s, lgreen)
        scenes7Text(c, sub - lw / 2, g - 15 * s, "SUBWAY", C(0xF4F0E0), s: s)
    }

    /// One art-deco block: setbacks, piers, window rows and a darker storefront with an awning.
    static func fawcettBlock(_ c: PixelCanvas, _ g: Int, _ x: Int, _ w: Int, _ top: Int, _ col: Px, seed: Int) {
        let s = unit(g), dark = lerp(col, C(0x3A2A20), 0.35), lite = lerp(col, C(0xFFFFFF), 0.3)
        c.rect(x, top, w, g - top, col)
        let st = noise(seed * 5 + 31)
        if st > 0.35 {                                         // stepped crown
            c.rect(x + w / 6, top - 5 * s, w * 2 / 3, 5 * s, col); c.rect(x + w / 6, top - 5 * s, w * 2 / 3, s, lite)
            c.rect(x + w / 3, top - 9 * s, w / 3, 4 * s, col); c.rect(x + w / 3, top - 9 * s, w / 3, s, lite)
            if st > 0.7 { c.rect(x + w / 2 - s, top - 16 * s, 2 * s, 7 * s, dark); c.rect(x + w / 2, top - 18 * s, max(1, s / 2), 2 * s, dark) }
        }
        c.rect(x, top, w, s, lite)
        for px in stride(from: x + 2 * s, to: x + w - 2 * s, by: 6 * s) { c.rect(px, top + 2 * s, s, g - top - 10 * s, lite.alpha(0.6)) }
        for (j, wy) in stride(from: top + 3 * s, to: g - 11 * s, by: 4 * s).enumerated() {
            for px in stride(from: x + 4 * s, to: x + w - 3 * s, by: 6 * s) {
                c.rect(px, wy, 2 * s, 2 * s, C(0x2E3E5E))
                if noise(seed * 37 + j * 7 + px) > 0.8 { c.rect(px, wy, s, s, C(0xBFD8F0)) }
            }
        }
        // the storefront
        c.rect(x, g - 9 * s, w, 9 * s, dark)
        c.rect(x + 2 * s, g - 6 * s, w - 4 * s, 4 * s, C(0x2A3446))
        let aw: Px = noise(seed * 5 + 33) > 0.5 ? C(0x9A3A30) : C(0x2E6A4A)
        for k in 0..<((w - 2 * s) / (2 * s)) { c.rect(x + s + k * 2 * s, g - 9 * s, 2 * s, 3 * s, k % 2 == 0 ? aw : C(0xD8D0C0)) }
    }

    /// The Fawcett Broadcasting building and the WHIZ tower over it.
    static func fawcettStation(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tw = fawcettTower(c, g), bw = 44 * s
        let col = C(0xE0D2B0), lite = C(0xF4ECD8)
        c.rect(tw.x - bw / 2, tw.base, bw, g - tw.base, col)
        c.rect(tw.x - bw / 2 + 4 * s, tw.base - 4 * s, bw - 8 * s, 4 * s, col); c.rect(tw.x - bw / 2 + 4 * s, tw.base - 4 * s, bw - 8 * s, s, lite)
        c.rect(tw.x - bw / 2, tw.base, bw, s, lite)
        for px in stride(from: tw.x - bw / 2 + 3 * s, to: tw.x + bw / 2 - 2 * s, by: 5 * s) {
            c.rect(px, tw.base + 9 * s, 2 * s, g - tw.base - 18 * s, C(0x2E3E5E))
            c.rect(px - s, tw.base + 8 * s, s, g - tw.base - 16 * s, lite)
        }
        let lw = scenes7TextWidth("WHIZ", s: s)
        c.rect(tw.x - lw / 2 - 3 * s, tw.base + 2 * s, lw + 6 * s, 7 * s, C(0xB82A22))
        scenes7Text(c, tw.x - lw / 2, tw.base + 3 * s, "WHIZ", C(0xFFF4D0), s: s)
        c.rect(tw.x - bw / 2, g - 9 * s, bw, 9 * s, lerp(col, C(0x3A2A20), 0.35))
        c.rect(tw.x - 5 * s, g - 7 * s, 10 * s, 7 * s, C(0x2A3446)); c.rect(tw.x - 7 * s, g - 9 * s, 14 * s, 2 * s, C(0xB82A22))
        // the lattice tower, red and white bands
        let top = tw.tip, base = tw.base - 4 * s, hgt = base - top, half0 = 10 * s
        let halfAt = { (y: Int) -> Int in max(s, half0 * (y - top) / max(1, hgt)) }
        for y in top..<base {
            let band = ((y - top) / (8 * s)) % 2 == 0
            let col: Px = band ? C(0xD0382A) : C(0xF0ECE4)
            let hw = halfAt(y)
            c.rect(tw.x - hw, y, s, 1, col); c.rect(tw.x + hw - s + 1, y, s, 1, col)
        }
        for y in stride(from: top + 6 * s, to: base - 6 * s, by: 8 * s) {
            let y2 = y + 8 * s, a = halfAt(y), b = halfAt(y2)
            let col: Px = ((y - top) / (8 * s)) % 2 == 0 ? C(0xB03024) : C(0xD8D4CC)
            scenes7Line(c, tw.x - a, y, tw.x + b, y2, col); scenes7Line(c, tw.x + a, y, tw.x - b, y2, col)
            c.rect(tw.x - b, y2, b * 2, 1, col)
        }
        c.rect(tw.x - s / 2, top - 6 * s, max(1, s), 6 * s, C(0x8A8A90))
        c.circle(tw.x, top, 2 * s, C(0xE8E4DC))
    }

    /// Clouds drifting by, the tower's beacon and its radio waves, and now and then Shazam's red-and-gold lightning
    /// bolt cracking in the clouds.
    static func fawcettLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), tw = fawcettTower(c, g)
        let n = tall ? 6 : 3
        for i in 0..<n {
            let speed = (3.0 + noise(i * 3 + 1) * 4) * Double(s), span = Double(c.w + 120 * s)
            let x = Int((noise(i * 3 + 2) * span + t * speed).truncatingRemainder(dividingBy: span)) - 60 * s
            let y = (tall ? g / 10 : 6 * s) + Int(noise(i * 3 + 3) * Double(tall ? g / 3 : 10 * s))
            cloud(c, x, y, (tall ? 7 : 4) * s, seed: i + 30)
        }
        if tall {                                       // a blimp
            let span = Double(c.w + 120 * s), x = Int((t * 6 * Double(s)).truncatingRemainder(dividingBy: span)) - 60 * s, y = g / 5
            c.ellipse(x, y, 24 * s, 7 * s, C(0xC8CCD4)); c.ellipse(x - 2 * s, y - 2 * s, 20 * s, 4 * s, C(0xE0E4EA))
            c.rect(x - 4 * s, y + 7 * s, 8 * s, 3 * s, C(0x5A5E66))
            c.rect(x - 26 * s, y - 6 * s, 4 * s, 12 * s, C(0xB82A22))
            let lw = scenes7TextWidth("WHIZ", s: s)
            scenes7Text(c, x - lw / 2, y - 2 * s, "WHIZ", C(0xB82A22), s: s)
        }
        if scenes7Phase(t, 1.4) < 0.35 { c.circle(tw.x, tw.tip, 2 * s, C(0xFF3A2A)); c.circle(tw.x, tw.tip, 4 * s, C(0xFF3A2A, 0.3)) }
        for k in 0..<2 {
            let ph = scenes7Phase(t, 2.0, offset: Double(k))
            let r = Double(6 + Int(ph * 20)) * Double(s)
            for a in stride(from: -2.4, to: -0.7, by: 0.12) {
                let ang: Double = a
                c.px(tw.x + Int(cos(ang) * r), tw.tip + Int(sin(ang) * r), C(0xFFFFFF, 0.6 * (1 - ph)))
            }
        }
        // the lightning bolt
        let cyc = 7.0, ph = scenes7Phase(t, cyc, offset: 5.75)
        guard ph < 0.12 else { return }
        let bx = Double(Int(noise(Int((t + 5.75) / cyc) * 7 + 3) * Double(c.w) * 0.5) + c.w / 5)
        let by = Double(tall ? g / 6 : 4 * s), u = Double(s) * (tall ? 3.0 : 1.4)
        let pts: [(Double, Double)] = [(0, 0), (-5, 7), (0, 7), (-6, 16), (3, 5), (-2, 5), (2, -1)]
        let on = ph < 0.04 || (ph > 0.07 && ph < 0.12)
        guard on else { return }
        c.circle(Int(bx), Int(by + 6 * u), Int(10 * u), C(0xFFF0B0, 0.18))
        for k in 0..<(pts.count - 1) {
            let a = pts[k], b = pts[k + 1]
            c.glowLine(bx + a.0 * u, by + a.1 * u, bx + b.0 * u, by + b.1 * u, core: C(0xFFD830), glow: C(0xE02020),
                       coreR: 0.6 * u, glowR: 1.4 * u, strength: 1)
        }
    }
}

// MARK: - S.T.A.R. Labs

extension Scenes {
    /// The accelerator ring: centre, radii and pipe thickness.
    static func starLabsRing(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, rx: Int, ry: Int, th: Int) {
        let s = unit(g), tall = isTall(c)
        return (c.w / 2, tall ? g * 9 / 20 : g * 2 / 5, Int(Double(c.w) * (tall ? 0.36 : 0.3)), tall ? g / 4 : g / 3, (tall ? 8 : 6) * s)
    }

    /// The racks, consoles and chambers along the walls: centre column and kind (0 console, 1 chamber, 2 rack).
    static func starLabsKit(_ c: PixelCanvas, _ g: Int) -> [(x: Int, kind: Int)] {
        let s = unit(g), r = starLabsRing(c, g)
        var out: [(x: Int, kind: Int)] = []
        for side in [-1, 1] {
            out.append((r.x + side * r.rx * 2 / 3, 0))
            var off = r.rx + 20 * s, k = 1
            while off < c.w / 2 + 30 * s {
                out.append((r.x + side * off, k % 2 == 1 ? 1 : 2))
                off += 30 * s; k += 1
            }
        }
        return out
    }

    /// S.T.A.R. Labs, Central City: a steel-blue lab with the particle accelerator's ring sweeping round the room on
    /// its struts, the S.T.A.R. LABS sign under it, consoles of monitors, server racks and glass test chambers along
    /// the walls, and a polished floor. Tall screens get the ceiling's light strips and a catwalk.
    static func starLabs(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), r = starLabsRing(c, g)
        c.gradient(0, g, C(0x141C26), C(0x1E2A36), bands: 4)
        for x in stride(from: 0, to: c.w, by: 24 * s) { c.rect(x, 0, s, g, C(0x10161E)); c.rect(x + s, 0, max(1, s / 2), g, C(0x2A3846)) }
        for y in stride(from: g / 3, to: g, by: max(12 * s, g / 3)) { c.rect(0, y, c.w, s, C(0x10161E)) }
        if tall {
            for y in [g / 14, g / 7] {
                for x in stride(from: 10 * s, to: c.w, by: 50 * s) {
                    c.rect(x, y, 30 * s, 2 * s, C(0xD8F0FF)); c.rect(x - 4 * s, y + 2 * s, 38 * s, 3 * s, C(0xBFE4FF, 0.08))
                }
            }
            let cy = g / 5 + 6 * s
            c.rect(0, cy, c.w, 3 * s, C(0x3A4654)); c.rect(0, cy, c.w, s, C(0x6A7A8A))
            for x in stride(from: 0, to: c.w, by: 4 * s) { c.rect(x, cy - 6 * s, max(1, s / 2), 6 * s, C(0x4A5664)) }
            c.rect(0, cy - 6 * s, c.w, s, C(0x6A7A8A))
        }
        // the lower wall
        let dado = g - 14 * s
        c.rect(0, dado, c.w, g - dado, C(0x10161E)); c.rect(0, dado, c.w, s, C(0x3A4A5A))
        c.rect(0, g - 2 * s, c.w, s, C(0x4AB8FF, 0.35))
        // the ring's struts
        for a in [0.28, 0.42, 0.58, 0.72] {
            let ang: Double = a * .pi
            let x = r.x + Int(cos(ang) * Double(r.rx)), y = r.y + Int(sin(ang) * Double(r.ry))
            c.rect(x - 3 * s, y, 6 * s, g - y, C(0x2A3440)); c.rect(x - 3 * s, y, s, g - y, C(0x4A5A6A)); c.rect(x - 5 * s, g - 3 * s, 10 * s, 3 * s, C(0x3A4654))
        }
        for side in [-1, 1] {
            let x = r.x + side * r.rx
            c.rect(x - 3 * s, r.y, 6 * s, g - r.y, C(0x2A3440)); c.rect(x - 3 * s, r.y, s, g - r.y, C(0x4A5A6A))
            c.rect(x - 5 * s, g - 4 * s, 10 * s, 4 * s, C(0x3A4654))
        }
        // the ring: thinner along its far side, magnets in orange housings, the beam pipe glowing down its middle
        let steps = Int(Double(r.rx + r.ry) * 7)
        let thick = { (a: Double) -> Int in max(2 * s, Int(Double(r.th) * (0.7 + 0.3 * sin(a)))) }
        for i in 0..<steps {
            let a = Double(i) / Double(steps) * 2 * .pi, th = thick(a)
            let x = r.x + Int(cos(a) * Double(r.rx)), y = r.y + Int(sin(a) * Double(r.ry))
            c.rect(x - th / 2, y - th / 2, th, th, sin(a) < 0 ? C(0x34404C) : C(0x3E4A58))
        }
        for i in 0..<steps {
            let a = Double(i) / Double(steps) * 2 * .pi, th = thick(a)
            let x = r.x + Int(cos(a) * Double(r.rx)), y = r.y + Int(sin(a) * Double(r.ry))
            c.px(x, y - th / 2, C(0x8A9AAA)); c.px(x, y + th / 2 - 1, C(0x222A34))
            c.px(x, y, C(0x2A6A9A))
        }
        for k in 0..<36 {
            let a = Double(k) / 36 * 2 * .pi, th = thick(a) + 2 * s
            let x = r.x + Int(cos(a) * Double(r.rx)), y = r.y + Int(sin(a) * Double(r.ry))
            let bw = max(2 * s, Int(Double(th) * (0.4 + 0.6 * abs(sin(a)))))
            c.rect(x - bw / 2, y - th / 2, bw, th, k % 3 == 0 ? C(0x2A6A9A) : C(0xC8602A))
            c.rect(x - bw / 2, y - th / 2, bw, max(1, s), k % 3 == 0 ? C(0x6AB8E8) : C(0xF0A060))
            c.rect(x - bw / 2, y + th / 2 - s, bw, max(1, s), C(0x1A1E24))
        }
        // the sign
        let m = tall ? 2 * s : s, text = "S.T.A.R. LABS", tw = scenes7TextWidth(text, s: m)
        let sy = r.y - r.ry / 3 - 3 * m
        c.rect(r.x - tw / 2 - 5 * m, sy - 3 * m, tw + 10 * m, 11 * m, C(0x0C1218))
        c.rect(r.x - tw / 2 - 5 * m, sy - 3 * m, tw + 10 * m, s, C(0x4A5A6A))
        scenes7Text(c, r.x - tw / 2, sy, text, C(0xE0EAF4), s: m)
        c.rect(r.x - tw / 2, sy + 7 * m, tw, s, C(0x4AB8FF, 0.6))
        if tall {                                           // the big wall display: the ring's schematic
            let d = starLabsDisplay(c, g)
            c.rect(d.x - d.w / 2 - 2 * s, d.y - 2 * s, d.w + 4 * s, d.h + 4 * s, C(0x3A4654))
            c.rect(d.x - d.w / 2, d.y, d.w, d.h, C(0x08121C))
            for x in stride(from: d.x - d.w / 2, to: d.x + d.w / 2, by: 8 * s) { c.rect(x, d.y, max(1, s / 2), d.h, C(0x14283A)) }
            for y in stride(from: d.y, to: d.y + d.h, by: 8 * s) { c.rect(d.x - d.w / 2, y, d.w, max(1, s / 2), C(0x14283A)) }
            for i in 0..<240 {
                let a = Double(i) / 240 * 2 * .pi
                c.px(d.x + Int(cos(a) * Double(d.w) * 0.32), d.y + d.h / 2 + Int(sin(a) * Double(d.h) * 0.3), C(0x4AB8FF))
            }
            for k in 0..<5 { c.rect(d.x + d.w / 2 - 34 * s, d.y + 6 * s + k * 5 * s, (10 + Int(noise(k + 77) * 20)) * s, 2 * s, C(0x4AE88A, 0.7)) }
            c.rect(d.x - d.w / 2 + 6 * s, d.y + 6 * s, 20 * s, 2 * s, C(0xFFB84A, 0.8))
        }
        for k in starLabsKit(c, g) {
            switch k.kind {
            case 0: starLabsConsole(c, g, k.x)
            case 1: starLabsChamber(c, g, k.x)
            default: starLabsRack(c, g, k.x)
            }
        }
        c.ground(g, C(0x262E38), edge: C(0x7A8A9A), speck: C(0x2E3844), seed: 51)
        for x in stride(from: 0, to: c.w, by: 20 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x1E242C)) }
        c.rect(0, g + (c.h - g) / 2, c.w, max(1, s / 2), C(0x1E242C))
        c.ellipse(r.x, g + (c.h - g) / 2, r.rx, max(1, (c.h - g) / 4), C(0x4AB8FF, 0.06))
    }

    /// The tall screens' wall display inside the ring: centre, top row, size.
    static func starLabsDisplay(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, w: Int, h: Int) {
        let r = starLabsRing(c, g), s = unit(g)
        return (r.x, r.y - r.ry / 3 + 16 * s, r.rx, r.ry * 3 / 4)
    }

    static func starLabsConsole(_ c: PixelCanvas, _ g: Int, _ x: Int) {
        let s = unit(g)
        c.rect(x - 14 * s, g - 8 * s, 28 * s, 8 * s, C(0x2A323C)); c.rect(x - 15 * s, g - 9 * s, 30 * s, 2 * s, C(0x8A9AAA))
        for k in 0..<3 {
            let mx = x - 13 * s + k * 9 * s
            c.rect(mx, g - 17 * s, 8 * s, 7 * s, C(0x0A1018)); c.rect(mx, g - 17 * s, 8 * s, s, C(0x4A5A6A))
            c.rect(mx + 3 * s, g - 10 * s, 2 * s, s, C(0x3A4654))
        }
    }

    static func starLabsChamber(_ c: PixelCanvas, _ g: Int, _ x: Int) {
        let s = unit(g), hgt = (isTall(c) ? 40 : 30) * s, top = g - hgt
        c.rect(x - 8 * s, g - 4 * s, 16 * s, 4 * s, C(0x3A4654)); c.rect(x - 8 * s, g - 4 * s, 16 * s, s, C(0x8A9AAA))
        c.rect(x - 8 * s, top, 16 * s, 4 * s, C(0x3A4654)); c.rect(x - 8 * s, top + 3 * s, 16 * s, s, C(0x2A323C))
        c.rect(x - 7 * s, top + 4 * s, 14 * s, hgt - 8 * s, C(0x3AD8C8, 0.16))
        c.rect(x - 7 * s, top + 4 * s, s, hgt - 8 * s, C(0xBFF0F0, 0.5)); c.rect(x + 6 * s, top + 4 * s, s, hgt - 8 * s, C(0xBFF0F0, 0.3))
        c.rect(x - 4 * s, top + 6 * s, s, hgt / 2, C(0xFFFFFF, 0.25))
        c.rect(x - s, top - 6 * s, 2 * s, 6 * s, C(0x2A323C))
    }

    static func starLabsRack(_ c: PixelCanvas, _ g: Int, _ x: Int) {
        let s = unit(g), hgt = (isTall(c) ? 44 : 32) * s
        c.rect(x - 6 * s, g - hgt, 12 * s, hgt, C(0x161C24)); c.rect(x - 6 * s, g - hgt, 12 * s, s, C(0x4A5A6A))
        for y in stride(from: g - hgt + 3 * s, to: g - 2 * s, by: 3 * s) { c.rect(x - 5 * s, y, 10 * s, s, C(0x222A34)) }
    }

    /// Pulses of energy chasing round the ring, the monitors' traces, rack lights blinking and bubbles rising through
    /// the test chambers round a glowing sample.
    static func starLabsLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), r = starLabsRing(c, g), tall = isTall(c)
        for k in 0..<4 {
            let head = t * 1.3 + Double(k) * .pi / 2
            for j in 0..<10 {
                let a: Double = head - Double(j) * 0.03
                let x = r.x + Int(cos(a) * Double(r.rx)), y = r.y + Int(sin(a) * Double(r.ry))
                c.rect(x - s, y - s, 2 * s, 2 * s, C(0x9AE8FF, 1 - Double(j) * 0.09))
            }
            let x = r.x + Int(cos(head) * Double(r.rx)), y = r.y + Int(sin(head) * Double(r.ry))
            c.circle(x, y, 3 * s, C(0x6AD0FF, 0.35))
        }
        if tall {
            let d = starLabsDisplay(c, g), a = t * 1.3
            let x = d.x + Int(cos(a) * Double(d.w) * 0.32), y = d.y + d.h / 2 + Int(sin(a) * Double(d.h) * 0.3)
            c.rect(x - s, y - s, 3 * s, 3 * s, C(0xE0F8FF)); c.circle(x, y, 4 * s, C(0x6AD0FF, 0.3))
        }
        let screens: [Px] = [C(0x4AE88A), C(0x4AB8FF), C(0xFFB84A)]
        for kit in starLabsKit(c, g) {
            switch kit.kind {
            case 0:
                for k in 0..<3 {
                    let mx = kit.x - 13 * s + k * 9 * s, col = screens[(k + kit.x) % 3]
                    for j in 0..<(7 * s) {
                        let v = sin(Double(j) * 0.9 / Double(s) + t * 3 + Double(k)) * 1.5 + noise(j + Int(t * 4) * 9 + k) * 1.2
                        c.px(mx + s / 2 + j, g - 14 * s + Int(v * Double(s)), col)
                    }
                }
            case 1:
                let hgt = (tall ? 40 : 30) * s, top = g - hgt, p = 0.5 + 0.5 * sin(t * 2.5 + Double(kit.x))
                c.circle(kit.x, g - hgt / 2, (3 + Int(p * 2)) * s, C(0x6AFFE0, 0.2 + p * 0.15))
                c.circle(kit.x, g - hgt / 2, 2 * s, C(0xE0FFF8))
                for b in 0..<4 {
                    let ph = scenes7Phase(t, 2.2, offset: Double(b) * 0.55 + noise(kit.x))
                    let by = g - 5 * s - Int(ph * Double(hgt - 10 * s))
                    c.rect(kit.x - 5 * s + Int(noise(b + kit.x) * 10) * s, by, s, s, C(0xE0FFFF, 0.6))
                }
                _ = top
            default:
                let hgt = (tall ? 44 : 32) * s
                for (j, y) in stride(from: g - hgt + 4 * s, to: g - 2 * s, by: 3 * s).enumerated() {
                    for k in 0..<3 where noise(Int(t * 3) * 41 + j * 7 + k + kit.x) > 0.45 {
                        let col: Px = noise(j * 3 + k + kit.x) > 0.8 ? C(0xFF5A4A) : C(0x5AFF8A)
                        c.px(kit.x - 4 * s + k * 3 * s, y, col)
                    }
                }
            }
        }
    }
}

// MARK: - Hall of Doom

extension Scenes {
    /// Where the swamp's water starts.
    static func hallOfDoomWater(_ c: PixelCanvas, _ g: Int) -> Int { g - (isTall(c) ? 40 : 12) * unit(g) }

    /// The Hall: centre column, top row and height (its foot sinks a little below the water line).
    static func hallOfDoomFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, top: Int, hgt: Int) {
        let hz = hallOfDoomWater(c, g), hgt = isTall(c) ? Int(Double(g) * 0.6) : hz - 1
        return (c.w / 2, hz + 4 * unit(g) - hgt, hgt)
    }

    /// The Hall's half-width `u` of the way down from its crown, as a fraction of its height.
    static func hallOfDoomHalf(_ u: Double) -> Double {
        if u <= 0.5 { let v = (0.5 - u) / 0.5; return 0.36 * (1 - v * v).squareRoot() }
        let v = (u - 0.5) / 0.5
        return 0.36 + 0.26 * v * v
    }

    /// The Hall of Doom at night: the Legion of Doom's great helmet-shaped headquarters rising out of a misty swamp,
    /// its two slanted eye windows glowing yellow over the triangular grille of its door, its reflection in the black
    /// water, bald cypresses dripping with moss either side, a sickly moon behind thin cloud, and the crew on the muddy
    /// bank among the reeds.
    static func hallOfDoom(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), hz = hallOfDoomWater(c, g), f = hallOfDoomFrame(c, g)
        c.gradient(0, hz, C(0x04070A), C(0x24342C), bands: tall ? 9 : 6)
        c.stars(0, hz / 2, density: tall ? 110 : 70, seed: 66)
        let mx = Int(Double(c.w) * 0.8), my = tall ? g / 6 : g / 4, mr = max(6, g / 14)
        for k in 0..<4 { c.circle(mx, my, mr + (4 - k) * 4 * s, C(0xC8E0B0, 0.05)) }
        c.circle(mx, my, mr, C(0xD8E4C0)); c.circle(mx + mr / 3, my - mr / 4, mr / 4, C(0xC0CCA8)); c.circle(mx - mr / 3, my + mr / 3, mr / 5, C(0xC4D0AC))
        for k in 0..<3 { c.rect(mx - mr * 2 + k * 5 * s, my - mr / 3 + k * mr / 2, mr * 3, max(1, s), C(0x1A2A22, 0.7)) }
        // the far treeline
        c.dunes(base: hz - 6 * s, amp: Double(3 * s), freq: 0.07, phase: 1.2, bottom: hz, C(0x0E1612))
        for x in stride(from: 0, to: c.w, by: 3 * s) {
            let h = Int(noise(x / s + 1200) * 8) * s + 4 * s
            c.rect(x, hz - 6 * s - h, 2 * s, h, C(0x0E1612))
        }
        hallOfDoomHall(c, g)
        // the swamp
        c.rect(0, hz, c.w, g - hz, C(0x070C0A))
        for y in stride(from: hz + 2 * s, to: g, by: 2 * s) { c.rect(0, y, c.w, max(1, s / 2), C(0x0E1814, 0.7)) }
        hallOfDoomReflection(c, g)
        for y in stride(from: hz + s, to: g - s, by: 2 * s) {                       // the moon's path
            let w = Int(noise(y * 5 + 3) * 8 + 3) * s
            c.rect(mx - w / 2 + Int(noise(y) * 6) * s - 3 * s, y, w, max(1, s / 2), C(0xD8E4C0, 0.3))
        }
        for k in 0..<3 { c.rect(0, hz - 2 * s - k * 3 * s, c.w, 3 * s, C(0x8AA090, 0.05)) }
        // cypresses
        let trees: [(Double, Double)] = [(0.06, 0.95), (0.19, 0.75), (0.32, 0.55), (0.69, 0.6), (0.94, 0.9)]
        for (k, tr) in trees.enumerated() {
            let x = Int(Double(c.w) * tr.0)
            guard abs(x - f.x) > Int(Double(f.hgt) * 0.62) + 10 * s else { continue }
            hallOfDoomCypress(c, g, x, Int(Double(tall ? g * 3 / 4 : g) * tr.1), seed: k)
        }
        // the bank and its reeds
        c.ground(g, C(0x1A2016), edge: C(0x3A4A30), speck: C(0x12180E), seed: 33)
        for i in 0..<(c.w / 4) {
            let x = Int(noise(i * 3 + 1300) * Double(c.w)), h = (3 + Int(noise(i * 3 + 1301) * 7)) * s
            if abs(x - f.x) < 20 * s, noise(i) > 0.3 { continue }
            c.rect(x, g - h, max(1, s / 2) + (s > 1 ? 0 : 0), h, C(0x0A100A))
            if noise(i * 3 + 1302) > 0.75 { c.rect(x, g - h, s, 2 * s, C(0x3A2A18)) }
        }
        c.rect(0, g + (c.h - g) / 2, c.w, s, C(0x12180E))
    }

    /// The Hall itself: dome, flared guard, eyes, nose ridge and the door's grille.
    static func hallOfDoomHall(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = hallOfDoomFrame(c, g), H = Double(f.hgt)
        let body = C(0x1A2420), shade = C(0x101612), hi = C(0x4A5E52)
        for k in 0..<f.hgt {
            let u = Double(k) / H, half = Int(hallOfDoomHalf(u) * H)
            let y = f.top + k
            c.rect(f.x - half, y, half * 2 + 1, 1, body)
            c.rect(f.x + half / 3, y, half - half / 3 + 1, 1, shade)
            c.rect(f.x - half, y, max(1, s), 1, hi)
            if u < 0.5 { c.px(f.x - half * 2 / 3, y, C(0x2E3C34)) }
        }
        // the brow ridge across the dome
        let browY = f.top + Int(H * 0.40)
        let browHalf = Int(hallOfDoomHalf(0.4) * H)
        c.rect(f.x - browHalf, browY - s, browHalf * 2, 2 * s, C(0x2A3830))
        // the flare's rim
        let rimY = f.top + Int(H * 0.82)
        for k in rimY..<(f.top + f.hgt) {
            let half = Int(hallOfDoomHalf(Double(k - f.top) / H) * H)
            c.px(f.x - half, k, C(0x5A7062)); c.px(f.x + half, k, C(0x2A3830))
        }
        // the face mask: cheek creases, nose ridge, mouth grille
        let ex1 = H * 0.24
        for side in [-1, 1] {
            scenes7Line(c, f.x + side * Int(ex1), f.top + Int(H * 0.56), f.x + side * Int(H * 0.30), f.top + Int(H * 0.95), C(0x0A0E0C))
            scenes7Line(c, f.x + side * Int(H * 0.06), f.top + Int(H * 0.6), f.x + side * Int(H * 0.2), f.top + Int(H * 0.95), C(0x0A0E0C))
        }
        for k in Int(H * 0.5)..<Int(H * 0.68) {
            let hw = max(s, Int(Double(k) - H * 0.5) / 4)
            c.rect(f.x - hw, f.top + k, hw * 2, 1, C(0x2A3A32))
        }
        let my0 = Int(H * 0.68), my1 = Int(H * 0.93)
        for k in my0..<my1 {
            let hw = Int(Double(k - my0) * 0.55) + 2 * s
            c.rect(f.x - hw, f.top + k, hw * 2 + 1, 1, C(0x080A08))
        }
        for x in stride(from: f.x - Int(Double(my1 - my0) * 0.55), to: f.x + Int(Double(my1 - my0) * 0.55), by: 3 * s) {
            let k0 = my0 + Int(Double(abs(x - f.x)) / 0.55)
            if k0 < my1 { c.rect(x, f.top + k0, max(1, s), my1 - k0, C(0x2A3A32)) }
        }
        // the eyes, dark in the still picture; their light is in the moving layer
        for e in hallOfDoomEyes(c, g) { c.rect(e.x, e.y - s, 1, e.h + 2 * s, C(0x0A0E0C)) }
        for e in hallOfDoomEyes(c, g) { c.rect(e.x, e.y, 1, e.h, C(0x5A4410)) }
        // the ridge down the crown and a moonlit sheen
        c.rect(f.x - s / 2, f.top + s, max(1, s), Int(H * 0.38), C(0x2E3C34))
        for k in 0..<Int(H * 0.3) {
            let u = Double(k) / H + 0.06, half = Int(hallOfDoomHalf(u) * H)
            c.px(f.x - half * 3 / 4, f.top + Int(u * H), C(0x3A4A40))
        }
    }

    /// The eye windows as rows: x, y and height of each column (both eyes).
    static func hallOfDoomEyes(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, h: Int)] {
        let f = hallOfDoomFrame(c, g), H = Double(f.hgt), ey0 = H * 0.41, ex0 = H * 0.045, ex1 = H * 0.25
        var out: [(x: Int, y: Int, h: Int)] = []
        for side in [-1, 1] {
            for xi in Int(ex0)..<Int(ex1) {
                let xf = (Double(xi) - ex0) / (ex1 - ex0)
                let top = ey0 + H * 0.07 * xf, bot = ey0 + H * 0.12 + H * 0.025 * xf - (xf < 0.25 ? H * 0.05 * (0.25 - xf) * 4 : 0)
                out.append((f.x + side * xi, f.top + Int(top), Int(bot - top)))
            }
        }
        return out
    }

    /// The Hall's broken reflection in the swamp, with its eyes.
    static func hallOfDoomReflection(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), hz = hallOfDoomWater(c, g), f = hallOfDoomFrame(c, g), H = Double(f.hgt)
        for y in stride(from: hz, to: g, by: 1) {
            let src = 2 * hz - y
            guard src >= f.top else { continue }
            let half = Int(hallOfDoomHalf(Double(src - f.top) / H) * H), jit = Int(noise(y * 7) * 3) * s - s
            if (y - hz) % (2 * s) < s { c.rect(f.x - half + jit, y, half * 2, 1, C(0x18221E, 0.8)) }
        }
        for e in hallOfDoomEyes(c, g) {
            for k in 0..<e.h where (2 * hz - e.y - k) < g {
                let y = 2 * hz - e.y - k
                if (y - hz) % (2 * s) < s { c.px(e.x + Int(noise(y * 7) * 3) * s - s, y, C(0xFFC83A, 0.3)) }
            }
        }
    }

    /// A bald cypress: buttressed trunk, flat clumps of crown and moss hanging down.
    static func hallOfDoomCypress(_ c: PixelCanvas, _ g: Int, _ x: Int, _ hgt: Int, seed: Int) {
        let s = unit(g), col = C(0x0A100C), moss = C(0x2A3A2C, 0.8), base = hallOfDoomWater(c, g) + 4 * s
        let top = base - hgt
        for y in top..<base {
            let k = Double(y - top) / Double(hgt)
            let half = Int(1.5 * Double(s) + k * Double(hgt) * 0.03 + (k > 0.8 ? (k - 0.8) * Double(hgt) * 0.3 : 0))
            c.rect(x - half, y, half * 2 + 1, 1, col)
        }
        for j in 0..<9 {
            let cy = top + Int(Double(hgt) * (0.02 + noise(seed * 31 + j + 40) * 0.4))
            let cx = x + Int((noise(seed * 31 + j) - 0.5) * 34) * s
            let rx = (6 + Int(noise(seed * 31 + j + 7) * 9)) * s, ry = (3 + Int(noise(seed * 31 + j + 9) * 4)) * s
            scenes7Line(c, x, cy + ry + 6 * s, cx, cy, col, s: s)
            c.ellipse(cx, cy, rx, ry, col)
            c.ellipse(cx - rx / 3, cy - ry / 2, rx / 2, max(1, ry / 2), C(0x18221C))
            for m in 0..<(rx / s) where noise(seed * 97 + j * 11 + m) > 0.55 {
                let lx = cx - rx + m * 2 * s, len = (3 + Int(noise(seed * 7 + j * 5 + m) * 10)) * s
                c.rect(lx, cy + ry - s, max(1, s), len, moss)
            }
        }
    }

    /// The eyes' glow breathing, mist creeping over the water and bats flitting round the Hall.
    static func hallOfDoomLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), hz = hallOfDoomWater(c, g), f = hallOfDoomFrame(c, g), tall = isTall(c)
        let p = 0.5 + 0.5 * sin(t * 1.6), H = Double(f.hgt)
        let eyeY = f.top + Int(H * 0.47)
        for side in [-1, 1] {
            let ex = f.x + side * Int(H * 0.14)
            c.ellipse(ex, eyeY, Int(H * 0.16), Int(H * 0.07), C(0xFFB830, 0.08 + p * 0.08))
        }
        for e in hallOfDoomEyes(c, g) {
            c.rect(e.x, e.y, 1, e.h, C(0xFFC83A, 0.8 + p * 0.2))
            if e.h > 3 * s { c.rect(e.x, e.y + e.h / 3, 1, max(1, e.h / 3), C(0xFFF0A0, 0.6 + p * 0.3)) }
        }
        for e in hallOfDoomEyes(c, g) where (e.x - f.x) % (3 * s) == 0 {
            let y = 2 * hz - e.y - e.h / 2
            if y < g, y > hz { c.px(e.x + Int(sin(t * 3 + Double(y)) * 2), y, C(0xFFD860, 0.25 + p * 0.2)) }
        }
        // the mist
        for i in 0..<(tall ? 10 : 6) {
            let speed = (4.0 + noise(i * 3) * 6) * Double(s), span = Double(c.w + 160 * s)
            let x = Int((noise(i * 3 + 1) * span + t * speed).truncatingRemainder(dividingBy: span)) - 80 * s
            let y = hz - 4 * s + Int(noise(i * 3 + 2) * Double((tall ? 30 : 12) * s))
            c.ellipse(x, y, (30 + Int(noise(i * 3 + 4) * 30)) * s, (2 + Int(noise(i * 3 + 5) * 3)) * s, C(0x9AB0A0, 0.14))
        }
        // bats
        let up: [String] = ["b.....b", "bb.b.bb", ".bbbbb.", "...b..."]
        let down: [String] = ["...b...", ".bbbbb.", "bb...bb", "b.....b"]
        for i in 0..<(tall ? 8 : 4) {
            let a: Double = t * (0.5 + noise(i * 5) * 0.4) * (noise(i * 5 + 1) > 0.5 ? 1 : -1) + noise(i * 5 + 2) * 6.28
            let rx = H * (0.5 + noise(i * 5 + 3) * 0.5), ry = H * (0.12 + noise(i * 5 + 4) * 0.15)
            let x = f.x + Int(cos(a) * rx), y = f.top + Int(H * 0.15) + Int(sin(a * 1.3) * ry)
            let flap = sin(t * 14 + Double(i) * 2) > 0
            let m = tall ? 2 * s : s
            scenes7Stamp(c, x - 3 * m, y, flap ? up : down, ["b": C(0x020403)], s: m)
        }
    }
}
