import Foundation

// Villains: the Suicide Squad, the assassins and the ring-wielders. Clawd in costume, every one of them; where the
// costume shows a face it's Clawd's own orange (Killer Frost and Black Hand have gone pale for their own reasons).

let villains9: [Leader: Persona] = [
    .deadshot: Persona(name: "Deadshot", weapon: .ranged, shot: .bullet, muzzle: (47, 33), headTop: 22, signature: 2.8,
                  callout: "I don't miss.",
                  draw: drawDeadshot),
    .killerFrost: Persona(name: "Killer Frost", weapon: .ranged, shot: .ice, muzzle: (43, 34), handGun: false, headTop: 15,
                  signature: 3.0, callout: "Chill.",
                  draw: drawKillerFrost),
    .amandaWaller: Persona(name: "Amanda Waller", weapon: .none, headTop: 21, signature: 3.2,
                  callout: "Don't make me push the button.",
                  draw: drawAmandaWaller),
    .enchantress: Persona(name: "Enchantress", weapon: .magic, motion: .hover, magic: Magic(core: C(0xF0FFE0), glow: C(0x6AE83A)),
                  headTop: 19, signature: 3.0,
                  draw: drawEnchantress),
    .copperhead: Persona(name: "Copperhead", weapon: .melee, headTop: 18, signature: 2.8,
                  draw: drawCopperhead),
    .cheshire: Persona(name: "Cheshire", weapon: .melee, headTop: 18, signature: 2.6,
                  draw: drawCheshire),
    .blackHand: Persona(name: "Black Hand", weapon: .magic, magic: Magic(core: C(0xF0F0F0), glow: C(0x3A2A4A), jagged: false),
                  headTop: 21, signature: 3.2, callout: "Rise.",
                  draw: drawBlackHand),
    .cyborgSuperman: Persona(name: "Cyborg Superman", weapon: .ranged, motion: .fly, shot: .beam(core: C(0xFFF4D0), glow: C(0xFF3A1E)),
                  armoured: true, muzzle: (34, 30), handGun: false, headTop: 21, signature: 3.0,
                  callout: "I am the real Superman.",
                  draw: drawCyborgSuperman),
    .leagueAssassin: Persona(name: "League Assassin", weapon: .melee, headTop: 22, signature: 2.4,
                  draw: drawLeagueAssassin),
    .kobraAgent: Persona(name: "Kobra Agent", weapon: .ranged, shot: .energy(core: C(0xF0FFD0), glow: C(0x8AE82A)),
                  muzzle: (51, 31), headTop: 20, signature: 2.8, callout: "Hail Kobra!",
                  draw: drawKobraAgent),
    .starSapphire: Persona(name: "Star Sapphire", weapon: .magic, motion: .fly, magic: Magic(core: C(0xFFE0F8), glow: C(0xFF4AC8), jagged: false),
                  headTop: 17, signature: 3.0, callout: "Love conquers all.",
                  draw: drawStarSapphire),
]

// MARK: - Shared bits

private let clear = C(0x000000, 0)

/// A solid pixel line (no glow), `r` its half-width.
private func line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

private func unit(_ degrees: Double) -> (x: Double, y: Double) {
    let r = degrees * .pi / 180
    return (cos(r), sin(r))
}

/// Boots (or shoes) on the bottom of the legs, following the walk cycle.
private func drawBoots(_ c: PixelCanvas, step: Int, _ col: Px, rows: Int = 2) {
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx + 2, 38, 1, 2, col) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// Legs held together and toes pointed, for flying: two thick legs, `boot` on the bottom rows.
private func drawFlightLegs(_ c: PixelCanvas, _ leg: Px, boot: Px, front: Px? = nil) {
    for lx in [21, 30] {
        let col = lx == 30 ? (front ?? leg) : leg
        c.rect(lx, 36, 4, 5, col)
        c.rect(lx, 40, 4, 2, boot)
        c.rect(lx + 1, 42, 2, 1, boot)
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

/// A cape hanging down his back (to the left), clear of the legs, its hem swaying.
private func drawBackCape(_ c: PixelCanvas, t: Double, speed: Double, color: Px, edge: Px) {
    for y in 27...43 where y + c.oy <= 43 {
        let k = Double(y - 27) / 16
        let sway = sin(t * speed + k * 2.2) * k * 1.4
        let l = Int((15 - k * 3 + sway).rounded()), r = 19
        c.rect(l, y, r - l + 1, 1, color)
        c.px(l, y, edge)
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
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x + shift, y, unpremultiplied(s, i))
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

/// A fast swing's smear: faint streaks along the earlier angles, `r0`…`r0 + length` out from `h`.
private func drawSmear(_ c: PixelCanvas, at h: (x: Double, y: Double), _ trail: [Double], from r0: Double = 3,
                       length: Double, _ col: Px) {
    for (i, a) in trail.enumerated() {
        let u = unit(a)
        c.glowLine(h.x + u.x * r0, h.y + u.y * r0, h.x + u.x * (r0 + length), h.y + u.y * (r0 + length),
                   core: col.alpha(0.35 / Double(i + 1)), glow: col.alpha(0.18 / Double(i + 1)), coreR: 0.6, glowR: 1.6)
    }
}

/// Spell wisps: two little glowing strands curling round a hand.
private func drawWisps(_ c: PixelCanvas, at: (x: Double, y: Double), t: Double, r: Double, core: Px, glow: Px) {
    for k in 0..<2 {
        var prev: (Double, Double)? = nil
        for i in 0...5 {
            let a: Double = t * 5 + Double(k) * .pi + Double(i) * 0.45
            let rr: Double = r * (0.6 + Double(i) * 0.12)
            let q = (at.x + cos(a) * rr, at.y + sin(a) * rr * 0.8)
            if let pv = prev {
                c.glowLine(pv.0, pv.1, q.0, q.1, core: core.alpha(0.9), glow: glow.alpha(0.8), coreR: 0.35, glowR: 1.3)
            }
            prev = q
        }
    }
}

/// A four-pointed twinkle.
private func twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px) {
    c.px(x, y, white)
    c.px(x - 1, y, col); c.px(x + 1, y, col); c.px(x, y - 1, col); c.px(x, y + 1, col)
}

// MARK: - Deadshot

/// Deadshot: Floyd Lawton as Clawd in the red bodysuit and red cowl, a silver face mask with the red targeting
/// monocle over the front eye, a silver breastplate and black belt, and the silver twin-barrelled gun on his wrist.
/// Signature: brings the wrist guns up to eye level, the monocle's scope telescopes out and a red laser sight
/// reaches across the screen and settles on you.
private func drawDeadshot(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xB8202A), redDark = C(0x7A141A), silver = C(0xC8CCD4), silverDark = C(0x8A8F9C)
    let black = C(0x1E1E24), lens = C(0xFF3A2A)
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, step: p.step, black, rows: 3)
    for lx in [19, 23, 31, 35] where !seatedPose { c.rect(lx, 38, 2, 1, silver) }   // knee plates
    c.oy += p.breathe
    let aim: Double = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawBody(c, Look(body: red, shade: redDark, arm: red, eye: nil))
    c.pattern(18, 22, ["...RRRRRRRRRRRRRR...", ".RRRRRRRRRRRRRRRRRR.", "RRRRRRRRRRRRRRRRRRRr",
                       "RRRRRRRRRRRRRRRRRRRr"], ["R": red, "r": redDark])
    // The silver mask, the strap of the scope across the brow, the left eye.
    c.rect(19, 27, 18, 5, silver)
    c.rect(19, 31, 18, 1, silverDark)
    c.rect(28, 28, 1, 3, silverDark)
    c.rect(19, 27, 12, 1, black)
    c.rect(19, 28, 2, 3, black)                                                  // earpiece
    c.rect(22, 28, 2, 3, ink)
    // The monocle: a black housing, a scope tube out to the front and the red lens.
    let ext = 1 + Int((4 * aim).rounded())
    c.rect(31, 27, 4, 5, black)
    c.rect(32, 28, 2, 3, lens); c.px(32, 28, C(0xFFC0B0))
    c.rect(35, 28, ext, 3, black); c.rect(35, 28, ext, 1, silverDark)
    c.rect(35 + ext, 28, 1, 3, lens)
    if aim > 0.3 && Int(p.t * 8) % 4 != 0 { c.px(35 + ext, 29, C(0xFFE0D0)) }
    // Breastplate, bandolier and belt.
    c.rect(18, 32, 20, 1, redDark)
    c.rect(20, 33, 16, 3, silver); c.rect(20, 35, 16, 1, silverDark)
    c.rect(27, 33, 2, 2, silverDark)
    c.pattern(21, 33, ["B....", ".B...", "..B.."], ["B": black])
    c.rect(18, 36, 20, 1, black); c.rect(27, 36, 2, 1, silver)
    c.rect(15, 34, 3, 2, silver)                                                 // the other gauntlet
    // The laser sight, once the guns are up.
    if aim > 0.55 {
        let x0 = 36.0 + Double(ext)
        c.glowLine(x0, 29.5, 69, 29.5, core: C(0xFF3A2A, 0.55), glow: C(0xFF2A2A, 0.12), coreR: 0.3, glowR: 0.9)
        c.glowLine(69, 29.5, 69, 29.5, core: C(0xFFC0B0), glow: C(0xFF2A2A), coreR: 0.5, glowR: 1.6,
                   strength: 0.7 + 0.3 * sin(p.t * 20))
    }
    // The wrist guns.
    let up = Int((3 * aim).rounded())
    c.oy += p.gunY - up
    c.rect(38, 33, 3, 3, red)
    c.rect(39, 32, 4, 4, silver); c.rect(39, 35, 4, 1, silverDark)
    c.rect(40, 31, 2, 1, silverDark)
    c.rect(43, 32, 4, 1, black); c.rect(43, 34, 4, 1, black)
    c.rect(43, 33, 3, 1, silverDark)
}

// MARK: - Killer Frost

/// Killer Frost: Caitlin Snow gone cold, a frost-blue Clawd with long white hair, a crown of icicles, pale glowing
/// eyes and blue lips, in a deep-blue suit with an icy V and white ice boots; frost gathers in her bare hand when she
/// shoots. Signature: both hands go up, snow falls round her and three ice spikes burst out of the ground in front.
private func drawKillerFrost(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8CC6EC), skinShade = C(0x5E9CCC), suit = C(0x2E5E96), suitDark = C(0x1E4070), ice = C(0xD8F6FF)
    let hair = C(0xF4FAFF), hairDark = C(0xA8C8E4), lips = C(0x1E3E8A), frostGlow = C(0x7FD8FF)
    let frost: Double = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    if frost > 0.02 {
        // Ice spikes out of the ground, in front of her.
        let spikes: [(Double, Double)] = [(46, 8), (51, 12), (57, 7)]
        for (x, h0) in spikes {
            let h = h0 * frost
            guard h >= 1 else { continue }
            let apex = 43.5 - h
            for y in Int(apex)...43 {
                let hw = max(0.5, (Double(y) - apex) / h * 2.2)
                let l = Int((x - hw).rounded()), r = Int((x + hw).rounded())
                c.rect(l, y, max(1, r - l), 1, C(0x9ADCF8, 0.9))
                c.px(l, y, ice); c.px(max(l, r - 1), y, C(0x5AA8D8))
            }
            c.px(Int(x), Int(apex), white)
        }
    }
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, step: p.step, ice, rows: 3)
    c.oy += p.breathe
    let up = frost > 0.05 ? 4 : 0
    drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil), armLeft: up, armRight: max(p.armRaise, up))
    c.pattern(16, 20, [
        "......HHHHHHHHHHH.......",
        "....HHHHHHHHHHHHHHHH....",
        "...HHHHhHHHHHHHhHHHHH...",
        "..HHHHHHhHHHHHHHhHHHHH..",
        "..HHHHHHHhhHHHHHHhHHHHh.",
        ".hHHHHHHhh......hhHHHHh.",
        ".hHHHhh...........hHHHh.",
        ".hHHh..............hHHh.",
        ".hHh................hHh.",
        ".hHh................hHh.",
        ".hHh................hHh.",
        "hHHh................hHHh",
        "hHh..................hHh",
        "hh....................hh",
    ], ["H": hair, "h": hairDark])
    c.pattern(19, 14, [                                                          // the icicle crown
        "....I.....I.....I.",
        "....I....III....I.",
        ".I..I....III...II.",
        ".II.II..IIIII..II.",
        "..iIIIi.iIIIi.iIi.",
    ], ["I": ice, "i": C(0x5AB8E8)])
    for ex in [22, 32] {
        c.rect(ex, 29, 2, 3, C(0x16285A)); c.px(ex, 29, C(0xE8FCFF))
    }
    c.rect(27, 32, 3, 1, lips)
    c.rect(18, 33, 20, 5, suit)
    c.pattern(24, 33, ["IIIIIIII", ".IiiiiI.", "..IiiI..", "...II..."], ["I": ice, "i": skin])
    c.rect(18, 37, 20, 1, suitDark)
    c.px(20, 35, ice); c.px(34, 35, ice); c.px(21, 36, C(0x8ACCEC))
    c.rect(15, 33 - up, 3, 3, ice)
    c.oy += p.gunY
    let hy = 33 - max(p.armRaise, up)
    c.rect(38, hy, 3, 3, ice)
    if p.fire != nil || p.ready || frost > 0.05 || p.gunLift > 0 {
        c.glowLine(41.5, Double(hy) + 1.5, 41.5, Double(hy) + 1.5, core: white, glow: frostGlow, coreR: 0.6, glowR: 2)
    }
    if frost > 0.05 {
        c.glowLine(16.5, Double(hy) + 1.5, 16.5, Double(hy) + 1.5, core: white, glow: frostGlow, coreR: 0.6, glowR: 2)
        // Snow drifting down round her, and her breath steaming.
        for k in 0..<12 {
            let f = frac(p.t * 0.45 + noise(k * 5))
            let x = 8 + noise(k * 11) * 56 + sin(p.t * 2 + Double(k)) * 1.5
            let y = 8 + f * 34
            c.px(Int(x), Int(y), white.alpha(frost * (1 - f * 0.6)))
        }
        if frost > 0.6 {
            let b = frac(p.t * 1.2)
            c.rect(31 + Int(b * 6), 31 - Int(b * 2), 2, 1, white.alpha((1 - b) * 0.7))
        }
    }
}

// MARK: - Amanda Waller

/// Amanda Waller: the Wall herself, Clawd with close-cropped black hair, heavy brows over a flat, unimpressed stare,
/// a navy skirt suit with a white blouse and pearls, a dossier under her hand. Working, she taps away at a tablet.
/// Signature: checks the Squad on her tablet, puts it away and holds up the detonator, thumb over the button.
private func drawAmandaWaller(_ c: PixelCanvas, _ p: Pose) {
    let navy = C(0x26324E), navyDark = C(0x18203A), shirt = C(0xF2EFE8), hair = C(0x1C1618), hairLight = C(0x3A3034)
    let shoe = C(0x141418), pearl = C(0xF4F0E4), folder = C(0xD8C08A), folderDark = C(0xA8905A)
    drawLegs(c, Look(leg: navy), step: p.step)
    drawBoots(c, step: p.step, shoe, rows: 1)
    c.oy += p.breathe
    let s = p.signature
    let tablet = (p.mode == .working && !p.walking) || p.ready || (s.map { $0 > 0.08 && $0 < 0.5 } ?? false)
    let detonator = s.map { $0 > 0.56 && $0 < 0.94 } ?? false
    let raised = tablet || detonator
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: navy, eye: nil), armRight: raised ? 3 : 0)
    c.pattern(17, 21, [
        ".....HHHHHHHHHHHH.....",
        "...HHHHHHHhHHHHHHHH...",
        "..HHHhHHHHHHHHHHhHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHH..............HHH.",
        ".HH................HH.",
        ".H..................H.",
    ], ["H": hair, "h": hairLight])
    // The stare: heavy brows pressed down, narrowed eyes, a flat mouth.
    c.rect(21, 28, 4, 1, hair); c.px(24, 29, hair)
    c.rect(31, 28, 4, 1, hair); c.px(31, 29, hair)
    let blink = !p.walking && frac(p.lt / 5.3) < 0.025
    c.rect(22, blink ? 31 : 30, 2, blink ? 1 : 2, ink); c.rect(32, blink ? 31 : 30, 2, blink ? 1 : 2, ink)
    c.rect(26, 32, 4, 1, C(0x8A3A28))
    // Suit, blouse and pearls.
    c.rect(18, 33, 20, 5, navy)
    c.pattern(24, 33, ["WWWWWWWW", ".WWWWWW.", "..WWWW..", "...WW..."], ["W": shirt])
    c.pattern(23, 33, ["L........L", ".L......L.", "..L....L..", "...L..L..."], ["L": navyDark])
    for x in stride(from: 24, through: 31, by: 2) { c.px(x, 33, pearl) }
    c.px(28, 36, C(0xC8A040))
    c.rect(18, 37, 20, 1, navyDark)
    c.rect(15, 35, 3, 1, clawdOrange)
    if detonator, let s = s {
        // The detonator: a black box with a red button, her thumb hovering over it.
        let flash = Int(p.t * 6) % 2 == 0
        c.rect(38, 30, 3, 3, navy)
        c.rect(40, 26, 4, 5, C(0x1E1E24)); c.rect(40, 30, 4, 1, C(0x3A3A44))
        c.rect(41, 25, 2, 1, flash ? C(0xFF2A2A) : C(0xA81818))
        if flash { c.glowLine(41.5, 24.5, 42.5, 24.5, core: C(0xFF6A5A), glow: C(0xFF2A2A), coreR: 0.4, glowR: 1.4) }
        let press = s > 0.75 ? 1 : 0
        c.rect(41, 23 + press, 2, 1, clawdOrange)                                // thumb
        c.rect(44, 27, 1, 3, C(0x5A5A66)); c.px(44, 26, C(0x9A9AA4))              // antenna stub
    } else if tablet {
        // Tablet held up in front, its light on her face, a finger tapping.
        c.rect(38, 30, 3, 3, navy)
        c.rect(39, 25, 6, 8, C(0x1A1A20))
        c.rect(40, 26, 4, 6, C(0x4A9AE0))
        c.rect(40, 26, 4, 1, C(0x8AD0FF))
        for k in 0..<3 { c.rect(40, 28 + k, 2 + Int(noise(k + 3) * 2), 1, C(0xC8E8FF)) }
        if s != nil && Int(p.t * 4) % 2 == 0 { c.px(43, 29, C(0xFF3A2A)) }      // somebody's implant, blinking
        c.rect(36, 28, 2, 4, C(0x8AD0FF, 0.22))
        let tap = Int(p.t * 5) % 3
        c.px(41 + tap, 31 - (tap == 1 ? 1 : 0), clawdOrange)
    } else {
        // The dossier, held at her side.
        c.rect(38, 33, 3, 3, navy)
        c.rect(40, 32, 2, 7, folder); c.rect(41, 32, 1, 7, folderDark)
        c.px(40, 34, C(0xC82A2A))
        c.rect(39, 34, 2, 2, clawdOrange)
    }
}

// MARK: - Enchantress

/// Enchantress: June Moone possessed, Clawd under a wild tangle of black hair with a gold circlet and green gem, a
/// green bodice with a gold girdle and a long dark-green gown that trails beneath her as she floats. Green spell
/// wisps curl round her casting hand. Signature: her hair lifts and writhes, her eyes burn green, a sigil circle
/// turns under her and sparks of green magic rise from it.
private func drawEnchantress(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E8A3E), greenDark = C(0x1C5A28), gown = C(0x1E4A26), gownEdge = C(0x3EA850), gold = C(0xD8B040)
    let hair = C(0x16121A), hairLight = C(0x2E2636)
    let magic = (core: C(0xF0FFE0), glow: C(0x6AE83A))
    let power: Double = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    if power > 0.05 {
        // The sigil circle turning under her, with runes round its rim.
        let rx = 15 * power, ry = 3 * power
        for i in 0..<28 {
            let a: Double = Double(i) / 28 * 2 * .pi + p.t * 1.5
            c.px(Int(28 + cos(a) * rx), Int(46 + sin(a) * ry), magic.glow.alpha(0.8 * power))
        }
        for i in 0..<5 {
            let a: Double = Double(i) / 5 * 2 * .pi - p.t * 2
            c.px(Int(28 + cos(a) * rx * 0.6), Int(46 + sin(a) * ry * 0.6), magic.core.alpha(power))
        }
        for k in 0..<8 {
            let f = frac(p.t * 0.8 + noise(k * 13))
            let x = 28 + (noise(k * 7) - 0.5) * 30 * power
            c.px(Int(x), Int(46 - f * 30), magic.glow.alpha(power * (1 - f)))
        }
    }
    drawCape(c, t: p.t, speed: p.capeSpeed * 0.8, color: gown, edge: gownEdge, extra: 1)
    drawLegs(c, Look(leg: C(0x141418)), step: p.step)
    c.oy += p.breathe
    let lift = power > 0.05 ? 4 : 0
    drawBody(c, Look(body: clawdOrange, arm: green, eye: nil), armLeft: lift, armRight: max(p.armRaise, lift))
    // Stray strands of the tangle, blowing about (straight up when the power's in her).
    for k in 0..<5 {
        let base: [(Double, Double)] = [(17, 22), (21, 19), (28, 18), (35, 19), (39, 23)]
        let (bx, by) = base[k]
        let side = bx < 28 ? -1.0 : (bx > 28 ? 1.0 : 0)
        let len = 3 + noise(k * 3) * 2 + power * 6
        let w = sin(p.t * 3 + Double(k) * 1.7) * (1 + power * 1.5)
        let dx = side * len * (1 - power * 0.8), dy = -len * (0.5 + power * 0.5)
        let m1 = (bx + dx * 0.4 + w * 0.6, by + dy * 0.4), m2 = (bx + dx * 0.75 - w * 0.6, by + dy * 0.75)
        line(c, bx, by, m1.0, m1.1, hair, 1)
        line(c, m1.0, m1.1, m2.0, m2.1, hair, 0.8)
        line(c, m2.0, m2.1, bx + dx + w * 0.4, by + dy, hairLight, 0.6)
    }
    c.pattern(16, 19, [
        "...H..HHHHHHHHHHH..H....",
        "..HH.HHHHHHHHHHHHHHH.HH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHhHHHHHHHHHHhHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHhhHHhHHHHhHHhhHHHHH",
        "HHHH................HHHH",
        "HHHh................hHHH",
        ".HHH................HHH.",
        "HHH..................HHH",
        "HHHh................hHH.",
        ".HHH................HHH.",
        "HHH.................HHHH",
        "HHh..................HH.",
        "HH....................HH",
        "H.H..................H.H",
        "H....................H..",
    ], ["H": hair, "h": hairLight])
    c.rect(20, 23, 16, 1, gold)                                                 // circlet and gem
    c.rect(27, 22, 2, 2, C(0x6AE83A)); c.px(27, 22, C(0xD0FFC0))
    if power > 0.3 {
        for ex in [22, 32] {
            c.glowLine(Double(ex) + 1, 30.5, Double(ex) + 1, 30.5, core: magic.core, glow: magic.glow, coreR: 0.9, glowR: 2.2)
        }
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    c.rect(26, 32, 3, 1, C(0x2A5A2E))                                           // dark green lips
    c.rect(18, 33, 20, 5, green)
    c.pattern(23, 33, ["G..........G", ".G........G.", "..GGGGGGGG.."], ["G": greenDark])
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 2, C(0x6AE83A))
    if power > 0.05 {
        drawWisps(c, at: (16.5, 34.5 - Double(lift)), t: p.t, r: 3, core: magic.core, glow: magic.glow)
        drawWisps(c, at: (39.5, 34.5 - Double(lift)), t: p.t + 1, r: 3, core: magic.core, glow: magic.glow)
    } else if p.zap != nil {
        drawWisps(c, at: (Sprite.hand.x, Sprite.hand.y - Double(p.armRaise)), t: p.t, r: 3, core: magic.core, glow: magic.glow)
    }
}

// MARK: - Copperhead

/// Copperhead: the snake suit, a copper-scaled Clawd whose hood is a snake's head (yellow eyes on top, fangs hanging
/// over his face), a pale belly and a long scaly tail dragging behind. He fights with a snake-headed gauntlet that
/// strikes on a coiled arm. Signature: the tail rears up behind him and quivers, and a forked tongue flicks out.
private func drawCopperhead(_ c: PixelCanvas, _ p: Pose) {
    let copper = C(0xC0703A), copperDark = C(0x8A4A22), scale = C(0xA05A2C), belly = C(0xE8C26A), eye = C(0xFFE040)
    let fang = C(0xF4F0E4)
    let rise: Double = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    // The tail: lying along the ground behind, or reared up in an S.
    var pts: [(Double, Double)] = []
    for i in 0...14 {
        let k = Double(i)
        let gx = 18 - k * 0.95, gy = min(seatedPose ? 38.5 : 42.5, 37 + k * 0.9) - (i > 11 ? Double(i - 11) * 0.8 : 0)
        let rx = 17 - k * 0.7 + sin(k * 0.5) * 2.5, ry = 37 - k * 1.3
        var x = gx + (rx - gx) * rise, y = gy + (ry - gy) * rise
        let sway: Double = sin(p.t * 2.5 - k * 0.5) * k / 14 * (1 - rise)
        y += sway
        if rise > 0.5, i > 9 { x += sin(p.t * 40 + k) * 0.6 * rise }
        pts.append((x, y))
    }
    for i in 0..<(pts.count - 1) {
        let r = max(0.45, 1.5 - Double(i) * 0.075)
        line(c, pts[i].0, pts[i].1, pts[i + 1].0, pts[i + 1].1, i % 3 == 1 ? copperDark : copper, r)
    }

    drawLegs(c, Look(leg: copper), step: p.step)
    drawBoots(c, step: p.step, copperDark, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: copper, shade: copperDark, arm: copper, eye: nil))
    for y in stride(from: 33, through: 36, by: 2) {
        for x in stride(from: 19 + (y / 2) % 2 * 1, to: 37, by: 3) { c.px(x, y, scale) }
    }
    c.rect(25, 33, 6, 4, belly)
    c.rect(25, 34, 6, 1, C(0xC8A04A)); c.rect(25, 36, 6, 1, C(0xC8A04A))
    // The snake's-head hood, its jaw open round his face.
    c.pattern(16, 19, [
        "......CCCCCCCCCCC.........",
        "....CCCdCCCCdCCCCCC.......",
        "..CCCCdddCCdddCCCCCCCC....",
        ".CCCCCCdCCCCdCCCCCYYCCCC..",
        "CCCCCCCCCCCCCCCCCCKYCCCCCC",
        "CCCdCCCCdCCCCdCCCCCCCCCCNC",
        "CCdddCCdddCCdddCCCCCCCCCCC",
        "dbbbbbbbbbbbbbbbbbbbbbbbbb",
        "CC........................",
        "CC........................",
        "Cd........................",
    ], ["C": copper, "d": copperDark, "b": belly, "Y": eye, "K": ink, "N": ink])
    c.rect(19, 27, 18, 5, clawdOrange)
    c.rect(19, 27, 18, 1, clawdShade)
    c.rect(22, 28, 2, 3, ink); c.rect(32, 28, 2, 3, ink)
    c.px(35, 27, fang); c.px(35, 28, fang); c.px(39, 27, fang); c.px(39, 28, fang); c.px(40, 27, fang)
    c.rect(18, 32, 20, 1, copperDark)
    if let s = p.signature, s > 0.2, s < 0.85, sin(s * 40) > -0.2 {
        // A forked tongue flicking from the snout.
        let tongue = C(0xD0203A)
        c.rect(42, 26, 3, 1, tongue); c.px(45, 25, tongue); c.px(45, 27, tongue)
    }
    c.rect(15, 33, 3, 3, copper)
    if let a = p.melee {
        drawSmear(c, at: Sprite.hand, p.trail, length: 11, belly)
        prop(c, at: Sprite.hand, angle: a) { s in
            for k in 0..<6 { s.rect(16 + k, 19 + (k % 2 == 0 ? 0 : 0), 1, 3, k % 2 == 0 ? copper : copperDark) }
            s.pattern(22, 17, [
                "CCCC..",
                "CYCCCC",
                "CCCCCF",
                "CK....",
                "CCCCF.",
            ], ["C": copper, "Y": eye, "K": C(0x7A1A2A), "F": fang])
        }
    } else {
        c.rect(38, 33, 4, 3, copper); c.px(39, 33, eye); c.px(41, 35, fang); c.rect(38, 35, 3, 1, copperDark)
    }
}

// MARK: - Cheshire

/// Cheshire: Jade Nguyen, long black hair, a pale cat mask with slanted eye slits, little ears and the huge toothy
/// grin, a green outfit with a black sash, and long claws tipped with green poison. Signature: raises her claws to
/// admire them, and a drop of poison gathers on a tip, falls and hisses on the ground.
private func drawCheshire(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x2E8A4A), greenDark = C(0x1E5E32), black = C(0x16141A), hair = C(0x18141C), hairLight = C(0x342A3A)
    let mask = C(0xF2ECE0), maskShade = C(0xC8BFAE), grin = C(0x8A1E2A), claw = C(0xC8CCD4), poison = C(0x9AFF4A)
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, step: p.step, black, rows: 3)
    c.oy += p.breathe
    let sig = p.signature
    let raise: Double = sig.map { habitArc($0, hold: 0.6) } ?? 0
    drawBody(c, Look(body: clawdOrange, arm: green, eye: nil), armRight: raise > 0.05 ? 4 : 0)
    c.pattern(16, 19, [
        ".......HHHHHHHHHH.......",
        ".....HHHHHHHHHHHHHH.....",
        "...HHHHHHHHHHHHHHHHHH...",
        "..HHHHHhHHHHHHHHHhHHHH..",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHH..............HHHH.",
        ".HHH................HHH.",
        ".HHH................HHH.",
        ".HHh................hHH.",
        ".HHH................HHH.",
        ".HHH................HHH.",
        ".HHh................hHH.",
        ".HHH................HHH.",
        ".HHH................HHH.",
        ".HHh................hHH.",
        ".HH..................HH.",
        ".H....................H.",
    ], ["H": hair, "h": hairLight])
    c.pattern(20, 18, ["E..........E", "EE........EE", "EP........PE"], ["E": mask, "P": C(0xE8A0A8)])   // ears
    c.pattern(20, 26, [
        "..MMMMMMMMMMMM..",
        ".MMMMMMMMMMMMMM.",
        "MMKKKMMMMMMKKKMM",
        "MMMKKMMMMMMKKMMM",
        "MMMMMMMMMMMMMMMM",
        "MRMMMMMMMMMMMMRM",
        "MMRTRTRTRTRTRRMM",
        ".mMRRRRRRRRRRMm.",
    ], ["M": mask, "m": maskShade, "K": ink, "R": grin, "T": white])
    c.rect(18, 34, 20, 4, green)
    c.rect(18, 35, 20, 1, black); c.rect(21, 36, 1, 2, black)
    c.pattern(25, 34, ["G....G", ".G..G."], ["G": greenDark])
    c.rect(18, 37, 20, 1, greenDark)
    if let a = p.melee {
        let tip = p.trail.isEmpty ? claw : poison
        drawSmear(c, at: Sprite.hand, p.trail, length: 7, poison)
        prop(c, at: Sprite.hand, angle: a) { s in
            s.rect(18, 19, 3, 3, green)
            for dy in [-1, 0, 1] {
                let len = dy == 0 ? 6 : 5
                for k in 0..<len { s.px(21 + k, 20 + dy * (1 + k / 3), k >= len - 1 ? poison : (k == len - 2 ? tip : claw)) }
            }
        }
    } else if raise > 0.05, let s = sig {
        // Claws up by her face; a drop of poison gathers, drops and hisses.
        prop(c, at: (40.5, 30.5), angle: -80 + 10 * sin(p.t * 3)) { s in
            s.rect(18, 19, 3, 3, green)
            for dy in [-1, 0, 1] {
                let len = Int((3 + 3 * raise).rounded())
                for k in 0..<len { s.px(21 + k, 20 + dy * (1 + k / 3), k == len - 1 ? poison : claw) }
            }
        }
        if s > 0.3 && s < 0.55 {
            let g = (s - 0.3) / 0.25
            c.px(43, 25, poison.alpha(0.5 + g * 0.5))
            if g > 0.5 { c.px(43, 26, poison) }
        } else if s >= 0.55 && s < 0.7 {
            let f = (s - 0.55) / 0.15
            let y = 26 + f * f * 17
            c.px(43, Int(y), poison); c.px(43, Int(y) - 1, poison.alpha(0.5))
        } else if s >= 0.7 && s < 0.9 {
            let f = (s - 0.7) / 0.2
            for k in 0..<3 {
                c.px(42 + k, 43 - p.breathe - Int(f * 4) - (k == 1 ? 1 : 0), poison.alpha((1 - f) * 0.8))
            }
            c.rect(41, 43 - p.breathe, 5, 1, poison.alpha((1 - f) * 0.6))
        }
    } else {
        c.rect(38, 33, 3, 3, green)
        c.px(41, 33, claw); c.px(42, 34, poison); c.px(41, 34, claw); c.px(41, 35, claw); c.px(42, 36, poison)
    }
    c.rect(15, 33, 3, 3, green); c.px(14, 35, claw)
}

// MARK: - Black Hand

/// Black Hand: William Hand risen as a Black Lantern, a corpse-pale Clawd with sunken, dark-ringed eyes and black
/// lips, slicked black hair, the black uniform with grey piping and the Black Lantern emblem on the chest, and the
/// black ring glowing on his hand. Signature: he raises a skull in his ringed hand and regards it, its eyes lighting
/// up as little black rings drift off it.
private func drawBlackHand(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xD4D6DA), skinShade = C(0xA4A6B0), black = C(0x141418), blackLight = C(0x2A2A34), gray = C(0x7A7A88)
    let bone = C(0xE8E4D8), boneDark = C(0xB0AA98), aura = C(0x6A5A8A)
    drawLegs(c, Look(leg: black), step: p.step)
    drawBoots(c, step: p.step, gray, rows: 1)
    c.oy += p.breathe
    let look: Double = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let up = look > 0.05 ? Int((5 * look).rounded()) : p.armRaise
    drawBody(c, Look(body: skin, shade: skinShade, arm: black, eye: nil), armRight: up)
    c.pattern(18, 22, ["....HHHHHHHHHHHH....", "..HHHHHHHHHHHHHHHH..", ".HHHHhhhhHHHHHHHHHH.",
                       "HHHHHHHHHHHHHHHHHHHH", "HH................HH", "H..................H"],
              ["H": black, "h": blackLight])
    for ex in [21, 31] {                                                        // the sockets
        c.rect(ex, 28, 4, 4, C(0x6A6878)); c.rect(ex + 1, 29, 2, 3, ink)
        c.px(ex + 2, 29, white)
    }
    c.rect(26, 31, 4, 1, C(0x2A2230))
    c.px(19, 30, skinShade); c.px(35, 31, skinShade)
    c.rect(18, 32, 20, 6, black)
    c.rect(18, 32, 20, 1, gray)
    c.pattern(24, 33, ["WWWWWWWW", "..WKKW..", "..WKKW..", "WWWWWWWW"], ["W": C(0xC8C8D4), "K": C(0x0A0A0E)])
    c.rect(18, 37, 20, 1, blackLight)
    c.rect(15, 33, 3, 3, black)
    // Black Lantern ooze dripping off him now and then.
    for k in 0..<3 {
        let f = frac(p.t * 0.6 + Double(k) / 3)
        c.px(19 + k * 7, 38 + Int(f * 5), aura.alpha(0.6 * (1 - f)))
    }
    let hx = 39.5, hy = 34.5 - Double(up)
    c.rect(38, 33 - up, 3, 3, black)
    let pulse = 0.7 + 0.3 * sin(p.t * 6)
    c.glowLine(hx + 1, hy, hx + 1, hy, core: white, glow: C(0x9A7AD8), coreR: 0.6, glowR: 2, strength: pulse)
    c.px(40, Int(hy), black)
    if look > 0.05 {
        // The skull, held up at eye level.
        let sy = Int(hy) - 6
        c.pattern(40, sy, [".BBBBB.", "BBBBBBB", "BKKBKKB", "BBBdBBB", ".BdBdB.", "..BBB.."],
                  ["B": bone, "K": ink, "d": boneDark])
        if look > 0.5 && Int(p.t * 5) % 3 != 0 {
            for ex in [41, 44] {
                c.glowLine(Double(ex) + 1, Double(sy) + 2.5, Double(ex) + 1, Double(sy) + 2.5, core: white, glow: aura,
                           coreR: 0.5, glowR: 1.4)
            }
        }
        for k in 0..<3 {
            let f = frac(p.t * 0.5 + Double(k) / 3)
            let x = 43 + Int(sin(p.t * 2 + Double(k) * 2) * 3), y = sy - 2 - Int(f * 14)
            let col = black.alpha(look * (1 - f)), rim = gray.alpha(look * (1 - f))
            c.rect(x - 1, y - 1, 3, 3, col); c.px(x, y, clear); c.px(x - 1, y - 1, rim)
        }
    }
}

// MARK: - Cyborg Superman

/// Cyborg Superman: Hank Henshaw in Superman's blue suit, red cape and boots and the S-shield, but half of him is
/// machine, the front of his face and skull steel with a glowing red eye, his chest plated and his arm a robot's.
/// Heat vision comes from the eyes. In flight he leads with the steel fist, cape streaming. Signature: his robot eye
/// whirs, a scan line runs down the steel and a red targeting reticle closes in and locks on.
private func drawCyborgSuperman(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A48A8), blueDark = C(0x1C3078), red = C(0xC8202A), redDark = C(0x7A1018), yellow = C(0xF0C830)
    let metal = C(0xA8AEB8), metalDark = C(0x6A7080), metalLight = C(0xDCE0E8), hair = C(0x16161E)
    let eyeRed = C(0xFF3A1E)
    let scan: Double = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: red, edge: redDark)
            drawFlightLegs(c, blue, boot: red, front: metal)
        } else {
            drawBackCape(c, t: p.t, speed: p.capeSpeed, color: red, edge: redDark)
            drawLegs(c, Look(leg: blue), step: p.step)
            for (i, lx) in [31, 35].enumerated() where !seatedPose {               // the machine half's legs
                let lifted = p.step >= 0 && (i * 2 + 1) % 2 == p.step
                c.rect(lx, 36, 2, lifted ? 4 : 5, metal); c.px(lx + 1, 38, metalDark)
            }
            drawBoots(c, step: p.step, red, rows: 3)
        }
        c.oy += p.breathe
        drawBody(c, Look(body: clawdOrange, arm: blue, eye: nil))
        // Steel over the front half of his face and skull, black hair on the rest, the spit curl.
        c.pattern(18, 21, [
            "...HHHHHHHMMMMMMM...",
            ".HHHHHHHHHMMMMMMMMM.",
            "HHHHHHHHHHMMMMMMMMMm",
            "HHHHHHHHHHMMMMMMMMMm",
            "HHHHHH.HHHMMMMMMMMMm",
        ], ["H": hair, "M": metal, "m": metalDark])
        c.rect(30, 22, 4, 1, metalLight)
        c.px(24, 26, hair); c.px(25, 26, hair); c.px(25, 27, hair)
        c.rect(28, 26, 10, 7, metal)
        c.rect(28, 26, 1, 7, metalDark)
        c.rect(29, 26, 8, 1, metalLight)
        c.px(30, 32, metalDark); c.px(36, 27, metalDark); c.px(36, 32, metalDark)
        c.rect(31, 28, 4, 4, metalDark)
        let hot = p.fire != nil || p.ready || scan > 0.5
        c.rect(32, 29, 2, 2, eyeRed)
        c.glowLine(33, 30, 33, 30, core: C(0xFFC0A0), glow: eyeRed, coreR: 0.5, glowR: hot ? 2 : 1.2)
        c.rect(22, 29, 2, 3, hot ? eyeRed : ink)
        if hot { c.px(22, 29, C(0xFFC0A0)) }
        if scan > 0.05, let s = p.signature {
            // A scan line down the steel, and the reticle closing in out front.
            let row = 26 + Int(frac(s * 4) * 7)
            c.rect(29, row, 8, 1, C(0xFF6A4A, 0.7))
            let r = Int((7 - 4 * scan).rounded()), cx = 48, cy = 30
            let col = (scan > 0.9 && Int(p.t * 10) % 2 == 0) ? C(0xFFE0D0) : C(0xFF3A1E, 0.85)
            for (sx, sy) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] {
                c.rect(cx + sx * r - (sx > 0 ? 1 : 0), cy + sy * r - (sy > 0 ? 0 : 0), 2, 1, col)
                c.rect(cx + sx * r, cy + sy * r - (sy > 0 ? 1 : 0), 1, 2, col)
            }
            if scan > 0.9 { c.px(cx, cy, col) }
        }
        // The suit, the shield and the plated half.
        c.rect(18, 33, 20, 5, blue)
        c.rect(32, 33, 6, 5, metal); c.rect(32, 33, 1, 5, metalDark); c.px(35, 35, metalDark)
        c.pattern(24, 32, ["YYYYYYY", "YRRRRYY", ".YRYRY.", "..YRY..", "...Y..."], ["Y": yellow, "R": red])
        c.rect(18, 37, 20, 1, red); c.rect(27, 37, 2, 1, yellow)
        c.rect(18, 33, 1, 4, blueDark)
        if p.flying {
            c.rect(38, 31, 5, 3, metal); c.rect(42, 31, 1, 3, metalDark); c.rect(38, 33, 5, 1, metalDark)
            return
        }
        c.rect(38, 33, 3, 3, metal); c.rect(38, 35, 3, 1, metalDark); c.px(40, 33, metalLight)
    }
}

// MARK: - League Assassin

/// A League of Assassins killer: Clawd in a charcoal hood and gi with the League's dark green trim, the face wrapped
/// to the eyes, a green sash with a gold clasp, and a curved sword (on its back when not in use). Signature: a
/// standing backflip, tucked tight, landing in a crouch exactly where it started.
private func drawLeagueAssassin(_ c: PixelCanvas, _ p: Pose) {
    if let s = p.signature, s > 0.12, s < 0.88, !seatedPose {
        let k = (s - 0.12) / 0.76
        let e = k * k * (3 - 2 * k)
        let scratch = PixelCanvas(c.w, c.h)
        var q = p
        q.signature = nil; q.breathe = 0; q.step = -1
        seatedPose = true                                                         // tucked: the legs fold up
        drawAssassin(scratch, q)
        seatedPose = false
        let hop = 14 * sin(k * .pi)
        let turned = scratch.rotated(-360 * e, about: (28, 33), into: c.w, c.h, at: (28, 33 - hop))
        c.paste(turned)
        if k < 0.12 || k > 0.88 {                                                // dust kicked up at take-off and landing
            let d = k < 0.12 ? k / 0.12 : (1 - k) / 0.12
            for i in 0..<4 { c.px(18 + i * 6 + Int(noise(i) * 3), 43 - Int(noise(i + 5) * 2), C(0xC8BCA8, 0.6 * (1 - d))) }
        }
        return
    }
    drawAssassin(c, p)
}

private func drawAssassin(_ c: PixelCanvas, _ p: Pose) {
    let gi = C(0x2C2C34), dark = C(0x1A1A20), green = C(0x2E6A3A), greenDark = C(0x1E4A28), gold = C(0xC8A040)
    drawLegs(c, Look(leg: gi), step: p.step)
    drawBoots(c, step: p.step, dark, rows: 2)
    c.oy += p.breathe
    if p.melee == nil {                                                          // the sword across the back
        line(c, 12.5, 21.5, 19, 28, dark, 0.8)
        c.px(17, 27, gold); c.px(18, 26, gold)
        line(c, 18.5, 27.5, 20.5, 29.5, green, 0.6)
    }
    let flap = Int(p.lt * 6) % 2
    c.pattern(13, 24 + flap, ["GG...", ".GGG.", "..GGG"], ["G": greenDark])     // hood tails
    drawBody(c, Look(body: gi, shade: dark, arm: gi, eye: nil))
    c.pattern(18, 22, ["...KKKKKKKKKKKKKK...", ".KKKKKKKKKKKKKKKKKK.", "KKKKKKKKKKKKKKKKKKKK",
                       "GGGGGGGGGGGGGGGGGGGg"], ["K": gi, "G": green, "g": greenDark])
    c.rect(19, 28, 18, 3, clawdOrange)                                           // eye slit
    c.rect(36, 28, 1, 3, clawdShade)
    c.rect(22, 28, 2, 3, ink); c.rect(32, 28, 2, 3, ink)
    c.rect(21, 28, 3, 1, dark); c.rect(31, 28, 3, 1, dark)
    c.rect(19, 31, 18, 1, dark)
    c.pattern(23, 32, ["G........G", ".G......G.", "..G....G.."], ["G": green])  // the gi's crossed collar
    c.rect(18, 35, 20, 2, green); c.rect(27, 35, 2, 2, gold)
    c.rect(20, 37, 1, 1, green)
    if let a = p.melee {
        drawSmear(c, at: Sprite.hand, p.trail, length: 15, C(0xDDE2EA))
        prop(c, at: Sprite.hand, angle: a) { s in
            s.rect(16, 20, 5, 1, green); s.px(17, 20, gold)
            s.rect(21, 18, 1, 5, gold)
            for k in 0..<15 {
                let y = 20 - Int(Double(k * k) / 60)
                s.px(22 + k, y, C(0xDDE2EA))
                if k < 13 { s.px(22 + k, y - 1, C(0xA8AEB8)) }
            }
            s.px(36, 20 - Int(196.0 / 60), white)
        }
    }
}

// MARK: - Kobra Agent

/// A soldier of the Kobra cult: green fatigues, a hood flared like a cobra's with yellow markings on its back, black
/// goggles with green lenses, the yellow coiled-snake emblem on the chest, and a rifle with a glowing green cell.
/// Signature: slings the rifle, the hood flares wide and the arm goes up with the hand cocked like a striking cobra.
private func drawKobraAgent(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x4A8A2E), greenDark = C(0x2E5E1E), hood = C(0x3A6E26), hoodDark = C(0x24481A), yellow = C(0xE8C82A)
    let black = C(0x16161A), lens = C(0x9AFF5A), gun = C(0x2A2A30)
    let flare: Double = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, step: p.step, black, rows: 3)
    c.oy += p.breathe
    if flare > 0 { line(c, 12, 37, 21, 23, gun, 0.8) }                          // rifle slung on the back
    drawBody(c, Look(body: green, shade: greenDark, arm: green, eye: nil))
    // The cobra hood: widest round the face, flaring wider still.
    let widths: [Double] = [5, 7.5, 9.5, 11, 12.5, 13.5, 14, 14, 13.5, 13, 12, 11, 10]
    for (i, base) in widths.enumerated() {
        let y = 20 + i
        let hw = base + (y >= 24 && y <= 30 ? flare * 3.5 * sin(Double(y - 23) / 8 * .pi) : 0)
        let l = Int((28 - hw).rounded()), r = Int((28 + hw).rounded())
        c.rect(l, y, r - l, 1, hood)
        c.px(l, y, hoodDark); c.px(r - 1, y, hoodDark)
        if flare > 0.3 && y >= 25 && y <= 29 {                                   // markings on the flare
            c.px(l + 1, y, yellow); c.px(r - 2, y, yellow)
        }
    }
    c.rect(20, 21, 16, 1, C(0x5A9A3A))
    c.rect(20, 27, 16, 6, greenDark)                                             // the face in the hood
    c.rect(20, 28, 16, 3, black)
    c.rect(21, 29, 4, 1, lens); c.rect(31, 29, 4, 1, lens)
    c.px(21, 29, C(0xE8FFD0)); c.px(31, 29, C(0xE8FFD0))
    c.rect(21, 31, 14, 2, green)
    c.pattern(26, 33, [".YY.", "Y..Y", ".Y..", "..YY"], ["Y": yellow])            // the coiled snake
    c.rect(18, 37, 20, 1, black); c.rect(27, 37, 2, 1, yellow)
    c.rect(15, 33, 3, 3, green)
    if flare > 0 {
        // The arm up, the hand bent forward like a cobra's head about to strike.
        let up = 10 * flare
        line(c, 39.5, 34, 40.5, 34 - up, green, 1)
        let hx = Int(40.5), hy = Int(34 - up)
        c.rect(hx - 1, hy - 2, 4, 2, black); c.px(hx + 3, hy - 1, black)
        c.px(hx + 2, hy, yellow)
        return
    }
    c.oy += p.gunY
    c.pattern(37, 30, [
        "......SS......",
        "KKKKKKKKKKKKKK",
        "KKKBBBKKKKKKK.",
        "..KK..KK......",
    ], ["K": gun, "S": C(0x6A6E78), "B": lens])
}

// MARK: - Star Sapphire

/// Star Sapphire: Carol Ferris in the pink-and-violet costume cut to a deep V, long dark hair, the violet tiara with
/// its swept-up wings and the star sapphire at its centre, and the violet ring of the Zamarons on her hand. In flight
/// she leads with the ring, hair streaming. Signature: she raises both hands and a glowing violet heart forms
/// between them, beats once and floats up in a shower of sparkles.
private func drawStarSapphire(_ c: PixelCanvas, _ p: Pose) {
    let magenta = C(0xC02A80), magentaDark = C(0x841E5A), violet = C(0x9A3AD8), violetLight = C(0xD8A0FF)
    let hair = C(0x3A2018), hairDark = C(0x24120C), gem = C(0xE070FF)
    let love = (core: C(0xFFE0F8), glow: C(0xFF4AC8))
    let heart: Double = p.signature.map { habitArc($0, hold: 0.5) } ?? 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            for k in 0..<3 {                                                     // the hair streaming back
                let y = 22 + Double(k) * 2.5
                line(c, 17, y, 9 - Double(k), y + 2 + sin(p.t * 10 + Double(k)), k == 1 ? hairDark : hair, 1)
            }
            drawFlightLegs(c, magenta, boot: violet)
            for x in [23.0, 32.0] {
                c.glowLine(x, 43, x - 4, 45, core: love.core.alpha(0.7), glow: love.glow.alpha(0.5), coreR: 0.4, glowR: 1.4)
            }
        } else {
            drawLegs(c, Look(leg: magenta), step: p.step)
            drawBoots(c, step: p.step, violet, rows: 4)
        }
        c.oy += p.breathe
        let lift = heart > 0.05 ? 3 : 0
        drawBody(c, Look(body: clawdOrange, arm: magenta, eye: nil), armLeft: lift,
                 armRight: p.flying ? 0 : max(p.armRaise, lift))
        c.pattern(16, 20, [
            "......HHHHHHHHHHHH......",
            "....HHHHHHHHHHHHHHHH....",
            "...HHHHHHHHHHHHHHHHHH...",
            "..HHHHHhHHHHHHHHhHHHHH..",
            "..HHHHHHHHHHHHHHHHHHHH..",
            ".HHHHHh..........hHHHHH.",
            ".HHHh..............hHHH.",
            ".HHH................HHH.",
            ".HHH................HHH.",
            ".HHh................hHH.",
            "HHH..................HH.",
            "HHH..................HHH",
            "HHh..................hHH",
            "HH....................HH",
            "Hh....................hH",
            "H......................H",
        ], ["H": hair, "h": hairDark])
        c.pattern(15, 16, [                                                      // the tiara and its wings
            "VV......................VV",
            ".VV....................VV.",
            "..VV........GG........VV..",
            "...VVVVVVVVvGGvVVVVVVVV...",
            "....VVVVVVVVVVVVVVVVVV....",
        ], ["V": violet, "v": violetLight, "G": gem])
        c.px(27, 18, white)
        if heart > 0.3 {
            for ex in [22, 32] { c.rect(ex, 29, 2, 3, C(0xC83AA8)); c.px(ex, 29, love.core) }
        } else {
            c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        }
        c.rect(27, 32, 2, 1, C(0xC82A6A))
        c.rect(18, 33, 20, 5, magenta)
        c.pattern(24, 33, ["OOOOOOOO", ".OOOOOO.", "..OOOO..", "...GG..."], ["O": clawdOrange, "G": gem])
        c.pattern(23, 33, ["V........V", ".V......V.", "..V....V..", "...V..V..."], ["V": violet])
        c.rect(18, 37, 20, 1, magentaDark)
        if p.flying {
            c.rect(38, 31, 4, 3, magenta)
            c.glowLine(42, 32, 42, 32, core: love.core, glow: love.glow, coreR: 0.6, glowR: 2)
            return
        }
        let hy = 34 - max(p.armRaise, lift)
        c.px(40, hy, violetLight)
        if p.zap != nil || p.ready {
            c.glowLine(40.5, Double(hy) + 0.5, 40.5, Double(hy) + 0.5, core: love.core, glow: love.glow, coreR: 0.5, glowR: 1.8)
        }
        if heart > 0.05, let s = p.signature {
            // The heart construct: forms between her hands, beats, floats up.
            let rise = s > 0.5 ? (s - 0.5) * 2 : 0
            let beat = (s > 0.38 && s < 0.48) ? 1 : 0
            let hx = 44, hy0 = 27 - Int(rise * 10) - beat
            let rows: [String] = beat == 1
                ? [".HH.HH.", "HHHHHHH", "HHHHHHH", "HHHHHHH", ".HHHHH.", "..HHH..", "...H..."]
                : [".HH.HH.", "HHHHHHH", "HHHHHHH", ".HHHHH.", "..HHH..", "...H..."]
            let a = heart * (1 - rise * 0.6)
            c.pattern(hx - 3, hy0, rows, ["H": C(0xFF5AD0).alpha(0.85 * a)])
            c.pattern(hx - 2, hy0 + 1, [".W.", "WW."], ["W": love.core.alpha(a)])
            c.glowLine(Double(hx) + 0.5, Double(hy0) + 2.5, Double(hx) + 0.5, Double(hy0) + 2.5, core: love.core.alpha(a),
                       glow: love.glow.alpha(a), coreR: 0.6, glowR: 2.2, strength: 0.4)
            for k in 0..<4 {
                let f = frac(p.t * 0.9 + Double(k) / 4)
                if Int(p.t * 8 + Double(k)) % 3 != 0 {
                    twinkle(c, hx - 6 + k * 4, hy0 + 6 - Int(f * 10), violetLight.alpha(a * (1 - f)))
                }
            }
        }
    }
}
