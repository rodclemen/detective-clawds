import AppKit
import AVFoundation

// The comic-book transitions between places (`ComicWipe`), rendered as short clips and a sheet of key frames.
//   Tools/Transitions/build.sh && build/transitions <out folder> [from place] [to place]

let args = Array(CommandLine.arguments.dropFirst())
let outDir = args.first ?? "build/transitions"
let from = Location(rawValue: args.count > 1 ? args[1] : "watchtower") ?? .watchtower
let to = Location(rawValue: args.count > 2 ? args[2] : "gotham") ?? .gotham
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let W = 1280, H = 800, P = 4                          // output size, screen pixels per art pixel
let fps = 30.0

/// A place as the screen saver shows it: the still picture plus its moving layer, scaled up crisp.
func placeImage(_ l: Location, t: Double) -> CGImage {
    let cw = W / P, ch = H / P, floor = max(8, ch / 8)
    let still = PixelCanvas(cw, ch); l.drawStatic(still, floorRows: floor)
    let moving = PixelCanvas(cw, ch); l.drawAnimated(moving, floorRows: floor, t: t)
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    ctx.interpolationQuality = .none
    for img in [still.makeImage(), moving.makeImage()].compactMap({ $0 }) { ctx.draw(img, in: CGRect(x: 0, y: 0, width: W, height: H)) }
    return ctx.makeImage()!
}

let full = CGRect(x: 0, y: 0, width: W, height: H)

struct Transition {
    let key: String, title: String, duration: Double
    let draw: (CGContext, CGImage, CGImage, Double) -> Void     // ctx, old, new, k 0…1
}

/// The app's own transitions (`ComicTrip`), every one of them.
func shown(_ kind: ComicWipe) -> Transition {
    let trip = ComicTrip(kind: kind, caption: "MEANWHILE, IN \(to.name.uppercased())…")
    return Transition(key: "\(kind.rawValue + 1)-\(kind)", title: "\(kind)", duration: kind.duration) { ctx, old, new, k in
        trip.draw(ctx, old: old, new: new, k: k, in: full)
    }
}

/// ONLY="1,4,12" renders just those (by number or name).
let only = ProcessInfo.processInfo.environment["ONLY"]?.split(separator: ",").map(String.init)
let transitions: [Transition] = ComicWipe.allCases.map(shown).filter { tr in
    only.map { $0.contains { tr.key.hasPrefix("\($0)-") || tr.key.hasSuffix("-\($0)") } } ?? true
}

// MARK: Rendering

func frameContext() -> CGContext {
    CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
}

/// A clip: the old place for 0.6 s, the transition, the new place for 0.8 s.
func clip(_ tr: Transition) {
    let url = URL(fileURLWithPath: "\(outDir)/\(tr.key).mp4")
    try? FileManager.default.removeItem(at: url)
    let writer = try! AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: W, AVVideoHeightKey: H,
        AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 6_000_000]])
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey as String: W,
        kCVPixelBufferHeightKey as String: H])
    writer.add(input); writer.startWriting(); writer.startSession(atSourceTime: .zero)
    let lead = 0.6, tail = 0.8
    let total = lead + tr.duration + tail
    let frames = Int(total * fps)
    for f in 0..<frames {
        let t = Double(f) / fps
        let ctx = frameContext()
        ctx.interpolationQuality = .none
        let old = placeImage(from, t: t), new = placeImage(to, t: t)
        if t < lead { ctx.draw(old, in: full) }
        else if t > lead + tr.duration { ctx.draw(new, in: full) }
        else { tr.draw(ctx, old, new, (t - lead) / tr.duration) }
        let img = ctx.makeImage()!
        var pb: CVPixelBuffer?
        CVPixelBufferCreate(nil, W, H, kCVPixelFormatType_32BGRA, nil, &pb)
        CVPixelBufferLockBaseAddress(pb!, [])
        let pctx = CGContext(data: CVPixelBufferGetBaseAddress(pb!), width: W, height: H, bitsPerComponent: 8,
                             bytesPerRow: CVPixelBufferGetBytesPerRow(pb!), space: CGColorSpaceCreateDeviceRGB(),
                             bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
        pctx.draw(img, in: full)
        CVPixelBufferUnlockBaseAddress(pb!, [])
        while !input.isReadyForMoreMediaData { usleep(1000) }
        adaptor.append(pb!, withPresentationTime: CMTime(value: CMTimeValue(f), timescale: CMTimeScale(fps)))
    }
    input.markAsFinished()
    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    done.wait()
    print("wrote \(url.path)")
}

/// One sheet: a row per transition, five moments through it.
func sheet() {
    let moments = [0.15, 0.35, 0.5, 0.65, 0.85]
    let cw = 320, chh = 200, label = 34
    let ctx = CGContext(data: nil, width: cw * moments.count, height: (chh + label) * transitions.count,
                        bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    ctx.setFillColor(CGColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: ctx.width, height: ctx.height))
    let old = placeImage(from, t: 1), new = placeImage(to, t: 1)
    for (row, tr) in transitions.enumerated() {
        let y = ctx.height - (row + 1) * (chh + label)
        let gc = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = gc
        NSAttributedString(string: "\(row + 1). \(tr.title)", attributes: [.font: NSFont.systemFont(ofSize: 18, weight: .bold),
                                                                         .foregroundColor: NSColor.white])
            .draw(at: NSPoint(x: 8, y: y + chh + 6))
        NSGraphicsContext.restoreGraphicsState()
        for (i, k) in moments.enumerated() {
            let f = frameContext(); f.interpolationQuality = .none
            tr.draw(f, old, new, k)
            ctx.draw(f.makeImage()!, in: CGRect(x: i * cw, y: y, width: cw - 4, height: chh))
        }
    }
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outDir)/transitions.png"))
    print("wrote \(outDir)/transitions.png")
}

/// FRAMES="key:0.3,0.6" writes just those moments of one transition, full size, as PNGs.
if let spec = ProcessInfo.processInfo.environment["FRAMES"], let colon = spec.firstIndex(of: ":"),
   let tr = transitions.first(where: { $0.key == String(spec[..<colon]) }) {
    let old = placeImage(from, t: 1), new = placeImage(to, t: 1)
    for part in spec[spec.index(after: colon)...].split(separator: ",") { guard let k = Double(part) else { continue }
        let f = frameContext(); f.interpolationQuality = .none
        tr.draw(f, old, new, k)
        try! NSBitmapImageRep(cgImage: f.makeImage()!).representation(using: .png, properties: [:])!
            .write(to: URL(fileURLWithPath: "\(outDir)/\(tr.key)-\(part).png"))
    }
    exit(0)
}
sheet()
if ProcessInfo.processInfo.environment["SHEET_ONLY"] == nil { for tr in transitions { clip(tr) } }
