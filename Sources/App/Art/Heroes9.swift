import Foundation

// Heroes: the Amazons, the Atlanteans, the New Gods and a few friends. Every one is Clawd in costume, the way the
// rest of the cast is done: hair, helmets and armour drawn over (and around) the blocky body, Clawd's own orange wherever
// a face shows.

let heroes9: [Companion: Persona] = [
    .mera: Persona(name: "Mera", weapon: .magic, magic: Magic(core: C(0xE0FFFF), glow: C(0x2AC8D8), jagged: false),
                   headTop: 20, signature: 3.2, callout: "The sea answers to me.",
                   draw: drawMera),
    .artemis: Persona(name: "Artemis", weapon: .melee, headTop: 17, signature: 3.0, callout: "For Bana-Mighdall!",
                   draw: drawArtemis),
    .donnaTroy: Persona(name: "Donna Troy", weapon: .melee, motion: .fly, headTop: 20, signature: 3.0, callout: "Titans, together!",
                   draw: drawDonnaTroy),
    .nubia: Persona(name: "Nubia", weapon: .melee, headTop: 18, signature: 3.0,
                   draw: drawNubia),
    .hippolyta: Persona(name: "Hippolyta", weapon: .melee, headTop: 15, signature: 3.2, callout: "Sisters, to arms!",
                   draw: drawHippolyta),
    .steveTrevor: Persona(name: "Steve Trevor", weapon: .ranged, shot: .bullet, muzzle: (47, 32), headTop: 20, signature: 2.8,
                   callout: "I can save today.",
                   draw: drawSteveTrevor),
    .mrMiracle: Persona(name: "Mister Miracle", weapon: .melee, motion: .fly, headTop: 23, signature: 3.4,
                   callout: "No trap can hold me!",
                   draw: drawMisterMiracle),
    .bigBarda: Persona(name: "Big Barda", weapon: .melee, armoured: true, pivot: bardaHand, bulk: 1, headTop: 15, signature: 3.0,
                   callout: "Nobody touches Scott.",
                   draw: drawBigBarda),
    .orion: Persona(name: "Orion", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xFFF0E0), glow: C(0xFF8A2A)),
                   muzzle: (45, 33), handGun: false, headTop: 18, signature: 3.0, callout: "Darkseid is mine!",
                   draw: drawOrion),
    .animalMan: Persona(name: "Animal Man", weapon: .melee, headTop: 20, signature: 3.0, callout: "Lend me your strength.",
                   draw: drawAnimalMan),
    .katana: Persona(name: "Katana", weapon: .melee, headTop: 20, signature: 3.2, callout: "Soultaker hungers.",
                   draw: drawKatana),
]

// MARK: - Mera

/// Mera: Clawd with a great mane of crimson hair, the green scale suit of Xebel with a gold collar, scales glinting
/// down the legs. Her hard water pours from her raised hand. Signature: both hands come up, a column of sea water
/// spirals up out of the ground, sets hard into a glassy water trident in her hand, and bursts back into spray.
private func drawMera(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E9A5A), greenDark = C(0x1C6A3C), scale = C(0x7AD89A), gold = C(0xE0B840)
    let hair = C(0xD8302A), hairDark = C(0x941C16)
    let sig = p.signature.flatMap { $0 > 0.05 && $0 < 0.97 ? $0 : nil }
    drawSuitLegs(c, p, green, boot: greenDark, bootRows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() where !(p.step >= 0 && i % 2 == p.step) { c.px(lx, 38, scale); c.px(lx + 1, 40, scale) }
    }
    c.oy += p.breathe
    let lift = sig != nil ? 5 : 0
    drawBody(c, Look(arm: green), armLeft: lift, armRight: max(p.armRaise, lift))
    c.pattern(16, 19, [
        ".......HHHHHHHHHH.......",
        ".....HHHHHHHHHHHHHH.....",
        "...HHHHHhHHHHHHHHhHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHhHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHh........hHHHHHH.",
        ".HHHh..............hHHH.",
        "HHHH................HHHH",
        "HHHh................hHHH",
        "HHH..................HHH",
        "HHHh................hHHH",
        ".HHH................HHH.",
        "HHHh................hHHh",
        "HHH..................HHH",
        "HHh..................hHH",
        "Hh....................hH",
    ], ["H": hair, "h": hairDark])
    c.rect(26, 33, 4, 1, clawdShade)
    // The scale suit and its gold collar.
    c.rect(18, 33, 20, 5, green)
    for y in 34...36 {
        for x in stride(from: 19 + (y % 2) * 2, to: 37, by: 4) { c.px(x, y, scale) }
    }
    c.pattern(22, 33, ["GG........GG", ".GGG....GGG.", "...GGGGGG..."], ["G": gold])
    c.rect(18, 37, 20, 1, greenDark)
    c.rect(37, 33, 1, 4, greenDark)

    let water = (core: C(0xE0FFFF), glow: C(0x2AC8D8))
    if let s = sig {
        let hand = (x: 39.5, y: 29.5)
        if s < 0.42 {
            // The column of water winds up out of the ground to her hand.
            let k = min(1, (s - 0.05) / 0.22)
            let top = 43 - (43 - hand.y) * k
            var prev = (x: 47.0, y: 43.0)
            var y = 43.0
            while y > top {
                y -= 1
                let x = 46 + sin(y * 0.7 + p.t * 9) * 3 * (y - hand.y) / (43 - hand.y)
                c.glowLine(prev.x, prev.y, x, y, core: water.core, glow: water.glow, coreR: 0.6, glowR: 1.8)
                prev = (x, y)
            }
            c.glowLine(14.5, 29.5, 14.5, 29.5, core: water.core, glow: water.glow, coreR: 0.5, glowR: 1.6)
        } else if s < 0.86 {
            let k = min(1, (s - 0.42) / 0.08)
            drawWaterTrident(c, x: 40.5, top: 9, bottom: 39, alpha: k, t: p.t)
        } else {
            // Spray: drops thrown out from where the trident was, falling away.
            let k = (s - 0.86) / 0.11
            for i in 0..<10 {
                let a = -Double.pi / 2 + (noise(i * 7) - 0.5) * 2.6
                let v = 8 + noise(i * 3) * 8
                let x = 40.5 + cos(a) * v * k, y = 20 + sin(a) * v * k + 18 * k * k
                c.px(Int(x), Int(y), water.core.alpha(1 - k * 0.6))
                c.px(Int(x), Int(y) + 1, water.glow.alpha(0.8 * (1 - k)))
            }
        }
        return
    }
    if p.zap != nil {
        // Water curling round the casting hand.
        let hy = 34.5 - Double(p.armRaise)
        for i in 0..<3 {
            let a = p.t * 7 + Double(i) * 2.1
            c.px(Int(40 + cos(a) * 3), Int(hy + sin(a) * 2), i == 0 ? water.core : water.glow)
        }
    }
}

/// A hard-water trident, glassy and shimmering, standing upright at `x` from `bottom` to its prong tips at `top`.
private func drawWaterTrident(_ c: PixelCanvas, x: Double, top: Double, bottom: Double, alpha: Double, t: Double) {
    let core = C(0xE0FFFF).alpha(alpha), glow = C(0x2AC8D8).alpha(alpha * 0.9)
    let bar = top + 6
    c.glowLine(x, bottom, x, bar, core: core, glow: glow, coreR: 0.5, glowR: 1.5)
    c.glowLine(x - 4, bar, x + 4, bar, core: core, glow: glow, coreR: 0.5, glowR: 1.5)
    for dx in [-4.0, 0.0, 4.0] {
        c.glowLine(x + dx, bar, x + dx, top + (dx == 0 ? 0 : 2), core: core, glow: glow, coreR: 0.5, glowR: 1.4)
    }
    // A glint running up the shaft.
    let y = bottom - frac(t * 1.3) * (bottom - top)
    c.px(Int(x), Int(y), white.alpha(alpha))
}

// MARK: - Artemis

/// Artemis: Clawd with fiery orange-red hair pulled into a long high ponytail under a gold headband, the gold and
/// black-leather armour of the Bana-Mighdall with a red-and-leather war skirt and gold greaves, and a huge
/// double-bladed axe, held upright at her side. Signature: she heaves the axe up behind her head with both hands and
/// brings it down into the ground with a crack and a burst of dust, then hauls it back out.
private func drawArtemis(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xE0582A), hairDark = C(0xA0381A), gold = C(0xD8A838), goldDark = C(0x9A7020)
    let leather = C(0x3A2420), red = C(0x9A1E22)
    // The ponytail, swinging behind her.
    let sway = p.walking ? (p.step == 0 ? 1.0 : -1.0) : sin(p.lt * 2) * 0.6
    bar(c, 21, 19, 15, 21, hair, 1.5)
    bar(c, 15, 21, 11 + sway, 30, hair, 1.4)
    bar(c, 11 + sway, 30, 10 + sway * 1.5, 35, hairDark, 1)
    c.rect(20, 18, 3, 2, gold)
    drawLegs(c, Look(leg: leather), step: p.step)
    drawBoots(c, gold, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: clawdOrange))
    c.pattern(17, 19, [
        ".......HHHHHHHH.......",
        ".....HHHHHHHHHHHH.....",
        "...HHHHhHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHhHH..",
        "..HHHHHHHHHHHHHHHHHH..",
        "..GGGGGGGGGGGGGGGGGG..",
        "..HHHh..........hHHH..",
        "..HHH............HHH..",
        "..HH..............HH..",
        "..H................H..",
    ], ["H": hair, "h": hairDark, "G": gold])
    c.px(28, 24, C(0xC83A2A))
    c.rect(26, 33, 4, 1, clawdShade)
    c.pattern(18, 33, [
        "GGGGGGGGGGGGGGGGGGGG",
        "GgGGGGGGGGGGGGGGGGgG",
        "LgGGGGGGGGGGGGGGGGgL",
        "LLLLLLLLLLLLLLLLLLLL",
        "RLRRLRRLRRLRRLRRLRRL",
    ], ["G": gold, "g": goldDark, "L": leather, "R": red])
    c.rect(15, 33, 3, 1, gold)                                  // bracer

    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawLabrys(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawLabrys(c, at: Sprite.hand, angle: a)
        c.rect(38, 33, 3, 3, clawdOrange); c.rect(38, 33, 3, 1, gold)
        return
    }
    let grip = (x: 42.5, y: seatedPose ? 29.5 : 32.5)
    if let s = p.signature, s > 0.06, s < 0.97 {
        var angle = -90.0, at = grip, high = false
        if s < 0.42 {
            let k = (s - 0.06) / 0.36
            angle = -90 - 75 * (0.5 - 0.5 * cos(k * .pi)); at = (40.5, 28.5); high = true
        } else if s < 0.5 {
            let k = (s - 0.42) / 0.08
            angle = -165 + 195 * k * k; at = (40.5 + 1 * k, 28.5 + 6 * k)
            let prev = -165 + 195 * max(0, k - 0.3) * max(0, k - 0.3)
            drawLabrys(c, at: at, angle: prev, alpha: 0.3)
        } else if s < 0.86 {
            angle = 30; at = (41.5, 34.5)
            // The crack and the dust.
            let k = (s - 0.5) / 0.36
            c.rect(46, 43, 12, 1, C(0x3A2A1E))
            c.px(49, 44, C(0x3A2A1E)); c.px(54, 44, C(0x3A2A1E)); c.px(57, 42, C(0x3A2A1E))
            for i in 0..<6 {
                let d = 3 + Double(i) * 1.6 + k * 6
                let col = C(0xD8CCB8).alpha(0.85 * (1 - k))
                c.px(Int(52 - d), 42 - i % 3, col); c.px(Int(52 + d * 0.7), 42 - (i + 1) % 3, col)
            }
        } else {
            let k = (s - 0.86) / 0.11
            angle = 30 - 120 * k; at = (41.5 + k, 34.5 - k)
        }
        drawLabrys(c, at: at, angle: angle)
        if high {
            c.rect(37, 27, 4, 3, clawdOrange); c.rect(37, 27, 1, 3, gold)
        } else {
            c.rect(Int(at.x) - 3, Int(at.y) - 1, 3, 3, clawdOrange)
        }
        return
    }
    drawLabrys(c, at: grip, angle: -90)
    c.rect(39, Int(grip.y) - 1, 3, 3, clawdOrange); c.rect(39, Int(grip.y) - 1, 1, 3, gold)
}

/// Artemis' axe: a long dark haft with a gold butt cap and a great double crescent head of bronze-edged steel, held
/// at `at`, head out along `angle`.
private func drawLabrys(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        s.rect(9, 20, 26, 1, C(0x4A3020))
        for x in [18, 20, 22] { s.px(x, 20, C(0x8A5A30)) }
        s.px(8, 20, C(0xD8A838))
        s.pattern(27, 12, [
            "EEEEEEEE",
            "ESSSSSSE",
            ".SSSSSS.",
            "..SSSS..",
            "..SSSS..",
            "...SS...",
            "...GG...",
            "...GG...",
            "...GGGGW",
            "...GG...",
            "...GG...",
            "...ss...",
            "..ssss..",
            "..ssss..",
            ".ssssss.",
            "EssssssE",
            "EEEEEEEE",
        ], ["E": C(0xF0F2F8), "S": C(0xB8BEC8), "s": C(0x8A909C), "G": C(0xB8862A), "W": C(0xE8ECF4)])
    }
}

// MARK: - Donna Troy

/// Donna Troy: Clawd with long black hair and the starry-night suit, a deep midnight blue full of little stars that
/// twinkle, and silver Amazon bracelets. Fights with her fists; flies leaning into it, hair streaming, fist first.
/// Signature: the stars lift off her suit and wheel round her like a small galaxy, then settle back where they were.
private func drawDonnaTroy(_ c: PixelCanvas, _ p: Pose) {
    let night = C(0x1C2660), nightDark = C(0x111840), silver = C(0xC8CCD4)
    let hair = C(0x16161E), hairLight = C(0x34344A)
    let swirl = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    // Where her stars sit on the suit, and the colour each one twinkles.
    let stars: [(Int, Int)] = [(20, 34), (24, 36), (29, 33), (33, 35), (36, 34), (19, 39), (24, 41), (32, 40), (35, 42),
                               (16, 34), (39, 34), (27, 37)]
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            for y in 21...31 {
                let len = 5 + (y % 3) + Int((sin(p.t * 14 + Double(y)) * 1.2).rounded())
                c.rect(17 - len, y, len + 2, 1, y % 3 == 0 ? hairLight : hair)
            }
        } else {
            for x in [15, 37] { c.rect(x, 24, 4, 12, hair); c.rect(x + (x < 28 ? 0 : 3), 27, 1, 9, hairLight) }
        }
        drawSuitLegs(c, p, night, boot: nightDark, bootRows: 2)
        c.oy += p.breathe
        drawBody(c, Look(arm: night))
        c.pattern(16, 19, [
            ".......HHHHHHHHHH.......",
            ".....HHHHHHHHHHHHHH.....",
            "...HHHHHHHHHHHhHHHHHH...",
            "..HHHHhHHHHHHHHHHHHHHH..",
            "..HHHHHHHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHHHHHHHHHH.",
            ".HHHHHHh.......hHHHHHHH.",
            ".HHHh..............hHHH.",
            ".HHH................HHH.",
        ], ["H": hair, "h": hairLight])
        c.rect(19, 24, 18, 1, silver)                                     // a silver circlet with a star
        c.pattern(27, 22, [".W.", "WWW", ".W."], ["W": white])
        c.rect(26, 33, 4, 1, clawdShade)
        c.rect(18, 33, 20, 5, night)
        c.rect(18, 37, 20, 1, nightDark)
        c.rect(24, 33, 8, 1, nightDark)                                   // the neckline
        // The stars: in the suit, or out round her.
        for (i, st) in stars.enumerated() {
            let tw = noise(Int(p.t * 5) + i * 13)
            let col = tw > 0.75 ? white : (i % 3 == 0 ? C(0xA8C8FF) : C(0xE8ECFF))
            if (p.flying || seatedPose) && st.1 > 37 { continue }
            if swirl > 0.02 {
                let a = p.t * 1.6 + Double(i) * 2 * .pi / Double(stars.count)
                let ox = 28 + cos(a) * 17, oy = 31 + sin(a) * 9
                let x = Double(st.0) + (ox - Double(st.0)) * swirl, y = Double(st.1) + (oy - Double(st.1)) * swirl
                if swirl > 0.6 && (tw > 0.4 || i % 2 == 0) {
                    twinkle(c, Int(x.rounded()), Int(y.rounded()))
                } else {
                    c.px(Int(x.rounded()), Int(y.rounded()), col)
                }
            } else {
                c.px(st.0, st.1, col)
            }
        }
        c.rect(15, 35, 3, 1, silver)
        if p.flying {
            c.rect(38, 31, 4, 2, night); c.rect(41, 30, 1, 4, silver); c.rect(42, 30, 3, 3, night)
            return
        }
        if let a = p.melee {
            drawFist(c, angle: a, trail: p.trail, from: (39.5, 34.5), reach: 5, arm: night, fist: night)
            let r = a * .pi / 180
            c.px(Int(39.5 + cos(r) * 3.5), Int(34.5 + sin(r) * 3.5), silver)
        } else {
            c.rect(38, 35, 3, 1, silver)
        }
    }
}

// MARK: - Nubia

/// Nubia: Clawd with long black braids threaded with gold beads under a gold tiara with a red stone, gold armour
/// over a white Amazon tunic, a round bronze shield on her left arm and a short broad sword, held low when she isn't
/// using it. Signature: she grounds the shield in front of her and lifts the sword high over it, a guardian at the
/// gate, a gleam running up the blade.
private func drawNubia(_ c: PixelCanvas, _ p: Pose) {
    let gold = C(0xE0B040), goldDark = C(0xA8802A), tunic = C(0xF0ECE0), tunicShade = C(0xC8C2B0)
    let hair = C(0x1A1418), hairLight = C(0x3A2E30)
    let sig = p.signature.flatMap { $0 > 0.06 && $0 < 0.96 ? $0 : nil }
    // Braids behind the shoulders.
    for x in [14, 16] {
        c.rect(x, 24, 2, 14, hair)
        for y in [28, 32, 36] { c.px(x, y + (x % 3) - 1, gold) }
    }
    drawLegs(c, Look(leg: clawdOrange), step: p.step)
    drawBoots(c, gold, step: p.step, rows: 4)
    c.oy += p.breathe
    let raised = sig != nil
    drawBody(c, Look(arm: clawdOrange), armRight: raised ? 5 : 0)
    c.pattern(17, 19, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHHHhHHHHhHHHH...",
        "..HHHhHHHHHHHHHHHHhH..",
        "..GGGGGGGGGRGGGGGGGG..",
        "..HHHHHHHHGRRGHHHHHH..",
        "..HhHh..........hHhH..",
        "..HHH............HHH..",
        "..HH..............HH..",
    ], ["H": hair, "h": hairLight, "G": gold, "R": C(0xC8202A)])
    c.rect(26, 33, 4, 1, clawdShade)
    c.pattern(18, 33, [
        "GGGGGGGGGGGGGGGGGGGG",
        "GgGGGgGGGGGGGGgGGGgG",
        "TGGGGGgGGGGGGgGGGGGT",
        "TTTggggggggggggggTTT",
        "TtTTtTTtTTtTTtTTtTTt",
    ], ["G": gold, "g": goldDark, "T": tunic, "t": tunicShade])
    c.rect(38, 33 - (raised ? 5 : 0), 3, 1, gold)

    if let s = sig {
        // Shield grounded in front, sword up high over it.
        let k = habitArc((s - 0.06) / 0.9, hold: 0.7)
        drawRoundShield(c, cx: 15 + Int((30 * k).rounded()), cy: 35 + Int((3 * k).rounded()))
        drawAmazonSword(c, at: (40.5, 29.5), angle: -90 + 25 * (1 - k), trail: [])
        if k > 0.95 {
            let g = frac(s * 3)
            c.glowLine(40.5, 26 - g * 12, 40.5, 26 - g * 12, core: white, glow: C(0xFFF6C8), coreR: 0.6, glowR: 1.8)
        }
        return
    }
    drawRoundShield(c, cx: 15, cy: seatedPose ? 33 : 35)
    if let a = p.melee {
        drawAmazonSword(c, at: Sprite.hand, angle: a, trail: p.trail)
    } else {
        drawAmazonSword(c, at: (41.5, seatedPose ? 30.5 : 33.5), angle: -80, trail: [])
    }
}

/// A round bronze Amazon shield with a darker rim and a gold boss, centred on (`cx`, `cy`).
private func drawRoundShield(_ c: PixelCanvas, cx: Int, cy: Int) {
    c.ellipse(cx, cy, 5, 5, C(0x7A4A1A))
    c.ellipse(cx, cy, 4, 4, C(0xB8782A))
    c.ellipse(cx - 1, cy - 1, 2, 2, C(0xD09848))
    c.rect(cx - 1, cy - 1, 3, 3, C(0xE0B040)); c.px(cx - 1, cy - 1, C(0xFFF0B0))
}

// MARK: - Hippolyta

/// Hippolyta: the Amazon queen. Clawd with long black hair under a tall gold crown set with red stones, an ornate gold
/// breastplate over a blue war skirt, gold greaves and a royal red cape, and a long sword. Signature: she lifts the
/// crown off, breathes on it, gives it a polish and sets it back on her head, gleaming.
private func drawHippolyta(_ c: PixelCanvas, _ p: Pose) {
    let gold = C(0xE8BC40), goldDark = C(0xA8842A), blue = C(0x2A4AA0), blueDark = C(0x1A3070)
    let cape = C(0xA01C28), capeDark = C(0x6A1018), hair = C(0x1E1618), hairLight = C(0x3E3034)
    drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeDark, extra: 1)
    drawLegs(c, Look(leg: clawdOrange), step: p.step)
    drawBoots(c, gold, step: p.step, rows: 4)
    c.oy += p.breathe
    // Signature: 0.08…0.3 off, 0.3…0.72 breathed on and polished, 0.72…0.9 back on.
    var lift = 0.0
    var holding = false
    if let s = p.signature {
        if s > 0.08 && s < 0.9 {
            holding = true
            lift = s < 0.3 ? (s - 0.08) / 0.22 : (s < 0.72 ? 1 : 1 - (s - 0.72) / 0.18)
            lift = 0.5 - 0.5 * cos(lift * .pi)
        }
    }
    drawBody(c, Look(arm: clawdOrange), armRight: holding ? Int((9 * lift).rounded()) : 0)
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHhHHHHHHhHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHh........hHHHHHH.",
        ".HHHh..............hHHH.",
        ".HHH................HHH.",
        "HHHh................hHHH",
        "HHH..................HHH",
        "HHh..................hHH",
        "HH....................HH",
        "Hh....................hH",
    ], ["H": hair, "h": hairLight])
    c.rect(26, 33, 4, 1, clawdShade)
    c.pattern(18, 33, [
        "GGGGGGGGGGGGGGGGGGGG",
        "GgGGGGgGGggGGgGGGGgG",
        ".gGGGgGGGGGGGGgGGGg.",
        "BBBBBBBBBBBBBBBBBBBB",
        "BbBBbBBbBBbBBbBBbBBb",
    ], ["G": gold, "g": goldDark, "B": blue, "b": blueDark])
    c.pattern(25, 33, ["..G..", ".GgG.", "..G.."], ["G": C(0xFFE890), "g": C(0xC8202A)])   // the royal clasp
    c.rect(15, 33, 3, 1, gold)

    // The crown: on her head, or held up in her hand.
    let cx = 20 + Int((16 * lift).rounded()), cy = 15 + Int((5 * lift).rounded())
    var jiggle = 0
    if let s = p.signature, s > 0.42, s < 0.7 { jiggle = Int(s * 30) % 2 }
    drawCrown(c, x: cx + jiggle, y: cy)
    if holding {
        c.rect(37, 33 - Int((9 * lift).rounded()), 3, 3, clawdOrange)
        if let s = p.signature, s > 0.3, s < 0.44 {
            // A breath of mist on the gold.
            let k = (s - 0.3) / 0.14
            for i in 0..<3 { c.px(32 + i * 2, 31 - Int(k * 3) - i, C(0xE8F0FF, 0.7 * (1 - k))) }
        }
        if let s = p.signature, s > 0.42, s < 0.7, Int(s * 40) % 3 == 0 { twinkle(c, cx + 10, cy + 1) }
    }
    if let s = p.signature, s >= 0.86, s < 0.98 { twinkle(c, 33, 15); twinkle(c, 22, 16) }

    if let a = p.melee {
        drawQueenSword(c, at: Sprite.hand, angle: a, trail: p.trail)
        c.rect(38, 33, 3, 3, clawdOrange); c.rect(38, 33, 3, 1, gold)
    } else if holding {
        drawQueenSword(c, at: (47.5, 25.5), angle: 90, trail: [])            // stood in the ground beside her
    } else {
        // Point down in the ground before her, her hand resting on the pommel.
        let top = seatedPose ? 21.5 : 25.5
        bar(c, 39.5, 34.5, 42.5, top + 1, clawdOrange, 1.1)
        drawQueenSword(c, at: (43.5, top), angle: 90, trail: [])
        c.rect(42, Int(top) - 2, 3, 2, clawdOrange); c.rect(42, Int(top), 3, 1, gold)
    }
}

/// Hippolyta's crown: tall gold points with red stones, its top-left corner at (`x`, `y`).
private func drawCrown(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        "G.....G..G.....G",
        "GG...GGGGGG...GG",
        "GGG.GGGRRGGG.GGG",
        "GGGGGGGRRGGGGGGG",
        "GgGRGgGGGGgGRGgG",
        "gggggggggggggggg",
    ], ["G": C(0xF0C848), "g": C(0xA8842A), "R": C(0xD0202A)])
    c.px(x + 1, y + 2, C(0xFFF4C0))
}

/// The queen's long sword: a gold guard and pommel, a long bright blade, swung from `at`.
private func drawQueenSword(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, trail: [Double]) {
    for (i, a) in trail.enumerated() {
        let s = along(a, 4, from: at), e = along(a, 21, from: at)
        c.glowLine(s.x, s.y, e.x, e.y, core: C(0xFFF0C8), glow: C(0xE8BC40), coreR: 0.4, glowR: 1.4, strength: 0.4 / Double(i + 1))
    }
    prop(c, at: at, angle: angle) { s in
        s.rect(16, 20, 4, 1, C(0x5A2A1E))
        s.rect(15, 19, 1, 3, C(0xE8BC40))
        s.rect(20, 17, 1, 7, C(0xE8BC40)); s.px(20, 20, C(0xD0202A))
        s.rect(21, 19, 16, 1, C(0xEEF2F8))
        s.rect(21, 20, 17, 1, C(0xB0B8C4))
        s.rect(21, 21, 16, 1, C(0x8A909C))
        s.px(38, 20, C(0xEEF2F8))
    }
}

/// Nubia's sword: a short, broad leaf blade with a gold guard, swung from `at`.
private func drawAmazonSword(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, trail: [Double]) {
    for (i, a) in trail.enumerated() {
        let s = along(a, 4, from: at), e = along(a, 17, from: at)
        c.glowLine(s.x, s.y, e.x, e.y, core: C(0xFFF0C8), glow: C(0xE0B040), coreR: 0.4, glowR: 1.4, strength: 0.4 / Double(i + 1))
    }
    prop(c, at: at, angle: angle) { s in
        s.rect(16, 20, 4, 1, C(0x4A2A1A))
        s.px(15, 20, C(0xE0B040))
        s.rect(20, 18, 1, 5, C(0xE0B040))
        s.pattern(21, 18, [
            "..LLLLLLLLL...",
            "LLLLLLLLLLLLL.",
            "SSSSSSSSSSSSSS",
            "dddddddddddd..",
            "..ddddddddd...",
        ], ["L": C(0xEEF2F8), "S": C(0xB8BEC8), "d": C(0x7A808C)])
    }
}

// MARK: - Steve Trevor

/// Steve Trevor: the pilot. Clawd with neat side-parted blond hair, flying goggles pushed up on his forehead, a brown
/// leather bomber jacket with a sheepskin collar over a khaki shirt and tie, olive trousers and a service pistol.
/// Signature: he holsters the pistol, checks the watch on his wrist, and snaps off a salute.
private func drawSteveTrevor(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x7A4A2A), jacketDark = C(0x5A3418), fleece = C(0xEADFC4), fleeceShade = C(0xC8B898)
    let shirt = C(0xCDBF90), hair = C(0xD8B060), hairDark = C(0xA88438), olive = C(0x5E5A3E)
    drawLegs(c, Look(leg: olive), step: p.step)
    drawBoots(c, C(0x3A2A1E), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket))
    c.pattern(17, 20, [
        "......HHHHHHHHHH......",
        "....HHHHHHHHHHHHHH....",
        "...HHHHhHHHHHHHHHHH...",
        "..HHHHHhhHHHHHHHHHHH..",
        "..HHHH...hhHHHHHHHHH..",
        "..HHh.......hhHHHHHh..",
        "..Hh.............hH...",
    ], ["H": hair, "h": hairDark])
    // Goggles up on the brow.
    c.rect(18, 23, 20, 1, C(0x4A3020))
    c.pattern(21, 22, ["FFFF.....FFFF", "FGGF.....FGGF", ".FF.......FF."], ["F": C(0x6A5A3A), "G": C(0x9AC8E0)])
    c.px(22, 23, white); c.px(31, 23, white)
    c.rect(26, 32, 4, 1, clawdShade)
    // The jacket, open over the shirt and tie, the fleece collar.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(26, 33, 4, 5, shirt); c.px(27, 33, C(0x3A3A2A)); c.px(28, 33, C(0x3A3A2A)); c.rect(27, 34, 2, 3, C(0x4A4A36))
    c.pattern(18, 33, [
        "FFFFFF........FFFFFF",
        ".fFFf..........fFFf.",
    ], ["F": fleece, "f": fleeceShade])
    c.rect(25, 34, 1, 4, jacketDark); c.rect(30, 34, 1, 4, jacketDark)
    c.rect(18, 37, 20, 1, jacketDark)
    c.rect(37, 34, 1, 3, jacketDark)

    if let s = p.signature, s > 0.06, s < 0.95 {
        // Pistol in its holster on his hip.
        c.rect(35, 36, 3, 3, C(0x4A3020)); c.rect(36, 35, 2, 1, C(0x2A2A30))
        if s < 0.52 {
            // Wrist up to read the watch.
            c.rect(36, 30, 5, 3, jacket); c.rect(36, 30, 1, 3, jacketDark)
            c.rect(37, 33, 3, 1, clawdOrange)
            c.rect(38, 30, 2, 2, C(0xD8DCE4)); c.px(38, 30, C(0x3A3A40))
            if s > 0.3 && Int(s * 30) % 2 == 0 { c.px(40, 29, white) }
        } else {
            // The salute: hand flat at the brow.
            bar(c, 39.5, 33.5, 39.5, 26.5, jacket, 1.3)
            c.rect(35, 23, 7, 2, clawdOrange); c.rect(35, 24, 7, 1, clawdShade)
        }
        return
    }
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, jacket)
    drawPistol(c, x: 40, y: 31)
}

// MARK: - Mister Miracle

/// Mister Miracle: Scott Free, the super escape artist. A red Clawd under a red cowl with a yellow mask across the
/// eyes, yellow straps crossing his chest, green gloves and boots, and a green cape with a tall collar. He flies
/// standing on two humming aero-discs. Signature: chains snap round him, padlock and all; he strains, and they burst
/// off in every direction, and he flings his arms up: ta-da!
private func drawMisterMiracle(_ c: PixelCanvas, _ p: Pose) {
    let sig = p.signature
    var chained = false, burst: Double? = nil, tada = false
    if let s = sig {
        if s > 0.06 && s < 0.6 { chained = true }
        if s >= 0.6 && s < 0.85 { burst = (s - 0.6) / 0.25 }
        if s >= 0.66 && s < 0.97 { tada = true }
    }
    let strain = chained && (sig ?? 0) > 0.25
    if strain { c.ox += Int(p.t * 30) % 2 == 0 ? 1 : -1 }
    layer(c, lean: p.flying ? 5 : 0) { c in
        let red = C(0xC8202A), redDark = C(0x8A1418), yellow = C(0xF0C830), yellowDark = C(0xB8961E)
        let green = C(0x5AC84A), cape = C(0x1E6A2E), capeDark = C(0x124A1E)
        if p.flying {
            drawFlyingCape(c, t: p.t, color: cape, edge: capeDark)
        } else {
            drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeDark)
        }
        var legs = p
        if p.flying { legs.step = -1; legs.flying = false }
        drawSuitLegs(c, legs, red, boot: green, bootRows: 3)
        if p.flying {
            // Aero-discs under his feet.
            for x in [21, 33] {
                c.glowLine(Double(x) - 1, 45, Double(x) + 4, 45, core: C(0xE8FAFF), glow: C(0x6AD8FF), coreR: 0.4, glowR: 1.8,
                           strength: 0.8 + 0.2 * sin(p.t * 30))
                c.rect(x - 2, 44, 7, 1, C(0xC8CCD4)); c.rect(x - 1, 45, 5, 1, C(0x7A808C))
            }
        }
        c.oy += p.breathe
        drawBody(c, Look(body: red, shade: redDark, arm: green, eye: nil))
        if tada {
            c.rect(15, 33, 3, 3, red); c.rect(38, 33, 3, 3, red)
            bar(c, 16.5, 33.5, 12.5, 23.5, red, 1.1); bar(c, 39.5, 33.5, 43.5, 23.5, red, 1.1)
            c.rect(11, 20, 3, 3, green); c.rect(43, 20, 3, 3, green)
        }
        // Cowl top, the tall collar either side, the yellow mask with the eyes.
        c.pattern(19, 24, ["...RRRRRRRRRRRR...", ".RRRRRRRRRRRRRRRR."], ["R": red])
        c.pattern(15, 25, [
            "GG......................GG",
            "GGg....................gGG",
            "GGGg..................gGGG",
            ".GGg..................gGG.",
            "..Gg..................gG..",
        ], ["G": cape, "g": capeDark])
        c.rect(20, 28, 16, 4, yellow); c.rect(20, 31, 16, 1, yellowDark)
        c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
        c.rect(23, 32, 10, 1, clawdOrange); c.rect(24, 33, 8, 1, clawdShade)
        // Chest straps and belt.
        c.pattern(18, 33, [
            "YY................YY",
            "..YY............YY..",
            "....YY........YY....",
            "......YY....YY......",
            "YYYYYYYYYYYYYYYYYYYY",
        ], ["Y": yellow])
        c.rect(27, 37, 2, 1, yellowDark)

        if chained { drawChains(c, t: p.t, tight: strain) }
        if let k = burst {
            // Links flying off in every direction.
            for i in 0..<12 {
                let a = Double(i) * 2 * .pi / 12 + noise(i) * 0.4
                let d = 4 + k * (14 + noise(i * 5) * 8)
                let x = 28 + cos(a) * d, y = 33 + sin(a) * d * 0.8 + 10 * k * k
                c.rect(Int(x), Int(y), 2, 1, C(0xA8ACB8).alpha(1 - k * 0.7)); c.px(Int(x) + 1, Int(y) + 1, C(0x5A5E68).alpha(1 - k * 0.7))
            }
            if k < 0.5 { c.pattern(26, 36 + Int(k * 14), [".GG.", "G..G", "GGGG", "GKGG"], ["G": C(0xE0B040), "K": ink]) }
        }
        if tada {
            let s = sig ?? 0
            if Int(s * 20) % 2 == 0 { twinkle(c, 9, 17); twinkle(c, 48, 18) } else { twinkle(c, 15, 16); twinkle(c, 42, 15) }
            return
        }
        if p.flying {
            c.rect(38, 33, 3, 3, green)
            return
        }
        if let a = p.melee, !chained {
            drawFist(c, angle: a, trail: p.trail, from: (39.5, 34.5), reach: 5, arm: red, fist: green)
        }
    }
}

/// Chains wrapped round Mister Miracle, three turns and a padlock. `tight`: he's straining against them.
private func drawChains(_ c: PixelCanvas, t: Double, tight: Bool) {
    let light = C(0xB8BCC8), dark = C(0x5A5E68)
    for (n, y) in [28, 33, 38].enumerated() {
        let sag = tight ? 0 : n % 2
        for x in stride(from: 14, through: 41, by: 3) {
            if (x / 3) % 2 == 0 {
                c.rect(x, y + sag, 3, 1, light); c.rect(x, y + sag + 1, 3, 1, dark)
            } else {
                c.px(x, y + sag, light); c.px(x + 2, y + sag, light); c.rect(x, y + sag + 1, 3, 1, dark)
            }
        }
    }
    c.pattern(26, 34, [".GG.", "G..G", "GGGG", "GKGG", "GGGG"], ["G": C(0xE0B040), "K": ink])
    if tight && Int(t * 20) % 3 == 0 { c.px(13, 31, white); c.px(43, 36, white) }
}

// MARK: - Big Barda

private let bardaHand = (x: 41.5, y: 32.5)

/// Big Barda: a head taller than everyone, long legs, a gold Female Furies helmet with a crest and cheek guards and a
/// blue brow band, long black hair pouring out the back, blue armour with gold shoulders, belt and gauntlets, and the
/// mega-rod. Signature: she points the mega-rod and blasts open a Boom Tube, a swirling ring of light, which booms
/// shut again.
private func drawBigBarda(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A4A9A), blueDark = C(0x1A2E6A), gold = C(0xE0B030), goldDark = C(0xA8801E)
    let hair = C(0x16161E), hairLight = C(0x30303E)
    // Long legs.
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 4, 2, blueDark); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 34, 2, lifted ? 9 : 10, blueDark)
        c.rect(lx, lifted ? 39 : 40, 2, 3, gold)
    }
    c.oy += p.breathe - 2
    // Hair pouring out under the helmet at the back.
    for y in 22...35 {
        let w = 3 + (y > 28 ? 1 : 0) + Int((sin(p.lt * 3 + Double(y) * 0.6) * 0.8).rounded())
        c.rect(17 - w, y, w + 2, 1, y % 4 == 0 ? hairLight : hair)
    }
    drawBody(c, Look(arm: blue))
    c.pattern(16, 17, [
        ".........GG.............",
        "........GGGG............",
        ".......GGgGGG...........",
        ".....GGGGgGGGGGGG.......",
        "...GGGGGGGGGGGGGGGGG....",
        "..GGGGGGGGgGGGGGGGGGG...",
        "..GGGGGGGGGGGGGGGGGGGG..",
        "..BBBBBBBBBBBBBBBBBBBB..",
        "..GGg..............gGG..",
        "..GGg..............gGG..",
        "..GGg..............gGG..",
        "...Gg..............gG...",
    ], ["G": gold, "g": goldDark, "B": blue])
    c.rect(21, 19, 3, 1, C(0xFFF0B0))
    c.rect(26, 33, 4, 1, clawdShade)
    // Armour.
    c.rect(18, 33, 20, 5, blue)
    c.pattern(18, 33, [
        "GG................GG",
        "GgG..GGGGGGGG....GgG",
        "......GgGGgG........",
        ".......GGGG.........",
        "GGGGGGGGGGGGGGGGGGGG",
    ], ["G": gold, "g": goldDark])
    c.rect(37, 33, 1, 4, blueDark)
    c.rect(14, 31, 4, 2, gold); c.rect(38, 31, 4, 2, gold)        // shoulders
    c.rect(15, 35, 3, 1, gold)

    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawMegaRod(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1), lit: false) }
        drawMegaRod(c, at: Sprite.hand, angle: a, lit: true)
        c.rect(38, 33, 3, 3, blue); c.rect(38, 35, 3, 1, gold)
        return
    }
    if let s = p.signature, s > 0.06, s < 0.95 {
        let aim = s < 0.18 ? -90 + 60 * (s - 0.06) / 0.12 : -30.0
        drawMegaRod(c, at: Sprite.hand, angle: aim, lit: s > 0.18)
        c.rect(38, 33, 3, 3, blue); c.rect(38, 35, 3, 1, gold)
        if s > 0.18 {
            let k = habitArc((s - 0.18) / 0.77, hold: 0.6)
            drawBoomTube(c, cx: 56, cy: 22, k: k, t: p.t)
            if s < 0.26 { c.glowLine(52, 26, 56, 22, core: white, glow: C(0x8AD8FF), coreR: 0.6, glowR: 2) }
        }
        return
    }
    let grip = (x: 41.5, y: seatedPose ? 31.5 : 33.5)
    drawMegaRod(c, at: grip, angle: -90, lit: false)
    c.rect(39, Int(grip.y) - 1, 3, 3, blue); c.rect(39, Int(grip.y) + 1, 3, 1, gold)
}

/// The mega-rod: a long silver rod with gold knobs, its far end glowing when `lit`, held at `at` along `angle`.
private func drawMegaRod(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1, lit: Bool) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        s.rect(10, 20, 22, 1, C(0xD4D8E0))
        s.rect(10, 21, 22, 1, C(0x8A909C))
        s.rect(7, 19, 3, 4, C(0xE0B030))
        s.rect(32, 19, 3, 4, C(0xE0B030)); s.rect(32, 22, 3, 1, C(0xA8801E))
        s.rect(35, 20, 1, 2, lit ? white : C(0xF0E0A0))
    }
    if lit {
        let tip = along(angle, 15, from: at)
        c.glowLine(tip.x, tip.y, tip.x, tip.y, core: C(0xFFF4E0), glow: C(0xFF9A4A), coreR: 0.6, glowR: 2)
    }
}

/// A Boom Tube opening at (`cx`, `cy`): a ring of white-blue light with a swirling inside, `k` 0…1 how open it is.
private func drawBoomTube(_ c: PixelCanvas, cx: Double, cy: Double, k: Double, t: Double) {
    guard k > 0.02 else { return }
    let rx = 9 * k, ry = 12 * k
    let n = 28
    for i in 0..<n {
        let a = Double(i) / Double(n) * 2 * .pi, b = Double(i + 1) / Double(n) * 2 * .pi
        c.glowLine(cx + cos(a) * rx, cy + sin(a) * ry, cx + cos(b) * rx, cy + sin(b) * ry,
                   core: C(0xF4FCFF), glow: C(0x6AB8FF), coreR: 0.5, glowR: 1.8)
    }
    c.ellipse(Int(cx), Int(cy), Int(rx) - 1, Int(ry) - 1, C(0x1A2A6A, 0.6))
    for j in 0..<3 {
        let a = t * 6 + Double(j) * 2.1
        let r: Double = 0.6
        c.glowLine(cx + cos(a) * rx * r, cy + sin(a) * ry * r, cx + cos(a + 1.2) * rx * 0.3, cy + sin(a + 1.2) * ry * 0.3,
                   core: C(0xC8E8FF, 0.8), glow: C(0x4A8AFF, 0.5), coreR: 0.4, glowR: 1.2)
    }
}

// MARK: - Orion

/// Orion: the dog of war of New Genesis. Clawd under a steel helmet with gold fins and a scowling brow, a blue
/// battle suit and the red Astro-Harness strapped round him, its twin prongs out in front firing astro-force blasts;
/// in flight its thrusters push him along. Signature: he takes out his Mother Box, which pings, pulse after pulse of
/// light, lights blinking.
private func drawOrion(_ c: PixelCanvas, _ p: Pose) {
    layer(c, lean: p.flying ? 4 : 0) { c in
        let steel = C(0x4E586C), steelLight = C(0x8A94A8), steelDark = C(0x2A3040), gold = C(0xE0B030)
        let blue = C(0x2A3E8A), blueDark = C(0x1A2860), red = C(0xB82A22), redDark = C(0x7A1810), metal = C(0x8A8F9C)
        drawSuitLegs(c, p, blue, boot: steelDark, bootRows: 3)
        if p.flying {
            for y in [32, 35] { drawThrust(c, x: 12, y: y, t: p.t + Double(y)) }
        }
        c.oy += p.breathe
        // Harness thrusters on his back.
        c.rect(13, 31, 4, 7, red); c.rect(13, 31, 4, 1, metal); c.rect(13, 37, 4, 1, redDark)
        drawBody(c, Look(arm: blue))
        c.pattern(16, 18, [
            "......SSSSSSSSSSSS......",
            "....SSSSSSSSSSSSSSSS....",
            "...SSlSSSSSSSSSSSSlSS...",
            "..YSSSSSSSSSSSSSSSSSSY..",
            ".YYSSSSSSSSSSSSSSSSSSYY.",
            "YYYSSSSSSSSSSSSSSSSSSYYY",
            ".YYSddddddddddddddddSYY.",
            "..YSS..............SSY..",
            "..SSS..............SSS..",
            "..SSs..............sSS..",
            "..SSs..............sSS..",
            "..SSs..............sSS..",
        ], ["S": steel, "l": steelLight, "d": steelDark, "Y": gold, "s": steelDark])
        c.rect(22, 18, 12, 1, steelLight)
        // The scowl.
        c.rect(21, 27, 4, 1, ink); c.rect(31, 27, 4, 1, ink); c.px(24, 28, ink); c.px(31, 28, ink)
        c.rect(25, 32, 6, 1, clawdShade)
        // Suit and harness straps.
        c.rect(18, 33, 20, 5, blue)
        c.rect(37, 33, 1, 5, blueDark)
        c.pattern(18, 33, [
            "RRRRRRRRRRRRRRRRRRRR",
            "R....R..MM..R......R",
            "R.....R.MM.R.......R",
            "RRRRRRRRRRRRRRRRRRRR",
            "rrrrrrrrrrrrrrrrrrrr",
        ], ["R": red, "r": redDark, "M": gold])
        c.rect(15, 33, 3, 3, blue)

        if let s = p.signature, s > 0.06, s < 0.95, !p.flying {
            // Mother Box on his palm, pinging.
            c.rect(38, 31, 3, 3, blue)
            c.pattern(39, 26, ["BBBBBB", "BLBbLB", "BbBBbB", "BBLBBB", "bbbbbb"],
                      ["B": C(0x5A6A7A), "b": C(0x3A4654), "L": Int(p.t * 8) % 2 == 0 ? C(0x7AF0FF) : C(0x2A8AA0)])
            let k = (s - 0.06) / 0.89
            for r in 0..<3 {
                let f = frac(k * 3 + Double(r) / 3)
                let rr = 2 + f * 11
                let col = C(0x9AF4FF).alpha(0.7 * (1 - f))
                for j in 0..<16 {
                    let a = Double(j) / 16 * 2 * .pi
                    c.px(Int(42 + cos(a) * rr), Int(28 + sin(a) * rr * 0.8), col)
                }
            }
            return
        }
        // The harness prongs, forward of his hands.
        c.oy += p.gunY
        c.rect(38, 33, 3, 3, blue)
        c.rect(39, 32, 6, 1, metal); c.rect(39, 34, 6, 1, metal); c.rect(38, 32, 2, 3, red)
        c.rect(44, 32, 1, 3, steelDark)
        if p.fire != nil || p.ready || p.flying {
            c.glowLine(45, 33.5, 45, 33.5, core: C(0xFFF0E0), glow: C(0xFF8A2A), coreR: 0.6, glowR: 1.8)
        }
    }
}

/// A short sideways thruster flame pointing back (left) from (`x`, `y`).
private func drawThrust(_ c: PixelCanvas, x: Int, y: Int, t: Double) {
    let len = 3 + Int(noise(Int(t * 30)) * 3)
    c.rect(x - len, y, len + 1, 2, C(0xFF8A2A, 0.85))
    c.rect(x - len + 1, y, len - 1, 1, C(0xFFE27A))
}

// MARK: - Animal Man

/// Animal Man: Buddy Baker. Clawd with messy blond hair, the blue suit with the orange "A" roundel, orange boots and
/// gloves, and a battered brown leather jacket thrown on over it. Fights with his fists. Signature: he reaches into the
/// morphogenetic field and borrows an eagle: ghostly red wings spread out of his back and beat, lifting him off his
/// feet, and his eyes glow.
private func drawAnimalMan(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A5AB8), blueDark = C(0x1A3A80), orange = C(0xF08A2A), jacket = C(0x6A4428), jacketDark = C(0x4A2E1A)
    let hair = C(0xE8C860), hairDark = C(0xB8963A)
    let spread = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let flap = sin((p.signature ?? 0) * .pi * 8)
    let rise = spread > 0.6 ? (flap > 0 ? -2 : -1) : 0
    c.oy += rise
    if spread > 0.02 {
        // The borrowed wings, beating behind him.
        for side in [-1.0, 1.0] {
            let bx = 28 + side * 6, by = 30.0
            for f in 0..<4 {
                let deg: Double = 62 - Double(f) * 16 + flap * 16
                let a: Double = (side > 0 ? -deg : -180 + deg) * .pi / 180
                let len: Double = (19 - Double(f) * 3) * spread
                c.glowLine(bx, by, bx + cos(a) * len, by + sin(a) * len,
                           core: C(0xFFC0A0).alpha(0.75 * spread), glow: C(0xFF3A2A).alpha(0.5 * spread), coreR: 0.5, glowR: 1.5)
            }
        }
    }
    drawLegs(c, Look(leg: blue), step: rise < 0 ? -1 : p.step)
    drawBoots(c, orange, step: rise < 0 ? -1 : p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: jacket))
    c.pattern(17, 20, [
        "....H.HHHHH.HH........",
        "...HHHHHHHHHHHHHH.....",
        "..HHHHHHHHHHHhHHHH....",
        "..HHHhHHHHHHHHHHHHHH..",
        "..HHHHHHHhHHHHHHhHHH..",
        "..HHh.HHHH..HHH..hHH..",
        "..HH...hH.....H...HH..",
        "..H................H..",
    ], ["H": hair, "h": hairDark])
    if spread > 0.4 {
        c.rect(22, 29, 2, 3, C(0xFF6A3A)); c.rect(32, 29, 2, 3, C(0xFF6A3A))
        c.px(22, 29, C(0xFFE0C0)); c.px(32, 29, C(0xFFE0C0))
    }
    c.rect(26, 33, 4, 1, clawdShade)
    c.rect(18, 33, 20, 5, blue)
    c.pattern(24, 33, [
        ".OOOOO.",
        "OOOKOOO",
        "OOKOKOO",
        "OOKKKOO",
        ".KOOOK.",
    ], ["O": orange, "K": ink])
    // The jacket, hanging open.
    c.rect(18, 33, 5, 5, jacket); c.rect(33, 33, 5, 5, jacket)
    c.rect(22, 33, 1, 5, jacketDark); c.rect(33, 33, 1, 5, jacketDark)
    c.rect(20, 33, 2, 1, jacketDark); c.rect(34, 33, 2, 1, jacketDark)
    c.rect(18, 37, 20, 1, blueDark)
    c.rect(15, 35, 3, 1, orange)
    if let a = p.melee {
        drawFist(c, angle: a, trail: p.trail, from: (39.5, 34.5), reach: 5, arm: jacket, fist: orange)
    } else {
        c.rect(38, 35, 3, 1, orange)
    }
}

// MARK: - Katana

/// Katana: Tatsu Yamashiro. Clawd with a sleek black bob, the white rising-sun mask across her eyes, a black fighting
/// suit with a red obi and red bracers, and Soultaker, the katana that keeps the souls of those it slays, sheathed at her
/// hip. Signature: she draws Soultaker in one stroke; the blade glows and the trapped souls drift out of it and circle
/// her, wailing, before it drinks them back in and she sheathes it.
private func drawKatana(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E1E26), suitLight = C(0x34343E), red = C(0xC0202A), redDark = C(0x7A1018)
    let hair = C(0x121218), hairLight = C(0x2E2E3C), mask = C(0xF4F2EC), sun = C(0xD0202A)
    let sig = p.signature.flatMap { $0 > 0.05 && $0 < 0.95 ? $0 : nil }
    let drawn = p.melee != nil || sig != nil
    if !drawn { bar(c, 22, 36, 6, 41, C(0x2A1A1A), 1) ; c.px(6, 41, C(0xC8A040)) }   // the scabbard, behind
    else { bar(c, 22, 36, 6, 41, C(0x2A1A1A), 1) }
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, C(0x0E0E14), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: suit))
    c.pattern(16, 20, [
        ".......HHHHHHHHHH.......",
        ".....HHHHHHHHHHHHHH.....",
        "...HHHHHHhHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHH................HHH.",
        ".HHH................HHH.",
        ".HHh................hHH.",
        ".HHH................HHH.",
        "..HH................HH..",
    ], ["H": hair, "h": hairLight])
    // The mask: a white band, the red sun between the eyes, rays out to the edges.
    c.pattern(18, 27, [
        "WRWWWWWWWRRWWWWWWWRW",
        "WWRWWWWWRRRRWWWWWRWW",
        "WWWRKKWRRRRRRWKKRWWW",
        "WWWWKKWWRRRRWWKKWWWW",
        "WWWRKKWWWRRWWWKKRWWW",
    ], ["W": mask, "R": sun, "K": ink])
    c.rect(26, 33, 4, 1, clawdShade)
    c.rect(18, 33, 20, 5, suit)
    c.pattern(18, 33, [
        "......SS....SS......",
        ".......SS..SS.......",
        "........SSSS........",
        "RRRRRRRRRRRRRRRRRRRR",
        "rrrrrrrrrrRRrrrrrrrr",
    ], ["S": suitLight, "R": red, "r": redDark])
    c.rect(15, 33, 3, 1, red)

    if let a = p.melee {
        drawSoultaker(c, angle: a, trail: p.trail, t: p.t, souls: 0)
        c.rect(38, 33, 3, 3, suit); c.rect(38, 33, 1, 3, red)
        return
    }
    if let s = sig {
        var angle = -60.0, trail: [Double] = []
        if s < 0.18 {
            let k = (s - 0.05) / 0.13
            angle = 160 - 220 * (1 - pow(1 - k, 3))
            trail = [angle + 40, angle + 80]
        } else if s > 0.86 {
            let k = (s - 0.86) / 0.09
            angle = -60 + 220 * k
        }
        let souls = s > 0.22 && s < 0.84 ? habitArc((s - 0.22) / 0.62, hold: 0.5) : 0
        drawSoultaker(c, angle: angle, trail: trail, t: p.t, souls: souls)
        c.rect(38, 33, 3, 3, suit); c.rect(38, 33, 1, 3, red)
        return
    }
    // Sheathed: the hilt rides at her hip.
    bar(c, 23, 36, 28, 34, C(0x2A2A30), 0.9)
    c.px(25, 35, C(0xC8A040)); c.px(24, 36, C(0xC8A040))
    c.rect(38, 33, 3, 3, suit); c.rect(38, 33, 1, 3, red)
}

/// Soultaker: a black-wrapped hilt, a gold tsuba and a long curved steel blade with a pale green ghost-light along it,
/// swung from the hand at `angle`. `souls` 0…1: the trapped souls out of the blade, circling.
private func drawSoultaker(_ c: PixelCanvas, angle: Double, trail: [Double], t: Double, souls: Double) {
    for (i, a) in trail.enumerated() {
        let s = along(a, 4), e = along(a, 21)
        c.glowLine(s.x, s.y, e.x, e.y, core: C(0xD8FFE8), glow: C(0x6AFFB0), coreR: 0.4, glowR: 1.5, strength: 0.4 / Double(i + 1))
    }
    let s = along(angle, 4), e = along(angle, 20)
    c.glowLine(s.x, s.y, e.x, e.y, core: C(0, 0), glow: C(0x6AFFB0), coreR: 0.1, glowR: 1.8, strength: 0.35 + 0.5 * souls)
    prop(c, at: Sprite.hand, angle: angle) { s in
        s.rect(15, 20, 5, 1, C(0x1A1A20)); s.px(16, 20, C(0xC0202A)); s.px(18, 20, C(0xC0202A))
        s.rect(20, 19, 1, 3, C(0xC8A040))
        s.rect(21, 20, 13, 1, C(0xC8CED8)); s.rect(21, 21, 12, 1, C(0x8A909C))
        s.rect(34, 19, 4, 1, C(0xC8CED8)); s.rect(33, 20, 4, 1, C(0x8A909C)); s.px(38, 18, C(0xEEF2F8))
    }
    guard souls > 0.02 else { return }
    for i in 0..<4 {
        let a = t * 2.4 + Double(i) * .pi / 2
        let r = 15 * souls
        let x = 30 + cos(a) * r, y = 27 + sin(a) * r * 0.6
        let col = C(0xD8FFE8).alpha(0.75 * souls), eye = C(0x1A3A2A).alpha(0.8 * souls)
        c.pattern(Int(x) - 1, Int(y) - 1, [".W.", "WWW", "KWK", "WWW", "W.W"], ["W": col, "K": eye])
        c.px(Int(x - cos(a + 0.5) * 3), Int(y - sin(a + 0.5) * 2), col.alpha(0.4))
    }
}

// MARK: - Shared helpers

/// Legs in a suit colour (swept back in flight), with boots of `bootRows` rows.
private func drawSuitLegs(_ c: PixelCanvas, _ p: Pose, _ leg: Px, boot: Px? = nil, bootRows: Int = 2) {
    if p.flying {
        let sweep: [(Int, Int)] = [(0, 36), (0, 37), (-1, 38), (-2, 39), (-3, 40)]
        for lx in [19, 23, 31, 35] {
            for (i, s) in sweep.enumerated() {
                let col = boot != nil && i >= sweep.count - bootRows ? boot! : leg
                c.rect(lx + s.0, s.1, 2, 1, col)
            }
        }
        return
    }
    drawLegs(c, Look(leg: leg), step: p.step)
    guard let boot else { return }
    drawBoots(c, boot, step: p.step, rows: bootRows)
}

/// A punch: the arm reaching out from the shoulder `s` at `angle`, a fist on the end; a fast swing smears.
private func drawFist(_ c: PixelCanvas, angle: Double, trail: [Double], from s: (x: Double, y: Double),
                      reach: Double = 6, arm: Px, fist: Px, size: Int = 3) {
    for (i, a) in trail.enumerated() {
        let r = a * .pi / 180
        c.glowLine(s.x + cos(r) * (reach - 2), s.y + sin(r) * (reach - 2), s.x + cos(r) * (reach + 1), s.y + sin(r) * (reach + 1),
                   core: white.alpha(0.35 / Double(i + 1)), glow: white.alpha(0.2 / Double(i + 1)), coreR: 0.8, glowR: 1.8)
    }
    let r = angle * .pi / 180
    let ex = s.x + cos(r) * reach, ey = s.y + sin(r) * reach
    c.glowLine(s.x, s.y, ex, ey, core: arm, glow: C(0, 0), coreR: 1.1, glowR: 1.2)
    let x0 = Int((ex - Double(size) / 2).rounded()), y0 = Int((ey - Double(size) / 2).rounded())
    c.rect(x0, y0, size, size, fist)
}

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from `h` (the hand) along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A cape streaming out behind (to the left) in flight.
private func drawFlyingCape(_ c: PixelCanvas, t: Double, color: Px, edge: Px) {
    for x in 3...20 {
        let k = Double(20 - x) / 17
        let mid = 29 + k * 4 + sin(t * 9 - k * 5) * k * 1.6
        let half = 3 + k * 2
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, color)
        c.px(x, top, edge); c.px(x, bottom, edge)
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`, and
/// leaning forward one pixel every `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, dx: Int = 0, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let feet = 43 + c.oy + c.baseY
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        let shift = dx + (lean > 0 ? Int((Double(feet - y) / Double(lean)).rounded(.down)) : 0)
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4, a = s.buf[i + 3]
            guard a > 0 else { continue }
            c.px(x + shift, y, unpremultiplied(s, i).alpha(alpha))
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

/// A four-point twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int) {
    c.px(x, y, white)
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] as [(Int, Int)] { c.px(x + dx, y + dy, C(0xFFFFFF, 0.6)) }
}

private func unpremultiplied(_ s: PixelCanvas, _ i: Int) -> Px {
    let a = s.buf[i + 3], m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(s.buf[i]) * m)), g: UInt8(min(255, Double(s.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(s.buf[i + 2]) * m)), a: a)
}
