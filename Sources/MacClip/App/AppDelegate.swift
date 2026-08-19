import AppKit
import SwiftUI

/// Coordena o ciclo de vida do app e liga todas as peças:
/// persistência (StorageService/JSON), UI (status item + popover), observação do
/// clipboard e atalho global. É aqui que a injeção de dependências acontece.
final class AppDelegate: NSObject, NSApplicationDelegate {

    // Persistência
    private var storage: StorageService!
    private var viewModel: ClipboardViewModel!

    // UI (barra de status)
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    // Serviços de sistema
    private var monitor: PasteboardMonitor!
    private var hotKey: HotKeyService!

    // MARK: - Ciclo de vida

    func applicationDidFinishLaunching(_ notification: Notification) {
        // App discreto: sem ícone no Dock (ver ADR-0004).
        NSApp.setActivationPolicy(.accessory)

        setupPersistence()
        setupStatusItem()
        setupPopover()
        setupMonitor()
        setupHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
        hotKey?.unregister()
    }

    // MARK: - Setup

    private func setupPersistence() {
        storage = StorageService()
        viewModel = ClipboardViewModel(storage: storage)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "MacClip"
            )
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        let root = ClipboardPopoverView(onPasteAndClose: { [weak self] in
            self?.closePopover()
        })
        .environmentObject(viewModel)
        .environmentObject(storage)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.behavior = .transient   // fecha ao clicar fora
        popover.contentViewController = NSHostingController(rootView: root)
    }

    private func setupMonitor() {
        monitor = PasteboardMonitor()
        monitor.onCapture = { [weak self] content in
            // O Timer dispara na main thread; StorageService é @MainActor.
            self?.storage.store(content)
        }
        monitor.start()
    }

    private func setupHotKey() {
        hotKey = HotKeyService()
        hotKey.onHotKey = { [weak self] in
            self?.togglePopover()
        }
        hotKey.register()   // ⌘⇧V por padrão
    }

    // MARK: - Popover

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            closePopover()
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}
