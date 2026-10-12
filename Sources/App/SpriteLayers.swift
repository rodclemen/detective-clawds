import AppKit
import QuartzCore

/// Shows a frame's `DrawItem`s as Core Animation layers, so the GPU scales and composites them instead of the CPU
/// redrawing every pixel of the scene each frame. One layer per item, reused frame to frame; pixel art keeps its
/// hard edges with nearest-neighbour filtering. Text (name labels, callouts) is rendered once per look and cached.
final class SpriteLayers {
    let root = CALayer()
    private var pool: [CALayer] = []
    private var textCache: [TextKey: CGImage] = [:]
    private var textCacheBytes = 0
    /// Room around a text image for the box's stroke, which straddles the box's edge.
    private static let textPad: CGFloat = 2

    private struct TextKey: Hashable {
        let text: NSAttributedString
        let boxed: Bool
        let agentBox: Bool
        let accent: String
        let width: CGFloat
        let height: CGFloat
        let scale: CGFloat
    }

    init() {
        root.anchorPoint = .zero
        root.actions = Self.noAnimations
    }

    private static let noAnimations: [String: CAAction] = [
        "contents": NSNull(), "bounds": NSNull(), "position": NSNull(), "transform": NSNull(),
        "opacity": NSNull(), "hidden": NSNull(), "sublayers": NSNull(), "sublayerTransform": NSNull(),
    ]

    /// Lay `items` (screen coordinates) out in `host`, offset by `origin`. `pixelsPerPoint` is how many device pixels
    /// one of the host's points covers, for rendering text sharply.
    func update(_ items: [OverlayController.DrawItem], origin o: NSPoint, in host: CALayer, pixelsPerPoint: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if root.superlayer !== host { host.addSublayer(root) }
        for (i, item) in items.enumerated() {
            if i == pool.count {
                let layer = CALayer()
                layer.actions = Self.noAnimations
                layer.magnificationFilter = .nearest
                layer.minificationFilter = .nearest
                root.addSublayer(layer)
                pool.append(layer)
            }
            let layer = pool[i]
            var r = item.rect.offsetBy(dx: -o.x, dy: -o.y)
            if let text = item.text {
                if !item.boxed { r.size = text.size() }   // plain text is drawn at its origin, at its own size
                r = r.insetBy(dx: -Self.textPad, dy: -Self.textPad)
                // Shown at exactly the image's whole pixels, on the pixel grid: a fraction of a pixel smaller and the
                // nearest-neighbour filter dropped a whole row, cutting the tops off a name's letters.
                let k = pixelsPerPoint
                r = CGRect(x: (r.minX * k).rounded() / k, y: (r.minY * k).rounded() / k,
                           width: (r.width * k).rounded(.up) / k, height: (r.height * k).rounded(.up) / k)
                layer.contents = textImage(item, size: r.size, scale: pixelsPerPoint)
                layer.contentsScale = pixelsPerPoint
            } else {
                layer.contents = item.image
            }
            layer.bounds = CGRect(origin: .zero, size: r.size)
            layer.position = CGPoint(x: r.midX, y: r.midY)
            layer.transform = item.mirrored ? CATransform3DMakeScale(-1, 1, 1) : CATransform3DIdentity
            layer.opacity = Float(item.alpha)
            layer.isHidden = item.text == nil && item.image == nil
        }
        for layer in pool.dropFirst(items.count) where !layer.isHidden {
            layer.isHidden = true
            layer.contents = nil
        }
        CATransaction.commit()
    }

    /// The text item drawn by `OverlayView.render` into an image (box and all), at full opacity: the layer fades it.
    private func textImage(_ item: OverlayController.DrawItem, size: CGSize, scale: CGFloat) -> CGImage? {
        guard let text = item.text else { return nil }
        let key = TextKey(text: text, boxed: item.boxed, agentBox: item.agentBox, accent: item.accent?.description ?? "",
                          width: size.width, height: size.height, scale: scale)
        if let hit = textCache[key] { return hit }
        let w = Int((size.width * scale).rounded(.up)), h = Int((size.height * scale).rounded(.up))
        guard w > 0, h > 0, let space = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.scaleBy(x: scale, y: scale)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        let p = Self.textPad
        let inner = CGRect(x: p, y: p, width: size.width - 2 * p, height: size.height - 2 * p)
        let flat = OverlayController.DrawItem(text: text, rect: inner, alpha: 1, boxed: item.boxed,
                                              agentBox: item.agentBox, accent: item.accent)
        OverlayView.render([flat], origin: .zero, in: ctx)
        NSGraphicsContext.restoreGraphicsState()
        let image = ctx.makeImage()
        // Labels change and hover cards are big: don't keep every look forever (by count, and by memory).
        if textCache.count > 300 || textCacheBytes > 16 << 20 { textCache.removeAll(); textCacheBytes = 0 }
        textCache[key] = image
        textCacheBytes += image.map { $0.bytesPerRow * $0.height } ?? 0
        return image
    }
}
