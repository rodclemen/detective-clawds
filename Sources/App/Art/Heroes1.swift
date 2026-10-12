import Foundation

// Heroes: the Justice League. Every one of them is Clawd in costume: the cowl, hair, mask and armour drawn over (and
// around) the blocky body, the way the whole cast is done. Where the hero shows a face, it's Clawd's own orange.

let heroes1: [Companion: Persona] = [
    .superman: Persona(name: "Superman", weapon: .ranged, motion: .fly, shot: .beam(core: C(0xFFF4D0), glow: C(0xFF3A1E)),
                  armoured: true, muzzle: (34, 30), handGun: false, headTop: 21, signature: 3.0, callout: "Up, up and away!",
                  draw: drawSuperman),
    .batman: Persona(name: "Batman", weapon: .melee, motion: .swing, headTop: 19, signature: 2.8, callout: "I'm Batman.",
                  draw: drawBatman),
    .wonderWoman: Persona(name: "Wonder Woman", weapon: .melee, motion: .fly, headTop: 21, signature: 3.2,
                  callout: "For Themyscira!",
                  draw: drawWonderWoman),
    .flash: Persona(name: "The Flash", weapon: .melee, headTop: 22, signature: 2.8, callout: "Fastest man alive!",
                  draw: drawFlash),
    .greenLantern: Persona(name: "Green Lantern", weapon: .magic, motion: .fly,
                  magic: Magic(core: C(0xD8FFD0), glow: C(0x2ADB4A), jagged: false),
                  headTop: 21, signature: 3.2, callout: "In brightest day!",
                  draw: drawGreenLantern),
    .aquaman: Persona(name: "Aquaman", weapon: .melee, headTop: 21, signature: 3.0, callout: "For Atlantis!",
                  draw: drawAquaman),
    .cyborg: Persona(name: "Cyborg", weapon: .ranged, shot: .energy(core: C(0xE8F4FF), glow: C(0x4AA8FF)), armoured: true,
                  muzzle: (46, 34), handGun: false, headTop: 23, signature: 2.8, callout: "Booyah!",
                  draw: drawCyborg),
    .martianManhunter: Persona(name: "Martian Manhunter", weapon: .melee, motion: .fly, headTop: 23, signature: 3.2,
                  draw: drawMartianManhunter),
    .greenArrow: Persona(name: "Green Arrow", weapon: .ranged, shot: .arrow, muzzle: (46, 34), handGun: false, headTop: 19,
                  signature: 3.0, callout: "You have failed this city!",
                  draw: drawGreenArrow),
    .blackCanary: Persona(name: "Black Canary", weapon: .magic, magic: Magic(core: C(0xF4F8FF), glow: C(0x9AD8FF), jagged: false),
                  pivot: canaryMouth, headTop: 21, signature: 2.8,
                  draw: drawBlackCanary),
    .shazam: Persona(name: "Shazam", weapon: .magic, motion: .fly, magic: Magic(core: C(0xFFF8D0), glow: C(0xFFD21E)),
                  headTop: 22, signature: 3.0, callout: "SHAZAM!",
                  draw: drawShazam),
]

// MARK: - Superman

/// Superman: Clawd with the black hair and the curl over his brow, the blue suit with the red-and-yellow S-shield, a
/// yellow belt over red trunks, red boots and the red cape. Heat vision comes from his eyes (they burn red as he fires);
/// bullets bounce off him. In flight he leans into it, one fist forward, cape streaming. Signature: up, up and away: he
/// crouches, springs into the air with a fist raised, hangs there with the cape fluttering and comes back down.
private func drawSuperman(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A5CC8), blueDark = C(0x1C3E8A), red = C(0xD0202A), redDark = C(0x8A1218)
    let yellow = C(0xF2C230), hair = C(0x15151D)
    let sig = p.signature
    let rise: Double = sig.map { (s: Double) -> Double in s < 0.14 ? 0 : habitArc((s - 0.14) / 0.86, hold: 0.45) } ?? 0
    let up = Int((12 * rise).rounded())
    let crouch = sig.map { $0 > 0.03 && $0 < 0.15 } ?? false
    let aloft = up > 3
    if aloft { drawAirWash(c, t: p.t) }
    layer(c, lean: p.flying ? 4 : 0) { c in
        c.oy -= up
        if p.flying {
            drawFlyingCape(c, t: p.t, color: red, edge: redDark)
        } else {
            drawBackCape(c, t: p.t, speed: aloft ? 5 : p.capeSpeed, color: red, edge: redDark)
        }
        if p.flying || aloft {
            drawFlightLegs(c, leg: blue, boot: red, shade: blueDark, bootRows: 3)
        } else {
            drawLegs(c, Look(leg: blue), step: p.step)
            drawBoots(c, red, step: p.step, rows: 3)
        }
        c.oy += p.breathe + (crouch ? 1 : 0)
        drawBody(c, Look(arm: blue, eye: nil), armRight: aloft ? 10 : 0)
        c.pattern(17, 21, [
            "......KKKKKKKKKK......",
            "....KKKKKKKKKKKKKK....",
            "...KKKKKKKKKKKKKKKK...",
            "..KKKKKKKKKKKKKKKKKK..",
            ".KKKKKKKKKKKKKKKKKKKK.",
            ".KKKKKKKKKKKKKKKKKKKK.",
            ".KKK.......KK......KK.",
            ".KK........K........K.",
            "............K.........",
        ], ["K": hair])
        // The eyes, burning red while the heat vision is on.
        if p.fire != nil {
            for x in [22, 32] { c.rect(x, 29, 2, 3, C(0xFF3A1E)); c.rect(x, 30, 2, 1, C(0xFFF4D0)) }
            c.glowLine(33.5, 30.5, 33.5, 30.5, core: C(0xFFF4D0), glow: C(0xFF3A1E), coreR: 0.6, glowR: 2)
        } else {
            c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        }
        // The suit, the S-shield, the belt and trunks.
        c.rect(18, 32, 20, 6, blue)
        c.rect(37, 32, 1, 6, blueDark)
        c.pattern(24, 32, [
            "RRRRRRRRR",
            "RYRRRRRYR",
            ".RRYYYYR.",
            "..RRRRR..",
            "...YYR...",
            "....R....",
        ], ["R": red, "Y": yellow])
        c.rect(18, 37, 20, 1, yellow)
        if !p.flying && !aloft && !seatedPose { c.rect(18, 38, 20, 1, red) }
        c.rect(15, 33, 3, 3, blue)
        if p.flying {
            c.rect(38, 31, 5, 3, blue); c.rect(42, 31, 1, 3, blueDark)       // fist forward
        } else if aloft {
            c.rect(38, 26, 3, 8, blue)                                       // fist up
            c.rect(38, 22, 3, 1, blueDark)
        }
    }
}

// MARK: - Batman

/// Batman: Clawd under the black cowl with the pointed ears and narrow white eyes, his own orange jaw showing, the grey
/// suit with the black bat on a yellow oval, a yellow utility belt, black gloves and boots, and the long black cape with a
/// scalloped hem. He travels on a grapnel line, one hand up on it, cape streaming. He fights with his fists, the
/// gauntlet fins catching the light. Signature: he throws a batarang that whirls out and boomerangs back into his hand.
private func drawBatman(_ c: PixelCanvas, _ p: Pose) {
    let grey = C(0x7A7E8A), greyDark = C(0x555963), black = C(0x1E1E28), blackLight = C(0x3A3A4A)
    let cape = C(0x2E3248), capeEdge = C(0x15172A), yellow = C(0xF0C838), yellowDark = C(0xB8922A)
    let swinging = p.walking
    if swinging {
        drawFlyingCape(c, t: p.t, color: cape, edge: capeEdge)
        // Legs trailing back and down as he swings.
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let kick = (i + p.step) % 2
            for r in 0..<7 { c.rect(lx - r / 2 - kick, 36 + r, 2, 1, r >= 4 ? black : grey) }
        }
    } else {
        drawBackCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge, scallops: true)
        drawLegs(c, Look(leg: grey), step: p.step)
        drawBoots(c, black, step: p.step, rows: 3)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: grey, shade: greyDark, arm: black, eye: nil))
    c.pattern(18, 19, [
        "..K..............K..",
        "..KK............KK..",
        "..KKK..........KKK..",
        ".KKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KLKKKKKKKKKKKKKKKKKK",
        "KLKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKKbbbKKKKKKKKbbbKKK",
        "KKKWWWKKKKKKKKWWWKKK",
        "KKKKWWKKKKKKKKWWKKKK",
        "KKSSSSSSSSSSSSSSSSKK",
        "KSSSSSSSkkkkSSSSSSSK",
    ], ["K": black, "L": blackLight, "b": C(0x0E0E14), "W": white, "S": clawdOrange, "k": clawdShade])
    // The bat on its yellow oval, and the utility belt.
    c.pattern(24, 33, [
        ".YYYYYYY.",
        "YKYKKKYKY",
        "YKKKKKKKY",
        ".YYYKYYY.",
    ], ["Y": yellow, "K": black])
    c.rect(18, 37, 20, 1, yellow)
    for x in [19, 22, 32, 35] { c.rect(x, 37, 2, 1, yellowDark) }
    c.rect(15, 33, 3, 3, black)

    if swinging {
        // Right hand up on the grapnel line at (41, 22).
        bar(c, 39, 33, 41, 23, grey, 1.1)
        c.rect(40, 21, 3, 3, black); c.px(42, 21, blackLight)
        return
    }
    if let a = p.melee {
        drawFinnedPunch(c, angle: a, trail: p.trail)
        return
    }
    // Signature: the batarang whirls out along an ellipse and comes back.
    if let s = p.signature, s > 0.06, s < 0.94 {
        if s < 0.16 {
            c.rect(37, 29, 3, 3, black)                               // wound up behind the head
            drawBatarang(c, x: 38, y: 28, frame: 0)
            return
        }
        let u = min(1, (s - 0.16) / 0.66)
        let th = u * 2 * .pi
        let bx = 54 - 13 * cos(th), by = 29 - 6 * sin(th)
        if u < 1 {
            c.rect(38, 32, 4, 3, black)                               // arm out after the throw
            drawBatarang(c, x: Int(bx.rounded()), y: Int(by.rounded()), frame: Int(u * 14) % 3)
        } else {
            c.rect(38, 32, 3, 3, black)
            drawBatarang(c, x: 41, y: 33, frame: 0)                   // caught
        }
        return
    }
    c.rect(38, 33, 3, 3, black)
    c.px(38, 32, blackLight)
}

/// Batman's punch: grey forearm, black glove with the three gauntlet fins, and a dark smear for a fast swing.
private func drawFinnedPunch(_ c: PixelCanvas, angle: Double, trail: [Double], alpha: Double = 1) {
    for (i, ta) in trail.enumerated() {
        prop(c, at: Sprite.hand, angle: ta, alpha: 0.35 / Double(i + 1)) { s in s.rect(21, 18, 7, 5, C(0x3A3A4A)) }
    }
    prop(c, at: Sprite.hand, angle: angle, alpha: alpha) { s in
        let grey = C(0x7A7E8A), black = C(0x1E1E28), fin = C(0x3A3A4A)
        s.rect(16, 19, 5, 3, grey)
        s.rect(21, 19, 4, 3, black)
        s.rect(25, 18, 3, 5, black)
        s.px(27, 18, fin)
        for x in [21, 23] { s.px(x, 18, black); s.px(x + 1, 17, fin) }
    }
}

/// A batarang centred near (`x`, `y`): `frame` 0 flat, 1 tilted, 2 edge-on, as it spins.
private func drawBatarang(_ c: PixelCanvas, x: Int, y: Int, frame: Int) {
    let k = C(0x1E1E28), hi = C(0x8A8E9A)
    switch frame {
    case 0: c.pattern(x - 3, y - 1, ["K.....K", "KKK.KKK", ".KKHKK."], ["K": k, "H": hi])
    case 1: c.pattern(x - 2, y - 2, ["K....", "KK..K", ".KHKK", ".KKK.", "..K.."], ["K": k, "H": hi])
    default: c.rect(x - 3, y, 7, 1, k); c.px(x, y, hi)
    }
}

// MARK: - Wonder Woman

/// Wonder Woman: Clawd with long black hair under the gold tiara and its red star, the red top with the golden eagle
/// across the chest, the blue star-spangled skirt, red boots and the silver bracelets; a round shield on her left arm
/// and a sword in her right hand when she fights, the golden lasso at her hip when she doesn't. In flight she leans in,
/// fist forward, hair streaming. Signature: the Lasso of Truth: she twirls it glowing over her head and throws the loop.
private func drawWonderWoman(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redDark = C(0x8A1218), blue = C(0x2A3A9A), gold = C(0xF0C030), goldDark = C(0xB8902A)
    let hair = C(0x18161E), hairDark = C(0x2E2A36), silver = C(0xD8DCE4)
    let sig = p.signature
    let twirl = sig.map { $0 > 0.06 && $0 < 0.5 } ?? false
    let thrown: Double? = sig.flatMap { $0 >= 0.5 && $0 < 0.94 ? ($0 - 0.5) / 0.44 : nil }
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            // Hair streaming out behind.
            c.pattern(9, 22, [
                ".......HHHHHH",
                "....HHHHHHHHH",
                "..HHHHhHHHHHH",
                "HHHHHHHHHHHHH",
                "..hHHHHHHHHHH",
                ".....HHHhHHHH",
                "........HHHHH",
            ], ["H": hair, "h": hairDark])
            drawFlightLegs(c, leg: clawdOrange, boot: red, shade: clawdShade, bootRows: 4)
        } else {
            drawLegs(c, Look(), step: p.step)
            drawBoots(c, red, step: p.step, rows: 4)
        }
        c.oy += p.breathe
        drawBody(c, Look(), armRight: twirl ? 8 : 0)
        c.pattern(16, 21, [
            "......HHHHHHHHHHHH......",
            "....HHHHHHHHHHHHHHHH....",
            "...HHHHHHHHHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHHHHHH..",
            "..HHHHHhHHHHHHHHhHHHHH..",
            ".HHHHh............hHHHH.",
            ".HHHh..............hHHH.",
            ".HHH................HHH.",
            ".HHH................HHH.",
            ".HHh................hHH.",
            ".HH..................HH.",
            "HHH..................HHH",
            "HHh..................hHH",
            "HH....................HH",
            "Hh....................hH",
        ], ["H": hair, "h": hairDark])
        // The tiara and its star.
        c.pattern(19, 23, [
            "........YY........",
            ".......YRRY.......",
            ".YYYYYYYRRYYYYYYY.",
            "..yyyyyyyyyyyyyy..",
        ], ["Y": gold, "y": goldDark, "R": C(0xE8202A)])
        // Red top with the golden eagle, belt, blue skirt with stars.
        c.rect(18, 32, 20, 4, red)
        c.rect(37, 32, 1, 4, redDark)
        c.pattern(19, 32, [
            "YY.....YYYY.....YY",
            ".YY...YY..YY...YY.",
            "..YYYYY....YYYYY..",
        ], ["Y": gold])
        c.rect(18, 35, 20, 1, gold)
        if p.flying {
            c.rect(18, 36, 20, 2, blue)
        } else {
            c.rect(18, 36, 20, 2, blue); c.rect(17, 38, 22, 1, blue)
            for x in [20, 26, 32, 37] { c.px(x, 37, white) }
            for x in [23, 29, 35] { c.px(x, 36, white) }
        }
        // Left arm: the bracelet, and the shield when she's armed.
        c.rect(17, 33, 1, 3, silver)
        if p.melee != nil { drawAmazonShield(c, cx: 15, cy: 34) }
        if p.flying {
            c.rect(38, 31, 5, 3, clawdOrange); c.rect(38, 31, 1, 3, silver)
            return
        }
        if let a = p.melee {
            for (i, ta) in p.trail.enumerated() { drawAmazonSword(c, angle: ta, alpha: 0.3 / Double(i + 1)) }
            drawAmazonSword(c, angle: a)
            c.rect(38, 33, 3, 3, clawdOrange); c.rect(38, 33, 1, 3, silver)
            return
        }
        let lasso = C(0xFFD84A), lassoGlow = C(0xFFB01E)
        if twirl {
            // The loop spinning over her head, the rope running down to her raised hand.
            c.rect(38, 25, 1, 3, silver)
            let k = ((sig ?? 0) - 0.06) / 0.44
            let cx = 34.0, cy = 15.0
            bar(c, 39.5, 25.5, cx + 6 * cos(k * 30), cy + 1.5 * sin(k * 30), lasso, 0.5)
            drawLoop(c, cx: cx, cy: cy, rx: 7, ry: 2.5, spin: k * 30, rope: lasso, glow: lassoGlow)
        } else if let u = thrown {
            // Thrown: the loop flies out and down, then she reels it back.
            c.rect(38, 32, 4, 3, clawdOrange); c.rect(38, 32, 1, 3, silver)
            let out = sin(u * .pi)
            let lx = 42 + 20 * out, ly = 30 - 8 * out * (1 - u)
            bar(c, 41.5, 33, lx - 3, ly + 1, lasso, 0.5)
            c.glowLine(41.5, 33, lx - 3, ly + 1, core: lasso.alpha(0), glow: lassoGlow, coreR: 0.1, glowR: 1.4, strength: 0.4)
            drawLoop(c, cx: lx, cy: ly, rx: 3, ry: 4, spin: u * 10, rope: lasso, glow: lassoGlow)
        } else {
            c.rect(38, 33, 3, 3, clawdOrange); c.rect(38, 33, 1, 3, silver)
            // The lasso coiled at her hip.
            c.pattern(36, 35, [".YYY.", "Y...Y", "Y...Y", ".YYY."], ["Y": gold])
        }
    }
}

/// A loop of glowing rope seen at a slant: an ellipse round (`cx`, `cy`), brighter on its near side.
private func drawLoop(_ c: PixelCanvas, cx: Double, cy: Double, rx: Double, ry: Double, spin: Double, rope: Px, glow: Px) {
    c.glowLine(cx - rx, cy, cx + rx, cy, core: rope.alpha(0), glow: glow, coreR: 0.1, glowR: ry + 1.8, strength: 0.25)
    let n = 16
    for i in 0..<n {
        let a0: Double = Double(i) / Double(n) * 2 * .pi, a1: Double = Double(i + 1) / Double(n) * 2 * .pi
        let near = sin(a0 + spin) > 0.5
        bar(c, cx + rx * cos(a0), cy + ry * sin(a0), cx + rx * cos(a1), cy + ry * sin(a1), near ? C(0xFFF4C0) : rope, 0.45)
    }
}

/// Her sword, the grip in the hand: a leather grip, a gold crossguard and a long silver blade.
private func drawAmazonSword(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: Sprite.hand, angle: angle, alpha: alpha) { s in
        let blade = C(0xD8DCE4), edge = C(0xFFFFFF), shade = C(0x8A8F9C), gold = C(0xF0C030)
        s.rect(17, 20, 4, 1, C(0x6A4428))
        s.rect(21, 18, 1, 5, gold)
        s.rect(22, 19, 14, 3, blade)
        s.rect(22, 19, 14, 1, edge)
        s.rect(22, 21, 14, 1, shade)
        s.px(36, 20, blade); s.px(37, 20, edge)
    }
}

/// Her round shield on the left arm: silver with a gold rim and a gold star.
private func drawAmazonShield(_ c: PixelCanvas, cx: Int, cy: Int) {
    c.ellipse(cx, cy, 4, 5, C(0xB8902A))
    c.ellipse(cx, cy, 3, 4, C(0xC8CCD4))
    c.rect(cx - 2, cy - 3, 1, 3, C(0xF0F2F6))
    c.pattern(cx - 1, cy - 1, [".Y.", "YYY", "Y.Y"], ["Y": C(0xF0C030)])
}

// MARK: - The Flash

/// The Flash: Clawd in the red suit and cowl with the gold lightning-bolt wings at his ears, his jaw showing, the white
/// circle with the gold bolt on his chest, a gold belt and gold boots. He runs leaning into it with lightning crackling
/// off behind him, and fights as a blur of fists. Signature: he's gone in a red streak, the lightning hangs in the air
/// where he was, and he zips back in holding a coffee.
private func drawFlash(_ c: PixelCanvas, _ p: Pose) {
    let crackle = C(0xFFF4B0), crackleGlow = C(0xFFB01E)
    if let s = p.signature {
        // 0…0.1 set, 0.1…0.28 gone right, 0.28…0.62 away, 0.62…0.78 back in from the left, then the coffee.
        if s > 0.1 && s < 0.78 {
            let away: Double = s < 0.28 ? (s - 0.1) / 0.18 : s < 0.62 ? 1 : -(1 - (s - 0.62) / 0.16)
            let fade = s < 0.28 ? 1 - (s - 0.1) / 0.18 : s < 0.62 ? 0 : (s - 0.62) / 0.16
            // The streak and the lightning left hanging.
            let i = Int(p.t * 24)
            for k in 0..<2 {
                var prev = (x: 2.0, y: 29.0 + Double(k) * 6)
                for j in 1...6 {
                    let q = (x: 2 + Double(j) * 11, y: 29 + Double(k) * 6 + (noise(i + k * 9 + j) - 0.5) * 5)
                    c.glowLine(prev.x, prev.y, q.x, q.y, core: crackle, glow: crackleGlow.alpha(0.5),
                               coreR: 0.35, glowR: 1, strength: 0.35 + 0.5 * (1 - fade))
                    prev = q
                }
            }
            if fade > 0.02 {
                let dx = Int((away * 40).rounded())
                for g in 1...2 { layer(c, alpha: 0.25 * fade / Double(g), lean: 4, dx: dx - (away > 0 ? 6 : -6) * g) { drawFlashBody($0, p) } }
                layer(c, alpha: fade, lean: 4, dx: dx) { drawFlashBody($0, p) }
            }
            return
        }
        layer(c) { drawFlashBody($0, p, coffee: s >= 0.78) }
        return
    }
    let running = p.walking
    if running {
        // Lightning crackling off behind him.
        let i = Int(p.t * 20)
        for k in 0..<2 {
            var prev = (x: 16.0, y: 30.0 + Double(k) * 6)
            for j in 1...4 {
                let q = (x: 16 - Double(j) * 4, y: 30 + Double(k) * 6 + (noise(i * 3 + k * 7 + j) - 0.5) * 5)
                c.glowLine(prev.x, prev.y, q.x, q.y, core: crackle, glow: crackleGlow, coreR: 0.4, glowR: 1.4,
                           strength: 1 - Double(j) * 0.18)
                prev = q
            }
        }
    }
    layer(c, lean: running ? 5 : 0) { drawFlashBody($0, p) }
}

private func drawFlashBody(_ c: PixelCanvas, _ p: Pose, coffee: Bool = false) {
    let red = C(0xD0242A), redDark = C(0x8A1418), gold = C(0xF8D030), goldDark = C(0xC89A20)
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, gold, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: red, shade: redDark, arm: red, eye: nil), armRight: coffee ? 3 : 0)
    // The cowl's ear wings.
    for (x0, flip) in [(13, false), (38, true)] {
        let rows: [String] = ["Y....", ".YY..", "..YYY", ".YY..", "Y...."]
        c.pattern(x0, 24, flip ? rows.map { String($0.reversed()) } : rows, ["Y": gold])
    }
    c.pattern(18, 22, [
        "....RRRRRRRRRRRR....",
        "..RRRRRRRRRRRRRRRR..",
        ".RRRRRRRRRRRRRRRRRR.",
        "RRRRRRRRRRRRRRRRRRRR",
        "RRRRRRRRRRRRRRRRRRRR",
        "RrRRRRRRRRRRRRRRRRRr",
        "RRRRRRRRRRRRRRRRRRRR",
        "RRRWWWWRRRRRRWWWWRRR",
        "RRRRWKKRRRRRRRWKKRRR",
        "RRRRWKKRRRRRRRWKKRRR",
        "RRSSSSSSSSSSSSSSSSRR",
        "RSSSSSSSSkkkSSSSSSSR",
    ], ["R": red, "r": redDark, "W": C(0xF2EEE0), "K": ink, "S": clawdOrange, "k": clawdShade])
    // The emblem: a white disc with the bolt across it.
    c.ellipse(28, 35, 3, 3, C(0xF4F2EC))
    c.pattern(26, 32, ["...Y.", "..YY.", ".YYYY", "..YY.", ".YY..", ".Y..."], ["Y": gold])
    c.rect(18, 37, 20, 1, gold)
    c.rect(26, 37, 4, 1, goldDark)
    c.rect(15, 33, 3, 3, red)
    if coffee {
        // A takeaway cup from somewhere across town, still steaming.
        c.rect(39, 26, 3, 5, C(0xF4F2EC)); c.rect(39, 27, 3, 1, C(0x8A5A34)); c.rect(38, 26, 5, 1, C(0x3A3A44))
        let wisp = Int(p.t * 4) % 2
        c.px(40 + wisp, 24, C(0xFFFFFF, 0.6)); c.px(41 - wisp, 22, C(0xFFFFFF, 0.4))
        return
    }
    if let a = p.melee {
        // A blur of fists: the real one, ghosts either side and a lightning smear.
        for (i, ta) in p.trail.enumerated() {
            let e = along(ta, 7)
            c.glowLine(Sprite.hand.x, Sprite.hand.y, e.x, e.y, core: C(0xFFF4B0, 0.5 / Double(i + 1)), glow: C(0xFFB01E, 0.5),
                       coreR: 0.5, glowR: 1.8)
        }
        for d in [-28.0, 28.0] {
            let e = along(a + d, 6)
            c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, red.alpha(0.35))
        }
        drawPunch(c, angle: a, trail: [], arm: red, fist: red)
        return
    }
    c.rect(38, 33, 3, 3, red)
}

// MARK: - Green Lantern

/// Green Lantern (Hal Jordan): Clawd with short brown hair and the green domino mask, the green suit with black
/// shoulders, the white circle with the lantern symbol on his chest, white gloves and the ring glowing on his right
/// hand; the steady green beam comes from the ring. In flight he leans in, ring fist forward, a green wake behind him.
/// Signature: the power battery appears beside him; he holds the ring to it and swears the oath, glowing green.
private func drawGreenLantern(_ c: PixelCanvas, _ p: Pose) {
    let sig = p.signature
    let charge = sig.map { habitArc($0, hold: 0.55) } ?? 0
    if charge > 0.05 {
        c.oy += p.breathe
        c.ellipse(28, 31, Int(13 * charge), Int(14 * charge), C(0x2ADB4A, 0.16 * charge))
        drawPowerBattery(c, x: 46, alpha: min(1, charge * 1.5), t: p.t)
        c.oy -= p.breathe
    }
    if p.flying {
        let i = Int(p.t * 16)
        for k in 0..<3 {
            let y = 30 + k * 4, len = 6 + Int(noise(i + k) * 6)
            c.rect(14 - len, y, len, 1, C(0x5AFF6A, 0.35))
        }
    }
    layer(c, lean: p.flying ? 4 : 0) { c in
        let green = C(0x2EB84A), greenDark = C(0x1E7A30), black = C(0x1E1E26), glove = C(0xF2F2F4)
        let hair = C(0x5A3A22), hairDark = C(0x3E2616)
        if p.flying {
            drawFlightLegs(c, leg: green, boot: black, shade: greenDark, bootRows: 3)
        } else {
            drawLegs(c, Look(leg: green), step: p.step)
            drawBoots(c, black, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        let raise = p.flying ? 0 : p.armRaise
        drawBody(c, Look(body: clawdOrange, arm: glove, eye: nil), armRight: raise)
        c.pattern(18, 21, [
            "....HHHHHHHHHHHH....",
            "..HHHHHHHHHHHHHHHH..",
            ".HHHHHHhHHHHHHHHHHH.",
            "HHHHHHHHHHHHHHHHHHHH",
            "HHHhHHHHHHHHHHHHHHHH",
            "HHHHHHHHHHhHHHHHHHHH",
            "HH...H.......H...HHH",
            "H.................HH",
        ], ["H": hair, "h": hairDark])
        // The domino mask, eyes white behind it (glowing green as he charges).
        c.pattern(20, 28, [
            ".GGGG......GGGG.",
            "GGWWGGGGGGGGWWGG",
            ".GWKG......GWKG.",
        ], ["G": green, "W": charge > 0.3 ? C(0xC8FFC8) : white, "K": charge > 0.3 ? C(0x2ADB4A) : ink])
        // Suit: green, black shoulders, the lantern symbol in its white circle.
        c.rect(18, 32, 20, 6, green)
        c.rect(18, 32, 3, 6, black); c.rect(35, 32, 3, 6, black)
        c.rect(18, 37, 20, 1, greenDark)
        c.pattern(25, 32, [
            ".WWWWW.",
            "..WWW..",
            ".W...W.",
            ".W...W.",
            "..WWW..",
            ".WWWWW.",
        ], ["W": white])
        c.rect(15, 33, 3, 3, glove)
        let ringLit = p.zap != nil || p.flying || charge > 0.2 || p.ready
        if p.flying {
            c.rect(38, 31, 5, 3, glove)
            c.glowLine(41.5, 32.5, 41.5, 32.5, core: C(0xD8FFD0), glow: C(0x2ADB4A), coreR: 0.6, glowR: 2.4)
            return
        }
        let hy = 33 - raise - (charge > 0.05 ? 1 : 0)
        if charge > 0.05 { c.rect(38, hy, 4, 3, glove) } else { c.rect(38, hy, 3, 3, glove) }
        c.px(40, hy + 1, C(0x2ADB4A))
        if ringLit {
            let r = 1.6 + (charge > 0.2 ? 2 * charge : 0)
            c.glowLine(40.5, Double(hy) + 1.5, 40.5, Double(hy) + 1.5, core: C(0xD8FFD0), glow: C(0x2ADB4A), coreR: 0.6, glowR: r)
        }
    }
}

/// The lantern-shaped power battery standing on the ground at `x`, fading in with `alpha`.
private func drawPowerBattery(_ c: PixelCanvas, x: Int, alpha: Double, t: Double) {
    let g = C(0x2EB84A).alpha(alpha), d = C(0x1E7A30).alpha(alpha), l = C(0xC8FFC8).alpha(alpha)
    c.pattern(x, 33, [
        "..ddd..",
        ".d...d.",
        "GGGGGGG",
        ".dGGGd.",
        ".GLLLG.",
        ".GLLLG.",
        ".GLLLG.",
        ".dGGGd.",
        "GGGGGGG",
        ".GGGGG.",
        "GGGGGGG",
    ], ["G": g, "d": d, "L": l])
    let flick = 0.8 + 0.2 * sin(t * 20)
    c.glowLine(Double(x) + 3.5, 39, Double(x) + 3.5, 39, core: C(0xF0FFF0, alpha), glow: C(0x2ADB4A, alpha),
               coreR: 1, glowR: 3.5, strength: flick)
}

// MARK: - Aquaman

/// Aquaman: Clawd with wavy blond hair, the orange shirt of gold-edged scales, green gloves and leggings, a gold belt
/// with the "A" buckle, and the golden trident: it stands upright in his hand, and he fights with it. Signature: he
/// raises the trident and calls to the sea, telepathic rings pulsing from his head while a fish leaps past.
private func drawAquaman(_ c: PixelCanvas, _ p: Pose) {
    let shirt = C(0xF08A1E), scale = C(0xB85A12), green = C(0x2E8A3E), greenDark = C(0x1E5A2A)
    let hair = C(0xF2D470), hairDark = C(0xB8963A), gold = C(0xE8B530)
    let sig = p.signature
    let call = sig.map { habitArc($0, hold: 0.7) } ?? 0
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, greenDark, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: green), armRight: call > 0.1 ? 3 : 0)
    c.pattern(17, 22, [
        "......HHHHHHHHHH......",
        "....HHHHhHHHHHHhHH....",
        "...HHhHHHHHHhHHHHHH...",
        "..HHHHHHHHHHHHHHHHHHh.",
        ".HHHHhHH.HHHH.HHhHHHH.",
        ".HHH.....H...H....HHH.",
        ".HH................hH.",
        ".Hh.................h.",
    ], ["H": hair, "h": hairDark])
    // The shirt of scales, the belt and its buckle.
    c.rect(18, 32, 20, 5, shirt)
    for y in 32...35 {
        for x in stride(from: 18 + (y % 2) * 2, to: 38, by: 4) { c.px(x, y, scale) }
    }
    c.rect(37, 32, 1, 5, scale)
    c.rect(18, 37, 20, 1, gold)
    c.pattern(26, 36, [".YY.", "Y..Y"], ["Y": gold])
    c.rect(15, 33, 3, 3, green)

    if call > 0.05 {
        // Telepathic rings pulsing out from his head.
        for k in 0..<3 {
            let f = frac(p.lt * 0.9 + Double(k) / 3)
            let r = 7 + f * 14
            let a = (1 - f) * 0.7 * call
            for i in 0..<28 {
                let th: Double = Double(i) / 28 * 2 * .pi
                c.px(Int((28 + r * cos(th)).rounded()), Int((27 + r * 0.7 * sin(th)).rounded()), C(0x9AE8FF, a))
            }
        }
        // A fish leaping past.
        if let s = sig, s > 0.25, s < 0.8 {
            let u = (s - 0.25) / 0.55
            let fx = 46 + Int((20 * u).rounded()), fy = 40 - Int((22 * sin(u * .pi)).rounded())
            let rows = u < 0.5 ? ["O.OOO.", "OOOOKO", "O.OOO."] : ["O.OOO.", "OOOOOO", "O.OO.."]
            c.pattern(fx - 3, fy - 1, rows, ["O": C(0xFF8A2A), "K": ink])
            if u < 0.15 || u > 0.85 {
                let sx = u < 0.15 ? 46 : 66
                for d in [-2, 0, 2] { c.px(sx + d, 41 - abs(d), C(0x7AC8FF)) }
            }
        }
        drawTrident(c, at: (41.5, 31.5), angle: -90)
        return
    }
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawTrident(c, at: Sprite.hand, angle: ta, alpha: 0.3 / Double(i + 1)) }
        drawTrident(c, at: Sprite.hand, angle: a)
        return
    }
    drawTrident(c, at: (41.5, seatedPose ? 30.5 : 34.5), angle: -90)
}

/// The golden trident, gripped at `at`: a short butt behind the hand, the long shaft and three barbed prongs.
private func drawTrident(_ c: PixelCanvas, at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    prop(c, at: at, angle: angle, alpha: alpha) { s in
        let gold = C(0xE8B530), light = C(0xFFE27A), dark = C(0xA87A1A)
        s.rect(12, 20, 22, 1, gold)
        s.px(12, 20, dark); s.px(19, 20, C(0x2E8A3E)); s.px(21, 20, C(0x2E8A3E))
        s.rect(33, 17, 1, 7, dark)
        s.rect(34, 19, 5, 3, gold); s.rect(34, 20, 6, 1, light)
        s.rect(34, 17, 4, 1, gold); s.px(38, 17, light); s.px(37, 18, gold)
        s.rect(34, 23, 4, 1, gold); s.px(38, 23, light); s.px(37, 22, gold)
    }
}

// MARK: - Cyborg

/// Cyborg: Clawd rebuilt in silver-and-grey armour plates, half his face still his own orange with one dark eye and
/// the other half metal with a glowing red eye; a red light on his chest. His right arm turns into the sonic cannon
/// to fire. Signature: the arm reconfigures into the cannon plate by plate, the red eye sweeps a scan, and the cannon
/// charges up blue before it folds back away.
private func drawCyborg(_ c: PixelCanvas, _ p: Pose) {
    let metal = C(0xC8CCD8), metalDark = C(0x7A808E), deep = C(0x4A505C), red = C(0xFF3030), blue = C(0x4AA8FF)
    drawLegs(c, Look(leg: metal), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, lifted ? 38 : 39, 2, 1, deep); c.rect(lx + 1, 36, 1, 7, metalDark)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: metal, shade: metalDark, arm: metal, eye: nil))
    c.pattern(18, 23, [
        "...MMMMMMMMMMMMMM...",
        ".MMMMMMMMMMMMMMMMMM.",
        "MMMMMMMMMdMMMMMMMMMM",
        "MSSSSSSSSdMMMMMMMMMM",
        "SSSSSSSSSdMMMdddMMMM",
        "SSSSSSSSSdMMdRRRdMMd",
        "SSSSKKSSSdMMdRRRdMMd",
        "SSSSKKSSSdMMMdddMMMd",
        "SSSSKKSSSdMMMMMMMMMd",
        "SSSSSSSSSdddMMMMMMMd",
    ], ["M": metal, "d": deep, "S": clawdOrange, "K": ink, "R": red])
    c.glowLine(32, 29, 32, 29, core: C(0xFFD0D0), glow: red, coreR: 0.5, glowR: 1.8)
    // Chest plates and the red light.
    c.rect(18, 33, 20, 1, deep)
    c.rect(27, 33, 1, 5, deep)
    c.rect(20, 35, 5, 1, metalDark); c.rect(30, 35, 5, 1, metalDark)
    c.glowLine(28.5, 35.5, 28.5, 35.5, core: C(0xFFD0D0), glow: red, coreR: 0.6, glowR: 1.8)
    c.rect(18, 37, 20, 1, deep)
    c.rect(15, 33, 3, 3, metal); c.rect(15, 34, 3, 1, deep)

    // How far the cannon is out (0…8), and how charged.
    var cannon = p.fire != nil || p.ready || p.cheering || p.gunY != 0 ? 8 : 0
    var orb = 0.0
    if let s = p.signature {
        cannon = s < 0.3 ? Int((8 * s / 0.3).rounded()) : s < 0.82 ? 8 : Int((8 * (1 - (s - 0.82) / 0.18)).rounded())
        if s > 0.3 && s < 0.82 { orb = (s - 0.3) / 0.52 }
        if s > 0.1 && s < 0.5 {
            // The red eye's scan, sweeping across in front of him.
            let k = (s - 0.1) / 0.4
            let y = 22 + 18 * (0.5 - 0.5 * cos(k * 2 * .pi))
            c.glowLine(33, 29.5, 60, y, core: C(0xFF6060, 0.5), glow: C(0xFF3030, 0.2), coreR: 0.3, glowR: 0.9)
        }
    }
    c.oy += p.gunY
    if cannon > 0 {
        c.rect(38, 32, cannon, 4, metal)
        c.rect(38, 35, cannon, 1, metalDark)
        for x in stride(from: 40, to: 38 + cannon - 1, by: 3) { c.rect(x, 32, 1, 4, deep) }
        if cannon >= 8 {
            c.rect(45, 31, 1, 6, deep)
            c.glowLine(46, 33.5, 46, 33.5, core: C(0xE8F4FF), glow: blue, coreR: 0.5, glowR: 1.4)
        }
        if orb > 0 {
            let f = 0.85 + 0.15 * sin(p.t * 40)
            c.glowLine(47, 33.5, 47, 33.5, core: C(0xE8F4FF), glow: blue, coreR: 0.5 + 1.2 * orb, glowR: 1.5 + 3 * orb, strength: f)
            let i = Int(p.t * 30)
            for k in 0..<3 {
                let a = noise(i + k * 5) * 2 * .pi, r = 4 + noise(i * 3 + k) * 3
                c.px(Int(47 + cos(a) * r), Int(33.5 + sin(a) * r), C(0x9AD8FF))
            }
        }
    } else {
        c.rect(38, 33, 3, 3, metal); c.rect(38, 34, 3, 1, deep)
    }
}

// MARK: - Martian Manhunter

/// Martian Manhunter: a green Clawd with the tall bald dome, heavy brow and red eyes, the red X straps crossing his
/// chest, a blue belt and boots and the blue cape with its high collar. In flight he leans in, cape streaming. He fights
/// with his fists. Signature: he phases out, fading to a ghost but for his red eyes, then comes back with a Chocos
/// cookie and eats it in three bites.
private func drawMartianManhunter(_ c: PixelCanvas, _ p: Pose) {
    let sig = p.signature
    let phase = sig.map { $0 < 0.55 ? habitArc($0 / 0.55, hold: 0.4) : 0 } ?? 0
    let cookie: Double? = sig.flatMap { $0 >= 0.58 && $0 < 0.98 ? ($0 - 0.58) / 0.4 : nil }
    if phase > 0.05 {
        layer(c, alpha: 0.2 * phase, dx: -Int((3 * phase).rounded())) { drawManhunterBody($0, p, cookie: nil) }
        layer(c, alpha: 1 - 0.75 * phase) { drawManhunterBody($0, p, cookie: nil) }
        // The eyes stay lit.
        c.oy += p.breathe
        for x in [22, 32] { c.rect(x, 29, 2, 2, C(0xFF3A2A)) }
        c.glowLine(23, 30, 23, 30, core: C(0xFFC0B0), glow: C(0xFF2A1A, 0.6), coreR: 0.4, glowR: 1.6, strength: phase)
        c.glowLine(33, 30, 33, 30, core: C(0xFFC0B0), glow: C(0xFF2A1A, 0.6), coreR: 0.4, glowR: 1.6, strength: phase)
        return
    }
    layer(c, lean: p.flying ? 4 : 0) { drawManhunterBody($0, p, cookie: cookie) }
}

private func drawManhunterBody(_ c: PixelCanvas, _ p: Pose, cookie: Double?) {
    let green = C(0x3AA04A), greenDark = C(0x2A7838), brow = C(0x1E5A28), red = C(0xD0242A), redDark = C(0x8A1418)
    let blue = C(0x2A3A9A), blueDark = C(0x1C2868)
    if p.flying {
        drawFlyingCape(c, t: p.t, color: blue, edge: blueDark)
        drawFlightLegs(c, leg: green, boot: blue, shade: greenDark, bootRows: 3)
    } else {
        drawBackCape(c, t: p.t, speed: p.capeSpeed, color: blue, edge: blueDark)
        drawLegs(c, Look(leg: green), step: p.step)
        drawBoots(c, blue, step: p.step, rows: 3)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil), armRight: cookie != nil ? 3 : 0)
    // The high collar, the dome and the brow.
    c.pattern(13, 23, [
        "B..........................B",
        "BB........................BB",
        "BBB......................BBB",
        "BBBB....................BBBB",
        ".BBBB..................BBBB.",
    ], ["B": blue])
    c.pattern(19, 22, [
        "....GGGGGGGGGG....",
        "..GGGGGGGGGGGGGG..",
        ".GGGGdGGGGGGdGGGG.",
        "GGGGGGGGGGGGGGGGGG",
    ], ["G": green, "d": greenDark])
    c.pattern(20, 27, [
        "bbbbbbb..bbbbbbb",
        ".bbbbb....bbbbb.",
        "..RR........RR..",
        "..RR........RR..",
    ], ["b": brow, "R": C(0xE8302A)])
    c.rect(26, 31, 4, 1, greenDark)
    // The red X across his chest, the belt.
    c.rect(18, 32, 20, 5, C(0x2E8A3E))
    c.rect(18, 32, 20, 1, greenDark)
    bar(c, 21.5, 33, 34.5, 36.8, red, 0.55)
    bar(c, 21.5, 36.8, 34.5, 33, red, 0.55)
    c.rect(27, 34, 2, 2, redDark)
    c.rect(18, 37, 20, 1, blue)
    if !p.flying && !seatedPose { c.rect(18, 38, 20, 1, blue) }
    c.rect(15, 33, 3, 3, green)
    if p.flying {
        c.rect(38, 31, 5, 3, green); c.rect(42, 31, 1, 3, greenDark)
        return
    }
    if let k = cookie {
        // A Chocos: brought up to his mouth, eaten in three bites, crumbs falling.
        c.rect(38, 30, 3, 3, green)
        let bites = min(4, Int(k * 5))
        if bites < 4 {
            let rows: [String] = [".KKKK.", "KKKKKK", "WWWWWW", "KKKKKK", ".KKKK."]
            c.pattern(33 + bites, 27, rows.map { String($0.dropFirst(bites)) }, ["K": C(0x3A2216), "W": C(0xF2EEE0)])
        }
        if bites > 0 {
            let f = frac(k * 5)
            c.px(33, 32 + Int(f * 9), C(0x3A2216)); c.px(35, 33 + Int(f * 7), C(0x3A2216))
        }
        return
    }
    if let a = p.melee {
        drawPunch(c, angle: a, trail: p.trail, arm: green, fist: green, reach: 8, size: 4)
        return
    }
    c.rect(38, 33, 3, 3, green)
}

// MARK: - Green Arrow

/// Green Arrow: Clawd in the pointed green hood (its tip hanging down behind), a dark green domino mask and a blond
/// goatee, the green tunic with a brown quiver strap and belt, dark green leggings and brown boots, and the black
/// recurve bow; green-fletched arrows over his shoulder. Signature: he picks the boxing-glove arrow, draws, and lets it
/// fly.
private func drawGreenArrow(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3E8A2E), greenDark = C(0x2A5E1E), legs = C(0x24361E), brown = C(0x7A4A2A), brownDark = C(0x5A3420)
    let blond = C(0xE8C860), fletch = C(0x6ACF4A)
    let sig = p.signature
    let pulled = sig.map { $0 > 0.06 && $0 < 0.3 ? ($0 - 0.06) / 0.24 : 0 } ?? 0
    c.oy += p.breathe
    c.pattern(12, 19, [
        "G.G.....",
        "GwGw....",
        ".wGwG...",
        "..QQQQ..",
        "..QQQQ..",
        "...QQQq.",
        "...QQQQ.",
        "....QQQQ",
        "....QQQQ",
        ".....QQq",
        ".....QQQ",
    ], ["G": fletch, "w": C(0xE8E0D0), "Q": brown, "q": brownDark])
    if pulled > 0 {
        let y = 19 - Int((pulled * 6).rounded())
        c.rect(14, y, 1, 6, C(0x8A6A3A)); c.rect(13, y - 2, 3, 2, C(0xD02A2A)); c.px(13, y + 5, fletch); c.px(15, y + 5, fletch)
    }
    c.oy -= p.breathe
    drawLegs(c, Look(leg: legs), step: p.step)
    drawBoots(c, brown, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil))
    c.pattern(13, 19, [
        "...........HHHHHHHHHH....",
        ".........HHHHHHHHHHHHHH..",
        ".......HHHHHHHHHHHHHHHHH.",
        "....HHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHhhhhhhhhhHHHHH",
        "..HHHHHHHh.........hHHHH.",
        ".....HHHh...........hHHH.",
        ".....HHH.............HHH.",
        ".....HHH.............HHH.",
        ".....HHh.............hHH.",
        ".....HH...............HH.",
        ".....HH...............HH.",
        ".....HH...............HH.",
    ], ["H": green, "h": greenDark])
    // The face inside the hood: the mask, the goatee.
    c.rect(20, 24, 16, 8, clawdOrange)
    c.pattern(20, 28, [
        ".MMMM......MMMM.",
        "MMWWMMMMMMMMWWMM",
        ".MWKM......MWKM.",
    ], ["M": C(0x1E3A18), "W": white, "K": ink])
    c.rect(25, 31, 6, 1, blond); c.rect(25, 32, 1, 1, blond); c.rect(30, 32, 1, 1, blond); c.rect(27, 32, 2, 2, blond)
    // Tunic: the quiver strap across the chest, the belt.
    for i in 0..<5 { c.rect(21 + i * 3, 37 - i, 3, 1, brown) }
    c.rect(18, 37, 20, 1, brownDark)
    c.rect(15, 33, 3, 3, green)

    // The bow, an arrow on the string when he's shooting, aiming, or about to let the glove go.
    let drawing = sig.map { $0 > 0.3 && $0 < 0.72 } ?? false
    var pull = 0
    if drawing { pull = Int((4 * min(1, ((sig ?? 0) - 0.3) / 0.2)).rounded()) }
    let firing = p.fire.map { frac($0.t / shotPeriod) < 0.45 } ?? false
    if let f = p.fire, frac(f.t / shotPeriod) > 0.6 { pull = Int(((frac(f.t / shotPeriod) - 0.6) / 0.4 * 3).rounded()) }
    let raise = drawing ? -1 : seatedPose ? -3 : 0
    c.oy += p.gunY + raise
    drawBow(c, pull: pull, limb: C(0x1E2218), grip: brown)
    let shaft = C(0x8A6A3A), tip = C(0xC8CCD4)
    if drawing {
        let tail = 41 - pull
        c.rect(tail, 34, 47 - tail, 1, shaft)
        c.rect(47, 33, 3, 3, C(0xD02A2A)); c.px(49, 33, C(0xFF6A5A))
        c.px(tail, 33, fletch); c.px(tail, 35, fletch)
    } else if p.ready || (p.fire != nil && !firing) {
        let tail = 41 - pull
        c.rect(tail, 34, 47 - tail, 1, shaft)
        c.px(47, 34, tip); c.px(48, 34, C(0xE8ECF4))
        c.px(tail, 33, fletch); c.px(tail, 35, fletch)
    }
    if let s = sig, s >= 0.72 {
        // Loosed: the glove flies off to the right.
        let x = 47 + Int(((s - 0.72) / 0.28 * 28).rounded())
        c.rect(x - 7, 34, 7, 1, shaft)
        c.rect(x, 33, 3, 3, C(0xD02A2A)); c.px(x + 2, 33, C(0xFF6A5A))
        c.px(x - 7, 33, fletch); c.px(x - 7, 35, fletch)
    }
    c.rect(38 - pull, 33, 3, 3, green)
}

/// A recurve bow gripped at the hand; `pull` draws the string back that many pixels.
private func drawBow(_ c: PixelCanvas, pull: Int, limb: Px, grip: Px) {
    let string = C(0xE0E0E8)
    for y in 25...43 {
        let d = abs(y - 34)
        let x = d <= 2 ? 44 : d <= 5 ? 43 : d <= 7 ? 42 : 41
        c.px(x, y, d <= 1 ? grip : limb)
        if d == 9 { c.px(x + 1, y, limb) }
    }
    for y in 26...42 {
        let d = Double(abs(y - 34)) / 8
        c.px(41 - Int((Double(pull) * (1 - d)).rounded()), y, string)
    }
}

// MARK: - Black Canary

private let canaryMouth = (x: 38.5, y: 33.0)

/// Black Canary: Clawd with long, wild blonde hair, a cropped black leather jacket over a black bodysuit, a choker,
/// fishnet stockings and black boots. Her weapon is the Canary Cry, a sonic scream from her mouth (it opens wide as
/// she lets go). Signature: the full cry: she throws her head back, her hair whips and the sound rings out in waves,
/// shaking her where she stands.
private func drawBlackCanary(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x34343F), jacketLight = C(0x56566A), suit = C(0x16161B), hair = C(0xF4DC78), hairDark = C(0xC8A848)
    let sig = p.signature
    let cry = sig.map { habitArc($0, hold: 0.65) } ?? 0
    let shaking = cry > 0.5
    let shake = shaking ? (Int(p.t * 30) % 2 == 0 ? 1 : -1) : 0
    c.ox += shake
    drawLegs(c, Look(leg: clawdOrange), step: p.step)
    // Fishnets.
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            for y in 38...(lifted ? 39 : 40) { c.px(lx + y % 2, y, C(0x3A2A2A)) }
        }
    }
    drawBoots(c, suit, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(body: clawdOrange, arm: jacket, eye: nil))
    // Hair: blown back when she screams.
    let back = cry > 0.3 ? 2 : 0
    c.pattern(16 - back, 21, [
        ".....HHHHHHHHHHHHH......",
        "...HHHHHHHHHHHHHHHHH....",
        "..HHHhHHHHHHHHHHHHHHH...",
        ".HHHHHHHHHHHHhHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        "HHHHhH.H...H.....hHHHHH.",
        "HHHHh..............hHHH.",
        "HHHH................HHH.",
        "HHHh................hHH.",
        "HHH..................HH.",
        "HHHH.................HHH",
        "HHHh..................HH",
        ".HHH..................hH",
        "HHh....................H",
        "Hh......................",
    ], ["H": hair, "h": hairDark])
    if back > 0 {
        for k in 0..<4 { c.rect(10 - k, 23 + k * 3, 4, 2, k % 2 == 0 ? hair : hairDark) }
    }
    // Eyes squeezed shut and mouth wide open in the cry; open a little in the fight.
    let open = cry > 0.2 ? 2 : p.zap != nil ? 1 : 0
    if cry > 0.2 {
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    if open > 0 { c.rect(27, 32 - (open - 1), 3, open + 1, C(0x5A1A1A)) }
    // Choker, jacket, bodysuit.
    c.rect(25, 32, 6, 1, suit); c.px(27, 33, C(0xC8CCD4))
    c.rect(18, 33, 20, 5, jacket)
    c.rect(37, 33, 1, 5, suit)
    c.pattern(24, 33, ["LSSSSSSL", ".LSSSSL.", "..LSSL..", "...LL..."], ["L": jacketLight, "S": suit])
    c.rect(19, 35, 2, 1, C(0xA8ACB8)); c.rect(35, 35, 2, 1, C(0xA8ACB8))   // zips
    c.rect(18, 37, 20, 1, suit)
    // Long hair falling past her shoulders (swept back behind her in the cry).
    c.pattern(13 - back, 26, ["..HHH", ".HHHH", "HHHHh", "HHHHH", "HHHHh", ".HHHH", "HHHHh", "HHHH.", "HHHh.", "HHH..", "Hh...", "H...."],
              ["H": hair, "h": hairDark])
    if back == 0 { c.pattern(38, 26, ["HH..", "HHH.", "hHHH", "HHHH", "hHH.", "HH.."], ["H": hair, "h": hairDark]) }
    c.rect(15, 33, 3, 3, jacket); c.rect(38, 33, 3, 3, jacket)
    c.ox -= shake
    // The sound: rings rolling out from her mouth.
    if cry > 0.2 {
        for k in 0..<4 {
            let f = frac(p.t * 1.6 + Double(k) / 4)
            let r = 10 + f * 30
            drawSoundArc(c, cx: 29, cy: 32, r: r, alpha: (1 - f) * cry)
        }
    } else if p.zap == false {
        drawSoundArc(c, cx: 29, cy: 32, r: 11 + Double(Int(p.t * 8) % 3), alpha: 0.6)
    }
}

/// A ")" of sound centred on (`cx`, `cy`), `r` pixels out to the right.
private func drawSoundArc(_ c: PixelCanvas, cx: Double, cy: Double, r: Double, alpha: Double) {
    let n = Int(r * 1.4)
    for i in 0...n {
        let a: Double = (Double(i) / Double(n) - 0.5) * 1.6
        let x = cx + r * cos(a), y = cy + r * 0.8 * sin(a)
        guard x > 38 else { continue }
        c.px(Int(x.rounded()), Int(y.rounded()), C(0xD8F0FF, alpha * 0.9))
    }
}

// MARK: - Shazam

/// Shazam: Clawd with slicked black hair, the red suit with the gold lightning bolt down the chest, a gold sash, gold
/// cuffs and boots, and the short white cape with its gold trim. Lightning comes from his hand. In flight he leans in,
/// fist forward, cape streaming. Signature: he shouts the word, the lightning comes down out of the sky onto him in a
/// white flash, and he's left crackling, fists on his hips.
private func drawShazam(_ c: PixelCanvas, _ p: Pose) {
    let sig = p.signature
    let struck: Double = sig.map { (s: Double) -> Double in s > 0.3 && s < 0.55 ? 1 - (s - 0.3) / 0.25 : 0 } ?? 0
    let after = sig.map { $0 >= 0.55 && $0 < 0.97 } ?? false
    layer(c, lean: p.flying ? 4 : 0, flash: struck) { c in drawShazamBody(c, p, armsUp: sig.map { $0 > 0.06 && $0 < 0.4 } ?? false, hips: after) }
    if struck > 0.1 {
        // The bolt from the sky.
        c.oy += p.breathe
        let i = Int(p.t * 24)
        var prev = (x: 32.0 + (noise(i) - 0.5) * 8, y: -2.0)
        for k in 1...4 {
            let next = (x: k == 4 ? 28.0 : 28 + (noise(i + k) - 0.5) * 10, y: -2 + Double(k) * 6)
            c.glowLine(prev.x, prev.y, next.x, next.y, core: C(0xFFFFF0), glow: C(0xFFD21E), coreR: 0.7, glowR: 2.4)
            prev = next
        }
        drawSparks(c, x: 28, y: 22, t: p.t, size: 4)
        c.oy -= p.breathe
    }
    if after, Int(p.t * 12) % 3 != 0 {
        // Still crackling.
        c.oy += p.breathe
        let i = Int(p.t * 18)
        for k in 0..<2 {
            let x = 18 + noise(i + k * 7) * 20, y = 24 + noise(i * 3 + k) * 12
            c.glowLine(x, y, x + 2, y + 2, core: C(0xFFF8D0), glow: C(0xFFD21E), coreR: 0.4, glowR: 1.2)
        }
        c.oy -= p.breathe
    }
}

private func drawShazamBody(_ c: PixelCanvas, _ p: Pose, armsUp: Bool, hips: Bool) {
    let red = C(0xD0242A), redDark = C(0x8A1418), gold = C(0xF8D030), goldDark = C(0xC89A20)
    let cape = C(0xF2F2EE), capeEdge = C(0xD8B040), hair = C(0x16161E)
    if p.flying {
        drawFlyingCape(c, t: p.t, color: cape, edge: capeEdge)
        drawFlightLegs(c, leg: red, boot: gold, shade: redDark, bootRows: 3)
    } else {
        drawBackCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeEdge, hem: 39, trim: capeEdge)
        drawLegs(c, Look(leg: red), step: p.step)
        drawBoots(c, gold, step: p.step, rows: 3)
    }
    c.oy += p.breathe
    let raise = p.flying ? 0 : armsUp ? 9 : p.armRaise
    drawBody(c, Look(body: clawdOrange, arm: red), armLeft: armsUp ? 9 : 0, armRight: raise)
    c.pattern(18, 21, [
        "....KKKKKKKKKKKK....",
        "..KKKKKKKKKKKKKKKK..",
        ".KKKKKKKKKKKKKKKKKK.",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKK....KKKKK.....KKK",
        "KK......KKK.......KK",
        "K..................K",
    ], ["K": hair])
    // The suit and the bolt, the sash, the cuffs.
    c.rect(18, 32, 20, 6, red)
    c.rect(37, 32, 1, 6, redDark)
    c.pattern(24, 32, [
        "....YYY",
        "...YYY.",
        "..YYYYY",
        ".....Y.",
        "....Y..",
    ], ["Y": gold])
    c.rect(18, 37, 20, 1, gold); c.rect(30, 37, 3, 1, goldDark)
    let ly = armsUp ? 24 : 33
    c.rect(17, ly, 1, 3, gold)
    if armsUp { c.rect(15, 27, 3, 6, red) }
    if p.flying {
        c.rect(38, 31, 5, 3, red); c.rect(38, 31, 1, 3, gold)
        return
    }
    if hips {
        // Fists on his hips.
        c.rect(15, 33, 3, 3, C(0, 0)); c.rect(16, 34, 3, 3, red); c.rect(37, 34, 3, 3, red)
        return
    }
    let ry = 33 - raise
    if armsUp { c.rect(38, 27, 3, 6, red) }
    c.rect(38, ry, 1, 3, gold)
}

// MARK: - Shared helpers

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A cape hanging down the back, seen from the side: it shows past the shoulder blade and between the back legs, so
/// the legs still read in front of it. Its hem sways at `speed`, ends on row `hem` (with an optional `trim` colour
/// along it) and, for Batman, is cut into points.
private func drawBackCape(_ c: PixelCanvas, t: Double, speed: Double, color: Px, edge: Px, hem: Int = 43,
                          trim: Px? = nil, scallops: Bool = false) {
    let last = min(hem, 43 - c.oy)
    guard last >= 27 else { return }
    for y in 27...last {
        let k = Double(y - 27) / Double(max(1, hem - 27))
        let sway = sin(t * speed + k * 2.2) * k * 1.6
        let l = Int((15.5 - k * 3.5 + sway).rounded())
        let r = 24 + Int((k * 2).rounded())
        if scallops && y >= last - 1 {
            // The points: one every three pixels, cut deeper on the last row.
            for x in l...r {
                let m = (x - l) % 3
                if y == last && m != 1 { continue }
                if y == last - 1 && m == 0 && x != l { continue }
                c.px(x, y, x == l ? edge : color)
            }
            continue
        }
        c.rect(l, y, r - l + 1, 1, y == last ? (trim ?? color) : color)
        c.px(l, y, edge)
    }
}

/// Legs held together for flight, `bootRows` of boot at the bottom (lean the sprite with `layer` so they trail).
private func drawFlightLegs(_ c: PixelCanvas, leg: Px, boot: Px, shade: Px, bootRows: Int) {
    for lx in [21, 31] {
        c.rect(lx, 36, 4, 6, leg)
        c.rect(lx + 3, 36, 1, 6 - bootRows, shade)
        c.rect(lx, 42 - bootRows, 4, bootRows, boot)
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

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
private func bar(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from the hand along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// A punch: the arm thrown out along `angle`, a fist on the end and faint fists where a fast swing just was.
private func drawPunch(_ c: PixelCanvas, angle: Double, trail: [Double], arm: Px, fist: Px, reach: Double = 7, size: Int = 3) {
    let h = Sprite.hand
    for (i, a) in trail.enumerated() {
        let e = along(a, reach)
        c.rect(Int(e.x.rounded()) - size / 2, Int(e.y.rounded()) - size / 2, size, size, fist.alpha(0.35 / Double(i + 1)))
    }
    let e = along(angle, reach)
    bar(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - size / 2, Int(e.y.rounded()) - size / 2, size, size, fist)
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`,
/// leaning forward one pixel every `lean` rows above the feet (0: upright), and washed toward white by `flash`.
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, dx: Int = 0, flash: Double = 0,
                   _ art: (PixelCanvas) -> Void) {
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
            var col = unpremultiplied(s, i)
            if flash > 0 {
                let f = min(1, flash)
                col.r = UInt8(Double(col.r) + (255 - Double(col.r)) * f)
                col.g = UInt8(Double(col.g) + (255 - Double(col.g)) * f)
                col.b = UInt8(Double(col.b) + (230 - min(230, Double(col.b))) * f)
            }
            c.px(x + shift, y, col.alpha(alpha))
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
