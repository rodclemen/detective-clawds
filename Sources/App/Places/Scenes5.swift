import Foundation

let scenes5: [Location: Place] = [
    .phantomZone: Place(name: "The Phantom Zone", panel: 0x14102A, still: Scenes.phantomZone, moving: Scenes.phantomZoneDrift),
    .kahndaq: Place(name: "Kahndaq", panel: 0x2A1C10, still: Scenes.kahndaq, moving: Scenes.kahndaqLife),
    .ironHeights: Place(name: "Iron Heights", panel: 0x16181A, still: Scenes.ironHeights, moving: Scenes.ironHeightsLights),
    .speedForce: Place(name: "The Speed Force", panel: 0x10142E, still: Scenes.speedForce, moving: Scenes.speedForceRush),
    .wayneManor: Place(name: "Wayne Manor", panel: 0x1E140E, still: Scenes.wayneManor, moving: Scenes.wayneManorLife),
    .legionHQ: Place(name: "Legion of Super-Heroes HQ", panel: 0x14182E, still: Scenes.legionHQ, moving: Scenes.legionTraffic),
]

// MARK: - Shared bits for these scenes

/// String art drawn with every character `s` pixels square.
fileprivate func s5Stamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ pal: [Character: Px], s: Int) {
    for (r, row) in rows.enumerated() {
        for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * s, y + r * s, s, s, col) } }
    }
}

/// Where a repeating motion of `period` seconds is, from 0 up to 1.
fileprivate func s5Phase(_ t: Double, _ period: Double, offset: Double = 0) -> Double {
    let v = (t + offset).truncatingRemainder(dividingBy: period) / period
    return v < 0 ? v + 1 : v
}

/// A straight line of `s`-pixel dots.
fileprivate func s5Line(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ col: Px, s: Int = 1) {
    let n = max(abs(x1 - x0), abs(y1 - y0), 1)
    let step = max(1, s / 2)
    for i in stride(from: 0, through: n, by: step) {
        c.rect(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, s, s, col)
    }
}

/// A colour along a ramp of evenly spaced stops, `k` from 0 to 1.
fileprivate func s5Ramp(_ stops: [Px], _ k: Double) -> Px {
    let x = max(0, min(1, k)) * Double(stops.count - 1)
    let i = min(stops.count - 2, Int(x))
    return lerp(stops[i], stops[i + 1], x - Double(i))
}

/// Fills a polygon given in canvas pixels (scanline, even-odd).
fileprivate func s5Poly(_ c: PixelCanvas, _ pts: [(Double, Double)], _ col: Px) {
    guard pts.count >= 3 else { return }
    let ys: [Double] = pts.map { $0.1 }
    let y0 = max(0, Int(floor(ys.min() ?? 0))), y1 = min(c.h - 1, Int(ceil(ys.max() ?? 0)))
    guard y1 >= y0 else { return }
    for y in y0...y1 {
        let sy = Double(y) + 0.5
        var xs: [Double] = []
        for i in 0..<pts.count {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            if (a.1 <= sy && b.1 > sy) || (b.1 <= sy && a.1 > sy) {
                xs.append(a.0 + (sy - a.1) / (b.1 - a.1) * (b.0 - a.0))
            }
        }
        xs.sort()
        var k = 0
        while k + 1 < xs.count {
            let xa = Int(xs[k].rounded()), xb = Int(xs[k + 1].rounded())
            c.rect(xa, y, xb - xa, 1, col)
            k += 2
        }
    }
}

/// The top half of an ellipse standing on row `base`: a dome, lit on its left.
fileprivate func s5Dome(_ c: PixelCanvas, _ cx: Int, _ base: Int, _ rx: Int, _ ry: Int, _ col: Px, lit: Px, shade: Px) {
    guard rx > 0, ry > 0 else { return }
    for dy in 0...ry {
        let k = 1 - Double(dy * dy) / Double(ry * ry)
        let half = Int((Double(rx) * k.squareRoot()).rounded())
        let y = base - dy
        c.rect(cx - half, y, half * 2 + 1, 1, col)
        c.rect(cx - half, y, max(1, half / 2), 1, lit)
        c.rect(cx + half - max(1, half / 3), y, max(1, half / 3), 1, shade)
    }
}

// MARK: - The Phantom Zone

extension Scenes {
    /// The bright tear at the heart of the void, and how flattened its rings are.
    static func phantomCentre(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Double, squash: Double) {
        let tall = isTall(c)
        return (c.w / 2, tall ? g * 2 / 5 : g / 3, Double(c.w) * 0.55, tall ? 0.55 : 0.3)
    }

    /// A point on warped ring `k` of the void, `a` radians round.
    static func phantomRing(_ c: PixelCanvas, _ g: Int, r: Double, a: Double, k: Int) -> (x: Int, y: Int) {
        let o = phantomCentre(c, g)
        let wob: Double = 1 + 0.14 * sin(a * 3 + Double(k) * 1.3) + 0.06 * sin(a * 7 - Double(k))
        return (o.x + Int(cos(a) * r * wob), o.y + Int(sin(a) * r * wob * o.squash))
    }

    /// The Phantom Zone: a silver-violet void with no up or down, warped rings rippling out from a pale tear in it,
    /// cold specks and smears of light, and the crew standing on a sheet of crystal fading off into nothing. On a tall
    /// canvas huge empty prison panes hang far off in the haze.
    static func phantomZone(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), o = phantomCentre(c, g)
        c.gradient(0, g, C(0x2E2858), C(0x0A0918), bands: 8)
        for k in 0..<10 {
            let f = 1 - Double(k) / 10
            c.ellipse(o.x, o.y, Int(o.r * f), max(1, Int(o.r * f * o.squash)), C(0x8A7ACC, 0.06))
        }
        c.stars(0, g, density: tall ? 80 : 55, seed: 51)
        for i in 0..<(tall ? 26 : 12) {                       // smears of light dragged sideways by the warp
            let x = Int(noise(i * 5 + 510) * Double(c.w)), y = Int(noise(i * 5 + 511) * Double(g - 4))
            let len = (14 + Int(noise(i * 5 + 512) * 40)) * s
            c.rect(x - len / 2, y, len, s, C(0xB8A8F0, 0.10))
            c.rect(x - len / 4, y, len / 2, s, C(0xD8D0FF, 0.10))
        }
        let rings = tall ? 10 : 7
        for k in 1...rings {
            let r = o.r * Double(k) / Double(rings)
            let n = Int(r * 5)
            for i in 0..<n {
                let a: Double = Double(i) / Double(n) * 2 * Double.pi
                let p = phantomRing(c, g, r: r, a: a, k: k)
                c.rect(p.x, p.y, s, s, C(0xC8C0F0, 0.24 - 0.016 * Double(k)))
            }
        }
        // the tear itself
        let tr = o.r * 0.1
        c.ellipse(o.x, o.y, Int(tr * 1.8), max(1, Int(tr * 1.8 * o.squash)), C(0xC8C0F8, 0.15))
        c.ellipse(o.x, o.y, Int(tr), max(1, Int(tr * o.squash)), C(0xE8E4FF, 0.35))
        c.ellipse(o.x, o.y, Int(tr * 0.5), max(1, Int(tr * 0.5 * o.squash)), C(0xFFFFFF, 0.55))
        if tall {
            for i in 0..<5 {                                    // empty panes lost in the haze
                let x = Int(noise(i * 7 + 520) * Double(c.w)), y = g / 10 + Int(noise(i * 7 + 521) * Double(g / 3))
                phantomPane(c, x: x, y: y, p: 3 * s, turn: 0.4 + noise(i * 7 + 522) * 0.6, fade: 0.22, who: -1)
            }
        }
        // the band behind the crew sinks into darkness
        for k in 0..<4 { c.rect(0, g - (k + 1) * 6 * s, c.w, 6 * s, C(0x06050E, 0.10)) }
        // the crystal sheet underfoot, its seams running off toward the tear
        c.ground(g, C(0x171433), edge: C(0xC8C0F0), speck: C(0x2C2654), seed: 51)
        for k in -16...16 {
            let xb = o.x + k * 34 * s
            for y in (g + 1)..<c.h {
                let f = Double(y - g + 8) / Double(c.h - g + 8)
                c.rect(o.x + Int(Double(xb - o.x) * f), y, s, 1, C(0x8A80C8, 0.30))
            }
        }
        c.rect(0, g + 1, c.w, s, C(0xE8E4FF, 0.25))
    }

    /// One crystal pane, 13 by 17 units of `p` pixels, centred on `x`, its top on `y`, turned so that it shows
    /// `turn` of its width (negative: its back). `who` picks the prisoner flattened on it (-1: none).
    static func phantomPane(_ c: PixelCanvas, x: Int, y: Int, p: Int, turn: Double, fade: Double, who: Int) {
        let cols = max(1, Int((abs(turn) * 13).rounded())), ww = cols * p, hh = 17 * p, left = x - ww / 2
        let lean = Int(turn * 2) * p                            // the pane's top swings as it turns
        for r in 0..<hh {
            let off = lean * (hh - r) / hh
            c.rect(left + off, y + r, ww, 1, C(0xD8D4F8, 0.14 * fade))
            c.rect(left + off, y + r, p, 1, C(0xF0EEFF, 0.75 * fade))
            c.rect(left + off + ww - p, y + r, p, 1, C(0xF0EEFF, 0.75 * fade))
        }
        c.rect(left + lean, y, ww, p, C(0xF0EEFF, 0.75 * fade))
        c.rect(left, y + hh - p, ww, p, C(0xF0EEFF, 0.75 * fade))
        c.rect(left + lean + p, y + p, p, p, C(0xFFFFFF, 0.9 * fade))
        guard who >= 0, cols > 2 else { return }
        let shapes: [[String]] = [[
            "p.p.....p.p",
            "ppp.hhh.ppp",
            ".p.hhhhh.p.",
            ".phhhhhhhp.",
            "..hkkhkkh..",
            "..hhhhhhh..",
            "..hhhkhhh..",
            "..hhkkkhh..",
            "...hkkkh...",
            "....hhh....",
            "...bbbbb...",
            "..bbbbbbb..",
        ], [
            "p.p.kkk.p.p",
            "pppkkkkkppp",
            ".pkhhhhhkp.",
            ".phhhhhhhp.",
            "..hkkhkkh..",
            "..hhhhhhh..",
            "..hhkkkhh..",
            "..hkkkkkh..",
            "..kkkkkkk..",
            "...kkkkk...",
            "...bbbbb...",
            "..bbbbbbb..",
        ]]
        let rows = shapes[who % shapes.count]
        let back = turn < 0
        let pale = C(0xE4DCF4, (back ? 0.35 : 0.8) * fade), dark = C(0x1E1838, (back ? 0.3 : 0.9) * fade)
        let pal: [Character: Px] = ["p": pale, "h": pale, "b": pale.alpha(0.7), "k": dark]
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() {
                guard let col = pal[ch] else { continue }
                let u = back ? 10 - k : k
                let sx = left + Int(Double(1 + u) * Double(cols) / 13) * p
                let off = lean * (hh - (r + 3) * p) / hh
                c.rect(sx + off, y + (r + 3) * p, p, p, col)
            }
        }
    }

    /// The prison panes drift by, slowly turning over, a prisoner screaming silently on each; sparks of light run
    /// round the warped rings.
    static func phantomZoneDrift(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), o = phantomCentre(c, g)
        let rings = tall ? 10 : 7
        for i in 0..<(tall ? 22 : 12) {
            let k = 1 + i % rings
            let dir: Double = k % 2 == 0 ? 1 : -1
            let a: Double = noise(i * 3 + 530) * 6.283 + t * 0.25 * dir
            let p = phantomRing(c, g, r: o.r * Double(k) / Double(rings), a: a, k: k)
            c.rect(p.x, p.y, s, s, C(0xFFFFFF, 0.7))
            c.rect(p.x - s, p.y, s, s, C(0xD8D0FF, 0.3)); c.rect(p.x + s, p.y, s, s, C(0xD8D0FF, 0.3))
        }
        let n = tall ? 9 : 5
        for i in 0..<n {
            let p = tall ? (i % 3 == 0 ? 3 : 2) * s : s
            let span = Double(c.w + 40 * p)
            let speed: Double = (3 + noise(i * 9 + 540) * 4) * Double(p) * (i % 2 == 0 ? 1 : -1)
            var xf = (noise(i * 9 + 541) * span + t * speed).truncatingRemainder(dividingBy: span)
            if xf < 0 { xf += span }
            let x = Int(xf) - 20 * p
            let top = tall ? g / 12 : 2 * s, room = tall ? g * 3 / 5 : max(1, g / 3 - 6)
            let y = top + Int(noise(i * 9 + 542) * Double(room)) + Int(sin(t * 0.6 + Double(i) * 1.7) * 2 * Double(p))
            let turn = cos(t * 0.3 + Double(i) * 2.1)
            phantomPane(c, x: x, y: y, p: p, turn: turn, fade: tall && p == 2 * s ? 0.75 : 1, who: i)
        }
    }
}

// MARK: - Kahndaq

extension Scenes {
    /// Where the statue of Black Adam stands, and its size in pixels per unit.
    static func kahndaqStatue(_ c: PixelCanvas, _ g: Int) -> (x: Int, k: Int, head: Int) {
        let k = isTall(c) ? max(2, g / 90) : 1
        return (Int(Double(c.w) * 0.76), k, g - 57 * k)
    }

    /// Kahndaq at golden hour: a low sun behind the haze, mesas and dunes, the old city of sandstone blocks, domes and
    /// minarets catching the light, and in the square the giant statue of Black Adam, arms folded and cape flaring,
    /// the gold bolt on his chest, its long shadow lying across the plaza where the crew stands.
    static func kahndaq(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, tall ? C(0x4E4C84) : C(0x6E5C8C), C(0xF6C274), bands: tall ? 10 : 8)
        let sx = Int(Double(c.w) * 0.2), sy = tall ? Int(Double(g) * 0.48) : g - max(10, g / 5), sr = max(6, g / 10)
        for k in 0..<5 { c.circle(sx, sy, sr + (5 - k) * 4 * s, C(0xFFD890, 0.08)) }
        c.circle(sx, sy, sr, C(0xFFF0C0))
        c.circle(sx, sy, sr - max(1, sr / 4), C(0xFFFAE0))
        for i in 0..<(tall ? 7 : 3) {
            wisp(c, Int(noise(i * 5 + 600) * Double(c.w)), g / 10 + Int(noise(i * 5 + 601) * Double(g / 3)),
                 (30 + Int(noise(i * 5 + 602) * 50)) * s, C(0xF8C8A0, 0.45), s: s)
        }
        if tall {                                               // the old palace up on its crag
            let hx = Int(Double(c.w) * 0.3), hb = g - g / 8, hh = Int(Double(g) * 0.42)
            mesa(c, x: hx, width: 130 * s, h: hh, base: hb, C(0xB07C66), seed: 63)
            mesa(c, x: hx + 10 * s, width: 40 * s, h: hh - 4 * s, base: hb, C(0xC08A70), seed: 64)
            let top = hb - hh, px = hx + 40 * s
            c.rect(px, top - 16 * s, 50 * s, 16 * s, C(0xC89C76)); c.rect(px, top - 16 * s, 3 * s, 16 * s, C(0xE0B88E))
            c.rect(px + 10 * s, top - 24 * s, 30 * s, 8 * s, C(0xD0A47C))
            s5Dome(c, px + 25 * s, top - 24 * s, 11 * s, 10 * s, C(0xD8AA50), lit: C(0xF8D488), shade: C(0xA87840))
            c.rect(px + 25 * s, top - 38 * s, s, 4 * s, C(0xF8D488))
            for k in [0, 46] { c.rect(px + k * s, top - 32 * s, 4 * s, 16 * s, C(0xD0A47C)); s5Dome(c, px + k * s + 2 * s, top - 32 * s, 3 * s, 3 * s, C(0xD8AA50), lit: C(0xF8D488), shade: C(0xA87840)) }
            for k in stride(from: 4, to: 48, by: 5) { c.rect(px + k * s, top - 11 * s, s, 3 * s, C(0x7A5038)) }
        }
        mesa(c, x: Int(Double(c.w) * 0.38), width: 70 * s, h: max(8, g / 6), base: g - g / 8, C(0xC08A78), seed: 61)
        mesa(c, x: Int(Double(c.w) * 0.84), width: 60 * s, h: max(6, g / 8), base: g - g / 8, C(0xC8927A), seed: 62)
        c.dunes(base: g - g / 7, amp: 2, freq: 0.05, phase: 1, bottom: g, C(0xD8A272), shade: C(0xF0C890))
        // the city, a hazy far row and a sunlit near row
        kahndaqRow(c, g, lo: 0.16, hi: 0.32, seed: 3, col: C(0xD4A678), lit: C(0xE8C092), shade: C(0xB8886A), win: C(0xA07052))
        kahndaqMinarets(c, g)
        kahndaqRow(c, g, lo: 0.08, hi: 0.2, seed: 11, col: C(0xBE8A54), lit: C(0xE6B87C), shade: C(0x8A5C38), win: C(0x5A3A22))
        // the great dome of the palace mosque
        let mx = Int(Double(c.w) * 0.47), mb = g - Int(Double(g) * 0.2)
        let mr = tall ? 26 * s : 14 * s
        c.rect(mx - mr - 4 * s, mb, (mr + 4 * s) * 2, g - mb, C(0xC8945C))
        c.rect(mx - mr - 4 * s, mb, (mr + 4 * s) * 2, s, C(0xF0C890))
        c.rect(mx - mr + 3 * s, mb - 4 * s, (mr - 3 * s) * 2, 4 * s, C(0xD09C62))
        s5Dome(c, mx, mb - 4 * s, mr - 3 * s, mr * 4 / 5, C(0xE0AE4A), lit: C(0xFFE08A), shade: C(0xA87830))
        c.rect(mx, mb - 4 * s - mr * 4 / 5 - 4 * s, s, 4 * s, C(0xFFE08A))
        for x in stride(from: mx - mr, to: mx + mr, by: 5 * s) { c.rect(x, mb + 3 * s, 2 * s, 4 * s, C(0x5A3A22)) }
        // the golden-hour shadow pooling at street level
        for k in 0..<3 { c.rect(0, g - (k + 1) * 5 * s, c.w, 5 * s, C(0x4A2410, 0.12)) }
        kahndaqStatueDraw(c, g)
        c.ground(g, C(0xC4925A), edge: C(0xF2CA8A), speck: C(0xA87A48), seed: 61)
        for x in stride(from: 0, to: c.w, by: 18 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0xA87A48)) }
        c.rect(0, g + (c.h - g) / 2, c.w, s, C(0xA87A48))
        // the statue's long shadow, thrown away from the low sun
        let st = kahndaqStatue(c, g)
        let fh = Double(c.h - g)
        s5Poly(c, [(Double(st.x - 12 * st.k), Double(g + 1)), (Double(st.x + 12 * st.k), Double(g + 1)),
                   (Double(st.x + 12 * st.k) + fh * 4, Double(c.h)), (Double(st.x - 12 * st.k) + fh * 2.5, Double(c.h))],
               C(0x5A2A12, 0.3))
    }

    /// A row of flat-roofed sandstone houses, some with domes, standing on the ground row.
    static func kahndaqRow(_ c: PixelCanvas, _ g: Int, lo: Double, hi: Double, seed: Int, col: Px, lit: Px, shade: Px, win: Px) {
        let s = unit(g)
        var x = -6 * s, i = 0
        while x < c.w {
            let bw = (10 + Int(noise(i * 7 + seed * 131) * 16)) * s
            let bh = Int(Double(g) * (lo + noise(i * 7 + 1 + seed * 131) * (hi - lo)))
            let top = g - bh
            c.rect(x, top, bw, bh, col)
            c.rect(x, top, 2 * s, bh, lit)
            c.rect(x + bw - 3 * s, top, 3 * s, bh, shade)
            c.rect(x - s, top, bw + 2 * s, s, lit)
            for (j, wy) in stride(from: top + 3 * s, to: g - 3 * s, by: 6 * s).enumerated() {
                for (n, wx) in stride(from: x + 3 * s, to: x + bw - 4 * s, by: 4 * s).enumerated()
                where noise(i * 37 + j * 5 + n + seed) > 0.45 {
                    c.rect(wx, wy + s, s, 2 * s, win); c.px(wx, wy, win.alpha(0.5))
                }
            }
            if noise(i * 7 + 2 + seed * 131) > 0.62 {
                let gold = noise(i * 7 + 4 + seed * 131) > 0.7
                s5Dome(c, x + bw / 2, top - s, bw / 2 - 2 * s, max(2 * s, bw / 3), gold ? C(0xDCAA48) : lerp(col, lit, 0.4),
                       lit: gold ? C(0xFFE08A) : lit, shade: shade)
                c.rect(x + bw / 2, top - s - max(2 * s, bw / 3) - 2 * s, s, 2 * s, C(0xF8D070))
            }
            x += bw + Int(noise(i * 7 + 3 + seed * 131) * 3) * s
            i += 1
        }
    }

    /// Slender minarets with a balcony and a pointed cap.
    static func kahndaqMinarets(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        for (i, f) in ([0.07, 0.36, 0.58, 0.95] as [Double]).enumerated() {
            let x = Int(Double(c.w) * f), hgt = Int(Double(g) * (tall ? 0.42 : 0.62) * (i % 2 == 0 ? 1 : 0.86))
            let top = g - hgt, bw = (tall ? 6 : 4) * s
            c.rect(x - bw / 2, top, bw, hgt, C(0xDCAE74))
            c.rect(x - bw / 2, top, s, hgt, C(0xF4D49C))
            c.rect(x + bw / 2 - s, top, s, hgt, C(0xA87A50))
            let by = top + hgt / 4
            c.rect(x - bw / 2 - 2 * s, by, bw + 4 * s, 2 * s, C(0xE8C088)); c.rect(x - bw / 2 - 2 * s, by + 2 * s, bw + 4 * s, s, C(0x8A5C38))
            c.rect(x - bw / 2 - s, top + hgt / 2, bw + 2 * s, s, C(0xE8C088))
            s5Dome(c, x, top, bw / 2 + s, bw / 2 + s, C(0xDCAA48), lit: C(0xFFE08A), shade: C(0xA87830))
            c.rect(x, top - bw / 2 - 4 * s, s, 3 * s, C(0xFFE08A))
            c.rect(x - s / 2, top + 3 * s, max(1, s), 3 * s, C(0x5A3A22))
        }
    }

    /// The statue of Black Adam on its stepped pedestal, sunlit from the left.
    static func kahndaqStatueDraw(_ c: PixelCanvas, _ g: Int) {
        let st = kahndaqStatue(c, g), k = st.k, x = st.x
        let stone = C(0x6E5236), lit = C(0xB08A56), shade = C(0x3C2A1C), gold = C(0xF6CC50)
        let ped = C(0xC89A62), pedLit = C(0xF0CA8C), pedShade = C(0x8A6038)
        var base = g
        let r = { (u0: Int, v0: Int, u1: Int, v1: Int, col: Px) in
            c.rect(x + u0 * k, base + v0 * k, (u1 - u0) * k, (v1 - v0) * k, col)
        }
        r(-15, -3, 15, 0, ped); r(-15, -3, -13, 0, pedLit); r(13, -3, 15, 0, pedShade)
        r(-12, -8, 12, -3, ped); r(-12, -8, -10, -3, pedLit); r(10, -8, 12, -3, pedShade)
        r(-15, -3, 15, -2, pedLit); r(-12, -8, 12, -7, pedLit)
        r(-8, -6, 8, -5, pedShade)                         // the inscription
        base -= 8 * k
        let poly = { (pts: [(Double, Double)], col: Px) in
            let fx = Double(x), fy = Double(base), fk = Double(k)
            s5Poly(c, pts.map { (p: (Double, Double)) -> (Double, Double) in (fx + p.0 * fk, fy + p.1 * fk) }, col)
        }
        let rightSide = C(0x56402A)
        poly([(-8, -38), (8, -38), (15, 0), (-15, 0)], shade)                    // the cape, flaring behind
        for u in [-12, -5, 4, 10] { r(u, -1, u + 2, 0, C(0x2A1C12)) }
        poly([(-6, -22), (-1, -22), (-2, 0), (-8, 0)], stone)                   // legs and boots
        poly([(1, -22), (6, -22), (8, 0), (2, 0)], rightSide)
        poly([(-6, -22), (-4.5, -22), (-6.5, 0), (-8, 0)], lit)
        r(-8, -4, -2, 0, C(0x4E3A26)); r(2, -4, 8, 0, C(0x3E2C1E))
        poly([(-10, -39), (10, -39), (6, -22), (-6, -22)], stone)              // the torso
        poly([(3, -39), (10, -39), (6, -22), (2, -22)], rightSide)
        poly([(-10, -39), (-7, -39), (-4, -22), (-6, -22)], lit)
        r(-11, -40, 11, -38, stone); r(-11, -40, 4, -39, lit)
        r(-6, -24, 6, -22, C(0xB8902E)); r(-1, -24, 1, -22, gold)
        // fists on his hips, elbows out
        poly([(-11, -39), (-8, -37), (-12, -29), (-16, -31)], stone)
        poly([(-11, -39), (-10, -38.5), (-15, -30), (-16, -31)], lit)
        poly([(-16, -31), (-12, -30), (-6, -26), (-6, -22), (-9, -23), (-15, -28)], stone)
        poly([(-16, -31), (-12, -30), (-6, -26), (-6, -25), (-12, -29), (-16, -30)], lit)
        poly([(11, -39), (8, -37), (12, -29), (16, -31)], rightSide)
        poly([(16, -31), (12, -30), (6, -26), (6, -22), (9, -23), (15, -28)], rightSide)
        poly([(16, -31), (12, -30), (6, -26), (6, -25), (12, -29), (16, -30)], stone)
        r(0, -37, 2, -36, gold); r(-1, -36, 1, -35, gold); r(-2, -35, 2, -34, gold); r(0, -34, 2, -33, gold); r(-1, -33, 1, -32, gold)
        r(-2, -42, 2, -39, stone); r(0, -42, 2, -39, rightSide)                 // neck and head
        c.ellipse(x, base - 45 * k, 3 * k, 4 * k, stone)
        r(0, -48, 4, -41, rightSide.alpha(0.6))
        r(-3, -49, 3, -46, C(0x2E2016)); r(-1, -46, 1, -45, C(0x2E2016))
        r(-3, -46, -2, -42, lit)
        if k >= 2 { r(-2, -45, 3, -44, shade); r(-1, -42, 2, -41, shade) }
    }

    /// Heat shimmering over the rooftops, the sun glinting on the statue's bolt and a hawk circling his head.
    static func kahndaqLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), st = kahndaqStatue(c, g)
        let band = tall ? Int(Double(g) * 0.3) : g / 3
        for i in 0..<(tall ? 9 : 5) {
            let y0 = g - band + i * band / (tall ? 9 : 5)
            let ph = t * 2.6 + Double(i) * 1.9
            for x in stride(from: 0, to: c.w, by: 2 * s) {
                let fx = Double(x)
                let v = sin(fx * 0.09 + ph) + sin(fx * 0.031 - ph * 0.6)
                if v > 1.1 { c.rect(x, y0 + Int(sin(fx * 0.2 + ph) * 1.5), 2 * s, 1, C(0xFFF2C8, 0.16)) }
            }
        }
        let gl = 0.5 + 0.5 * sin(t * 1.7)
        let by = g - 8 * st.k - 35 * st.k
        c.circle(st.x + st.k / 2, by, 2 * st.k + Int(gl * 2 * Double(st.k)), C(0xFFE890, 0.18 + 0.2 * gl))
        // the hawk
        let p = tall ? 2 * s : s
        let a = t * 0.55
        let rx = Double(tall ? 70 : 34) * Double(s), ry = Double(tall ? 18 : 6) * Double(s)
        let hx = st.x + Int(cos(a) * rx), hy = st.head - (tall ? 22 : 7) * s + Int(sin(a) * ry)
        let up = s5Phase(t, 0.5) < 0.5 && sin(a * 3) > -0.3
        let rows: [String] = up ? ["d.....d", ".dd.dd.", "...d..."] : [".......", "ddddddd", "..ddd..", "...d..."]
        s5Stamp(c, hx - 3 * p, hy, rows, ["d": C(0x3A2418)], s: p)
    }
}

// MARK: - Iron Heights

extension Scenes {
    /// The high barred windows along the top of the cell block.
    static func ironWindows(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, w: Int, h: Int)] {
        let s = unit(g), tall = isTall(c)
        let wh = tall ? Int(Double(g) * 0.2) : 10 * s, ww = tall ? 36 * s : 22 * s, gap = tall ? 74 * s : 64 * s
        var out: [(x: Int, y: Int, w: Int, h: Int)] = []
        var x = tall ? 24 * s : 18 * s
        while x + ww < c.w { out.append((x, tall ? 10 * s : 2 * s, ww, wh)); x += gap }
        return out
    }

    /// The guard tower outside: where its lamp is.
    static func ironTower(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int) {
        let win = ironWindows(c, g), s = unit(g)
        let w = win[min(win.count - 1, win.count * 2 / 3)]
        return (w.x + w.w / 2, w.y + w.h / 3 + (isTall(c) ? 2 * s : 0))
    }

    /// Where the red alarm lamps hang, over each cell door.
    static func ironLamps(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        var out: [(x: Int, y: Int)] = []
        for tier in ironTiers(c, g) {
            for (i, x) in ironCellXs(c, g).enumerated() where i % 2 == 0 { out.append((x + 12 * unit(g), tier - 34 * unit(g))) }
        }
        return out
    }

    /// The floor row each tier of cells stands on, top to bottom.
    static func ironTiers(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let s = unit(g)
        guard isTall(c) else { return [g] }
        let top = ironWindows(c, g)[0].y + ironWindows(c, g)[0].h + 50 * s
        var out: [Int] = []
        var y = g
        while y - 36 * s > top { out.insert(y, at: 0); y -= 44 * s }
        return out
    }

    static func ironCellXs(_ c: PixelCanvas, _ g: Int) -> [Int] {
        let s = unit(g)
        return Array(stride(from: 4 * s, to: c.w, by: 30 * s))
    }

    /// Iron Heights, where Central City keeps the Rogues: a grim concrete cell block under a row of high barred
    /// windows, a tower outside throwing its searchlight about, tiers of barred cells along the wall with caged red
    /// lamps over the doors, and in the middle a glass case of confiscated Rogues' gear: Captain Cold's cold gun,
    /// Heat Wave's flame gun, Captain Boomerang's boomerang, Mirror Master's mirror and the Weather Wizard's wand.
    static func ironHeights(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.rect(0, 0, c.w, g, C(0x3E4246))
        for (j, y) in stride(from: 0, to: g, by: 6 * s).enumerated() {
            c.rect(0, y, c.w, s, C(0x34383C))
            for x in stride(from: (j % 2) * 9 * s, to: c.w, by: 18 * s) { c.rect(x, y, s, 6 * s, C(0x36393D)) }
        }
        for i in 0..<(c.w * g / 140) {                          // stains and pitting
            let x = Int(noise(i * 3 + 700) * Double(c.w)), y = Int(noise(i * 3 + 701) * Double(g))
            c.rect(x, y, s, (1 + Int(noise(i * 3 + 702) * 4)) * s, C(0x2E3134, 0.6))
        }
        let tw = ironTower(c, g)
        for w in ironWindows(c, g) {
            c.rect(w.x - 2 * s, w.y - 2 * s, w.w + 4 * s, w.h + 4 * s, C(0x26292C))
            for k in 0..<w.h { c.rect(w.x, w.y + k, w.w, 1, lerp(C(0x0A1024), C(0x1E2440), Double(k) / Double(w.h))) }
            c.stars(w.y, w.y + w.h, density: 30, seed: w.x, x0: w.x, x1: w.x + w.w)
            // the perimeter wall and the tower, seen through the bars
            c.rect(w.x, w.y + w.h * 4 / 5, w.w, w.h - w.h * 4 / 5, C(0x14161C))
            if abs(w.x + w.w / 2 - tw.x) < 2 {
                let tb = w.y + w.h * 4 / 5, q = tall ? 2 * s : s
                c.rect(tw.x - 2 * q, tw.y + 2 * q, 4 * q, tb - tw.y - 2 * q, C(0x101218))
                s5Line(c, tw.x - 2 * q, tw.y + 2 * q, tw.x - 5 * q, tb, C(0x101218), s: s)
                s5Line(c, tw.x + 2 * q, tw.y + 2 * q, tw.x + 5 * q, tb, C(0x101218), s: s)
                c.rect(tw.x - 4 * q, tw.y - q, 8 * q, 3 * q, C(0x101218))
                c.rect(tw.x - 3 * q, tw.y, 6 * q, q, C(0xFFE6A0, 0.7))
                c.rect(tw.x - 5 * q, tw.y - 2 * q, 10 * q, q, C(0x181A20))
            }
            for x in stride(from: w.x + 3 * s, to: w.x + w.w, by: 4 * s) { c.rect(x, w.y, s, w.h, C(0x1A1C20)) }
            c.rect(w.x, w.y + w.h / 2, w.w, s, C(0x1A1C20))
            c.rect(w.x - 2 * s, w.y + w.h + s, w.w + 4 * s, s, C(0x5A5E62))
        }
        // pipes along the wall under the windows
        let py = ironWindows(c, g)[0].y + ironWindows(c, g)[0].h + 5 * s
        c.rect(0, py, c.w, 2 * s, C(0x5A4E3A)); c.rect(0, py, c.w, s, C(0x7A6A4E))
        c.rect(0, py + 4 * s, c.w, s, C(0x4A4E52))
        for tier in ironTiers(c, g) { ironCells(c, g, floor: tier, catwalk: tier < g) }
        ironCase(c, g)
        c.ground(g, C(0x383A3C), edge: C(0x6A6E70), speck: C(0x2C2E30), seed: 71)
        c.rect(0, g + 3 * s, c.w, s, C(0xB8A040, 0.7))
        for x in stride(from: 0, to: c.w, by: 24 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x2E3032)) }
        if tall {                                                // hazard stripes along the pipe run
            for x in stride(from: 0, to: c.w, by: 8 * s) {
                c.rect(x, py + 8 * s, 4 * s, 3 * s, C(0xB8A040, 0.6)); c.rect(x + 4 * s, py + 8 * s, 4 * s, 3 * s, C(0x1A1A1A, 0.6))
            }
        }
    }

    /// A row of barred cells standing on row `floor`, with a catwalk and railing along its foot on the upper tiers.
    static func ironCells(_ c: PixelCanvas, _ g: Int, floor: Int, catwalk: Bool) {
        let s = unit(g), top = floor - 30 * s
        c.rect(0, top - 2 * s, c.w, 2 * s, C(0x5A5E62))
        for (i, x) in ironCellXs(c, g).enumerated() {
            c.rect(x, top, 24 * s, 30 * s, C(0x141618))
            c.rect(x + 2 * s, top + 4 * s, 4 * s, 3 * s, C(0x24262A))  // a bunk and a shelf in the gloom
            c.rect(x + 2 * s, floor - 9 * s, 14 * s, 2 * s, C(0x2A2C30)); c.rect(x + 2 * s, floor - 7 * s, s, 7 * s, C(0x222428))
            if noise(i * 5 + floor) > 0.6 { c.rect(x + 18 * s, floor - 6 * s, 4 * s, 6 * s, C(0x26282C)) }
            for bx in stride(from: x + s, to: x + 24 * s, by: 3 * s) { c.rect(bx, top, s, 30 * s, C(0x7A7E82)) }
            c.rect(x, top, 24 * s, 2 * s, C(0x6A6E72)); c.rect(x, top + 14 * s, 24 * s, s, C(0x6A6E72))
            c.rect(x, top, s, 30 * s, C(0x8A8E92)); c.rect(x + 23 * s, top, s, 30 * s, C(0x4A4E52))
            c.rect(x + 9 * s, top - 6 * s, 6 * s, 3 * s, C(0xC8C8B8)); c.rect(x + 10 * s, top - 5 * s, 4 * s, s, C(0x2A2A2A))
            if i % 2 == 0 {
                let lx = x + 12 * s, ly = floor - 34 * s
                c.rect(lx - 2 * s, ly - s, 4 * s, 3 * s, C(0x6A1A1A)); c.rect(lx - s, ly, 2 * s, s, C(0xA02828))
                c.rect(lx - 2 * s, ly - s, s, 3 * s, C(0x2A2C2E)); c.rect(lx + s, ly - s, s, 3 * s, C(0x2A2C2E))
            }
        }
        if catwalk {
            c.rect(0, floor, c.w, 3 * s, C(0x4A4E52)); c.rect(0, floor, c.w, s, C(0x8A8E92))
            c.rect(0, floor - 8 * s, c.w, s, C(0x9A9EA2)); c.rect(0, floor - 4 * s, c.w, s, C(0x6A6E72))
            for x in stride(from: 0, to: c.w, by: 10 * s) { c.rect(x, floor - 8 * s, s, 8 * s, C(0x7A7E82)) }
        }
    }

    /// The display case of Rogues' gear, in the middle of the floor.
    static func ironCase(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), p = isTall(c) ? 2 * s : s
        let w = 50 * p, h = 28 * p, x = c.w / 2 - w / 2, y = g - h
        c.rect(x - 2 * p, g - 5 * p, w + 4 * p, 5 * p, C(0x2A2C30)); c.rect(x - 2 * p, g - 5 * p, w + 4 * p, p, C(0x6A6E72))
        c.rect(x, y, w, h - 5 * p, C(0x1C2228))
        c.rect(x, y + 11 * p, w, p, C(0x5A6066))                // the shelf
        c.rect(x, y, w, p, C(0xD8F0FF, 0.25))                   // light inside the case
        s5Stamp(c, x + 4 * p, y + 4 * p, [
            "...ww.......",
            "wwwwwwwwwccc",
            "ccwwwwwwwc..",
            "...ww.......",
            "...w........",
        ], ["w": C(0xE8F4FF), "c": C(0x7AD8FF)], s: p)          // the cold gun
        s5Stamp(c, x + 22 * p, y + 3 * p, [
            "..rrr.........",
            ".rrrrr........",
            "ooooooooooyy..",
            "oorrrrrrrooo..",
            "...oo.........",
            "...o..........",
        ], ["r": C(0xA02818), "o": C(0xE87A28), "y": C(0xFFD050)], s: p)   // the heat gun
        s5Stamp(c, x + 39 * p, y + 3 * p, [
            "..mmmm.",
            ".mssssm",
            ".mssssm",
            ".mssssm",
            "..mmmm.",
            "...m...",
            "..mmm..",
        ], ["m": C(0x2A8A4A), "s": C(0xC8E4F0)], s: p)          // Mirror Master's mirror
        s5Stamp(c, x + 5 * p, y + 14 * p, [
            "b........b",
            ".b......b.",
            "..bb..bb..",
            "....yy....",
        ], ["b": C(0x8A5A2A), "y": C(0xE8C040)], s: p)          // the boomerang
        s5Stamp(c, x + 22 * p, y + 13 * p, [
            "....oo",
            "....oo",
            "...g..",
            "..g...",
            ".g....",
            "g.....",
        ], ["o": C(0x7AB8FF), "g": C(0xC8A048)], s: p)          // the Weather Wizard's wand
        s5Stamp(c, x + 34 * p, y + 14 * p, [
            "...k....",
            ".kkkkk..",
            "ppppppp.",
            ".kkkkk..",
            "..kkk...",
            "...k....",
        ], ["k": C(0x3A5AC8), "p": C(0xF0D040)], s: p)          // the Top's spinning top
        c.rect(x + 18 * p, g - 4 * p, 14 * p, 2 * p, C(0xC8A048))   // the brass plaque
        c.rect(x, y, w, h - 5 * p, C(0xC8E8FF, 0.06))
        c.rect(x, y, p, h - 5 * p, C(0xC8D4DC)); c.rect(x + w - p, y, p, h - 5 * p, C(0xC8D4DC))
        c.rect(x, y - p, w, p, C(0xC8D4DC))
        c.rect(x + 2 * p, y + 2 * p, p, 8 * p, C(0xFFFFFF, 0.35)); c.rect(x + 4 * p, y + 2 * p, p, 4 * p, C(0xFFFFFF, 0.2))
    }

    /// The tower's searchlight sweeping back and forth through the windows and the shafts of light it throws across
    /// the floor, and the red lamps over the cells pulsing in turn.
    static func ironHeightsLights(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), wins = ironWindows(c, g), tw = ironTower(c, g)
        let sweep: Double = sin(t * 0.45)
        let aim = Double(tw.x) + sweep * Double(c.w) * 0.6     // where the beam is pointing, along the window row
        // the beam itself, in the sky behind the bars
        for w in wins {
            for k in 0..<w.h * 4 / 5 {
                let y = w.y + k
                let f = Double(tw.y - y) / Double(max(1, tw.y - w.y + 1))
                let cx = Double(tw.x) + (aim - Double(tw.x)) * max(0, f)
                let half = 2 + max(0, f) * 10 * Double(s)
                let x0 = max(w.x, Int(cx - half)), x1 = min(w.x + w.w, Int(cx + half))
                if y <= tw.y, x1 > x0 { c.rect(x0, y, x1 - x0, 1, C(0xE8F0FF, 0.35)) }
            }
            if abs(w.x + w.w / 2 - tw.x) < 2 { c.circle(tw.x, tw.y, 2 * s, C(0xFFF4C8, 0.9)) }
            // the shaft falling through this window into the hall
            let lit = max(0, 1 - abs(aim - Double(w.x + w.w / 2)) / Double(70 * s))
            guard lit > 0 else { continue }
            let y0 = w.y + w.h, drift = Double(w.w) * 0.6 * sweep
            for y in y0..<g {
                let f = Double(y - y0) / Double(max(1, g - y0))
                let x0 = w.x + Int(f * (Double(g - y0) * 0.5 + drift))
                c.rect(x0, y, w.w, 1, C(0xE8F0FF, 0.11 * lit))
            }
            c.ellipse(w.x + Int(Double(g - y0) * 0.5 + drift) + w.w / 2, g + (c.h - g) / 2, w.w, max(2, (c.h - g) / 3),
                      C(0xE8F0FF, 0.12 * lit))
        }
        let lamps = ironLamps(c, g)
        for (i, l) in lamps.enumerated() {
            let on = 0.5 + 0.5 * sin(t * 3 + Double(i % 4) * 1.57)
            c.rect(l.x - s, l.y - s, 2 * s, 2 * s, C(0xFF4A3A, 0.3 + 0.7 * on))
            c.circle(l.x, l.y, (tall ? 9 : 6) * s, C(0xFF2A2A, 0.10 * on))
            c.circle(l.x, l.y, 3 * s, C(0xFF3A3A, 0.25 * on))
            c.rect(l.x - 8 * s, l.y + 4 * s, 16 * s, 2 * s, C(0xFF2A2A, 0.08 * on))
        }
    }
}

// MARK: - The Speed Force

extension Scenes {
    /// The bright heart of the tunnel and how flattened its rings are.
    static func speedCore(_ c: PixelCanvas, _ g: Int) -> (x: Int, y: Int, r: Double, squash: Double) {
        let tall = isTall(c)
        return (c.w / 2, Int(Double(g) * (tall ? 0.42 : 0.36)), Double(c.w) * 0.62, tall ? 0.8 : 0.42)
    }

    /// Where the frozen moments hang (fractions of the width and of the ground row) and what each shows.
    static let speedMoments: [(x: Double, y: Double, kind: Int)] = [
        (0.09, 0.12, 0), (0.27, 0.06, 1), (0.71, 0.08, 2), (0.9, 0.16, 3), (0.37, 0.3, 4), (0.62, 0.32, 1),
    ]

    /// The Speed Force: a tunnel of light streaming toward a white-gold heart, ringed with blue and gold, its walls
    /// fading to deep blue around the crew, who stand on a plane of light streaked toward the vanishing point.
    /// Frozen moments of time hang in it like shards of glass: a clock, a city at dusk, the Flash's emblem, a man
    /// running, the house on a night long ago.
    static func speedForce(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), o = speedCore(c, g)
        let stops: [Px] = [C(0xFFFCEC), C(0xFFE89A), C(0xE8B848), C(0x5A78D8), C(0x1E2A78), C(0x0C1240), C(0x070A26)]
        c.rect(0, 0, c.w, g, C(0x070A26))
        let bands = 22
        for b in 0..<bands {
            let f = 1 - Double(b) / Double(bands)
            let rx = o.r * f * f
            c.ellipse(o.x, o.y, max(1, Int(rx)), max(1, Int(rx * o.squash)), s5Ramp(stops, f * 1.15))
        }
        // the tunnel's ribs
        var rr = o.r * 0.06, n = 0
        while rr < o.r * 1.4 {
            let col = n % 2 == 0 ? C(0xFFD860, 0.35) : C(0x9AC8FF, 0.3)
            let steps = Int(rr * 6) + 8
            for i in 0..<steps {
                let a: Double = Double(i) / Double(steps) * 2 * Double.pi
                let wob: Double = 1 + 0.05 * sin(a * 5 + Double(n))
                c.rect(o.x + Int(cos(a) * rr * wob), o.y + Int(sin(a) * rr * wob * o.squash), s, s, col)
            }
            rr *= 1.45; n += 1
        }
        // still streaks of light along the walls
        for i in 0..<(tall ? 70 : 40) {
            let a: Double = noise(i * 4 + 800) * 2 * Double.pi
            let r0: Double = o.r * (0.15 + noise(i * 4 + 801) * 0.6), r1 = r0 * (1.3 + noise(i * 4 + 802) * 0.5)
            let col = noise(i * 4 + 803) > 0.5 ? C(0xFFE08A, 0.18) : C(0xBFE0FF, 0.16)
            s5Line(c, o.x + Int(cos(a) * r0), o.y + Int(sin(a) * r0 * o.squash),
                   o.x + Int(cos(a) * r1), o.y + Int(sin(a) * r1 * o.squash), col, s: s)
        }
        let p = tall ? 2 * s : s
        for (i, m) in speedMoments.enumerated() {
            if !tall && m.y > 0.2 { continue }
            speedMoment(c, Int(Double(c.w) * m.x), Int(Double(g) * m.y) + (tall ? 0 : 2 * s), p, m.kind, seed: i)
        }
        if tall {
            for i in 0..<6 {
                let x = Int(noise(i * 3 + 820) * Double(c.w)), y = g / 2 + Int(noise(i * 3 + 821) * Double(g / 4))
                speedMoment(c, x, y, s, (i + 2) % 5, seed: i + 10)
            }
        }
        for k in 0..<4 { c.rect(0, g - (k + 1) * 6 * s, c.w, 6 * s, C(0x04061A, 0.12)) }
        c.ground(g, C(0x16205A), edge: C(0xE8F0FF), speck: C(0x2A3A88), seed: 81)
        for k in -14...14 {
            let xb = o.x + k * 30 * s
            let col = k % 2 == 0 ? C(0xFFD860, 0.45) : C(0x9AC8FF, 0.4)
            for y in (g + 1)..<c.h {
                let f = Double(y - g + 10) / Double(c.h - g + 10)
                c.rect(o.x + Int(Double(xb - o.x) * f), y, s, 1, col)
            }
        }
    }

    /// One frozen moment: a shard of glass 16 by 12 units of `p` pixels, centred on `x`, with a picture in it.
    static func speedMoment(_ c: PixelCanvas, _ x: Int, _ y: Int, _ p: Int, _ kind: Int, seed: Int) {
        let x0 = x - 8 * p
        c.rect(x0 - p, y - p, 18 * p, 14 * p, C(0xBFE0FF, 0.15))
        c.rect(x0, y, 16 * p, 12 * p, C(0xE8F4FF, 0.9))
        let ix = x0 + p, iy = y + p
        let pictures: [[String]] = [[
            "kkkkkkkkkkkkkk",
            "kkkkwwwwwwkkkk",
            "kkkwwwwrwwwkkk",
            "kkwwwwwrwwwwkk",
            "kkwwwwwrrrwwkk",
            "kkwwwwwwwwwwkk",
            "kkkwwwwwwwwkkk",
            "kkkkwwwwwwkkkk",
            "kkkkkkkkkkkkkk",
            "kkkkkkkkkkkkkk",
        ], [
            "oooooooooooooo",
            "oooooooooooooo",
            "oooooooooodooo",
            "pppdpppppdpppp",
            "ppddppdppdddpp",
            "ppddpdddpddddd",
            "dpddddddddddyd",
            "ddddyddddyddd.",
            "dddddddddddddd",
            "dddddddddddddd",
        ], [
            "rrrrrrrrrrrrrr",
            "rrrrwwwwwwrrrr",
            "rrrwwwwwyywrrr",
            "rrwwwwwyywwwrr",
            "rrwwwyyyyywwrr",
            "rrwwwwyywwwwrr",
            "rrwwwyywwwwwrr",
            "rrrwyywwwwwrrr",
            "rrrrwwwwwwrrrr",
            "rrrrrrrrrrrrrr",
        ], [
            "bbbbbbbbbbbbbb",
            "bbbbbbbbbrrbbb",
            "bbbbbbbbrrrrbb",
            "yyyybrrrrrbbbb",
            "bbbrr.rrrbbbbb",
            "yybbbbrrrbyybb",
            "bbbbbrrbrrbbbb",
            "bbbbrrbbbrrbbb",
            "gggrgggggggrgg",
            "gggggggggggggg",
        ], [
            "nnnnnnnnnnnnnn",
            "nnnnnnhhnnnnnn",
            "nnnnnhhhhnnnnn",
            "nnnnhhhhhhnnnn",
            "nnnhhhhhhhhnnn",
            "nnnnffyyffnnnn",
            "nnnnffyyffnnnn",
            "nnnnffffffnnnn",
            "gggggggggggggg",
            "gggggggggggggg",
        ]]
        let pal: [Character: Px] = ["k": C(0x2A2E44), "w": C(0xF4F0E0), "r": C(0xC81E1E), "o": C(0xE8905A),
                                    "p": C(0x8A4A7A), "d": C(0x2A1830), "y": C(0xFFD040), "b": C(0x3A4A6E),
                                    "g": C(0x2A3A2A), "n": C(0x101838), "h": C(0x3A2A2A), "f": C(0x6A5A4A)]
        s5Stamp(c, ix, iy, pictures[kind % pictures.count], pal, s: p)
        c.rect(ix, iy, 14 * p, 10 * p, C(0xC8E0FF, 0.18))          // the time-stopped haze over it
        c.rect(ix + p, iy + p, p, 3 * p, C(0xFFFFFF, 0.5))
        // chip a corner off so it reads as a shard
        let corner = seed % 4
        let cx = corner % 2 == 0 ? x0 : x0 + 14 * p, cy = corner < 2 ? y : y + 10 * p
        c.rect(cx, cy, 2 * p, 2 * p, C(0x0C1240, 0.85))
    }

    /// Lightning streams past: streaks of gold and blue-white rushing out of the heart of the tunnel, a few forks of
    /// lightning crackling along its walls, and the frozen moments shimmering.
    static func speedForceRush(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), o = speedCore(c, g)
        for i in 0..<(tall ? 110 : 60) {
            let a: Double = noise(i * 5 + 850) * 2 * Double.pi
            let ph = s5Phase(t, 0.9 + noise(i * 5 + 851) * 0.9, offset: noise(i * 5 + 852) * 3)
            let r0: Double = o.r * (0.04 + ph * ph * 1.1), r1 = r0 * (1.15 + ph * 0.5)
            let gold = noise(i * 5 + 853) > 0.5
            let col = gold ? C(0xFFD860, 0.25 + 0.6 * ph) : C(0xE0F0FF, 0.25 + 0.6 * ph)
            s5Line(c, o.x + Int(cos(a) * r0), o.y + Int(sin(a) * r0 * o.squash),
                   o.x + Int(cos(a) * r1), o.y + Int(sin(a) * r1 * o.squash), col, s: ph > 0.6 && tall ? 2 * s : s)
        }
        // lightning: a fresh fork every fifth of a second
        let step = Int(t * 5)
        for b in 0..<(tall ? 4 : 3) {
            guard noise(step * 7 + b * 3 + 860) > 0.35 else { continue }
            let a0: Double = noise(step * 7 + b * 3 + 861) * 2 * Double.pi
            var px = Double(o.x) + cos(a0) * o.r * 0.15, py = Double(o.y) + sin(a0) * o.r * 0.15 * o.squash
            let gold = (b + step) % 2 == 0
            let core = gold ? C(0xFFF4C0) : C(0xF0F8FF), glow = gold ? C(0xFFC830) : C(0x7AB8FF)
            for k in 0..<7 {
                let rr: Double = o.r * (0.15 + Double(k + 1) * 0.12)
                let a: Double = a0 + (noise(step * 31 + b * 11 + k) - 0.5) * 0.5
                let nx = Double(o.x) + cos(a) * rr, ny = Double(o.y) + sin(a) * rr * o.squash
                c.glowLine(px, py, nx, ny, core: core, glow: glow, coreR: 0.5 * Double(s), glowR: 1.8 * Double(s), strength: 0.85)
                px = nx; py = ny
            }
        }
        // the frozen moments catch the light now and then
        let p = tall ? 2 * s : s
        for (i, m) in speedMoments.enumerated() {
            if !tall && m.y > 0.2 { continue }
            let k = 0.5 + 0.5 * sin(t * 1.3 + Double(i) * 2)
            let x0 = Int(Double(c.w) * m.x) - 8 * p, y0 = Int(Double(g) * m.y) + (tall ? 0 : 2 * s)
            let sx = x0 + Int(k * 14) * p
            c.rect(sx, y0 + p, p, 10 * p, C(0xFFFFFF, 0.3))
        }
    }
}

// MARK: - Wayne Manor

extension Scenes {
    /// The size of the hall's furniture: 1 unit is this many pixels.
    static func wayneScale(_ c: PixelCanvas, _ g: Int) -> Int { isTall(c) ? 2 * unit(g) : unit(g) }

    /// The grandfather clock: its centre, top row, and the glass window its pendulum swings in.
    static func wayneClock(_ c: PixelCanvas, _ g: Int) -> (x: Int, top: Int, win: (x: Int, y: Int, w: Int, h: Int)) {
        let p = wayneScale(c, g), x = Int(Double(c.w) * 0.27), top = g - 54 * p
        return (x, top, (x - 3 * p, top + 18 * p, 6 * p, 20 * p))
    }

    /// The fireplace: centre, and the opening the fire burns in.
    static func wayneFire(_ c: PixelCanvas, _ g: Int) -> (x: Int, open: (x: Int, y: Int, w: Int, h: Int)) {
        let p = wayneScale(c, g), x = Int(Double(c.w) * 0.6)
        return (x, (x - 15 * p, g - 19 * p, 30 * p, 19 * p))
    }

    /// The candles of the chandelier on a tall canvas.
    static func wayneCandles(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int)] {
        let s = unit(g), cx = Int(Double(c.w) * 0.6), cy = g / 5
        return (-3...3).map { (k: Int) -> (x: Int, y: Int) in (cx + k * 9 * s, cy - (abs(k) == 3 ? 0 : abs(k) == 2 ? 2 : 3) * s) }
    }

    /// Wayne Manor's great hall by night: oak wainscot under dark green damask, tall windows hung with red velvet,
    /// the stone fireplace with its fire, Thomas and Martha Wayne in their gilded frames above the mantel, and the
    /// grandfather clock that hides the way down to the Batcave, its hands stopped at 10:47. Herringbone parquet and
    /// a rug before the hearth. On a tall canvas: the gallery, older Waynes on the upper wall, a coffered ceiling and
    /// a chandelier.
    static func wayneManor(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), p = wayneScale(c, g)
        c.rect(0, 0, c.w, g, C(0x1C2A1E))
        for (j, y) in stride(from: 2 * s, to: g, by: 6 * s).enumerated() {   // the damask
            for x in stride(from: (j % 2) * 4 * s, to: c.w, by: 8 * s) {
                c.rect(x + s, y, s, s, C(0x26382A)); c.rect(x, y + s, 3 * s, s, C(0x26382A)); c.rect(x + s, y + 2 * s, s, s, C(0x26382A))
            }
        }
        c.rect(0, 0, c.w, 3 * s, C(0x3A2416)); c.rect(0, 3 * s, c.w, s, C(0x8A6038))
        if tall { wayneUpper(c, g) }
        let wain = g - 22 * p
        c.rect(0, wain, c.w, g - wain, C(0x3E2616))
        for x in stride(from: 2 * s, to: c.w, by: 16 * s) {
            c.rect(x, wain + 4 * p, 12 * s, g - wain - 7 * p, C(0x4A2E1A))
            c.rect(x, wain + 4 * p, 12 * s, s, C(0x2A180C)); c.rect(x, g - 3 * p - s, 12 * s, s, C(0x6A4428))
        }
        c.rect(0, wain, c.w, 2 * s, C(0x6A4428)); c.rect(0, wain, c.w, s, C(0x9A6E40))
        for f in [0.06, 0.94] as [Double] { wayneWindow(c, g, Int(Double(c.w) * f)) }
        for f in [0.14, 0.43, 0.8] as [Double] {               // brass sconces
            let x = Int(Double(c.w) * f), y = wain - 16 * p
            c.circle(x, y, 7 * p, C(0xFFC870, 0.06)); c.circle(x, y, 4 * p, C(0xFFC870, 0.08))
            c.rect(x - p, y + p, 2 * p, 4 * p, C(0xA8804A)); c.rect(x - 2 * p, y, 4 * p, p, C(0xFFE0A0))
        }
        wayneFireplace(c, g)
        wayneClockDraw(c, g)
        for k in 0..<3 { c.rect(0, g - (k + 1) * 5 * s, c.w, 5 * s, C(0x0A0604, 0.10)) }
        // herringbone parquet
        c.ground(g, C(0x5A3820), edge: C(0x9A6E40), speck: C(0x4A2C18), seed: 91)
        for y in stride(from: g + 1, to: c.h, by: 2 * s) {
            for x in stride(from: ((y - g) / (2 * s)) % 2 * 3 * s, to: c.w, by: 6 * s) { c.rect(x, y, 3 * s, s, C(0x6A4428)) }
        }
        let fx = wayneFire(c, g).x
        c.rect(fx - 30 * p, g + 2 * s, 60 * p, c.h - g - 3 * s, C(0x6A1418))
        c.rect(fx - 30 * p, g + 2 * s, 60 * p, s, C(0xC8963A)); c.rect(fx - 30 * p, c.h - 2 * s, 60 * p, s, C(0xC8963A))
        c.rect(fx - 30 * p, g + 2 * s, s, c.h - g - 3 * s, C(0xC8963A)); c.rect(fx + 30 * p - s, g + 2 * s, s, c.h - g - 3 * s, C(0xC8963A))
        for x in stride(from: fx - 26 * p, to: fx + 26 * p, by: 8 * s) { c.rect(x, g + (c.h - g) / 2, 3 * s, s, C(0x9A2A2A)) }
    }

    /// A tall window hung with red velvet, the grounds under the moon outside.
    static func wayneWindow(_ c: PixelCanvas, _ g: Int, _ x: Int) {
        let s = unit(g), p = wayneScale(c, g), tall = isTall(c)
        let ww = 18 * p, top = tall ? g - 70 * p : 6 * s, wh = g - 6 * p - top, x0 = x - ww / 2
        c.rect(x0 - 2 * s, top - 2 * s, ww + 4 * s, wh + 4 * s, C(0x3A2416))
        for k in 0..<wh { c.rect(x0, top + k, ww, 1, lerp(C(0x0E1430), C(0x2A3A5A), Double(k) / Double(wh))) }
        c.circle(x0 + ww * 2 / 3, top + wh / 4, max(2, 3 * p), C(0xE8ECF4, 0.9))
        c.rect(x0, top + wh * 3 / 4, ww, wh - wh * 3 / 4, C(0x101A18))
        for k in 0..<4 { c.rect(x0 + k * ww / 4 + s, top + wh * 3 / 4 - (2 + k % 2 * 3) * s, 3 * s, 6 * s, C(0x101A18)) }
        for xx in stride(from: x0 + ww / 3, to: x0 + ww, by: ww / 3) { c.rect(xx, top, s, wh, C(0x2A1A10)) }
        for yy in stride(from: top + wh / 4, to: top + wh, by: wh / 4) { c.rect(x0, yy, ww, s, C(0x2A1A10)) }
        c.rect(x0 - 6 * s, top - 4 * s, ww + 12 * s, 3 * s, C(0x8A6038))
        for side in [0, 1] {                                       // the drapes
            let dx = side == 0 ? x0 - 6 * s : x0 + ww - 2 * s
            c.rect(dx, top - s, 8 * s, wh + 6 * p, C(0x6A161A))
            c.rect(dx + 2 * s, top - s, s, wh + 6 * p, C(0x8A2228)); c.rect(dx + 5 * s, top - s, s, wh + 6 * p, C(0x4A0E12))
            c.rect(dx, top + wh / 2, 8 * s, 2 * s, C(0xC8963A))
        }
    }

    /// The fireplace, the mantel and the portraits over it.
    static func wayneFireplace(_ c: PixelCanvas, _ g: Int) {
        let p = wayneScale(c, g), f = wayneFire(c, g), o = f.open, x = f.x
        c.rect(x - 26 * p, g - 30 * p, 52 * p, 30 * p, C(0x8A8274))
        for (j, y) in stride(from: g - 30 * p, to: g, by: 4 * p).enumerated() {
            for xx in stride(from: x - 26 * p + (j % 2) * 4 * p, to: x + 26 * p, by: 8 * p) { c.rect(xx, y, p, 4 * p, C(0x6A6458)) }
            c.rect(x - 26 * p, y, 52 * p, p, C(0x6A6458))
        }
        c.rect(x - 26 * p, g - 30 * p, 2 * p, 30 * p, C(0xA8A090)); c.rect(x + 24 * p, g - 30 * p, 2 * p, 30 * p, C(0x5A5448))
        c.rect(o.x - 2 * p, o.y - 3 * p, o.w + 4 * p, o.h + 3 * p, C(0x5A5448))
        c.rect(o.x, o.y, o.w, o.h, C(0x140A06))
        c.ellipse(x, g - 3 * p, o.w / 2 - p, 3 * p, C(0xC84A18, 0.35))  // embers
        c.rect(x - 10 * p, g - 4 * p, 20 * p, 2 * p, C(0x3A2214)); c.rect(x - 8 * p, g - 6 * p, 14 * p, 2 * p, C(0x4A2A18))
        c.rect(x - 9 * p, g - 2 * p, 18 * p, p, C(0xFF8A30, 0.7))
        c.rect(o.x + 2 * p, g - 2 * p, p, 2 * p, C(0x2A2A2A)); c.rect(o.x + o.w - 3 * p, g - 2 * p, p, 2 * p, C(0x2A2A2A))
        // the mantel, with candlesticks
        c.rect(x - 29 * p, g - 33 * p, 58 * p, 3 * p, C(0x4A2E1A)); c.rect(x - 29 * p, g - 33 * p, 58 * p, p, C(0x9A6E40))
        for dx in [-24, 22] { c.rect(x + dx * p, g - 38 * p, 2 * p, 5 * p, C(0xC8A048)); c.rect(x + dx * p, g - 40 * p, 2 * p, 2 * p, C(0xF0E8D0)) }
        c.rect(x - 2 * p, g - 37 * p, 4 * p, 4 * p, C(0xC8A048))              // a small carriage clock
        c.rect(x - p, g - 36 * p, 2 * p, 2 * p, C(0xF0E8D0))
        // Thomas and Martha
        let thomas: [String] = [
            "............",
            "....hhhh....",
            "...hhhhhh...",
            "...hssssh...",
            "...sesses...",
            "...ssssss...",
            "...smmmms...",
            "....ssss....",
            ".....ss.....",
            "..dddwwddd..",
            ".ddddwtdddd.",
            ".ddddwtdddd.",
            "dddddwtddddd",
            "ddddddtddddd",
            "dddddddddddd",
        ]
        let martha: [String] = [
            "....hhhh....",
            "...hhhhhh...",
            "..hhhhhhhh..",
            "..hhssssh...",
            "..hsesses...",
            "..hsssssh...",
            "..hssrrsh...",
            "...hssssh...",
            ".....ss.....",
            "...pppppp...",
            "..vvvvvvvv..",
            ".vvvvvvvvvv.",
            "vvvvvvvvvvvv",
            "vvvvvvvvvvvv",
            "vvvvvvvvvvvv",
        ]
        let pal: [Character: Px] = ["h": C(0x2A1A12), "s": C(0xD8B08C), "e": C(0x2A1A12), "m": C(0x3A2418), "d": C(0x1A1A22),
                                    "w": C(0xE8E4DC), "t": C(0x6A1A1E), "r": C(0xA83A3A), "p": C(0xF4F0E8), "v": C(0x1E3A2E)]
        for (i, who) in [thomas, martha].enumerated() {
            let fx = x - 19 * p + i * 22 * p, fy = g - 57 * p
            c.rect(fx - 2 * p, fy - 2 * p, 20 * p, 23 * p, C(0x8A6A2A))
            c.rect(fx - p, fy - p, 18 * p, 21 * p, C(0xD8B050))
            c.rect(fx - 2 * p, fy - 2 * p, 20 * p, p, C(0xF0D080))
            c.rect(fx, fy, 16 * p, 19 * p, C(0x2E2A1A))
            c.ellipse(fx + 8 * p, fy + 8 * p, 6 * p, 7 * p, C(0x4A4028, 0.6))
            s5Stamp(c, fx + 2 * p, fy + 3 * p, who, pal, s: p)
            c.rect(fx + 6 * p, fy + 20 * p, 4 * p, p, C(0xC8A048))
        }
    }

    /// The grandfather clock, hands at 10:47.
    static func wayneClockDraw(_ c: PixelCanvas, _ g: Int) {
        let p = wayneScale(c, g), k = wayneClock(c, g), x = k.x, top = k.top
        let wood = C(0x4A1E10), lit = C(0x7A3A1E), dark = C(0x2A0E06), brass = C(0xD8B050)
        c.rect(x - 7 * p, top + 2 * p, 14 * p, 15 * p, wood)                       // the hood
        c.ellipse(x, top + 3 * p, 7 * p, 3 * p, wood)
        c.rect(x - 7 * p, top + 2 * p, p, 15 * p, lit); c.rect(x + 6 * p, top + 2 * p, p, 15 * p, dark)
        c.rect(x - 8 * p, top + 16 * p, 16 * p, 2 * p, lit)
        c.rect(x - p, top - 2 * p, 2 * p, 2 * p, brass)
        c.circle(x, top + 9 * p, 5 * p, brass)
        c.circle(x, top + 9 * p, 4 * p, C(0xF0E8D4))
        for i in 0..<12 {
            let a: Double = Double(i) / 12 * 2 * Double.pi
            c.rect(x + Int(sin(a) * 3.4 * Double(p)), top + 9 * p - Int(cos(a) * 3.4 * Double(p)), max(1, p / 2), max(1, p / 2), C(0x2A1A12))
        }
        let ha: Double = (10 + 47.0 / 60) / 12 * 2 * Double.pi, ma: Double = 47.0 / 60 * 2 * Double.pi
        let cy = top + 9 * p
        s5Line(c, x, cy, x + Int(sin(ha) * 2.2 * Double(p)), cy - Int(cos(ha) * 2.2 * Double(p)), C(0x1A0E08), s: max(1, p / 2))
        s5Line(c, x, cy, x + Int(sin(ma) * 3.3 * Double(p)), cy - Int(cos(ma) * 3.3 * Double(p)), C(0x1A0E08), s: max(1, p / 2))
        c.rect(x - 5 * p, top + 18 * p, 10 * p, 24 * p, wood)                     // the trunk
        c.rect(x - 5 * p, top + 18 * p, p, 24 * p, lit); c.rect(x + 4 * p, top + 18 * p, p, 24 * p, dark)
        let w = k.win
        c.rect(w.x - p, w.y - p, w.w + 2 * p, w.h + 2 * p, brass)
        c.rect(w.x, w.y, w.w, w.h, C(0x1A0A04))
        c.rect(w.x + p, w.y + p, p, w.h / 2, C(0xFFFFFF, 0.12))
        c.rect(x - 7 * p, top + 42 * p, 14 * p, 12 * p, wood)                     // the base
        c.rect(x - 7 * p, top + 42 * p, 14 * p, p, lit); c.rect(x - 7 * p, top + 42 * p, p, 12 * p, lit)
        c.rect(x - 5 * p, top + 45 * p, 10 * p, 6 * p, dark); c.rect(x - 4 * p, top + 46 * p, 8 * p, 4 * p, wood)
        c.rect(x - 8 * p, g - 2 * p, 16 * p, 2 * p, dark)
    }

    /// The upper hall on a tall canvas: coffered ceiling, chandelier, ancestors' portraits and the gallery rail.
    static func wayneUpper(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let ceil = g / 9
        c.rect(0, 0, c.w, ceil, C(0x2A180C))
        for x in stride(from: 0, to: c.w, by: 30 * s) {
            c.rect(x + 3 * s, 3 * s, 24 * s, ceil - 6 * s, C(0x3A2214)); c.rect(x + 3 * s, 3 * s, 24 * s, s, C(0x1E1008))
            c.rect(x + 3 * s, ceil - 4 * s, 24 * s, s, C(0x5A3A22))
        }
        c.rect(0, ceil, c.w, 3 * s, C(0x8A6038)); c.rect(0, ceil + 3 * s, c.w, s, C(0x4A2E1A))
        // the gallery
        let gy = Int(Double(g) * 0.42)
        c.rect(0, gy, c.w, 8 * s, C(0x3A2214)); c.rect(0, gy, c.w, s, C(0x9A6E40)); c.rect(0, gy + 7 * s, c.w, s, C(0x1E1008))
        c.rect(0, gy - 12 * s, c.w, 2 * s, C(0x6A4428))
        for x in stride(from: 2 * s, to: c.w, by: 5 * s) {
            c.rect(x, gy - 10 * s, 2 * s, 10 * s, C(0x5A3A22)); c.rect(x, gy - 7 * s, 2 * s, 2 * s, C(0x7A5232))
        }
        // older Waynes along the upper wall
        let faces: [Px] = [C(0x2A2018), C(0x3A2A18), C(0x1A2028), C(0x2A1A20)]
        for (i, x) in stride(from: 22 * s, to: c.w - 20 * s, by: 46 * s).enumerated()
        where abs(x + 7 * s - Int(Double(c.w) * 0.6)) > 40 * s {
            let y = ceil + 14 * s
            c.rect(x - 2 * s, y - 2 * s, 18 * s, 24 * s, C(0xC8A048)); c.rect(x, y, 14 * s, 20 * s, C(0x2E2A1A))
            c.ellipse(x + 7 * s, y + 7 * s, 3 * s, 4 * s, C(0xC8A080)); c.rect(x + 4 * s, y + 3 * s, 6 * s, 2 * s, faces[i % 4])
            c.rect(x + 2 * s, y + 12 * s, 10 * s, 8 * s, faces[(i + 1) % 4]); c.rect(x + 6 * s, y + 12 * s, 2 * s, 3 * s, C(0xE8E4DC))
        }
        // the chandelier
        let cx = Int(Double(c.w) * 0.6), cy = g / 5
        c.rect(cx, ceil + 4 * s, s, cy - ceil - 8 * s, C(0x8A7040))
        c.circle(cx, cy - 2 * s, 12 * 3 * s, C(0xFFD890, 0.05))
        c.ellipse(cx, cy + 2 * s, 28 * s, 3 * s, C(0xA8884A)); c.ellipse(cx, cy + 2 * s, 26 * s, 2 * s, C(0x6A5030))
        c.ellipse(cx, cy + 6 * s, 6 * s, 4 * s, C(0xC8A050))
        for k in stride(from: -24, through: 24, by: 4) { c.rect(cx + k * s, cy + 4 * s, s, (2 + abs(k) % 3) * s, C(0xE8F0FF, 0.6)) }
        for p in wayneCandles(c, g) { c.rect(p.x, p.y + s, s, 3 * s, C(0xF0E8D0)) }
    }

    /// The fire flickering in the hearth and its glow on the rug, the pendulum swinging, and on a tall canvas the
    /// chandelier's candles.
    static func wayneManorLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), p = wayneScale(c, g), f = wayneFire(c, g), o = f.open
        let step = Int(t * 9)
        let fw = o.w - 6 * p
        for k in stride(from: 0, to: fw, by: s) {
            let u = Double(k) / Double(fw)
            let env = sin(u * Double.pi)
            let hgt = Int(Double(o.h - 5 * p) * env * (0.45 + 0.55 * noise(k * 7 + step * 13)))
            let x = o.x + 3 * p + k, b = g - 4 * p
            c.rect(x, b - hgt, s, hgt, C(0xC8381A))
            c.rect(x, b - hgt * 7 / 10, s, hgt * 7 / 10, C(0xF07A22))
            c.rect(x, b - hgt * 4 / 10, s, hgt * 4 / 10, C(0xFFD050))
        }
        let glow = 0.75 + 0.25 * noise(step * 3 + 900)
        c.ellipse(f.x, g + (c.h - g) / 2, 34 * p, max(2, (c.h - g) / 2), C(0xFF9A40, 0.10 * glow))
        c.ellipse(f.x, g - 10 * p, 30 * p, 14 * p, C(0xFF9A40, 0.05 * glow))
        // the pendulum: a swing every second
        let k = wayneClock(c, g), w = k.win
        let ang: Double = 0.28 * sin(t * Double.pi)
        let len = Double(w.h - 4 * p)
        let bx = w.x + w.w / 2 + Int(sin(ang) * len), by = w.y + p + Int(cos(ang) * len)
        s5Line(c, w.x + w.w / 2, w.y + p, bx, by, C(0xB8903A), s: max(1, p / 2))
        c.circle(bx, by, 2 * p, C(0xD8B050)); c.rect(bx - p, by - p, p, p, C(0xFFF0B0))
        if isTall(c) {
            for (i, q) in wayneCandles(c, g).enumerated() {
                let fl = noise(step * 5 + i * 3 + 910)
                c.rect(q.x, q.y - (fl > 0.5 ? 2 : 1) * s, s, (fl > 0.5 ? 2 : 1) * s, C(0xFFD060))
                c.circle(q.x, q.y - s, 3 * s, C(0xFFD890, 0.12 + 0.08 * fl))
            }
        }
    }
}

// MARK: - Legion of Super-Heroes HQ

extension Scenes {
    /// The rocket clubhouse: centre, body width and the row its nose cone tops out on.
    static func legionRocket(_ c: PixelCanvas, _ g: Int) -> (x: Int, w: Int, top: Int, nose: Int) {
        let s = unit(g), tall = isTall(c)
        let w = tall ? 44 * s : 22 * s, top = tall ? Int(Double(g) * 0.3) : 2 * s
        return (Int(Double(c.w) * 0.76), w, top, tall ? 44 * s : 13 * s)
    }

    /// The flying-car lanes: row, direction, pixel size and speed.
    static func legionLanes(_ c: PixelCanvas, _ g: Int) -> [(y: Int, dir: Int, p: Int, speed: Double)] {
        let s = unit(g)
        if isTall(c) {
            return (0..<6).map { (i: Int) -> (y: Int, dir: Int, p: Int, speed: Double) in
                let y = Int(Double(g) * (0.12 + Double(i) * 0.09))
                return (y, i % 2 == 0 ? 1 : -1, (i < 3 ? 1 : 2) * s, Double(20 + i * 7) * Double(s))
            }
        }
        return [(5 * s, 1, s, 22 * Double(s)), (11 * s, -1, s, 30 * Double(s)), (18 * s, 1, s, 38 * Double(s))]
    }

    /// The Legion of Super-Heroes' clubhouse in the 31st century: an old rocket ship stood on its fins in a plaza,
    /// silver and red with lit portholes and the Legion's emblem, in front of a gleaming future city at dusk: slim
    /// towers with saucer decks and glowing bands, skybridges, a ringed planet over the horizon.
    static func legionHQ(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c)
        c.gradient(0, g, C(0x10164A), C(0xC8708E), bands: tall ? 10 : 7)
        c.stars(0, g / 2, density: 90, seed: 101)
        let px = Int(Double(c.w) * 0.16), py = tall ? g / 5 : g / 4, pr = tall ? 22 * s : 8 * s
        c.ellipse(px, py, pr * 2 + pr / 2, max(1, pr / 4), C(0xE8C8F0, 0.35))
        c.circle(px, py, pr, C(0xB88AC8)); c.circle(px - pr / 3, py - pr / 3, pr / 2, C(0xD8B0E0))
        c.rect(px - pr, py - max(1, pr / 8), pr * 2, max(1, pr / 4), C(0xE8C8F0, 0.5))
        c.ellipse(px + pr * 2, py + pr, pr / 4 + s, pr / 4 + s, C(0xE0E4F0))
        if tall {
            for i in 0..<5 {
                wisp(c, Int(noise(i * 5 + 1010) * Double(c.w)), g / 3 + Int(noise(i * 5 + 1011) * Double(g / 4)),
                     (40 + Int(noise(i * 5 + 1012) * 50)) * s, C(0xE89AB0, 0.3), s: s)
            }
        }
        legionTowers(c, g, far: true)
        legionTowers(c, g, far: false)
        for k in 0..<3 { c.rect(0, g - (k + 1) * 6 * s, c.w, 6 * s, C(0x080A20, 0.14)) }
        legionRocketDraw(c, g)
        c.ground(g, C(0x262C48), edge: C(0x9AE8FF), speck: C(0x1E2440), seed: 101)
        for x in stride(from: 0, to: c.w, by: 20 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x323A5A)) }
        c.rect(0, g + (c.h - g) / 2, c.w, s, C(0x7AE0FF, 0.35))
    }

    /// A row of future towers: needles, saucer decks, glowing bands and skybridges.
    static func legionTowers(_ c: PixelCanvas, _ g: Int, far: Bool) {
        let s = unit(g), tall = isTall(c), r = legionRocket(c, g)
        let body = far ? C(0x5A5A9A) : C(0x22305E), edge = far ? C(0x9A9AD0) : C(0xC8ECFF)
        let band = far ? C(0xE8B8D8, 0.6) : C(0x7AE0FF), shade = far ? C(0x4A4A88) : C(0x18224A)
        var x = far ? -10 * s : 0, i = 0
        var prev: (x: Int, y: Int)? = nil
        while x < c.w {
            let tw = (far ? 8 + Int(noise(i * 7 + 1020) * 8) : 10 + Int(noise(i * 7 + 1030) * 12)) * s
            let lo: Double = far ? 0.4 : 0.22, hi: Double = far ? (tall ? 0.85 : 0.9) : (tall ? 0.6 : 0.7)
            let th = Int(Double(g) * (lo + noise(i * 7 + (far ? 1021 : 1031)) * (hi - lo)))
            let top = g - th
            if !far && abs(x + tw / 2 - r.x) < r.w { x += tw + 6 * s; i += 1; continue }
            c.rect(x, top, tw, th, body)
            c.rect(x + tw - tw / 3, top, tw / 3, th, shade)
            c.rect(x + s, top, s, th, edge)                          // the gleam down its sunlit edge
            for y in stride(from: top + 6 * s, to: g, by: (far ? 9 : 7) * s) { c.rect(x + 2 * s, y, tw - 3 * s, s, band.alpha(0.55)) }
            let kind = Int(noise(i * 7 + (far ? 1022 : 1032)) * 3)
            switch kind {
            case 0:                                                  // a needle spire
                c.rect(x + tw / 2 - s, top - 10 * s, 2 * s, 10 * s, body); c.rect(x + tw / 2 - s, top - 10 * s, s, 10 * s, edge)
                c.rect(x + tw / 2 - s, top - 12 * s, 2 * s, 2 * s, C(0xFF5A7A))
            case 1:                                                  // a saucer deck
                c.ellipse(x + tw / 2, top + 2 * s, tw / 2 + 5 * s, 2 * s, body)
                c.rect(x + tw / 2 - tw / 2 - 5 * s, top + 2 * s, tw + 10 * s, s, edge)
                c.rect(x + tw / 2 - tw / 2 - 3 * s, top + 3 * s, tw + 6 * s, s, band)
            default:                                                 // a glass dome
                c.ellipse(x + tw / 2, top, tw / 2, tw / 3, C(0x9AD8F0, far ? 0.4 : 0.6))
                c.rect(x + tw / 2 - tw / 4, top - tw / 4, s, s, C(0xFFFFFF, 0.7))
            }
            if !far {
                for (j, wy) in stride(from: top + 3 * s, to: g - 2 * s, by: 3 * s).enumerated() {
                    for (k, wx) in stride(from: x + 3 * s, to: x + tw - 2 * s, by: 3 * s).enumerated()
                    where noise(i * 41 + j * 7 + k * 3 + 1040) > 0.72 { c.rect(wx, wy, s, s, C(0xFFE8B0, 0.8)) }
                }
                if let p = prev, noise(i * 7 + 1033) > 0.4 {         // a skybridge to the last tower
                    let by = max(p.y, top) + 8 * s
                    if by < g - 12 * s { c.rect(p.x, by, x - p.x, 2 * s, C(0x3A4A7A)); c.rect(p.x, by, x - p.x, s, C(0x9AE8FF, 0.7)) }
                }
                prev = (x + tw, top)
            }
            x += tw + (far ? Int(noise(i * 7 + 1023) * 6) : 6 + Int(noise(i * 7 + 1034) * 14)) * s
            i += 1
        }
    }

    /// The rocket ship clubhouse, standing on its fins.
    static func legionRocketDraw(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), r = legionRocket(c, g), x0 = r.x - r.w / 2
        let bodyTop = r.top + r.nose
        let red = C(0xC8282E)
        func metal(_ k: Int) -> Px {
            let d = abs(Double(k) - Double(r.w) * 0.3) / Double(r.w)
            return lerp(C(0xF4F6FA), C(0x5A6478), min(1, d * 1.5))
        }
        // fins behind the body
        let finH = r.w * 6 / 5, finW = r.w * 2 / 3
        s5Poly(c, [(Double(x0 + s), Double(g - finH)), (Double(x0 - finW), Double(g)), (Double(x0 + s), Double(g))], C(0xA81E26))
        s5Poly(c, [(Double(x0 + r.w - s), Double(g - finH)), (Double(x0 + r.w + finW), Double(g)), (Double(x0 + r.w - s), Double(g))], C(0x7A141A))
        c.rect(x0 - finW, g - s, finW, s, C(0xE85A60))
        for k in 0..<r.w { c.rect(x0 + k, bodyTop, 1, g - bodyTop, metal(k)) }
        for k in 0..<r.nose {                                       // the nose cone
            let f = Double(k + 1) / Double(r.nose)
            let half = Int(Double(r.w) / 2 * f.squareRoot())
            let y = r.top + k
            for j in -half..<half {
                let col = k < r.nose / 3 ? lerp(C(0xF06068), C(0x7A141A), abs(Double(j) / Double(max(1, half)) - (-0.4)) * 0.8)
                    : metal(r.w / 2 + j * r.w / max(1, 2 * half))
                c.px(r.x + j, y, col)
            }
        }
        for f in [0.12, 0.62] as [Double] {                         // red bands
            let y = bodyTop + Int(Double(g - bodyTop) * f)
            for k in 0..<r.w { c.rect(x0 + k, y, 1, 3 * s, lerp(red, C(0x4A0A0E), Double(k) / Double(r.w) * 0.8)) }
        }
        // portholes
        let pr = max(1, r.w / 9)
        for y in stride(from: bodyTop + Int(Double(g - bodyTop) * 0.22), to: bodyTop + Int(Double(g - bodyTop) * 0.58), by: pr * 4) {
            c.circle(r.x - r.w / 6, y, pr + s, C(0x6A7488)); c.circle(r.x - r.w / 6, y, pr, C(0xFFE08A))
        }
        // the Legion emblem
        let ey = bodyTop + Int(Double(g - bodyTop) * 0.4), er = max(3 * s, r.w / 5)
        c.circle(r.x + r.w / 6, ey, er + s, C(0x2A3A7A)); c.circle(r.x + r.w / 6, ey, er, C(0xF4F4F8))
        let lu = max(1, er / 3)
        c.rect(r.x + r.w / 6 - lu, ey - er + lu, lu, er * 2 - 2 * lu, C(0x2A3A7A))
        c.rect(r.x + r.w / 6 - lu, ey + er - 2 * lu, lu * 3, lu, C(0x2A3A7A))
        // the front fin, and the door between the fins
        c.rect(r.x - r.w / 10, g - finH, r.w / 5, finH, C(0xC8282E)); c.rect(r.x - r.w / 10, g - finH, s, finH, C(0xF06068))
        let dw = r.w / 4, dh = r.w / 3
        c.rect(x0 + r.w / 8, g - dh, dw, dh, C(0xFFE8B0)); c.rect(x0 + r.w / 8, g - dh, dw, s, C(0x5A6478))
        c.rect(x0 + r.w / 8 + dw / 3, g - dh / 2, s, s, C(0x5A6478))
    }

    /// Flying cars streaming along their lanes, trailing light, and the beacon on the rocket's nose.
    static func legionTraffic(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), r = legionRocket(c, g)
        let bodies: [Px] = [C(0xE84A5A), C(0xF0C040), C(0x4AB8E8), C(0xE8E8F0), C(0x8A5AE8), C(0x4AE89A)]
        for (li, lane) in legionLanes(c, g).enumerated() {
            let p = lane.p, span = Double(c.w + 30 * p)
            let count = max(2, c.w / (60 * s))
            for i in 0..<count {
                let base = noise(li * 37 + i * 5 + 1050) * span
                var xf = (base + Double(lane.dir) * t * lane.speed * (0.8 + noise(li * 37 + i * 5 + 1051) * 0.4))
                    .truncatingRemainder(dividingBy: span)
                if xf < 0 { xf += span }
                let x = Int(xf) - 15 * p, y = lane.y + Int(sin(t * 2 + Double(i)) * Double(p) * 0.6)
                let col = bodies[(li * 3 + i) % bodies.count]
                let rows: [String] = lane.dir > 0 ? ["..ccc..", "bbbbbbh", ".kkkkk."] : ["..ccc..", "hbbbbbb", ".kkkkk."]
                s5Stamp(c, x, y, rows, ["c": C(0xAEEBFF, 0.85), "b": col, "h": C(0xFFFFE0), "k": C(0x2A2E44)], s: p)
                let tail = lane.dir > 0 ? x - 6 * p : x + 7 * p
                c.rect(tail, y + p, 6 * p, p, C(0xFF5A6A, 0.25))
                c.rect(lane.dir > 0 ? x - p : x + 7 * p, y + p, p, p, C(0xFF4A5A))
            }
        }
        if s5Phase(t, 1.4) < 0.25 {
            c.rect(r.x - s, r.top - 2 * s, 2 * s, 2 * s, C(0xFF5A5A))
            c.circle(r.x, r.top - s, 3 * s, C(0xFF5A5A, 0.3))
        }
    }
}
