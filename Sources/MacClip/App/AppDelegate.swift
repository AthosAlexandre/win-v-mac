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
    private let updateService = UpdateService()

    // MARK: - Ciclo de vida

    func applicationDidFinishLaunching(_ notification: Notification) {
        // App discreto: sem ícone no Dock (ver ADR-0004).
        NSApp.setActivationPolicy(.accessory)

        setupPersistence()
        setupStatusItem()
        setupPopover()
        setupMonitor()
        setupHotKey()

        // Checa atualizações alguns segundos após abrir (silencioso se não houver).
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.checkForUpdates(manual: false)
        }
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
        let root = ClipboardPopoverView(
            onPasteAndClose: { [weak self] in self?.closePopover() },
            onCheckUpdates: { [weak self] in
                self?.closePopover()
                self?.checkForUpdates(manual: true)
            }
        )
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

    // MARK: - Atualizações

    /// Verifica se há uma versão mais nova no GitHub Releases.
    /// - Parameter manual: se `true`, avisa também quando já está atualizado.
    private func checkForUpdates(manual: Bool) {
        // Em `swift run` (não é um .app) não faz sentido atualizar.
        guard updateService.isRunningAsBundle else {
            if manual { showInfoAlert(title: "Atualizações", message: "A verificação só funciona no app instalado.") }
            return
        }

        updateService.checkLatest { [weak self] info in
            guard let self else { return }
            guard let info else {
                if manual { self.showInfoAlert(title: "Atualizações", message: "Não foi possível verificar agora. Tente mais tarde.") }
                return
            }
            if self.updateService.isNewer(info.version, than: self.updateService.currentVersion) {
                self.presentUpdateAlert(info)
            } else if manual {
                self.showInfoAlert(
                    title: "Tudo em dia",
                    message: "Você já está na versão mais recente (\(self.updateService.currentVersion))."
                )
            }
        }
    }

    /// Popup de "atualização disponível" com as novidades e as ações.
    private func presentUpdateAlert(_ info: ReleaseInfo) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Atualização disponível — MacClip \(info.version)"
        let notes = info.notes.isEmpty ? "Melhorias e correções." : info.notes
        alert.informativeText = "Você tem a versão \(updateService.currentVersion).\n\nO que mudou:\n\(notes)"
        alert.addButton(withTitle: "Atualizar agora")
        alert.addButton(withTitle: "Ver no GitHub")
        alert.addButton(withTitle: "Depois")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            performUpdate(info)
        case .alertSecondButtonReturn:
            NSWorkspace.shared.open(info.htmlURL)
        default:
            break
        }
    }

    /// Baixa e instala; ao concluir, encerra o app para o helper trocar o bundle e reabrir.
    private func performUpdate(_ info: ReleaseInfo) {
        updateService.downloadAndInstall(info) { [weak self] success in
            if success {
                NSApp.terminate(nil)   // o helper reabre a nova versão
            } else {
                self?.showInfoAlert(
                    title: "Falha na atualização",
                    message: "Não foi possível baixar/instalar. Abrindo a página da release para download manual."
                )
                NSWorkspace.shared.open(info.htmlURL)
            }
        }
    }

    private func showInfoAlert(title: String, message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
