import Foundation

// Heroes: Justice League Dark. Stage magicians, chain-smoking exorcists, ghosts, a demon and a walking swamp, every one
// of them Clawd in costume: hats, hoods, helms and rags drawn over (and around) the blocky body.

let heroes7: [Companion: Persona] = [
    .zatanna: Persona(name: "Zatanna", weapon: .magic, magic: Magic(core: C(0xFFF0FF), glow: C(0xD84AE8)),
                  pivot: zatannaWand, headTop: 15, signature: 3.0, callout: "!kcab yats",
                  draw: drawZatanna),
    .constantine: Persona(name: "Constantine", weapon: .magic, magic: Magic(core: C(0xFFF4D0), glow: C(0xFFAA2A)),
                  headTop: 22, signature: 3.2, callout: "Bloody hell.",
                  draw: drawConstantine),
    .swampThing: Persona(name: "Swamp Thing", weapon: .melee, pivot: swampShoulder, bulk: 5, headTop: 17, signature: 3.0,
                  callout: "I am the Green.",
                  draw: drawSwampThing),
    .deadman: Persona(name: "Deadman", weapon: .melee, motion: .hover, headTop: 23, signature: 2.6,
                  draw: drawDeadman),
    .spectre: Persona(name: "The Spectre", weapon: .magic, motion: .hover, magic: Magic(core: C(0xF0FFF0), glow: C(0x8AE88A)),
                  pivot: spectreHand, bulk: 1, headTop: 12, signature: 3.2, callout: "Vengeance is mine.",
                  draw: drawSpectre),
    .etrigan: Persona(name: "Etrigan", weapon: .ranged, shot: .fire, muzzle: (39, 32), handGun: false, headTop: 19,
                  signature: 3.0, callout: "Gone, gone, the form of man; rise the demon Etrigan!",
                  draw: drawEtrigan),
    .madameXanadu: Persona(name: "Madame Xanadu", weapon: .magic, magic: Magic(core: C(0xF0E0FF), glow: C(0x8A4AD8), jagged: false),
                  headTop: 22, signature: 3.2, callout: "The cards never lie.",
                  draw: drawMadameXanadu),
    .phantomStranger: Persona(name: "Phantom Stranger", weapon: .magic, motion: .hover,
                  magic: Magic(core: C(0xF0F4FF), glow: C(0x9AA8D8), jagged: false),
                  headTop: 19, signature: 3.0,
                  draw: drawPhantomStranger),
    .ragman: Persona(name: "Ragman", weapon: .melee, headTop: 19, signature: 2.8,
                  draw: drawRagman),
    .dream: Persona(name: "Dream", weapon: .magic, motion: .hover, magic: Magic(core: C(0xF0F4FF), glow: C(0x6A8AD8), jagged: false),
                  headTop: 16, signature: 3.2, callout: "I am Dream of the Endless.",
                  draw: drawDream),
]

// MARK: - Shared bits

private let hand = Sprite.hand
private let none = C(0, 0)

/// A point `d` pixels out from `h` at `angle` degrees.
private func reach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// A solid bar along `angle` from `a` to `b` pixels out from `h` (arms, wands, rags).
private func bar(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ angle: Double, from a: Double, to b: Double, _ col: Px,
                 r: Double = 0.8) {
    let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
    c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: none, coreR: r, glowR: r + 0.1)
}

/// The fading smear a fast swing leaves behind.
private func smear(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ trail: [Double], from a: Double, to b: Double, _ col: Px) {
    for (i, angle) in trail.enumerated() {
        let p0 = reach(h, angle, a), p1 = reach(h, angle, b)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// A one-pixel ring of radius `r`, squashed vertically by `squash`.
private func ring(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double, _ col: Px, squash: Double = 1) {
    var seen = Set<Int>()
    let n = max(12, Int(r * 8))
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi
        let x = Int((cx + cos(a) * r).rounded()), y = Int((cy + sin(a) * r * squash).rounded())
        if seen.insert(x * 1000 + y).inserted { c.px(x, y, col) }
    }
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A sorcerer's glyph: a glowing ring with a turning triangle inside, centred on `at`.
private func drawSigil(_ c: PixelCanvas, at: (x: Double, y: Double), r: Double, t: Double, core: Px, glow: Px) {
    guard r >= 1 else { return }
    let n = 12
    for i in 0..<n {
        let a0 = Double(i) / Double(n) * 2 * .pi + t * 1.5, a1 = Double(i + 1) / Double(n) * 2 * .pi + t * 1.5
        c.glowLine(at.x + cos(a0) * r, at.y + sin(a0) * r, at.x + cos(a1) * r, at.y + sin(a1) * r,
                   core: core.alpha(0.9), glow: glow.alpha(0.6), coreR: 0.35, glowR: 1.2)
    }
    for i in 0..<3 {
        let step: Double = 2 * .pi / 3
        let a0 = Double(i) * step - t * 2.5, a1 = Double(i + 1) * step - t * 2.5
        let r2 = r * 0.7
        c.glowLine(at.x + cos(a0) * r2, at.y + sin(a0) * r2, at.x + cos(a1) * r2, at.y + sin(a1) * r2,
                   core: core.alpha(0.7), glow: glow.alpha(0.4), coreR: 0.3, glowR: 0.9)
    }
}

/// Little four-pointed glints round `at`, twinkling on clock `t`.
private func drawTwinkles(_ c: PixelCanvas, at: (x: Double, y: Double), spread: Double, t: Double, core: Px, glow: Px,
                          count: Int = 3, alpha: Double = 1) {
    for i in 0..<count {
        let f = frac(t * 2.2 + Double(i) / Double(count))
        let a = Double(i) * 2.1 + floor(t * 2.2 + Double(i) / Double(count)) * 1.7
        let x = Int((at.x + cos(a) * spread * f).rounded()), y = Int((at.y + sin(a) * spread * f - f * 2).rounded())
        let k = (1 - f) * alpha
        c.px(x, y, core.alpha(k))
        c.px(x - 1, y, glow.alpha(k * 0.7)); c.px(x + 1, y, glow.alpha(k * 0.7))
        c.px(x, y - 1, glow.alpha(k * 0.7)); c.px(x, y + 1, glow.alpha(k * 0.7))
    }
}

/// Draws `draw` on a layer of its own and lays it over `c` at `alpha` (offsets as for any drawing), with a `rim`
/// outline round it if given: for a ghost, or a figure fading out of sight.
private func overlay(_ c: PixelCanvas, alpha: Double, rim: Px? = nil, _ draw: (PixelCanvas) -> Void) {
    let layer = PixelCanvas(c.w, c.h)
    draw(layer)
    let w = layer.w, h = layer.h, b = layer.buf
    func solid(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && b[(y * w + x) * 4 + 3] > 200 }
    for y in 0..<h {
        for x in 0..<w {
            let i = (y * w + x) * 4, a = b[i + 3]
            if a > 0 {
                c.px(x, y, unpremultiplied(layer, i).alpha(alpha))
            } else if let rim, solid(x - 1, y) || solid(x + 1, y) || solid(x, y - 1) || solid(x, y + 1) {
                c.px(x, y, rim)
            }
        }
    }
}

/// A prop drawn pointing right from pixel (20, 20) of a scratch canvas, turned to `angle` degrees (0 forward, -90 up)
/// and placed with that point on `at`.
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

private struct Fire { let tip, outer, mid, core: Px }
private let hellFire = Fire(tip: C(0xA01C0C), outer: C(0xE8461A), mid: C(0xFF8A1E), core: C(0xFFD84A))

/// Flame tongues licking up from row `base` over columns x0…x1, at most `height` tall, bending by `lean` pixels a row
/// (negative leans forward), flickering on clock `t`.
private func drawFlames(_ c: PixelCanvas, x0: Int, x1: Int, base: Int, height: Double, lean: Double, t: Double,
                        seed: Int = 0, _ fire: Fire, alpha: Double = 1) {
    let tick = Int(t * 10)
    let half = Double(x1 - x0) / 2 + 1, mid = Double(x0 + x1) / 2
    for x in x0...x1 {
        let d = (Double(x) - mid) / half
        let env = max(0.2, 1 - d * d)
        let n = 0.7 * noise(seed + (x / 2) * 13 + tick * 71) + 0.3 * noise(seed + x * 7 + tick * 29)
        let h = Int((height * env * (0.45 + 0.55 * n)).rounded())
        guard h > 0 else { continue }
        for k in 0..<h {
            let f = Double(k) / Double(h)
            let col = f > 0.72 ? fire.tip : f > 0.42 ? fire.outer : f > 0.18 ? fire.mid : fire.core
            c.px(x - Int((Double(k) * lean).rounded()), base - 1 - k, col.alpha(alpha))
        }
    }
}

/// A cape like `drawCape`, whose bottom rows break up into flickering tongues (a hem of shadow-flame, or rags).
private func drawTatteredCape(_ c: PixelCanvas, t: Double, speed: Double, color: Px, edge: Px, extra: Double, ragged: Int,
                              flicker: Double) {
    let tick = Int(t * flicker)
    for y in 27...43 where y + c.oy <= 43 {
        let k = Double(y - 27) / 16
        let hw = 10.5 + k * (4.5 + extra)
        let sway = sin(t * speed + k * 2.2) * k * 1.6
        let l = Int((Sprite.bodyCenterX - hw + sway).rounded())
        let r = Int((Sprite.bodyCenterX + hw + sway).rounded()) - 1
        for x in l...r {
            if y > 43 - ragged {
                let reach = 43 - ragged + Int(noise(x * 7 + tick * 13) * Double(ragged + 1))
                guard y <= reach else { continue }
            }
            c.px(x, y, x == l || x == r ? edge : color)
        }
    }
}

// MARK: - Zatanna

private let zatannaWand = (x: 45.5, y: 30.5)

/// Zatanna: Clawd as the stage magician, a black top hat with a red band over long black hair, a black tailcoat with
/// the tails swinging behind, a white shirt front and red bow tie, white gloves and fishnets above black heels; her
/// wand sparkles as she casts, the spells said backwards. Signature: she taps the hat with her wand, it hops up off her
/// head and a white dove flutters out and away.
private func drawZatanna(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x1C1C26), coatLight = C(0x3A3A4C), shirt = C(0xF4F4F8), bow = C(0xC8203A), bowDark = C(0x8A1428)
    let hair = C(0x141018), hairShade = C(0x2E2840), net = C(0x241A20), heel = C(0x101014)
    let spark = (core: C(0xFFF0FF), glow: C(0xD84AE8))
    let s = p.signature
    let tap = s.map { habitArc(min(1, $0 / 0.45), hold: 0.3) } ?? 0               // wand raised to the hat
    let lift = s.map { $0 > 0.22 && $0 < 0.9 ? habitArc(($0 - 0.22) / 0.68, hold: 0.5) : 0 } ?? 0
    let hatUp = Int((lift * 5).rounded())

    drawLegs(c, Look(leg: clawdOrange), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            for y in 36..<(bottom - 1) {
                for x in lx...(lx + 1) where (x + y) % 2 == 0 { c.px(x, y, net) }
            }
            c.rect(lx, bottom - 1, 2, 2, heel)
            c.px(lx + 1, bottom - 2, heel)
        }
    }
    c.oy += p.breathe
    // The tails of the coat hang behind her, swinging as she walks.
    let swing = p.walking && p.step == 0 ? 1 : 0
    c.pattern(12 - swing, 33, [
        ".....TTT",
        "....TTTT",
        "...TTTTT",
        "..TTTTt.",
        ".TTTTt..",
        ".TTTt...",
        "TTTt....",
        "Tt......",
    ], ["T": coat, "t": coatLight])
    let raise = max(p.armRaise, Int((tap * 7).rounded()))
    drawBody(c, Look(arm: shirt), armRight: raise)
    // Long black hair, a straight fringe under the brim.
    c.pattern(16, 25, [
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHhHH.HHHhHH.HHhHHHHH",
        "HHHh..h.............hHHH",
        "HHH..................HHH",
        "HHH..................HH.",
        "HHh..................H..",
        "HH......................",
        "HH......................",
        "Hh......................",
        "H.......................",
    ], ["H": hair, "h": hairShade])
    // The tailcoat, the shirt front and the bow tie.
    c.rect(18, 33, 20, 5, coat)
    c.pattern(23, 33, [
        "LSbBBbSL",
        ".LSSSSL.",
        "..LSSL..",
        "...LL...",
    ], ["L": coatLight, "S": shirt, "b": bow, "B": bowDark])
    c.px(27, 37, coatLight); c.px(28, 37, coatLight)
    c.rect(15, 33, 3, 3, shirt)
    // The top hat, hopping up off her head in the trick.
    let by = 24 - hatUp
    c.rect(22, by - 8, 12, 8, hair)
    c.rect(23, by - 8, 1, 6, C(0x3A3A4C))
    c.rect(22, by - 2, 12, 2, bow)
    c.rect(19, by, 18, 1, hair)
    c.rect(18, by + 1, 20, 1, hair)
    c.px(18, by, hair); c.px(37, by, hair)
    // The wand: black with a white tip.
    let hy = 33.5 - Double(raise)
    c.glowLine(40.5, hy, 45.5, hy - 3, core: ink, glow: none, coreR: 0.6, glowR: 0.7)
    c.px(45, Int(hy) - 3, shirt); c.px(46, Int(hy) - 4, shirt)
    if p.zap != nil {
        drawTwinkles(c, at: (45.5, hy - 3.5), spread: 4, t: p.t, core: spark.core, glow: spark.glow)
    }
    if let s {
        if tap > 0.4 {
            // Sparkles from the wand to the brim.
            drawTwinkles(c, at: (44, hy - 4), spread: 6, t: p.lt * 1.3, core: spark.core, glow: spark.glow, count: 4, alpha: tap)
        }
        if s > 0.38 {
            // The dove: out from under the brim and away, flapping.
            let f = min(1, (s - 0.38) / 0.62)
            let x = 27 + f * 34, y = Double(by) - 1 - f * 22 - sin(f * .pi) * 3
            let up = Int(p.lt * 10) % 2 == 0
            c.pattern(Int(x.rounded()) - 2, Int(y.rounded()) - 1, up ? ["W..W..", ".WWWWo", "..WW.."] : ["......", "WWWWWo", ".W..W."],
                      ["W": white.alpha(f > 0.85 ? (1 - f) / 0.15 : 1), "o": C(0xF0A040)])
        }
    }
}

// MARK: - Constantine

/// John Constantine: Clawd with messy blond hair, a cigarette in the corner of his mouth trailing smoke, a long tan
/// trench coat with the collar up over a white shirt and a loosened red tie, dark trousers. Casting, a gold ward turns
/// in front of his hand. Signature: a fresh one; the lighter flicks, he takes a long drag (the tip glows) and blows
/// smoke rings.
private func drawConstantine(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xB89A64), coatShade = C(0x8E7444), coatDark = C(0x6A5432), shirt = C(0xF0EEE8), tie = C(0xA82424)
    let hair = C(0xE2C46A), hairShade = C(0xB89A3E), slacks = C(0x34343C), shoe = C(0x1A1A1E)
    let gold = (core: C(0xFFF4D0), glow: C(0xFFAA2A))
    let s = p.signature
    drawLegs(c, Look(leg: slacks), step: p.step)
    drawBoots(c, shoe, step: p.step, rows: 1)
    c.oy += p.breathe
    // The skirt of the coat, open at the front.
    if !seatedPose {
        let sway = p.walking ? (p.step == 0 ? 1 : -1) : 0
        for y in 38...40 {
            let k = y - 38
            let l = 17 - k + (k > 0 ? sway : 0), r = 38 + k + (k > 0 ? sway : 0)
            c.rect(l, y, r - l + 1, 1, coat)
            c.px(r, y, coatShade); c.px(l, y, coatShade)
            c.rect(26 + (k > 0 ? sway : 0), y, 4, 1, slacks)
        }
    }
    // The hand: up to the lighter and the cigarette in the signature, raised to cast otherwise.
    let toMouth = s.map { $0 < 0.5 ? habitArc($0 / 0.5, hold: 0.5) : 0 } ?? 0
    let raise = max(p.armRaise, Int((toMouth * 3).rounded()))
    drawBody(c, Look(arm: coat), armRight: raise)
    // The coat, collar up, open over the shirt and the loose tie.
    c.rect(17, 33, 22, 5, coat)
    c.rect(38, 33, 1, 5, coatShade)
    c.rect(17, 31, 2, 2, coat); c.rect(37, 31, 2, 2, coat)
    c.px(18, 31, coatShade); c.px(37, 31, coatShade)
    c.rect(24, 33, 8, 5, shirt)
    c.rect(24, 33, 1, 5, coatShade); c.rect(31, 33, 1, 5, coatShade)
    c.rect(23, 35, 1, 3, coatDark); c.rect(32, 35, 1, 3, coatDark)
    c.rect(27, 33, 2, 1, tie)
    c.px(27, 34, tie); c.px(27, 35, tie); c.px(28, 36, tie); c.px(28, 37, tie)
    c.px(25, 33, C(0xC8C4BA)); c.px(30, 33, C(0xC8C4BA))
    c.rect(15, 33, 3, 3, coat); c.rect(15, 35, 3, 1, coatShade)
    // Messy blond hair.
    c.pattern(18, 22, [
        "....H..HH..H..H.....",
        "..HHHHHHHHHHHHHHH.H.",
        ".HHHHHHHHHHHHHHHHHH.",
        "HHHHHhHHHHHHhHHHHHHH",
        "HHHhHH.hHH.HHhH.HHHH",
        "HH..h......h.....hHH",
        "H..................H",
    ], ["H": hair, "h": hairShade])
    // The cigarette: unlit until the lighter's been to it in the signature.
    let lit = s.map { $0 > 0.2 } ?? true
    c.px(38, 32, C(0xD8A060)); c.px(39, 32, shirt); c.px(40, 31, shirt); c.px(41, 31, shirt)
    if lit {
        let drag = s.map { $0 > 0.24 && $0 < 0.5 ? habitArc(($0 - 0.24) / 0.26, hold: 0.4) : 0 } ?? 0
        c.px(42, 31, Int(p.t * 7) % 3 == 0 ? C(0xFFB02A) : C(0xFF5A1A))
        if drag > 0.1 { c.glowLine(42.5, 31.5, 42.5, 31.5, core: C(0xFFE27A), glow: C(0xFF5A1A), coreR: 0.6, glowR: 2.2 * drag) }
        // A thin curl of smoke off the tip.
        for i in 0..<4 {
            let f = frac(p.lt * 0.5 + Double(i) / 4)
            let x = 42.5 + sin(f * 6 + Double(i)) * 1.2 + f * 2, y = 30 - f * 11
            c.px(Int(x), Int(y), C(0xD8D8DC, 0.55 * (1 - f)))
        }
    }
    if let s {
        if s > 0.06 && s < 0.26 {
            // The lighter, flame up to the end of the cigarette.
            c.rect(40, 33 - raise + 1, 2, 3, C(0xB8BCC6))
            let flick = noise(Int(p.t * 30))
            c.px(41, 33 - raise, C(0xFFE27A)); c.px(41, 32 - raise, C(0xFF9A2A, 0.6 + 0.4 * flick))
        }
        if s > 0.5 {
            // Smoke rings, drifting off and spreading.
            for i in 0..<3 {
                let f = (s - 0.5 - Double(i) * 0.1) / 0.4
                guard f > 0, f < 1 else { continue }
                ring(c, 41 + f * 12, 31 - f * 8, 1.5 + f * 3, C(0xE0E0E4).alpha(0.8 * (1 - f)), squash: 0.6)
            }
        }
    }
    if p.zap != nil {
        drawSigil(c, at: (42.5, 34.5 - Double(raise)), r: 3.5, t: p.t, core: gold.core, glow: gold.glow)
    }
}

// MARK: - Swamp Thing

private let swampShoulder = (x: 40.5, y: 26.5)

/// Swamp Thing: a much bigger Clawd of moss and bark, a crown of leaves, a heavy brow over glowing red eyes, a beard of
/// hanging moss and roots for toes; one arm hangs at his side and the other swings from the shoulder ending in a fist of
/// knotted wood. Signature: the Green answers him; vines climb out of the ground round his feet and flower, blossoms
/// open on his shoulders and his eyes burn, then it all draws back in.
private func drawSwampThing(_ c: PixelCanvas, _ p: Pose) {
    let moss = C(0x4E7E30), mossShade = C(0x3C6626), deep = C(0x24401A), bark = C(0x6A5634), barkDark = C(0x46381E)
    let leaf = C(0x7EB640), leafDark = C(0x5A9030), drape = C(0x8A9A62), eye = C(0xFF2A1E)
    let bloom = p.signature.map { habitArc($0, hold: 0.45) } ?? 0
    // Vines out of the ground (behind him and in front).
    if bloom > 0.02 {
        let stalks: [(x: Int, h: Int, col: Px)] = [(7, 11, C(0xFF6AA8)), (11, 7, C(0xFFE04A)), (45, 9, C(0xF4F0F8)),
                                                   (50, 13, C(0xFF6AA8)), (55, 6, C(0xE84A3A))]
        for (i, v) in stalks.enumerated() {
            let h = Int((Double(v.h) * min(1, bloom * 1.3)).rounded())
            guard h > 0 else { continue }
            for k in 0..<h {
                let x = v.x + Int((sin(Double(k) * 0.7 + Double(i)) * 1.2).rounded())
                c.px(x, 43 - k, k % 3 == 1 ? leafDark : moss)
                if k % 4 == 2 { c.px(x + (i % 2 == 0 ? 1 : -1), 43 - k, leaf) }
            }
            if bloom > 0.7 {
                let top = 43 - h, x = v.x + Int((sin(Double(h - 1) * 0.7 + Double(i)) * 1.2).rounded())
                let a = (bloom - 0.7) / 0.3
                c.px(x, top - 1, v.col.alpha(a)); c.px(x - 1, top, v.col.alpha(a)); c.px(x + 1, top, v.col.alpha(a))
                c.px(x, top + 1, v.col.alpha(a)); c.px(x, top, C(0xFFD84A).alpha(a))
            }
        }
    }
    // Thick legs, roots spreading at the feet.
    for (i, lx) in [16, 21, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, moss); c.px(lx, 39, bark); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 3, lifted ? 7 : 8, moss)
        c.rect(lx + 2, 38, 1, lifted ? 5 : 6, deep)
        c.px(lx, 39, bark); c.px(lx + 1, 41, barkDark)
        if !lifted { c.px(lx - 1, 43, barkDark); c.px(lx + 3, 43, barkDark) }
    }
    c.oy += p.breathe
    // The left arm hangs behind the body's edge, moss trailing off it.
    c.rect(10, 24, 5, 9, moss); c.rect(9, 32, 6, 6, moss)
    c.rect(10, 24, 1, 9, deep); c.rect(9, 34, 6, 1, mossShade); c.rect(9, 36, 6, 1, mossShade)
    c.px(9, 38, drape); c.px(11, 38, drape); c.px(11, 39, drape)
    c.px(10, 27, bark); c.px(12, 29, bark)
    // The big body.
    c.rect(15, 22, 26, 16, moss)
    c.rect(40, 22, 1, 16, deep)
    c.rect(15, 37, 26, 1, deep)
    let streaks: [(Int, Int, Int)] = [(17, 30, 6), (20, 34, 3), (36, 31, 5), (38, 24, 6), (16, 23, 4), (33, 35, 2)]
    for (x, y0, len) in streaks { c.rect(x, y0, 1, len, mossShade) }
    let knots: [(Int, Int)] = [(18, 33), (35, 27), (24, 36), (31, 36), (39, 33)]
    for (x, y) in knots { c.px(x, y, bark); c.px(x, y + 1, barkDark) }
    // A crown of leaves.
    c.pattern(15, 17, [
        "...L....LL...L...L.L......",
        "..LLL..LLLL.LLL.LLLLL..L..",
        ".LLlLLLLLlLLLLLLLLlLLLLLL.",
        "LLLLLLlLLLLLLLlLLLLLLLLLLL",
        "lLLlLLLLLlLLLLLLLLLlLLLlLL",
        "l.l..lL...l..lL.l....lL..l",
    ], ["L": leaf, "l": leafDark])
    // Brow, burning eyes, the moss beard.
    c.pattern(19, 24, [
        "dddd..........dddd",
        "ddddd........ddddd",
        "..ddd........ddd..",
        "...EE........EE...",
        "...EE........EE...",
    ], ["d": deep, "E": eye])
    let burn = 0.35 + 0.65 * bloom
    c.glowLine(23, 28, 23, 28, core: C(0xFF8A6A, burn), glow: C(0xFF2A1E, burn), coreR: 0.4, glowR: 1.8)
    c.glowLine(33, 28, 33, 28, core: C(0xFF8A6A, burn), glow: C(0xFF2A1E, burn), coreR: 0.4, glowR: 1.8)
    c.rect(22, 30, 13, 1, deep)
    for x in stride(from: 21, through: 35, by: 2) {
        c.rect(x, 31, 1, 2 + (x % 4 == 1 ? 2 : 0), deep)
        c.px(x + 1, 31, drape)
    }
    if bloom > 0.4 {
        let a = min(1, (bloom - 0.4) / 0.3)
        let blossoms: [(Int, Int, Px)] = [(17, 20, C(0xFF6AA8)), (30, 18, C(0xF4F0F8)), (38, 21, C(0xFFE04A)), (16, 26, C(0xE84A3A))]
        for (x, y, col) in blossoms {
            c.px(x, y - 1, col.alpha(a)); c.px(x - 1, y, col.alpha(a)); c.px(x + 1, y, col.alpha(a)); c.px(x, y + 1, col.alpha(a))
            c.px(x, y, C(0xFFD84A).alpha(a))
        }
    }
    let angle = p.melee ?? 80
    for (i, ta) in p.trail.enumerated() { drawSwampArm(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
    drawSwampArm(c, angle: angle)
}

/// Swamp Thing's right arm, swung from the shoulder: mossy, barked, ending in a fist of knotted wood.
private func drawSwampArm(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: swampShoulder, angle: angle, alpha: alpha) { s in
        let moss = C(0x4E7E30), shade = C(0x37602A), bark = C(0x6A5634), barkDark = C(0x46381E)
        s.rect(18, 18, 9, 5, moss)
        s.rect(18, 22, 9, 1, shade)
        s.px(21, 19, bark); s.px(24, 21, bark)
        s.rect(26, 16, 7, 8, bark)
        s.rect(32, 17, 1, 6, barkDark); s.rect(26, 23, 7, 1, barkDark)
        s.px(29, 17, barkDark); s.px(29, 19, barkDark); s.px(29, 21, barkDark)
        s.px(27, 16, moss); s.px(28, 16, moss); s.px(26, 17, moss)
    }
}

// MARK: - Deadman

/// Deadman: a ghost, and it shows; the whole of him is see-through with a pale glow round the edges. Clawd in Boston
/// Brand's red circus tights, the tall flared collar, a black belt, a corpse-white face with sunken eye sockets and
/// slicked black hair; he floats, wisps trailing off his feet, and punches. Signature: the aerialist's backflip, a full
/// turn in the air, ghost images left behind.
private func drawDeadman(_ c: PixelCanvas, _ p: Pose) {
    let rim = C(0xCFF4FF, 0.5)
    if !seatedPose {
        for i in 0..<3 {
            let f = frac(p.lt * 0.9 + Double(i) / 3)
            let x = 20 + i * 7 + Int((sin(f * 7 + Double(i)) * 1.5).rounded()), y = 44 + Int(f * 4)
            c.rect(x, y, 2, 1, C(0xCFF4FF, 0.4 * (1 - f)))
        }
    }
    guard let s = p.signature else {
        overlay(c, alpha: 0.85, rim: rim) { l in drawDeadmanFigure(l, p) }
        return
    }
    let ease = s * s * (3 - 2 * s)
    let turn = { (k: Double) -> Double in -360 * k }
    let lift = sin(s * .pi) * 10
    let figure = PixelCanvas(c.w, c.h)
    drawDeadmanFigure(figure, p)
    let pivot = (x: 28.0, y: 33.0)
    for back in [0.07] where s > back && s < 0.93 {
        let k = s - back, e = k * k * (3 - 2 * k)
        let ghost = figure.rotated(turn(e), about: pivot, into: c.w, c.h, at: (pivot.x, pivot.y - sin(k * .pi) * 10))
        overlay(c, alpha: 0.22) { l in l.paste(ghost) }
    }
    let now = figure.rotated(turn(ease), about: pivot, into: c.w, c.h, at: (pivot.x, pivot.y - lift))
    overlay(c, alpha: 0.85, rim: rim) { l in l.paste(now) }
}

private func drawDeadmanFigure(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8262A), redDark = C(0x8A141A), redLight = C(0xE8484A), pale = C(0xE6ECF0), paleShade = C(0xB4C0CA)
    let socket = C(0x3A4252), hair = C(0x16141C), belt = C(0x1A1A20), gold = C(0xE8C040)
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, redDark, step: p.step, rows: 2)
    c.oy += p.breathe
    // The tall collar standing up behind his head.
    for y in 24...33 {
        let out = 14 + (y - 24) * 4 / 9
        c.rect(out, y, 18 - out, 1, red); c.px(out, y, redDark)
        c.rect(38, y, 18 - out, 1, red); c.px(55 - out, y, redDark)
        if y < 31 { c.px(out + 1, y, redLight); c.px(54 - out, y, redLight) }
    }
    drawBody(c, Look(body: red, shade: redDark, arm: red, eye: nil))
    // A dead man's face.
    c.rect(18, 26, 20, 7, pale)
    c.rect(37, 26, 1, 7, paleShade)
    c.rect(21, 28, 4, 3, socket); c.rect(31, 28, 4, 3, socket)
    c.px(22, 29, C(0xE8FCFF)); c.px(32, 29, C(0xE8FCFF))
    c.px(24, 31, paleShade); c.px(31, 31, paleShade)
    c.rect(25, 32, 6, 1, paleShade)
    c.pattern(18, 24, [
        "..HHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHH",
        "HH..............H.HH",
    ], ["H": hair])
    // The suit: a high neck, the belt.
    c.rect(18, 33, 20, 1, redDark)
    c.rect(18, 36, 20, 1, belt)
    c.rect(27, 36, 2, 1, gold)
    c.px(22, 34, redLight); c.px(33, 34, redLight)
    if let m = p.melee {
        smear(c, hand, p.trail, from: 2, to: 7, C(0xCFF4FF))
        bar(c, hand, m, from: 0, to: 5, red, r: 1.2)
        let f = reach(hand, m, 6)
        c.rect(Int(f.x.rounded()) - 1, Int(f.y.rounded()) - 1, 3, 3, redLight)
        c.px(Int(f.x.rounded()) + 1, Int(f.y.rounded()) + 1, redDark)
    }
}

// MARK: - The Spectre

private let spectreHand = (x: 42.5, y: 31.5)

/// The Spectre: a tall, chalk-white Clawd under a great green hood, the face in its shadow but for two white points of
/// eyes, a green cloak sweeping to the ground, green gloves, trunks and boots; he hangs in the air. Casting, a green
/// glow gathers in his glove. Signature: the wrath of God; his eyes blaze, he raises his hand and a giant spectral hand
/// rises out of the ground in front of him, open, then closes into a fist and sinks away.
private func drawSpectre(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E8A3E), greenDark = C(0x1C5A28), greenLight = C(0x52B860), skin = C(0xF0F4F0), skinShade = C(0xC8D2CA)
    let shadow = C(0x0E1A12)
    let wrath = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.6, color: C(0x247434), edge: greenDark, extra: 3)
    drawLegs(c, Look(leg: skin), step: p.step)
    drawBoots(c, greenLight, step: p.step, rows: 3)
    c.oy += p.breathe
    // A taller body than plain Clawd's.
    let raise = p.armRaise + Int((wrath * 4).rounded())
    c.rect(17, 23, 22, 15, skin)
    c.rect(38, 23, 1, 15, skinShade)
    c.rect(17, 37, 22, 1, skinShade)
    // The hood, its shadow over the face.
    c.pattern(15, 12, [
        "...........GGGG...........",
        ".........GGGGGGGG.........",
        ".......GGGGGGGGGGGG.......",
        "......GGGGGGGGGGGGGG......",
        ".....GGGGGGGGGGGGGGGG.....",
        "....GGGlGGGGGGGGGGGGGG....",
        "...GGGlGGGGGGGGGGGGGGGG...",
        "...GGlGGGGGGGGGGGGGGGGG...",
        "..GGGGGGGGGGGGGGGGGGGGGG..",
        "..GGGGGGGGGGGGGGGGGGGGGGG.",
        ".GGGGggggggggggggggggGGGG.",
        ".GGGgKKKKKKKKKKKKKKKKgGGG.",
        ".GGGgK..............KgGGG.",
        "GGGg..................gGGG",
        "GGGg..................gGGG",
        "GGG....................GGG",
        "GGG....................GGG",
        "GGg....................gGG",
        "GGg....................gGG",
        "gGg....................gGg",
    ], ["G": green, "g": greenDark, "l": greenLight, "K": shadow])
    c.rect(14, 30, 3, 3, skin); c.rect(14, 30, 1, 3, green); c.rect(14, 32, 3, 1, skinShade)
    c.rect(39, 30 - raise, 3, 3, skin)
    c.rect(41, 30 - raise, 1, 3, green); c.rect(39, 32 - raise, 2, 1, skinShade)
    // Brows in shadow and the white points of his eyes.
    c.rect(21, 27, 4, 3, shadow); c.rect(31, 27, 4, 3, shadow)
    let eye = wrath > 0.3 ? C(0xF0FFF0) : white
    c.px(22, 28, eye); c.px(23, 28, eye); c.px(32, 28, eye); c.px(33, 28, eye)
    if wrath > 0.3 {
        c.glowLine(22.5, 28.5, 22.5, 28.5, core: C(0xF0FFF0, wrath), glow: C(0x8AE88A, wrath), coreR: 0.6, glowR: 2.2)
        c.glowLine(32.5, 28.5, 32.5, 28.5, core: C(0xF0FFF0, wrath), glow: C(0x8AE88A, wrath), coreR: 0.6, glowR: 2.2)
    }
    c.rect(24, 31, 7, 1, skinShade)
    // Cloak fastened at the neck, green trunks.
    c.rect(18, 33, 20, 1, greenDark)
    c.px(19, 34, greenDark); c.px(36, 34, greenDark)
    c.rect(17, 35, 22, 3, green)
    c.rect(17, 37, 22, 1, greenDark)
    if p.zap != nil || wrath > 0.3 {
        let k = max(wrath, 0.6)
        c.glowLine(spectreHand.x, spectreHand.y - Double(raise), spectreHand.x, spectreHand.y - Double(raise),
                   core: C(0xF0FFF0, k), glow: C(0x8AE88A, k), coreR: 0.7, glowR: 2.6)
    }
    if let sig = p.signature, wrath > 0.02 { drawSpectralHand(c, wrath: wrath, fist: sig > 0.55, t: p.t) }
}

/// The Spectre's giant hand of green light, rising out of the ground ahead of him (`wrath` 0…1 how far), open or a fist.
private func drawSpectralHand(_ c: PixelCanvas, wrath: Double, fist: Bool, t: Double) {
    let open: [String] = [
        ".F.F.F...",
        ".F.F.F.F.",
        ".F.F.F.F.",
        ".FFFFFFF.",
        "TFFFFFFF.",
        "TTFFFFFF.",
        ".TFFFFFF.",
        "..FFFFFF.",
        "..FFFFF..",
        "...FFFF..",
        "...FFFF..",
    ]
    let closed: [String] = [
        ".........",
        ".........",
        ".........",
        ".FFFFFF..",
        "TFLFLFLF.",
        "TFFFFFFF.",
        ".FFFFFFF.",
        "..FFFFFF.",
        "..FFFFF..",
        "...FFFF..",
        "...FFFF..",
    ]
    let rows = fist ? closed : open
    let rise = Int(((1 - wrath) * 24).rounded())
    let a = wrath * (0.55 + 0.1 * sin(t * 8))
    let ground = 43 - c.oy - c.baseY                          // the ground row in the current offsets
    for (r, row) in rows.enumerated() {
        for (k, ch) in row.enumerated() {
            let col: Px
            switch ch {
            case "F": col = C(0x52C860, a)
            case "T": col = C(0x3AA04A, a)
            case "L": col = C(0xC8FFD0, a)
            default: continue
            }
            for dy in 0..<2 {
                let y = 21 + rise + r * 2 + dy
                guard y <= ground else { continue }
                c.rect(44 + k * 2, y, 2, 1, col)
            }
        }
    }
    let glowY = Double(min(ground, 33 + rise))
    c.glowLine(53, glowY, 53, glowY, core: C(0xF0FFF0, wrath * 0.5), glow: C(0x8AE88A, wrath * 0.6), coreR: 2, glowR: 9)
}

// MARK: - Etrigan

/// Etrigan: Clawd as Kirby's rhyming demon, yellow skin, great swept-back ears, a heavy brow over red eyes and a fanged
/// grin, a red cape with a spiked collar over a purple tunic, clawed hands; his hellfire comes out of his mouth. Signature:
/// he throws his arms up and roars a column of fire into the sky.
private func drawEtrigan(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE8B830), skinShade = C(0xB8861E), skinDark = C(0x8A6012), cape = C(0xB82020), capeDark = C(0x781010)
    let tunic = C(0x4A3A8E), tunicDark = C(0x2E2462), eye = C(0xFF2A1A), mouth = C(0x2A0A08), fang = C(0xF4F0E0)
    let claw = C(0x1A1410)
    let roar = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let breathing = p.fire.map { frac($0.t / shotPeriod) < 0.25 } ?? false
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeDark, extra: -1.5)
    drawLegs(c, Look(leg: tunicDark), step: p.step)
    drawBoots(c, cape, step: p.step, rows: 2)
    c.oy += p.breathe
    // The spiked collar behind his head.
    c.pattern(13, 22, [
        "C............................C",
        "CC..........................CC",
        ".CC........................CC.",
        ".CCc......................cCC.",
        "..CCc....................cCC..",
        "..CCCc..................cCCC..",
        "...CCc..................cCC...",
    ], ["C": cape, "c": capeDark])
    let up = roar > 0.2 ? 5 : 0
    drawBody(c, Look(body: skin, shade: skinShade, arm: skin, eye: nil), armLeft: up, armRight: max(p.armRaise, up))
    // Claws on both hands.
    c.px(14, 33 - up, claw); c.px(14, 35 - up, claw)
    c.px(41, 33 - max(p.armRaise, up), claw); c.px(41, 35 - max(p.armRaise, up), claw)
    // Ears sweeping up and back, a ridge over the head.
    c.pattern(12, 19, [
        "S......",
        "SS.....",
        "sSS....",
        ".sSS...",
        ".sSSS..",
        "..sSSS.",
        "..sSSSS",
        "...sSSS",
    ], ["S": skin, "s": skinDark])
    c.pattern(37, 19, [
        "......S",
        ".....SS",
        "....SSs",
        "...SSs.",
        "..SSSs.",
        ".SSSs..",
        "SSSSs..",
        "SSSs...",
    ], ["S": skin, "s": skinDark])
    c.pattern(21, 24, [
        "...s..s..s..s...",
        "..ssssssssssss..",
    ], ["s": skinShade])
    // Brow, red eyes, the grin (wide open with fire in it when he breathes).
    c.pattern(20, 27, [
        "kkkk........kkkk",
        ".kkkk......kkkk.",
        "..EE........EE..",
    ], ["k": skinDark, "E": eye])
    c.px(22, 30, skinShade); c.px(23, 30, skinShade); c.px(32, 30, skinShade); c.px(33, 30, skinShade)
    if breathing || roar > 0.2 {
        c.pattern(23, 31, [
            "MWMWMWMWMWMWMW",
            "MMMFFFFFFFFFFM",
            "MWMWMWMWMWMWMW",
        ], ["M": mouth, "W": fang, "F": C(0xFF8A1E)])
    } else {
        c.pattern(23, 31, [
            "MMMMMMMMMMMMMM",
            "MW.WMW.WMW.WMW",
        ], ["M": mouth, "W": fang])
        c.rect(24, 32, 1, 1, mouth); c.rect(28, 32, 1, 1, mouth); c.rect(32, 32, 1, 1, mouth)
    }
    // The tunic and belt.
    c.rect(18, 34, 20, 4, tunic)
    c.rect(18, 37, 20, 1, tunicDark)
    c.rect(18, 35, 20, 1, C(0x1E1A2A))
    c.rect(27, 35, 2, 1, C(0xE8C040))
    c.px(20, 34, skinShade); c.px(35, 34, skinShade)
    if breathing {
        c.glowLine(38, 32, 38, 32, core: C(0xFFF2B0), glow: C(0xFF7A1A), coreR: 0.6, glowR: 1.8)
    }
    if roar > 0.05 {
        // Hellfire roared up out of his mouth.
        let tick = Int(p.t * 20)
        for i in stride(from: 11, through: 0, by: -1) {
            let f = Double(i) / 11
            let x = 38 + f * 16 * roar + (noise(tick + i * 3) - 0.5) * 2 * f
            let y = 32 - f * f * 22 * roar + (noise(tick * 7 + i) - 0.5) * 2 * f
            let r = 0.6 + f * 3.2
            let core = f < 0.3 ? C(0xFFF2B0) : f < 0.65 ? C(0xFFB02A) : C(0xFF6A1A)
            let glow = f < 0.5 ? C(0xFF7A1A) : C(0xC82A10)
            c.glowLine(x, y, x, y, core: core.alpha(roar), glow: glow.alpha(roar * 0.9), coreR: r * 0.6, glowR: r + 1)
        }
        if let s = p.signature {
            for i in 0..<6 {
                let f = frac(s * 3 + Double(i) / 6)
                c.px(44 + Int(noise(i * 11) * 14) + Int(f * 4), 14 - Int(f * 12), C(0xFFC23A).alpha((1 - f) * roar))
            }
        }
    }
}

// MARK: - Madame Xanadu

/// Madame Xanadu: Clawd with long black hair cut in a straight fringe under a gold circlet with a blue stone, a violet
/// gown sweeping the ground with gold at the neck and hem, a tarot card always between her fingers; casting, she fans
/// out three glowing cards. Signature: a reading; three cards float out in front of her and turn over one by one, the
/// Sun, the Tower and Death, before they fade.
private func drawMadameXanadu(_ c: PixelCanvas, _ p: Pose) {
    let gown = C(0x6A2A8E), gownDark = C(0x481A66), gownLight = C(0x8A46B0), gold = C(0xE8B840)
    let hair = C(0x121018), hairSheen = C(0x2E2A4A), stone = C(0x3AD0E8)
    let violet = (core: C(0xF0E0FF), glow: C(0x8A4AD8))
    drawLegs(c, Look(leg: C(0x2A1A30)), step: p.step)
    c.oy += p.breathe
    // Hair falling down her back, behind the gown.
    c.rect(14, 27, 4, 12, hair); c.rect(13, 31, 1, 7, hair); c.px(15, 30, hairSheen); c.px(15, 35, hairSheen)
    drawBody(c, Look(arm: gown), armRight: p.armRaise)
    // The gown, flaring to the ground.
    c.rect(18, 33, 20, 5, gown)
    c.rect(37, 33, 1, 5, gownDark)
    let hem = seatedPose ? 39 : 41
    let sway = p.walking ? (p.step == 0 ? 1 : -1) : 0
    for y in 38...hem {
        let k = y - 38
        let l = 18 - (k + 1) / 2 + (k > 1 ? sway : 0), r = 37 + (k + 1) / 2 + (k > 1 ? sway : 0)
        c.rect(l, y, r - l + 1, 1, y == hem ? gold : gown)
        if y < hem {
            for x in stride(from: l + 3, through: r - 2, by: 5) { c.px(x, y, gownDark) }
            c.px(r, y, gownDark)
        }
    }
    c.pattern(22, 33, [
        "GG........GG",
        ".GGG....GGG.",
        "...GGSSGG...",
        ".....GG.....",
    ], ["G": gold, "S": stone])
    c.px(24, 36, gownLight); c.px(31, 36, gownLight)
    // A bell sleeve on the arm.
    c.rect(38, 36 - p.armRaise, 3, 1, gownDark)
    // Hair: a straight fringe, long at the sides, the circlet.
    c.pattern(16, 22, [
        "....HHHHHHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHhHHHHHHHHhHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHH",
        "HHhHHHHHHHHHHHHHHHHHHhHH",
        "HHHH................HHHH",
        "HHH..................HHH",
        "HHH..................HH.",
        "HHH..................HH.",
        "HH...................H..",
    ], ["H": hair, "h": hairSheen])
    c.rect(18, 25, 20, 1, gold)
    c.rect(27, 25, 2, 1, stone)
    c.px(27, 24, gold); c.px(28, 24, gold)
    let hy = 34 - p.armRaise
    if p.zap != nil {
        // Three cards fanned in her raised hand, glowing.
        let glow = 0.6 + 0.4 * sin(p.t * 6)
        c.glowLine(42.5, Double(hy) - 2, 42.5, Double(hy) - 2, core: violet.core.alpha(glow), glow: violet.glow.alpha(glow),
                   coreR: 1, glowR: 4)
        drawTarotCard(c, x: 39, y: hy - 6, face: nil)
        drawTarotCard(c, x: 41, y: hy - 7, face: nil)
        drawTarotCard(c, x: 43, y: hy - 6, face: nil)
    } else {
        c.pattern(40, hy - 4, ["CCC", "CPC", "CGC", "CCC"], ["C": gold, "P": C(0x4A1A6A), "G": C(0xF4D870)])
    }
    if let s = p.signature {
        // The reading: three cards out, each one turned over in turn.
        let fade = s > 0.88 ? (1 - s) / 0.12 : min(1, s / 0.12)
        for k in 0..<3 {
            let x = 44 + k * 8, y = 18 + Int((sin(p.t * 2 + Double(k)) * 1).rounded())
            let start = 0.2 + Double(k) * 0.17
            let f = min(1, max(0, (s - start) / 0.12))
            let w = abs(cos(f * .pi))
            let face: Int? = f > 0.5 ? k : nil
            drawTarotCard(c, x: x, y: y, face: face, squeeze: w, alpha: fade)
            if f > 0.5 {
                c.glowLine(Double(x) + 2.5, Double(y) + 3.5, Double(x) + 2.5, Double(y) + 3.5,
                           core: violet.core.alpha(0.3 * fade), glow: violet.glow.alpha(0.4 * fade), coreR: 2, glowR: 5)
            }
        }
    }
}

/// A tarot card, 5×7 with its top-left at (`x`, `y`): face down (violet back, gold star), or face up: 0 the Sun,
/// 1 the Tower, 2 Death. `squeeze` (0…1) narrows it as it turns over.
private func drawTarotCard(_ c: PixelCanvas, x: Int, y: Int, face: Int?, squeeze: Double = 1, alpha: Double = 1) {
    let rows: [String]
    switch face {
    case .some(0): rows = ["CCCCC", "CWYWC", "CYOYC", "CWYWC", "CWWWC", "CSSSC", "CCCCC"]
    case .some(1): rows = ["CCCCC", "CWFWC", "CWTWC", "CWTWC", "CFTWC", "CTTTC", "CCCCC"]
    case .some(2): rows = ["CCCCC", "CKKKC", "CWWWC", "CKWKC", "CWWWC", "CWKWC", "CCCCC"]
    default: rows = ["CCCCC", "CPPPC", "CPGPC", "CGGGC", "CPGPC", "CPPPC", "CCCCC"]
    }
    let pal: [Character: Px] = ["C": C(0xE8B840), "P": C(0x4A1A6A), "G": C(0xF4D870), "W": C(0xF4ECD8), "Y": C(0xFFD040),
                                "O": C(0xFF8A1E), "S": C(0x8AC8F0), "F": C(0xFF5A1A), "T": C(0x7A7A88), "K": C(0x16161B)]
    let w = max(1, Int((5 * squeeze).rounded()))
    let off = (5 - w) / 2
    for (r, row) in rows.enumerated() {
        let chars = Array(row)
        for k in 0..<w {
            let src = w == 1 ? 2 : min(4, Int((Double(k) / Double(w - 1) * 4).rounded()))
            guard let col = pal[chars[src]] else { continue }
            c.px(x + off + k, y + r, col.alpha(alpha))
        }
    }
}

// MARK: - Phantom Stranger

/// The Phantom Stranger: Clawd in a navy suit and turtleneck under a long black cloak with a high collar, a wide-brimmed
/// fedora pulled low so his face is all shadow but for the gleam of his eyes, and a gold medallion on a chain. Casting,
/// pale wisps curl round his hand. Signature: he's gone; he fades away into a curl of mist, the medallion glinting last,
/// and then he's back as if he'd never left.
private func drawPhantomStranger(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { drawStrangerFigure(c, p); return }
    let fade = habitArc(s, hold: 0.3)
    // Mist curling where he stands.
    for i in 0..<8 {
        let a = Double(i) / 8 * 2 * .pi + p.t * 2.2
        let r = 6 + 6 * fade
        let x = 28 + cos(a) * r, y = 33 + sin(a) * r * 0.6 - fade * 4
        c.rect(Int(x.rounded()), Int(y.rounded()), 2, 1, C(0xC8D0E8, 0.5 * fade))
    }
    overlay(c, alpha: 1 - fade) { l in drawStrangerFigure(l, p) }
    if fade > 0.2 {
        let k = fade * (0.75 + 0.25 * sin(p.t * 9))
        c.glowLine(27.5, 35.5 + Double(p.breathe), 27.5, 35.5 + Double(p.breathe), core: C(0xFFF4C0, k),
                   glow: C(0xE8B840, k), coreR: 0.7, glowR: 2.4)
    }
}

private func drawStrangerFigure(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x2A3A5E), suitDark = C(0x1A2440), suitLight = C(0x3E5280), cloak = C(0x16161C), cloakEdge = C(0x2E3450)
    let hat = C(0x20222C), band = C(0x3A3E54), gold = C(0xE8C040), goldDark = C(0xA88420)
    let wisp = (core: C(0xF0F4FF), glow: C(0x9AA8D8))
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.7, color: cloak, edge: cloakEdge, extra: 1.5)
    drawLegs(c, Look(leg: suitDark), step: p.step)
    drawBoots(c, C(0x101014), step: p.step, rows: 1)
    c.oy += p.breathe
    // The cloak's collar standing up round his face.
    c.pattern(14, 25, [
        "CC..........................",
        "CCC......................CC.",
        ".CCe....................eCCC",
        ".CCe....................eCC.",
        "..Ce....................eC..",
        "...e....................e...",
    ], ["C": cloak, "e": cloakEdge])
    drawBody(c, Look(arm: suit, eye: nil), armRight: p.armRaise)
    // The face in the hat's shadow, only the eyes catching the light.
    c.rect(18, 26, 20, 5, C(0x0A0A12, 0.6))
    c.rect(18, 31, 20, 1, C(0x0A0A12, 0.3))
    c.rect(22, 29, 2, 1, C(0xDDE6FF)); c.rect(32, 29, 2, 1, C(0xDDE6FF))
    // Suit, turtleneck, medallion on its chain.
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, suitDark)
    c.rect(23, 33, 10, 1, suitLight)
    c.px(23, 34, suitDark); c.px(32, 34, suitDark)
    c.px(25, 34, goldDark); c.px(30, 34, goldDark)
    c.pattern(26, 34, [".GG.", "GggG", "GggG", ".GG."], ["G": gold, "g": goldDark])
    c.px(27, 35, C(0xFFF4C0))
    // The fedora, pulled low.
    c.pattern(15, 19, [
        "........HHHHHHHHHH........",
        "......HHHHHHdHHHHHHH......",
        "......HHHHHHHHHHHHHH......",
        "......HHHHHHHHHHHHHH......",
        "......BBBBBBBBBBBBBB......",
        "..HHHHHHHHHHHHHHHHHHHHHH..",
        "HHHHHHHHHHHHHHHHHHHHHHHHHH",
    ], ["H": hat, "B": band, "d": C(0x121218)])
    c.px(22, 20, C(0x34364A)); c.px(22, 21, C(0x34364A))
    if p.zap != nil {
        let h = (x: hand.x, y: hand.y - Double(p.armRaise))
        for k in 0..<2 {
            var prev: (Double, Double)? = nil
            for i in 0...5 {
                let a = p.t * 4 + Double(k) * .pi + Double(i) * 0.5
                let rr = 2.0 + Double(i) * 0.4
                let q = (h.x + cos(a) * rr, h.y + sin(a) * rr * 0.8)
                if let pv = prev {
                    c.glowLine(pv.0, pv.1, q.0, q.1, core: wisp.core.alpha(0.8), glow: wisp.glow.alpha(0.7), coreR: 0.3, glowR: 1.2)
                }
                prev = q
            }
        }
    }
}

// MARK: - Ragman

/// Ragman: Clawd wrapped in the Suit of Souls, a patchwork of browns and rust stitched together, a ragged hood over a dark
/// face with two burning white eyes, loose strips fluttering off his arms and waist; he lashes out with a whipping strip
/// of rag. Signature: the souls in the suit wake; pale faces show in the patches and the rags tear loose and whirl round
/// him before they settle back.
private func drawRagman(_ c: PixelCanvas, _ p: Pose) {
    let rags: [Px] = [C(0x8A6844), C(0xB08C58), C(0x6A4E30), C(0xCDB088), C(0x7E7A4E), C(0xA05A3E), C(0x6E7686)]
    let stitch = C(0x2A2016), hood = C(0x6A4E30), hoodLight = C(0x9A7A50), face = C(0x1E1610), eyes = C(0xF8F4C8)
    let souls = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    let flap = Int(p.t * 6) % 2
    // Strips whirling round behind him in the signature.
    if souls > 0.05 { drawRagWhirl(c, p: p, souls: souls, front: false) }
    drawLegs(c, Look(leg: rags[0]), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 38 - (lifted ? 1 : 0), 2, 1, stitch)
            c.rect(lx, 40 - (lifted ? 1 : 0), 2, 1, rags[2 + i % 3])
        }
    }
    c.oy += p.breathe
    // Loose strips trailing off the back and the left arm.
    c.pattern(13 - flap, 30, ["RR....", ".RRR..", "..RR..", "...R.."], ["R": rags[2]])
    c.rect(15, 36, 1, 3 + flap, rags[3]); c.rect(17, 38, 1, 2, rags[5])
    drawBody(c, Look(body: rags[1], shade: rags[2], arm: rags[0], eye: nil))
    // The patchwork, stitched.
    for (ci, x0) in stride(from: 18, to: 38, by: 5).enumerated() {
        for (ri, y0) in stride(from: 31, to: 38, by: 3).enumerated() {
            let col = rags[Int(noise(ci * 7 + ri * 13 + 3) * 7) % 7]
            c.rect(x0, y0, min(5, 38 - x0), min(3, 38 - y0), col)
            c.px(x0, y0, stitch)
            if x0 + 2 < 38 { c.px(x0 + 2, y0, stitch) }
        }
    }
    c.rect(18, 37, 20, 1, rags[2])
    c.rect(18, 35, 20, 1, stitch.alpha(0.6))
    c.px(15, 33, stitch); c.px(39, 34, stitch)
    // The ragged hood, the dark face and the eyes.
    c.pattern(16, 19, [
        "....h.....h..h....h.....",
        "...HHH...HHHHHH..HHH....",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHlHHHHHHHHlHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHFFFFFFFFFFFFFFFFHHHH",
        "HHHFFFFFFFFFFFFFFFFFFHHH",
        "HHHFFFFFFFFFFFFFFFFFFHHH",
        "HHHFFFFFFFFFFFFFFFFFFHHH",
        "HHHFFFFFFFFFFFFFFFFFFHH.",
        "HHHHFFFFFFFFFFFFFFFFHH..",
        ".HhH................hH..",
        "..h.................h...",
    ], ["H": hood, "h": hoodLight, "l": hoodLight, "F": face])
    c.rect(21, 28, 4, 1, eyes); c.rect(31, 28, 4, 1, eyes)
    c.px(22, 27, eyes.alpha(0.5)); c.px(32, 27, eyes.alpha(0.5))
    c.rect(24, 31, 8, 1, C(0x3A2C1E))
    for x in stride(from: 25, to: 31, by: 2) { c.px(x, 30, C(0x3A2C1E)); c.px(x, 32, C(0x3A2C1E)) }
    if souls > 0.3 {
        // Faces in the patches.
        let a = min(1, (souls - 0.3) / 0.3) * (0.6 + 0.4 * sin(p.t * 9))
        let ghost = C(0xC8FFD8, a)
        let spots: [(Int, Int)] = [(19, 32), (29, 34), (34, 31)]
        for (x, y) in spots { c.px(x, y, ghost); c.px(x + 2, y, ghost); c.rect(x, y + 2, 3, 1, ghost.alpha(0.7)) }
        c.glowLine(23, 28, 23, 28, core: eyes, glow: C(0xC8FFD8, souls), coreR: 0.5, glowR: 2)
        c.glowLine(33, 28, 33, 28, core: eyes, glow: C(0xC8FFD8, souls), coreR: 0.5, glowR: 2)
    }
    if let m = p.melee {
        for (i, ta) in p.trail.enumerated() { drawRagLash(c, angle: ta, t: p.t, alpha: 0.3 / Double(i + 1)) }
        drawRagLash(c, angle: m, t: p.t)
    } else {
        // Strips hanging off the hand.
        c.rect(39, 36, 1, 3 + flap, rags[3]); c.rect(41, 36, 1, 2 + (1 - flap), rags[5])
    }
    if souls > 0.05 { drawRagWhirl(c, p: p, souls: souls, front: true) }
}

/// A whipping strip of rag out of Ragman's hand along `angle`, rippling, frayed at the end.
private func drawRagLash(_ c: PixelCanvas, angle: Double, t: Double, alpha: Double = 1) {
    let rags: [Px] = [C(0x9A7A4E), C(0x7A5A3A), C(0xB0926A), C(0x8A4A34)]
    let r = angle * .pi / 180, nx = -sin(r), ny = cos(r)
    let n = 16
    for i in 0...n {
        let d = Double(i), f = d / Double(n)
        let wave = sin(d * 0.8 - t * 18) * 1.4 * f
        let x = hand.x + cos(r) * (d + 1) + nx * wave, y = hand.y + sin(r) * (d + 1) + ny * wave
        let col = rags[(i / 3) % rags.count].alpha(alpha)
        c.px(Int(x.rounded()), Int(y.rounded()), col)
        if i < 11 { c.px(Int((x + nx).rounded()), Int((y + ny).rounded()), col) }
        if i % 3 == 0 { c.px(Int((x - nx * 0.5).rounded()), Int((y - ny * 0.5).rounded()), C(0x2A2016).alpha(alpha)) }
    }
    let tip = (x: hand.x + cos(r) * Double(n + 1), y: hand.y + sin(r) * Double(n + 1))
    c.px(Int((tip.x + nx * 2).rounded()), Int((tip.y + ny * 2).rounded()), rags[2].alpha(alpha))
    c.px(Int((tip.x - nx * 2).rounded()), Int((tip.y - ny * 2).rounded()), rags[3].alpha(alpha))
}

/// Six rag strips whirling round Ragman on an ellipse: the far ones behind him (`front` false), the near ones in front.
private func drawRagWhirl(_ c: PixelCanvas, p: Pose, souls: Double, front: Bool) {
    let rags: [Px] = [C(0xB08C58), C(0xCDB088), C(0xA05A3E), C(0x7E7A4E), C(0x6E7686), C(0x8A6844)]
    let r = 8 + 14 * souls
    for k in 0..<6 {
        let base = p.t * 4 + Double(k) * .pi / 3
        guard (sin(base) > 0) == front else { continue }
        let lift = Double(k % 3) * 5 - 5
        for j in 0..<9 {
            let a = base - Double(j) * 0.11
            let x = 28 + cos(a) * r, y = 31 - souls * 3 + sin(a) * r * 0.3 + lift + sin(Double(j) * 0.9 + p.t * 12) * 0.8
            c.rect(Int(x.rounded()), Int(y.rounded()), 2, 2, rags[k].alpha(souls * (1 - Double(j) * 0.08)))
        }
    }
}

// MARK: - Dream

/// Dream of the Endless: a chalk-pale Clawd with a wild black thatch of hair and eyes that are pits with a star in each,
/// a long black coat whose hem burns away into shadow-flame, the ruby on its chain at his chest and the pouch of sand at
/// his hip; he drifts above the ground, and sand glitters round his hand when he casts. Signature: he puts on the helm,
/// the gas-mask skull with its ribbed trunk, and the sand swirls up round him.
private func drawDream(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x16161E), coatEdge = C(0x34304A), skin = C(0xEEEEF4), skinShade = C(0xC6C8D4), hair = C(0x0C0C10)
    let ruby = C(0xD8142A), rubyLight = C(0xFF8A9A), sand = C(0xE8D49A), pouch = C(0x7A5A3A)
    let helm = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    if helm > 0.05 { drawSandSwirl(c, p: p, k: helm, front: false) }
    drawTatteredCape(c, t: p.t, speed: p.capeSpeed * 0.6, color: coat, edge: coatEdge, extra: 2, ragged: 4, flicker: 8)
    drawLegs(c, Look(leg: C(0x101016)), step: p.step)
    c.oy += p.breathe
    // The coat's collar up round his neck.
    c.pattern(15, 28, [
        "CC......................CC",
        "CCC....................CCC",
        ".CCe..................eCC.",
        "..Ce..................eC..",
        "...e..................e...",
    ], ["C": coat, "e": coatEdge])
    drawBody(c, Look(body: skin, shade: skinShade, arm: coat, eye: nil), armRight: p.armRaise)
    c.rect(40, 33 - p.armRaise, 1, 3, skin)
    // Eyes: black pits with a pinpoint star.
    c.rect(22, 29, 2, 3, hair); c.rect(32, 29, 2, 3, hair)
    c.px(23, 30, white); c.px(33, 30, white)
    c.px(23, 32, skinShade); c.px(33, 32, skinShade)
    // The coat over the body, the ruby, the pouch of sand.
    c.rect(18, 33, 20, 5, coat)
    c.rect(37, 33, 1, 5, coatEdge)
    c.rect(25, 33, 6, 1, skinShade)
    c.px(25, 34, C(0x8A8A98)); c.px(30, 34, C(0x8A8A98))
    c.pattern(26, 35, [".RR.", "RLRR", ".RR."], ["R": ruby, "L": rubyLight])
    c.rect(19, 36, 3, 3, pouch); c.px(20, 35, C(0xC8A870)); c.px(19, 38, C(0x5A4228))
    // A wild black thatch of hair.
    c.pattern(15, 16, [
        "....H.....H.....H.......",
        "....HH...HHH...HH...H...",
        ".H..HHH.HHHHH.HHHH.HH...",
        ".HHHHHHHHHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHH",
        ".HHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHH.HHHHHHHHHH.HHHHHH",
        ".HHH....HH.....H....HHH.",
        "HHH..................HHH",
        ".HH...................HH",
        "..H...................H.",
    ], ["H": hair])
    if helm > 0.05 {
        // The helm, faded in over his head.
        let a = min(1, helm * 1.6)
        let pal: [Character: Px] = ["H": C(0x4A5248, a), "L": C(0x7A8676, a), "D": C(0x2A2E28, a), "K": C(0x0A0A0C, a),
                                    "R": C(0x5E6A5A, a)]
        c.pattern(17, 19, [
            "......HHHHHHHHHH......",
            "....HHHHHHHHHHHHHH....",
            "...HHLHHHHHHHHHHHHH...",
            "..HHLHHHHHDHHHHHHHHH..",
            "..HLHHHHHHDHHHHHHHHH..",
            ".HLHHHHHHHDHHHHHHHHHH.",
            ".HHHHHHHHHDHHHHHHHHHH.",
            ".HHDDDDDHHHHHHDDDDDHH.",
            ".HDKKKKKDHHHHDKKKKKDH.",
            ".HDKKKKKDHHHHDKKKKKDH.",
            ".HDKKKKKDHHHHDKKKKKDH.",
            ".HHDDDDDHHHHHHDDDDDHH.",
            "..HHHHHHHHRRHHHHHHHH..",
            "...HHHHHHRRRRHHHHHH...",
        ], pal)
        c.px(22, 28, C(0x8AE8FF, a * 0.8)); c.px(32, 28, C(0x8AE8FF, a * 0.8))
        // The ribbed trunk hanging down over his chest.
        let trunk: [(Int, Int)] = [(27, 33), (28, 34), (28, 35), (29, 36), (30, 37), (31, 38)]
        for (i, q) in trunk.enumerated() {
            c.rect(q.0, q.1, 3, 1, (i % 2 == 0 ? C(0x5E6A5A) : C(0x2A2E28)).alpha(a))
        }
        drawSandSwirl(c, p: p, k: helm, front: true)
    }
    if p.zap != nil {
        // Sand glittering round his hand.
        let h = (x: hand.x, y: hand.y - Double(p.armRaise))
        for i in 0..<7 {
            let a = p.t * 5 + Double(i) * 0.9
            let rr = 1.5 + Double(i % 3) * 1.2
            c.px(Int((h.x + cos(a) * rr).rounded()), Int((h.y + sin(a) * rr * 0.8).rounded()),
                 i % 2 == 0 ? sand : C(0xFFF6D8))
        }
    }
}

/// Dream's sand rising round him in a loose spiral, `k` 0…1 strong: the far side behind him, the near side in front.
private func drawSandSwirl(_ c: PixelCanvas, p: Pose, k: Double, front: Bool) {
    for i in 0..<34 {
        let f = Double(i) / 34
        let a = p.t * 3 + f * 5 * .pi
        guard (sin(a) > 0) == front else { continue }
        let r = 9 + 7 * k - f * 3
        let x = 28 + cos(a) * r, y = 43 - f * 30 * k + sin(a) * 2.5
        let col = i % 3 == 0 ? C(0xFFF6D8) : C(0xF0D890)
        let a2 = k * (0.7 + 0.3 * noise(i + Int(p.t * 12)))
        c.px(Int(x.rounded()), Int(y.rounded()), col.alpha(a2))
        if i % 4 == 0 { c.glowLine(x, y, x, y, core: col.alpha(a2), glow: C(0xC8A848, a2 * 0.6), coreR: 0.4, glowR: 1.4) }
    }
}
