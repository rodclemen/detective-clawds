import Foundation

// Heroes: the Bat-family and Gotham. Every one of them is Clawd in costume: cowls, masks, hoods and hair drawn over
// (and around) the blocky body. Where the hero shows a face, it's Clawd's own orange. They have to be told apart at a
// glance, so each keeps one loud tell: Robin's R, Nightwing's blue bird, Batgirl's red hair and yellow bat, Red Hood's
// helmet, Red Robin's wings, Batwoman's red bat, Orphan's stitches, Spoiler's purple hood, Gordon's coat and glasses.

let heroes2: [Companion: Persona] = [
    .robin: Persona(name: "Robin", weapon: .melee, headTop: 21, signature: 2.6, callout: "Tt.",
                    draw: drawRobin),
    .nightwing: Persona(name: "Nightwing", weapon: .melee, motion: .swing, headTop: 21, signature: 2.4,
                        callout: "Too easy.",
                    draw: drawNightwing),
    .batgirl: Persona(name: "Batgirl", weapon: .melee, motion: .swing, headTop: 17, signature: 3.0,
                      callout: "Oracle's online.",
                    draw: drawBatgirl),
    .redHood: Persona(name: "Red Hood", weapon: .ranged, shot: .bullet, muzzle: (47, 32), headTop: 20, signature: 2.8,
                      callout: "Bang.",
                    draw: drawRedHood),
    .redRobin: Persona(name: "Red Robin", weapon: .melee, headTop: 19, signature: 2.8,
                    draw: drawRedRobin),
    .catwoman: Persona(name: "Catwoman", weapon: .melee, headTop: 19, signature: 3.0, callout: "Meow.",
                    draw: drawCatwoman),
    .huntress: Persona(name: "Huntress", weapon: .ranged, shot: .arrow, muzzle: (47, 32), handGun: false, headTop: 21,
                       signature: 3.0,
                    draw: drawHuntress),
    .batwoman: Persona(name: "Batwoman", weapon: .melee, headTop: 17, signature: 2.8,
                    draw: drawBatwoman),
    .orphan: Persona(name: "Orphan", weapon: .melee, headTop: 23, signature: 2.6,
                    draw: drawOrphan),
    .spoiler: Persona(name: "Spoiler", weapon: .melee, headTop: 19, signature: 3.0, callout: "Spoiler alert!",
                    draw: drawSpoiler),
    .commissionerGordon: Persona(name: "Commissioner Gordon", weapon: .ranged, shot: .bullet, muzzle: (48, 32),
                                 headTop: 21, signature: 3.4, callout: "Light it up.",
                    draw: drawGordon),
]

// MARK: - Shared bits

private let hand = Sprite.hand
private let none = C(0, 0)

/// A point `d` pixels out from `h` at `angle` degrees.
private func reach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: none, coreR: r, glowR: r + 0.1)
}

/// A solid bar along `angle` from `a` to `b` pixels out from `h` (sticks, staffs, blades, arms).
private func bar(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ angle: Double, from a: Double, to b: Double, _ col: Px,
                 r: Double = 0.8) {
    let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
    line(c, p0.x, p0.y, p1.x, p1.y, col, r)
}

/// The fading smear a fast swing leaves behind.
private func smear(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ trail: [Double], from a: Double, to b: Double, _ col: Px) {
    for (i, angle) in trail.enumerated() {
        let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// Boots over the bottom of standing legs (seated legs fold away under the body, so they get none).
private func drawBoots(_ c: PixelCanvas, step: Int, _ col: Px, height: Int = 2) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let lifted = step >= 0 && i % 2 == step
        c.rect(lx, (lifted ? 43 : 44) - height, 2, height, col)
    }
}

/// A punch: the arm thrown out along `angle`, a fist on the end and faint fists where a fast swing just was.
private func drawPunch(_ c: PixelCanvas, angle: Double, trail: [Double], arm: Px, fist: Px, reach len: Double = 7) {
    for (i, a) in trail.enumerated() {
        let e = reach(hand, a, len)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist.alpha(0.35 / Double(i + 1)))
    }
    let e = reach(hand, angle, len)
    line(c, hand.x - 2, hand.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, fist)
}

/// A bo staff gripped in the middle: a long bar through the hand, end caps, a smear when it's swung fast.
private func drawStaff(_ c: PixelCanvas, angle: Double, trail: [Double], pole: Px, cap: Px, wrap: Px, smearCol: Px) {
    smear(c, hand, trail, from: -9, to: 13, smearCol)
    bar(c, hand, angle, from: -9, to: 13, pole, r: 0.75)
    bar(c, hand, angle, from: 11.5, to: 13, cap, r: 0.8)
    bar(c, hand, angle, from: -9, to: -7.5, cap, r: 0.8)
    bar(c, hand, angle, from: -1.5, to: 1.5, wrap, r: 0.85)
}

/// The legs of a swinger on the move: trailing back and down from the hips, boots at the ends.
private func drawSwingLegs(_ c: PixelCanvas, step: Int, leg: Px, boot: Px) {
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let kick = (i + max(0, step)) % 2
        for r in 0..<7 { c.rect(lx - r / 2 - kick, 36 + r, 2, 1, r >= 5 ? boot : leg) }
    }
}

/// A swinger's right hand up on the grapnel line, at (41, 22) where the renderer ties the line on.
private func drawLineHand(_ c: PixelCanvas, arm: Px, glove: Px) {
    line(c, 39, 32, 41, 23, arm, 1.1)
    c.rect(40, 21, 3, 3, glove)
    c.px(41, 20, C(0x5A5A66))                       // the grapnel gun's nose
}

/// A cape streaming out behind a swinger, from the shoulders back and down.
private func drawStreamingCape(_ c: PixelCanvas, t: Double, color: Px, edge: Px) {
    for x in 4...19 {
        let k = Double(19 - x) / 15
        let mid = 31 + k * 5 + sin(t * 9 - k * 5) * k * 1.6
        let half = 3.5 + k * 2
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, color)
        c.px(x, top, edge); c.px(x, bottom, edge)
    }
}

/// A cape that stops short of the knees (`bottom` row), its hem in the lining colour.
private func drawShortCape(_ c: PixelCanvas, t: Double, speed: Double, color: Px, lining: Px, bottom: Int) {
    for y in 27...bottom where y + c.oy <= 43 {
        let k = Double(y - 27) / Double(bottom - 27)
        let hw = 10.5 + k * 3
        let sway = sin(t * speed + k * 2.2) * k * 1.4
        let l = Int((Sprite.bodyCenterX - hw + sway).rounded()), r = Int((Sprite.bodyCenterX + hw + sway).rounded()) - 1
        c.rect(l, y, r - l + 1, 1, y == bottom ? lining : color)
        c.px(l, y, lining)
    }
}

/// A domino mask across the eyes, white lenses over Clawd's eyes. `flare` turns the outer corners up.
private func drawDomino(_ c: PixelCanvas, _ mask: Px, lens: Px = white, flare: Bool = false) {
    c.pattern(18, 27, [
        flare ? "K..................K" : "....................",
        ".KKKKKKKKKKKKKKKKKK.",
        "KKKKWWKKKKKKKKWWKKKK",
        "KKKKWWKKKKKKKKWWKKKK",
        "..KKKKK......KKKKK..",
    ], ["K": mask, "W": lens])
}

/// The bat cowl Batgirl and Batwoman wear: pointed ears, white lenses, the mouth and chin left bare.
private func drawCowl(_ c: PixelCanvas, _ cowl: Px, _ shade: Px, lips: Px? = nil) {
    c.pattern(17, 17, [
        "...K..............K...",
        "...KK............KK...",
        "...KKK..........KKK...",
        "..KKKKKKKKKKKKKKKKKK..",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKWWKKKKKKKKWWKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKSSSSSSSSSSSSSSSSKk.",
        "..KKSSSSSSmmSSSSSSKK..",
    ], ["K": cowl, "k": shade, "W": white, "S": clawdOrange, "m": lips ?? clawdShade])
}

/// Draws `art` on a layer of its own, turns it `degrees` about the middle of the body (negative: over backwards) and
/// lays it over `c` raised `lift` pixels.
private func turned(_ c: PixelCanvas, degrees: Double, lift: Double, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let pivot = (x: 28.0 + Double(c.ox), y: 33.0 + Double(c.oy + c.baseY))
    let r = s.rotated(degrees, about: pivot, into: c.w, c.h, at: (pivot.x, pivot.y - lift))
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    c.paste(r)
}

/// Draws `art` on a layer of its own and lays it over `c` faded to `alpha`: for someone vanishing into smoke.
private func ghost(_ c: PixelCanvas, alpha: Double, _ art: (PixelCanvas) -> Void) {
    guard alpha > 0.02 else { return }
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x, y, unpremultiplied(s, i).alpha(alpha))
        }
    }
}

/// Draws `art` (its pivot at (20.5, 20.5) on a 41×41 sheet) turned `angle` degrees, the pivot landing on `at`.
private func prop(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(41, 41)
    art(s)
    let r = s.rotated(angle, about: (20.5, 20.5), into: 41, 41, at: (20.5, 20.5))
    let x0 = Int(floor(at.x - 20.5)), y0 = Int(floor(at.y - 20.5))
    for y in 0..<r.h {
        for x in 0..<r.w {
            let i = (y * r.w + x) * 4
            guard r.buf[i + 3] > 0 else { continue }
            c.px(x0 + x, y0 + y, unpremultiplied(r, i).alpha(alpha))
        }
    }
}

private func unpremultiplied(_ s: PixelCanvas, _ i: Int) -> Px {
    let a = s.buf[i + 3], m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a)
}

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white.alpha(Double(col.a) / 255))
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

// MARK: - Robin

/// Robin (Damian Wayne): Clawd with spiky black hair and a black domino mask, the red tunic with the yellow R in its
/// circle, a yellow belt, green sleeves and leggings, and a short black hooded cape lined in yellow, the hood down.
/// A katana in a green scabbard on his back; it comes out to fight. Signature: a leaf drifts down in front of him, he
/// draws and cuts it in half in one stroke, holds the pose and sheathes.
private func drawRobin(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redD = C(0x8A1418), green = C(0x2E8A3E), greenD = C(0x1E5E2A)
    let yellow = C(0xF2C230), cape = C(0x1C1C24), hair = C(0x16161C), boot = C(0x1E1E24)
    var angle = p.melee, trail = p.trail
    let sig = p.signature
    if let s = sig, s > 0.5, s < 0.88 {
        let len = p.who.persona.signature ?? 2.6, t0 = p.t
        let cut = { (u: Double) -> Double in
            let k = s + (u - t0) / len
            if k < 0.5 { return -110 }
            if k < 0.56 { let f = (k - 0.5) / 0.06; return -110 + 135 * (1 - pow(1 - f, 3)) }
            if k < 0.76 { return 25 }
            let f = min(1, (k - 0.76) / 0.1)
            return 25 - 115 * f * f * (3 - 2 * f)
        }
        angle = cut(p.t); trail = swingTrail(p.t, pose: cut)
    }
    drawShortCape(c, t: p.t, speed: p.capeSpeed, color: cape, lining: yellow, bottom: 38)
    // The scabbard across his back, the hilt over his left shoulder while the sword's in it.
    line(c, 15, 23, 29, 40, greenD, 0.9)
    if angle == nil {
        line(c, 12, 19, 15, 23, C(0x2A2A30), 0.8)
        line(c, 13, 24, 16, 21, C(0xB8A040), 0.6)
    }
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, step: p.step, boot, height: 3)
    c.oy += p.breathe
    // The hood, down, bunched behind his neck.
    c.pattern(14, 24, ["..KKK", ".KYYK", "KYYK.", "KYK..", "KK..."], ["K": cape, "Y": yellow])
    drawBody(c, Look(arm: green))
    c.pattern(18, 21, [
        "....H..HH.H..H.H....",
        "...HHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "HHH.HHH.HH.HHHH.HHHH",
        "HH...H....H...H...HH",
    ], ["H": hair])
    drawDomino(c, C(0x101014))
    // Tunic, belt, the R.
    c.rect(27, 32, 2, 1, clawdShade)
    c.rect(18, 33, 20, 4, red); c.rect(37, 33, 1, 4, redD)
    c.pattern(16, 33, ["GG.", "GGG"], ["G": green])
    c.rect(18, 37, 20, 1, yellow); c.px(24, 37, C(0xC09018)); c.px(25, 37, C(0xC09018))
    c.pattern(29, 33, [".YYYY", "YKKYY", "YKYKY", "YKKYY", "YKYKY"], ["Y": yellow, "K": C(0x101014)])
    c.rect(15, 35, 3, 1, greenD)
    if let a = angle {
        drawBlade(c, angle: a, trail: trail)
        c.rect(38, 33, 3, 3, green)
    } else {
        c.rect(38, 35, 3, 1, greenD)
    }
    // The leaf: whole until the cut goes through it, then two halves seesawing down.
    if let s = sig, s > 0.04 {
        let leaf = C(0x8AC23A), vein = C(0x4E8A22)
        if s < 0.515 {
            let x = Int((48 + sin(s * 18) * 2).rounded()), y = Int((2 + (s - 0.04) / 0.475 * 25).rounded())
            c.rect(x - 1, y, 3, 1, leaf); c.px(x, y - 1, leaf); c.px(x, y + 1, leaf); c.px(x, y, vein); c.px(x + 2, y + 1, vein)
        } else if s < 0.98 {
            let k = (s - 0.515) / 0.465
            let fade = s > 0.85 ? (0.98 - s) / 0.13 : 1
            let y = min(43, Int((27 + k * 16).rounded()))
            for side in [-1.0, 1.0] {
                let x = Int((48 + side * (1 + k * 6) + sin(k * 9 + side) * 1.5).rounded())
                let tip = Int(k * 8) % 2 == 0 ? 1 : 0
                c.rect(x, y + (side < 0 ? tip : 1 - tip), 2, 1, leaf.alpha(fade))
                c.px(x + (side < 0 ? 0 : 1), y + (side < 0 ? 1 - tip : tip), vein.alpha(fade))
            }
            if s < 0.56 { twinkle(c, 48, 27, C(0xFFFFFF, 0.9)) }
        }
    }
}

/// Robin's katana in the hand at `angle`: a dark grip, a small gold guard and a slightly curved blade.
private func drawBlade(_ c: PixelCanvas, angle: Double, trail: [Double]) {
    let steel = C(0xB4BAC4), edge = C(0xF0F4F8)
    for (i, a) in trail.enumerated() {
        let s = reach(hand, a, 3), e = reach(hand, a, 17)
        c.glowLine(s.x, s.y, e.x, e.y, core: edge.alpha(0.5), glow: edge.alpha(0.5), coreR: 0.4, glowR: 1.4,
                   strength: 0.45 / Double(i + 1))
    }
    let r = angle * .pi / 180, ux = cos(r), uy = sin(r), nx = -uy, ny = ux
    bar(c, hand, angle, from: -2.5, to: 1.5, C(0x2A2A30), r: 0.8)
    line(c, hand.x + ux * 2 - nx * 1.5, hand.y + uy * 2 - ny * 1.5, hand.x + ux * 2 + nx * 1.5, hand.y + uy * 2 + ny * 1.5,
         C(0xB8A040), 0.6)
    var prev = (x: hand.x + ux * 2.5, y: hand.y + uy * 2.5)
    for i in 1...4 {
        let f = Double(i) / 4, bend = 1.2 * f * f
        let q = (x: hand.x + ux * (2.5 + 14 * f) - nx * bend, y: hand.y + uy * (2.5 + 14 * f) - ny * bend)
        line(c, prev.x, prev.y, q.x, q.y, steel, 0.8)
        prev = q
    }
    line(c, hand.x + ux * 3 + nx * 0.4, hand.y + uy * 3 + ny * 0.4, prev.x, prev.y, edge, 0.45)
}

// MARK: - Nightwing

/// Nightwing (Dick Grayson): Clawd with swept-back black hair and a black domino mask, the black suit with the blue
/// bird across his chest, its wings running out to blue hands; two escrima sticks, crossed on his back until he needs
/// them, crackling blue when he hits. Travelling, he swings on a grapnel line. Signature: a standing backflip.
private func drawNightwing(_ c: PixelCanvas, _ p: Pose) {
    if let s = p.signature, s > 0.1, s < 0.9 {
        let k = (s - 0.1) / 0.8
        let e = 0.5 - 0.5 * cos(k * .pi)
        turned(c, degrees: -360 * e, lift: 13 * sin(k * .pi)) { nightwing($0, p, tuck: sin(k * .pi) > 0.3) }
        return
    }
    nightwing(c, p, tuck: false)
}

private func nightwing(_ c: PixelCanvas, _ p: Pose, tuck: Bool) {
    let suit = C(0x1A1A22), suitL = C(0x30303C), blue = C(0x2A8AF0), blueL = C(0x8ACCFF), hair = C(0x121218)
    let stick = C(0x22222A)
    let swinging = p.walking
    let look = Look(leg: suit, arm: blue)
    let fighting = !swinging ? p.melee : nil
    // The sticks: crossed on his back, or the left one up behind him while the right one works.
    if fighting == nil {
        line(c, 13, 21, 22, 33, stick, 0.8); line(c, 21, 21, 14, 33, stick, 0.8)
        c.px(13, 21, blue); c.px(21, 21, blue)
    } else {
        line(c, 16.5, 34.5, 10, 26, stick, 0.8); line(c, 10.6, 26.8, 10, 26, blue, 0.8)
    }
    if swinging {
        drawSwingLegs(c, step: p.step, leg: suit, boot: suitL)
    } else if tuck {
        for lx in [19, 23, 31, 35] { c.rect(lx, 36, 2, 4, suit) }
    } else {
        drawLegs(c, look, step: p.step)
        drawBoots(c, step: p.step, C(0x2A2A36), height: 3)
    }
    c.oy += p.breathe
    drawBody(c, look)
    c.pattern(16, 21, [
        ".......HHHHHHHHH......",
        "....HHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHhHHHHHHhHHHH",
        "HHHHH....H.......H..HH",
        "HHHH..................",
        "HHH...................",
        "HHH...................",
        ".H....................",
    ], ["H": hair, "h": C(0x2A2A3A)])
    drawDomino(c, C(0x0E0E14))
    c.rect(27, 32, 2, 1, clawdShade)
    c.rect(18, 33, 20, 5, suit); c.rect(37, 33, 1, 5, C(0x101016))
    c.pattern(18, 33, [
        "BBB..............BBB",
        ".BBBB..........BBBB.",
        "...BBBB......BBBB...",
        ".....BBBB..BBBB.....",
        ".......BBBBBB.......",
    ], ["B": blue])
    c.px(18, 33, blueL); c.px(37, 33, blueL)
    c.rect(18, 37, 20, 1, suitL)
    c.rect(15, 33, 3, 3, blue); c.px(15, 33, suit)
    if swinging {
        drawLineHand(c, arm: suit, glove: blue)
        return
    }
    if let a = fighting {
        smear(c, hand, p.trail, from: 1, to: 10, blueL)
        bar(c, hand, a, from: -2, to: 10, stick, r: 0.8)
        bar(c, hand, a, from: 8, to: 10, blue, r: 0.85)
        if !p.trail.isEmpty || p.mode == .working && Int(p.t * 14) % 3 == 0 {
            // Charged: a crackle at the tip.
            let tip = reach(hand, a, 10)
            c.glowLine(tip.x, tip.y, tip.x, tip.y, core: C(0xE8F8FF), glow: C(0x4AA8FF), coreR: 0.6, glowR: 2)
            let seed = Int(p.t * 30)
            for k in 0..<3 {
                let b = noise(seed * 3 + k) * 2 * .pi, d = 1.5 + noise(seed * 5 + k) * 2
                c.px(Int(tip.x + cos(b) * d), Int(tip.y + sin(b) * d), k == 0 ? white : blueL)
            }
        }
        c.rect(38, 33, 3, 3, blue)
    }
}

// MARK: - Batgirl

/// Batgirl (Barbara Gordon): Clawd in the dark purple-grey suit under a pointed-eared cowl, long red hair spilling out
/// of the back of it, the yellow bat on her chest, yellow belt, gloves and boots, and a cape lined in gold. She fights
/// with her fists and swings on a grapnel line, hair and cape streaming. Signature: Oracle at work, a holo-screen
/// opens over her wrist and she types away at it.
private func drawBatgirl(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x3E3858), suitD = C(0x28243C), yellow = C(0xF2C430), yellowD = C(0xC0961E)
    let hair = C(0xD0502A), hairD = C(0x962E18), cape = C(0x1C1A2C)
    let swinging = p.walking
    let look = Look(body: suit, shade: suitD, leg: suit, arm: suit, eye: nil)
    if swinging {
        drawStreamingCape(c, t: p.t, color: cape, edge: yellowD)
        c.oy += p.breathe
        c.pattern(4, 22, [
            ".......HHHHHHHHHHH",
            "...HHHHHHHhHHHHHHH",
            "HHHHHHhHHHHHHHHHHH",
            ".HHHHHHHHhHHHHHHHH",
            "...HHHhHHHHHHHH...",
            ".......HHHHH......",
        ], ["H": hair, "h": hairD])
        c.oy -= p.breathe
        drawSwingLegs(c, step: p.step, leg: suit, boot: yellow)
    } else {
        drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: yellowD)
        c.oy += p.breathe
        c.pattern(11, 22, [
            "......HHH",
            "....HHHHH",
            "...HHHHHH",
            "..HHHHhHH",
            "..HHHhHHH",
            ".HHHhHHH.",
            ".HHhHHHH.",
            ".HHHhHHH.",
            "..HHhHHH.",
            "..HHHhHH.",
            ".HHHHhHH.",
            ".HHhHHHH.",
            "HHH.HHh..",
            "HH..HH...",
            "H....H...",
        ], ["H": hair, "h": hairD])
        c.oy -= p.breathe
        drawLegs(c, look, step: p.step)
        drawBoots(c, step: p.step, yellow, height: 3)
    }
    c.oy += p.breathe
    let oracle = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    drawBody(c, look)
    drawCowl(c, suit, suitD)
    c.pattern(20, 34, ["YY....Y..Y....YY", "YYYYYYYYYYYYYYYY", ".YYY.YYYYYY.YYY."], ["Y": yellow])
    c.rect(18, 37, 20, 1, yellow); c.rect(27, 37, 2, 1, yellowD)
    c.rect(15, 33, 3, 3, yellow)
    if swinging {
        drawLineHand(c, arm: suit, glove: yellow)
        return
    }
    if oracle > 0.05 {
        // The holo-screen, thrown up from her wrist: lines of text typing themselves out, a blinking cursor.
        let s = p.signature ?? 0
        let a = oracle
        let glow = C(0x4AE0FF)
        for k in 0..<3 { line(c, 40, 33, 42 + Double(k) * 5, 31, glow.alpha(0.18 * a), 0.5) }
        c.rect(41, 21, 12, 10, glow.alpha(0.22 * a))
        c.rect(41, 21, 12, 1, glow.alpha(0.8 * a)); c.rect(41, 30, 12, 1, glow.alpha(0.8 * a))
        c.rect(41, 21, 1, 10, glow.alpha(0.6 * a)); c.rect(52, 21, 1, 10, glow.alpha(0.6 * a))
        let typed = Int(s * 34)
        for (i, y) in [23, 25, 27].enumerated() {
            let n = min(9, max(0, typed - i * 9))
            for x in 0..<n where noise(i * 13 + x) > 0.25 { c.px(43 + x, y, C(0xC8F8FF).alpha(a)) }
            if n > 0 && n < 9 && Int(p.t * 6) % 2 == 0 { c.px(43 + n, y, white.alpha(a)) }
        }
        c.pattern(44, 28, ["O.C.L"], ["O": C(0xFF9A6A).alpha(a), "C": C(0xFF9A6A).alpha(a), "L": C(0xFF9A6A).alpha(a)])
        let tap = Int(p.t * 12) % 2
        c.rect(38, 31 + tap, 3, 3, yellow)
        return
    }
    if let a = p.melee {
        drawPunch(c, angle: a, trail: p.trail, arm: suit, fist: yellow)
    } else {
        c.rect(38, 33, 3, 3, yellow)
    }
}

// MARK: - Red Hood

/// Red Hood (Jason Todd): Clawd under the smooth red helmet with its white eye slits, a brown leather jacket open
/// over a grey shirt with a red bat, dark trousers and boots, a pistol in each hand. Signature: he twirls both
/// pistols round his trigger fingers, three turns, and snaps them level.
private func drawRedHood(_ c: PixelCanvas, _ p: Pose) {
    let helmet = C(0xC41E26), helmetD = C(0x86121A), shine = C(0xF07078)
    let jacket = C(0x6A4428), jacketD = C(0x48301C), shirt = C(0x2E2E36), legs = C(0x2A2A32)
    drawLegs(c, Look(leg: legs), step: p.step)
    drawBoots(c, step: p.step, C(0x1A1A1E), height: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: shirt, shade: C(0x2A2A32), leg: legs, arm: jacket, eye: nil))
    c.pattern(17, 20, [
        "......RRRRRRRRRR......",
        "....RRRRRRRRRRRRRR....",
        "...RRLLRRRRRRRRRRRR...",
        "..RRLLRRRRRRRRRRRRRr..",
        "..RRLRRRRRRRRRRRRRRr..",
        ".RRRRRRRRRRRRRRRRRRRr.",
        ".RRRRRRRRRRRRRRRRRRRr.",
        ".RRRRRRRRRRRRRRRRRRRr.",
        ".RRRRRRRRRRRRRRRRRRRr.",
        ".RRRRWWWRRRRRRRWWWRRr.",
        ".RRRRRWWRRRRRRRWWRRRr.",
        ".RRRRRRRRRRRRRRRRRRRr.",
        ".rRRRRRRRRRRRRRRRRRrr.",
        "..rrrrrrrrrrrrrrrrrr..",
    ], ["R": helmet, "r": helmetD, "L": shine, "W": white])
    // The jacket: open down the front, collar up, the red bat on the shirt between.
    c.rect(18, 33, 3, 5, jacket); c.rect(35, 33, 3, 5, jacket)
    c.rect(20, 33, 1, 5, jacketD); c.rect(35, 33, 1, 5, jacketD); c.rect(37, 33, 1, 5, jacketD)
    c.pattern(16, 31, ["KK", "KK", ".K"], ["K": jacket])
    c.pattern(38, 31, ["KK", "KK", "K."], ["K": jacket])
    c.pattern(21, 34, [".R....RR....R.", "RRRR.RRRR.RRRR", ".RRRRRRRRRRRR.", "...RR.RR.RR..."], ["R": C(0xD0202A)])
    c.rect(18, 37, 20, 1, C(0x22222A))
    c.rect(15, 33, 3, 3, jacket)

    let gun = { (s: PixelCanvas) in drawPistol(s, x: 19, y: 18, body: C(0x26262C), trim: C(0x9AA0AC)) }
    let gun2 = { (s: PixelCanvas) in drawPistol(s, x: 19, y: 18, body: C(0x1A1A20), trim: C(0x6A707C)) }
    if let s = p.signature, s > 0.08, s < 0.96 {
        if s < 0.72 {
            let k = (s - 0.08) / 0.64
            let a = 1080 * (0.5 - 0.5 * cos(k * .pi))
            prop(c, at: (40.5, 37.5), angle: a + 40, gun2)
            c.rect(37, 36, 3, 3, jacketD)
            prop(c, at: (41.5, 33.5), angle: a, gun)
            c.rect(38, 33, 3, 3, jacket)
        } else {
            // Snapped level, both barrels on you.
            c.oy -= 1
            c.rect(37, 36, 3, 3, jacketD); drawPistol(c, x: 39, y: 35, body: C(0x1A1A20), trim: C(0x6A707C))
            c.rect(38, 33, 3, 3, jacket); drawPistol(c, x: 40, y: 31, body: C(0x26262C), trim: C(0x9AA0AC))
            if s < 0.78 { twinkle(c, 46, 31, C(0xFFFFFF, 0.9)) }
        }
        return
    }
    c.oy += p.gunY
    c.rect(37, 36, 3, 3, jacketD); drawPistol(c, x: 39, y: 35, body: C(0x1A1A20), trim: C(0x6A707C))
    c.rect(38, 33, 3, 3, jacket); drawPistol(c, x: 40, y: 31, body: C(0x26262C), trim: C(0x9AA0AC))
    if let f = p.fire, frac((f.t + shotPeriod / 2) / shotPeriod) < 0.08 {
        // The other gun fires on the off-beat.
        c.rect(46, 35, 2, 3, C(0xFFE27A)); c.px(48, 36, C(0xFFF6C8))
    }
}

// MARK: - Red Robin

/// Red Robin (Tim Drake): Clawd in a red cowl-hood with a black domino mask, the red suit with black gloves, leggings
/// and a black bird on the chest, a yellow belt, and the black wing-cape lined in red that hangs half-folded at his
/// shoulders like a pair of wings. Fights with a bo staff, collapsed on his belt between fights. Signature: he spreads
/// the wings wide and rises onto his toes, a glider about to go.
private func drawRedRobin(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB81A22), redD = C(0x7E1016), black = C(0x1A1A20), blackL = C(0x30303A), yellow = C(0xE8B830)
    let spread = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let rise = spread > 0.6 ? -1 : 0
    c.oy += rise
    let open = 0.22 + 0.78 * spread + (p.walking ? 0.05 * sin(p.t * 8) : 0)
    drawWings(c, open: open, t: p.t, black: black, rib: blackL, lining: red)
    c.oy -= rise
    drawLegs(c, Look(leg: black), step: p.step)
    drawBoots(c, step: p.step, red, height: 2)
    c.oy += p.breathe + rise
    drawBody(c, Look(body: clawdOrange, arm: black))
    // Cowl-hood round the face.
    c.pattern(16, 19, [
        "......RRRRRRRRRRRR......",
        "....RRRRRRRRRRRRRRRR....",
        "...RRRRRRRRRRRRRRRRRR...",
        "..RRRRRRRRRRRRRRRRRRRR..",
        "..RRRRRRRRRRRRRRRRRRRr..",
        ".RRRRRRRRRRRRRRRRRRRRRr.",
        ".RRRrrrrrrrrrrrrrrrRRRr.",
        ".RRR..............RRRr..",
        ".RRR...............RRr..",
        ".RR................RRr..",
        ".RR................RRr..",
        ".RR................RRr..",
        ".RRR..............RRRr..",
        ".RRRR............RRRRr..",
    ], ["R": red, "r": redD])
    drawDomino(c, C(0x101014))
    c.rect(18, 33, 20, 4, red); c.rect(37, 33, 1, 4, redD)
    c.rect(18, 33, 3, 4, black); c.rect(35, 33, 3, 4, black)
    c.pattern(29, 33, ["Y..Y", "YKKY", ".KK."], ["K": black, "Y": yellow])
    c.rect(18, 37, 20, 1, yellow)
    c.rect(15, 33, 3, 3, black)
    let staff = C(0xA4AAB4)
    if let a = p.melee {
        drawStaff(c, angle: a, trail: p.trail, pole: staff, cap: C(0xE0E4EA), wrap: black, smearCol: C(0xE0E4EA))
        c.rect(38, 33, 3, 3, black)
    } else {
        c.rect(34, 36, 3, 2, staff); c.px(34, 36, C(0xE0E4EA))
        c.rect(38, 33, 3, 3, black)
    }
}

/// Red Robin's wing-cape: two black wings hung from the shoulders, scalloped along the bottom, red showing at the
/// edges. `open` 0…1 spreads them out from folded to a full glide.
private func drawWings(_ c: PixelCanvas, open: Double, t: Double, black: Px, rib: Px, lining: Px) {
    for side in [-1, 1] {
        let span = 3 + 15 * open
        let n = Int(span.rounded())
        for d in 0...n {
            let f = Double(d) / max(1, span)
            let x = side < 0 ? 17 - d : 38 + d
            let top = Int((26 - 6 * f * open - (side < 0 ? 0 : 1)).rounded())
            let scallop = [0, 1, 2, 2, 1][d % 5]
            var bottom = Int((42 - f * (6 + 6 * open)).rounded()) - scallop
            if side > 0 { bottom -= 2 }
            let flutter = open > 0.6 ? Int((sin(t * 7 + f * 3) * f).rounded()) : 0
            c.rect(x, top + flutter, 1, max(1, bottom - top + 1), black)
            c.px(x, top + flutter, lining)
            c.px(x, bottom + flutter, lining)
            if d % 5 == 0 && d > 0 { c.rect(x, top + flutter + 1, 1, max(1, bottom - top - 2), rib) }
        }
    }
}

// MARK: - Catwoman

/// Catwoman (Selina Kyle): Clawd in the black catsuit with a silver zip, a cowl with short cat ears and round goggles
/// over the eyes, her mouth left bare; a whip in her hand, coiled at her hip when she's not using it. Signature: she
/// pushes the goggles up, holds a stolen diamond to the light, admires it, and it disappears into a pocket.
private func drawCatwoman(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E1E28), sheen = C(0x3A3A4C), silver = C(0xC8CCD4), lens = C(0x2E6A5A), lensL = C(0x8AE0C0)
    let leather = C(0x3A2A24)
    let sig = p.signature
    let admire = sig.map { $0 > 0.12 && $0 < 0.86 } ?? false
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, step: p.step, C(0x101016), height: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: suit, shade: C(0x121218), arm: suit, eye: nil))
    c.pattern(17, 19, [
        "..KK..............KK..",
        "..KKK............KKK..",
        "..KKKK..........KKKK..",
        "..KKKKKKKKKKKKKKKKKK..",
        ".KKKLKKKKKKKKKKKKKKKk.",
        ".KKLLKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKKKKKKKKKKKKKKKKKKk.",
        ".KKSSSSSSSSSSSSSSSSKk.",
        "..KSSSSSSSmmSSSSSSSK..",
        "..KKSSSSSSSSSSSSSSKK..",
    ], ["K": suit, "k": C(0x121218), "L": sheen, "S": clawdOrange, "m": C(0xA03040)])
    for (x, y) in [(20, 20), (20, 21), (21, 21), (35, 20), (35, 21), (34, 21)] { c.px(x, y, C(0xB05A78)) }   // inside the ears
    let goggles = ["..RR..", ".RLLR.", "RLlLLR", "RLLLLR", ".RLLR.", "..RR.."]
    if admire {
        // Goggles up on her forehead; her eyes half-lidded, pleased with herself.
        c.pattern(20, 22, goggles.prefix(4).map { String($0) }, ["R": silver, "L": lens, "l": lensL])
        c.pattern(30, 22, goggles.prefix(4).map { String($0) }, ["R": silver, "L": lens, "l": lensL])
        c.rect(20, 28, 16, 4, clawdOrange)
        c.rect(22, 30, 2, 2, ink); c.rect(32, 30, 2, 2, ink)
        c.rect(21, 29, 4, 1, suit); c.rect(31, 29, 4, 1, suit)
    } else {
        c.pattern(20, 27, goggles, ["R": silver, "L": lens, "l": lensL])
        c.pattern(30, 27, goggles, ["R": silver, "L": lens, "l": lensL])
        c.rect(26, 29, 4, 1, silver)
    }
    // Zip down the front.
    c.rect(28, 34, 1, 4, silver); c.px(28, 34, white)
    c.rect(18, 37, 20, 1, C(0x121218))
    c.rect(15, 33, 3, 3, suit)
    if admire, let s = sig {
        let k = min(1, (s - 0.12) / 0.12)
        let y = 32 - Int((5 * k).rounded())
        c.rect(38, y, 3, 3, suit)
        let gem = C(0xBFF4FF), gemD = C(0x5AB8E0)
        c.pattern(40, y - 4, [".WG.", "WGGg", ".Gg.", "..g."].map { String($0) }, ["W": white, "G": gem, "g": gemD])
        if Int(p.t * 8) % 3 == 0 || (s > 0.4 && s < 0.5) { twinkle(c, 43, y - 5, C(0xFFFFFF, 0.9)) }
        drawCoil(c, leather)
        return
    }
    if let a = p.melee {
        drawWhip(c, angle: a, trail: p.trail, t: p.t, leather: leather)
        c.rect(38, 33, 3, 3, suit)
    } else {
        c.rect(38, 33, 3, 3, suit)
        drawCoil(c, leather)
    }
}

/// The whip coiled at Catwoman's hip.
private func drawCoil(_ c: PixelCanvas, _ leather: Px) {
    c.pattern(33, 35, [".LLL.", "L...L", "LL.LL", ".LLL."], ["L": leather])
    c.px(35, 39, leather)
}

/// Catwoman's whip from the hand at `angle`: a short grip, then the lash, lagging behind a fast swing and curling at the
/// tip.
private func drawWhip(_ c: PixelCanvas, angle: Double, trail: [Double], t: Double, leather: Px) {
    smear(c, hand, trail, from: 3, to: 17, C(0xC8B8E8))
    bar(c, hand, angle, from: -2, to: 2.5, C(0x101014), r: 0.8)
    let lag = trail.first.map { $0 - angle } ?? 0
    var prev = reach(hand, angle, 2.5)
    let n = 9
    for i in 1...n {
        let f = Double(i) / Double(n)
        let sag = (lag == 0 ? 30 : 10) * f * f * cos(angle * .pi / 180)        // it hangs a little, unless it's cracking
        let a = (angle + lag * f * f * 0.9 + sag + sin(t * 9 - f * 5) * 8 * f) * .pi / 180
        let q = (x: prev.x + cos(a) * 1.8, y: prev.y + sin(a) * 1.8)
        line(c, prev.x, prev.y, q.x, q.y, i == n ? C(0x8A6A5A) : leather, i < 4 ? 0.65 : 0.5)
        prev = q
    }
}

// MARK: - Huntress

/// Huntress (Helena Bertinelli): Clawd with long black hair, a purple domino mask with flared corners, the purple suit
/// with the white cross on her chest, a gold belt and a short purple cape; a crossbow in her hand, a quiver of bolts on
/// her back. Signature: she pulls a bolt from the quiver, loads, cocks and raises the crossbow to aim.
private func drawHuntress(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x6A2E9A), purpleD = C(0x46186A), purpleL = C(0x9A62CC), hair = C(0x16141C), gold = C(0xD8A830)
    let sig = p.signature
    let pulled = sig.map { $0 > 0.08 && $0 < 0.36 ? ($0 - 0.08) / 0.28 : 0 } ?? 0
    let loaded = sig.map { $0 >= 0.36 } ?? true
    let aiming = sig.map { $0 > 0.5 && $0 < 0.95 } ?? false
    drawShortCape(c, t: p.t, speed: p.capeSpeed, color: purpleD, lining: purple, bottom: 39)
    c.oy += p.breathe
    // Quiver behind the left shoulder.
    c.pattern(12, 20, ["R.R.", "wRwR", ".QQQ", ".QQQ", "..QQq", "..QQQ", "...QQ"],
              ["R": C(0xC83A2A), "w": C(0xE8E0D0), "Q": C(0x3A2A40), "q": C(0x2A1E30)])
    if pulled > 0 {
        let y = 20 - Int((pulled * 6).rounded())
        c.rect(14, y, 1, 6, C(0x8A6A3A)); c.px(14, y - 1, C(0xC8CCD4)); c.px(13, y + 5, C(0xC83A2A))
        c.rect(15, 26, 3, 3, purple)                                         // reaching back for it
    }
    c.oy -= p.breathe
    drawLegs(c, Look(leg: purpleD), step: p.step)
    drawBoots(c, step: p.step, purple, height: 3)
    c.oy += p.breathe
    // Her hair falls down her back, behind her.
    c.pattern(13, 26, ["HHHHH", "HHHHH", ".HHHH", ".HHhH", "..HHH", ".HHHH", "..HhH", "...HH", "...H."], ["H": hair, "h": C(0x2E2A38)])
    drawBody(c, Look(body: clawdOrange, arm: purple))
    c.pattern(17, 20, [
        ".......HHHHHHHH.......",
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHhh.HHHHHHHH.",
        "HHHHHh..........hHHHH.",
        "HHHH..............HHH.",
        "HHH................HH.",
        "HH.................HH.",
        "HH..................H.",
        "HH....................",
        "H.....................",
    ], ["H": hair, "h": C(0x2E2A38)])
    drawDomino(c, purpleD, flare: true)
    c.rect(27, 32, 2, 1, clawdShade)
    c.rect(18, 33, 20, 5, purple); c.rect(37, 33, 1, 5, purpleD)
    c.pattern(27, 33, [".W.", "WWW", ".W.", ".W."], ["W": C(0xF2F2F4)])
    c.rect(18, 37, 20, 1, gold); c.px(28, 37, C(0xF4D670))
    c.px(19, 33, purpleL)
    if pulled == 0 { c.rect(15, 33, 3, 3, purple) }

    // The crossbow, raised to aim in the signature.
    var lift = p.gunY + (aiming ? -2 : 0)
    if sig != nil && !aiming && !loaded { lift += 1 }
    c.oy += lift
    let firing = p.fire.map { frac($0.t / shotPeriod) < 0.4 } ?? false
    let cocked = loaded && !firing
    drawCrossbow(c, cocked: cocked)
    c.rect(38, 33, 3, 3, purple)
    if aiming, let s = sig, s > 0.6, s < 0.7 { twinkle(c, 46, 30, C(0xFFFFFF, 0.9)) }
}

/// Huntress' crossbow, gripped at the hand: a dark stock, the bow across its nose, a bolt on top when `cocked`.
private func drawCrossbow(_ c: PixelCanvas, cocked: Bool) {
    let stock = C(0x3A2E40), limb = C(0x2A1A36), string = C(0xE0E0E8)
    c.rect(36, 33, 11, 2, stock); c.rect(38, 35, 2, 2, stock)
    line(c, 45.5, 33.5, 43.5, 28.5, limb, 0.6); line(c, 45.5, 33.5, 43.5, 38.5, limb, 0.6)
    let back = cocked ? 41.0 : 43.5
    line(c, 43.5, 28.5, back, 33.5, string, 0.35); line(c, 43.5, 38.5, back, 33.5, string, 0.35)
    if cocked {
        c.rect(41, 32, 6, 1, C(0x8A6A3A)); c.px(47, 32, C(0xC8CCD4)); c.px(48, 32, C(0xE8ECF4))
        c.px(41, 31, C(0xC83A2A))
    }
}

// MARK: - Batwoman

/// Batwoman (Kate Kane): Clawd in the black suit with the big red bat across her chest, a pointed-eared cowl over
/// white lenses and red lips, a mane of crimson hair, red gloves and tall red boots, and a black cape lined in red. She
/// fights with her fists. Signature: she throws a red batarang that arcs out, spinning, and comes back to her hand.
private func drawBatwoman(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x16161C), blackD = C(0x0C0C10), red = C(0xD8141E)
    let hair = C(0xE01E24), hairD = C(0x9A0E14)
    let look = Look(body: black, shade: blackD, leg: black, arm: black, eye: nil)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: black, edge: red, extra: 1)
    c.oy += p.breathe
    c.pattern(9, 21, [
        "........HHH",
        "......HHHHH",
        "....HHHHHHH",
        "...HHHHhHHH",
        "..HHHhHHHHH",
        "..HHHHHhHHH",
        ".HHHhHHHHH.",
        ".HHHHHhHHH.",
        "HHHhHHHHHH.",
        "HHHHHhHHH..",
        ".HHHHHHhHH.",
        "HHhHHHHHH..",
        "HHHHhHHHH..",
        ".HHHHHHh...",
        "HH.HHhHH...",
        "H..HH.H....",
        "...H.......",
    ], ["H": hair, "h": hairD])
    c.oy -= p.breathe
    drawLegs(c, look, step: p.step)
    drawBoots(c, step: p.step, red, height: 4)
    c.oy += p.breathe
    drawBody(c, look)
    drawCowl(c, black, blackD, lips: C(0xC01020))
    c.pattern(20, 34, [
        "......R..R......",
        "RRR...RRRR...RRR",
        ".RRRRRRRRRRRRRR.",
        "...RR.RRRR.RR...",
    ].map { String($0) }, ["R": red])
    c.rect(15, 33, 3, 3, red)
    if let s = p.signature, s > 0.06, s < 0.96 {
        // Wind up, throw, and the batarang loops out and back.
        if s < 0.18 || s > 0.84 {
            c.rect(38, 29, 3, 3, red)
            drawBatarang(c, x: 41, y: 28, spin: 0)
        } else {
            let k = (s - 0.18) / 0.66
            let x = 42 + 24 * sin(k * .pi), y = 29 - 13 * sin(k * 2 * .pi) * 0.6 - 6 * sin(k * .pi)
            for i in 1...3 {
                let kb = max(0, k - Double(i) * 0.025)
                let xb = 42 + 24 * sin(kb * .pi), yb = 29 - 13 * sin(kb * 2 * .pi) * 0.6 - 6 * sin(kb * .pi)
                c.px(Int(xb.rounded()), Int(yb.rounded()), red.alpha(0.5 / Double(i)))
            }
            drawBatarang(c, x: Int(x.rounded()), y: Int(y.rounded()), spin: Int(p.t * 20) % 4)
            c.rect(38, 31, 3, 3, red)
        }
        return
    }
    if let a = p.melee {
        drawPunch(c, angle: a, trail: p.trail, arm: black, fist: red)
    } else {
        c.rect(38, 33, 3, 3, red)
    }
}

/// A red batarang centred on (x, y), turned through four positions as it spins.
private func drawBatarang(_ c: PixelCanvas, x: Int, y: Int, spin: Int) {
    let red = C(0xE02028), dark = C(0x8A0E14)
    switch spin {
    case 0: c.pattern(x - 3, y - 1, ["R.....R", "RRRRRRR", ".R.R.R."], ["R": red])
    case 1: c.pattern(x - 2, y - 2, ["R....", ".RR..", "..RR.", "..RRR", "...R."], ["R": red])
    case 2: c.pattern(x - 1, y - 2, [".R.", "RR.", "RRR", "RR.", ".R."], ["R": red])
    default: c.pattern(x - 2, y - 2, ["...R.", "..RRR", "..RR.", ".RR..", "R...."], ["R": red])
    }
    c.px(x, y, dark)
}

// MARK: - Orphan

/// Orphan (Cassandra Cain): a sleek all-black Clawd, no cape, the full black mask with grey stitching across the mouth
/// and down the brow, narrow white eye slits and a small grey bat on the chest. She fights hand and foot: punches high,
/// kicks low. Signature: a slow, perfectly balanced high kick, held, and set back down.
private func drawOrphan(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x141418), blackL = C(0x2C2C36), stitch = C(0x8A8A98)
    let sig = p.signature
    let high = sig.map { habitArc($0, hold: 0.55) } ?? 0
    let kick: Double? = seatedPose ? nil : high > 0.05 ? -50 * high + 20 * (1 - high) : (p.melee.flatMap { $0 > -15 ? $0 : nil })
    // Legs: the front one out in a kick (drawn over the body, below), the rest planted.
    if kick != nil {
        for (i, lx) in [19, 23, 31].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 2, lifted ? 7 : 8, black)
            c.rect(lx, lifted ? 41 : 42, 2, 2, blackL)
        }
    } else {
        drawLegs(c, Look(leg: black), step: p.step)
        drawBoots(c, step: p.step, blackL, height: 2)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: black, shade: C(0x0A0A0E), arm: black, eye: nil))
    c.pattern(18, 23, ["....KKKKKKKKKKKK....", "..KKKKKKKKKKKKKKKK..", ".KKKKKKKKKKKKKKKKKK."], ["K": black])
    c.px(23, 24, blackL); c.px(24, 24, blackL)
    // The seam down the brow, eye slits, the stitched mouth.
    for y in stride(from: 23, through: 28, by: 1) { c.px(28, y, y % 2 == 0 ? stitch : black) }
    for y in [24, 26] { c.px(27, y, stitch); c.px(29, y, stitch) }
    c.pattern(21, 29, ["WWWW......WWWW", ".WW........WW."], ["W": white])
    c.rect(22, 33, 12, 1, stitch)
    for x in stride(from: 22, through: 33, by: 2) { c.px(x, 32, stitch); c.px(x, 34, stitch) }
    c.pattern(25, 35, ["G.G.G.G", ".GGGGG."], ["G": C(0x5A5A66)])
    c.rect(18, 37, 20, 1, C(0x0A0A0E))
    if let k = kick {
        let hip = (x: 35.0, y: 37.0)
        for (i, t) in p.trail.enumerated() where t > -15 {
            let q = reach(hip, t, 11)
            c.rect(Int(q.x.rounded()) - 1, Int(q.y.rounded()) - 1, 3, 2, blackL.alpha(0.4 / Double(i + 1)))
        }
        let foot = reach(hip, k, high > 0.05 ? 13 : 11)
        line(c, hip.x, hip.y, foot.x, foot.y, black, 1.2)
        line(c, hip.x, hip.y - 1, foot.x, foot.y - 1, blackL, 0.4)
        c.rect(Int(foot.x.rounded()) - 1, Int(foot.y.rounded()) - 1, 3, 2, blackL)
    }
    if high > 0.05 {
        // Arms in guard while she holds the kick.
        c.rect(14, 29, 3, 3, black); c.rect(33, 27, 3, 3, blackL)
        return
    }
    c.rect(15, 33, 3, 3, black)
    if let a = p.melee, kick == nil {
        drawPunch(c, angle: a, trail: p.trail, arm: black, fist: blackL)
    } else {
        c.rect(38, 33, 3, 3, black)
    }
}

// MARK: - Spoiler

/// Spoiler (Stephanie Brown): Clawd in the purple hooded cape over a black suit, the face hidden behind a dark full
/// mask with white eye lenses, purple gloves and boots, a grey belt. Fights with a bo staff, collapsed at her belt when
/// she's not. Signature: a smoke pellet at her feet, a purple cloud, and she's gone, then back.
private func drawSpoiler(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.04 else { spoiler(c, p); return }
    let fade: Double
    if s < 0.14 { fade = 1 } else if s < 0.32 { fade = 1 - (s - 0.14) / 0.18 } else if s < 0.6 { fade = 0 }
    else if s < 0.82 { fade = (s - 0.6) / 0.22 } else { fade = 1 }
    ghost(c, alpha: fade) { spoiler($0, p) }
    if s < 0.14 {
        // The pellet, dropped from the hand.
        let k = s / 0.14
        c.rect(43, Int((34 + k * 8).rounded()), 2, 2, C(0x5A4A6A))
    }
    let cloud = s < 0.14 ? 0 : (s < 0.3 ? (s - 0.14) / 0.16 : (s < 0.7 ? 1 : max(0, 1 - (s - 0.7) / 0.3)))
    guard cloud > 0 else { return }
    let grow = min(1, (s - 0.14) / 0.3)
    for i in 0..<11 {
        let ang = Double(i) / 11 * 2 * .pi + noise(i) * 0.6
        let r = 3 + grow * (6 + noise(i + 3) * 6)
        let x = 30 + cos(ang) * r * 1.3, y = 36 + sin(ang) * r * 0.7 - grow * 3 - (s - 0.14) * 4
        let rad = Int((2 + grow * 3 + noise(i + 7) * 2).rounded())
        let col = (i % 3 == 0 ? C(0x9A6AC8) : C(0x6A4A8A)).alpha(0.45 * cloud)
        c.ellipse(Int(x.rounded()), Int(y.rounded()), rad, max(1, rad - 1), col)
    }
}

private func spoiler(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x7A2EAA), purpleD = C(0x52187A), purpleL = C(0xA866D8), suit = C(0x1E1A26), mask = C(0x2A1838)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: purple, edge: purpleD, extra: 0.5)
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, step: p.step, purple, height: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: mask, shade: C(0x160E20), arm: suit, eye: nil))
    c.pattern(15, 19, [
        ".......PPPPPPPPPPPP.......",
        ".....PPPPPPPPPPPPPPPP.....",
        "....PPPPLPPPPPPPPPPPPP....",
        "...PPPLLPPPPPPPPPPPPPPP...",
        "...PPPPPPPPPPPPPPPPPPPd...",
        "..PPPPPPPPPPPPPPPPPPPPPd..",
        "..PPPd..............dPPd..",
        ".PPPP................PPPd.",
        ".PPP..................PPd.",
        ".PPP..................PPd.",
        "PPPP..................PPPd",
        "PPP....................PPd",
        "PPP....................PPd",
        "PPPP..................PPPd",
        ".PPPPP..............PPPPd.",
    ], ["P": purple, "d": purpleD, "L": purpleL])
    c.pattern(21, 29, ["WWWW......WWWW", ".WWW......WWW."], ["W": C(0xEDEDF4)])
    c.rect(18, 34, 20, 3, suit)
    c.rect(18, 37, 20, 1, C(0x6A6A74)); c.rect(27, 37, 2, 1, C(0x9A9AA4))
    c.rect(15, 33, 3, 3, purple)
    if let a = p.melee {
        drawStaff(c, angle: a, trail: p.trail, pole: C(0x5A5A66), cap: purpleL, wrap: purple, smearCol: purpleL)
        c.rect(38, 33, 3, 3, purple)
    } else {
        c.rect(19, 35, 2, 3, C(0x5A5A66)); c.px(19, 35, purpleL)
        c.rect(38, 33, 3, 3, purple)
    }
}

// MARK: - Commissioner Gordon

/// Commissioner Gordon: Clawd with neat grey hair, glasses and a grey moustache, a tan trench coat with the collar up
/// and the belt tied, a white shirt and a dark red tie, grey trousers; a police revolver in his hand. Signature: he
/// switches on the Bat-Signal, the searchlight behind him throws its beam up and the bat lights the sky.
private func drawGordon(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xB89A66), coatD = C(0x8A7048), coatL = C(0xD4B886), shirt = C(0xEDEDE8), tie = C(0x7A1E22)
    let trousers = C(0x4A4A54), hair = C(0xC4C6CE), hairD = C(0x8E909C), frame = C(0x2A2A30)
    let sig = p.signature
    if let s = sig { drawBatSignal(c, s: s, t: p.t) }
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, step: p.step, C(0x3A2A1E), height: 1)
    c.oy += p.breathe
    let lookUp = sig.map { $0 > 0.25 && $0 < 0.9 } ?? false
    drawBody(c, Look(body: clawdOrange, arm: coat, eye: nil))
    // Coat tails over the legs.
    let tails = seatedPose ? 1 : 3
    c.rect(17, 38, 22, tails, coat); c.rect(17, 37 + tails, 22, 1, coatD); c.rect(28, 38, 1, tails, coatD)
    // Hair, combed with a side parting.
    c.pattern(17, 21, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHHHHhHHHHHHHH...",
        "..HHHHHHHHhHHHHHHHHH..",
        "..HHHHHHHHHhHHHHHHHH..",
        ".HHHHHHHHHHHhHHHHHHHH.",
        ".HHH..............HHH.",
        ".HH................HH.",
    ], ["H": hair, "h": hairD])
    // Eyes behind the glasses (raised to the sky in the signature), the moustache.
    let ey = lookUp ? 29 : 30
    c.rect(22, ey, 2, 2, ink); c.rect(32, ey, 2, 2, ink)
    c.pattern(20, 28, ["FFFFFF....FFFFFF", "F....FFFFFF....F", "F....F....F....F", "FFFFFF....FFFFFF"], ["F": frame])
    c.rect(21, 29, 4, 2, C(0xDFF0FF, 0.25)); c.rect(31, 29, 4, 2, C(0xDFF0FF, 0.25))
    c.px(21, 29, C(0xFFFFFF, 0.7)); c.px(31, 29, C(0xFFFFFF, 0.7))
    c.pattern(23, 32, [".MMMMMMMM.", "MMMMMMMMMM", "MM......MM"], ["M": hair])
    // Coat, lapels, shirt and tie.
    c.rect(18, 34, 20, 4, coat); c.rect(37, 34, 1, 4, coatD)
    c.pattern(24, 34, ["lSSTTSSl", ".lSTTSl.", "..lTTl..", "...TT..."], ["l": coatD, "S": shirt, "T": tie])
    c.pattern(16, 30, ["CC", "CC", "CC", "CC", ".C"], ["C": coatL])
    c.pattern(38, 30, ["CC", "CC", "CC", "CC", "C."], ["C": coatL])
    c.rect(18, 37, 20, 1, coatD); c.rect(20, 37, 3, 1, coatL)
    if let s = sig, s > 0.04, s < 0.96 {
        // Left hand on the switch, the revolver away.
        c.rect(14, 31, 3, 3, coat)
        c.rect(38, 33, 3, 3, coat)
        c.rect(35, 36, 2, 2, C(0x2A2A30))
        return
    }
    c.rect(15, 33, 3, 3, coat)
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, coat)
    c.pattern(40, 31, ["KKKKKKKK", "KKCCKK..", "KK......", "KK......"], ["K": C(0x2A2A30), "C": C(0x6A6E78)])
    c.px(41, 33, C(0x5A3A26)); c.px(41, 34, C(0x5A3A26))
}

/// The Bat-Signal on the rooftop behind Gordon: a searchlight on its stand, its beam thrown up into the sky with the
/// bat in a pale oval at the top. `s` 0…1 through the signature: it flickers on, burns, and goes out.
private func drawBatSignal(_ c: PixelCanvas, s: Double, t: Double) {
    let present = min(1, s / 0.08, (1 - s) / 0.06)
    let metal = C(0x6A707C).alpha(present), metalD = C(0x3A3E48).alpha(present)
    // Stand and drum.
    line(c, 8, 37, 4, 43, metalD, 0.6); line(c, 8, 37, 12, 43, metalD, 0.6); line(c, 8, 37, 8, 43, metalD, 0.5)
    line(c, 5, 38, 10, 32, metal, 2.4)
    var on = 0.0
    if s > 0.18 && s < 0.28 { on = Int(t * 30) % 3 == 0 ? 0 : 1 }       // it sputters into life
    else if s >= 0.28 && s < 0.88 { on = 1 } else if s >= 0.88 && s < 0.94 { on = (0.94 - s) / 0.06 }
    c.glowLine(11, 31, 11, 31, core: C(0xFFF8D8).alpha(0.4 + 0.6 * on), glow: C(0xFFE27A).alpha(on), coreR: 1.2, glowR: 2.4)
    guard on > 0 else { return }
    for k in -4...4 {
        line(c, 11, 31, 22 + Double(k) * 2, 10, C(0xFFF4C0, 0.07 * on), 1.6)
    }
    c.ellipse(22, 6, 10, 5, C(0xFFF0A0, 0.85 * on))
    c.pattern(15, 3, [
        "K.....K.K.....K",
        "KK....KKK....KK",
        "KKKK.KKKKK.KKKK",
        "KKKKKKKKKKKKKKK",
        ".KKKKKKKKKKKKK.",
        "...KK.KKK.KK...",
    ], ["K": C(0x16161B).alpha(on)])
}
