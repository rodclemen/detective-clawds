import Foundation

let scenes1: [Location: Place] = [
    .metropolis: Place(name: "Metropolis", panel: 0x142438, still: Scenes.metropolis, moving: Scenes.metropolisLife),
    .gotham: Place(name: "Gotham City", panel: 0x12121C, still: Scenes.gotham, moving: Scenes.gothamLife),
    .batcave: Place(name: "The Batcave", panel: 0x0E1216, still: Scenes.batcave, moving: Scenes.batcaveLife),
    .fortressOfSolitude: Place(name: "Fortress of Solitude", panel: 0x10202E, still: Scenes.fortress, moving: Scenes.fortressLife),
    .themyscira: Place(name: "Themyscira", panel: 0x16283A, still: Scenes.themyscira, moving: Scenes.themysciraLife),
    .atlantis: Place(name: "Atlantis", panel: 0x0A2230, still: Scenes.atlantis, moving: Scenes.atlantisLife),
]

// MARK: - Shared bits for these scenes

/// A 3 by 5 pixel alphabet, only the letters these scenes need.
private let scenes1Font: [Character: [String]] = [
    "A": ["010", "101", "111", "101", "101"],
    "D": ["110", "101", "101", "101", "110"],
    "E": ["111", "100", "110", "100", "111"],
    "I": ["111", "010", "010", "010", "111"],
    "L": ["100", "100", "100", "100", "111"],
    "N": ["101", "111", "111", "101", "101"],
    "P": ["110", "101", "110", "100", "100"],
    "T": ["111", "010", "010", "010", "010"],
    "Y": ["101", "101", "010", "010", "010"],
]

/// The bat emblem, 21 by 9.
private let scenes1Bat: [String] = [
    "#........#.#........#",
    "##.......###.......##",
    "###.....#####.....###",
    "####...#######...####",
    "#####################",
    "#####################",
    ".######.#####.######.",
    "..####...###...####..",
    "...##.....#.....##...",
]

extension Scenes {
    /// String art drawn with every character `s` pixels square.
    static func scenes1Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
        }
    }

    /// String art mirrored left to right.
    static func scenes1StampFlipped(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        let n = rows.map { $0.count }.max() ?? 0
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + (n - 1 - k) * s, y + r * s, s, s, col) } }
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes1Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// Capital letters from the little alphabet, 4 units apart.
    static func scenes1Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, s: Int) {
        var cx = x
        for ch in text {
            if let rows = scenes1Font[ch] { scenes1Stamp(c, cx, y, rows, ["1": col], s: s) }
            cx += 4 * s
        }
    }

    static func scenes1TextWidth(_ text: String, s: Int) -> Int { max(0, text.count * 4 - 1) * s }

    /// A filled upright triangle: apex at (`x`, `top`), `half` wide either side at row `base`.
    static func scenes1Spike(_ c: PixelCanvas, _ x: Int, _ top: Int, _ base: Int, half: Int, _ col: Px) {
        guard base > top else { return }
        for y in top..<base {
            let k = Double(y - top) / Double(base - top)
            let hw = Int(Double(half) * k)
            c.rect(x - hw, y, hw * 2 + 1, 1, col)
        }
    }

    /// A small bird or bat, wings up or down.
    static func scenes1Flapper(_ c: PixelCanvas, _ x: Int, _ y: Int, up: Bool, _ col: Px, s: Int) {
        if up {
            scenes1Stamp(c, x, y, ["#...#", ".#.#.", "..#.."], ["#": col], s: s)
        } else {
            scenes1Stamp(c, x, y, ["..#..", "##.##", "#...#"], ["#": col], s: s)
        }
    }
}

// MARK: - Metropolis

extension Scenes {
    /// One art-deco building of the skyline.
    struct Scenes1Block { let x, y, w, h, kind: Int }

    /// The Daily Planet's place on the canvas: left edge, width and top row (the globe sits above it).
    static func metropolisPlanetFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, w: Int, top: Int) {
        let s = unit(g)
        return (Int(Double(c.w) * 0.64), 30 * s, isTall(c) ? g / 4 : 27 * s)
    }

    /// Metropolis on a bright afternoon: the crew is up on a stone roof terrace with a balustrade. Behind them the
    /// art-deco skyline stands in pale stone and hazy blue under fair-weather clouds, and the Daily Planet rises at the
    /// right, stepped crown, its name on the plaque and the golden globe with its ring on top.
    static func metropolis(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x2E6FD6), C(0xB8DEF6), bands: 8)
        for i in 0..<(tall ? 8 : 3) {
            let x = Int(noise(i * 7 + 11) * Double(c.w))
            let y = tall ? g / 14 + Int(noise(i * 7 + 12) * Double(g / 3)) : 5 + Int(noise(i * 7 + 12) * 8.0)
            let r = (tall ? 4 + Int(noise(i * 7 + 13) * 5.0) : 2 + Int(noise(i * 7 + 13) * 2.0)) * s
            cloud(c, x, y, r, seed: i + 40)
        }
        let f = metropolisPlanetFrame(c, g)
        for b in metropolisBlocks(c, g, far: true) {
            metropolisBuilding(c, b, body: C(0x9CC0E0), shade: C(0x88AED4), window: C(0x7A9EC6), s: s)
        }
        if tall {
            for b in metropolisBlocks(c, g, far: false, mid: true) where b.x + b.w < f.x - 14 * s || b.x > f.x + f.w + 14 * s {
                metropolisBuilding(c, b, body: C(0xBCCAD8), shade: C(0xA4B4C8), window: C(0x7E96B4), s: s)
            }
        }
        metropolisPlanet(c, g)
        for b in metropolisBlocks(c, g, far: false) where b.x + b.w < f.x - 10 * s || b.x > f.x + f.w + 10 * s {
            metropolisBuilding(c, b, body: C(0xD6CBB2), shade: C(0xB2A68E), window: C(0x6A7E9A), s: s)
        }
        // the roof terrace balustrade
        let rail = 7 * s
        c.rect(0, g - rail, c.w, rail, C(0xB8AE9A))
        c.rect(0, g - rail, c.w, 2 * s, C(0xE6DECC)); c.rect(0, g - rail + 2 * s, c.w, s, C(0x8C8270))
        for x in stride(from: 2 * s, to: c.w, by: 4 * s) {
            c.rect(x, g - rail + 3 * s, 2 * s, rail - 4 * s, C(0xD4CAB4))
            c.rect(x + s, g - rail + 3 * s, s, rail - 4 * s, C(0xA89E88))
        }
        c.rect(0, g - s, c.w, s, C(0x9A907C))
        for x in stride(from: 0, to: c.w, by: 40 * s) { c.rect(x, g - rail - s, 4 * s, rail + s, C(0xE0D8C4)) }
        c.ground(g, C(0x9C968A), edge: C(0xD8D2C4), speck: C(0x8E887C), seed: 5)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x8A8478)) }
    }

    /// The skyline: a far row of hazy towers and a nearer row of stone ones.
    static func metropolisBlocks(_ c: PixelCanvas, _ g: Int, far: Bool, mid: Bool = false) -> [Scenes1Block] {
        let s = unit(g)
        var lo = far ? 0.34 : 0.16, hi = far ? 0.72 : 0.46, seed = far ? 3 : 8
        if mid { lo = 0.28; hi = 0.55; seed = 5 }
        var out: [Scenes1Block] = []
        var x = -6 * s, i = 0
        while x < c.w {
            let bw = (10 + Int(noise(i * 7 + seed * 131) * 12.0)) * s
            var bh = Int(Double(g) * (lo + noise(i * 7 + 1 + seed * 131) * (hi - lo)))
            if far, noise(i * 7 + 3 + seed * 131) > 0.8 { bh = bh * 5 / 4 }
            out.append(Scenes1Block(x: x, y: g - bh, w: bw, h: bh, kind: Int(noise(i * 7 + 4 + seed * 131) * 4.0)))
            x += bw + (far ? 0 : (2 + Int(noise(i * 7 + 2 + seed * 131) * 10.0)) * s)
            i += 1
        }
        return out
    }

    /// An art-deco building: setback crown (and sometimes a spire), shaded side, vertical window strips.
    static func metropolisBuilding(_ c: PixelCanvas, _ b: Scenes1Block, body: Px, shade: Px, window: Px, s: Int) {
        let steps = b.kind % 3, y0 = b.y + steps * 3 * s
        c.rect(b.x, y0, b.w, b.h - steps * 3 * s, body)
        for k in 1...max(1, steps) where steps > 0 {
            let inset = k * 2 * s
            c.rect(b.x + inset, y0 - k * 3 * s, b.w - inset * 2, 3 * s, body)
            c.rect(b.x + b.w - inset - 2 * s, y0 - k * 3 * s, 2 * s, 3 * s, shade)
        }
        if b.kind == 3 { c.rect(b.x + b.w / 2, b.y - 7 * s, s, 7 * s, shade) }
        c.rect(b.x + b.w - 3 * s, y0, 3 * s, b.h - steps * 3 * s, shade)
        c.rect(b.x, y0, b.w, s, lerp(body, white, 0.35))
        for x in stride(from: b.x + 2 * s, to: b.x + b.w - 4 * s, by: 3 * s) {
            c.rect(x, y0 + 3 * s, s, b.h - steps * 3 * s - 3 * s, window.alpha(0.75))
        }
        for y in stride(from: y0 + 6 * s, to: b.y + b.h, by: 5 * s) { c.rect(b.x + s, y, b.w - 4 * s, s, body.alpha(0.8)) }
    }

    /// The Daily Planet: stepped stone shaft, the name plaque and the golden globe with its ring.
    static func metropolisPlanet(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = metropolisPlanetFrame(c, g), x = f.x, w = f.w, top = f.top
        let stone = C(0xEAE2D0), shade = C(0xC0B6A0), slot = C(0x6A7E9A)
        // the lower wings either side
        if g - top > 50 * s {
            for side in [-1, 1] {
                let wx = side < 0 ? x - 12 * s : x + w
                c.rect(wx, top + 46 * s, 12 * s, g - top - 46 * s, side < 0 ? stone : shade)
                c.rect(wx, top + 46 * s, 12 * s, s, white)
                for xx in stride(from: wx + 2 * s, to: wx + 11 * s, by: 3 * s) {
                    c.rect(xx, top + 49 * s, s, g - top - 49 * s, slot.alpha(0.8))
                }
            }
        }
        c.rect(x, top + 9 * s, w, g - top - 9 * s, stone)
        c.rect(x + 3 * s, top + 6 * s, w - 6 * s, 3 * s, stone)
        c.rect(x + 6 * s, top + 3 * s, w - 12 * s, 3 * s, stone)
        c.rect(x + 9 * s, top, w - 18 * s, 3 * s, stone)
        for (k, inset) in [0, 3, 6, 9].enumerated() {
            let y = top + (3 - k) * 3 * s
            c.rect(x + w - inset - 4 * s, y, 4 * s, k == 0 ? g - y : 3 * s, shade)
            c.rect(x + inset, y, w - inset * 2, s, white)
        }
        for xx in stride(from: x + 3 * s, to: x + w - 4 * s, by: 4 * s) {
            c.rect(xx, top + 25 * s, 2 * s, g - top - 25 * s, slot)
            c.rect(xx, top + 25 * s, 2 * s, s, C(0x4A5A74))
        }
        for y in stride(from: top + 31 * s, to: g, by: 6 * s) { c.rect(x + 2 * s, y, w - 6 * s, s, stone) }
        // the plaque
        c.rect(x + 2 * s, top + 11 * s, w - 4 * s, 13 * s, C(0x24345A))
        c.rect(x + 2 * s, top + 11 * s, w - 4 * s, s, C(0xC89A3A)); c.rect(x + 2 * s, top + 23 * s, w - 4 * s, s, C(0xC89A3A))
        let gold = C(0xF6E2A8)
        scenes1Text(c, x + (w - scenes1TextWidth("DAILY", s: s)) / 2, top + 13 * s, "DAILY", gold, s: s)
        scenes1Text(c, x + (w - scenes1TextWidth("PLANET", s: s)) / 2, top + 19 * s, "PLANET", gold, s: s)
        // the globe on its plinth, with the ring round it
        let gx = x + w / 2, r = 10 * s, gy = top - 3 * s - r
        c.rect(gx - 5 * s, top - 3 * s, 10 * s, 3 * s, shade); c.rect(gx - 5 * s, top - 3 * s, 10 * s, s, stone)
        metropolisRing(c, gx, gy, r, s: s, front: false)
        c.circle(gx, gy, r + 3 * s, C(0xFFE8A0, 0.12))
        c.circle(gx, gy, r, C(0xB8862A))
        c.circle(gx - s, gy - s, r - s, C(0xD8A23A))
        c.circle(gx - 3 * s, gy - 3 * s, r - 5 * s, C(0xE8BC58))
        c.circle(gx - 5 * s, gy - 5 * s, max(1, 2 * s), C(0xFFF0B8))
        let rr = Double(r)
        for f in [-0.5, 0.0, 0.5] {
            let dy = Int(rr * f), half = Int((rr * rr - Double(dy * dy)).squareRoot())
            c.rect(gx - half, gy + dy, half * 2, max(1, s / 2), C(0x9A6C1E, 0.8))
        }
        metropolisRing(c, gx, gy, r, s: s, front: true)
    }

    /// The tilted ring round the globe, its back half or its front half.
    static func metropolisRing(_ c: PixelCanvas, _ gx: Int, _ gy: Int, _ r: Int, s: Int, front: Bool) {
        let rad = Double(r + 4 * s), tilt: Double = -0.3
        let n = Int(rad * 8)
        for i in 0..<n {
            let a: Double = Double(i) / Double(n) * 2 * Double.pi
            guard (sin(a) > 0) == front else { continue }
            let ex = cos(a) * rad, ey = sin(a) * rad * 0.28
            let x = Double(gx) + ex * cos(tilt) - ey * sin(tilt), y = Double(gy) + ex * sin(tilt) + ey * cos(tilt)
            c.rect(Int(x), Int(y), s, s, front ? C(0xF6D070) : C(0xA87A2A))
        }
    }

    /// The globe turning, and every so often a red and blue blur streaking across the sky.
    static func metropolisLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = metropolisPlanetFrame(c, g)
        let gx = f.x + f.w / 2, r = 10 * s, gy = f.top - 3 * s - r, rr = Double(r)
        for k in 0..<4 {
            let a: Double = (scenes1Phase(t, 12) + Double(k) / 4) * 2 * Double.pi
            guard sin(a) > 0.05 else { continue }
            for dy in -r + 1..<r {
                let half = (rr * rr - Double(dy * dy)).squareRoot()
                c.px(gx + Int(half * cos(a)), gy + dy, C(0xFFE49A, 0.35 + 0.4 * sin(a)))
            }
        }
        // the blur: across, then a long pause
        let cycle = 10.0, dur = 1.4, tt = scenes1Phase(t, cycle, offset: 9.3) * cycle
        guard tt < dur else { return }
        let hx = Int(-60.0 * Double(s) + tt / dur * Double(c.w + 140 * s))
        let base = isTall(c) ? g / 6 : 12 * s
        let hy = base + Int(Double(c.w / 2 - hx) * 0.06)
        let len = 90 * s
        for k in 0..<len {
            let a = 0.75 * (1 - Double(k) / Double(len))
            let y = hy + Int(Double(k) * 0.06)
            c.rect(hx - k, y - 2 * s, 1, 2 * s, C(0x3A6AF0, a))
            c.rect(hx - k, y, 1, 2 * s, C(0xF03A3A, a))
            c.rect(hx - k, y - 5 * s, 1, 10 * s, C(0xFFFFFF, a * 0.12))
            if k % 4 == 0 { c.rect(hx - k, y - 3 * s, 1, s, C(0xFFFFFF, a * 0.5)); c.rect(hx - k, y + 2 * s, 1, s, C(0xFFFFFF, a * 0.3)) }
        }
        scenes1Stamp(c, hx - 2 * s, hy - 2 * s, [
            "rrr.....",
            "rrbbbbbk",
            ".rbbbbys",
            "..rr....",
        ], ["r": C(0xE02A2A), "b": C(0x2A5AD8), "k": C(0x1A1A24), "s": C(0xF0C8A0), "y": C(0xF6D040)], s: s)
        c.circle(hx + 5 * s, hy, 6 * s, C(0xFFFFFF, 0.12))
    }
}

// MARK: - Gotham City

extension Scenes {
    /// Where the Bat-Signal shines in the clouds.
    static func gothamSignal(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int) {
        let s = unit(g)
        return (Int(Double(c.w) * 0.3), isTall(c) ? g / 5 : 12 * s)
    }

    /// Gotham City on a rainy night: the crew is on a wet slate rooftop, a stone gargoyle crouched on each corner pillar
    /// of its parapet. Beyond, gothic towers with pointed roofs and spires crowd under low clouds, a few windows lit
    /// amber, and a searchlight on a nearby roof throws the Bat-Signal up onto the clouds.
    static func gotham(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), sig = gothamSignal(c, g)
        c.gradient(0, g, C(0x0A0C16), C(0x2C2A3C), bands: 7)
        // the low clouds, lit from below by the city and around the signal
        let cloudRows = tall ? g / 2 : g / 2
        for i in 0..<(c.w / 14 + (tall ? 24 : 0)) {
            let x = Int(noise(i * 5 + 70) * Double(c.w))
            let y = Int(noise(i * 5 + 71) * Double(cloudRows))
            let rx = (10 + Int(noise(i * 5 + 72) * 20.0)) * s, ry = (2 + Int(noise(i * 5 + 73) * 3.0)) * s
            let d = abs(Double(x - sig.x)) + abs(Double(y - sig.y)) * 2
            let glow = max(0, 1 - d / Double(90 * s))
            let col = lerp(noise(i * 5 + 74) > 0.5 ? C(0x26263A) : C(0x14141F), C(0x6A6450), glow * 0.6)
            c.ellipse(x, y, rx, ry, col.alpha(0.75))
            c.ellipse(x - rx / 3, y - ry, rx / 2, ry, col.alpha(0.75))
            c.ellipse(x + rx / 3, y - ry / 2, rx / 2, ry, col.alpha(0.75))
            c.rect(x - rx / 2, y + ry, rx, s, lerp(C(0x4A4660), C(0xA89A70), glow).alpha(0.4))
        }
        // the searchlight's beam
        let lx = Int(Double(c.w) * 0.44), ly = g - (tall ? 70 : 34) * s
        for y in sig.y..<ly {
            let k = Double(y - sig.y) / Double(max(1, ly - sig.y))
            let cx = Double(sig.x) + Double(lx - sig.x) * k, half = 15.0 * Double(s) * (1 - k) + Double(s)
            c.rect(Int(cx - half), y, Int(half * 2), 1, C(0xF0E6B0, 0.07))
        }
        // the signal itself
        c.ellipse(sig.x, sig.y, 26 * s, 16 * s, C(0xF0E6B0, 0.07))
        c.ellipse(sig.x, sig.y, 19 * s, 12 * s, C(0xF0E6B0, 0.12))
        c.ellipse(sig.x, sig.y, 14 * s, 9 * s, C(0xF4ECB8, 0.9))
        scenes1Stamp(c, sig.x - 10 * s, sig.y - 4 * s, scenes1Bat, ["#": C(0x14141C)], s: s)
        // far towers then near ones
        gothamRow(c, g, lo: tall ? 0.30 : 0.34, hi: tall ? 0.62 : 0.62, col: C(0x1C1C2C), lamp: 0.35, seed: 2)
        gothamTower(c, g)
        gothamRow(c, g, lo: tall ? 0.10 : 0.16, hi: tall ? 0.30 : 0.42, col: C(0x0E0E18), lamp: 0.6, seed: 6)
        // the searchlight housing on its roof
        c.rect(lx - 6 * s, ly + 4 * s, 12 * s, g - ly, C(0x0E0E18))
        c.rect(lx - 2 * s, ly + s, 4 * s, 3 * s, C(0x3A3A48))
        c.ellipse(lx - s, ly, 3 * s, 2 * s, C(0x5A5A68)); c.ellipse(lx - 2 * s, ly - s, 2 * s, s, C(0xFFF4C0))
        // the parapet and the gargoyles
        c.rect(0, g - 4 * s, c.w, 4 * s, C(0x22222E)); c.rect(0, g - 4 * s, c.w, s, C(0x44445A))
        for x in stride(from: 0, to: c.w, by: 10 * s) { c.rect(x, g - 6 * s, 5 * s, 2 * s, C(0x22222E)); c.rect(x, g - 6 * s, 5 * s, s, C(0x44445A)) }
        for (side, fx) in [(1, 0.06), (-1, 0.93)] {
            let px = Int(Double(c.w) * fx)
            c.rect(px - 4 * s, g - 14 * s, 8 * s, 14 * s, C(0x26263A)); c.rect(px - 5 * s, g - 14 * s, 10 * s, 2 * s, C(0x4A4A60))
            c.rect(px + 2 * s, g - 12 * s, 2 * s, 12 * s, C(0x1A1A28))
            gothamGargoyle(c, px - 8 * s, g - 30 * s, facingRight: side > 0, s: s)
        }
        c.ground(g, C(0x1C1E28), edge: C(0x4E5266), speck: C(0x262836), seed: 9)
        for y in stride(from: g + 3 * s, to: c.h, by: 3 * s) { c.rect(0, y, c.w, max(1, s / 2), C(0x14161E)) }
        for i in 0..<(c.w / 40) {
            let x = Int(noise(i * 3 + 500) * Double(c.w)), y = g + 2 * s + Int(noise(i * 3 + 501) * Double(max(1, c.h - g - 3 * s)))
            c.rect(x, y, (8 + Int(noise(i * 3 + 502) * 14.0)) * s, s, C(0x5A5E78, 0.4))
        }
    }

    /// Wayne Tower: the tallest thing in town, a gothic-deco shaft with a lit crown and a needle.
    static func gothamTower(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), x = Int(Double(c.w) * 0.78), w = 18 * s, top = isTall(c) ? g / 4 : 9 * s
        let col = C(0x24243A), edge = C(0x5A5A7A)
        c.rect(x - w / 2 - 4 * s, top + 24 * s, w + 8 * s, g - top - 24 * s, col)
        c.rect(x - w / 2, top + 8 * s, w, g - top - 8 * s, col)
        c.rect(x - w / 2, top + 8 * s, s, g - top - 8 * s, edge); c.rect(x - w / 2 - 4 * s, top + 24 * s, s, g - top - 24 * s, edge)
        c.rect(x + w / 2 - 3 * s, top + 8 * s, 3 * s, g - top - 8 * s, C(0x1A1A2C))
        c.rect(x - w / 2 + 3 * s, top + 3 * s, w - 6 * s, 5 * s, col)
        scenes1Spike(c, x, top - 6 * s, top + 3 * s, half: w / 2 - 3 * s, col)
        c.rect(x, top - 16 * s, max(1, s), 10 * s, edge)
        for k in [-1, 1] {
            scenes1Spike(c, x + k * (w / 2 - s), top + 2 * s, top + 8 * s, half: s, col)
            c.rect(x + k * (w / 2 + 2 * s), top + 20 * s, s, 4 * s, edge)
        }
        c.rect(x - w / 2, top + 8 * s, w, s, edge)
        for xx in stride(from: x - w / 2 + 2 * s, to: x + w / 2 - s, by: 3 * s) {
            c.rect(xx, top + 10 * s, s, 4 * s, C(0xF0D890, 0.85))
        }
        c.circle(x, top + 12 * s, 14 * s, C(0xF0D890, 0.06))
        for (j, y) in stride(from: top + 18 * s, to: g, by: 5 * s).enumerated() {
            for k in 0..<4 where noise(j * 7 + k + 333) > 0.75 { c.rect(x - w / 2 + 2 * s + k * 4 * s, y, 2 * s, 2 * s, C(0xE8B860, 0.5)) }
        }
    }

    /// A row of gothic buildings: pointed roofs, turrets, spires and arched windows.
    static func gothamRow(_ c: PixelCanvas, _ g: Int, lo: Double, hi: Double, col: Px, lamp: Double, seed: Int) {
        let s = unit(g), edge = lerp(col, C(0x6A6488), 0.3)
        var x = -4 * s, i = 0
        while x < c.w {
            let bw = (8 + Int(noise(i * 9 + seed * 77) * 14.0)) * s
            let bh = Int(Double(g) * (lo + noise(i * 9 + 1 + seed * 77) * (hi - lo)))
            let y = g - bh, kind = Int(noise(i * 9 + 2 + seed * 77) * 4.0)
            c.rect(x, y, bw, bh, col)
            c.rect(x, y, bw, s, edge)
            switch kind {
            case 0: scenes1Spike(c, x + bw / 2, y - bw * 3 / 4, y, half: bw / 2, col)
            case 1:
                scenes1Spike(c, x + bw / 2, y - 18 * s, y, half: 2 * s, col)
                c.rect(x + bw / 2, y - 22 * s, max(1, s / 2), 4 * s, edge)
            case 2:
                for tx in [x + s, x + bw - 4 * s] {
                    c.rect(tx, y - 6 * s, 3 * s, 6 * s, col)
                    scenes1Spike(c, tx + s, y - 11 * s, y - 6 * s, half: 2 * s, col)
                }
            default:
                for k in stride(from: 0, to: bw, by: 3 * s) { c.rect(x + k, y - 2 * s, 2 * s, 2 * s, col) }
            }
            for (j, wy) in stride(from: y + 3 * s, to: g - 3 * s, by: 6 * s).enumerated() {
                for (k, wx) in stride(from: x + 2 * s, to: x + bw - 2 * s, by: 4 * s).enumerated() {
                    let n = noise(i * 131 + j * 17 + k * 7 + seed * 1000)
                    let lit = n > (seed > 4 ? 0.9 : 0.8)
                    let wcol = lit ? C(0xE8B860, lamp) : C(0x050508, 0.5)
                    c.rect(wx, wy + s, 2 * s, 3 * s, wcol); c.rect(wx + s / 2, wy, max(1, s), s, wcol)
                }
            }
            x += bw + (Int(noise(i * 9 + 3 + seed * 77) * 4.0)) * s
            i += 1
        }
    }

    /// A crouching winged stone gargoyle, 16 by 16 units, looking left (or right).
    static func gothamGargoyle(_ c: PixelCanvas, _ x: Int, _ y: Int, facingRight: Bool, s: Int) {
        let art = [
            "............#...",
            "...........##..#",
            "..##.......###.#",
            ".#hh#......####.",
            "#hhhh#....#####.",
            "#ohhh##..######.",
            "hhhh####.######.",
            ".vv#######.####.",
            "..#########.###.",
            "...##h#######.#.",
            "...#hh########..",
            "..##h.#######...",
            ".##...##.####...",
            "......##..###...",
            ".....###.####...",
            "....####.#####..",
        ]
        let pal: [Character: Px] = ["#": C(0x3C3C50), "h": C(0x62627A), "o": C(0xE8C050), "v": C(0xB8B8C8)]
        if facingRight { scenes1StampFlipped(c, x, y, art, pal, s: s) } else { scenes1Stamp(c, x, y, art, pal, s: s) }
    }

    /// Rain slanting down, splashes on the slates and now and then lightning over the towers.
    static func gothamLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        let cycle = 11.0, tt = scenes1Phase(t, cycle, offset: 4) * cycle
        if tt < 0.35 && (tt < 0.08 || tt > 0.18) {
            c.rect(0, 0, c.w, g, C(0xB8C0F0, 0.07))
            var x = Double(c.w) * (0.55 + noise(Int(t / cycle) + 3) * 0.3), y = 0.0
            let yEnd = Double(g) * 0.45
            var i = 0
            while y < yEnd {
                let nx = x + (noise(i * 7 + Int(t / cycle) * 13) - 0.5) * 10 * Double(s), ny = y + 5 * Double(s)
                c.glowLine(x, y, nx, ny, core: C(0xF0F4FF), glow: C(0x8A9AF0), coreR: 0.5 * Double(s), glowR: 2 * Double(s), strength: 0.9)
                x = nx; y = ny; i += 1
            }
        }
        let n = c.w * c.h / 160
        for i in 0..<n {
            let speed = 150.0 + noise(i * 3 + 7) * 60
            let y = (noise(i * 3 + 8) * Double(c.h) + t * speed).truncatingRemainder(dividingBy: Double(c.h + 10)) - 5
            let x = Int(noise(i * 3 + 9) * Double(c.w + 40)) - Int(y / 4)
            c.rect(x, Int(y), max(1, s / 2), 3 * s, C(0xB0B8D8, 0.3))
        }
        for i in 0..<(c.w / 20) where noise(Int(t * 10) * 31 + i) > 0.5 {
            let x = Int(noise(Int(t * 10) * 17 + i) * Double(c.w)), y = g + 1 + Int(noise(Int(t * 10) * 13 + i) * Double(c.h - g - 1))
            c.rect(x - s, y, 3 * s, max(1, s / 2), C(0xC8D0E8, 0.45))
            c.px(x, y - s, C(0xC8D0E8, 0.35))
        }
    }
}

// MARK: - The Batcave

extension Scenes {
    /// The Batcomputer's three screens: the big one and the two either side.
    static func batcaveScreens(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let s = unit(g), cx = c.w / 2, bottom = g - (isTall(c) ? 40 : 24) * s
        let mw = 48 * s, mh = 26 * s, sw = 22 * s, sh = 16 * s
        return [(cx - mw / 2, bottom - mh, mw, mh),
                (cx - mw / 2 - sw - 3 * s, bottom - mh + 6 * s, sw, sh),
                (cx + mw / 2 + 3 * s, bottom - mh + 6 * s, sw, sh)]
    }

    /// The waterfall's left edge and width.
    static func batcaveFall(_ c: PixelCanvas, _ g: Int) -> (x: Int, w: Int, top: Int) {
        let s = unit(g)
        return (Int(Double(c.w) * 0.03), 14 * s, isTall(c) ? g / 5 : 0)
    }

    /// The Batcave: dark rock, stalactites dripping from the roof and a waterfall pouring into a pool at the left. The
    /// trophies stand about: the mechanical T-rex, the giant penny on its stand. In the middle the Batcomputer glows
    /// on its console, and at the right the Batmobile sits on its turntable. Up high on tall screens, catwalks.
    static func batcave(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x07090C), C(0x141A20), bands: 6)
        // rock texture
        for i in 0..<(c.w * g / 120) {
            let x = Int(noise(i * 4 + 900) * Double(c.w)), y = Int(noise(i * 4 + 901) * Double(g))
            let n = noise(i * 4 + 902), len = (3 + Int(n * 14.0)) * s
            c.rect(x, y, len, s, n > 0.5 ? C(0x222A32, 0.6) : C(0x030405, 0.6))
            if n > 0.8 { c.rect(x + s, y + s, len - 2 * s, s, C(0x030405, 0.5)) }
        }
        // rock mounds and columns at the back, so the floor has depth
        c.dunes(base: g - (tall ? 40 : 12) * s, amp: Double((tall ? 18 : 6) * s), freq: 0.025, phase: 3, bottom: g, C(0x12171C), shade: C(0x2A323A))
        if tall { batcaveHigh(c, g) }
        // stalactites
        for i in 0..<(c.w / (7 * s)) {
            let x = Int(noise(i * 3 + 300) * Double(c.w))
            let len = Int(Double((tall ? 14 : 6) * s) + noise(i * 3 + 301) * Double((tall ? 50 : 12) * s))
            let half = (2 + Int(noise(i * 3 + 302) * 4.0)) * s
            for y in 0..<len {
                let hw = half * (len - y) / len
                c.rect(x - hw, y, hw * 2 + 1, 1, y < 2 ? C(0x161C22) : C(0x1C2228))
                c.px(x - hw, y, C(0x2A343C))
            }
        }
        batcaveWaterfall(c, g)
        for fx in [0.17, 0.7, 0.88] {
            let x = Int(Double(c.w) * fx), top = tall ? g / 3 : 0
            for y in top..<g {
                let k = Double(y - top) / Double(max(1, g - top)), half = Int(Double(3 * s) + k * Double(26 * s))
                c.rect(x - half, y, half * 2, 1, C(0xC8D8F0, 0.04))
            }
            c.ellipse(x, g, 30 * s, 3 * s, C(0xC8D8F0, 0.06))
            if tall { c.rect(x - 3 * s, top - 2 * s, 6 * s, 2 * s, C(0x3A4250)); c.rect(x - 2 * s, top, 4 * s, s, C(0xE8F0FF)) }
        }
        batcaveRex(c, g)
        batcaveComputer(c, g)
        batcavePenny(c, g)
        batcaveCar(c, g)
        c.ground(g, C(0x181C22), edge: C(0x3E4652), speck: C(0x12161A), seed: 13)
        for x in stride(from: 0, to: c.w, by: 24 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x22282E)) }
        c.rect(0, g + 1, c.w, s, C(0x0E1014))
    }

    /// High up: rock ledges with catwalks and their lamps.
    static func batcaveHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        for (k, fy) in [0.38, 0.6].enumerated() {
            let y = Int(Double(g) * fy), x0 = k == 0 ? c.w / 5 : c.w / 2, x1 = k == 0 ? c.w * 3 / 5 : c.w * 9 / 10
            c.rect(x0, y, x1 - x0, 2 * s, C(0x3A4250)); c.rect(x0, y, x1 - x0, s, C(0x5A6474))
            c.rect(x0, y - 6 * s, x1 - x0, s, C(0x3A4250))
            for x in stride(from: x0, to: x1, by: 6 * s) { c.rect(x, y - 6 * s, s, 6 * s, C(0x2E3440)) }
            for x in stride(from: x0 + 10 * s, to: x1, by: 40 * s) {
                c.rect(x, y + 2 * s, s, g - y - 2 * s, C(0x1E242C, 0.8))
                c.rect(x - s, y - 8 * s, 3 * s, 2 * s, C(0xA8D8FF)); c.circle(x, y - 6 * s, 6 * s, C(0x6AB8F0, 0.08))
            }
        }
    }

    static func batcaveWaterfall(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = batcaveFall(c, g)
        c.rect(f.x - 3 * s, f.top, f.w + 6 * s, g - f.top, C(0x0A0E12))
        for k in 0..<f.w { c.rect(f.x + k, f.top, 1, g - f.top, lerp(C(0x3A5A6E), C(0x6A8EA4), noise(k + 40))) }
        c.rect(f.x, f.top, s, g - f.top, C(0x9AC0D4, 0.6))
        if f.top > 0 { c.ellipse(f.x + f.w / 2, f.top, f.w, 3 * s, C(0x1C2228)) }
        c.ellipse(f.x + f.w / 2, g - s, f.w + 8 * s, 3 * s, C(0x2A4656))
        c.ellipse(f.x + f.w / 2, g - 2 * s, f.w + 2 * s, 3 * s, C(0xC8E0EC, 0.35))
    }

    /// The life-size mechanical Tyrannosaurus, mouth open, on its low plinth.
    static func batcaveRex(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), u = 2 * s, x = Int(Double(c.w) * 0.17) - 22 * u, base = g - 3 * s
        c.rect(x + 6 * u, base, 20 * u, 3 * s, C(0x2A3038)); c.rect(x + 6 * u, base, 20 * u, s, C(0x4A5462))
        let art = [
            ".........................########..",
            "........................###########",
            "........................##o########",
            "........................###########",
            ".......................#####v.v.v.v",
            "......................#####........",
            ".....................######..v.v.v.",
            ".....................######.######.",
            "...................########.......",
            "................##########.........",
            "##...........#############.##......",
            ".###......###############...#......",
            "...################.#####..........",
            "......##############...............",
            "........###########................",
            ".........####..####................",
            ".........###....###................",
            ".........###.....##................",
            "........####....###................",
            ".......#####...####................",
        ]
        let rows = art.count
        scenes1Stamp(c, x, base - rows * u, art, ["#": C(0x3E4A42), "o": C(0xE8C040), "v": C(0xD8D4C0)], s: u)
        // light catching its back
        for (r, row) in art.enumerated() {
            if let k = row.firstIndex(of: "#") {
                c.rect(x + row.distance(from: row.startIndex, to: k) * u, base - (rows - r) * u, u, s, C(0x6A7A6E))
            }
        }
    }

    /// The Batcomputer: a big screen and two smaller, on their gantry over the console.
    static func batcaveComputer(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), scr = batcaveScreens(c, g), cx = c.w / 2
        let bottom = scr[0].y + scr[0].h
        c.rect(cx - 2 * s, bottom, 4 * s, g - bottom, C(0x1E242C))
        for k in [-1, 1] { c.rect(cx + k * 30 * s - s, bottom - 6 * s, 2 * s, g - bottom + 6 * s, C(0x1A2028)) }
        c.circle(cx, scr[0].y + scr[0].h / 2, scr[0].w * 3 / 4, C(0x3AA8E8, 0.05))
        for (i, r) in scr.enumerated() {
            c.rect(r.x - 2 * s, r.y - 2 * s, r.w + 4 * s, r.h + 4 * s, C(0x22282E))
            c.rect(r.x - s, r.y - s, r.w + 2 * s, r.h + 2 * s, C(0x2A86C0))
            c.rect(r.x, r.y, r.w, r.h, C(0x08202E))
            for y in stride(from: r.y + 3 * s, to: r.y + r.h, by: 4 * s) { c.rect(r.x, y, r.w, max(1, s / 2), C(0x1A4A66, 0.6)) }
            if i == 0 {
                c.ellipse(r.x + r.w / 2, r.y + r.h / 2, 10 * s, 6 * s, C(0x3AB8F0, 0.25))
                scenes1Stamp(c, r.x + r.w / 2 - 10 * s, r.y + r.h / 2 - 4 * s, scenes1Bat, ["#": C(0x6AD0FF, 0.7)], s: s)
            }
        }
        // the console desk
        let dy = g - 12 * s
        c.rect(cx - 34 * s, dy, 68 * s, 12 * s, C(0x14181E))
        c.rect(cx - 36 * s, dy, 72 * s, 3 * s, C(0x2A323C)); c.rect(cx - 36 * s, dy, 72 * s, s, C(0x5A6878))
        for k in 0..<10 { c.rect(cx - 30 * s + k * 6 * s, dy + s, 4 * s, s, C(0x3AA8E8, 0.5 + noise(k + 90) * 0.4)) }
        c.rect(cx - 5 * s, dy - 9 * s, 10 * s, 2 * s, C(0x1A1E24)); c.rect(cx - 4 * s, dy - 7 * s, 2 * s, 7 * s, C(0x1A1E24))
        c.rect(cx - 6 * s, dy - 18 * s, 2 * s, 11 * s, C(0x1A1E24))
    }

    /// The giant penny standing on edge in its cradle.
    static func batcavePenny(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), x = Int(Double(c.w) * 0.7), r = 16 * s, y = g - 5 * s - r
        c.ellipse(x + 2 * s, y, r - 3 * s, r, C(0x5A3418))
        c.ellipse(x, y, r - 3 * s, r, C(0xB8703A))
        c.ellipse(x, y, r - 5 * s, r - 2 * s, C(0x9A5A2C))
        c.ellipse(x - s, y, r - 6 * s, r - 3 * s, C(0xA8642E))
        // Lincoln's profile, facing right
        let bust = C(0x8A4E24)
        c.ellipse(x - s, y - 3 * s, 4 * s, 5 * s, bust)
        c.rect(x + 3 * s, y - 3 * s, s, 2 * s, bust)
        c.rect(x - 2 * s, y + 2 * s, 4 * s, 2 * s, bust)
        c.ellipse(x - s, y + 7 * s, 6 * s, 3 * s, bust)
        c.rect(x - 3 * s, y - 8 * s, 4 * s, s, C(0x7A421E))
        c.rect(x - 9 * s, y - 6 * s, s, 12 * s, C(0xE8A060, 0.6))
        c.rect(x - 7 * s, g - 5 * s, 14 * s, 5 * s, C(0x2A3038)); c.rect(x - 7 * s, g - 5 * s, 14 * s, s, C(0x4A5462))
    }

    /// Where the Batmobile sits: left edge, length and the top of its body.
    static func batcaveCarFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, len: Int, by: Int) {
        let s = unit(g), len = 62 * s
        return (Int(Double(c.w) * 0.97) - len - 8 * s, len, g - 11 * s)
    }

    /// The Batmobile on its turntable, picked out by the blue light of the cave.
    static func batcaveCar(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = batcaveCarFrame(c, g), x = f.x, len = f.len, by = f.by
        c.ellipse(x + len / 2 + 4 * s, g - s, len / 2 + 10 * s, 2 * s, C(0x262C34))
        for k in stride(from: x - 6 * s, to: x + len + 14 * s, by: 6 * s) { c.rect(k, g - s, s, s, C(0x3AA8E8, 0.7)) }
        let body = C(0x2A303C), dark = C(0x181C24), rim = C(0x7A9AC4)
        // rear fins sweeping up
        for k in 0..<8 {
            let w = (3 + k * 2) * s
            c.rect(x, by - 8 * s + k * s, w, s, body)
            c.rect(x + w - s, by - 8 * s + k * s, s, s, rim)
        }
        c.rect(x, by - 8 * s, 3 * s, s, rim)
        c.rect(x, by, len, 7 * s, body)
        c.rect(x, by + 4 * s, len, 3 * s, dark)
        c.rect(x + 8 * s, by + 3 * s, len - 14 * s, s, C(0x2E3644))
        c.rect(x, by, len, s, rim)
        // the long nose tapering down
        for k in 0..<6 {
            c.rect(x + len, by + k * s, (12 - k * 2) * s, s, k < 4 ? body : dark)
            c.px(x + len + (12 - k * 2) * s - s, by + k * s, rim)
        }
        c.rect(x + len, by, 12 * s, s, rim)
        // the canopy
        c.ellipse(x + len / 2 - 2 * s, by, 12 * s, 4 * s, body)
        c.ellipse(x + len / 2 - s, by - s, 9 * s, 3 * s, C(0x24384E))
        c.rect(x + len / 2 - 7 * s, by - 3 * s, 6 * s, s, C(0x9AC0E0))
        c.rect(x + len / 2 - 12 * s, by - 2 * s, 2 * s, 2 * s, rim)
        // wheels
        for wx in [x + 11 * s, x + len - 6 * s] {
            c.circle(wx, by + 7 * s, 5 * s, C(0x060608)); c.circle(wx, by + 7 * s, 3 * s, C(0x2A2E38))
            c.circle(wx, by + 7 * s, s, C(0x6A88B0))
        }
        c.rect(x + len + 9 * s, by + s, 3 * s, s, C(0xFFE8A0))
        c.rect(x - s, by + s, s, 3 * s, C(0xE03A2A))
    }

    /// Water pouring down, the Batcomputer's readouts ticking over, the turbine's glow and bats flitting overhead.
    static func batcaveLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = batcaveFall(c, g), h = g - f.top
        for k in 0..<f.w {
            for j in 0..<max(1, h / (10 * s)) {
                let speed = 70.0 + noise(k * 13 + j) * 40
                let y = f.top + Int((noise(k * 31 + j * 7) * Double(h) + t * speed).truncatingRemainder(dividingBy: Double(h)))
                c.rect(f.x + k, y, 1, 3 * s, C(0xC8E4F0, 0.45))
            }
        }
        for i in 0..<6 {
            let ph = scenes1Phase(t, 1.2, offset: Double(i) * 0.2)
            let x = f.x + f.w / 2 + Int((noise(i + 50) - 0.5) * Double(f.w + 8 * s))
            c.circle(x, g - 2 * s - Int(ph * 6.0 * Double(s)), s, C(0xDCEEF6, 0.4 * (1 - ph)))
        }
        // the screens
        let scr = batcaveScreens(c, g)
        for (i, r) in scr.enumerated() where i > 0 {
            let lines = r.h / (2 * s) - 1, shift = Int(t * 3)
            for j in 0..<lines {
                let n = noise((j + shift) * 7 + i * 100)
                c.rect(r.x + 2 * s, r.y + s + j * 2 * s, Int(n * Double(r.w - 4 * s)), max(1, s / 2), C(0x7AE0FF, 0.55))
            }
        }
        let m = scr[0]
        let sweep = scenes1Phase(t, 3.0)
        c.rect(m.x + Int(sweep * Double(m.w)), m.y, s, m.h, C(0x8AE8FF, 0.35))
        for k in 0..<8 {
            let hgt = Int((0.3 + 0.7 * noise(Int(t * 4) * 11 + k)) * Double(6 * s))
            c.rect(m.x + 2 * s + k * 2 * s, m.y + m.h - s - hgt, s, hgt, C(0x6AF0B0, 0.6))
        }
        if scenes1Phase(t, 1.0) < 0.5 { c.rect(m.x + m.w - 5 * s, m.y + m.h - 4 * s, 3 * s, 2 * s, C(0xFF4A3A)) }
        // the Batmobile's turbine
        let car = batcaveCarFrame(c, g)
        c.circle(car.x - 2 * s, car.by + 3 * s, 2 * s + Int(noise(Int(t * 12)) * 2.0), C(0xFF8A3A, 0.4))
        c.rect(car.x - 2 * s, car.by + 2 * s, s, 2 * s, C(0xFFC87A))
        // bats
        let tall = isTall(c)
        for i in 0..<(tall ? 9 : 5) {
            let ax = 0.3 + noise(i + 7) * 0.5, ay = 0.5 + noise(i + 17) * 0.6
            let x = Int(Double(c.w) * noise(i + 27) + sin(t * ax + Double(i)) * Double(c.w) * 0.15)
            let y = Int(Double(tall ? g / 2 : 22 * s) * (0.3 + noise(i + 37) * 0.6) + sin(t * ay * 1.7 + Double(i) * 2) * Double(6 * s))
            scenes1Flapper(c, x, y, up: Int(t * 8 + Double(i)) % 2 == 0, C(0x4A5262), s: s)
        }
    }
}

// MARK: - Fortress of Solitude

extension Scenes {
    /// The Fortress of Solitude: an arctic night, stars, distant ice ridges, and the fortress itself, a great cluster of
    /// pale crystal spires leaning out of the snowfield with a cold light at its heart. Lone shards stand out on the ice
    /// either side, and the aurora ripples green and violet across the sky.
    static func fortress(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x040818), C(0x1C3A58), bands: 8)
        c.stars(0, g * 2 / 3, density: tall ? 70 : 50, seed: 12)
        // far peaks
        for i in 0..<(c.w / (30 * s)) {
            let x = Int(noise(i * 3 + 640) * Double(c.w)), hgt = Int(Double((tall ? 40 : 14) * s) + noise(i * 3 + 641) * Double((tall ? 70 : 16) * s))
            let half = hgt + Int(noise(i * 3 + 642) * Double(hgt / 2)), foot = g - (tall ? 24 : 8) * s, peak = foot - hgt
            scenes1Spike(c, x, peak, foot, half: half, C(0x34567A))
            for y in peak..<foot { c.rect(x + 1, y, half * (y - peak) / max(1, hgt), 1, C(0x26445F)) }
            scenes1Spike(c, x, peak, peak + hgt / 5, half: half / 5, C(0xA8C4E0, 0.8))
        }
        c.dunes(base: g - (tall ? 40 : 16) * s, amp: Double((tall ? 14 : 5) * s), freq: 0.02, phase: 1, bottom: g, C(0x2A4664), shade: C(0x5A82A8))
        c.dunes(base: g - (tall ? 22 : 9) * s, amp: Double((tall ? 8 : 3) * s), freq: 0.035, phase: 4, bottom: g, C(0x3E6488), shade: C(0x8AB4D4))
        // the fortress
        let cx = Int(Double(c.w) * 0.58), hmax = Double(g) * (tall ? 0.78 : 0.86)
        c.ellipse(cx, g - 10 * s, 70 * s, 26 * s, C(0x8AD8FF, 0.06))
        for i in 0..<24 {
            let spread = (noise(i * 5 + 600) - 0.5) * (noise(i * 5 + 604) * 0.6 + 0.4)
            let dx = Int(spread * 90.0 * Double(s))
            let k = 1 - abs(Double(dx)) / (40.0 * Double(s))
            let hgt = Int(hmax * (0.35 + 0.65 * max(0.2, k) * (0.6 + noise(i * 5 + 601) * 0.4)))
            let lean = Int(Double(dx) * 0.5 + (noise(i * 5 + 602) - 0.5) * 10.0 * Double(s))
            let w = (5 + Int(noise(i * 5 + 603) * 8.0)) * s
            fortressShard(c, cx + dx, g + 2 * s, w: w, h: hgt, lean: lean, dark: i % 3 == 0)
        }
        c.ellipse(cx, g - 3 * s, 10 * s, 6 * s, C(0xC8F4FF, 0.18))
        // lone shards out on the ice
        for i in 0..<10 {
            let x = Int(noise(i * 5 + 700) * Double(c.w))
            if abs(x - cx) < 50 * s { continue }
            let hgt = Int(Double((tall ? 18 : 8) * s) + noise(i * 5 + 701) * Double((tall ? 50 : 16) * s))
            fortressShard(c, x, g + s, w: (3 + Int(noise(i * 5 + 702) * 3.0)) * s, h: hgt,
                          lean: Int((noise(i * 5 + 703) - 0.5) * Double(hgt) * 0.5), dark: true)
        }
        c.ground(g, C(0xC6DAE8), edge: C(0xF2FAFF), speck: C(0xA8C2D6), seed: 17)
        for i in 0..<(c.w / 30) {
            let x = Int(noise(i * 3 + 800) * Double(c.w)), y = g + 2 * s + Int(noise(i * 3 + 801) * Double(max(1, c.h - g - 3 * s)))
            c.ellipse(x, y, (6 + Int(noise(i * 3 + 802) * 10.0)) * s, s, C(0x8AAAC8, 0.5))
        }
    }

    /// One crystal: pointed at the top, lit face on the left, shaded face on the right, standing on row `base`.
    static func fortressShard(_ c: PixelCanvas, _ x: Int, _ base: Int, w: Int, h: Int, lean: Int, dark: Bool) {
        guard h > 2 else { return }
        let light = dark ? C(0x7EB8D8) : C(0xCDEFFC), mid = dark ? C(0x4E86AE) : C(0x8CCAE8), edge = C(0xF4FCFF)
        let tip = max(2, h / 4)
        for y in 0..<h {
            let up = Double(y) / Double(h)
            let cx = x + Int(Double(lean) * up)
            let fromTop = h - y
            let half = fromTop < tip ? max(0, w / 2 * fromTop / tip) : w / 2
            let row = base - y
            c.rect(cx - half, row, half, 1, light)
            c.rect(cx, row, half + 1, 1, mid)
            c.px(cx - half, row, edge.alpha(0.8))
        }
    }

    /// The aurora rippling, glints running up the crystals and a little snow blowing past.
    static func fortressLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c)
        let top = tall ? g / 10 : 0, amp = Double((tall ? 14 : 4) * s), len = (tall ? 50 : 18) * s
        let step = 2 * s
        for x in stride(from: 0, to: c.w, by: step) {
            let fx = Double(x)
            let y = top + Int(amp * (1 + sin(fx * 0.013 + t * 0.5) * 0.7 + sin(fx * 0.041 - t * 0.9) * 0.3))
            let bright = 0.5 + 0.5 * sin(fx * 0.03 + t * 1.3)
            let l = Int(Double(len) * (0.6 + 0.4 * sin(fx * 0.021 - t * 0.4)))
            c.rect(x, y, step, s, C(0xB8FFD8, 0.25 + 0.3 * bright))
            c.rect(x, y + s, step, l / 3, C(0x5AF0A0, 0.18 + 0.2 * bright))
            c.rect(x, y + s + l / 3, step, l / 3, C(0x3AD8A8, 0.10 + 0.12 * bright))
            c.rect(x, y + s + l * 2 / 3, step, l / 3, C(0x9A6AE8, 0.07 + 0.08 * bright))
        }
        // glints on the fortress
        let cx = Int(Double(c.w) * 0.58)
        for i in 0..<5 {
            let ph = scenes1Phase(t, 2.6, offset: Double(i) * 0.53)
            guard ph < 0.25 else { continue }
            let x = cx + Int((noise(i * 3 + 950) - 0.5) * 60.0 * Double(s))
            let y = g - Int(Double(g) * (0.2 + noise(i * 3 + 951) * 0.4))
            let a = 1 - abs(ph - 0.125) * 8
            c.rect(x - 2 * s, y, 5 * s, s, C(0xFFFFFF, a)); c.rect(x, y - 2 * s, s, 5 * s, C(0xFFFFFF, a))
        }
        // blowing snow
        for i in 0..<(c.w * c.h / 600) {
            let speed = 30.0 + noise(i * 3 + 11) * 30
            let x = Int((noise(i * 3 + 12) * Double(c.w + 40) + t * speed * 1.5).truncatingRemainder(dividingBy: Double(c.w + 40))) - 20
            let y = Int((noise(i * 3 + 13) * Double(c.h) + t * speed * 0.5).truncatingRemainder(dividingBy: Double(c.h)))
            c.rect(x, y, s, s, C(0xF0F8FF, 0.6))
        }
    }
}

// MARK: - Themyscira

extension Scenes {
    /// The horizon row of the sea.
    static func themysciraHorizon(_ c: PixelCanvas, _ g: Int) -> Int {
        isTall(c) ? g - g / 3 : g - 26 * unit(g)
    }

    static func themysciraSun(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int) {
        (Int(Double(c.w) * 0.8), isTall(c) ? g / 4 : 13 * unit(g))
    }

    /// Themyscira in the late sun: the crew is on a white marble terrace above the sea. Off to the left a sheer cliff
    /// climbs out of the water with a columned temple on top, an island with a smaller temple floats on the horizon,
    /// the sun hangs over the Aegean blue, and dark cypresses and a broken column frame the terrace.
    static func themyscira(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), hy = themysciraHorizon(c, g), sun = themysciraSun(c, g)
        c.gradient(0, hy, C(0x2E84D6), C(0xF6DEAA), bands: 8)
        for r in [26, 18, 12] { c.circle(sun.x, sun.y, r * s, C(0xFFF2C0, 0.12)) }
        c.circle(sun.x, sun.y, 7 * s, C(0xFFF6D8))
        for i in 0..<(tall ? 5 : 2) {
            wisp(c, Int(noise(i * 5 + 40) * Double(c.w)), (tall ? g / 10 : 4 * s) + Int(noise(i * 5 + 41) * Double(tall ? g / 3 : 8 * s)),
                 (24 + Int(noise(i * 5 + 42) * 30.0)) * s, C(0xFFF6E8, 0.6), s: s)
        }
        if tall {
            for i in 0..<4 {
                cloud(c, Int(noise(i * 5 + 50) * Double(c.w)), g / 12 + Int(noise(i * 5 + 51) * Double(g / 4)),
                      (4 + Int(noise(i * 5 + 52) * 4.0)) * s, seed: i + 60, top: C(0xFFFBF2), base: C(0xF0E2CC))
            }
            // far islands along the horizon
            for (fx, w) in [(0.08, 60), (0.36, 34), (0.92, 48)] {
                c.ellipse(Int(Double(c.w) * fx), hy, w * s, 6 * s, C(0x8AA6B8))
            }
        }
        // the sea
        c.gradient(hy, g, C(0x2A7AB8), C(0x14508A), bands: 5)
        for y in stride(from: hy + 2 * s, to: g, by: 3 * s) {
            for i in 0..<(c.w / 30) {
                let x = Int(noise(y * 13 + i * 7) * Double(c.w))
                c.rect(x, y, (3 + Int(noise(y * 7 + i) * 6.0)) * s, max(1, s / 2) + 0, C(0x6AB0E0, 0.35))
            }
        }
        // the island on the horizon, with its town and temple
        let ix = Int(Double(c.w) * 0.6), iw = (tall ? 70 : 40) * s, ih = (tall ? 22 : 9) * s
        for k in -iw...iw {
            let f = Double(k) / Double(iw), top = hy - Int(Double(ih) * (1 - f * f) * (0.85 + noise(k / max(1, s) + 90) * 0.15))
            c.rect(ix + k, top, 1, hy - top, k > iw / 3 ? C(0x5A7E90) : C(0x6A8E9E))
        }
        for i in 0..<(tall ? 10 : 4) {
            let hx = ix - iw / 2 + Int(noise(i + 120) * Double(iw)), hh = (2 + Int(noise(i + 121) * 2.0)) * s
            let f = Double(hx - ix) / Double(iw), top = hy - Int(Double(ih) * (1 - f * f) * 0.8)
            c.rect(hx, top - hh, 3 * s, hh, C(0xDCE4E8))
        }
        themysciraTemple(c, ix, hy - ih + s, cols: 4, s: s, scale: 1, stone: C(0xE4EAEE), shade: C(0xA8B4BC))
        // the cliff with its temple
        let ct = tall ? Int(Double(g) * 0.42) : 22 * s, cw = Int(Double(c.w) * 0.3)
        for x in 0..<cw {
            let k = Double(x) / Double(cw)
            let top = ct + Int(pow(max(0, k - 0.6) / 0.4, 2) * Double(g - ct - 4 * s)) + Int(noise(x / max(1, s) + 3) * 2.0) * s
            let face = k > 0.6
            for y in stride(from: top, to: g, by: s) {
                let band = ((y + x / 6) / (3 * s)) % 3
                var col = band == 0 ? C(0xC8A47C) : band == 1 ? C(0xBC9872) : C(0xD2AE86)
                if face { col = lerp(col, C(0x8A6A4E), 0.35) }
                c.rect(x, y, 1, s, col)
            }
            c.rect(x, top, 1, 2 * s, C(0x6A8A3A))
            if face { c.rect(x, top + 2 * s, 1, s, C(0x4A6A2A)) }
        }
        for i in 0..<(cw / 3) {
            let x = Int(noise(i + 444) * Double(cw) * 0.85), y = ct + 4 * s + Int(noise(i + 445) * Double(g - ct))
            c.rect(x, y, (2 + Int(noise(i + 446) * 8.0)) * s, s, C(0x7A5A40, 0.55))
            if noise(i + 447) > 0.7 { c.rect(x, y + s, s, (2 + Int(noise(i + 448) * 4.0)) * s, C(0x7A5A40, 0.45)) }
        }
        themysciraTemple(c, cw * 2 / 5, ct, cols: tall ? 8 : 6, s: s, scale: tall ? 2 : 1, stone: C(0xF4F0E6), shade: C(0xCAC2B0))
        c.rect(cw - 2 * s, g - 3 * s, 20 * s, 3 * s, C(0xEAF4FF, 0.5))
        // cypresses and a broken column
        for (k, fx) in [0.36, 0.4, 0.9].enumerated() {
            let x = Int(Double(c.w) * fx), hgt = (tall ? 46 : 26 + k * 3) * s
            c.rect(x - s / 2, g - 4 * s, max(1, s), 4 * s, C(0x4A3420))
            c.ellipse(x, g - 4 * s - hgt / 2, 4 * s, hgt / 2, C(0x22402A))
            c.ellipse(x - s, g - 4 * s - hgt / 2, 2 * s, hgt / 2 - 2 * s, C(0x3A5E36))
        }
        let bx = Int(Double(c.w) * 0.96), bh = (tall ? 40 : 20) * s
        c.rect(bx - 4 * s, g - bh, 8 * s, bh, C(0xEEE8DA))
        for k in stride(from: bx - 3 * s, to: bx + 4 * s, by: 2 * s) { c.rect(k, g - bh, max(1, s / 2), bh, C(0xC8C0AE)) }
        for k in 0..<4 { c.rect(bx - 4 * s + k * 2 * s, g - bh - [2, 0, 3, 1][k] * s, 2 * s, [2, 0, 3, 1][k] * s, C(0xEEE8DA)) }
        c.rect(bx - 6 * s, g - 3 * s, 12 * s, 3 * s, C(0xD8D0C0))
        c.ground(g, C(0xE2DACA), edge: C(0xFFFCF4), speck: C(0xCCC2AE), seed: 19)
        for x in stride(from: 0, to: c.w, by: 14 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0xC8BEAA)) }
        for y in stride(from: g + 5 * s, to: c.h, by: 5 * s) { c.rect(0, y, c.w, s, C(0xD2C8B6)) }
    }

    /// A Greek temple: stepped base, columns, architrave and pediment, standing on row `base` centred at `x`.
    static func themysciraTemple(_ c: PixelCanvas, _ x: Int, _ base: Int, cols: Int, s: Int, scale: Int, stone: Px, shade: Px) {
        let u = s * scale, gap = 5 * u, w = cols * gap + u, x0 = x - w / 2
        let colH = 12 * u
        c.rect(x0 - 2 * u, base - u, w + 4 * u, u, shade)
        c.rect(x0 - u, base - 2 * u, w + 2 * u, u, stone)
        c.rect(x0 - u, base - 2 * u - colH, w + 2 * u, colH, C(0x5A4A3A, 0.55))
        for k in 0...cols {
            let cx = x0 + k * gap
            c.rect(cx, base - 2 * u - colH, 2 * u, colH, stone)
            c.rect(cx + u, base - 2 * u - colH, max(1, u / 2), colH, shade)
        }
        let ay = base - 2 * u - colH
        c.rect(x0 - u, ay - 3 * u, w + 2 * u, 3 * u, stone)
        c.rect(x0 - u, ay - u, w + 2 * u, u, shade)
        let ph = max(2, w / 6)
        for k in 0..<ph {
            let half = (w / 2 + u) * (k + 1) / ph
            c.rect(x0 + w / 2 - half, ay - 3 * u - ph + k, half * 2, 1, k == 0 ? shade : stone)
        }
    }

    /// The sea glittering, foam at the foot of the cliff and gulls wheeling.
    static func themysciraLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), hy = themysciraHorizon(c, g), sun = themysciraSun(c, g)
        let frame = Int(t * 6)
        for i in 0..<(c.w / 6) {
            let n = noise(frame * 97 + i * 3)
            guard n > 0.55 else { continue }
            let near = noise(i * 3 + 1)
            let y = hy + Int(near * Double(g - hy - s))
            let spread = 10 * s + (y - hy)
            let x = noise(i * 3 + 2) > 0.5 ? sun.x - spread / 2 + Int(noise(i * 5 + frame) * Double(spread))
                : Int(noise(i * 7 + frame * 3) * Double(c.w))
            c.rect(x, y, 2 * s, max(1, s / 2), C(0xFFF6D8, 0.7))
        }
        let cw = Int(Double(c.w) * 0.3), ph = scenes1Phase(t, 3)
        let foam = Int((sin(ph * 2 * Double.pi) * 0.5 + 0.5) * Double(6 * s))
        c.rect(cw - 4 * s, g - 2 * s, 12 * s + foam, s, C(0xFFFFFF, 0.6))
        c.rect(cw + 2 * s, g - 4 * s, 6 * s + foam / 2, s, C(0xFFFFFF, 0.35))
        let tall = isTall(c)
        for i in 0..<(tall ? 5 : 3) {
            let speed = 12.0 + noise(i + 60) * 10
            let x = Int((noise(i + 61) * Double(c.w) + t * speed).truncatingRemainder(dividingBy: Double(c.w + 20))) - 10
            let y = (tall ? g / 6 : 8 * s) + Int(noise(i + 62) * Double(tall ? g / 3 : 14 * s)) + Int(sin(t * 1.3 + Double(i)) * 3.0 * Double(s))
            scenes1Flapper(c, x, y, up: Int(t * 3 + Double(i) * 0.7) % 2 == 0, C(0xF8F8F8), s: s)
        }
    }
}

// MARK: - Atlantis

extension Scenes {
    /// The domes of Atlantis: centre, radius across and radius up.
    static func atlantisDomes(_ c: PixelCanvas, _ g: Int) -> [(x: Int, rx: Int, ry: Int)] {
        let s = unit(g), tall = isTall(c), m = tall ? 2 : 1
        return [(Int(Double(c.w) * 0.5), 64 * s * m, (tall ? 92 : 40) * s), (Int(Double(c.w) * 0.18), 34 * s * m, 26 * s * m),
                (Int(Double(c.w) * 0.84), 40 * s * m, 30 * s * m)]
    }

    /// Atlantis on the sea floor: blue water fading down into the deep, shafts of sunlight slanting from the surface,
    /// the city's glass domes over teal and gold towers with glowing windows, kelp swaying and coral at the edges, and
    /// the crew on the paved plaza in front.
    static func atlantis(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x2A86A8), C(0x0A3448), bands: 8)
        // light shafts
        for i in 0..<6 {
            let x0 = Int(noise(i * 3 + 30) * Double(c.w)), w = (8 + Int(noise(i * 3 + 31) * 14.0)) * s
            for y in 0..<g {
                let a = 0.09 * (1 - Double(y) / Double(g))
                c.rect(x0 + y / 3, y, w, 1, C(0xC8F4FF, a))
            }
        }
        if tall {                                            // the surface far overhead, rippling with light
            for y in 0..<(10 * s) {
                for x in stride(from: 0, to: c.w, by: 2 * s) where sin(Double(x) * 0.09 + Double(y) * 0.7) + noise(x + y * 7) > 1.2 {
                    c.rect(x, y, 2 * s, 1, C(0xD8FCFF, 0.3 * (1 - Double(y) / Double(10 * s))))
                }
            }
        }
        // far towers in the haze
        for i in 0..<(c.w / (14 * s)) {
            let x = Int(noise(i * 4 + 200) * Double(c.w)), hgt = Int(Double(g) * (0.15 + noise(i * 4 + 201) * 0.3))
            let w = (4 + Int(noise(i * 4 + 202) * 6.0)) * s
            c.rect(x - w / 2, g - hgt, w, hgt, C(0x1E5E72, 0.7))
            c.ellipse(x, g - hgt, w / 2 + s, w / 2, C(0x1E5E72, 0.7))
        }
        c.dunes(base: g - 8 * s, amp: Double(3 * s), freq: 0.03, phase: 2, bottom: g, C(0x1C4A56), shade: C(0x3A7A80))
        for (k, d) in atlantisDomes(c, g).enumerated() { atlantisDome(c, g, d.x, d.rx, d.ry, seed: k) }
        // kelp and coral
        for i in 0..<(c.w / 40) {
            let x = Int(noise(i * 5 + 400) * Double(c.w)), hgt = Int(Double((tall ? 30 : 14) * s) + noise(i * 5 + 401) * Double((tall ? 60 : 20) * s))
            for y in 0..<hgt {
                let dx = Int(sin(Double(y) * 0.25 / Double(s) + Double(i)) * 1.5 * Double(s))
                c.rect(x + dx, g - y, 2 * s, 1, C(0x2A7A4A))
                if y % (5 * s) == 0 { c.rect(x + dx + 2 * s, g - y, 2 * s, s, C(0x3A9A5A)) }
            }
        }
        for (fx, col) in [(0.04, C(0xE8705A)), (0.31, C(0xE8A84A)), (0.67, C(0xC85A9A)), (0.95, C(0xE8705A))] {
            let x = Int(Double(c.w) * fx)
            for k in 0..<5 {
                let bx = x + (k - 2) * 2 * s, bh = (4 + Int(noise(k + Int(fx * 100)) * 6.0)) * s
                c.rect(bx, g - bh, s, bh, col)
                c.rect(bx - s, g - bh, 3 * s, s, lerp(col, white, 0.3))
            }
        }
        c.ground(g, C(0x22495A), edge: C(0x6AB0BA), speck: C(0x1A3C4A), seed: 23)
        for x in stride(from: 0, to: c.w, by: 12 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x1A3E4C)) }
        for y in stride(from: g + 4 * s, to: c.h, by: 4 * s) { c.rect(0, y, c.w, max(1, s / 2), C(0x1A3E4C)) }
    }

    /// One glass dome over its towers.
    static func atlantisDome(_ c: PixelCanvas, _ g: Int, _ x: Int, _ rx: Int, _ ry: Int, seed: Int) {
        let s = unit(g), base = g - 2 * s
        // the towers inside
        let n = max(3, rx / (7 * s))
        for k in 0..<n {
            let fx = (Double(k) + 0.5) / Double(n) * 2 - 1
            let hmax = Double(ry) * (1 - fx * fx).squareRoot() * 0.9
            let hgt = Int(hmax * (0.45 + noise(k * 3 + seed * 50) * 0.55))
            let tx = x + Int(fx * Double(rx) * 0.85), w = (4 + Int(noise(k * 3 + 1 + seed * 50) * 4.0)) * s
            c.rect(tx - w / 2, base - hgt, w, hgt, C(0x1E6A6E))
            c.rect(tx - w / 2, base - hgt, max(1, s), hgt, C(0x3A9A96))
            if k % 3 == 1 {
                c.circle(tx, base - hgt, w / 2 + s, C(0xC8A84A)); c.circle(tx - s, base - hgt - s, max(1, w / 4), C(0xF0D880))
            } else {
                scenes1Spike(c, tx, base - hgt - 6 * s, base - hgt, half: w / 2, C(0xC8A84A))
            }
            for y in stride(from: base - hgt + 3 * s, to: base, by: 4 * s) { c.rect(tx - w / 2 + s, y, w - 2 * s, s, C(0x8AF0D8, 0.5)) }
        }
        // the glass
        var prev = rx
        for dy in 0...ry {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int((Double(rx) * k.squareRoot()).rounded())
            c.rect(x - half, base - dy, half * 2 + 1, 1, C(0x8AE8F8, 0.10))
            let run = max(s, prev - half)
            c.rect(x - half - run + s, base - dy, run, 1, C(0xB8F4FF, 0.6)); c.rect(x + half, base - dy, run, 1, C(0xB8F4FF, 0.6))
            prev = half
        }
        for a in [Double.pi / 3, Double.pi * 2 / 3] {
            for i in 0..<ry {
                let yy = Double(i), xx = cos(a) * Double(rx) * (1 - yy * yy / Double(ry * ry)).squareRoot()
                c.px(x + Int(xx), base - i, C(0xB8F4FF, 0.25))
            }
        }
        c.ellipse(x - rx / 3, base - ry * 2 / 3, rx / 6, max(1, ry / 8), C(0xFFFFFF, 0.18))
        if seed == 0 {                                       // the golden trident crowning the great dome
            let top = base - ry, gold = C(0xE8C860)
            c.circle(x, top, 3 * s, C(0xC8A84A))
            c.rect(x - s / 2, top - 16 * s, max(1, s), 16 * s, gold)
            c.rect(x - 5 * s, top - 14 * s, 10 * s + 1, s, gold)
            for dx in [-5, 0, 5] {
                c.rect(x + dx * s - s / 2, top - 20 * s, max(1, s), 6 * s, gold)
                c.rect(x + dx * s - s / 2 - s, top - 19 * s, max(1, s), s, gold); c.rect(x + dx * s - s / 2 + s, top - 19 * s, max(1, s), s, gold)
            }
            c.circle(x, top - 15 * s, 10 * s, C(0xFFF0A0, 0.08))
        }
        c.rect(x - rx - 2 * s, base, rx * 2 + 4 * s, 2 * s, C(0xC8A84A))
    }

    /// Fish schooling past, bubbles rising and the sunlight rippling on the plaza.
    static func atlantisLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c)
        let schools: [(y: Double, speed: Double, col: UInt32, n: Int)] = [
            (0.2, 18, 0xF0A040, 7), (0.45, -13, 0xC8D8E8, 9), (0.12, -24, 0xF0E060, 5)]
        for (k, sc) in schools.enumerated() {
            let span = Double(c.w + 80 * s)
            let lead = (t * sc.speed * Double(s) + noise(k + 3) * span).truncatingRemainder(dividingBy: span)
            let headX = (lead < 0 ? lead + span : lead) - Double(40 * s)
            for f in 0..<sc.n {
                let x = Int(headX - (sc.speed > 0 ? 1 : -1) * Double(f % 4) * 6 * Double(s)) + Int(noise(f + k * 20) * 10.0) * s
                let y = Int(Double(g) * sc.y) + (f / 4 - 1) * 4 * s + Int(sin(t * 2 + Double(f)) * 2.0 * Double(s))
                let art = [".##.#", "#####", ".##.#"]
                let pal: [Character: Px] = ["#": C(sc.col)]
                if sc.speed > 0 { scenes1StampFlipped(c, x, y, art, pal, s: s) } else { scenes1Stamp(c, x, y, art, pal, s: s) }
            }
        }
        if tall {
            let x = Int(scenes1Phase(t, 40) * Double(c.w + 120 * s)) - 60 * s, y = g / 4 + Int(sin(t * 0.7) * 6.0)
            scenes1Stamp(c, x, y, [
                "......##......",
                "....######....",
                "##############",
                ".############.",
                "......##......",
                "......#.......",
                ".....#........",
            ], ["#": C(0x0E2E3E, 0.8)], s: 2 * s)
        }
        for i in 0..<(tall ? 26 : 12) {
            let period = 4.0 + noise(i + 70) * 3
            let ph = scenes1Phase(t, period, offset: noise(i + 71) * period)
            let x0 = Int(noise(i + 72) * Double(c.w))
            let y = g - Int(ph * Double(g + 10))
            let x = x0 + Int(sin(ph * 12 + Double(i)) * 2.0 * Double(s))
            let r = noise(i + 73) > 0.7 ? 2 * s : s
            if r > s {
                c.rect(x - s, y - r, 2 * s, s, C(0xD8F8FF, 0.6)); c.rect(x - s, y + r - s, 2 * s, s, C(0xD8F8FF, 0.6))
                c.rect(x - r, y - s, s, 2 * s, C(0xD8F8FF, 0.6)); c.rect(x + r - s, y - s, s, 2 * s, C(0xD8F8FF, 0.6))
            } else {
                c.rect(x, y, s, s, C(0xD8F8FF, 0.6))
            }
        }
        let frame = Int(t * 4)
        for i in 0..<(c.w / 12) {
            let x = Int(noise(i * 3 + 990) * Double(c.w)) + Int(sin(t + Double(i)) * 3.0 * Double(s))
            let y = g + s + Int(noise(i * 3 + 991) * Double(max(1, c.h - g - 2 * s)))
            let a = 0.15 + 0.25 * noise(frame * 31 + i)
            c.rect(x, y, (3 + i % 4) * s, max(1, s / 2) + 0, C(0xC8F8FF, a))
        }
    }
}
