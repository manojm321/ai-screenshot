import AppKit

func drawIcon(in rect: NSRect, size: CGFloat) {
    let scale = size / 1024.0

    // Squircle background with rounded corners
    let pad = 80.0 * scale
    let sDim = 864.0 * scale
    let radius = 200.0 * scale
    let bgRect = NSRect(x: pad, y: pad, width: sDim, height: sDim)
    let bezier = NSBezierPath(roundedRect: bgRect, xRadius: radius, yRadius: radius)

    let bgGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.18, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.08, alpha: 1.0)
    )!
    bgGrad.draw(in: bezier, angle: 90.0)

    // Glowing border highlight
    let border = NSBezierPath(roundedRect: bgRect, xRadius: radius, yRadius: radius)
    border.lineWidth = max(1.0, 4.0 * scale)
    NSColor(calibratedRed: 0.35, green: 0.45, blue: 0.85, alpha: 0.45).setStroke()
    border.stroke()

    // Camera body
    let camW = 540.0 * scale
    let camH = 390.0 * scale
    let camX = (size - camW) / 2.0
    let camY = 280.0 * scale
    let camRect = NSRect(x: camX, y: camY, width: camW, height: camH)
    let camPath = NSBezierPath(roundedRect: camRect, xRadius: 56.0 * scale, yRadius: 56.0 * scale)

    let camGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.22, green: 0.25, blue: 0.38, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.26, alpha: 1.0)
    )!
    camGrad.draw(in: camPath, angle: 90.0)

    // Camera top notch / viewfinder bump
    let notchW = 160.0 * scale
    let notchH = 46.0 * scale
    let notchX = camX + 70.0 * scale
    let notchY = camY + camH - 12.0 * scale
    let notchRect = NSRect(x: notchX, y: notchY, width: notchW, height: notchH)
    let notchPath = NSBezierPath(roundedRect: notchRect, xRadius: 18.0 * scale, yRadius: 18.0 * scale)
    NSColor(calibratedRed: 0.22, green: 0.25, blue: 0.38, alpha: 1.0).setFill()
    notchPath.fill()

    // Red recording / sensor dot on the right
    let dotRadius = 14.0 * scale
    let dotX = camX + camW - 90.0 * scale
    let dotY = camY + camH - 36.0 * scale
    let dotPath = NSBezierPath(ovalIn: NSRect(x: dotX, y: dotY, width: dotRadius * 2, height: dotRadius * 2))
    NSColor(calibratedRed: 1.0, green: 0.28, blue: 0.28, alpha: 1.0).setFill()
    dotPath.fill()

    // Outer lens metallic rim
    let lensDiameter = 280.0 * scale
    let lensX = (size - lensDiameter) / 2.0
    let lensY = camY + (camH - lensDiameter) / 2.0 - 10.0 * scale
    let lensOuter = NSBezierPath(ovalIn: NSRect(x: lensX, y: lensY, width: lensDiameter, height: lensDiameter))

    let rimGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.45, green: 0.50, blue: 0.65, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.20, green: 0.22, blue: 0.32, alpha: 1.0)
    )!
    rimGrad.draw(in: lensOuter, angle: 45.0)

    // Mid lens gradient (AI cyan to purple glass)
    let midDiameter = 240.0 * scale
    let midX = (size - midDiameter) / 2.0
    let midY = lensY + (lensDiameter - midDiameter) / 2.0
    let midLens = NSBezierPath(ovalIn: NSRect(x: midX, y: midY, width: midDiameter, height: midDiameter))

    let lensGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.15, green: 0.65, blue: 1.0, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.70, green: 0.25, blue: 0.95, alpha: 1.0)
    )!
    lensGrad.draw(in: midLens, angle: 45.0)

    // Inner dark aperture
    let innerDiameter = 150.0 * scale
    let innerX = (size - innerDiameter) / 2.0
    let innerY = lensY + (lensDiameter - innerDiameter) / 2.0
    let innerLens = NSBezierPath(ovalIn: NSRect(x: innerX, y: innerY, width: innerDiameter, height: innerDiameter))
    NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.12, alpha: 1.0).setFill()
    innerLens.fill()

    // Glass reflection glare
    let glareW = 44.0 * scale
    let glareH = 44.0 * scale
    let glareX = innerX + 25.0 * scale
    let glareY = innerY + innerDiameter - 50.0 * scale
    let glare = NSBezierPath(ovalIn: NSRect(x: glareX, y: glareY, width: glareW, height: glareH))
    NSColor(white: 1.0, alpha: 0.50).setFill()
    glare.fill()

    // AI 4-Point Golden Sparkle Star (top right)
    let sparkle = NSBezierPath()
    let cx = size - 290.0 * scale
    let cy = size - 280.0 * scale
    let rOut = 84.0 * scale
    let rIn = 26.0 * scale

    for i in 0..<8 {
        let angle = Double(i) * .pi / 4.0 - .pi / 2.0
        let r = (i % 2 == 0) ? rOut : rIn
        let pt = NSPoint(x: cx + CGFloat(Double(r) * cos(angle)), y: cy + CGFloat(Double(r) * sin(angle)))
        if i == 0 {
            sparkle.move(to: pt)
        } else {
            sparkle.line(to: pt)
        }
    }
    sparkle.close()

    let sparkleGrad = NSGradient(
        starting: NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.40, alpha: 1.0),
        ending: NSColor(calibratedRed: 1.0, green: 0.60, blue: 0.15, alpha: 1.0)
    )!
    sparkleGrad.draw(in: sparkle, angle: 45.0)

    // Subtle smaller sparkle (bottom left)
    let smallSparkle = NSBezierPath()
    let scx = 280.0 * scale
    let scy = camY + 40.0 * scale
    let srOut = 36.0 * scale
    let srIn = 11.0 * scale

    for i in 0..<8 {
        let angle = Double(i) * .pi / 4.0 - .pi / 2.0
        let r = (i % 2 == 0) ? srOut : srIn
        let pt = NSPoint(x: scx + CGFloat(Double(r) * cos(angle)), y: scy + CGFloat(Double(r) * sin(angle)))
        if i == 0 {
            smallSparkle.move(to: pt)
        } else {
            smallSparkle.line(to: pt)
        }
    }
    smallSparkle.close()
    sparkleGrad.draw(in: smallSparkle, angle: 45.0)
}

func createExactBitmap(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current = ctx

    drawIcon(in: NSRect(x: 0, y: 0, width: pixels, height: pixels), size: CGFloat(pixels))

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let iconsetDir = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let entries: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, px) in entries {
    let rep = createExactBitmap(pixels: px)
    if let png = rep.representation(using: .png, properties: [:]) {
        let path = "\(iconsetDir)/\(name)"
        try? png.write(to: URL(fileURLWithPath: path))
    }
}

let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconsetDir, "-o", "AppIcon.icns"]
try? proc.run()
proc.waitUntilExit()

try? FileManager.default.removeItem(atPath: iconsetDir)

if FileManager.default.fileExists(atPath: "AppIcon.icns") {
    print("✅ Generated pixel-perfect AppIcon.icns with all 10 resolutions.")
} else {
    print("❌ Failed to generate AppIcon.icns")
    exit(1)
}
