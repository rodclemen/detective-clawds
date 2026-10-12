import Foundation

let scenes2: [Location: Place] = [
    .watchtower: Place(name: "The Watchtower", panel: 0x10141E, still: Scenes.watchtower, moving: Scenes.watchtowerLife),
    .hallOfJustice: Place(name: "Hall of Justice", panel: 0x1C2230, still: Scenes.hallOfJustice, moving: Scenes.hallLife),
    .arkham: Place(name: "Arkham Asylum", panel: 0x121119, still: Scenes.arkham, moving: Scenes.arkhamLife),
    .centralCity: Place(name: "Central City", panel: 0x241618, still: Scenes.centralCity, moving: Scenes.centralLife),
    .starCity: Place(name: "Star City", panel: 0x16182A, still: Scenes.starCity, moving: Scenes.starCityLife),
    .oa: Place(name: "Oa", panel: 0x08140F, still: Scenes.oa, moving: Scenes.oaLife),
]

// MARK: - Shared bits for these scenes

/// Draws in units of `s` pixels from an origin, with `s` chosen by the caller (landmarks grow on the screen saver).
fileprivate struct S2Pen {
    let c: PixelCanvas, x: Int, y: Int, s: Int
    func rect(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, y + v * s, w * s, h * s, col) }
    func ellipse(_ u: Int, _ v: Int, _ rx: Int, _ ry: Int, _ col: Px) { c.ellipse(x + u * s, y + v * s, rx * s, ry * s, col) }
    func circle(_ u: Int, _ v: Int, _ r: Int, _ col: Px) { c.circle(x + u * s, y + v * s, r * s, col) }
    /// A pointed roof: apex at (u, v), `half` units wide each side at its foot, `h` units tall.
    func roof(_ u: Int, _ v: Int, half: Int, h: Int, _ col: Px) {
        let rows = h * s
        for r in 0..<rows {
            let hw = half * s * (r + 1) / rows
            c.rect(x + u * s - hw, y + v * s + r, max(1, 2 * hw), 1, col)
        }
    }
    /// A trapezoid `w` units wide at the bottom, narrowing by `inset` units each side at the top, `h` units tall.
    func trap(_ u: Int, _ v: Int, _ w: Int, _ h: Int, inset: Int, _ col: Px) {
        let rows = h * s
        for r in 0..<rows {
            let ins = inset * s * (rows - 1 - r) / max(1, rows)
            c.rect(x + u * s + ins, y + v * s + r, w * s - 2 * ins, 1, col)
        }
    }
}

/// A 3×5 pixel alphabet, for the names over doorways.
fileprivate let scenes2Font: [Character: [String]] = [
    "A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"], "E": ["###", "#..", "##.", "#..", "###"],
    "F": ["###", "#..", "##.", "#..", "#.."], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"], "J": ["..#", "..#", "..#", "#.#", ".#."],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"], "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#.#", "###", "###", "#.#", "#.#"], "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"], "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
    ".": ["...", "...", "...", "...", ".#."],
]

extension Scenes {
    /// String art drawn with every character `s` pixels square.
    static func scenes2Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
        }
    }

    /// Where a repeating motion of `period` seconds is, from 0 up to 1.
    static func scenes2Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
        let v = (t + offset).truncatingRemainder(dividingBy: period) / period
        return v < 0 ? v + 1 : v
    }

    /// How big landmarks are drawn: 1 in the window's strip, 2 or more on the screen saver.
    static func scenes2Big(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? max(2, g / 120) : 1 }

    /// Capital letters in the 3×5 alphabet, centred on `cx`.
    static func scenes2Text(_ c: PixelCanvas, cx: Int, y: Int, _ text: String, _ col: Px, s: Int) {
        let width = (text.count * 4 - 1) * s
        var x = cx - width / 2
        for ch in text {
            if let rows = scenes2Font[ch] { scenes2Stamp(c, x, y, rows, ["#": col], s: s) }
            x += 4 * s
        }
    }

    /// Smooth value noise on a grid that wraps every `period` cells across.
    static func scenes2Value(_ x: Double, _ y: Double, period: Int, seed: Int) -> Double {
        let xi = Int(floor(x)), yi = Int(floor(y))
        let fx = x - Double(xi), fy = y - Double(yi)
        let ux = fx * fx * (3 - 2 * fx), uy = fy * fy * (3 - 2 * fy)
        let v = { (i: Int, j: Int) -> Double in
            let ii = ((i % period) + period) % period
            return noise(ii * 57 + j * 911 + seed * 7919)
        }
        let a = v(xi, yi), b = v(xi + 1, yi), c0 = v(xi, yi + 1), d = v(xi + 1, yi + 1)
        let top = a + (b - a) * ux, bottom = c0 + (d - c0) * ux
        return top + (bottom - top) * uy
    }

    /// A jagged bolt of lightning from one point to another, its kinks fixed by `seed`.
    static func scenes2Bolt(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, kinks: Int, seed: Int,
                            jitter: Double, core: Px, glow: Px, s: Double) {
        let dx = x1 - x0, dy = y1 - y0, len = max(1, (dx * dx + dy * dy).squareRoot())
        let nx = -dy / len, ny = dx / len
        var px = x0, py = y0
        for k in 1...max(1, kinks) {
            let f = Double(k) / Double(kinks)
            let off: Double = k == kinks ? 0 : (noise(seed * 37 + k) - 0.5) * 2 * jitter
            let x = x0 + dx * f + nx * off, y = y0 + dy * f + ny * off
            c.glowLine(px, py, x, y, core: core, glow: glow, coreR: 0.6 * s, glowR: 2.0 * s)
            if k == kinks / 2, kinks > 3 {                       // a fork off the middle
                let fx = x + nx * jitter * 1.5 + dx * 0.15, fy = y + ny * jitter * 1.5 + dy * 0.15
                c.glowLine(x, y, fx, fy, core: core, glow: glow, coreR: 0.4 * s, glowR: 1.5 * s, strength: 0.8)
            }
            px = x; py = y
        }
    }

    /// One building of a skyline.
    struct S2Block { let x, y, w, h: Int }

    /// A row of buildings standing on `base`, `lo` to `hi` pixels tall, `minW` to `maxW` wide.
    static func scenes2Blocks(_ width: Int, base: Int, lo: Int, hi: Int, minW: Int, maxW: Int, gap: Int, seed: Int) -> [S2Block] {
        var out: [S2Block] = []
        var x = -3, i = 0
        while x < width {
            let bw = minW + Int(noise(i * 7 + seed * 131) * Double(max(1, maxW - minW)))
            var bh = lo + Int(noise(i * 7 + 1 + seed * 131) * Double(max(1, hi - lo)))
            if noise(i * 7 + 3 + seed * 131) > 0.86 { bh = bh * 13 / 10 }
            out.append(S2Block(x: x, y: base - bh, w: bw, h: bh))
            x += bw + Int(noise(i * 7 + 2 + seed * 131) * Double(gap))
            i += 1
        }
        return out
    }

    /// A skyline building with a lighter roof line and a scatter of lit windows every `step` pixels.
    static func scenes2Building(_ c: PixelCanvas, _ b: S2Block, _ col: Px, roof: Px, window: Px?, chance: Double, step: Int, seed: Int) {
        c.rect(b.x, b.y, b.w, b.h, col)
        c.rect(b.x, b.y, b.w, 1, roof)
        guard let window else { return }
        for (j, wy) in stride(from: b.y + step, to: b.y + b.h - 1, by: step + 1).enumerated() {
            for (k, wx) in stride(from: b.x + 1, to: b.x + b.w - 1, by: step).enumerated()
            where noise(b.x * 31 + j * 7 + k * 13 + seed * 977) > 1 - chance {
                c.rect(wx, wy, max(1, step / 2), 1, window.alpha(0.55 + noise(j + k * 3 + b.x) * 0.45))
            }
        }
    }
}

// MARK: - The Watchtower

extension Scenes {
    /// The great window: its edges, and Earth's centre and radius below it.
    static func watchtowerWindow(_ c: PixelCanvas, _ g: Int) -> (x0: Int, x1: Int, top: Int, bottom: Int, ex: Int, ey: Int, er: Int) {
        let s = unit(g), tall = isTall(c)
        let top = tall ? g / 6 : 3, bottom = g - 13 * s * scenes2Big(c, g) / (tall ? 2 : 1)
        let er = Int(Double(c.w) * (tall ? 0.6 : 0.62))
        let cap = Int(Double(bottom - top) * (tall ? 0.48 : 0.42))
        return (8 * s, c.w - 8 * s, top, bottom, Int(Double(c.w) * 0.56), bottom - cap + er, er)
    }

    /// How much sunlight falls on Earth at a point of its face (the sun is off to the upper left), in steps.
    static func watchtowerLight(_ nx: Double, _ ny: Double, _ nz: Double) -> Double {
        let l = -1.2 * nx - 0.3 * ny + 0.35 * nz
        return (max(0, min(1, l * 1.2 + 0.1)) * 5).rounded(.down) / 5
    }

    /// The Watchtower, the Justice League's satellite: the crew is on the deck of the monitor womb, in front of the
    /// round meeting table with its high-backed chairs. Behind them a great window, braced into panes, looks down on
    /// Earth turning below, its blue limb glowing against the stars, day on the left and night with city lights on
    /// the right. On the screen saver the steel ceiling rises above, with light strips and the League's gold plaque.
    static func watchtower(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), w = watchtowerWindow(c, g), b = scenes2Big(c, g)
        // space through the window
        c.gradient(w.top, w.bottom, C(0x02030A), C(0x0A1430), bands: 6)
        c.stars(w.top, w.bottom, density: 55, seed: 21, x0: w.x0, x1: w.x1)
        if tall {                                               // the Moon, small and far off
            let mx = w.x0 + (w.x1 - w.x0) / 6, my = w.top + (w.bottom - w.top) / 5
            c.circle(mx, my, 6 * s, C(0xC8CCD8)); c.circle(mx + 2 * s, my - s, 2 * s, C(0xA8ACB8))
            c.circle(mx - 2 * s, my + 2 * s, s, C(0xA8ACB8))
        }
        // Earth's ocean, shaded, with its blue halo of air
        let R = Double(w.er), halo = Double(6 * s)
        for y in max(w.top, w.ey - w.er - 6 * s)..<w.bottom {
            let dy = Double(y - w.ey) + 0.5
            for x in w.x0..<w.x1 {
                let dx = Double(x - w.ex) + 0.5, d = (dx * dx + dy * dy).squareRoot()
                if d > R + halo { continue }
                if d > R {
                    let f = 1 - (d - R) / halo
                    c.px(x, y, C(0x5AA8FF, (f * 3).rounded(.up) / 3 * 0.32))
                    continue
                }
                let nx = dx / R, ny = dy / R, nz = max(0, 1 - nx * nx - ny * ny).squareRoot()
                let lit = watchtowerLight(nx, ny, nz)
                var col = lerp(C(0x050C22), C(0x1E58A8), lit)
                if nz < 0.3 { col = lerp(col, C(0x8AC8FF), (0.3 - nz) / 0.3 * 0.7 * max(0.25, lit)) }
                c.px(x, y, col)
            }
        }
        // the steel around the window
        let wall = C(0x161C2A)
        c.rect(0, 0, c.w, w.top, wall); c.rect(0, w.top, w.x0, w.bottom - w.top, wall)
        c.rect(w.x1, w.top, c.w - w.x1, w.bottom - w.top, wall); c.rect(0, w.bottom, c.w, g - w.bottom, wall)
        if tall { watchtowerCeiling(c, g) }
        // the frame and its struts, with braced corners on every pane
        let frame = C(0x323C52), lite = C(0x7A8AA8), fw = 3 * s
        c.rect(w.x0 - fw, w.top - fw, w.x1 - w.x0 + 2 * fw, fw, frame); c.rect(w.x0 - fw, w.bottom, w.x1 - w.x0 + 2 * fw, fw, frame)
        c.rect(w.x0 - fw, w.top, fw, w.bottom - w.top, frame); c.rect(w.x1, w.top, fw, w.bottom - w.top, frame)
        c.rect(w.x0, w.top, w.x1 - w.x0, 1, lite.alpha(0.6))
        watchtowerStruts(c, g)
        // the console sill under the window, its lights dim until they blink
        let sill = w.bottom + fw
        c.rect(0, sill, c.w, s, C(0x5A6A88))
        c.rect(0, sill + s, c.w, g - sill - s, C(0x1A2132))
        for x in stride(from: 4 * s, to: c.w - 4 * s, by: 6 * s) where noise(x + 501) > 0.35 {
            c.rect(x, sill + 3 * s, 2 * s, s, [C(0x3A6A9A), C(0x3A8A5A), C(0x8A6A2A)][Int(noise(x + 502) * 3) % 3])
        }
        for x in stride(from: 0, to: c.w, by: 40 * s) { c.rect(x, sill + s, s, g - sill - s, C(0x10151F)) }
        watchtowerTable(c, g, b: b)
        // the deck
        c.ground(g, C(0x252B3A), edge: C(0x7A8AA8), speck: C(0x1E2432), seed: 51)
        for x in stride(from: 0, to: c.w, by: 24 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x1A202C)) }
        c.rect(0, g + 2 * s, c.w, s, C(0x3A6AA8, 0.35))
    }

    /// The struts splitting the window into panes, and the braces in their corners (drawn again over the turning
    /// Earth, which would otherwise paint over them).
    static func watchtowerStruts(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), w = watchtowerWindow(c, g)
        let frame = C(0x323C52), lite = C(0x7A8AA8)
        let panes = max(3, (w.x1 - w.x0) / (90 * s))
        let brace = max(3 * s, (w.bottom - w.top) / 8)
        for k in 0...panes {
            let x = w.x0 + (w.x1 - w.x0) * k / panes
            if k > 0, k < panes {
                c.rect(x - s, w.top, 3 * s, w.bottom - w.top, frame); c.rect(x - s, w.top, s, w.bottom - w.top, lite.alpha(0.5))
            }
            for r in 0..<brace {                                  // the corner braces
                let run = brace - r
                if k < panes { c.rect(x + (k > 0 ? 2 * s : 0), w.top + r, run, 1, frame); c.rect(x + (k > 0 ? 2 * s : 0), w.bottom - 1 - r, run, 1, frame) }
                if k > 0 { c.rect(x - (k < panes ? s : 0) - run, w.top + r, run, 1, frame); c.rect(x - (k < panes ? s : 0) - run, w.bottom - 1 - r, run, 1, frame) }
            }
        }
    }

    /// The round table where the League sits, its emblem glowing in the middle, and the high-backed chairs behind it.
    static func watchtowerTable(_ c: PixelCanvas, _ g: Int, b: Int) {
        let p = S2Pen(c: c, x: Int(Double(c.w) * 0.24), y: g, s: b)
        for k in 0..<7 {                                          // chair backs along the far side
            let u = -30 + k * 10
            p.rect(u - 2, -15, 5, 9, C(0x222A3E)); p.rect(u - 2, -15, 5, 1, C(0x5A6A8A))
            p.rect(u - 1, -14, 3, 1, [C(0x8A2A2A), C(0x2A4A9A), C(0xC8A030), C(0x2A8A4A), C(0xC8C8D0), C(0x6A2A8A), C(0x2A8A8A)][k])
        }
        p.rect(-3, -6, 6, 6, C(0x1A2030))                          // the pedestal
        p.ellipse(0, -7, 36, 3, C(0x2A3448))
        p.ellipse(0, -8, 36, 2, C(0x3E4A62))
        p.rect(-36, -8, 72, 1, C(0x8A9AB8))
        p.ellipse(0, -8, 8, 1, C(0x8AD0FF, 0.5))
        p.rect(-2, -8, 4, 1, C(0xDAF0FF))
    }

    /// Up high on the screen saver: ceiling ribs, light strips, and the gold JL plaque over the window.
    static func watchtowerCeiling(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), b = scenes2Big(c, g), w = watchtowerWindow(c, g)
        for x in stride(from: 0, to: c.w, by: 30 * s) {
            c.rect(x, 0, 2 * s, w.top, C(0x0E121C)); c.rect(x + 2 * s, 0, s, w.top, C(0x2A3246))
        }
        c.rect(0, w.top / 5, c.w, 2 * s, C(0x9AD0FF, 0.55)); c.rect(0, w.top / 5 + 2 * s, c.w, s, C(0x9AD0FF, 0.15))
        c.rect(0, w.top - 9 * s, c.w, s, C(0x0E121C))
        let px = c.w / 2, py = w.top / 2 - 2 * b
        let p = S2Pen(c: c, x: px, y: py, s: b)
        p.rect(-9, -6, 18, 12, C(0xA8822A)); p.rect(-8, -5, 16, 10, C(0x1A2A5A))
        p.trap(-9, 6, 18, 3, inset: 0, C(0xA8822A))
        p.roof(0, 6, half: 9, h: 5, C(0xA8822A)); p.roof(0, 5, half: 8, h: 4, C(0x1A2A5A))
        scenes2Stamp(c, px - 7 * b, py - 3 * b, [
            ".JJJ..L.....",
            "..J...L.....",
            "..J...L.....",
            "J.J...L.....",
            "JJ....LLLL..",
        ], ["J": C(0xF0D070), "L": C(0xF0D070)], s: b)
        c.circle(px, py, 16 * b, C(0xF0D070, 0.05))
    }

    /// Earth's face as of one turn of the globe, drawn into a canvas covering the window from the top of the cap down.
    static func watchtowerEarth(_ c: PixelCanvas, _ g: Int, step: Int) -> PixelCanvas {
        let w = watchtowerWindow(c, g), R = Double(w.er), y0 = max(w.top, w.ey - w.er)
        let e = PixelCanvas(max(1, w.x1 - w.x0), max(1, w.bottom - y0))
        e.ox = -w.x0; e.oy = -y0
        // tilt the globe so the band in view is the tropics, not the pole
        let capMid = Double(w.bottom - y0) / 2
        let ny0 = -(1 - capMid / R), nz0 = max(0.01, 1 - ny0 * ny0).squareRoot()
        let tilt = atan2(ny0, nz0), ct = cos(tilt), st = sin(tilt)
        let spin = Double(step) / R, twoPi = 2 * Double.pi
        for y in y0..<w.bottom {
            let dy = Double(y - w.ey) + 0.5, half2 = R * R - dy * dy
            guard half2 > 0 else { continue }
            let half = Int(half2.squareRoot())
            let xa = max(w.x0, w.ex - half), xb = min(w.x1, w.ex + half)
            guard xb > xa else { continue }
            let ny = dy / R
            for x in xa..<xb {
                let nx = (Double(x - w.ex) + 0.5) / R
                let nz = max(0, 1 - nx * nx - ny * ny).squareRoot()
                let y2 = ny * ct - nz * st, z2 = ny * st + nz * ct
                let lat = asin(max(-1, min(1, y2))), lon = atan2(nx, z2) + spin
                let u = lon / twoPi * 24, v = (lat / Double.pi + 0.5) * 12
                let lit = watchtowerLight(nx, ny, nz)
                if abs(lat) > 1.15 {
                    e.px(x, y, lerp(C(0x3A4458), C(0xE8F0F8), lit))
                } else {
                    let land = scenes2Value(u, v, period: 24, seed: 3) * 0.65 + scenes2Value(u * 3, v * 3, period: 72, seed: 4) * 0.35
                    if land > 0.56 {
                        let dry = scenes2Value(u * 2, v * 2, period: 48, seed: 5) > 0.62
                        e.px(x, y, lerp(dry ? C(0x2A2414) : C(0x0C1A10), dry ? C(0xB89A5A) : C(0x4A8A3A), lit))
                        if lit < 0.2, noise(Int(u * 20) * 7 + Int(v * 20) * 131) > 0.87 { e.px(x, y, C(0xFFD27A, 0.85)) }
                    }
                }
                let cl = scenes2Value(u * 3 + spin * 2, v * 4, period: 72, seed: 9)
                if cl > 0.68 { e.px(x, y, C(0xF4F8FF, 0.15 + 0.65 * lit)) }
            }
        }
        e.ox = 0; e.oy = 0
        return e
    }

    /// The last Earth drawn, kept until the globe has turned another pixel (it turns slowly, and it's the costly bit).
    private static let watchtowerEarthLock = NSLock()
    nonisolated(unsafe) private static var watchtowerEarthCache: (w: Int, h: Int, step: Int, earth: PixelCanvas)?

    /// Earth turning below (continents, ice, drifting cloud, city lights on the night side), the console lights
    /// blinking, and now and then a Javelin gliding past the window.
    static func watchtowerLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), w = watchtowerWindow(c, g), b = scenes2Big(c, g)
        let step = Int(t * 0.02 * Double(w.er))
        watchtowerEarthLock.lock()
        let earth: PixelCanvas
        if let k = watchtowerEarthCache, k.w == c.w, k.h == c.h, k.step == step {
            earth = k.earth
        } else {
            earth = watchtowerEarth(c, g, step: step)
            watchtowerEarthCache = (c.w, c.h, step, earth)
        }
        watchtowerEarthLock.unlock()
        c.paste(earth, x: w.x0, y: max(w.top, w.ey - w.er))
        watchtowerStruts(c, g)
        watchtowerTable(c, g, b: b)
        // the console lights
        let sill = w.bottom + 3 * s
        for x in stride(from: 4 * s, to: c.w - 4 * s, by: 6 * s) where noise(x + 501) > 0.35 {
            if noise(Int(t * 2 + noise(x) * 5) * 17 + x) > 0.6 {
                c.rect(x, sill + 3 * s, 2 * s, s, [C(0x8AD0FF), C(0x7AFF9A), C(0xFFC85A)][Int(noise(x + 502) * 3) % 3])
            }
        }
        // a Javelin gliding past, then a long pause
        let speed = 22.0 * Double(b), travel = Double(c.w + 40 * b), dur = travel / speed, cycle = dur + 14
        let ph = (t + 3).truncatingRemainder(dividingBy: cycle)
        guard ph < dur else { return }
        let jx = Int(Double(c.w + 20 * b) - ph * speed), jy = w.top + (w.bottom - w.top) / 4
        scenes2Stamp(c, jx, jy, [
            "........dd....",
            "..cddddddddd..",
            "dddddddddddddee",
            "...dddddddd...",
            "........dd....",
        ], ["d": C(0x8A94A8), "c": C(0x9AD8FF), "e": C(0x8AE0FF)], s: b)
        c.rect(jx + 2 * b, jy + 3 * b, 10 * b, b, C(0x4A5468))
        c.rect(jx + 15 * b, jy + 2 * b, 5 * b, b, C(0x8AE0FF, 0.35))
        if scenes2Phase(t, 0.9) < 0.4 { c.rect(jx + 8 * b, jy, b, b, C(0xFF5A5A)) }
    }
}

// MARK: - Hall of Justice

extension Scenes {
    /// The hall's centre, the row its front stands on, and the size of one unit of it.
    static func hallFrame(_ c: PixelCanvas, _ g: Int) -> (cx: Int, base: Int, b: Int) {
        let b = scenes2Big(c, g)
        return (c.w / 2, g - 6 * b, b)
    }

    /// Where the flagpoles stand along the plaza (x of each pole) and the row their tops reach.
    static func hallPoles(_ c: PixelCanvas, _ g: Int) -> (xs: [Int], top: Int) {
        let f = hallFrame(c, g)
        var xs: [Int] = []
        for k in 0..<3 { for side in [-1, 1] { xs.append(f.cx + side * (54 + k * 22) * f.b) } }
        return (xs, f.base + 2 * f.b - 34 * f.b)
    }

    /// The Hall of Justice on a bright day: the Super Friends' white hall, its colonnade under the carved name band,
    /// the great ribbed dome on its drum with a flag on the cupola, long low wings either side, a row of flags along
    /// the sunny plaza, clipped hedges and round trees, and the pale towers of the city far behind.
    static func hallOfJustice(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = hallFrame(c, g), b = f.b, s = unit(g)
        c.gradient(0, g, C(0x2E7AD0), C(0xB8DCF4), bands: 7)
        if tall {
            let sx = Int(Double(c.w) * 0.82), sy = g / 7
            c.circle(sx, sy, 22 * s, C(0xFFF4C8, 0.12)); c.circle(sx, sy, 15 * s, C(0xFFF4C8, 0.18))
            c.circle(sx, sy, 10 * s, C(0xFFF8E0))
            for i in 0..<6 { cloud(c, Int(noise(i * 3 + 70) * Double(c.w)), g / 4 + Int(noise(i * 3 + 71) * Double(g / 4)), (4 + i % 3 * 2) * s, seed: i + 40) }
            for i in 0..<4 { wisp(c, Int(noise(i * 3 + 80) * Double(c.w)), g / 12 + Int(noise(i * 3 + 81) * Double(g / 6)), 50 * s, C(0xE8F4FC, 0.5), s: s) }
        } else {
            cloud(c, Int(Double(c.w) * 0.12), 8, 3, seed: 41); cloud(c, Int(Double(c.w) * 0.86), 6, 3, seed: 42)
        }
        // the city far behind, pale in the haze
        for blk in scenes2Blocks(c.w, base: f.base, lo: 10 * b, hi: 26 * b, minW: 6 * b, maxW: 16 * b, gap: 6 * b, seed: 17) {
            scenes2Building(c, blk, C(0x8AB4DC), roof: C(0xA8CCEC), window: nil, chance: 0, step: 3, seed: 0)
        }
        for k in 0..<2 { c.rect(0, f.base - (4 + k * 4) * b, c.w, 4 * b, C(0xD8ECF8, 0.25)) }
        hallTrees(c, g)
        hallBuilding(c, g)
        // the plaza
        c.rect(0, f.base, c.w, g - f.base, C(0xE4DED0))
        for y in stride(from: f.base + 2 * b, to: g, by: 2 * b) { c.rect(0, y, c.w, 1, C(0xCCC4B2)) }
        for k in -20...20 {                                         // paving seams fanning out toward us
            let x0 = Double(f.cx + k * 10 * b), x1 = Double(f.cx + k * 16 * b)
            for y in f.base..<g {
                let fy = Double(y - f.base) / Double(max(1, g - f.base))
                c.px(Int(x0 + (x1 - x0) * fy), y, C(0xCCC4B2))
            }
        }
        let p = S2Pen(c: c, x: f.cx, y: f.base, s: b)
        for k in 0..<3 { p.rect(-38 - 2 * k, k, 76 + 4 * k, 1, k % 2 == 0 ? C(0xF6F2EA) : C(0xC8C0B0)) }   // front steps
        let poles = hallPoles(c, g)
        for x in poles.xs {
            c.rect(x, poles.top, max(1, b), f.base + 2 * b - poles.top, C(0x9AA4B4))
            c.rect(x - b, poles.top - b, 2 * b + 1, b, C(0xE8C860))
            c.rect(x - b, f.base + b, 3 * b, b, C(0x8A8A94))
        }
        c.ground(g, C(0xCCC4B2), edge: C(0xF4EEE2), speck: C(0xB8B0A0), seed: 61)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0xB4AC9C)) }
    }

    /// The hall itself: wings, central block with its name band and colonnade, drum and dome.
    static func hallBuilding(_ c: PixelCanvas, _ g: Int) {
        let f = hallFrame(c, g), b = f.b
        let p = S2Pen(c: c, x: f.cx, y: f.base, s: b)
        let marble = C(0xF2F4F6), shade = C(0xCDD5E0), glass = C(0x34587E)
        // the wings
        p.rect(-112, -18, 224, 18, marble); p.rect(-113, -19, 226, 1, C(0xFFFFFF)); p.rect(-112, -18, 224, 1, shade)
        p.rect(-112, -2, 224, 2, C(0xDAD4C8))
        for side in [-1, 1] {
            var u = 50
            while u < 108 {
                let x = side < 0 ? -u - 4 : u
                p.rect(x, -15, 4, 11, glass); p.rect(x, -15, 4, 1, C(0x1E3450)); p.rect(x + 1, -14, 1, 5, C(0x8AB4DA, 0.6))
                p.rect(x - 2, -16, 1, 14, shade)
                u += 9
            }
            p.rect(side < 0 ? -112 : 109, -18, 3, 18, shade)
        }
        // the central block
        p.rect(-44, -30, 88, 30, marble); p.rect(-46, -32, 92, 2, C(0xFFFFFF)); p.rect(-46, -30, 92, 1, shade)
        p.rect(-44, -23, 88, 1, C(0xB8C2D0))
        scenes2Text(c, cx: f.cx, y: f.base - 28 * b, "HALL OF JUSTICE", C(0x3A4A66), s: b)
        p.rect(-40, -22, 80, 22, C(0xA6B2C4))                       // the shaded colonnade behind the columns
        p.rect(-40, -22, 80, 2, C(0x8A98AE))
        p.rect(-8, -15, 16, 15, C(0x283A58)); p.rect(-7, -14, 6, 6, C(0x5A86B8)); p.rect(1, -14, 6, 6, C(0x5A86B8))
        p.rect(-8, -16, 16, 1, C(0xE8C860))
        for side in [-1, 1] { for k in 0..<2 { p.rect(side * (24 + k * 8) - 2, -16, 4, 10, glass) } }
        for k in 0..<8 {
            let u = -37 + k * 10 + (k > 3 ? 1 : 0)
            p.rect(u, -21, 3, 21, marble); p.rect(u + 2, -21, 1, 21, shade); p.rect(u - 1, -22, 5, 1, C(0xFFFFFF))
            p.rect(u - 1, -1, 5, 1, shade)
        }
        // drum and dome
        p.rect(-27, -37, 54, 5, C(0xE8ECF0)); p.rect(-28, -38, 56, 1, C(0xFFFFFF))
        for u in stride(from: -24, to: 24, by: 6) { p.rect(u, -36, 2, 3, glass) }
        let dcx = f.cx, dcy = f.base - 38 * b, rx = 30 * b, ry = 15 * b
        for dy in 0...ry {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int((Double(rx) * k.squareRoot()).rounded())
            let y = dcy - dy
            c.rect(dcx - half, y, half * 2 + 1, 1, marble)
            c.rect(dcx + half / 3, y, half - half / 3 + 1, 1, C(0xDCE2EA))
            c.rect(dcx + half * 3 / 4, y, half / 4 + 1, 1, shade)
            for fr in [-0.7, -0.35, 0.0, 0.35, 0.7] { c.px(dcx + Int(fr * Double(half)), y, C(0xC2CCD8)) }
            if dy == ry / 3 || dy == ry * 2 / 3 { c.rect(dcx - half, y, half * 2 + 1, 1, C(0xD4DCE6)) }
        }
        p.rect(-3, -56, 6, 3, marble); p.rect(-2, -55, 4, 1, glass); p.roof(0, -58, half: 4, h: 2, C(0xE8ECF0))
        if isTall(c) { c.rect(dcx, f.base - 64 * b, max(1, b / 2 + 1), 6 * b, C(0x9AA4B4)) }
    }

    /// Round trees and clipped hedges either side of the hall.
    static func hallTrees(_ c: PixelCanvas, _ g: Int) {
        let f = hallFrame(c, g), b = f.b
        let p = S2Pen(c: c, x: f.cx, y: f.base, s: b)
        for side in [-1, 1] {
            var u = 122, k = 0
            while f.cx + side * (u - 12) * b > -20 * b && f.cx + side * (u - 12) * b < c.w + 20 * b {
                let hgt = 18 + Int(noise(k * 5 + side + 90) * 10.0)
                p.rect(side * u - 1, -hgt / 2, 2, hgt / 2, C(0x6A4A30))
                p.ellipse(side * u, -hgt / 2 - 6, 9, 8, C(0x2E6A34))
                p.ellipse(side * u - 2, -hgt / 2 - 8, 6, 5, C(0x4A8A42))
                p.ellipse(side * u - 3, -hgt / 2 - 9, 3, 2, C(0x6AA85A))
                u += 20; k += 1
            }
        }
        for side in [-1, 1] {                                      // hedges along the wing fronts
            p.rect(side < 0 ? -110 : 46, -3, 64, 3, C(0x3A7A3A)); p.rect(side < 0 ? -110 : 46, -3, 64, 1, C(0x5A9A4A))
        }
    }

    /// A flag rippling in the breeze, its hoist at (x, y): stripes and a blue canton with a white star.
    static func hallFlag(_ c: PixelCanvas, x: Int, y: Int, b: Int, t: Double, seed: Double, w: Int = 10, h: Int = 6) {
        let fw = w * b, fh = h * b
        for i in 0..<fw {
            let along = Double(i) / Double(fw)
            let ph = t * 5 + Double(i) / Double(b) * 0.7 + seed
            let dy = Int((sin(ph) * Double(b) * along * 1.3).rounded())
            let dim = cos(ph) > 0.3 ? 0.0 : 0.18
            for j in 0..<fh {
                let canton = i < fw * 2 / 5 && j < fh / 2 + b / 2
                let stripe = (j * 7 / fh) % 2 == 0
                var col = canton ? C(0x2A3A8A) : (stripe ? C(0xC8282E) : C(0xF4F4F4))
                if canton, i == fw / 5, j == fh / 4 { col = C(0xFFFFFF) }
                c.px(x + i, y + j + dy, lerp(col, C(0x202030), dim))
            }
        }
    }

    /// Flags rippling on the plaza and over the dome, clouds drifting high up on the screen saver, and now and then
    /// the Invisible Jet slipping across the sky, just a glint of an outline.
    static func hallLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = hallFrame(c, g), b = f.b, s = unit(g)
        let poles = hallPoles(c, g)
        for (i, x) in poles.xs.enumerated() { hallFlag(c, x: x + max(1, b), y: poles.top, b: b, t: t, seed: Double(i) * 1.7) }
        if isTall(c) { hallFlag(c, x: f.cx + max(1, b / 2 + 1), y: f.base - 64 * b, b: b, t: t, seed: 0.4, w: 6, h: 4) }
        if isTall(c) {
            for i in 0..<3 {
                let span = Double(c.w + 120 * s)
                let x = Int((noise(i * 5 + 11) * span + t * Double(3 + i) * Double(s)).truncatingRemainder(dividingBy: span)) - 60 * s
                cloud(c, x, g / 10 + Int(noise(i * 5 + 12) * Double(g / 6)), (4 + i) * s, seed: i + 50)
            }
        }
        // the Invisible Jet
        let speed = 30.0 * Double(b), travel = Double(c.w + 50 * b), dur = travel / speed, cycle = dur + 11
        let ph = (t + 6).truncatingRemainder(dividingBy: cycle)
        guard ph < dur else { return }
        let jx = Int(-25.0 * Double(b) + ph * speed), jy = isTall(c) ? g / 5 : 2
        scenes2Stamp(c, jx, jy, [
            ".o..............",
            ".oo.............",
            ".oiooooooooooo..",
            "ooiiiiiiiiiiiioo",
            ".ooooiiioooooo..",
            ".....oiio.......",
            "......oo........",
        ], ["o": C(0xFFFFFF, 0.55), "i": C(0xFFFFFF, 0.1)], s: b)
        if scenes2Phase(t, 1.1) < 0.2 { c.rect(jx + 13 * b, jy + 3 * b, b, b, C(0xFFFFFF, 0.9)) }
    }
}

// MARK: - Arkham Asylum

extension Scenes {
    /// The asylum's centre, the hilltop row it stands on, and the size of one unit of it.
    static func arkhamFrame(_ c: PixelCanvas, _ g: Int) -> (ax: Int, top: Int, b: Int) {
        let b = scenes2Big(c, g)
        return (Int(Double(c.w) * 0.56), g - (isTall(c) ? 20 : 12) * b, b)
    }

    /// Every window of the asylum, as unit offsets from its centre on the hilltop, and whether it's lit.
    static func arkhamWindows() -> [(u: Int, v: Int, lit: Bool)] {
        var out: [(u: Int, v: Int, lit: Bool)] = []
        var i = 0
        for v in [-19, -12] { for u in stride(from: -22, to: 22, by: 6) { out.append((u, v, noise(i * 7 + 300) > 0.4)); i += 1 } }
        for side in [-1, 1] {
            for u in stride(from: 30, to: 66, by: 6) { out.append((side * u - 1, -10, noise(i * 7 + 300) > 0.45)); i += 1 }
        }
        out.append((-1, -31, true))
        return out
    }

    /// Where the two searchlights sit, on the turret tops.
    static func arkhamLamps(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let f = arkhamFrame(c, g)
        return [(f.ax - 72 * f.b, f.top - 35 * f.b), (f.ax + 72 * f.b, f.top - 35 * f.b)]
    }

    /// Arkham Asylum on a stormy night: the gothic pile black against a bruised purple sky, its clock tower and
    /// steep spires, turrets at either end, rows of barred windows burning a sickly yellow. It sits on its bare hill
    /// among dead trees, a full moon caught in torn cloud behind it, with the iron gate and its ARKHAM arch and the
    /// spiked fence down in front.
    static func arkham(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = arkhamFrame(c, g), b = f.b
        c.gradient(0, g, C(0x07060E), C(0x2E2442), bands: 7)
        c.stars(0, f.top / 2, density: 110, seed: 33)
        let mx = Int(Double(c.w) * 0.22), my = tall ? g / 4 : 14, mr = 9 * b
        c.circle(mx, my, mr + 6 * b, C(0xC8C8E8, 0.06)); c.circle(mx, my, mr + 3 * b, C(0xC8C8E8, 0.1))
        c.circle(mx, my, mr, C(0xE2E0EA)); c.circle(mx + 3 * b, my - 2 * b, 2 * b, C(0xC4C2D2)); c.circle(mx - 3 * b, my + 3 * b, 3 * b, C(0xCAC8D8))
        // torn cloud across the moon and the sky
        let nClouds = tall ? 9 : 4
        for i in 0..<nClouds {
            let x = i == 0 ? mx : Int(noise(i * 5 + 410) * Double(c.w))
            let y = i == 0 ? my + 3 * b : Int(noise(i * 5 + 411) * Double(f.top - 40 * b))
            wisp(c, x, max(2, y), (30 + Int(noise(i * 5 + 412) * 50)) * b, C(0x3A2E52, 0.85), s: b)
            wisp(c, x + 6 * b, max(2, y) + 2 * b, (20 + Int(noise(i * 5 + 413) * 30)) * b, C(0x1E1830, 0.8), s: b)
        }
        // the hill
        for x in 0..<c.w {
            let d = Double(x - f.ax) / Double(c.w / 2)
            let y = f.top + Int(d * d * Double(10 * b)) + Int(noise(x / 3 + 700) * Double(b))
            c.rect(x, y, 1, g - y, C(0x15121C)); c.px(x, y, C(0x2C2438))
        }
        arkhamTrees(c, g)
        arkhamBuilding(c, g)
        for p in arkhamLamps(c, g) { c.rect(p.x - b, p.y - b, 3 * b, 2 * b, C(0xE8E4C0)) }
        arkhamGate(c, g)
        // the fence along the front
        let fy = g - 9 * b
        c.rect(0, fy + 2 * b, c.w, b, C(0x0C0B12)); c.rect(0, g - 3 * b, c.w, b, C(0x0C0B12))
        for x in stride(from: 0, to: c.w, by: 4 * b) where abs(x - Int(Double(c.w) * 0.16)) > 14 * b {
            c.rect(x, fy, max(1, b), g - fy, C(0x0C0B12)); c.px(x, fy - 1, C(0x3A3446))
        }
        c.ground(g, C(0x17151E), edge: C(0x3E3850), speck: C(0x100E16), seed: 71)
        _ = s
    }

    /// The asylum building: wings, the main block and its gable, the clock tower and the turrets.
    static func arkhamBuilding(_ c: PixelCanvas, _ g: Int) {
        let f = arkhamFrame(c, g)
        let p = S2Pen(c: c, x: f.ax, y: f.top, s: f.b)
        let stone = C(0x26222E), dark = C(0x17141E), roofC = C(0x1C1826), edge = C(0x4A4258), rimC = C(0x5A5070)
        // a slate roof with its edges catching the moonlight
        let roof = { (u: Int, v: Int, half: Int, h: Int) in
            c.oy = -1; p.roof(u, v, half: half, h: h, rimC); c.oy = 0; p.roof(u, v, half: half, h: h, roofC)
        }
        // wings with their long roofs and chimneys
        for side in [-1, 1] {
            let u0 = side < 0 ? -70 : 26
            p.rect(u0, -14, 44, 14, stone)
            c.oy = -1; p.trap(u0 - 1, -20, 46, 6, inset: 5, rimC); c.oy = 0; p.trap(u0 - 1, -20, 46, 6, inset: 5, roofC)
            p.rect(u0 + 8, -24, 3, 5, dark); p.rect(u0 + 30, -23, 3, 4, dark)
            p.rect(u0, -14, 44, 1, edge)
        }
        // turrets at both ends with their witch's-hat roofs
        for side in [-1, 1] {
            let u = side * 72
            p.rect(u - 4, -28, 8, 28, stone); p.rect(u - 4, -28, 1, 28, edge)
            roof(u, -36, 6, 9)
            p.rect(u - 1, -24, 2, 3, C(0xC8C070, 0.7)); p.rect(u - 1, -17, 2, 3, C(0xC8C070, 0.5))
        }
        // the main block and its gable
        p.rect(-26, -24, 52, 24, stone); p.rect(-26, -24, 52, 1, edge)
        roof(0, -36, 30, 13)
        roof(-16, -30, 7, 7); roof(16, -30, 7, 7)
        // the clock tower
        p.rect(-6, -42, 12, 20, C(0x2C2836)); p.rect(-6, -42, 1, 20, edge)
        roof(0, -51, 8, 9); p.rect(0, -54, 1, 3, C(0x5A5070))
        p.circle(0, -37, 3, C(0xC8C8A8, 0.85)); p.rect(0, -39, 1, 2, dark); p.rect(0, -37, 2, 1, dark)
        // the doorway
        p.rect(-4, -7, 8, 7, dark); p.ellipse(0, -7, 4, 2, dark); p.rect(-1, -6, 2, 6, C(0x8A7A3A, 0.6))
        for w in arkhamWindows() {
            p.rect(w.u, w.v, 3, 4, w.lit ? C(0xCACA78) : C(0x0E0C14))
            p.rect(w.u, w.v - 1, 3, 1, dark)
            c.rect(f.ax + w.u * f.b + f.b, f.top + w.v * f.b, max(1, f.b / 2), 4 * f.b, C(0x1A1620))     // the bars
            if w.lit { c.rect(f.ax + (w.u - 1) * f.b, f.top + (w.v + 4) * f.b, 5 * f.b, f.b, C(0xCACA78, 0.12)) }
        }
    }

    /// Dead trees clawing at the sky on the hill.
    static func arkhamTrees(_ c: PixelCanvas, _ g: Int) {
        let f = arkhamFrame(c, g), b = f.b
        let col = C(0x0E0C14)
        for (i, fx) in [0.06, 0.3, 0.84, 0.95].enumerated() {
            let x = Int(Double(c.w) * fx), h = (16 + Int(noise(i + 800) * 10)) * b
            let d = Double(x - f.ax) / Double(c.w / 2)
            let base = f.top + Int(d * d * Double(10 * b)) + 2 * b
            c.rect(x, base - h, 2 * b, h, col)
            for k in 0..<4 {
                let dir = k % 2 == 0 ? -1 : 1, by = base - h + (k + 1) * h / 6
                let len = (5 + Int(noise(i * 9 + k + 810) * 6)) * b
                for j in 0..<len { c.rect(x + b + dir * j, by - j / 2, b, b, col) }
                c.rect(x + b + dir * len, by - len / 2 - 2 * b, b, 2 * b, col)
            }
        }
    }

    /// The iron gate with ARKHAM lettered over it, off to the left of the crew.
    static func arkhamGate(_ c: PixelCanvas, _ g: Int) {
        let b = scenes2Big(c, g), gx = Int(Double(c.w) * 0.16)
        let p = S2Pen(c: c, x: gx, y: g, s: b)
        for side in [-1, 1] {
            p.rect(side * 15 - 3, -20, 6, 20, C(0x2A2632)); p.rect(side * 15 - 4, -21, 8, 2, C(0x3E3848))
            p.rect(side * 15 - 1, -23, 2, 2, C(0x3E3848))
        }
        for u in stride(from: -11, to: 12, by: 3) { p.rect(u, -14, 1, 14, C(0x0C0B12)) }
        p.rect(-12, -13, 24, 1, C(0x0C0B12)); p.rect(-12, -6, 24, 1, C(0x0C0B12))
        // the arch with the name
        for k in 0..<25 {
            let dx = Double(k - 12) / 12, rise = Int((1 - dx * dx) * 5)
            p.rect(k - 12, -21 - rise, 1, 1, C(0x0C0B12))
            p.rect(k - 12, -14 - rise / 2, 1, 1, C(0x0C0B12))
        }
        scenes2Text(c, cx: gx, y: g - 23 * b, "ARKHAM", C(0x7A7488), s: b)
    }

    /// Searchlights sweeping the sky, a few windows flickering, and now and then a fork of lightning with the sky
    /// flashing white.
    static func arkhamLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = arkhamFrame(c, g), b = f.b
        for (i, lamp) in arkhamLamps(c, g).enumerated() {
            let a = sin(t * 0.45 + Double(i) * 2.2) * 0.75 + (i == 0 ? -0.15 : 0.15)
            let spread = 0.07, lo = tan(a - spread), hi = tan(a + spread)
            let length = Double(lamp.y)
            for y in stride(from: lamp.y - b, through: 0, by: -1) {
                let d = Double(lamp.y - y)
                let fade = ((1 - d / length) * 4).rounded(.up) / 4
                let xa = lamp.x + Int(d * lo), xb = lamp.x + Int(d * hi)
                c.rect(xa, y, max(1, xb - xa), 1, C(0xF0ECC8, 0.08 + (isTall(c) ? 0.09 : 0.14) * fade))
            }
            c.circle(lamp.x, lamp.y - b, 3 * b, C(0xFFF8D0, 0.35))
        }
        // windows flickering
        let wins = arkhamWindows()
        for i in 0..<4 {
            let w = wins[Int(noise(i * 31 + Int(t / 3)) * Double(wins.count)) % wins.count]
            if noise(Int(t * 7) + i * 13) > 0.5 {
                c.rect(f.ax + w.u * f.b, f.top + w.v * f.b, 3 * f.b, 4 * f.b, w.lit ? C(0x0E0C14, 0.9) : C(0xCACA78, 0.8))
                c.rect(f.ax + w.u * f.b + f.b, f.top + w.v * f.b, max(1, f.b / 2), 4 * f.b, C(0x1A1620))
            }
        }
        // lightning
        let cycle = 7.0, n = Int(floor(t / cycle)), ph = scenes2Phase(t, cycle)
        let on = ph < 0.03 || (ph > 0.05 && ph < 0.09)
        guard on else { return }
        c.rect(0, 0, c.w, g, C(0xD8D0FF, 0.1))
        let x0 = Double(c.w) * (0.05 + noise(n * 3 + 900) * 0.9)
        let x1 = x0 + (noise(n * 3 + 901) - 0.5) * Double(c.w) * 0.2
        let y1 = Double(f.top - 30 * b) * (0.5 + noise(n * 3 + 902) * 0.5)
        scenes2Bolt(c, x0, 0, x1, max(4, y1), kinks: 7, seed: n, jitter: 6 * Double(b), core: C(0xFFFFFF), glow: C(0xB8A8FF), s: Double(b))
    }
}

// MARK: - Central City

extension Scenes {
    /// Where S.T.A.R. Labs stands and the size of one unit of it.
    static func centralLabs(_ c: PixelCanvas, _ g: Int) -> (x: Int, b: Int) {
        (Int(Double(c.w) * 0.74), isTall(c) ? scenes2Big(c, g) + 1 : 1)
    }

    /// The near skyline (the one with windows going on and off).
    static func centralNear(_ c: PixelCanvas, _ g: Int) -> [S2Block] {
        let l = centralLabs(c, g), b = scenes2Big(c, g)
        return scenes2Blocks(c.w, base: g, lo: Int(Double(g) * 0.16), hi: Int(Double(g) * 0.42), minW: 8 * b, maxW: 20 * b,
                             gap: 7 * b, seed: 23)
            .filter { $0.x + $0.w < l.x - 30 * l.b || $0.x > l.x + 30 * l.b }
    }

    /// Central City at sunset: a sky going from violet to rose to gold, the sun low and huge behind the towers,
    /// streaks of lit cloud, a hazy far skyline and a darker near one with warm windows, and S.T.A.R. Labs standing
    /// out on the right with its great observatory dome catching the light. On the screen saver the evening's first
    /// stars come out up high.
    static func centralCity(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), b = scenes2Big(c, g)
        c.gradient(0, g / 2, C(0x2A1E50), C(0xA8466A), bands: 6)
        c.gradient(g / 2, g, C(0xC8565A), C(0xFFBE6A), bands: 6)
        if tall { c.stars(0, g / 4, density: 140, seed: 24) }
        let sx = Int(Double(c.w) * 0.3), sy = g - Int(Double(g) * (tall ? 0.6 : 0.36)), sr = (tall ? 16 : 11) * s
        c.circle(sx, sy, sr * 2, C(0xFFD890, 0.1)); c.circle(sx, sy, sr * 3 / 2, C(0xFFD890, 0.14))
        c.circle(sx, sy, sr, C(0xFFE8B0))
        for k in 0..<3 { c.rect(sx - sr, sy + sr / 3 + k * 3 * b, sr * 2 + 1, b, C(0xF08A5A, 0.5)) }
        for i in 0..<(tall ? 8 : 4) {
            let y = Int(Double(g) * (tall ? 0.15 + noise(i * 5 + 600) * 0.4 : 0.1 + noise(i * 5 + 600) * 0.25))
            wisp(c, Int(noise(i * 5 + 601) * Double(c.w)), y, (30 + Int(noise(i * 5 + 602) * 50)) * s, C(0xF0A07A, 0.45), s: s)
        }
        for blk in scenes2Blocks(c.w, base: g, lo: Int(Double(g) * 0.25), hi: Int(Double(g) * (tall ? 0.45 : 0.55)), minW: 6 * b, maxW: 14 * b,
                                 gap: 0, seed: 19) {
            scenes2Building(c, blk, C(0x9A4A62), roof: C(0xC8707A), window: C(0xFFC890), chance: 0.18, step: 2 * b, seed: 3)
        }
        for k in 0..<3 { c.rect(0, g - (8 + k * 8) * b, c.w, 8 * b, C(0xF08A6A, 0.08)) }
        centralLabsDraw(c, g)
        for blk in centralNear(c, g) {
            scenes2Building(c, blk, C(0x3A1E2C), roof: C(0x8A4A50), window: C(0xFFD27A), chance: 0.35, step: 2 * b, seed: 5)
            if blk.h > Int(Double(g) * 0.38) { c.rect(blk.x + blk.w / 2, blk.y - 5 * b, max(1, b / 2 + 1), 5 * b, C(0x3A1E2C)) }
        }
        // the street
        c.ground(g, C(0x2E2228), edge: C(0x9A6A5A), speck: C(0x261C22), seed: 81)
        for x in stride(from: 0, to: c.w, by: 14 * s) { c.rect(x, g + (c.h - g) / 2, 6 * s, s, C(0xC8A050, 0.6)) }
    }

    /// S.T.A.R. Labs: the low wide block, its lettered band and the big panelled dome with its ring.
    static func centralLabsDraw(_ c: PixelCanvas, _ g: Int) {
        let l = centralLabs(c, g), b = l.b
        let p = S2Pen(c: c, x: l.x, y: g, s: b)
        let wall = C(0x4A3A50), glass = C(0x2A2A44)
        p.rect(-30, -24, 60, 24, wall); p.rect(-31, -25, 62, 1, C(0xB89AA8))
        for v in stride(from: -20, to: -2, by: 4) { p.rect(-28, v, 56, 2, glass); p.rect(-28, v, 56, 1, C(0xFFC890, 0.25)) }
        p.rect(-22, -24, 44, 6, C(0x5A4A60)); p.rect(-22, -24, 44, 1, C(0xC8A8B8))
        scenes2Text(c, cx: l.x, y: g - 23 * b, "S.T.A.R. LABS", C(0xF4ECF0), s: b)
        // the dome
        let dcx = l.x, dcy = g - 25 * b, rx = 19 * b, ry = 15 * b
        for dy in 0...ry {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int((Double(rx) * k.squareRoot()).rounded()), y = dcy - dy
            c.rect(dcx - half, y, half * 2 + 1, 1, C(0xC8C0D2))
            c.rect(dcx - half, y, max(1, half * 2 / 3), 1, C(0xF0D2B8))
            c.rect(dcx + half / 2, y, half - half / 2 + 1, 1, C(0x9A8AAC))
            for fr in [-0.66, -0.33, 0.0, 0.33, 0.66] { c.px(dcx + Int(fr * Double(half)), y, C(0x7A6A8A)) }
            if dy % (4 * b) == 0 { c.rect(dcx - half, y, half * 2 + 1, 1, C(0x8A7A9A)) }
        }
        p.rect(-3, -41, 6, 2, C(0x5A4A60)); c.rect(dcx, g - 45 * b, max(1, b / 2 + 1), 4 * b, C(0x8A7A9A))
        p.ellipse(0, -25, 24, 2, C(0x6A5A78)); p.ellipse(0, -26, 24, 1, C(0xC8A8C8))     // the accelerator ring
        p.rect(-18, -26, 36, 1, C(0x6A5A78))
    }

    /// Windows going on and off, the beacon on the dome, and now and then the Flash racing through town: a red
    /// blur with yellow lightning crackling off its trail.
    static func centralLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let l = centralLabs(c, g), b = scenes2Big(c, g)
        let near = centralNear(c, g).filter { $0.h > 8 * b }
        if !near.isEmpty {
            for i in 0..<max(8, c.w / 30) {
                let blk = near[Int(noise(i * 13 + 5) * Double(near.count)) % near.count]
                let wx = blk.x + 1 + Int(noise(i * 13 + 6) * Double(max(1, blk.w - 3)))
                let wy = blk.y + 3 * b + Int(noise(i * 13 + 7) * Double(max(1, blk.h - 6 * b)))
                if noise(Int(t * 0.5 + noise(i) * 7) * 31 + i) > 0.5 { c.rect(wx, wy, b, 1, C(0xFFE0A0, 0.85)) }
            }
        }
        if scenes2Phase(t, 1.8) < 0.2 { c.rect(l.x - l.b, g - 46 * l.b, 2 * l.b + 1, l.b, C(0xFF5A4A)); c.circle(l.x, g - 46 * l.b, 2 * l.b, C(0xFF5A4A, 0.3)) }
        // the Flash
        let cycle = 6.5, n = Int(floor(t / cycle)), ph = (t - Double(n) * cycle)
        let dur = 0.9, trail = 90.0 * Double(b)
        guard ph < dur else { return }
        let dir: Double = n % 2 == 0 ? 1 : -1
        let span = Double(c.w) + trail * 2
        let head = dir > 0 ? -trail + ph / dur * span : Double(c.w) + trail - ph / dur * span
        let y = Double(g - 7 * b)
        let tail = head - dir * trail
        c.glowLine(tail, y, head, y, core: C(0xE83A2A), glow: C(0xFF8A3A), coreR: 1.0 * Double(b), glowR: 2.6 * Double(b), strength: 0.75)
        c.glowLine(head - dir * trail * 0.3, y, head, y, core: C(0xFFF0B0), glow: C(0xFFD040), coreR: 0.8 * Double(b), glowR: 2.0 * Double(b))
        let frame = Int(t * 24)
        for k in 0..<3 {
            let f0 = noise(frame * 5 + k) * 0.8
            let x0 = head - dir * trail * f0, x1 = x0 - dir * trail * 0.25
            let up = (noise(frame * 5 + k + 50) - 0.5) * 12 * Double(b)
            scenes2Bolt(c, x0, y + up * 0.3, x1, y + up, kinks: 4, seed: frame * 3 + k, jitter: 3 * Double(b),
                        core: C(0xFFF6C0), glow: C(0xFFC83A), s: Double(b) * 0.7)
        }
        c.circle(Int(head), Int(y), 3 * b, C(0xFFFFE0, 0.6))
    }
}

// MARK: - Star City

extension Scenes {
    /// The far shore's waterline, where the promenade starts, and the size of one unit of the city.
    static func starFrame(_ c: PixelCanvas, _ g: Int) -> (shore: Int, prom: Int, b: Int) {
        let b = scenes2Big(c, g)
        return (g - (isTall(c) ? 30 : 18) * b, g - 4 * b, b)
    }

    /// How many units tall Queen Tower is, below its crown.
    static func starTower(_ c: PixelCanvas) -> Int { isTall(c) ? 40 : 34 }

    /// The skyline across the bay.
    static func starNear(_ c: PixelCanvas, _ g: Int) -> [S2Block] {
        let f = starFrame(c, g), b = f.b, qx = Int(Double(c.w) * 0.62)
        return scenes2Blocks(c.w, base: f.shore, lo: 8 * b, hi: 26 * b, minW: 6 * b, maxW: 14 * b, gap: 3 * b, seed: 29)
            .filter { ($0.x + $0.w < qx - 6 * b || $0.x > qx + 6 * b) && $0.x > Int(Double(c.w) * 0.27) }
    }

    /// Star City at dusk: the skyline across the bay against a sky fading from indigo to a last orange glow, Queen
    /// Tower rising tallest with its green crown, a suspension bridge strung across on the left, lights doubled in
    /// the dark water, and the waterfront promenade with its railing and lamps where the crew stands. On the screen
    /// saver a crescent moon and the first stars hang above.
    static func starCity(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = starFrame(c, g), b = f.b, s = unit(g)
        c.gradient(0, f.shore, C(0x141640), C(0x5A3A6E), bands: 6)
        c.gradient(f.shore * 2 / 3, f.shore, C(0x8A4A6A), C(0xE88A5A), bands: 4)
        c.stars(0, f.shore / 2, density: tall ? 70 : 120, seed: 27)
        if tall {
            let mx = Int(Double(c.w) * 0.16), my = g / 6
            c.circle(mx, my, 9 * s, C(0xF0ECD8)); c.circle(mx + 4 * s, my - 2 * s, 8 * s, C(0x161842))
            for i in 0..<5 { wisp(c, Int(noise(i * 3 + 950) * Double(c.w)), g / 3 + Int(noise(i * 3 + 951) * Double(g / 4)), 60 * s, C(0xC87A8A, 0.35), s: s) }
        }
        // far haze towers
        for blk in scenes2Blocks(c.w, base: f.shore, lo: 6 * b, hi: 18 * b, minW: 5 * b, maxW: 12 * b, gap: 0, seed: 31) {
            scenes2Building(c, blk, C(0x6A4A72), roof: C(0x9A6A8A), window: nil, chance: 0, step: 2, seed: 0)
        }
        starBridge(c, g)
        // Queen Tower
        let qx = Int(Double(c.w) * 0.62)
        let q = S2Pen(c: c, x: qx, y: f.shore, s: b), qh = starTower(c)
        q.rect(-5, -qh, 10, qh, C(0x1E1A30)); q.rect(-5, -qh, 2, qh, C(0x3A3456)); q.trap(-5, -qh - 6, 10, 6, inset: 3, C(0x1E1A30))
        q.rect(-2, -qh - 6, 4, 1, C(0x5AE08A)); q.rect(-3, -qh - 4, 6, 1, C(0x5AE08A, 0.7)); q.rect(0, -qh - 11, 1, 5, C(0x3A3456))
        for v in stride(from: -qh + 2, to: -1, by: 3) { for u in [-3, -1, 1, 3] where noise(u * 7 + v * 13 + 999) > 0.45 { q.rect(u, v, 1, 1, C(0xFFE0A0, 0.8)) } }
        q.circle(0, -qh - 5, 6, C(0x5AE08A, 0.1))
        for blk in starNear(c, g) {
            scenes2Building(c, blk, C(0x221C34), roof: C(0x5A4A70), window: C(0xFFD890), chance: 0.4, step: 2 * b, seed: 9)
        }
        // the bay, with the city's reflection
        c.gradient(f.shore, f.prom, C(0x3A2A52), C(0x121430), bands: 4)
        c.rect(0, f.shore, c.w, b, C(0xE8906A, 0.35))
        for blk in starNear(c, g) + [S2Block(x: qx - 5 * b, y: f.shore - qh * b, w: 10 * b, h: qh * b)] {
            let depth = min(f.prom - f.shore - b, blk.h / 2)
            for y in stride(from: f.shore + b, to: f.shore + depth, by: 2) {
                let wob = Int(noise(y * 7 + blk.x) * 3) - 1
                c.rect(blk.x + wob, y, blk.w, 1, C(0x0E0C20, 0.45))
                if noise(y * 3 + blk.x * 5) > 0.6 { c.rect(blk.x + wob + Int(noise(y + blk.x) * Double(blk.w)), y, 2 * b, 1, C(0xFFC880, 0.45)) }
            }
        }
        c.rect(qx - 2 * b, f.shore + 2 * b, 4 * b, b, C(0x5AE08A, 0.35))
        // the promenade railing and its lamps
        c.rect(0, f.prom - 5 * b, c.w, b, C(0x2A2636)); c.rect(0, f.prom - 2 * b, c.w, b, C(0x2A2636))
        for x in stride(from: 0, to: c.w, by: 5 * b) { c.rect(x, f.prom - 5 * b, max(1, b), 5 * b, C(0x2A2636)) }
        for x in stride(from: 20 * s, to: c.w, by: 70 * s) {
            c.rect(x, f.prom - 16 * b, max(1, b), 16 * b, C(0x2A2636))
            c.rect(x - b, f.prom - 17 * b, 3 * b, 2 * b, C(0xFFE0A0)); c.circle(x, f.prom - 16 * b, 3 * b, C(0xFFD890, 0.1))
        }
        c.rect(0, f.prom, c.w, g - f.prom, C(0x3A2E30)); c.rect(0, f.prom, c.w, b, C(0x8A6A58))
        c.ground(g, C(0x3E302C), edge: C(0x9A7A62), speck: C(0x2E2420), seed: 91)
        for x in stride(from: 0, to: c.w, by: 9 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x2E2420)) }
    }

    /// The suspension bridge on the left: two towers, the sagging cables, the deck and its lights.
    static func starBridge(_ c: PixelCanvas, _ g: Int) {
        let f = starFrame(c, g), b = f.b
        let deck = f.shore - 6 * b, col = C(0x2A2238)
        let t1 = Int(Double(c.w) * 0.05), t2 = Int(Double(c.w) * 0.22), top = f.shore - 30 * b
        c.rect(0, deck, Int(Double(c.w) * 0.3), 2 * b, col)
        for tx in [t1, t2] {
            c.rect(tx - b, top, 3 * b, f.shore - top, col); c.rect(tx - 2 * b, top + 6 * b, 5 * b, b, col)
            c.rect(tx, top - b, b, b, C(0xFF5A5A))
        }
        for x in 0..<Int(Double(c.w) * 0.3) {
            let span = Double(t2 - t1), u = (Double(x - t1) / span) * 2 - 1
            let sag: Double
            if x < t1 { sag = Double(top) + Double(t1 - x) / Double(max(1, t1)) * Double(deck - top) }
            else if x > t2 { sag = Double(top) + Double(x - t2) / Double(c.w) * 6 * Double(deck - top) }
            else { sag = Double(deck - 2 * b) - (1 - u * u) * 0 - Double(deck - 2 * b - top) * (u * u) }
            c.px(x, Int(min(Double(deck), sag)), C(0x8A7AA8))
            if x % (4 * b) == 0 { c.rect(x, Int(min(Double(deck), sag)), 1, max(0, deck - Int(sag)), C(0x5A4A78, 0.6)) }
            if x % (6 * b) == 0 { c.px(x, deck - 1, C(0xFFE0A0)) }
        }
    }

    /// Glints on the water, a boat's lights drifting across the bay, Queen Tower's crown pulsing, and now and then
    /// a green-fletched arrow zipping across the sky.
    static func starCityLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = starFrame(c, g), b = f.b
        let frame = Int(t * 3)
        for i in 0..<max(10, c.w / 16) {
            let x = Int(noise(i * 5 + frame * 101) * Double(c.w))
            let y = f.shore + 2 * b + Int(noise(i * 5 + 1 + frame * 101) * Double(max(1, f.prom - f.shore - 4 * b)))
            c.rect(x, y, (2 + Int(noise(i * 3 + 7) * 3)) * b, 1, C(0xF0B890, 0.5))
        }
        // a boat
        let bx = Int((Double(c.w + 40) * scenes2Phase(t, 70))) - 20, by = f.shore + (f.prom - f.shore) / 2
        c.rect(bx, by, 8 * b, 2 * b, C(0x1A1626)); c.rect(bx + 2 * b, by - 2 * b, 3 * b, 2 * b, C(0x1A1626))
        c.rect(bx + 3 * b, by - b, b, b, C(0xFFE0A0)); c.rect(bx + 7 * b, by, b, b, C(0x5AFF7A))
        c.rect(bx - 6 * b, by + 2 * b, 6 * b, 1, C(0xC8C8E0, 0.3))
        let qx = Int(Double(c.w) * 0.62)
        c.circle(qx, f.shore - (starTower(c) + 5) * b, 4 * b, C(0x5AE08A, 0.1 + 0.12 * (0.5 + 0.5 * sin(t * 2))))
        // the arrow
        let cycle = 5.5, n = Int(floor(t / cycle)), ph = t - Double(n) * cycle
        let dur = 0.7
        guard ph < dur else { return }
        let dir: Double = n % 2 == 0 ? 1 : -1
        let k = ph / dur, span = Double(c.w + 40 * b)
        let x = dir > 0 ? -20.0 * Double(b) + k * span : Double(c.w) + 20.0 * Double(b) - k * span
        let y0 = Double(f.shore) * (0.25 + noise(n + 960) * 0.35)
        let y = y0 + k * k * 6 * Double(b)
        let ax = Int(x), ay = Int(y), d = Int(dir)
        c.rect(ax - d * 12 * b + (d < 0 ? 0 : 0), ay, 12 * b, max(1, b / 2 + 1), C(0x9A8A6A))
        if d < 0 { c.rect(ax, ay, 12 * b, max(1, b / 2 + 1), C(0x9A8A6A)) }
        let shaftStart = d > 0 ? ax - 12 * b : ax + 12 * b
        c.rect(ax + d * b, ay - b, b, 3 * b, C(0xD8DCE6)); c.rect(ax + d * 2 * b, ay, b, b, C(0xF0F4FA))
        c.rect(shaftStart - d * b, ay - b, 2 * b, b, C(0x3AA85A)); c.rect(shaftStart - d * b, ay + b, 2 * b, b, C(0x3AA85A))
        c.glowLine(Double(shaftStart) - dir * 30 * Double(b), y, Double(shaftStart), y, core: C(0xFFFFFF, 0.25), glow: C(0xFFFFFF, 0.08),
                   coreR: 0.4, glowR: 1.2)
    }
}

// MARK: - Oa

extension Scenes {
    /// Where the Central Power Battery stands, the horizon, and the size of one unit of it.
    static func oaFrame(_ c: PixelCanvas, _ g: Int) -> (bx: Int, hz: Int, b: Int, bb: Int) {
        let b = scenes2Big(c, g)
        return (Int(Double(c.w) * 0.66), g - 8 * b, b, isTall(c) ? b + 1 : b)
    }

    /// Far off behind the city: great tapering towers, dim in the green haze.
    static func oaFarTowers(_ c: PixelCanvas, _ g: Int) {
        let f = oaFrame(c, g), b = f.b
        var x = 4 * b, i = 0
        while x < c.w {
            let h = Int(Double(f.hz) * (0.3 + noise(i * 5 + 1500) * (isTall(c) ? 0.35 : 0.45)))
            let w = (12 + Int(noise(i * 5 + 1501) * 10)) * b
            for r in 0..<h {
                let k = Double(r) / Double(h), hw = max(b, Int(Double(w) * (0.35 + 0.65 * k * k)) / 2)
                c.rect(x - hw, f.hz - h + r, hw * 2, 1, C(0x0F3628))
                c.px(x - hw, f.hz - h + r, C(0x1E5A44))
            }
            c.rect(x, f.hz - h - 6 * b, max(1, b / 2 + 1), 6 * b, C(0x1E5A44))
            for v in stride(from: f.hz - h + 6 * b, to: f.hz - 4 * b, by: 5 * b) where noise(v + i * 31) > 0.4 {
                c.rect(x - b / 2, v, max(1, b), max(1, b), C(0x5AE08A, 0.55))
            }
            x += (28 + Int(noise(i * 5 + 1502) * 30)) * b
            i += 1
        }
    }

    /// Oa, at the centre of the universe: a green-black sky swirling with nebula and a ringed world hanging in it,
    /// the alien spires of the Guardians' city with their glowing green windows, and in the middle the Central Power
    /// Battery, a lantern the size of a tower on its stepped plinth, blazing green through its slats.
    static func oa(_ c: PixelCanvas, _ g: Int) {
        let tall = isTall(c), f = oaFrame(c, g), b = f.b, s = unit(g)
        c.gradient(0, g, C(0x020806), C(0x0E3A2A), bands: 7)
        c.stars(0, g * 3 / 4, density: 45, seed: 37)
        for i in 0..<(tall ? 10 : 5) {                               // nebula streaks
            let y = Int(noise(i * 5 + 1200) * Double(g) * 0.6)
            wisp(c, Int(noise(i * 5 + 1201) * Double(c.w)), y, (40 + Int(noise(i * 5 + 1202) * 70)) * s, C(0x2AA86A, 0.18), s: 2 * s)
        }
        // the ringed world
        let px = Int(Double(c.w) * 0.17), py = tall ? g / 4 : 16, pr = tall ? 28 * s : 10
        c.ellipse(px, py, pr * 2, max(1, pr / 4), C(0x8AB8A0, 0.35))
        c.circle(px, py, pr, C(0x3A6A5A)); c.circle(px - pr / 4, py - pr / 4, pr * 3 / 4, C(0x4A8A6E))
        c.rect(px - pr, py - pr / 3, pr * 2, max(1, pr / 8), C(0x3A6A5A, 0.6))
        c.ellipse(px, py + max(1, pr / 8), pr * 2, max(1, pr / 4), C(0xA8D8C0, 0.25))
        c.rect(px - pr * 2, py, pr - pr / 10, 1, C(0xC8F0D8, 0.5)); c.rect(px + pr + pr / 10, py, pr - pr / 10, 1, C(0xC8F0D8, 0.5))
        // distant crags
        oaFarTowers(c, g)
        c.dunes(base: f.hz - 4 * b, amp: Double(5 * b), freq: 0.03, phase: 2, bottom: f.hz, C(0x0C221A), shade: C(0x2A5A44))
        oaCity(c, g)
        oaBattery(c, g)
        c.rect(0, f.hz, c.w, g - f.hz, C(0x0E1E18)); c.rect(0, f.hz, c.w, b, C(0x3A7A5A))
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x, f.hz + b, s, g - f.hz - b, C(0x0A1812)) }
        c.ground(g, C(0x12201A), edge: C(0x4A9A6A), speck: C(0x0C1812), seed: 101)
        c.rect(0, g + 2 * s, c.w, s, C(0x3AFF7A, 0.3))
    }

    /// The Guardians' city: slender spires, domed towers and mushroom-topped columns, windows burning green.
    static func oaCity(_ c: PixelCanvas, _ g: Int) {
        let f = oaFrame(c, g), b = f.b
        var x = 6 * b, i = 0
        while x < c.w {
            if abs(x - f.bx) < 32 * f.bb { x += 8 * b; continue }
            let kind = Int(noise(i * 7 + 1300) * 3), h = (16 + Int(noise(i * 7 + 1301) * 22)) * b
            let col = C(0x16302A), edge = C(0x4A9A72), lit = C(0x7AFFA0)
            let p = S2Pen(c: c, x: x, y: f.hz, s: b)
            let hu = h / b
            switch kind {
            case 0:                                                    // a needle spire with a bulb
                p.rect(-1, -hu, 3, hu, col); p.rect(-1, -hu, 1, hu, edge)
                p.ellipse(0, -hu - 2, 3, 3, col); p.circle(0, -hu - 2, 1, lit)
                p.rect(0, -hu - 8, 1, 4, edge)
            case 1:                                                    // a domed cylinder
                p.rect(-5, -hu, 10, hu, col); p.rect(-5, -hu, 1, hu, edge)
                p.ellipse(0, -hu, 5, 4, C(0x1E3E34)); p.ellipse(-1, -hu - 1, 2, 1, edge)
                for v in stride(from: -hu + 3, to: -2, by: 4) { p.rect(-3, v, 6, 1, lit.alpha(0.55)) }
            default:                                                   // a column under a wide disc
                p.trap(-4, -hu, 8, hu, inset: 2, col); p.rect(-2, -hu, 1, hu, edge)
                p.ellipse(0, -hu, 9, 2, col); p.rect(-9, -hu, 18, 1, edge); p.ellipse(0, -hu - 2, 4, 2, C(0x1E3E34))
                for k in 0..<3 { p.rect(-6 + k * 5, -hu + 1, 2, 1, lit) }
            }
            x += (14 + Int(noise(i * 7 + 1302) * 16)) * b
            i += 1
        }
    }

    /// The Central Power Battery on its plinth, with a glow around it.
    static func oaBattery(_ c: PixelCanvas, _ g: Int) {
        let f = oaFrame(c, g)
        let p = S2Pen(c: c, x: f.bx, y: f.hz, s: f.bb)
        p.circle(0, -24, 30, C(0x3AFF7A, 0.06)); p.circle(0, -24, 22, C(0x3AFF7A, 0.08))
        let metal = C(0x1E3A2E), hi = C(0x6ACA8A)
        p.rect(-24, -3, 48, 3, metal); p.rect(-24, -3, 48, 1, hi)        // the plinth
        p.rect(-18, -6, 36, 3, metal); p.rect(-18, -6, 36, 1, hi)
        p.trap(-13, -10, 26, 4, inset: 3, metal)                          // the foot
        p.rect(-10, -32, 20, 22, C(0x8AFFA8))                             // the body, glowing through its slats
        p.rect(-8, -30, 16, 18, C(0xD8FFE0))
        for u in stride(from: -10, to: 10, by: 4) { p.rect(u, -32, 1, 22, metal) }
        p.rect(9, -32, 1, 22, metal)
        p.rect(-11, -22, 22, 2, metal); p.rect(-11, -22, 22, 1, hi)       // the band round its middle
        p.trap(-13, -36, 26, 4, inset: 2, metal); p.rect(-11, -36, 22, 1, hi)   // the cap
        p.trap(-9, -39, 18, 3, inset: 3, metal)
        p.rect(-5, -44, 10, 1, metal); p.rect(-5, -44, 1, 5, metal); p.rect(4, -44, 1, 5, metal)   // the handle
        p.rect(-11, -32, 1, 22, hi.alpha(0.6))
    }

    /// The battery pulsing, and Green Lanterns streaking past in the sky, trails of green light behind them.
    static func oaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = oaFrame(c, g), b = f.b
        let pulse = 0.5 + 0.5 * sin(t * 2.2)
        let p = S2Pen(c: c, x: f.bx, y: f.hz, s: f.bb)
        p.circle(0, -21, 16 + Int(pulse * 4), C(0x5AFF8A, 0.05 + 0.05 * pulse))
        p.rect(-8, -30, 16, 18, C(0xFFFFFF, 0.25 * pulse))
        for u in stride(from: -10, to: 10, by: 4) { p.rect(u, -32, 1, 22, C(0x1E3A2E)) }
        p.rect(-11, -22, 22, 2, C(0x1E3A2E)); p.rect(-11, -22, 22, 1, C(0x6ACA8A))
        // Lanterns flying past
        for i in 0..<4 {
            let period = 4.5 + Double(i) * 1.7, ph = scenes2Phase(t, period, offset: Double(i) * 1.3)
            let dur = 0.45
            guard ph < dur else { continue }
            let n = Int(floor((t + Double(i) * 1.3) / period))
            let dir: Double = (n + i) % 2 == 0 ? 1 : -1
            let k = ph / dur, span = Double(c.w) + 120 * Double(b)
            let x = dir > 0 ? -60 * Double(b) + k * span : Double(c.w) + 60 * Double(b) - k * span
            let yTop = Double(f.hz) * 0.08, yRange = Double(f.hz) * 0.5
            let y0 = yTop + noise(n * 7 + i * 3 + 1400) * yRange
            let climb = (noise(n * 7 + i * 3 + 1401) - 0.5) * 30 * Double(b)
            let y = y0 + climb * k
            let len = 50 * Double(b)
            c.glowLine(x - dir * len, y - climb * len / span, x, y, core: C(0xB8FFC8), glow: C(0x2AE85A), coreR: 0.6 * Double(b),
                       glowR: 2.2 * Double(b), strength: 0.8)
            c.circle(Int(x), Int(y), b, C(0xFFFFFF))
            c.circle(Int(x), Int(y), 3 * b, C(0x5AFF8A, 0.35))
        }
    }
}
