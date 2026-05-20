import Cocoa
import Carbon

struct KeyboardShortcut: Equatable {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags

    private static let relevantModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    static func parse(_ shortcut: String) -> KeyboardShortcut? {
        let trimmedShortcut = shortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedShortcut.isEmpty else { return nil }

        var modifiers: NSEvent.ModifierFlags = []
        var resolvedKeyCode: UInt16?

        for part in trimmedShortcut.split(separator: "+") {
            let token = String(part).trimmingCharacters(in: .whitespaces)
            switch token {
            case "⌘", "Cmd", "Command":
                modifiers.insert(.command)
            case "⌥", "Opt", "Option", "Alt":
                modifiers.insert(.option)
            case "⌃", "Ctrl", "Control":
                modifiers.insert(.control)
            case "⇧", "Shift":
                modifiers.insert(.shift)
            default:
                resolvedKeyCode = Self.keyCode(for: token)
            }
        }

        guard let resolvedKeyCode else { return nil }
        return KeyboardShortcut(keyCode: resolvedKeyCode, modifiers: modifiers)
    }

    static func isReservedSystemShortcut(_ shortcut: String) -> Bool {
        guard let parsed = parse(shortcut) else { return false }

        let reserved: [KeyboardShortcut] = [
            KeyboardShortcut(keyCode: 13, modifiers: [.command]),
            KeyboardShortcut(keyCode: 12, modifiers: [.command])
        ]

        return reserved.contains(parsed)
    }

    func matches(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool {
        self.keyCode == keyCode && Self.normalized(modifiers) == self.modifiers
    }

    func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let normalizedFlags = Self.normalized(flags)
        return Int64(self.keyCode) == keyCode && normalizedFlags == Self.cgFlags(from: modifiers)
    }

    var menuKeyEquivalent: String {
        switch keyCode {
        case 36: return "\r"
        case 48: return "\t"
        case 49: return " "
        case 51: return String(UnicodeScalar(NSDeleteCharacter) ?? UnicodeScalar(0x08)!)
        case 53: return String(Character(UnicodeScalar(0x1B)!))
        default:
            return Self.displayString(for: keyCode).lowercased()
        }
    }

    private static func normalized(_ modifiers: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        modifiers.intersection(relevantModifiers)
    }

    private static func normalized(_ flags: CGEventFlags) -> CGEventFlags {
        var normalized: CGEventFlags = []
        if flags.contains(.maskCommand) { normalized.insert(.maskCommand) }
        if flags.contains(.maskAlternate) { normalized.insert(.maskAlternate) }
        if flags.contains(.maskControl) { normalized.insert(.maskControl) }
        if flags.contains(.maskShift) { normalized.insert(.maskShift) }
        return normalized
    }

    private static func cgFlags(from modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        if modifiers.contains(.command) { flags.insert(.maskCommand) }
        if modifiers.contains(.option) { flags.insert(.maskAlternate) }
        if modifiers.contains(.control) { flags.insert(.maskControl) }
        if modifiers.contains(.shift) { flags.insert(.maskShift) }
        return flags
    }

    private static func keyCode(for key: String) -> UInt16? {
        switch key.uppercased() {
        case "A": return 0
        case "S": return 1
        case "D": return 2
        case "F": return 3
        case "H": return 4
        case "G": return 5
        case "Z": return 6
        case "X": return 7
        case "C": return 8
        case "V": return 9
        case "B": return 11
        case "Q": return 12
        case "W": return 13
        case "E": return 14
        case "R": return 15
        case "Y": return 16
        case "T": return 17
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "6": return 22
        case "5": return 23
        case "=": return 24
        case "9": return 25
        case "7": return 26
        case "-": return 27
        case "8": return 28
        case "0": return 29
        case "]": return 30
        case "O": return 31
        case "U": return 32
        case "[": return 33
        case "I": return 34
        case "P": return 35
        case "RETURN", "ENTER": return 36
        case "L": return 37
        case "J": return 38
        case "'": return 39
        case "K": return 40
        case ";": return 41
        case "\\": return 42
        case ",": return 43
        case "/": return 44
        case "N": return 45
        case "M": return 46
        case ".": return 47
        case "TAB": return 48
        case "SPACE": return 49
        case "`": return 50
        case "DELETE", "BACKSPACE": return 51
        case "ESC", "ESCAPE": return 53
        default: return nil
        }
    }

    static func displayString(for keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "Delete"
        case 53: return "Esc"
        default: return ""
        }
    }
}

@MainActor
protocol GlobalHotkeyDelegate: AnyObject {
    func createNewNote()
    func openSettings()
    func closeKeyWindow()
    func toggleTopmost()
    func foldFrontmostNote()
    func switchColorPreset(_ index: Int)
}

final class GlobalHotkeyManager: @unchecked Sendable {
    private enum Action {
        case newNote
        case openSettings
        case closeKeyWindow
        case toggleTopmost
        case foldFrontmostNote
        case switchColorPreset(Int)
    }

    weak var delegate: GlobalHotkeyDelegate?
    private var localMonitor: Any?
    private var newNoteHotKeyRef: EventHotKeyRef?
    private var hotKeyHandlerRef: EventHandlerRef?
    private var isSuspended = false
    private static let newNoteHotKeyID: UInt32 = 1
    private static let hotKeySignature: OSType = 0x4E545931

    init(delegate: GlobalHotkeyDelegate) {
        self.delegate = delegate
    }

    func startMonitoring() {
        installHotKeyHandlerIfNeeded()
        registerGlobalNewNoteShortcut()
        setupLocalMonitor()
    }

    private func setupLocalMonitor() {
        if localMonitor != nil { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if self.isSuspended { return event }

            if let action = self.actionForLocalEvent(keyCode: event.keyCode, modifiers: event.modifierFlags) {
                Task { @MainActor in
                    self.perform(action)
                }
                return nil
            }

            return event
        }
    }

    func stopMonitoring() {
        unregisterGlobalNewNoteShortcut()
        if let hotKeyHandlerRef {
            RemoveEventHandler(hotKeyHandlerRef)
            self.hotKeyHandlerRef = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    @MainActor
    func reloadShortcuts() {
        registerGlobalNewNoteShortcut()
    }

    private func installHotKeyHandlerIfNeeded() {
        guard hotKeyHandlerRef == nil else { return }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handleRegisteredHotKey(eventRef)
                return noErr
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &hotKeyHandlerRef
        )

        if status != noErr {
            print("安装全局快捷键处理器失败: \(status)")
        }
    }

    private func registerGlobalNewNoteShortcut() {
        unregisterGlobalNewNoteShortcut()

        guard let shortcut = KeyboardShortcut.parse(SettingsManager.shared.shortcutNewNote) else {
            return
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.hotKeySignature,
            id: Self.newNoteHotKeyID
        )
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            carbonModifiers(from: shortcut.modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &newNoteHotKeyRef
        )

        if status != noErr {
            print("注册全局新建便签快捷键失败: \(status)")
        }
    }

    private func unregisterGlobalNewNoteShortcut() {
        guard let newNoteHotKeyRef else { return }
        UnregisterEventHotKey(newNoteHotKeyRef)
        self.newNoteHotKeyRef = nil
    }

    private func handleRegisteredHotKey(_ eventRef: EventRef?) {
        guard !isSuspended, let eventRef else { return }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr,
              hotKeyID.signature == Self.hotKeySignature,
              hotKeyID.id == Self.newNoteHotKeyID else {
            return
        }

        Task { @MainActor in
            self.perform(.newNote)
        }
    }

    private func actionForLocalEvent(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Action? {
        currentLocalShortcuts().first(where: { $0.shortcut.matches(keyCode: keyCode, modifiers: modifiers) })?.action
    }

    private func currentLocalShortcuts() -> [(shortcut: KeyboardShortcut, action: Action)] {
        let settings = SettingsManager.shared
        return [
            ("⌘+W", .closeKeyWindow),
            (settings.shortcutOpenSettings, .openSettings),
            (settings.shortcutToggleTopmost, .toggleTopmost),
            (settings.shortcutFoldNote, .foldFrontmostNote),
            (settings.shortcutColor1, .switchColorPreset(0)),
            (settings.shortcutColor2, .switchColorPreset(1)),
            (settings.shortcutColor3, .switchColorPreset(2))
        ].compactMap { shortcutString, action in
            KeyboardShortcut.parse(shortcutString).map { ($0, action) }
        }
    }

    @MainActor
    private func perform(_ action: Action) {
        switch action {
        case .newNote:
            delegate?.createNewNote()
        case .openSettings:
            delegate?.openSettings()
        case .closeKeyWindow:
            delegate?.closeKeyWindow()
        case .toggleTopmost:
            delegate?.toggleTopmost()
        case .foldFrontmostNote:
            delegate?.foldFrontmostNote()
        case .switchColorPreset(let index):
            delegate?.switchColorPreset(index)
        }
    }

    @MainActor
    func setSuspended(_ suspended: Bool) {
        isSuspended = suspended
    }

    private func carbonModifiers(from modifiers: NSEvent.ModifierFlags) -> UInt32 {
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        return carbonModifiers
    }
}
