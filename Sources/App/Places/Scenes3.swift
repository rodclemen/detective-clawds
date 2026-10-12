import Foundation

let scenes3: [Location: Place] = [
    .apokolips: Place(name: "Apokolips", panel: 0x200C0A, still: Scenes.apokolips, moving: Scenes.apokolipsLife),
    .krypton: Place(name: "Krypton", panel: 0x221210, still: Scenes.krypton, moving: Scenes.kryptonLife),
    .titansTower: Place(name: "Titans Tower", panel: 0x101828, still: Scenes.titansTower, moving: Scenes.titansTowerLife),
    .smallville: Place(name: "Smallville", panel: 0x1E1C16, still: Scenes.smallville, moving: Scenes.smallvilleLife),
    .strykersIsland: Place(name: "Stryker's Island", panel: 0x14181E, still: Scenes.strykersIsland, moving: Scenes.strykersIslandLife),
    .belleReve: Place(name: "Belle Reve", panel: 0x141A12, still: Scenes.belleReve, moving: Scenes.belleReveLife),
]

// MARK: - Shared bits for these scenes

extension Scenes {
    /// String art drawn with every character `s` pixels square.
    static func scenes3Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes3Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// A cone of light from (x0, y0) to (x1, y1), `spread` pixels either side at the far end.
    static func scenes3Beam(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, spread: Double, _ col: Px) {
        let dx = x1 - x0, dy = y1 - y0
        let len = max(abs(dx), abs(dy))
        guard len >= 1 else { return }
        let full = (dx * dx + dy * dy).squareRoot()
        let n = Int(len)
        for i in 0...n {
            let u = Double(i) / Double(n)
            let x = x0 + dx * u, y = y0 + dy * u, half = 1 + spread * u
            if abs(dy) >= abs(dx) {
                let run = half * full / abs(dy)
                c.rect(Int(x - run), Int(y), max(1, Int(run * 2)), 1, col)
            } else {
                let run = half * full / abs(dx)
                c.rect(Int(x), Int(y - run), 1, max(1, Int(run * 2)), col)
            }
        }
    }

    /// A sharp crystal shard standing on row `base`: lit left face, shaded right face, a bright ridge.
    static func scenes3Shard(_ c: PixelCanvas, _ x: Int, _ base: Int, half: Int, h: Int, lit: Px, shade: Px, ridge: Px, lean: Int = 0) {
        guard h > 0, half > 0 else { return }
        let top = base - h
        for y in top..<base {
            let k = Double(y - top) / Double(h)
            let hw = max(0, Int((Double(half) * min(1, k * 1.6)).rounded()))
            let cx = x + Int(Double(lean) * (1 - k))
            c.rect(cx - hw, y, hw, 1, lit)
            c.rect(cx, y, hw + 1, 1, shade)
            c.px(cx, y, ridge)
        }
    }
}

// MARK: - Apokolips

extension Scenes {
    /// Darkseid's tower: centre, width and top row.
    static func apokolipsTower(_ c: PixelCanvas, _ g: Int) -> (x: Int, w: Int, top: Int, f: Int) {
        let f = max(1, g / 80)
        return (Int(Double(c.w) * 0.66), 34 * f, isTall(c) ? g / 7 : -2, f)
    }

    /// The fire pits in the middle distance: centre and half-width.
    static func apokolipsPits(_ c: PixelCanvas, _ g: Int) -> [(x: Int, r: Int)] {
        let s = unit(g)
        var out: [(x: Int, r: Int)] = []
        var x = 20 * s, i = 0
        let tower = apokolipsTower(c, g)
        while x < c.w {
            if abs(x - tower.x) > tower.w / 2 + 14 * s { out.append((x, (7 + Int(noise(i * 5 + 900) * 6)) * s)) }
            x += (70 + Int(noise(i * 5 + 901) * 50)) * s
            i += 1
        }
        return out
    }

    /// Apokolips: a smoky blood-red sky over a skyline of black slab towers and smokestacks, their slit windows
    /// glowing like furnaces. Darkseid's own tower stands over them all with his stone face carved into it, heavy brow,
    /// deep-lined cheeks and burning eyes. Fire pits roar along the plain below, and the ground is scorched rock run
    /// through with lava seams.
    static func apokolips(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x14060A), C(0x9A3216), bands: 8)
        for k in 0..<5 { c.rect(0, g - 6 * s - k * 6 * s, c.w, 6 * s, C(0xFF6A1E, 0.07)) }
        // banks of smoke
        let banks = c.w / 36 * (tall ? 4 : 1)
        for i in 0..<banks {
            let x = Int(noise(i * 7 + 800) * Double(c.w))
            let y = Int(noise(i * 7 + 801) * Double(g) * (tall ? 0.7 : 0.45))
            let rx = (18 + Int(noise(i * 7 + 802) * 30)) * s, ry = (2 + Int(noise(i * 7 + 803) * 4)) * s
            c.ellipse(x, y, rx, ry, C(0x1E0A0A, 0.45))
            c.ellipse(x + rx / 4, y + ry / 2, rx * 2 / 3, max(1, ry / 2), C(0xC8482A, 0.12))
        }
        if tall { apokolipsHigh(c, g) }
        // far towers, then nearer ones
        apokolipsSkyline(c, g, lo: 0.30, hi: 0.75, col: C(0x3A1814), glow: C(0xFF8A3A, 0.55), seed: 1)
        apokolipsSkyline(c, g, lo: 0.16, hi: 0.42, col: C(0x200C0C), glow: C(0xFFB050, 0.75), seed: 2)
        apokolipsDarkseid(c, g)
        // the plain, with the fire pits dug into it
        let plain = g - 9 * s
        c.rect(0, plain, c.w, g - plain, C(0x2A1210))
        c.rect(0, plain, c.w, s, C(0x5A2418))
        for p in apokolipsPits(c, g) {
            c.ellipse(p.x, plain + 2 * s, p.r + 3 * s, 3 * s, C(0x140808))
            c.ellipse(p.x, plain + 2 * s, p.r, 2 * s, C(0xFF7A20))
            c.ellipse(p.x, plain + 2 * s, p.r / 2, s, C(0xFFE08A))
            c.circle(p.x, plain - 2 * s, p.r + 6 * s, C(0xFF6A1E, 0.10))
            c.rect(p.x - p.r - 4 * s, plain + 2 * s, 2 * s, 5 * s, C(0x3A1A14))      // the pit's iron lips
            c.rect(p.x + p.r + 2 * s, plain + 2 * s, 2 * s, 5 * s, C(0x3A1A14))
        }
        c.ground(g, C(0x2A1612), edge: C(0x7A3A22), speck: C(0x1A0C0A), seed: 51)
        for i in 0..<max(3, c.w / 60) {                    // lava seams through the rock
            var x = Int(noise(i * 9 + 950) * Double(c.w)), y = g + 2 * s
            while y < c.h - s {
                c.rect(x, y, s, s, C(0xFF6A1E, 0.8))
                x += noise(x * 3 + y) > 0.5 ? s : -s
                y += s
                if noise(x + y * 7) > 0.85 { c.rect(x, y, 2 * s, s, C(0xFFB050, 0.6)) }
            }
        }
    }

    /// A row of slab towers, smokestacks and spires with glowing slits.
    static func apokolipsSkyline(_ c: PixelCanvas, _ g: Int, lo: Double, hi: Double, col: Px, glow: Px, seed: Int, gap: Int = 0) {
        let s = unit(g)
        var x = -6 * s, i = 0
        while x < c.w {
            let bw = (7 + Int(noise(i * 7 + seed * 211) * 12)) * s
            let bh = Int(Double(g) * (lo + noise(i * 7 + 1 + seed * 211) * (hi - lo)))
            let top = g - bh
            let kind = Int(noise(i * 7 + 2 + seed * 211) * 4)
            switch kind {
            case 0:                                        // a smokestack
                c.rect(x + bw / 4, top, bw / 2, bh, col)
                c.rect(x + bw / 4 - s, top, bw / 2 + 2 * s, 2 * s, col)
                c.rect(x + bw / 4, top + 2 * s, bw / 2, s, glow.alpha(0.5))
            case 1:                                        // a stepped ziggurat block
                c.rect(x, top + bh / 3, bw, bh - bh / 3, col)
                c.rect(x + bw / 5, top + bh / 6, bw * 3 / 5, bh / 6 + 1, col)
                c.rect(x + bw * 2 / 5, top, bw / 5 + 1, bh / 6 + 1, col)
            default:                                       // a slab with a spiked crown
                c.rect(x, top, bw, bh, col)
                for k in stride(from: 0, to: bw, by: 3 * s) { c.rect(x + k, top - 2 * s, s, 2 * s, col) }
                c.rect(x + bw / 2 - s / 2, top - 6 * s, max(1, s), 6 * s, col)
            }
            for (j, wy) in stride(from: top + 4 * s, to: g - 2 * s, by: 5 * s).enumerated()
            where noise(i * 13 + j * 3 + seed * 37) > 0.55 {
                c.rect(x + bw / 2 - s, wy, 2 * s, 2 * s, glow)
            }
            x += bw + Int(noise(i * 7 + 3 + seed * 211) * Double(6 + gap)) * s
            i += 1
        }
    }

    /// Darkseid's tower and the stone face carved into it.
    static func apokolipsDarkseid(_ c: PixelCanvas, _ g: Int) {
        let t = apokolipsTower(c, g), f = t.f, x0 = t.x - t.w / 2
        let stone = C(0x2E1C1A), dark = C(0x1A0E0E)
        // buttressed base flaring out, then the shaft
        for k in 0..<(12 * f) {
            c.rect(x0 - k, g - (12 * f - k) * 3, t.w + 2 * k, (12 * f - k) * 3, stone)
        }
        c.rect(x0, max(0, t.top), t.w, g - max(0, t.top), stone)
        c.rect(x0, max(0, t.top), 2 * f, g - max(0, t.top), C(0x4A2A22))
        c.rect(x0 + t.w - 2 * f, max(0, t.top), 2 * f, g - max(0, t.top), dark)
        if t.top > 0 {                                     // the crown: three horns
            c.rect(x0 - 2 * f, t.top, t.w + 4 * f, 3 * f, stone)
            for (k, hx) in [x0, t.x - 2 * f, x0 + t.w - 4 * f].enumerated() {
                let hh = (k == 1 ? 18 : 10) * f
                c.rect(hx, t.top - hh, 4 * f, hh, stone)
                c.rect(hx + f, t.top - hh - 2 * f, 2 * f, 2 * f, stone)
            }
        }
        for y in stride(from: max(0, t.top) + 34 * f, to: g - 4 * f, by: 6 * f) {   // furnace slits below the face
            c.rect(t.x - 6 * f, y, 2 * f, 3 * f, C(0xFF8A3A, 0.6))
            c.rect(t.x + 4 * f, y, 2 * f, 3 * f, C(0xFF8A3A, 0.6))
        }
        let fy = max(0, t.top) + 4 * f
        apokolipsFace(c, t.x, fy, f)
    }

    /// Darkseid's face in stone, `f` pixels a unit, its top centre at (x, y): the helmet, the brow, the craggy cheeks.
    static func apokolipsFace(_ c: PixelCanvas, _ x: Int, _ y: Int, _ f: Int) {
        let r = { (u: Int, v: Int, w: Int, h: Int, col: Px) in c.rect(x + u * f, y + v * f, w * f, h * f, col) }
        let helm = C(0x22243A), helmLit = C(0x383C58)
        let face = C(0x5A5258), lit = C(0x7A6E72), shade = C(0x3A3240), deep = C(0x160E14)
        r(-13, 0, 26, 28, helm)                            // the helmet framing the face
        r(-13, 0, 3, 28, helmLit)
        r(-11, -2, 22, 2, helm)
        r(-9, 2, 18, 24, face)                             // the face and the broad jaw
        r(-10, 14, 20, 10, face)
        r(-8, 24, 16, 3, face)
        r(-9, 2, 7, 22, lit)
        r(-10, 14, 3, 9, lit)
        r(3, 3, 6, 21, shade)
        r(4, 14, 6, 9, shade)
        r(-9, 2, 18, 3, C(0x2A2C44))                       // the helmet's brim on the forehead
        r(-9, 6, 18, 3, lit)                               // the heavy brow
        r(-9, 8, 18, 1, shade)
        r(0, 6, 9, 3, face)
        r(-7, 9, 5, 2, deep)                               // eye sockets
        r(2, 9, 5, 2, deep)
        r(-6, 9, 3, 1, C(0xFF3A1A))
        r(3, 9, 3, 1, C(0xFF3A1A))
        r(-1, 9, 2, 7, lit)                                // the nose
        r(1, 10, 1, 6, shade)
        r(-2, 15, 5, 1, deep)
        r(-6, 12, 1, 9, deep)                              // the deep cracks down his cheeks
        r(-4, 13, 1, 5, shade)
        r(5, 12, 1, 9, deep)
        r(3, 13, 1, 5, deep)
        r(-8, 19, 1, 4, shade)
        r(-4, 19, 8, 1, deep)                              // the set mouth
        r(-3, 20, 6, 1, shade)
        r(-2, 23, 4, 1, shade)                             // the cleft chin
        r(-10, 26, 20, 2, helm)
    }

    /// Up high: more towers reaching into the smoke, a great column of fire from a pit and the red moon.
    static func apokolipsHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.circle(Int(Double(c.w) * 0.2), g / 7, g / 14, C(0xC83A1A, 0.25))
        c.circle(Int(Double(c.w) * 0.2), g / 7, g / 18, C(0xD85A2A, 0.6))
        for i in 0..<6 {                                   // smoke columns rising from the city
            let x = Int(noise(i * 3 + 990) * Double(c.w)), top = g / 6 + Int(noise(i * 3 + 991) * Double(g / 4))
            for y in stride(from: top, to: g * 2 / 3, by: 3 * s) {
                let k = Double(y - top) / Double(g)
                c.ellipse(x + Int(sin(Double(y) * 0.05 + Double(i)) * 6 * Double(s)), y, Int((8 + k * 10) * Double(s)), 3 * s, C(0x1A0A0A, 0.25))
            }
        }
        apokolipsSkyline(c, g, lo: 0.55, hi: 0.85, col: C(0x4A2018, 0.7), glow: C(0xFF8A3A, 0.35), seed: 7, gap: 40)
    }

    /// Flames dancing over the pits, embers rising, Darkseid's eyes smouldering and Parademons flitting overhead.
    static func apokolipsLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), plain = g - 9 * s
        for (i, p) in apokolipsPits(c, g).enumerated() {
            let n = max(3, p.r * 2 / (2 * s))
            for k in 0..<n {
                let x = p.x - p.r + k * 2 * s
                let fl = noise(Int(t * 10) * 7 + k * 3 + i * 31)
                let h = Int((3 + fl * 7) * Double(s) * (1 - abs(Double(x - p.x)) / Double(p.r + s) * 0.6))
                c.rect(x, plain + s - h, 2 * s, h, C(0xFF6A1E, 0.85))
                c.rect(x, plain + s - h / 2, 2 * s, h / 2, C(0xFFC050, 0.9))
                if fl > 0.8 { c.rect(x, plain - h - s, s, s, C(0xFFE08A, 0.8)) }
            }
            for e in 0..<4 {                               // embers
                let ph = scenes3Phase(t, 2.4, offset: Double(e) * 0.6 + Double(i) * 0.37)
                let ex = p.x + Int((noise(e * 5 + i * 17) - 0.5) * Double(p.r * 2)) + Int(sin(t * 2 + Double(e)) * 2)
                c.rect(ex, plain - Int(ph * Double(g) * 0.4), s, s, C(0xFFB050, 1 - ph))
            }
        }
        // the eyes smoulder
        let tw = apokolipsTower(c, g), f = tw.f, fy = max(0, tw.top) + 4 * f
        let pulse = 0.5 + 0.5 * sin(t * 2.2)
        for ex in [tw.x - 6 * f, tw.x + 3 * f] {
            c.rect(ex, fy + 9 * f, 3 * f, f, C(0xFFD060, 0.4 + pulse * 0.6))
            c.circle(ex + f, fy + 9 * f, 2 * f, C(0xFF3A1A, 0.08 + pulse * 0.14))
        }
        // Parademons
        let flock = isTall(c) ? 7 : 4
        for i in 0..<flock {
            let speed = (22 + noise(i * 3 + 700) * 18) * Double(s), span = Double(c.w + 40 * s)
            let ph = (t * speed + noise(i * 3 + 701) * span).truncatingRemainder(dividingBy: span)
            let left = i % 2 == 0
            let x = left ? Int(ph) - 20 * s : c.w + 20 * s - Int(ph)
            let base = Double(g) * (isTall(c) ? 0.1 + noise(i * 3 + 702) * 0.5 : 0.08 + noise(i * 3 + 702) * 0.22)
            let y = Int(base + sin(t * 1.7 + Double(i) * 2) * 3 * Double(s))
            let up = scenes3Phase(t, 0.3, offset: Double(i) * 0.11) < 0.5
            scenes3Stamp(c, x, y, up ? [
                "w.....w",
                "ww.b.ww",
                ".wbrbw.",
                "...b...",
                "..b.b..",
            ] : [
                ".......",
                "...b...",
                "wwbrbww",
                "w..b..w",
                "..b.b..",
            ], ["w": C(0x2A1210), "b": C(0x3A1E16), "r": C(0xFF4A1A)], s: s)
        }
    }
}

// MARK: - Krypton

extension Scenes {
    /// The red sun: centre and radius.
    static func kryptonSun(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        isTall(c) ? (Int(Double(c.w) * 0.34), Int(Double(g) * 0.5), Int(Double(g) * 0.3))
            : (Int(Double(c.w) * 0.34), Int(Double(g) * 0.62), Int(Double(g) * 0.55))
    }

    /// The cracks in the plain: each a run of points from the crew's row down into the floor, and on into the plain behind.
    static func kryptonCracks(_ c: PixelCanvas, _ g: Int) -> [[(x: Int, y: Int)]] {
        let s = unit(g)
        var out: [[(x: Int, y: Int)]] = []
        for i in 0..<max(4, c.w / 55) {
            var x = Int(noise(i * 11 + 400) * Double(c.w)), y = g - 6 * s
            var run: [(x: Int, y: Int)] = []
            while y < c.h {
                run.append((x, y))
                x += (noise(x * 7 + y * 3 + i) > 0.5 ? 1 : -1) * s * (noise(y + i * 5) > 0.6 ? 2 : 1)
                y += s
            }
            out.append(run)
        }
        return out
    }

    /// Where the city's tallest spires stand: x, half-width and height.
    static func kryptonSpires(_ c: PixelCanvas, _ g: Int) -> [(x: Int, half: Int, h: Int)] {
        let s = unit(g), tall = isTall(c)
        var out: [(x: Int, half: Int, h: Int)] = []
        var x = 8 * s, i = 0
        while x < c.w {
            let h = Int(Double(g) * (tall ? 0.35 + noise(i * 5 + 450) * 0.4 : 0.45 + noise(i * 5 + 450) * 0.45))
            out.append((x, (3 + Int(noise(i * 5 + 451) * 3)) * s, h))
            x += (26 + Int(noise(i * 5 + 452) * 34)) * s
            i += 1
        }
        return out
    }

    /// Krypton in its last days: a swollen red sun fills the sky behind a city of white crystal spires, domes and
    /// arching bridges, its towers clustered in sharp shards. The plain they stand on is pale rust-red stone, split by
    /// cracks glowing with the planet's molten core.
    static func krypton(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x2A0A16), C(0xE8743A), bands: 8)
        let sun = kryptonSun(c, g)
        c.circle(sun.x, sun.y, sun.r + 10 * s, C(0xFF5A2A, 0.10))
        c.circle(sun.x, sun.y, sun.r + 5 * s, C(0xFF6A3A, 0.14))
        c.circle(sun.x, sun.y, sun.r, C(0xC8281E))
        c.circle(sun.x - sun.r / 6, sun.y - sun.r / 6, sun.r * 3 / 4, C(0xE0402A))
        c.circle(sun.x - sun.r / 4, sun.y - sun.r / 4, sun.r / 3, C(0xF06A3A))
        for i in 0..<5 {                                   // sunspots
            let a: Double = noise(i * 3 + 470) * 6.28, d: Double = 0.3 + noise(i * 3 + 471) * 0.5
            c.circle(sun.x + Int(cos(a) * d * Double(sun.r)), sun.y + Int(sin(a) * d * Double(sun.r)), max(1, sun.r / 24), C(0xA82018))
        }
        if tall { kryptonHigh(c, g) }
        // the far city: hazy shards in the sun's light
        var x = 0, i = 0
        while x < c.w {
            let h = Int(Double(g) * (0.15 + noise(i * 3 + 480) * 0.25))
            scenes3Shard(c, x, g - 6 * s, half: (2 + Int(noise(i * 3 + 481) * 3)) * s, h: h,
                         lit: C(0xB8707A), shade: C(0x8A4A5A), ridge: C(0xE8A8A0))
            x += (5 + Int(noise(i * 3 + 482) * 8)) * s
            i += 1
        }
        // domes
        for k in 0..<max(2, c.w / 120) {
            let dx = Int((Double(k) + noise(k + 490) * 0.6) * 120.0 * Double(s)), r = (8 + Int(noise(k + 491) * 6)) * s
            c.ellipse(dx, g - 6 * s, r, r * 2 / 3, C(0xC8B0B8))
            c.ellipse(dx - r / 4, g - 6 * s - r / 4, r / 2, r / 3, C(0xF0E0E0))
            c.rect(dx - r, g - 6 * s, r * 2, s, C(0x6A3A48))
        }
        // the great spires, with a bridge between some neighbours
        let spires = kryptonSpires(c, g)
        for (j, p) in spires.enumerated() {
            if j > 0, noise(j + 495) > 0.5 {
                let q = spires[j - 1], by = g - min(p.h, q.h) / 2
                for bx in q.x..<p.x {
                    let sag = Int(sin(Double(bx - q.x) / Double(max(1, p.x - q.x)) * .pi) * 4 * Double(s))
                    c.rect(bx, by - sag, 1, s, C(0xE8D8E0))
                    c.px(bx, by - sag + s, C(0x8A5A68))
                }
            }
            scenes3Shard(c, p.x - p.half * 2, g - 4 * s, half: p.half / 2 + s, h: p.h * 5 / 8,
                         lit: C(0xD8C8D8), shade: C(0x9A7A90), ridge: C(0xFFF0F0))
            scenes3Shard(c, p.x + p.half * 2, g - 4 * s, half: p.half / 2 + s, h: p.h / 2,
                         lit: C(0xD8C8D8), shade: C(0x9A7A90), ridge: C(0xFFF0F0))
            scenes3Shard(c, p.x, g - 4 * s, half: p.half, h: p.h, lit: C(0xE4D4E4), shade: C(0x9C7C98), ridge: C(0xFFF4F0))
        }
        // dust haze over the city's feet, so the crew stands out against it
        for k in 0..<5 { c.rect(0, g - 4 * s - (k + 1) * 3 * s, c.w, (k + 1) * 3 * s, C(0x7A2E26, 0.13)) }
        // the plain and the cracks
        c.dunes(base: g - 4 * s, amp: 1.5, freq: 0.05, phase: 2, bottom: g, C(0x7A3A2E), shade: C(0xA85A42))
        c.ground(g, C(0x6A3026), edge: C(0xC8704A), speck: C(0x542620), seed: 61)
        for run in kryptonCracks(c, g) {
            for p in run {
                c.rect(p.x - s, p.y, 3 * s, s, C(0x2A0E0C))
                c.rect(p.x, p.y, s, s, C(0xC84A1E))
            }
        }
        for k in 0..<(c.w / (14 * s)) {                    // crystal outcrops on the plain
            guard noise(k + 520) > 0.6 else { continue }
            let ox = k * 14 * s + Int(noise(k + 521) * 10.0) * s
            scenes3Shard(c, ox, g + 3 * s, half: 2 * s, h: (3 + Int(noise(k + 522) * 4)) * s,
                         lit: C(0xE8D8F0), shade: C(0x9A7A98), ridge: white, lean: noise(k + 523) > 0.5 ? s : -s)
        }
    }

    /// Up high: Krypton's moons, and crystal sky-platforms hanging over the city.
    static func kryptonHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.stars(0, g / 4, density: 140, seed: 33)
        let mx = Int(Double(c.w) * 0.8), my = g / 7, mr = max(5, g / 22)
        c.circle(mx, my, mr, C(0xC89A8A)); c.circle(mx + mr / 3, my - mr / 4, mr * 3 / 4, C(0x7A4A4A))
        c.circle(Int(Double(c.w) * 0.62), g / 12, max(2, mr / 3), C(0xD8B0A0))
        for k in 0..<3 {
            let px = Int(Double(c.w) * (0.15 + Double(k) * 0.33)), py = Int(Double(g) * (0.22 + noise(k + 530) * 0.15))
            let pw = (24 + Int(noise(k + 531) * 16)) * s
            c.ellipse(px, py, pw / 2, 2 * s, C(0xE0D0E0))
            for j in 0..<(pw / (4 * s)) {
                let dx = px - pw / 2 + j * 4 * s + 2 * s
                let hh = Int((1 - abs(Double(dx - px)) / Double(pw / 2)) * 14) * s + 2 * s
                c.rect(dx - s, py + s, 3 * s, hh / 2, C(0xA88AA4)); c.rect(dx, py + s, s, hh, C(0xC8B0C8))
            }
            scenes3Shard(c, px, py - s, half: 3 * s, h: 12 * s, lit: C(0xEEE4F0), shade: C(0xA88AA4), ridge: white)
        }
    }

    /// The cracks throbbing with heat, embers lifting off them, and now and then a quake: the cracks flare, dust bursts
    /// off the plain and shards break off the spires and tumble.
    static func kryptonLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g)
        let qp = scenes3Phase(t, 7)
        let quake = qp > 0.72 ? sin((qp - 0.72) / 0.28 * .pi) : 0
        for (i, run) in kryptonCracks(c, g).enumerated() {
            let glow = 0.35 + 0.3 * sin(t * 1.8 + Double(i)) + quake * 0.5
            for (j, p) in run.enumerated() where j % 1 == 0 {
                c.rect(p.x, p.y, s, s, C(0xFFC060, min(1, glow)))
                if quake > 0.2 { c.rect(p.x - s, p.y, 3 * s, s, C(0xFF6A2A, quake * 0.4)) }
            }
            if let p = run.first {
                for e in 0..<3 {
                    let ph = scenes3Phase(t, 3, offset: Double(e) + Double(i) * 0.7)
                    c.rect(p.x + Int(sin(t + Double(e * 3)) * 3 * Double(s)), p.y - Int(ph * 24 * Double(s)), s, s, C(0xFFA050, (1 - ph) * 0.9))
                }
            }
        }
        // the sun's corona flickering
        let sun = kryptonSun(c, g)
        for k in 0..<5 {
            let a: Double = Double(k) * 1.3 + t * 0.2
            let flare = 0.5 + 0.5 * sin(t * 1.3 + Double(k) * 2)
            let fx = sun.x + Int(cos(a) * Double(sun.r + 2 * s)), fy = sun.y + Int(sin(a) * Double(sun.r + 2 * s))
            if fy < g - 20 * s { c.circle(fx, fy, Int(1 + flare * 2.5) * s, C(0xFF6A3A, 0.5)) }
        }
        guard quake > 0 else { return }
        let ft = (qp - 0.72) / 0.28
        for (i, p) in kryptonSpires(c, g).enumerated() where i % 2 == 0 {
            let fall = Int(ft * ft * Double(p.h))
            let sx = p.x + (i % 4 == 0 ? 2 : -2) * s + Int(ft * 6 * Double(s))
            c.rect(sx, g - p.h * 3 / 4 + fall, 2 * s, 3 * s, C(0xEEE4F0, 1 - ft * 0.5))
            c.rect(sx + s, g - p.h * 3 / 4 + fall + s, s, 2 * s, C(0xA88AA4, 1 - ft * 0.5))
        }
        for k in 0..<(c.w / (40 * s)) {                     // dust shaken off the plain
            let dx = k * 40 * s + Int(noise(k + 560) * 30.0) * s
            c.ellipse(dx, g - 2 * s, Int(quake * 8 * Double(s)) + s, Int(quake * 3 * Double(s)) + 1, C(0xC88A6A, quake * 0.35))
        }
    }
}

// MARK: - Titans Tower

extension Scenes {
    /// The tower: centre of the shaft, half its width, the crossbar's half-width and height, top row, island top.
    static func titansTowerFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, shaft: Int, bar: Int, barH: Int, top: Int, base: Int, f: Int) {
        let f = isTall(c) ? max(2, g / 130) : 1
        let top = isTall(c) ? g * 3 / 10 : 2
        return (Int(Double(c.w) * 0.72), 9 * f, 30 * f, 14 * f, top, g - 10 * unit(g), f)
    }

    /// Titans Tower at night: the T-shaped tower stands on its rocky island in the bay, every floor of its glass lit
    /// blue, with the lights of Jump City strung along the far shore across the black water and a moon over the bay.
    /// The crew is on the island's near shore.
    static func titansTower(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        let horizon = g - (tall ? g / 4 : 22 * s)
        c.gradient(0, horizon, C(0x070C22), C(0x2C3C72), bands: 7)
        c.stars(0, horizon * 3 / 4, density: tall ? 80 : 50, seed: 71)
        let mx = Int(Double(c.w) * 0.18), my = tall ? g / 5 : horizon / 3, mr = max(4, g / 20)
        c.circle(mx, my, mr + 3 * s, C(0xD8E0F8, 0.08)); c.circle(mx, my, mr, C(0xEEF2FA))
        c.circle(mx + mr / 3, my - mr / 4, max(1, mr / 4), C(0xC8D0E0))
        if tall {
            for i in 0..<5 {
                wisp(c, Int(noise(i * 5 + 710) * Double(c.w)), g / 10 + Int(noise(i * 5 + 711) * Double(g / 3)),
                     (30 + Int(noise(i * 5 + 712) * 40)) * s, C(0x3A4A80, 0.5), s: s)
            }
        }
        // Jump City along the far shore
        for k in 0..<3 { c.rect(0, horizon - 6 * s - k * 4 * s, c.w, 4 * s, C(0x7A6AA0, 0.07)) }
        var x = -3 * s, i = 0
        while x < c.w {
            let bw = (3 + Int(noise(i * 5 + 720) * 7)) * s
            let bh = (3 + Int(noise(i * 5 + 721) * Double(tall ? 26 : 13))) * s
            c.rect(x, horizon - bh, bw, bh, C(0x161C3A))
            for (j, wy) in stride(from: horizon - bh + s, to: horizon - s, by: 2 * s).enumerated() {
                for (k, wx) in stride(from: x, to: x + bw - s, by: 2 * s).enumerated() where noise(i * 31 + j * 7 + k) > 0.68 {
                    c.rect(wx, wy, s, s, noise(i + j + k * 5) > 0.75 ? C(0xBFE0FF, 0.7) : C(0xFFD890, 0.7))
                }
            }
            if noise(i * 5 + 723) > 0.85 { c.rect(x + bw / 2, horizon - bh - 3 * s, s, 3 * s, C(0x161C3A)) }
            x += bw + (noise(i * 5 + 722) > 0.7 ? 3 * s : 0)
            i += 1
        }
        // the bay
        c.gradient(horizon, g, C(0x0E1838), C(0x1A2A4E), bands: 4)
        for (j, y) in stride(from: horizon + 2 * s, to: g, by: 3 * s).enumerated() {
            for k in 0..<(c.w / (18 * s)) where noise(j * 17 + k + 730) > 0.5 {
                c.rect(k * 18 * s + Int(noise(j * 3 + k + 731) * 12.0) * s, y, (3 + Int(noise(k + j + 732) * 5)) * s, max(1, s / 2), C(0x3A5088, 0.6))
            }
        }
        titansTowerIsland(c, g)
        // the near shore: the island's grassy rock
        c.dunes(base: g - s, amp: 1.5, freq: 0.07, phase: 0.5, bottom: g, C(0x22302A), shade: C(0x3A5040))
        c.ground(g, C(0x2A3036), edge: C(0x4A6A50), speck: C(0x20242A), seed: 71)
        for k in 0..<(c.w / (26 * s)) {                     // boulders along the shore
            let rx = k * 26 * s + Int(noise(k + 740) * 16.0) * s, rw = (4 + Int(noise(k + 741) * 5)) * s
            c.rect(rx, g + 2 * s, rw, 3 * s, C(0x3A424E))
            c.rect(rx + s, g + s, rw - 2 * s, s, C(0x3A424E))
            c.rect(rx + s, g + s, rw / 2, s, C(0x5A6474))
        }
    }

    /// The island and the T on it.
    static func titansTowerIsland(_ c: PixelCanvas, _ g: Int) {
        let f = titansTowerFrame(c, g), u = f.f
        let iw = f.bar + 20 * u
        // the island: rocky flanks, grass on top, a few trees
        c.ellipse(f.x, f.base + 2 * u, iw, 5 * u, C(0x262A34))
        c.ellipse(f.x - 3 * u, f.base, iw - 6 * u, 4 * u, C(0x3A4250))
        c.ellipse(f.x - 5 * u, f.base - u, iw - 16 * u, 2 * u, C(0x2A4632))
        for k in 0..<5 {
            let tx = f.x - iw + 10 * u + k * (iw * 2 - 20 * u) / 4
            guard abs(tx - f.x) > f.shaft + 6 * u else { continue }
            c.rect(tx, f.base - 4 * u, max(1, u / 2 + u % 2), 3 * u, C(0x1E1A16))
            c.ellipse(tx, f.base - 5 * u, 3 * u, 2 * u, C(0x1E3424))
        }
        c.rect(f.x - iw, f.base + 7 * u, iw * 2, max(1, u / 2 + u % 2), C(0x5A78B0, 0.35))
        let body = C(0x6A7488), edge = C(0xB8C4D8), glass = C(0x24508C), frame = C(0x3A4258)
        // the shaft
        let sh = f.base - f.top - f.barH
        c.rect(f.x - f.shaft, f.top + f.barH, f.shaft * 2, sh, body)
        c.rect(f.x - f.shaft, f.top + f.barH, u, sh, edge)
        c.rect(f.x - f.shaft + 2 * u, f.top + f.barH, f.shaft * 2 - 4 * u, sh, glass)
        c.rect(f.x + f.shaft - u, f.top + f.barH, u, sh, frame)
        // the crossbar
        c.rect(f.x - f.bar, f.top, f.bar * 2, f.barH, body)
        c.rect(f.x - f.bar, f.top, f.bar * 2, u, edge)
        c.rect(f.x - f.bar, f.top, u, f.barH, edge)
        c.rect(f.x - f.bar + 2 * u, f.top + 2 * u, f.bar * 2 - 4 * u, f.barH - 4 * u, glass)
        c.rect(f.x - f.bar, f.top + f.barH - u, f.bar * 2, u, frame)
        c.rect(f.x + f.bar - u, f.top, u, f.barH, frame)
        titansTowerWindows(c, g)
        c.rect(f.x - u / 2, f.top - 6 * u, max(1, u), 6 * u, C(0x8A94A8))          // the mast
        // the T's reflection in the bay
        for y in stride(from: f.base + 6 * u, to: g, by: 2 * u) {
            c.rect(f.x - f.shaft + 2 * u, y, f.shaft * 2 - 4 * u, u, C(0x6AA0E0, 0.22))
        }
    }

    /// Where the T's panes are: one per row in the shaft, a grid across the crossbar.
    static func titansTowerPanes(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int)] {
        let f = titansTowerFrame(c, g), u = f.f
        var out: [(x: Int, y: Int, w: Int)] = []
        for y in stride(from: f.top + 3 * u, to: f.top + f.barH - 3 * u + 1, by: 2 * u) {
            for x in stride(from: f.x - f.bar + 3 * u, to: f.x + f.bar - 4 * u, by: 4 * u) { out.append((x, y, 3 * u)) }
        }
        for y in stride(from: f.top + f.barH + u, to: f.base - u, by: 2 * u) {
            for x in stride(from: f.x - f.shaft + 3 * u, to: f.x + f.shaft - 4 * u, by: 4 * u) { out.append((x, y, 3 * u)) }
        }
        return out
    }

    /// The lit panes across the T's glass.
    static func titansTowerWindows(_ c: PixelCanvas, _ g: Int) {
        let u = titansTowerFrame(c, g).f
        for (i, p) in titansTowerPanes(c, g).enumerated() where noise(i * 7 + 760) > 0.2 {
            c.rect(p.x, p.y, p.w, u, noise(i * 7 + 761) > 0.85 ? C(0xE8F4FF, 0.8) : C(0x8AC8FF, 0.6))
        }
    }

    /// The bay's moonlit ripples drifting, panes of the T going on and off, the beacon on its mast and every so often
    /// the T-Ship streaking across.
    static func titansTowerLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = titansTowerFrame(c, g), tall = isTall(c), u = f.f
        let horizon = g - (tall ? g / 4 : 22 * s)
        let mx = Int(Double(c.w) * 0.18)
        for (j, y) in stride(from: horizon + s, to: g - s, by: 2 * s).enumerated() {   // the moon's path on the water
            let wob = Int(sin(t * 1.5 + Double(j)) * 2 * Double(s))
            let half = (2 + j / 2) * s
            c.rect(mx - half / 2 + wob, y, half / 2 + Int(noise(Int(t * 3) + j) * Double(half / 2)), max(1, s / 2), C(0xE0E8FF, 0.35))
        }
        for k in 0..<(c.w / (24 * s)) {                     // glints drifting
            let y = horizon + s + Int(noise(k + 750) * Double(g - horizon - 2 * s))
            let x = (k * 24 * s + Int(t * 4 * Double(s) * (0.5 + noise(k + 751)))) % c.w
            c.rect(x, y, 2 * s, max(1, s / 2), C(0x8AB0E8, 0.5))
        }
        let panes = titansTowerPanes(c, g)
        for i in 0..<min(panes.count, 8) {                  // a few panes going on and off
            let p = panes[Int(noise(i * 5 + 770 + Int(t / 4) * 3) * Double(panes.count)) % panes.count]
            c.rect(p.x, p.y, p.w, u, noise(i + Int(t * 1.5)) > 0.5 ? C(0xFFF4C8, 0.9) : C(0x24508C))
        }
        if scenes3Phase(t, 1.4) < 0.2 {
            c.rect(f.x - u, f.top - 7 * u, 2 * u, u, C(0xFF4A4A))
            c.circle(f.x, f.top - 7 * u, 2 * u, C(0xFF4A4A, 0.3))
        }
        // the T-Ship
        let speed = 70.0 * Double(s), travel = Double(c.w + 40 * s), dur = travel / speed, cycle = dur + 11
        let ph = (t + 2).truncatingRemainder(dividingBy: cycle)
        guard ph < dur else { return }
        let x = c.w + 20 * s - Int(ph * speed), y = tall ? g / 7 : 18 * s
        scenes3Stamp(c, x, y, [
            "..ww........",
            "wwwwwwwwwwr.",
            "..ww........",
        ], ["w": C(0xD8DEE8), "r": C(0xFF6A3A)], s: s)
        for k in 1...4 { c.rect(x + (10 + k * 2) * s, y + s, 2 * s, s, C(0xFFB060, 0.6 - Double(k) * 0.13)) }
    }
}

// MARK: - Smallville

extension Scenes {
    /// The windmill by the water tower: hub position and blade length.
    static func smallvilleMill(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let f = smallvilleScale(c, g)
        return (Int(Double(c.w) * 0.68), g - 10 * unit(g) - 26 * f, 7 * f)
    }

    /// How big the farm buildings are drawn: doubled on the screen saver.
    static func smallvilleScale(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? max(2, g / 130) : 1 }

    /// Where the cornfield starts (it runs from here to the right edge; left of it is the farmyard).
    static func smallvilleCornStart(_ c: PixelCanvas) -> Int { Int(Double(c.w) * 0.4) }

    /// Smallville at dusk: the Kent farm under a peach and violet sky. The red barn with its white trim and hayloft
    /// stands beside a grain silo, the white farmhouse glows on its porch, the old blue pickup sits in the yard, and a
    /// windmill and the town's water tower stand on their stilts across a cornfield running behind the crew.
    static func smallville(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = smallvilleScale(c, g)
        let mid = Int(Double(g) * 0.5)
        c.gradient(0, mid, C(0x2A2A5A), C(0xB8687A), bands: 6)
        c.gradient(mid, g, C(0xD8806A), C(0xFFD08A), bands: 5)
        c.circle(Int(Double(c.w) * 0.42), g - 8 * s, g / 4, C(0xFFE0A0, 0.12))
        c.circle(Int(Double(c.w) * 0.42), g - 8 * s, g / 7, C(0xFFE8B0, 0.18))
        if tall { smallvilleHigh(c, g) }
        for (i, fy) in [0.3, 0.45].enumerated() {
            for k in 0..<max(2, c.w / 140) {
                let x = Int((Double(k) + noise(i * 9 + k + 600)) * 140.0 * Double(s))
                wisp(c, x, Int(Double(mid) * fy * 2), (30 + Int(noise(i * 9 + k + 604) * 40)) * s, C(0xF0A08A, 0.5), s: s)
            }
        }
        // the far hills and a tree line
        c.dunes(base: g - 16 * s, amp: 3, freq: 0.03, phase: 1.2, bottom: g, C(0x6A6A5A))
        c.dunes(base: g - 13 * s, amp: 2, freq: 0.05, phase: 3, bottom: g, C(0x4A5240))
        for x in stride(from: 0, to: c.w, by: 5 * s) where noise(x + 610) > 0.4 {
            c.ellipse(x, g - 14 * s + Int(noise(x + 611) * 3.0) * s, (2 + Int(noise(x + 612) * 3)) * s, 2 * s, C(0x3A4232))
        }
        if tall {                                         // patchwork fields rolling up the hills
            let cols = [C(0x6A6A3A), C(0x5A6234), C(0x7A6A42), C(0x4E5A30)]
            for k in 0..<10 {
                c.dunes(base: g - 13 * s - (10 - k) * 3 * s, amp: 4, freq: 0.012, phase: Double(k) * 0.35, bottom: g - 12 * s,
                        cols[k % cols.count], shade: C(0x8A7A4A, 0.6))
            }
        }
        smallvilleWaterTower(c, Int(Double(c.w) * 0.86), g - 10 * s, f)
        smallvilleWindmill(c, g)
        smallvilleBarn(c, Int(Double(c.w) * 0.14), g - 6 * s, f)
        smallvilleHouse(c, Int(Double(c.w) * 0.5), g - 10 * s, f)
        // the yard in front of the barn, with the dirt drive
        let cx = smallvilleCornStart(c)
        c.rect(0, g - 6 * s, cx, 6 * s, C(0x3E4A26))
        c.rect(0, g - 6 * s, cx, s, C(0x5A6A32))
        c.rect(0, g - 3 * s, cx, 3 * s, C(0x6A5034))
        c.rect(0, g - 3 * s, cx, s, C(0x8A6A44))
        // the fence along the field
        let fy = g - 14 * s
        c.rect(cx, fy, c.w - cx, s, C(0x6A4A32)); c.rect(cx, fy + 3 * s, c.w - cx, s, C(0x6A4A32))
        for x in stride(from: cx + 2 * s, to: c.w, by: 9 * s) { c.rect(x, fy - s, s, 6 * s, C(0x4A3222)) }
        smallvilleCorn(c, g)
        smallvilleTruck(c, Int(Double(c.w) * 0.27), g - s, f)
        c.ground(g, C(0x4A3A26), edge: C(0x8A6A3A), speck: C(0x3A2C1C), seed: 81)
        for y in stride(from: g + 2 * s, to: c.h, by: 3 * s) { c.rect(0, y, c.w, max(1, s / 2), C(0x3A2C1C)) }
    }

    /// The cornfield's body: rows of stalks with leaves, a darker band so the crew stands out.
    static func smallvilleCorn(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), top = g - 10 * s, x0 = smallvilleCornStart(c)
        c.rect(x0, top + 2 * s, c.w - x0, g - top - 2 * s, C(0x3A4A22))
        for x in stride(from: x0, to: c.w, by: 2 * s) {
            let h = (8 + Int(noise(x + 620) * 3)) * s
            c.rect(x, g - h, s, h, C(0x5A6A2A))
            if noise(x + 621) > 0.5 { c.rect(x - s, g - h + 3 * s, s, s, C(0x6A7A32)) }
            if noise(x + 622) > 0.6 { c.rect(x + s, g - h + 5 * s, s, s, C(0x4A5A26)) }
        }
    }

    /// The red barn: gambrel roof, white trim, the cross-braced doors and the hayloft door, with a silo beside it.
    static func smallvilleBarn(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let red = C(0xA02A22), dark = C(0x6A1A16), trim = C(0xE8E0D0), roof = C(0x3A2A2A)
        // the silo
        c.rect(x + 24 * s, b - 34 * s, 9 * s, 34 * s, C(0x8A98A8))
        c.rect(x + 24 * s, b - 34 * s, 2 * s, 34 * s, C(0xB8C4D0))
        c.ellipse(x + 28 * s, b - 34 * s, 5 * s, 4 * s, C(0x9AA8B8))
        c.ellipse(x + 27 * s, b - 35 * s, 3 * s, 2 * s, C(0xC8D4E0))
        for y in stride(from: b - 30 * s, to: b, by: 4 * s) { c.rect(x + 24 * s, y, 9 * s, max(1, s / 2), C(0x6A7888)) }
        // the barn body
        let w = 28 * s, bx = x - w / 2, wall = 14 * s
        c.rect(bx, b - wall, w, wall, red)
        for k in stride(from: bx + 2 * s, to: bx + w, by: 3 * s) { c.rect(k, b - wall, max(1, s / 2), wall, dark) }
        // the gambrel roof: steep lower slopes, shallow upper
        for k in 0..<(w / 2 + 2 * s) {
            let dx = Double(k)
            let up: Double = dx < Double(5 * s) ? dx * 2.0 : Double(10 * s) + (dx - Double(5 * s)) * 0.55
            let hgt = Int(up)
            c.rect(bx - 2 * s + k, b - wall - hgt, 1, hgt, roof)
            c.rect(bx + w + 2 * s - 1 - k, b - wall - hgt, 1, hgt, roof)
        }
        let peak = b - wall - Int(Double(10 * s) + Double(w / 2 - 3 * s) * 0.55)
        // the gable end, red under the roof line
        for k in 0..<(w / 2 - 2 * s) {
            let dx = Double(k)
            let up: Double = dx < Double(4 * s) ? dx * 2.0 : Double(8 * s) + (dx - Double(4 * s)) * 0.55
            let hgt = Int(up)
            c.rect(bx + 2 * s + k, b - wall - hgt, 1, hgt, red)
            c.rect(bx + w - 2 * s - 1 - k, b - wall - hgt, 1, hgt, red)
        }
        c.rect(bx + w / 2 - 3 * s, peak + 4 * s, 6 * s, b - wall - peak - 4 * s, red)
        c.rect(bx, b - wall, w, s, trim)
        c.rect(bx, b - wall, s, wall, trim); c.rect(bx + w - s, b - wall, s, wall, trim)
        // the hayloft door
        c.rect(bx + w / 2 - 3 * s, peak + 6 * s, 6 * s, 6 * s, trim)
        c.rect(bx + w / 2 - 2 * s, peak + 7 * s, 4 * s, 4 * s, C(0x2A1A14))
        c.rect(bx + w / 2 - 2 * s, peak + 7 * s, 4 * s, 2 * s, C(0xD8B060, 0.6))
        // the big doors with their white X braces
        let dw = 14 * s, dx0 = bx + w / 2 - dw / 2, dh = 11 * s
        c.rect(dx0, b - dh, dw, dh, dark)
        c.rect(dx0, b - dh, dw, s, trim); c.rect(dx0, b - dh, s, dh, trim); c.rect(dx0 + dw - s, b - dh, s, dh, trim)
        c.rect(dx0 + dw / 2, b - dh, max(1, s / 2), dh, trim)
        for k in 0..<(dh - s) {
            let u = k * (dw / 2 - s) / max(1, dh - s)
            c.rect(dx0 + s + u, b - dh + s + k, s, 1, trim)
            c.rect(dx0 + dw / 2 - s - u, b - dh + s + k, s, 1, trim)
            c.rect(dx0 + dw / 2 + u, b - dh + s + k, s, 1, trim)
            c.rect(dx0 + dw - 2 * s - u, b - dh + s + k, s, 1, trim)
        }
        c.rect(dx0 - 4 * s, b - 6 * s, 3 * s, 3 * s, C(0xFFD890, 0.8))          // a lamp by the door
        c.circle(dx0 - 3 * s, b - 5 * s, 4 * s, C(0xFFD890, 0.15))
    }

    /// The Kent farmhouse: white clapboard, a pitched roof with a chimney, lit windows and the porch light on.
    static func smallvilleHouse(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let wall = C(0xD8D0C4), shade = C(0xA89C94), roof = C(0x4A3A3A), glow = C(0xFFD890)
        let w = 26 * s, x0 = x - w / 2, wallH = 16 * s
        c.rect(x0, b - wallH, w, wallH, wall)
        c.rect(x0 + w - 4 * s, b - wallH, 4 * s, wallH, shade)
        for y in stride(from: b - wallH + 2 * s, to: b, by: 2 * s) { c.rect(x0, y, w, max(1, s / 2), C(0xB8B0A8)) }
        for k in 0..<(8 * s) { c.rect(x0 - 2 * s + k * 2, b - wallH - k, w + 4 * s - k * 4, 1, roof) }   // the roof
        c.rect(x0 + 18 * s, b - wallH - 9 * s, 3 * s, 6 * s, C(0x6A3A2E))                                // the chimney
        for wx in [x0 + 4 * s, x0 + 11 * s, x0 + 18 * s] {
            c.rect(wx, b - wallH + 2 * s, 3 * s, 4 * s, glow)
            c.rect(wx + s, b - wallH + 2 * s, max(1, s / 2), 4 * s, C(0xC8A060))
        }
        // the porch along the front
        c.rect(x0 - 2 * s, b - 8 * s, w + 4 * s, 2 * s, C(0x6A5A52))
        for px in stride(from: x0 - s, through: x0 + w + s, by: 6 * s) { c.rect(px, b - 6 * s, s, 6 * s, C(0xE8E0D8)) }
        c.rect(x0 + 6 * s, b - 5 * s, 3 * s, 5 * s, C(0x5A3A2A))
        c.rect(x0 + 13 * s, b - 5 * s, 3 * s, 3 * s, glow)
        c.rect(x0 + 10 * s, b - 6 * s, s, s, C(0xFFF0C0))
        c.circle(x0 + 10 * s, b - 5 * s, 5 * s, C(0xFFD890, 0.15))
    }

    /// The Kents' old pickup.
    static func smallvilleTruck(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        scenes3Stamp(c, x, b - 9 * s, [
            "........bbbbb.....",
            "........bwwwbb....",
            "........bwwwbbb...",
            "bbbbbbbbbbbbbbbbbh",
            "bbbbbbbbbbbbbbbbbb",
            "dddtttdddddddtttdd",
            "...ttt.......ttt..",
            "...tct.......tct..",
            "....t.........t...",
        ], ["b": C(0x3A6A8A), "w": C(0xB8D0E0), "d": C(0x2A3A4A), "t": C(0x1A1A1E), "c": C(0x8A8A90), "h": C(0xFFE0A0)], s: s)
        c.rect(x, b - 6 * s, 18 * s, s, C(0x6A9AB8))
    }

    /// The water tower on its legs.
    static func smallvilleWaterTower(_ c: PixelCanvas, _ x: Int, _ b: Int, _ s: Int) {
        let leg = C(0x5A5A62), tank = C(0xC8C8C0), shade = C(0x8A8A88)
        let tankTop = b - 44 * s, tankH = 12 * s, tw = 18 * s
        for k in [-7, -2, 2, 7] {
            for y in (tankTop + tankH)..<b {
                let spread = (y - tankTop - tankH) * abs(k) / 7 / 6
                c.rect(x + k * s + (k < 0 ? -spread : spread), y, s, 1, leg)
            }
        }
        for y in stride(from: tankTop + tankH + 6 * s, to: b - 2 * s, by: 8 * s) { c.rect(x - 8 * s, y, 16 * s, max(1, s / 2), leg) }
        c.rect(x - tw / 2, tankTop, tw, tankH, tank)
        c.rect(x + tw / 4, tankTop, tw / 4, tankH, shade)
        c.rect(x - tw / 2, tankTop + tankH - s, tw, s, shade)
        for k in 0..<(5 * s) { c.rect(x - tw / 2 + k * 2, tankTop - k, tw - k * 4, 1, C(0x8A3A2A)) }     // the cone roof
        c.rect(x - tw / 2, tankTop + 4 * s, tw, 4 * s, C(0x2A4A6A))                                         // the name band
        for k in 0..<(tw / (2 * s)) where k % 3 != 2 { c.rect(x - tw / 2 + s + k * 2 * s, tankTop + 5 * s, s, 2 * s, C(0xE8E0D0)) }
        c.rect(x - tw / 2 - s, tankTop + tankH, tw + 2 * s, s, leg)                                         // the catwalk
    }

    /// The windmill's tower (the blades turn in the moving layer).
    static func smallvilleWindmill(_ c: PixelCanvas, _ g: Int) {
        let s = smallvilleScale(c, g), m = smallvilleMill(c, g), b = g - 12 * unit(g)
        for y in (m.y + s)..<b {
            let spread = (y - m.y) / 6
            c.rect(m.x - s - spread, y, s, 1, C(0x4A4A50)); c.rect(m.x + spread, y, s, 1, C(0x4A4A50))
        }
        for y in stride(from: m.y + 5 * s, to: b, by: 5 * s) { c.rect(m.x - s - (y - m.y) / 6, y, 2 * s + (y - m.y) / 3, max(1, s / 2), C(0x4A4A50)) }
        c.rect(m.x, m.y - s, 6 * s, 2 * s, C(0x3A3A40))                 // the tail vane
        c.rect(m.x + 5 * s, m.y - 3 * s, s, 5 * s, C(0x3A3A40))
    }

    /// Up high: a deepening sky with the first stars, a crescent moon and pink-lit clouds.
    static func smallvilleHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        c.stars(0, g / 3, density: 120, seed: 82)
        let mx = Int(Double(c.w) * 0.78), my = g / 6, mr = max(4, g / 24)
        c.circle(mx, my, mr, C(0xF4ECD8)); c.circle(mx + mr / 2, my - mr / 4, mr, C(0x2E2C5A))
        for i in 0..<4 {
            cloud(c, Int(noise(i * 5 + 630) * Double(c.w)), g / 4 + Int(noise(i * 5 + 631) * Double(g / 5)),
                  (4 + Int(noise(i * 5 + 632) * 4)) * s, seed: i + 60, top: C(0xE8A0A0), base: C(0xA8708A))
        }
    }

    /// Corn tassels nodding in the breeze, the windmill turning and fireflies blinking over the field.
    static func smallvilleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = smallvilleScale(c, g)
        for x in stride(from: smallvilleCornStart(c), to: c.w, by: 2 * s) {
            let h = (8 + Int(noise(x + 620) * 3)) * s
            let lean = Int((sin(t * 1.6 - Double(x) * 0.05) * 1.4).rounded()) * s
            c.rect(x + lean, g - h - 2 * s, s, 2 * s, C(0xD8B85A))
            c.rect(x + lean / 2, g - h, s, s, C(0x7A8A3A))
        }
        let m = smallvilleMill(c, g)
        for k in 0..<8 {
            let a: Double = t * 2.4 + Double(k) * .pi / 4
            c.glowLine(Double(m.x), Double(m.y), Double(m.x) + cos(a) * Double(m.r), Double(m.y) + sin(a) * Double(m.r),
                       core: C(0x4A4A52), glow: C(0x4A4A52, 0), coreR: 0.6 * Double(f), glowR: 0.7 * Double(f))
        }
        c.rect(m.x - f, m.y - f, 2 * f, 2 * f, C(0x3A3A40))
        for i in 0..<(isTall(c) ? 26 : 14) {
            let fx = Int(noise(i * 7 + 640) * Double(c.w)) + Int(sin(t * 0.5 + Double(i)) * 6 * Double(s))
            let fy = g - (6 + Int(noise(i * 7 + 641) * 20)) * s + Int(cos(t * 0.7 + Double(i) * 2) * 3 * Double(s))
            let on = scenes3Phase(t, 2 + noise(i + 642) * 2, offset: noise(i + 643) * 4)
            guard on < 0.4 else { continue }
            let a = sin(on / 0.4 * .pi)
            c.rect(fx, fy, s, s, C(0xE8FF8A, a))
            c.circle(fx, fy, 2 * s, C(0xC8FF6A, a * 0.2))
        }
    }
}

// MARK: - Stryker's Island

extension Scenes {
    /// The waterline across the bay and the top of the prison wall.
    static func strykersLevels(_ c: PixelCanvas, _ g: Int) -> (water: Int, wall: Int) {
        let s = unit(g)
        return isTall(c) ? (g - g / 4, g - 22 * s) : (g - 30 * s, g - 17 * s)
    }

    /// The guard towers: x and the row of their lamps.
    static func strykersTowers(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let s = unit(g), lv = strykersLevels(c, g), up = (isTall(c) ? 64 : 22) * s
        return [(Int(Double(c.w) * 0.1), lv.wall - up), (Int(Double(c.w) * 0.9), lv.wall - up)]
    }

    /// How big the prison's towers are drawn: doubled on the screen saver.
    static func strykersScale(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? max(2, g / 130) : 1 }

    /// The Daily Planet's globe: centre and radius.
    static func strykersGlobe(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Int) {
        let s = unit(g), lv = strykersLevels(c, g)
        let hgt = isTall(c) ? g / 3 : 22 * s
        let r = (isTall(c) ? 9 : 5) * s
        return (Int(Double(c.w) * 0.36), lv.water - hgt - r, r)
    }

    /// Stryker's Island at night: the prison yard, its grey wall topped with coils of razor wire and a guard tower at
    /// either end, the cell block looming at the right. Across the black bay the Metropolis skyline glitters, the Daily
    /// Planet's globe turning on its tower and LexCorp's spire beside it, under a low, cloudy sky.
    static func strykersIsland(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), lv = strykersLevels(c, g)
        c.gradient(0, lv.water, C(0x0C1018), C(0x3A4252), bands: 7)
        let banks = c.w / 50 * (tall ? 4 : 1)
        for i in 0..<banks {
            let x = Int(noise(i * 5 + 1000) * Double(c.w)), y = Int(noise(i * 5 + 1001) * Double(lv.water) * 0.6)
            c.ellipse(x, y, (20 + Int(noise(i * 5 + 1002) * 30)) * s, (2 + Int(noise(i * 5 + 1003) * 3)) * s, C(0x4A5262, 0.35))
        }
        if tall { c.stars(0, g / 4, density: 200, seed: 91) }
        for k in 0..<4 { c.rect(0, lv.water - 5 * s - k * 5 * s, c.w, 5 * s, C(0x8A7A6A, 0.06)) }
        // Metropolis across the water
        var x = -4 * s, i = 0
        let maxH = Double(lv.water) * (tall ? 0.5 : 0.75)
        let globe = strykersGlobe(c, g)
        while x < c.w {
            let bw = (4 + Int(noise(i * 5 + 1010) * 9)) * s
            let bh = Int(maxH * (0.25 + noise(i * 5 + 1011) * 0.6))
            if abs(x + bw / 2 - globe.x) > 8 * s {
                c.rect(x, lv.water - bh, bw, bh, C(0x1C2230))
                for (j, wy) in stride(from: lv.water - bh + 2 * s, to: lv.water - s, by: 3 * s).enumerated() {
                    for (k, wx) in stride(from: x + s, to: x + bw - s, by: 2 * s).enumerated() where noise(i * 37 + j * 5 + k) > 0.65 {
                        c.rect(wx, wy, s, s, C(0xFFE0A0, 0.6))
                    }
                }
                if noise(i * 5 + 1012) > 0.75 { c.rect(x + bw / 2, lv.water - bh - 4 * s, s, 4 * s, C(0x1C2230)) }
            }
            x += bw + (noise(i * 5 + 1013) > 0.75 ? 2 * s : 0)
            i += 1
        }
        // the Daily Planet: its tower and the ring round the globe
        let dpTop = globe.y + globe.r + 2 * s, dw = globe.r + 2 * s
        c.rect(globe.x - dw, dpTop, dw * 2, lv.water - dpTop, C(0x2A3244))
        c.rect(globe.x - dw, dpTop, 2 * s, lv.water - dpTop, C(0x4A5468))
        c.rect(globe.x - dw - 2 * s, dpTop + (lv.water - dpTop) / 3, dw * 2 + 4 * s, lv.water - dpTop, C(0x242C3C))
        c.rect(globe.x - s, globe.y + globe.r, 2 * s, 2 * s, C(0x4A5468))
        for y in stride(from: dpTop + 2 * s, to: lv.water - s, by: 3 * s) { c.rect(globe.x - dw + 2 * s, y, dw * 2 - 4 * s, s, C(0xFFE0A0, 0.5)) }
        // LexCorp's spire
        let lx = Int(Double(c.w) * 0.58), lh = Int(maxH * 1.05)
        for k in 0..<(lh) {
            let hw = max(s, (5 * s) * k / max(1, lh / 3))
            c.rect(lx - min(hw, 5 * s), lv.water - lh + k, min(hw, 5 * s) * 2, 1, C(0x16302A))
        }
        c.rect(lx - s, lv.water - lh * 2 / 3, s, lh * 2 / 3, C(0x3A8A6A, 0.6))
        // the bay
        c.gradient(lv.water, lv.wall, C(0x0E1420), C(0x1A2230), bands: 3)
        for (j, y) in stride(from: lv.water + s, to: lv.wall, by: 2 * s).enumerated() {
            for k in 0..<(c.w / (14 * s)) where noise(j * 13 + k + 1020) > 0.55 {
                c.rect(k * 14 * s + Int(noise(j + k * 3 + 1021) * 8.0) * s, y, 3 * s, max(1, s / 2), C(0xFFD890, 0.25))
            }
        }
        strykersWall(c, g)
        c.ground(g, C(0x34383E), edge: C(0x6A7078), speck: C(0x2A2E34), seed: 91)
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x, g + 4 * s, 14 * s, s, C(0xC8B04A, 0.5)) }   // painted yard lines
    }

    /// The wall, the razor wire, the cell block and the two guard towers.
    static func strykersWall(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), lv = strykersLevels(c, g)
        let concrete = C(0x40464E), lit = C(0x646A74), dark = C(0x2C3138), f = strykersScale(c, g)
        // the cell block behind the wall at the right
        let bx = Int(Double(c.w) * 0.66), bw = Int(Double(c.w) * 0.18), bt = lv.wall - (isTall(c) ? 56 : 22) * s
        c.rect(bx, bt, bw, lv.wall - bt, C(0x3A4048))
        c.rect(bx, bt, bw, s, lit)
        for y in stride(from: bt + 3 * s, to: lv.wall - s, by: 5 * s) {
            for x in stride(from: bx + 2 * s, to: bx + bw - 2 * s, by: 4 * s) {
                c.rect(x, y, 2 * s, 3 * s, noise(x * 3 + y) > 0.7 ? C(0xE8D8A0, 0.7) : C(0x1A1E24))
                c.rect(x + s / 2, y, max(1, s / 2), 3 * s, C(0x5A6068))
            }
        }
        c.rect(0, lv.wall, c.w, g - lv.wall, concrete)
        c.rect(0, lv.wall, c.w, s, lit)
        for x in stride(from: 0, to: c.w, by: 16 * s) {
            c.rect(x, lv.wall + s, max(1, s / 2), g - lv.wall - s, dark)
            if noise(x + 1030) > 0.6 { c.rect(x + 5 * s, lv.wall + 3 * s, s, 6 * s, C(0x3A3E44)) }      // water stains
        }
        // razor wire: posts and coils along the top
        for x in stride(from: 0, to: c.w, by: 12 * s) { c.rect(x, lv.wall - 4 * s, s, 4 * s, C(0x5A5E66)) }
        for x in stride(from: 0, to: c.w, by: 3 * s) {
            c.rect(x, lv.wall - 3 * s, 2 * s, s, C(0x9AA0A8))
            c.rect(x + s, lv.wall - 2 * s, s, s, C(0x7A8088))
            c.rect(x, lv.wall - 4 * s, s, s, C(0x7A8088))
        }
        for p in strykersTowers(c, g) {                     // the guard towers: a tapering shaft, the cab, a lamp on the roof
            let sh = g - p.y - 5 * f
            for k in 0..<sh {
                let hw = 4 * f + k * 2 * f / max(1, sh)
                c.rect(p.x - hw, p.y + 5 * f + k, hw * 2, 1, C(0x484E58))
                c.rect(p.x - hw, p.y + 5 * f + k, f, 1, lit)
            }
            for y in stride(from: p.y + 9 * f, to: g - 4 * f, by: 8 * f) { c.rect(p.x - f, y, 2 * f, 2 * f, C(0x1A1E24)) }
            c.rect(p.x - 9 * f, p.y, 18 * f, 6 * f, C(0x2A2E36))
            c.rect(p.x - 8 * f, p.y + f, 16 * f, 4 * f, C(0xE8D8A0, 0.3))
            for k in 0..<4 { c.rect(p.x - 8 * f + k * 5 * f, p.y + f, f, 4 * f, C(0x2A2E36)) }
            c.rect(p.x - 11 * f, p.y - 2 * f, 22 * f, 2 * f, C(0x22262C))
            c.rect(p.x - 10 * f, p.y + 6 * f, 20 * f, f, C(0x5A6068))
            c.rect(p.x - s, p.y - 2 * f - 2 * s, 3 * s, 2 * s, C(0x6A7078))
        }
    }

    /// Searchlights sweeping from the towers, the Daily Planet's globe turning, beacons blinking on the skyline and
    /// glints on the bay.
    static func strykersIslandLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), lv = strykersLevels(c, g), f = strykersScale(c, g)
        for (i, p) in strykersTowers(c, g).enumerated() {
            let a: Double = sin(t * 0.45 + Double(i) * 2.2) * 0.8 + (i == 0 ? 0.35 : -0.35)
            let len = Double(lv.water) * (isTall(c) ? 0.8 : 1.4)
            let ly = Double(p.y - 2 * f - s)
            let ex = Double(p.x) + sin(a) * len, ey = ly - cos(a) * len * 0.8
            scenes3Beam(c, Double(p.x), ly, ex, ey, spread: 10 * Double(s), C(0xF0F0D8, 0.09))
            scenes3Beam(c, Double(p.x), ly, ex, ey, spread: 4 * Double(s), C(0xF0F0D8, 0.10))
            c.rect(p.x - s, p.y - 2 * f - 2 * s, 3 * s, 2 * s, C(0xFFFFE0))
        }
        // the globe: a gold ball with the continents sliding round
        let gl = strykersGlobe(c, g)
        c.circle(gl.x, gl.y, gl.r + s, C(0xFFC860, 0.2))
        c.circle(gl.x, gl.y, gl.r, C(0xC8902A))
        for k in 0..<3 {
            let u = scenes3Phase(t, 6, offset: Double(k) * 2)
            let lx = gl.x - gl.r + Int(u * Double(gl.r * 2))
            guard abs(lx - gl.x) < gl.r * 2 / 3 else { continue }
            c.rect(lx, gl.y - gl.r / 2 + k * s, max(s, gl.r / 3), gl.r * 2 / 3, C(0xFFE08A))
        }
        c.rect(gl.x - gl.r - 2 * s, gl.y, gl.r * 2 + 4 * s, max(1, s / 2), C(0xE8D0A0))
        if scenes3Phase(t, 1.8) < 0.2 {
            let lh = Int(Double(lv.water) * (isTall(c) ? 0.5 : 0.75) * 1.05)
            c.rect(Int(Double(c.w) * 0.58), lv.water - lh - s, s, s, C(0xFF4A4A))
        }
        for k in 0..<(c.w / (20 * s)) {
            let y = lv.water + s + Int(noise(k + 1040) * Double(max(1, lv.wall - lv.water - 4 * s)))
            let x = (k * 20 * s + Int(t * 3 * Double(s) * (0.5 + noise(k + 1041)))) % c.w
            c.rect(x, y, 2 * s, max(1, s / 2), C(0xC8D8F0, 0.35 + 0.3 * sin(t * 2 + Double(k))))
        }
    }
}

// MARK: - Belle Reve

extension Scenes {
    /// The prison's footprint: left edge, width, roof row, the waterline in front of it and its scale.
    static func belleReveFrame(_ c: PixelCanvas, _ g: Int) -> (x: Int, w: Int, top: Int, water: Int, f: Int) {
        let s = unit(g), tall = isTall(c)
        let water = g - 14 * s, f = tall ? max(2, g / 130) : 1
        return (Int(Double(c.w) * 0.3), Int(Double(c.w) * 0.42), water - 30 * f, water, f)
    }

    /// The cypresses: trunk x and seed.
    static func belleReveTrees(_ c: PixelCanvas) -> [(x: Int, seed: Int)] {
        [(Int(Double(c.w) * 0.04), 1), (Int(Double(c.w) * 0.17), 2), (Int(Double(c.w) * 0.95), 3)]
    }

    /// A cypress's crowns: each clump's centre and half-width.
    static func belleReveCrowns(_ c: PixelCanvas, _ g: Int, x: Int, seed: Int) -> [(x: Int, y: Int, rx: Int)] {
        let s = unit(g), tall = isTall(c)
        let hgt = tall ? g * 4 / 5 : g + 6 * s, top = g - hgt
        var out: [(x: Int, y: Int, rx: Int)] = []
        for k in 0..<(tall ? 5 : 2) {
            let cy = top + k * (tall ? hgt / 8 : 7 * s) + 2 * s
            let side = k % 2 == 0 ? -1 : 1
            let cx = x + side * (4 + Int(noise(seed * 13 + k) * 8.0)) * s
            out.append((cx, cy, (9 + Int(noise(seed * 13 + k + 5) * 7)) * s * (tall ? 3 : 2) / 2))
        }
        return out
    }

    /// Belle Reve at night: the brutal grey block of the penitentiary squats on a rise in the Louisiana swamp, slit
    /// windows lit, a guard tower at each corner and a chain-link fence topped with wire around it. Bald cypresses
    /// draped in Spanish moss frame the picture, a sickly green moon hangs in the haze and the black water runs up to
    /// the muddy bank the crew stands on.
    static func belleReve(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = belleReveFrame(c, g)
        c.gradient(0, f.water, C(0x0A100C), C(0x3A4A34), bands: 7)
        let mx = Int(Double(c.w) * 0.8), my = tall ? g / 5 : f.water / 3, mr = max(4, g / 18)
        c.circle(mx, my, mr * 3, C(0xC8D8A0, 0.06)); c.circle(mx, my, mr * 2, C(0xC8D8A0, 0.08))
        c.circle(mx, my, mr, C(0xD8E0B0))
        c.circle(mx - mr / 3, my + mr / 4, max(1, mr / 4), C(0xB8C490))
        if tall {
            c.stars(0, g / 3, density: 160, seed: 101)
            for i in 0..<6 {                               // ragged clouds over the swamp
                wisp(c, Int(noise(i * 5 + 1150) * Double(c.w)), g / 8 + Int(noise(i * 5 + 1151) * Double(g / 3)),
                     (40 + Int(noise(i * 5 + 1152) * 50)) * s, C(0x4A5A44, 0.5), s: s)
            }
        }
        // haze banks and the far treeline
        for k in 0..<4 { c.rect(0, f.water - 8 * s - k * 6 * s, c.w, 6 * s, C(0x8AA07A, 0.05)) }
        for x in stride(from: 0, to: c.w, by: 3 * s) {
            let h = (6 + Int(noise(x + 1100) * 8)) * s + (tall ? Int(noise(x + 1101) * 14) * s : 0)
            c.rect(x, f.water - h, 3 * s, h, C(0x1A241A))
            if noise(x + 1102) > 0.7 { c.rect(x + s, f.water - h - 4 * s, s, 4 * s, C(0x1A241A)) }
        }
        belleRevePrison(c, g)
        // the swamp water
        c.rect(0, f.water, c.w, g - f.water, C(0x141E18))
        for (j, y) in stride(from: f.water + s, to: g, by: 2 * s).enumerated() {
            for k in 0..<(c.w / (20 * s)) where noise(j * 7 + k + 1110) > 0.6 {
                c.rect(k * 20 * s + Int(noise(j + k + 1111) * 12.0) * s, y, (2 + Int(noise(k + 1112) * 4)) * s, max(1, s / 2), C(0x3A4A30, 0.6))
            }
        }
        for k in 0..<(c.w / (24 * s)) where noise(k + 1113) > 0.5 {          // lily pads
            c.ellipse(k * 24 * s + 6 * s, f.water + (3 + Int(noise(k + 1114) * 6)) * s, 2 * s, max(1, s / 2), C(0x3A5A2A))
        }
        for x in stride(from: f.x, to: f.x + f.w, by: 3 * s) where noise(x + 1115) > 0.5 {      // the prison's lights on the water
            c.rect(x, f.water + s + Int(noise(x + 1116) * 4.0) * s, 2 * s, max(1, s / 2), C(0xE8D890, 0.25))
        }
        for t in belleReveTrees(c) { belleReveCypress(c, g, x: t.x, seed: t.seed) }
        // the muddy bank
        c.dunes(base: g - s, amp: 1.5, freq: 0.06, phase: 2, bottom: g, C(0x2A2A1A), shade: C(0x4A4A2A))
        c.ground(g, C(0x2E2A1C), edge: C(0x5A5434), speck: C(0x22200E), seed: 101)
        for k in 0..<(c.w / (34 * s)) {                     // puddles and reeds
            let px = k * 34 * s + Int(noise(k + 1120) * 20.0) * s
            c.ellipse(px, g + 4 * s, 5 * s, s, C(0x1A2420))
            for r in 0..<3 { c.rect(px + (r * 3 - 9) * s, g - (3 + r) * s, s, (3 + r) * s, C(0x3A4A26)) }
            c.rect(px - 6 * s, g - 6 * s, s, 2 * s, C(0x5A3A22))
        }
    }

    /// The penitentiary block, its towers and fence.
    static func belleRevePrison(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = belleReveFrame(c, g), u = f.f
        let wall = C(0x4A5048), lit = C(0x6A7066), dark = C(0x2E342E)
        c.dunes(base: f.water - 2 * s, amp: 1, freq: 0.04, phase: 0, bottom: f.water, C(0x2A3424))
        // the main block and a taller centre wing
        c.rect(f.x, f.top + 8 * u, f.w, f.water - f.top - 8 * u, wall)
        c.rect(f.x + f.w / 3, f.top, f.w / 3, f.water - f.top, C(0x545A50))
        c.rect(f.x, f.top + 8 * u, f.w, u, lit); c.rect(f.x + f.w / 3, f.top, f.w / 3, u, lit)
        c.rect(f.x + f.w - 2 * u, f.top + 8 * u, 2 * u, f.water - f.top - 8 * u, dark)
        c.rect(f.x + f.w * 2 / 3 - u, f.top, u, f.water - f.top, dark)
        for y in stride(from: f.top + 11 * u, to: f.water - 3 * u, by: 5 * u) {
            for x in stride(from: f.x + 3 * u, to: f.x + f.w - 3 * u, by: 5 * u) {
                c.rect(x, y, u, 3 * u, noise(x * 5 + y) > 0.6 ? C(0xE8D890, 0.75) : C(0x1E221E))
            }
        }
        for x in stride(from: f.x + f.w / 3 + 3 * u, to: f.x + f.w * 2 / 3 - 3 * u, by: 5 * u) {
            c.rect(x, f.top + 3 * u, u, 3 * u, noise(x + 1117) > 0.5 ? C(0xE8D890, 0.75) : C(0x1E221E))
        }
        c.rect(f.x + f.w / 2 - 4 * u, f.water - 7 * u, 8 * u, 7 * u, C(0x1A1E1A))           // the gate
        for k in 0..<4 { c.rect(f.x + f.w / 2 - 3 * u + k * 2 * u, f.water - 7 * u, max(1, u / 2), 7 * u, C(0x6A7066)) }
        // the corner towers
        for tx in belleReveTowers(c, g) {
            let tt = f.top - 4 * u
            c.rect(tx - 2 * u, tt + 4 * u, 4 * u, f.water - tt - 4 * u, C(0x3A4038))
            c.rect(tx - 5 * u, tt, 10 * u, 4 * u, C(0x2A2E28))
            c.rect(tx - 4 * u, tt + u, 8 * u, 2 * u, C(0xE8D890, 0.4))
            c.rect(tx - 6 * u, tt - 2 * u, 12 * u, 2 * u, C(0x22261E))
        }
        // the chain-link fence and its barbed wire
        let fx0 = f.x - 12 * u, fx1 = f.x + f.w + 12 * u, ft = f.water - 8 * u
        for x in stride(from: fx0, to: fx1, by: 2 * s) {
            for y in stride(from: ft, to: f.water, by: 2 * s) { c.px(x + ((y / (2 * s)) % 2) * s, y, C(0x8A9488, 0.45)) }
        }
        for x in stride(from: fx0, through: fx1, by: 10 * u) { c.rect(x, ft - 2 * u, u, f.water - ft + 2 * u, C(0x6A7066)) }
        c.rect(fx0, ft, fx1 - fx0, max(1, s / 2), C(0x8A9488))
        for x in stride(from: fx0, to: fx1, by: 2 * s) { c.px(x, ft - s - (x / (2 * s)) % 2 * s, C(0x9AA498)) }
    }

    /// The guard towers' x.
    static func belleReveTowers(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let f = belleReveFrame(c, g)
        return [f.x - 4 * f.f, f.x + f.w + 4 * f.f]
    }

    /// A bald cypress: a tall trunk flaring wide at the waterline, crooked branches out to flat clumps of needles.
    /// The moss hanging from them is drawn in the moving layer so it can sway.
    static func belleReveCypress(_ c: PixelCanvas, _ g: Int, x: Int, seed: Int) {
        let s = unit(g), tall = isTall(c)
        let hgt = tall ? g * 4 / 5 : g + 6 * s, top = g - hgt
        let bark = C(0x221C16), barkLit = C(0x3A3026)
        for y in max(0, top)..<g {
            let k = Double(y - top) / Double(hgt)
            let hw = Int((1.5 + pow(k, 5) * 7) * Double(s) * (tall ? 1.8 : 1))
            c.rect(x - hw, y, hw * 2, 1, bark)
            c.rect(x - hw, y, max(1, s / 2), 1, barkLit)
        }
        for k in 0..<3 { c.rect(x + (k * 6 - 9) * s, g - 2 * s, 2 * s, 2 * s, bark) }     // cypress knees
        for cr in belleReveCrowns(c, g, x: x, seed: seed) {
            let dir = cr.x < x ? -1 : 1
            for k in 0..<abs(cr.x - x) {                                                  // the branch out to the clump
                c.rect(x + dir * k, cr.y + 3 * s - k / 3, s, s, bark)
            }
            let th = tall ? 5 * s : 3 * s
            c.ellipse(cr.x, cr.y, cr.rx, th, C(0x1A2618))
            c.ellipse(cr.x - cr.rx / 3, cr.y - th / 3, cr.rx / 2, th * 2 / 3, C(0x26361E))
            c.ellipse(cr.x + cr.rx / 3, cr.y, cr.rx / 2, th * 2 / 3, C(0x22301C))
            for k in 0..<4 {                                                          // ragged edges of needles
                let ex = cr.x + Int((noise(cr.x + k * 3) - 0.5) * Double(cr.rx * 2))
                c.ellipse(ex, cr.y - th / 2, cr.rx / 4 + s, th / 2, C(0x1E2C1A))
            }
            c.rect(cr.x - cr.rx, cr.y + 2 * s, cr.rx * 2, s, C(0x142012))
        }
    }

    /// Fog drifting across the water, Spanish moss swaying, a searchlight raking from a tower, fireflies, a gator's
    /// eyes surfacing now and then, and Task Force X's helicopter passing over with its spotlight down.
    static func belleReveLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = belleReveFrame(c, g), tall = isTall(c)
        // the searchlight
        let tx = belleReveTowers(c, g)[1], ty = f.top - 3 * f.f
        let a: Double = sin(t * 0.35) * 0.9 - 0.4
        let len = Double(g) * (tall ? 0.6 : 0.9)
        scenes3Beam(c, Double(tx), Double(ty), Double(tx) + sin(a) * len, Double(ty) - cos(a) * len * 0.7, spread: 7 * Double(s), C(0xE8F0C8, 0.09))
        scenes3Beam(c, Double(tx), Double(ty), Double(tx) + sin(a) * len, Double(ty) - cos(a) * len * 0.7, spread: 2 * Double(s), C(0xE8F0C8, 0.09))
        c.rect(tx - s, ty - s, 2 * s, 2 * s, C(0xFFFFE0))
        // Spanish moss, swaying more towards the ends of the strands
        let moss = C(0x6A7A62, 0.8), mossLit = C(0x8A9A7A, 0.6)
        for tr in belleReveTrees(c) {
            for (k, cr) in belleReveCrowns(c, g, x: tr.x, seed: tr.seed).enumerated() {
                for m in stride(from: cr.x - cr.rx + 2 * s, to: cr.x + cr.rx - 2 * s, by: 2 * s) where noise(m * 3 + tr.seed + k) > 0.35 {
                    let len = (4 + Int(noise(m + tr.seed * 7 + k) * 12)) * s
                    let sway = sin(t * 0.9 + Double(m) * 0.05)
                    let y0 = cr.y + 2 * s
                    c.rect(m, y0, s, len / 2, moss)
                    c.rect(m + Int((sway * 0.8).rounded()) * s, y0 + len / 2, s, len / 4, moss)
                    c.rect(m + Int((sway * 1.6).rounded()) * s, y0 + len * 3 / 4, s, len / 4, mossLit)
                }
            }
        }
        // fog banks rolling across
        for k in 0..<(tall ? 7 : 4) {
            let speed = (3 + noise(k + 1130) * 4) * Double(s)
            let span = Double(c.w + 120 * s)
            let x = Int((t * speed + noise(k + 1131) * span).truncatingRemainder(dividingBy: span)) - 60 * s
            let y = f.water - 2 * s + Int(noise(k + 1132) * Double(g - f.water))
            c.ellipse(x, y, (30 + Int(noise(k + 1133) * 30)) * s, 2 * s, C(0xB8C8A8, 0.10))
            c.ellipse(x + 10 * s, y - s, (16 + Int(noise(k + 1134) * 16)) * s, s, C(0xC8D8B8, 0.10))
        }
        // a gator's eyes and snout
        let gp = scenes3Phase(t, 11)
        if gp < 0.5 {
            let gx = Int(Double(c.w) * 0.62) - Int(gp * 30 * Double(s)), gy = g - 5 * s
            let rise = min(1, min(gp, 0.5 - gp) * 10)
            c.rect(gx, gy, 6 * s, s, C(0x2A3A22, rise))
            c.rect(gx + 6 * s, gy - s, s, s, C(0xC8D84A, rise)); c.rect(gx + 8 * s, gy - s, s, s, C(0xC8D84A, rise))
            c.rect(gx + 6 * s, gy, 4 * s, s, C(0x3A4A2A, rise))
            c.rect(gx + 10 * s, gy, 6 * s, max(1, s / 2), C(0x5A6A4A, rise * 0.6))
        }
        for i in 0..<(tall ? 20 : 10) {
            let fx = Int(noise(i * 7 + 1140) * Double(c.w)) + Int(sin(t * 0.6 + Double(i)) * 5 * Double(s))
            let fy = f.water - (2 + Int(noise(i * 7 + 1141) * 14)) * s + Int(cos(t * 0.8 + Double(i)) * 3 * Double(s))
            let on = scenes3Phase(t, 2.5 + noise(i + 1142) * 2, offset: noise(i + 1143) * 4)
            guard on < 0.4 else { continue }
            let al = sin(on / 0.4 * .pi)
            c.rect(fx, fy, s, s, C(0xD8FF7A, al))
            c.circle(fx, fy, 2 * s, C(0xC8FF6A, al * 0.18))
        }
        // Task Force X's helicopter: across the sky from the right, then a long pause
        let speed = 30.0 * Double(s), travel = Double(c.w + 60 * s), dur = travel / speed, cycle = dur + 14
        let ph = (t + 1).truncatingRemainder(dividingBy: cycle)
        guard ph < dur else { return }
        let hx = c.w + 30 * s - Int(ph * speed), hy = tall ? g / 4 : 4 * s
        scenes3Beam(c, Double(hx + 5 * s), Double(hy + 6 * s), Double(hx - 4 * s), Double(f.water), spread: 8 * Double(s), C(0xE8F0C8, 0.07))
        let spin = scenes3Phase(t, 0.16) < 0.5
        scenes3Stamp(c, hx, hy, [
            spin ? "rrrrrrrrrrrrr...." : "...rrrrrrrrrrrrr.",
            "......d..........",
            "...ddddddd.......",
            "..wwdddddddddddt.",
            "..ddddddddd...dtt",
            "....d...d........",
            "..ddddddddd......",
        ], ["r": C(0x6A7066, 0.8), "d": C(0x1E241C), "w": C(0x8AA0A0), "t": C(0x2A3028)], s: s)
        if scenes3Phase(t, 0.9) < 0.3 { c.rect(hx + 15 * s, hy + 3 * s, s, s, C(0xFF4A3A)) }
    }
}
