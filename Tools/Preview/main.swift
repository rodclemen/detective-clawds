import AppKit

// Sprite and location contact sheets, for checking art while drawing it.
//
//   Tools/Preview/build.sh                         compiles it into build/preview
//   build/preview cast  out.png superman batman ...  every pose of each character (or a batch: heroes1 … villains9, all)
//   build/preview fight out.png superman lexLuthor two characters fighting, a few moments of it, with the effects
//   build/preview place out.png watchtower ...  locations at window size and at screen-saver size
//   build/preview rides out.png                    the ships, landed and flying
//
// SCALE=4 makes cells bigger (default 3).

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2 else {
    print("usage: preview cast|fight|place|rides <out.png> [names…]")
    exit(2)
}
let mode = args[0], out = args[1], names = Array(args.dropFirst(2))
let scale = CGFloat(Double(ProcessInfo.processInfo.environment["SCALE"] ?? "") ?? 3)
let bg = CGColor(red: 0.13, green: 0.14, blue: 0.19, alpha: 1)

func sheet(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.setFillColor(bg); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    ctx.interpolationQuality = .none
    draw(ctx)
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
    print("wrote \(out)")
}

func label(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 12, color: NSColor = .white) {
    NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .semibold),
                                               .foregroundColor: color]).draw(at: NSPoint(x: x, y: y))
}

/// A canvas drawn at `scale`, its bottom-left at (x, y), with a faint ground line under the feet (row 44).
func put(_ c: PixelCanvas, _ ctx: CGContext, x: CGFloat, y: CGFloat, outline: Bool = true) {
    if outline { c.addOutline(C(0xFFFFFF, 0.92)) }
    guard let img = c.makeImage() else { return }
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    ctx.fill(CGRect(x: x, y: y + CGFloat(c.h - 44) * scale, width: CGFloat(c.w) * scale, height: 1))
    ctx.draw(img, in: CGRect(x: x, y: y, width: CGFloat(c.w) * scale, height: CGFloat(c.h) * scale))
}

func cast(named n: String) -> [Cast] {
    let heroBatches = [heroes1, heroes2, heroes3, heroes4, heroes5, heroes6, heroes7, heroes8, heroes9, heroes10]
    let villainBatches = [villains1, villains2, villains3, villains4, villains5, villains6, villains7, villains8, villains9]
    var batches: [String: [Cast]] = [
        "heroes": Companion.allCases.map { .hero($0) },
        "villains": Leader.allCases.map { .villain($0) },
        "all": Companion.allCases.map { .hero($0) } + Leader.allCases.map { .villain($0) },
    ]
    for (i, b) in heroBatches.enumerated() { batches["heroes\(i + 1)"] = b.keys.sorted { $0.rawValue < $1.rawValue }.map { .hero($0) } }
    for (i, b) in villainBatches.enumerated() { batches["villains\(i + 1)"] = b.keys.sorted { $0.rawValue < $1.rawValue }.map { .villain($0) } }
    if let b = batches[n] { return b }
    if let h = Companion.allCases.first(where: { "\($0)" == n }) { return [.hero(h)] }
    if let v = Leader.allCases.first(where: { "\($0)" == n }) { return [.villain(v)] }
    print("unknown character: \(n)")
    exit(2)
}

switch mode {
case "cast":
    let who = names.flatMap(cast(named:))
    // Each pose: a title and how to draw it.
    typealias Shot = (title: String, draw: (Cast, PixelCanvas) -> Void)
    func habit(_ kind: IdleHabit, _ k: Double) -> (Cast, PixelCanvas) -> Void {
        { who, c in
            let len = kind == .signature ? who.signatureLength ?? kind.length : kind.length
            forcedHabit = HabitPlay(kind: kind, e: len * k, length: len)
            who.draw(c, t: 0.3, mode: .idle, walking: false, role: .none, asSession: true)
            forcedHabit = nil
        }
    }
    let shots: [Shot] = [
        ("idle", { $0.draw($1, t: 0.3, mode: .idle, walking: false, role: .none, asSession: true) }),
        ("walk 1", { $0.draw($1, t: 0.05, mode: .working, walking: true, role: .none, asSession: false, airborne: $0.motion == .fly) }),
        ("walk 2", { $0.draw($1, t: 0.18, mode: .working, walking: true, role: .none, asSession: false, airborne: $0.motion == .fly) }),
        ("working", { $0.draw($1, t: 0.3, mode: .working, walking: false, role: .none, asSession: false) }),
        ("working 2", { $0.draw($1, t: 0.62, mode: .working, walking: false, role: .none, asSession: false) }),
        ("fight", { who, c in
            let role: FightRole
            switch who.weapon {
            case .melee: role = .duel
            case .ranged: role = .shoot(offset: 0)
            case .magic: role = .zap
            case .none: role = .cheer
            }
            who.draw(c, t: 0.45, mode: .working, walking: false, role: role, asSession: false)
        }),
        ("hit", { $0.draw($1, t: 0.3, mode: .working, walking: false, role: .hit, asSession: false) }),
        ("waiting", { $0.draw($1, t: 0.3, mode: .waiting, walking: false, role: .none, urgent: true, asSession: true) }),
        ("sitting", { $0.draw($1, t: 0.3, mode: .idle, walking: false, role: .none, sitting: true, asSession: true) }),
        ("weapon habit", { who, c in
            switch who.weapon {
            case .melee: habit(.flourish, 0.45)(who, c)
            case .ranged: who.persona.handGun ? habit(.checkWeapon, 0.7)(who, c) : habit(.bounce, 0.2)(who, c)
            case .magic: habit(.crackle, 0.5)(who, c)
            case .none: habit(.bounce, 0.2)(who, c)
            }
        }),
        ("signature ¼", habit(.signature, 0.25)),
        ("signature ½", habit(.signature, 0.5)),
        ("signature ¾", habit(.signature, 0.75)),
    ]
    let cellW = CGFloat(Sprite.width) * scale + 8, cellH = CGFloat(Sprite.height) * scale + 22, nameW: CGFloat = 130
    let w = Int(nameW + cellW * CGFloat(shots.count)), h = Int(cellH * CGFloat(who.count) + 24)
    save(sheet(w, h) { ctx in
        for (j, s) in shots.enumerated() { label(s.title, nameW + CGFloat(j) * cellW + 4, CGFloat(h) - 18) }
        for (i, c) in who.enumerated() {
            let y = CGFloat(h) - 24 - cellH * CGFloat(i + 1)
            let p = c.persona
            label(c.name, 6, y + cellH / 2 + 4, size: 13)
            var kind = "\(p.weapon)"
            if p.motion != .walk { kind += " · \(p.motion)" }
            label(kind, 6, y + cellH / 2 - 12, size: 10, color: NSColor(white: 0.7, alpha: 1))
            for (j, s) in shots.enumerated() {
                if s.title.hasPrefix("signature"), c.signatureLength == nil { continue }
                let canvas = PixelCanvas(Sprite.width, Sprite.height)
                s.draw(c, canvas)
                put(canvas, ctx, x: nameW + CGFloat(j) * cellW, y: y + 4)
            }
        }
    })

case "fight":
    guard names.count == 2 else { print("fight needs two characters"); exit(2) }
    let a = cast(named: names[0])[0], b = cast(named: names[1])[0]
    let (ra, rb) = fightRoles(a.weapon, b.weapon)
    let close = fightIsCloseQuarters(a.weapon, b.weapon)
    let gap = close ? 30.0 + a.persona.bulk + b.persona.bulk : 64.0, margin = 24.0
    let width = Int(gap + margin * 2 + 36)
    let moments = [0.05, 0.2, 0.33, 0.45, 0.6, 0.75, 0.9, 1.3, 2.1]
    let headroom = 24   // flyers fight from the air now and then (`sortieAir`)
    let cellW = CGFloat(width) * scale + 8, cellH = CGFloat(Sprite.height + headroom) * scale + 8
    let w = Int(cellW * 3), h = Int(cellH * CGFloat((moments.count + 2) / 3) + 26)
    save(sheet(w, h) { ctx in
        label("\(a.name) (\(ra)) vs \(b.name) (\(rb))", 6, CGFloat(h) - 20)
        for (i, t) in moments.enumerated() {
            let c = PixelCanvas(width, Sprite.height + headroom)
            let lx = margin + 10, rx = lx + gap
            let ua = Int((sortieAir(a, seed: 0, fighting: true, t: t) * 16).rounded())
            let ub = Int((sortieAir(b, seed: 0.5, fighting: true, t: t) * 16).rounded())
            let ca = PixelCanvas(Sprite.width, Sprite.height), cb = PixelCanvas(Sprite.width, Sprite.height)
            a.draw(ca, t: t, mode: .working, walking: false, role: ra, asSession: false, aloft: ua > 4)
            b.draw(cb, t: t, mode: .working, walking: false, role: rb, asSession: false, aloft: ub > 4)
            cb.flipHorizontally()
            c.paste(ca, x: Int(lx - Sprite.bodyCenterX), y: headroom - ua)
            c.paste(cb, x: Int(rx - (Double(Sprite.width) - Sprite.bodyCenterX)), y: headroom - ub)
            func fighter(_ who: Cast, x: Double, side: Double, up: Int) -> Fighter {
                Fighter(weapon: who.weapon, x: x, k: 1, top: Double(headroom - up), side: side, muzzle: who.muzzle,
                        armoured: who.armoured, pivot: who.weaponPivot).dressed(as: who)
            }
            drawFightFX(c, t: t, left: fighter(a, x: lx, side: 1, up: ua), right: fighter(b, x: rx, side: -1, up: ub))
            put(c, ctx, x: CGFloat(i % 3) * cellW, y: CGFloat(h) - 26 - cellH * CGFloat(i / 3 + 1), outline: false)
            label("t=\(t)", CGFloat(i % 3) * cellW + 4, CGFloat(h) - 26 - cellH * CGFloat(i / 3) - 16, size: 10)
        }
    })

case "place":
    let places = names.isEmpty || names == ["all"] ? Location.allCases
        : names.map { n in Location.allCases.first { "\($0)" == n } ?? { print("unknown place: \(n)"); exit(2) }() }
    // The window's strip (about 480×75 pixels) and a screen-saver frame (16:10, tall enough for the extras).
    let strip = (w: 480, h: 75), tall = (w: 480, h: 300)
    let s: CGFloat = 2
    let rowH = CGFloat(strip.h + tall.h) * s + 40
    let w = Int(CGFloat(tall.w) * s + 12), h = Int(rowH * CGFloat(places.count))
    save(sheet(w, h) { ctx in
        for (i, l) in places.enumerated() {
            let top = CGFloat(h) - rowH * CGFloat(i)
            label(l.name, 6, top - 18, size: 13)
            for (j, size) in [strip, tall].enumerated() {
                let c = PixelCanvas(size.w, size.h); l.drawStatic(c, floorRows: 10)
                let m = PixelCanvas(size.w, size.h); l.drawAnimated(m, floorRows: 10, t: 1.3)
                let y = j == 0 ? top - 22 - CGFloat(strip.h) * s : top - 30 - CGFloat(strip.h + tall.h) * s
                for img in [c.makeImage(), m.makeImage()].compactMap({ $0 }) {
                    ctx.draw(img, in: CGRect(x: 6, y: y, width: CGFloat(size.w) * s, height: CGFloat(size.h) * s))
                }
            }
        }
    })

case "rides":
    let cellW = CGFloat(Ride.width) * scale + 12, cellH = CGFloat(Ride.height) * scale + 30
    let states: [(String, Double, Bool, Bool)] = [("landed", 0, false, true), ("ramp down", 1, false, true), ("flying", 0, true, false)]
    save(sheet(Int(cellW * 3), Int(cellH * 2)) { ctx in
        for (i, ride) in [Ride.javelin, .batwing].enumerated() {
            for (j, st) in states.enumerated() {
                let c = PixelCanvas(Ride.width, Ride.height)
                drawRide(c, ride, ramp: st.1, engines: st.2, gear: st.3)
                c.addOutline(C(0xFFFFFF, 0.92))
                let x = CGFloat(j) * cellW, y = cellH * CGFloat(1 - i)
                ctx.draw(c.makeImage()!, in: CGRect(x: x + 6, y: y + 6, width: CGFloat(Ride.width) * scale, height: CGFloat(Ride.height) * scale))
                label("\(ride) · \(st.0)", x + 6, y + cellH - 20)
            }
        }
    })

default:
    print("unknown mode \(mode)")
    exit(2)
}
