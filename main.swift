import Cocoa

class ThumbnailView: NSView, NSDraggingSource {
    let filePath: String
    var onDismiss: (() -> Void)?
    private var dragStartLocation: NSPoint?
    private var isDragging = false

    init(frame: NSRect, filePath: String) {
        self.filePath = filePath
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.cornerRadius = 10
        self.layer?.masksToBounds = true
        self.layer?.borderColor = NSColor(white: 1.0, alpha: 0.35).cgColor
        self.layer?.borderWidth = 1.5

        // Background visual effect (frosted glass)
        let visualEffect = NSVisualEffectView(frame: self.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.autoresizingMask = [.width, .height]
        self.addSubview(visualEffect)

        // Image view
        if let image = NSImage(contentsOfFile: filePath) {
            let imageView = NSImageView(frame: self.bounds.insetBy(dx: 2, dy: 2))
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.autoresizingMask = [.width, .height]
            imageView.wantsLayer = true
            imageView.layer?.cornerRadius = 8
            imageView.layer?.masksToBounds = true
            self.addSubview(imageView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        dragStartLocation = event.locationInWindow
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStartLocation else { return }
        let current = event.locationInWindow
        let dist = hypot(current.x - start.x, current.y - start.y)

        // Threshold before initiating drag
        if dist > 4 && !isDragging {
            isDragging = true
            let fileURL = URL(fileURLWithPath: filePath)
            let dragItem = NSDraggingItem(pasteboardWriter: fileURL as NSURL)
            dragItem.setDraggingFrame(self.bounds, contents: self)
            self.beginDraggingSession(with: [dragItem], event: event, source: self)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if !isDragging {
            let url = URL(fileURLWithPath: filePath)
            NSWorkspace.shared.open(url)
            onDismiss?()
        }
    }

    override func rightMouseUp(with event: NSEvent) {
        let url = URL(fileURLWithPath: filePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
        onDismiss?()
    }

    // NSDraggingSource
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if operation != [] {
            onDismiss?()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSPanel!
    var filePath: String

    init(filePath: String) {
        self.filePath = filePath
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else {
            NSApp.terminate(nil)
            return
        }

        var targetWidth: CGFloat = 220
        var targetHeight: CGFloat = 140

        if let rep = NSImageRep(contentsOfFile: filePath) {
            let imgW = CGFloat(rep.pixelsWide > 0 ? rep.pixelsWide : Int(rep.size.width))
            let imgH = CGFloat(rep.pixelsHigh > 0 ? rep.pixelsHigh : Int(rep.size.height))
            if imgW > 0 && imgH > 0 {
                let ratio = imgW / imgH
                if ratio > 1 {
                    targetWidth = 220
                    targetHeight = max(80, min(150, targetWidth / ratio))
                } else {
                    targetHeight = 150
                    targetWidth = max(90, min(220, targetHeight * ratio))
                }
            }
        }

        let marginX: CGFloat = 24
        let marginY: CGFloat = 24
        let screenFrame = screen.visibleFrame

        let windowRect = NSRect(
            x: screenFrame.maxX - targetWidth - marginX,
            y: screenFrame.minY + marginY,
            width: targetWidth,
            height: targetHeight
        )

        window = NSPanel(
            contentRect: windowRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.alphaValue = 0.0

        let thumbView = ThumbnailView(frame: NSRect(origin: .zero, size: windowRect.size), filePath: filePath)
        thumbView.onDismiss = { [weak self] in
            self?.dismiss()
        }
        window.contentView = thumbView

        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        }

        // Auto dismiss after 4.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { [weak self] in
            self?.dismiss()
        }
    }

    func dismiss() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.35
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            NSApp.terminate(nil)
        })
    }
}

func getScreenshotDirectory() -> URL {
    if let customPath = CFPreferencesCopyAppValue("location" as CFString, "com.apple.screencapture" as CFString) as? String {
        let expanded = NSString(string: customPath).expandingTildeInPath
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir), isDir.boolValue {
            return URL(fileURLWithPath: expanded)
        }
    }
    return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSString(string: "~/Desktop").expandingTildeInPath)
}

func sanitizeSlug(_ text: String) -> String {
    let stripped = text.replacingOccurrences(of: "[\"'`]", with: "", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    var slug = stripped.replacingOccurrences(of: "[^a-zA-Z0-9_-]+", with: "-", options: .regularExpression)
    slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-_")).lowercased()
    slug = slug.replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
    if slug.isEmpty { return "screenshot" }
    return String(slug.prefix(45))
}

func describeImage(at path: String) -> String {
    let fmCandidate = "/usr/bin/fm"
    guard FileManager.default.fileExists(atPath: fmCandidate) else {
        return "screenshot"
    }

    let instructions = "Describe this screenshot in 2 to 4 words. Output only lowercase words separated by hyphens (kebab-case). Do not include quotes, periods, or extra text. Example: github-issue-list"

    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: fmCandidate)
    proc.arguments = [
        "respond",
        "--image", path,
        "--instructions", instructions,
        "--no-stream",
        "--greedy"
    ]

    let stdoutPipe = Pipe()
    proc.standardOutput = stdoutPipe
    proc.standardError = Pipe()

    do {
        try proc.run()
        proc.waitUntilExit()
        if proc.terminationStatus == 0 {
            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                return sanitizeSlug(output)
            }
        }
    } catch {
        return "screenshot"
    }

    return "screenshot"
}

func captureInteractive() -> String? {
    let tempDir = FileManager.default.temporaryDirectory
    let tempURL = tempDir.appendingPathComponent("ai_screen_\(UUID().uuidString).png")
    let tempPath = tempURL.path

    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    proc.arguments = ["-i", tempPath]

    do {
        try proc.run()
        proc.waitUntilExit()
    } catch {
        return nil
    }

    guard proc.terminationStatus == 0,
          FileManager.default.fileExists(atPath: tempPath),
          let attrs = try? FileManager.default.attributesOfItem(atPath: tempPath),
          let size = attrs[.size] as? UInt64, size > 0 else {
        try? FileManager.default.removeItem(atPath: tempPath)
        return nil
    }

    let slug = describeImage(at: tempPath)
    let destDir = getScreenshotDirectory()

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HHmmss"
    let timestamp = formatter.string(from: Date())

    var filename = "\(timestamp)_\(slug).png"
    var destURL = destDir.appendingPathComponent(filename)
    var counter = 1
    while FileManager.default.fileExists(atPath: destURL.path) {
        filename = "\(timestamp)_\(slug)_\(counter).png"
        destURL = destDir.appendingPathComponent(filename)
        counter += 1
    }

    do {
        try FileManager.default.moveItem(at: tempURL, to: destURL)
        return destURL.path
    } catch {
        return nil
    }
}

func run() {
    let args = CommandLine.arguments

    var previewPath: String? = nil

    if args.count > 2 && args[1] == "--preview" {
        previewPath = args[2]
    } else if args.count > 1 && !args[1].hasPrefix("-") {
        previewPath = args[1]
    } else {
        // Trigger capture
        previewPath = captureInteractive()
    }

    guard let finalPath = previewPath, FileManager.default.fileExists(atPath: finalPath) else {
        exit(0)
    }

    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate(filePath: finalPath)
    app.delegate = delegate
    app.run()
}

run()
