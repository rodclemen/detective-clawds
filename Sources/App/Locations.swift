import AppKit

// Window-mode backdrops: one DC location per character, drawn as pixel art in code.
// The first-spawned Claude decides where the crew is (or pick one from the Location menu).
// Every scene gets a canvas of w×h pixels whose bottom `floorRows` rows are the ground the crew stands on.
//
// Each place is a `Place` registered in one of the Scenes*.swift files: its name, the tint of the window's card
// area, the still picture and (optionally) what moves there. Who lives where is `Location.home(of:)` in Roster.swift.

enum Location: String, CaseIterable {
    case metropolis, gotham, batcave, fortressOfSolitude, themyscira, atlantis, watchtower, hallOfJustice, arkham
    case centralCity, starCity, oa, apokolips, krypton, titansTower, smallville, strykersIsland, belleReve
    case nandaParbat, houseOfMystery, rockOfEternity, newGenesis, thanagar, kandor, phantomZone, kahndaq, ironHeights
    case speedForce, wayneManor, legionHQ, aceChemicals, lexCorp, bayou, theDreaming, coastCity, gorillaCity
    case korugar, warworld, bludhaven, jsaHQ, fawcettCity, starLabs, hallOfDoom

    var place: Place { places[self] ?? Place(name: rawValue, panel: 0x16181D, still: { _, _ in }) }

    var name: String { place.name }

    /// Background tint for the card area, so the whole window feels like the place.
    var panel: NSColor {
        let hex = place.panel
        return NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                       blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }

    /// The parts of the scene that never move (cached per window size).
    func drawStatic(_ c: PixelCanvas, floorRows f: Int) {
        guard c.w > 0, c.h > f, f >= 0 else { return }
        place.still(c, c.h - f)
    }

    /// Whether `drawAnimated` draws anything here (the rest are still pictures, with no per-frame layer).
    var hasAnimatedLayer: Bool { place.moving != nil }

    /// `hasAnimatedLayer` for a canvas `rows` tall.
    func animates(rows: Int) -> Bool { hasAnimatedLayer }

    /// The moving bits, drawn every frame on a transparent canvas of the same size.
    func drawAnimated(_ c: PixelCanvas, floorRows f: Int, t: Double) {
        guard let moving = place.moving, c.w > 0, c.h > f, f >= 0 else { return }
        moving(c, c.h - f, t)
    }
}

/// One location: what it's called and how it's drawn.
struct Place {
    let name: String
    /// The window's card area under the scene, as 0xRRGGBB: a dark tint of the place.
    let panel: UInt32
    /// The still picture: canvas and ground row `g` (the crew's feet stand on row `g`; rows below are floor).
    let still: (PixelCanvas, Int) -> Void
    /// What moves there, drawn every frame on a transparent canvas the same size: canvas, ground row, clock.
    var moving: ((PixelCanvas, Int, Double) -> Void)? = nil
}

/// Every place, from the Scenes*.swift files.
let places: [Location: Place] = scenes1.merging(scenes2) { a, _ in a }.merging(scenes3) { a, _ in a }
    .merging(scenes4) { a, _ in a }.merging(scenes5) { a, _ in a }.merging(scenes6) { a, _ in a }.merging(scenes7) { a, _ in a }


/// The wipes between places, shared by the window and the screen saver: what's left of the old
/// picture `k` of the way through, right of an edge sweeping left to right, or what a clock hand sweeping round from
/// twelve hasn't reached yet.
enum Wipe {
    static let duration = 1.2

    static func remaining(_ k: Double, clock: Bool, in r: CGRect) -> CGPath {
        let path = CGMutablePath()
        if clock {
            let c = CGPoint(x: r.midX, y: r.midY), top = CGFloat.pi / 2
            path.move(to: c)
            path.addArc(center: c, radius: hypot(r.width, r.height), startAngle: top - 2 * .pi * k,
                        endAngle: top - 2 * .pi, clockwise: true)
            path.closeSubpath()
        } else {
            path.addRect(CGRect(x: r.minX + r.width * k, y: r.minY, width: r.width * (1 - k), height: r.height))
        }
        return path
    }

    /// One picture from several stacked (the place and what moves there), to freeze for a wipe.
    static func flatten(_ images: [CGImage]) -> CGImage? {
        guard let first = images.first else { return nil }
        let w = first.width, h = first.height
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        for img in images { ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h)) }
        return ctx.makeImage()
    }
}


// MARK: - Drawing helpers

func lerp(_ a: Px, _ b: Px, _ t: Double) -> Px {
    let k = max(0, min(1, t))
    return Px(r: UInt8(Double(a.r) + (Double(b.r) - Double(a.r)) * k), g: UInt8(Double(a.g) + (Double(b.g) - Double(a.g)) * k),
              b: UInt8(Double(a.b) + (Double(b.b) - Double(a.b)) * k), a: UInt8(Double(a.a) + (Double(b.a) - Double(a.a)) * k))
}

extension PixelCanvas {
    /// Vertical gradient from row y0 (top colour) to y1 (bottom colour), quantised into bands like old pixel art.
    func gradient(_ y0: Int, _ y1: Int, _ top: Px, _ bottom: Px, bands: Int = 6) {
        guard y1 > y0 else { return }
        for y in y0..<y1 {
            let k = (Double(y - y0) / Double(y1 - y0) * Double(bands)).rounded(.down) / Double(bands)
            rect(0, y, w, 1, lerp(top, bottom, k))
        }
    }

    func circle(_ cx: Int, _ cy: Int, _ r: Int, _ col: Px) {
        guard r > 0 else { px(cx, cy, col); return }
        for dy in -r...r {
            let half = Int((Double(r * r - dy * dy)).squareRoot().rounded())
            rect(cx - half, cy + dy, half * 2 + 1, 1, col)
        }
    }

    func ellipse(_ cx: Int, _ cy: Int, _ rx: Int, _ ry: Int, _ col: Px) {
        guard rx > 0, ry > 0 else { return }
        for dy in -ry...ry {
            let k = 1 - Double(dy * dy) / Double(ry * ry)
            let half = Int((Double(rx) * k.squareRoot()).rounded())
            rect(cx - half, cy + dy, half * 2 + 1, 1, col)
        }
    }

    /// Stars scattered over a box, or only the part of it `inside` says is open sky (a round window).
    func stars(_ y0: Int, _ y1: Int, density: Int = 40, seed: Int = 0, x0: Int = 0, x1: Int? = nil,
               inside: ((Int, Int) -> Bool)? = nil) {
        let xe = x1 ?? w
        guard y1 > y0, xe > x0 else { return }
        for i in 0..<((xe - x0) * (y1 - y0) / density) {
            let x = x0 + Int(noise(i * 3 + seed * 1000) * Double(xe - x0))
            let y = y0 + Int(noise(i * 3 + 1 + seed * 1000) * Double(y1 - y0))
            if let inside, !inside(x, y) { continue }
            px(x, y, white.alpha(noise(i * 3 + 2 + seed * 1000) > 0.8 ? 0.95 : 0.5))
        }
    }

    /// Rolling dunes or hills: fills from a wavy line down to `bottom`.
    func dunes(base: Int, amp: Double, freq: Double, phase: Double, bottom: Int, _ col: Px, shade: Px? = nil) {
        for x in 0..<w {
            let top = base - Int((sin(Double(x) * freq + phase) * 0.6 + sin(Double(x) * freq * 2.3 + phase * 1.7) * 0.4) * amp)
            if top < bottom { rect(x, top, 1, bottom - top, col) }
            if let shade, top < bottom { px(x, top, shade) }
        }
    }

    /// Ground strip with a highlighted edge and speckles.
    func ground(_ g: Int, _ col: Px, edge: Px, speck: Px, seed: Int = 0) {
        rect(0, g, w, h - g, col)
        rect(0, g, w, 1, edge)
        for i in 0..<(w * (h - g) / 6) {
            px(Int(noise(i * 11 + 3 + seed) * Double(w)), g + 1 + Int(noise(i * 11 + 4 + seed) * Double(max(1, h - g - 1))), speck)
        }
    }
}


// MARK: - Shared scene helpers

enum Scenes {
    /// Pixel size of the backdrop on screen: matches the crew's pixels at the window's Small size.
    static let pixel: CGFloat = 2

    /// A plain sky and floor for a place that isn't drawn yet.
    static func standIn(_ c: PixelCanvas, _ g: Int) {
        c.gradient(0, g, C(0x1A2034), C(0x3A4466))
        c.ground(g, C(0x2A2E38), edge: C(0x5A6070), speck: C(0x22262E))
    }
}

// The screensaver draws each place full screen, several times taller than the window's strip, which would leave the
// upper part bare. Scenes fill it with more of the same place, in the same palette, when `isTall` says so. The
// window's strip is never `tallRows` rows tall.
extension Scenes {
    static let tallRows = 140
    static func isTall(_ c: PixelCanvas) -> Bool { c.h >= tallRows }
    /// Whole-pixel size of one unit of the extras: 1, growing on very tall canvases so they keep their size on screen.
    static func unit(_ g: Int) -> Int { max(1, (g + 60) / 300) }

    /// Draws in units of `s` pixels from an origin.
    struct Pen {
        let c: PixelCanvas, x: Int, y: Int, s: Int
        init(_ c: PixelCanvas, _ x: Int, _ y: Int, _ g: Int) { self.c = c; self.x = x; self.y = y; s = Scenes.unit(g) }
        func rect(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, y + v * s, w * s, h * s, col) }
        func ellipse(_ u: Int, _ v: Int, _ rx: Int, _ ry: Int, _ col: Px) { c.ellipse(x + u * s, y + v * s, rx * s, ry * s, col) }
        func circle(_ u: Int, _ v: Int, _ r: Int, _ col: Px) { c.circle(x + u * s, y + v * s, r * s, col) }
    }

    /// A soft fair-weather cloud: a shaded flat base under a few puffs.
    static func cloud(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, seed: Int, top: Px = C(0xF6F9FC), base: Px = C(0xDDE9F3)) {
        c.ellipse(x, y + r / 2, r * 3, max(1, r / 2), base)
        for k in 0..<4 {
            let dx = Int((noise(seed * 7 + k) - 0.5) * Double(r * 4)), rr = r * (2 + k % 2) / 3 + 1
            c.ellipse(x + dx, y - rr / 3, rr * 3 / 2, rr, top)
        }
    }

    /// A thin streak of high cloud, `len` pixels long.
    static func wisp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ len: Int, _ col: Px, s: Int) {
        c.rect(x - len / 2, y, len, s, col)
        c.rect(x - len / 3, y - s, len / 2, s, col.alpha(0.7))
        c.rect(x - len / 6, y + s, len / 2, s, col.alpha(0.6))
    }

    /// A flat-topped mesa with sloping flanks, `h` rows tall, standing on row `base`.
    static func mesa(_ c: PixelCanvas, x: Int, width: Int, h: Int, base: Int, _ col: Px, seed: Int) {
        let flankW = max(1, width / 5)
        for k in 0..<width {
            let flank = max(0, max(flankW - k, k - (width - flankW))) * h / (flankW * 2)
            let top = base - h + flank + Int(noise(k + seed * 31) * 2)
            if top < base { c.rect(x + k, top, 1, base - top, col) }
        }
    }

}
