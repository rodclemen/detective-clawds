import AppKit

// Renders Resources/AppIcon.png (1024²): Batman facing down the Joker's gun under the Bat-Signal in a
// Gotham night sky, drawn with the app's own sprite code. build.sh turns it into AppIcon.icns.
//   swiftc Sources/App/{Pixel,Characters,Fights,Roster,Pose,Locations,Cast,Habits}.swift Sources/App/Art/*.swift \
//          Sources/App/Places/*.swift Sources/Shared/*.swift Tools/MakeIcon/main.swift -o build/makeicon \
//          && build/makeicon Resources/AppIcon.png

let size: CGFloat = 1024
let p: CGFloat = 9                      // icon pixels per sprite pixel
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
ctx.interpolationQuality = .none

// macOS icon grid: 824² rounded square, centred.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.addPath(shape); ctx.clip()

// Deep-space gradient
let space = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                       colors: [CGColor(red: 0.10, green: 0.12, blue: 0.24, alpha: 1),
                                CGColor(red: 0.03, green: 0.04, blue: 0.10, alpha: 1)] as CFArray,
                       locations: [0, 1])!
ctx.drawLinearGradient(space, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// Pixel stars (deterministic)
for i in 0..<70 {
    let x = 100 + noise(i * 3) * 824, y = 360 + noise(i * 3 + 1) * 564
    let big = noise(i * 3 + 2) > 0.85
    let s: CGFloat = big ? p : p / 2
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: big ? 0.95 : 0.55))
    ctx.fill(CGRect(x: (CGFloat(x) / s).rounded() * s, y: (CGFloat(y) / s).rounded() * s, width: s, height: s))
}

// The Bat-Signal on the clouds: a pale glow, a yellow oval and the bat cut out of it, in sprite pixels.
let bat: [String] = [
    "..X.............X..",
    "..XX...X...X...XX..",
    ".XXXX..XXXXX..XXXX.",
    "XXXXXXXXXXXXXXXXXXX",
    "XXXXXXXXXXXXXXXXXXX",
    ".XXXXXXXXXXXXXXXXX.",
    "..XXX.XXXXXXX.XXX..",
    "...X...XXXXX...X...",
    ".........X.........",
]
let sigX: CGFloat = 513, sigY: CGFloat = 702      // on the sprite-pixel grid (multiples of p)
for (r, a) in [(24.0, 0.05), (19.0, 0.07)] as [(Double, Double)] {
    ctx.setFillColor(CGColor(red: 1, green: 0.95, blue: 0.7, alpha: a))
    ctx.fillEllipse(in: CGRect(x: sigX - CGFloat(r) * p, y: sigY - CGFloat(r) * p * 0.62, width: CGFloat(r) * 2 * p, height: CGFloat(r) * 1.24 * p))
}
for row in 0..<13 {
    let dy = Double(row) - 6.0
    let half = Int((14.0 * (1 - dy * dy / 49).squareRoot()).rounded())
    ctx.setFillColor(CGColor(red: 0.98, green: 0.86, blue: 0.36, alpha: 1))
    ctx.fill(CGRect(x: sigX - CGFloat(half) * p, y: sigY + CGFloat(6 - row) * p,
                    width: CGFloat(half * 2 + 1) * p, height: p))
}
ctx.setFillColor(CGColor(red: 0.06, green: 0.06, blue: 0.10, alpha: 1))
for (r, line) in bat.enumerated() {
    for (k, ch) in line.enumerated() where ch == "X" {
        ctx.fill(CGRect(x: sigX + CGFloat(k - 9) * p, y: sigY + CGFloat(4 - r) * p, width: p, height: p))
    }
}

// Ground strip
ctx.setFillColor(CGColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: 318))
ctx.setFillColor(CGColor(red: 0.85, green: 0.47, blue: 0.34, alpha: 1))   // Claude-orange horizon
ctx.fill(CGRect(x: 0, y: 318, width: size, height: p))

// The fight, frozen mid-blast: the Joker on the left, Batman on the right
let t = 0.55
let dist = 170.0 / 3                     // duel distance in sprite pixels, as in the app
let centerL = 490 - CGFloat(dist) / 2 * p, centerR = 490 + CGFloat(dist) / 2 * p   // a touch left: Batman's cape trails right
let canvasBottom: CGFloat = 318 - 8 * p  // feet (row 44) on the horizon
func put(_ c: PixelCanvas, center: CGFloat, mirrored: Bool) {
    c.addOutline(C(0xFFFFFF, 0.92))
    let img = c.makeImage()!
    let w = CGFloat(c.w) * p, h = CGFloat(c.h) * p
    let x = center - (mirrored ? CGFloat(c.w) - 28 : 28) * p
    ctx.saveGState()
    if mirrored {
        ctx.translateBy(x: x + w, y: canvasBottom); ctx.scaleBy(x: -1, y: 1)
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    } else {
        ctx.draw(img, in: CGRect(x: x, y: canvasBottom, width: w, height: h))
    }
    ctx.restoreGState()
}
let left = Cast.villain(.joker), right = Cast.hero(.batman)
let (lRole, rRole) = fightRoles(left.weapon, right.weapon)
let lc = PixelCanvas(72, 52)
left.draw(lc, t: t, mode: .working, walking: false, role: lRole, asSession: true)
let rc = PixelCanvas(72, 52)
right.draw(rc, t: t, mode: .working, walking: false, role: rRole, asSession: true)
put(lc, center: centerL, mirrored: false)
put(rc, center: centerR, mirrored: true)

let margin = 24.0
let fx = PixelCanvas(Int(dist + margin * 2), 52)
func fighter(_ who: Cast, x: Double, side: Double) -> Fighter {
    Fighter(weapon: who.weapon, x: x, k: 1, top: 0, side: side, muzzle: who.muzzle, armoured: who.armoured,
            pivot: who.weaponPivot).dressed(as: who)
}
drawFightFX(fx, t: t, left: fighter(left, x: margin, side: 1), right: fighter(right, x: margin + dist, side: -1))
ctx.draw(fx.makeImage()!, in: CGRect(x: centerL - CGFloat(margin) * p, y: canvasBottom,
                                     width: CGFloat(fx.w) * p, height: CGFloat(fx.h) * p))
ctx.restoreGState()

// Subtle rim
ctx.addPath(shape)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12)); ctx.setLineWidth(4); ctx.strokePath()

try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
