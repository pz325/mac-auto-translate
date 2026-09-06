import AppKit
import Foundation

private enum MenuBarIconRenderer {
    static func render(pixelSize: Int, to outputURL: URL) throws {
        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let graphicsContext = NSGraphicsContext(bitmapImageRep: representation) else {
            throw CocoaError(.fileWriteUnknown)
        }

        let scale = CGFloat(pixelSize) / 18
        let context = graphicsContext.cgContext
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        defer { NSGraphicsContext.restoreGraphicsState() }

        context.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(1.35 * scale)
        context.setLineJoin(.round)

        let leftPanel = CGRect(x: 0.9 * scale, y: 3.8 * scale, width: 4.8 * scale, height: 10.4 * scale)
        let rightPanel = CGRect(x: 12.3 * scale, y: 3.8 * scale, width: 4.8 * scale, height: 10.4 * scale)
        context.addPath(CGPath(roundedRect: leftPanel, cornerWidth: 1.4 * scale, cornerHeight: 1.4 * scale, transform: nil))
        context.addPath(CGPath(roundedRect: rightPanel, cornerWidth: 1.4 * scale, cornerHeight: 1.4 * scale, transform: nil))
        context.strokePath()

        context.setLineWidth(0.9 * scale)
        context.setLineCap(.round)
        for y in [9.0] {
            context.move(to: CGPoint(x: 1.8 * scale, y: y * scale))
            context.addLine(to: CGPoint(x: 4.8 * scale, y: y * scale))
            context.move(to: CGPoint(x: 13.2 * scale, y: y * scale))
            context.addLine(to: CGPoint(x: 16.2 * scale, y: y * scale))
        }
        context.strokePath()

        context.setLineWidth(1.1 * scale)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.move(to: CGPoint(x: 7.9 * scale, y: 7.1 * scale))
        context.addLine(to: CGPoint(x: 6.7 * scale, y: 9 * scale))
        context.addLine(to: CGPoint(x: 7.9 * scale, y: 10.9 * scale))

        context.move(to: CGPoint(x: 10.1 * scale, y: 7.1 * scale))
        context.addLine(to: CGPoint(x: 11.3 * scale, y: 9 * scale))
        context.addLine(to: CGPoint(x: 10.1 * scale, y: 10.9 * scale))
        context.strokePath()

        guard let pngData = representation.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try pngData.write(to: outputURL, options: .atomic)
    }
}

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
let resources = projectRoot.appendingPathComponent("Resources", isDirectory: true)
try MenuBarIconRenderer.render(pixelSize: 18, to: resources.appendingPathComponent("MenuBarIconTemplate.png"))
try MenuBarIconRenderer.render(pixelSize: 36, to: resources.appendingPathComponent("MenuBarIconTemplate@2x.png"))
