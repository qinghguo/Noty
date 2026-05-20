import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var shortcutNewNote: String
    @State private var shortcutOpenSettings: String
    @State private var shortcutToggleTopmost: String
    @State private var shortcutFoldNote: String
    @State private var shortcutColor1: String
    @State private var shortcutColor2: String
    @State private var shortcutColor3: String
    @Binding var colorPreset1: Color
    @Binding var colorPreset2: Color
    @Binding var colorPreset3: Color
    var onShortcutRecordingChange: ((Bool) -> Void)?
    var onClose: (() -> Void)?
    @State private var invalidShortcutMessage: String?

    init(shortcutNewNote: Binding<String>, shortcutOpenSettings: Binding<String>, shortcutToggleTopmost: Binding<String>, shortcutFoldNote: Binding<String>, shortcutColor1: Binding<String>, shortcutColor2: Binding<String>, shortcutColor3: Binding<String>, colorPreset1: Binding<Color>, colorPreset2: Binding<Color>, colorPreset3: Binding<Color>, onShortcutRecordingChange: ((Bool) -> Void)?, onClose: (() -> Void)?) {
        self._shortcutNewNote = State(initialValue: shortcutNewNote.wrappedValue)
        self._shortcutOpenSettings = State(initialValue: shortcutOpenSettings.wrappedValue)
        self._shortcutToggleTopmost = State(initialValue: shortcutToggleTopmost.wrappedValue)
        self._shortcutFoldNote = State(initialValue: shortcutFoldNote.wrappedValue)
        self._shortcutColor1 = State(initialValue: shortcutColor1.wrappedValue)
        self._shortcutColor2 = State(initialValue: shortcutColor2.wrappedValue)
        self._shortcutColor3 = State(initialValue: shortcutColor3.wrappedValue)
        self._colorPreset1 = colorPreset1
        self._colorPreset2 = colorPreset2
        self._colorPreset3 = colorPreset3
        self.onShortcutRecordingChange = onShortcutRecordingChange
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 20) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    shortcutSection
                    colorShortcutSection
                    fontSizeSection
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .frame(minWidth: 400, minHeight: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .alert("该快捷键不可用", isPresented: invalidShortcutBinding) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text(invalidShortcutMessage ?? "该快捷键不可用。")
        }
    }

    var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快捷键设置")
                .font(.headline)

            ShortcutRecorderRow(title: "新建便签", shortcut: $shortcutNewNote, onRecordingChange: onShortcutRecordingChange)
                .onChange(of: shortcutNewNote) { _, newValue in
                    let applied = applyShortcutChange(title: "新建便签", value: newValue) {
                        SettingsManager.shared.shortcutNewNote = newValue
                    }
                    if !applied {
                        shortcutNewNote = SettingsManager.shared.shortcutNewNote
                    }
                }
            ShortcutRecorderRow(title: "打开设置", shortcut: $shortcutOpenSettings, onRecordingChange: onShortcutRecordingChange)
                .onChange(of: shortcutOpenSettings) { _, newValue in
                    let applied = applyShortcutChange(title: "打开设置", value: newValue) {
                        SettingsManager.shared.shortcutOpenSettings = newValue
                    }
                    if !applied {
                        shortcutOpenSettings = SettingsManager.shared.shortcutOpenSettings
                    }
                }
            ShortcutRecorderRow(title: "置顶/取消置顶", shortcut: $shortcutToggleTopmost, onRecordingChange: onShortcutRecordingChange)
                .onChange(of: shortcutToggleTopmost) { _, newValue in
                    let applied = applyShortcutChange(title: "置顶/取消置顶", value: newValue) {
                        SettingsManager.shared.shortcutToggleTopmost = newValue
                    }
                    if !applied {
                        shortcutToggleTopmost = SettingsManager.shared.shortcutToggleTopmost
                    }
                }
            ShortcutRecorderRow(title: "折叠便签", shortcut: $shortcutFoldNote, onRecordingChange: onShortcutRecordingChange)
                .onChange(of: shortcutFoldNote) { _, newValue in
                    let applied = applyShortcutChange(title: "折叠便签", value: newValue) {
                        SettingsManager.shared.shortcutFoldNote = newValue
                    }
                    if !applied {
                        shortcutFoldNote = SettingsManager.shared.shortcutFoldNote
                    }
                }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    var colorShortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("颜色快捷键")
                .font(.headline)

            ColorShortcutRow(
                title: "颜色 1",
                shortcut: $shortcutColor1,
                color: $colorPreset1,
                onRecordingChange: onShortcutRecordingChange
            )
            .onChange(of: shortcutColor1) { _, newValue in
                let applied = applyShortcutChange(title: "颜色 1", value: newValue) {
                    SettingsManager.shared.shortcutColor1 = newValue
                }
                if !applied {
                    shortcutColor1 = SettingsManager.shared.shortcutColor1
                }
            }
            ColorShortcutRow(
                title: "颜色 2",
                shortcut: $shortcutColor2,
                color: $colorPreset2,
                onRecordingChange: onShortcutRecordingChange
            )
            .onChange(of: shortcutColor2) { _, newValue in
                let applied = applyShortcutChange(title: "颜色 2", value: newValue) {
                    SettingsManager.shared.shortcutColor2 = newValue
                }
                if !applied {
                    shortcutColor2 = SettingsManager.shared.shortcutColor2
                }
            }
            ColorShortcutRow(
                title: "颜色 3",
                shortcut: $shortcutColor3,
                color: $colorPreset3,
                onRecordingChange: onShortcutRecordingChange
            )
            .onChange(of: shortcutColor3) { _, newValue in
                let applied = applyShortcutChange(title: "颜色 3", value: newValue) {
                    SettingsManager.shared.shortcutColor3 = newValue
                }
                if !applied {
                    shortcutColor3 = SettingsManager.shared.shortcutColor3
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    var fontSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("字体大小")
                    .frame(width: 120, alignment: .leading)

                Spacer()

                Slider(
                    value: Binding(
                        get: { settings.noteFontSize },
                        set: { settings.noteFontSize = $0 }
                    ),
                    in: 10...24,
                    step: 1
                )
                    .frame(width: 200)

                Text("\(Int(settings.noteFontSize))")
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 36, alignment: .trailing)
            }
            .frame(height: 36)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var invalidShortcutBinding: Binding<Bool> {
        Binding(
            get: { invalidShortcutMessage != nil },
            set: { if !$0 { invalidShortcutMessage = nil } }
        )
    }

    @discardableResult
    private func applyShortcutChange(title: String, value: String, update: () -> Void) -> Bool {
        if KeyboardShortcut.isReservedSystemShortcut(value) {
            invalidShortcutMessage = "\(title) 不能使用 macOS 保留快捷键，例如 Command+W 或 Command+Q。这些组合会继续保留给系统默认操作。"
            return false
        }

        update()
        NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
        return true
    }
}

struct ShortcutRecorderRow: View {
    let title: String
    @Binding var shortcut: String
    var onRecordingChange: ((Bool) -> Void)?
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(title)
                .frame(width: 120, alignment: .leading)

            Spacer()

            Button(action: {
                isRecording.toggle()
                onRecordingChange?(isRecording)
            }) {
                Text(isRecording ? "按下快捷键..." : (shortcut.isEmpty ? "未设置" : shortcut))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isRecording ? .accentColor : .primary)
                    .frame(minWidth: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecording ? Color.accentColor.opacity(0.1) : Color(NSColor.textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcutRecorder(isRecording: $isRecording, shortcut: $shortcut, onRecordingChange: onRecordingChange)
        }
        .frame(height: 36)
    }
}

struct ColorShortcutRow: View {
    let title: String
    @Binding var shortcut: String
    @Binding var color: Color
    var onRecordingChange: ((Bool) -> Void)?
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(title)
                .frame(width: 80, alignment: .leading)

            Spacer()

            Button(action: {
                isRecording.toggle()
                onRecordingChange?(isRecording)
            }) {
                Text(isRecording ? "按下快捷键..." : (shortcut.isEmpty ? "未设置" : shortcut))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isRecording ? .accentColor : .primary)
                    .frame(minWidth: 100)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecording ? Color.accentColor.opacity(0.1) : Color(NSColor.textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcutRecorder(isRecording: $isRecording, shortcut: $shortcut, onRecordingChange: onRecordingChange)

            ColorPicker("", selection: $color)
                .labelsHidden()
                .frame(width: 44, height: 28)
        }
        .frame(height: 36)
    }
}

struct KeyboardShortcutRecorder: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var shortcut: String
    var onRecordingChange: ((Bool) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isRecording {
            if context.coordinator.monitor == nil {
                context.coordinator.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    let modifiers = event.modifierFlags
                    let keyCode = event.keyCode

                    var parts: [String] = []
                    if modifiers.contains(.command) { parts.append("⌘") }
                    if modifiers.contains(.option) { parts.append("⌥") }
                    if modifiers.contains(.control) { parts.append("⌃") }
                    if modifiers.contains(.shift) { parts.append("⇧") }

                    let keyString = KeyboardShortcut.displayString(for: keyCode)
                    if !keyString.isEmpty {
                        parts.append(keyString)
                    }

                    if !parts.isEmpty {
                        shortcut = parts.joined(separator: "+")
                        isRecording = false
                        DispatchQueue.main.async {
                            context.coordinator.onRecordingChange?(false)
                        }
                    }

                    return nil
                }
            }
        } else {
            context.coordinator.removeMonitor()
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onRecordingChange: { isRecording in
            onRecordingChange?(isRecording)
        })
    }

    final class Coordinator {
        var monitor: Any?
        let onRecordingChange: ((Bool) -> Void)?

        init(onRecordingChange: ((Bool) -> Void)? = nil) {
            self.onRecordingChange = onRecordingChange
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
    }
}

extension View {
    func keyboardShortcutRecorder(isRecording: Binding<Bool>, shortcut: Binding<String>, onRecordingChange: ((Bool) -> Void)? = nil) -> some View {
        self.background(KeyboardShortcutRecorder(isRecording: isRecording, shortcut: shortcut, onRecordingChange: onRecordingChange))
    }
}
