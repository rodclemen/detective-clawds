import Foundation

// Villains: Superman's rogues. Kryptonian criminals, a bald billionaire, a skull full of stolen cities and a few
// people who should never have been let near kryptonite.

let villains3: [Leader: Persona] = [
    .lexLuthor: Persona(name: "Lex Luthor", weapon: .ranged, motion: .fly, shot: .energy(core: C(0xF0FFF0), glow: C(0x3AE86A)),
                  armoured: true, muzzle: (44, 34), handGun: false, headTop: 24, signature: 3.0,
                  callout: "Brains beat brawn, Superman.",
                  draw: drawLexLuthor),
    .generalZod: Persona(name: "General Zod", weapon: .ranged, motion: .fly, shot: .beam(core: C(0xFFF4D0), glow: C(0xFF3A1E)),
                  muzzle: (34, 30), handGun: false, headTop: 21, signature: 3.0, callout: "Kneel before Zod!",
                  draw: drawGeneralZod),
    .ursa: Persona(name: "Ursa", weapon: .melee, motion: .fly, headTop: 21, signature: 3.0, callout: "Kneel, little man.",
                  draw: drawUrsa),
    .brainiac: Persona(name: "Brainiac", weapon: .magic, motion: .hover, magic: Magic(core: C(0xE8FFE0), glow: C(0x6AE83A), jagged: false),
                  headTop: 21, signature: 3.2, callout: "Your city will make a fine addition to my collection.",
                  draw: drawBrainiac),
    .doomsday: Persona(name: "Doomsday", weapon: .melee, armoured: true, canSit: false, pivot: doomsdayShoulder,
                  bulk: 8, headTop: 2, signature: 2.8, callout: "RRRAAARGH!",
                  draw: drawDoomsday),
    .bizarro: Persona(name: "Bizarro", weapon: .ranged, motion: .fly, shot: .ice, muzzle: (37, 32), handGun: false,
                  headTop: 22, signature: 3.2, callout: "Me am Bizarro!",
                  draw: drawBizarro),
    .metallo: Persona(name: "Metallo", weapon: .ranged, shot: .beam(core: C(0xE8FFE0), glow: C(0x3AE83A)), armoured: true,
                  muzzle: (37, 35), handGun: false, headTop: 24, signature: 2.8,
                  draw: drawMetallo),
    .parasite: Persona(name: "Parasite", weapon: .magic, magic: Magic(core: C(0xF0E0FF), glow: C(0xA84AE8), jagged: false),
                  headTop: 19, signature: 3.0, callout: "I'll take that power.",
                  draw: drawParasite),
    .toyman: Persona(name: "Toyman", weapon: .ranged, shot: .thrown(C(0xE8C83A)), muzzle: (44, 32), handGun: false,
                  headTop: 20, signature: 3.4, callout: "Let's play!",
                  draw: drawToyman),
    .mrMxyzptlk: Persona(name: "Mr. Mxyzptlk", weapon: .magic, motion: .hover, magic: Magic(core: C(0xFFF0F8), glow: C(0xFF6AD8), jagged: false),
                  headTop: 15, signature: 3.6, callout: "Hiya, Supey!",
                  draw: drawMxyzptlk),
    .livewire: Persona(name: "Livewire", weapon: .magic, motion: .fly, magic: Magic(core: C(0xF4F8FF), glow: C(0x4AB8FF)),
                  headTop: 13, signature: 2.8, callout: "Shocking, isn't it?",
                  draw: drawLivewire),
]

// MARK: - Shared bits

private let clear = C(0, 0)

/// A solid line `r` thick: arms, spikes, wires.
private func stick(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: clear, coreR: r, glowR: r + 0.1)
}

/// The point `len` pixels from `h` along `angle` degrees.
private func along(_ angle: Double, _ len: Double, from h: (x: Double, y: Double) = Sprite.hand) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * len, h.y + sin(r) * len)
}

/// A punch: the arm thrown out along `angle`, a fist on the end and faint fists where a fast swing just was.
private func drawPunch(_ c: PixelCanvas, angle: Double, trail: [Double], arm: Px, fist: Px, reach: Double = 7,
                       size: Int = 3, from h: (x: Double, y: Double) = Sprite.hand) {
    for (i, a) in trail.enumerated() {
        let e = along(a, reach, from: h)
        c.rect(Int(e.x.rounded()) - size / 2, Int(e.y.rounded()) - size / 2, size, size, fist.alpha(0.35 / Double(i + 1)))
    }
    let e = along(angle, reach, from: h)
    stick(c, h.x - 2, h.y - 0.5, e.x, e.y, arm, 1.2)
    c.rect(Int(e.x.rounded()) - size / 2, Int(e.y.rounded()) - size / 2, size, size, fist)
}

/// Boots: the bottom `rows` of each leg in `col` (not when sitting, when the legs are folded).
private func drawBoots(_ c: PixelCanvas, _ col: Px, step: Int, rows: Int) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, rows, col)
    }
}

/// A flickering jet flame pointing down from (`x`, `y`), `w` wide.
private func drawJet(_ c: PixelCanvas, x: Int, y: Int, w: Int, t: Double, seed: Int, hot: Px = C(0xFFE27A), flame: Px = C(0xFF9A2A)) {
    let len = 2 + Int(noise(Int(t * 30) + seed) * 3)
    c.rect(x, y, w, len + 1, flame.alpha(0.85))
    c.rect(x + (w > 2 ? 1 : 0), y, max(1, w - 2), len, hot)
    c.rect(x, y, w, 1, C(0xF4FCFF))
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

/// A cape seen from the front, hanging behind the shoulders: it shows past the body's edges and sways, but leaves
/// the legs in view (a full cape behind them turns a dark costume into one blob).
private func drawShoulderCape(_ c: PixelCanvas, t: Double, speed: Double, color: Px, edge: Px) {
    for y in 32...42 where y + c.oy <= 43 {
        let k = Double(y - 32) / 10
        let sway = sin(t * speed + k * 2.2) * k * 1.2
        let l = Int((15.5 - k * 3 + sway).rounded())
        c.rect(l, y, 18 - l, 1, color); c.px(l, y, edge)
        let r = Int((40 + k * 1.5 + sway).rounded())
        c.rect(38, y, r - 38, 1, color); c.px(r - 1, y, edge)
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

/// Draws `art` on a scratch canvas (same offsets as `c`) and copies it onto `c` scaled by `scale` about the canvas
/// point `about` (a swelling body, a shrinking imp).
private func scaled(_ c: PixelCanvas, _ scale: Double, about: (x: Double, y: Double), alpha: Double = 1, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    let ax = about.x + Double(ox), ay = about.y + Double(oy + by)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for y in 0..<s.h {
        for x in 0..<s.w {
            let sx = Int(floor(ax + (Double(x) + 0.5 - ax) / scale)), sy = Int(floor(ay + (Double(y) + 0.5 - ay) / scale))
            guard sx >= 0, sy >= 0, sx < s.w, sy < s.h else { continue }
            let i = (sy * s.w + sx) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x, y, unpremultiplied(s, i).alpha(alpha))
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

/// A puff of smoke at (`x`, `y`), `k` 0…1 through its life: it swells and fades.
private func puff(_ c: PixelCanvas, x: Double, y: Double, k: Double, _ col: Px) {
    guard k > 0, k < 1 else { return }
    let r = Int((1 + k * 3).rounded())
    c.circle(Int(x.rounded()), Int(y.rounded()), r, col.alpha(0.75 * (1 - k)))
    c.circle(Int(x.rounded()) - 1, Int(y.rounded()) - 1, max(0, r - 1), white.alpha(0.5 * (1 - k)))
}

// MARK: - Lex Luthor

/// Lex Luthor: a bald orange Clawd, smug as ever, in the green-and-purple warsuit: a tall purple collar, green chest
/// plate with a glowing core, green pauldrons and gauntlets, the right one a built-in energy cannon. He flies on boot jets,
/// leaning in. Signature: a slow, smug little wave, one eyebrow up, while his bald head catches the light.
private func drawLexLuthor(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3A8A3A), greenDark = C(0x266A2A), greenLight = C(0x6AC060)
    let purple = C(0x6A3A9A), purpleDark = C(0x4A2470), purpleLight = C(0x9A6AC8)
    let glow = C(0x3AE86A), core = C(0xF0FFF0), shine = C(0xF6B496)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            for lx in [21, 31] {
                c.rect(lx, 36, 4, 5, purple); c.rect(lx + 3, 36, 1, 5, purpleDark)
                c.rect(lx, 39, 4, 2, green); c.rect(lx, 39, 4, 1, greenLight)
                drawJet(c, x: lx, y: 41, w: 4, t: p.t, seed: lx, hot: C(0xE0FFE0), flame: glow)
            }
        } else {
            drawLegs(c, Look(leg: purple), step: p.step)
            drawBoots(c, green, step: p.step, rows: 3)
        }
        c.oy += p.breathe
        // The tall collar behind his head.
        c.rect(16, 27, 2, 7, purple); c.rect(38, 27, 2, 7, purpleDark)
        c.px(16, 27, purpleLight)
        drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: green, eye: nil))
        // Bald and pleased with himself: the shine, the brows, the smirk.
        c.rect(21, 26, 4, 1, shine); c.rect(20, 27, 2, 1, shine)
        let brow = k > 0.3 ? 1 : 0
        c.rect(21, 28, 4, 1, clawdShade); c.rect(31, 28 - brow, 4, 1, clawdShade)
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        c.rect(26, 32, 4, 1, clawdShade); c.px(30, 31, clawdShade)
        if k > 0.3 { c.px(31, 31, clawdShade) }
        // The warsuit's chest.
        c.pattern(18, 33, [
            "PPPPPPPPPPPPPPPPPPPP",
            "GGGGGGGgGLLGgGGGGGGg",
            "GGGGGGGgGLLGgGGGGGGg",
            "ggggggPPPPPPPPgggggg",
            "GGGGGGGGGGGGGGGGGGGg",
        ], ["P": purple, "G": green, "g": greenDark, "L": greenLight])
        c.glowLine(28, 35, 28, 35, core: core, glow: glow, coreR: 0.8, glowR: 2)
        c.rect(18, 37, 20, 1, greenDark)
        // Pauldrons and the off-hand gauntlet.
        c.pattern(13, 30, [".GGGG", "GGLGG", "ggggg"], ["G": green, "g": greenDark, "L": greenLight])
        c.rect(15, 33, 3, 3, green); c.rect(15, 35, 3, 1, greenDark)

        if p.flying {
            c.pattern(37, 30, ["GGGG.", "GGLGG", "ggggg"], ["G": green, "g": greenDark, "L": greenLight])
            c.rect(38, 32, 5, 3, green); c.rect(38, 34, 5, 1, greenDark)
            c.glowLine(43.5, 33, 43.5, 33, core: core, glow: glow, coreR: 0.6, glowR: 2)
            return
        }
        if k > 0.02, let s = p.signature {
            // The smug wave: the gauntlet raised beside his face, fingers waggling.
            let lift = Int((k * 7).rounded())
            let wag = Int((sin(s * 38) * 1.4).rounded())
            c.rect(38, 34 - lift, 3, lift + 2, green); c.rect(40, 34 - lift, 1, lift + 2, greenDark)
            c.pattern(37 + wag, 29 - lift, ["G.G.G", "GGGGG", "GLLLG", ".GGG."], ["G": green, "L": greenLight])
            if k > 0.9 && frac(s * 3) < 0.4 { twinkle(c, 20, 25, C(0xFFF4E0)) }
        } else {
            c.oy += p.gunY
            c.rect(38, 33, 5, 3, green); c.rect(38, 35, 5, 1, greenDark); c.rect(42, 33, 1, 3, purple)
            let hot = p.fire != nil || p.ready || p.gunLift > 0
            c.glowLine(43.5, 34, 43.5, 34, core: core, glow: glow, coreR: 0.5, glowR: hot ? 1.8 : 1, strength: hot ? 1 : 0.6)
        }
        c.pattern(37, 30, ["GGGG.", "GGLGG", "ggggg"], ["G": green, "g": greenDark, "L": greenLight])
    }
}

// MARK: - General Zod

/// General Zod: black Kryptonian armour with the House of Zod glyph in silver, a dark cape, swept-back black hair and
/// a full black beard round a hard scowl. His weapon is his eyes: heat vision fires from them, glowing red. Flies
/// fist first. Signature: "Kneel before Zod!": he points at the ground, eyes blazing.
private func drawGeneralZod(_ c: PixelCanvas, _ p: Pose) {
    let armour = C(0x34343F), armourDark = C(0x1E1E26), armourLight = C(0x5A5A6A), silver = C(0xB0B4C0)
    let hair = C(0x16161A), beard = C(0x2A2420), cape = C(0x1A1A22), capeEdge = C(0x0A0A10)
    let red = C(0xFF3A1E), hot = C(0xFFF4D0)
    let k = p.signature.map { habitArc($0, hold: 0.62) } ?? 0
    layer(c, lean: p.flying ? 4 : 0) { c in
        if p.flying {
            drawFlyingCape(c, t: p.t, color: cape, edge: capeEdge)
        } else {
            drawShoulderCape(c, t: p.lt, speed: p.capeSpeed, color: cape, edge: capeEdge)
        }
        drawLegs(c, Look(leg: armour), step: p.step)
        drawBoots(c, silver, step: p.step, rows: 1)
        c.oy += p.breathe
        drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: armour, eye: nil))
        // Hair swept up and back, sideburns into the beard.
        c.pattern(17, 23, [
            "....HHHHHHHHHHHHH.....",
            "..HHHHHhHHHHHHHHhHH...",
            ".HHHHHHHHhHHHHHHHHHHH.",
            ".HHHH...........HHHHH.",
            ".HH................HH.",
            ".H..................H.",
        ], ["H": hair, "h": C(0x3A3A44)])
        // The scowl and the eyes, red-hot when he's using them.
        let heat = p.fire != nil || p.ready ? 1.0 : k
        c.pattern(20, 28, ["KKKK......KKKK.", "..KK......KK..."], ["K": hair])
        let ey = 29 + (heat > 0.5 ? p.gunY : 0)
        if heat > 0.3 {
            for x in [22, 32] {
                c.glowLine(Double(x) + 1, Double(ey) + 1.5, Double(x) + 1, Double(ey) + 1.5, core: hot, glow: red, coreR: 0.8,
                           glowR: 1.6 + heat * 1.4, strength: 0.6 + 0.4 * heat)
                c.rect(x, ey, 2, 3, red); c.rect(x, ey + 1, 2, 1, hot)
            }
        } else {
            c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        }
        // The beard: moustache, cheeks and a full chin.
        c.pattern(18, 31, [
            "BB....BBBBBBBB....BB",
            "BBBBBBBMMMMMMBBBBBBB",
            ".BBBBBBBBBBBBBBBBBB.",
        ], ["B": beard, "M": C(0x5A2A1A)])
        // Armour: black plates, the glyph, silver seams.
        c.rect(18, 34, 20, 4, armour)
        c.rect(18, 34, 20, 1, armourLight)
        c.rect(37, 34, 1, 4, armourDark)
        c.pattern(25, 34, [".SSSSS.", "S..S..S", ".S.S.S.", "..SSS.."], ["S": silver])
        c.rect(18, 37, 20, 1, armourDark)
        c.rect(15, 33, 3, 3, armour); c.rect(15, 33, 3, 1, armourLight)

        if p.flying {
            c.rect(38, 31, 5, 3, armour); c.rect(38, 31, 5, 1, armourLight)
            return
        }
        if k > 0.05 {
            // Kneel: the arm thrust out and down, finger to the floor.
            let a = along(52, 3 + 7 * k, from: (39.5, 34))
            stick(c, 39, 34, a.x, a.y, armour, 1.3)
            c.rect(Int(a.x) - 1, Int(a.y) - 1, 3, 2, armourLight)
            c.px(Int(a.x) + 1, Int(a.y) + 1, clawdOrange)
            if k > 0.9 {
                let i = Int(p.t * 14)
                for n in 0..<4 {
                    let x = 48 + Int(noise(i + n) * 10), col = noise(i * 3 + n) > 0.5 ? C(0xC8BCA8) : C(0x8A7E6A)
                    c.px(x, 43 - Int(noise(i + n * 7) * 2), col)
                }
            }
        } else {
            c.rect(38, 33, 3, 3, armour); c.rect(38, 33, 3, 1, armourLight)
        }
    }
}

// MARK: - Ursa

/// Ursa: Zod's lieutenant in plain black Kryptonian armour with a silver collar and belt, a sleek black bob with its
/// fringe swept across, dark red lips. She flies and fights with her fists. Signature: she folds her arms and rises
/// off the floor, eyes glinting red, thoroughly unimpressed.
private func drawUrsa(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x22222C), suitDark = C(0x121218), suitLight = C(0x3E3E4C), silver = C(0xA8AEBC)
    let hair = C(0x16161C), hairShine = C(0x3A3A4A), lips = C(0x9A1E2E), red = C(0xFF3A2A)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let rise = Int((k * 4).rounded())
    c.oy -= rise
    layer(c, lean: p.flying ? 4 : 0) { c in
        drawLegs(c, Look(leg: suit), step: rise > 0 ? -1 : p.step)
        drawBoots(c, suitLight, step: rise > 0 ? -1 : p.step, rows: 2)
        if rise > 1 && !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx + 1, 43, suitDark) } }   // toes pointed
        c.oy += p.breathe
        // The back of the bob, behind the face.
        c.rect(17, 26, 2, 7, hair); c.rect(37, 26, 2, 7, hair)
        drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: suit, eye: nil))
        c.pattern(16, 23, [
            "......HHHHHHHHHHH.......",
            "....HHHHHHHhhHHHHHH.....",
            "..HHHHHHHhhHHHHHHHHHH...",
            "..HHHHHHHHHHHHHHHHHHHH..",
            ".HHHHHHHHHHHHHH.....HH..",
            ".HHHHHHHH...........HH..",
            ".HHH................HH..",
            ".HHH................HH..",
            ".HHH................HH..",
            ".HH..................H..",
        ], ["H": hair, "h": hairShine])
        // Eyes (red when she means it), and the lips.
        if k > 0.5 {
            for x in [22, 32] {
                c.glowLine(Double(x) + 1, 30.5, Double(x) + 1, 30.5, core: C(0xFFE0D0), glow: red, coreR: 0.6, glowR: 1.8, strength: 0.8)
                c.rect(x, 30, 2, 2, red)
            }
        } else {
            c.rect(22, 30, 2, 2, ink); c.rect(32, 30, 2, 2, ink)
            c.px(24, 29, ink); c.px(34, 29, ink)                     // the lashes flick out
        }
        c.rect(26, 32, 4, 1, lips)
        // The suit: silver collar, belt.
        c.rect(18, 33, 20, 5, suit)
        c.pattern(18, 33, ["SSSSSS........SSSSSS", "..SSSSSS....SSSSSS..", "......SSSSSSSS......"], ["S": silver])
        c.rect(18, 36, 20, 1, silver)
        c.rect(37, 33, 1, 5, suitDark)
        c.rect(18, 37, 20, 1, suitDark)

        if rise > 0 || k > 0.05 {
            // Arms folded across her chest.
            c.rect(15, 33, 24, 3, suitLight)
            c.rect(15, 35, 24, 1, suitDark)
            stick(c, 18, 35, 26, 33, suit, 0.6)
            c.rect(27, 33, 3, 2, clawdOrange); c.rect(16, 33, 2, 2, clawdOrange)
            return
        }
        c.rect(15, 33, 3, 3, suit)
        if p.flying {
            c.rect(38, 31, 4, 3, suit); c.rect(42, 31, 2, 3, suitLight)
            return
        }
        if let a = p.melee {
            drawPunch(c, angle: a, trail: p.trail, arm: suit, fist: suitLight)
        } else {
            c.rect(38, 33, 3, 3, suit)
        }
    }
}

// MARK: - Brainiac

/// Brainiac: a green-skinned Clawd in a purple bodysuit with a white collar and circuit lines, three silver ports on
/// his bald skull wired together, glowing green. He hovers, and casts a green beam from his raised hand.
/// Signature: the skull ports light up one after another and he holds up a bottled city, tiny towers and all.
private func drawBrainiac(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x6AB04A), skinDark = C(0x4A8A32), skinLight = C(0x9AD07A)
    let suit = C(0x5A2A8A), suitDark = C(0x3E1C62), suitLight = C(0x8A5ABA), collar = C(0xE8E4F0)
    let silver = C(0xB8BEC8), silverDark = C(0x7A808C), glow = C(0x6AE83A), core = C(0xE8FFE0)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, suitDark, step: p.step, rows: 2)
    c.oy += p.breathe
    // The wires between the ports, then the ports on top of his skull.
    let ports: [(Int, Int)] = [(19, 23), (26, 21), (33, 23)]
    stick(c, 21, 25, 28, 23, silverDark, 0.5); stick(c, 28, 23, 35, 25, silverDark, 0.5)
    drawBody(c, Look(body: skin, shade: skinDark, arm: suit, eye: nil), armRight: p.armRaise)
    for (n, (x, y)) in ports.enumerated() {
        c.rect(x, y, 4, 26 - y + 1, silver); c.rect(x + 3, y, 1, 26 - y + 1, silverDark)
        var lit = p.zap != nil
        if let s = p.signature { lit = s > 0.12 + Double(n) * 0.1 && s < 0.92 }
        if lit {
            c.glowLine(Double(x) + 1.5, Double(y) + 1.5, Double(x) + 1.5, Double(y) + 1.5, core: core, glow: glow, coreR: 0.6, glowR: 2.2)
        } else {
            c.rect(x + 1, y + 1, 2, 1, C(0x2A5A1E))
        }
    }
    c.rect(20, 27, 3, 1, skinLight)
    // A heavy brow, cold eyes, thin mouth.
    c.rect(21, 28, 4, 1, skinDark); c.rect(31, 28, 4, 1, skinDark)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(23, 29, white); c.px(33, 29, white)
    c.rect(26, 32, 5, 1, skinDark)
    // Suit, collar, the circuit lines.
    c.rect(18, 33, 20, 5, suit)
    c.rect(37, 33, 1, 5, suitDark)
    c.pattern(18, 33, ["CCCC....CCCC....CCCC", "..CCCCCC....CCCCCC.."], ["C": collar])
    c.pattern(20, 35, ["L..LLLL.....LLLL..L", "LLLL..L.....L..LLLL"], ["L": suitLight])
    c.rect(18, 37, 20, 1, suitDark)
    c.rect(15, 33, 3, 3, suit)
    c.rect(15, 35, 3, 1, skin)

    // The casting hand (a green glove of skin poking from the sleeve).
    let hy = 33 - p.armRaise
    c.rect(38, hy, 3, 3, suit); c.rect(39, hy, 2, 1, skin)
    if k > 0.05 {
        // The bottled city, held up high.
        let lift = Int((k * 11).rounded())
        let by = 33 - lift
        c.rect(38, by, 3, lift + 2, suit)
        c.rect(38, by, 3, 2, skin)
        let bx = 37, top = by - 10
        c.pattern(bx, top, [
            "..cc..",
            ".gGGg.",
            ".g..g.",
            "g....g",
            "g.T..g",
            "gTTT.g",
            "gTTTTg",
            "gTTTTg",
            ".gggg.",
        ], ["c": C(0x8A5A2A), "g": C(0xC8F0FF, 0.85), "G": C(0xE8FAFF), "T": C(0xE8C860)])
        c.rect(bx + 1, top + 3, 4, 5, C(0xA8E8FF, 0.25))
        if k > 0.9 {
            let i = Int(p.t * 10)
            c.px(bx + 2 + i % 2, top + 5, C(0xFFFFFF))                   // a light on in Kandor
            c.glowLine(Double(bx) + 3, Double(top) + 5, Double(bx) + 3, Double(top) + 5, core: clear, glow: C(0xA8E8FF),
                       coreR: 0, glowR: 5, strength: 0.4)
        }
    }
}

// MARK: - Doomsday

/// Doomsday's shoulder: his spiked arm swings from here.
private let doomsdayShoulder = (x: 40.0, y: 19.0)

/// Doomsday: a towering grey brute studded with bone spikes (shoulders, forearms, knuckles, knees and brow), a
/// shock of white hair, burning red eyes, a mouthful of jagged teeth, and the tattered green remains of his
/// containment suit. Signature: he roars and every spike bristles out longer.
private func drawDoomsday(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8A8C86), dark = C(0x5E605A), light = C(0xB0B2AA), bone = C(0xEAE4D2), boneShade = C(0xB8B0A0)
    let suit = C(0x2E5A3A), suitDark = C(0x1E3E28), hair = C(0xECECEC), hairShade = C(0xB8BCC4), red = C(0xFF4A2A)
    let roar = p.signature.map { habitArc($0, hold: 0.55) } ?? 0
    let grow = 1 + roar * 0.8
    func spike(_ x: Double, _ y: Double, _ angle: Double, _ len: Double) {
        let e = along(angle, len * grow, from: (x, y))
        c.glowLine(x, y, e.x, e.y, core: bone, glow: clear, coreR: 1.1, glowR: 1.2)
        let m = along(angle, len * grow * 0.55, from: (x, y))
        c.glowLine(x, y, m.x, m.y, core: boneShade, glow: clear, coreR: 1.3, glowR: 1.4)
        c.px(Int(e.x), Int(e.y), bone)
    }
    // Legs: thick, with bony knees and tattered suit.
    for (i, lx) in [18, 31].enumerated() {
        let up = p.step >= 0 && i == p.step ? 1 : 0
        if seatedPose { c.rect(lx - 1, 38, 9, 2, skin); continue }
        c.rect(lx, 30, 8, 13 - up, skin); c.rect(lx + 7, 30, 1, 13 - up, dark)
        c.rect(lx, 30, 8, 5, suit); c.rect(lx + 2, 35, 3, 1, suit); c.px(lx + 6, 35, suitDark)
        c.rect(lx - 1, 41 - up, 10, 2, dark)
        for n in 0..<3 { c.px(lx - 1 + n * 4, 43 - up, bone) }
        spike(Double(lx) + 7, 37 - Double(up), -20, 3)
    }
    c.oy += p.breathe
    // The far arm, hanging behind.
    c.rect(10, 18, 6, 13, dark); c.rect(9, 30, 7, 5, dark)
    for n in 0..<3 { c.px(9 + n * 2, 35, bone) }
    spike(10, 24, -160, 4)
    // Spikes off his back.
    for (n, y) in [16.0, 21, 26].enumerated() { spike(15, y, -150 + Double(n) * 12, 5) }
    // The torso.
    c.rect(15, 12, 26, 20, skin)
    c.rect(15, 12, 2, 20, dark); c.rect(40, 12, 1, 20, dark)
    c.rect(22, 16, 8, 1, light); c.rect(31, 16, 8, 1, light)            // the pecs
    c.rect(26, 19, 1, 8, dark)
    for y in [21, 24, 27] { c.rect(23, y, 7, 1, dark); c.rect(31, y, 7, 1, dark) }
    for (x, y) in [(19, 15), (34, 22), (20, 25), (36, 14)] { c.rect(x, y, 2, 1, dark) }
    // The ragged green suit, round his middle.
    c.rect(15, 28, 26, 5, suit); c.rect(15, 28, 26, 1, suitDark)
    for x in stride(from: 15, to: 41, by: 3) { c.px(x, 33, suit); c.px(x + 1, 27, suit) }
    spike(36, 13, -60, 5); spike(30, 12, -80, 4)                       // shoulder spikes
    // The head, thrown back as he roars.
    c.oy -= Int((roar * 2).rounded())
    c.pattern(18, 0, [
        "...hh.hHH.hh.........",
        ".hHHHHHHHHHHHHh......",
        "hHHHHHHHHHHHHHHHh....",
        "HHHHHHHHHHHHHHHHHHh..",
        "HHHHSSSSSSSSSSSSSSSH.",
        "HHHSSSSSSSSSSSSSSSSS.",
        "HHHSSDDDDDSSSDDDDDSS.",
        "HHSSSSSSSSSSSSSSSSSSS",
        "HHSSSSSSSSSSSSSSSSSSS",
        ".HSSSSSSSSSSSSSSSSSSS",
        ".HSSSSSSSSSSSSSSSSSSS",
        "..SSSSSSSSSSSSSSSSSS.",
        "...SSSSSSSSSSSSSSSS..",
        ".....SSSSSSSSSSSS....",
    ], ["H": hair, "h": hairShade, "S": skin, "D": dark])
    // Hair streaming down his back.
    c.rect(16, 4, 3, 12, hair); c.rect(15, 8, 2, 10, hairShade)
    // Brow spikes and the red eyes under them.
    spike(25, 5, -110, 3); spike(33, 5, -70, 3); spike(38, 9, -10, 3)
    for x in [24, 32] {
        c.glowLine(Double(x) + 1, 8, Double(x) + 1, 8, core: C(0xFFE0D0), glow: red, coreR: 0.6, glowR: 1.6 + roar, strength: 0.8)
        c.rect(x, 7, 3, 2, red)
    }
    let gape = Int((roar * 4).rounded())
    c.rect(24, 10, 13, 2 + gape, C(0x3A0E10))
    for n in 0..<6 { c.px(24 + n * 2, 10, bone); c.px(25 + n * 2, 11 + gape, bone) }
    if roar > 0.9, let s = p.signature {
        for i in 0..<3 {
            let f = frac(s * 4 + Double(i) / 3), x = 42 + Int(f * 14), col = C(0xF4EEE0).alpha(0.8 * (1 - f))
            for dy in -2 - i...(2 + i) where abs(dy) > 0 || i == 0 { c.px(x - abs(dy) / 2, 11 + dy, col) }
        }
    }
    c.oy += Int((roar * 2).rounded())
    // The spiked arm and fist.
    let angle = p.melee ?? 80
    for (i, a) in p.trail.enumerated() {
        let e = along(a, 18, from: doomsdayShoulder)
        c.glowLine(doomsdayShoulder.x, doomsdayShoulder.y, e.x, e.y, core: C(0xE0E0D8), glow: C(0xE0E0D8),
                   coreR: 0.6, glowR: 2, strength: 0.35 / Double(i + 1))
    }
    c.circle(40, 18, 3, skin)
    let e = along(angle, 13, from: doomsdayShoulder)
    stick(c, doomsdayShoulder.x, doomsdayShoulder.y, e.x, e.y, skin, 2.4)
    let mid = along(angle, 8, from: doomsdayShoulder)
    spike(mid.x, mid.y, angle - 120, 4)                                 // the forearm spike
    c.rect(Int(e.x) - 3, Int(e.y) - 3, 6, 6, skin)
    c.rect(Int(e.x) - 3, Int(e.y) + 2, 6, 1, dark)
    let r = angle * .pi / 180
    for n in 0..<3 {                                                    // bone knuckle spikes
        let off = Double(n - 1) * 1.8
        spike(e.x + cos(r) * 2 - sin(r) * off, e.y + sin(r) * 2 + cos(r) * off, angle, 2.5)
    }
}

// MARK: - Bizarro

/// Bizarro: Superman's backwards double, a chalk-white Clawd with grey cracks across his face, a black spit curl on
/// the wrong side, a dopey grin, the blue suit with the S back to front, and a red cape. Freeze breath from his
/// mouth, not heat vision. Signature: he says hello by standing on his hands, upside down and very pleased.
private func drawBizarro(_ c: PixelCanvas, _ p: Pose) {
    if let s = p.signature, s > 0.04, s < 0.96 {
        // Flip over, hold the handstand, flip back.
        let turn: Double = s < 0.2 ? (s - 0.04) / 0.16 : (s > 0.8 ? (0.96 - s) / 0.16 : 1)
        let e = 0.5 - 0.5 * cos(turn * .pi)
        let hop = sin(turn * .pi) * 6
        let s0 = PixelCanvas(c.w, c.h)
        bizarroArt(s0, p, handstand: e > 0.5, wobble: s)
        let r = s0.rotated(180 * e, about: (28, 32.5), into: c.w, c.h, at: (28, 32.5 - hop))
        c.paste(r)
        return
    }
    layer(c, lean: p.flying ? 4 : 0) { c in bizarroArt(c, p, handstand: false, wobble: 0) }
}

private func bizarroArt(_ c: PixelCanvas, _ p: Pose, handstand: Bool, wobble: Double) {
    let chalk = C(0xE6E6DA), chalkShade = C(0xB8B8AA), crack = C(0x8A8A7E)
    let blue = C(0x2A4AA8), blueDark = C(0x1C3478), red = C(0xC0242A), redDark = C(0x8A161C), yellow = C(0xF0D040)
    let hair = C(0x16161B)
    if p.flying {
        drawFlyingCape(c, t: p.t, color: red, edge: redDark)
    } else if !handstand {
        drawShoulderCape(c, t: p.lt, speed: p.capeSpeed, color: red, edge: redDark)
    }
    drawLegs(c, Look(leg: blue), step: handstand ? -1 : p.step)
    drawBoots(c, red, step: handstand ? -1 : p.step, rows: 3)
    if !handstand { c.oy += p.breathe }
    drawBody(c, Look(body: chalk, shade: chalkShade, arm: blue, eye: nil))
    // Hair: a flat black block with the curl on the wrong side.
    c.pattern(17, 22, [
        "...HHHHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHH.",
        ".HH..............HHH.",
        ".H.................H.",
    ], ["H": hair])
    c.pattern(31, 26, ["HH.", ".HH", "HH."], ["H": hair])          // the spit curl, over his left eye instead
    // Cracks in the chalk.
    c.pattern(19, 27, ["C.......", ".C......", ".CC....."], ["C": crack])
    c.pattern(35, 28, [".C", "C.", "C."], ["C": crack])
    // Uneven eyes, the big dopey grin (or a mouthful of frost).
    c.rect(21, 29, 3, 3, ink); c.rect(32, 30, 2, 2, ink)
    c.px(21, 29, white)
    let blowing = p.fire != nil || p.ready
    if blowing {
        c.rect(27, 31, 5, 2, C(0x2A3A4A)); c.rect(28, 31, 3, 1, C(0xA8E8FF))
        let i = Int(p.t * 18)
        for n in 0..<4 {
            let x = 32 + n * 2 + Int(noise(i + n) * 2), y = 31 + Int(noise(i * 3 + n) * 3) - 1
            c.px(x, y, C(0xE8FAFF, 0.9 - Double(n) * 0.18))
        }
    } else {
        c.pattern(25, 31, ["K........K", ".KWWWWWWK."], ["K": ink, "W": white])
    }
    // The suit and its backwards S.
    c.rect(18, 33, 20, 5, blue)
    c.rect(37, 33, 1, 5, blueDark)
    c.pattern(23, 33, [
        "RYYYYYYYR",
        ".RRRRRRR.",
        "..YYYRY..",
        "...RRR...",
        "....R....",
    ], ["R": red, "Y": yellow])
    c.pattern(23, 33, [
        ".........",
        "..YYYY...",
        ".........",
        ".........",
        ".........",
    ], ["Y": yellow])
    c.rect(18, 37, 20, 1, blueDark)
    c.rect(15, 33, 3, 3, blue)
    if handstand {
        // Arms straight up over his head (the floor, once he's turned over), hands flat.
        let w = Int(sin(wobble * 30) * 0.8)
        c.rect(15, 21 + w, 3, 12 - w, blue); c.rect(38, 21 - w, 3, 12 + w, blue)
        c.rect(14, 20 + w, 4, 2, chalk); c.rect(38, 20 - w, 4, 2, chalk)
        return
    }
    if p.flying {
        c.rect(38, 31, 5, 3, blue); c.rect(42, 31, 2, 3, chalk)
        return
    }
    c.rect(38, 33, 3, 3, blue)
}

// MARK: - Metallo

/// Metallo: half a man, half chrome: one side of his face still Clawd's orange, the other a bare metal skull with a
/// red eye and teeth. A chrome body with dark joints and rib plates, and a hatch in his chest over the kryptonite
/// heart, which opens to fire its green beam. Signature: the hatch swings open and the heart pulses brighter and
/// brighter, bathing him in green.
private func drawMetallo(_ c: PixelCanvas, _ p: Pose) {
    let chrome = C(0xA8AEB8), dark = C(0x6E747E), light = C(0xDDE2E8), joint = C(0x34383F)
    let green = C(0x3AE83A), core = C(0xE8FFE0), red = C(0xFF3A2A)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    // Legs: chrome pistons with black knee joints.
    drawLegs(c, Look(leg: chrome), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let up = p.step >= 0 && i % 2 == p.step ? 1 : 0
            c.rect(lx, 39 - up, 2, 1, joint); c.px(lx + 1, 36, dark)
            c.rect(lx, 42 - up, 2, 1, dark)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: chrome, shade: dark, arm: chrome, eye: nil))
    // The face: skin on the left, metal skull on the right.
    c.pattern(18, 26, [
        "SSSSSSSSSs..........",
        "SSSSSSSSSs..........",
        "SSSSSSSSSs..........",
        "SSSSSSSSs...........",
        "SSSSSSSSs...........",
        "SSSSSSSSs...........",
        "SSSSSSSs............",
    ], ["S": clawdOrange, "s": clawdShade])
    c.rect(28, 26, 9, 1, light)
    c.rect(22, 29, 2, 3, ink)
    c.rect(31, 28, 4, 4, joint)                                         // the eye socket
    c.glowLine(33, 30, 33, 30, core: C(0xFFE0D0), glow: red, coreR: 0.6, glowR: 1.8)
    c.rect(32, 29, 2, 2, red)
    c.rect(22, 32, 4, 1, clawdShade)
    c.pattern(26, 32, ["JWJWJWJWJ", ".JJJJJJJ."], ["J": joint, "W": light])   // the exposed teeth
    // Rib plates down the body, a dark pelvis.
    for x in [20, 23, 26] { c.rect(x, 34, 2, 3, dark); c.px(x, 34, light) }
    c.rect(18, 37, 20, 1, joint)
    c.rect(15, 33, 3, 3, chrome); c.rect(15, 34, 3, 1, joint)
    // The hatch over the heart.
    let open = p.fire != nil || p.ready ? 1.0 : k
    let hx = 30, hy = 33
    c.rect(hx, hy, 6, 4, joint)
    if open > 0.1 {
        let pulse = 0.75 + 0.25 * sin(p.t * (k > 0.1 ? 14 : 9))
        let size = 1.6 + k * 2.5
        c.glowLine(Double(hx) + 3, Double(hy) + 2, Double(hx) + 3, Double(hy) + 2, core: core, glow: green, coreR: 0.9,
                   glowR: size * pulse + 1)
        c.pattern(hx + 1, hy, ["..G.", ".GWG", "GGG.", ".G.."], ["G": green, "W": core])
        // The plate, swung open on its hinge.
        c.rect(hx + 6, hy - 1, 1, 6, light); c.rect(hx + 7, hy - 1, 1, 6, dark)
        if k > 0.6 {
            let i = Int(p.t * 12)
            for n in 0..<4 {
                let a = noise(i + n * 5) * 2 * .pi, d = 5 + noise(i * 3 + n) * 6
                c.px(hx + 3 + Int(cos(a) * d), hy + 2 + Int(sin(a) * d), green.alpha(0.7))
            }
        }
    } else {
        c.rect(hx, hy, 6, 4, chrome); c.rect(hx, hy, 6, 1, light)
        c.rect(hx, hy, 1, 4, green.alpha(0.7)); c.rect(hx + 5, hy, 1, 4, green.alpha(0.7))
        c.rect(hx, hy + 3, 6, 1, green.alpha(0.7))
        c.px(hx + 3, hy + 1, joint); c.px(hx + 2, hy + 2, joint)
    }
    c.rect(37, 26, 1, 12, dark)
    // His right arm: hanging, or bracing, the hand a chrome claw.
    c.rect(38, 33, 3, 3, chrome); c.rect(38, 34, 3, 1, joint)
    c.px(41, 35, dark)
}

// MARK: - Parasite

/// Parasite: a hunched purple Clawd with a bulbous, veined skull, lighter purple blotches, blank yellow eyes, a wide
/// mouth of crooked teeth, ragged dark trousers and clawed hands. He drains: a purple stream pulled into his hand.
/// Signature: stolen energy streams into him from all around, he swells up fat with it, and burps.
private func drawParasite(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x7A3AA8), dark = C(0x562478), light = C(0xA868D0), spot = C(0xC890E8), vein = C(0x4A1A68)
    let pants = C(0x2A3A2E), pantsDark = C(0x1A281E), eye = C(0xF4F0A0), claw = C(0xE8E0C8)
    let sig = p.signature
    let k = sig.map { habitArc($0, hold: 0.45) } ?? 0
    let swell = 1 + 0.14 * k
    if let s = sig, s > 0.05, s < 0.7 {
        // Stolen energy flowing in from every side.
        let cols: [Px] = [C(0xFFE03A), C(0x5AC8FF), C(0xFF5A5A), C(0x6AE86A), C(0xF0E0FF)]
        for n in 0..<10 {
            let f = frac(s * 3 + Double(n) * 0.1)
            let a = Double(n) * 2.4 + 0.3, d = 24 * (1 - f) + 4
            let x = 28 + cos(a) * d, y = 30 + sin(a) * d * 0.7
            c.glowLine(x, y, x, y, core: cols[n % 5], glow: cols[n % 5].alpha(0.5), coreR: 0.5, glowR: 1.4, strength: 0.4 + 0.6 * f)
        }
    }
    scaled(c, swell, about: (28, 43.5)) { c in
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            if seatedPose { c.rect(lx - 1, 38, 4, 2, pants); continue }
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 2, lifted ? 7 : 8, pants)
            c.rect(lx, lifted ? 42 : 43, 3, 1, purple)
            c.px(lx + 2, lifted ? 42 : 43, claw)
        }
        c.oy += p.breathe
        // The bulging skull above the body.
        c.pattern(18, 20, [
            ".....PPPPPPPPPP.....",
            "...PPPPLPPPPPPPPP...",
            "..PPPLPPPPVPPPPPPP..",
            ".PPPPPPPVPPPPPVPPPP.",
            ".PPPPPPPVPPPPVPPPPP.",
            "PPPPPPPPPVPPPVPPPPPP",
        ], ["P": purple, "L": light, "V": vein])
        drawBody(c, Look(body: purple, shade: dark, arm: purple, eye: nil), armRight: p.armRaise)
        for (x, y) in [(20, 27), (34, 26), (19, 33), (25, 35), (33, 34), (29, 27)] {
            c.rect(x, y, 2, 2, spot); c.px(x, y, light)
        }
        // A heavy brow, blank glowing eyes, the crooked grin.
        c.rect(20, 28, 6, 1, dark); c.rect(30, 28, 6, 1, dark)
        c.rect(21, 29, 3, 2, eye); c.rect(32, 29, 3, 2, eye)
        let wide = k > 0.5 ? 1 : 0
        c.rect(23 - wide, 32, 11 + wide * 2, 2 + wide, C(0x2A0A30))
        for n in 0..<5 { c.px(24 + n * 2, 32, claw); c.px(25 + n * 2, 33 + wide, claw) }
        // Ragged trousers.
        c.rect(18, 36, 20, 2, pants); c.rect(18, 37, 20, 1, pantsDark)
        c.rect(37, 26, 1, 10, dark)
        // Clawed hands.
        c.rect(15, 33, 3, 3, purple)
        c.px(14, 35, claw); c.px(15, 36, claw)
        let hy = 33 - p.armRaise
        c.px(41, hy, claw); c.px(41, hy + 2, claw)
    }
    if let s = sig, s > 0.74, s < 0.92 {
        // The burp.
        let f = (s - 0.74) / 0.18
        puff(c, x: 38 + f * 6, y: 31 - f * 3, k: f, C(0xC890E8))
    }
}

// MARK: - Toyman

/// Toyman: a porcelain doll's mask with painted blue eyes, rosy cheeks and a fixed little smile, a mop of orange
/// curls, a frilly white collar, a red-and-yellow harlequin suit and white gloves; a yo-yo bobs from his hand and
/// his toys are thrown. Signature: he winds up a toy soldier and sets it marching off, until it goes pop.
private func drawToyman(_ c: PixelCanvas, _ p: Pose) {
    let face = C(0xF4ECE2), faceShade = C(0xD8CCBE), cheek = C(0xF0A0A8), blue = C(0x3A7AE0)
    let hair = C(0xE8782A), hairDark = C(0xB85A1A), collar = C(0xF8F8F8), collarShade = C(0xC8C8D0)
    let red = C(0xC8323A), redDark = C(0x92222A), yellow = C(0xF0C83A), glove = C(0xF4F4F4)
    drawLegs(c, Look(leg: red), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() where i % 2 == 1 {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 2, lifted ? 7 : 8, yellow)
        }
    }
    drawBoots(c, C(0x3A2A6A), step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(body: face, shade: faceShade, arm: yellow, eye: nil))
    // The curls.
    c.pattern(16, 21, [
        "....HH.HHH.HHH.HH.......",
        "..HHHHHHHHHHHHHHHHHH....",
        ".HHHhHHHhHHHHhHHHHhHH...",
        "HHHHHHHHHHHHHHHHHHHHHH..",
        "HHhHHHhHHHHHHHHHhHHHHHH.",
        "HHH..HH..HH..HH..HH.HHH.",
        "HHH..................HHH",
        ".HH..................hH.",
        ".hH...................H.",
    ], ["H": hair, "h": hairDark])
    // The painted doll face.
    c.rect(21, 29, 3, 3, white); c.rect(32, 29, 3, 3, white)
    c.rect(22, 29, 2, 2, blue); c.rect(33, 29, 2, 2, blue)
    c.px(22, 29, ink); c.px(33, 29, ink)
    c.pattern(20, 28, [".K.K.......K.K."], ["K": ink])                // painted lashes
    c.rect(20, 32, 3, 1, cheek); c.rect(33, 32, 3, 1, cheek)
    c.pattern(26, 31, ["R...R", ".RRR."], ["R": C(0xC83A4A)])        // the fixed smile
    // The frilly collar and the harlequin suit.
    c.rect(18, 34, 20, 4, red)
    c.pattern(18, 35, ["YY..YY..YY..YY..YY..", "..YY..YY..YY..YY..YY"], ["Y": yellow])
    c.pattern(16, 33, ["CcCcCcCcCcCcCcCcCcCcCcCc", ".C.C.C.C.C.C.C.C.C.C.C.."], ["C": collar, "c": collarShade])
    c.rect(18, 37, 20, 1, redDark)
    c.rect(15, 33, 3, 3, glove)

    if let s = p.signature, s > 0.02, s < 0.97 {
        // Wind the soldier, set it down, watch it march off, and pop.
        c.oy -= p.breathe
        let sx: Int = s < 0.22 ? 43 : 43 + Int(((min(s, 0.78) - 0.22) / 0.56) * 16)
        c.rect(38, 34, 3, 3, glove)
        if s < 0.82 {
            let stepping = s > 0.22 && Int(s * 40) % 2 == 0
            c.pattern(sx, 34, [
                ".KK.",
                ".KK.",
                "KKKK",
                ".FF.",
                "RRRR",
                "RYRR",
                "RRRR",
                stepping ? "B..B" : ".BB.",
                stepping ? "B..B" : ".BB.",
            ], ["K": ink, "F": C(0xF0C8A0), "R": red, "Y": yellow, "B": C(0x2A2A6A)])
            let turn = Int(s * 30) % 3
            c.rect(sx - 2, 39, 2, 1, C(0xA8ACB8))
            c.rect(sx - 3, 38 + turn % 2, 1, 2 - turn % 2, C(0xC8CCD4))
        } else {
            let f = (s - 0.82) / 0.15
            let cols: [Px] = [C(0xFF4A5A), C(0xFFD03A), C(0x4AB8FF), C(0x6AE86A)]
            for n in 0..<10 {
                let a = Double(n) * 0.63, d = 2 + f * 8
                c.px(sx + 2 + Int(cos(a) * d), 38 + Int(sin(a) * d * 0.8 - f * 3), cols[n % 4].alpha(1 - f * 0.7))
            }
            puff(c, x: Double(sx) + 2, y: 38, k: f, C(0xE8E0D0))
        }
        return
    }
    // The throwing hand, or the yo-yo going up and down.
    if p.fire != nil {
        c.rect(38, 31 + p.gunY, 4, 3, glove)
    } else {
        c.rect(38, 33 + p.gunY, 3, 3, glove)
        if seatedPose { return }
        let drop = p.ready ? 1 : 1 + Int((abs(sin(p.lt * 3.2)) * 3).rounded())
        c.rect(40, 36 + p.gunY, 1, drop, C(0xE8E8E8, 0.8))
        c.pattern(39, 36 + p.gunY + drop, [".RR.", "RYYR", ".RR."], ["R": red, "Y": yellow])
    }
}

// MARK: - Mr. Mxyzptlk

/// "KLTPZYXM" in a tiny 3×5 pixel font, its first `count` letters, top-left at (x, y).
private func drawNameBackwards(_ c: PixelCanvas, x: Int, y: Int, count: Int, _ col: Px) {
    let glyphs: [[String]] = [
        ["X.X", "X.X", "XX.", "X.X", "X.X"],   // K
        ["X..", "X..", "X..", "X..", "XXX"],   // L
        ["XXX", ".X.", ".X.", ".X.", ".X."],   // T
        ["XX.", "X.X", "XX.", "X..", "X.."],   // P
        ["XXX", "..X", ".X.", "X..", "XXX"],   // Z
        ["X.X", "X.X", ".X.", ".X.", ".X."],   // Y
        ["X.X", "X.X", ".X.", "X.X", "X.X"],   // X
        ["X.X", "XXX", "XXX", "X.X", "X.X"],   // M
    ]
    for (i, g) in glyphs.prefix(count).enumerated() { c.pattern(x + i * 4, y, g, ["X": col]) }
}

/// Mr. Mxyzptlk: the imp from the fifth dimension, a grinning Clawd in a purple suit with a green bow tie, white
/// tufts of hair over his ears and an enormous purple bowler hat; he hovers and casts pink mischief. Signature: he
/// says his name backwards, "Kltpzyxm!", and pops out of existence in a puff, then pops back in.
private func drawMxyzptlk(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x6A3AA8), suitDark = C(0x48247A), hat = C(0x5A2A90), hatDark = C(0x3A1866), hatLight = C(0x8A5AC0)
    let band = C(0x2A123E), bow = C(0x3AC84A), bowDark = C(0x229030), tuft = C(0xF4F4F4), pink = C(0xFF6AD8)
    let sig = p.signature
    if let s = sig, s > 0.04, s < 0.62 {
        // The speech bubble, spelling it out.
        let n = min(8, Int((s - 0.04) / 0.42 * 8) + 1)
        c.rect(11, 3, 35, 9, white.alpha(0.92)); c.rect(12, 2, 33, 11, white.alpha(0.92))
        c.pattern(30, 13, ["WW", "W."], ["W": white.alpha(0.92)])
        drawNameBackwards(c, x: 13, y: 5, count: n, ink)
        if s > 0.46 { c.rect(45, 4, 1, 4, ink); c.px(45, 9, ink) }
    }
    if let s = sig, s > 0.56, s < 0.86 {
        // Popped. Only the smoke and a few stars where he was.
        let f = (s - 0.56) / 0.3
        puff(c, x: 28, y: 30, k: min(0.99, f * 1.6), C(0xFFB0F0))
        for n in 0..<4 {
            let a = Double(n) * 1.57 + f * 3
            twinkle(c, 28 + Int(cos(a) * (4 + f * 10)), 30 + Int(sin(a) * (3 + f * 7)), pink.alpha(max(0, 1 - f)))
        }
        return
    }
    var shrink = 1.0
    if let s = sig, s > 0.48, s <= 0.56 { shrink = 1 - (s - 0.48) / 0.08 * 0.85 }
    if let s = sig, s >= 0.86, s < 0.94 { shrink = 0.15 + (s - 0.86) / 0.08 * 0.85 }
    scaled(c, shrink, about: (28, 34)) { c in
        drawLegs(c, Look(leg: suit), step: p.step)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let lifted = p.step >= 0 && i % 2 == p.step
                c.rect(lx, lifted ? 41 : 42, 3, 2, C(0xE8782A))         // pointy orange shoes
            }
        }
        c.oy += p.breathe
        drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: suit, eye: nil), armRight: p.armRaise)
        // White tufts over the ears.
        c.pattern(14, 26, [".TT", "TTT", "TT.", ".T."], ["T": tuft])
        c.pattern(39, 26, ["TT.", "TTT", ".TT", ".T."], ["T": tuft])
        // The big bowler.
        c.pattern(15, 15, [
            "........HHHHHHHHH.........",
            "......HHHHHHHHHHHHH.......",
            ".....HHLHHHHHHHHHHHH......",
            ".....HLHHHHHHHHHHHHHh.....",
            ".....HLHHHHHHHHHHHHHh.....",
            ".....HHHHHHHHHHHHHHHh.....",
            ".....HHHHHHHHHHHHHHHh.....",
            ".....BBBBBBBBBBBBBBBB.....",
            ".....BBBBBBBBBBBBBBBB.....",
            "..HHHHHHHHHHHHHHHHHHHHHH..",
            "HHHHhhhhhhhhhhhhhhhhhhHHHH",
            "hh......................hh",
        ], ["H": hat, "h": hatDark, "L": hatLight, "B": band])
        // Mischievous brows, bright eyes, the enormous grin.
        c.pattern(20, 27, ["KK........KK.", "..K......K..."], ["K": ink])
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        c.px(23, 29, white); c.px(33, 29, white)
        c.pattern(23, 32, ["K..........K", ".KWWWWWWWWK.", "..KKKKKKKK.."], ["K": ink, "W": white])
        // The suit and the bow tie.
        c.rect(18, 35, 20, 3, suit)
        c.rect(37, 35, 1, 3, suitDark)
        c.rect(18, 37, 20, 1, suitDark)
        c.pattern(24, 34, ["BB..BB", "BBbbBB", "BB..BB"], ["B": bow, "b": bowDark])
        c.rect(15, 33, 3, 3, suit); c.rect(15, 35, 3, 1, clawdOrange)
        let hy = 33 - p.armRaise
        c.rect(38, hy, 3, 3, suit); c.rect(39, hy, 2, 1, clawdOrange)
        if p.zap == false || p.zap == true {
            twinkle(c, 41 + Int(p.t * 8) % 3, hy - 2, pink)
        }
    }
    if shrink < 0.95 {
        let f = 1 - shrink
        puff(c, x: 28, y: 30, k: min(0.95, f), C(0xFFB0F0))
    }
}

// MARK: - Livewire

/// Livewire: pale blue-white skin, a shock of spiky white hair crackling blue, blue lips, a black bodysuit with a
/// blue lightning bolt running across it. She flies on a trail of sparks and throws forked lightning. Signature: she
/// charges up, arcs jumping between her raised hands and running all over her, hair standing even taller.
private func drawLivewire(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xC8DAF0), skinShade = C(0x9AB0CE), hair = C(0xF8FCFF), hairBlue = C(0x6AC8FF)
    let suit = C(0x1A1C26), suitDark = C(0x0E1016), bolt = C(0x4AB8FF), lips = C(0x2A6AC8)
    let k = p.signature.map { habitArc($0, hold: 0.6) } ?? 0
    let i = Int(p.t * 20)
    layer(c, lean: p.flying ? 4 : 0) { c in
        drawLegs(c, Look(leg: suit), step: p.step)
        drawBoots(c, bolt, step: p.step, rows: 1)
        if p.flying {
            for lx in [19, 23, 31, 35] {
                c.glowLine(Double(lx) + 1, 44, Double(lx) + 1 + (noise(i + lx) - 0.5) * 3, 47, core: C(0xF4F8FF), glow: bolt,
                           coreR: 0.4, glowR: 1.3)
            }
        }
        c.oy += p.breathe
        drawBody(c, Look(body: skin, shade: skinShade, arm: suit, eye: nil), armRight: p.armRaise)
        // The hair: spikes standing straight up, taller when she's charged.
        let tall = Int((k * 3).rounded())
        let spikes: [(Double, Double, Double)] = [(20, 6, -125), (24, 9, -100), (28, 11, -88), (32, 9, -72), (36, 6, -50)]
        for (n, sp) in spikes.enumerated() {
            let len = sp.1 + Double(tall) + noise(i / 3 + n) * 1.5
            let e = along(sp.2, len, from: (sp.0, 27))
            c.glowLine(sp.0, 27, e.x, e.y, core: hair, glow: hairBlue.alpha(0.6), coreR: 1.1, glowR: 1.9)
            c.px(Int(e.x), Int(e.y), hairBlue)
        }
        c.rect(19, 25, 18, 2, hair)
        c.rect(18, 26, 4, 2, hair); c.rect(34, 26, 4, 2, hair)
        for n in 0..<3 where noise(i + n * 11) > 0.55 {
            let sp = spikes[Int(noise(i * 7 + n) * Double(spikes.count)) % spikes.count]
            let e = along(sp.2, sp.1 * 0.7, from: (sp.0, 27))
            c.glowLine(e.x, e.y, e.x + 1, e.y - 1, core: C(0xF4F8FF), glow: bolt, coreR: 0.4, glowR: 1.4)
        }
        // Eyes and blue lips.
        c.rect(22, 29, 2, 3, C(0x1A3A6A)); c.rect(32, 29, 2, 3, C(0x1A3A6A))
        c.px(22, 29, k > 0.4 ? C(0xF4F8FF) : C(0x7AD0FF)); c.px(32, 29, k > 0.4 ? C(0xF4F8FF) : C(0x7AD0FF))
        c.rect(26, 32, 4, 1, lips)
        if k > 0.4 { c.rect(25, 31, 1, 1, lips); c.rect(30, 31, 1, 1, lips) }
        // The black suit and its lightning bolt.
        c.rect(18, 33, 20, 5, suit)
        c.pattern(19, 33, ["BBBBBB............", ".....BBBBBBB......", "...........BBBBBBB", ".......BBBBB......"], ["B": bolt])
        c.rect(18, 37, 20, 1, suitDark)
        c.rect(15, 33, 3, 3, suit)
        if k > 0.05 {
            // Both hands up, an arc jumping between them and sparks running over her.
            let up = Int((k * 8).rounded())
            c.rect(15, 33 - up, 3, up + 3, suit); c.rect(38, 33 - up, 3, up + 3, suit)
            c.rect(15, 32 - up, 3, 2, skin); c.rect(38, 32 - up, 3, 2, skin)
            if k > 0.5 {
                drawMagic(c, Magic(core: C(0xF4F8FF), glow: bolt), from: (16.5, Double(32 - up)), to: (39.5, Double(32 - up)), t: p.t)
                for n in 0..<4 where noise(i * 5 + n) > 0.4 {
                    let x = 18 + Int(noise(i + n * 3) * 20), y = 26 + Int(noise(i * 2 + n) * 12)
                    c.glowLine(Double(x), Double(y), Double(x) + 2, Double(y) + 1, core: C(0xF4F8FF), glow: bolt, coreR: 0.4, glowR: 1.2)
                }
            }
            return
        }
        if p.flying {
            c.rect(38, 31, 4, 3, suit); c.rect(42, 31, 2, 3, skin)
            return
        }
        let hy = 33 - p.armRaise
        c.rect(38, hy, 3, 3, suit); c.rect(40, hy, 1, 3, skin)
    }
}
