import AppKit

func createIconImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let scale = size / 1024.0

    // Squircle background with rounded corners
    let pad = 64.0 * scale
    let sDim = 896.0 * scale
    let radius = 200.0 * scale
    let rect = NSRect(x: pad, y: pad, width: sDim, height: sDim)
    let bezier = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    let bgGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.11, green: 0.13, blue: 0.20, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.10, alpha: 1.0)
    )!
    bgGrad.draw(in: bezier, angle: 90.0)

    // Sleek border highlight
    let border = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    border.lineWidth = 4.0 * scale
    NSColor(white: 1.0, alpha: 0.15).setStroke()
    border.stroke()

    // Camera body
    let camRect = NSRect(x: 256.0 * scale, y: 310.0 * scale, width: 512.0 * scale, height: 380.0 * scale)
    let camPath = NSBezierPath(roundedRect: camRect, xRadius: 64.0 * scale, yRadius: 64.0 * scale)
    let camGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.22, green: 0.26, blue: 0.38, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.16, green: 0.19, blue: 0.28, alpha: 1.0)
    )!
    camGrad.draw(in: camPath, angle: 90.0)

    // Camera top notch
    let notchRect = NSRect(x: 320.0 * scale, y: 690.0 * scale, width: 140.0 * scale, height: 40.0 * scale)
    let notchPath = NSBezierPath(roundedRect: notchRect, xRadius: 16.0 * scale, yRadius: 16.0 * scale)
    NSColor(calibratedRed: 0.20, green: 0.23, blue: 0.34, alpha: 1.0).setFill()
    notchPath.fill()

    // Outer lens ring
    let lensOuter = NSBezierPath(ovalIn: NSRect(x: 372.0 * scale, y: 360.0 * scale, width: 280.0 * scale, height: 280.0 * scale))
    let lensGrad = NSGradient(
        starting: NSColor(calibratedRed: 0.32, green: 0.55, blue: 0.98, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.65, green: 0.35, blue: 0.95, alpha: 1.0)
    )!
    lensGrad.draw(in: lensOuter, angle: 45.0)

    // Inner lens dark glass
    let lensInner = NSBezierPath(ovalIn: NSRect(x: 432.0 * scale, y: 420.0 * scale, width: 160.0 * scale, height: 160.0 * scale))
    NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.18, alpha: 1.0).setFill()
    lensInner.fill()

    // Glass glare reflection
    let glare = NSBezierPath(ovalIn: NSRect(x: 462.0 * scale, y: 490.0 * scale, width: 50.0 * scale, height: 50.0 * scale))
    NSColor(white: 1.0, alpha: 0.35).setFill()
    glare.fill()

    // AI 4-point Sparkle Star (top-right of camera)
    let sparkle = NSBezierPath()
    let cx = 710.0 * scale
    let cy = 720.0 * scale
    let rOut = 80.0 * scale
    let rIn = 24.0 * scale

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
        starting: NSColor(calibratedRed: 1.0, green: 0.88, blue: 0.35, alpha: 1.0),
        ending: NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.15, alpha: 1.0)
    )!
    sparkleGrad.draw(in: sparkle, angle: 45.0)

    image.unlockFocus()
    return image
}

let iconsetDir = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (dim, scale) in sizes {
    let px = CGFloat(dim * scale)
    let img = createIconImage(size: px)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let name = scale == 1 ? "icon_\(dim)x\(dim).png" : "icon_\(dim)x\(dim)@2x.png"
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
print("✅ Generated AppIcon.icns successfully")
