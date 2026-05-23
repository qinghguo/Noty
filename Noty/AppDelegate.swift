import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, GlobalHotkeyDelegate {
    var statusItem: NSStatusItem!
    var windowControllers: [NoteWindowController] = []
    var hotkeyManager: GlobalHotkeyManager!
    var settingsWindow: NSWindow?
    private var menuItems: [String: [NSMenuItem]] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        hotkeyManager = GlobalHotkeyManager(delegate: self)
        hotkeyManager.startMonitoring()
        setupShortcutChangeObserver()
        updateMenuBarShortcuts()
        createNewNote()
        setupTextEditingShortcuts()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "Noty")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        let menu = NSMenu()

        let newNoteItem = NSMenuItem(
            title: "新建",
            action: #selector(createNewNote),
            keyEquivalent: "n"
        )
        newNoteItem.keyEquivalentModifierMask = .command
        newNoteItem.target = self
        menu.addItem(newNoteItem)
        registerMenuItem(newNoteItem, for: "newNote")

        let topmostItem = NSMenuItem(
            title: "置顶/取消置顶",
            action: #selector(toggleTopmost),
            keyEquivalent: "/"
        )
        topmostItem.keyEquivalentModifierMask = .option
        topmostItem.target = self
        menu.addItem(topmostItem)
        registerMenuItem(topmostItem, for: "topmost")

        let foldItem = NSMenuItem(
            title: "折叠",
            action: #selector(foldFrontmostNote),
            keyEquivalent: "["
        )
        foldItem.keyEquivalentModifierMask = .option
        foldItem.target = self
        menu.addItem(foldItem)
        registerMenuItem(foldItem, for: "fold")

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        registerMenuItem(settingsItem, for: "settings")

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func setupShortcutChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShortcutDidChange),
            name: .shortcutDidChange,
            object: nil
        )
    }

    @objc private func handleShortcutDidChange() {
        updateMenuBarShortcuts()
        hotkeyManager?.reloadShortcuts()
    }

    func updateMenuBarShortcuts() {
        let configuredShortcuts: [String: String] = [
            "newNote": SettingsManager.shared.shortcutNewNote,
            "settings": SettingsManager.shared.shortcutOpenSettings,
            "topmost": SettingsManager.shared.shortcutToggleTopmost,
            "fold": SettingsManager.shared.shortcutFoldNote
        ]

        for (identifier, items) in menuItems {
            let shortcutString = configuredShortcuts[identifier] ?? ""
            let parsedShortcut = KeyboardShortcut.parse(shortcutString)
            for item in items {
                item.keyEquivalent = parsedShortcut?.menuKeyEquivalent ?? ""
                item.keyEquivalentModifierMask = parsedShortcut?.modifiers ?? []
            }
        }
    }

    private func registerMenuItem(_ item: NSMenuItem, for identifier: String) {
        menuItems[identifier, default: []].append(item)
    }

    @objc func createNewNote() {
        let wc = NoteWindowController(startExpanded: true)
        wc.showWindow(nil)
        windowControllers.append(wc)
    }

    @objc func toggleTopmost() {
        guard let stickyWindow = findFrontmostStickyWindow() else { return }

        if stickyWindow.level == .floating {
            stickyWindow.level = .normal
        } else {
            stickyWindow.level = .floating
        }
    }

    @objc func foldFrontmostNote() {
        guard let stickyWC = findFrontmostStickyWindowController() else { return }
        stickyWC.foldNote()
    }

    @objc func openSettings() {
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsManager = SettingsManager.shared
        let settingsView = SettingsView(
            shortcutNewNote: Binding(
                get: { settingsManager.shortcutNewNote },
                set: { settingsManager.shortcutNewNote = $0 }
            ),
            shortcutOpenSettings: Binding(
                get: { settingsManager.shortcutOpenSettings },
                set: { settingsManager.shortcutOpenSettings = $0 }
            ),
            shortcutToggleTopmost: Binding(
                get: { settingsManager.shortcutToggleTopmost },
                set: { settingsManager.shortcutToggleTopmost = $0 }
            ),
            shortcutFoldNote: Binding(
                get: { settingsManager.shortcutFoldNote },
                set: { settingsManager.shortcutFoldNote = $0 }
            ),
            shortcutColor1: Binding(
                get: { settingsManager.shortcutColor1 },
                set: { settingsManager.shortcutColor1 = $0 }
            ),
            shortcutColor2: Binding(
                get: { settingsManager.shortcutColor2 },
                set: { settingsManager.shortcutColor2 = $0 }
            ),
            shortcutColor3: Binding(
                get: { settingsManager.shortcutColor3 },
                set: { settingsManager.shortcutColor3 = $0 }
            ),
            colorPreset1: Binding(
                get: { settingsManager.colorPreset1 },
                set: { settingsManager.colorPreset1 = $0 }
            ),
            colorPreset2: Binding(
                get: { settingsManager.colorPreset2 },
                set: { settingsManager.colorPreset2 = $0 }
            ),
            colorPreset3: Binding(
                get: { settingsManager.colorPreset3 },
                set: { settingsManager.colorPreset3 = $0 }
            ),
            onShortcutRecordingChange: { [weak self] isRecording in
                self?.hotkeyManager?.setSuspended(isRecording)
            },
            onClose: { [weak self] in
                self?.settingsWindow?.close()
                self?.settingsWindow = nil
            }
        )

        let hostingView = NSHostingView(rootView: settingsView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        self.settingsWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func switchColorPreset(_ index: Int) {
        guard let targetWindow = findFrontmostStickyWindow() else { return }
        NotificationCenter.default.post(
            name: .switchNoteColor,
            object: targetWindow,
            userInfo: ["colorIndex": index]
        )
    }

    func closeActiveNote() {
        guard let stickyWindow = findFrontmostStickyWindow() else { return }
        NotificationCenter.default.post(
            name: .closeActiveNote,
            object: stickyWindow
        )
    }

    @objc func closeKeyWindow() {
        if let settingsWindow, settingsWindow.isKeyWindow || settingsWindow.isMainWindow {
            settingsWindow.close()
            self.settingsWindow = nil
            return
        }

        if let keyWindow = NSApp.keyWindow {
            if keyWindow === settingsWindow {
                settingsWindow?.close()
                settingsWindow = nil
                return
            }

            if let stickyController = windowControllers.first(where: { $0.window === keyWindow }) {
                stickyController.closeNote()
                return
            }

            keyWindow.performClose(nil)
            return
        }

        if let stickyController = findFrontmostStickyWindowController() {
            stickyController.closeNote()
            return
        }

        settingsWindow?.close()
        settingsWindow = nil
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func setupTextEditingShortcuts() {
            // 注意闭包这里加上了 [weak self]，允许调用 AppDelegate 里的方法
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                
                // 只拦截带有 Command 键的组合
                guard modifierFlags.contains(.command) else { return event }
                
                let hasShift = modifierFlags.contains(.shift)
                let characters = event.charactersIgnoringModifiers?.lowercased()
                
                // 🌟 新增逻辑：强行拦截 Cmd + Q 退出软件
                if characters == "q" && !hasShift {
                    self?.quitApp()
                    return nil // 返回 nil 代表彻底拦截，系统不会再发出“咚”的报错声
                }
                
                var selector: Selector?
                
                // 处理基础的文本编辑操作
                switch characters {
                case "x": selector = Selector(("cut:"))
                case "c": selector = Selector(("copy:"))
                case "v": selector = Selector(("paste:"))
                case "a": selector = Selector(("selectAll:"))
                case "z": selector = hasShift ? Selector(("redo:")) : Selector(("undo:"))
                default: break
                }
                
                if let action = selector {
                    if NSApp.sendAction(action, to: nil, from: nil) {
                        return nil
                    }
                }
                
                return event
            }
        }

    private func findFrontmostStickyWindow() -> NSWindow? {
        let stickyWindows = windowControllers.compactMap { $0.window }
        guard !stickyWindows.isEmpty else { return nil }

        for window in NSApp.orderedWindows {
            if stickyWindows.contains(where: { $0 === window }) {
                return window
            }
        }
        return stickyWindows.first
    }

    private func findFrontmostStickyWindowController() -> NoteWindowController? {
        let stickyWindows = windowControllers.compactMap { ($0.window, $0) }
        guard !stickyWindows.isEmpty else { return nil }

        for window in NSApp.orderedWindows {
            if let wc = stickyWindows.first(where: { $0.0 === window }) {
                return wc.1
            }
        }
        return windowControllers.first
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window === settingsWindow {
            settingsWindow = nil
        }
    }
}
