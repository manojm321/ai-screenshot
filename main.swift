import Cocoa
import Carbon
import ServiceManagement

// MARK: - HotKey Manager (Carbon EventHotKey)
class HotKeyManager {
    static let shared = HotKeyManager()
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onHotKeyPressed: (() -> Void)?

    func register(keyCode: UInt32, modifiers: UInt32) {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hkID = EventHotKeyID()
                GetEventParameter(
                    theEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                if hkID.signature == OSType(0x41495343) && hkID.id == 1 {
                    DispatchQueue.main.async {
                        manager.onHotKeyPressed?()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x41495343), id: 1)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status != noErr {
            NSLog("Warning: RegisterEventHotKey returned %d", status)
        }
    }

    func unregister() {
        if let hk = hotKeyRef {
            UnregisterEventHotKey(hk)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}

// MARK: - Floating Thumbnail View
class ThumbnailView: NSView, NSDraggingSource {
    let filePath: String
    var onDismiss: (() -> Void)?
    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?
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

        let visualEffect = NSVisualEffectView(frame: self.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.autoresizingMask = [.width, .height]
        self.addSubview(visualEffect)

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

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func mouseDown(with event: NSEvent) {
        dragStartLocation = event.locationInWindow
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStartLocation else { return }
        let current = event.locationInWindow
        let dist = hypot(current.x - start.x, current.y - start.y)

        if dist > 4 && !isDragging {
            isDragging = true
            onDragStart?()
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

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        isDragging = false
        if operation != [] {
            onDismiss?()
        } else {
            onDragEnd?()
        }
    }
}

// MARK: - Helper Functions
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
    if slug.hasSuffix("-png") {
        slug = String(slug.dropLast(4)).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
    }
    if slug.isEmpty { return "screenshot" }
    return String(slug.prefix(45))
}

func findFMExecutable() -> String? {
    if FileManager.default.isExecutableFile(atPath: "/usr/bin/fm") {
        return "/usr/bin/fm"
    }
    let whichProc = Process()
    whichProc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    whichProc.arguments = ["fm"]
    let pipe = Pipe()
    whichProc.standardOutput = pipe
    whichProc.standardError = Pipe()
    do {
        try whichProc.run()
        whichProc.waitUntilExit()
        if whichProc.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                return path
            }
        }
    } catch {}
    return nil
}

func describeImage(at path: String) -> String {
    guard let fmPath = findFMExecutable() else {
        return "screenshot"
    }

    let instructions = "Describe this screenshot in 2 to 4 words. Output only lowercase words separated by hyphens (kebab-case). Do not include quotes, periods, or extra text. Example: github-issue-list"

    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: fmPath)
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

        let timeoutSeconds: TimeInterval = 10.0
        let startTime = Date()
        while proc.isRunning && Date().timeIntervalSince(startTime) < timeoutSeconds {
            Thread.sleep(forTimeInterval: 0.05)
        }

        if proc.isRunning {
            proc.terminate()
            return "screenshot"
        }

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
    formatter.dateFormat = "HHmmss"
    let timestamp = formatter.string(from: Date())

    var filename = "\(slug)_\(timestamp).png"
    var destURL = destDir.appendingPathComponent(filename)
    var counter = 1
    while FileManager.default.fileExists(atPath: destURL.path) {
        filename = "\(slug)_\(timestamp)_\(counter).png"
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

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var previewWindow: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?
    private var isCapturing = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments

        if args.contains("--show-icon") {
            UserDefaults.standard.set(false, forKey: "HideMenuBarIcon")
        } else if args.contains("--hide-icon") {
            UserDefaults.standard.set(true, forKey: "HideMenuBarIcon")
        }

        setupStatusBar()
        setupHotKey()

        if args.count > 2 && args[1] == "--preview" {
            showThumbnail(filePath: args[2])
        } else if args.contains("--capture") {
            triggerCapture()
        } else {
            notifyOnLaunch()
        }
    }

    func notifyOnLaunch() {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")

        // Trigger notification banner
        DispatchQueue.global(qos: .utility).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            let title = isFirstLaunch ? "AI Screenshot Ready!" : "AI Screenshot Running"
            let msg = "Press ⌘ + ⇧ + 1 anywhere to capture. Camera icon added to menu bar."
            proc.arguments = ["-e", "display notification \"\(msg)\" with title \"\(title)\" sound name \"Glass\""]
            try? proc.run()
        }

        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let alert = NSAlert()
                alert.messageText = "AI Screenshot is Ready!"
                alert.informativeText = "AI Screenshot is now active in your top menu bar.\n\n• Shortcut: Press ⌘ + ⇧ + 1 anywhere to take an AI screenshot.\n• Menu Bar: Click the camera icon for quick capture, screenshot folder, or Launch at Login."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Got It")
                NSApp.activate(ignoringOtherApps: true)
                alert.runModal()
            }
        }
    }

    func setupHotKey() {
        // Register ⌘ + ⇧ + 1 (key code 18 = '1')
        HotKeyManager.shared.register(keyCode: 18, modifiers: UInt32(cmdKey | shiftKey))
        HotKeyManager.shared.onHotKeyPressed = { [weak self] in
            self?.triggerCapture()
        }
    }

    func setupStatusBar() {
        if UserDefaults.standard.bool(forKey: "HideMenuBarIcon") {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
            return
        }

        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        let icon = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "AI Screenshot")
            ?? NSImage(systemSymbolName: "camera", accessibilityDescription: "AI Screenshot")
        icon?.isTemplate = true
        button.image = icon

        let menu = NSMenu()

        let captureItem = NSMenuItem(title: "Take AI Screenshot", action: #selector(triggerCaptureAction), keyEquivalent: "1")
        captureItem.keyEquivalentModifierMask = [.command, .shift]
        captureItem.target = self
        menu.addItem(captureItem)

        let openFolderItem = NSMenuItem(title: "Open Screenshots Folder", action: #selector(openFolderAction), keyEquivalent: "")
        openFolderItem.target = self
        menu.addItem(openFolderItem)

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItemAction(_:)), keyEquivalent: "")
        loginItem.target = self
        if #available(macOS 13.0, *) {
            loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        }
        menu.addItem(loginItem)

        let hideIconItem = NSMenuItem(title: "Hide Menu Bar Icon", action: #selector(hideStatusBarIconAction), keyEquivalent: "")
        hideIconItem.target = self
        menu.addItem(hideIconItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit AI Screenshot", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc func hideStatusBarIconAction() {
        let alert = NSAlert()
        alert.messageText = "Hide Menu Bar Icon?"
        alert.informativeText = "AI Screenshot will continue running in the background and respond to ⌘⇧1.\n\nTo restore the menu bar icon, simply open AI Screenshot again from Applications or Spotlight."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Hide Icon")
        alert.addButton(withTitle: "Cancel")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            UserDefaults.standard.set(true, forKey: "HideMenuBarIcon")
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    @objc func triggerCaptureAction() {
        triggerCapture()
    }

    @objc func openFolderAction() {
        let dir = getScreenshotDirectory()
        NSWorkspace.shared.open(dir)
    }

    @objc func toggleLoginItemAction(_ sender: NSMenuItem) {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    sender.state = .off
                } else {
                    try SMAppService.mainApp.register()
                    sender.state = .on
                }
            } catch {
                NSLog("Failed to toggle login item: %@", error.localizedDescription)
            }
        }
    }

    @objc func quitAction() {
        HotKeyManager.shared.unregister()
        NSApp.terminate(nil)
    }

    func triggerCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let capturedPath = captureInteractive()

            DispatchQueue.main.async {
                self?.isCapturing = false
                if let path = capturedPath {
                    self?.showThumbnail(filePath: path)
                }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if UserDefaults.standard.bool(forKey: "HideMenuBarIcon") {
            UserDefaults.standard.set(false, forKey: "HideMenuBarIcon")
            setupStatusBar()
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            proc.arguments = ["-e", "display notification \"Menu bar icon restored.\" with title \"AI Screenshot\" sound name \"Glass\""]
            try? proc.run()
        } else {
            triggerCapture()
        }
        return true
    }

    func showThumbnail(filePath: String) {
        dismissCurrentThumbnail()

        let mouseLoc = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first else {
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

        let window = NSPanel(
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
            self?.dismissCurrentThumbnail()
        }
        thumbView.onDragStart = { [weak self] in
            self?.cancelDismiss()
        }
        thumbView.onDragEnd = { [weak self] in
            self?.scheduleDismiss(after: 2.5)
        }
        window.contentView = thumbView

        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        }

        self.previewWindow = window
        scheduleDismiss(after: 4.5)
    }

    func scheduleDismiss(after delay: TimeInterval = 4.5) {
        dismissWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.dismissCurrentThumbnail()
        }
        dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func cancelDismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
    }

    func dismissCurrentThumbnail() {
        cancelDismiss()
        guard let win = previewWindow else { return }
        self.previewWindow = nil

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.35
            win.animator().alphaValue = 0.0
        }, completionHandler: {
            win.orderOut(nil)
        })
    }
}

// MARK: - Main Run Loop
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
