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
            // Click opens in default viewer (Preview)
            let url = URL(fileURLWithPath: filePath)
            NSWorkspace.shared.open(url)
            onDismiss?()
        }
    }

    override func rightMouseUp(with event: NSEvent) {
        // Right-click reveals in Finder
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
            // If dropped successfully somewhere, dismiss thumbnail
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

        // Determine thumbnail size preserving image aspect ratio
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

        // Smooth fade-in
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

let args = CommandLine.arguments
guard args.count > 1 else {
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate(filePath: args[1])
app.delegate = delegate
app.run()
