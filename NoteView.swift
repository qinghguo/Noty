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
                TodoTextView(
                    text: $noteText,
                    fontSize: settings.noteFontSize,
                    isFocused: $isTextEditorFocused
                )
                .background(Color.clear)
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

private struct TodoTextView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var isFocused: FocusState<Bool>.Binding

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: isFocused)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.borderType = .noBorder

        let textView = TodoNSTextView()
        textView.delegate = context.coordinator
        textView.todoDelegate = context.coordinator
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.string = text
        textView.font = .systemFont(ofSize: fontSize)

        scrollView.documentView = textView
        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? TodoNSTextView else { return }
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(clampedRange(selectedRange, in: textView.string))
        }
        textView.font = .systemFont(ofSize: fontSize)

        if isFocused.wrappedValue, textView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    private func clampedRange(_ range: NSRange, in string: String) -> NSRange {
        let length = (string as NSString).length
        return NSRange(location: min(range.location, length), length: min(range.length, max(0, length - range.location)))
    }

    final class Coordinator: NSObject, NSTextViewDelegate, TodoNSTextViewDelegate {
        @Binding private var text: String
        private var isFocused: FocusState<Bool>.Binding
        weak var textView: TodoNSTextView?

        init(text: Binding<String>, isFocused: FocusState<Bool>.Binding) {
            self._text = text
            self.isFocused = isFocused
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }

        func textDidBeginEditing(_ notification: Notification) {
            isFocused.wrappedValue = true
        }

        func textDidEndEditing(_ notification: Notification) {
            isFocused.wrappedValue = false
        }

        func insertTodoMarker(in textView: TodoNSTextView) {
            let nsString = textView.string as NSString
            let selectedRange = textView.selectedRange()
            let lineRange = nsString.lineRange(for: NSRange(location: selectedRange.location, length: 0))
            let linePrefix = nsString.substring(with: NSRange(location: lineRange.location, length: min(2, lineRange.length)))

            if linePrefix == "○ " || linePrefix == "● " {
                return
            }

            textView.insertText("○ ", replacementRange: NSRange(location: lineRange.location, length: 0))
            text = textView.string
        }

        func toggleTodoLine(at characterIndex: Int, in textView: TodoNSTextView) {
            let nsString = textView.string as NSString
            guard characterIndex < nsString.length else { return }

            let lineRange = nsString.lineRange(for: NSRange(location: characterIndex, length: 0))
            guard lineRange.length > 0 else { return }

            let linePrefix = nsString.substring(with: NSRange(location: lineRange.location, length: min(2, lineRange.length)))
            guard linePrefix == "○ " || linePrefix == "● " else { return }

            let replacement = linePrefix == "○ " ? "●" : "○"
            let markerRange = NSRange(location: lineRange.location, length: 1)
            guard textView.shouldChangeText(in: markerRange, replacementString: replacement) else { return }
            textView.textStorage?.replaceCharacters(in: markerRange, with: replacement)
            textView.didChangeText()
            textView.needsDisplay = true
            text = textView.string
        }
    }
}

private protocol TodoNSTextViewDelegate: AnyObject {
    func insertTodoMarker(in textView: TodoNSTextView)
    func toggleTodoLine(at characterIndex: Int, in textView: TodoNSTextView)
}

private final class TodoNSTextView: NSTextView {
    weak var todoDelegate: TodoNSTextViewDelegate?

    override func keyDown(with event: NSEvent) {
        if let shortcut = KeyboardShortcut.parse(SettingsManager.shared.shortcutTodoList),
           shortcut.matches(keyCode: event.keyCode, modifiers: event.modifierFlags) {
            todoDelegate?.insertTodoMarker(in: self)
            return
        }

        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let textContainer, let layoutManager else {
            super.mouseDown(with: event)
            return
        }

        let textOrigin = textContainerOrigin
        let containerPoint = NSPoint(
            x: point.x - textOrigin.x,
            y: point.y - textOrigin.y
        )
        let glyphIndex = layoutManager.glyphIndex(for: containerPoint, in: textContainer)
        let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)

        if isTodoCircleClick(at: characterIndex, point: containerPoint) {
            todoDelegate?.toggleTodoLine(at: characterIndex, in: self)
            return
        }

        super.mouseDown(with: event)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawCompletedTodoChecks()
    }

    private func isTodoCircleClick(at characterIndex: Int, point: NSPoint) -> Bool {
        let nsString = string as NSString
        guard characterIndex < nsString.length else { return false }

        let lineRange = nsString.lineRange(for: NSRange(location: characterIndex, length: 0))
        guard lineRange.length >= 1 else { return false }
        let marker = nsString.substring(with: NSRange(location: lineRange.location, length: 1))
        guard marker == "○" || marker == "●" else { return false }

        let clickedMarker = characterIndex == lineRange.location || characterIndex == lineRange.location + 1
        guard clickedMarker else { return false }

        if let layoutManager, let textContainer {
            let glyphRange = layoutManager.glyphRange(
                forCharacterRange: NSRange(location: lineRange.location, length: 1),
                actualCharacterRange: nil
            )
            let markerRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer).insetBy(dx: -4, dy: -4)
            return markerRect.contains(point)
        }

        return true
    }

    private func drawCompletedTodoChecks() {
        guard let layoutManager, let textContainer else { return }

        let nsString = string as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        var searchRange = fullRange

        while searchRange.location < fullRange.length {
            let lineRange = nsString.lineRange(for: NSRange(location: searchRange.location, length: 0))
            if lineRange.length > 0,
               nsString.substring(with: NSRange(location: lineRange.location, length: 1)) == "●" {
                drawCheckMark(forMarkerAt: lineRange.location, layoutManager: layoutManager, textContainer: textContainer)
            }

            let nextLocation = NSMaxRange(lineRange)
            if nextLocation <= searchRange.location { break }
            searchRange.location = nextLocation
            searchRange.length = fullRange.length - searchRange.location
        }
    }

    private func drawCheckMark(forMarkerAt markerIndex: Int, layoutManager: NSLayoutManager, textContainer: NSTextContainer) {
        let glyphRange = layoutManager.glyphRange(
            forCharacterRange: NSRange(location: markerIndex, length: 1),
            actualCharacterRange: nil
        )
        var markerRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        markerRect.origin.x += textContainerOrigin.x
        markerRect.origin.y += textContainerOrigin.y

        let side = min(markerRect.width, markerRect.height) * 0.72
        guard side > 4 else { return }

        let center = NSPoint(x: markerRect.midX, y: markerRect.midY)
        let start = NSPoint(x: center.x - side * 0.32, y: center.y + side * 0.02)
        let middle = NSPoint(x: center.x - side * 0.08, y: center.y + side * 0.25)
        let end = NSPoint(x: center.x + side * 0.34, y: center.y - side * 0.24)

        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: middle)
        path.line(to: end)
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.lineWidth = max(1.6, side * 0.18)

        NSColor.white.setStroke()
        path.stroke()
    }
}
