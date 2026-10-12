import Foundation

let scenes6: [Location: Place] = [
    .aceChemicals: Place(name: "Ace Chemicals", panel: 0x0E1810, still: Scenes.aceChemicals, moving: Scenes.aceChemicalsLife),
    .lexCorp: Place(name: "LexCorp Tower", panel: 0x18162A, still: Scenes.lexCorp, moving: Scenes.lexCorpLife),
    .bayou: Place(name: "Louisiana Bayou", panel: 0x0E1A16, still: Scenes.bayou, moving: Scenes.bayouLife),
    .theDreaming: Place(name: "The Dreaming", panel: 0x16122C, still: Scenes.theDreaming, moving: Scenes.theDreamingLife),
    .coastCity: Place(name: "Coast City", panel: 0x1A2A3A, still: Scenes.coastCity, moving: Scenes.coastCityLife),
    .gorillaCity: Place(name: "Gorilla City", panel: 0x14200E, still: Scenes.gorillaCity, moving: Scenes.gorillaCityLife),
]

// MARK: - Shared bits for these scenes

/// String art drawn with every character `s` pixels square, skipping columns outside `clip` when given.
fileprivate func s6Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int,
                         clip: ClosedRange<Int>? = nil) {
    for (r, row) in rows.enumerated() {
        for (k, ch) in row.enumerated() {
            guard let col = pal[ch] else { continue }
            let px = x + k * s
            if let clip, px < clip.lowerBound || px + s - 1 > clip.upperBound { continue }
            c.rect(px, y + r * s, s, s, col)
        }
    }
}

/// Where a repeating motion of `period` seconds is, from 0 up to 1.
fileprivate func s6Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
    let v = (t + offset).truncatingRemainder(dividingBy: period) / period
    return v < 0 ? v + 1 : v
}

/// `v` wrapped into 0..<span.
fileprivate func s6Wrap(_ v: Double, _ span: Double) -> Double {
    let r = v.truncatingRemainder(dividingBy: span)
    return r < 0 ? r + span : r
}

/// A blocky capital alphabet, five rows tall, for the signs.
fileprivate let s6Glyphs: [Character: [String]] = [
    "A": [".#.", "#.#", "###", "#.#", "#.#"],
    "C": [".##", "#..", "#..", "#..", ".##"],
    "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."],
    "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
]

/// Draws `text` in the sign alphabet, each pixel `k` square.
fileprivate func s6Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, k: Int) {
    var cx = x
    for ch in text {
        guard let rows = s6Glyphs[ch] else { cx += 3 * k; continue }
        s6Stamp(c, cx, y, rows, ["#": col], s: k)
        cx += (rows[0].count + 1) * k
    }
}

fileprivate func s6TextWidth(_ text: String, k: Int) -> Int {
    var w = 0
    for ch in text { w += ((s6Glyphs[ch]?.first?.count ?? 2) + 1) * k }
    return max(0, w - k)
}

/// An ellipse outline, for ripples and rings.
fileprivate func s6Ring(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ col: Px, s: Int) {
    guard rx > 0 else { return }
    let n = max(12, rx * 3 / max(1, s))
    for i in 0..<n {
        let a: Double = Double(i) / Double(n) * 2 * Double.pi
        c.rect(cx + Int((cos(a) * Double(rx)).rounded()), cy + Int((sin(a) * Double(ry)).rounded()), s, max(1, s / 2), col)
    }
}

/// A palm tree: a gently leaning trunk and drooping fronds.
fileprivate func s6Palm(_ c: PixelCanvas, x: Int, base: Int, h: Int, s: Int, lean: Int, trunk: Px, leaf: Px, leafHi: Px) {
    for k in 0..<h {
        let u = Double(k) / Double(max(1, h))
        let dx = Int(Double(lean) * u * u)
        c.rect(x + dx, base - k, 2 * s, 1, k % (3 * s) == 0 ? lerp(trunk, C(0x000000), 0.3) : trunk)
    }
    let tx = x + lean + s, ty = base - h
    let dirs: [Double] = [-2.7, -2.2, -1.6, -0.9, -0.4, 0.15]
    for (i, d) in dirs.enumerated() {
        let len = Double((9 + i % 3 * 2) * s)
        for k in 0..<Int(len) {
            let u = Double(k) / len
            let fx = Double(tx) + cos(d) * Double(k), fy = Double(ty) + sin(d) * Double(k) * 0.6 + u * u * len * 0.55
            c.rect(Int(fx), Int(fy), s, s, k % 2 == 0 ? leaf : leafHi)
            if k % 3 == 1 { c.rect(Int(fx), Int(fy) + s, s, s, leaf.alpha(0.7)) }
        }
    }
    c.circle(tx, ty + s, s, C(0x5A3A1E))
}

// MARK: - Ace Chemicals

extension Scenes {
    /// The vats: left edge, width and the row of the acid's surface.
    static func aceVats(_ c: PixelCanvas, _ g: Int) -> [(x: Int, w: Int, top: Int)] {
        let s = unit(g), tall = isTall(c)
        let vw = max(44 * s, c.w / 10), top = g - (tall ? g / 5 : 25 * s)
        let spots: [Double] = [0.1, 0.26, 0.76, 0.92]
        return spots.map { (f: Double) -> (x: Int, w: Int, top: Int) in (Int(Double(c.w) * f) - vw / 2, vw, top) }
    }

    /// The big "ACE" letters on the roof sign: left edge, top row and pixel size.
    static func aceSign(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, k: Int) {
        let s = unit(g), tall = isTall(c)
        let k = tall ? max(6, g / 40) : 4 * s
        return (c.w / 2 - s6TextWidth("ACE", k: k) / 2, tall ? g / 4 : 3 * s, k)
    }

    /// The row the main pipe runs along.
    static func acePipeRow(_ c: PixelCanvas, _ g: Int) -> Int { g - (isTall(c) ? g / 3 : 33 * unit(g)) }

    /// The steam vents along the pipe: where the steam leaves.
    static func aceVents(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let s = unit(g), py = acePipeRow(c, g)
        let spots: [Double] = [0.18, 0.39, 0.61, 0.84]
        return spots.map { (f: Double) -> (x: Int, y: Int) in (Int(Double(c.w) * f), py - 6 * s) }
    }

    /// Ace Chemicals at night, where the Joker was born: the crew is up on a hazard-striped catwalk over the glow of
    /// the acid. Open vats of bubbling green acid stand either side, pipes with steam vents run along behind, and the
    /// plant's dark block rises in the middle under the big "ACE" sign (the red letters are lit in `aceChemicalsLife`,
    /// green "CHEMICALS" beneath). Gotham's smokestacks and tanks line the horizon under a sickly moon.
    static func aceChemicals(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x06070E), C(0x1C2C24), bands: 7)
        c.stars(0, g / 2, density: tall ? 110 : 70, seed: 61)
        let mx = Int(Double(c.w) * 0.86), my = tall ? g / 7 : 11 * s, mr = max(5, g / (tall ? 16 : 10))
        c.circle(mx, my, mr + 4 * s, C(0xC8E0A0, 0.06)); c.circle(mx, my, mr + 2 * s, C(0xC8E0A0, 0.08))
        c.circle(mx, my, mr, C(0xD8E2B8))
        c.circle(mx - mr / 3, my + mr / 4, max(1, mr / 4), C(0xB8C49A)); c.circle(mx + mr / 3, my - mr / 3, max(1, mr / 6), C(0xC0CCA4))
        c.rect(mx - mr - 6 * s, my + mr / 3, mr * 2 + 14 * s, max(1, s), C(0x1A2620, 0.85))   // smoke across the moon
        c.rect(mx - mr - 2 * s, my + mr / 3 + 2 * s, mr * 2 + 8 * s, max(1, s), C(0x1A2620, 0.6))
        if tall { aceHigh(c, g) }
        aceSkyline(c, g)
        acePlant(c, g)
        if tall { aceHighCatwalk(c, g) }
        acePipes(c, g)
        for v in aceVats(c, g) { aceVat(c, g, v) }
        // the catwalk's railing
        let rail = 10 * s
        for x in stride(from: 4 * s, to: c.w, by: 16 * s) { c.rect(x, g - rail, s, rail, C(0x4A5248)) }
        c.rect(0, g - rail / 2, c.w, s, C(0x3A423A))
        c.rect(0, g - rail, c.w, s, C(0xC8A030)); c.rect(0, g - rail + s, c.w, s, C(0x5A4A18))
        // the catwalk: steel grating over the green glow of the acid below, hazard stripes along its edge
        c.rect(0, g, c.w, c.h - g, C(0x2E6A1E))
        for y in stride(from: g, to: c.h, by: 3 * s) { c.rect(0, y, c.w, s, C(0x222A24)) }
        for x in stride(from: 0, to: c.w, by: 3 * s) { c.rect(x, g, s, c.h - g, C(0x222A24)) }
        for y in g..<min(c.h, g + 2 * s) {
            for x in 0..<c.w { c.px(x, y, ((x + y) / (3 * s)) % 2 == 0 ? C(0xD8B020) : C(0x16140E)) }
        }
        c.rect(0, g + 2 * s, c.w, s, C(0x3A4238))
    }

    /// Gotham's industrial edge on the horizon: works, smokestacks with red lamps, round tanks.
    static func aceSkyline(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), col = C(0x111A18)
        var x = -3 * s, i = 0
        while x < c.w {
            let n = noise(i * 7 + 610)
            let bw = (8 + Int(noise(i * 7 + 611) * 14)) * s
            let bh = Int(Double(g) * (0.2 + n * 0.25))
            c.rect(x, g - bh, bw, bh, col)
            if n > 0.5 {                                      // a smokestack
                let sx = x + bw / 3, sh = Int(Double(g) * (0.12 + noise(i * 7 + 612) * 0.2))
                c.rect(sx, g - bh - sh, 3 * s, sh, col)
                c.rect(sx, g - bh - sh, 3 * s, s, C(0x2A3430))
                c.rect(sx + s, g - bh - sh - s, s, s, C(0xFF3A2A, 0.8))
                c.ellipse(sx + 6 * s, g - bh - sh - 3 * s, 6 * s, 2 * s, C(0x2A342E, 0.5))
            } else if n < 0.25 {                              // a round tank
                c.ellipse(x + bw / 2, g - bh, bw / 2, max(1, bw / 6), col)
            }
            for wy in stride(from: g - bh + 3 * s, to: g, by: 4 * s) where noise(wy * 3 + i) > 0.75 {
                c.rect(x + s + Int(noise(wy + i * 5) * Double(max(1, bw - 2 * s))), wy, s, s, C(0x9AD86A, 0.35))
            }
            x += bw
            i += 1
        }
    }

    /// The plant's main block with the sign on its roof.
    static func acePlant(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), sg = aceSign(c, g)
        let sw = s6TextWidth("ACE", k: sg.k), sh = 5 * sg.k
        let sub = max(1, sg.k / 4), subW = s6TextWidth("CHEMICALS", k: sub)
        let boardW = max(sw, subW) + 8 * s, bx = c.w / 2 - boardW / 2
        let by = sg.y - 2 * s, boardH = sh + 5 * sub + 7 * s
        let roof = by + boardH + 4 * s
        let x0 = Int(Double(c.w) * 0.33), x1 = Int(Double(c.w) * 0.67)
        // the block
        c.rect(x0, roof, x1 - x0, g - roof, C(0x18221E))
        c.rect(x0, roof, x1 - x0, s, C(0x3A4A40))
        c.rect(x0, roof + s, x1 - x0, s, C(0x0E1410))
        for (j, y) in stride(from: roof + 4 * s, to: g - 4 * s, by: 5 * s).enumerated() {
            for (k, x) in stride(from: x0 + 3 * s, to: x1 - 4 * s, by: 7 * s).enumerated() {
                let lit = noise(j * 13 + k * 7 + 640) > 0.55
                c.rect(x, y, 4 * s, 3 * s, lit ? C(0x8AE05A, 0.38) : C(0x0E1612))
                c.rect(x, y + 3 * s, 4 * s, s, C(0x26302A))
            }
        }
        for x in [x0 + 2 * s, x1 - 4 * s] { c.rect(x, roof, 2 * s, g - roof, C(0x2A342E)) }   // corner downpipes
        // the sign's legs and lattice down to the roof
        for lx in [bx + 4 * s, bx + boardW - 5 * s, c.w / 2 - s] { c.rect(lx, by + boardH, s, roof - by - boardH, C(0x2A3230)) }
        for k in 0..<(roof - by - boardH) { c.px(bx + 4 * s + k * 2, by + boardH + k, C(0x2A3230)); c.px(bx + boardW - 5 * s - k * 2, by + boardH + k, C(0x2A3230)) }
        // the board, bulbs round its edge
        c.rect(bx, by, boardW, boardH, C(0x15181A))
        c.rect(bx, by, boardW, s, C(0x3A3E40)); c.rect(bx, by + boardH - s, boardW, s, C(0x3A3E40))
        c.rect(bx, by, s, boardH, C(0x3A3E40)); c.rect(bx + boardW - s, by, s, boardH, C(0x3A3E40))
        for x in stride(from: bx + 2 * s, to: bx + boardW - s, by: 3 * s) {
            c.rect(x, by, s, s, C(0xF0E0A0, 0.7)); c.rect(x, by + boardH - s, s, s, C(0xF0E0A0, 0.7))
        }
        s6Text(c, sg.x, sg.y, "ACE", C(0x4A1612), k: sg.k)                       // unlit tubes; lit in the moving layer
        let cy = sg.y + sh + 2 * s
        c.rect(c.w / 2 - subW / 2 - s, cy - s, subW + 2 * s, 7 * sub, C(0x5AE02A, 0.08))
        s6Text(c, c.w / 2 - subW / 2, cy, "CHEMICALS", C(0x7AE05A), k: sub)
    }

    /// The pipe run along the back, with flanges, vents and drops feeding the vats.
    static func acePipes(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), py = acePipeRow(c, g), th = 3 * s
        c.rect(0, py + 5 * s, c.w, 2 * s, C(0x2A322C)); c.rect(0, py + 5 * s, c.w, max(1, s / 2), C(0x5A6658))
        c.rect(0, py, c.w, th, C(0x3A443C)); c.rect(0, py, c.w, s, C(0x7A8A78)); c.rect(0, py + th - s, c.w, s, C(0x1E2620))
        for x in stride(from: 6 * s, to: c.w, by: 24 * s) { c.rect(x, py - s, 2 * s, th + 2 * s, C(0x4E5A50)) }
        for v in aceVents(c, g) {
            c.rect(v.x, v.y + s, 2 * s, py - v.y - s, C(0x3A443C)); c.rect(v.x, v.y + s, s, py - v.y - s, C(0x6A7A68))
            c.rect(v.x - s, v.y, 4 * s, s, C(0x5A665A))
        }
        for v in aceVats(c, g) {
            let x = v.x + v.w * 3 / 4
            c.rect(x, py + th, 2 * s, max(0, v.top - py - th - 2 * s), C(0x323C34))
            c.rect(x, py + th, s, max(0, v.top - py - th - 2 * s), C(0x5A6A58))
            c.rect(x - s, v.top - 3 * s, 4 * s, s, C(0x4A564C))
        }
    }

    /// One open vat of acid: a banded steel drum, its rim, the glowing surface and drips down the side.
    static func aceVat(_ c: PixelCanvas, _ g: Int, _ v: (x: Int, w: Int, top: Int)) {
        let s = unit(g), ry = max(2 * s, v.w / 9), cx = v.x + v.w / 2
        c.ellipse(cx, v.top - ry, v.w * 2 / 3, ry * 3, C(0x5AE02A, 0.07))
        for k in 0..<v.w {
            let u = Double(k) / Double(v.w)
            let shade = u < 0.15 ? 0.7 : (u < 0.3 ? 0.9 : (u > 0.78 ? 0.0 : 0.4))
            c.rect(v.x + k, v.top, 1, g - v.top, lerp(C(0x1A221C), C(0x4E5E50), shade))
        }
        for y in stride(from: v.top + ry + 4 * s, to: g, by: 7 * s) {
            c.rect(v.x, y, v.w, s, C(0x141A16))
            for x in stride(from: v.x + 2 * s, to: v.x + v.w - s, by: 5 * s) { c.px(x, y + s, C(0x7A8A78)) }
        }
        c.ellipse(cx, v.top, v.w / 2 + s, ry + s, C(0x6A7A68))
        c.ellipse(cx, v.top, v.w / 2 - s, max(1, ry - s / 2), C(0x34B020))
        c.ellipse(cx, v.top + ry / 4, v.w / 2 - 2 * s, max(1, ry / 2), C(0x4ACF2A))
        c.ellipse(cx - v.w / 8, v.top - ry / 3, v.w / 5, max(1, ry / 4), C(0x9AFF5A))
        for k in 0..<3 {                                        // drips over the rim
            let dx = v.x + 3 * s + Int(noise(v.x + k * 13) * Double(v.w - 6 * s))
            c.rect(dx, v.top + ry, s, (3 + Int(noise(v.x + k * 7) * 7)) * s, C(0x5AE02A, 0.75))
        }
        // a hazard diamond
        let hy = v.top + ry + 8 * s
        if hy + 6 * s < g - 10 * s {
            for k in 0...3 { c.rect(cx - k * s, hy + k * s, (2 * k + 1) * s, s, C(0xD8B020)); c.rect(cx - k * s, hy + (6 - k) * s, (2 * k + 1) * s, s, C(0xD8B020)) }
            c.rect(cx, hy + 2 * s, s, 2 * s, C(0x16140E)); c.rect(cx, hy + 5 * s, s, s, C(0x16140E))
        }
    }

    /// The upper sky on a tall canvas: smog, and the Bat-Signal thrown on the clouds from across the city.
    static func aceHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for i in 0..<7 {
            wisp(c, Int(noise(i * 5 + 620) * Double(c.w)), g / 12 + Int(noise(i * 5 + 621) * Double(g / 3)),
                 (40 + Int(noise(i * 5 + 622) * 70)) * s, C(0x24342C, 0.55), s: 2 * s)
        }
        let bx = Int(Double(c.w) * 0.2), by = g / 9, br = max(10, g / 14)
        let x0 = Double(c.w) * 0.06, y0 = Double(g) * 0.72
        for y in by..<Int(y0) {
            let u = Double(y - by) / (y0 - Double(by))
            let cx = Double(bx) + (x0 - Double(bx)) * u, half = Double(br) * (1 - u) * 0.9 + 2
            c.rect(Int(cx - half), y, Int(half * 2), 1, C(0xE8E0A0, 0.06))
        }
        c.ellipse(bx, by, br * 3 / 2 + 2 * s, br + 2 * s, C(0xF0E8A8, 0.12))
        c.ellipse(bx, by, br * 3 / 2, br, C(0xF0E8A8, 0.42))
        let k = max(1, br / 6)
        s6Stamp(c, bx - 11 * k / 2, by - 3 * k, [
            "#.........#",
            "##..#.#..##",
            "###.###.###",
            "###########",
            ".#########.",
            "...##.##...",
        ], ["#": C(0x0A0C10, 0.85)], s: k)
    }

    /// A gantry catwalk high across the plant on a tall canvas, with caged lamps hanging under it.
    static func aceHighCatwalk(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), y = Int(Double(g) * 0.52)
        c.rect(0, y, c.w, 2 * s, C(0x3A443C)); c.rect(0, y, c.w, s, C(0x7A8A78))
        for x in stride(from: 0, to: c.w, by: 8 * s) {                    // the truss under it
            for k in 0..<(4 * s) { c.px(x + k, y + 2 * s + k, C(0x2A322C)); c.px(x + 8 * s - k, y + 2 * s + k, C(0x2A322C)) }
        }
        c.rect(0, y + 6 * s, c.w, s, C(0x2A322C))
        c.rect(0, y - 6 * s, c.w, s, C(0xC8A030))
        for x in stride(from: 2 * s, to: c.w, by: 12 * s) { c.rect(x, y - 6 * s, s, 6 * s, C(0x4A5248)) }
        for x in stride(from: 30 * s, to: c.w, by: 70 * s) {
            c.rect(x, y + 7 * s, s, 4 * s, C(0x2A322C))
            c.rect(x - s, y + 11 * s, 3 * s, 2 * s, C(0xF0E8B0))
            for k in 0..<(18 * s) { c.rect(x - k / 3, y + 13 * s + k, 1 + 2 * (k / 3), 1, C(0xF0E8B0, 0.05)) }
        }
        for x in [Int(Double(c.w) * 0.2), Int(Double(c.w) * 0.8)] {         // the legs down to the vats
            c.rect(x, y + 2 * s, 3 * s, acePipeRow(c, g) - y - 2 * s, C(0x2A322C))
        }
    }

    /// The acid bubbling and popping in the vats, steam puffing from the vents, and the "ACE" sign buzzing on, its E
    /// sputtering and now and then the whole sign dropping out.
    static func aceChemicalsLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c)
        let splash: [(Int, Int)] = [(-2, 0), (2, 0), (0, -2), (-1, -1), (1, -1)]
        for (j, v) in aceVats(c, g).enumerated() {
            let ry = max(2 * s, v.w / 9)
            for k in 0..<4 {
                let seed = j * 40 + k * 7
                let period = 1.3 + noise(seed) * 1.2, off = noise(seed + 1) * period
                let p = s6Phase(t, period, offset: off), cycle = Int(floor((t + off) / period))
                let bx = v.x + v.w / 2 + Int((noise(seed + cycle * 3 + 2) - 0.5) * Double(v.w - 12 * s))
                let by = v.top + Int((noise(seed + cycle * 3 + 3) - 0.5) * Double(ry))
                if p < 0.7 {
                    let r = Int(p / 0.7 * 2.2 * Double(s))
                    c.circle(bx, by - r, r, C(0x8AFF4A))
                    c.px(bx - r / 2, by - r - r / 2, C(0xE0FFC0))
                } else if p < 0.85 {
                    for d in splash { c.rect(bx + d.0 * s, by - s + d.1 * s, s, s, C(0xB8FF8A, 0.85)) }
                }
            }
        }
        let rise = Double(tall ? g / 6 : 24 * s)
        for (j, v) in aceVents(c, g).enumerated() {
            for k in 0..<4 {
                let p = s6Phase(t, 2.6, offset: Double(k) * 0.65 + Double(j) * 0.37)
                let r = Int((1.5 + p * 4) * Double(s))
                let x = v.x + s + Int(sin(p * 5 + Double(j)) * 2 * Double(s) + p * 8 * Double(s))
                let y = v.y - Int(p * rise)
                c.circle(x, y, r, C(0xD0DAD0, 0.3 * (1 - p)))
            }
        }
        let sg = aceSign(c, g)
        let blackout = noise(Int(t * 6) + 900) > 0.95
        for (i, ch) in "ACE".enumerated() {
            let off = blackout || (i == 2 && noise(Int(t * 9) + 300) > 0.68)
            guard !off else { continue }
            let lx = sg.x + i * 4 * sg.k
            c.rect(lx - sg.k, sg.y - sg.k, 5 * sg.k, 7 * sg.k, C(0xFF4A3A, 0.10))
            s6Text(c, lx, sg.y, String(ch), C(0xFF5038), k: sg.k)
        }
    }
}

// MARK: - LexCorp Tower

extension Scenes {
    /// Where the glass wall runs, between the two wall panels.
    static func lexFrame(_ c: PixelCanvas, _ g: Int) -> (l: Int, r: Int) {
        let s = unit(g)
        return (max(72 * s, c.w / 6), c.w - max(72 * s, c.w / 6))
    }

    /// The horizon behind the glass.
    static func lexHorizon(_ c: PixelCanvas, _ g: Int) -> Int { g - (isTall(c) ? g / 5 : 14 * unit(g)) }

    /// Metropolis below: a hazy far row and a nearer, darker row of buildings, as (x, top, width).
    static func lexBlocks(_ c: PixelCanvas, _ g: Int, near: Bool) -> [(x: Int, y: Int, w: Int)] {
        let s = unit(g), f = lexFrame(c, g), hz = lexHorizon(c, g)
        let seed = near ? 660 : 630
        let m = isTall(c) ? 0.6 : 1.0, lo = (near ? 0.02 : 0.2) * m, hi = (near ? 0.3 : 0.55) * m
        var out: [(x: Int, y: Int, w: Int)] = []
        var x = f.l - 8 * s, i = 0
        while x < f.r + 8 * s {
            let bw = ((near ? 9 : 6) + Int(noise(i * 5 + seed) * 12)) * s
            let top = hz - Int(Double(g) * (lo + noise(i * 5 + seed + 1) * (hi - lo)))
            out.append((x, top, bw))
            x += bw + Int(noise(i * 5 + seed + 2) * 3) * s
            i += 1
        }
        return out
    }

    /// LexCorp Tower's executive top floor at dusk: a wall of glass looks out over Metropolis under a violet-to-amber
    /// sky, the Daily Planet's golden globe among the towers. On the left wall the green LexCorp badge and name, with
    /// Lex's sleek desk and tall chair; on the right wall a gilt-framed portrait of Lex himself, and before the glass a
    /// kryptonite sample glowing in a lit display case. Polished black marble underfoot.
    static func lexCorp(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = lexFrame(c, g), hz = lexHorizon(c, g)
        let ceil = tall ? g / 12 : 0
        c.gradient(0, hz * 3 / 5, C(0x1C1A46), C(0x9A4A72), bands: 6)
        c.gradient(hz * 3 / 5, g, C(0xC86A62), C(0xFFC47A), bands: 5)
        if tall { c.stars(ceil, g / 4, density: 90, seed: 62) }
        let sx = Int(Double(c.w) * 0.42), sy = hz - Int(Double(g) * (tall ? 0.42 : 0.6)), sr = max(4, g / (tall ? 18 : 13))
        c.circle(sx, sy, sr * 2, C(0xFFD890, 0.10)); c.circle(sx, sy, sr + 2 * s, C(0xFFE0A0, 0.18)); c.circle(sx, sy, sr, C(0xFFEAB8))
        for i in 0..<(tall ? 8 : 4) {
            let y = tall ? g / 6 + Int(noise(i * 3 + 650) * Double(g / 2)) : 6 * s + Int(noise(i * 3 + 650) * Double(hz / 2))
            wisp(c, f.l + Int(noise(i * 3 + 651) * Double(f.r - f.l)), y, (30 + Int(noise(i * 3 + 652) * 40)) * s, C(0xF0A890, 0.45), s: s)
        }
        // the city: far row, the Daily Planet, near row
        for b in lexBlocks(c, g, near: false) { lexBuilding(c, b, C(0x6A4272), lit: 0.4, seed: 1) }
        let dx = Int(Double(c.w) * 0.6), dw = 16 * s, dt = hz - Int(Double(g) * (tall ? 0.34 : 0.5))
        c.rect(dx - dw / 2, dt, dw, g - dt, C(0x523462))
        c.rect(dx - dw / 2 + 2 * s, dt - 3 * s, dw - 4 * s, 3 * s, C(0x523462))
        let gr = max(4 * s, g / (tall ? 22 : 14)), gy = dt - 3 * s - gr
        c.circle(dx, gy, gr + s, C(0xFFD070, 0.25))
        c.circle(dx, gy, gr, C(0xE8B04A)); c.circle(dx - gr / 3, gy - gr / 3, gr / 2, C(0xF8D47A))
        c.rect(dx - gr, gy, gr * 2 + 1, max(1, s), C(0xB07A2A)); c.rect(dx - s / 2, gy - gr, max(1, s), gr * 2, C(0xB07A2A))
        c.rect(dx - gr - 2 * s, gy + gr / 3, gr * 2 + 4 * s, max(1, s), C(0xF8D47A))
        for b in lexBlocks(c, g, near: true) { lexBuilding(c, b, C(0x2C2244), lit: 0.75, seed: 2) }
        // tinted lower glass, calm behind the crew
        c.rect(f.l, hz - 4 * s, f.r - f.l, g - hz + 4 * s, C(0x0C0A1C, 0.35))
        // the mullions and reflections in the glass
        let n = max(3, (f.r - f.l) / (64 * s))
        for k in 0...n {
            let x = f.l + k * (f.r - f.l) / n
            c.rect(x - s, ceil, 2 * s, g - ceil, C(0x14141E)); c.rect(x - s, ceil, max(1, s / 2), g - ceil, C(0x5A5A78))
            if k < n {
                let px0 = x + (f.r - f.l) / n / 3
                for i in 0..<min(g - ceil, (f.r - f.l) / n) {
                    c.rect(px0 + i / 2, g - i - 1, 3 * s, 1, C(0xFFFFFF, 0.05))
                    c.rect(px0 + i / 2 + 6 * s, g - i - 1, s, 1, C(0xFFFFFF, 0.05))
                }
            }
        }
        c.rect(f.l, g - 2 * s, f.r - f.l, 2 * s, C(0x14141E))
        if tall {
            c.rect(0, 0, c.w, ceil, C(0x111320))
            c.rect(0, ceil - s, c.w, s, C(0x3A4058))
            for x in stride(from: 20 * s, to: c.w, by: 40 * s) {
                c.rect(x, ceil - 2 * s, 6 * s, s, C(0xFFF0D0))
                for k in 0..<(16 * s) { c.rect(x - k / 3, ceil + k, 6 * s + 2 * (k / 3), 1, C(0xFFF0D0, 0.025)) }
            }
        }
        lexWalls(c, g)
        lexDesk(c, g)
        lexCase(c, g)
        // polished black marble with the sunset in it
        c.ground(g, C(0x15161E), edge: C(0x8A90A8), speck: C(0x22242E), seed: 62)
        c.rect(f.l, g + s, f.r - f.l, max(1, (c.h - g) / 2), C(0xFFA070, 0.06))
        for k in 0...n { c.rect(f.l + k * (f.r - f.l) / n - s, g + s, 2 * s, c.h - g - s, C(0x0C0C14, 0.6)) }
        for x in stride(from: 0, to: c.w, by: 24 * s) { c.rect(x, g + s, max(1, s / 2), c.h - g, C(0x2A2C38)) }
    }

    /// One skyline building with a sunlit roof edge and a scatter of lit windows.
    static func lexBuilding(_ c: PixelCanvas, _ b: (x: Int, y: Int, w: Int), _ col: Px, lit: Double, seed: Int) {
        c.rect(b.x, b.y, b.w, c.h - b.y, col)
        c.rect(b.x, b.y, b.w, 1, lerp(col, C(0xFFB07A), 0.45))
        c.rect(b.x + b.w - 1, b.y, 1, c.h - b.y, lerp(col, C(0xFFB07A), 0.2))
        let step = max(2, b.w / 5)
        for (j, wy) in stride(from: b.y + 2, to: c.h, by: 3).enumerated() {
            for (k, wx) in stride(from: b.x + 1, to: b.x + b.w - 1, by: step).enumerated()
            where noise(b.x * 31 + j * 7 + k * 13 + seed * 977) > 0.68 {
                c.px(wx, wy, C(0xFFD890, lit))
            }
        }
    }

    /// The two solid walls: the LexCorp badge and name on the left, Lex's portrait on the right.
    static func lexWalls(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = lexFrame(c, g)
        for (x0, x1) in [(0, f.l), (f.r, c.w)] {
            c.rect(x0, 0, x1 - x0, g, C(0x1C1E2A))
            for x in stride(from: x0 + 12 * s, to: x1 - 4 * s, by: 18 * s) { c.rect(x, 0, s, g, C(0x161822)) }
            c.rect(x0, g - 4 * s, x1 - x0, 4 * s, C(0x12131C)); c.rect(x0, g - 4 * s, x1 - x0, s, C(0x3A3E52))
        }
        c.rect(f.l - s, 0, s, g, C(0x4A4E66)); c.rect(f.r, 0, s, g, C(0x4A4E66))
        // the badge: a green square with the bold L, the name beneath
        let kb = tall ? 4 * s : 2 * s, kt = tall ? 2 * s : s
        let lw = s6TextWidth("LEXCORP", k: kt), bx = f.l / 2 - 9 * kb / 2
        let by = tall ? Int(Double(g) * 0.3) : 6 * s
        c.rect(bx - 2 * kb, by - 2 * kb, 13 * kb, 9 * kb + 11 * kt, C(0x5AE07A, 0.05))
        s6Stamp(c, bx, by, [
            "ggggggggg",
            "gwwgggggg",
            "gwwgggggg",
            "gwwgggggg",
            "gwwgggggg",
            "gwwgggggg",
            "gwwwwwwwg",
            "gwwwwwwwg",
            "ggggggggg",
        ], ["g": C(0x2AA85A), "w": C(0xF0F4F8)], s: kb)
        c.rect(bx, by, 9 * kb, max(1, s), C(0x7AE89A))
        s6Text(c, f.l / 2 - lw / 2, by + 9 * kb + 3 * kt, "LEXCORP", C(0xC8D0DC), k: kt)
        // the portrait
        let pk = tall ? 4 * s : 2 * s, pw = 16 * pk, ph = 20 * pk
        let px0 = (f.r + c.w) / 2 - pw / 2, py0 = tall ? Int(Double(g) * 0.26) : 5 * s
        c.rect(px0 - 3 * s, py0 - 6 * s, pw + 6 * s, s, C(0x8A8070))            // the picture light
        c.rect(px0, py0 - 5 * s, pw, ph / 3, C(0xFFF0C8, 0.06))
        c.rect(px0 - 2 * s, py0 - 2 * s, pw + 4 * s, ph + 4 * s, C(0xC8963A))
        c.rect(px0 - s, py0 - s, pw + 2 * s, ph + 2 * s, C(0x7A5A22))
        s6Stamp(c, px0, py0, [
            "bbbbbbbbbbbbbbbb",
            "bbbbbbbbbbbbbbbb",
            "bbbbbhkkkkkbbbbb",
            "bbbbhkkkkkkkbbbb",
            "bbbhkkkkkkkkdbbb",
            "bbbkkkkkkkkkdbbb",
            "bbbkeeekkeeedbbb",
            "bbbkkekkkkekdbbb",
            "bbdkkkkddkkkkdbb",
            "bbbkkkkkdkkkdbbb",
            "bbbkkkkkkkkkdbbb",
            "bbbbkkmmmmkdbbbb",
            "bbbbbkkkkkdbbbbb",
            "bbbbbbdkkdbbbbbb",
            "bbsssswwwwssssbb",
            "bssssswttwsssssb",
            "sssssswttwssssss",
            "sssssssttsssssss",
            "sssssssttsssssss",
            "ssssssssssssssss",
        ], ["b": C(0x1E3A2C), "k": C(0xE8C0A0), "d": C(0xB88A70), "h": C(0xFFF0DC), "e": C(0x2A1A1A),
            "m": C(0x8A4A40), "s": C(0x3A2A5A), "w": C(0xE8E8F0), "t": C(0x4ACF6A)], s: pk)
        c.rect(px0 + pw / 2 - 4 * s, py0 + ph + 3 * s, 8 * s, 2 * s, C(0xC8963A))       // the brass plate
    }

    /// Lex's desk on the left, a slab of black glass with a tall chair behind it.
    static func lexDesk(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = lexFrame(c, g), x = f.l + 10 * s, w = 40 * s, top = g - 11 * s
        c.rect(x + w / 2 - 5 * s, top - 12 * s, 10 * s, 16 * s, C(0x2A1A1E)); c.rect(x + w / 2 - 5 * s, top - 12 * s, 10 * s, s, C(0x5A3A40))
        c.rect(x, top, w, 2 * s, C(0x0C0C12)); c.rect(x, top, w, s, C(0x8A92B0))
        c.rect(x + 2 * s, top + 2 * s, 3 * s, g - top - 2 * s, C(0x12121A)); c.rect(x + w - 5 * s, top + 2 * s, 3 * s, g - top - 2 * s, C(0x12121A))
        c.rect(x + 6 * s, top - 4 * s, 6 * s, 4 * s, C(0x1A1E2A)); c.rect(x + 7 * s, top - 3 * s, 4 * s, 2 * s, C(0x5AC8F0, 0.7))   // a screen
        c.rect(x + w - 10 * s, top - 2 * s, 4 * s, 2 * s, C(0xC8B080))                                                          // a decanter
    }

    /// Where the kryptonite sits: the display case's centre column and the crystal's row.
    static func lexCaseSpot(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, k: Int) {
        let s = unit(g), f = lexFrame(c, g), k = isTall(c) ? 2 * s : s
        return (f.r - 26 * s, g - 15 * k - 3 * k, k)
    }

    /// The kryptonite sample on its pedestal under a glass case.
    static func lexCase(_ c: PixelCanvas, _ g: Int) {
        let p = lexCaseSpot(c, g), k = p.k
        c.rect(p.x - 4 * k, g - 13 * k, 8 * k, 13 * k, C(0x22242E)); c.rect(p.x - 5 * k, g - 13 * k, 10 * k, k, C(0x8A92A8))
        c.rect(p.x - 3 * k, g - 11 * k, k, 10 * k, C(0x3A3E4E))
        c.circle(p.x, p.y + 3 * k, 7 * k, C(0x5AFF6A, 0.08))
        s6Stamp(c, p.x - 4 * k, p.y, [
            "...h.....",
            "..hg..h..",
            "..ggg.g..",
            ".gggg.gh.",
            ".ggggggg.",
            "ddddddddd",
        ], ["g": C(0x3AE05A), "h": C(0xB8FFC0), "d": C(0x2A3A2E)], s: k)
        c.rect(p.x - 6 * k, p.y - 6 * k, 12 * k, 12 * k, C(0xB8E0F0, 0.12))
        c.rect(p.x - 6 * k, p.y - 6 * k, 12 * k, k, C(0xD8F0FF, 0.6)); c.rect(p.x - 6 * k, p.y - 6 * k, k, 12 * k, C(0xD8F0FF, 0.4))
        c.rect(p.x + 5 * k, p.y - 6 * k, k, 12 * k, C(0xD8F0FF, 0.3))
    }

    /// The kryptonite's glow breathing, windows coming and going across Metropolis, and a LexCorp helicopter crossing
    /// behind the glass, rotor flickering and beacon blinking.
    static func lexCorpLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = lexFrame(c, g), hz = lexHorizon(c, g)
        let p = lexCaseSpot(c, g), k = p.k
        let pulse = 0.5 + 0.5 * sin(t * 2.2)
        c.circle(p.x, p.y + 3 * k, Int(Double(5 * k) + pulse * Double(3 * k)), C(0x5AFF6A, 0.08 + pulse * 0.08))
        c.circle(p.x, p.y + 3 * k, 3 * k, C(0x9AFFA0, 0.1 + pulse * 0.12))
        if s6Phase(t, 1.7) < 0.25 { c.rect(p.x - 2 * k, p.y + k, k, k, C(0xF0FFF0)) }
        let near = lexBlocks(c, g, near: true).filter { $0.x > f.l && $0.x + $0.w < f.r }
        if !near.isEmpty {
            for i in 0..<max(8, c.w / 30) {
                let b = near[Int(noise(i * 13 + 5) * Double(near.count)) % near.count]
                let wx = b.x + 1 + Int(noise(i * 13 + 6) * Double(max(1, b.w - 2)))
                let wy = b.y + 2 + Int(noise(i * 13 + 7) * Double(max(1, min(g - 4 * s, hz) - b.y - 4))) / 3 * 3
                if noise(Int(t * 0.7 + noise(i) * 7) * 31 + i) > 0.45 { c.px(wx, wy, C(0xFFE0A0, 0.85)) }
            }
        }
        let speed = 22.0 * Double(s), span = Double(f.r - f.l + 40 * s), cycle = span / speed + 8
        let ph = (t + 3).truncatingRemainder(dividingBy: cycle)
        guard ph < span / speed else { return }
        let x = f.r + 10 * s - Int(ph * speed), y = hz - Int(Double(g) * 0.62) + Int(sin(ph * 1.3) * Double(s))
        let clip = f.l...(f.r - 1)
        s6Stamp(c, x, y, [
            "..rrrrrrrrrrr...",
            ".......m........",
            "..cbbbbb........",
            ".cbbbbbbbbbbbbbt",
            "..bbbbbb.....t..",
            "...l..l.........",
        ], ["b": C(0x2A2A3A), "c": C(0xF0C890), "m": C(0x4A4A5A), "t": C(0x2A2A3A), "l": C(0x4A4A5A),
            "r": s6Phase(t, 0.12) < 0.5 ? C(0x8A8AA0, 0.7) : C(0x8A8AA0, 0.2)], s: s, clip: clip)
        if s6Phase(t, 0.9) < 0.3, x + 15 * s < f.r, x + 15 * s > f.l { c.rect(x + 15 * s, y + 2 * s, s, s, C(0xFF4A4A)) }
    }
}

// MARK: - Louisiana Bayou

extension Scenes {
    /// The far shore, where the open water begins.
    static func bayouWaterline(_ c: PixelCanvas, _ g: Int) -> Int { g - (isTall(c) ? g / 4 : 16 * unit(g)) }

    /// The near cypress trees: trunk centre, trunk width and where it meets the water.
    static func bayouTrees(_ c: PixelCanvas, _ g: Int) -> [(x: Int, w: Int, base: Int)] {
        let s = unit(g), wl = bayouWaterline(c, g)
        let spots: [Double] = [0.04, 0.19, 0.35, 0.69, 0.86]
        return spots.enumerated().map { (i: Int, f: Double) -> (x: Int, w: Int, base: Int) in
            let w = (5 + Int(noise(i * 3 + 670) * 4)) * s * (isTall(c) ? 2 : 1)
            return (Int(Double(c.w) * f), w, wl + Int(Double(g - wl) * (0.35 + noise(i * 3 + 671) * 0.5)))
        }
    }

    /// Swamp Thing's spot among the trees: left edge, top row and pixel size.
    static func bayouSwampThing(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, k: Int) {
        let s = unit(g), k = isTall(c) ? 3 * s : s, wl = bayouWaterline(c, g)
        return (Int(Double(c.w) * 0.79), wl + 3 * k - 13 * k, k)
    }

    /// The Louisiana bayou at dusk, Swamp Thing's swamp: a big low moon in the haze over still black water, the far
    /// tree line and a fisherman's shack on stilts with a lit window, bald cypresses rising out of the water with their
    /// flared trunks, knees and veils of Spanish moss, lily pads, a great blue heron in the shallows, and Swamp Thing
    /// himself, a mossy hulk half-hidden among the trunks. The crew stands on the muddy bank among the reeds.
    static func bayou(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), wl = bayouWaterline(c, g)
        c.gradient(0, wl * 2 / 3, C(0x0A121E), C(0x2E3E44), bands: 6)
        c.gradient(wl * 2 / 3, wl, C(0x3E4A44), C(0x8A7A52), bands: 4)
        c.stars(0, wl / 2, density: tall ? 80 : 70, seed: 63)
        let mx = Int(Double(c.w) * 0.56), my = wl - (tall ? g / 4 : 22 * s), mr = max(7, g / (tall ? 14 : 9))
        c.circle(mx, my, mr * 2, C(0xE8D8A0, 0.06)); c.circle(mx, my, mr + 3 * s, C(0xE8D8A0, 0.10))
        c.circle(mx, my, mr, C(0xF0E2B0))
        c.circle(mx + mr / 3, my - mr / 4, max(1, mr / 4), C(0xDCCC98)); c.circle(mx - mr / 3, my + mr / 3, max(1, mr / 5), C(0xE0D0A0))
        if tall { bayouCanopy(c, g) }
        for i in 0..<(tall ? 8 : 4) {
            wisp(c, Int(noise(i * 4 + 680) * Double(c.w)), wl - 6 * s - Int(noise(i * 4 + 681) * Double(wl / 3)),
                 (40 + Int(noise(i * 4 + 682) * 50)) * s, C(0x9AA08A, 0.18), s: s)
        }
        // the far tree line
        for x in 0..<c.w {
            let fx = Double(x)
            let h = 5 * s + Int((abs(sin(fx * 0.07)) * 0.6 + abs(sin(fx * 0.19 + 1)) * 0.4) * Double(9 * s)) + Int(noise(x + 690) * 2)
            c.rect(x, wl - h, 1, h, C(0x1A2A24))
        }
        // the shack on stilts
        let q = tall ? 2 * s : s, hx = Int(Double(c.w) * 0.27), hy = wl - 9 * q
        for k in 0..<3 { c.rect(hx + k * 6 * q, hy + 6 * q, s, 5 * q, C(0x1A1A14)) }
        c.rect(hx - s, hy, 15 * q, 6 * q, C(0x221E18))
        for k in 0..<5 { c.rect(hx - 2 * q + k, hy - 1 - k / 2, 17 * q - 2 * k, 1, C(0x2A241C)) }
        c.rect(hx + 3 * q, hy + 2 * q, 3 * q, 2 * q, C(0xFFC86A)); c.circle(hx + 4 * q, hy + 3 * q, 4 * q, C(0xFFC86A, 0.08))
        // the still water with the sky, the moon and the shack in it
        c.rect(0, wl, c.w, g - wl, C(0x0C1614))
        for (j, y) in stride(from: wl + s, to: g, by: 2 * s).enumerated() {
            for x in stride(from: Int(noise(j + 700) * 12), to: c.w, by: 17 * s) where noise(x * 3 + j) > 0.5 {
                c.rect(x, y, (3 + Int(noise(x + j * 7) * 8)) * s, max(1, s / 2), C(0x3A4A44, 0.6))
            }
            let half = Int(Double(mr) * (0.8 - Double(j) * 0.06) + noise(j + 710) * 3)
            if half > 0 { c.rect(mx - half, y, half * 2, max(1, s / 2), C(0xF0E2B0, 0.5)) }
        }
        c.rect(hx + 3 * q, wl + 4 * q, 3 * q, q, C(0xFFC86A, 0.35))
        // lily pads
        for i in 0..<(c.w / 30) {
            let x = Int(noise(i * 3 + 720) * Double(c.w)), y = wl + 2 * s + Int(noise(i * 3 + 721) * Double(g - wl - 4 * s))
            c.ellipse(x, y, 3 * s, max(1, s), C(0x2A4A24)); c.px(x + s, y, C(0x0C1614))
            if noise(i * 3 + 722) > 0.7 { c.rect(x - s, y - s, 2 * s, s, C(0xF0E0E8)) }
        }
        // Swamp Thing among the trunks, wading
        let st = bayouSwampThing(c, g)
        s6Stamp(c, st.x, st.y, [
            "....mmmm....",
            "...mmmmmm...",
            "...mmeemm...",
            "...mlmmlm...",
            ".mmmmmmmmmm.",
            "mmlmmmmmmlmm",
            "mmmmmmmmmmmm",
            "mm.mmlmmm.mm",
            "mm.mmmmmm.mm",
            "ml.mmmmlm.lm",
            "m..mmmmmm..m",
            "l..mmmmmm..l",
            "...mmmmmm...",
        ], ["m": C(0x1A2E1E), "l": C(0x3A5A30), "e": C(0x0A0E0A)], s: st.k)
        c.rect(st.x - 2 * st.k, wl + 3 * st.k, 16 * st.k, max(1, st.k), C(0x4A5A4A, 0.6))
        for tr in bayouTrees(c, g) { bayouCypress(c, g, tr) }
        // the heron in the shallows
        let hk = tall ? 2 * s : s, hxx = c.w - 34 * s, hyy = g - 17 * hk
        s6Stamp(c, hxx, hyy, [
            "..kkh.....",
            "yyhhh.....",
            "...hh.....",
            "....h.....",
            "....hh....",
            ".....h....",
            ".....hh...",
            "....gggg..",
            "...gggggg.",
            "...ggggggg",
            "....ggggg.",
            ".....gg.gg",
            ".....l.l..",
            ".....l.l..",
            ".....l.l..",
            ".....l.l..",
            "....ll.ll.",
        ], ["h": C(0xC8D0D8), "k": C(0x1A1E24), "y": C(0xD8B040), "g": C(0x6A7A90), "l": C(0x8A7A5A)], s: hk)
        // the muddy bank, reeds and cattails
        c.ground(g, C(0x221E14), edge: C(0x4A5A2A), speck: C(0x2E2A1C), seed: 63)
        for i in 0..<(c.w / 7) {
            let x = Int(noise(i * 3 + 730) * Double(c.w)), h = (3 + Int(noise(i * 3 + 731) * 7)) * s
            let lean = noise(i * 3 + 732) > 0.5 ? 1 : -1
            for k in 0..<h { c.px(x + (k > h / 2 ? lean : 0), g - k, C(0x4A5A2A)) }
            if h > 7 * s { c.rect(x + lean, g - h - 2 * s, s, 3 * s, C(0x5A3A1E)) }
        }
    }

    /// One bald cypress: flared trunk standing in the water, its dark reflection, knees, branches, a flat crown and
    /// veils of Spanish moss.
    static func bayouCypress(_ c: PixelCanvas, _ g: Int, _ tr: (x: Int, w: Int, base: Int)) {
        let s = unit(g), tall = isTall(c)
        let crown = tall ? Int(Double(g) * 0.12) + Int(noise(tr.x + 740) * Double(g / 10)) : Int(noise(tr.x + 740) * 6) * s
        for y in max(0, crown)..<tr.base {
            let flare = max(0, y - (tr.base - 12 * s)) / 2
            let half = tr.w / 2 + flare
            c.rect(tr.x - half, y, half * 2, 1, C(0x2A241C))
            c.rect(tr.x - half, y, max(1, s), 1, C(0x4A4030))
            c.rect(tr.x + half - s, y, s, 1, C(0x18140E))
            if noise(y * 7 + tr.x) > 0.85 { c.px(tr.x - half / 2 + Int(noise(y + tr.x) * Double(max(1, half))), y, C(0x3A3226)) }
        }
        for y in tr.base..<g where (y - tr.base) % (2 * s) == 0 {
            let half = tr.w / 2 + 6 * s - (y - tr.base) / 3
            if half > 0 { c.rect(tr.x - half, y, half * 2, s, C(0x16140E, 0.7)) }
        }
        for k in 0..<3 {                                        // knees poking out of the water
            let kx = tr.x + Int((noise(tr.x + k * 5 + 750) - 0.5) * Double(tr.w * 5)), kh = (2 + k) * s
            for r in 0..<kh { c.rect(kx - (kh - r) / 3, tr.base - kh + r + 2 * s, 2 * ((kh - r) / 3) + s, 1, C(0x2E281E)) }
        }
        // branches and the flat crown, with moss hanging
        let crownY = max(-4 * s, crown), m = tall ? 2 : 1
        let reach = tr.w * 3 + 10 * s * m
        let arms: [Double] = [-1, -0.45, 0.4, 1]
        for (i, a) in arms.enumerated() {
            let ax = tr.x + Int(a * Double(reach)), ay = crownY + 6 * s + i % 2 * 4 * s
            let steps = abs(ax - tr.x)
            for k in 0..<max(1, steps) {
                let u = Double(k) / Double(max(1, steps))
                c.rect(tr.x + (ax - tr.x) * k / max(1, steps), ay + 8 * s - Int(u * Double(8 * s)), s, s, C(0x241E16))
            }
            c.ellipse(ax, ay, (9 * s + Int(noise(i + tr.x) * 5) * s) * m, 3 * s * m, C(0x16261A))
            c.ellipse(ax - s, ay - s * m, 7 * s * m, 2 * s * m, C(0x22382A))
            for mm in 0..<(6 * m) {                                    // Spanish moss
                let mxx = ax - 8 * s * m + Int(noise(tr.x * 3 + i * 11 + mm) * Double(16 * s * m))
                let len = (4 + Int(noise(tr.x + i * 7 + mm * 3) * 12)) * s * m
                for k in 0..<len { c.px(mxx + (k / (3 * s)) % 2, ay + 2 * s + k, C(0x7A8A6A, 0.85 - Double(k) / Double(len) * 0.5)) }
            }
        }
        c.ellipse(tr.x, crownY + 2 * s, 12 * s * m, 4 * s * m, C(0x16261A)); c.ellipse(tr.x, crownY + s, 9 * s * m, 2 * s * m, C(0x22382A))
    }

    /// The overhanging canopy and its moss at the top of a tall canvas.
    static func bayouCanopy(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for x in 0..<c.w {
            let fx = Double(x)
            let d = Int((abs(sin(fx * 0.03)) * 0.6 + abs(sin(fx * 0.011 + 2)) * 0.4) * Double(g) * 0.1) + Int(noise(x + 760) * 3)
            c.rect(x, 0, 1, d, C(0x0E1A12))
            c.px(x, d, C(0x1E3020))
            if noise(x * 3 + 761) > 0.8 {
                let len = Int(noise(x * 3 + 762) * Double(g) * 0.12)
                for k in 0..<len { c.px(x + (k / (4 * s)) % 2, d + k, C(0x6A7A5A, 0.7 - Double(k) / Double(max(1, len)) * 0.6)) }
            }
        }
    }

    /// Fireflies drifting and blinking over the water, a few slow ripples, and Swamp Thing's red eyes in the dark.
    static func bayouLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), wl = bayouWaterline(c, g)
        let n = max(18, c.w * g / 1100)
        for i in 0..<n {
            let period = 2.2 + noise(i * 5 + 800) * 2
            let p = s6Phase(t, period, offset: noise(i * 5 + 801) * period)
            guard p < 0.45 else { continue }
            let bright = sin(p / 0.45 * Double.pi)
            let x = Int(noise(i * 5 + 802) * Double(c.w) + sin(t * 0.3 + Double(i)) * Double(14 * s))
            let y = Int(Double(g) * (0.3 + noise(i * 5 + 803) * 0.62)) + Int(sin(t * 0.7 + Double(i) * 2) * Double(5 * s))
            c.rect(x, y, s, s, C(0xE8FF7A, 0.4 + bright * 0.6))
            if bright > 0.5 {
                c.rect(x - s, y, s, s, C(0xC8FF5A, 0.3)); c.rect(x + s, y, s, s, C(0xC8FF5A, 0.3))
                c.rect(x, y - s, s, s, C(0xC8FF5A, 0.3)); c.rect(x, y + s, s, s, C(0xC8FF5A, 0.3))
            }
        }
        for i in 0..<3 {
            let p = s6Phase(t, 3.5, offset: Double(i) * 1.2)
            let x = Int(noise(i * 3 + 810 + Int((t + Double(i) * 1.2) / 3.5) * 7) * Double(c.w))
            let y = wl + 3 * s + Int(noise(i * 3 + 811) * Double(max(1, g - wl - 6 * s)))
            s6Ring(c, x, y, Int(2.0 + p * 12) * s, Int(1.0 + p * 3) * s, C(0x8A9A8A, 0.4 * (1 - p)), s: s)
        }
        let hk = isTall(c) ? 2 * s : s
        let hp = s6Phase(t, 5)
        s6Ring(c, c.w - 34 * s + 6 * hk, g - s, Int(2.0 + hp * 8) * s, Int(1.0 + hp * 2) * s, C(0x8A9A8A, 0.35 * (1 - hp)), s: s)
        let st = bayouSwampThing(c, g)
        if s6Phase(t, 4.3) > 0.06 {
            for ex in [st.x + 5 * st.k, st.x + 6 * st.k + max(1, st.k / 2)] {
                c.rect(ex, st.y + 2 * st.k, max(1, st.k * 2 / 3), max(1, st.k * 2 / 3), C(0xFF3A2A))
            }
            c.rect(st.x + 4 * st.k, st.y + st.k, 4 * st.k, 3 * st.k, C(0xFF3A2A, 0.12))
        }
    }
}

// MARK: - The Dreaming

extension Scenes {
    /// Where the dunes begin.
    static func dreamHorizon(_ c: PixelCanvas, _ g: Int) -> Int { g - (isTall(c) ? g / 6 : 13 * unit(g)) }

    /// Dream's castle: centre column, base row and the size of one unit.
    static func dreamCastleSpot(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, u: Int) {
        let tall = isTall(c), u = tall ? max(2, g / 95) : unit(g)
        return (Int(Double(c.w) * 0.68), dreamHorizon(c, g) - 3 * u, u)
    }

    /// The Dreaming, Morpheus's realm: a swirling indigo sky like brushstrokes, thick with stars, a great gold
    /// crescent and two stranger moons, and on its crag Dream's impossible castle, towers leaning every way, roofs like
    /// witches' hats, a stair climbing nowhere and the gate aglow. Silver-lilac sand dunes roll away, and a lone door
    /// stands in the sand with light behind it. On a tall canvas islands of rock float overhead and an upside-down
    /// tower hangs from one.
    static func theDreaming(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), hz = dreamHorizon(c, g)
        c.gradient(0, hz, C(0x0A0820), C(0x5A3A8A), bands: 7)
        for i in 0..<max(3, c.w / 100) {                          // swirling skies
            let cx = Int(noise(i * 5 + 820) * Double(c.w)), cy = Int(noise(i * 5 + 821) * Double(hz) * 0.75)
            let r = Double((10 + Int(noise(i * 5 + 822) * 18)) * s * (tall ? 2 : 1))
            let col = i % 2 == 0 ? C(0x8A7AE0, 0.22) : C(0x5AB8D0, 0.18)
            let steps = Int(r * 6)
            for k in 0..<steps {
                let u = Double(k) / Double(steps)
                let a: Double = u * 4.5 * Double.pi + Double(i)
                c.rect(cx + Int(cos(a) * r * u), cy + Int(sin(a) * r * u * 0.6), s, s, col)
            }
        }
        c.stars(0, hz, density: tall ? 55 : 36, seed: 64)
        for i in 0..<max(4, c.w / 70) {                           // big four-pointed stars
            let x = Int(noise(i * 3 + 830) * Double(c.w)), y = Int(noise(i * 3 + 831) * Double(hz) * 0.8)
            c.rect(x - s, y, 3 * s, s, C(0xF0E8FF, 0.8)); c.rect(x, y - s, s, 3 * s, C(0xF0E8FF, 0.8))
        }
        // the moons: a gold crescent, a pale teal one with a ring, a small rose one half in shadow
        let cr = max(9, g / (tall ? 9 : 6)), cmx = Int(Double(c.w) * 0.16), cmy = tall ? g / 5 : cr + 3 * s
        c.circle(cmx, cmy, cr + 4 * s, C(0xF0D890, 0.06))
        for dy in -cr...cr {
            for dx in -cr...cr where dx * dx + dy * dy <= cr * cr {
                let ox = dx - cr / 2, oy = dy + cr / 4
                if ox * ox + oy * oy > cr * cr * 7 / 10 { c.px(cmx + dx, cmy + dy, dx < -cr / 2 ? C(0xF8E4A0) : C(0xE8C870)) }
            }
        }
        let tr = max(5, cr / 2), tmx = Int(Double(c.w) * 0.88), tmy = tall ? g / 9 : tr + 4 * s
        c.circle(tmx, tmy, tr, C(0x8AD8D0)); c.circle(tmx - tr / 3, tmy - tr / 3, tr / 2, C(0xB8F0E8))
        c.circle(tmx + tr / 3, tmy + tr / 4, max(1, tr / 4), C(0x6AB8B0))
        c.rect(tmx - tr * 2, tmy + tr / 4, tr * 4, max(1, s), C(0xE0F0FF, 0.7))
        let rr = max(3, cr / 4), rmx = Int(Double(c.w) * 0.42), rmy = tall ? g / 3 : rr + 6 * s
        c.circle(rmx, rmy, rr, C(0xF0A0C0)); c.ellipse(rmx + rr / 2, rmy, rr / 2 + 1, rr, C(0x3A2858))
        if tall { dreamIslands(c, g) }
        dreamCastle(c, g)
        // dunes of dream sand
        c.dunes(base: hz, amp: 3 * Double(s), freq: 0.02 / Double(s), phase: 1.3, bottom: g, C(0x4A3A7A), shade: C(0x8A7AC0))
        c.dunes(base: hz + (g - hz) / 2, amp: 2 * Double(s), freq: 0.035 / Double(s), phase: 0.2, bottom: g, C(0x5E4C92), shade: C(0xA898D8))
        for i in 0..<(c.w * (g - hz) / 40) {
            c.px(Int(noise(i * 2 + 840) * Double(c.w)), hz + Int(noise(i * 2 + 841) * Double(g - hz)), C(0xE0D8FF, 0.5))
        }
        // the lone door standing in the sand
        let dk = tall ? 2 * s : s, dx = Int(Double(c.w) * 0.13), dw = 9 * dk, dh = 16 * dk, dy = g - dh
        c.ellipse(dx + dw, g, 12 * dk, 2 * dk, C(0xF0E0A0, 0.18))
        c.rect(dx - dk, dy - dk, dw + 2 * dk, dh + dk, C(0x3A2A4A))
        c.rect(dx, dy, dw, dh, C(0xFFF0C0))
        c.rect(dx, dy, dw, dh, C(0xF0D880, 0.4))
        for k in 0..<dh { c.rect(dx + dw - 1 + k / 6, dy + k, max(1, dw / 2 - k / 6), 1, C(0x6A4A3A)) }   // the door swung open
        c.rect(dx + dw + dw / 3, dy + dh / 2, dk, dk, C(0xE8C060))
        for k in 0..<(14 * dk) { c.rect(dx - k / 2, g - 1 - k / 6, dw + k, 1, C(0xFFF0C0, 0.05)) }
        c.ground(g, C(0x8A7AB0), edge: C(0xD8C8F0), speck: C(0xB0A0DA), seed: 64)
        for x in stride(from: 0, to: c.w, by: 9 * s) { c.rect(x + Int(noise(x + 850) * 5), g + 3 * s, 4 * s, s, C(0x7A6AA4)) }
    }

    /// The castle on its crag.
    static func dreamCastle(_ c: PixelCanvas, _ g: Int) {
        let p = dreamCastleSpot(c, g), u = p.u
        let body = C(0x1E1636), rim = C(0x8A7AD0), lit = C(0xC8D8FF)
        mesa(c, x: p.x - 34 * u, width: 68 * u, h: 8 * u, base: dreamHorizon(c, g) + 2 * u, C(0x2A2048), seed: 64)
        // dx, width, height, lean (units over the full height), roof height
        let towers: [(Int, Int, Int, Int, Int)] = [(-24, 6, 22, -4, 8), (-15, 7, 34, -1, 10), (-5, 9, 44, 2, 12),
                                                   (6, 7, 30, -3, 9), (14, 5, 40, 5, 11), (22, 6, 20, 1, 7)]
        for (i, tw) in towers.enumerated() {
            let w = tw.1 * u, h = tw.2 * u
            for k in 0..<h {
                let x = p.x + tw.0 * u + tw.3 * u * k / max(1, h)
                let y = p.y - k
                c.rect(x, y, w, 1, body)
                c.px(x + w - 1, y, rim.alpha(0.7))
                if k == h - 1 {
                    let rh = tw.4 * u
                    for r in 0..<rh {                             // a witch's-hat roof, its tip bent over
                        let half = (w / 2 + u) * (rh - r) / rh
                        let bend = r > rh * 3 / 4 ? (r - rh * 3 / 4) * (i % 2 == 0 ? 1 : -1) : 0
                        c.rect(x + w / 2 - half + bend, y - r, max(1, half * 2), 1, C(0x2A1E4A))
                        if half > u { c.px(x + w / 2 + half - 1, y - r, rim) }
                    }
                }
            }
            for (j, wy) in stride(from: p.y - 4 * u, to: p.y - h + 3 * u, by: -6 * u).enumerated()
            where noise(i * 17 + j + 860) > 0.4 {
                let k = p.y - wy
                c.rect(p.x + tw.0 * u + tw.3 * u * k / max(1, h) + w / 2 - u / 2, wy, max(1, u), 2 * u, lit)
            }
        }
        // bridges between towers and a stair climbing to nowhere
        c.rect(p.x - 15 * u, p.y - 22 * u, 20 * u, u, body); c.rect(p.x - 15 * u, p.y - 22 * u, 20 * u, max(1, u / 2), rim.alpha(0.5))
        c.rect(p.x + 4 * u, p.y - 16 * u, 14 * u, u, body)
        for k in 0..<10 { c.rect(p.x + 18 * u + k * 2 * u, p.y - 24 * u - k * 2 * u, 2 * u, u, rim.alpha(0.8)) }
        // the gate
        c.rect(p.x - 4 * u, p.y - 9 * u, 8 * u, 9 * u, C(0x2A1E4A))
        c.ellipse(p.x, p.y - 8 * u, 3 * u, 3 * u, C(0xFFE8A0, 0.9)); c.rect(p.x - 3 * u, p.y - 8 * u, 6 * u, 8 * u, C(0xFFE8A0, 0.9))
        c.circle(p.x, p.y - 5 * u, 7 * u, C(0xFFE8A0, 0.08))
    }

    /// Rocks floating in the upper sky of a tall canvas, one with a tower hanging upside down beneath it.
    static func dreamIslands(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let spots: [(Double, Double, Int)] = [(0.3, 0.42, 14), (0.52, 0.2, 24), (0.88, 0.4, 10)]
        for (i, sp) in spots.enumerated() {
            let x = Int(Double(c.w) * sp.0), y = Int(Double(g) * sp.1), r = sp.2 * s
            c.ellipse(x, y, r, max(1, r / 4), C(0x3A2E5E))
            for k in 0..<(r / 2) { c.rect(x - r + k * 2, y + k, 2 * (r - k * 2), 1, C(0x2A2048)) }
            c.rect(x - r, y - max(1, r / 4), r * 2, s, C(0x7A6AB8))
            c.rect(x - r / 3, y - r / 2, s, r / 4, C(0x2A2048)); c.circle(x - r / 3, y - r / 2, 2 * s, C(0x3A5A6A))
            if i == 1 {
                let w = 12 * s, h = 44 * s
                c.rect(x - w / 2, y + r / 2, w, h, C(0x1E1636)); c.rect(x + w / 2 - s, y + r / 2, s, h, C(0x8A7AD0, 0.7))
                for k in 0..<(10 * s) { c.rect(x - (w / 2 + s) * (10 * s - k) / (10 * s), y + r / 2 + h + k, max(1, 2 * (w / 2 + s) * (10 * s - k) / (10 * s)), 1, C(0x2A1E4A)) }
                for wy in stride(from: y + r / 2 + 4 * s, to: y + r / 2 + h - 2 * s, by: 7 * s) { c.rect(x - s, wy, 2 * s, 3 * s, C(0xC8D8FF)) }
            }
        }
    }

    /// Glittering sand blowing across in drifts, ravens flapping over, and the castle's windows going on and off.
    static func theDreamingLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c)
        let n = max(40, c.w / 5)
        for i in 0..<n {
            let speed = (14 + noise(i * 4 + 870) * 18) * Double(s)
            let x = Int(s6Wrap(noise(i * 4 + 871) * Double(c.w) + t * speed, Double(c.w)))
            let y0 = Double(g) - noise(i * 4 + 872) * Double(g) * (tall ? 0.35 : 0.7)
            let y = Int(y0 + sin(Double(x) * 0.04 / Double(s) + t * 1.5 + Double(i)) * Double(3 * s))
            let tw = s6Phase(t, 0.9, offset: noise(i * 4 + 873)) < 0.5
            c.rect(x, y, s, s, (i % 3 == 0 ? C(0xFFE8A0) : C(0xE8E0FF)).alpha(tw ? 0.9 : 0.45))
        }
        let k = tall ? 2 * s : s
        for r in 0..<2 {
            let speed = (16.0 + Double(r) * 6) * Double(s), span = Double(c.w + 40 * s), cycle = span / speed + 5
            let ph = (t + Double(r) * 7).truncatingRemainder(dividingBy: cycle)
            guard ph < span / speed else { continue }
            let x = -20 * s + Int(ph * speed), y = Int(Double(g) * (0.2 + Double(r) * 0.12)) + Int(sin(ph * 2) * Double(2 * s))
            let up = s6Phase(t, 0.5, offset: Double(r) * 0.2) < 0.5
            s6Stamp(c, x, y, up ? ["##.....##", "..##.##..", "....###b.", ".....#..."] : [".........", "....###b.", "..##.##..", "##.....##"],
                    ["#": C(0x08060E), "b": C(0x6A5A3A)], s: k)
        }
        let p = dreamCastleSpot(c, g)
        for i in 0..<4 where noise(Int(t * 0.8) * 13 + i) > 0.5 {
            let wx = p.x + Int((noise(i * 7 + 880) - 0.5) * Double(36 * p.u)), wy = p.y - (8 + Int(noise(i * 7 + 881) * 18)) * p.u
            c.rect(wx, wy, max(1, p.u), 2 * p.u, C(0xFFE8A0, 0.9))
        }
    }
}

// MARK: - Coast City

extension Scenes {
    /// The sea's horizon.
    static func coastHorizon(_ c: PixelCanvas, _ g: Int) -> Int { g - (isTall(c) ? g / 4 : 24 * unit(g)) }

    /// The Green Lantern memorial: centre column, the row its feet stand on and its pixel size.
    static func coastStatueSpot(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, k: Int) {
        let s = unit(g), tall = isTall(c)
        let k = tall ? max(3, Int(Double(g) * 0.5 / 26)) : 2 * s
        let plinth = tall ? 6 * k : 8 * s
        return (Int(Double(c.w) * 0.58), g - plinth, k)
    }

    /// Coast City on a bright day: a blue Pacific sky and sun, the sea on the left running to a strip of beach, a
    /// white-and-glass skyline with palms along the promenade, the giant Green Lantern memorial statue (Hal Jordan, arm
    /// raised high with his lantern) on its plinth, and on the right the curved hangar of Ferris Aircraft, red letters
    /// over its open doors, a jet nosing out. The crew stands on the seafront promenade.
    static func coastCity(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), hz = coastHorizon(c, g)
        c.gradient(0, hz, C(0x2A78D8), C(0xBCE2F8), bands: 6)
        let sx = Int(Double(c.w) * 0.08), sy = tall ? g / 8 : 9 * s, sr = max(5, g / (tall ? 20 : 12))
        c.circle(sx, sy, sr * 3, C(0xFFFFE0, 0.08)); c.circle(sx, sy, sr * 2, C(0xFFFFE0, 0.14)); c.circle(sx, sy, sr, C(0xFFFCE8))
        let clouds = tall ? 9 : 4
        for i in 0..<clouds {
            let x = Int(noise(i * 3 + 900) * Double(c.w)), y = tall ? g / 10 + Int(noise(i * 3 + 901) * Double(g / 2)) : 6 * s + Int(noise(i * 3 + 901) * 10) * s
            cloud(c, x, y, (tall ? 4 : 2) * s + Int(noise(i * 3 + 902) * 3) * s, seed: i + 90)
        }
        // the sea
        let beach = g - (tall ? g / 12 : 6 * s)
        c.rect(0, hz, c.w, beach - hz, C(0x2A86C8))
        c.rect(0, hz, c.w, s, C(0x1E6AA8))
        for (j, y) in stride(from: hz + 2 * s, to: beach, by: 2 * s).enumerated() {
            for x in stride(from: Int(noise(j + 910) * 9), to: c.w, by: 15 * s) where noise(x * 7 + j) > 0.45 {
                c.rect(x, y, (2 + Int(noise(x + j) * 4)) * s, max(1, s / 2), noise(x * 3 + j) > 0.7 ? C(0xF0FAFF, 0.75) : C(0x1E70B0))
            }
        }
        // the beach
        c.rect(0, beach, c.w, g - beach, C(0xEED8A0))
        c.rect(0, beach, c.w, s, C(0xF8F0D8))
        for i in 0..<(c.w / 6) { c.px(Int(noise(i * 2 + 920) * Double(c.w)), beach + s + Int(noise(i * 2 + 921) * Double(max(1, g - beach - s))), C(0xD8C088)) }
        coastSkyline(c, g)
        coastHangar(c, g)
        coastStatue(c, g)
        // palms along the promenade
        let palms: [Double] = [0.05, 0.2, 0.33, 0.45, 0.71]
        for (i, f) in palms.enumerated() {
            let h = (tall ? 30 : 18) * s + Int(noise(i + 930) * 6) * s
            s6Palm(c, x: Int(Double(c.w) * f), base: g, h: h, s: tall ? 2 * s : s, lean: (i % 2 == 0 ? 4 : -3) * s,
                   trunk: C(0x8A6A4A), leaf: C(0x2A8A4A), leafHi: C(0x4AB060))
        }
        // the promenade and its blue railing
        for x in stride(from: 0, to: c.w, by: 6 * s) { c.rect(x, g - 5 * s, s, 5 * s, C(0x3A6AA8)) }
        c.rect(0, g - 5 * s, c.w, s, C(0x5A8AC8))
        c.ground(g, C(0xC8BCA0), edge: C(0xF0E8D0), speck: C(0xB0A488), seed: 65)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + s, s, c.h - g, C(0xB4A88C)) }
    }

    /// The city behind the beach: white, sand and glass towers.
    static func coastSkyline(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), beach = g - (isTall(c) ? g / 12 : 6 * s)
        let cols: [UInt32] = [0xECE8DC, 0xC8DCEC, 0xDCD0BC, 0xA8C4DC, 0xF4F0E8]
        var x = Int(Double(c.w) * 0.27), i = 0
        let end = Int(Double(c.w) * 0.82)
        while x < end {
            let bw = (8 + Int(noise(i * 5 + 940) * 12)) * s
            let bh = Int(Double(g) * (0.22 + noise(i * 5 + 941) * 0.38))
            let col = C(cols[i % cols.count]), y = beach - bh
            c.rect(x, y, bw, bh, col)
            c.rect(x + bw - 2 * s, y, 2 * s, bh, lerp(col, C(0x6A88A8), 0.35))
            c.rect(x, y, bw, s, lerp(col, white, 0.5))
            for wy in stride(from: y + 3 * s, to: beach - 2 * s, by: 3 * s) {
                c.rect(x + s, wy, bw - 4 * s, max(1, s / 2) + (i % 2 == 0 ? 0 : s / 2), C(0x5A8AC0, 0.5))
            }
            if noise(i * 5 + 942) > 0.7 { c.rect(x + bw / 2, y - 5 * s, max(1, s / 2), 5 * s, C(0x8A9AAA)) }
            x += bw + Int(noise(i * 5 + 943) * 3) * s
            i += 1
        }
    }

    /// Ferris Aircraft's hangar at the right: arched roof, the name in red, open doors and a jet inside.
    static func coastHangar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        let x0 = Int(Double(c.w) * 0.78), x1 = c.w + 6 * s, hw = x1 - x0
        let hh = tall ? Int(Double(g) * 0.4) : 36 * s, top = g - hh, arch = hh / 3
        for k in 0..<hw {
            let u = Double(k) / Double(hw) * 2 - 1
            let y = top + Int(Double(arch) * u * u)
            c.rect(x0 + k, y, 1, g - y, C(0xD8DCE2))
            c.px(x0 + k, y, C(0xF4F6F8))
            if k % (6 * s) == 0 { c.rect(x0 + k, y + s, max(1, s / 2), g - y, C(0xB8BEC8)) }
        }
        let k = tall ? 3 * s : 2 * s
        let tw = s6TextWidth("FERRIS", k: k), tx = x0 + hw / 2 - tw / 2, ty = top + arch / 2 + 2 * s
        s6Text(c, tx, ty, "FERRIS", C(0xC83A2A), k: k)
        let dy = ty + 5 * k + 4 * s, dw = hw * 2 / 3, dx = x0 + hw / 2 - dw / 2
        c.rect(dx, dy, dw, g - dy, C(0x2A3038))
        c.rect(dx, dy, dw, s, C(0x8A929C))
        for x in stride(from: dx, to: dx + dw, by: 5 * s) { c.rect(x, dy, max(1, s / 2), g - dy, C(0x3A424C)) }
        let jk = tall ? 2 * s : s
        s6Stamp(c, dx - 8 * jk, g - 7 * jk, [
            "............d...",
            "...........dd...",
            "..ckddddddddddd.",
            "ddddddddddddddde",
            "....dddd...dd...",
            "....l.......l...",
            "...ooo.....ooo..",
        ], ["d": C(0x9AA4B0), "c": C(0x5AB8E8), "k": C(0x2A4A6A), "e": C(0x4A4A4A), "l": C(0x5A5A5A), "o": C(0x1A1A1A)], s: jk)
        c.rect(dx - 6 * jk, g - 4 * jk, 3 * jk, jk, C(0x3A6AA8))                       // a blue stripe down the side
    }

    /// The memorial statue on its plinth.
    static func coastStatue(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), p = coastStatueSpot(c, g), k = p.k, ps = isTall(c) ? k : s
        // the plinth
        c.rect(p.x - 9 * ps, g - 3 * ps, 18 * ps, 3 * ps, C(0xB8B4A8)); c.rect(p.x - 9 * ps, g - 3 * ps, 18 * ps, max(1, s), C(0xE8E4D8))
        c.rect(p.x - 7 * ps, p.y + ps, 14 * ps, g - p.y - 4 * ps, C(0xCCC8BC)); c.rect(p.x + 5 * ps, p.y + ps, 2 * ps, g - p.y - 4 * ps, C(0xA8A49A))
        c.rect(p.x - 8 * ps, p.y, 16 * ps, ps, C(0xE8E4D8))
        c.circle(p.x, p.y + (g - p.y) / 2, max(1, ps * 3 / 2), C(0x3ABF5A))           // the lantern emblem on the plinth
        c.circle(p.x, p.y + (g - p.y) / 2, max(1, ps / 2), C(0xCCC8BC))
        s6Stamp(c, p.x - 7 * k, p.y - 25 * k, [
            "..........gg..",
            ".........gggg.",
            ".........gggg.",
            "..........hh..",
            "..........hb..",
            "..........hb..",
            ".....hh...hb..",
            "....hbbd..hb..",
            "....hmmd..hb..",
            ".....bd...hb..",
            "...hbbbbbbbb..",
            "..hbbeeebbbd..",
            "..hbbeoebbbd..",
            "..hbbeeebbbd..",
            "..hb.bbbbb.d..",
            "..hb.bbbbbd...",
            "..hh.bbbbbd...",
            ".....bbbbbd...",
            ".....bbb.bd...",
            ".....bbd.bd...",
            ".....bbd.bd...",
            ".....bbd.bd...",
            ".....bbd.bd...",
            "....hbbd.bdd..",
            "....bbbd.bddd.",
        ], ["b": C(0x3A8A64), "h": C(0x7AC89A), "d": C(0x24603F), "e": C(0xE8F0E8), "o": C(0x3A8A64),
            "m": C(0x2A6A4A), "g": C(0x7AFF8A)], s: k)
    }

    /// A jet streaking across with its contrail, waves breaking along the beach, gulls wheeling, and the statue's
    /// lantern glowing.
    static func coastCityLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), hz = coastHorizon(c, g)
        let beach = g - (tall ? g / 12 : 6 * s)
        // the surf
        let surf = beach - Int((sin(t * 1.4) * 0.5 + 0.5) * Double(2 * s))
        for x in stride(from: 0, to: Int(Double(c.w) * 0.78), by: 2 * s) where noise(x / (2 * s) + Int(t * 2) * 3) > 0.25 {
            c.rect(x, surf, 2 * s, s, C(0xFFFFFF, 0.85))
        }
        for j in 0..<max(3, (beach - hz) / (5 * s)) {
            let y = hz + 3 * s + j * 5 * s
            guard y < beach - 2 * s else { break }
            let open = Int(Double(c.w) * 0.27) - (4 + j) * s           // only where the sea shows, left of the city
            let x = Int(s6Wrap(noise(j + 950) * Double(c.w) + t * Double((4 + j) * s), Double(max(1, open))))
            c.rect(x, y, (4 + j) * s, max(1, s / 2), C(0xFFFFFF, 0.7))
        }
        // gulls
        let gk = tall ? 2 * s : s
        for i in 0..<3 {
            let x = Int(s6Wrap(noise(i * 3 + 960) * Double(c.w) + t * Double(6 + i * 3) * Double(s), Double(c.w + 20 * s))) - 10 * s
            let y = Int(Double(hz) * (0.3 + noise(i * 3 + 961) * 0.5)) + Int(sin(t + Double(i)) * Double(3 * s))
            let up = s6Phase(t, 0.7, offset: Double(i) * 0.3) < 0.5
            s6Stamp(c, x, y, up ? ["#...#", ".#.#.", "..#.."] : [".....", "##.##", "..#.."], ["#": C(0xF8F8F8)], s: gk)
        }
        // the lantern's glow
        let p = coastStatueSpot(c, g), k = p.k
        let pulse = 0.5 + 0.5 * sin(t * 2)
        let lx = p.x + 4 * k, ly = p.y - 23 * k
        c.circle(lx, ly, Int(Double(3 * k) + pulse * Double(2 * k)), C(0x7AFF8A, 0.10 + pulse * 0.10))
        c.circle(lx, ly, 2 * k, C(0xC8FFD0, 0.2 + pulse * 0.2))
        // a jet with its contrail
        let speed = 60.0 * Double(s), span = Double(c.w + 60 * s), dur = span / speed, cycle = dur + 6
        let ph = (t + 1).truncatingRemainder(dividingBy: cycle)
        guard ph < dur else { return }
        let jx = c.w + 20 * s - Int(ph * speed), jy = tall ? g / 5 : 5 * s
        let trail = min(c.w, Int(ph * speed))
        for k in 0..<trail / (2 * s) {
            let a = 0.6 * (1 - Double(k * 2 * s) / Double(max(1, trail)))
            c.rect(jx + 15 * s + k * 2 * s, jy + 3 * s + (k / 20) % 2, 2 * s, s, C(0xFFFFFF, a))
        }
        s6Stamp(c, jx, jy, [
            "............d...",
            "...........dd...",
            "..ckddddddddddd.",
            "ddddddddddddddde",
            "....dddd...dd...",
        ], ["d": C(0x8A94A0), "c": C(0x5AB8E8), "k": C(0x2A4A6A), "e": C(0xFFB050)], s: s)
    }
}

// MARK: - Gorilla City

extension Scenes {
    /// The waterfalls: column, width, the top they pour from and the row they vanish into the canopy.
    static func gorillaFalls(_ c: PixelCanvas, _ g: Int) -> [(x: Int, w: Int, top: Int, bottom: Int)] {
        let s = unit(g), tall = isTall(c)
        let top = tall ? Int(Double(g) * 0.22) : 6 * s, bottom = g - (tall ? g / 7 : 14 * s)
        return [(Int(Double(c.w) * 0.07), 7 * s, top + 4 * s, bottom), (Int(Double(c.w) * 0.17), 4 * s, top + 12 * s, bottom),
                (Int(Double(c.w) * 0.97), 5 * s, top + 6 * s, bottom)]
    }

    /// Gorilla City, hidden in the African jungle: a misty green-gold morning, jungle ridges fading into haze, sheer
    /// cliffs either side with waterfalls pouring down and a great gorilla face carved into the right-hand rock. Between
    /// them the city's ivory and gold domes, ribbed and crowned with spires, and slender disc-topped towers rise out of
    /// the canopy, skybridges strung between them. The crew stands on a mossy stone plaza edged with ferns.
    static func gorillaCity(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x6AAEA4), C(0xF2E4AA), bands: 7)
        c.circle(c.w / 2, Int(Double(g) * 0.35), g / 3, C(0xFFF6D0, 0.10))
        c.dunes(base: Int(Double(g) * 0.5), amp: 6 * Double(s), freq: 0.017 / Double(s), phase: 0.3, bottom: g, C(0x8ABCA4))
        c.dunes(base: Int(Double(g) * 0.62), amp: 5 * Double(s), freq: 0.026 / Double(s), phase: 2.1, bottom: g, C(0x6AA488))
        c.rect(0, Int(Double(g) * 0.58), c.w, 4 * s, C(0xFFFFFF, 0.18))
        gorillaDomes(c, g, far: true)
        c.rect(0, Int(Double(g) * 0.7), c.w, 3 * s, C(0xFFFFFF, 0.2))
        gorillaDomes(c, g, far: false)
        // the cliffs either side, the falls and the carved face
        let ctop = tall ? Int(Double(g) * 0.2) : 4 * s
        mesa(c, x: -20 * s, width: Int(Double(c.w) * 0.24) + 20 * s, h: g - ctop, base: g, C(0x4A6A5A), seed: 66)
        mesa(c, x: Int(Double(c.w) * 0.84), width: Int(Double(c.w) * 0.16) + 30 * s, h: g - ctop - 4 * s, base: g, C(0x4E6E5C), seed: 67)
        for x in 0..<c.w where x < Int(Double(c.w) * 0.24) || x > Int(Double(c.w) * 0.84) {
            for y in stride(from: ctop + Int(noise(x + 980) * 6), to: g, by: 5 * s) where noise(x * 7 + y) > 0.85 {
                c.rect(x, y, s, 2 * s, C(0x3A5848))
            }
            if noise(x + 981) > 0.6 { c.rect(x, ctop + Int(noise(x + 982) * 4) * s, s, s, C(0x5A8A4A)) }
        }
        for f in gorillaFalls(c, g) {
            c.rect(f.x - s, f.top, f.w + 2 * s, f.bottom - f.top, C(0x3A5A4A))
            c.rect(f.x, f.top, f.w, f.bottom - f.top, C(0xC8E8F0))
            c.rect(f.x, f.top, max(1, s), f.bottom - f.top, C(0xFFFFFF, 0.8))
            c.ellipse(f.x + f.w / 2, f.bottom, f.w + 4 * s, 3 * s, C(0xFFFFFF, 0.5))
        }
        let fk = tall ? 4 * s : 2 * s, fx = Int(Double(c.w) * 0.84) + 8 * s, fy = tall ? Int(Double(g) * 0.3) : 9 * s
        s6Stamp(c, fx, fy, [
            "....hhhhhh....",
            "..hhffffffhh..",
            ".hffffffffffh.",
            "hffffffffffffh",
            "hhhhhhhhhhhhhh",
            "fdddffffffdddf",
            "fdedffffffdedf",
            "fffffhhhhfffff",
            "ffffhffffhffff",
            "fffhdhffhdhfff",
            "ffhhhhhhhhhhff",
            ".hffffffffffh.",
            ".fddddddddddf.",
            "..ffffffffff..",
            "....ffffff....",
        ], ["f": C(0x7A8A70), "h": C(0xA8B494), "d": C(0x2E3E34), "e": C(0xE8C860)], s: fk)
        if tall { gorillaVines(c, g) }
        // the canopy the city rises from
        for i in 0..<(c.w / (9 * s) + 2) {
            let x = i * 9 * s + Int(noise(i + 990) * 6) - 4 * s, r = (6 + Int(noise(i + 991) * 5)) * s
            let y = g - (tall ? g / 9 : 9 * s) + Int(noise(i + 992) * 4) * s
            c.ellipse(x, y, r, r * 2 / 3, C(0x2A5A2A)); c.ellipse(x - s, y - r / 3, r * 2 / 3, r / 3, C(0x4A8A3A))
        }
        c.rect(0, g - (tall ? g / 12 : 6 * s), c.w, tall ? g / 12 : 6 * s, C(0x24502A))
        if tall {                                                 // more of the canopy, layer on layer, down to the plaza
            for (j, y) in stride(from: g - g / 12 + 4 * s, to: g, by: 7 * s).enumerated() {
                for i in 0..<(c.w / (11 * s) + 2) {
                    let x = i * 11 * s + Int(noise(i * 3 + j * 71 + 1050) * 8) * s - 5 * s, r = (5 + Int(noise(i + j * 31 + 1051) * 4)) * s
                    c.ellipse(x, y, r, r / 2, j % 2 == 0 ? C(0x2E6230) : C(0x285A2C)); c.ellipse(x - s, y - r / 4, r / 2, r / 4, C(0x447E38))
                }
            }
        }
        // the plaza, ferns at its edges
        c.ground(g, C(0x8A7A58), edge: C(0xC8B888), speck: C(0x6A5E44), seed: 66)
        for x in stride(from: 0, to: c.w, by: 14 * s) { c.rect(x, g + s, s, c.h - g, C(0x6A5E44)) }
        c.rect(0, g + (c.h - g) / 2, c.w, s, C(0x6A5E44))
        for i in 0..<(c.w / 40) {
            let x = Int(noise(i * 2 + 995) * Double(c.w))
            for k in 0..<5 {
                let a: Double = Double.pi * (1.1 + Double(k) * 0.2)
                for r in 0..<(6 * s) { c.px(x + Int(cos(a) * Double(r)), g - Int(-sin(a) * Double(r) * 0.8) - r / 3, C(0x3A7A3A)) }
            }
        }
    }

    /// One band of the city: domes and disc-topped towers spread across the gap between the cliffs.
    static func gorillaDomes(_ c: PixelCanvas, _ g: Int, far: Bool) {
        let s = max(unit(g), g / 110), seed = far ? 1000 : 1040
        let base = Int(Double(g) * (far ? 0.66 : 0.82))
        let ivory = far ? C(0xD8D4B4) : C(0xF0E6C4), shade = far ? C(0xB0B49A) : C(0xC8B88A)
        let gold = far ? C(0xC8B070) : C(0xE0B040), glass = far ? C(0x8AB8B0) : C(0x5AA8B0)
        var x = Int(Double(c.w) * 0.22), i = 0
        let end = Int(Double(c.w) * 0.86)
        var tops: [(Int, Int)] = []
        while x < end {
            let kind = Int(noise(i * 7 + seed) * 3)
            let r = ((far ? 5 : 7) + Int(noise(i * 7 + seed + 1) * (far ? 6 : 9))) * s
            switch kind {
            case 0, 1:                                               // a ribbed dome on its drum
                let dh = r / 2, cx = x + r
                c.rect(x, base - dh, r * 2, dh + 12 * s, shade)
                c.ellipse(cx, base - dh, r, r * 4 / 5, kind == 0 ? ivory : glass)
                c.ellipse(cx - r / 3, base - dh - r / 3, r / 3, r / 4, white.alpha(0.35))
                for k in -2...2 {
                    let rx = cx + k * r / 3, u = Double(k) / 3
                    let hh = Int(Double(r * 4 / 5) * (1 - u * u).squareRoot())
                    c.rect(rx, base - dh - hh, max(1, s / 2), hh, gold.alpha(0.6))
                }
                for wx in stride(from: x + s, to: x + r * 2 - s, by: 3 * s) { c.rect(wx, base - dh + s, s, s, C(0xFFD87A, far ? 0.4 : 0.8)) }
                let sh = r / 2 + 3 * s
                c.rect(cx, base - dh - r * 4 / 5 - sh, max(1, s), sh, gold)
                c.circle(cx, base - dh - r * 4 / 5 - sh, s, gold)
                tops.append((cx, base - dh - r / 3))
                x += r * 2 + (2 + Int(noise(i * 7 + seed + 2) * 6)) * s
            default:                                                 // a slender tower with a disc on top
                let th = Int(Double(g) * (far ? 0.3 : 0.38) * (isTall(c) ? 0.6 : 1)) + Int(noise(i * 7 + seed + 3) * Double(g) * 0.1)
                let tw = 3 * s, tx = x + 4 * s
                c.rect(tx, base - th, tw, th + 12 * s, ivory); c.rect(tx + tw - s, base - th, s, th + 12 * s, shade)
                c.ellipse(tx + tw / 2, base - th, 6 * s, 2 * s, gold); c.ellipse(tx + tw / 2, base - th - s, 4 * s, s, ivory)
                c.rect(tx + tw / 2, base - th - 6 * s, max(1, s / 2), 5 * s, gold)
                for wy in stride(from: base - th + 4 * s, to: base, by: 4 * s) { c.rect(tx + s, wy, s, s, C(0xFFD87A, far ? 0.4 : 0.8)) }
                tops.append((tx + tw / 2, base - th * 2 / 3))
                x += 11 * s
            }
            i += 1
        }
        for k in 1..<max(1, tops.count) where noise(k + seed + 50) > 0.45 {   // skybridges
            let a = tops[k - 1], b = tops[k], y = max(a.1, b.1)
            guard b.0 - a.0 < 30 * s else { continue }
            c.rect(a.0, y, b.0 - a.0, max(1, s / 2) + (far ? 0 : s / 2), gold.alpha(0.8))
        }
    }

    /// Vines and leaves hanging from the top of a tall canvas.
    static func gorillaVines(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for x in 0..<c.w {
            let d = Int((abs(sin(Double(x) * 0.025)) * 0.5 + noise(x / 6 + 1010) * 0.5) * Double(g) * 0.08)
            c.rect(x, 0, 1, d, C(0x1E4A22)); c.px(x, d, C(0x3A7A34))
        }
        for i in 0..<(c.w / 14) {
            let x = Int(noise(i * 3 + 1020) * Double(c.w)), len = Int(Double(g) * (0.1 + noise(i * 3 + 1021) * 0.3))
            for k in 0..<len {
                c.px(x + Int(sin(Double(k) * 0.08) * Double(2 * s)), k, C(0x2A5A2A))
                if k % (7 * s) == 0 { c.rect(x + Int(sin(Double(k) * 0.08) * Double(2 * s)) - s, k, 3 * s, s, C(0x4A8A3A)) }
            }
        }
    }

    /// The waterfalls pouring, spray at their feet, mist drifting through the city and birds flying over.
    static func gorillaCityLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c)
        for (j, f) in gorillaFalls(c, g).enumerated() {
            let len = f.bottom - f.top, speed = 40.0 * Double(s)
            for col in 0..<(f.w / max(1, s)) {
                for k in 0..<max(2, len / (9 * s)) {
                    let y = f.top + Int(s6Wrap(noise(j * 50 + col * 7 + k) * Double(len) + t * speed * (1 + noise(col + j) * 0.4), Double(len)))
                    c.rect(f.x + col * s, y, s, min(3 * s, f.bottom - y), C(0x8AB8C8, 0.7))
                }
            }
            let p = s6Phase(t, 1.2, offset: Double(j) * 0.4)
            c.ellipse(f.x + f.w / 2, f.bottom - Int(p * Double(3 * s)), f.w / 2 + Int(p * Double(5 * s)), 2 * s, C(0xFFFFFF, 0.4 * (1 - p)))
        }
        for i in 0..<4 {
            let x = Int(s6Wrap(noise(i * 3 + 1030) * Double(c.w) + t * Double(3 + i) * Double(s), Double(c.w + 120 * s))) - 60 * s
            let y = Int(Double(g) * (0.55 + Double(i) * 0.08))
            c.ellipse(x, y, 50 * s, 2 * s, C(0xFFFFFF, 0.14))
        }
        let k = tall ? 2 * s : s
        for i in 0..<4 {
            let x = Int(s6Wrap(noise(i * 3 + 1040) * Double(c.w) - t * Double(10 + i * 2) * Double(s), Double(c.w + 20 * s))) - 10 * s
            let y = Int(Double(g) * (0.15 + noise(i * 3 + 1041) * 0.25)) + Int(sin(t * 1.2 + Double(i)) * Double(2 * s))
            let up = s6Phase(t, 0.45, offset: Double(i) * 0.2) < 0.5
            s6Stamp(c, x, y, up ? ["#...#", ".#.#.", "..#.."] : [".....", "##.##", "..#.."], ["#": C(0x1E2A1E)], s: k)
        }
    }
}
