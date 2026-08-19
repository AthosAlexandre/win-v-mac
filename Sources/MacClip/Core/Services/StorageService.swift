import AppKit

/// Repositório e porta única de entrada/saída de dados do MacClip.
///
/// Responsabilidades:
/// - Manter a lista de itens em memória (`@Published`, observável pela UI).
/// - Persistir os metadados em JSON (`Application Support/MacClip/history.json`).
/// - Gravar imagens em disco (`.../Images/`) e guardar só o caminho.
/// - Aplicar o limite de itens recentes (favoritos são preservados).
/// - Remover itens (e apagar o arquivo de imagem associado).
/// - Reescrever um item na área de transferência (ação "colar").
///
/// Ver ADR-0003 (JSON + imagens em disco) em docs/DECISOES.md.
final class StorageService: ObservableObject {

    /// Lista completa de itens (recentes + favoritos), fonte de verdade para a UI.
    @Published private(set) var items: [ClipboardItem] = []

    /// Número máximo de itens **não-favoritos** mantidos no histórico.
    let historyLimit: Int

    private let baseDirectory: URL
    private let imagesDirectory: URL
    private let storeURL: URL

    init(historyLimit: Int = 15) {
        self.historyLimit = historyLimit

        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MacClip", isDirectory: true)
        self.baseDirectory = base
        self.imagesDirectory = base.appendingPathComponent("Images", isDirectory: true)
        self.storeURL = base.appendingPathComponent("history.json")

        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        load()
    }

    // MARK: - Captura

    /// Persiste um conteúdo recém-capturado da área de transferência.
    func store(_ content: CapturedContent) {
        switch content {
        case .text(let text):
            // Evita duplicar a última cópia de texto idêntica.
            if let newest = items.max(by: { $0.createdAt < $1.createdAt }),
               newest.textContent == text {
                return
            }
            add(ClipboardItem(textContent: text))

        case .image(let image):
            guard let path = saveImageToDisk(image) else { return }
            add(ClipboardItem(imagePath: path))
        }
    }

    private func add(_ item: ClipboardItem) {
        items.append(item)
        enforceHistoryLimit()
        save()
    }

    // MARK: - Favoritos / remoção

    func toggleFavorite(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isFavorite.toggle()
        save()
    }

    func delete(_ item: ClipboardItem) {
        if let path = item.imagePath {
            try? FileManager.default.removeItem(atPath: path)
        }
        items.removeAll { $0.id == item.id }
        save()
    }

    // MARK: - Colar (escrever de volta no pasteboard)

    /// Coloca o item de volta na área de transferência, pronto para `⌘V`.
    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let text = item.textContent {
            pasteboard.setString(text, forType: .string)
        } else if let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
            pasteboard.writeObjects([image])
        }
    }

    // MARK: - Limite de histórico

    /// Mantém apenas os `historyLimit` itens recentes **não-favoritos**; remove o excedente.
    private func enforceHistoryLimit() {
        let nonFavorites = items
            .filter { !$0.isFavorite }
            .sorted { $0.createdAt > $1.createdAt }

        guard nonFavorites.count > historyLimit else { return }

        let overflow = nonFavorites[historyLimit...]
        for item in overflow {
            if let path = item.imagePath {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        let overflowIDs = Set(overflow.map { $0.id })
        items.removeAll { overflowIDs.contains($0.id) }
    }

    // MARK: - Persistência (JSON)

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([ClipboardItem].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    // MARK: - Disco (imagens)

    /// Grava a imagem como PNG e retorna o caminho absoluto salvo.
    private func saveImageToDisk(_ image: NSImage) -> String? {
        guard let data = image.pngData() else { return nil }
        let fileURL = imagesDirectory.appendingPathComponent("\(UUID().uuidString).png")
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            NSLog("MacClip: falha ao salvar imagem em disco — \(error.localizedDescription)")
            return nil
        }
    }
}
