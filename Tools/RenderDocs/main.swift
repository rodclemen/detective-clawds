import AppKit

// Renders the README's roster and locations images with the app's own sprite code.
//   swiftc -swift-version 5 Sources/App/{Pixel,Characters,Fights,Roster,Pose,Locations,Cast,Habits}.swift \
//          Sources/App/Art/*.swift Sources/App/Places/*.swift Sources/Shared/*.swift \
//          Tools/RenderDocs/main.swift -o build/renderdocs && build/renderdocs docs

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
let bg = CGColor(red: 0.07, green: 0.075, blue: 0.11, alpha: 1)

func canvas(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
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

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}

func label(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 13, color: NSColor = .white, width: CGFloat = 0) {
    let a = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .semibold), .foregroundColor: color])
    let w = a.size().width
    a.draw(at: NSPoint(x: width > 0 ? x + (width - w) / 2 : x, y: y))
}

/// A character cropped to its outline, drawn at `scale` with its feet on `ground`, centred in a cell.
func put(_ c: PixelCanvas, in ctx: CGContext, cellX: CGFloat, cellW: CGFloat, ground: CGFloat, scale: CGFloat) {
    c.addOutline(C(0xFFFFFF, 0.92))
    guard let b = c.opaqueBounds(), let img = c.makeImage()?.cropping(to: b) else { return }
    let feet = CGFloat(Sprite.height - 44) // canvas rows under the feet
    let bottomGap = CGFloat(Sprite.height) - b.maxY
    ctx.draw(img, in: CGRect(x: cellX + (cellW - b.width * scale) / 2, y: ground + (bottomGap - feet) * scale,
                             width: b.width * scale, height: b.height * scale))
}

// MARK: Roster

let scale: CGFloat = 3, cellW: CGFloat = 190, rowH: CGFloat = 190, cols = 5
let villains = Leader.allCases, heroes = Companion.allCases
let vRows = (villains.count + cols - 1) / cols, hRows = (heroes.count + cols - 1) / cols
let titleH: CGFloat = 54
let rosterH = Int(titleH * 2 + CGFloat(vRows + hRows) * rowH + 20)
let roster = canvas(Int(cellW) * cols, rosterH) { ctx in
    var top = CGFloat(rosterH)
    func section(_ title: String, _ count: Int, rows: Int, _ draw: (Int, PixelCanvas) -> String) {
        top -= titleH
        label(title, 20, top + 16, size: 20, color: NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1))
        for i in 0..<count {
            let c = PixelCanvas(Sprite.width, Sprite.height)
            let name = draw(i, c)
            let x = CGFloat(i % cols) * cellW, rowTop = top - CGFloat(i / cols + 1) * rowH
            put(c, in: ctx, cellX: x, cellW: cellW, ground: rowTop + 34, scale: scale)
            label(name, x, rowTop + 10, width: cellW)
        }
        top -= CGFloat(rows) * rowH
    }
    section("THE HEROES", heroes.count, rows: hRows) { i, c in
        Cast.hero(heroes[i]).draw(c, t: 0.4, mode: .working, walking: false, role: .none, asSession: false)
        return heroes[i].name
    }
    section("THE VILLAINS", villains.count, rows: vRows) { i, c in
        Cast.villain(villains[i]).draw(c, t: 0.62, mode: .working, walking: false, role: .none, asSession: false)
        return villains[i].name
    }
}
save(roster, "roster.png")

// MARK: Desktop

// What it looks like along the bottom of your screen: sessions (name tags) and their agents (task labels) fighting,
// heroes against villains, Superman fighting from the air. The app's own sizes: a session is drawn 3 points per sprite
// pixel, an agent 2; this sheet is twice that, as on a Retina screen.
struct Extra { let who: Cast; let leader: Bool; let label: String; let x: Double; let facing: Double; let role: FightRole
               var up = 0.0 }
let S: CGFloat = 6, gy: CGFloat = 46, momentT = 0.25
let ak = 2.0 / 3
let lineup: [[Extra]] = [
    [Extra(who: .villain(.sinestro), leader: true, label: "Sinestro", x: 30, facing: 1, role: .zap),
     Extra(who: .hero(.superman), leader: true, label: "Superman", x: 98, facing: -1, role: .hit, up: 10)],
    [Extra(who: .hero(.greenArrow), leader: false, label: "Check git history", x: 132, facing: 1, role: .shoot(offset: 0)),
     Extra(who: .villain(.captainCold), leader: false, label: "Write changelog", x: 182, facing: -1, role: .shoot(offset: shotPeriod / 2))],
    [Extra(who: .hero(.batman), leader: false, label: "Plan the refactor", x: 214, facing: 1, role: .duel),
     Extra(who: .villain(.bane), leader: false, label: "Review Overlay.swift", x: 244, facing: -1, role: .duel)],
    [Extra(who: .hero(.wonderWoman), leader: true, label: "Wonder Woman", x: 282, facing: 1, role: .deflect),
     Extra(who: .villain(.lexLuthor), leader: true, label: "Lex Luthor", x: 352, facing: -1, role: .shoot(offset: 0))],
    [Extra(who: .hero(.krypto), leader: false, label: "Run the test suite", x: 388, facing: 1, role: .cheer)],
]
let desktop = canvas(2600, 400) { ctx in
    var tags: [CGRect] = []   // labels already placed: one that would overlap moves up a row, as in the app
    func sprite(_ e: Extra) {
        let c = PixelCanvas(Sprite.width, Sprite.height)
        e.who.draw(c, t: momentT, mode: .working, walking: false, role: e.role, asSession: e.leader, aloft: e.up > 4)
        if e.facing < 0 { c.flipHorizontally() }
        c.addOutline(C(0xFFFFFF, 0.92))
        let k: CGFloat = e.leader ? 1 : CGFloat(ak)
        let bodyX = (e.facing < 0 ? CGFloat(Sprite.width) - CGFloat(Sprite.bodyCenterX) : CGFloat(Sprite.bodyCenterX)) * S * k
        let y = gy + (e.leader ? 0 : 8 * S * (1 - k)) + CGFloat(e.up) * S * k
        ctx.draw(c.makeImage()!, in: CGRect(x: CGFloat(e.x) * S - bodyX, y: y, width: CGFloat(Sprite.width) * S * k,
                                           height: CGFloat(Sprite.height) * S * k))
        // Its label above the head, as the app boxes it: sessions dark grey, agents dark blue.
        let font = e.leader ? NSFont.monospacedSystemFont(ofSize: 20, weight: .bold) : NSFont.monospacedSystemFont(ofSize: 17, weight: .semibold)
        let text = NSAttributedString(string: e.label, attributes: [.font: font, .foregroundColor: NSColor.white])
        let ts = text.size()
        let top = y + CGFloat(Sprite.height - e.who.drawnTop()) * S * k + (e.leader ? 16 : 10)
        var box = CGRect(x: CGFloat(e.x) * S - ts.width / 2 - 10, y: top, width: ts.width + 20, height: ts.height + 8)
        while tags.contains(where: { $0.insetBy(dx: -4, dy: -2).intersects(box) }) { box.origin.y += box.height + 4 }
        tags.append(box)
        let path = CGPath(roundedRect: box, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.addPath(path)
        ctx.setFillColor(e.leader ? CGColor(gray: 0.08, alpha: 0.85) : CGColor(red: 0.05, green: 0.10, blue: 0.24, alpha: 0.85))
        ctx.fillPath()
        ctx.addPath(path)
        ctx.setStrokeColor(e.leader ? CGColor(gray: 1, alpha: 0.35) : CGColor(red: 0.45, green: 0.65, blue: 1, alpha: 0.5))
        ctx.setLineWidth(2); ctx.strokePath()
        text.draw(at: NSPoint(x: box.minX + 10, y: box.minY + 4))
    }
    for group in lineup {
        for e in group where !e.leader { sprite(e) }   // agents first, sessions on top
        for e in group where e.leader { sprite(e) }
        guard group.count == 2 else { continue }
        // The fight between them, from the app's effects code.
        let l = group[0], r = group[1], margin = 24.0, headroom = 24
        let left = l.x - margin, width = Int(r.x - l.x + margin * 2)
        func fighter(_ e: Extra, side: Double) -> Fighter {
            let k = e.leader ? 1 : ak
            return Fighter(weapon: e.who.weapon, x: e.x - left, k: k, top: 44 * (1 - k) - e.up * k + Double(headroom), side: side,
                           muzzle: e.who.muzzle, armoured: e.who.armoured, pivot: e.who.weaponPivot).dressed(as: e.who)
        }
        let fx = PixelCanvas(width, Sprite.height + headroom)
        drawFightFX(fx, t: momentT, left: fighter(l, side: 1), right: fighter(r, side: -1))
        ctx.draw(fx.makeImage()!, in: CGRect(x: CGFloat(left) * S, y: gy, width: CGFloat(width) * S,
                                            height: CGFloat(Sprite.height + headroom) * S))
    }
}
save(desktop, "desktop.png")
print("wrote \(out)/desktop.png")

// MARK: Locations

let lw = 250, lh = 70, lscale: CGFloat = 2, lcols = 3
let locs = Location.allCases
let lRows = (locs.count + lcols - 1) / lcols
let cellLW = CGFloat(lw) * lscale, cellLH = CGFloat(lh) * lscale + 26
let locations = canvas(Int(cellLW) * lcols + (lcols - 1) * 8, Int(cellLH) * lRows) { ctx in
    for (i, l) in locs.enumerated() {
        let c = PixelCanvas(lw, lh); l.drawStatic(c, floorRows: 10)
        let a = PixelCanvas(lw, lh); l.drawAnimated(a, floorRows: 10, t: 1.3)
        let x = CGFloat(i % lcols) * (cellLW + 8), y = CGFloat(lRows - 1 - i / lcols) * cellLH
        ctx.draw(c.makeImage()!, in: CGRect(x: x, y: y + 22, width: cellLW, height: CGFloat(lh) * lscale))
        ctx.draw(a.makeImage()!, in: CGRect(x: x, y: y + 22, width: cellLW, height: CGFloat(lh) * lscale))
        label(l.name, x, y + 4, size: 12, color: NSColor(white: 0.85, alpha: 1), width: cellLW)
    }
}
save(locations, "locations.png")
print("wrote \(out)/roster.png and \(out)/locations.png")

// MARK: Social preview (1280×640, for GitHub → Settings → Social preview)

let social = canvas(1280, 640) { ctx in
    let space = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [CGColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
                                    CGColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(space, start: CGPoint(x: 0, y: 640), end: CGPoint(x: 0, y: 0), options: [])
    for i in 0..<160 {
        let big = noise(i * 3 + 2) > 0.85
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: big ? 0.9 : 0.45))
        let s: CGFloat = big ? 4 : 2
        ctx.fill(CGRect(x: CGFloat(noise(i * 3)) * 1280, y: 200 + CGFloat(noise(i * 3 + 1)) * 440, width: s, height: s))
    }
    ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: 1280, height: 150))
    ctx.setFillColor(CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1)); ctx.fill(CGRect(x: 0, y: 147, width: 1280, height: 4))
    // title
    let yellow = NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1)
    let titleFont = NSFont(name: "Futura-CondensedExtraBold", size: 68) ?? .systemFont(ofSize: 70, weight: .black)
    let title = NSAttributedString(string: "JUSTICE LEAGUE: CLAWD WARS", attributes: [.font: titleFont, .foregroundColor: yellow, .kern: 6])
    title.draw(at: NSPoint(x: (1280 - title.size().width) / 2, y: 470))
    let sub = NSAttributedString(string: "Your Claude Code sessions as a pixel-art DC battle on your desktop",
                                 attributes: [.font: NSFont.systemFont(ofSize: 26, weight: .semibold), .foregroundColor: NSColor(white: 0.9, alpha: 1)])
    sub.draw(at: NSPoint(x: (1280 - sub.size().width) / 2, y: 418))
    // the crew, standing on the horizon
    // Heroes on the left facing right, villains on the right facing them, the whole line centred.
    // Waiting poses: weapons held up, nothing streaming off across the picture.
    func pose(_ who: Cast) -> (PixelCanvas) -> Void {
        { who.draw($0, t: 0.3, mode: .waiting, walking: false, role: .none, asSession: true) }
    }
    let heroes = [Cast.hero(.flash), .hero(.wonderWoman), .hero(.batman), .hero(.superman)].map(pose)
    let villains = [Cast.villain(.joker), .villain(.lexLuthor), .villain(.darkseid), .villain(.sinestro)].map(pose)
    var s: CGFloat = 4, gap: CGFloat = 26, middle: CGFloat = 90
    var sprites: [(img: CGImage, w: CGFloat, h: CGFloat, bottomGap: CGFloat)] = []
    for (i, draw) in (heroes + villains).enumerated() {
        let c = PixelCanvas(Sprite.width, Sprite.height); draw(c)
        if i >= heroes.count { c.flipHorizontally() }
        c.addOutline(C(0xFFFFFF, 0.92))
        guard let b = c.opaqueBounds(), let img = c.makeImage()?.cropping(to: b) else { continue }
        sprites.append((img, b.width * s, b.height * s, CGFloat(Sprite.height) - b.maxY))
    }
    var total = sprites.reduce(0) { $0 + $1.w } + gap * CGFloat(sprites.count - 2) + middle
    if total > 1200 {                       // too wide: shrink everyone (and the spacing) to fit with margins
        let k = 1200 / total
        s *= k; gap *= k; middle *= k; total = 1200
        sprites = sprites.map { ($0.img, $0.w * k, $0.h * k, $0.bottomGap) }
    }
    var x = (1280 - total) / 2
    for (i, sp) in sprites.enumerated() {
        ctx.draw(sp.img, in: CGRect(x: x, y: 150 + (sp.bottomGap - 8) * s, width: sp.w, height: sp.h))
        x += sp.w + (i == heroes.count - 1 ? middle : gap)
    }
}
save(social, "social-preview.png")
print("wrote \(out)/social-preview.png")

// MARK: Screen-saver thumbnail (180×116, Resources/SaverThumbnail.png)

// Gotham at night with Batman and the Joker squaring off on the rooftop, one art pixel per point.
let thumb = canvas(180, 116) { ctx in
    let floor = 18
    let still = PixelCanvas(180, 116); Location.gotham.drawStatic(still, floorRows: floor)
    let moving = PixelCanvas(180, 116); Location.gotham.drawAnimated(moving, floorRows: floor, t: 1.3)
    for img in [still.makeImage(), moving.makeImage()].compactMap({ $0 }) {
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: 180, height: 116))
    }
    let left = Cast.villain(.joker), right = Cast.hero(.batman)
    let (lRole, rRole) = fightRoles(left.weapon, right.weapon)
    // Sprite feet end at row 43 of 52, so the canvas bottom sits 8 rows below the ground line.
    let bottom = CGFloat(floor) - 8
    for (who, role, x, mirrored) in [(left, lRole, 18.0, false), (right, rRole, 162.0, true)] as [(Cast, FightRole, Double, Bool)] {
        let c = PixelCanvas(72, 52)
        who.draw(c, t: 0.55, mode: .working, walking: false, role: role, asSession: true)
        c.addOutline(C(0xFFFFFF, 0.92))
        guard let img = c.makeImage() else { continue }
        ctx.saveGState()
        if mirrored {
            ctx.translateBy(x: CGFloat(x), y: bottom); ctx.scaleBy(x: -1, y: 1)
            ctx.draw(img, in: CGRect(x: 0, y: 0, width: 72, height: 52))
        } else {
            ctx.draw(img, in: CGRect(x: CGFloat(x), y: bottom, width: 72, height: 52))
        }
        ctx.restoreGState()
    }
}
save(thumb, "SaverThumbnail.png")
print("wrote \(out)/SaverThumbnail.png (copy it to Resources/)")
