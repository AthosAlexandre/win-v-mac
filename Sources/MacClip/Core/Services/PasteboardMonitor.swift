import AppKit
import Combine

/// Conteúdo detectado na área de transferência, já normalizado.
enum CapturedContent {
    case text(String)
    case image(NSImage)
}

/// Observa a área de transferência do sistema (`NSPasteboard`).
///
/// O macOS não emite um callback quando algo é copiado, então usamos *polling*:
/// um `Timer` checa `NSPasteboard.general.changeCount` periodicamente. Quando o
/// contador muda, houve uma nova cópia — extraímos o conteúdo e avisamos via `onCapture`.
///
/// Este serviço **não conhece** SwiftData nem disco: só emite `CapturedContent`.
/// Ver ARQUITETURA.md (fluxo de dados) e o exemplo-base em docs.
final class PasteboardMonitor {

    /// Callback chamado sempre que um novo conteúdo é copiado.
    var onCapture: ((CapturedContent) -> Void)?

    private let pasteboard: NSPasteboard
    private var lastChangeCount: Int
    private var timer: Timer?
    private let pollInterval: TimeInterval

    init(pasteboard: NSPasteboard = .general, pollInterval: TimeInterval = 0.5) {
        self.pasteboard = pasteboard
        self.pollInterval = pollInterval
        self.lastChangeCount = pasteboard.changeCount
    }

    deinit {
        stop()
    }

    /// Começa a observar a área de transferência.
    func start() {
        guard timer == nil else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        // Mantém o timer ativo mesmo durante interações de UI (ex.: menu aberto).
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Para de observar.
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Interno

    private func checkForChanges() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let content = readCurrentContent() {
            onCapture?(content)
        }
    }

    /// Extrai o conteúdo atual do pasteboard, priorizando imagem sobre texto.
    private func readCurrentContent() -> CapturedContent? {
        // 1. Imagem
        if let image = NSImage(pasteboard: pasteboard) {
            return .image(image)
        }
        // 2. Texto (ignora strings vazias/só espaços)
        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .text(text)
        }
        return nil
    }
}
