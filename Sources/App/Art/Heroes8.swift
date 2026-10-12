import Foundation

// Heroes: the Justice League International and friends. Clawd in costume, classic comic colours: masks, helmets,
// goggles and armour over the blocky body; where a face shows, it's Clawd's own orange. Two of them stretch, one
// shrinks, one is a whirlwind and one has no face at all.

let heroes8: [Companion: Persona] = [
    .blueBeetle: Persona(name: "Blue Beetle", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xE8F4FF), glow: C(0x2A8AFF)),
                  armoured: true, muzzle: (45, 34), handGun: false, headTop: 20, signature: 2.8, callout: "Scarab, not now!",
                  draw: drawBlueBeetle),
    .boosterGold: Persona(name: "Booster Gold", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xFFF8D0), glow: C(0xFFD21E)),
                  muzzle: (42, 34), handGun: false, headTop: 21, signature: 3.0, callout: "Booster Gold, at your service!",
                  draw: drawBoosterGold),
    .theAtom: Persona(name: "The Atom", weapon: .melee, headTop: 21, signature: 3.0, callout: "Size isn't everything.",
                  draw: drawTheAtom),
    .firestorm: Persona(name: "Firestorm", weapon: .ranged, motion: .fly, shot: .fire, muzzle: (43, 34), handGun: false,
                  headTop: 16, signature: 3.0, callout: "We are Firestorm!",
                  draw: drawFirestorm),
    .plasticMan: Persona(name: "Plastic Man", weapon: .melee, headTop: 22, signature: 2.8, callout: "Relax, I'm flexible.",
                  draw: drawPlasticMan),
    .elongatedMan: Persona(name: "Elongated Man", weapon: .melee, headTop: 22, signature: 3.0,
                  callout: "My nose is twitching. Something's up.",
                  draw: drawElongatedMan),
    .vixen: Persona(name: "Vixen", weapon: .melee, headTop: 19, signature: 2.8, callout: "Cunning of the fox!",
                  draw: drawVixen),
    .blackLightning: Persona(name: "Black Lightning", weapon: .magic, magic: Magic(core: C(0xF4F8FF), glow: C(0x7FB2FF)),
                  headTop: 16, signature: 2.8, callout: "Get lit.",
                  draw: drawBlackLightning),
    .theQuestion: Persona(name: "The Question", weapon: .melee, headTop: 19, signature: 2.8, callout: "Everything is connected.",
                  draw: drawTheQuestion),
    .metamorpho: Persona(name: "Metamorpho", weapon: .melee, headTop: 25, signature: 3.0, callout: "Element Man, coming through!",
                  draw: drawMetamorpho),
    .redTornado: Persona(name: "Red Tornado", weapon: .magic, motion: .fly,
                  magic: Magic(core: C(0xF4FAFF), glow: C(0xA8C4DC), jagged: false), armoured: true, headTop: 21,
                  signature: 3.0, callout: "I am learning what it means to be human.",
                  draw: drawRedTornado),
    .captainAtom: Persona(name: "Captain Atom", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xFFFFFF), glow: C(0x9AC8FF)),
                  armoured: true, muzzle: (42, 34), handGun: false, headTop: 22, signature: 3.0,
                  callout: "Captain Atom, reporting for duty.",
                  draw: drawCaptainAtom),
]

// MARK: - Blue Beetle

/// Blue Beetle (Jaime Reyes): Clawd sealed in the scarab armour, a blue-and-black helmet with a raised crest and two
/// big pale lenses, black plating over a blue body, and the scarab itself on his back. His arm reshapes into a plasma
/// cannon to shoot, and in flight the scarab's wings come out and buzz. Signature: the wings unfold from the scarab,
/// buzz into a blur, and fold away again.
private func drawBlueBeetle(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x1E5AC8), blueDark = C(0x163E8E), light = C(0x6AA6F4), black = C(0x15182A), lens = C(0xC8F4FF)
    let spread: Double = p.flying ? 1 : (p.signature.map { habitArc($0, hold: 0.55) } ?? 0)
    let buzz = p.flying || spread > 0.85
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            flyingLegs(c, leg: blue, boot: black, shade: blueDark)
        } else {
            drawLegs(c, Look(leg: blue), step: p.step)
            drawBoots(c, black, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        beetleWings(c, t: p.t, spread: spread, buzz: buzz)
        // The scarab on his back.
        c.pattern(12, 25, [
            "...KKK.",
            "..KBBBK",
            ".KBLBBK",
            "KBLBBBK",
            "KBBBBBK",
            "KBBKBBK",
            "KBBKBBK",
            ".KBKBBK",
            "..KKKK.",
        ], ["K": black, "B": blue, "L": light])
        drawBody(c, Look(body: blue, shade: blueDark, arm: black, eye: nil))
        let flash = spread > 0.85 && Int(p.t * 10) % 2 == 0
        c.pattern(17, 20, [
            "......KKKKKKKKKK......",
            "....KKBBBBLLBBBBKK....",
            "...KBBBBBBLLBBBBBBK...",
            "..KBBBBBBBLLBBBBBBBk..",
            "..KBBBBBBBLLBBBBBBBk..",
            ".KBBBBBBBBLLBBBBBBBBk.",
            ".KBBBBBBBBLLBBBBBBBBk.",
            ".KBKKKKKBBLLBBKKKKKBk.",
            ".KKEEEEEKBBBBKEEEEEKk.",
            ".KKEeEEEEKBBKEeEEEEKk.",
            ".KBKEEEEEKBBKEEEEEKBk.",
            ".KBBKKKKKBBBBKKKKKBBk.",
            ".KBBBBBBBKKKKBBBBBBBk.",
            "..KKBBBBBBBBBBBBBBKk..",
        ], ["K": black, "B": blue, "k": blueDark, "L": light, "E": flash ? white : lens, "e": white])
        // Black plating over the chest, blue plates on it.
        c.pattern(18, 33, [
            "bBBBBBBBKLLKBBBBBBBb",
            "KbBBBBBBKBBKBBBBBBbK",
            "KKbbbbbKKBBKKbbbbbKK",
            "KKKKKKKKKBBKKKKKKKKK",
            "KKKKKKKKKKKKKKKKKKKK",
        ], ["K": black, "B": blue, "b": blueDark, "L": light])
        if p.flying {
            c.rect(38, 31, 5, 3, blue); c.rect(38, 31, 5, 1, light); c.rect(42, 30, 2, 5, black)
            c.glowLine(44.5, 32.5, 44.5, 32.5, core: lens, glow: C(0x2A8AFF), coreR: 0.6, glowR: 1.8)
            return
        }
        c.oy += p.gunY
        if p.fire != nil || p.ready || p.gunLift > 0 || p.cheering {
            // The arm reshaped into the plasma cannon.
            c.rect(38, 33, 5, 3, blue); c.rect(38, 33, 5, 1, light); c.rect(38, 35, 5, 1, blueDark)
            c.rect(43, 32, 2, 5, black); c.px(43, 34, C(0x2A8AFF))
            c.glowLine(45, 34.5, 45, 34.5, core: lens, glow: C(0x2A8AFF), coreR: 0.5, glowR: 1.6, strength: 0.8)
        }
    }
}

/// The scarab's wings, rooted on his back: folded away at `spread` 0, fanned out behind him at 1; `buzz` blurs them.
private func beetleWings(_ c: PixelCanvas, t: Double, spread: Double, buzz: Bool) {
    guard spread > 0.05 else { return }
    let membrane = C(0x9AD8FF), vein = C(0x2A6AD0)
    let root = (x: 15.0, y: 27.0)
    let specs: [(angle: Double, len: Double)] = [(-120, 17), (-148, 15), (-172, 12)]
    let jitter: Double = buzz ? (Int(t * 40) % 2 == 0 ? 6 : -6) : 0
    for ghost in buzz ? [1, 0] : [0] {
        for (i, s) in specs.enumerated() {
            let wob = ghost == 1 ? -jitter : jitter * (i % 2 == 0 ? 1 : -0.5)
            let a = -92 + (s.angle + 92) * spread + wob
            let tip = reach(root, a, s.len * (0.45 + 0.55 * spread))
            let alpha = ghost == 1 ? 0.25 : 0.55
            c.glowLine(root.x, root.y, tip.x, tip.y, core: membrane.alpha(alpha), glow: membrane.alpha(alpha * 0.6),
                       coreR: 1.4, glowR: 2.2)
            c.glowLine(root.x, root.y, tip.x, tip.y, core: vein.alpha(ghost == 1 ? 0.35 : 0.9), glow: none, coreR: 0.4, glowR: 0.5)
        }
    }
}

// MARK: - Booster Gold

/// Booster Gold: Clawd with a blond quiff and the blue goggles, the gold suit with its blue collar, shoulders, belt,
/// gloves and boots, and the gold star at his throat; the blasts come off his gauntlet. Skeets, his little gold robot,
/// hovers at his shoulder (and tags along behind in flight). Signature: Skeets swings round in front to take his
/// picture, Booster flashes a thumbs-up and a grin, and the flash goes off.
private func drawBoosterGold(_ c: PixelCanvas, _ p: Pose) {
    let gold = C(0xF2C230), goldShade = C(0xC8961A), blue = C(0x1E3A9A), blueDark = C(0x142868)
    let hair = C(0xF4DA70), hairDark = C(0xC8A840), lens = C(0xA8DCFF)
    let s = p.signature
    let pose: Double = s.map { habitArc(min(1, max(0, ($0 - 0.15) / 0.75)), hold: 0.6) } ?? 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            flyingLegs(c, leg: gold, boot: blue, shade: goldShade)
        } else {
            drawLegs(c, Look(leg: gold), step: p.step)
            drawBoots(c, blue, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        drawBody(c, Look(arm: blue))
        c.pattern(17, 22, [
            "........HHHHHHHHH.....",
            "...HHHHHHHHHHHHHHHHHH.",
            ".HHHHHhHHHHHHHHHHHHHHH",
            ".HHHHHHHHHhHHHHHHHHhH.",
            ".HHh..hH.........hH...",
        ], ["H": hair, "h": hairDark])
        // The goggles.
        c.rect(18, 29, 20, 1, blueDark)
        c.rect(20, 28, 6, 4, blue); c.rect(30, 28, 6, 4, blue)
        c.rect(21, 29, 4, 2, lens); c.rect(31, 29, 4, 2, lens)
        c.px(21, 29, white); c.px(31, 29, white)
        if pose > 0.3 {                                       // the grin
            c.rect(26, 32, 5, 1, white); c.px(25, 31, clawdShade); c.px(31, 31, clawdShade)
            if pose > 0.9 { twinkle(c, 30, 31, C(0xFFF6C8)) }
        }
        // The suit: blue collar with the star, gold chest, blue shoulders and belt.
        c.rect(18, 33, 20, 5, gold)
        c.rect(37, 33, 1, 5, goldShade)
        c.rect(18, 33, 20, 1, blue)
        c.pattern(26, 33, [".YY.", "YYYY", ".YY."], ["Y": C(0xFFE27A)])
        c.rect(18, 37, 20, 1, blue); c.rect(27, 37, 2, 1, gold)
        if p.flying {
            c.rect(38, 31, 5, 3, blue)
            return
        }
        if pose > 0.3 {
            // Thumbs up for the camera.
            c.rect(39, 29, 2, 5, blue)
            c.rect(39, 26, 4, 3, blue); c.rect(42, 26, 1, 3, blueDark)
            c.rect(39, 23, 2, 3, blue)
            return
        }
        c.oy += p.gunY
        if p.fire != nil || p.ready || p.cheering {
            c.rect(38, 33, 4, 3, blue); c.rect(40, 33, 1, 3, gold)
            c.glowLine(42, 34.5, 42, 34.5, core: C(0xFFF8D0), glow: C(0xFFD21E), coreR: 0.5, glowR: 1.6, strength: 0.8)
        }
    }
    // Skeets.
    let bob: Double = sin(p.lt * 3) * 1.2
    var at = (x: 10.0, y: 21.0 + bob), facing = 1, flash = false
    if p.flying { at = (5, 25 + bob) }
    if let s {
        let k = habitArc(s, hold: 0.5)
        at = (10 + 38 * k, 21 - 3 * k + bob)
        facing = k > 0.5 ? -1 : 1
        flash = s > 0.48 && s < 0.6
    }
    drawSkeets(c, at: at, t: p.t, facing: facing, flash: flash)
}

/// Skeets: a little gold bullet of a robot with one eye and a thruster, centred on `at`, looking `facing` (1 right).
private func drawSkeets(_ c: PixelCanvas, at: (x: Double, y: Double), t: Double, facing: Int, flash: Bool) {
    let gold = C(0xF2C230), light = C(0xFFE89A), shade = C(0xB8861A), eye = C(0xE8302A)
    var rows: [String] = [
        ".GGGG.",
        "GLLGGG",
        "GLGGEG",
        "GGGGGS",
        ".SSSS.",
    ]
    if facing < 0 { rows = rows.map { String($0.reversed()) } }
    let x = Int(at.x.rounded()) - 3, y = Int(at.y.rounded()) - 2
    c.pattern(x, y, rows, ["G": gold, "L": light, "S": shade, "E": eye])
    let flick = noise(Int(t * 24) + 9) > 0.5
    c.rect(x + 2, y + 5, 2, 1, C(0x8AD0FF, 0.8))
    if flick { c.px(x + 2, y + 6, C(0x8AD0FF, 0.5)) }
    if flash {
        let ex = Double(x) + (facing > 0 ? 4.5 : 1.5), ey = Double(y) + 2.5
        c.glowLine(ex, ey, ex, ey, core: white, glow: C(0xFFF6C8), coreR: 1.6, glowR: 5)
        for i in 0..<6 {
            let a = Double(i) / 6 * 2 * .pi
            c.px(Int(ex + cos(a) * 6), Int(ey + sin(a) * 6), white.alpha(0.7))
        }
    }
}

// MARK: - The Atom

/// The Atom (Ray Palmer): Clawd in a red cowl, the blue suit with the red-and-white atom on his chest, red gloves,
/// belt and boots. He fights with his fists. Signature: he shrinks to the size of a speck with electron rings round
/// him, bounds across the floor in big tiny leaps, and grows back.
private func drawTheAtom(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.08, s < 0.92 else { atom(c, p); return }
    var q = p
    q.signature = nil; q.breathe = 0
    // 1 = full size: down fast, a while tiny, back up fast.
    let k: Double = s < 0.2 ? 1 - (s - 0.08) / 0.12 : s > 0.8 ? (s - 0.8) / 0.12 : 0
    var x = 28.0, y = 43.5
    if s > 0.2 && s < 0.8 {
        let f = (s - 0.2) / 0.6
        x = 28 + sin(f * 2 * .pi) * 12
        y = 43.5 - abs(sin(f * 3 * .pi)) * 7
    }
    stamp(c, offscreen { atom($0, q) }, scale: 0.2 + 0.8 * k * k, to: (x, y))
    // Electron rings round him while he's small, each with its electron racing round.
    let tiny = 1 - k
    let cx = x, cy = y - 3 - 6 * k
    let rx: Double = 6 + 6 * k, ry: Double = 2 + 3 * k
    for i in 0..<3 {
        let tilt = Double(i) * .pi / 3
        let col = i == 1 ? C(0xFF5A4A) : C(0x9AD8FF)
        func at(_ e: Double) -> (Int, Int) {
            let ex = cos(e) * rx, ey = sin(e) * ry
            return (Int((cx + ex * cos(tilt) - ey * sin(tilt)).rounded()), Int((cy + ex * sin(tilt) + ey * cos(tilt)).rounded()))
        }
        for j in 0..<16 {
            let q = at(Double(j) / 16 * 2 * .pi)
            c.px(q.0, q.1, col.alpha(0.3 * tiny))
        }
        let e = at(p.t * 9 + Double(i) * 2.1)
        c.px(e.0, e.1, white.alpha(tiny))
        c.px(e.0 + 1, e.1, col.alpha(0.7 * tiny))
    }
}

private func atom(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8202A), redDark = C(0x8A1218), blue = C(0x2A4FB0), blueDark = C(0x1C3878)
    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, red, step: p.step, rows: 3)
    c.oy += p.breathe
    drawBody(c, Look(arm: red))
    c.pattern(17, 21, [
        "......RRRRRRRRRR......",
        "....RRRRRRRRRRRRRR....",
        "...RRRRRRRRRRRRRRRR...",
        "..RRRRRRRRRRRRRRRRRr..",
        "..RRRRRRRRRRRRRRRRRr..",
        ".RRRRRRRRRRRRRRRRRRRr.",
        ".RRRr...........rRRRr.",
        ".RRr.............RRRr.",
        ".RR...............RRr.",
        ".RR...............RRr.",
        ".RRr.............rRRr.",
        ".RRRr...........rRRRr.",
    ], ["R": red, "r": redDark])
    c.px(20, 22, C(0xE85A5A)); c.px(19, 23, C(0xE85A5A))
    c.rect(18, 33, 20, 5, blue)
    c.rect(37, 33, 1, 5, blueDark)
    c.pattern(25, 33, [".RRRRR.", "RW.R.WR", "R.RWR.R", "RW.R.WR", ".RRRRR."], ["R": red, "W": white])
    c.rect(18, 37, 20, 1, red)
    if let a = p.melee {
        punch(c, angle: a, trail: p.trail, arm: blue, fist: red, cuff: redDark, smearCol: C(0x9AD8FF))
    }
}

// MARK: - Firestorm

/// Firestorm, the Nuclear Man: Clawd with his head ablaze, the red suit with the yellow flare across the chest and
/// the big puffy pale sleeves with yellow cuffs; fireballs from his hand. In flight the fire on his head streams
/// back. Signature: Professor Stein, the other half of the matrix, pops up beside him as a ghostly floating head with
/// a few words of advice.
private func drawFirestorm(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD8301E), redDark = C(0x9A1C10), yellow = C(0xFFC83A), yellowDark = C(0xD89A1A)
    let puff = C(0xFFF2D8), puffShade = C(0xE0C090)
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            flyingLegs(c, leg: red, boot: yellow, shade: redDark)
        } else {
            drawLegs(c, Look(leg: red), step: p.step)
            drawBoots(c, yellow, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        drawFlames(c, x0: 18, x1: 37, base: 27, height: 14, lean: p.flying ? 0.9 : 0.15, t: p.t, seed: 3, stormFire)
        drawBody(c, Look(arm: puff))
        c.rect(18, 26, 20, 1, C(0xFFB02A))
        c.rect(18, 33, 20, 5, red)
        c.rect(37, 33, 1, 5, redDark)
        // The flare: yellow tongues rising from the belt up over the chest.
        c.pattern(21, 33, [
            "YYY.YY..YY.YYY",
            ".YYYYYYYYYYYY.",
            "..YYYYrrYYYY..",
            "....YYrrYY....",
        ], ["Y": yellow, "r": red])
        c.rect(18, 37, 20, 1, yellowDark)
        // Puffy sleeves.
        c.ellipse(16, 33, 2, 3, puff); c.rect(15, 35, 2, 1, puffShade); c.rect(14, 35, 2, 1, yellow)
        if p.flying {
            c.ellipse(39, 31, 2, 2, puff); c.rect(41, 31, 2, 2, yellow)
            c.glowLine(44, 31.5, 44, 31.5, core: C(0xFFF2B0), glow: C(0xFF7A1A), coreR: 0.8, glowR: 2.2)
            return
        }
        c.oy += p.gunY
        c.ellipse(39, 33, 2, 3, puff); c.rect(38, 35, 3, 1, puffShade); c.rect(41, 33, 1, 3, yellow)
        if p.fire != nil || p.ready || p.cheering {
            let flick = noise(Int(p.t * 14))
            c.glowLine(43, 34, 43, 34, core: C(0xFFF2B0), glow: C(0xFF6A1A), coreR: 0.8, glowR: 1.8 + flick)
        }
    }
    if let s = p.signature {
        let k = habitArc(s, hold: 0.6)
        if k > 0.05 { layer(c, alpha: 0.75 * k) { drawStein($0, t: p.t, talking: s > 0.25 && s < 0.8) } }
    }
}

/// Professor Martin Stein as a ghostly head floating up by Firestorm's shoulder: white hair, glasses, chatting away.
private func drawStein(_ c: PixelCanvas, t: Double, talking: Bool) {
    let ghost = C(0xB8E4FF), ghostDark = C(0x7AB0E0), hair = C(0xE4E8F0), rim = C(0x2A4A7A)
    let y = Int((sin(t * 3) * 1).rounded())
    c.oy += y
    c.ellipse(8, 14, 5, 6, ghost)
    c.rect(4, 18, 9, 1, ghostDark)
    c.pattern(1, 9, [
        "..H.........H.",
        ".HHH.......HHH",
        "HHHH.......HHH",
        "HHH.........HH",
        ".HH..........H",
    ], ["H": hair])
    c.pattern(6, 13, ["KKK.KKK", "KWK.KWK", "KKKKKKK"], ["K": rim, "W": white])
    c.rect(10, 18, 3, 1, rim)
    if talking && Int(t * 8) % 2 == 0 { c.rect(10, 17, 3, 1, rim) }
    c.rect(7, 19, 4, 1, hair)                                 // a wisp of beard
    // A thread of the matrix's fire back to Ronnie.
    for i in 0..<4 {
        let f = frac(t * 2 + Double(i) / 4)
        c.px(13 + Int(f * 6), 18 + Int(f * 4), C(0xFFB02A).alpha(1 - f))
    }
    c.oy -= y
}

// MARK: - Plastic Man

/// Plastic Man: Clawd with black slicked hair and the wraparound dark goggles rimmed in white, the red suit with the
/// yellow-and-black striped belt. His punch is a rubber arm that reaches clean across the gap, the fist ballooning on
/// the fast ones. Signature: he pours himself down into a red rubber ball, goggles and all, bounces a few times, and
/// pours back up.
private func drawPlasticMan(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.03, s < 0.97 else { plasticMan(c, p); return }
    var q = p
    q.signature = nil; q.breathe = 0
    let melt: Double = s < 0.2 ? (s - 0.03) / 0.17 : s > 0.8 ? (0.97 - s) / 0.17 : 1
    if melt < 0.75 {
        let k = melt / 0.75
        stamp(c, offscreen { plasticMan($0, q) }, sx: 1 + 0.5 * k, sy: 1 - 0.65 * k)
        return
    }
    // The ball: dropped from the melt, bouncing, squashing as it lands.
    let f = s > 0.2 && s < 0.8 ? (s - 0.2) / 0.6 : 0
    let h = abs(sin(f * 3 * .pi)) * 10 * (1 - 0.4 * f)
    let squash = h < 1.2 ? 1 : 0
    drawPlasBall(c, x: 28 + Int((sin(f * .pi) * 3).rounded()), bottom: 43 - Int(h.rounded()), squash: squash)
}

private func plasticMan(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xD0202A), redDark = C(0x8E141C), yellow = C(0xF2C230), black = C(0x16161B)
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, redDark, step: p.step, rows: 1)
    c.oy += p.breathe
    // The rubber arm: behind him when it reaches back, so it doesn't cross his face.
    let behind = p.melee.map { cos($0 * .pi / 180) < 0.15 } ?? false
    let arm = {
        guard let a = p.melee else { return }
        let fast = !p.trail.isEmpty
        smear(c, hand, p.trail, from: 4, to: 22, red)
        stretchArm(c, angle: a, length: fast ? 24 : 12, t: p.t, arm: red, fist: clawdOrange, fistDark: clawdShade,
                   size: fast ? 6 : 4)
    }
    if behind { arm() }
    drawBody(c, Look(arm: red, eye: nil))
    c.pattern(18, 22, [
        "....KKKKKKKKKKKK....",
        "..KKKKKKKKKKKKKKKK..",
        ".KKKKgKKKKKKKKKKKKK.",
        "KKKKKKKKKKKKKKKKKKKK",
        "KK..............KKK.",
    ], ["K": black, "g": C(0x4A4A58)])
    plasGoggles(c, x: 19, y: 27)
    c.rect(18, 33, 20, 5, red)
    c.rect(37, 33, 1, 5, redDark)
    for x in 18...37 {
        c.px(x, 36, (x / 2) % 2 == 0 ? yellow : black)
        c.px(x, 37, (x / 2) % 2 == 0 ? yellow : black)
    }
    if !behind { arm() }
}

/// Plas' goggles: two dark lenses in white rims joined across the nose, top-left corner at (`x`, `y`).
private func plasGoggles(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y, [
        ".WWWWW...WWWWW.",
        "WKKKKKWWWKKKKKW",
        "WKLKKKW.WKLKKKW",
        ".WWWWW...WWWWW.",
    ], ["W": C(0xF2F2F4), "K": C(0x1E1E26), "L": C(0x6A7A9A)])
}

/// Plas as a bouncing ball: red, goggles on the front, the striped belt round its middle. `squash` 1 as it lands.
private func drawPlasBall(_ c: PixelCanvas, x: Int, bottom: Int, squash: Int) {
    let red = C(0xD0202A), redDark = C(0x8E141C), yellow = C(0xF2C230), black = C(0x16161B)
    let rx = 7 + squash, ry = 7 - squash, cy = bottom - ry
    c.ellipse(x, cy, rx, ry, red)
    c.ellipse(x + 2, cy + 2, rx - 3, ry - 3, redDark.alpha(0.35))
    c.px(x - 4, cy - 4, C(0xF07070)); c.px(x - 3, cy - 5, C(0xF07070))
    for dx in -rx...rx {
        let col = ((dx + 20) / 2) % 2 == 0 ? yellow : black
        c.px(x + dx, cy + 2, col)
    }
    c.rect(x - 4, cy - 6, 7, 2, black)                           // a tuft of his hair on top
    plasGoggles(c, x: x - 4, y: cy - 3)
}

// MARK: - Elongated Man

/// Elongated Man (Ralph Dibny): Clawd with reddish-brown hair and a nose that won't keep still, the purple suit with
/// black gloves, belt and boots. He punches with a rubbery arm that stretches across the gap. Signature: his nose
/// twitches at a mystery, his neck shoots up high, his head sways round having a good sniff, and he sinks back down.
private func drawElongatedMan(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x8A2E9E), dark = C(0x5A1C6A), black = C(0x1E1E26)
    let hair = C(0x9A4A22), hairDark = C(0x6A2E14)
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, black, step: p.step, rows: 3)
    c.oy += p.breathe
    var neck = 0, sway = 0
    var twitch = noise(Int(p.lt * 5)) > 0.82 ? (Int(p.lt * 20) % 2 == 0 ? 1 : 0) : 0
    if let s = p.signature {
        if s < 0.3 { twitch = Int(p.t * 18) % 2 == 0 ? 1 : -1 }
        if s > 0.22 {
            let k = habitArc((s - 0.22) / 0.74, hold: 0.5)
            neck = Int((13 * k).rounded())
            if k > 0.95 { sway = Int((sin((s - 0.22) * 18) * 2.5).rounded()) }
        }
    }
    let behind = p.melee.map { cos($0 * .pi / 180) < 0.15 } ?? false
    let arm = {
        guard let a = p.melee else { return }
        let fast = !p.trail.isEmpty
        smear(c, hand, p.trail, from: 4, to: 20, purple)
        stretchArm(c, angle: a, length: fast ? 21 : 11, t: p.t, arm: purple, fist: black, fistDark: C(0x0A0A10), size: 3)
    }
    if behind { arm() }
    // The suit and arms.
    c.rect(18, 33, 20, 5, purple)
    c.rect(37, 33, 1, 5, dark)
    c.rect(18, 36, 20, 1, black)
    c.rect(18, 37, 20, 1, dark)
    c.rect(15, 33, 3, 3, purple); c.rect(15, 33, 1, 3, black)
    if p.melee == nil { c.rect(38, 33, 3, 3, purple); c.rect(40, 33, 1, 3, black) }
    // The neck, then the head on top of it.
    if neck > 0 {
        c.glowLine(28, 33, 28 + Double(sway), Double(33 - neck), core: purple, glow: none, coreR: 2.6, glowR: 2.7)
        c.glowLine(30, 33, 30 + Double(sway), Double(33 - neck), core: dark, glow: none, coreR: 0.5, glowR: 0.6)
    }
    let hx = sway, hy = -neck
    c.rect(18 + hx, 26 + hy, 20, 7, clawdOrange)
    c.rect(37 + hx, 26 + hy, 1, 7, clawdShade)
    c.rect(18 + hx, 32 + hy, 20, 1, purple)                         // the collar
    c.rect(22 + hx, 29 + hy, 2, 3, ink); c.rect(32 + hx, 29 + hy, 2, 3, ink)
    c.pattern(18 + hx, 22 + hy, [
        "....HHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHH..",
        ".HHHHhHHHHHHHHHHHHH.",
        ".HHHHHHHHhhHHHHHHHH.",
        "HHHh............hHHH",
        "HHh..............hHH",
    ], ["H": hair, "h": hairDark])
    // The nose.
    c.rect(27 + hx + twitch, 29 + hy, 2, 2, clawdShade)
    c.rect(26 + hx + twitch, 31 + hy, 4, 1, C(0x9A4630))
    c.px(28 + hx + twitch, 29 + hy, C(0xF09A7A))
    if let s = p.signature, s < 0.3 || (neck > 10 && Int(s * 20) % 3 == 0) {
        for i in 0..<2 {                                          // sniff, sniff
            c.px(30 + hx + i * 2 + twitch, 32 + hy - i, C(0xE8E8F0, 0.7))
            c.px(31 + hx + i * 2 + twitch, 31 + hy - i, C(0xE8E8F0, 0.5))
        }
    }
    if !behind { arm() }
}

// MARK: - Vixen

/// Vixen (Mari McCabe): Clawd with a big mane of dark curls, the dark catsuit with gold trim and bracelets, and the
/// Tantu Totem, a gold fox-head pendant, at her throat. She fights with the spirit of whatever animal she needs:
/// ghostly amber claws rake out past her hand. Signature: the totem glows and an amber spirit fox leaps clean over
/// her head.
private func drawVixen(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x2E2018), suitShade = C(0x1E140E), gold = C(0xE8B530)
    let hair = C(0x22160E), hairLight = C(0x4A3020)
    let spirit = C(0xFFA040), spiritCore = C(0xFFE6B0)
    let sig: Double = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, suitShade, step: p.step, rows: 3)
    c.oy += p.breathe
    if sig > 0.05 { c.ellipse(28, 31, 13, 13, spirit.alpha(0.12 * sig)) }
    drawBody(c, Look(arm: suit))
    c.pattern(15, 19, [
        ".......hHHHHHHHHHHh.......",
        ".....HHHHHHhHHHHHHHHH.....",
        "....HHHHhHHHHHHHHhHHHH....",
        "...HHHHHHHHHHHHHHHHHHHH...",
        "..HHHhHHHHHHHHHHHHHHhHHH..",
        "..HHHHHHHHHHhHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHhHHH.",
        ".HHHHHhH...........HhHHHH.",
        ".HHHHh..............hHHHH.",
        "HHHHh................hHHH.",
        "HHHH..................HHH.",
        "HHhH..................HhHH",
        ".HHH..................HHH.",
        ".hHH..................HHh.",
        "..hH..................Hh..",
    ], ["H": hair, "h": hairLight])
    if sig > 0.3 { c.rect(22, 29, 2, 3, spirit); c.rect(32, 29, 2, 3, spirit) }   // eyes lit amber
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, suitShade)
    c.rect(18, 37, 20, 1, gold)
    // The totem on its chain.
    c.px(24, 33, gold); c.px(25, 34, gold); c.px(31, 33, gold); c.px(30, 34, gold)
    c.pattern(26, 34, ["G..G", "GGGG", ".GG."], ["G": sig > 0.2 ? C(0xFFE27A) : gold])
    if sig > 0.2 { c.glowLine(27.5, 35, 27.5, 35, core: spiritCore, glow: spirit, coreR: 0.6, glowR: 2.5 * sig) }
    c.rect(15, 33, 3, 3, suit); c.rect(17, 33, 1, 3, gold)
    if let a = p.melee {
        smear(c, hand, p.trail, from: 5, to: 13, spirit)
        bar(c, hand, a, from: -2, to: 4.5, suit, r: 1.2)
        bar(c, hand, a, from: 2.5, to: 3.5, gold, r: 1.3)
        let f = reach(hand, a, 6)
        c.rect(Int(f.x.rounded()) - 1, Int(f.y.rounded()) - 1, 3, 3, clawdOrange)
        let r = a * .pi / 180, nx = -sin(r), ny = cos(r)
        for k in -1...1 {
            let o = Double(k) * 1.6
            let s0 = reach(hand, a, 7.5), s1 = reach(hand, a, 12 - abs(o))
            c.glowLine(s0.x + nx * o, s0.y + ny * o, s1.x + nx * o, s1.y + ny * o, core: spiritCore, glow: spirit,
                       coreR: 0.4, glowR: 1.3, strength: 0.85)
        }
    } else {
        c.rect(38, 33, 3, 3, suit); c.rect(38, 33, 1, 3, gold)
    }
    if let s = p.signature, s > 0.15, s < 0.9 {
        let f = (s - 0.15) / 0.75
        let fx = -6 + f * 66, fy = 26 - sin(f * .pi) * 18
        drawSpiritFox(c, x: fx, y: fy, t: p.t, alpha: min(1, sin(f * .pi) * 2.2), spirit: spirit, core: spiritCore)
    }
}

/// An amber spirit fox mid-leap, its nose at (`x` + 14, `y`): tail streaming, legs stretched out.
private func drawSpiritFox(_ c: PixelCanvas, x: Double, y: Double, t: Double, alpha: Double, spirit: Px, core: Px) {
    let rows: [String] = [
        "...........S.S...",
        "..........SSSSS..",
        "SS.......SSSSeSS.",
        "SSS.....SSSSSSSSN",
        ".SSSSSSSSSSSSSS..",
        "..SSSSSSSSSSSS...",
        "...SScSSSSSSSS...",
        "..SS........SS...",
        ".S............S..",
    ]
    let ox = Int(x.rounded()), oy = Int(y.rounded()) - 3
    c.glowLine(Double(ox) + 3, Double(oy) + 4, Double(ox) + 14, Double(oy) + 3, core: spirit.alpha(0.25 * alpha),
               glow: spirit.alpha(0.2 * alpha), coreR: 3, glowR: 5)
    c.pattern(ox, oy, rows, ["S": C(0xFFB050).alpha(0.9 * alpha), "c": core.alpha(0.8 * alpha), "e": core.alpha(alpha),
                             "N": C(0x5A2A10).alpha(alpha)])
    for i in 0..<4 {                                             // sparks shed behind it
        let f = frac(t * 3 + Double(i) / 4)
        c.px(ox - 2 - Int(f * 8), oy + 2 + i, core.alpha(alpha * (1 - f) * 0.8))
    }
}

// MARK: - Black Lightning

/// Black Lightning (Jefferson Pierce), the classic look: a big afro, a black mask with white eyes, the blue tunic open
/// at the neck with a yellow lightning bolt across the chest, black gloves and boots. He throws lightning from his
/// raised hand. Signature: he throws both arms up and a crackling arc of lightning jumps between his hands, right over
/// his head.
private func drawBlackLightning(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2450B8), blueDark = C(0x163680), black = C(0x16161B), yellow = C(0xF4D23A)
    let afro = C(0x1A1410), afroLight = C(0x3A2C22)
    let arc: Double = p.signature.map { habitArc($0, hold: 0.7) } ?? 0
    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, black, step: p.step, rows: 3)
    c.oy += p.breathe
    let up = arc > 0.05
    drawBody(c, Look(arm: black, eye: nil), armRight: up ? 0 : p.armRaise)
    c.pattern(15, 15, [
        "........AAAAAAAAAA........",
        ".....AAAAAAaAAAAAAAAA.....",
        "....AAAAaAAAAAAAAAaAAA....",
        "...AAAAAAAAAAaAAAAAAAAA...",
        "..AAAaAAAAAAAAAAAAAAaAAA..",
        "..AAAAAAAAAaAAAAAAAAAAAA..",
        ".AAAAAAAAAAAAAAAAAaAAAAAA.",
        ".AAaAAAAAAAAAAAAAAAAAAaAA.",
        ".AAAAAAAAAAAAAAAAAAAAAAAA.",
        "..AAAAAAAAAAAAAAAAAAAAAA..",
        "..AAAAA..............AAAA.",
        "...AAA................AA..",
        "...AA..................A..",
    ], ["A": afro, "a": afroLight])
    // The mask.
    c.rect(19, 28, 18, 4, black); c.px(18, 29, black); c.px(37, 29, black)
    let eye = arc > 0.3 ? C(0xDFF0FF) : white
    c.rect(22, 29, 2, 2, eye); c.rect(32, 29, 2, 2, eye)
    if arc > 0.3 {
        c.glowLine(23, 30, 23, 30, core: eye, glow: C(0x7FB2FF), coreR: 0.5, glowR: 1.6)
        c.glowLine(33, 30, 33, 30, core: eye, glow: C(0x7FB2FF), coreR: 0.5, glowR: 1.6)
    }
    // The tunic, open at the neck, and the bolt.
    c.rect(18, 33, 20, 5, blue)
    c.rect(37, 33, 1, 5, blueDark)
    c.pattern(22, 32, [".OOOOOOOOO.", "..OOOOOOO..", "...OOOOO...", "....OOO...."], ["O": clawdOrange])
    c.pattern(31, 33, ["..YYY", ".YYY.", "YYYYY", "..YY.", ".YY.."], ["Y": yellow])
    c.rect(18, 37, 20, 1, black)
    if up {
        // Both arms thrown up, the lightning jumping between his hands over his head.
        let lift = arc
        let lh = (x: 15.5 - 2 * lift, y: 34 - 12 * lift), rh = (x: 40.5 + 2 * lift, y: 34 - 12 * lift)
        c.glowLine(16.5, 34, lh.x, lh.y, core: black, glow: none, coreR: 1.3, glowR: 1.4)
        c.glowLine(39.5, 34, rh.x, rh.y, core: black, glow: none, coreR: 1.3, glowR: 1.4)
        c.rect(15, 33, 3, 3, blue); c.rect(38, 33, 3, 3, blue)
        if arc > 0.6 {
            let top = (x: 28.0, y: 6.0 + noise(Int(p.t * 20)) * 3)
            drawMagic(c, Magic(core: C(0xF4F8FF), glow: C(0x7FB2FF)), from: (lh.x, lh.y), to: top, t: p.t)
            drawMagic(c, Magic(core: C(0xF4F8FF), glow: C(0x7FB2FF)), from: top, to: (rh.x, rh.y), t: p.t + 0.37)
            c.glowLine(lh.x, lh.y, lh.x, lh.y, core: white, glow: C(0x7FB2FF), coreR: 0.8, glowR: 2.2)
            c.glowLine(rh.x, rh.y, rh.x, rh.y, core: white, glow: C(0x7FB2FF), coreR: 0.8, glowR: 2.2)
        }
    }
}

// MARK: - The Question

/// The Question (Vic Sage): Clawd with no face at all, just the blank mask, under a blue fedora, in a tan trench
/// coat with the collar turned up over a blue shirt and tie. He fights with his fists, in gloves. Signature: he tips
/// his hat and a question mark curls up out of the smoke beside him and drifts away.
private func drawTheQuestion(_ c: PixelCanvas, _ p: Pose) {
    let hat = C(0x2E4C9E), hatDark = C(0x1C3068), band = C(0x14204A)
    let coat = C(0xC8A46A), coatDark = C(0x9A7A44), coatLight = C(0xE0C088), pants = C(0x2A3460), glove = C(0x4A3424)
    drawLegs(c, Look(leg: pants), step: p.step)
    drawBoots(c, ink, step: p.step, rows: 2)
    c.oy += p.breathe
    // The coat's skirt over the tops of the legs.
    if !seatedPose {
        for y in 37...40 {
            let w = 20 + (y - 37) / 2 * 2
            c.rect(28 - w / 2, y, w, 1, coat)
            c.px(28 - w / 2, y, coatDark); c.px(27 + w / 2, y, coatDark)
        }
        c.rect(28, 38, 1, 3, coatDark)
    }
    drawBody(c, Look(arm: coat, eye: nil))
    let mask = C(0xEAC4A4), maskShade = C(0xC89E80)
    c.rect(18, 26, 20, 6, mask); c.rect(37, 26, 1, 6, maskShade)      // the blank mask
    c.rect(28, 28, 2, 2, maskShade.alpha(0.5))
    c.rect(18, 32, 20, 6, coat)
    c.rect(37, 32, 1, 6, coatDark)
    c.pattern(23, 32, ["LSBBBBSL.", ".LSBKBSL.", "..LSKSL..", "...LKL..."], ["L": coatLight, "S": C(0xD8E0F0),
                                                                           "B": C(0x6A8AC8), "K": band])
    c.rect(17, 30, 3, 4, coat); c.rect(17, 30, 1, 4, coatDark)       // the collar, turned up
    c.rect(36, 30, 3, 4, coat); c.rect(38, 30, 1, 4, coatDark)
    c.rect(18, 36, 20, 1, coatDark); c.rect(27, 36, 2, 1, C(0xD8C080))
    // The hat, tipped as he says goodbye.
    let tip: Int = p.signature.map { $0 < 0.4 ? Int((2 * habitArc($0 / 0.4, hold: 0.3)).rounded()) : 0 } ?? 0
    c.pattern(15, 19 - tip, [
        "........HHHHHHHHHH........",
        ".......HHHHHHhHHHHH.......",
        "......HHHHHHhhHHHHHH......",
        "......HHHHHHHHHHHHHH......",
        "......BBBBBBBBBBBBBB......",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHH",
        "..hhhhhhhhhhhhhhhhhhhhhhh..",
    ], ["H": hat, "h": hatDark, "B": band])
    c.rect(18, 26 - tip, 20, 1, maskShade.alpha(0.8))               // shade under the brim
    c.rect(15, 33, 3, 3, coat); c.rect(15, 35, 3, 1, glove)
    if let a = p.melee {
        punch(c, angle: a, trail: p.trail, arm: coat, fist: glove, cuff: coatDark, smearCol: coatLight)
    } else if tip > 0 {
        c.rect(38, 24, 3, 9, coat); c.rect(38, 22, 3, 2, glove)       // hand up at the brim
    } else {
        c.rect(38, 33, 3, 3, coat); c.rect(38, 35, 3, 1, glove)
    }
    if let s = p.signature, s > 0.25 {
        // A question mark of smoke, rising and fading.
        let f = (s - 0.25) / 0.75
        let rows: [String] = [".SSS.", "S...S", "....S", "...S.", "..S..", ".....", "..S.."]
        let ox = 42 + Int((sin(f * 5) * 1.5).rounded()), oy = 12 - Int((f * 10).rounded())
        let a = f < 0.2 ? f / 0.2 : 1 - (f - 0.2) / 0.8
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() where ch == "S" {
                let wob = noise(r * 7 + k + Int(p.t * 6)) > 0.8 ? 1 : 0
                c.rect(ox + 2 * k + wob, oy + 2 * r, 2, 2, C(0xE4E4EC).alpha(0.9 * a))
            }
        }
        if f < 0.35 { drawBarrelSmoke(c, x: 40, y: 26, f / 0.35) }
    }
}

// MARK: - Metamorpho

/// Metamorpho, the Element Man (Rex Mason): a patchwork Clawd, chalk-white down one side, rust-red iron down the
/// other, a crown of yellow sulphur, one arm and leg copper-green and the other purple, in black trunks. His punch
/// turns to iron as it lands. Signature: he runs through his elements: he goes to glittering crystal, dissolves into
/// a drifting cloud of gas, and pulls himself back together.
private func drawMetamorpho(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature else { metamorpho(c, p); return }
    let crystal: Double = s < 0.4 ? habitArc(s / 0.4, hold: 0.4) : 0
    let gas: Double = s > 0.3 && s < 0.95 ? habitArc((s - 0.3) / 0.65, hold: 0.3) : 0
    layer(c, alpha: 1 - 0.85 * gas, tint: (C(0xBFF0FF), 0.6 * crystal)) { metamorpho($0, p) }
    if crystal > 0.3 {
        for i in 0..<5 {
            let x = 19 + Int(noise(i * 11 + Int(p.t * 6)) * 18), y = 24 + Int(noise(i * 5 + 3 + Int(p.t * 6)) * 16)
            twinkle(c, x, y, white.alpha(crystal))
        }
    }
    if gas > 0.05 {
        let cols: [Int] = [0x8AC86A, 0xA87AC8, 0xE8D070]
        for i in 0..<14 {
            let ang = noise(i * 7 + 1) * 2 * .pi + p.t * (0.8 + noise(i) * 0.8)
            let r = gas * (2 + noise(i * 3) * 9)
            let x = 28 + cos(ang) * r, y = 33 + sin(ang) * r * 0.7 - gas * (2 + noise(i * 5) * 6)
            c.ellipse(Int(x.rounded()), Int(y.rounded()), 3, 2, C(UInt32(cols[i % 3]), 0.35 * gas))
        }
    }
}

private func metamorpho(_ c: PixelCanvas, _ p: Pose) {
    let chalk = C(0xE0D8C8), chalkDark = C(0xB8B0A0), iron = C(0xA8482A), ironDark = C(0x7A3018)
    let sulphur = C(0xE8C040), green = C(0x5A9A3A), greenDark = C(0x3A6A24), purple = C(0x8A4AA8)
    let trunks = C(0x1A1A20)
    // Legs: copper-green on the left, purple on the right.
    let legCols: [Px] = [green, green, purple, purple]
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 4, 2, legCols[i]); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 2, lifted ? 7 : 8, legCols[i])
    }
    c.oy += p.breathe
    c.pattern(18, 24, [
        "....YYYYYYYYYY......",
        "..YYYYYYYYYYYYYY....",
        "CYYYYYYYYYYYYYYYYIIi",
        "CCYYYYYYYYYYYYIIIIIi",
        "CCCCYYYYYYIIIIIIIIIi",
        "CCCCCCCCCCIIIIIIIIIi",
        "CCCCCCCCCIIIIIIIIIIi",
        "CCCCCCCCCCIIIIIIIIIi",
        "CCCCCCCCCCCIIIIIIIIi",
        "cCCCCCCCCCIIIIIIIIIi",
        "cCCCCCCCCIIIIIIIIIIi",
        "KKKKKKKKKKKKKKKKKKKK",
        "KKKKKKKKKKKKKKKKKKKK",
        "kkkkkkkkkkkkkkkkkkkk",
    ], ["C": chalk, "c": chalkDark, "I": iron, "i": ironDark, "Y": sulphur, "K": trunks, "k": C(0x2E2E36)])
    c.px(23, 25, C(0xF8E080)); c.px(22, 26, C(0xF8E080))
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(33, 29, C(0xE8C0A0))                                         // a glint in the iron eye
    c.rect(26, 35, 4, 1, sulphur)                                    // belt buckle
    c.rect(15, 33, 3, 3, purple)
    if let a = p.melee {
        let fast = !p.trail.isEmpty
        smear(c, hand, p.trail, from: 3, to: 8, C(0x9AA0AC))
        bar(c, hand, a, from: -2, to: 4, green, r: 1.2)
        let f = reach(hand, a, 6.5)
        fist(c, f, size: fast ? 5 : 4, skin: C(0x8A909C), dark: C(0x4E545E), light: C(0xC8CCD4))
    } else {
        c.rect(38, 33, 3, 3, green); c.rect(38, 35, 3, 1, greenDark)
    }
}

// MARK: - Red Tornado

/// Red Tornado: the red android, a smooth helmeted head with a ridge down the middle, grey ear discs and glowing
/// yellow eye slits, a yellow arrow down the chest to the belt, and a blue cape. He throws wind from his raised hand,
/// and flies on a whirlwind of his own. Signature: he spins up into a red tornado, a howling funnel his own height,
/// and spins back down.
private func drawRedTornado(_ c: PixelCanvas, _ p: Pose) {
    let spin: Double = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    if spin > 0.55 {
        drawWhirl(c, top: 14, bottom: 43, width: 15 * spin, t: p.t, red: spin)
        return
    }
    let flip = spin > 0.1 && Int(p.t * 14) % 2 == 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        let s = flip ? PixelCanvas(c.w, c.h) : c
        if flip { s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY }
        redTornado(s, p)
        if flip {
            s.mirror(aboutX: Sprite.bodyCenterX)
            s.ox = 0; s.oy = 0; s.baseY = 0
            let (ox, oy, by) = (c.ox, c.oy, c.baseY)
            c.ox = 0; c.oy = 0; c.baseY = 0
            c.paste(s)
            c.ox = ox; c.oy = oy; c.baseY = by
        }
    }
    if spin > 0.05 { drawWhirl(c, top: 14, bottom: 43, width: 15 * spin, t: p.t, red: 0) }
}

private func redTornado(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8282E), redDark = C(0x8A161C), redLight = C(0xE86A6A), yellow = C(0xF2C230), yellowDark = C(0xC8961A)
    let cape = C(0x2A48A0), capeDark = C(0x1A2E70), eye = C(0xFFF2A0), disc = C(0x6A6A76)
    if p.flying {
        drawFlyingCape(c, t: p.t, color: cape, edge: capeDark)
        drawWhirl(c, top: 37, bottom: 48, width: 9, t: p.t, red: 0, narrowing: true)
    } else {
        drawCape(c, t: p.t, speed: p.capeSpeed, color: cape, edge: capeDark)
        drawLegs(c, Look(leg: red), step: p.step)
        drawBoots(c, redDark, step: p.step, rows: 1)
    }
    c.oy += p.breathe
    drawBody(c, Look(body: red, shade: redDark, arm: red, eye: nil), armRight: p.flying ? 0 : p.armRaise)
    c.pattern(17, 21, [
        "......RRRRRRRRRR......",
        "....RRRRRRLLRRRRRR....",
        "...RRRRRRRLLRRRRRRR...",
        "..RRRRRRRRLLRRRRRRRr..",
        "..RRRRRRRRLLRRRRRRRr..",
        ".DRRRRRRRRLLRRRRRRRrD.",
    ], ["R": red, "r": redDark, "L": redLight, "D": disc])
    c.rect(17, 27, 2, 4, disc); c.rect(37, 27, 2, 4, disc)
    c.rect(21, 29, 4, 2, eye); c.rect(31, 29, 4, 2, eye)
    c.glowLine(23, 30, 23, 30, core: eye, glow: C(0xFFC83A), coreR: 0.4, glowR: 1.4, strength: 0.6)
    c.glowLine(33, 30, 33, 30, core: eye, glow: C(0xFFC83A), coreR: 0.4, glowR: 1.4, strength: 0.6)
    c.rect(18, 32, 20, 1, redDark)                                  // the neck seam
    c.pattern(23, 33, [
        "YYYYYYYYYY",
        ".YYYYYYYY.",
        "..YYYYYY..",
        "...YYYY...",
    ], ["Y": yellow])
    c.rect(18, 37, 20, 1, yellowDark)
    if p.flying { c.rect(38, 31, 4, 3, red); c.rect(41, 31, 1, 3, redDark) }
}

/// A whirlwind funnel from `top` to `bottom`, `width` half-width at its widest (the top; with `narrowing`, the top is
/// widest and it tapers to a point at the bottom, else it tapers to the ground). `red` 0…1 is how much of Red
/// Tornado is spinning in it.
private func drawWhirl(_ c: PixelCanvas, top: Int, bottom: Int, width: Double, t: Double, red: Double, narrowing: Bool = false) {
    guard width > 0.5 else { return }
    let span = Double(bottom - top)
    for y in top...bottom {
        let k = Double(y - top) / max(1, span)
        let half = narrowing ? width * (1 - k * 0.85) : width * (1 - k * 0.78) + 1
        c.rect(Int((28 - half * 0.9).rounded()), y, Int((half * 1.8).rounded()) + 1, 1, C(0xC8D8E8, 0.22))
        for j in 0..<5 {
            let ph = t * 14 - Double(y) * 0.45 + Double(j) * 1.257
            let x = 28 + cos(ph) * half
            let front = sin(ph) > 0
            c.rect(Int(x.rounded()), y, 2, 1, C(0xEEF4FA).alpha(front ? 0.95 : 0.45))
            if red > 0.1 && j % 2 == 0 {
                let rx = 28 + cos(ph + 0.6) * half * 0.6
                c.rect(Int(rx.rounded()), y, 2, 1, C(0xD0282E).alpha(red * (front ? 1 : 0.6)))
            }
        }
        if red > 0.1 && y % 3 == 0 {
            let w = max(1, Int(half * 0.5))
            c.rect(28 - w / 2, y, w, 1, C(0xC8282E).alpha(0.35 * red))
        }
    }
    if red > 0.5 {
        let ey = Double(top) + span * 0.45
        let ex = 28 + cos(t * 14) * 3
        c.rect(Int(ex.rounded()) - 2, Int(ey), 2, 1, C(0xFFF2A0)); c.rect(Int(ex.rounded()) + 2, Int(ey), 2, 1, C(0xFFF2A0))
    }
}

// MARK: - Captain Atom

/// Captain Atom (Nathaniel Adam): Clawd in living chrome from head to foot, a bright highlight down his left side,
/// white glowing eyes, and the red atom on his chest. Quantum blasts from his fist; in flight he leads with it, a
/// faint quantum trail behind. Signature: a glint runs across his chrome, then he flares up with quantum energy,
/// a white-blue aura crackling round him and his eyes blazing.
private func drawCaptainAtom(_ c: PixelCanvas, _ p: Pose) {
    let chrome = C(0xC4CCD8), light = C(0xF0F4FA), dark = C(0x8A94A4), deeper = C(0x5E6878)
    let red = C(0xD0242A), quantum = C(0x9AC8FF)
    let flare: Double = p.signature.map { $0 > 0.4 ? habitArc(($0 - 0.4) / 0.6, hold: 0.5) : 0 } ?? 0
    if flare > 0.05 {
        let flick: Double = 0.85 + 0.15 * sin(p.t * 30)
        c.oy += p.breathe
        c.ellipse(28, 31, Int(14 * flare), Int(15 * flare), quantum.alpha(0.18 * flare * flick))
        c.ellipse(28, 32, Int(10 * flare), Int(11 * flare), C(0xE8F4FF).alpha(0.22 * flare * flick))
        c.oy -= p.breathe
    }
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            flyingLegs(c, leg: chrome, boot: chrome, shade: dark)
            for lx in [21, 31] { c.rect(lx, 36, 1, 5, light) }
            c.glowLine(20, 39, 10, 40, core: C(0xE8F4FF, 0.6), glow: quantum.alpha(0.4), coreR: 0.6, glowR: 1.8)
        } else {
            drawLegs(c, Look(leg: chrome), step: p.step)
            if !seatedPose { for lx in [19, 31] { c.rect(lx, 37, 1, 6, light) } }
            drawBoots(c, dark, step: p.step, rows: 1)
        }
        c.oy += p.breathe
        drawBody(c, Look(body: chrome, shade: dark, arm: chrome, eye: nil))
        c.pattern(18, 23, [
            "....SSSSSSSSSSSS....",
            "..SSLLSSSSSSSSSSSd..",
            ".SLLSSSSSSSSSSSSSSd.",
        ], ["S": chrome, "L": light, "d": dark])
        c.rect(19, 27, 1, 9, light); c.rect(20, 26, 1, 3, light)
        c.rect(36, 27, 1, 10, dark)
        c.rect(18, 32, 20, 1, dark)
        let eye = white
        c.rect(21, 28, 4, 4, deeper); c.rect(31, 28, 4, 4, deeper)
        c.rect(22, 29, 2, 2, eye); c.rect(32, 29, 2, 2, eye)
        c.glowLine(23, 30, 23, 30, core: eye, glow: quantum, coreR: 0.5, glowR: 1.4 + 1.4 * flare, strength: 0.7)
        c.glowLine(33, 30, 33, 30, core: eye, glow: quantum, coreR: 0.5, glowR: 1.4 + 1.4 * flare, strength: 0.7)
        c.pattern(22, 33, ["....RRR....", "r..RRRRR..r", ".rrRRWRRrr.", "...RRRRR...", "....RRR...."], ["R": red, "r": red.alpha(0.7), "W": white])
        c.rect(18, 37, 20, 1, deeper)
        if p.flying {
            c.rect(38, 31, 5, 3, chrome); c.rect(38, 31, 5, 1, light)
            c.glowLine(43.5, 32.5, 43.5, 32.5, core: white, glow: quantum, coreR: 0.6, glowR: 2)
            return
        }
        c.oy += p.gunY
        if p.fire != nil || p.ready || p.cheering || flare > 0.3 {
            c.rect(38, 33, 4, 3, chrome); c.rect(38, 33, 4, 1, light)
            c.glowLine(42, 34.5, 42, 34.5, core: white, glow: quantum, coreR: 0.6, glowR: 1.8)
        }
    }
    if let s = p.signature {
        if s < 0.42 { drawGlint(c, p: s / 0.42, maxX: 41) }
        if flare > 0.3 {
            for i in 0..<4 {                                         // quantum crackle round him
                let seed = Int(p.t * 18) * 7 + i * 13
                let a = noise(seed) * 2 * .pi, r = 12 + noise(seed + 1) * 4
                let x0 = 28 + cos(a) * r, y0 = 31 + sin(a) * r * 0.9
                let x1 = x0 + (noise(seed + 2) - 0.5) * 6, y1 = y0 + (noise(seed + 3) - 0.5) * 6
                c.glowLine(x0, y0, x1, y1, core: white.alpha(flare), glow: quantum.alpha(flare), coreR: 0.4, glowR: 1.2)
            }
        }
    }
}

// MARK: - Shared helpers

private let hand = Sprite.hand
private let none = C(0, 0)

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A flyer's legs, together and trailing: two thick legs with boots on.
private func flyingLegs(_ c: PixelCanvas, leg: Px, boot: Px, shade: Px) {
    for lx in [21, 31] {
        c.rect(lx, 36, 4, 5, leg); c.rect(lx, 39, 4, 2, boot); c.rect(lx + 3, 36, 1, 5, shade)
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

/// A point `d` pixels out from `h` at `angle` degrees.
private func reach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// A solid bar along `angle` from `a` to `b` pixels out from `h`.
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

/// A little four-pointed sparkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, col)
    for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(x + dx, y + dy, col.alpha(0.6)) }
}

/// A square fist of side `s` centred on `p`, knuckles to the front.
private func fist(_ c: PixelCanvas, _ p: (x: Double, y: Double), size s: Int, skin: Px, dark: Px, light: Px) {
    let x = Int(p.x.rounded()) - s / 2, y = Int(p.y.rounded()) - s / 2
    c.rect(x, y, s, s, skin)
    c.rect(x, y + s - 1, s, 1, dark)
    c.rect(x + s - 1, y, 1, s, dark)
    c.rect(x, y, s - 1, 1, light)
}

/// A punch along `angle` from the hand: the arm out to a square fist, a cuff at the wrist, a smear behind fast swings.
private func punch(_ c: PixelCanvas, angle: Double, trail: [Double], arm: Px, fist: Px, cuff: Px?, smearCol: Px) {
    smear(c, hand, trail, from: 2, to: 7, smearCol)
    bar(c, hand, angle, from: -2, to: 4.5, arm, r: 1.2)
    if let cuff { bar(c, hand, angle, from: 3.5, to: 4.5, cuff, r: 1.3) }
    let f = reach(hand, angle, 6)
    c.rect(Int(f.x.rounded()) - 2, Int(f.y.rounded()) - 2, 4, 4, fist)
}

/// A rubber arm stretched `length` pixels along `angle` from the shoulder, rippling as it goes, a fist of side
/// `size` on the end.
private func stretchArm(_ c: PixelCanvas, angle: Double, length: Double, t: Double, arm: Px, fist f: Px, fistDark: Px,
                        size: Int) {
    let r = angle * .pi / 180, nx = -sin(r), ny = cos(r)
    var prev = (x: hand.x - 2, y: hand.y)
    let n = max(2, Int(length / 2))
    for i in 1...n {
        let d = length * Double(i) / Double(n), k = Double(i) / Double(n)
        let off = sin(d * 0.55 - t * 14) * 1.1 * k * (1 - k) * 2
        let q = (x: hand.x + cos(r) * d + nx * off, y: hand.y + sin(r) * d + ny * off)
        c.glowLine(prev.x, prev.y, q.x, q.y, core: arm, glow: none, coreR: 0.9, glowR: 1.0)
        prev = q
    }
    let tip = reach(hand, angle, length + Double(size) / 2)
    fist(c, tip, size: size, skin: f, dark: fistDark, light: f)
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, washed towards
/// `tint`'s colour by its amount, and leaning forward one pixel every `lean` rows above the feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, lean: Int = 0, tint: (Px, Double)? = nil, _ art: (PixelCanvas) -> Void) {
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
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] > 0, var col = colour(s, x, y) else { continue }
            if let (t, k) = tint { col = mix(col, t, k) }
            c.px(x + shift, y, col.alpha(alpha))
        }
    }
}

/// `a` washed towards `b` by `k` (0…1), keeping `a`'s opacity.
private func mix(_ a: Px, _ b: Px, _ k: Double) -> Px {
    let r: Double = Double(a.r) + (Double(b.r) - Double(a.r)) * k
    let g: Double = Double(a.g) + (Double(b.g) - Double(a.g)) * k
    let bl: Double = Double(a.b) + (Double(b.b) - Double(a.b)) * k
    return Px(r: UInt8(r), g: UInt8(g), b: UInt8(bl), a: a.a)
}

/// Draws `art` on a fresh canvas of sprite size, its origin at (0, 0).
private func offscreen(_ art: (PixelCanvas) -> Void) -> PixelCanvas {
    let o = PixelCanvas(Sprite.width, Sprite.height)
    art(o)
    return o
}

/// The colour drawn at (`x`, `y`) on `o`, or nil where nothing is.
private func colour(_ o: PixelCanvas, _ x: Int, _ y: Int) -> Px? {
    guard x >= 0, y >= 0, x < o.w, y < o.h else { return nil }
    let i = (y * o.w + x) * 4, a = o.buf[i + 3]
    guard a > 0 else { return nil }
    let m = 255 / Double(a)
    return Px(r: UInt8(min(255, Double(o.buf[i]) * m)), g: UInt8(min(255, Double(o.buf[i + 1]) * m)),
              b: UInt8(min(255, Double(o.buf[i + 2]) * m)), a: a)
}

/// `o` drawn onto `c`, scaled by `scale` (or `sx` across and `sy` down) so that its point `from` lands on `to`.
private func stamp(_ c: PixelCanvas, _ o: PixelCanvas, scale: Double = 1, sx: Double? = nil, sy: Double? = nil,
                   from: (x: Double, y: Double) = (28, 43.5), to: (x: Double, y: Double)? = nil) {
    let to = to ?? from
    let kx = sx ?? scale, ky = sy ?? scale
    for y in 0..<o.h {
        for x in 0..<o.w {
            let srcX = Int(floor(from.x + (Double(x) + 0.5 - to.x) / kx))
            let srcY = Int(floor(from.y + (Double(y) + 0.5 - to.y) / ky))
            guard let col = colour(o, srcX, srcY) else { continue }
            c.px(x, y, col)
        }
    }
}

private struct Fire { let tip, outer, mid, core: Px }
private let stormFire = Fire(tip: C(0xD8301E), outer: C(0xF0661A), mid: C(0xFFA02A), core: C(0xFFE89A))

/// Flame tongues licking up from row `base` over columns x0…x1, at most `height` tall, bending back by `lean` pixels a
/// row, flickering on clock `t`.
private func drawFlames(_ c: PixelCanvas, x0: Int, x1: Int, base: Int, height: Double, lean: Double, t: Double,
                        seed: Int = 0, _ fire: Fire, alpha: Double = 1) {
    let tick = Int(t * 10)
    let half = Double(x1 - x0) / 2 + 1, mid = Double(x0 + x1) / 2 - half * 0.25
    for x in x0...x1 {
        let d = (Double(x) - mid) / half
        let env = max(0.2, 1 - d * d)
        let n = 0.7 * noise(seed + (x / 2) * 13 + tick * 71) + 0.3 * noise(seed + x * 7 + tick * 29)
        let h = Int((height * env * (0.45 + 0.55 * n)).rounded())
        guard h > 0 else { continue }
        for k in 0..<h {
            let f = Double(k) / Double(h)
            let col = f > 0.72 ? fire.tip : f > 0.42 ? fire.outer : f > 0.18 ? fire.mid : fire.core
            c.px(x - Int(Double(k) * lean), base - 1 - k, col.alpha(alpha))
        }
    }
}
