import Foundation

// The ships that come to pick someone up when their agent is done (`Cast.ride`): the Javelin for the Justice League,
// the Batwing for the Bat-family. Drawn nose to the right on a `Ride.width`×`Ride.height` canvas, sitting on its bottom
// row when landed; the boarding ramp comes down to the left of centre, its foot about 14 px left of the middle.

extension Ride {
    static let width = 66, height = 29
}

/// `ramp` 0…1 lowers the boarding ramp, `engines` lights the thrusters, `gear`: landing gear down.
func drawRide(_ c: PixelCanvas, _ ride: Ride, ramp: Double, engines: Bool, gear: Bool) {
    switch ride {
    case .javelin: drawJavelin(c, ramp: ramp, engines: engines, gear: gear)
    case .batwing: drawBatwing(c, ramp: ramp, engines: engines, gear: gear)
    }
}

/// The hull's outline at column `x`, read off a polyline of (x, y) points (straight between them).
private func profile(_ x: Int, _ pts: [(Double, Double)]) -> Int {
    let fx = Double(x)
    for i in 1..<pts.count where fx <= pts[i].0 {
        let (a, b) = (pts[i - 1], pts[i])
        return Int((a.1 + (b.1 - a.1) * (fx - a.0) / (b.0 - a.0)).rounded())
    }
    return Int(pts[pts.count - 1].1.rounded())
}

/// A hull filled column by column between the `top` and `bottom` outlines, lit along its spine and shaded
/// along its belly.
private func hull(_ c: PixelCanvas, x0: Int, x1: Int, top: [(Double, Double)], bottom: [(Double, Double)],
                  body: Px, light: Px, dark: Px) {
    for x in x0...x1 {
        let t = profile(x, top), b = profile(x, bottom)
        guard b >= t else { continue }
        c.rect(x, t, 1, b - t + 1, body)
        c.px(x, t, light)
        c.px(x, b, dark)
        if b - t > 4 { c.px(x, b - 1, dark) }
    }
}

/// The boarding ramp, hinged under the hull at (`hx`, `hy`) and swinging down to its foot on the ground about 14 px
/// left of centre; a warm light spills from the hold behind it.
private func drawRamp(_ c: PixelCanvas, ramp: Double, hx: Double, hy: Double, plate: Px, edge: Px) {
    guard ramp > 0 else { return }
    let foot = (x: 19.0, y: 27.5)
    let closed = atan2(0.0, -1.0), open = atan2(foot.y - hy, foot.x - hx)
    let a = closed + (open - closed) * ramp, len = hypot(foot.x - hx, foot.y - hy)
    let tip = (x: hx + cos(a) * len, y: hy + sin(a) * len)
    c.rect(Int(tip.x) + 1, Int(hy) - 3, Int(hx - tip.x) - 1, 3, C(0xFFD890, 0.35 + 0.5 * ramp))   // the lit hold
    c.glowLine(hx, hy, tip.x, tip.y, core: plate, glow: C(0x000000, 0), coreR: 1, glowR: 1.1)
    c.glowLine(hx, hy - 0.6, tip.x, tip.y - 0.6, core: edge, glow: C(0x000000, 0), coreR: 0.35, glowR: 0.4)
}

/// Landing legs with wide feet, standing on the bottom row.
private func drawGear(_ c: PixelCanvas, xs: [Int], from y: Int, strut: Px, foot: Px) {
    for x in xs {
        c.rect(x, y, 1, 27 - y, strut)
        c.rect(x - 1, 27, 3, 1, foot); c.rect(x - 2, 28, 5, 1, foot)
    }
}


/// The Justice League's Javelin (the animated series): a sleek silver-grey and white wedge with a big canopy over the
/// nose, angular swept wings with red leading edges, a blue stripe down the flank, a tall swept tail fin with the JL
/// emblem, and blue thrusters.
private func drawJavelin(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool) {
    let body = C(0xB8BEC8), light = C(0xF2F4F8), dark = C(0x6A727E), panel = C(0x8E96A2), white = C(0xFFFFFF)
    let red = C(0xC8202A), blue = C(0x2A5CC8), glass = C(0x16243C)
    let top: [(Double, Double)] = [(3, 15), (10, 13), (40, 12), (56, 15), (65, 19)]
    if gear { drawGear(c, xs: [13, 50], from: 22, strut: dark, foot: panel) }
    // The far wing, behind: its swept tip shows above the hull
    for k in 0...4 {
        let l = 22 - k * 3, r = 34 - k * 4
        c.rect(l, 13 - k, r - l + 1, 1, panel)
        c.px(r, 13 - k, red); c.px(l, 13 - k, dark)
    }
    hull(c, x0: 3, x1: 65, top: top, bottom: [(3, 20), (8, 23), (52, 23), (60, 21), (65, 19)],
         body: body, light: light, dark: dark)
    // The tail fin, swept back, white on its leading edge, with the JL emblem
    for y in 1...13 {
        let f = Double(y - 1) / 12
        let l = Int(3 + f * 2), r = Int(8 + f * 12)
        c.rect(l, y, r - l + 1, 1, body)
        c.px(r, y, light); c.px(l, y, dark)
    }
    c.pattern(5, 6, [
        "RRRRRRR",
        "RBWBWBR",
        "RBWBWBR",
        "RWWBWWR",
        "RRRRRRR",
    ], ["R": red, "B": blue, "W": white])
    // A blue stripe down the flank, and red on the canopy sill and the nose tip
    c.rect(6, 17, 52, 1, blue)
    for x in 41...61 { c.px(x, profile(x, top) + 2, red) }
    c.rect(63, 18, 3, 1, red)
    // The big canopy bubbling up over the nose, with a white frame and a sky glint
    let canopy: [(Double, Double)] = [(40, 12), (44, 9), (52, 9), (61, 17)]
    for x in 41...59 {
        let t = profile(x, canopy), b = profile(x, top) + 1
        guard b >= t else { continue }
        c.rect(x, t, 1, b - t + 1, glass)
        c.px(x, t, light)
    }
    for x in 45...50 { c.px(x, 10, C(0x8AC8F0)) }
    c.px(52, 11, C(0x8AC8F0)); c.px(53, 12, C(0x8AC8F0))
    // The near wing: an angular swept plate, red on its leading edge
    for y in 18...23 {
        let f = Double(y - 18) / 5
        let l = Int(30 - f * 18), r = Int(48 - f * 30)
        c.rect(l, y, r - l + 1, 1, y == 18 ? light : C(0xD8DCE2))
        c.px(l, y, dark)
    }
    c.glowLine(48.5, 18.5, 18.5, 23.5, core: red, glow: C(0x000000, 0), coreR: 0.6, glowR: 0.7)
    for x in stride(from: 16, through: 40, by: 8) { c.px(x, 15, panel) }    // hull panel seams
    drawRamp(c, ramp: ramp, hx: 33, hy: 23, plate: panel, edge: light)
    if engines {
        c.rect(0, 14, 3, 6, C(0x6FB8FF)); c.rect(0, 15, 2, 4, C(0xBFE0FF))
    } else {
        c.rect(2, 15, 1, 5, dark)
    }
}

/// The Batwing: a black jet with a bat-wing silhouette raised over the hull, scalloped along its trailing edge between
/// the bones, a yellow-on-black bat emblem on the wing, a slit canopy, and amber jets with a blue core.
private func drawBatwing(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool) {
    let body = C(0x26282F), light = C(0x4A4F5C), dark = C(0x121317), wing = C(0x2C2F38), bone = C(0x464B58)
    let yellow = C(0xF2C230), steel = C(0x7A808C)
    let top: [(Double, Double)] = [(4, 17), (14, 15), (40, 14), (52, 15), (60, 17), (65, 19)]
    if gear { drawGear(c, xs: [14, 50], from: 22, strut: dark, foot: steel) }
    // The bat wing: leading edge sweeping up and back from the hull to a hooked tip, the trailing edge cut into
    // scallops between the bones
    let lead: [(Double, Double)] = [(0, 0), (8, 1), (24, 4), (40, 9), (50, 15)]
    let base: [(Double, Double)] = [(1, 1), (19, 17)]
    let points: [Int] = [1, 7, 13, 19]                          // where the bones meet the trailing edge
    for x in 0...50 {
        let t = profile(x, lead)
        var b = profile(x, base)
        if x < 1 {
            b = t
        } else if x < 19 {
            let i = min(2, (x - 1) / 6), u = Double(x - points[i]) / Double(points[i + 1] - points[i])
            b -= Int((sin(u * Double.pi) * (i == 0 ? 2.2 : 4.4)).rounded())
        } else {
            b = 17
        }
        guard b >= t else { continue }
        c.rect(x, t, 1, b - t + 1, wing)
        c.px(x, t, light)
    }
    // The bones, from the wing root out to each point of the trailing edge
    for p in points.dropFirst().dropLast() {
        c.glowLine(38, 12, Double(p) + 0.5, Double(profile(p, base)) + 0.2, core: bone, glow: C(0x000000, 0),
                   coreR: 0.45, glowR: 0.5)
    }
    hull(c, x0: 4, x1: 65, top: top, bottom: [(4, 21), (9, 23), (50, 23), (58, 22), (65, 20)],
         body: body, light: light, dark: dark)
    // The bat emblem on the wing: a black bat in a yellow oval
    c.pattern(19, 5, [
        "..YYYYYYY..",
        ".YKYYKYKYY.",
        "YKKKKKKKKKY",
        ".YYKKYKKYY.",
        "..YYYYYYY..",
    ], ["Y": yellow, "K": dark])
    // Slit canopy with a blue glint, and a yellow pinstripe along the flank
    for x in 46...57 { c.px(x, profile(x, top) + 1, C(0x10161E)) }
    for x in 48...52 { c.px(x, profile(x, top) + 1, C(0x4A90D8)) }
    for x in 8...60 { c.px(x, max(profile(x, top) + 4, 18), x % 6 == 0 ? body : C(0x30333C)) }
    c.rect(62, 19, 3, 1, yellow)
    drawRamp(c, ramp: ramp, hx: 33, hy: 23, plate: dark, edge: yellow)
    if engines {
        c.rect(0, 16, 4, 5, C(0xFFA030)); c.rect(0, 17, 3, 3, C(0xFFE0A0)); c.rect(3, 18, 1, 1, C(0x6FB8FF))
        c.rect(24, 24, 14, 1, C(0x6FB8FF, 0.7))                       // the belly jets' blue downwash
    } else {
        c.rect(3, 17, 1, 4, dark)
    }
}
