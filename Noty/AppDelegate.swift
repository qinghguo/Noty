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
        setupMainMenu()
        setupMenuBar()
        hotkeyManager = GlobalHotkeyManager(delegate: self)
        hotkeyManager.startMonitoring()
        setupShortcutChangeObserver()
        updateMenuBarShortcuts()
        createNewNote()
    }

    func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        registerMenuItem(settingsItem, for: "settings")

        let quitItem = NSMenuItem(
            title: "退出 Noty",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "文件")

        let newNoteItem = NSMenuItem(
            title: "新建",
            action: #selector(createNewNote),
            keyEquivalent: "n"
        )
        newNoteItem.keyEquivalentModifierMask = .command
        newNoteItem.target = self
        fileMenu.addItem(newNoteItem)
        registerMenuItem(newNoteItem, for: "newNote")

        let closeWindowItem = NSMenuItem(
            title: "关闭窗口",
            action: #selector(closeKeyWindow),
            keyEquivalent: "w"
        )
        closeWindowItem.keyEquivalentModifierMask = .command
        closeWindowItem.target = self
        fileMenu.addItem(closeWindowItem)

        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        NSApp.mainMenu = mainMenu
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
            keyEquivalent: ""
        )
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
