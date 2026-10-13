import AppKit

/// The trips between places: comic-book transitions, a different one each time. Most belong to someone (the Flash,
/// Batman, Superman…) and come up more often with them on screen, or when the trip heads for their home turf; any of
/// them can turn up on any trip.
enum ComicWipe: Int, CaseIterable {
    case speedForce     // the Flash races through the frozen panel in red and yellow lightning: WHOOSH!
    case batSignal      // Gotham goes dark, the Bat-Signal lights the sky, and its circle grows into the new place
    case pageBreaker    // Superman punches through the page from behind (KRAASH!), the new place underneath
    case lasso          // the Lasso of Truth loops the panel, crumples it up, and whips open on the new one
    case emerald        // the old place dissolves into green dots; a ring's constructs pencil, ink and colour the new one
    case jokerCard      // a giant Joker card spins in and flips (HAHAHA!), and its back is the new place
    case wave           // an Atlantean wave rises and crashes over everything (SPLAAASH!), and recedes on the new place
    case omegaBeams     // Darkseid's Omega Beams zigzag across the panel, which bursts apart: KRAKOOM!
    case grapple        // a grapnel catches the panel (THWIP!) and yanks it away; the new one swings down on cables
    case shazam         // lightning strikes (SHAZAM!), the page goes black and white, a second bolt brings the new place
    case mallet         // Harley's mallet smashes the panel (KAPOW!) into falling scraps of coloured paper
    case ankh           // Doctor Fate's ankh rises in a spread of glyphs, opens like a door, and the camera goes through
    case pageFlip       // the camera pulls back to a vintage comic book, the page turns: "MEANWHILE, IN …"
    case glitch         // Cyborg: the panel glitches into pixels and circuitry and rebuilds itself as the new place
    case multiverse     // the panel splits into a vortex of alternate versions; one rushes at you as the new place

    var duration: Double {
        switch self {
        case .speedForce: return 1.8
        case .batSignal: return 2.6
        case .pageBreaker: return 1.9
        case .lasso: return 2.2
        case .emerald: return 2.4
        case .jokerCard: return 2.2
        case .wave: return 1.9
        case .omegaBeams: return 1.9
        case .grapple: return 1.8
        case .shazam: return 1.8
        case .mallet: return 1.7
        case .ankh: return 2.6
        case .pageFlip: return 2.8
        case .glitch: return 1.9
        case .multiverse: return 2.6
        }
    }

    /// Whose it is: with one of them on screen it comes up more often.
    var owners: [Cast] {
        switch self {
        case .speedForce: return [.hero(.flash), .hero(.wallyWest), .hero(.jayGarrick), .hero(.impulse), .hero(.jesseQuick)]
        case .batSignal: return [.hero(.batman), .hero(.robin), .hero(.nightwing), .hero(.batgirl), .hero(.commissionerGordon),
                                 .hero(.aceTheBatHound)]
        case .pageBreaker: return [.hero(.superman), .hero(.supergirl), .hero(.superboy), .hero(.powerGirl), .hero(.jonKent)]
        case .lasso: return [.hero(.wonderWoman), .hero(.wonderGirl), .hero(.donnaTroy), .hero(.hippolyta), .hero(.artemis), .hero(.nubia)]
        case .emerald: return [.hero(.greenLantern), .hero(.johnStewart), .hero(.guyGardner), .hero(.kyleRayner), .hero(.jessicaCruz),
                               .hero(.simonBaz), .hero(.kilowog), .hero(.alanScott)]
        case .jokerCard: return [.villain(.joker), .villain(.jokerGoon)]
        case .wave: return [.hero(.aquaman), .hero(.mera), .hero(.aqualad), .villain(.oceanMaster)]
        case .omegaBeams: return [.villain(.darkseid), .villain(.kalibak), .villain(.desaad), .villain(.grannyGoodness),
                                  .villain(.steppenwolf), .villain(.parademon)]
        case .grapple: return [.hero(.batman), .hero(.robin), .hero(.nightwing), .hero(.batgirl), .hero(.redRobin), .hero(.batwoman)]
        case .shazam: return [.hero(.shazam), .villain(.blackAdam)]
        case .mallet: return [.villain(.harleyQuinn)]
        case .ankh: return [.hero(.doctorFate)]
        case .glitch: return [.hero(.cyborg)]
        case .pageFlip, .multiverse: return []
        }
    }

    /// Its home turf: a trip there brings it up more often too.
    var turf: [Location] {
        switch self {
        case .speedForce: return [.centralCity, .speedForce]
        case .batSignal: return [.gotham, .batcave, .wayneManor, .arkham]
        case .pageBreaker: return [.metropolis, .fortressOfSolitude, .smallville, .krypton, .kandor]
        case .lasso: return [.themyscira]
        case .emerald: return [.oa, .coastCity, .korugar]
        case .jokerCard: return [.aceChemicals, .arkham]
        case .wave: return [.atlantis]
        case .omegaBeams: return [.apokolips]
        case .grapple: return [.gotham, .bludhaven]
        case .shazam: return [.rockOfEternity, .fawcettCity, .kahndaq]
        case .mallet: return [.aceChemicals]
        case .ankh: return [.jsaHQ, .houseOfMystery]
        case .glitch: return [.starLabs, .titansTower, .watchtower]
        case .pageFlip, .multiverse: return []
        }
    }
}

/// One trip's transition, picked for who's on screen and where it's going. Shared by the window and the screen saver,
/// which hand over the old picture (frozen), the new one (as it is right now) and how far through it is; a frame is
/// drawn over the whole of `r`. Sizes are against an 800-pixel-tall frame.
struct ComicTrip {
    let kind: ComicWipe
    var caption = ""
    var duration: Double { kind.duration }

    /// Any transition but the last one, those of whoever's on screen and of the place it's going to weighted up.
    static func pick(after last: ComicWipe?, cast: [Cast], to place: Location) -> ComicTrip {
        let here = Set(cast)
        var kinds: [ComicWipe] = []
        for kind in ComicWipe.allCases where kind != last {
            kinds.append(kind)
            if kind.owners.contains(where: here.contains) { kinds += [kind, kind, kind] }
            if kind.turf.contains(place) { kinds += [kind, kind] }
        }
        return ComicTrip(kind: kinds.randomElement() ?? .multiverse, caption: "MEANWHILE, IN \(place.name.uppercased())…")
    }

    // MARK: Drawing

    private static let ink = rgb(0x121014)
    private static let paper = rgb(0xF4ECD8)

    private static func ease(_ k: Double) -> Double { k * k * (3 - 2 * k) }
    private static func clamp(_ k: Double) -> Double { min(1, max(0, k)) }
    /// How far `k` is through `a…b`: 0 before, 1 after.
    private static func span(_ k: Double, _ a: Double, _ b: Double) -> Double { clamp((k - a) / (b - a)) }
    /// Up to 1 over `a…b`, held, and back to 0 over `c…d`.
    private static func pop(_ k: Double, _ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
        ease(span(k, a, b)) * (1 - ease(span(k, c, d)))
    }

    /// A frame `k` (0…1) of the way from `old` to `new`, over the whole of `r`.
    func draw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.saveGState(); defer { ctx.restoreGState() }
        ctx.interpolationQuality = .none
        switch kind {
        case .speedForce: drawSpeedForce(ctx, old: old, new: new, k: k, in: r)
        case .batSignal: drawBatSignal(ctx, old: old, new: new, k: k, in: r)
        case .pageBreaker: drawPageBreaker(ctx, old: old, new: new, k: k, in: r)
        case .lasso: drawLasso(ctx, old: old, new: new, k: k, in: r)
        case .emerald: drawEmerald(ctx, old: old, new: new, k: k, in: r)
        case .jokerCard: drawJokerCard(ctx, old: old, new: new, k: k, in: r)
        case .wave: drawWave(ctx, old: old, new: new, k: k, in: r)
        case .omegaBeams: drawOmegaBeams(ctx, old: old, new: new, k: k, in: r)
        case .grapple: drawGrapple(ctx, old: old, new: new, k: k, in: r)
        case .shazam: drawShazam(ctx, old: old, new: new, k: k, in: r)
        case .mallet: drawMallet(ctx, old: old, new: new, k: k, in: r)
        case .ankh: drawAnkh(ctx, old: old, new: new, k: k, in: r)
        case .pageFlip: drawPageFlip(ctx, old: old, new: new, k: k, in: r)
        case .glitch: drawGlitch(ctx, old: old, new: new, k: k, in: r)
        case .multiverse: drawMultiverse(ctx, old: old, new: new, k: k, in: r)
        }
    }

    // MARK: The Flash

    /// The old place freezes into a panel; the Flash tears across it in red and yellow lightning, the picture smeared
    /// into speed lines, and leaves the new place behind him.
    private func drawSpeedForce(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        let f = Self.fold(k, in: 0.16, out: 0.84), p = Self.panelRect(r, f)
        let run = Self.span(k, 0.2, 0.76), blur = CGFloat(sin(.pi * run))
        let fx = p.minX - p.width * 0.15 + p.width * 1.3 * CGFloat(run)
        ctx.setFillColor(Self.paper); ctx.fill(r)

        func smeared(_ img: CGImage) {
            ctx.draw(img, in: p)
            guard blur > 0.01 else { return }
            for i in 1...5 {
                ctx.setAlpha(0.22)
                ctx.draw(img, in: p.offsetBy(dx: -CGFloat(i) * blur * p.width * 0.03, dy: 0))
            }
            ctx.setAlpha(1)
        }
        ctx.saveGState(); ctx.clip(to: p)
        ctx.saveGState(); ctx.clip(to: CGRect(x: fx, y: p.minY, width: p.maxX - fx, height: p.height)); smeared(old); ctx.restoreGState()
        ctx.saveGState(); ctx.clip(to: CGRect(x: p.minX, y: p.minY, width: max(0, fx - p.minX), height: p.height)); smeared(new); ctx.restoreGState()

        // Speed lines streaming past.
        if blur > 0.01 {
            for i in 0..<46 {
                let y = p.minY + p.height * CGFloat(noise(i * 3))
                let len = p.width * (0.15 + 0.4 * CGFloat(noise(i * 3 + 1)))
                let x = p.maxX - (p.width + len) * CGFloat((noise(i * 3 + 2) + k * 2.5).truncatingRemainder(dividingBy: 1)) * 1.2
                ctx.setFillColor(i % 3 == 0 ? rgb(0x121014, 0.45 * blur) : rgb(0xFFFFFF, 0.7 * blur))
                ctx.fill(CGRect(x: x, y: y, width: len, height: (1.5 + 3.5 * CGFloat(noise(i * 5))) * s))
            }
        }
        // His trail: red and yellow streaks, afterimages, and lightning crackling round him.
        if run > 0, run < 1 {
            let size = p.height * 0.011, feet = p.minY + p.height * 0.12, body = feet + 12 * size
            for (n, hex) in [(0, 0xE8202A), (1, 0xFFD21F), (2, 0xE8202A)] as [(Int, UInt32)] {
                let y = body + CGFloat(n - 1) * 5 * size
                ctx.setFillColor(rgb(hex, 0.75))
                ctx.fill(CGRect(x: fx - p.width * 0.55, y: y - 1.6 * size, width: p.width * 0.55 - 10 * size, height: 3.2 * size))
            }
            let flicker = Int(k * 24)
            for i in 0..<5 where noise(i * 7 + flicker) > 0.3 {
                let y0 = body + (CGFloat(noise(i * 9 + flicker)) - 0.5) * 30 * size
                let path = Self.bolt(CGPoint(x: fx - p.width * 0.5, y: y0), CGPoint(x: fx + 6 * size, y: body + (CGFloat(noise(i)) - 0.5) * 16 * size),
                                     steps: 9, jag: 7 * size, seed: i * 13 + flicker)
                Self.glow(ctx, path, i % 2 == 0 ? rgb(0xE8202A) : rgb(0xFFD21F), core: rgb(0xFFF8D0), width: 3.5 * size)
            }
            for i in stride(from: 3, through: 1, by: -1) {
                Self.figure(ctx, .hero(.flash), x: fx - CGFloat(i) * 9 * size, feet: feet, size: size, t: k * 9, walking: true,
                            alpha: 0.4 / CGFloat(i))
            }
            Self.figure(ctx, .hero(.flash), x: fx, feet: feet, size: size, t: k * 9, walking: true)
        }
        ctx.restoreGState()
        Self.frame(ctx, p, s: s, f: f)

        let say = Self.pop(k, 0.28, 0.36, 0.68, 0.78)
        if say > 0.01 {
            Self.letters(ctx, "WHOOSH!", at: CGPoint(x: r.midX, y: p.maxY - p.height * 0.24), size: (60 + 110 * CGFloat(say)) * s,
                         maxWidth: r.width * 0.85, angle: -0.1, fill: rgb(0xFFD21F), outline: rgb(0xC8102E))
        }
    }

    // MARK: Batman

    /// The old place sinks into a Gotham night; the Bat-Signal lights the sky, and its circle grows, the new place
    /// showing through it more and more until the light covers everything and fades off it.
    private func drawBatSignal(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, far = hypot(r.width, r.height)
        let night = Self.ease(Self.span(k, 0, 0.25)), lit = CGFloat(Self.ease(Self.span(k, 0.18, 0.34)))
        let fade = CGFloat(Self.span(k, 0.85, 1))
        let sky = CGPoint(x: r.midX, y: r.minY + r.height * 0.64)
        let rad = CGFloat(0.12 + 0.04 * Self.ease(Self.span(k, 0.2, 0.42))) * r.height
            + CGFloat(Self.ease(Self.span(k, 0.42, 0.86))) * far * 0.62
        ctx.draw(old, in: r)
        ctx.setFillColor(rgb(0x070C24, 0.72 * night)); ctx.fill(r)
        guard lit > 0.01 else { return }

        // The beam, from a searchlight on a rooftop below the frame.
        let foot = CGPoint(x: r.minX + r.width * 0.3, y: r.minY - 10 * s)
        let d = max(hypot(sky.x - foot.x, sky.y - foot.y), 1)
        let n = CGPoint(x: -(sky.y - foot.y) / d, y: (sky.x - foot.x) / d)
        ctx.addPath(Self.polygon([CGPoint(x: foot.x - n.x * 14 * s, y: foot.y - n.y * 14 * s),
                                  CGPoint(x: sky.x - n.x * rad * 0.95, y: sky.y - n.y * rad * 0.95),
                                  CGPoint(x: sky.x + n.x * rad * 0.95, y: sky.y + n.y * rad * 0.95),
                                  CGPoint(x: foot.x + n.x * 14 * s, y: foot.y + n.y * 14 * s)]))
        ctx.setFillColor(rgb(0xFFF1B0, 0.3 * lit * (1 - fade))); ctx.fillPath()

        // The circle of light: yellow, the new place coming through, the bat over it until it fades away.
        let circle = CGRect(x: sky.x - rad, y: sky.y - rad, width: rad * 2, height: rad * 2)
        ctx.saveGState()
        ctx.addEllipse(in: circle); ctx.clip()
        ctx.setAlpha(lit); ctx.setFillColor(rgb(0xFFE36B)); ctx.fill(r)
        ctx.setAlpha(lit * CGFloat(Self.ease(Self.span(k, 0.36, 0.76)))); ctx.draw(new, in: r)
        ctx.setAlpha(1)
        ctx.setFillColor(rgb(0xFFE36B, 0.42 * (1 - fade))); ctx.fill(r)
        let batA = lit * CGFloat(1 - Self.ease(Self.span(k, 0.46, 0.72)))
        if batA > 0.01 { ctx.addPath(Self.bat(sky, width: rad * 1.6)); ctx.setFillColor(rgb(0x0A0A0A, batA)); ctx.fillPath() }
        ctx.restoreGState()
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 24 * s, color: rgb(0xFFE36B))
        ctx.addEllipse(in: circle); ctx.setStrokeColor(rgb(0xFFF6C8, 0.85 * lit * (1 - fade))); ctx.setLineWidth(6 * s); ctx.strokePath()
        ctx.restoreGState()
    }

    /// A grapnel catches the top of the panel and yanks it up out of the frame; the new panel swings down on two cables
    /// and settles.
    private func drawGrapple(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        let f = Self.fold(k, in: 0.1, out: 0.88), p = Self.panelRect(r, f)
        let shot = CGFloat(Self.ease(Self.span(k, 0.1, 0.28))), yank = CGFloat(Self.ease(Self.span(k, 0.3, 0.56)))
        let drop = Self.span(k, 0.4, 0.95)
        let hook = CGPoint(x: p.midX + p.width * 0.12, y: p.maxY)
        let lift = yank * r.height * 1.3
        ctx.setFillColor(Self.paper); ctx.fill(r)

        // The new panel, swinging in on its cables and settling.
        if drop > 0 {
            let u = CGFloat(drop)
            let fall = CGFloat(1 - Self.ease(Self.span(drop, 0, 0.3))) * r.height * 1.2
            let swing = 0.3 * exp(-4.5 * u) * cos(u * 13)
            ctx.saveGState()
            ctx.translateBy(x: p.midX, y: p.maxY + fall); ctx.rotate(by: swing); ctx.translateBy(x: -p.midX, y: -p.maxY)
            let cables = CGFloat(1 - Self.span(k, 0.84, 0.94))
            if cables > 0.01 {
                for x in [p.minX + p.width * 0.18, p.maxX - p.width * 0.18] {
                    ctx.move(to: CGPoint(x: x, y: p.maxY)); ctx.addLine(to: CGPoint(x: p.midX + (x - p.midX) * 0.4, y: p.maxY + r.height * 2))
                }
                ctx.setStrokeColor(rgb(0x121014, cables)); ctx.setLineWidth(3 * s); ctx.strokePath()
            }
            Self.panel(ctx, new, p, s: s, border: f)
            ctx.restoreGState()
        }
        // The old one, hooked and hauled away.
        if yank < 1 {
            ctx.saveGState()
            ctx.translateBy(x: hook.x, y: hook.y + lift); ctx.rotate(by: yank * -0.14); ctx.translateBy(x: -hook.x, y: -hook.y)
            Self.panel(ctx, old, p, s: s, border: f)
            ctx.restoreGState()
        }
        // The line and the grapnel: shot in from the left, then reeled straight up.
        if k > 0.1 && yank < 1 {
            let from = CGPoint(x: r.minX - 20 * s, y: r.minY + r.height * 0.22)
            let head = k < 0.3 ? Self.mix(from, hook, shot) : CGPoint(x: hook.x, y: hook.y + lift)
            ctx.move(to: k < 0.3 ? from : CGPoint(x: head.x, y: r.maxY + 40 * s)); ctx.addLine(to: head)
            ctx.setStrokeColor(rgb(0x2B2B33)); ctx.setLineWidth(3.5 * s); ctx.strokePath()
            let angle = k < 0.3 ? atan2(hook.y - from.y, hook.x - from.x) : -.pi / 2
            Self.grapnel(ctx, at: head, angle: angle, size: 34 * s)
        }
        let say = Self.pop(k, 0.1, 0.16, 0.36, 0.44)
        if say > 0.01 {
            Self.letters(ctx, "THWIP!", at: CGPoint(x: r.minX + r.width * 0.27, y: r.minY + r.height * 0.42), size: (50 + 80 * CGFloat(say)) * s,
                         maxWidth: r.width * 0.6, angle: 0.14, fill: rgb(0xFFD21F), outline: Self.ink)
        }
    }

    // MARK: Superman

    /// The old place becomes a printed panel; something strains it from behind, then Superman bursts through, the paper
    /// tearing open on the new place and scraps of it flying at you: KRAASH!
    private func drawPageBreaker(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, far = hypot(r.width, r.height)
        let f = Self.fold(k, in: 0.15, out: 0.86)
        let hit = 0.36
        let strain = CGFloat(Self.span(k, 0.22, hit)) * (k < hit ? 1 : 0)
        var p = Self.panelRect(r, f)
        if strain > 0 { p = p.offsetBy(dx: (CGFloat(noise(Int(k * 90))) - 0.5) * 8 * s * strain, dy: (CGFloat(noise(Int(k * 90) + 5)) - 0.5) * 8 * s * strain) }
        let c = CGPoint(x: p.midX, y: p.midY + p.height * 0.04)
        ctx.setFillColor(Self.paper); ctx.fill(r)

        let open = CGFloat(Self.ease(Self.span(k, hit, 0.82))) * far * 0.72
        let hole = CGMutablePath()
        if open > 1 {
            var pts: [CGPoint] = []
            for i in 0..<30 {
                let a = CGFloat(i) / 30 * 2 * .pi, rr = open * (0.7 + 0.42 * CGFloat(noise(i * 11 + 3)))
                pts.append(CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr))
            }
            hole.addPath(Self.polygon(pts))
        }
        ctx.saveGState(); ctx.clip(to: p); ctx.draw(new, in: p); ctx.restoreGState()
        ctx.saveGState()
        ctx.addRect(p); if open > 1 { ctx.addPath(hole) }
        ctx.clip(using: .evenOdd)
        ctx.draw(old, in: p)
        // The paper straining: cracks running out from where he'll come through.
        if strain > 0 {
            for i in 0..<9 {
                let a = CGFloat(i) / 9 * 2 * .pi + CGFloat(noise(i)) * 0.5
                let len = strain * p.height * (0.12 + 0.1 * CGFloat(noise(i + 20)))
                let path = Self.bolt(c, CGPoint(x: c.x + cos(a) * len, y: c.y + sin(a) * len), steps: 4, jag: len * 0.12, seed: i * 7)
                ctx.addPath(path)
            }
            ctx.setStrokeColor(Self.ink); ctx.setLineWidth(3 * s); ctx.strokePath()
        }
        ctx.restoreGState()
        if open > 1 {   // the torn edge: white paper fibres, then the print's ink line
            ctx.saveGState(); ctx.clip(to: p)
            ctx.addPath(hole); ctx.setStrokeColor(rgb(0xFFFDF4)); ctx.setLineWidth(16 * s); ctx.setLineJoin(.round); ctx.strokePath()
            ctx.addPath(hole); ctx.setStrokeColor(rgb(0xB9AE96)); ctx.setLineWidth(3 * s); ctx.strokePath()
            ctx.restoreGState()
        }
        Self.frame(ctx, p, s: s, f: f)

        // Scraps of the page flying out at you.
        if k > hit {
            let age = Self.span(k, hit, hit + 0.42)
            var bits: [[CGPoint]] = []
            for i in 0..<24 {
                let a = CGFloat(noise(i * 5)) * 2 * .pi, d = (20 + 60 * CGFloat(noise(i * 5 + 1))) * s
                let o = CGPoint(x: c.x + cos(a) * d, y: c.y + sin(a) * d), sz = (40 + 50 * CGFloat(noise(i * 5 + 2))) * s
                bits.append([CGPoint(x: o.x - sz * 0.5, y: o.y - sz * 0.4), CGPoint(x: o.x + sz * 0.6, y: o.y - sz * 0.2),
                             CGPoint(x: o.x + sz * 0.1 * CGFloat(noise(i)), y: o.y + sz * 0.55)])
            }
            Self.scatter(ctx, old, in: p, bits, edge: { _ in rgb(0xFFFDF4) }, width: 4 * s) { i, mid in
                let dx = mid.x - c.x, dy = mid.y - c.y, len = max(hypot(dx, dy), 1)
                let go = CGFloat(Self.ease(age)) * far * (0.35 + 0.4 * CGFloat(noise(i * 9)))
                return (CGPoint(x: dx / len * go, y: dy / len * go), CGFloat(age) * (CGFloat(noise(i * 9 + 1)) - 0.5) * 9,
                        1 + CGFloat(age) * 3, CGFloat(1 - Self.span(age, 0.6, 1)))
            }
        }
        // Superman, fist first through the hole and on past you.
        let fly = Self.span(k, hit - 0.02, 0.64)
        if fly > 0 && fly < 1 {
            let size = p.height * (0.008 + 0.05 * CGFloat(pow(fly, 1.6)))
            Self.figure(ctx, .hero(.superman), x: c.x, feet: c.y - 12 * size, size: size, t: k * 4, airborne: true, angle: 0.3,
                        alpha: CGFloat(1 - Self.span(fly, 0.75, 1)))
        }
        let say = Self.pop(k, hit, hit + 0.08, 0.72, 0.84)
        if say > 0.01 {
            Self.letters(ctx, "KRAASH!", at: CGPoint(x: r.midX, y: r.maxY - r.height * 0.22), size: (60 + 120 * CGFloat(say)) * s,
                         maxWidth: r.width * 0.85, angle: -0.12, fill: rgb(0xFFD21F), outline: rgb(0xC8102E))
        }
    }

    // MARK: Wonder Woman

    /// The Lasso of Truth swings in and loops the panel, tightens and crumples it up into a ball; a golden flash, and it
    /// whips open again on the new place.
    private func drawLasso(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, far = hypot(r.width, r.height), c = CGPoint(x: r.midX, y: r.midY)
        let f = Self.fold(k, in: 0.12, out: 0.9), base = Self.panelRect(r, f)
        let swing = CGFloat(Self.ease(Self.span(k, 0.06, 0.32))), tight = CGFloat(Self.ease(Self.span(k, 0.34, 0.54)))
        let whip = CGFloat(Self.ease(Self.span(k, 0.58, 0.9)))
        ctx.setFillColor(Self.paper); ctx.fill(r)

        func crumpled(_ img: CGImage, scale: CGFloat, turn: CGFloat, creases: CGFloat) {
            ctx.saveGState()
            ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: turn); ctx.scaleBy(x: scale, y: scale); ctx.translateBy(x: -c.x, y: -c.y)
            Self.panel(ctx, img, base, s: s / max(scale, 0.3), border: f)
            if creases > 0.01 {
                ctx.clip(to: base)
                for i in 0..<18 {
                    let pt = { (j: Int) in CGPoint(x: base.minX + base.width * CGFloat(noise(i * 17 + j)),
                                                   y: base.minY + base.height * CGFloat(noise(i * 17 + j + 7))) }
                    ctx.addPath(Self.polygon([pt(1), pt(2), pt(3)]))
                    ctx.setFillColor(i % 2 == 0 ? rgb(0xFFFFFF, 0.14 * creases) : rgb(0x000000, 0.12 * creases)); ctx.fillPath()
                }
            }
            ctx.restoreGState()
        }
        let loop: CGFloat
        if k < 0.56 {
            crumpled(old, scale: 1 - 0.8 * tight, turn: tight * CGFloat(sin(k * 40)) * 0.08, creases: tight)
            loop = 1.2 - 0.98 * tight
        } else {
            crumpled(new, scale: 0.2 + 0.8 * whip, turn: (1 - whip) * -0.6, creases: 1 - whip)
            loop = 0.22 + 2.6 * whip
        }
        // The lasso: a glowing golden loop, and its rope back to whoever's holding it, off to the top left.
        let fadeRope = CGFloat(1 - Self.span(k, 0.86, 0.96))
        if fadeRope > 0.01 {
            let at = CGPoint(x: c.x - (1 - swing) * r.width * 0.95, y: c.y + (1 - swing) * r.height * 0.35)
            let rx = base.width / 2 * loop + 10 * s, ry = base.height / 2 * loop + 10 * s
            let path = CGMutablePath()
            for i in 0...64 {
                let a = CGFloat(i) / 64 * 2 * .pi + .pi, wob = 1 + 0.03 * sin(a * 7 + CGFloat(k) * 20)
                let pt = CGPoint(x: at.x + cos(a) * rx * wob, y: at.y + sin(a) * ry * wob)
                i == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            let knot = CGPoint(x: at.x - rx, y: at.y)
            path.move(to: knot)
            path.addCurve(to: CGPoint(x: r.minX - 60 * s, y: r.maxY + 60 * s), control1: CGPoint(x: knot.x - r.width * 0.15, y: knot.y + r.height * 0.05),
                          control2: CGPoint(x: r.minX + r.width * 0.05, y: r.maxY - r.height * 0.1))
            Self.rope(ctx, path, s: s, alpha: fadeRope)
        }
        let flash = CGFloat(Self.pop(k, 0.5, 0.56, 0.58, 0.7))
        if flash > 0.01 {
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [rgb(0xFFFFFF, flash), rgb(0xFFE27A, 0.9 * flash), rgb(0xF5C542, 0)] as CFArray, locations: [0, 0.35, 1])!
            ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: far * 0.65, options: [])
        }
    }

    // MARK: Green Lantern

    /// The old place dissolves into thousands of green dots; a ring lights up, its constructs frame out the new place
    /// and draw it: rough pencils, then inks, then full colour.
    private func drawEmerald(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height)
        let green = rgb(0x39FF6A)
        let dissolve = CGFloat(Self.ease(Self.span(k, 0.04, 0.32))), build = CGFloat(Self.ease(Self.span(k, 0.36, 0.62)))
        let stage = 2 * Self.span(k, 0.5, 0.95)
        ctx.setFillColor(rgb(0x031208)); ctx.fill(r)
        ctx.setAlpha(1 - dissolve); ctx.draw(old, in: r); ctx.setAlpha(1)
        Self.dots(ctx, r, 0x39FF6A, alpha: CGFloat(Self.pop(k, 0, 0.16, 0.34, 0.52)), size: 0.35 + 0.35 * dissolve, cell: 11 * s)

        if build > 0.001 {
            let area = CGRect(x: c.x - r.width / 2 * build, y: c.y - r.height / 2 * build, width: r.width * build, height: r.height * build)
            ctx.saveGState(); ctx.clip(to: area)
            ctx.draw(new, in: r)
            Self.develop(ctx, area, pencil: 1 - Self.clamp(stage), ink: 1 - Self.clamp(stage - 1))
            let grid = CGFloat(1 - Self.span(k, 0.6, 0.9)) * 0.5
            if grid > 0.01 {
                let step = 48 * s
                var x = c.x.truncatingRemainder(dividingBy: step); while x < r.maxX { ctx.move(to: CGPoint(x: x, y: r.minY)); ctx.addLine(to: CGPoint(x: x, y: r.maxY)); x += step }
                var y = c.y.truncatingRemainder(dividingBy: step); while y < r.maxY { ctx.move(to: CGPoint(x: r.minX, y: y)); ctx.addLine(to: CGPoint(x: r.maxX, y: y)); y += step }
                ctx.setStrokeColor(rgb(0x39FF6A, grid)); ctx.setLineWidth(1.5 * s); ctx.strokePath()
            }
            ctx.setFillColor(rgb(0x2BD45A, 0.3 * (1 - Self.span(k, 0.72, 1)))); ctx.fill(area)
            ctx.restoreGState()
            Self.glow(ctx, CGPath(rect: area, transform: nil), green, core: rgb(0xD8FFE2), width: 7 * s, alpha: CGFloat(1 - Self.span(k, 0.8, 0.95)))
        }
        // The ring's light: beams out to the corners of the construct, and the lantern symbol blazing at the centre.
        let ring = CGFloat(Self.pop(k, 0.2, 0.32, 0.56, 0.7))
        if ring > 0.01 {
            let reach = max(build, 0.08)
            for (dx, dy) in [(-1.0, -1.0), (1, -1), (1, 1), (-1, 1)] as [(CGFloat, CGFloat)] {
                let path = CGMutablePath()
                path.move(to: c); path.addLine(to: CGPoint(x: c.x + dx * r.width / 2 * reach, y: c.y + dy * r.height / 2 * reach))
                Self.glow(ctx, path, green, core: rgb(0xD8FFE2), width: 9 * s, alpha: ring * CGFloat(Self.span(k, 0.28, 0.4)))
            }
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [rgb(0x9DFFB5, 0.9 * ring), rgb(0x39FF6A, 0.4 * ring), rgb(0x39FF6A, 0)] as CFArray, locations: [0, 0.4, 1])!
            ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: far * 0.25, options: [])
            Self.lantern(ctx, at: c, radius: (54 + 26 * ring) * s, color: green)
        }
    }

    // MARK: The Joker

    /// A giant Joker card spins in over the old place, flips with a HAHAHA!, and its back is the new place; it grows
    /// to fill the screen while a deck's worth of cards scatters.
    private func drawJokerCard(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, far = hypot(r.width, r.height), c = CGPoint(x: r.midX, y: r.midY)
        let fly = CGFloat(Self.ease(Self.span(k, 0, 0.3))), flip = Self.span(k, 0.32, 0.58), grow = CGFloat(Self.ease(Self.span(k, 0.6, 1)))
        let h0 = r.height * 0.86, w0 = h0 * 0.68
        let cover = max(r.width / w0, r.height / h0) * 1.15
        let scale = (0.25 + 0.75 * fly) * (1 + (cover - 1) * grow)
        let at = CGPoint(x: c.x + (1 - fly) * r.width * 0.75, y: c.y + (1 - fly) * r.height * 0.6)
        let xs = CGFloat(abs(cos(.pi * flip)))
        ctx.draw(old, in: r)
        ctx.setFillColor(rgb(0x1E0A2E, 0.55 * Self.span(k, 0.05, 0.3))); ctx.fill(r)

        ctx.saveGState()
        ctx.translateBy(x: at.x, y: at.y); ctx.rotate(by: (1 - fly) * 7); ctx.scaleBy(x: scale * max(xs, 0.01), y: scale)
        if flip < 0.5 {
            Self.jokerFace(ctx, w: w0, h: h0, s: s)
        } else {
            let card = CGRect(x: -w0 / 2, y: -h0 / 2, width: w0, height: h0), round = w0 * 0.07
            ctx.addPath(CGPath(roundedRect: card, cornerWidth: round, cornerHeight: round, transform: nil))
            ctx.setFillColor(rgb(0xFFFFFF)); ctx.fillPath()
            ctx.saveGState()
            let inner = card.insetBy(dx: w0 * 0.045, dy: w0 * 0.045)
            ctx.addPath(CGPath(roundedRect: inner, cornerWidth: round * 0.6, cornerHeight: round * 0.6, transform: nil)); ctx.clip()
            // Lined up with the screen, so it's the new place exactly once the card stops turning.
            ctx.draw(new, in: CGRect(x: (r.minX - at.x) / scale, y: (r.minY - at.y) / scale, width: r.width / scale, height: r.height / scale))
            ctx.restoreGState()
            ctx.addPath(CGPath(roundedRect: card, cornerWidth: round, cornerHeight: round, transform: nil))
            ctx.setStrokeColor(Self.ink); ctx.setLineWidth(4 * s / scale); ctx.strokePath()
        }
        ctx.restoreGState()

        // The rest of the deck, flung out.
        for i in 0..<14 {
            let born = 0.34 + 0.22 * noise(i * 3), age = Self.span(k, born, born + 0.5)
            guard age > 0, age < 1 else { continue }
            let a = CGFloat(noise(i * 3 + 1)) * 2 * .pi, d = CGFloat(Self.ease(age)) * far * 0.62
            let mini = r.height * 0.16 / h0
            ctx.saveGState()
            ctx.setAlpha(CGFloat(1 - Self.span(age, 0.7, 1)))
            ctx.translateBy(x: c.x + cos(a) * d, y: c.y + sin(a) * d)
            ctx.rotate(by: CGFloat(age) * 9 * (CGFloat(noise(i * 3 + 2)) - 0.5) + a)
            ctx.scaleBy(x: mini, y: mini)
            Self.jokerFace(ctx, w: w0, h: h0, s: s / mini)
            ctx.restoreGState()
        }
        let say = Self.pop(k, 0.36, 0.44, 0.72, 0.82)
        if say > 0.01 {
            Self.letters(ctx, "HAHAHA!", at: CGPoint(x: c.x, y: r.maxY - r.height * 0.2), size: (60 + 110 * CGFloat(say)) * s,
                         maxWidth: r.width * 0.85, angle: 0.1, fill: rgb(0x8CF23A), outline: rgb(0x3B0F5E))
        }
    }

    // MARK: Aquaman

    /// A huge comic wave rises from the bottom, all thick black outlines and turquoise halftone, crashes over the whole
    /// frame (SPLAAASH!) and draws back down off the new place.
    private func drawWave(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        let rise = CGFloat(Self.ease(Self.span(k, 0, 0.42))), recede = CGFloat(Self.ease(Self.span(k, 0.56, 1)))
        let front = k < 0.5 ? r.minY - r.height * 0.6 + r.height * 2.05 * rise : r.maxY + r.height * 0.45 - r.height * 2.1 * recede
        ctx.draw(k < 0.5 ? old : new, in: r)

        // The water's top: three big breakers, each curling over into a lip, drifting sideways.
        let humps = 3, hw = r.width / CGFloat(humps) * 1.05, drift = CGFloat(k) * hw * 0.6
        let lift = min(hw * 0.75, r.height * 0.42)
        let crest = CGMutablePath()
        var x = r.minX - hw - drift.truncatingRemainder(dividingBy: hw)
        crest.move(to: CGPoint(x: x, y: r.minY - r.height))
        crest.addLine(to: CGPoint(x: x, y: front))
        var tops: [CGPoint] = []
        while x < r.maxX + hw {
            // Up the back of the wave, over the top and out past its face, then down under the lip.
            let lip = CGPoint(x: x + hw * 0.92, y: front + lift * 0.55)
            crest.addCurve(to: lip, control1: CGPoint(x: x + hw * 0.35, y: front + lift * 0.9),
                           control2: CGPoint(x: x + hw * 1.12, y: front + lift * 1.25))
            crest.addQuadCurve(to: CGPoint(x: x + hw, y: front), control: CGPoint(x: x + hw * 0.78, y: front + lift * 0.3))
            tops.append(CGPoint(x: x + hw * 0.8, y: front + lift * 0.98))
            x += hw
        }
        crest.addLine(to: CGPoint(x: x, y: r.minY - r.height))
        crest.closeSubpath()

        ctx.saveGState()
        ctx.addPath(crest); ctx.clip()
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(0x3FD6E0), rgb(0x1696B8), rgb(0x0A4F80)] as CFArray,
                              locations: [0, 0.4, 1])!
        ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: front + lift), end: CGPoint(x: 0, y: front - r.height * 1.2),
                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        Self.dots(ctx, r, 0x063A63, alpha: 0.4, size: 0.5, cell: 15 * s)
        // Swirls in the water.
        for i in 0..<10 {
            let cx = r.minX + r.width * CGFloat(noise(i * 7)), cy = front - r.height * (0.1 + 0.9 * CGFloat(noise(i * 7 + 1)))
            let rr = (30 + 40 * CGFloat(noise(i * 7 + 2))) * s
            ctx.move(to: CGPoint(x: cx + rr, y: cy))
            ctx.addArc(center: CGPoint(x: cx, y: cy), radius: rr, startAngle: 0, endAngle: 4, clockwise: false)
        }
        ctx.setStrokeColor(rgb(0xBFF4FF, 0.55)); ctx.setLineWidth(4 * s); ctx.strokePath()
        ctx.restoreGState()
        ctx.addPath(crest); ctx.setStrokeColor(rgb(0xF2FDFF)); ctx.setLineWidth(16 * s); ctx.setLineJoin(.round); ctx.strokePath()
        ctx.addPath(crest); ctx.setStrokeColor(Self.ink); ctx.setLineWidth(5 * s); ctx.strokePath()
        // Foam curling off each crest, and spray.
        for (i, t) in tops.enumerated() {
            for j in 0..<4 {
                let rr = (12 + 7 * CGFloat(j)) * s, o = CGPoint(x: t.x - CGFloat(j) * 26 * s, y: t.y - CGFloat(j) * 6 * s)
                ctx.addEllipse(in: CGRect(x: o.x - rr, y: o.y - rr, width: rr * 2, height: rr * 2))
                ctx.setFillColor(rgb(0xF2FDFF)); ctx.fillPath()
                ctx.addEllipse(in: CGRect(x: o.x - rr, y: o.y - rr, width: rr * 2, height: rr * 2))
                ctx.setStrokeColor(Self.ink); ctx.setLineWidth(3 * s); ctx.strokePath()
            }
            if k < 0.5 {
                for j in 0..<4 {
                    let id = i * 11 + j, up = CGFloat(noise(id + Int(k * 30))) * 60 * s
                    let d = CGPoint(x: t.x + (CGFloat(noise(id * 3)) - 0.3) * hw * 0.4, y: t.y + 30 * s + up)
                    ctx.setFillColor(rgb(0xF2FDFF)); ctx.fillEllipse(in: CGRect(x: d.x - 6 * s, y: d.y - 6 * s, width: 12 * s, height: 12 * s))
                }
            }
        }
        // Bubbles while it's all under water.
        let under = CGFloat(Self.pop(k, 0.36, 0.44, 0.62, 0.72))
        if under > 0.01 {
            for i in 0..<28 {
                let bx = r.minX + r.width * CGFloat(noise(i * 13)), speed = 0.4 + CGFloat(noise(i * 13 + 1))
                let by = r.minY + r.height * ((CGFloat(noise(i * 13 + 2)) + CGFloat(k) * speed * 3).truncatingRemainder(dividingBy: 1))
                let rr = (6 + 14 * CGFloat(noise(i * 13 + 3))) * s
                ctx.addEllipse(in: CGRect(x: bx - rr, y: by - rr, width: rr * 2, height: rr * 2))
            }
            ctx.setStrokeColor(rgb(0xE6FBFF, 0.8 * under)); ctx.setLineWidth(3 * s); ctx.strokePath()
        }
        let say = Self.pop(k, 0.34, 0.42, 0.64, 0.74)
        if say > 0.01 {
            Self.letters(ctx, "SPLAAASH!", at: CGPoint(x: r.midX, y: r.midY + r.height * 0.06), size: (60 + 120 * CGFloat(say)) * s,
                         maxWidth: r.width * 0.9, angle: -0.08, fill: rgb(0xE8FBFF), outline: rgb(0x08406E))
        }
    }

    // MARK: Darkseid

    /// Two Omega Beams zigzag across the panel, burning cracks into it; it splits along them and blows apart (KRAKOOM!)
    /// on the new place.
    private func drawOmegaBeams(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, far = hypot(r.width, r.height)
        let f = Self.fold(k, in: 0.12, out: 0.88), p = Self.panelRect(r, f), c = CGPoint(x: p.midX, y: p.midY)
        let fire = Self.span(k, 0.1, 0.4), burst = Self.span(k, 0.5, 1)
        ctx.setFillColor(Self.paper); ctx.fill(r)

        func zigzag(_ a: CGPoint, _ b: CGPoint, seed: Int) -> [CGPoint] {
            let dx = b.x - a.x, dy = b.y - a.y, len = max(hypot(dx, dy), 1), n = CGPoint(x: -dy / len, y: dx / len)
            return (0...8).map { i in
                let t = CGFloat(i) / 8, side: CGFloat = i == 0 || i == 8 ? 0 : (i % 2 == 0 ? 1 : -1)
                let off = side * r.height * (0.06 + 0.07 * CGFloat(noise(seed * 31 + i)))
                return CGPoint(x: a.x + dx * t + n.x * off, y: a.y + dy * t + n.y * off)
            }
        }
        let beams = [zigzag(CGPoint(x: r.minX - r.width * 0.05, y: p.maxY - p.height * 0.12), CGPoint(x: r.maxX + r.width * 0.05, y: p.minY + p.height * 0.28), seed: 1),
                     zigzag(CGPoint(x: r.minX - r.width * 0.05, y: p.minY + p.height * 0.18), CGPoint(x: r.maxX + r.width * 0.05, y: p.maxY - p.height * 0.32), seed: 2)]
        if burst <= 0 {
            let shake = CGFloat(Self.span(k, 0.2, 0.5)) * 6 * s
            let q = p.offsetBy(dx: (CGFloat(noise(Int(k * 80))) - 0.5) * shake, dy: (CGFloat(noise(Int(k * 80) + 3)) - 0.5) * shake)
            Self.panel(ctx, old, q, s: s, border: f)
            ctx.saveGState(); ctx.clip(to: q)
            for (i, b) in beams.enumerated() {
                let path = Self.partial(b, Self.span(fire, Double(i) * 0.25, 0.75 + Double(i) * 0.25))
                ctx.addPath(path); ctx.setStrokeColor(rgb(0x2A0505)); ctx.setLineWidth(14 * s); ctx.setLineJoin(.miter); ctx.strokePath()
                ctx.addPath(path); ctx.setStrokeColor(rgb(0xFF7A1A)); ctx.setLineWidth(5 * s); ctx.strokePath()
            }
            ctx.restoreGState()
            for (i, b) in beams.enumerated() {
                Self.glow(ctx, Self.partial(b, Self.span(fire, Double(i) * 0.25, 0.75 + Double(i) * 0.25)), rgb(0xFF1E1E), core: rgb(0xFFE6E0),
                          width: 22 * s, alpha: CGFloat(1 - Self.span(k, 0.42, 0.5)))
            }
        } else {
            Self.panel(ctx, new, p, s: s, border: f)
            Self.scatter(ctx, old, in: p, Self.shards(p, cols: 6, rows: 4, seed: 5), edge: { _ in rgb(0xFF6A1A) }, width: 5 * s) { i, mid in
                let dx = mid.x - c.x, dy = mid.y - c.y, len = max(hypot(dx, dy), 1)
                let e = CGFloat(Self.ease(burst)), go = e * far * (0.45 + 0.6 * CGFloat(noise(i * 5)))
                return (CGPoint(x: dx / len * go, y: dy / len * go), e * (CGFloat(noise(i * 5 + 1)) - 0.5) * 4, 1 + e * 0.6,
                        CGFloat(1 - Self.span(burst, 0.55, 0.9)))
            }
        }
        let flash = CGFloat(Self.pop(k, 0.46, 0.5, 0.52, 0.64))
        if flash > 0.01 { ctx.setFillColor(rgb(0xFF2A10, 0.8 * flash)); ctx.fill(r) }
        let say = Self.pop(k, 0.5, 0.56, 0.78, 0.9)
        if say > 0.01 {
            Self.letters(ctx, "KRAKOOM!", at: CGPoint(x: r.midX, y: r.midY + r.height * 0.05), size: (60 + 120 * CGFloat(say)) * s,
                         maxWidth: r.width * 0.9, angle: -0.1, fill: rgb(0xFF5A1F), outline: rgb(0x1A0505))
        }
    }

    // MARK: Shazam

    /// A golden bolt strikes the old place: SHAZAM!, and the page turns into a hard black-and-white print. A second
    /// bolt brings the new place, still in black and white, and the colour floods back in.
    private func drawShazam(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        let gold = rgb(0xFFC21A)
        let inked: Double
        if k < 0.55 {
            ctx.draw(old, in: r); inked = Self.span(k, 0.09, 0.16)
        } else {
            ctx.draw(new, in: r); inked = 1 - Self.ease(Self.span(k, 0.62, 0.96))
        }
        Self.develop(ctx, r, pencil: 0, ink: inked)
        Self.dots(ctx, r, 0x000000, alpha: 0.2 * CGFloat(inked), size: 0.32, cell: 9 * s)

        for (n, (a, b)) in [(0.04, 0.24), (0.5, 0.68)].enumerated() {
            let on = CGFloat(Self.pop(k, a, a + 0.03, b - 0.06, b))
            guard on > 0.01 else { continue }
            let top = CGPoint(x: r.midX + (n == 0 ? 0.12 : -0.18) * r.width, y: r.maxY + 20 * s)
            let hit = CGPoint(x: r.midX + (n == 0 ? -0.04 : 0.06) * r.width, y: r.minY + r.height * 0.28)
            let flicker = Int(k * 30) % 3
            Self.glow(ctx, Self.bolt(top, hit, steps: 10, jag: r.height * 0.06, seed: n * 40 + flicker), gold, core: rgb(0xFFFBEA), width: 26 * s, alpha: on)
            for j in 0..<3 {   // forks
                let from = Self.mix(top, hit, 0.3 + 0.2 * CGFloat(j))
                let to = CGPoint(x: from.x + (CGFloat(noise(n * 9 + j)) - 0.5) * r.width * 0.4, y: from.y - r.height * 0.22)
                Self.glow(ctx, Self.bolt(from, to, steps: 5, jag: r.height * 0.03, seed: n * 50 + j * 3 + flicker), gold, core: rgb(0xFFFBEA),
                          width: 10 * s, alpha: on)
            }
            let flash = CGFloat(Self.pop(k, a + 0.03, a + 0.04, a + 0.05, a + 0.12))
            if flash > 0.01 { ctx.setFillColor(rgb(0xFFFBEA, 0.85 * flash)); ctx.fill(r) }
        }
        let say = Self.pop(k, 0.1, 0.17, 0.7, 0.8)
        if say > 0.01 {
            Self.letters(ctx, "SHAZAM!", at: CGPoint(x: r.midX, y: r.maxY - r.height * 0.24), size: (60 + 120 * CGFloat(say)) * s,
                         maxWidth: r.width * 0.88, angle: -0.08, fill: rgb(0xFFD21F), outline: rgb(0xC8102E))
        }
    }

    // MARK: Harley Quinn

    /// Harley's giant mallet swings in from off screen and slams into the panel (KAPOW!), which shatters into scraps of
    /// coloured paper that fall away off the new place.
    private func drawMallet(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        let f = Self.fold(k, in: 0.1, out: 0.9), p = Self.panelRect(r, f)
        let hit = 0.32, impact = CGPoint(x: p.midX, y: p.midY)
        let colours = [rgb(0xFF4FA3), rgb(0xFFE14A), rgb(0x3FC8F2), rgb(0xD7263D)]
        ctx.setFillColor(Self.paper); ctx.fill(r)
        if k < hit {
            Self.panel(ctx, old, p, s: s, border: f)
        } else {
            Self.panel(ctx, new, p, s: s, border: f)
            let t = CGFloat(Self.span(k, hit, 0.95))
            Self.scatter(ctx, old, in: p, Self.shards(p, cols: 7, rows: 5, seed: 9), edge: { colours[$0 % 4] }, width: 5 * s) { i, mid in
                let dx = mid.x - impact.x, dy = mid.y - impact.y, len = max(hypot(dx, dy), 1)
                let speed = r.height * (0.4 + 0.9 * CGFloat(noise(i * 7)))
                return (CGPoint(x: dx / len * speed * t, y: dy / len * speed * t * 0.6 + r.height * 0.5 * t - r.height * 3.4 * t * t),
                        t * (CGFloat(noise(i * 7 + 1)) - 0.5) * 8, 1 - 0.25 * t, CGFloat(1 - Self.span(Double(t), 0.7, 1)))
            }
            // Confetti.
            for i in 0..<40 {
                let a = CGFloat(noise(i * 3)) * 2 * .pi, v = r.height * (0.5 + CGFloat(noise(i * 3 + 1)))
                let pos = CGPoint(x: impact.x + cos(a) * v * t, y: impact.y + sin(a) * v * t - r.height * 2.6 * t * t)
                let sz = (8 + 10 * CGFloat(noise(i * 3 + 2))) * s
                ctx.saveGState()
                ctx.translateBy(x: pos.x, y: pos.y); ctx.rotate(by: t * 12 + CGFloat(i))
                ctx.setFillColor(colours[i % 4]); ctx.setAlpha(CGFloat(1 - Self.span(Double(t), 0.7, 1)))
                ctx.fill(CGRect(x: -sz / 2, y: -sz * 0.3, width: sz, height: sz * 0.6))
                ctx.restoreGState()
            }
        }
        // The mallet, swung from a hand off the bottom right.
        let pivot = CGPoint(x: r.maxX + r.width * 0.12, y: r.minY - r.height * 0.4)
        let reach = hypot(impact.x - pivot.x, impact.y - pivot.y), strike = atan2(impact.y - pivot.y, impact.x - pivot.x)
        var angle: CGFloat? = nil
        if k < hit { let u = CGFloat(Self.span(k, 0.02, hit)); angle = strike - 1.4 * (1 - u * u) }
        else if k < 0.66 {
            angle = strike - 0.16 * CGFloat(sin(.pi * Self.span(k, hit, 0.46))) - 1.7 * CGFloat(Self.ease(Self.span(k, 0.46, 0.66)))
        }
        if let angle { Self.mallet(ctx, pivot: pivot, angle: angle, reach: reach, size: r.height) }

        let boom = CGFloat(Self.pop(k, hit, hit + 0.03, hit + 0.1, hit + 0.22))
        if boom > 0.01 {
            let rad = boom * hypot(r.width, r.height) * 0.36
            ctx.addPath(Self.starburst(impact, r: rad * 1.05, seed: 4)); ctx.setFillColor(Self.ink); ctx.fillPath()
            ctx.addPath(Self.starburst(impact, r: rad, seed: 4)); ctx.setFillColor(rgb(0xFF4FA3)); ctx.fillPath()
            ctx.addPath(Self.starburst(impact, r: rad * 0.66, seed: 6)); ctx.setFillColor(rgb(0xFFE14A)); ctx.fillPath()
        }
        let say = Self.pop(k, hit, hit + 0.05, 0.7, 0.8)
        if say > 0.01 {
            Self.letters(ctx, "KAPOW!", at: CGPoint(x: r.midX, y: r.midY + r.height * 0.04), size: (60 + 130 * CGFloat(say)) * s,
                         maxWidth: r.width * 0.85, angle: -0.12, fill: rgb(0xFFE14A), outline: rgb(0xE0218A))
        }
    }

    // MARK: Doctor Fate

    /// A golden ankh rises in the middle of the old place while glyphs and rings of golden ink spread out across it; it
    /// turns, its loop opens like a doorway on the new place, and the camera flies through.
    private func drawAnkh(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height)
        let gold = rgb(0xF2C14E)
        let rise = CGFloat(Self.ease(Self.span(k, 0.04, 0.24))), spread = CGFloat(Self.ease(Self.span(k, 0.08, 0.5)))
        let spin = Self.span(k, 0.22, 0.46), open = CGFloat(Self.ease(Self.span(k, 0.44, 0.62))), dive = CGFloat(Self.ease(Self.span(k, 0.58, 1)))
        let parts = Self.ankh(c, height: r.height * 0.56 * (0.4 + 0.6 * rise))
        let hole = parts.hole
        // Through the doorway: zoom on the loop's hole until it holds the whole screen, its middle moving to the middle.
        let ax = r.width / 2 / (hole.width / 2), ay = r.height / 2 / (hole.height / 2)
        let zoom = pow(sqrt(ax * ax + ay * ay) * 1.08, dive)
        let door = CGPoint(x: hole.midX, y: hole.midY), to = Self.mix(door, c, dive)
        let cam = CGAffineTransform(translationX: to.x, y: to.y).scaledBy(x: zoom, y: zoom).translatedBy(x: -door.x, y: -door.y)

        ctx.draw(old, in: r)
        ctx.setFillColor(rgb(0x140C02, 0.5 * spread)); ctx.fill(r)
        ctx.saveGState()
        ctx.concatenate(cam)
        Self.glyphs(ctx, around: c, reach: spread * far * 0.62, s: s, color: gold, alpha: 1 - CGFloat(Self.span(k, 0.7, 0.9)))
        if rise > 0.01 {
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [rgb(0xFFE9A8, 0.75 * rise), rgb(0xF2C14E, 0.3 * rise), rgb(0xF2C14E, 0)] as CFArray, locations: [0, 0.45, 1])!
            ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: r.height * 0.5, options: [])
        }
        let xs = CGFloat(cos(2 * .pi * spin))
        ctx.translateBy(x: c.x, y: 0); ctx.scaleBy(x: abs(xs) < 0.02 ? 0.02 : xs, y: 1); ctx.translateBy(x: -c.x, y: 0)
        if open > 0.001 {
            ctx.saveGState()
            ctx.addEllipse(in: hole); ctx.clip()
            ctx.concatenate(cam.inverted())   // the new place on screen as it is, a little zoomed while the camera arrives
            let z = 1.2 - 0.2 * dive
            ctx.draw(new, in: CGRect(x: c.x - r.width / 2 * z, y: c.y - r.height / 2 * z, width: r.width * z, height: r.height * z))
            ctx.restoreGState()
            ctx.saveGState(); ctx.addEllipse(in: hole); ctx.clip()
            ctx.setFillColor(rgb(0xFFE9A8, 1 - open)); ctx.fill(hole)
            ctx.restoreGState()
        }
        if rise > 0.01 {
            ctx.setAlpha(min(1, rise * 1.5))
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 30 * s, color: gold)
            ctx.addPath(parts.ring); ctx.addPath(parts.solid); ctx.setStrokeColor(Self.ink); ctx.setLineWidth(9 * s); ctx.setLineJoin(.round); ctx.strokePath()
            ctx.restoreGState()
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(0xFFF0B8), rgb(0xF2C14E), rgb(0xB07A12)] as CFArray,
                                  locations: [0, 0.45, 1])!
            let box = parts.ring.boundingBox.union(parts.solid.boundingBox)
            for (path, rule) in [(parts.ring, CGPathFillRule.evenOdd), (parts.solid, .winding)] {
                ctx.saveGState(); ctx.addPath(path); ctx.clip(using: rule)
                ctx.drawLinearGradient(grad, start: CGPoint(x: box.minX, y: box.maxY), end: CGPoint(x: box.maxX, y: box.minY), options: [])
                ctx.restoreGState()
            }
            ctx.setAlpha(1)
        }
        ctx.restoreGState()
    }

    // MARK: Anyone

    /// The camera pulls back from the old place to find it printed on the page of a vintage comic book; the page turns
    /// on the new place, "MEANWHILE, IN …", and the camera pushes back in.
    private func drawPageFlip(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, c = CGPoint(x: r.midX, y: r.midY)
        let pull = CGFloat(Self.ease(Self.span(k, 0, 0.26))), turn = CGFloat(Self.ease(Self.span(k, 0.3, 0.68)))
        let push = CGFloat(Self.ease(Self.span(k, 0.72, 1)))
        let pw = r.width * 0.45, m = pw * 0.06, artW = pw - 2 * m, artH = artW * r.height / r.width, ph = artH + 2 * m
        let right = CGRect(x: c.x, y: c.y - ph / 2, width: pw, height: ph), left = right.offsetBy(dx: -pw, dy: 0)
        let art = right.insetBy(dx: m, dy: m)
        // The camera: right in on the page's picture (filling the screen) at 0, the whole book at 1.
        let out = k < 0.7 ? pull : 1 - push
        let zoom = pow(r.width / artW, 1 - out)
        let focus = CGPoint(x: c.x + (art.midX - c.x) * out, y: c.y + (art.midY - c.y) * out)
        let cam = CGAffineTransform(translationX: focus.x, y: focus.y).scaledBy(x: zoom, y: zoom).translatedBy(x: -art.midX, y: -art.midY)

        ctx.setFillColor(rgb(0x24170E)); ctx.fill(r)
        let vignette = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(0x5A3B22), rgb(0x24170E)] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(vignette, startCenter: c, startRadius: 0, endCenter: c, endRadius: hypot(r.width, r.height) * 0.55, options: [])
        ctx.saveGState()
        ctx.concatenate(cam)
        let sw = s / zoom * 1.0
        ctx.setFillColor(rgb(0x000000, 0.45)); ctx.fill(left.union(right).offsetBy(dx: 14 * s, dy: -14 * s))
        let pageColour = rgb(0xEFE2C2)
        ctx.setFillColor(pageColour); ctx.fill(left); ctx.fill(right)

        /// A picture printed on the old paper: yellowed, with the dots showing.
        func printed(_ img: CGImage, in box: CGRect, mirrored: Bool = false, faint: CGFloat = 1) {
            ctx.saveGState(); ctx.clip(to: box)
            if mirrored { ctx.translateBy(x: box.midX, y: 0); ctx.scaleBy(x: -1, y: 1); ctx.translateBy(x: -box.midX, y: 0) }
            ctx.setAlpha(faint); ctx.draw(img, in: box)
            ctx.setBlendMode(.multiply); ctx.setFillColor(rgb(0xE9D3A0, 0.5 * out)); ctx.fill(box)
            ctx.restoreGState()
            if faint >= 1 {
                Self.dots(ctx, box, 0x5A3A1A, alpha: 0.14 * out, size: 0.4, cell: 7 * s)
                ctx.setStrokeColor(Self.ink); ctx.setLineWidth(4 * s); ctx.stroke(box)
            }
        }
        // The page before: four panels of the old place.
        let la = left.insetBy(dx: m, dy: m), gw = la.width / 2, gh = la.height / 2, gut = 8 * s
        for i in 0..<4 {
            let cell = CGRect(x: la.minX + CGFloat(i % 2) * gw, y: la.minY + CGFloat(i / 2) * gh, width: gw, height: gh).insetBy(dx: gut / 2, dy: gut / 2)
            ctx.saveGState(); ctx.clip(to: cell)
            let zoomIn = 1.6 + 0.3 * CGFloat(i)
            ctx.draw(old, in: CGRect(x: cell.midX - cell.width * zoomIn / 2 - CGFloat(i) * 20 * s, y: cell.midY - cell.height * zoomIn / 2,
                                     width: cell.width * zoomIn, height: cell.height * zoomIn))
            ctx.setBlendMode(.multiply); ctx.setFillColor(rgb(0xE9D3A0, 0.5)); ctx.fill(cell)
            ctx.restoreGState()
            ctx.setStrokeColor(Self.ink); ctx.setLineWidth(3 * s); ctx.stroke(cell)
        }
        if turn >= 1 { ctx.setFillColor(pageColour); ctx.fill(left); printed(old, in: left.insetBy(dx: m, dy: m), mirrored: true, faint: 0.14) }
        // The next page, under the one turning: the new place, captioned.
        printed(k < 0.3 ? old : new, in: art)
        if k >= 0.3 {
            let a = CGFloat(1 - Self.span(k, 0.8, 0.94))
            if a > 0.01 { Self.captionBox(ctx, caption, at: CGPoint(x: art.minX + 10 * s, y: art.maxY - 10 * s), size: art.height * 0.085,
                                          maxWidth: art.width * 0.8, s: s, alpha: a) }
        }
        // The spine's shadow.
        let spine = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(0x000000, 0), rgb(0x000000, 0.28), rgb(0x000000, 0)] as CFArray,
                               locations: [0, 0.5, 1])!
        ctx.drawLinearGradient(spine, start: CGPoint(x: c.x - pw * 0.06, y: 0), end: CGPoint(x: c.x + pw * 0.06, y: 0), options: [])
        // The page turning over on its spine.
        if turn > 0 && turn < 1 {
            let xs = cos(.pi * turn)
            ctx.saveGState()
            ctx.translateBy(x: c.x, y: 0); ctx.scaleBy(x: abs(xs) < 0.01 ? 0.01 : xs, y: 1); ctx.translateBy(x: -c.x, y: 0)
            ctx.setFillColor(pageColour); ctx.fill(right)
            if xs > 0 { printed(old, in: art) } else { printed(old, in: art, faint: 0.14) }
            ctx.setFillColor(rgb(0x000000, 0.35 * (1 - abs(xs)))); ctx.fill(right)
            ctx.setStrokeColor(rgb(0x8A7A58)); ctx.setLineWidth(2 * sw); ctx.stroke(right)
            ctx.restoreGState()
        }
        ctx.restoreGState()
    }

    /// The old place glitches apart into square pixels, halftone, scraps of speech balloons and racing blue and red
    /// circuitry; the blocks fall back together as the new place, rebuilt from pencils to inks to full colour.
    private func drawGlitch(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800
        let breakUp = Self.ease(Self.span(k, 0.04, 0.46)), rebuild = 1 - Self.ease(Self.span(k, 0.5, 0.86))
        let stage = 2 * Self.span(k, 0.52, 0.95)
        let amount = k < 0.5 ? breakUp : rebuild, img = k < 0.5 ? old : new
        let tick = Int(k * 20)   // glitches jump, they don't glide
        ctx.setFillColor(rgb(0x050A14)); ctx.fill(r)
        let cell = 56 * s, cols = Int((r.width / cell).rounded(.up)), rows = Int((r.height / cell).rounded(.up))
        for i in 0..<cols {
            for j in 0..<rows {
                let id = i * 131 + j * 7
                if noise(id * 5 + 1) < amount * 0.3 { continue }   // some drop out altogether
                let wild = CGFloat(noise(id) < 0.3 ? 1 : 0.25) * CGFloat(amount)
                let dx = (CGFloat(noise(id * 3 + tick)) - 0.5) * cell * 3 * wild, dy = (CGFloat(noise(id * 3 + tick + 1)) - 0.5) * cell * wild
                let tile = CGRect(x: r.minX + CGFloat(i) * cell + dx, y: r.minY + CGFloat(j) * cell + dy, width: cell, height: cell)
                ctx.saveGState(); ctx.clip(to: tile); ctx.draw(img, in: r.offsetBy(dx: dx, dy: dy)); ctx.restoreGState()
            }
        }
        if k >= 0.5 { Self.develop(ctx, r, pencil: 1 - Self.clamp(stage), ink: 1 - Self.clamp(stage - 1)) }
        let a = CGFloat(amount)
        // Bands of split colour.
        for b in 0..<7 where noise(b * 11 + tick) < amount {
            let band = CGRect(x: r.minX, y: r.minY + r.height * CGFloat(noise(b * 11 + tick + 1)), width: r.width, height: (10 + 40 * CGFloat(noise(b))) * s)
            ctx.setFillColor(rgb(b % 2 == 0 ? 0xFF2A4A : 0x2AD8FF, 0.35)); ctx.fill(band.offsetBy(dx: (CGFloat(noise(b + tick)) - 0.5) * 60 * s, dy: 0))
        }
        // The grid and the dots.
        if a > 0.01 {
            var x = r.minX; while x < r.maxX { ctx.move(to: CGPoint(x: x, y: r.minY)); ctx.addLine(to: CGPoint(x: x, y: r.maxY)); x += cell }
            var y = r.minY; while y < r.maxY { ctx.move(to: CGPoint(x: r.minX, y: y)); ctx.addLine(to: CGPoint(x: r.maxX, y: y)); y += cell }
            ctx.setStrokeColor(rgb(0x2EA8FF, 0.3 * a)); ctx.setLineWidth(1.5 * s); ctx.strokePath()
            Self.dots(ctx, r, 0x0A0A0A, alpha: 0.3 * a, size: 0.4, cell: 9 * s)
        }
        Self.circuits(ctx, r, s: s, progress: Self.span(k, 0.08, 0.55), alpha: k < 0.5 ? 1 : CGFloat(rebuild))
        // Scraps of speech balloons.
        let talk = CGFloat(Self.pop(k, 0.1, 0.24, 0.58, 0.74))
        if talk > 0.01 {
            let words = ["!?", "#@$%!", "...", "BZZT", "ERR0R", "01101", "BOO-YAH!"]
            for i in 0..<8 {
                let w = (110 + 80 * CGFloat(noise(i * 19 + 2))) * s, h = w * 0.58
                let at = CGPoint(x: r.minX + r.width * (0.1 + 0.8 * CGFloat(noise(i * 19))) + (CGFloat(noise(i + tick)) - 0.5) * 20 * s,
                                 y: r.minY + r.height * (0.15 + 0.7 * CGFloat(noise(i * 19 + 1))))
                let piece = CGRect(x: at.x - w * 0.6 + w * 0.5 * CGFloat(noise(i * 19 + 3)), y: at.y - h * 0.8 + h * 0.6 * CGFloat(noise(i * 19 + 4)),
                                   width: w * 0.7, height: h * 1.1)
                ctx.saveGState(); ctx.clip(to: piece); ctx.setAlpha(talk)
                Self.balloon(ctx, words[i % words.count], at: at, width: w, height: h, s: s)
                ctx.restoreGState()
            }
        }
    }

    /// The old place splits into a grid of panels that drift into a cosmic vortex, each turning into a slightly different
    /// version of the same scene; one panel races out of the middle at you and fills the screen with the new place.
    private func drawMultiverse(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let s = r.height / 800, c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height)
        let split = CGFloat(Self.ease(Self.span(k, 0, 0.2))), morph = CGFloat(Self.ease(Self.span(k, 0.14, 0.34)))
        let orbit = Self.span(k, 0.18, 0.88), settle = CGFloat(Self.ease(Self.span(orbit, 0, 0.35)))
        let fling = CGFloat(Self.ease(Self.span(k, 0.62, 0.92))), rush = Self.span(k, 0.56, 1)
        Self.vortex(ctx, r, s: s, k: k, alpha: min(1, split * 1.5))

        let cols = 5, rows = 4, cw = r.width / CGFloat(cols), ch = r.height / CGFloat(rows)
        var tiles: [(depth: CGFloat, n: Int, pos: CGPoint, size: CGSize, tilt: CGFloat, alpha: CGFloat, cell: CGRect)] = []
        for i in 0..<cols {
            for j in 0..<rows {
                let n = i * rows + j
                let cell = CGRect(x: r.minX + CGFloat(i) * cw, y: r.minY + CGFloat(j) * ch, width: cw, height: ch)
                let a0 = atan2(cell.midY - c.y, cell.midX - c.x), d0 = hypot(cell.midX - c.x, cell.midY - c.y)
                let turn = CGFloat(Self.ease(orbit)) * (2.2 + 0.8 * CGFloat(noise(n * 3)))
                let radius = d0 * (1 - 0.3 * settle) + settle * r.height * 0.08 + fling * far * (0.6 + 0.5 * CGFloat(noise(n * 3 + 1)))
                let depth = 1 + settle * (0.75 + 0.3 * sin(a0 * 3 + turn * 2 + CGFloat(n)) - 1)
                let scale = depth * (1 - 0.12 * split) * (1 + fling * 1.4)
                tiles.append((depth + fling, n, CGPoint(x: c.x + cos(a0 + turn) * radius, y: c.y + sin(a0 + turn) * radius),
                              CGSize(width: cw * scale, height: ch * scale), sin(CGFloat(n) * 1.7) * 0.5 * settle + turn * 0.12,
                              CGFloat(1 - Self.span(Double(fling), 0.4, 1)), cell))
            }
        }
        for t in tiles.sorted(by: { $0.depth < $1.depth }) where t.alpha > 0.01 {
            let box = CGRect(x: -t.size.width / 2, y: -t.size.height / 2, width: t.size.width, height: t.size.height)
            ctx.saveGState()
            ctx.translateBy(x: t.pos.x, y: t.pos.y); ctx.rotate(by: t.tilt)
            ctx.setAlpha(t.alpha)
            ctx.beginTransparencyLayer(auxiliaryInfo: nil)
            ctx.saveGState(); ctx.clip(to: box)
            // Its piece of the old place, giving way to the whole scene, its own way.
            let piece = box.width / t.cell.width
            ctx.draw(old, in: CGRect(x: box.minX - (t.cell.minX - r.minX) * piece, y: box.minY - (t.cell.minY - r.minY) * piece,
                                     width: r.width * piece, height: r.height * piece))
            if morph > 0.01 {
                ctx.setAlpha(morph)
                if t.n % 3 == 1 { ctx.saveGState(); ctx.scaleBy(x: -1, y: 1); ctx.draw(old, in: box); ctx.restoreGState() }
                else { ctx.draw(old, in: box) }
                ctx.setAlpha(1)
                Self.variant(ctx, t.n, box, amount: morph)
            }
            ctx.restoreGState()
            ctx.setStrokeColor(rgb(0xFFFFFF)); ctx.setLineWidth(6 * s); ctx.stroke(box)
            ctx.setStrokeColor(Self.ink); ctx.setLineWidth(3 * s); ctx.stroke(box)
            ctx.endTransparencyLayer()
            ctx.restoreGState()
        }
        if rush > 0 {
            let z = CGFloat(pow(rush, 2.2)), sc = 0.05 + 0.95 * z
            let box = CGRect(x: -r.width / 2 * sc, y: -r.height / 2 * sc, width: r.width * sc, height: r.height * sc)
            ctx.saveGState()
            ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: (1 - z) * 0.9)
            ctx.saveGState(); ctx.clip(to: box); ctx.draw(new, in: box); ctx.restoreGState()
            let edge = CGFloat(1 - Self.span(k, 0.9, 1))
            if edge > 0.01 {
                ctx.setStrokeColor(rgb(0xFFFFFF, edge)); ctx.setLineWidth(10 * s); ctx.stroke(box)
                ctx.setStrokeColor(rgb(0x121014, edge)); ctx.setLineWidth(4 * s); ctx.stroke(box)
            }
            ctx.restoreGState()
        }
    }

    // MARK: Shared

    /// The frame shrunk to a panel on a page: `f` 0 is the whole frame, 1 a panel with a margin round it.
    private static func panelRect(_ r: CGRect, _ f: Double) -> CGRect {
        r.insetBy(dx: r.width * 0.06 * CGFloat(f), dy: r.height * 0.08 * CGFloat(f))
    }

    /// How far into its panel the picture is: in over `0…a`, back out to the whole frame over `b…1`.
    private static func fold(_ k: Double, in a: Double, out b: Double) -> Double { ease(span(k, 0, a)) * (1 - ease(span(k, b, 1))) }

    /// `img` filling panel `p`, with its black border (`f` thins it away to nothing).
    private static func panel(_ ctx: CGContext, _ img: CGImage, _ p: CGRect, s: CGFloat, border f: Double = 1) {
        ctx.saveGState(); ctx.clip(to: p); ctx.draw(img, in: p); ctx.restoreGState()
        frame(ctx, p, s: s, f: f)
    }

    private static func frame(_ ctx: CGContext, _ p: CGRect, s: CGFloat, f: Double = 1) {
        guard f > 0.01 else { return }
        ctx.setStrokeColor(ink); ctx.setLineWidth(8 * s * CGFloat(f)); ctx.stroke(p)
    }

    /// Takes what's already drawn in `p` back towards the artist's board: `ink` 1 is a hard black-and-white inked
    /// print, `pencil` 1 washes that out to faint blue-grey pencils; both 0 leave the colour alone.
    private static func develop(_ ctx: CGContext, _ p: CGRect, pencil: Double, ink: Double) {
        let inked = CGFloat(clamp(max(ink, pencil))), pencilled = CGFloat(clamp(pencil))
        guard inked > 0.01 else { return }
        ctx.saveGState()
        ctx.clip(to: p)
        ctx.setAlpha(inked)
        ctx.setBlendMode(.saturation); ctx.setFillColor(CGColor(gray: 0.5, alpha: 1)); ctx.fill(p)
        ctx.setBlendMode(.colorBurn); ctx.setFillColor(CGColor(gray: 0.62, alpha: 1)); ctx.fill(p)
        ctx.setBlendMode(.colorDodge); ctx.setFillColor(CGColor(gray: 0.3, alpha: 1)); ctx.fill(p)
        if pencilled > 0.01 {
            ctx.setAlpha(pencilled)
            ctx.setBlendMode(.normal); ctx.setFillColor(CGColor(gray: 1, alpha: 0.64)); ctx.fill(p)
            ctx.setBlendMode(.multiply); ctx.setFillColor(rgb(0x9CC2EC)); ctx.fill(p)
        }
        ctx.restoreGState()
    }

    private static var dotTiles: [Int: CGImage] = [:]
    /// Halftone dots in `hex` over `area`, `cell` pixels apart, each `size` of its cell across: a small tile, tiled.
    private static func dots(_ ctx: CGContext, _ area: CGRect, _ hex: UInt32, alpha: CGFloat, size: CGFloat, cell: CGFloat) {
        guard alpha > 0.01, cell >= 2 else { return }
        let key = Int(hex) << 8 | Int(size * 100)
        if dotTiles[key] == nil, let t = CGContext(data: nil, width: 32, height: 32, bitsPerComponent: 8, bytesPerRow: 0,
                                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            t.setFillColor(rgb(hex))
            let d = 32 * size
            t.fillEllipse(in: CGRect(x: 16 - d / 2, y: 16 - d / 2, width: d, height: d))
            dotTiles[key] = t.makeImage()
        }
        guard let tile = dotTiles[key] else { return }
        ctx.saveGState()
        ctx.clip(to: area); ctx.setAlpha(alpha); ctx.interpolationQuality = .medium
        ctx.draw(tile, in: CGRect(x: area.minX, y: area.minY, width: cell, height: cell), byTiling: true)
        ctx.restoreGState()
    }

    /// Someone from the cast, `size` pixels a sprite pixel, the body's centre at `x` and the feet at `y`.
    private static func figure(_ ctx: CGContext, _ who: Cast, x: CGFloat, feet y: CGFloat, size: CGFloat, facingLeft: Bool = false, t: Double,
                               walking: Bool = false, airborne: Bool = false, angle: CGFloat = 0, alpha: CGFloat = 1) {
        guard alpha > 0.01 else { return }
        let canvas = PixelCanvas(Sprite.width, Sprite.height)
        who.draw(canvas, t: t, mode: .working, walking: walking, role: .none, asSession: false, airborne: airborne)
        canvas.addOutline(C(0x0A0A0A))
        guard let img = canvas.makeImage() else { return }
        ctx.saveGState()
        ctx.interpolationQuality = .none
        ctx.setAlpha(alpha)
        ctx.translateBy(x: x, y: y); ctx.rotate(by: angle)
        if facingLeft { ctx.scaleBy(x: -1, y: 1) }
        // The body's centre is `Sprite.bodyCenterX` from the left, the feet 8 rows up from the bottom.
        ctx.draw(img, in: CGRect(x: -CGFloat(Sprite.bodyCenterX) * size, y: -8 * size,
                                 width: CGFloat(Sprite.width) * size, height: CGFloat(Sprite.height) * size))
        ctx.restoreGState()
    }

    /// A jagged bolt from `a` to `b` in `steps` kinks, each up to `jag` off the straight line; `seed` picks the shape.
    private static func bolt(_ a: CGPoint, _ b: CGPoint, steps: Int, jag: CGFloat, seed: Int) -> CGPath {
        let p = CGMutablePath()
        p.move(to: a)
        let dx = b.x - a.x, dy = b.y - a.y, len = max(hypot(dx, dy), 1), n = CGPoint(x: -dy / len, y: dx / len)
        for i in 1..<max(steps, 2) {
            let t = CGFloat(i) / CGFloat(steps), off = (CGFloat(noise(seed * 97 + i)) - 0.5) * 2 * jag
            p.addLine(to: CGPoint(x: a.x + dx * t + n.x * off, y: a.y + dy * t + n.y * off))
        }
        p.addLine(to: b)
        return p
    }

    /// `path` stroked as energy: a wide glow in `color`, a bright core.
    private static func glow(_ ctx: CGContext, _ path: CGPath, _ color: CGColor, core: CGColor, width: CGFloat, alpha: CGFloat = 1) {
        guard alpha > 0.01 else { return }
        ctx.saveGState()
        ctx.setAlpha(alpha); ctx.setLineJoin(.round); ctx.setLineCap(.round)
        ctx.setShadow(offset: .zero, blur: width * 1.4, color: color)
        ctx.addPath(path); ctx.setStrokeColor(color); ctx.setLineWidth(width); ctx.strokePath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.addPath(path); ctx.setStrokeColor(core); ctx.setLineWidth(width * 0.38); ctx.strokePath()
        ctx.restoreGState()
    }

    /// The first `t` (0…1) of the polyline through `pts`, by length.
    private static func partial(_ pts: [CGPoint], _ t: Double) -> CGPath {
        let p = CGMutablePath()
        guard let first = pts.first, t > 0 else { return p }
        let lengths = zip(pts, pts.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) }
        var left = lengths.reduce(0, +) * CGFloat(min(t, 1))
        p.move(to: first)
        for (i, len) in lengths.enumerated() {
            let a = pts[i], b = pts[i + 1]
            if left >= len { p.addLine(to: b); left -= len; continue }
            p.addLine(to: CGPoint(x: a.x + (b.x - a.x) * left / max(len, 0.001), y: a.y + (b.y - a.y) * left / max(len, 0.001)))
            break
        }
        return p
    }

    /// `r` cut into triangles on a jittered grid, the same cut every frame for a `seed`.
    private static func shards(_ r: CGRect, cols: Int, rows: Int, seed: Int) -> [[CGPoint]] {
        func vertex(_ i: Int, _ j: Int) -> CGPoint {
            let jx = i == 0 || i == cols ? 0 : (CGFloat(noise(seed + i * 131 + j * 17)) - 0.5) * 0.7
            let jy = j == 0 || j == rows ? 0 : (CGFloat(noise(seed + i * 37 + j * 151)) - 0.5) * 0.7
            return CGPoint(x: r.minX + r.width * (CGFloat(i) + jx) / CGFloat(cols), y: r.minY + r.height * (CGFloat(j) + jy) / CGFloat(rows))
        }
        var out: [[CGPoint]] = []
        for i in 0..<cols {
            for j in 0..<rows {
                let a = vertex(i, j), b = vertex(i + 1, j), c = vertex(i + 1, j + 1), d = vertex(i, j + 1)
                out += noise(seed + i * 7 + j * 13) < 0.5 ? [[a, b, c], [a, c, d]] : [[a, b, d], [b, c, d]]
            }
        }
        return out
    }

    /// Each piece of `img` (as drawn over `r`) moved by `move` (offset, turn, scale and opacity, about its middle),
    /// its cut edge stroked.
    private static func scatter(_ ctx: CGContext, _ img: CGImage, in r: CGRect, _ pieces: [[CGPoint]], edge: (Int) -> CGColor, width: CGFloat,
                                move: (Int, CGPoint) -> (offset: CGPoint, angle: CGFloat, scale: CGFloat, alpha: CGFloat)) {
        for (i, poly) in pieces.enumerated() {
            let mid = CGPoint(x: poly.map(\.x).reduce(0, +) / CGFloat(poly.count), y: poly.map(\.y).reduce(0, +) / CGFloat(poly.count))
            let m = move(i, mid)
            guard m.alpha > 0.01 else { continue }
            ctx.saveGState()
            ctx.setAlpha(m.alpha)
            ctx.translateBy(x: mid.x + m.offset.x, y: mid.y + m.offset.y); ctx.rotate(by: m.angle); ctx.scaleBy(x: m.scale, y: m.scale)
            ctx.translateBy(x: -mid.x, y: -mid.y)
            let shape = polygon(poly)
            ctx.saveGState(); ctx.addPath(shape); ctx.clip(); ctx.draw(img, in: r); ctx.restoreGState()
            ctx.addPath(shape); ctx.setStrokeColor(edge(i)); ctx.setLineWidth(width); ctx.setLineJoin(.round); ctx.strokePath()
            ctx.restoreGState()
        }
    }

    private static func polygon(_ pts: [CGPoint]) -> CGPath {
        let p = CGMutablePath()
        p.addLines(between: pts)
        p.closeSubpath()
        return p
    }

    private static func mix(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint { CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t) }

    /// Comic lettering, centred at `c`, tilted by `angle` radians, with a thick outline; never wider than `maxWidth`.
    private static func letters(_ ctx: CGContext, _ text: String, at c: CGPoint, size: CGFloat, maxWidth: CGFloat, angle: CGFloat,
                                fill: CGColor = .white, outline: CGColor = CGColor(gray: 0, alpha: 1)) {
        let fillColor = NSColor(cgColor: fill) ?? .white, lineColor = NSColor(cgColor: outline) ?? .black
        func strings(_ size: CGFloat) -> (NSAttributedString, NSAttributedString) {
            let font = NSFont(name: "Futura-CondensedExtraBold", size: size) ?? .systemFont(ofSize: size, weight: .black)
            return (NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: lineColor, .strokeColor: lineColor, .strokeWidth: 12]),
                    NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: fillColor]))
        }
        var (back, face) = strings(size)
        if face.size().width > maxWidth { (back, face) = strings(size * maxWidth / face.size().width) }
        let sz = face.size()
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: angle)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        back.draw(at: NSPoint(x: -sz.width / 2, y: -sz.height / 2))
        face.draw(at: NSPoint(x: -sz.width / 2, y: -sz.height / 2))
        NSGraphicsContext.restoreGraphicsState()
        ctx.restoreGState()
    }

    /// A yellow caption box ("MEANWHILE, IN …") hanging from its top-left corner at `at`.
    private static func captionBox(_ ctx: CGContext, _ text: String, at: CGPoint, size: CGFloat, maxWidth: CGFloat, s: CGFloat, alpha: CGFloat) {
        var size = size
        func font() -> NSFont { NSFont(name: "AvenirNext-HeavyItalic", size: size) ?? .boldSystemFont(ofSize: size) }
        let pad = size * 0.5
        let width = NSAttributedString(string: text, attributes: [.font: font()]).size().width
        if width > maxWidth - pad * 2 { size *= (maxWidth - pad * 2) / width }
        let str = NSAttributedString(string: text, attributes: [.font: font(), .foregroundColor: NSColor.black])
        let sz = str.size()
        let box = CGRect(x: at.x, y: at.y - sz.height - pad, width: sz.width + pad * 2, height: sz.height + pad)
        ctx.saveGState()
        ctx.setAlpha(alpha)
        ctx.setFillColor(rgb(0xFFE14A)); ctx.fill(box)
        ctx.setStrokeColor(ink); ctx.setLineWidth(max(2, size * 0.12)); ctx.stroke(box)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        str.draw(at: NSPoint(x: box.minX + pad, y: box.minY + pad / 2))
        NSGraphicsContext.restoreGraphicsState()
        ctx.restoreGState()
    }

    /// A jagged comic starburst round `c`, radius `r`, with `n` points dipping to `inner` of the way in.
    private static func starburst(_ c: CGPoint, r: CGFloat, n: Int = 18, seed: Int = 0, inner: CGFloat = 0.62) -> CGPath {
        let p = CGMutablePath()
        for i in 0..<(n * 2) {
            let a = CGFloat(i) / CGFloat(n * 2) * 2 * .pi + 0.1
            let k = i % 2 == 0 ? 1 : inner + 0.12 * CGFloat(noise(i + seed * 31))
            let rr = r * k * (0.9 + 0.2 * CGFloat(noise(i * 7 + seed)))
            let pt = CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }

    // MARK: Props

    /// The bat emblem, `w` wide, centred on `c`.
    private static func bat(_ c: CGPoint, width w: CGFloat) -> CGPath {
        // The right half, from between the ears round the wing to the tail; the left half mirrors it.
        let half: [(CGFloat, CGFloat)] = [(0, 0.10), (0.05, 0.13), (0.075, 0.27), (0.11, 0.12), (0.19, 0.12), (0.30, 0.21), (0.55, 0.29),
                                          (0.84, 0.25), (1.0, 0.08), (0.88, 0.06), (0.80, -0.06), (0.70, -0.03), (0.60, -0.16), (0.48, -0.11),
                                          (0.37, -0.26), (0.25, -0.17), (0.11, -0.32), (0, -0.22)]
        let right = half.map { CGPoint(x: c.x + $0.0 * w / 2, y: c.y + $0.1 * w / 2) }
        let left = half.reversed().dropFirst().dropLast().map { CGPoint(x: c.x - $0.0 * w / 2, y: c.y + $0.1 * w / 2) }
        return polygon(right + left)
    }

    /// A grapnel at `at`, pointing along `angle`: a shaft and three claws.
    private static func grapnel(_ ctx: CGContext, at: CGPoint, angle: CGFloat, size: CGFloat) {
        ctx.saveGState()
        ctx.translateBy(x: at.x, y: at.y); ctx.rotate(by: angle)
        let p = CGMutablePath()
        p.addRect(CGRect(x: -size, y: -size * 0.08, width: size * 1.1, height: size * 0.16))
        p.addLines(between: [CGPoint(x: size * 0.1, y: -size * 0.14), CGPoint(x: size * 0.45, y: 0), CGPoint(x: size * 0.1, y: size * 0.14)])
        p.closeSubpath()
        for side in [-1.0, 0, 1] as [CGFloat] {
            p.move(to: CGPoint(x: size * 0.05, y: side * size * 0.05))
            p.addQuadCurve(to: CGPoint(x: -size * 0.25, y: side * size * 0.42),
                           control: CGPoint(x: size * 0.3, y: side * size * 0.5))
        }
        ctx.addPath(p); ctx.setFillColor(rgb(0x1A1A1E)); ctx.setStrokeColor(rgb(0x1A1A1E)); ctx.setLineWidth(size * 0.12); ctx.setLineCap(.round)
        ctx.drawPath(using: .fillStroke)
        ctx.move(to: CGPoint(x: -size * 0.9, y: size * 0.03)); ctx.addLine(to: CGPoint(x: size * 0.05, y: size * 0.03))
        ctx.setStrokeColor(rgb(0x7A7A86)); ctx.setLineWidth(size * 0.04); ctx.strokePath()
        ctx.restoreGState()
    }

    /// The Lasso of Truth along `path`: glowing gold, braided.
    private static func rope(_ ctx: CGContext, _ path: CGPath, s: CGFloat, alpha: CGFloat) {
        ctx.saveGState()
        ctx.setAlpha(alpha); ctx.setLineJoin(.round); ctx.setLineCap(.round)
        ctx.setShadow(offset: .zero, blur: 24 * s, color: rgb(0xFFD84A))
        ctx.addPath(path); ctx.setStrokeColor(rgb(0xD9A21B)); ctx.setLineWidth(12 * s); ctx.strokePath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.addPath(path); ctx.setStrokeColor(rgb(0xFFE27A)); ctx.setLineWidth(6 * s); ctx.strokePath()
        ctx.addPath(path); ctx.setLineDash(phase: 0, lengths: [5 * s, 9 * s]); ctx.setStrokeColor(rgb(0xA9740E)); ctx.setLineWidth(3 * s); ctx.strokePath()
        ctx.restoreGState()
    }

    /// The Green Lantern symbol: a ring between two bars, glowing.
    private static func lantern(_ ctx: CGContext, at c: CGPoint, radius R: CGFloat, color: CGColor) {
        let ring = CGMutablePath()
        ring.addEllipse(in: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R))
        ring.addEllipse(in: CGRect(x: c.x - R * 0.6, y: c.y - R * 0.6, width: 1.2 * R, height: 1.2 * R))
        let bars = CGMutablePath()
        bars.addRect(CGRect(x: c.x - R * 0.95, y: c.y + R * 0.86, width: 1.9 * R, height: R * 0.28))
        bars.addRect(CGRect(x: c.x - R * 0.95, y: c.y - R * 1.14, width: 1.9 * R, height: R * 0.28))
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: R * 0.6, color: color)
        ctx.addPath(ring); ctx.setFillColor(color); ctx.fillPath(using: .evenOdd)
        ctx.addPath(bars); ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        ctx.addPath(ring); ctx.addPath(bars); ctx.setStrokeColor(rgb(0xD8FFE2)); ctx.setLineWidth(R * 0.06); ctx.strokePath()
        ctx.restoreGState()
    }

    /// A Joker playing card, `w`×`h`, centred on the origin: a grinning Joker on purple, green diamonds behind him.
    private static func jokerFace(_ ctx: CGContext, w: CGFloat, h: CGFloat, s: CGFloat) {
        let card = CGRect(x: -w / 2, y: -h / 2, width: w, height: h), round = w * 0.07
        ctx.addPath(CGPath(roundedRect: card, cornerWidth: round, cornerHeight: round, transform: nil))
        ctx.setFillColor(rgb(0xFFFFFF)); ctx.fillPath()
        ctx.saveGState()
        let inner = card.insetBy(dx: w * 0.08, dy: w * 0.08)
        ctx.addPath(CGPath(roundedRect: inner, cornerWidth: round * 0.6, cornerHeight: round * 0.6, transform: nil)); ctx.clip()
        ctx.setFillColor(rgb(0x4B1D6E)); ctx.fill(inner)
        let step = w * 0.14
        var d = -h
        while d < h { ctx.move(to: CGPoint(x: -w, y: d - w)); ctx.addLine(to: CGPoint(x: w, y: d + w)); ctx.move(to: CGPoint(x: -w, y: d + w)); ctx.addLine(to: CGPoint(x: w, y: d - w)); d += step }
        ctx.setStrokeColor(rgb(0x2E9E4A, 0.55)); ctx.setLineWidth(w * 0.012); ctx.strokePath()
        // Hair, face, eyes, the grin.
        let face = CGRect(x: -w * 0.28, y: -h * 0.2, width: w * 0.56, height: h * 0.46)
        var spikes: [CGPoint] = [CGPoint(x: face.minX - w * 0.04, y: face.midY)]
        for i in 0...8 {
            let a = CGFloat.pi * (1 - CGFloat(i) / 8)
            let rr: CGFloat = i % 2 == 0 ? 1.28 : 1.05
            spikes.append(CGPoint(x: cos(a) * face.width / 2 * rr, y: face.midY + sin(a) * face.height / 2 * rr))
        }
        spikes.append(CGPoint(x: face.maxX + w * 0.04, y: face.midY))
        ctx.addPath(polygon(spikes)); ctx.setFillColor(rgb(0x3FB54A)); ctx.fillPath()
        ctx.addEllipse(in: face); ctx.setFillColor(rgb(0xF3EFE6)); ctx.fillPath()
        ctx.addEllipse(in: face); ctx.setStrokeColor(ink); ctx.setLineWidth(w * 0.012); ctx.strokePath()
        for side in [-1.0, 1.0] as [CGFloat] {
            ctx.saveGState()
            ctx.translateBy(x: side * w * 0.11, y: face.midY + h * 0.06); ctx.rotate(by: side * -0.35)
            ctx.addEllipse(in: CGRect(x: -w * 0.07, y: -h * 0.02, width: w * 0.14, height: h * 0.04)); ctx.setFillColor(rgb(0x121014)); ctx.fillPath()
            ctx.addEllipse(in: CGRect(x: -w * 0.02, y: -h * 0.012, width: w * 0.04, height: h * 0.024)); ctx.setFillColor(rgb(0x7CFC3A)); ctx.fillPath()
            ctx.restoreGState()
        }
        let grin = CGMutablePath()
        let l = CGPoint(x: -w * 0.27, y: face.midY - h * 0.02), rt = CGPoint(x: w * 0.27, y: face.midY - h * 0.02)
        grin.move(to: l)
        grin.addQuadCurve(to: rt, control: CGPoint(x: 0, y: face.minY - h * 0.1))
        grin.addQuadCurve(to: l, control: CGPoint(x: 0, y: face.midY - h * 0.1))
        ctx.addPath(grin); ctx.setFillColor(rgb(0xC8102E)); ctx.fillPath()
        let teeth = CGMutablePath()
        teeth.move(to: CGPoint(x: -w * 0.22, y: face.midY - h * 0.05))
        teeth.addQuadCurve(to: CGPoint(x: w * 0.22, y: face.midY - h * 0.05), control: CGPoint(x: 0, y: face.minY - h * 0.02))
        teeth.addQuadCurve(to: CGPoint(x: -w * 0.22, y: face.midY - h * 0.05), control: CGPoint(x: 0, y: face.midY - h * 0.11))
        ctx.addPath(teeth); ctx.setFillColor(rgb(0xFFFDF0)); ctx.fillPath()
        ctx.saveGState(); ctx.addPath(teeth); ctx.clip()
        for i in -5...5 { ctx.move(to: CGPoint(x: CGFloat(i) * w * 0.04, y: face.minY - h * 0.2)); ctx.addLine(to: CGPoint(x: CGFloat(i) * w * 0.04, y: face.midY)) }
        ctx.move(to: CGPoint(x: -w * 0.3, y: face.midY - h * 0.075)); ctx.addLine(to: CGPoint(x: w * 0.3, y: face.midY - h * 0.075))
        ctx.setStrokeColor(ink); ctx.setLineWidth(w * 0.008); ctx.strokePath()
        ctx.restoreGState()
        ctx.addPath(grin); ctx.setStrokeColor(ink); ctx.setLineWidth(w * 0.012); ctx.strokePath()
        ctx.restoreGState()
        // The corners: a J, upright and upside down.
        let font = NSFont(name: "Futura-CondensedExtraBold", size: h * 0.11) ?? .boldSystemFont(ofSize: h * 0.11)
        let j = NSAttributedString(string: "J", attributes: [.font: font, .foregroundColor: NSColor(srgbRed: 0.78, green: 0.06, blue: 0.18, alpha: 1)])
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        j.draw(at: NSPoint(x: card.minX + w * 0.015, y: card.maxY - h * 0.13))
        ctx.saveGState(); ctx.rotate(by: .pi)
        j.draw(at: NSPoint(x: card.minX + w * 0.015, y: card.maxY - h * 0.13))
        ctx.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
        ctx.addPath(CGPath(roundedRect: card, cornerWidth: round, cornerHeight: round, transform: nil))
        ctx.setStrokeColor(ink); ctx.setLineWidth(max(w * 0.008, 2 * s)); ctx.strokePath()
    }

    /// Harley's mallet, held at `pivot` and swung to `angle`: a long handle, the head `reach` out, sized to the frame.
    private static func mallet(_ ctx: CGContext, pivot: CGPoint, angle: CGFloat, reach: CGFloat, size h: CGFloat) {
        let headLen = h * 0.42, headW = h * 0.24, grip = h * 0.05
        ctx.saveGState()
        ctx.translateBy(x: pivot.x, y: pivot.y); ctx.rotate(by: angle)
        let handle = CGRect(x: 0, y: -grip / 2, width: reach - headW / 2, height: grip)
        ctx.setFillColor(rgb(0x2A2024)); ctx.fill(handle)
        var x: CGFloat = reach - headW / 2 - grip
        var n = 0
        while x > reach - headW / 2 - h * 0.5 {   // the striped wrap up by the head
            ctx.setFillColor(n % 2 == 0 ? rgb(0xD7263D) : rgb(0x111111)); ctx.fill(CGRect(x: x, y: -grip / 2, width: grip, height: grip))
            x -= grip; n += 1
        }
        ctx.setStrokeColor(ink); ctx.setLineWidth(h * 0.006); ctx.stroke(handle)
        let head = CGRect(x: reach - headW / 2, y: -headLen / 2, width: headW, height: headLen)
        let shape = CGPath(roundedRect: head, cornerWidth: headW * 0.18, cornerHeight: headW * 0.18, transform: nil)
        ctx.saveGState(); ctx.addPath(shape); ctx.clip()
        ctx.setFillColor(rgb(0xD7263D)); ctx.fill(CGRect(x: head.minX, y: 0, width: headW, height: headLen / 2))
        ctx.setFillColor(rgb(0x1C1C1C)); ctx.fill(CGRect(x: head.minX, y: head.minY, width: headW, height: headLen / 2))
        ctx.setFillColor(rgb(0xFFFFFF)); ctx.fill(CGRect(x: head.minX, y: -headLen * 0.06, width: headW, height: headLen * 0.12))
        ctx.setFillColor(rgb(0xFFFFFF, 0.25)); ctx.fill(CGRect(x: head.minX + headW * 0.62, y: head.minY, width: headW * 0.14, height: headLen))
        ctx.restoreGState()
        ctx.addPath(shape); ctx.setStrokeColor(ink); ctx.setLineWidth(h * 0.008); ctx.strokePath()
        for end in [head.minY, head.maxY] {
            ctx.addEllipse(in: CGRect(x: head.minX - headW * 0.02, y: end - headW * 0.09, width: headW * 1.04, height: headW * 0.18))
            ctx.setFillColor(rgb(0x6B6B73)); ctx.fillPath()
        }
        ctx.restoreGState()
    }

    /// Doctor Fate's ankh, `h` tall, centred on `c`: the loop (filled even-odd), the bar and shaft, and the loop's hole.
    private static func ankh(_ c: CGPoint, height h: CGFloat) -> (ring: CGPath, solid: CGPath, hole: CGRect) {
        let ring = CGMutablePath()
        ring.addEllipse(in: CGRect(x: c.x - 0.17 * h, y: c.y - 0.02 * h, width: 0.34 * h, height: 0.5 * h))
        let hole = CGRect(x: c.x - 0.085 * h, y: c.y + 0.07 * h, width: 0.17 * h, height: 0.32 * h)
        ring.addEllipse(in: hole)
        let solid = CGMutablePath()
        let bar: [(CGFloat, CGFloat)] = [(-0.4, 0.08), (-0.1, 0.04), (0.1, 0.04), (0.4, 0.08), (0.4, -0.08), (0.1, -0.04), (-0.1, -0.04), (-0.4, -0.08)]
        solid.addPath(polygon(bar.map { CGPoint(x: c.x + $0.0 * h, y: c.y + $0.1 * h) }))
        solid.addPath(polygon([CGPoint(x: c.x - 0.07 * h, y: c.y - 0.02 * h), CGPoint(x: c.x + 0.07 * h, y: c.y - 0.02 * h),
                               CGPoint(x: c.x + 0.13 * h, y: c.y - 0.52 * h), CGPoint(x: c.x - 0.13 * h, y: c.y - 0.52 * h)]))
        return (ring, solid, hole)
    }

    /// Rings of golden hieroglyphs round `c`, out as far as `reach`.
    private static func glyphs(_ ctx: CGContext, around c: CGPoint, reach: CGFloat, s: CGFloat, color: CGColor, alpha: CGFloat) {
        guard alpha > 0.01, reach > 1 else { return }
        let path = CGMutablePath()
        for ring in 1...7 {
            let rr = CGFloat(ring) * 125 * s
            guard rr - 30 * s < reach else { break }
            for edge in [rr - 26 * s, rr + 26 * s] { path.addEllipse(in: CGRect(x: c.x - edge, y: c.y - edge, width: edge * 2, height: edge * 2)) }
            let n = 6 + ring * 4
            for i in 0..<n {
                let a = CGFloat(i) / CGFloat(n) * 2 * .pi + CGFloat(ring) * 0.3
                let at = CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr)
                let t = CGAffineTransform(translationX: at.x, y: at.y).rotated(by: a - .pi / 2).scaledBy(x: 15 * s, y: 15 * s)
                let g = CGMutablePath()
                switch (i + ring) % 5 {
                case 0:   // an eye
                    g.move(to: CGPoint(x: -1, y: 0)); g.addQuadCurve(to: CGPoint(x: 1, y: 0), control: CGPoint(x: 0, y: 0.9))
                    g.addQuadCurve(to: CGPoint(x: -1, y: 0), control: CGPoint(x: 0, y: -0.9))
                    g.addEllipse(in: CGRect(x: -0.28, y: -0.28, width: 0.56, height: 0.56))
                    g.move(to: CGPoint(x: 0, y: -0.45)); g.addLine(to: CGPoint(x: -0.25, y: -1.1))
                case 1:   // a little ankh
                    g.addEllipse(in: CGRect(x: -0.3, y: 0.15, width: 0.6, height: 0.8))
                    g.move(to: CGPoint(x: -0.65, y: 0.1)); g.addLine(to: CGPoint(x: 0.65, y: 0.1))
                    g.move(to: CGPoint(x: 0, y: 0.1)); g.addLine(to: CGPoint(x: 0, y: -1))
                case 2:   // water
                    for row in [-0.45, 0.0, 0.45] as [CGFloat] {
                        g.move(to: CGPoint(x: -1, y: row))
                        for j in 1...8 { g.addLine(to: CGPoint(x: -1 + CGFloat(j) * 0.25, y: row + (j % 2 == 0 ? 0 : 0.18))) }
                    }
                case 3:   // a feather
                    g.move(to: CGPoint(x: 0, y: -1)); g.addLine(to: CGPoint(x: 0, y: 1))
                    g.addEllipse(in: CGRect(x: -0.35, y: -0.35, width: 0.7, height: 1.3))
                default:  // the sun over a pyramid
                    g.addEllipse(in: CGRect(x: -0.35, y: 0.25, width: 0.7, height: 0.7))
                    g.addLines(between: [CGPoint(x: -0.85, y: -0.95), CGPoint(x: 0.85, y: -0.95), CGPoint(x: 0, y: 0.05)]); g.closeSubpath()
                }
                path.addPath(g, transform: t)
            }
        }
        for i in 0..<24 {   // and rays of golden ink between them
            let a = CGFloat(i) / 24 * 2 * .pi
            path.move(to: CGPoint(x: c.x + cos(a) * 90 * s, y: c.y + sin(a) * 90 * s))
            path.addLine(to: CGPoint(x: c.x + cos(a) * reach, y: c.y + sin(a) * reach))
        }
        ctx.saveGState()
        ctx.addEllipse(in: CGRect(x: c.x - reach, y: c.y - reach, width: reach * 2, height: reach * 2)); ctx.clip()
        ctx.setAlpha(alpha); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        ctx.setShadow(offset: .zero, blur: 10 * s, color: color)
        ctx.addPath(path); ctx.setStrokeColor(color); ctx.setLineWidth(3 * s); ctx.strokePath()
        ctx.restoreGState()
    }

    /// Blue and red circuit traces racing in from the edges, `progress` of the way along.
    private static func circuits(_ ctx: CGContext, _ r: CGRect, s: CGFloat, progress: Double, alpha: CGFloat) {
        guard alpha > 0.01, progress > 0 else { return }
        for i in 0..<14 {
            var p = i % 2 == 0 ? CGPoint(x: r.minX, y: r.minY + r.height * CGFloat(noise(i * 7)))
                               : CGPoint(x: r.minX + r.width * CGFloat(noise(i * 7)), y: r.minY)
            var pts = [p], across = i % 2 == 0
            for j in 0..<8 {
                let len = (0.06 + 0.16 * CGFloat(noise(i * 31 + j))) * (across ? r.width : r.height)
                if across { p.x += i % 2 == 0 ? len : (noise(i * 13 + j) < 0.5 ? len : -len) }
                else { p.y += i % 2 == 1 ? len : (noise(i * 13 + j) < 0.5 ? len : -len) }
                pts.append(p)
                across.toggle()
            }
            let t = clamp(progress * 1.4 - noise(i * 3) * 0.4)
            guard t > 0 else { continue }
            let colour = i % 2 == 0 ? rgb(0x2EA8FF) : rgb(0xFF3B3B)
            glow(ctx, partial(pts, t), colour, core: rgb(0xEAF6FF), width: 5 * s, alpha: alpha)
            let reached = Int(Double(pts.count - 1) * t)
            ctx.setAlpha(alpha)
            for q in pts.prefix(reached + 1) { ctx.setFillColor(colour); ctx.fillEllipse(in: CGRect(x: q.x - 6 * s, y: q.y - 6 * s, width: 12 * s, height: 12 * s)) }
            ctx.setAlpha(1)
        }
    }

    /// A speech balloon with `text` in it, centred on `at`.
    private static func balloon(_ ctx: CGContext, _ text: String, at: CGPoint, width w: CGFloat, height h: CGFloat, s: CGFloat) {
        let shape = CGMutablePath()
        shape.addEllipse(in: CGRect(x: at.x - w / 2, y: at.y - h / 2, width: w, height: h))
        shape.addLines(between: [CGPoint(x: at.x - w * 0.12, y: at.y - h * 0.4), CGPoint(x: at.x - w * 0.3, y: at.y - h * 0.85),
                                 CGPoint(x: at.x + w * 0.05, y: at.y - h * 0.45)])
        ctx.addPath(shape); ctx.setFillColor(rgb(0xFFFFFF)); ctx.fillPath()
        ctx.addPath(shape); ctx.setStrokeColor(ink); ctx.setLineWidth(3 * s); ctx.strokePath()
        let font = NSFont(name: "AvenirNext-HeavyItalic", size: h * 0.32) ?? .boldSystemFont(ofSize: h * 0.32)
        let str = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: NSColor.black])
        let sz = str.size()
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        str.draw(at: NSPoint(x: at.x - sz.width / 2, y: at.y - sz.height / 2))
        NSGraphicsContext.restoreGraphicsState()
    }

    /// The multiverse: a purple-black vortex with glowing spiral arms, stars and speed lines, turning with `k`.
    private static func vortex(_ ctx: CGContext, _ r: CGRect, s: CGFloat, k: Double, alpha: CGFloat) {
        let c = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height)
        ctx.setFillColor(rgb(0x07021A)); ctx.fill(r)
        guard alpha > 0.01 else { return }
        ctx.saveGState()
        ctx.setAlpha(alpha)
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(0xF2D9FF), rgb(0x8A3DF0), rgb(0x2A0A5C), rgb(0x07021A, 0)] as CFArray,
                              locations: [0, 0.12, 0.45, 1])!
        ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: far * 0.55, options: [])
        let spin = CGFloat(k) * 5
        let colours = [rgb(0xB44CFF, 0.6), rgb(0x38D9FF, 0.55), rgb(0xFF4FD8, 0.55)]
        for arm in 0..<6 {
            let p = CGMutablePath()
            for i in 0...60 {
                let th = CGFloat(i) / 60 * 4 * .pi, rr = 10 * s * exp(0.33 * th)
                let a = th + CGFloat(arm) * .pi / 3 + spin
                let pt = CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr)
                i == 0 ? p.move(to: pt) : p.addLine(to: pt)
            }
            ctx.addPath(p); ctx.setStrokeColor(colours[arm % 3]); ctx.setLineWidth((5 + 3 * CGFloat(arm % 2)) * s); ctx.strokePath()
        }
        for i in 0..<90 {
            let a = CGFloat(noise(i * 3)) * 2 * .pi + spin * 0.4, d = CGFloat(noise(i * 3 + 1)) * far * 0.55
            let sz = (2 + 4 * CGFloat(noise(i * 3 + 2))) * s
            ctx.setFillColor(rgb(0xFFFFFF, 0.8)); ctx.fillEllipse(in: CGRect(x: c.x + cos(a) * d - sz / 2, y: c.y + sin(a) * d - sz / 2, width: sz, height: sz))
        }
        for i in 0..<50 {
            let a = CGFloat(noise(i * 5 + 300)) * 2 * .pi + spin * 0.2
            ctx.move(to: CGPoint(x: c.x + cos(a) * far * 0.22, y: c.y + sin(a) * far * 0.22))
            ctx.addLine(to: CGPoint(x: c.x + cos(a) * far * 0.6, y: c.y + sin(a) * far * 0.6))
        }
        ctx.setStrokeColor(rgb(0xFFFFFF, 0.14)); ctx.setLineWidth(2 * s); ctx.strokePath()
        ctx.restoreGState()
    }

    /// Panel `n`'s own version of the scene already drawn in `p`: tinted another colour, inked, or in negative.
    private static func variant(_ ctx: CGContext, _ n: Int, _ p: CGRect, amount: CGFloat) {
        ctx.saveGState()
        ctx.clip(to: p)
        ctx.setAlpha(amount)
        switch n % 7 {
        case 1: ctx.setBlendMode(.color); ctx.setFillColor(rgb(0xFF2D55)); ctx.fill(p)
        case 2: ctx.setBlendMode(.color); ctx.setFillColor(rgb(0x2D7CFF)); ctx.fill(p)
        case 3: develop(ctx, p, pencil: 0, ink: Double(amount))
        case 4: ctx.setBlendMode(.difference); ctx.setFillColor(rgb(0xFFFFFF)); ctx.fill(p)
        case 5: ctx.setBlendMode(.color); ctx.setFillColor(rgb(0xC9A060)); ctx.fill(p)
        case 6: ctx.setBlendMode(.color); ctx.setFillColor(rgb(0x39E36A)); ctx.fill(p)
        default: break
        }
        ctx.restoreGState()
    }
}

/// A colour from 0xRRGGBB.
private func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
