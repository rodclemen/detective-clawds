import Foundation

// Heroes: Task Force X, the Legion of Super-Heroes, the Wonder Twins and the pets. Clawd in costume, except King
// Shark, Ace, Streaky, Gleek and Beppo, who are a shark, a dog, a cat and two monkeys (blocky ones, at least).

let heroes10: [Companion: Persona] = [
    .peacemaker: Persona(name: "Peacemaker", weapon: .ranged, shot: .bullet, muzzle: (47, 32), headTop: 15, signature: 3.4,
                  callout: "I cherish peace with all my heart.",
                  draw: drawPeacemaker),
    .bloodsport: Persona(name: "Bloodsport", weapon: .ranged, shot: .bullet, armoured: true, muzzle: (55, 32), headTop: 19,
                  signature: 3.0,
                  draw: drawBloodsport),
    .ratcatcher2: Persona(name: "Ratcatcher 2", headTop: 18, signature: 3.2, callout: "Sebastian, go!",
                  draw: drawRatcatcher),
    .kingShark: Persona(name: "King Shark", weapon: .melee, pivot: sharkShoulder, bulk: 5, headTop: 13, signature: 3.0,
                  callout: "Nom nom",
                  draw: drawKingShark),
    .polkaDotMan: Persona(name: "Polka-Dot Man", weapon: .ranged, shot: .energy(core: C(0xFFE0F0), glow: C(0xFF4AA8)),
                  muzzle: (42, 33), handGun: false, headTop: 19, signature: 3.2,
                  draw: drawPolkaDotMan),
    .saturnGirl: Persona(name: "Saturn Girl", weapon: .magic, motion: .fly, magic: Magic(core: C(0xFFE0F0), glow: C(0xFF6AB8), jagged: false),
                  headTop: 17, signature: 3.0, callout: "Long live the Legion!",
                  draw: drawSaturnGirl),
    .cosmicBoy: Persona(name: "Cosmic Boy", weapon: .magic, motion: .fly, magic: Magic(core: C(0xF0E0FF), glow: C(0xB86AFF)),
                  headTop: 18, signature: 3.2,
                  draw: drawCosmicBoy),
    .lightningLad: Persona(name: "Lightning Lad", weapon: .magic, motion: .fly, magic: Magic(core: C(0xF4F8FF), glow: C(0x7FB2FF)),
                  headTop: 17, signature: 2.8,
                  draw: drawLightningLad),
    .zan: Persona(name: "Zan", weapon: .melee, headTop: 19, signature: 3.6, callout: "Wonder Twin powers, activate!",
                  draw: drawZan),
    .jayna: Persona(name: "Jayna", weapon: .melee, headTop: 19, signature: 3.6, callout: "Shape of... an eagle!",
                  draw: drawJayna),
    .aceTheBatHound: Persona(name: "Ace the Bat-Hound", weapon: .melee, canSit: false, bulk: 6, headTop: 19, signature: 3.0,
                  draw: drawAce),
    .streaky: Persona(name: "Streaky", weapon: .melee, motion: .fly, canSit: false, bulk: 2, headTop: 23, signature: 3.0,
                  draw: drawStreaky),
    .gleek: Persona(name: "Gleek", headTop: 19, signature: 3.0,
                  draw: drawGleek),
    .beppo: Persona(name: "Beppo", weapon: .melee, motion: .fly, pivot: monkeyShoulder, headTop: 18, signature: 3.0,
                  draw: drawBeppo),
]

// MARK: - Peacemaker

/// Peacemaker: Clawd under the chrome dome helmet with its wide ring of a brim and a chin strap, a blue suit with a
/// white chest panel and the blue dove on it, white gloves, brown boots and a pistol. Signature: Eagly, his bald
/// eagle, swoops down and lands on his raised fist, flaps, and takes off again.
private func drawPeacemaker(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2E58B8), blueDark = C(0x1E3C86), wht = C(0xF0F2F6), whtShade = C(0xC6CCD8)
    let chrome = C(0xC4CAD4), chromeLight = C(0xF4F6FA), chromeDark = C(0x7C8494), strap = C(0x3A3E48)
    let sig = p.signature
    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, C(0x4A3020), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: wht, eye: ink))
    // The suit: blue, the white chest panel with the dove.
    c.rect(18, 33, 20, 5, blue)
    c.rect(37, 33, 1, 5, blueDark)
    c.rect(21, 33, 14, 4, wht); c.rect(21, 36, 14, 1, whtShade)
    c.pattern(24, 33, ["B.....B", ".BB.BB.", "...B..."], ["B": blue])
    c.rect(18, 37, 20, 1, C(0x23232A)); c.rect(27, 37, 2, 1, C(0xC8A040))
    // The chrome dome, its brim and the chin strap.
    c.pattern(15, 15, [
        "..........CCCCCC..........",
        ".......CCCCCCCCCCCC.......",
        ".....CCHHCCCCCCCCCCCC.....",
        "....CCHHCCCCCCCCCCCCCd....",
        "....CHHCCCCCCCCCCCCCCd....",
        "...CCHCCCCCCCCCCCCCCCCd...",
        "...CCHCCCCCCCCCCCCCCCCd...",
        "...CCCCCCCCCCCCCCCCCCCd...",
        "...CCCCCCCCCCCCCCCCCCCd...",
        "...dCCCCCCCCCCCCCCCCCdd...",
        "HHHHHHHHHHHHHHHHHHHHHHHHHC",
        ".ddddddddddddddddddddddddd",
    ], ["C": chrome, "H": chromeLight, "d": chromeDark])
    c.px(20, 17, white); c.px(19, 18, white)
    c.rect(19, 27, 1, 5, strap); c.rect(36, 27, 1, 5, strap); c.rect(20, 32, 16, 1, strap)

    c.rect(15, 33, 3, 3, wht)
    // Eagly comes down 0…0.3, sits on the fist to 0.74, then off he goes.
    if let s = sig, s > 0.04, s < 0.96 {
        c.rect(19, 35, 3, 2, C(0x2A2A30))                          // the pistol, holstered
        let up = min(1, s / 0.2) * (s > 0.84 ? max(0, (0.96 - s) / 0.12) : 1)
        let ay = 33 - Int((5 * up).rounded())
        c.rect(38, ay, 3, 3, wht); c.rect(38, ay + 2, 1, 2, blue)
        if s < 0.3 {
            let k = s / 0.3, e = 1 - (1 - k) * (1 - k)
            drawEagle(c, x: 66 - 26 * e, y: 2 + 21 * e, s: 1, flap: sin(p.t * 18))
        } else if s < 0.74 {
            let flap = s < 0.4 || (s > 0.55 && s < 0.62)
            drawPerchedEagle(c, x: 36, y: ay - 8, flapping: flap, t: p.t)
        } else {
            let k = (s - 0.74) / 0.22
            drawEagle(c, x: 40 + 28 * k * k, y: 23 - 26 * k, s: 1, flap: sin(p.t * 18))
        }
        return
    }
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, wht)
    drawPistol(c, x: 40, y: 31)
}

/// Eagly sitting on a fist, feet at (x + 3, y + 8): white head, hooked yellow beak, brown body, wings out when he flaps.
private func drawPerchedEagle(_ c: PixelCanvas, x: Int, y: Int, flapping: Bool, t: Double) {
    let brown = C(0x5A3A22), brownLight = C(0x7A5232), wht = C(0xF4F2EC), yel = C(0xF0B830)
    if flapping {
        let up = sin(t * 20) > 0
        if up {
            c.pattern(x - 3, y - 4, ["B..........B", "BB........BB", ".BB......BB.", "..BB....BB.."], ["B": brownLight])
        } else {
            c.pattern(x - 3, y + 3, ["..BB....BB..", ".BB......BB.", "BB........BB"], ["B": brownLight])
        }
    }
    c.pattern(x, y, [
        "...WWW..",
        "..WWWkY.",
        "..WWWWYY",
        ".BBWW...",
        "BBBBBB..",
        "BbBBBBb.",
        "BBbBBb..",
        "WW.Y.Y..",
    ], ["W": wht, "k": ink, "Y": yel, "B": brown, "b": brownLight])
}

/// A bald eagle in flight, facing right, body centred on (x, y), `s` times life size; `flap` -1 (wings down) to 1 (up).
private func drawEagle(_ c: PixelCanvas, x: Double, y: Double, s: Double, flap: Double, alpha: Double = 1, tint: Px? = nil) {
    let brown = (tint ?? C(0x5A3A22)).alpha(alpha), brownLight = (tint.map { mix($0, white, 0.3) } ?? C(0x7A5232)).alpha(alpha)
    let wht = C(0xF4F2EC).alpha(alpha), yel = C(0xF0B830).alpha(alpha)
    let k: Double = (flap + 1) / 2
    let a: Double = (160 + 95 * k) * .pi / 180          // down-and-back to up-and-back
    // Far wing, a little behind; then the body, tail and head; then the near wing.
    let far = (x: x - 0.5 * s, y: y - 0.8 * s)
    stick(c, far.x, far.y, far.x + cos(a + 0.25) * 6 * s, far.y + sin(a + 0.25) * 6 * s, brown, 0.9 * s)
    stick(c, x - 3 * s, y + 0.5 * s, x - 6 * s, y + 1 * s, wht, 1.0 * s)
    stick(c, x - 3 * s, y, x + 2 * s, y - 0.3 * s, brown, 1.4 * s)
    stick(c, x + 2.5 * s, y - 1 * s, x + 3.6 * s, y - 1.2 * s, wht, 1.2 * s)
    stick(c, x + 4.4 * s, y - 0.8 * s, x + 5 * s, y - 0.5 * s, yel, 0.6 * s)
    c.px(Int(x + 3.4 * s), Int(y - 1.8 * s), ink.alpha(alpha))
    let root = (x: x - 0.2 * s, y: y - 0.6 * s)
    let mid = (x: root.x + cos(a) * 4 * s, y: root.y + sin(a) * 4 * s)
    stick(c, root.x, root.y, mid.x, mid.y, brownLight, 1.1 * s)
    stick(c, mid.x, mid.y, mid.x + cos(a + 0.3) * 4 * s, mid.y + sin(a + 0.3) * 4 * s, brown, 0.8 * s)
    if s > 1.5 {
        c.px(Int(x - 2 * s), Int(y + 1.6 * s), yel); c.px(Int(x - 1 * s), Int(y + 1.6 * s), yel)
    }
}

// MARK: - Bloodsport

/// Bloodsport: Clawd sealed in gunmetal armour: a helmet with a silver faceplate and a red visor slit, heavy shoulder
/// plates, knee guards and a long rifle. Signature: the rifle comes apart into his armour and he builds it again
/// piece by piece, each part flying in and clicking home, then he aims down a red laser sight.
private func drawBloodsport(_ c: PixelCanvas, _ p: Pose) {
    let metal = C(0x3C424C), metalLight = C(0x5E6672), metalDark = C(0x262A32), silver = C(0xAAB2BE)
    let red = C(0xD8342A)
    drawLegs(c, Look(leg: metal), step: p.step)
    drawBoots(c, metalDark, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, lifted ? 38 : 39, 2, 1, silver)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: metal, shade: metalDark, arm: metal, eye: nil))
    // Helmet, faceplate and visor.
    c.pattern(17, 19, [
        "......MMMMMMMMMM......",
        "....MMMMMMMMMMMMMM....",
        "...MMLLMMMMMMMMMMMd...",
        "..MMLMMMMMMMMMMMMMMd..",
        "..MMMMMMMMMMMMMMMMMd..",
        ".MMMMMMMMMMMMMMMMMMMd.",
        ".MMMMSSSSSSSSSSSSMMMd.",
        ".MMMSSSSSSSSSSSSSSMMd.",
        ".MMMSSSSSSSSSSSSSSMMd.",
        ".MMMSRRRRRRRRRRRRSMMd.",
        ".MMMSSSSSSSSSSSSSSMMd.",
        ".MMMMSSSSddSSSSSSMMMd.",
        ".MMMMMSSdSSdSSSSMMMMd.",
        ".MMMMMMMMMMMMMMMMMMMd.",
    ], ["M": metal, "L": metalLight, "d": metalDark, "S": silver, "R": red])
    c.rect(22, 28, 12, 1, C(0xFF8A70))
    // Chest plate, red stripe, belt of magazines.
    c.rect(18, 33, 20, 4, metalLight); c.rect(19, 33, 18, 1, silver)
    c.rect(27, 34, 2, 3, red)
    c.rect(18, 37, 20, 1, metalDark)
    for x in [20, 24, 31, 34] { c.rect(x, 36, 2, 2, C(0x4A3A2A)) }
    // Shoulder plates.
    c.pattern(14, 30, ["..PPPPP", ".PPPPPP", "PPPPPPd", "PPPPdd."], ["P": metalLight, "d": metalDark])
    c.pattern(36, 30, ["PPPPP..", "PPPPPP.", "dPPPPPP", ".ddPPPP"], ["P": metalLight, "d": metalDark])
    c.rect(15, 34, 3, 2, metal)

    if let s = p.signature, s > 0.04, s < 0.96 {
        // Parts fly home from where they're stowed: back, hip, shoulder, thigh.
        let parts: [(from: (Double, Double), to: (Int, Int), art: [String])] = [
            ((10, 22), (39, 31), ["KKKKKK", "KKSKKK", "KK....", "KK...."]),     // receiver and grip
            ((22, 38), (45, 31), ["KKKKKKKKKK", "KKKKKKKKKK"]),                 // barrel
            ((40, 22), (42, 29), ["SSSS"]),                                       // scope
            ((34, 40), (35, 31), ["KKKK", "KK.."]),                               // stock
        ]
        c.rect(38, 33, 3, 3, metal)
        for (i, part) in parts.enumerated() {
            let a = 0.08 + Double(i) * 0.12, b = a + 0.14
            guard s > a else { continue }
            let k = min(1, (s - a) / (b - a)), e = k * k * (3 - 2 * k)
            let x = part.from.0 + (Double(part.to.0) - part.from.0) * e
            let y = part.from.1 + (Double(part.to.1) - part.from.1) * e - sin(k * .pi) * 6
            let lift = s > 0.62 ? -1 : 0
            c.pattern(Int(x.rounded()), Int(y.rounded()) + lift, part.art, ["K": C(0x24242A), "S": silver])
            if k >= 1 && s < b + 0.05 { drawSparks(c, x: Double(part.to.0) + 1, y: Double(part.to.1), t: p.t, size: 2) }
        }
        if s > 0.66 {
            let sweep = Int(((s - 0.66) * 40).rounded())
            c.glowLine(55, 31, Double(57 + sweep), 31, core: C(0xFF5040, 0.8), glow: C(0xFF2A2A, 0.25), coreR: 0.3, glowR: 0.9)
            c.px(57 + sweep, 31, C(0xFF3020))
        }
        return
    }
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, metal)
    drawRifle(c, x: 35, y: 31)
}

/// Bloodsport's rifle, stock at `x`, barrel along row y + 1, muzzle at (x + 20, y + 1).
private func drawRifle(_ c: PixelCanvas, x: Int, y: Int) {
    c.pattern(x, y - 2, [
        ".......SSSS..........",
        ".......K..K..........",
        "KKKKKKKKKKKKKKKKKKKK.",
        "KKKKKKSKKKKKKKKKKKKKK",
        "KK..KK..KK...........",
        "....KK..KK...........",
    ], ["K": C(0x24242A), "S": C(0xAAB2BE)])
    c.px(x + 16, y, C(0x4A4E58))
}

// MARK: - Ratcatcher 2

/// Ratcatcher 2: Clawd with long dark hair, her dad's big round brass goggles pushed up on her head, an olive coat
/// over a dark top, and the rat-calling staff with its glowing tip. Sebastian, her white rat, rides on her shoulder.
/// She's no fighter: she waves the staff from the side. Signature: she raises the staff, the light flares and a pack
/// of rats comes scurrying across in front of her.
private func drawRatcatcher(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x6A6A3A), coatDark = C(0x4A4A28), top = C(0x8A2A30), hair = C(0x2A1C16), hairLight = C(0x46302A)
    let brass = C(0xB88A3A), brassDark = C(0x7A5A22), lens = C(0x7ADAB0)
    let sig = p.signature
    let call: Double = sig.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: C(0x3A3A44)), step: p.step)
    drawBoots(c, C(0x2A1E18), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: coat))
    c.rect(18, 33, 20, 5, top)
    c.rect(18, 33, 5, 5, coat); c.rect(33, 33, 5, 5, coat)
    c.rect(22, 33, 1, 5, coatDark); c.rect(33, 33, 1, 5, coatDark)
    c.rect(18, 37, 20, 1, coatDark)
    c.rect(19, 22, 18, 4, clawdOrange)
    c.pattern(16, 19, [
        "......HHHHHHHHHHH.......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHHhHHHHHHHHHHHH...",
        "..HHHHHHHHHHHHHHhHHHHH..",
        "..HHH..............HHH..",
        ".HHH................HHH.",
        ".HHh................hHH.",
        ".HH..................HH.",
        ".HH..................HH.",
        ".HH..................HH.",
        "HHh..................hHH",
        "HH....................HH",
        "Hh....................hH",
    ], ["H": hair, "h": hairLight])
    // Goggles up on her head.
    c.pattern(19, 21, [
        "SSSSSSSSSSSSSSSSSS",
        ".BBBB.......BBBB..",
        "BLLLLB.....BLLLLB.",
        "BLWLLBbbbbbBLWLLB.",
        "BLLLLB.....BLLLLB.",
        ".BBBB.......BBBB..",
    ], ["S": C(0x3A2A1E), "B": brass, "b": brassDark, "L": lens, "W": white])
    // Sebastian on her left shoulder.
    let twitch = Int(p.lt * 3) % 4 == 0 ? 1 : 0
    c.pattern(15, 22 + twitch, [
        "..pp...",
        ".pRRp..",
        "RRRRRk.",
        "RRRRRRn",
        ".RRRR..",
    ], ["R": C(0xEEEAE4), "p": C(0xF0A0B0), "k": ink, "n": C(0xF07A90)])
    c.px(14, 26 + twitch, C(0xF0A0B0)); c.px(13, 27 + twitch, C(0xF0A0B0)); c.px(13, 28 + twitch, C(0xF0A0B0))

    // The staff: planted by her hand, waved when she cheers, raised high to call the rats.
    var wave = 0.0
    if p.cheering { wave = sin(p.t * 9) * 18 }
    let raise = Int((8 * call).rounded())
    c.rect(38, 33 - raise, 3, 3, coat)
    let base = (x: 41.5, y: (seatedPose ? 39.0 : 43.0) - Double(raise))
    let r: Double = (-90 + wave) * .pi / 180
    let tip = (x: base.x + cos(r) * 20, y: base.y + sin(r) * 20)
    stick(c, base.x, base.y, tip.x, tip.y, C(0x3A3028), 0.6)
    c.rect(Int(tip.x) - 1, Int(tip.y), 3, 2, brass)
    let glow: Double = 0.55 + 0.45 * call + 0.1 * sin(p.lt * 5)
    c.glowLine(tip.x + 0.5, tip.y - 0.5, tip.x + 0.5, tip.y - 0.5, core: C(0xF8FFE0, glow), glow: C(0xD8F06A, glow),
               coreR: 0.8 + call, glowR: 2 + 3 * call)
    if let s = sig, s > 0.2, s < 0.95 {
        let k = (s - 0.2) / 0.75
        for i in 0..<6 {
            let x = Int(-8 + (k * 1.3 - Double(i) * 0.09) * 90)
            let y = 40 + (i % 2) * 2
            let hop = Int(p.t * 16 + Double(i)) % 2
            guard x > -6, x < 72 else { continue }
            drawRat(c, x: x, y: y - hop, col: i % 3 == 0 ? C(0x6A5A50) : C(0x4A3E38))
        }
    }
}

/// A scurrying rat facing right, nose at (x + 6, y + 1).
private func drawRat(_ c: PixelCanvas, x: Int, y: Int, col: Px) {
    c.pattern(x - 4, y - 2, ["......pp...", ".....RRRR..", "t..RRRRRRk.", ".tRRRRRRRRn", "..tRRRRRR..", "...R...R..."],
              ["R": col, "p": C(0xD88A9A), "t": C(0xD88A9A), "k": ink, "n": C(0xE87A8A)])
}

// MARK: - King Shark

private let sharkShoulder = (x: 40.5, y: 28.5)

/// King Shark (Nanaue): a huge blue-grey shark-man, much bigger than Clawd, a white belly, a dorsal fin, beady
/// little eyes and a mouth full of triangle teeth right across his face, in striped board shorts. His big right arm
/// swings from the shoulder and clubs or claws. Signature: he pulls out a fish and goes nom nom nom, then pats his belly.
private func drawKingShark(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x5E80A4), dark = C(0x3E5C80), deep = C(0x2A4060), belly = C(0xE6EAF0), bellyShade = C(0xB8C2D0)
    let shorts = C(0x2A8AC8), shortsDark = C(0x1C6498), stripe = C(0xF2F2F2)
    let sig = p.signature
    for (i, lx) in [17, 22, 31, 36].enumerated() {
        if seatedPose { c.rect(lx - 1, 38, 5, 2, skin); continue }
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx, 36, 3, lifted ? 7 : 8, skin)
        c.rect(lx + 2, 37, 1, lifted ? 6 : 7, dark)
    }
    c.oy += p.breathe
    // The fin and the left arm, hanging.
    c.pattern(22, 12, ["....FF", "...FFF", "..FFFF", ".FFFFd", "FFFFdd"], ["F": dark, "d": deep])
    c.rect(11, 25, 5, 9, skin); c.rect(11, 25, 1, 9, dark)
    c.rect(10, 33, 6, 4, skin); c.px(10, 37, belly); c.px(12, 37, belly); c.px(14, 37, belly)
    // Body: rounded at the top, belly white.
    c.pattern(15, 17, [
        ".....SSSSSSSSSSSSSSS......",
        "...SSSSSSSSSSSSSSSSSSSS...",
        "..SSSSSSSSSSSSSSSSSSSSSS..",
        ".SSSSSSSSSSSSSSSSSSSSSSSd.",
        "SSSSSSSSSSSSSSSSSSSSSSSSSd",
    ], ["S": skin, "d": dark])
    c.rect(15, 22, 26, 16, skin)
    c.rect(40, 21, 1, 17, dark)
    c.pattern(18, 30, [
        "..WWWWWWWWWWWWWWWWW..",
        ".WWWWWWWWWWWWWWWWWWW.",
        "WWWWWWWWWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWWWWWWWWW",
        "WWWWWWWWWWWWWWWWWWWWw",
        "wWWWWWWWWWWWWWWWWWWww",
    ], ["W": belly, "w": bellyShade])
    for x in [17, 19] { c.rect(x, 26, 1, 3, dark) }                   // gills
    // Beady eyes high on the head.
    c.rect(21, 20, 2, 2, ink); c.rect(33, 20, 2, 2, ink); c.px(21, 20, C(0xC8D8E8)); c.px(33, 20, C(0xC8D8E8))
    // The mouth: a wide toothy grin; chomping in his signature.
    var open = 0
    if let s = sig, s > 0.25, s < 0.72 { open = Int(abs(sin((s - 0.25) / 0.47 * 3 * .pi)) * 3 + 0.5) }
    if p.hit { open = 2 }
    let mouthTop = 23, w = 21
    c.rect(18, mouthTop, w, 5 + open, C(0x5A1A22))
    c.rect(18, mouthTop, w, 1, deep); c.rect(18, mouthTop + 4 + open, w, 1, deep)
    for x in stride(from: 18, to: 18 + w, by: 4) {
        c.rect(x, mouthTop + 1, min(3, 18 + w - x), 1, white); c.px(x + 1, mouthTop + 2, white)
        c.rect(x + 2, mouthTop + 3 + open, min(3, 18 + w - x - 2), 1, white); c.px(x + 3, mouthTop + 2 + open, white)
    }
    // Board shorts.
    c.rect(15, 36, 26, 3, shorts); c.rect(15, 38, 26, 1, shortsDark)
    c.rect(15, 36, 26, 1, stripe); c.rect(27, 36, 1, 3, stripe)
    if !seatedPose { c.rect(15, 39, 7, 1, shorts); c.rect(34, 39, 7, 1, shorts) }

    // The right arm: from the shoulder, down at rest, round to the mouth with a fish.
    if let s = sig, s > 0.04, s < 0.96 {
        let k: Double = habitArc(s, hold: 0.7)
        let angle: Double = 80 + 80 * k
        drawSharkArm(c, angle: angle)
        if s < 0.72 {
            let bites = s > 0.3 ? min(3, Int((s - 0.3) / 0.12)) : 0
            drawFish(c, x: 30 + Int((6 * (1 - min(1, s / 0.25))).rounded()), y: 23 + open / 2, bitten: bites)
        } else {
            c.pattern(26, 18 - Int((s - 0.72) * 20), [".HH.HH.", "HHHHHHH", ".HHHHH.", "..HHH..", "...H..."], ["H": C(0xF04A7A)])
        }
        return
    }
    let angle = p.melee ?? (seatedPose ? 15 : 80)
    for (i, ta) in p.trail.enumerated() { drawSharkArm(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
    drawSharkArm(c, angle: angle)
}

/// King Shark's right arm from the shoulder, ending in a clawed fist.
private func drawSharkArm(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: sharkShoulder, angle: angle, alpha: alpha) { s in
        let skin = C(0x5E80A4), dark = C(0x3E5C80), deep = C(0x2A4060)
        s.rect(18, 17, 9, 7, deep); s.rect(25, 15, 9, 10, deep)
        s.rect(18, 18, 9, 5, skin); s.rect(18, 22, 9, 1, dark)
        s.rect(26, 16, 7, 8, skin); s.rect(32, 17, 1, 6, dark); s.rect(26, 23, 7, 1, dark)
        for y in [16, 18, 20, 22] { s.px(33, y, C(0xE6EAF0)) }
    }
}

/// A silver fish held by the tail, head at (x, y + 1); `bitten` bites already gone from the head end.
private func drawFish(_ c: PixelCanvas, x: Int, y: Int, bitten: Int) {
    let rows: [String] = ["..SSSSSs..T", ".SSkSSSSsTT", "SSSSSSSSsTT", ".SSSSSSs..T"]
    let cut = bitten * 2
    var shown: [String] = []
    for row in rows { shown.append(String(repeating: ".", count: cut) + String(row.dropFirst(cut))) }
    c.pattern(x - 6, y, shown, ["S": C(0xD8E4EC), "s": C(0x9AB0C0), "T": C(0xF0A040), "k": ink])
}

// MARK: - Polka-Dot Man

private let polkaColours: [Int] = [0xE83A6A, 0xF0C030, 0x3A8AE0, 0x4AC060, 0xF07A2A, 0x9A5AD0, 0xE83A6A, 0x3A8AE0, 0xF0C030]
private let polkaSpots: [(Int, Int)] = [(20, 34), (25, 36), (30, 33), (34, 35), (23, 23), (31, 21), (35, 25), (19, 27), (27, 25)]

/// Polka-Dot Man: Clawd in the white bodysuit and hood covered in coloured dots, round black goggles over the eyes.
/// He peels dots off himself and throws them. Signature: every dot lifts off his suit and circles round him like a
/// little planetarium, then they settle back where they belong.
private func drawPolkaDotMan(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xF0EEEA), shade = C(0xC8C4BC)
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, C(0xE83A6A), step: p.step, rows: 1)
    c.oy += p.breathe
    drawBody(c, Look(body: suit, shade: shade, arm: suit, eye: nil))
    // The hood: white all over the head, a seam round the face, goggles.
    c.pattern(17, 20, [
        "......WWWWWWWWWW......",
        "....WWWWWWWWWWWWWW....",
        "...WWWWWWWWWWWWWWWW...",
        "..WWWWWWWWWWWWWWWWWs..",
        "..WWWWWWWWWWWWWWWWWs..",
        ".WWWWWWWWWWWWWWWWWWWs.",
    ], ["W": suit, "s": shade])
    c.pattern(20, 27, ["GGGGG......GGGGG", "GKKKG......GKKKG", "GKWKGGGGGGGGKWKG", "GKKKG......GKKKG", "GGGGG......GGGGG"],
              ["G": C(0x4A4A52), "K": C(0x1A1A22), "W": C(0x8AA0C0)])
    c.rect(18, 37, 20, 1, shade)
    let swirl: Double = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    for (i, spot) in polkaSpots.enumerated() {
        let col = C(UInt32(polkaColours[i]))
        var x = Double(spot.0), y = Double(spot.1)
        if swirl > 0 {
            let a: Double = Double(i) / Double(polkaSpots.count) * 2 * .pi + p.t * 3
            x += (28 + cos(a) * 17 - x) * swirl
            y += (30 + sin(a) * 12 - y) * swirl
        }
        c.rect(Int(x.rounded()), Int(y.rounded()), 2, 2, col)
        if swirl > 0.3 { c.glowLine(x + 1, y + 1, x + 1, y + 1, core: col, glow: col.alpha(0.35), coreR: 0.4, glowR: 2) }
        if swirl > 0.15 && swirl < 0.95 {
            // Where it peeled off from, a pale mark.
            c.rect(spot.0, spot.1, 2, 2, C(0xDCD8D0))
        }
    }
    c.rect(15, 33, 3, 3, suit)
    c.oy += p.gunY
    c.rect(38, 33, 3, 3, suit)
    if p.fire != nil || p.ready || p.gunLift > 0 || p.cheering {
        c.rect(41, 32, 2, 2, C(0xFF4AA8)); c.px(41, 32, C(0xFFC0DC))
    }
}

// MARK: - Saturn Girl

/// Saturn Girl (Imra Ardeen): Clawd with long blonde hair, the pink-red Legion suit with a white collar and the
/// little ringed planet on the chest, a gold belt, white boots and the gold Legion flight ring. She flies leaning in,
/// one fist forward; her telepathy streams from her raised hand. Signature: two fingers to her temple, her eyes go
/// pink and rings of thought ripple out from her head.
private func drawSaturnGirl(_ c: PixelCanvas, _ p: Pose) {
    let think: Double = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        let suit = C(0xD83A6A), dark = C(0x9A2050), wht = C(0xF4EEF0), hair = C(0xF2D070), hairDark = C(0xC8A040)
        let gold = C(0xF0C040)
        if p.flying {
            drawFlyingLegs(c, leg: suit, shade: dark, boot: wht)
        } else {
            drawLegs(c, Look(leg: suit), step: p.step)
            drawBoots(c, wht, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        drawBody(c, Look(arm: suit, eye: think > 0.3 ? nil : ink), armRight: p.flying ? 0 : p.armRaise)
        if think > 0.3 {
            for x in [22, 32] {
                c.rect(x, 29, 2, 3, C(0xFF6AB8))
                c.glowLine(Double(x) + 1, 30.5, Double(x) + 1, 30.5, core: C(0xFFE0F0), glow: C(0xFF6AB8), coreR: 0.5, glowR: 2)
            }
        }
        c.rect(18, 33, 20, 5, suit); c.rect(37, 33, 1, 5, dark)
        c.rect(18, 33, 20, 1, wht)
        c.pattern(25, 34, ["..YY..", "WYYYYW", "..YY.."], ["Y": gold, "W": wht])
        c.rect(18, 37, 20, 1, gold)
        c.rect(19, 22, 18, 4, clawdOrange)      // forehead under the hair
        c.pattern(16, 18, [
            ".......HHHHHHHHHH.......",
            ".....HHHHHHHHHHHHHH.....",
            "...HHHHHHhHHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHhHHHH..",
            "..HHHHhHHHHHHHHHHHHHHH..",
            ".HHHH..hHHHHHHHHh...HHH.",
            ".HHH................HHH.",
            ".HHh................hHH.",
            ".HH..................HH.",
            ".HH..................HH.",
            "HHH..................HHH",
            "HHh..................hHH",
            "HH....................HH",
            "Hh....................hH",
            "H......................H",
        ], ["H": hair, "h": hairDark])
        c.rect(15, 33, 3, 3, suit)
        if think > 0.05 {
            c.rect(15, 33, 3, 3, C(0x000000, 0))
            c.rect(14, 28, 3, 3, suit); c.px(15, 27, clawdOrange); c.px(16, 27, clawdOrange)
        }
        if p.flying {
            c.rect(38, 31, 4, 3, suit); c.px(41, 32, gold)
            c.glowLine(41.5, 32.5, 41.5, 32.5, core: C(0xFFF4C0), glow: gold, coreR: 0.4, glowR: 1.6)
        } else {
            c.px(40, 34 - p.armRaise, gold)
        }
    }
    if think > 0.05 {
        for i in 0..<3 {
            let f: Double = frac(p.t * 0.9 + Double(i) / 3)
            let r: Double = 5 + f * 15
            let a: Double = think * (1 - f) * 0.9
            for k in 0..<28 {
                let ang: Double = Double(k) / 28 * 2 * .pi
                guard sin(ang) < 0.3 else { continue }
                c.px(Int((28 + cos(ang) * r).rounded()), Int((22 + sin(ang) * r * 0.7).rounded()), C(0xFF6AB8, a))
            }
        }
    }
}

// MARK: - Cosmic Boy

/// Cosmic Boy (Rokk Krinn): Clawd with short black hair in the pink-and-black Legion suit, black sleeves and legs,
/// a gold belt, pink boots and the flight ring. Magnetism streams from his raised hand. Signature: both hands up, a
/// handful of steel ball bearings lift off the ground and orbit him on purple field lines, then drop.
private func drawCosmicBoy(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature
    let pull: Double = s.map { habitArc($0, hold: 0.6) } ?? 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        let black = C(0x1E1E28), blackLight = C(0x3A3A48), pink = C(0xE0489A), pinkDark = C(0xA82A72)
        let hair = C(0x18141A), gold = C(0xF0C040)
        if p.flying {
            drawFlyingLegs(c, leg: black, shade: blackLight, boot: pink)
        } else {
            drawLegs(c, Look(leg: black), step: p.step)
            drawBoots(c, pink, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        let up = pull > 0.2 ? 4 : 0
        drawBody(c, Look(arm: black), armLeft: up, armRight: p.flying ? 0 : max(up, p.armRaise))
        c.rect(18, 33, 20, 5, pink); c.rect(37, 33, 1, 5, pinkDark)
        c.rect(18, 33, 3, 5, black); c.rect(35, 33, 3, 5, black)
        c.rect(26, 33, 4, 4, black)
        c.pattern(21, 34, ["SS", "Ss"], ["S": C(0xC8CED8), "s": C(0x8A929E)]); c.pattern(33, 34, ["SS", "Ss"], ["S": C(0xC8CED8), "s": C(0x8A929E)])
        c.rect(18, 37, 20, 1, gold)
        c.rect(19, 22, 18, 4, clawdOrange)      // forehead under the hair
        c.pattern(17, 20, [
            ".....HHHHHHHHHHHH.....",
            "...HHHHHHHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHHHHHHHH.",
            ".HHHHHHHHHHHHHHH..HHH.",
            ".HH...............HHH.",
            ".H.................HH.",
        ], ["H": hair])
        c.rect(15, 33 - up, 3, 3, pink); c.rect(38, 33 - (p.flying ? 0 : max(up, p.armRaise)), 3, 3, pink)
        if p.flying {
            c.rect(38, 31, 4, 3, black); c.rect(40, 31, 2, 3, pink); c.px(41, 32, gold)
        } else {
            c.px(40, 34 - max(up, p.armRaise), gold)
        }
    }
    if let s = s, s > 0.04, s < 0.96 {
        let violet = C(0xB86AFF)
        for i in 0..<6 {
            let a: Double = Double(i) / 6 * 2 * .pi + p.t * 4
            let home = (x: 10.0 + Double(i) * 9, y: 42.0)
            let orbit = (x: 28 + cos(a) * 18, y: 24 + sin(a) * 6)
            let x = home.x + (orbit.x - home.x) * pull, y = home.y + (orbit.y - home.y) * pull
            if pull > 0.5 && i % 2 == 0 {
                c.glowLine(x, y, i < 3 ? 16 : 40, 28, core: violet.alpha(0.25), glow: violet.alpha(0.12), coreR: 0.3, glowR: 0.9)
            }
            c.rect(Int(x), Int(y), 2, 2, C(0x8A929E)); c.px(Int(x), Int(y), C(0xE8ECF2))
            c.glowLine(x + 1, y + 1, x + 1, y + 1, core: C(0x000000, 0), glow: violet.alpha(0.3 * pull), coreR: 0.1, glowR: 2.2)
        }
    }
}

// MARK: - Lightning Lad

/// Lightning Lad (Garth Ranzz): Clawd with spiky red hair in the blue Legion suit with a yellow lightning bolt
/// slashed across the chest, a gold belt, yellow boots and the flight ring. Lightning comes from his raised hand.
/// Signature: he throws a fist up and the lightning takes him over: bolts crawl all over him, his hair stands on end
/// and he flickers white.
private func drawLightningLad(_ c: PixelCanvas, _ p: Pose) {
    let charge: Double = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let flash = charge > 0.4 && Int(p.t * 20) % 3 == 0
    layer(c, lean: p.flying ? 4 : 0, tint: flash ? (C(0xE8F4FF), 0.4) : nil) { c in
        let blue = C(0x2E52B0), dark = C(0x1E3880), yel = C(0xF4D030), hair = C(0xE0582A), hairDark = C(0xA83A1A)
        if p.flying {
            drawFlyingLegs(c, leg: blue, shade: dark, boot: yel)
        } else {
            drawLegs(c, Look(leg: blue), step: p.step)
            drawBoots(c, yel, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        let fist = charge > 0.2 ? 7 : (p.flying ? 0 : p.armRaise)
        drawBody(c, Look(arm: blue), armRight: fist)
        c.rect(18, 33, 20, 5, blue); c.rect(37, 33, 1, 5, dark)
        c.pattern(19, 33, [
            "..............YY",
            "........YYYYYYY.",
            ".......YYY......",
            "..YYYYYYY.......",
            "YYY.............",
        ], ["Y": yel])
        c.rect(18, 37, 20, 1, C(0xF0C040))
        if charge > 0.3 {
            c.pattern(16, 13, [
                "..H...H...H....H...H..",
                "..HH..HH..HH..HH..HH..",
                "...HH.HHH.HHH.HHH.HH..",
                "....HHHHHHHHHHHHHHH...",
                "...HHHHHHHHHHHHHHHHH..",
                "..HHHHHHHHHHHHHHHHHHH.",
                "..HHHhHHHHHhHHHHHhHHH.",
            ], ["H": hair, "h": hairDark])
        }
        c.rect(19, 22, 18, 4, clawdOrange)      // forehead under the hair
        c.pattern(17, 19, [
            "......H...H...H.......",
            "....HHHH.HHH.HHHH.....",
            "...HHHHHHHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHHHH..",
            ".HHHHhHHHHHhHHHHHHHHH.",
            ".HHH.H...H....H..HHHH.",
            ".HH...............HHh.",
            ".H.................Hh.",
        ], ["H": hair, "h": hairDark])
        if p.flying {
            c.rect(38, 31, 4, 3, blue); c.px(41, 32, C(0xF0C040))
        } else {
            c.px(40, 34 - fist, C(0xF0C040))
        }
    }
    if charge > 0.3 {
        // Bolts crawling over him.
        let seed = Int(p.t * 18)
        for b in 0..<4 {
            var prev = (x: 14 + noise(seed + b * 7) * 28, y: 16 + noise(seed + b * 11) * 24)
            for k in 1...3 {
                let next = (x: prev.x + (noise(seed + b * 13 + k) - 0.5) * 9, y: prev.y + (noise(seed + b * 17 + k) - 0.5) * 9)
                c.glowLine(prev.x, prev.y, next.x, next.y, core: C(0xF4F8FF), glow: C(0x7FB2FF, 0.7), coreR: 0.35, glowR: 1.3)
                prev = next
            }
        }
        c.glowLine(39.5, 26.5, 39.5, 26.5, core: C(0xF4F8FF), glow: C(0x7FB2FF), coreR: 0.8, glowR: 3)
    }
}

// MARK: - The Wonder Twins

/// One of the Wonder Twins: Clawd with the Exxorians' pointed ears, black hair (a ponytail for Jayna), the purple
/// suit with a lavender collar, a gold belt and the gold "W" on the chest, and a Wonder Twin ring. `fist` 0…1 raises
/// the right fist for "Wonder Twin powers, activate!"; `armOut` hides the resting right arm (a weapon arm is drawn).
private func drawTwinBody(_ c: PixelCanvas, _ p: Pose, girl: Bool, fist: Double, armOut: Bool) {
    let purple = C(0x6E3AA8), dark = C(0x4A2478), lav = C(0xB08AE0), gold = C(0xF0C040), hair = C(0x1A1420)
    let hairLight = C(0x3A2C40)
    drawLegs(c, Look(leg: purple), step: p.step)
    drawBoots(c, dark, step: p.step, rows: 3)
    c.oy += p.breathe
    if girl {
        // Ponytail swinging behind.
        let sw = Int((sin(p.lt * 3) * 1).rounded())
        c.pattern(11 + sw, 22, ["..HHHH", ".HHHHH", "HHHHH.", "HHHH..", "HHH...", ".HH...", "..H..."], ["H": hair])
    }
    drawBody(c, Look(arm: purple))
    c.rect(18, 33, 20, 5, purple); c.rect(37, 33, 1, 5, dark)
    c.rect(18, 33, 20, 1, lav)
    c.pattern(25, 34, ["W.W.W", "W.W.W", ".W.W."], ["W": gold])
    c.rect(18, 37, 20, 1, gold)
    c.rect(19, 22, 18, 4, clawdOrange)
    if girl {
        c.pattern(17, 19, [
            "......HHHHHHHHHH......",
            "....HHHHHHHHHHHHHH....",
            "...HHHHHHHHHHHHHHHH...",
            "..HHHHHhHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHHhHHHHH.",
            ".HHHHHH.......HHHHHHH.",
            ".HHH..............HHH.",
            ".HH................HH.",
            ".HH................HH.",
        ], ["H": hair, "h": hairLight])
    } else {
        c.pattern(17, 20, [
            ".....HHHHHHHHHHHH.....",
            "...HHHHHHHHHHHHHHHH...",
            "..HHHHHHhHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHHHhHHHH.",
            ".HHHHHH.HHHHH..HHHHHH.",
            ".HH................HH.",
        ], ["H": hair, "h": hairLight])
    }
    // Pointed ears.
    c.pattern(15, 25, ["O..", "OO.", ".OO"], ["O": clawdOrange])
    c.pattern(38, 25, ["..O", ".OO", "OO."], ["O": clawdOrange])
    c.rect(15, 33, 3, 3, lav)
    if fist > 0 {
        let up = Int((6 * min(1, fist * 2)).rounded())
        c.rect(38, 33 - up, 4, 3, lav); c.px(41, 33 - up, gold)
    } else if !armOut {
        c.rect(38, 33, 3, 3, lav); c.px(40, 34, gold)
    }
}

/// "Wonder Twin powers…": the other twin's fist comes in from the right to meet the raised one, `k` 0…1; they
/// touch at the end with a flash.
private func drawTwinFistBump(_ c: PixelCanvas, k: Double, t: Double, other: Px) {
    let x = 52 - Int((10 * min(1, k / 0.7)).rounded())
    c.rect(x, 27, 3, 3, C(0xB08AE0)); c.rect(x + 3, 27, 8, 3, other.alpha(0.9)); c.px(x, 27, C(0xF0C040))
    if k > 0.7 {
        let f = (k - 0.7) / 0.3
        c.glowLine(42, 28.5, 42, 28.5, core: white, glow: C(0xD8B0FF), coreR: 0.6 + f, glowR: 2.5 + 4 * f)
        for i in 0..<6 {
            let a: Double = Double(i) * .pi / 3 + t * 4
            let r: Double = 3 + f * 5
            c.px(Int(42 + cos(a) * r), Int(28.5 + sin(a) * r), C(0xF8F0FF, 1 - f * 0.5))
        }
    }
}

/// Zan: the boy twin, short black hair. He fights with a sword of ice he forms in his hand. Signature: "Wonder Twin
/// powers, activate!", fists touch, and "Form of... ice!": he freezes into a block of ice, frost sparkling, and thaws.
private func drawZan(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature
    let ice: Double = s.map { $0 > 0.42 ? habitArc(($0 - 0.42) / 0.58, hold: 0.6) : 0 } ?? 0
    if ice > 0.05 {
        layer(c, tint: (C(0xBDEBFF), 0.85 * ice)) { drawTwinBody($0, p, girl: false, fist: 0, armOut: false) }
        let a = ice
        // Clear ice round him, and crystals.
        c.rect(14, 18, 28, 26, C(0xD8F4FF, 0.18 * a))
        c.rect(14, 18, 28, 1, C(0xFFFFFF, 0.6 * a)); c.rect(14, 18, 1, 26, C(0xFFFFFF, 0.5 * a))
        c.rect(41, 18, 1, 26, C(0x8ACAE8, 0.6 * a))
        for (x, y, h) in [(17, 14, 4), (24, 12, 6), (31, 13, 5), (37, 15, 3)] as [(Int, Int, Int)] {
            for k in 0..<h { c.rect(x - (h - k) / 3, y + k, 1 + 2 * ((h - k) / 3 == 0 ? k / 2 : 0) + 1, 1, C(0xD8F4FF, a)) }
            c.px(x, y, C(0xFFFFFF, a))
        }
        for i in 0..<4 {
            let f: Double = frac(p.t * 1.3 + Double(i) * 0.27)
            if f < 0.3 { c.px(16 + i * 7, 20 + (i * 5) % 18, C(0xFFFFFF, a)) }
        }
        return
    }
    let fist: Double = s.map { $0 > 0.04 && $0 < 0.42 ? ($0 - 0.04) / 0.38 : 0 } ?? 0
    drawTwinBody(c, p, girl: false, fist: fist, armOut: p.melee != nil)
    if fist > 0 { drawTwinFistBump(c, k: fist, t: p.t, other: C(0x6E3AA8)) }
    if let a = p.melee {
        c.rect(38, 33, 3, 3, C(0xB08AE0))
        for (i, ta) in p.trail.enumerated() { drawIceSword(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawIceSword(c, angle: a)
    }
}

/// Zan's ice sword, grip in the hand, a long jagged icicle of a blade.
private func drawIceSword(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: Sprite.hand, angle: angle, alpha: alpha) { s in
        let ice = C(0xBDEBFF), light = C(0xF4FCFF), dark = C(0x6AAED8)
        s.rect(18, 20, 4, 1, dark)
        s.rect(22, 18, 1, 5, light)
        s.rect(23, 19, 13, 3, ice)
        s.rect(23, 19, 13, 1, light); s.rect(23, 21, 13, 1, dark)
        s.rect(36, 20, 3, 1, ice); s.px(39, 20, light)
        for x in [26, 30, 34] { s.px(x, 18, ice); s.px(x + 1, 22, dark) }
    }
}

/// Jayna: the girl twin, black ponytail. She fights with a gorilla's arm. Signature: "Wonder Twin powers,
/// activate!", fists touch, and "Shape of... an eagle!": in a purple flash she becomes a bald eagle, flaps, and
/// changes back.
private func drawJayna(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature
    if let s = s, s > 0.42, s < 0.95 {
        let k = (s - 0.42) / 0.53
        c.oy += p.breathe
        drawEagle(c, x: 26, y: 26 - 3 * sin(k * .pi), s: 2.2, flap: sin(p.t * 9))
        let fl: Double = max(0, 1 - k / 0.15) + max(0, (k - 0.85) / 0.15)
        if fl > 0 {
            c.ellipse(28, 30, Int(14 * fl) + 1, Int(14 * fl) + 1, C(0xD8B0FF, 0.5 * fl))
            c.glowLine(28, 30, 28, 30, core: white.alpha(fl), glow: C(0xB08AE0, fl), coreR: 2 + 3 * fl, glowR: 6 + 6 * fl)
        }
        return
    }
    let fist: Double = s.map { $0 > 0.04 && $0 < 0.42 ? ($0 - 0.04) / 0.38 : 0 } ?? 0
    drawTwinBody(c, p, girl: true, fist: fist, armOut: p.melee != nil)
    if fist > 0 { drawTwinFistBump(c, k: fist, t: p.t, other: C(0x6E3AA8)) }
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() { drawGorillaArm(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawGorillaArm(c, angle: a)
    }
}

/// Jayna's arm turned gorilla: thick black fur and a big grey-knuckled fist.
private func drawGorillaArm(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: (39.5, 34.5), angle: angle, alpha: alpha) { s in
        let fur = C(0x3A302C), furLight = C(0x5A4C44), skin = C(0x8A8290), knuckle = C(0xB0A8B4)
        s.rect(18, 18, 8, 5, fur); s.rect(18, 18, 8, 1, furLight)
        for x in [19, 22, 25] { s.px(x, 17, fur); s.px(x + 1, 23, fur) }
        s.rect(25, 16, 7, 9, fur); s.rect(25, 16, 7, 1, furLight)
        s.rect(30, 16, 3, 9, skin)
        for y in [16, 19, 22] { s.rect(32, y, 1, 2, knuckle); s.px(31, y + 2, C(0x4A4450)) }
    }
}

// MARK: - Ace the Bat-Hound

/// Ace the Bat-Hound: a black-and-tan German shepherd in a black bat cowl with tall pointed ears, a white eye in the
/// mask, and a blue collar with a gold bat tag. He fights with a bite, jaw dropping open as he lunges. Signature: the
/// Bat-Signal lights up the sky, he lifts his head and howls at it.
private func drawAce(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x2A2626), tan = C(0xB8824A), tanLight = C(0xD8A86A)
    let sig = p.signature
    let howl: Double = sig.map { habitArc($0, hold: 0.55) } ?? 0
    let open: Double = max(p.melee.map { a in max(0, 1 - abs(a - 5) / 45) } ?? 0, howl > 0.5 ? 0.5 : 0)
    let lunge = p.melee != nil ? Int((2 * open).rounded()) : 0
    if howl > 0.05 {
        // The Bat-Signal.
        let a = howl
        c.glowLine(2, 40, 13, 8, core: C(0xFFF4C0, 0.08 * a), glow: C(0xFFF4C0, 0.06 * a), coreR: 2, glowR: 5)
        c.ellipse(13, 7, 7, 4, C(0xFFE27A, 0.85 * a))
        c.pattern(8, 5, ["K.........K", "KK.K.K.KK..", ".KKKKKKKK..", "..KK..KK..."].map { String($0) },
                  ["K": C(0x1A1A22, a)])
    }
    for (i, lx) in [13, 18, 28, 33].enumerated() {
        let lifted = p.step >= 0 && i % 2 == p.step
        c.rect(lx + lunge, 36, 3, lifted ? 6 : 7, tan)
        c.rect(lx + lunge + 2, 37, 1, lifted ? 5 : 6, C(0x8A5A30))
        c.rect(lx + lunge, lifted ? 42 : 43, 4, 1, tanLight)
    }
    c.oy += p.breathe
    c.ox += lunge
    // Tail, bushy, wagging.
    let wag: Double = sin(p.lt * (howl > 0 ? 3 : 7)) * 2
    stick(c, 13, 30, 8, 27 + wag, fur, 1.4)
    stick(c, 8, 27 + wag, 5, 24 + wag * 1.4, fur, 1.1)
    // Body: black saddle over tan.
    c.rect(12, 29, 24, 8, tan)
    c.rect(13, 28, 21, 1, fur); c.rect(12, 29, 22, 5, fur)
    c.rect(12, 36, 24, 1, C(0x8A5A30))
    // Head on a pivot at the neck, lifted for the howl.
    prop(c, at: (34.5, 29.5), angle: -38 * howl) { s in
        s.pattern(17, 9, [
            "...CC...........",
            "...CCC..........",
            "..CCCCC.........",
            "..CCCCCCCC......",
            ".CCCCCCCCCC.....",
            ".CCCCCCWkCCC....",
            ".CCCCCCCCCCCDDD.",
            ".FFCCCCCCCCDDDDN",
            ".FFFTTTTTTTTTTT.",
            "..FFTTTTTTTTTT..",
            "..FFFTTTTTTTT...",
            "...FFFTT........",
        ], ["C": C(0x1A1A24), "W": white, "k": ink, "D": C(0x3A2C24), "N": ink, "F": fur, "T": tan])
        s.px(20, 9, C(0x3A3A4A)); s.px(21, 11, C(0x3A3A4A))
        let o = Int((3 * open).rounded())
        if o > 0 {
            s.rect(26, 17, 7, o, C(0x7A1A22))
            s.pattern(21, 17 + o, ["TTTTTTTTTTT", ".TTTTTTTT..", "..TTTTT...."], ["T": tan])
            s.px(29, 17, white); s.px(31, 17, white)
        } else {
            s.rect(27, 18, 5, 1, C(0x5A3424))
        }
    }
    // Collar and the bat tag.
    c.rect(31, 28, 2, 5, C(0x3A4AA8)); c.rect(32, 32, 2, 2, C(0xF0C040))
    c.ox -= lunge
    if howl > 0.5 {
        for i in 0..<2 {
            let f: Double = frac(p.t * 1.5 + Double(i) * 0.5)
            let x = 45 + Int(f * 6), y = 14 - Int(f * 8)
            c.pattern(x, y, ["..o", ".o.", "o.."], ["o": C(0xF4F0E0, 1 - f)])
        }
    }
}

// MARK: - Streaky

/// Streaky the Supercat: Supergirl's orange tabby, darker stripes, a yellow lightning streak down his side, green
/// eyes, white whiskers and a little red cape. He flies stretched out, cape flat behind, and fights with a clawed paw
/// swipe. Signature: a ball of yarn turns up and he bats it up into the air, again and again.
private func drawStreaky(_ c: PixelCanvas, _ p: Pose) {
    let orange = C(0xF0902A), dark = C(0xC0661A), stripe = C(0xA84E10), cream = C(0xF8E0B0), yel = C(0xF8E040)
    let cape = C(0xD02828), capeDark = C(0x901818)
    let swipe: Double = p.melee.map { a in max(0, 1 - abs(a - 5) / 50) } ?? 0
    let lunge = Int((2 * swipe).rounded())
    let sig = p.signature
    c.oy += p.breathe
    c.ox += lunge
    // Cape: flat out behind in flight, draped over his back otherwise.
    if p.flying {
        for x in 6...26 {
            let k: Double = Double(26 - x) / 20
            let mid: Double = 30 + sin(p.t * 10 - k * 5) * k * 1.6
            let half: Double = 1.5 + k * 1.5
            c.rect(x, Int((mid - half).rounded()), 1, Int(2 * half) + 1, cape)
            c.px(x, Int((mid + half).rounded()), capeDark)
        }
    } else {
        let sway: Double = sin(p.t * p.capeSpeed) * 1
        for y in 28...35 {
            let k: Double = Double(y - 28) / 7
            let l = Int((30 - k * 16 + sway * k).rounded())
            c.rect(l, y, 31 - l, 1, cape)
            c.px(l, y, capeDark)
        }
    }
    // Legs: stretched fore and aft in flight.
    if p.flying {
        c.rect(32, 34, 8, 2, orange); c.rect(39, 34, 2, 2, cream)
        c.rect(8, 35, 9, 2, orange); c.rect(7, 35, 2, 2, cream)
    } else {
        for (i, lx) in [17, 21, 29, 33].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 37, 2, lifted ? 5 : 6, i % 2 == 0 ? orange : dark)
            c.rect(lx, lifted ? 41 : 42, 3, 1, cream)
        }
    }
    // Tail curling up.
    let flick: Double = sin(p.lt * 2.2)
    if p.flying {
        stick(c, 16, 33, 6, 31 + flick, orange, 1.0)
    } else {
        stick(c, 16, 33, 11, 30, orange, 1.0)
        stick(c, 11, 30, 11 + flick, 24, orange, 1.0)
        c.px(Int(11 + flick), 23, stripe)
    }
    // Body.
    c.rect(16, 31, 20, 7, orange)
    c.rect(17, 30, 17, 1, orange)
    c.rect(18, 36, 16, 2, cream)
    for x in [19, 23, 27] { c.rect(x, 31, 1, 3, stripe) }
    c.pattern(23, 33, ["....YY", "..YYY.", "YYY...", ".YY..."].map { String($0) }, ["Y": yel])
    // Head, three-quarter on.
    c.pattern(30, 21, [
        "O.........O",
        "OO.......OO",
        "OpOOOOOOOpO",
        "OOOSOSOSOOO",
        "OOOOOOOOOOO",
        "OGkOOOOOGkO",
        "OOOOOOOOOOO",
        "OOOOOnOOOOO",
        ".OOCMCMCOO.",
        "..OOOOOOO..",
    ], ["O": orange, "p": C(0xF0A0A0), "S": stripe, "G": C(0x5AC85A), "k": ink, "n": C(0xF07A90), "C": cream, "M": dark])
    if let s = sig, s > 0.3, s < 0.7 { c.px(31, 26, orange); c.px(39, 26, orange) }       // eyes narrowed on the yarn
    for y in [28, 30] { c.rect(26, y, 4, 1, C(0xFFFFFF, 0.8)); c.rect(41, y, 4, 1, C(0xFFFFFF, 0.8)) }
    // Collar knot of the cape.
    c.rect(31, 31, 9, 1, cape); c.px(35, 32, C(0xF0C040))
    // The front paw: swiping, batting yarn, or just standing.
    var paw: Double? = p.melee
    if let s = sig, s > 0.08, s < 0.92 {
        let k: Double = (s - 0.08) / 0.84
        let bounce: Double = abs(sin(k * 3 * .pi))
        let ballY = 41 - Int((bounce * 14).rounded())
        c.ellipse(45, ballY, 2, 2, C(0xE0406A)); c.px(44, ballY - 1, C(0xFF8AA8)); c.px(46, ballY + 1, C(0xA02848))
        stick(c, 47, Double(ballY) + 1, 52, 42, C(0xE0406A, 0.8), 0.3)
        paw = bounce < 0.35 ? 20 : -40
    }
    if let a = paw {
        for (i, ta) in p.trail.enumerated() { drawCatPaw(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawCatPaw(c, angle: a)
    }
    c.ox -= lunge
}

/// Streaky's front paw from the shoulder, claws out at the end.
private func drawCatPaw(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: (36.5, 33.5), angle: angle, alpha: alpha) { s in
        s.rect(19, 19, 7, 3, C(0xF0902A)); s.rect(19, 21, 7, 1, C(0xC0661A))
        s.rect(26, 19, 2, 3, C(0xF8E0B0))
        s.px(28, 18, white); s.px(28, 20, white); s.px(28, 22, white)
    }
}

// MARK: - Monkeys

private let monkeyShoulder = (x: 35.5, y: 32.5)

/// A monkey's head, front on, top-left at (x, y): fur round a pale face, big ears, eyes (squeezed shut when
/// `happy`), a little nose and a mouth (`mouth` rows open).
private func drawMonkeyHead(_ c: PixelCanvas, x: Int, y: Int, fur: Px, dark: Px, face: Px, happy: Bool = false, mouth: Int = 0) {
    c.pattern(x, y, [
        ".....FFFFFF.....",
        "...FFFFFFFFFF...",
        "..FFFFFFFFFFFF..",
        "EEFFFTTTTTTFFFEE",
        "EeFFTTTTTTTTFFeE",
        "EEFTTTTTTTTTTFEE",
        ".FFTTTTTTTTTTFF.",
        ".FFTTTTTTTTTTFF.",
        "..FTTTnTTnTTTF..",
        "..FTTTTTTTTTTF..",
        "...TTTTTTTTTT...",
        "....TTTTTTTT....",
    ], ["F": fur, "E": dark, "e": face, "T": face, "n": C(0x9A6A4A)])
    if happy {
        c.pattern(x + 4, y + 5, ["K......K.", ".K....K.K", "........."].map { String($0) }, ["K": ink])
        c.pattern(x + 4, y + 5, ["K.K..K.K", ".K....K."], ["K": ink])
    } else {
        c.rect(x + 5, y + 5, 2, 2, ink); c.rect(x + 9, y + 5, 2, 2, ink)
        c.px(x + 5, y + 5, white); c.px(x + 9, y + 5, white)
    }
    if mouth > 0 {
        c.rect(x + 5, y + 9, 6, mouth, C(0x7A2A2A)); c.rect(x + 6, y + 9, 4, 1, white)
    } else {
        c.px(x + 5, y + 9, C(0x8A5A3A)); c.rect(x + 6, y + 10, 4, 1, C(0x8A5A3A)); c.px(x + 10, y + 9, C(0x8A5A3A))
    }
}

/// Two monkey legs (walking, or folded when sitting), feet in `foot`.
private func drawMonkeyLegs(_ c: PixelCanvas, step: Int, leg: Px, foot: Px) {
    if seatedPose {
        for lx in [23, 31] { c.rect(lx - 1, 38, 5, 2, leg); c.rect(lx + 3, 38, 1, 2, foot) }
        return
    }
    for (i, lx) in [24, 31].enumerated() {
        let lifted = step >= 0 && i == step
        c.rect(lx, 37, 3, lifted ? 5 : 6, leg)
        c.rect(lx, lifted ? 41 : 42, 4, 2, foot)
    }
}

// MARK: - Gleek

/// Gleek: the Wonder Twins' blue space monkey: blue fur, a pale face and belly, big ears, a purple cape and a gold
/// belt, a long curling tail, and the bucket he carries Zan about in. He doesn't fight: he jumps about and cheers.
/// Signature: he holds the bucket up, a little water Zan rises out of it with a face and waves, then splashes back in.
private func drawGleek(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x3A7AD0), dark = C(0x2A5498), face = C(0xE8C890), cape = C(0x7A3AA8), capeDark = C(0x52247A)
    let sig = p.signature
    let lift: Double = sig.map { habitArc($0, hold: 0.7) } ?? 0
    // Cape and tail behind.
    let sway: Double = sin(p.t * p.capeSpeed)
    for y in 27...38 {
        let k: Double = Double(y - 27) / 11
        let l = Int((21 - k * 3 + sway * k).rounded()), r = Int((35 + k * 2 + sway * k).rounded())
        c.rect(l, y, r - l, 1, cape); c.px(l, y, capeDark)
    }
    let flick: Double = sin(p.lt * 2)
    stick(c, 21, 36, 13, 38, fur, 0.9)
    stick(c, 13, 38, 10, 31 + flick, fur, 0.9)
    stick(c, 10, 31 + flick, 13, 27 + flick, fur, 0.8)
    stick(c, 13, 27 + flick, 15, 29 + flick, fur, 0.7)
    drawMonkeyLegs(c, step: p.step, leg: fur, foot: dark)
    c.oy += p.breathe
    // Body: fur, pale belly, gold belt.
    c.rect(22, 27, 13, 11, fur)
    c.rect(25, 29, 7, 8, face)
    c.rect(22, 35, 13, 1, C(0xF0C040))
    c.rect(34, 27, 1, 11, dark)
    let cheer = p.cheering
    let wave = cheer && Int(p.t * 6) % 2 == 0
    drawMonkeyHead(c, x: 20, y: 16, fur: fur, dark: dark, face: face, happy: lift > 0.5 || cheer, mouth: cheer ? 2 : 0)
    // Arms; the bucket in his right hand.
    c.rect(19, wave ? 24 : 30, 3, wave ? 6 : 4, fur)
    let by = 33 - Int((10 * lift).rounded())
    c.rect(35, by - 2, 3, 5, fur)
    c.pattern(37, by - 3, [
        ".hhhhh.",
        "h.....h",
        "BBBBBBB",
        "BwBBBBB",
        ".BBBBB.",
        ".BBBBB.",
        "..BBB..",
    ], ["B": C(0x8A929E), "w": C(0xC8CED8), "h": C(0x5A606A)])
    c.rect(38, by - 1, 5, 1, C(0x4AA8E8))
    if let s = sig, s > 0.2, s < 0.85 {
        let k: Double = habitArc((s - 0.2) / 0.65, hold: 0.5)
        let h = Int((9 * k).rounded())
        let water = C(0x4AA8E8, 0.9), light = C(0xB8E4FF)
        c.rect(38, by - 1 - h, 5, h + 1, water)
        c.rect(37, by - 3 - h, 7, 3, water); c.rect(38, by - 4 - h, 5, 1, water)
        c.px(39, by - 2 - h, ink); c.px(42, by - 2 - h, ink)
        c.rect(38, by - 4 - h, 2, 1, light)
        if k > 0.8 { c.rect(44, by - 6 - h + (Int(p.t * 6) % 2), 2, 3, water) }      // a wave
    }
}

// MARK: - Beppo

/// Beppo the Super-Monkey: a brown monkey in Superman's kit: blue suit, red cape, red trunks over a yellow belt, red
/// boots and the "S" shield on his chest. He flies the Superman way, fist forward, and punches. Signature: out comes
/// a banana; he peels it and eats it in three happy bites.
private func drawBeppo(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x7A4A28), dark = C(0x5A341C), face = C(0xE0B888), blue = C(0x2A4FB0), blueDark = C(0x1C3880)
    let red = C(0xD0282A), redDark = C(0x8A1418), yel = C(0xF4D030)
    let sig = p.signature
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            for x in 3...20 {
                let k: Double = Double(20 - x) / 17
                let mid: Double = 30 + k * 3 + sin(p.t * 9 - k * 5) * k * 1.6
                let half: Double = 2.5 + k * 2
                c.rect(x, Int((mid - half).rounded()), 1, Int(2 * half) + 1, red)
                c.px(x, Int((mid - half).rounded()), redDark); c.px(x, Int((mid + half).rounded()), redDark)
            }
        } else {
            let sway: Double = sin(p.t * p.capeSpeed)
            for y in 27...41 where y + c.oy <= 43 {
                let k: Double = Double(y - 27) / 14
                let l = Int((21 - k * 4 + sway * k).rounded()), r = Int((35 + k * 3 + sway * k).rounded())
                c.rect(l, y, r - l, 1, red); c.px(l, y, redDark); c.px(r - 1, y, redDark)
            }
        }
        // Tail curling out from behind.
        stick(c, 22, 36, 15, 39, fur, 0.9)
        stick(c, 15, 39, 13, 34, fur, 0.9)
        if p.flying {
            for lx in [24, 30] { c.rect(lx, 37, 3, 5, blue); c.rect(lx, 40, 3, 2, red) }
        } else {
            drawMonkeyLegs(c, step: p.step, leg: blue, foot: red)
        }
        c.oy += p.breathe
        c.rect(22, 27, 13, 11, blue); c.rect(34, 27, 1, 11, blueDark)
        c.rect(22, 34, 13, 1, yel); c.rect(22, 35, 13, 3, red)
        c.pattern(25, 28, ["RRRRRRR", "RYYYYYR", ".RRRRR.", ".YYYYR.", "..RRR..", "...R..."], ["R": red, "Y": yel])
        let eating: Double? = sig.flatMap { $0 > 0.06 && $0 < 0.94 ? ($0 - 0.06) / 0.88 : nil }
        let chew = eating.map { $0 > 0.4 && Int($0 * 20) % 2 == 0 } ?? false
        drawMonkeyHead(c, x: 20, y: 16, fur: fur, dark: dark, face: face, happy: (eating ?? 0) > 0.75, mouth: chew ? 2 : 0)
        c.rect(19, 30, 3, 3, blue); c.rect(19, 33, 3, 2, fur)
        if p.flying {
            c.rect(35, 28, 4, 3, blue); c.rect(39, 28, 3, 3, fur)
            return
        }
        if let k = eating {
            // Banana up by the mouth, peeled, bites gone.
            c.rect(35, 27, 3, 4, blue); c.rect(35, 25, 3, 2, fur)
            let bites = k < 0.4 ? 0 : min(3, Int((k - 0.4) / 0.15) + 1)
            let rows: [String] = ["...BB", "..BWW", ".BWW.", "BWW..", "YBB..", "Y...."]
            var shown = rows
            for i in 0..<min(bites, 3) { shown[i] = "....." }
            c.pattern(36, 18, k < 0.25 ? ["...YY", "..YYY", ".YYY.", "YYY..", "YYY..", "Y...."] : shown,
                      ["Y": yel, "B": C(0xE8C030), "W": C(0xFFF4C8)])
            if k > 0.25 { c.pattern(35, 23, ["Y.Y", "Y.Y"], ["Y": yel]) }      // the peel hanging down
            return
        }
        let angle = p.melee ?? 70
        for (i, ta) in p.trail.enumerated() { drawMonkeyPunch(c, angle: ta, alpha: 0.35 / Double(i + 1)) }
        drawMonkeyPunch(c, angle: angle)
    }
}

/// Beppo's right arm from the shoulder: blue sleeve, brown fist.
private func drawMonkeyPunch(_ c: PixelCanvas, angle: Double, alpha: Double = 1) {
    prop(c, at: monkeyShoulder, angle: angle, alpha: alpha) { s in
        s.rect(19, 19, 5, 3, C(0x2A4FB0))
        s.rect(24, 18, 4, 4, C(0x7A4A28)); s.rect(27, 18, 1, 4, C(0x5A341C))
    }
}

// MARK: - Shared helpers

/// A thick line from (x0, y0) to (x1, y1), `r` pixels round: tails, arms, staffs.
private func stick(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0x000000, 0), coreR: r, glowR: r + 0.05)
}

private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A flyer's legs in the air: together, trailing behind, boots at the ends.
private func drawFlyingLegs(_ c: PixelCanvas, leg: Px, shade: Px, boot: Px) {
    for lx in [21, 31] {
        c.rect(lx, 36, 4, 6, leg); c.rect(lx + 3, 36, 1, 6, shade); c.rect(lx, 40, 4, 2, boot)
    }
}

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c`: faded to `alpha`, moved `dx`
/// pixels, washed towards `tint`'s colour by its amount, and leaning forward one pixel every `lean` rows above the
/// feet (0: upright).
private func layer(_ c: PixelCanvas, alpha: Double = 1, dx: Int = 0, lean: Int = 0, tint: (Px, Double)? = nil,
                   _ art: (PixelCanvas) -> Void) {
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
            var col = unpremultiplied(s, i)
            if let (t, k) = tint { col = mix(col, t, k) }
            c.px(x + shift + dx, y, col.alpha(alpha))
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

/// Draws `art` (pointing right from (20.5, 20.5) on a 41×41 scratch canvas) turned to `angle` degrees about `at`.
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

