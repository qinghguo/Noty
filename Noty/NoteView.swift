import SwiftUI

extension Notification.Name {
    static let foldActiveNote = Notification.Name("FoldActiveNote")
    static let switchNoteColor = Notification.Name("SwitchNoteColor")
    static let shortcutDidChange = Notification.Name("ShortcutDidChange")
}

struct NoteView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State var isFolded: Bool = true
    @State private var noteText: String = ""
    @State private var localNoteColor: Color = Color(hex: "#f5f1bb")
    @FocusState private var isTextEditorFocused: Bool
    @State private var dragStartFrame: NSRect? = nil
    @State private var resizeStartFrame: NSRect? = nil
    @State private var hasTriggeredLongPress: Bool = false
    @State private var initialMouseLocation: NSPoint? = nil
    var window: NSWindow?
    var onClose: (() -> Void)?

    private let foldedSize: CGFloat = 60
    private let expandedSize = CGSize(width: 420, height: 300)
    private var foldedWindowSize: CGSize {
        CGSize(width: foldedSize, height: foldedSize)
    }

    var body: some View {
        ZStack(alignment: .center) {
            if isFolded {
                foldedView
            } else {
                expandedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            localNoteColor = SettingsManager.shared.colorPreset1
            guard let window else { return }
            if isFolded {
                applyFoldedWindowConstraints(to: window)
                window.setFrame(clampedFrame(foldedFrame(from: window.frame), for: window), display: true)
            } else {
                applyExpandedWindowConstraints(to: window)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .foldActiveNote)) { notification in
            guard let targetWindow = notification.object as? NSWindow else { return }
            if targetWindow === self.window {
                self.foldNote()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .expandActiveNote)) { notification in
            guard let targetWindow = notification.object as? NSWindow else { return }
            if targetWindow === self.window {
                self.expandNote()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchNoteColor)) { notification in
            guard let targetWindow = notification.object as? NSWindow else { return }
            if targetWindow === self.window {
                if let colorIndex = notification.userInfo?["colorIndex"] as? Int {
                    self.applyColorPreset(colorIndex)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeActiveNote)) { notification in
            guard let targetWindow = notification.object as? NSWindow else { return }
            if targetWindow === self.window {
                self.onClose?()
            }
        }
    }

    var foldedView: some View {
        Image(systemName: "star.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .foregroundColor(localNoteColor)
            .shadow(radius: 4)
            .frame(width: foldedSize, height: foldedSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if hasTriggeredLongPress { return }
                        guard let window = window else { return }
                        applyFoldedWindowConstraints(to: window)

                        if dragStartFrame == nil {
                            dragStartFrame = foldedFrame(from: window.frame)
                            initialMouseLocation = NSEvent.mouseLocation
                        }

                        if let startFrame = dragStartFrame, let startMouse = initialMouseLocation {
                            let currentMouse = NSEvent.mouseLocation
                            let deltaX = currentMouse.x - startMouse.x
                            let deltaY = currentMouse.y - startMouse.y

                            var newOrigin = startFrame.origin
                            newOrigin.x += deltaX
                            newOrigin.y += deltaY

                            var newFrame = foldedFrame(from: startFrame)
                            newFrame.origin = newOrigin
                            window.setFrame(clampedFrame(newFrame, for: window, preferredPoint: currentMouse), display: true)
                        }
                    }
                    .onEnded { value in
                        if hasTriggeredLongPress {
                            hasTriggeredLongPress = false
                            return
                        }

                        var isClick = false

                        if let startMouse = initialMouseLocation {
                            let currentMouse = NSEvent.mouseLocation
                            let deltaX = abs(currentMouse.x - startMouse.x)
                            let deltaY = abs(currentMouse.y - startMouse.y)

                            if deltaX < 3 && deltaY < 3 {
                                isClick = true
                            }
                        } else {
                            if abs(value.translation.width) < 3 && abs(value.translation.height) < 3 {
                                isClick = true
                            }
                        }

                        dragStartFrame = nil
                        initialMouseLocation = nil

                        if isClick {
                            expandNote()
                        }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        hasTriggeredLongPress = true
                        onClose?()
                    }
            )
    }

    var expandedView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
            }
            .frame(height: 20)
            .background(localNoteColor.opacity(0.6))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let window = window else { return }

                        if dragStartFrame == nil {
                            dragStartFrame = window.frame
                            initialMouseLocation = NSEvent.mouseLocation
                        }

                        if let startFrame = dragStartFrame, let startMouse = initialMouseLocation {
                            let currentMouse = NSEvent.mouseLocation
                            let deltaX = currentMouse.x - startMouse.x
                            let deltaY = currentMouse.y - startMouse.y

                            var newOrigin = startFrame.origin
                            newOrigin.x += deltaX
                            newOrigin.y += deltaY

                            var newFrame = startFrame
                            newFrame.origin = newOrigin
                            window.setFrame(clampedFrame(newFrame, for: window, preferredPoint: currentMouse), display: true)
                        }
                    }
                    .onEnded { _ in
                        dragStartFrame = nil
                        initialMouseLocation = nil
                    }
            )

            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteText)
                    .font(.system(size: settings.noteFontSize))
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .background(Color.clear)
                    .focused($isTextEditorFocused)
                    .id("textEditor")

            }
            .padding(8)

            HStack {
                Spacer()
                resizeHandle
            }
        }
        .frame(minWidth: 200, minHeight: 150)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(localNoteColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    var resizeHandle: some View {
        Image(systemName: "arrowtriangle.down.right")
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .padding(6)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard let window = window else { return }
                        if resizeStartFrame == nil { resizeStartFrame = window.frame }
                        if let startFrame = resizeStartFrame {
                            let newWidth = max(200, startFrame.size.width + value.translation.width)
                            let newHeight = max(150, startFrame.size.height - value.translation.height)
                            var newFrame = startFrame
                            newFrame.size.width = newWidth
                            newFrame.size.height = newHeight
                            newFrame.origin.y = startFrame.origin.y + (startFrame.size.height - newHeight)
                            window.setFrame(clampedFrame(newFrame, for: window), display: true)
                        }
                    }
                    .onEnded { _ in resizeStartFrame = nil }
            )
    }

    private func expandNote() {
        NSApp.activate(ignoringOtherApps: true)
        guard let window = window else { return }
        applyExpandedWindowConstraints(to: window)

        let oldFrame = foldedFrame(from: window.frame)
        let targetSize = expandedSize
        var newFrame = oldFrame
        newFrame.origin.x = oldFrame.origin.x + (oldFrame.size.width - targetSize.width) / 2
        newFrame.origin.y = oldFrame.origin.y + (oldFrame.size.height - targetSize.height) / 2
        newFrame.size = targetSize

        window.setFrame(clampedFrame(newFrame, for: window), display: true, animate: true)
        isFolded = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            self.window?.makeKeyAndOrderFront(nil)
            self.isTextEditorFocused = true
        }
    }

    func foldNote() {
        guard let window = window else { return }
        let oldFrame = window.frame
        let targetSize = foldedWindowSize

        isFolded = true

        DispatchQueue.main.async {
            applyFoldedWindowConstraints(to: window)
            var newFrame = oldFrame
            newFrame.origin.x = oldFrame.origin.x + (oldFrame.size.width - targetSize.width) / 2
            newFrame.origin.y = oldFrame.origin.y + (oldFrame.size.height - targetSize.height) / 2
            newFrame.size = targetSize
            window.setFrame(clampedFrame(newFrame, for: window), display: true, animate: true)
        }
    }

    private func applyColorPreset(_ index: Int) {
        let presets: [Color] = [
            SettingsManager.shared.colorPreset1,
            SettingsManager.shared.colorPreset2,
            SettingsManager.shared.colorPreset3
        ]
        guard index < presets.count else { return }
        localNoteColor = presets[index]
    }

    private func foldedFrame(from frame: NSRect) -> NSRect {
        var foldedFrame = frame
        foldedFrame.origin.x = frame.midX - foldedWindowSize.width / 2
        foldedFrame.origin.y = frame.midY - foldedWindowSize.height / 2
        foldedFrame.size = foldedWindowSize
        return foldedFrame
    }

    private func applyFoldedWindowConstraints(to window: NSWindow) {
        window.minSize = foldedWindowSize
        window.maxSize = foldedWindowSize
    }

    private func applyExpandedWindowConstraints(to window: NSWindow) {
        window.minSize = CGSize(width: 200, height: 150)
        window.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }

    private func clampedFrame(_ frame: NSRect, for window: NSWindow?, preferredPoint: NSPoint? = nil) -> NSRect {
        guard let visibleFrame = bestScreen(for: frame, window: window, preferredPoint: preferredPoint)?.visibleFrame else {
            return frame
        }

        var clamped = frame
        let maxX = max(visibleFrame.minX, visibleFrame.maxX - clamped.width)
        let maxY = max(visibleFrame.minY, visibleFrame.maxY - clamped.height)

        clamped.origin.x = min(max(clamped.origin.x, visibleFrame.minX), maxX)
        clamped.origin.y = min(max(clamped.origin.y, visibleFrame.minY), maxY)
        return clamped
    }

    private func bestScreen(for frame: NSRect, window: NSWindow?, preferredPoint: NSPoint? = nil) -> NSScreen? {
        if let preferredPoint,
           let screen = NSScreen.screens.first(where: { $0.frame.contains(preferredPoint) }) {
            return screen
        }

        let center = NSPoint(x: frame.midX, y: frame.midY)
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) {
            return screen
        }

        let intersectingScreen = NSScreen.screens.max { first, second in
            first.frame.intersection(frame).area < second.frame.intersection(frame).area
        }

        return intersectingScreen ?? window?.screen ?? NSScreen.main
    }
}

private extension NSRect {
    var area: CGFloat {
        guard !isNull, !isEmpty else { return 0 }
        return width * height
    }
}
