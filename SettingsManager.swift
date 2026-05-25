import SwiftUI
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var noteColor: Color = Color(hex: "#f5f1bb")
    @Published var colorPreset1: Color = Color(hex: "#f5f1bb")
    @Published var colorPreset2: Color = Color(hex: "#f7eef0")
    @Published var colorPreset3: Color = Color(hex: "#ccf0f1")
    @Published var shortcutNewNote: String = "⌥+⌘+/"
    @Published var shortcutOpenSettings: String = "⌘+,"
    @Published var shortcutToggleTopmost: String = "⌥+/"
    @Published var shortcutFoldNote: String = "⌥+["
    @Published var shortcutTodoList: String = "⌥+."
    @Published var shortcutColor1: String = "⌥+1"
    @Published var shortcutColor2: String = "⌥+2"
    @Published var shortcutColor3: String = "⌥+3"
    @Published var noteFontSize: CGFloat = 14

    private var cancellables = Set<AnyCancellable>()

    private init() {
        noteColor = loadColor(key: "noteColor", default: Color(hex: "#f5f1bb"))
        colorPreset1 = loadColor(key: "colorPreset0", default: Color(hex: "#f5f1bb"))
        colorPreset2 = loadColor(key: "colorPreset1", default: Color(hex: "#f7eef0"))
        colorPreset3 = loadColor(key: "colorPreset2", default: Color(hex: "#ccf0f1"))

        let storedShortcutNewNote = UserDefaults.standard.string(forKey: "shortcutNewNote")
        shortcutNewNote = storedShortcutNewNote ?? "⌥+⌘+/"
        if storedShortcutNewNote == nil || storedShortcutNewNote == "⌘+N" {
            shortcutNewNote = "⌥+⌘+/"
            UserDefaults.standard.set(shortcutNewNote, forKey: "shortcutNewNote")
        }
        shortcutOpenSettings = UserDefaults.standard.string(forKey: "shortcutOpenSettings") ?? "⌘+,"
        shortcutToggleTopmost = UserDefaults.standard.string(forKey: "shortcutToggleTopmost") ?? "⌥+/"
        shortcutFoldNote = UserDefaults.standard.string(forKey: "shortcutFoldNote") ?? "⌥+["
        shortcutTodoList = UserDefaults.standard.string(forKey: "shortcutTodoList") ?? "⌥+."
        shortcutColor1 = UserDefaults.standard.string(forKey: "shortcutColor1") ?? "⌥+1"
        shortcutColor2 = UserDefaults.standard.string(forKey: "shortcutColor2") ?? "⌥+2"
        shortcutColor3 = UserDefaults.standard.string(forKey: "shortcutColor3") ?? "⌥+3"
        noteFontSize = CGFloat(UserDefaults.standard.double(forKey: "noteFontSize"))
        if noteFontSize == 0 {
            noteFontSize = 14
        }

        setupObservers()
    }

    private func setupObservers() {
        $noteColor
            .dropFirst()
            .sink { [weak self] color in
                self?.saveColor(key: "noteColor", color: color)
            }
            .store(in: &cancellables)

        $colorPreset1
            .dropFirst()
            .sink { [weak self] color in
                self?.saveColor(key: "colorPreset0", color: color)
            }
            .store(in: &cancellables)

        $colorPreset2
            .dropFirst()
            .sink { [weak self] color in
                self?.saveColor(key: "colorPreset1", color: color)
            }
            .store(in: &cancellables)

        $colorPreset3
            .dropFirst()
            .sink { [weak self] color in
                self?.saveColor(key: "colorPreset2", color: color)
            }
            .store(in: &cancellables)

        $shortcutNewNote
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "shortcutNewNote") }
            .store(in: &cancellables)

        $shortcutOpenSettings
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "shortcutOpenSettings") }
            .store(in: &cancellables)

        $shortcutToggleTopmost
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "shortcutToggleTopmost") }
            .store(in: &cancellables)

        $shortcutFoldNote
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "shortcutFoldNote") }
            .store(in: &cancellables)

        $shortcutTodoList
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "shortcutTodoList") }
            .store(in: &cancellables)

        $shortcutColor1
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "shortcutColor1") }
            .store(in: &cancellables)

        $shortcutColor2
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "shortcutColor2") }
            .store(in: &cancellables)

        $shortcutColor3
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "shortcutColor3") }
            .store(in: &cancellables)

        $noteFontSize
            .dropFirst()
            .sink { newSize in
                UserDefaults.standard.set(Double(newSize), forKey: "noteFontSize")
            }
            .store(in: &cancellables)
    }

    private func saveColor(key: String, color: Color) {
        let nsColor = NSColor(color)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: key)
        }
    }

    private func loadColor(key: String, default defaultColor: Color) -> Color {
        if let colorData = UserDefaults.standard.data(forKey: key),
           let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            return Color(nsColor)
        }
        return defaultColor
    }

    func applyColorPreset(_ index: Int) {
        switch index {
        case 0: noteColor = colorPreset1
        case 1: noteColor = colorPreset2
        case 2: noteColor = colorPreset3
        default: break
        }
    }

    var presetColors: [Color] {
        [.yellow, .green, .blue, .pink, .orange, .purple]
    }
}
