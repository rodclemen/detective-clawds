import AppKit
import AVFoundation

// Renders the promo with the app's own sprite code: a storyboard sheet of key frames, or the video
// (1920×1080, 30 fps). Build it, then run it from the repo root (it reads Resources/AppIcon.png):
//   swiftc -O -swift-version 5 Sources/App/{Pixel,Characters,Fights,Roster,Pose,Locations,Cast,Habits,Accents,Icon}.swift \
//          Sources/App/Art/*.swift Sources/App/Places/*.swift Sources/Shared/*.swift \
//          Tools/RenderPromo/main.swift -o build/renderpromo
//   build/renderpromo storyboard promo     → storyboard.png + one PNG per key frame
//   build/renderpromo video promo          → justice-league-clawd-wars-promo.mp4 (H.264 + AAC soundtrack)
//   build/renderpromo audio promo          → the soundtrack alone, as a .wav
//   build/renderpromo frame promo 9.5      → a single frame at 9.5 s

let W = 1920, H = 1080, fps = 30.0, duration = 51.2

// The stage the crew stands on. The whole frame by default; window mode narrows it to the scene strip.
var S = 6.0                      // screen pixels per sprite pixel for a session; agents are 2/3 of that
var groundY = 150.0              // fx-row of the floor line (the fx canvas is stageW/S × stageH/S, y down)
var stageW = Double(W), stageH = Double(H)

/// Runs `body` with the stage moved into `rect` (screen coordinates, y up), at `scale`, floor on fx-row `ground`.
func onStage(_ ctx: CGContext, _ rect: CGRect, scale: Double, ground: Double, _ body: () -> Void) {
    let saved = (S, groundY, stageW, stageH)
    ctx.saveGState()
    ctx.translateBy(x: rect.minX, y: rect.minY)
    ctx.clip(to: CGRect(origin: .zero, size: rect.size))
    (S, groundY, stageW, stageH) = (scale, ground, Double(rect.width), Double(rect.height))
    body()
    (S, groundY, stageW, stageH) = saved
    ctx.restoreGState()
}

// MARK: Palette

let yellow = NSColor(srgbRed: 1, green: 0.91, blue: 0.12, alpha: 1)
let claudeOrange = CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1)
func hexColor(_ h: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)
}

/// Every AI Clawd Wars supports, with its outline colour from `AIStyle`.
enum AI: CaseIterable { case claude, desktop, codex, qwen, gemini, copilot
    var hex: UInt32 {
        switch self {
        case .claude: return 0xFFFFFF; case .desktop: return 0xFF9E7A; case .codex: return 0x6FD3FF
        case .qwen: return 0xC08CFF; case .gemini: return 0xFFD166; case .copilot: return 0x7CF5A4
        }
    }
    var ns: NSColor { hexColor(hex) }
    var name: String {
        switch self {
        case .claude: return "Claude Code"; case .desktop: return "Claude Desktop"; case .codex: return "OpenAI Codex"
        case .qwen: return "Qwen Code"; case .gemini: return "Gemini CLI"; case .copilot: return "GitHub Copilot CLI"
        }
    }
    var tag: String {
        switch self {
        case .claude: return "CLAUDE"; case .desktop: return "DESKTOP"; case .codex: return "CODEX"
        case .qwen: return "QWEN"; case .gemini: return "GEMINI"; case .copilot: return "GITHUB\nCOPILOT CLI"
        }
    }
}

// MARK: Easing

func clamp(_ v: Double, _ a: Double = 0, _ b: Double = 1) -> Double { min(max(v, a), b) }
func easeOut(_ v: Double) -> Double { let x = clamp(v); return 1 - pow(1 - x, 3) }
func easeIn(_ v: Double) -> Double { let x = clamp(v); return x * x * x }
func backOut(_ v: Double) -> Double { let x = clamp(v), c = 1.9; return 1 + (c + 1) * pow(x - 1, 3) + c * pow(x - 1, 2) }
func lerp(_ a: Double, _ b: Double, _ f: Double) -> Double { a + (b - a) * f }

// MARK: Actors

struct Actor {
    var cast: Cast
    var x: Double                         // body centre, fx units
    var facing: Double = 1                // +1 right, -1 left
    var session = true                    // sessions are drawn large, agents at 2/3
    var mode: CrewMode = .working
    var role: FightRole = .none
    var walking = false
    var urgent = false
    var bubble: BubbleKind? = nil
    var label: String? = nil
    var labelSize: CGFloat? = nil
    var ai: AI = .claude
    var lift = 0.0                        // fx units off the floor (jumps, drop-ins)
    var alpha = 1.0
    var grow = 1.0                        // extra size (Claude stands a head taller in the line-up)
    var sitting = false
    var airborne = false                  // a flyer in the air
    var k: Double { (session ? 1 : 2.0 / 3) * grow }
    var top: Double { groundY - 44 * k - lift }
    var fighter: Fighter {
        Fighter(weapon: cast.weapon, x: x, k: k, top: top, side: facing, muzzle: cast.muzzle, armoured: cast.armoured,
                pivot: cast.weaponPivot).dressed(as: cast)
    }
}

/// A character's sprite with its AI's outline, for portraits.
func portrait(_ who: Cast, ai: AI, t: Double = 0.4) -> CGImage? {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.draw(c, t: t, mode: .working, walking: false, role: .none, asSession: true)
    c.addOutline(C(ai.hex, 0.92))
    guard let b = c.opaqueBounds() else { return nil }
    return c.makeImage()?.cropping(to: b)
}

/// Draws one actor (sprite, speech bubble, label) into a CG context whose units are screen pixels, y up.
func draw(_ a: Actor, _ ctx: CGContext, t: Double) {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    a.cast.draw(c, t: t, mode: a.mode, walking: a.walking, role: a.role, urgent: a.urgent, sitting: a.sitting,
                asSession: a.session, airborne: a.airborne)
    if a.facing < 0 { c.flipHorizontally() }
    c.addOutline(C(a.ai.hex, 0.92))
    guard let img = c.makeImage() else { return }
    let px = S * a.k
    let x0 = (a.facing > 0 ? a.x - Sprite.bodyCenterX * a.k : a.x - (Double(Sprite.width) - Sprite.bodyCenterX) * a.k) * S
    let yTop = a.top * S
    ctx.saveGState(); ctx.setAlpha(CGFloat(a.alpha))
    ctx.draw(img, in: CGRect(x: x0, y: stageH - yTop - Double(Sprite.height) * px,
                             width: Double(Sprite.width) * px, height: Double(Sprite.height) * px))
    // Speech bubble beside the head, tail pointing back at it.
    if let kind = a.bubble {
        let bc = PixelCanvas(Bubble.width, Bubble.height)
        drawBubble(bc, kind: kind, t: t, urgent: a.urgent, tailRight: a.facing < 0)
        if let bi = bc.makeImage() {
            let headRow = a.top + Double(a.cast.headTop) * a.k
            let bx = a.facing > 0 ? a.x + 7 * a.k : a.x - 7 * a.k - Double(Bubble.width)
            let by = headRow - Double(Bubble.height) + 2
            ctx.draw(bi, in: CGRect(x: bx * S, y: stageH - (by + Double(Bubble.height)) * S,
                                    width: Double(Bubble.width) * S, height: Double(Bubble.height) * S))
        }
    }
    if let l = a.label {
        let headRow = a.top + Double(a.cast.headTop) * a.k
        let z = S / 6
        chip(l, ctx, centerX: a.x * S, bottomY: stageH - headRow * S + (a.session ? 22 : 16) * z,
             size: a.labelSize ?? max(15, (a.session ? 30 : 23) * z), agent: !a.session, accent: a.ai)
    }
    ctx.restoreGState()
}

/// The overlay's label: monospaced white text in a dark rounded box (agents: navy box, blue border).
func chip(_ s: String, _ ctx: CGContext, centerX: Double, bottomY: Double, size: CGFloat, agent: Bool, accent: AI = .claude) {
    let font = NSFont.monospacedSystemFont(ofSize: size, weight: agent ? .semibold : .bold)
    let p = NSMutableParagraphStyle(); p.alignment = .center
    let text = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: NSColor.white, .paragraphStyle: p])
    let ts = text.size()
    let r = CGRect(x: centerX - ts.width / 2 - size * 0.5, y: bottomY, width: ts.width + size, height: ts.height + size * 0.4)
    let path = CGPath(roundedRect: r, cornerWidth: size * 0.3, cornerHeight: size * 0.3, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(agent ? CGColor(red: 0.07, green: 0.12, blue: 0.24, alpha: 0.92) : CGColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 0.88))
    ctx.fillPath()
    ctx.addPath(path); ctx.setLineWidth(size * 0.1)
    let border = agent ? CGColor(red: 0.30, green: 0.48, blue: 0.85, alpha: 1)
                       : (accent == .claude ? CGColor(gray: 0.55, alpha: 1) : accent.ns.cgColor)
    ctx.setStrokeColor(border); ctx.strokePath()
    text.draw(in: CGRect(x: r.minX, y: r.minY + size * 0.2, width: r.width, height: ts.height))
}

/// Bolts, sparks and lightning between pairs, drawn on one fx-resolution pixel canvas over the whole stage.
func drawFX(_ pairs: [(Actor, Actor)], _ ctx: CGContext, t: Double) {
    guard !pairs.isEmpty else { return }
    let c = PixelCanvas(Int(stageW / S) + 1, Int(stageH / S) + 1)
    for (l, r) in pairs where fightFXVisible(t: t, l.cast.weapon, r.cast.weapon) { drawFightFX(c, t: t, left: l.fighter, right: r.fighter) }
    if let img = c.makeImage() {
        ctx.draw(img, in: CGRect(x: 0, y: stageH - Double(c.h) * S, width: Double(c.w) * S, height: Double(c.h) * S))
    }
}

// MARK: Text

func attributed(_ s: String, size: CGFloat, weight: NSFont.Weight = .heavy, color: NSColor = .white, alpha: Double = 1,
                font: NSFont? = nil, kern: CGFloat = 0) -> NSAttributedString {
    let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.6 * alpha)
    shadow.shadowBlurRadius = 12; shadow.shadowOffset = NSSize(width: 0, height: -3)
    return NSAttributedString(string: s, attributes: [.font: font ?? NSFont.systemFont(ofSize: size, weight: weight),
                                                      .foregroundColor: color.withAlphaComponent(alpha), .kern: kern, .shadow: shadow])
}

func text(_ s: String, _ ctx: CGContext, x: Double? = nil, y: Double, size: CGFloat, weight: NSFont.Weight = .heavy,
          color: NSColor = .white, alpha: Double = 1, font: NSFont? = nil, kern: CGFloat = 0) {
    let a = attributed(s, size: size, weight: weight, color: color, alpha: alpha, font: font, kern: kern)
    a.draw(at: NSPoint(x: x ?? (Double(W) - a.size().width) / 2, y: y))
}

/// A caption that slides up and fades in at `start` (shot-local seconds).
func caption(_ s: String, _ ctx: CGContext, local: Double, start: Double = 0.1, y: Double = 900, size: CGFloat = 64,
             color: NSColor = .white, weight: NSFont.Weight = .heavy) {
    let f = easeOut((local - start) / 0.35)
    guard f > 0 else { return }
    text(s, ctx, y: y - 30 * (1 - f), size: size, weight: weight, color: color, alpha: f)
}

/// A small pill naming the mode on show ("DESKTOP MODE", "WINDOW MODE"), top-left.
func modeBadge(_ s: String, _ ctx: CGContext, local: Double) {
    let f = easeOut((local - 0.2) / 0.3)
    guard f > 0 else { return }
    let a = NSAttributedString(string: s, attributes: [.font: NSFont.monospacedSystemFont(ofSize: 26, weight: .heavy),
                                                       .foregroundColor: NSColor.black, .kern: 3])
    let sz = a.size()
    let r = CGRect(x: 60 - 40 * (1 - f), y: 980, width: sz.width + 36, height: sz.height + 16)
    ctx.saveGState(); ctx.setAlpha(CGFloat(f))
    ctx.addPath(CGPath(roundedRect: r, cornerWidth: r.height / 2, cornerHeight: r.height / 2, transform: nil))
    ctx.setFillColor(yellow.cgColor); ctx.fillPath()
    a.draw(at: NSPoint(x: r.minX + 18, y: r.minY + 8))
    ctx.restoreGState()
}

// MARK: Backgrounds

/// The user's desktop: a dusky wallpaper with three terminal windows (dimmed once the battle starts).
func desktop(_ ctx: CGContext, dim: Double, floor: Bool = true) {
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [CGColor(red: 0.20, green: 0.21, blue: 0.29, alpha: 1),
                                CGColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
    // menu bar
    ctx.setFillColor(CGColor(gray: 0, alpha: 0.35)); ctx.fill(CGRect(x: 0, y: H - 34, width: W, height: 34))
    let lines = [["claude ▸ refactor the hook installer", "● Reading HookInstaller.swift", "● Editing 3 files…", "✻ Thinking…"],
                 ["codex ▸ write the changelog", "● Bash(git log --oneline)", "", "Allow this command?  ❯ Yes   No"],
                 ["gemini ▸ shine the Bat-Signal", "✓ Done in 4m 12s", "", "> _"]]
    for i in 0..<3 {
        let r = CGRect(x: 110 + Double(i) * 580, y: 330 + Double(i % 2) * 70, width: 540, height: 360)
        ctx.saveGState(); ctx.setAlpha(CGFloat(1 - dim * 0.75))
        ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: CGColor(gray: 0, alpha: 0.5))
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 14, cornerHeight: 14, transform: nil))
        ctx.setFillColor(CGColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1)); ctx.fillPath()
        ctx.setShadow(offset: .zero, blur: 0)
        trafficLights(ctx, x: r.minX + 18, y: r.maxY - 30)
        for (j, l) in lines[i].enumerated() {
            let col: NSColor = j > 0 ? NSColor(white: 0.8, alpha: 1) : (i == 0 ? NSColor(cgColor: claudeOrange)! : [AI.codex, .gemini][i - 1].ns)
            NSAttributedString(string: l, attributes: [.font: NSFont.monospacedSystemFont(ofSize: 21, weight: .medium),
                                                       .foregroundColor: col])
                .draw(at: NSPoint(x: r.minX + 24, y: r.maxY - 90 - Double(j) * 44))
        }
        ctx.restoreGState()
    }
    // the dark floor band the battle stands on
    if floor {
        ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.14, alpha: dim * 0.55))
        ctx.fill(CGRect(x: 0, y: 0, width: W, height: Int(Double(H) - groundY * S + 6)))
    }
}

func trafficLights(_ ctx: CGContext, x: Double, y: Double, d: Double = 14) {
    for (j, col) in [CGColor(red: 1, green: 0.37, blue: 0.34, alpha: 1), CGColor(red: 1, green: 0.74, blue: 0.18, alpha: 1),
                     CGColor(red: 0.16, green: 0.79, blue: 0.25, alpha: 1)].enumerated() {
        ctx.setFillColor(col); ctx.fillEllipse(in: CGRect(x: x + Double(j) * d * 1.7, y: y, width: d, height: d))
    }
}

func space(_ ctx: CGContext, t: Double) {
    let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [CGColor(red: 0.16, green: 0.10, blue: 0.30, alpha: 1),
                                CGColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
    for i in 0..<220 {
        let big = noise(i * 3 + 2) > 0.85
        let tw = 0.6 + 0.4 * sin(t * 3 + Double(i))
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: (big ? 0.9 : 0.45) * tw))
        let s = big ? 6.0 : 3.0
        let x = (noise(i * 3) * Double(W) - t * (big ? 40 : 20)).truncatingRemainder(dividingBy: Double(W))
        ctx.fill(CGRect(x: x < 0 ? x + Double(W) : x, y: 250 + noise(i * 3 + 1) * Double(H - 250), width: s, height: s))
    }
    ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 240))
    ctx.setFillColor(claudeOrange); ctx.fill(CGRect(x: 0, y: 236, width: W, height: 6))
}

let appIcon: CGImage? = NSImage(contentsOfFile: "Resources/AppIcon.png")?.cgImage(forProposedRect: nil, context: nil, hints: nil)

// MARK: Window mode

/// One card in the window, as the app draws it: portrait, name · project, status pill, a few lines, agents.
struct Card {
    var who: Cast; var ai: AI; var name: String; var project: String
    var status: String; var statusColor: NSColor
    var lines: [(String, NSColor)]
    var agents: [(Cast, String, String, String)] = []   // portrait, name, task, detail
}

let dimText = NSColor(white: 0.62, alpha: 1), bodyText = NSColor(white: 0.9, alpha: 1)

/// Draws a card with its top-left at (x, top); returns its height. `z` scales the app's point sizes.
@discardableResult
func drawCard(_ c: Card, _ ctx: CGContext, x: Double, top: Double, width: Double, panel: NSColor, z: Double) -> Double {
    let pad = 14 * z, lineH = 19 * z, agentH = 36 * z
    let h = pad * 2 + 22 * z + Double(c.lines.count) * lineH + (c.agents.isEmpty ? 0 : 6 * z + Double(c.agents.count) * agentH)
    let r = CGRect(x: x, y: top - h, width: width, height: h)
    let box = CGPath(roundedRect: r, cornerWidth: 8 * z, cornerHeight: 8 * z, transform: nil)
    ctx.addPath(box); ctx.setFillColor((panel.blended(withFraction: 0.35, of: .black) ?? panel).withAlphaComponent(0.94).cgColor); ctx.fillPath()
    ctx.addPath(box); ctx.setStrokeColor(c.ai.ns.withAlphaComponent(0.55).cgColor); ctx.setLineWidth(1.5 * z); ctx.strokePath()

    func put(_ s: NSAttributedString, _ px: Double, _ py: Double) { s.draw(at: NSPoint(x: px, y: py)) }
    func str(_ s: String, _ size: Double, _ w: NSFont.Weight, _ col: NSColor, mono: Bool = false) -> NSAttributedString {
        NSAttributedString(string: s, attributes: [.font: mono ? NSFont.monospacedSystemFont(ofSize: size * z, weight: w)
                                                                : NSFont.systemFont(ofSize: size * z, weight: w), .foregroundColor: col])
    }
    // portrait, pixel-crisp, bottom-centred in a 96×80 (app points) box
    if let img = portrait(c.who, ai: c.ai) {
        let k = (min(96 * z / Double(img.width), 80 * z / Double(img.height), 2 * z)).rounded(.down)
        let w = Double(img.width) * k, ih = Double(img.height) * k
        ctx.saveGState(); ctx.interpolationQuality = .none
        ctx.draw(img, in: CGRect(x: r.minX + 10 * z + (96 * z - w) / 2, y: r.maxY - pad - 80 * z, width: w, height: ih))
        ctx.restoreGState()
    }
    let tx = r.minX + 26 * z + 96 * z
    var ty = r.maxY - pad - 18 * z
    let status = str(c.status, 11, .bold, c.statusColor, mono: true)
    let sw = status.size().width
    let pill = CGRect(x: r.maxX - 12 * z - sw - 14 * z, y: ty - 3 * z, width: sw + 14 * z, height: 19 * z)
    ctx.addPath(CGPath(roundedRect: pill, cornerWidth: 9.5 * z, cornerHeight: 9.5 * z, transform: nil))
    ctx.setFillColor(c.statusColor.withAlphaComponent(0.16).cgColor); ctx.fillPath()
    put(status, pill.minX + 7 * z, pill.minY + 2 * z)
    let header = NSMutableAttributedString(attributedString: str(c.name, 14, .bold, .white))
    header.append(str("  ·  " + c.project, 13, .semibold, c.ai.ns))
    put(header, tx, ty)
    ty -= 22 * z
    for (l, col) in c.lines { put(str(l, 11.5, .regular, col), tx, ty); ty -= lineH }
    if !c.agents.isEmpty {
        ty -= 6 * z
        for (who, name, task, detail) in c.agents {
            if let img = portrait(who, ai: c.ai) {
                let k = (min(36 * z / Double(img.width), 30 * z / Double(img.height))).rounded(.down)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: tx - 4 * z, y: ty - 14 * z, width: Double(img.width) * k, height: Double(img.height) * k))
                ctx.restoreGState()
            }
            let title = NSMutableAttributedString(attributedString: str(name, 11.5, .semibold, .white))
            title.append(str("  ·  " + task, 11.5, .regular, c.ai.ns))
            put(title, tx + 40 * z, ty)
            put(str(detail, 10.5, .regular, dimText), tx + 40 * z, ty - 16 * z)
            ty -= agentH
        }
    }
    return h
}

/// The "Show in Window" window: themed title bar, the place with the crew in it, a card per session.
func windowMode(_ ctx: CGContext, frame r: CGRect, local: Double, t: Double) {
    let loc = Location.batcave
    let panel = loc.panel
    let z = 2.0, cz = 1.5                         // app points → screen pixels (window chrome, cards)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 60, color: CGColor(gray: 0, alpha: 0.6))
    let outline = CGPath(roundedRect: r, cornerWidth: 22, cornerHeight: 22, transform: nil)
    ctx.addPath(outline); ctx.setFillColor((panel.blended(withFraction: 0.45, of: .black) ?? panel).cgColor); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(outline); ctx.clip()
    // title bar
    let barH = 30 * z
    trafficLights(ctx, x: r.minX + 20, y: r.maxY - barH / 2 - 7, d: 15)
    let where_ = NSAttributedString(string: loc.name.uppercased(), attributes: [
        .font: NSFont.systemFont(ofSize: 10.5 * z, weight: .semibold), .foregroundColor: NSColor(white: 0.78, alpha: 1), .kern: 1.2 * z])
    where_.draw(at: NSPoint(x: r.maxX - where_.size().width - 28, y: r.maxY - barH / 2 - where_.size().height / 2))
    // the scene strip: the place at 2 px per pixel in the app, so 4 here
    let px = Double(Scenes.pixel) * z
    let stripH = 100.0 * z
    let strip = CGRect(x: r.minX, y: r.maxY - barH - stripH, width: r.width, height: stripH)
    let cw = Int((strip.width / px).rounded(.up)), ch = Int(stripH / px)
    let floorRows = Int(20 / Double(Scenes.pixel))
    let room = PixelCanvas(cw, ch); loc.drawStatic(room, floorRows: floorRows)
    let live = PixelCanvas(cw, ch); loc.drawAnimated(live, floorRows: floorRows, t: t)
    ctx.saveGState(); ctx.interpolationQuality = .none
    for c in [room, live] { if let img = c.makeImage() { ctx.draw(img, in: CGRect(x: strip.minX, y: strip.minY, width: Double(cw) * px, height: Double(ch) * px)) } }
    ctx.restoreGState()
    // the crew in the scene (sessions at the app's Small size: 2 pt per pixel → 4 px)
    let needsYou = local > 2.5
    onStage(ctx, strip, scale: px, ground: Double(ch) - Double(floorRows) * 0.45) {
        let cap = Actor(cast: .hero(.batman), x: 140, role: .deflect)
        var skull = Actor(cast: .villain(.joker), x: 214, facing: -1, role: .shoot(offset: 0), ai: .codex)
        if needsYou { skull.role = .none; skull.mode = .waiting; skull.bubble = .waiting; skull.urgent = true; skull.lift = abs(sin(t * 2 * .pi * 1.6)) * 4 }
        var c2 = cap; if needsYou { c2.role = .none; c2.mode = .working }
        let spidey = Actor(cast: .hero(.robin), x: 72, session: false, role: .cheer, label: "Run the tests")
        let widow = Actor(cast: .hero(.nightwing), x: 30, session: false, role: .cheer, label: "Check git history")
        let hydra = Actor(cast: .villain(.jokerGoon), x: 290, facing: -1, session: false, ai: .codex)
        for a in [widow, spidey, c2, skull, hydra] { draw(a, ctx, t: t) }
        if !needsYou { drawFX([(cap, skull)], ctx, t: t) }
    }
    // cards
    let ticks = max(0, Int(local))
    let now = ["Now: Read Overlay.swift", "Now: Edit WindowMode.swift", "Now: Bash: swift build"][min(2, max(0, Int(local / 0.9)))]
    var top = strip.minY - 10 * cz
    let x = r.minX + 10 * cz, w = r.width - 20 * cz
    top -= drawCard(Card(who: .hero(.batman), ai: .claude, name: "Batman", project: "idle-claude",
                         status: "WORKING · \(24 + ticks)s", statusColor: NSColor(srgbRed: 0.45, green: 0.85, blue: 0.45, alpha: 1),
                         lines: [("claude-opus-5-5", dimText), (now, bodyText), ("You: “make the batarang come back”", bodyText)],
                         agents: [(.hero(.robin), "Robin", "Run the tests", "Bash: swift test · \(34 + ticks)s · 9 tool calls"),
                                  (.hero(.nightwing), "Nightwing", "Check git history", "Bash: git log · 1m \(21 + ticks)s · 25 tool calls")]),
                    ctx, x: x, top: top, width: w, panel: panel, z: cz) + 10 * cz
    // the Codex group divider, then its card
    let g = NSAttributedString(string: "CODEX", attributes: [.font: NSFont.systemFont(ofSize: 10.5 * cz, weight: .heavy), .kern: 1.2 * cz,
                                                             .foregroundColor: AI.codex.ns])
    let gs = g.size()
    g.draw(at: NSPoint(x: x + 2 * cz, y: top - gs.height - 2 * cz))
    ctx.setFillColor(AI.codex.ns.withAlphaComponent(0.35).cgColor)
    ctx.fill(CGRect(x: x + gs.width + 10 * cz, y: top - gs.height / 2 - 2 * cz, width: w - gs.width - 12 * cz, height: cz))
    top -= 22 * cz
    drawCard(Card(who: .villain(.joker), ai: .codex, name: "The Joker", project: "website",
                  status: needsYou ? "NEEDS YOU · \(max(1, Int(local - 2.5) + 1))s" : "THINKING",
                  statusColor: needsYou ? NSColor(srgbRed: 1, green: 0.42, blue: 0.42, alpha: 1) : NSColor(white: 0.85, alpha: 1),
                  lines: [("gpt-5-codex", dimText), (needsYou ? "Wants to run: npm run chaos" : "Now: Thinking…", bodyText),
                          ("You: “put a smile on that error page”", bodyText)]),
             ctx, x: x, top: top, width: w, panel: panel, z: cz)
    ctx.restoreGState()
}

// MARK: Opening (Gotham's signal, a kaiju over Metropolis, the League assembling)

let fxW = W / 6, fxH = H / 6        // the opening is drawn on 320×180 pixel canvases, 6 px per pixel

/// Draws a pixel canvas onto the screen, crisp: `dy` lifts it (screen pixels), `scale` screen pixels per pixel.
func blit(_ c: PixelCanvas, _ ctx: CGContext, scale: Double = 6, dx: Double = 0, dy: Double = 0) {
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.interpolationQuality = .none
    ctx.draw(img, in: CGRect(x: dx, y: Double(H) - Double(c.h) * scale - dy, width: Double(c.w) * scale, height: Double(c.h) * scale))
    ctx.restoreGState()
}

/// One of the app's places at frame size (or taller), still art plus what moves.
func place(_ l: Location, h: Int = fxH, floorRows: Int, t: Double) -> PixelCanvas {
    let c = PixelCanvas(fxW, h)
    l.drawStatic(c, floorRows: floorRows)
    l.drawAnimated(c, floorRows: floorRows, t: t)
    return c
}

/// A comic caption box: yellow, a thick black border, black italic capitals.
func captionBox(_ s: String, _ ctx: CGContext, center: CGPoint, size: CGFloat, alpha: Double = 1) {
    let font = NSFontManager.shared.convert(NSFont.systemFont(ofSize: size, weight: .black), toHaveTrait: .italicFontMask)
    let a = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: NSColor.black.withAlphaComponent(alpha)])
    let sz = a.size()
    let r = CGRect(x: center.x - sz.width / 2 - size * 0.7, y: center.y - sz.height / 2 - size * 0.45,
                   width: sz.width + size * 1.4, height: sz.height + size * 0.9)
    ctx.saveGState(); ctx.setAlpha(CGFloat(alpha))
    ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(r.offsetBy(dx: 10, dy: -10))
    ctx.setFillColor(CGColor(red: 1, green: 0.88, blue: 0.29, alpha: 1)); ctx.fill(r)
    ctx.setStrokeColor(CGColor(gray: 0, alpha: 1)); ctx.setLineWidth(6); ctx.stroke(r)
    ctx.restoreGState()
    a.draw(at: NSPoint(x: r.minX + size * 0.7, y: r.minY + size * 0.45))
}

/// The title: JUSTICE LEAGUE over CLAWD WARS. `ink` draws it as a plain silhouette (as the Bat-Signal shows it).
func title(_ ctx: CGContext, center: CGPoint, scale s: Double, alpha: Double = 1, ink: NSColor? = nil) {
    let tf = NSFont(name: "Futura-CondensedExtraBold", size: 200) ?? .systemFont(ofSize: 190, weight: .black)
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y); ctx.scaleBy(x: s, y: s)
    for (i, (word, col, size)) in [("JUSTICE LEAGUE", NSColor(srgbRed: 0.22, green: 0.48, blue: 0.95, alpha: alpha), 0.6),
                                   ("CLAWD WARS", yellow.withAlphaComponent(alpha), 1.0)].enumerated() {
        let f = NSFont(descriptor: tf.fontDescriptor, size: 200 * size) ?? tf
        let base: [NSAttributedString.Key: Any] = [.font: f, .kern: 10 * size]
        let sz = NSAttributedString(string: word, attributes: base).size()
        let p = NSPoint(x: -sz.width / 2, y: i == 0 ? 40 : -sz.height + 40)
        if let ink {
            var a = base; a[.foregroundColor] = ink.withAlphaComponent(alpha)
            NSAttributedString(string: word, attributes: a).draw(at: p)
            continue
        }
        var outlined = base; outlined[.foregroundColor] = NSColor.black.withAlphaComponent(alpha)
        var filled = base; filled[.foregroundColor] = col
        let stamp = NSAttributedString(string: word, attributes: outlined), r = 12 * size
        for k in 0..<16 {                                   // a thick, round outline
            let a = Double(k) / 16 * 2 * .pi
            stamp.draw(at: NSPoint(x: p.x + cos(a) * r, y: p.y + sin(a) * r))
        }
        NSAttributedString(string: word, attributes: filled).draw(at: p)
    }
    ctx.restoreGState()
}

/// Gotham at night, two screens tall: the camera tilts up the searchlight's beam to the Bat-Signal on the clouds, pushes
/// in, and the signal switches from the bat to the title.
func openingSignal(_ ctx: CGContext, local l: Double, t: Double) {
    let tallH = 300
    let city = place(.gotham, h: tallH, floorRows: 22, t: t)
    let sig = Scenes.gothamSignal(city, tallH - 22)               // the signal's centre, canvas pixels
    let tilt = clamp(l / 2.2), te = tilt * tilt * (3 - 2 * tilt)
    let off = Double(tallH - fxH) * (1 - te)                     // canvas rows above the top of the frame
    let push = clamp((l - 2.0) / 1.2), pe = push * push * (3 - 2 * push)
    let z = 1 + 2.2 * pe
    // where the signal sits on screen, and the push that brings it to the centre (y up, as CG has it)
    let sx = Double(sig.x) * 6 + 18, sy = Double(H) + off * 6 - Double(sig.y) * 6
    let cx = Double(W) / 2, cy = Double(H) / 2 + 60
    let s = 1 - pe + pe * z
    ctx.saveGState()
    ctx.translateBy(x: pe * (cx - sx * z), y: pe * (cy - sy * z))
    ctx.scaleBy(x: s, y: s)
    blit(city, ctx, dy: -off * 6)
    ctx.restoreGState()
    // the signal clicks over from the bat to the title
    if l > 3.0 {
        let on = clamp((l - 3.0) / 0.25) * (sin(l * 60) > -0.6 || l > 3.5 ? 1 : 0.4)
        ctx.saveGState()
        for (rx, ry, a) in [(760.0, 430.0, 0.10), (640.0, 360.0, 0.16), (560.0, 315.0, 0.95)] {
            ctx.setFillColor(CGColor(red: 0.96, green: 0.93, blue: 0.72, alpha: a * on))
            ctx.fillEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        }
        ctx.restoreGState()
        title(ctx, center: CGPoint(x: cx, y: cy - 20), scale: 0.66, alpha: on, ink: NSColor(srgbRed: 0.08, green: 0.08, blue: 0.11, alpha: 1))
    }
}

/// A kaiju over Metropolis: a colossal horned beast stomps into the city, roars, and Superman flies up to meet it with
/// heat vision.

/// Fills a polygon on a pixel canvas (scanline, even-odd).
func fillPoly(_ c: PixelCanvas, _ pts: [(Double, Double)], _ col: Px) {
    guard let y0 = pts.map({ $0.1 }).min(), let y1 = pts.map({ $0.1 }).max() else { return }
    for y in Int(y0.rounded(.down))...Int(y1.rounded(.up)) {             // rows off the canvas are clipped by rect
        let yy = Double(y) + 0.5
        var xs: [Double] = []
        for i in 0..<pts.count {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            if (a.1 <= yy && b.1 > yy) || (b.1 <= yy && a.1 > yy) { xs.append(a.0 + (yy - a.1) / (b.1 - a.1) * (b.0 - a.0)) }
        }
        xs.sort()
        var i = 0
        while i + 1 < xs.count { c.rect(Int(xs[i].rounded()), y, max(1, Int(xs[i + 1].rounded()) - Int(xs[i].rounded())), 1, col); i += 2 }
    }
}

/// A filled ellipse (centre, radii) that tolerates any size.
func blob(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px) {
    guard rx > 0, ry > 0 else { return }
    for y in Int((cy - ry).rounded(.down))...Int((cy + ry).rounded(.up)) {
        let d = (Double(y) + 0.5 - cy) / ry
        guard abs(d) <= 1 else { continue }
        let half = rx * (1 - d * d).squareRoot()
        c.rect(Int((cx - half).rounded()), y, max(1, Int((half * 2).rounded())), 1, col)
    }
}

/// A horn: a chain of shrinking circles along a curve from the root to the tip, lit along one side.
func horn(_ c: PixelCanvas, from a: (Double, Double), bend b: (Double, Double), to e: (Double, Double), r: Double) {
    for i in 0...24 {
        let u = Double(i) / 24
        let x = (1 - u) * (1 - u) * a.0 + 2 * (1 - u) * u * b.0 + u * u * e.0
        let y = (1 - u) * (1 - u) * a.1 + 2 * (1 - u) * u * b.1 + u * u * e.1
        let rr = max(0.6, r * (1 - u * 0.9))
        blob(c, x, y, rr, rr, C(0xB8AE94))
        blob(c, x - rr * 0.3, y - rr * 0.3, rr * 0.55, rr * 0.55, C(0xECE4CC))
    }
}

/// The kaiju, facing left, on a 120×128 canvas: hulking and upright, slate-green hide with a pale plated belly, a row of
/// bone spines down its back, two great curved horns, burning orange eyes, a jaw that drops open to roar.
let kaijuW = 120, kaijuH = 128                // 18 rows of headroom over the 110-row body for the horns
func drawKaiju(_ c: PixelCanvas, t: Double, roar: Double, step: Double) {
    let hide = C(0x3E4A44), dark = C(0x232B28), lite = C(0x5E6E64), belly = C(0x8C8E70), bellyDark = C(0x6A6C54)
    c.oy = 18; defer { c.oy = 0 }
    let breathe = sin(t * 2.2) * 1.2, lift = -abs(sin(step * .pi)) * 2
    // the tail sweeping out behind, then the far leg
    for i in 0..<10 {
        let u = Double(i) / 9
        blob(c, 86 + u * 28, 92 - u * 16 + sin(t * 1.5 + u * 3) * 2, 11 - u * 8, 9 - u * 6, i % 2 == 0 ? hide : dark)
    }
    blob(c, 74, 90 + lift, 11, 15, dark)
    // the spines down the back
    for i in 0..<8 {
        let u = Double(i) / 7, x = 62 + u * 26, y = 26 + u * 46
        fillPoly(c, [(x - 4, y + 2), (x + 9 - u * 3, y - 10 + u * 3), (x + 4, y + 5)], C(0xD8D0B8))
        fillPoly(c, [(x - 1, y + 3), (x + 6 - u * 3, y - 6 + u * 3), (x + 4, y + 5)], C(0x9A927C))
    }
    // the body, the belly plates
    blob(c, 62, 60 + breathe * 0.5, 28, 32 + breathe, hide)
    blob(c, 70, 58, 18, 26, lite.alpha(0.35))
    blob(c, 54, 64 + breathe * 0.5, 15, 24, belly)
    for k in 0..<7 { c.rect(42, 46 + k * 6 + Int(breathe * 0.5), 26, 1, bellyDark) }
    // the near leg and its claws
    blob(c, 48, 92 + lift, 13, 15, hide)
    blob(c, 44, 104 + lift, 14, 5, dark)
    for k in 0..<3 { fillPoly(c, [(32 + Double(k) * 7, 103 + lift), (29 + Double(k) * 7, 108 + lift), (36 + Double(k) * 7, 106 + lift)], C(0xE8E0C8)) }
    // the arms reaching forward, claws out
    let sway = sin(t * 1.8) * 2
    for (k, (sx, sy)) in [(44.0, 46.0), (52.0, 50.0)].enumerated() {
        let hx = 18.0 + Double(k) * 6, hy = 56 + sway * (k == 0 ? 1 : -1)
        for i in 0...6 { let u = Double(i) / 6; blob(c, sx + (hx - sx) * u, sy + (hy - sy) * u, 7 - u * 2, 6 - u * 2, k == 0 ? hide : dark) }
        for j in 0..<3 { fillPoly(c, [(hx - 2, hy - 3 + Double(j) * 3), (hx - 9, hy - 2 + Double(j) * 3.5), (hx - 2, hy + Double(j) * 3)], C(0xE8E0C8)) }
    }
    // the head: heavy brow, long snout, a jaw that drops open
    let jaw = roar * 9
    let hx = 36.0, hy = 26.0 + breathe * 0.3
    blob(c, hx + 8, hy + 4, 16, 13, hide)                                         // skull
    fillPoly(c, [(hx - 2, hy - 6), (hx - 20, hy + 1), (hx - 18, hy + 6), (hx + 2, hy + 6)], hide)   // snout
    fillPoly(c, [(hx + 2, hy + 6 + jaw * 0.2), (hx - 18, hy + 8 + jaw), (hx - 14, hy + 13 + jaw), (hx + 12, hy + 14)], dark)   // lower jaw
    if roar > 0.1 {                                                               // the open mouth and its teeth
        fillPoly(c, [(hx - 17, hy + 6), (hx + 4, hy + 6), (hx + 4, hy + 7 + jaw * 0.8), (hx - 16, hy + 8 + jaw)], C(0x5A1A14))
        for k in 0..<5 {
            let x = hx - 15 + Double(k) * 4
            fillPoly(c, [(x, hy + 6), (x + 2, hy + 6), (x + 1, hy + 9)], C(0xF0E8D4))
            fillPoly(c, [(x, hy + 8 + jaw * (1 - Double(k) * 0.15)), (x + 2, hy + 8 + jaw * (1 - Double(k) * 0.15)), (x + 1, hy + 5 + jaw * (1 - Double(k) * 0.15))], C(0xF0E8D4))
        }
    }
    c.rect(Int(hx - 12), Int(hy - 6), 22, 3, dark)                                 // the brow ridge
    let glow = 0.75 + 0.25 * sin(t * 7)
    for ex in [hx - 4, hx + 6] {                                                   // burning eyes
        blob(c, ex, hy - 2, 3.2, 2.2, C(0xFF8A1E, 0.5 * glow))
        blob(c, ex, hy - 2, 2, 1.3, C(0xFFE08A, glow))
    }
    // the horns, sweeping up and back from the brow
    horn(c, from: (hx + 4, hy - 8), bend: (hx + 2, hy - 30), to: (hx + 26, hy - 34), r: 4.5)
    horn(c, from: (hx - 6, hy - 8), bend: (hx - 16, hy - 26), to: (hx - 4, hy - 38), r: 4)
}

/// Where the kaiju is (fx units, its feet), how big, and how far through a step, at shot-local time `l`.
func kaijuAt(_ l: Double) -> (x: Double, y: Double, k: Double, step: Double) {
    let f = clamp((l - 0.8) / 5.6), e = f * f * (3 - 2 * f)
    return (lerp(330, 210, e), lerp(150, 190, e), lerp(0.5, 1.45, e), (l - 0.8) / 0.9)
}

func kaijuRoar(_ l: Double) -> Double {
    func pulse(_ at: Double, _ len: Double) -> Double { let u = (l - at) / len; return u > 0 && u < 1 ? sin(u * .pi) : 0 }
    return max(pulse(2.8, 1.6), pulse(6.0, 1.8))
}

func openingInvasion(_ ctx: CGContext, local l: Double, t: Double) {
    // every footfall shakes the frame, harder as it gets closer
    let k = kaijuAt(l)
    let fall = frac(max(0, k.step)), shake = l > 0.8 && l < 6.6 ? max(0, 1 - fall * 4) * 10 * k.k : 0
    ctx.saveGState()
    ctx.translateBy(x: sin(t * 90) * shake, y: cos(t * 77) * shake * 0.6)
    blit(place(.metropolis, floorRows: 14, t: t), ctx)
    // the kaiju, its feet on the street, growing as it comes
    let kc = PixelCanvas(kaijuW, kaijuH)
    drawKaiju(kc, t: t, roar: kaijuRoar(l), step: k.step)
    kc.addOutline(C(AI.codex.hex, 0.92))
    if let img = kc.makeImage() {
        let s = 6 * k.k
        ctx.saveGState(); ctx.interpolationQuality = .none
        ctx.draw(img, in: CGRect(x: k.x * 6 - Double(kaijuW) * s * 0.45, y: Double(H) - k.y * 6, width: Double(kaijuW) * s, height: Double(kaijuH) * s))
        ctx.restoreGState()
    }
    ctx.restoreGState()
    // Superman rockets up from the street and hits it with heat vision
    if l > 3.8 {
        let f = easeOut((l - 3.8) / 1.4)
        onStage(ctx, CGRect(x: 0, y: 0, width: W, height: H), scale: 6, ground: Double(fxH) + 10) {
            var sup = Actor(cast: .hero(.superman), x: lerp(-20, 70, f), facing: 1)
            sup.airborne = true
            sup.lift = lerp(10, 96, f)
            draw(sup, ctx, t: t)
            if l > 5.0 {
                let eyes = sup.fighter.point(sup.cast.muzzle.x, sup.cast.muzzle.y)
                let target = (k.x - 4 * k.k + sin(t * 9) * 2, k.y - 58 * k.k)       // its chest
                let beams = PixelCanvas(fxW, fxH + 10)
                beams.glowLine(eyes.x, eyes.y, target.0, target.1, core: C(0xFFF4D0), glow: C(0xFF3A1E), coreR: 0.8, glowR: 2.4)
                drawSparks(beams, x: target.0, y: target.1, t: t, size: 5)
                if let img = beams.makeImage() {
                    ctx.saveGState(); ctx.interpolationQuality = .none
                    ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(beams.h) * 6, width: Double(beams.w) * 6, height: Double(beams.h) * 6))
                    ctx.restoreGState()
                }
            }
        }
    }
}

/// The Watchtower: the League arrives one by one and lines up in front of the Earth.
func openingLeague(_ ctx: CGContext, local l: Double, t: Double) {
    blit(place(.watchtower, floorRows: 30, t: t), ctx)
    let league: [(Companion, Double, String)] = [(.aquaman, 32, "walk"), (.greenLantern, 74, "fly"), (.wonderWoman, 116, "fly"),
                                                 (.superman, 160, "fly"), (.batman, 204, "rope"), (.flash, 246, "zip"),
                                                 (.cyborg, 288, "walk")]
    onStage(ctx, CGRect(x: 0, y: 0, width: W, height: H), scale: 6, ground: 158) {
        for (i, (who, x, how)) in league.enumerated() {
            let order = [3, 4, 2, 0, 1, 5, 6][i]                       // Superman first, then Batman, Wonder Woman…
            let d = 0.2 + Double(order) * 0.38, f = clamp((l - d) / 0.55)
            guard l > d else { continue }
            var a = Actor(cast: .hero(who), x: x, facing: x < 160 ? 1 : -1, mode: .idle)
            a.grow = 1.15
            switch how {
            case "fly": a.lift = 140 * (1 - easeOut(f)); a.airborne = f < 1
            case "rope": a.lift = 150 * (1 - easeOut(f))
            case "zip": a.x = lerp(-60, x, easeOut(f * 1.6))
            default: a.x = lerp(x < 160 ? -30 : 350, x, easeOut(f)); a.walking = f < 1
            }
            if how == "rope" && f < 1 {                                   // Batman's grapnel line
                let c = PixelCanvas(fxW, fxH + 20)
                c.rect(Int(a.x) + 4, 0, 1, Int(a.top) + 22, C(0x9AA0AE))
                if let img = c.makeImage() { ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(c.h) * 6, width: Double(c.w) * 6, height: Double(c.h) * 6)) }
            }
            if how == "zip" && f < 0.62 {                                  // the Flash's streak
                let c = PixelCanvas(fxW, fxH + 20)
                c.glowLine(0, a.top + 30, a.x - 8, a.top + 30, core: C(0xFFF0A0), glow: C(0xE02A1E), coreR: 1, glowR: 3)
                if let img = c.makeImage() { ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(c.h) * 6, width: Double(c.w) * 6, height: Double(c.h) * 6)) }
            }
            draw(a, ctx, t: t)
        }
    }
}

// MARK: Shots

struct Shot {
    let name: String; let start: Double; let end: Double
    var cut = false                                   // comes in on a hard cut instead of a wipe
    let render: (CGContext, Double, Double) -> Void
}

let shots: [Shot] = [
    // 0a · A comic caption, typed out on black.
    Shot(name: "meanwhile", start: 0, end: 3.5) { ctx, local, t in
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let line = "MEANWHILE, AT THE HALL OF TERMINALS..."
        let n = Int(clamp((local - 0.3) / 1.6) * Double(line.count))
        let a = 1 - clamp((local - 3.0) / 0.4)
        if n > 0 { captionBox(String(line.prefix(n)), ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2), size: 54, alpha: a) }
    },
    // 0b · Gotham at night: up the searchlight's beam to the signal, which switches to the title.
    Shot(name: "signal", start: 3.5, end: 8.0, cut: true) { ctx, local, t in
        openingSignal(ctx, local: local, t: t)
    },
    // 0c · Metropolis: a colossal horned kaiju stomps in and roars; Superman meets it with heat vision.
    Shot(name: "invasion", start: 8.0, end: 16.5, cut: true) { ctx, local, t in
        openingInvasion(ctx, local: local, t: t)
    },
    // 0d · The Watchtower: the League arrives and lines up.
    Shot(name: "league", start: 16.5, end: 21.0, cut: true) { ctx, local, t in
        openingLeague(ctx, local: local, t: t)
    },
    // 1 · The hook: three AIs at work in three terminals, and one overwhelmed human.
    Shot(name: "hook", start: 21.0, end: 25.0) { ctx, local, t in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom)
        ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused human.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    // 2 · Desktop mode: a DC brawl along the bottom of the screen.
    Shot(name: "desktop", start: 25.0, end: 29.6) { ctx, local, t in
        desktop(ctx, dim: easeOut(local / 0.4))
        let drop = { (d: Double) -> Double in max(0, 40 * (1 - easeIn((local - d) / 0.3))) }
        var bat = Actor(cast: .hero(.batman), x: 56, mode: .working, role: .deflect, label: "idle-claude")
        var joker = Actor(cast: .villain(.joker), x: 128, facing: -1, mode: .working, role: .shoot(offset: 0), label: "website", ai: .codex)
        var arrow = Actor(cast: .hero(.greenArrow), x: 196, session: false, role: .shoot(offset: 0), label: "Run the test suite")
        var cold = Actor(cast: .villain(.captainCold), x: 258, facing: -1, session: false, role: .shoot(offset: shotPeriod / 2),
                         label: "Review Overlay.swift", ai: .codex)
        bat.lift = drop(0); joker.lift = drop(0.12); arrow.lift = drop(0.24); cold.lift = drop(0.32)
        for a in [bat, joker, arrow, cold] where a.lift < 40 { draw(a, ctx, t: t) }
        if local > 0.45 { drawFX([(bat, joker), (arrow, cold)], ctx, t: t) }
        modeBadge("DESKTOP MODE", ctx, local: local)
        caption("Now they're a pixel-art DC brawl", ctx, local: local, start: 0.35, y: 900)
        caption("along the bottom of your screen. They fight while they work.", ctx, local: local, start: 0.6, y: 830,
                size: 40, color: yellow, weight: .bold)
    },
    // 3 · Status at a glance: working, thinking, needs you, napping.
    Shot(name: "status", start: 29.6, end: 33.8) { ctx, local, t in
        desktop(ctx, dim: 1)
        let cast: [(Cast, AI, CrewMode, BubbleKind?, String, NSColor, Bool)] = [
            (.hero(.superman), .claude, .working, nil, "WORKING", NSColor(srgbRed: 0.45, green: 0.85, blue: 0.45, alpha: 1), false),
            (.villain(.riddler), .qwen, .thinking, .thinking, "THINKING…", NSColor(white: 0.9, alpha: 1), false),
            (.villain(.harleyQuinn), .gemini, .waiting, .waiting, "NEEDS YOU!", NSColor(srgbRed: 1, green: 0.4, blue: 0.4, alpha: 1), false),
            (.villain(.solomonGrundy), .copilot, .idle, .sleeping, "NAPPING", NSColor(srgbRed: 0.6, green: 0.55, blue: 1, alpha: 1), true),
        ]
        for (i, (who, ai, mode, bubble, word, col, sits)) in cast.enumerated() {
            let d = 0.1 + Double(i) * 0.22
            let f = backOut((local - d) / 0.35)
            guard local > d else { continue }
            var a = Actor(cast: who, x: 48 + Double(i) * 75, mode: mode, bubble: bubble, ai: ai)
            a.sitting = sits
            a.urgent = mode == .waiting
            if a.urgent { a.lift = abs(sin(t * 2 * .pi * 1.6)) * 6 }      // ignored for a minute: it jumps
            a.lift += (1 - f) * -8
            a.alpha = clamp(f)
            draw(a, ctx, t: t)
            let w = NSAttributedString(string: word, attributes: [.font: NSFont.systemFont(ofSize: 40, weight: .black), .kern: 2]).size().width
            text(word, ctx, x: a.x * S - w / 2, y: 70, size: 40, weight: .black, color: col, alpha: clamp(f), kern: 2)
        }
        caption("All fun and games, and you still see everything.", ctx, local: local, start: 0.05, y: 900, size: 58)
        caption("(Solomon Grundy: born on a Monday, napping by Thursday.)", ctx, local: local, start: 0.9, y: 835, size: 36,
                color: yellow, weight: .bold)
    },
    // 4 · Subagents arrive, each labelled with its task.
    Shot(name: "agents", start: 33.8, end: 37.8) { ctx, local, t in
        desktop(ctx, dim: 1)
        draw(Actor(cast: .hero(.wonderWoman), x: 262, facing: -1, mode: .standGuard, label: "idle-claude"), ctx, t: t)
        let crew: [(Companion, String, Double)] = [(.robin, "Find hook events", 190), (.nightwing, "Write changelog", 140),
                                                   (.cyborg, "Check git history", 90), (.krypto, "Plan the refactor", 40)]
        for (i, (who, task, stop)) in crew.enumerated() {
            let d = Double(i) * 0.18
            let f = easeOut((local - d) / 0.75)
            let x = lerp(-30, stop, f)
            draw(Actor(cast: .hero(who), x: x, session: false, walking: f < 0.98, label: task), ctx, t: t)
        }
        caption("Every subagent answers the signal.", ctx, local: local, start: 0.1, y: 900)
        caption("Its job is right there on its label. No more guessing.", ctx, local: local, start: 0.45, y: 835, size: 40,
                color: yellow, weight: .bold)
    },
    // 5 · Window mode: the crew in the Batcave, a live card for every session.
    Shot(name: "window", start: 37.8, end: 42.6) { ctx, local, t in
        desktop(ctx, dim: 1, floor: false)
        let f = easeOut(local / 0.6), s = 0.94 + 0.06 * f
        let base = CGRect(x: 300, y: 20, width: 1320, height: 800)
        let r = CGRect(x: base.midX - base.width * s / 2, y: base.minY + 20 * (1 - f), width: base.width * s, height: base.height * s)
        windowMode(ctx, frame: r, local: local, t: t)
        modeBadge("WINDOW MODE", ctx, local: local)
        caption("Prefer a window? Step into the Batcave.", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4,
                y: 890, size: 32, color: yellow, weight: .bold)
    },
    // 6 · Every AI it supports, Claude first and biggest, each with its own outline. Claude plays the heroes.
    Shot(name: "ais", start: 42.6, end: 47.0) { ctx, local, t in
        desktop(ctx, dim: 1)
        let lineup: [(Cast, AI, Double, Double, FightRole)] = [
            (.hero(.wonderWoman), .desktop, 34, 1, .cheer), (.hero(.superman), .claude, 100, 1, .shoot(offset: 0)),
            (.villain(.lexLuthor), .codex, 174, -1, .shoot(offset: shotPeriod / 2)), (.villain(.sinestro), .qwen, 222, -1, .cheer),
            (.villain(.cheetah), .gemini, 262, -1, .cheer), (.villain(.blackManta), .copilot, 300, -1, .cheer),
        ]
        var actors: [Actor] = []
        for (i, (who, ai, x, facing, role)) in lineup.enumerated() {
            let d = 0.15 + Double(i) * 0.1
            guard local > d else { continue }
            let f = backOut((local - d) / 0.3)
            var a = Actor(cast: who, x: x, facing: facing, role: role, label: ai.tag, ai: ai)
            if ai == .claude { a.grow = 1.25; a.labelSize = 36 } else { a.labelSize = 22 }
            a.lift = (1 - f) * -10; a.alpha = clamp(f)
            actors.append(a)
            draw(a, ctx, t: t)
        }
        if actors.count >= 3 { drawFX([(actors[1], actors[2])], ctx, t: t) }
        let fc = easeOut((local - 0.05) / 0.35)
        if fc > 0 {
            let tf = NSFont(name: "Futura-CondensedExtraBold", size: 140) ?? .systemFont(ofSize: 130, weight: .black)
            text("CLAUDE CODE", ctx, y: 790 - 30 * (1 - fc), size: 140, alpha: fc, font: tf, kern: 8)
        }
        let fr = easeOut((local - 0.35) / 0.35)
        if fr > 0 {
            let row = NSMutableAttributedString(attributedString: attributed("+  ", size: 40, weight: .heavy, color: dimText, alpha: fr))
            for (i, ai) in AI.allCases.dropFirst().enumerated() {
                if i > 0 { row.append(attributed("  ·  ", size: 40, weight: .heavy, color: dimText, alpha: fr)) }
                row.append(attributed(ai.name, size: 40, weight: .heavy, color: ai.ns, alpha: fr))
            }
            row.draw(at: NSPoint(x: (Double(W) - row.size().width) / 2, y: 720 - 20 * (1 - fr)))
        }
        caption("Claude plays the heroes. Everyone else gets to be the villain.", ctx, local: local, start: 0.7, y: 640, size: 40,
                color: yellow, weight: .bold)
    },
    // 7 · End card: Gotham's rooftop under the signal, the Batwing flies through, the title lands.
    Shot(name: "endcard", start: 47.0, end: 51.2) { ctx, local, t in
        blit(place(.gotham, floorRows: 34, t: t), ctx)
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.3)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        // the Batwing streaks across the sky
        let fp = local / 1.2
        if fp > 0 && fp < 1 {
            let bc = PixelCanvas(Ride.width, Ride.height)
            drawRide(bc, .batwing, ramp: 0, engines: true, gear: false)
            bc.addOutline(C(0xFFFFFF, 0.92))
            if let img = bc.makeImage() {
                let x = lerp(-600, Double(W) + 100, easeIn(fp) * 0.6 + fp * 0.4)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: x, y: 600 + 200 * fp, width: Double(Ride.width) * 6, height: Double(Ride.height) * 6))
                ctx.restoreGState()
            }
        }
        // the crew on the rooftop, one of every AI's colours
        let crew: [(Cast, FightRole, AI)] = [(.hero(.wonderWoman), .cheer, .desktop), (.hero(.superman), .shoot(offset: 0), .claude),
                                             (.villain(.lexLuthor), .shoot(offset: shotPeriod / 2), .codex), (.villain(.blackManta), .none, .copilot),
                                             (.villain(.sinestro), .cheer, .qwen), (.villain(.cheetah), .none, .gemini)]
        var placed: [Actor] = []
        for (i, (who, role, ai)) in crew.enumerated() {
            var a = Actor(cast: who, x: [28.0, 84, 156, 206, 252, 296][i], facing: i < 2 ? 1 : -1, role: role, ai: ai)
            a.lift = 8
            a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
            draw(a, ctx, t: t)
            placed.append(a)
        }
        if local > 0.5 { drawFX([(placed[1], placed[2])], ctx, t: t) }
        if local > 0.35 { title(ctx, center: CGPoint(x: Double(W) / 2, y: 760), scale: backOut((local - 0.35) / 0.4) * 0.8) }
        caption("Have fun. Keep track.", ctx, local: local, start: 0.6, y: 520, size: 56)
        caption("Free for macOS", ctx, local: local, start: 0.8, y: 462, size: 34, color: NSColor(white: 0.85, alpha: 1), weight: .bold)
        let ff = easeOut((local - 0.9) / 0.3)
        if ff > 0, let icon = appIcon {
            ctx.setFillColor(CGColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 0.8 * ff)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 170))
            ctx.saveGState(); ctx.setAlpha(CGFloat(ff)); ctx.interpolationQuality = .high
            ctx.draw(icon, in: CGRect(x: 470, y: 20, width: 130, height: 130))
            ctx.restoreGState()
            text("github.com/rodclemen/justice-league-clawd-wars", ctx, x: 630, y: 60, size: 44, weight: .bold, alpha: ff)
        }
    },
]

// MARK: Frame

/// A wipe between shots: a soft, feathered edge travels across the frame at a constant speed,
/// uncovering the next shot behind it while both shots keep playing. Centred on each cut.
let wipe = 2.7, feather = 220.0

/// Greyscale mask that is white (keep the outgoing shot) to the right of `edge`, ramping softly across `feather`.
func wipeMask(edge: Double) -> CGImage {
    var row = [UInt8](repeating: 0, count: W)
    for x in 0..<W { row[x] = UInt8(clamp((Double(x) - edge) / feather + 0.5) * 255) }
    let provider = CGDataProvider(data: Data(row) as CFData)!
    return CGImage(width: W, height: 1, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: W,
                   space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                   provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
}

func renderShot(_ s: Shot, at t: Double, into ctx: CGContext) {
    ctx.saveGState(); s.render(ctx, t - s.start, t); ctx.restoreGState()
}

func frame(_ t: Double) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.interpolationQuality = .none
    if let j = shots.indices.dropFirst().first(where: { !shots[$0].cut && abs(t - shots[$0].start) < wipe / 2 }) {
        // Mid-wipe: the incoming shot underneath, the outgoing one on top, masked to the right of the edge.
        let p = (t - shots[j].start + wipe / 2) / wipe
        let edge = lerp(-feather / 2, Double(W) + feather / 2, p)
        renderShot(shots[j], at: t, into: ctx)
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 0, y: 0, width: W, height: H), mask: wipeMask(edge: edge))
        ctx.interpolationQuality = .none
        renderShot(shots[j - 1], at: t, into: ctx)
        ctx.restoreGState()
    } else {
        renderShot(shots[shots.lastIndex(where: { t >= $0.start }) ?? 0], at: t, into: ctx)
    }
    // fade in from / out to black
    let black = max(1 - t / 0.2, (t - (duration - 0.3)) / 0.3, 0)
    if black > 0 { ctx.setFillColor(CGColor(gray: 0, alpha: black)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H)) }
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep, _ path: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

// MARK: Storyboard sheet

let beats: [(title: String, action: String, onScreen: String, sound: String)] = [
    ("MEANWHILE...", "Black screen. A yellow comic caption types itself out, letter by letter, in the spirit of the old cartoons' narrator.",
     "“MEANWHILE, AT THE HALL OF TERMINALS...”", "typewriter keys, a bell at the end"),
    ("THE SIGNAL", "Hard cut to the app's Gotham at night, rain falling. The camera climbs the searchlight's beam to the Bat-Signal on the clouds and pushes in; with a clunk the bat switches to the title.",
     "JUSTICE LEAGUE / CLAWD WARS, as the signal", "rain, far thunder, a rising line, then the clunk and the big hit"),
    ("THE KAIJU", "Hard cut to the app's Metropolis by day. A colossal horned kaiju stomps in from the right, every step shaking the frame, growing as it comes, and roars. Superman rockets up from the street and hits it in the chest with heat vision; it roars again.",
     "no text", "earth-shaking footfalls, two roars, a whoosh, the heat-vision crackle"),
    ("THE LEAGUE", "The app's Watchtower over the Earth. Superman flies down, Batman drops on his grapnel line, Wonder Woman and Green Lantern land, the Flash zips in, Aquaman and Cyborg walk up, and the seven line up.",
     "no text", "a heroic swell, whooshes, the Flash's zip"),
    ("THE HOOK", "Three busy terminals (Claude, Codex, Gemini) on a dusky Mac desktop, slow push-in. One thinking, one waiting on a permission prompt, one long done.",
     "“Three AIs. Nine agents. One very confused human.”  →  “Sound familiar?”", "keyboard clicks"),
    ("DESKTOP MODE", "Desktop dims; Claude's Batman and Codex's Joker drop onto the bottom edge: the Joker fires, Batman knocks every shot away. Agent Green Arrow trades arrows for Captain Cold's ice.",
     "DESKTOP MODE badge  ·  “Now they're a pixel-art DC brawl along the bottom of your screen. They fight while they work.”", "shots, whacks, arrows, ice"),
    ("AT A GLANCE", "Four sessions pop in, each in its AI's outline: Superman fights, the Riddler's bubble fills with dots, Harley Quinn's red ! jumps, Solomon Grundy sits down and snoozes with zZz.",
     "“All fun and games, and you still see everything.”  ·  “(Solomon Grundy: born on a Monday, napping by Thursday.)”", "one 8-bit blip per pop"),
    ("SUBAGENTS", "Wonder Woman stands guard. Krypto, Cyborg, Nightwing and Robin arrive one after another, each with its task label.",
     "“Every subagent answers the signal.”  ·  “Its job is right there on its label. No more guessing.”", "footsteps, Krypto barking"),
    ("WINDOW MODE", "The app window slides up on the Batcave: Batman knocks away the Joker's shots, Robin and Nightwing cheer; below, live cards whose timers tick. Then the Joker stops, jumps with a red ! and his Codex card flips to NEEDS YOU: he wants to run npm run chaos.",
     "WINDOW MODE badge  ·  “Prefer a window? Step into the Batcave.”  ·  “A live card per session...”", "cave drips, notification ping"),
    ("EVERY AI", "Six sessions pop in, one per AI outline. Claude's Superman stands a head taller and trades heat vision with Codex's Lex Luthor; Wonder Woman (Claude Desktop) and the villains of the other AIs cheer.",
     "CLAUDE CODE (huge)  ·  + Claude Desktop · OpenAI Codex · Qwen Code · Gemini CLI · GitHub Copilot CLI  ·  “Claude plays the heroes. Everyone else gets to be the villain.”", "heat vision crackle"),
    ("END CARD", "Gotham's rooftop under the signal. The Batwing streaks across; the crew lines up in all six colours; the title lands, then the icon and link.",
     "JUSTICE LEAGUE / CLAWD WARS  ·  “Have fun. Keep track.”  ·  Free for macOS  ·  github.com/rodclemen/justice-league-clawd-wars", "Batwing flyby, final sting"),
]

func storyboard(_ frames: [NSBitmapImageRep]) -> NSBitmapImageRep {
    let cols = 2, pw = 900.0, ph = pw * 9 / 16, textH = 260.0, gap = 60.0, margin = 70.0, headH = 200.0
    let rows = (frames.count + cols - 1) / cols
    let sw = Int(margin * 2 + pw * Double(cols) + gap * Double(cols - 1))
    let sh = Int(headH + Double(rows) * (ph + textH) + Double(rows - 1) * gap * 0.5 + margin)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: sw, pixelsHigh: sh, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.setFillColor(CGColor(red: 0.07, green: 0.075, blue: 0.11, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: sw, height: sh))
    func put(_ s: String, _ x: Double, _ y: Double, _ size: CGFloat, _ weight: NSFont.Weight, _ col: NSColor, width: Double = 0) {
        let a = NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: col])
        if width > 0 { a.draw(with: NSRect(x: x, y: y - 200, width: width, height: 200), options: [.usesLineFragmentOrigin]) }   // y = top edge
        else { a.draw(at: NSPoint(x: x, y: y)) }
    }
    let tf = NSFont(name: "Futura-CondensedExtraBold", size: 64) ?? .systemFont(ofSize: 60, weight: .black)
    NSAttributedString(string: "JUSTICE LEAGUE: CLAWD WARS", attributes: [.font: tf, .foregroundColor: yellow, .kern: 5])
        .draw(at: NSPoint(x: margin, y: Double(sh) - 110))
    put(String(format: "%.0f-second promo · storyboard", duration) + " · 1920×1080 · 30 fps · every sprite drawn by the app's own code",
        margin, Double(sh) - 150, 26, .medium, NSColor(white: 0.75, alpha: 1))
    let dim = NSColor(white: 0.62, alpha: 1), body = NSColor(white: 0.92, alpha: 1)
    for (i, f) in frames.enumerated() {
        let s = shots[i], b = beats[i]
        let x = margin + Double(i % cols) * (pw + gap)
        let top = Double(sh) - headH - Double(i / cols) * (ph + textH + gap * 0.5)
        let r = CGRect(x: x, y: top - ph, width: pw, height: ph)
        ctx.saveGState(); ctx.interpolationQuality = .high
        ctx.draw(f.cgImage!, in: r)
        ctx.restoreGState()
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.25)); ctx.setLineWidth(2); ctx.stroke(r)
        let ty = top - ph - 44
        put("\(i + 1)  \(b.title)", x, ty, 30, .heavy, yellow)
        put(String(format: "%.1f - %.1f s", s.start, s.end), x + pw - 170, ty + 2, 26, .semibold, dim)
        put(b.action, x, ty - 14, 21, .regular, body, width: pw)
        put("ON SCREEN  " + b.onScreen, x, ty - 100, 20, .semibold, NSColor(srgbRed: 0.75, green: 0.85, blue: 1, alpha: 1), width: pw)
        put("SOUND  " + b.sound, x, ty - 180, 20, .semibold, dim, width: pw)
    }
    NSGraphicsContext.current = nil
    return rep
}

// MARK: Soundtrack (all synthesized here: an original chiptune score and retro sound effects)

let sampleRate = 44100.0
func hashNoise(_ i: Int) -> Double { noise(i) }   // the sprites' noise, reachable from inside Mix

/// A mono mix bus the whole soundtrack is written into.
final class Mix {
    var buf: [Float]
    init(seconds: Double) { buf = [Float](repeating: 0, count: Int(seconds * sampleRate) + 1) }

    enum Wave { case square(Double), saw, triangle, sine }

    /// One note or sweep: `freq` slides to `to`, with an attack/release envelope and optional vibrato.
    func tone(_ start: Double, _ dur: Double, _ freq: Double, to: Double? = nil, wave: Wave = .square(0.5), vol: Double,
              attack: Double = 0.005, release: Double = 0.05, decay: Double = 0, vibrato: Double = 0) {
        guard start < Double(buf.count) / sampleRate, dur > 0 else { return }
        let n = Int(dur * sampleRate), s0 = Int(max(0, start) * sampleRate)
        var phase = 0.0
        for i in 0..<n {
            let idx = s0 + i
            guard idx < buf.count else { break }
            let tt = Double(i) / sampleRate, p = tt / dur
            var f = to.map { freq * pow($0 / freq, p) } ?? freq
            if vibrato > 0 { f *= 1 + vibrato * sin(tt * 2 * .pi * 5.5) }
            phase += f / sampleRate
            let ph = phase - floor(phase)
            let v: Double
            switch wave {
            case .square(let duty): v = ph < duty ? 1 : -1
            case .saw: v = 2 * ph - 1
            case .triangle: v = ph < 0.5 ? 4 * ph - 1 : 3 - 4 * ph
            case .sine: v = sin(2 * .pi * ph)
            }
            var env = min(1, tt / attack) * min(1, (dur - tt) / release)
            if decay > 0 { env *= exp(-tt / decay) }
            buf[idx] += Float(v * env * vol)
        }
    }

    /// Filtered noise: `cutoff` (0…1, one-pole low-pass amount) slides to `cutoffTo`; `highpass` keeps only the hiss.
    func noise(_ start: Double, _ dur: Double, vol: Double, cutoff: Double = 1, cutoffTo: Double? = nil,
               attack: Double = 0.002, release: Double = 0.05, decay: Double = 0, highpass: Bool = false, seed: Int = 1) {
        let n = Int(dur * sampleRate), s0 = Int(max(0, start) * sampleRate)
        var lp = 0.0, rng = UInt64(seed &* 2654435761 &+ 12345)
        for i in 0..<n {
            let idx = s0 + i
            guard idx < buf.count else { break }
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            let white = Double(Int64(bitPattern: rng >> 11) % 2_000_000) / 1_000_000 - 1
            let tt = Double(i) / sampleRate, p = tt / dur
            let a = cutoffTo.map { cutoff + ($0 - cutoff) * p } ?? cutoff
            lp += (white - lp) * a
            let v = highpass ? white - lp : lp
            var env = min(1, tt / attack) * min(1, max(0, dur - tt) / release)
            if decay > 0 { env *= exp(-tt / decay) }
            buf[idx] += Float(v * env * vol)
        }
    }

    // Sound effects
    func pew(_ t: Double, vol: Double = 0.16) {                       // a gunshot
        tone(t, 0.2, 1900, to: 220, wave: .square(0.5), vol: vol, release: 0.08, decay: 0.09)
        noise(t, 0.05, vol: vol * 0.5, cutoff: 0.6, decay: 0.02)
    }
    func turbolaser(_ t: Double, pitch: Double, vol: Double = 0.1) {
        tone(t, 0.32, 900 * pitch, to: 110 * pitch, wave: .saw, vol: vol, release: 0.1, decay: 0.14)
        noise(t, 0.12, vol: vol * 0.6, cutoff: 0.25, decay: 0.05, seed: Int(t * 100))
    }
    func clash(_ t: Double, vol: Double = 0.2) {                      // blades and fists meeting
        noise(t, 0.22, vol: vol, cutoff: 0.9, decay: 0.06, highpass: true, seed: Int(t * 77))
        tone(t, 0.18, 1400, to: 500, wave: .square(0.3), vol: vol * 0.35, decay: 0.05)
        tone(t, 0.25, 180, to: 120, wave: .saw, vol: vol * 0.4, decay: 0.1)
    }
    func ignite(_ t: Double, vol: Double = 0.14) {
        tone(t, 0.5, 70, to: 120, wave: .saw, vol: vol, attack: 0.02, release: 0.2)
        noise(t, 0.3, vol: vol * 0.5, cutoff: 0.05, cutoffTo: 0.4, decay: 0.15, seed: 9)
    }
    func hum(_ t: Double, _ dur: Double, vol: Double = 0.035) {        // a low hum while weapons are out
        tone(t, dur, 92, wave: .saw, vol: vol, attack: 0.3, release: 0.4, vibrato: 0.01)
        tone(t, dur, 94.5, wave: .saw, vol: vol, attack: 0.3, release: 0.4)
    }
    func boom(_ t: Double, vol: Double = 0.45) {
        tone(t, 1.2, 90, to: 32, wave: .sine, vol: vol, release: 0.4, decay: 0.45)
        noise(t, 0.8, vol: vol * 0.5, cutoff: 0.08, cutoffTo: 0.01, decay: 0.3, seed: Int(t * 13))
    }
    func whoosh(_ center: Double, _ dur: Double, vol: Double = 0.12) {
        noise(center - dur / 2, dur, vol: vol, cutoff: 0.01, cutoffTo: 0.25, attack: dur * 0.5, release: dur * 0.5, seed: Int(center * 31))
    }
    func pop(_ t: Double, step: Int, vol: Double = 0.1) {
        let f = 520 * pow(2, Double(step) * 4 / 12)
        tone(t, 0.09, f, to: f * 1.6, wave: .square(0.25), vol: vol, release: 0.03)
    }
    func ping(_ t: Double, vol: Double = 0.16) {                      // notification
        tone(t, 0.25, 1318.5, wave: .sine, vol: vol, release: 0.2, decay: 0.15)
        tone(t + 0.12, 0.45, 1760, wave: .sine, vol: vol, release: 0.35, decay: 0.2)
    }
    func step(_ t: Double, vol: Double = 0.05) { noise(t, 0.04, vol: vol, cutoff: 0.15, decay: 0.012, seed: Int(t * 997)) }
    func click(_ t: Double, vol: Double = 0.1) {                      // a laptop key
        noise(t, 0.025, vol: vol, cutoff: 0.3, decay: 0.008, highpass: true, seed: Int(t * 541))
        noise(t, 0.03, vol: vol * 0.5, cutoff: 0.15, decay: 0.01, seed: Int(t * 613))
    }
    func r2(_ t: Double, vol: Double = 0.07) {                       // a little droid chirp
        for k in 0..<10 {
            let f = 1100 + hashNoise(Int(t * 10) + k * 3) * 1700
            tone(t + Double(k) * 0.045, 0.05, f, to: f * (hashNoise(k + 4) > 0.5 ? 1.3 : 0.8), wave: .sine, vol: vol, release: 0.01)
        }
    }
    // Drums
    func kick(_ t: Double, vol: Double = 0.3) { tone(t, 0.16, 150, to: 45, wave: .sine, vol: vol, release: 0.05, decay: 0.08) }
    func snare(_ t: Double, vol: Double = 0.12) {
        noise(t, 0.14, vol: vol, cutoff: 0.7, decay: 0.05, seed: Int(t * 61))
        tone(t, 0.08, 220, to: 160, wave: .triangle, vol: vol * 0.5, decay: 0.04)
    }
    func hat(_ t: Double, vol: Double = 0.035) { noise(t, 0.04, vol: vol, cutoff: 0.95, decay: 0.012, highpass: true, seed: Int(t * 173)) }
}

func midi(_ n: Int) -> Double { 440 * pow(2, Double(n - 69) / 12) }

/// Writes 16-bit mono PCM as a WAV file.
func writeWAV(_ samples: [Float], to path: String) {
    var d = Data()
    func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
    func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
    d.append("RIFF".data(using: .ascii)!); u32(UInt32(36 + samples.count * 2)); d.append("WAVEfmt ".data(using: .ascii)!)
    u32(16); u16(1); u16(1); u32(UInt32(sampleRate)); u32(UInt32(sampleRate) * 2); u16(2); u16(16)
    d.append("data".data(using: .ascii)!); u32(UInt32(samples.count * 2))
    var pcm = [Int16](repeating: 0, count: samples.count)
    for i in samples.indices { pcm[i] = Int16(max(-1, min(1, samples[i])) * 32000) }
    pcm.withUnsafeBufferPointer { d.append(Data(buffer: $0)) }
    try! d.write(to: URL(fileURLWithPath: path))
}

func shotStart(_ name: String) -> Double { shots.first { $0.name == name }!.start }

/// Every time the duelling blades meet (the same clock the sparks use) between `a` and `b`.
func clashTimes(_ a: Double, _ b: Double) -> [Double] {
    var out: [Double] = [], was = false
    var t = a
    while t < b {
        let c = duelPose(t).clash
        if c && !was { out.append(t) }
        was = c; t += 1 / 120
    }
    return out
}

/// When a ranged fighter with `offset` fires between `a` and `b` (a bolt leaves at each whole period).
func shotTimes(_ a: Double, _ b: Double, offset: Double) -> [Double] {
    var out: [Double] = []
    var k = ceil((a + offset) / shotPeriod)
    while k * shotPeriod - offset < b { out.append(k * shotPeriod - offset); k += 1 }
    return out
}

// More sound effects
extension Mix {
    func type(_ t: Double, vol: Double = 0.22) {                     // a typewriter key: the strike, then the thunk
        noise(t, 0.04, vol: vol, cutoff: 0.25, decay: 0.012, highpass: true, seed: Int(t * 733))
        noise(t, 0.06, vol: vol * 0.8, cutoff: 0.12, decay: 0.02, seed: Int(t * 977))
        tone(t, 0.05, 150, to: 90, wave: .triangle, vol: vol * 0.7, decay: 0.018)
    }
    func ding(_ t: Double, vol: Double = 0.12) {                     // the bell at the end of the line
        tone(t, 0.9, 2093, wave: .sine, vol: vol, release: 0.6, decay: 0.35)
        tone(t, 0.6, 4186, wave: .sine, vol: vol * 0.3, release: 0.4, decay: 0.2)
    }
    func flip(_ t: Double, vol: Double = 0.06) {                     // a comic page turning
        noise(t, 0.09, vol: vol, cutoff: 0.05, cutoffTo: 0.5, attack: 0.03, release: 0.04, seed: Int(t * 389))
    }
    func clang(_ t: Double, vol: Double = 0.12) {                    // a shot off Cap's shield
        for (f, d) in [(1250.0, 0.35), (1870.0, 0.25), (2930.0, 0.18)] { tone(t, d, f, wave: .sine, vol: vol / 2, release: 0.1, decay: d / 3) }
        noise(t, 0.03, vol: vol * 0.7, cutoff: 0.9, decay: 0.01, highpass: true, seed: Int(t * 91))
    }
    func repulsor(_ t: Double, vol: Double = 0.1) {                  // heat vision or a ring blast
        tone(t, 0.28, 2400, to: 700, wave: .sine, vol: vol, release: 0.1, decay: 0.12)
        noise(t, 0.2, vol: vol * 0.7, cutoff: 0.5, cutoffTo: 0.05, decay: 0.08, seed: Int(t * 57))
    }
    func thwip(_ t: Double, vol: Double = 0.1) {                     // a web shot
        noise(t, 0.12, vol: vol, cutoff: 0.1, cutoffTo: 0.9, attack: 0.01, release: 0.05, seed: Int(t * 211))
        tone(t, 0.1, 600, to: 1600, wave: .triangle, vol: vol * 0.4, release: 0.04)
    }
    func bomb(_ t: Double, vol: Double = 0.1) {                      // a pumpkin bomb: lobbed, then a pop
        tone(t, 0.18, 400, to: 900, wave: .square(0.3), vol: vol * 0.4, release: 0.05)
        noise(t + 0.36, 0.25, vol: vol, cutoff: 0.3, cutoffTo: 0.03, decay: 0.09, seed: Int(t * 17))
    }
    func roar(_ t: Double, _ dur: Double, vol: Double = 0.2) {       // a Leviathan bellowing
        tone(t, dur, 75, to: 48, wave: .saw, vol: vol, attack: 0.15, release: dur * 0.4, vibrato: 0.06)
        tone(t, dur, 112, to: 70, wave: .saw, vol: vol * 0.6, attack: 0.2, release: dur * 0.4, vibrato: 0.08)
        noise(t, dur, vol: vol * 0.7, cutoff: 0.04, cutoffTo: 0.015, attack: 0.15, release: dur * 0.4, seed: Int(t * 3))
    }
    func crackle(_ t: Double, _ dur: Double, vol: Double = 0.05) {   // a magic beam or ring stream
        tone(t, dur, 160, wave: .saw, vol: vol, attack: 0.1, release: 0.2, vibrato: 0.04)
        noise(t, dur, vol: vol * 0.8, cutoff: 0.6, attack: 0.1, release: 0.2, highpass: true, seed: Int(t * 29))
    }
    func groot(_ t: Double, vol: Double = 0.08) {                    // a low, friendly rumble, three notes
        for (k, n) in [43, 45, 40].enumerated() {
            tone(t + Double(k) * 0.22, 0.24, midi(n), wave: .triangle, vol: vol, attack: 0.03, release: 0.08, vibrato: 0.02)
        }
    }
    func jet(_ t: Double, _ dur: Double, vol: Double = 0.06) {       // the Javelin going by
        tone(t, dur, 700, to: 1100, wave: .saw, vol: vol * 0.4, attack: dur * 0.4, release: dur * 0.5)
        noise(t, dur, vol: vol * 2, cutoff: 0.02, cutoffTo: 0.3, attack: dur * 0.45, release: dur * 0.5, seed: 77)
    }
}

/// When a ranged fighter with `offset` lets a shot go between `a` and `b`.
func fireTimes(_ a: Double, _ b: Double, offset: Double) -> [Double] { shotTimes(a, b, offset: offset) }

// DC sound effects
extension Mix {
    func rain(_ t: Double, _ dur: Double, vol: Double = 0.05) {      // a Gotham downpour
        noise(t, dur, vol: vol, cutoff: 0.5, attack: 0.6, release: 0.8, highpass: true, seed: 404)
    }
    func clunk(_ t: Double, vol: Double = 0.25) {                    // the searchlight's shutter thrown open
        tone(t, 0.12, 90, to: 50, wave: .square(0.4), vol: vol, decay: 0.05)
        noise(t, 0.08, vol: vol * 0.6, cutoff: 0.3, decay: 0.03, seed: 41)
    }
    func boomTube(_ t: Double, vol: Double = 0.3) {                  // space torn open
        boom(t, vol: vol)
        noise(t, 0.9, vol: vol * 0.5, cutoff: 0.9, decay: 0.3, highpass: true, seed: 66)
        tone(t, 0.8, 1800, to: 120, wave: .saw, vol: vol * 0.25, release: 0.3)
    }
    func buzz(_ t: Double, vol: Double = 0.03) {                     // a Parademon's wings
        tone(t, 0.35, 160 + hashNoise(Int(t * 10)) * 60, wave: .square(0.2), vol: vol, attack: 0.05, release: 0.15, vibrato: 0.1)
    }
    func ice(_ t: Double, vol: Double = 0.08) {                      // Captain Cold's cold gun
        noise(t, 0.3, vol: vol, cutoff: 0.6, attack: 0.02, release: 0.15, highpass: true, seed: Int(t * 97))
        tone(t, 0.3, 3200, to: 2600, wave: .sine, vol: vol * 0.3, release: 0.15)
    }
    func bark(_ t: Double, vol: Double = 0.1) {                      // Krypto, twice
        for k in 0..<2 {
            tone(t + Double(k) * 0.22, 0.12, 520, to: 300, wave: .square(0.35), vol: vol, release: 0.05, decay: 0.06)
            noise(t + Double(k) * 0.22, 0.08, vol: vol * 0.5, cutoff: 0.2, decay: 0.03, seed: k + 12)
        }
    }
}

func soundtrack() -> [Float] {
    let m = Mix(seconds: duration)
    let half = wipe / 2

    // ── Opening ────────────────────────────────────────────────────────────────
    // "Meanwhile…": a key for every letter as the caption types itself out, and the bell.
    let mw = shotStart("meanwhile")
    let line = 38.0
    for i in 0..<38 { m.type(mw + 0.3 + Double(i) / line * 1.6 + noise(i) * 0.02, vol: 0.18 + noise(i + 50) * 0.08) }
    m.ding(mw + 2.0)
    m.tone(mw + 0.2, 3.0, midi(33), wave: .sine, vol: 0.05, attack: 1.0, release: 0.8)          // a low drone

    // Gotham: rain and distant thunder, a slow climb up the beam, then the signal clunks over to the title and the
    // fanfare hits.
    let sg = shotStart("signal")
    m.rain(sg, 4.5 + wipe / 2)
    m.boom(sg + 0.4, vol: 0.12)                                                                 // far thunder
    for (k, n) in [45, 48, 52, 55, 57].enumerated() {                                           // the climb
        m.tone(sg + 0.3 + Double(k) * 0.5, 0.9, midi(n), wave: .triangle, vol: 0.05, attack: 0.1, release: 0.4)
    }
    let hit = sg + 3.0
    m.clunk(hit - 0.12)
    m.boom(hit, vol: 0.55)
    m.noise(hit, 1.6, vol: 0.12, cutoff: 0.9, decay: 0.5, highpass: true, seed: 3)
    for n in [45, 52, 57, 60, 64] { m.tone(hit, 1.2, midi(n), wave: .saw, vol: 0.05, release: 0.6, decay: 0.7) }
    for (s, d, n) in [(0.25, 0.22, 64), (0.5, 0.22, 69), (0.75, 0.5, 72), (1.3, 0.6, 71)] as [(Double, Double, Int)] {
        m.tone(hit + s, d, midi(n + 12), wave: .square(0.5), vol: 0.07, release: 0.08, vibrato: 0.006)
        m.tone(hit + s, d, midi(n), wave: .saw, vol: 0.045, release: 0.08)
    }

    // Metropolis: the kaiju's footfalls shake the city, it roars, Superman takes off,
    // and his heat vision hits it.
    let inv = shotStart("invasion")
    for i in 0..<Int((8.5 + wipe / 2) / 0.25) {
        let grow = min(1, Double(i) / 30)
        m.tone(inv + Double(i) * 0.25, 0.22, midi(i % 8 == 7 ? 37 : 36), wave: .square(0.25), vol: 0.04 + 0.06 * grow, release: 0.04)
    }
    for (s, chord) in [(0.0, [48, 51, 55]), (2.0, [44, 48, 51]), (4.0, [46, 50, 53]), (6.0, [48, 51, 55]), (7.0, [43, 47, 50])] {
        for n in chord { m.tone(inv + s, 1.8, midi(n), wave: .saw, vol: 0.035, attack: 0.05, release: 0.6) }
    }
    var step = 0.8                                                                           // its footfalls
    while step < 6.6 { m.boom(inv + step, vol: 0.14 + (step / 6.6) * 0.22); step += 0.9 }
    m.roar(inv + 2.8, 1.6, vol: 0.26)                                                        // the first roar
    m.roar(inv + 6.0, 1.8, vol: 0.32)                                                        // and when the beam lands
    m.noise(inv + 3.0, 6.5, vol: 0.28, cutoff: 0.004, cutoffTo: 0.03, attack: 3.0, release: 1.5, seed: 5)
    m.tone(inv + 3.0, 6.5, 41, wave: .sine, vol: 0.16, attack: 3.0, release: 1.5)
    m.whoosh(inv + 4.4, 1.4, vol: 0.18)                                                      // Superman takes off
    m.crackle(inv + 5.0, 3.5 + wipe / 2, vol: 0.06)                                          // heat vision
    m.tone(inv + 5.0, 3.5, 220, to: 180, wave: .saw, vol: 0.03, attack: 0.2, release: 1, vibrato: 0.05)

    // The Watchtower: a heroic swell as the League arrives, a whoosh for every flyer and the Flash's zip.
    let lg = shotStart("league")
    for k in 0..<10 { m.tone(lg - 0.5 + Double(k) * 0.05, 0.08, 70, to: 55, wave: .sine, vol: 0.05 + Double(k) * 0.012, decay: 0.05) }
    for (s, d, chord) in [(0.0, 1.1, [48, 52, 55, 60]), (1.1, 1.1, [41, 45, 48, 53]), (2.2, 1.1, [43, 47, 50, 55]), (3.3, 1.6, [48, 52, 55, 60])] {
        for n in chord { m.tone(lg + s, d, midi(n), wave: .saw, vol: 0.035, attack: 0.15, release: 0.4) }
        m.tone(lg + s, d, midi(chord[0] - 12), wave: .sine, vol: 0.16, attack: 0.05, release: 0.4)
    }
    for (s, d, n) in [(0.2, 0.4, 67), (0.6, 0.5, 72), (1.1, 0.9, 74), (2.2, 0.4, 71), (2.6, 0.5, 74), (3.3, 1.4, 79)] as [(Double, Double, Int)] {
        m.tone(lg + s, d, midi(n), wave: .square(0.5), vol: 0.06, attack: 0.02, release: 0.12, vibrato: 0.006)
    }
    for order in 0..<7 { m.whoosh(lg + 0.2 + Double(order) * 0.38 + 0.3, 0.5, vol: 0.08) }
    m.tone(lg + 0.2 + 5 * 0.38, 0.3, 300, to: 2400, wave: .saw, vol: 0.05, release: 0.1)        // the Flash

    // ── The promo: an original chiptune groove, Am F C G ────────────────────────
    let g0 = shotStart("hook"), beat = 0.5, bar = 2.0
    let roots = [45, 41, 48, 43]
    let triads = [[69, 72, 76], [65, 69, 72], [67, 72, 76], [67, 71, 74]]
    let melodyA: [[(Int, Double)]] = [[(76, 1), (81, 1), (84, 0.5), (83, 0.5), (81, 1)], [(84, 1), (81, 1), (77, 0.5), (79, 0.5), (81, 1)],
                                      [(79, 1), (76, 0.5), (79, 0.5), (84, 1), (83, 1)], [(86, 1), (83, 1), (79, 2)]]
    let melodyB: [[(Int, Double)]] = [[(81, 0.5), (84, 0.5), (88, 1), (86, 0.5), (84, 0.5), (83, 1)], [(81, 1.5), (84, 0.5), (81, 1), (77, 1)],
                                      [(79, 0.5), (81, 0.5), (79, 0.5), (76, 0.5), (79, 1), (84, 1)], [(83, 1), (86, 1), (91, 2)]]
    let grooveBars = Int(((shotStart("endcard") - g0) / bar).rounded())
    for b in 0..<grooveBars {
        let t0 = g0 + Double(b) * bar, c = b % 4
        let full = b >= 2
        for e in 0..<8 {
            m.tone(t0 + Double(e) * beat / 2, beat / 2 * 0.9, midi(roots[c] - 12 + (e % 2) * 12), wave: .square(0.25),
                   vol: full ? 0.075 : 0.05, release: 0.02)
            m.hat(t0 + Double(e) * beat / 2, vol: e % 2 == 1 ? 0.04 : 0.025)
        }
        m.kick(t0)
        if full {
            m.kick(t0 + 2 * beat); m.kick(t0 + 2.5 * beat, vol: 0.18)
            m.snare(t0 + beat); m.snare(t0 + 3 * beat)
            for s in 0..<16 {
                m.tone(t0 + Double(s) * beat / 4, beat / 4 * 0.8, midi(triads[c][s % 3] - 12 + (s / 3 % 2) * 12),
                       wave: .triangle, vol: 0.03, release: 0.02)
            }
            let phrase = (b - 2) / 4 % 2 == 0 ? melodyA : melodyB
            var tt = t0
            for (n, d) in phrase[c] {
                m.tone(tt, d * beat * 0.92, midi(n), wave: .square(0.5), vol: 0.055, release: 0.04, vibrato: 0.004)
                tt += d * beat
            }
        }
        if b == grooveBars - 1 {
            for k in 0..<8 { m.snare(t0 + 2 * beat + Double(k) * beat / 4, vol: 0.06 + Double(k) * 0.01) }
        }
    }

    // ── End card: a heroic cadence, F G A ────────────────────────────────────────
    let end = shotStart("endcard")
    for (s, d, chord, lead) in [(0.0, 0.7, [53, 57, 60, 65], 81), (0.7, 0.7, [55, 59, 62, 67], 83), (1.4, 2.8, [57, 61, 64, 69], 85)] {
        for n in chord { m.tone(end + s, d, midi(n), wave: .saw, vol: 0.045, attack: 0.02, release: d > 1 ? 1.6 : 0.1) }
        m.tone(end + s, d, midi(lead), wave: .square(0.5), vol: 0.06, release: d > 1 ? 1.6 : 0.1, vibrato: 0.006)
        m.tone(end + s, d, midi(chord[0] - 24), wave: .sine, vol: 0.2, release: d > 1 ? 1.6 : 0.1)
    }
    m.boom(end + 0.35, vol: 0.45)
    m.noise(end + 1.4, 2.5, vol: 0.08, cutoff: 0.9, decay: 0.8, highpass: true, seed: 8)
    m.jet(end, 1.2, vol: 0.08)                                                               // the Javelin goes by
    m.crackle(end + 0.5, duration - end - 0.5, vol: 0.025)                                  // the beams still at it

    // ── Sound effects in the promo ──────────────────────────────────────────────
    for s in shots.dropFirst() where !s.cut { m.whoosh(s.start, wipe, vol: 0.07) }

    let hook = shotStart("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }

    let desk = shotStart("desktop")                       // drop-ins; the Joker shoots, Batman knocks it away; arrows and ice
    for (i, d) in [0.0, 0.12, 0.24, 0.32].enumerated() { m.step(desk + d + 0.3, vol: 0.1 + Double(i % 2) * 0.03) }
    let deskEnd = shotStart("status") + half
    for t in fireTimes(desk + 0.45, deskEnd, offset: 0) { m.pew(t, vol: 0.1); m.clang(t + boltArrival * shotPeriod) }
    for t in fireTimes(desk + 0.45, deskEnd, offset: 0) { m.thwip(t + 0.02, vol: 0.07) }
    for t in fireTimes(desk + 0.45, deskEnd, offset: shotPeriod / 2) { m.ice(t, vol: 0.08) }

    let status = shotStart("status")
    for i in 0..<4 { m.pop(status + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(status + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }

    let agents = shotStart("agents")
    for k in 0..<14 { m.step(agents + Double(k) * 0.125, vol: 0.06) }
    m.bark(agents + 1.4)

    let win = shotStart("window")                         // the strip: the Joker firing at Batman, the cards, the ping
    for t in fireTimes(win, win + 2.5, offset: 0) { m.pew(t, vol: 0.05); m.clang(t + boltArrival * shotPeriod, vol: 0.05) }
    for k in [0.9, 1.8] { m.click(win + k, vol: 0.06) }
    m.ping(win + 2.5)

    let ais = shotStart("ais")                            // six pop in; heat vision against Lex's warsuit
    for i in 0..<6 { m.pop(ais + 0.15 + Double(i) * 0.1, step: i % 4) }
    m.crackle(ais + 0.4, shotStart("endcard") + half - ais - 0.4, vol: 0.045)

    // Master: gentle saturation, normalise, fade out.
    var peak: Float = 0
    for i in m.buf.indices { m.buf[i] = Float(tanh(Double(m.buf[i]) * 1.2)); peak = max(peak, abs(m.buf[i])) }
    let gain = peak > 0 ? 0.89 / peak : 1
    let fadeFrom = Int((duration - 1.2) * sampleRate)
    for i in m.buf.indices {
        m.buf[i] *= gain
        if i > fadeFrom { m.buf[i] *= Float(max(0, 1 - Double(i - fadeFrom) / (1.2 * sampleRate))) }
    }
    return m.buf
}

/// Puts the soundtrack under the silent video: WAV → AAC with afconvert, then a passthrough export.
func mux(video: String, audio: String, to out: String) {
    let m4a = audio.replacingOccurrences(of: ".wav", with: ".m4a")
    try? FileManager.default.removeItem(atPath: m4a)
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
    p.arguments = ["-f", "m4af", "-d", "aac", "-b", "192000", audio, m4a]
    try! p.run(); p.waitUntilExit()

    let comp = AVMutableComposition()
    let v = AVURLAsset(url: URL(fileURLWithPath: video)), a = AVURLAsset(url: URL(fileURLWithPath: m4a))
    let range = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))
    let vt = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
    try! vt.insertTimeRange(range, of: v.tracks(withMediaType: .video)[0], at: .zero)
    let at = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
    let aRange = CMTimeRange(start: .zero, duration: min(range.duration, a.duration))
    try! at.insertTimeRange(aRange, of: a.tracks(withMediaType: .audio)[0], at: .zero)
    try? FileManager.default.removeItem(atPath: out)
    let ex = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetPassthrough)!
    ex.outputURL = URL(fileURLWithPath: out); ex.outputFileType = .mp4
    let done = DispatchSemaphore(value: 0)
    ex.exportAsynchronously { done.signal() }
    done.wait()
    if ex.status != .completed { print("mux failed: \(String(describing: ex.error))"); exit(1) }
    print("wrote \(out)")
}

// MARK: Main

let args = CommandLine.arguments
let cmd = args.count > 1 ? args[1] : "storyboard"
let out = args.count > 2 ? args[2] : "build/promo"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

/// Encodes every frame straight into an H.264 MP4 with AVAssetWriter (no ffmpeg needed).
func writeVideo(to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.removeItem(at: url)
    let writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: W, AVVideoHeightKey: H,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 16_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel],
    ])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: W,
        kCVPixelBufferHeightKey as String: H,
    ])
    writer.add(input)
    writer.startWriting(); writer.startSession(atSourceTime: .zero)
    let n = Int(duration * fps)
    for f in 0..<n {
        autoreleasepool {
            while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.005) }
            var pb: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pb)
            let buf = pb!
            CVPixelBufferLockBaseAddress(buf, [])
            let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buf), width: W, height: H, bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buf), space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
            ctx.draw(frame(Double(f) / fps).cgImage!, in: CGRect(x: 0, y: 0, width: W, height: H))
            CVPixelBufferUnlockBaseAddress(buf, [])
            adaptor.append(buf, withPresentationTime: CMTime(value: CMTimeValue(f), timescale: CMTimeScale(fps)))
        }
    }
    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    done.wait()
    if writer.status != .completed { print("video failed: \(String(describing: writer.error))"); exit(1) }
    print("wrote \(path)")
}

if cmd == "video" {
    let tmp = NSTemporaryDirectory()
    writeVideo(to: tmp + "clawd-wars-silent.mp4")
    writeWAV(soundtrack(), to: tmp + "clawd-wars.wav")
    mux(video: tmp + "clawd-wars-silent.mp4", audio: tmp + "clawd-wars.wav", to: "\(out)/clawd-wars-promo.mp4")
} else if cmd == "audio" {
    writeWAV(soundtrack(), to: "\(out)/clawd-wars-promo.wav"); print("wrote \(out)/clawd-wars-promo.wav")
} else if cmd == "frames" {
    let n = Int(duration * fps)
    for f in 0..<n { autoreleasepool { save(frame(Double(f) / fps), "\(out)/frame-\(String(format: "%03d", f)).png") } }
    print("wrote \(n) frames to \(out)")
} else if cmd == "frame" {
    let t = Double(args[3]) ?? 0
    save(frame(t), "\(out)/t\(args[3]).png"); print("wrote \(out)/t\(args[3]).png")
} else {
    let keys: [Double] = [2.4, 7.0, 14.5, 19.0, 22.4, 27.3, 31.9, 36.0, 40.6, 45.0, 50.0]
    let frames = keys.map(frame)
    for (i, f) in frames.enumerated() { save(f, "\(out)/key-\(i + 1).png") }
    save(storyboard(frames), "\(out)/storyboard.png")
    print("wrote \(keys.count) key frames and storyboard.png to \(out)")
}

