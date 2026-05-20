import Cocoa
import SwiftUI

@MainActor
class NoteWindowController: NSWindowController, NSWindowDelegate {
    private var noteWindow: NoteWindow?

    convenience init(startExpanded: Bool = false) {
        let initialSize = CGSize(width: 60, height: 60)
        let window = NoteWindow(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        self.init(window: window)
        self.noteWindow = window
        window.delegate = self
        window.windowController = self

        let noteView = NoteView(
            window: window,
            onClose: { [weak self] in
                self?.closeNote()
            }
        )

        let hostingView = ConfigurableHostingView(rootView: noteView)
        window.contentView = hostingView

        if startExpanded {
            window.center()
            let expandedSize = CGSize(width: 420, height: 300)
            var frame = window.frame
            frame.size = expandedSize
            frame.origin.x = (NSScreen.main?.frame.midX ?? 0) - expandedSize.width / 2
            frame.origin.y = (NSScreen.main?.frame.midY ?? 0) - expandedSize.height / 2
            window.setFrame(frame, display: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                NotificationCenter.default.post(
                    name: .expandActiveNote,
                    object: self.window
                )
            }
        }
    }

    override func showWindow(_ sender: Any?) {
        guard let window = self.window else { return }
        if window.frame.size.width < 100 {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.windowControllers.removeAll { $0 == self }
            }
        }
    }

    func closeNote() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.windowControllers.removeAll { $0 == self }
        }
        self.close()
    }

    func foldNote() {
        NotificationCenter.default.post(
            name: .foldActiveNote,
            object: self.window
        )
    }

    func expandNote() {
        NotificationCenter.default.post(
            name: .expandActiveNote,
            object: self.window
        )
    }
}

class NoteWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = false
        self.level = .normal
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

extension Notification.Name {
    static let expandActiveNote = Notification.Name("ExpandActiveNote")
    static let closeActiveNote = Notification.Name("CloseActiveNote")
}

class ConfigurableHostingView<Content: View>: NSHostingView<Content> {
    required init(rootView: Content) {
        super.init(rootView: rootView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        DispatchQueue.main.async { [weak self] in
            self?.hideScrollersRecursively()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.hideScrollersRecursively()
        }
    }

    private func hideScrollersRecursively() {
        guard let contentView = self.subviews.first else { return }
        hideScrollers(in: contentView)
    }

    private func hideScrollers(in view: NSView) {
        if let scrollView = view as? NSScrollView {
            scrollView.hasVerticalScroller = false
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.scrollerStyle = .overlay
            scrollView.drawsBackground = false
            scrollView.backgroundColor = .clear
        }
        for subview in view.subviews {
            hideScrollers(in: subview)
        }
    }
}
