import Foundation

// Villains: Apokolips and the cosmic tyrants.

let villains4: [Leader: Persona] = [
    .darkseid: Persona(name: "Darkseid", weapon: .ranged, shot: .beam(core: C(0xFFE0D0), glow: C(0xFF2A1E)), armoured: true,
                  canSit: false, muzzle: darkseidEyes, handGun: false, bulk: 5, headTop: 0, signature: 3.4,
                  callout: "I am the darkness.",
                  draw: drawDarkseid),
    .steppenwolf: Persona(name: "Steppenwolf", weapon: .melee, armoured: true, headTop: 10, signature: 2.8,
                  callout: "For Darkseid!",
                  draw: drawSteppenwolf),
    .desaad: Persona(name: "DeSaad", weapon: .magic, magic: Magic(core: C(0xF0E0FF), glow: C(0x8A4AD8), jagged: false),
                  pivot: (41.5, 32.5), headTop: 17, signature: 2.8, callout: "Such exquisite agony.",
                  draw: drawDesaad),
    .grannyGoodness: Persona(name: "Granny Goodness", weapon: .melee, headTop: 15, signature: 2.8,
                  callout: "Granny knows best, dearie.",
                  draw: drawGrannyGoodness),
    .kalibak: Persona(name: "Kalibak", weapon: .melee, canSit: false, pivot: kalibakShoulder, bulk: 7, headTop: 1,
                  signature: 3.0, callout: "Kalibak crushes!",
                  draw: drawKalibak),
    .parademon: Persona(name: "Parademon", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xFFF0D0), glow: C(0xFF8A1E)),
                  muzzle: (54, 33), headTop: 14, signature: 2.4,
                  draw: drawParademon),
    .lobo: Persona(name: "Lobo", weapon: .melee, headTop: 19, signature: 3.0, callout: "Frag!",
                  draw: drawLobo),
    .mongul: Persona(name: "Mongul", weapon: .melee, canSit: false, pivot: mongulShoulder, bulk: 6, headTop: 1,
                  signature: 3.2, callout: "You will fight for my amusement.",
                  draw: drawMongul),
    .trigon: Persona(name: "Trigon", weapon: .magic, magic: Magic(core: C(0xFFE0D0), glow: C(0xFF3A1E), jagged: false),
                  canSit: false, pivot: trigonPalm, bulk: 6, headTop: 0, signature: 3.2, callout: "Kneel before Trigon!",
                  draw: drawTrigon),
    .antiMonitor: Persona(name: "Anti-Monitor", weapon: .magic, motion: .hover, magic: Magic(core: C(0xFFF0F0), glow: C(0xE83A3A)),
                  armoured: true, canSit: false, pivot: antiMonitorPalm, bulk: 5, headTop: 1, signature: 3.2,
                  callout: "Worlds will die.",
                  draw: drawAntiMonitor),
]

// MARK: - Shared bits

private let clear = C(0, 0)

/// A solid round-ended stroke: limbs, shafts, horns.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.05)
}

/// A thick limb from `s` at `angle` degrees, `len` long and `r` thick. Returns where it ends.
@discardableResult
private func limb(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ angle: Double, len: Double, r: Double,
                  _ col: Px) -> (x: Double, y: Double) {
    let a = angle * .pi / 180
    let e = (x: s.x + cos(a) * len, y: s.y + sin(a) * len)
    bar(c, s.x, s.y, e.x, e.y, col, r: r)
    return e
}

/// The smear a fast swing leaves behind: faint strokes at the earlier angles, from `inner` to `len` out of `s`.
private func smear(_ c: PixelCanvas, _ s: (x: Double, y: Double), _ trail: [Double], len: Double, _ col: Px,
                   inner: Double = 0.4) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(s.x + cos(r) * len * inner, s.y + sin(r) * len * inner, s.x + cos(r) * len, s.y + sin(r) * len,
                   core: col, glow: col, coreR: 0.6, glowR: 2, strength: 0.35 / Double(i + 1))
    }
}

/// A puff of smoke or dust at (`x`, `y`), `k` 0…1 through its life: it swells and fades.
private func puff(_ c: PixelCanvas, x: Double, y: Double, k: Double, _ col: Px) {
    guard k > 0, k < 1 else { return }
    let r = Int((1 + k * 2.5).rounded())
    c.circle(Int(x.rounded()), Int(y.rounded()), r, col.alpha(0.65 * (1 - k)))
}

/// An oval of pixels round (`x`, `y`), `rx` wide and `ry` tall: a shock wave, a smoke ring.
private func ring(_ c: PixelCanvas, _ x: Double, _ y: Double, rx: Double, ry: Double, _ col: Px) {
    let n = max(10, Int(max(rx, ry) * 6))
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        c.px(Int((x + cos(a) * rx).rounded(.down)), Int((y + sin(a) * ry).rounded(.down)), col)
    }
}

/// A glowing dot: eyes, gems, embers.
private func glowDot(_ c: PixelCanvas, _ x: Double, _ y: Double, core: Px, glow: Px, coreR: Double = 0.5, glowR: Double = 1.8,
                     strength: Double = 1) {
    c.glowLine(x, y, x, y, core: core, glow: glow, coreR: coreR, glowR: glowR, strength: strength)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`, leaning forward one pixel every
/// `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, lean: Int = 0, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
            let m = 255 / Double(a)
            c.px(x + shift, y, Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
                                  b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a))
        }
    }
}

/// A point on the cubic curve through the four control points `q`, `u` 0…1 along it.
private func cubic(_ q: [(x: Double, y: Double)], _ u: Double) -> (x: Double, y: Double) {
    let v = 1 - u
    let a = v * v * v, b = 3 * v * v * u, d = 3 * v * u * u, e = u * u * u
    return (a * q[0].x + b * q[1].x + d * q[2].x + e * q[3].x, a * q[0].y + b * q[1].y + d * q[2].y + e * q[3].y)
}

// MARK: - Darkseid

/// Where Darkseid's Omega Beams leave his eyes.
private let darkseidEyes = (x: 37.0, y: 7.0)

/// Darkseid: the lord of Apokolips as a towering Clawd, the craggy grey stone head with its ridged brow, deep cheek
/// grooves and red-lit eyes, a blue tunic over grey stone arms, a navy belt and skirt, navy gloves and boots. He stands
/// with his hands clasped behind his back and fires the Omega Beams from his eyes. Signature: his eyes ignite and two
/// Omega Beams snake out, curl through the air and strike the ground in front of him.
private func drawDarkseid(_ c: PixelCanvas, _ p: Pose) {
    let stone = C(0x8E8B86), stoneDark = C(0x64615D), stoneLight = C(0xB6B2AC), crack = C(0x46443F)
    let blue = C(0x34479A), blueDark = C(0x232F6C), blueLight = C(0x5A6CC4)
    let navy = C(0x1A1E36), navyLight = C(0x343A5E)
    let red = C(0xFF2A1E), hot = C(0xFFE0D0)
    for (i, lx) in [19, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 30, 7, 8, blueDark); c.rect(lx, 30, 1, 8, blue)
        c.rect(lx - 1, 37 - up, 9, 7, navy)                                // boots
        c.rect(lx - 1, 37 - up, 9, 1, navyLight); c.rect(lx + 7, 37 - up, 1, 7, C(0x10121F))
    }
    c.oy += p.breathe
    var glow: Double = p.fire != nil ? 0.75 + 0.25 * Double(p.recoil) : (p.ready ? 0.35 : 0)
    if let s = p.signature { glow = habitArc(s, hold: 0.7) }

    // The far arm: elbow out, the hand clasped behind his back.
    c.rect(11, 14, 5, 11, stoneDark); c.rect(11, 14, 1, 11, stone)
    c.rect(12, 24, 6, 4, navy)
    // The tunic.
    c.rect(15, 12, 26, 19, blue)
    c.rect(15, 12, 2, 19, blueLight); c.rect(39, 12, 2, 19, blueDark)
    c.rect(20, 12, 17, 2, blueDark)                                        // the neckline
    for x in [21, 35] { c.rect(x, 15, 1, 11, blueDark) }                   // the tunic's panels
    c.rect(15, 26, 26, 4, navy); c.rect(15, 26, 26, 1, navyLight)          // belt…
    for x in stride(from: 17, to: 40, by: 4) { c.rect(x, 27, 2, 2, stoneDark); c.px(x, 27, stoneLight) }   // …with its studs
    c.rect(16, 30, 24, 4, blue)                                            // the skirt over his legs
    for x in [22, 28, 34] { c.rect(x, 30, 1, 4, blueDark) }
    c.rect(16, 33, 24, 1, blueDark)
    // Shoulders.
    c.pattern(11, 10, [".BBBBBBB.", "BBLLBBBBB", "BBBBBBBBB", "BBBBBBBBB"], ["B": blue, "L": blueLight])

    // The stone head.
    c.pattern(16, 0, [
        "...SSSSSSSSSSSSSSSSSS...",
        ".SSSSSSSSSSSSSSSSSSSSSS.",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSSSSSSSSS",
        ".SSSSSSSSSSSSSSSSSSSSSS.",
        ".SSSSSSSSSSSSSSSSSSSSSS.",
        "..SSSSSSSSSSSSSSSSSSSS..",
        "....SSSSSSSSSSSSSSSS....",
    ], ["S": stone])
    c.rect(16, 3, 1, 8, stoneLight); c.rect(17, 1, 2, 2, stoneLight)
    c.rect(39, 3, 1, 8, stoneDark); c.rect(38, 11, 1, 2, stoneDark); c.rect(20, 14, 16, 1, stoneDark)
    for k in 0..<18 {                                                      // the rough grain of the stone
        let x = 18 + Int(noise(k * 7 + 3) * 20), y = 1 + Int(noise(k * 11 + 5) * 13)
        c.px(x, y, k % 2 == 0 ? stoneDark : stoneLight)
    }
    c.rect(22, 1, 12, 1, stoneDark); c.rect(21, 3, 15, 1, stoneDark)        // the ridged brow
    c.rect(23, 2, 10, 1, stoneLight)
    c.rect(23, 4, 15, 1, stoneLight)
    c.rect(23, 5, 15, 1, crack)
    c.rect(18, 6, 3, 4, stoneDark); c.px(19, 7, crack)                      // the ear
    c.rect(25, 6, 4, 3, stoneDark); c.rect(32, 6, 4, 3, stoneDark)          // deep-set sockets
    c.rect(26, 6, 2, 3, ink); c.rect(33, 6, 2, 3, ink)                      // Clawd's eyes
    c.px(27, 7, C(0xB01A12)); c.px(34, 7, C(0xB01A12))
    c.rect(30, 6, 1, 4, stoneDark); c.rect(30, 9, 2, 1, crack)              // the nose
    c.rect(23, 8, 1, 5, crack); c.rect(37, 8, 1, 4, crack)                  // the grooves down his cheeks
    c.rect(27, 11, 7, 1, crack)                                             // the grim mouth
    c.rect(28, 12, 5, 1, stoneLight)
    c.px(20, 2, crack); c.px(21, 3, crack); c.px(20, 11, crack); c.px(21, 12, crack)
    if glow > 0.02 {
        for ex in [26.5, 33.5] {
            glowDot(c, ex + 0.5, 7.5, core: hot.alpha(glow), glow: red.alpha(glow), coreR: 0.6, glowR: 1.4 + 1.4 * glow)
        }
    }

    // The near arm: elbow out, forearm folded back behind him.
    c.rect(38, 12, 6, 5, blue); c.rect(38, 12, 6, 1, blueLight)
    c.rect(39, 16, 5, 9, stone); c.rect(43, 16, 1, 9, stoneDark); c.rect(39, 16, 1, 9, stoneLight)
    c.rect(36, 24, 8, 4, navy); c.rect(36, 24, 8, 1, navyLight)

    // Signature: two Omega Beams snake out of his eyes and strike the ground.
    if let s = p.signature, s > 0.18 {
        let fade = s > 0.86 ? max(0, (1 - s) / 0.14) : 1
        let head = min(1, (s - 0.18) / 0.4)
        let paths: [[(x: Double, y: Double)]] = [
            [(36, 7), (60, -1), (70, 26), (50, 43)],
            [(36, 8), (56, 14), (50, 36), (64, 43)],
        ]
        for path in paths {
            let n = 22
            var prev = path[0]
            for i in 1...n {
                let q = cubic(path, Double(i) / Double(n) * head)
                c.glowLine(prev.x, prev.y, q.x, q.y, core: hot.alpha(fade), glow: red.alpha(fade), coreR: 0.6, glowR: 2,
                           strength: 0.85 + 0.15 * sin(p.t * 50 + Double(i)))
                prev = q
            }
            if head >= 1 {
                let f = min(1, (s - 0.58) / 0.3), end = path[3]
                ring(c, end.x, end.y - 0.5, rx: 2 + f * 7, ry: 1 + f * 2, red.alpha(1 - f))
                glowDot(c, end.x, end.y - 0.5, core: hot.alpha(1 - f), glow: red.alpha(1 - f), coreR: 1.2, glowR: 3.5)
                for k in 0..<4 {
                    let a = Double(k) * 0.8 + 3.6, d = 2 + f * 6
                    c.px(Int(end.x + cos(a) * d), Int(end.y - 1 + sin(a) * d), C(0x6A6058).alpha(1 - f))
                }
            }
        }
    }
}

// MARK: - Steppenwolf

/// Steppenwolf: Darkseid's uncle and warlord, a grey-skinned Clawd in segmented steel armour under a wolf-fur mantle and
/// a blood-red cape, the open steel helmet with its nose guard and great curving horns, pale eyes burning in its
/// shadow; he fights with a long electro-axe. Signature: he hoists the axe overhead and lightning crawls over its blade.
private func drawSteppenwolf(_ c: PixelCanvas, _ p: Pose) {
    let steel = C(0x6E7684), dark = C(0x424854), light = C(0xA2AAB8), skin = C(0x8C98A6), skinDark = C(0x66727E)
    let fur = C(0x5E4E40), furLight = C(0x847060), cape = C(0x6E1A1E), capeEdge = C(0x48100F)
    let horn = C(0xD2C8AE), hornDark = C(0x9C9278), eye = C(0xBFF4FF)
    var charge = 0.0, lift = 0.0, angle = p.melee
    if let s = p.signature {
        let k = habitArc(s, hold: 0.55)
        lift = 5 * k
        angle = -90 - 12 * k
        if s > 0.25 && s < 0.78 { charge = 1 }
    }
    drawCape(c, t: p.lt, speed: p.capeSpeed, color: cape, edge: capeEdge)
    drawLegs(c, Look(leg: dark), step: p.step)
    drawBoots(c, steel, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: steel, eye: nil))
    // The armour.
    c.rect(18, 32, 20, 6, steel)
    c.rect(18, 32, 20, 1, light)
    for x in [22, 27, 32] { c.rect(x, 33, 1, 4, dark) }
    c.rect(18, 35, 20, 1, dark); c.rect(37, 32, 1, 6, dark)
    c.rect(26, 35, 4, 2, C(0x8A6A3A)); c.px(27, 35, C(0xC8A060))
    // The wolf-fur mantle across his shoulders.
    c.pattern(15, 30, ["..FFfFFFfFF........FFfFFFf..", "FFFFFFFFFFFFF....FFFFFFFFFFF", ".F.FF.F..F.F......F..F.FF.F."],
              ["F": fur, "f": furLight])
    c.rect(15, 33, 3, 3, steel)
    // The face in the helmet's shadow.
    c.rect(18, 26, 20, 2, skinDark)
    c.rect(21, 29, 3, 2, ink); c.rect(31, 29, 3, 2, ink)
    for ex in [22.5, 32.5] { glowDot(c, ex, 29.8, core: eye, glow: C(0x5AB8FF), coreR: 0.6, glowR: 1.5, strength: 0.8 + 0.2 * charge) }
    c.rect(24, 31, 8, 1, C(0x3A4048))                                      // a hard mouth
    // Horns, then the helmet over their roots.
    let horns: [[(Double, Double)]] = [
        [(19, 23), (14, 20), (11, 15), (12, 10)],
        [(36, 23), (41, 20), (44, 15), (43, 10)],
    ]
    for h in horns {
        for i in 0..<(h.count - 1) {
            let r: Double = [1.5, 1.1, 0.7][i]
            bar(c, h[i].0, h[i].1, h[i + 1].0, h[i + 1].1, horn, r: r)
        }
        bar(c, h[1].0, h[1].1 + 1, h[2].0, h[2].1 + 1, hornDark, r: 0.4)
    }
    c.pattern(16, 18, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHLLHHHHHHHHHHHHH...",
        "..HHHLHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHDDDDDDDDDDDDDDDDHH.",
        ".HHH.......HH.......HHH.",
        ".HHH.......HH.......HHH.",
        ".HH........HH........HH.",
        ".HH........DD........HH.",
        "..H..................H..",
    ], ["H": steel, "D": dark, "L": light])
    c.rect(27, 18, 2, 7, dark)                                             // the crest down the middle

    // The electro-axe: upright in his hand when it's put away.
    let pv = (x: Sprite.hand.x, y: Sprite.hand.y - lift)
    c.rect(38, Int(pv.y) - 1, 3, 3, steel)
    drawElectroAxe(c, at: pv, angle: angle ?? -90, back: seatedPose ? 4 : 7, trail: p.trail, charge: charge, t: p.t)
}

/// Steppenwolf's axe, gripped at `h`: the haft running `back` px behind the grip, a broad crescent blade on the front
/// with a glowing edge and a spike on the back. `charge` sets lightning crawling over it.
private func drawElectroAxe(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double, back: Double, trail: [Double],
                            charge: Double, t: Double) {
    let haft = C(0x3A3530), metal = C(0x9AA2AE), metalDark = C(0x5E6672), edge = C(0xE8F8FF), glow = C(0x5AC8FF)
    smear(c, h, trail, len: 18, C(0xB8E8FF), inner: 0.55)
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    func at(_ u: Double, _ w: Double) -> (x: Double, y: Double) { (h.x + ux * u + nx * w, h.y + uy * u + ny * w) }
    let butt = at(-back, 0), top = at(17, 0)
    bar(c, butt.x, butt.y, top.x, top.y, haft, r: 0.6)
    c.px(Int(butt.x), Int(butt.y), metal)
    // The crescent blade, widest in the middle, its tips sweeping past where it meets the haft.
    var edgePts: [(x: Double, y: Double)] = []
    for k in 0...8 {
        let f = Double(k) / 8
        let u = 9 + f * 9, w = 1.5 + 4.5 * sin(f * .pi)
        let a = at(u, 0.6), b = at(u + (f - 0.5) * 1.5, w)
        bar(c, a.x, a.y, b.x, b.y, k % 4 == 0 ? metalDark : metal, r: 0.65)
        edgePts.append(b)
    }
    for i in 0..<(edgePts.count - 1) {
        c.glowLine(edgePts[i].x, edgePts[i].y, edgePts[i + 1].x, edgePts[i + 1].y, core: edge, glow: glow,
                   coreR: 0.4, glowR: 1 + 0.4 * charge, strength: 0.5 + 0.4 * charge)
    }
    let s0 = at(12.5, -0.5), s1 = at(13.5, -4)
    bar(c, s0.x, s0.y, s1.x, s1.y, metalDark, r: 0.6)                     // the back spike
    guard charge > 0 else { return }
    let seed = Int(t * 18)
    for b in 0..<3 {
        var prev = edgePts[Int(noise(seed + b * 5) * 8)]
        for j in 0..<3 {
            let q = (x: prev.x + (noise(seed * 3 + b * 7 + j) - 0.5) * 6 + 1, y: prev.y + (noise(seed + b * 11 + j) - 0.6) * 5)
            c.glowLine(prev.x, prev.y, q.x, q.y, core: edge, glow: glow, coreR: 0.3, glowR: 0.9, strength: 0.85 - Double(j) * 0.2)
            prev = q
        }
    }
}

// MARK: - DeSaad

/// DeSaad: Darkseid's torturer, a gaunt bald Clawd with a wrinkled pale dome, pointed ears, sunken eyes under cruel
/// slanted brows and a thin, sly grin, wrapped in a violet robe with gold trim inside a tall blood-red collar. He casts
/// violet torment from his hand. Signature: he rubs his hands together in anticipation, eyes glinting.
private func drawDesaad(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xCDBBA6), skinDark = C(0x9E8A76), skinLight = C(0xE4D6C4)
    let robe = C(0x4E2466), robeDark = C(0x33164A), robeLight = C(0x6E3A8A)
    let collar = C(0x9A2030), collarDark = C(0x661420), gold = C(0xD8A83A), violet = C(0xC88AFF)
    let rub = p.signature.map { habitArc($0, hold: 0.75) } ?? 0
    // The robe to the floor, feet peeking out under the hem as he walks.
    if p.step >= 0 && !seatedPose { c.rect(p.step == 0 ? 21 : 32, 42, 3, 2, C(0x2A1A2A)) }
    let hem = seatedPose ? 39 : 42
    for y in 35...hem {
        let k = (y - 35) / 3
        c.rect(17 - k, y, 22 + k * 2, 1, robe)
        c.px(17 - k, y, robeDark); c.px(38 + k, y, robeDark)
    }
    c.rect(15, hem, 26, 1, gold)
    c.rect(27, 35, 2, hem - 35, robeLight)
    c.oy += p.breathe
    // The tall collar standing up behind his head.
    let side = ["C....", "CC...", "CCC..", "cCCC.", "cCCCC", ".cCCC", ".cCCC", ".cCCC", "..cCC", "..cCC", "..cCC",
                "..cCC", "..cCC", "...cC", "...cC"]
    c.pattern(13, 18, side, ["C": collar, "c": collarDark])
    c.pattern(38, 18, side.map { String($0.reversed()) }, ["C": collar, "c": collarDark])
    var look = Look(body: skin, shade: skinDark, arm: robe, eye: nil)
    look.legs = false
    let raise = rub > 0.05 ? 0 : p.armRaise
    drawBody(c, look, armRight: raise)
    // The bald, wrinkled dome.
    c.pattern(19, 21, ["......SSSSSS......", "...SSSSSSSSSSSS...", ".SSSLLSSSSSSSSSSS.", "SSSLSSSSSSSSSSSSSS", "SSSSSSSSSSSSSSSSSS"],
              ["S": skin, "L": skinLight])
    c.px(24, 23, skinDark); c.rect(26, 22, 3, 1, skinDark); c.rect(30, 23, 3, 1, skinDark); c.rect(27, 24, 3, 1, skinDark)
    c.pattern(15, 26, ["S..", "SS.", ".SS"], ["S": skinDark])               // pointed ears
    c.pattern(38, 26, ["..S", ".SS", "SS."], ["S": skinDark])
    // The face: cruel brows, sunken eyes, the sly grin.
    c.pattern(21, 27, ["KK.........KK", "..KK.....KK.."], ["K": C(0x3A2A2A)])
    c.rect(21, 29, 4, 2, skinDark); c.rect(31, 29, 4, 2, skinDark)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    let glint = rub > 0.3 && Int(p.t * 6) % 2 == 0
    c.px(23, 29, glint ? white : violet); c.px(33, 29, glint ? white : violet)
    c.rect(20, 31, 1, 2, skinDark); c.rect(35, 31, 1, 2, skinDark)           // hollow cheeks
    c.pattern(23, 31, ["K.........K", ".KWKWKWKWK."], ["K": C(0x3A1A1A), "W": C(0xE8E0C8)])
    // The robe over his chest.
    c.rect(18, 33, 20, 5, robe)
    c.rect(37, 33, 1, 5, robeDark)
    c.pattern(18, 33, ["GGGG............GGGG", "...GG..........GG...", "....GG........GG....", ".....G........G....."], ["G": gold])
    c.rect(15, 33, 3, 3, robe)
    if rub > 0.05 {
        // Rubbing his hands together in front of his chest.
        let j = Int(p.t * 14) % 2
        c.rect(15, 33, 3, 3, robeDark)
        c.rect(35, 33, 4, 3, robe); c.rect(30, 34, 5, 2, robeDark)        // both sleeves brought forward
        c.rect(38, 32 + j, 3, 3, skin); c.px(41, 33 + j, skinDark)
        c.rect(36, 33 - j, 3, 3, skinLight); c.px(36, 35 - j, skinDark)
        if Int(p.t * 10) % 3 == 0 { c.px(42, 31 + j, violet.alpha(rub)); c.px(40, 30, white.alpha(rub * 0.7)) }
    } else {
        c.rect(41, 33 - raise, 1, 2, skin); c.px(40, 35 - raise, skin)      // the bony fingers
    }
}

// MARK: - Granny Goodness

/// Granny Goodness: the matron of Apokolips' orphanage, a sweet-faced old Clawd with grey curls and a bun, rosy
/// cheeks and a little smile, in a bronze breastplate and round pauldrons over a dark red dress, carrying an iron staff
/// with a spiked Apokoliptian head and a red gem. Signature: she raps the staff on the floor twice, hard.
private func drawGrannyGoodness(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE6C2A6), skinDark = C(0xC09A80), cheek = C(0xE8928A)
    let hair = C(0xC8C8CE), hairDark = C(0x9A9AA4), hairLight = C(0xEDEDF2)
    let bronze = C(0xB8782E), bronzeDark = C(0x7E4E1C), bronzeLight = C(0xE0A85A)
    let dress = C(0x8E1E24), dressDark = C(0x601418)
    var lift = 0.0, slam: Double?
    if let s = p.signature, s > 0.05, s < 0.95 {
        let f = frac((s - 0.05) / 0.45)
        if f < 0.6 { lift = 4 * sin(f / 0.6 * .pi / 2) } else if f < 0.7 { lift = 4 * (1 - (f - 0.6) / 0.1) } else { slam = (f - 0.7) / 0.3 }
    }
    drawLegs(c, Look(leg: C(0x2A2226)), step: p.step)
    // The skirt over her legs.
    let skirtEnd = seatedPose ? 39 : 40
    for y in 35...skirtEnd {
        let k = (y - 35) / 2
        c.rect(17 - k, y, 22 + k * 2, 1, dress)
        c.px(17 - k, y, dressDark); c.px(38 + k, y, dressDark)
    }
    c.rect(15, skirtEnd, 26, 1, dressDark)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinDark, arm: bronze, eye: nil))
    // Grey curls and the bun.
    c.pattern(17, 16, [
        "........HHHHHH........",
        ".......HHLHHHHH.......",
        ".......HHHHHHDH.......",
        "........HDDDD.........",
        "....HHHHHHHHHHHHHH....",
        "..HHHLHHHHLHHHHLHHHH..",
        ".HHLHHHHLHHHHLHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHHHDHHHHDHHHHDHHHHDHH",
        "HHH................HHH",
        "HHH................HHH",
        ".HH................HH.",
        ".HD................DH.",
    ], ["H": hair, "D": hairDark, "L": hairLight])
    // The face: small eyes, arched brows, rosy cheeks and a sweet little smile.
    c.rect(21, 27, 4, 1, hairDark); c.rect(31, 27, 4, 1, hairDark)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.px(21, 30, skinDark); c.px(34, 30, skinDark); c.px(25, 30, skinDark); c.px(30, 30, skinDark)   // crow's feet
    c.rect(20, 31, 2, 1, cheek); c.rect(34, 31, 2, 1, cheek)
    if slam != nil {
        c.rect(25, 31, 6, 2, C(0x6A2A2A))                                  // a stern bark
    } else {
        c.rect(25, 32, 6, 1, C(0x9A4A4A)); c.px(24, 31, C(0x9A4A4A)); c.px(31, 31, C(0x9A4A4A))
    }
    // The breastplate and pauldrons.
    c.rect(18, 33, 20, 5, bronze)
    c.rect(18, 33, 20, 1, bronzeLight)
    c.rect(27, 34, 2, 4, bronzeDark); c.rect(26, 34, 1, 3, bronzeLight)
    c.rect(37, 33, 1, 5, bronzeDark)
    c.px(20, 35, bronzeDark); c.px(35, 35, bronzeDark)
    for sx in [14, 36] {
        c.pattern(sx, 31, [".BBBB.", "BBLLBB", "BBBBBB", "DDDDDD"], ["B": bronze, "L": bronzeLight, "D": bronzeDark])
    }
    c.rect(15, 35, 3, 2, skin)

    // The staff: upright in her hand when it's put away.
    let pv = (x: Sprite.hand.x, y: Sprite.hand.y - lift)
    drawGrannyStaff(c, at: pv, angle: p.signature != nil ? -90 : p.melee ?? -90, back: seatedPose ? 4 : 8, trail: p.trail)
    c.rect(39, Int(pv.y) - 1, 3, 3, skin)
    if let f = slam, f < 1 {
        let gy = 43.5 - Double(p.breathe)
        ring(c, 41.5, gy, rx: 2 + f * 8, ry: 0.6 + f * 1.2, C(0xFFD8B0).alpha(1 - f))
        for k in 0..<3 { puff(c, x: 38 + Double(k) * 3.5, y: gy - 1 - f * 2, k: f, C(0xB8A890)) }
        if f < 0.2 { c.ox += Int(p.t * 40) % 2 }
    }
}

/// Granny's staff gripped at `h`: an iron shaft running `back` px behind the grip, the spiked head with its red gem.
private func drawGrannyStaff(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double, back: Double, trail: [Double]) {
    let iron = C(0x3E3A44), ironLight = C(0x6A6676), bronze = C(0xC8883A), gem = C(0xFF3A2A)
    smear(c, h, trail, len: 19, C(0xFFD8B0), inner: 0.6)
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    func at(_ u: Double, _ w: Double) -> (x: Double, y: Double) { (h.x + ux * u + nx * w, h.y + uy * u + ny * w) }
    let a = at(-back, 0), b = at(14, 0)
    bar(c, a.x, a.y, b.x, b.y, iron, r: 0.55)
    let hl0 = at(-back + 1, -0.4), hl1 = at(12, -0.4)
    bar(c, hl0.x, hl0.y, hl1.x, hl1.y, ironLight, r: 0.2)
    // The head: a crossbar with two hooked prongs and a central spike.
    let cl = at(14, -3), cr = at(14, 3)
    bar(c, cl.x, cl.y, cr.x, cr.y, bronze, r: 0.7)
    for w in [-3.0, 3.0] {
        let p0 = at(14, w), p1 = at(17, w * 1.2), p2 = at(19, w * 0.8)
        bar(c, p0.x, p0.y, p1.x, p1.y, bronze, r: 0.55); bar(c, p1.x, p1.y, p2.x, p2.y, bronze, r: 0.45)
    }
    let s0 = at(14, 0), s1 = at(20, 0)
    bar(c, s0.x, s0.y, s1.x, s1.y, iron, r: 0.55)
    let g = at(15, 0)
    glowDot(c, g.x, g.y, core: C(0xFFD0C0), glow: gem, coreR: 0.6, glowR: 1.6)
}

// MARK: - Kalibak

/// Kalibak's shoulder: his arm and the Beta Club swing from here.
private let kalibakShoulder = (x: 40.0, y: 21.0)

/// Kalibak: Darkseid's brute of a son, a hulking tan Clawd with a wild black mane and beard, a heavy brow and a
/// scowl, steel straps crossed over his bare chest, a studded belt and leather kilt, and the Beta Club in his fist, its
/// head glowing red. Signature: he props the club on the floor and pounds his chest with both fists, roaring.
private func drawKalibak(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xB0845A), skinDark = C(0x825E3C), skinLight = C(0xD0A47A)
    let hair = C(0x1E1A18), hairLight = C(0x3A3430)
    let steel = C(0x4C5878), steelDark = C(0x323A54), steelLight = C(0x7A88AE)
    let leather = C(0x4A3426), leatherDark = C(0x30221A), gold = C(0xD8A83A)
    let pounding = p.signature.map { $0 > 0.1 && $0 < 0.9 } ?? false
    let roar = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    for (i, lx) in [18, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 32, 7, 11 - up, skinDark)
        c.rect(lx - 1, 38 - up, 9, 6, steelDark); c.rect(lx - 1, 38 - up, 9, 1, steelLight)   // boots
    }
    if pounding {
        // The Beta Club, stood on its end beside him.
        drawBetaClub(c, fist: (47, 38), angle: -86, t: p.t, glow: 0.5)
    }
    c.oy += p.breathe
    let beat = pounding ? (Int((p.signature ?? 0) * 16) % 2) : -1
    // The far arm.
    if !pounding {
        c.rect(10, 15, 5, 14, skinDark); c.rect(9, 28, 7, 6, steelDark); c.rect(9, 28, 7, 1, steel)
    }
    // The torso.
    c.rect(14, 12, 28, 22, skin)
    c.rect(14, 12, 2, 22, skinLight); c.rect(40, 12, 2, 22, skinDark)
    c.rect(19, 18, 8, 1, skinDark); c.rect(30, 18, 8, 1, skinDark)          // pecs
    for y in [22, 25] { c.rect(24, y, 3, 1, skinDark); c.rect(30, y, 3, 1, skinDark) }
    bar(c, 16, 13, 38, 28, steel, r: 1.1); bar(c, 39, 13, 17, 28, steel, r: 1.1)   // the crossed straps
    c.rect(26, 19, 5, 4, steelDark); c.rect(27, 20, 3, 2, C(0xC0302A))      // and the disc where they cross
    c.rect(14, 28, 28, 4, steelDark); c.rect(14, 28, 28, 1, steelLight)      // the belt…
    for x in stride(from: 16, to: 41, by: 4) { c.px(x, 30, steelLight) }
    c.rect(25, 28, 6, 4, gold); c.rect(26, 29, 4, 2, C(0xA8781E))           // …and buckle
    c.rect(15, 32, 26, 4, leather)                                          // the leather kilt
    for x in [19, 24, 29, 34] { c.rect(x, 32, 1, 4, leatherDark) }
    // Shoulder plates.
    c.pattern(9, 9, ["..S.S.S..", ".SSSSSSS.", "SSLLSSSSS", "SSSSSSSSS", ".DDDDDDD."], ["S": steel, "L": steelLight, "D": steelDark])
    // The head, hunched forward: mane, brow, beard.
    c.pattern(18, 0, [
        "....HHHHHHHHHHHH......",
        "..HHHHHHHHHHHHHHHH....",
        ".HHHHHHHHHHHHHHHHHH...",
        "HHHHHHHHhHHHHHHhHHHH..",
        "HHHHHHHSSSSSSSSSSSSH..",
        "HHHHHHSSSSSSSSSSSSSSS.",
        "HHHHHSSSSSSSSSSSSSSSS.",
        "HHHHHSSSSSSSSSSSSSSSS.",
        "HHHHHSSSSSSSSSSSSSSSS.",
        "HHHHHHSSSSSSSSSSSSSSS.",
        "HHHHHHBBBBBBBBBBBBBBB.",
        ".HHHHHBBBBBBBBBBBBBBB.",
        "..HHHHBBBBBBBBBBBBBBB.",
        "...HHHBBBBBBBBBBBBBB..",
        "......BBBBBBBBBBBBB...",
        "........BBBBBBBBB.....",
    ], ["H": hair, "h": hairLight, "S": skin, "B": hair])
    c.rect(24, 5, 14, 1, skinDark)                                          // the heavy brow
    c.rect(26, 6, 2, 2, ink); c.rect(33, 6, 2, 2, ink)
    c.rect(29, 7, 3, 2, skinDark)                                           // the broad nose
    c.rect(25, 9, 13, 1, skinDark)
    let gape = Int((roar * 3).rounded())
    c.rect(27, 11, 8, 1 + gape, C(0x4A1410))                               // the mouth, in the beard
    for k in 0..<4 { c.px(28 + k * 2, 11, C(0xF0E6D0)) }
    if roar > 0.8, let s = p.signature {
        for i in 0..<3 {
            let f = frac(s * 4 + Double(i) / 3), x = 42 + Int(f * 12), col = C(0xF4EEE0).alpha(0.8 * (1 - f))
            for dy in -2 - i...(2 + i) where abs(dy) > 0 || i == 0 { c.px(x - abs(dy) / 2, 12 + dy, col) }
        }
    }
    c.pattern(33, 9, ["..S.S.S..", ".SSSSSSS.", "SSLLSSSSS", "SSSSSSSSS", ".DDDDDDD."], ["S": steel, "L": steelLight, "D": steelDark])
    // The near arm, with the Beta Club (or pounding his chest).
    if pounding {
        // Both fists taking turns on his chest.
        for (n, sh) in [(0, (x: 14.0, y: 15.0)), (1, kalibakShoulder)] {
            let hitting = beat == n
            let e = limb(c, sh, n == 0 ? (hitting ? 35 : 55) : (hitting ? 165 : 130), len: hitting ? 9 : 6, r: 2.2,
                         n == 0 ? skinDark : skin)
            let fy = Int(e.y) - 2 - (hitting ? 0 : 2)
            c.rect(Int(e.x) - 3, fy, 6, 6, steelDark); c.rect(Int(e.x) - 3, fy, 6, 1, steel)
            if hitting {
                for k in 0..<3 { c.px(Int(e.x) - 2 + k * 2, fy - 2 - k % 2, white.alpha(0.6)) }
            }
        }
        return
    }
    let angle = p.melee ?? 75
    smear(c, kalibakShoulder, p.trail, len: 21, C(0xFFB0A0), inner: 0.5)
    let e = limb(c, kalibakShoulder, angle, len: 7, r: 2.4, skin)
    drawBetaClub(c, fist: e, angle: angle, t: p.t, glow: p.melee != nil ? 1 : 0.6)
    c.rect(Int(e.x) - 2, Int(e.y) - 2, 5, 5, steelDark)
    c.rect(Int(e.x) - 2, Int(e.y) - 2, 5, 1, steel)
}

/// The Beta Club, gripped at `fist` and pointing along `angle`: a ribbed steel haft and a heavy head with red-hot bands.
private func drawBetaClub(_ c: PixelCanvas, fist e: (x: Double, y: Double), angle: Double, t: Double, glow: Double) {
    let metal = C(0x5A6070), metalLight = C(0x9AA2B4), dark = C(0x2E323C), darkLight = C(0x4E5464)
    let red = C(0xE8301E), hot = C(0xFF9A6A)
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    func at(_ u: Double, _ w: Double = 0) -> (x: Double, y: Double) { (e.x + ux * u + nx * w, e.y + uy * u + ny * w) }
    let a = at(-4), b = at(8)
    bar(c, a.x, a.y, b.x, b.y, metal, r: 1)
    for u in [-3.0, 1.0, 4.0, 7.0] { let q = at(u); c.px(Int(q.x), Int(q.y), metalLight) }
    let h0 = at(8), h1 = at(15)
    bar(c, h0.x, h0.y, h1.x, h1.y, dark, r: 2.6)
    let s0 = at(8.5, -1.6), s1 = at(14.5, -1.6)
    bar(c, s0.x, s0.y, s1.x, s1.y, darkLight, r: 0.5)
    let pulse = 0.75 + 0.25 * sin(t * 8)
    for u in [10.0, 13.0] {
        let p0 = at(u, -2.3), p1 = at(u, 2.3)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: red, glow: C(0xFF3A1E), coreR: 0.5, glowR: 1.3, strength: glow * pulse)
    }
    let tip = at(16)
    glowDot(c, tip.x, tip.y, core: hot, glow: red, coreR: 0.7, glowR: 2, strength: glow * pulse)
}

// MARK: - Parademon

/// A Parademon: Apokolips' winged foot soldier, olive insect armour plated in segments, a domed helmet with twitching
/// feelers, two great amber compound eyes and clicking mandibles, translucent dragonfly wings folded down its back
/// (spread and buzzing in flight), and a long energy rifle. Signature: its wings buzz into a blur and it rises off
/// the ground for a moment, mandibles chittering.
private func drawParademon(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0x56603E), dark = C(0x363E28), light = C(0x82905E), red = C(0x9A2E22)
    let eye = C(0xFFA82A), eyeDark = C(0xC86A10), eyeLight = C(0xFFE8A0)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let buzz = p.flying || k > 0.1
    let rise = Int((k * 4).rounded())
    layer(c, lean: p.flying ? 4 : 0) { c in
        c.oy -= rise
        drawBugWing(c, buzz: buzz, t: p.t, far: true)
        if p.flying || rise > 1 {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                c.rect(lx - 2 + i / 2, 36, 2, 6, dark); c.rect(lx - 2 + i / 2, 41, 2, 1, light)
            }
        } else {
            drawLegs(c, Look(leg: dark), step: p.step)
            drawBoots(c, armour, step: p.step, rows: 2)
        }
        c.oy += p.breathe
        drawBugWing(c, buzz: buzz, t: p.t + 0.03, far: false)
        drawBody(c, Look(body: armour, shade: dark, arm: armour, eye: nil))
        // Feelers, then the domed helmet.
        let tw = (k > 0.1 || p.flying) && Int(p.t * 12) % 2 == 0 ? 1.0 : 0.0
        bar(c, 25, 20, 22 - tw, 14, dark, r: 0.4); bar(c, 31, 20, 34 + tw, 15, dark, r: 0.4)
        c.px(Int(22 - tw), 14, light); c.px(Int(34 + tw), 15, light)
        c.pattern(17, 19, [
            ".......AAAAAAAA.......",
            ".....AAAAAAAAAAAA.....",
            "...AAALLAAAAAAAAAAA...",
            "..AAALAAAAAAAAAAAAAA..",
            ".AAAAAAAADDDDAAAAAAAA.",
            ".AAAAAAAAADDAAAAAAAAA.",
            "AAAAAAAAAAAAAAAAAAAAAA",
            "DDDDDDDDDDDDDDDDDDDDDD",
        ], ["A": armour, "D": dark, "L": light])
        // The compound eyes.
        for ex in [20, 30] {
            c.pattern(ex, 27, [".EEEE.", "EEeEEE", "EEEEEe", ".EeEE."], ["E": eye, "e": eyeDark])
            c.px(ex + 1, 28, eyeLight)
        }
        // Mandibles, clicking when it chitters.
        let open = (k > 0.1 && Int(p.t * 16) % 2 == 0) || p.hit ? 1 : 0
        c.rect(25, 31, 6, 2, dark)
        c.px(25 - open, 32, light); c.px(30 + open, 32, light)
        c.px(26 - open, 33, light); c.px(29 + open, 33, light)
        // Segmented chest plates and the red sash.
        c.rect(18, 34, 20, 4, armour)
        for y in [34, 36] { c.rect(19, y, 18, 1, dark) }
        c.rect(18, 37, 20, 1, red)
        c.rect(15, 32, 3, 2, light)
        // The energy rifle.
        let y = 32 + p.gunY
        c.rect(35, y + 1, 18, 2, C(0x2E302A)); c.rect(35, y + 1, 18, 1, C(0x4E5248))
        c.rect(33, y + 2, 4, 3, C(0x2E302A))                               // the stock
        c.rect(43, y, 5, 4, C(0x24261F))
        c.rect(44, y + 1, 3, 2, eye); c.px(45, y + 1, eyeLight)            // the power cell
        c.rect(52, y, 1, 4, C(0x4E5248))
        c.rect(38, y + 1, 3, 3, armour); c.px(38, y + 1, light)            // the hand
    }
}

/// A Parademon's pair of dragonfly wings on one side, from the shoulder: folded down its back, or spread and buzzing
/// (blurred, flicking between two beats). `far`: the pair on the far side, darker and a little behind.
private func drawBugWing(_ c: PixelCanvas, buzz: Bool, t: Double, far: Bool) {
    let membrane = far ? C(0x8AA48A, 0.8) : C(0xC8E0BE, 0.85), vein = far ? C(0x34422E) : C(0x4E6046)
    let root = (x: far ? 25.0 : 22.0, y: 29.0)
    let beat = Int(t * 30) % 2 == 0
    var angles: [Double] = far ? [160, 172] : [148, 162]
    var len: Double = 13
    if buzz {
        angles = beat ? [-150, -172] : [-128, -152]
        if far { angles = angles.map { (a: Double) -> Double in a - 8 } }
        len = 15
    }
    for (n, a) in angles.enumerated() {
        let r = a * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
        let l = len - Double(n) * 2
        if buzz {
            // The blur of the other half of the beat.
            let r2 = (a + (beat ? 20 : -20)) * .pi / 180
            for i in stride(from: 2.0, through: l, by: 1.0) {
                c.px(Int(root.x + cos(r2) * i), Int(root.y + sin(r2) * i), membrane.alpha(0.3))
            }
        }
        var rim: [(x: Double, y: Double)] = []
        for i in 0...Int(l) {
            let u = Double(i), w = 2.8 * sin(.pi * min(1, u / l * 1.1))
            bar(c, root.x + ux * u, root.y + uy * u, root.x + ux * u + nx * w, root.y + uy * u + ny * w, membrane, r: 0.55)
            rim.append((root.x + ux * u + nx * w, root.y + uy * u + ny * w))
        }
        for i in 0..<(rim.count - 1) { bar(c, rim[i].x, rim[i].y, rim[i + 1].x, rim[i + 1].y, vein, r: 0.3) }
        bar(c, root.x, root.y, root.x + ux * l, root.y + uy * l, vein, r: 0.4)
        let m0 = (x: root.x + ux * l * 0.3, y: root.y + uy * l * 0.3)
        bar(c, m0.x, m0.y, m0.x + ux * l * 0.5 + nx * 1.8, m0.y + uy * l * 0.5 + ny * 1.8, vein.alpha(0.6), r: 0.25)
    }
}

// MARK: - Lobo

/// Lobo: the Main Man, a chalk-white Clawd with a mane of black hair swept back, red eyes with the black streaks under
/// them, a nasty grin round a cigar, a black leather vest and trousers, a skull belt buckle, and the chain with its
/// meat hook (wound round his fist, the hook dangling, when he isn't swinging it). Signature: a long drag on the cigar
/// and a lazy string of smoke rings.
private func drawLobo(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE8ECEF), skinDark = C(0xBCC3CA), hair = C(0x16161C), hairLight = C(0x34343E)
    let leather = C(0x24242C), leatherLight = C(0x46464F), red = C(0xE0202A)
    let cigar = C(0x7A5232), ember = C(0xFF7A2A)
    var drag = 0.0, rings: Double?
    if let s = p.signature {
        if s < 0.35 { drag = habitArc(s / 0.35, hold: 0.5) } else { rings = (s - 0.35) / 0.65 }
    }
    drawLegs(c, Look(leg: leather), step: p.step)
    drawBoots(c, C(0x0E0E12), step: p.step, rows: 2)
    c.oy += p.breathe
    // The mane, hanging down his back.
    c.pattern(11, 21, [
        ".....HHHH",
        "...HHHHHH",
        "..HHHHHHH",
        ".HHHHHHHH",
        ".HHHHhHHH",
        "HHHHHHHHH",
        "HHHHhHHHH",
        "HHHHHHHHH",
        ".HHHHHHH.",
        ".HHhHHHH.",
        "..HHHHHH.",
        "..HHHHH..",
        "...HhHH..",
        "...HHH...",
        "....HH...",
        "....H....",
    ], ["H": hair, "h": hairLight])
    drawBody(c, Look(body: skin, shade: skinDark, arm: skin, eye: nil))
    c.pattern(17, 20, [
        ".....HHHHHHHHH........",
        "...HHHHHHHHHHHHHH.....",
        ".HHHHhhHHHHHHHHHHHH...",
        "HHHHhHHHHHHHHHHHHHHH..",
        "HHHHHHHHhhhHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHH.",
        "HHHHH.HHH..H..HHH.HH..",
        "HHH.......H...........",
        "HH....................",
    ], ["H": hair, "h": hairLight])
    // The face: red eyes, black streaks, the grin, the cigar.
    c.pattern(21, 27, ["KK.........KK", "..KK.....KK.."], ["K": ink])
    c.rect(22, 29, 2, 2, red); c.rect(32, 29, 2, 2, red)
    c.px(22, 29, ink); c.px(32, 29, ink)
    c.rect(22, 31, 1, 2, ink); c.rect(33, 31, 1, 2, ink)                   // the streaks under his eyes
    c.pattern(24, 31, ["K.......K", ".KWWWWWK."], ["K": ink, "W": white])
    c.rect(30, 32, 6, 1, cigar); c.rect(30, 32, 1, 1, C(0x5A3A22))
    let burn = 0.6 + 0.4 * drag
    glowDot(c, 36, 32.5, core: C(0xFFE0A0), glow: ember, coreR: 0.5, glowR: 1 + 1.5 * drag, strength: burn)
    if drag > 0.3 { c.rect(20, 31, 2, 1, skinDark); c.rect(35, 30, 1, 2, skinDark) }   // cheeks sucked in
    // The vest, open over his chest, and the skull buckle.
    c.rect(18, 33, 20, 5, leather)
    c.pattern(24, 33, ["SSSSSSSS", ".SSSSSS.", "..SSSS.."], ["S": skin])
    c.rect(18, 33, 1, 4, leatherLight); c.rect(37, 33, 1, 5, C(0x121216))
    c.rect(18, 36, 20, 1, C(0x3A3A44))
    c.pattern(26, 35, [".WWW.", "WKWKW", ".WWW."], ["W": C(0xD8DCE0), "K": ink])
    c.rect(15, 35, 3, 1, leather)                                           // wristbands
    if let f = rings {
        for i in 0..<3 {
            let g = f * 1.6 - Double(i) * 0.3
            guard g > 0, g < 1 else { continue }
            let x = 37 + g * 7 + sin(g * 6) * 1.5, y = 31 - g * 14
            ring(c, x, y, rx: 1.5 + g * 2.5, ry: 1 + g * 1.4, C(0xF0F0F4).alpha(0.95 * (1 - g * 0.8)))
        }
    }
    // The chain and hook.
    let h = Sprite.hand
    c.rect(38, 33, 3, 3, skin); c.rect(38, 35, 3, 1, leather)
    if let a = p.melee {
        smear(c, h, p.trail, len: 18, C(0xD8DCE4), inner: 0.6)
        drawChain(c, from: h, to: (h.x + cos(a * .pi / 180) * 16, h.y + sin(a * .pi / 180) * 16), sag: 2)
        drawHook(c, at: (h.x + cos(a * .pi / 180) * 16, h.y + sin(a * .pi / 180) * 16), angle: a)
    } else {
        // Wound round his fist, the rest swinging below with the hook on the end.
        c.rect(38, 34, 4, 1, C(0x8A909C)); c.rect(38, 33, 4, 1, C(0x6E7480))
        let sway = sin(p.lt * 2.2) * 1.2
        let end = (x: 43 + sway, y: seatedPose ? 38.5 : 41.5)
        drawChain(c, from: (41.5, 35), to: end, sag: -1)
        drawHook(c, at: end, angle: 90 + sway * 8)
    }
}

/// A steel chain from `a` to `b`, links alternating bright and dark, bowed `sag` px off the straight line.
private func drawChain(_ c: PixelCanvas, from a: (x: Double, y: Double), to b: (x: Double, y: Double), sag: Double) {
    let len = max(hypot(b.x - a.x, b.y - a.y), 0.01)
    let n = Int(len / 1.2)
    let nx = -(b.y - a.y) / len, ny = (b.x - a.x) / len
    for i in 0...n {
        let f = Double(i) / Double(max(1, n)), bow = sin(f * .pi) * sag
        let x = a.x + (b.x - a.x) * f + nx * bow, y = a.y + (b.y - a.y) * f + ny * bow
        c.px(Int(x), Int(y), i % 2 == 0 ? C(0xB4BAC4) : C(0x6A707C))
    }
}

/// Lobo's meat hook hanging off the end of the chain at `at`, its shank pointing along `angle`.
private func drawHook(_ c: PixelCanvas, at e: (x: Double, y: Double), angle: Double) {
    let steel = C(0xC8CED8), dark = C(0x7A808C)
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    func at(_ u: Double, _ w: Double) -> (x: Double, y: Double) { (e.x + ux * u + nx * w, e.y + uy * u + ny * w) }
    let pts: [(x: Double, y: Double)] = [at(0, 0), at(2.5, 0), at(3.8, -1.2), at(3.6, -2.8), at(2.2, -3.4)]
    for i in 0..<(pts.count - 1) { bar(c, pts[i].x, pts[i].y, pts[i + 1].x, pts[i + 1].y, i == 0 ? dark : steel, r: 0.55) }
    c.px(Int(pts[4].x), Int(pts[4].y), white)
}

// MARK: - Mongul

/// Mongul's shoulder: his fist swings from here.
private let mongulShoulder = (x: 40.0, y: 19.0)

/// Mongul: the yellow-skinned tyrant of Warworld, a giant Clawd with a huge bald ridged head, red eyes under a jutting
/// brow and a fanged scowl, a purple tunic with a towering collar, a black and gold belt, purple boots and bracers.
/// He fights with his fists. Signature: he holds out a Black Mercy, its crimson flower opening and its tendrils reaching.
private func drawMongul(_ c: PixelCanvas, _ p: Pose) {
    let yellow = C(0xE6C23A), yellowDark = C(0xB4902A), yellowLight = C(0xF6E07A)
    let purple = C(0x6E2A6A), purpleDark = C(0x4A1A48), purpleLight = C(0x9A4A90)
    let black = C(0x1C1A20), gold = C(0xD8A83A)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    for (i, lx) in [19, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 31, 7, 12 - up, purpleDark)
        c.rect(lx - 1, 36 - up, 9, 8, purple)
        c.rect(lx - 1, 36 - up, 9, 1, purpleLight); c.rect(lx + 7, 36 - up, 1, 8, purpleDark)
    }
    c.oy += p.breathe
    // The towering collar behind his head.
    c.pattern(13, 1, [
        "PP........................PP",
        "PPP......................PPP",
        "PPPP....................PPPP",
        "PPPP....................PPPP",
        ".PPPP..................PPPP.",
        ".PPPP..................PPPP.",
        ".PPPPP................PPPPP.",
        "..PPPP................PPPP..",
        "..PPPPP..............PPPPP..",
        "...PPPP..............PPPP...",
    ], ["P": purpleLight])
    // The far arm.
    c.rect(11, 16, 5, 9, yellowDark); c.rect(10, 24, 7, 4, purpleDark); c.rect(10, 28, 7, 5, yellowDark)
    // The torso.
    c.rect(15, 12, 26, 20, purple)
    c.rect(15, 12, 2, 20, purpleLight); c.rect(39, 12, 2, 20, purpleDark)
    c.pattern(21, 15, ["YYYYYYYYYYYYYY", ".YYYYYYYYYYYY.", "..YYYYYYYYYY..", "....YYYYYY....", "......YY......"],
              ["Y": yellowDark])                                         // the bare chest in the deep neckline
    c.rect(25, 16, 2, 1, yellow); c.rect(31, 16, 2, 1, yellow)
    c.rect(15, 26, 26, 4, black); c.rect(15, 26, 26, 1, C(0x3A3640))       // the belt
    c.rect(25, 26, 6, 4, gold); c.rect(26, 27, 4, 2, C(0xA8781E))
    c.rect(16, 30, 24, 3, purpleDark)
    c.pattern(10, 9, [".PPPPPPP.", "PPLLPPPPP", "PPPPPPPPP", "PPPPPPPPP", ".DDDDDDD."], ["P": purple, "L": purpleLight, "D": purpleDark])
    // The great bald head.
    c.pattern(18, 0, [
        "......YYYYYYYYYY......",
        "....YYYYYYYYYYYYYY....",
        "...YYYYYYYYYYYYYYYY...",
        "..YYYYYYYYYYYYYYYYYY..",
        ".YYYYYYYYYYYYYYYYYYYY.",
        ".YYYYYYYYYYYYYYYYYYYY.",
        "YYYYYYYYYYYYYYYYYYYYYY",
        "YYYYYYYYYYYYYYYYYYYYYY",
        "YYYYYYYYYYYYYYYYYYYYYY",
        "YYYYYYYYYYYYYYYYYYYYYY",
        ".YYYYYYYYYYYYYYYYYYYY.",
        ".YYYYYYYYYYYYYYYYYYYY.",
        "..YYYYYYYYYYYYYYYYYY..",
        "....YYYYYYYYYYYYYY....",
    ], ["Y": yellow])
    c.rect(22, 1, 2, 4, yellowLight); c.rect(20, 3, 2, 3, yellowLight)      // shine on the dome
    c.rect(27, 1, 1, 5, yellowDark); c.rect(32, 1, 1, 5, yellowDark)        // the ridges over his skull
    c.rect(18, 6, 2, 3, yellowDark)                                         // the ear
    c.rect(24, 6, 14, 1, yellowDark)                                        // the jutting brow
    c.rect(25, 7, 3, 2, ink); c.rect(33, 7, 3, 2, ink)
    c.px(26, 7, C(0xE02A2A)); c.px(34, 7, C(0xE02A2A))
    c.rect(30, 8, 2, 2, yellowDark)
    c.rect(26, 11, 10, 1, C(0x5A1A14))                                      // the fanged scowl
    c.px(27, 12, white); c.px(34, 12, white)
    c.rect(37, 6, 1, 7, yellowDark)
    c.rect(20, 14, 18, 1, purpleDark)                                     // the collar under his jaw
    // The near arm.
    var angle = p.melee ?? 80
    if k > 0 { angle = 80 + (-12 - 80) * k }
    smear(c, mongulShoulder, p.trail, len: 20, C(0xFFF0B0))
    c.pattern(34, 9, [".PPPPPPP.", "PPLLPPPPP", "PPPPPPPPP", "PPPPPPPPD", ".DDDDDDD."], ["P": purple, "L": purpleLight, "D": purpleDark])
    let e = limb(c, mongulShoulder, angle, len: 13, r: 2.2, yellow)
    let r = angle * .pi / 180
    bar(c, e.x - cos(r) * 4, e.y - sin(r) * 4, e.x - cos(r) * 1, e.y - sin(r) * 1, purple, r: 2.4)   // the bracer
    c.rect(Int(e.x) - 3, Int(e.y) - 3, 7, 6, yellow)
    c.rect(Int(e.x) - 3, Int(e.y) - 3, 7, 1, yellowLight); c.rect(Int(e.x) - 3, Int(e.y) + 2, 7, 1, yellowDark)
    // Signature: the Black Mercy in his palm.
    if k > 0.15 {
        let bx = e.x + 1, by = e.y - 4
        let grow = min(1, (k - 0.15) / 0.6)
        for n in 0..<5 {
            let a = (-160 + Double(n) * 35) * .pi / 180
            let l = 2 + grow * (4 + Double(n % 2) * 2)
            let wob = sin(p.t * 5 + Double(n)) * 0.6
            bar(c, bx, by + 1, bx + cos(a + wob * 0.3) * l, by + 1 + sin(a + wob * 0.3) * l, C(0x3A8A3A), r: 0.45)
            c.px(Int(bx + cos(a + wob * 0.3) * l), Int(by + 1 + sin(a + wob * 0.3) * l), C(0x7ACA5A))
        }
        c.rect(Int(bx) - 2, Int(by), 5, 3, C(0x2E6A2E))
        let open = Int((grow * 2).rounded())
        c.pattern(Int(bx) - 2 - open, Int(by) - 2 - open, petals(open), ["R": C(0xB01E3A), "r": C(0x7A1028), "P": C(0xFF8AB0)])
    }
}

/// The Black Mercy's flower, `open` 0…2 from a closed bud to a full bloom.
private func petals(_ open: Int) -> [String] {
    switch open {
    case 0: return ["..R..", ".RrR.", ".RRR."]
    case 1: return ["R..R..R", ".RRRRR.", "RRrPrRR", ".RRRRR.", "..RRR.."]
    default: return ["R...R...R", ".RR.R.RR.", "..RRRRR..", "RRRrPrRRR", "..RRPRR..", ".RR.R.RR.", "R...R...R"]
    }
}

// MARK: - Trigon

/// Trigon's palm, held out to cast.
private let trigonPalm = (x: 54.0, y: 26.0)

/// Trigon: the demon lord, Raven's father, the biggest thing in the cast, a red-skinned giant with a bare, heavily
/// muscled chest, gold torc and bracelets, a black kilt on a gold belt, the great ivory antlers sweeping out of his
/// skull, four glowing yellow eyes, fangs and a black goatee. Casts hellfire from his outstretched palm. Signature: his
/// four eyes blaze one after another and flames rise out of the ground all round him.
private func drawTrigon(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB82A22), redDark = C(0x861A16), redLight = C(0xE04A3A)
    let gold = C(0xE0B040), goldDark = C(0xA87A20), black = C(0x1A1416), blackLight = C(0x3A2E32)
    let bone = C(0xEDE4CC), boneDark = C(0xB8AC90), eye = C(0xFFE24A), hot = C(0xFFF6C0)
    let power = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    for (i, lx) in [19, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        c.rect(lx, 33, 7, 10 - up, red); c.rect(lx, 33, 1, 10 - up, redLight); c.rect(lx + 6, 33, 1, 10 - up, redDark)
        c.rect(lx, 39 - up, 7, 1, gold)                                     // anklets
        c.rect(lx - 1, 42 - up, 9, 2, redDark)                              // feet
    }
    // Signature: hellfire rising round him (the ones behind him first).
    if let s = p.signature, power > 0.05 {
        drawHellfire(c, xs: [8, 15, 23, 33], t: p.t, s: s, power: power, base: 43.5 - Double(p.hop))
    }
    c.oy += p.breathe
    // The far arm.
    c.rect(10, 18, 5, 14, redDark); c.rect(10, 27, 5, 2, goldDark); c.rect(9, 30, 7, 5, redDark)
    // The torso: a bare, muscled chest.
    c.rect(14, 15, 28, 18, red)
    c.rect(14, 15, 2, 18, redLight); c.rect(40, 15, 2, 18, redDark)
    c.pattern(18, 19, [
        "DDDDDDDD..DDDDDDDD",
        ".DDDDDD....DDDDDD.",
        "................. ",
        "......DD..DD......",
        "..................",
        "......DD..DD......",
        "..................",
        "......DD..DD......",
    ], ["D": redDark])
    c.rect(28, 21, 1, 9, redDark)
    c.rect(18, 17, 6, 1, redLight); c.rect(31, 17, 6, 1, redLight)
    // The kilt and belt.
    c.rect(14, 29, 28, 3, gold); c.rect(14, 31, 28, 1, goldDark)
    c.circle(28, 30, 2, goldDark); c.px(28, 30, C(0xFF3A2A))
    c.rect(15, 32, 26, 6, black)
    for x in [19, 24, 32, 37] { c.rect(x, 32, 1, 6, blackLight) }
    // Shoulders and the gold torc.
    c.pattern(9, 13, ["..RRRRRR..", ".RRLLRRRRR", "RRLRRRRRRR", "RRRRRRRRRR", "RRRRRRRRRR"], ["R": red, "L": redLight])
    c.rect(20, 15, 16, 2, gold); c.rect(20, 16, 16, 1, goldDark)
    // The antlers, out of his skull.
    let horns: [[(Double, Double)]] = [
        [(21, 7), (15, 5), (11, 1), (12, -2)],
        [(37, 7), (43, 5), (47, 1), (46, -2)],
    ]
    for h in horns {
        for i in 0..<(h.count - 1) {
            let r: Double = [1.6, 1.2, 0.8][i]
            bar(c, h[i].0, h[i].1, h[i + 1].0, h[i + 1].1, bone, r: r)
        }
        bar(c, h[0].0, h[0].1 + 1, h[1].0, h[1].1 + 1.2, boneDark, r: 0.5)
        let tine = (x: h[1].0 + (h[2].0 - h[1].0) * 0.3, y: h[1].1 + (h[2].1 - h[1].1) * 0.3)
        bar(c, tine.0, tine.1, tine.0 + (h[1].0 > 28 ? -1 : 1), tine.1 - 4, bone, r: 0.6)
    }
    // The head.
    c.pattern(19, 3, [
        "....RRRRRRRRRR....",
        "..RRRRRRRRRRRRRR..",
        ".RRRRRRRRRRRRRRRR.",
        "RRRRRRRRRRRRRRRRRR",
        "RRRRRRRRRRRRRRRRRR",
        "RRRRRRRRRRRRRRRRRR",
        "RRRRRRRRRRRRRRRRRR",
        "RRRRRRRRRRRRRRRRRR",
        "RRRRRRRRRRRRRRRRRR",
        ".RRRRRRRRRRRRRRRR.",
        "..RRRRRRRRRRRRRR..",
        "....RRRRRRRRRR....",
    ], ["R": red])
    c.rect(20, 4, 2, 4, redLight)
    c.pattern(16, 6, ["R...", "RR..", ".RRR", "..RR"], ["R": redDark])     // the pointed ear
    c.rect(23, 6, 5, 1, black); c.rect(31, 6, 5, 1, black)                 // brows slanting down to the middle
    c.px(27, 7, black); c.px(31, 7, black)
    // The four eyes.
    let spots: [(Int, Int)] = [(24, 7), (32, 7), (24, 10), (32, 10)]
    for (n, e) in spots.enumerated() {
        c.rect(e.0, e.1, 3, 2, eye)
        c.px(e.0 + 1, e.1, hot)
        var lit = p.zap == true ? 0.5 : 0.25
        if let s = p.signature { lit = max(lit, min(1, (s - 0.08 - Double(n) * 0.06) / 0.08) * power) }
        glowDot(c, Double(e.0) + 1.5, Double(e.1) + 1, core: hot.alpha(lit), glow: C(0xFF8A1E).alpha(lit), coreR: 0.5,
                glowR: 1.2 + 1.6 * lit)
    }
    c.rect(29, 9, 1, 3, redDark)
    c.rect(25, 12, 9, 1, black)                                             // the mouth and fangs
    c.px(26, 13, white); c.px(32, 13, white)
    c.pattern(26, 13, ["..KKKKK..", "..KKKKK..", "...KKK...", "....K...."], ["K": black])   // the goatee
    // The near arm: out to cast, or hanging.
    c.pattern(33, 13, ["..RRRRRR..", ".RRLLRRRRR", "RRRRRRRRRR", "RRRRRRRRRD", ".DDDDDDDD."], ["R": red, "L": redLight, "D": redDark])
    if p.zap != nil || power > 0.05 {
        let py = trigonPalm.y - Double(p.armRaise) - 4 * power
        bar(c, 40, 18, 47, py + 1, red, r: 2.3)
        bar(c, 47, py + 1, trigonPalm.x - 2, py, red, r: 2.2)
        bar(c, 47, py - 0.5, 47, py + 2.5, gold, r: 1)
        c.rect(Int(trigonPalm.x) - 2, Int(py) - 2, 2, 5, redLight)
        if power > 0.05 {
            glowDot(c, trigonPalm.x + 1, py - 2, core: hot.alpha(power), glow: C(0xFF3A1E).alpha(power), coreR: 1, glowR: 3 + 2 * power,
                    strength: 0.8 + 0.2 * sin(p.t * 20))
        }
    } else {
        c.rect(38, 17, 5, 13, red); c.rect(42, 17, 1, 13, redDark)
        c.rect(38, 26, 5, 2, gold)
        c.rect(37, 29, 7, 5, red); c.rect(37, 29, 7, 1, redLight); c.rect(43, 29, 1, 5, redDark)
    }
    if let s = p.signature, power > 0.05 {
        c.oy -= p.breathe
        drawHellfire(c, xs: [44, 52, 60, 2], t: p.t + 0.4, s: s, power: power, base: 43.5 - Double(p.hop))
    }
}

/// Tongues of hellfire rising out of the floor at each of `xs`, swelling with `power`.
private func drawHellfire(_ c: PixelCanvas, xs: [Int], t: Double, s: Double, power: Double, base: Double) {
    for (n, x) in xs.enumerated() {
        let rise = min(1, max(0, (s - 0.15 - Double(n) * 0.05) / 0.2)) * power
        guard rise > 0 else { continue }
        let flick = noise(Int(t * 16) + x * 7)
        let h = rise * (7 + noise(x * 3) * 6 + flick * 3)
        let sway = sin(t * 9 + Double(x)) * 1.5
        let x0 = Double(x) + 0.5
        c.glowLine(x0, base - 0.5, x0 + sway, base - h, core: C(0xFFB02A), glow: C(0xE8321A), coreR: 1.1, glowR: 2.6, strength: 0.9)
        c.glowLine(x0, base - 0.5, x0 + sway * 0.6, base - h * 0.55, core: C(0xFFF4C0), glow: C(0xFFB02A), coreR: 0.6, glowR: 1.2)
    }
}

// MARK: - Anti-Monitor

/// The Anti-Monitor's palm, held out to cast.
private let antiMonitorPalm = (x: 52.0, y: 24.0)

/// The Anti-Monitor: the destroyer of worlds from the Crisis, a hovering armoured giant in deep indigo plate with
/// crimson-lit seams, the tall swept fins rising from his shoulders round the helmet, a black skull-like face with
/// two burning white eyes and a slotted jaw, his legs tapering to points over an antimatter glow. Casts antimatter
/// from his outstretched palm. Signature: he raises both arms and an antimatter wave pulses out of his chest.
private func drawAntiMonitor(_ c: PixelCanvas, _ p: Pose) {
    let plate = C(0x3A3484), dark = C(0x221E58), light = C(0x605AB8), face = C(0x0E0C20)
    let red = C(0xE83A3A), hot = C(0xFFE0E0)
    let wave = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    // The antimatter glow he hangs on.
    let flick = noise(Int(p.t * 14))
    c.glowLine(22, 44, 34, 44, core: C(0xFF8A8A, 0.4), glow: red.alpha(0.35), coreR: 0.4, glowR: 2 + flick)
    for (i, lx) in [19, 31].enumerated() {
        let sway = Int((sin(p.lt * 2 + Double(i)) * 0.6).rounded())
        c.pattern(lx + sway, 31, ["PPPPPPP", "PPPPPPP", "LPPPPPD", "DDDDDDD", "PPPPPPP", "PPPPPPD", ".PPPPD.", ".PPPPD.", "..PPD..",
                                  "..PD...", "..P...."], ["P": plate, "D": dark, "L": light])
        c.px(lx + sway + 3, 34, red)
    }
    c.oy += p.breathe
    // The swept fins rising from his shoulders.
    c.pattern(9, 0, [
        "F......................................F",
        "FF....................................FF",
        "FFF..................................FFF",
        "FFFF................................FFFF",
        ".FFFF..............................FFFF.",
        ".FFFFF............................FFFFF.",
        "..FFFFF..........................FFFFF..",
        "..FFFFFF........................FFFFFF..",
        "...FFFFF........................FFFFF...",
        "...FFFFFF......................FFFFFF...",
        "....FFFFF......................FFFFF....",
        "....FFFFFF....................FFFFFF....",
        ".....FFFFF....................FFFFF.....",
        ".....FFFFFF..................FFFFFF.....",
    ], ["F": dark])
    bar(c, 10, 1, 15, 13, light, r: 0.4); bar(c, 47, 1, 42, 13, plate, r: 0.4)
    // The far arm.
    c.rect(10, 17, 5, 14, dark)
    if wave > 0.05 {
        let up = Int((wave * 12).rounded())
        c.rect(9, 16 - up, 6, up + 2, dark); c.rect(8, 13 - up, 7, 4, plate)
    } else {
        c.rect(9, 29, 7, 5, plate)
    }
    // The torso.
    c.rect(15, 13, 26, 19, plate)
    c.rect(15, 13, 2, 19, light); c.rect(39, 13, 2, 19, dark)
    c.pattern(17, 15, ["DDDDDDDDDDD.DDDDDDDDDD", ".DDDDDDDDD...DDDDDDDD.", "..DDDDDDD.....DDDDDD..", "...DDDDD.......DDDD..."],
              ["D": dark])
    let pulse = 0.6 + 0.4 * sin(p.t * 4) + wave * 0.4
    for (x0, y0, x1, y1) in [(28.5, 16.0, 28.5, 30.0), (20.0, 22.0, 37.0, 22.0), (22.0, 27.0, 35.0, 27.0)] as [(Double, Double, Double, Double)] {
        c.glowLine(x0, y0, x1, y1, core: C(0xFF9A9A), glow: red, coreR: 0.4, glowR: 1.3, strength: min(1, pulse))
    }
    glowDot(c, 28.5, 19.5, core: hot, glow: red, coreR: 1, glowR: 2.6 + 1.5 * wave, strength: min(1, pulse))
    c.rect(15, 29, 26, 3, dark); c.rect(15, 29, 26, 1, light)
    c.pattern(10, 11, [".PPPPPPP.", "PPLLPPPPP", "PPPPPPPPP", ".DDDDDDD."], ["P": plate, "L": light, "D": dark])
    // The head: a pointed helmet round a black, skull-like face.
    c.pattern(19, 1, [
        "........PP........",
        ".......PPPP.......",
        "......PPLPPP......",
        ".....PPLPPPPP.....",
        "....PPPPPPPPPP....",
        "...PPPPPPPPPPPP...",
        "..PPPKKKKKKKKKPP..",
        "..PPKKKKKKKKKKKP..",
        ".PPPKKKKKKKKKKKPP.",
        ".PPPKKKKKKKKKKKPP.",
        ".PPPKKKKKKKKKKKPP.",
        ".PPPPKKKKKKKKKPPP.",
        "..PPPPKKKKKKKPPP..",
        "...PPPPKKKKKPPP...",
    ], ["P": plate, "K": face, "L": light])
    c.rect(27, 1, 1, 6, dark)
    let eyeK = 0.7 + 0.3 * wave
    for ex in [25.0, 32.0] {
        c.glowLine(ex - 1, 10, ex + 1.5, 10.5, core: hot, glow: red, coreR: 0.5, glowR: 1.4 + wave, strength: eyeK)
    }
    for x in [26, 28, 30, 32] { c.rect(x, 12, 1, 2, C(0x3A3060)) }          // the slotted jaw
    // The near arm: out to cast, raised for the wave, or hanging.
    c.pattern(36, 11, [".PPPPPPP.", "PPLLPPPPP", "PPPPPPPPP", ".DDDDDDD."], ["P": plate, "L": light, "D": dark])
    if wave > 0.05 {
        let up = Int((wave * 12).rounded())
        c.rect(40, 16 - up, 5, up + 2, plate); c.rect(40, 13 - up, 7, 4, light)
    } else if p.zap != nil {
        let py = antiMonitorPalm.y - Double(p.armRaise)
        bar(c, 40, 16, 46, py + 1, plate, r: 2.2)
        bar(c, 46, py + 1, antiMonitorPalm.x - 2, py, dark, r: 2.3)
        c.rect(Int(antiMonitorPalm.x) - 1, Int(py) - 2, 2, 5, light)
    } else {
        c.rect(38, 15, 5, 13, plate); c.rect(42, 15, 1, 13, dark)
        c.rect(37, 27, 7, 6, dark); c.rect(37, 27, 7, 1, light)
    }
    // Signature: antimatter waves pulse out of his chest.
    if let s = p.signature, wave > 0.05 {
        for i in 0..<3 {
            let f = frac(s * 2.2 - Double(i) / 3)
            guard s > 0.15 + Double(i) * 0.08, s < 0.92 else { continue }
            let r = 3 + f * 30
            ring(c, 28.5, 20, rx: r, ry: r * 0.75, red.alpha(0.9 * (1 - f) * wave))
            ring(c, 28.5, 20, rx: r - 1, ry: r * 0.75 - 1, C(0xFFB0B0).alpha(0.5 * (1 - f) * wave))
        }
    }
}
