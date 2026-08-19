import Foundation

/// Um item do histórico da área de transferência.
///
/// Modelo simples `Codable` (persistido em JSON — ver ADR-0003 em docs/DECISOES.md).
/// Guarda **texto** OU o **caminho de uma imagem** em disco (nunca o binário da imagem).
struct ClipboardItem: Identifiable, Codable, Equatable {
    /// Identificador único do item.
    let id: UUID

    /// Conteúdo de texto, quando o item copiado é texto. `nil` para imagens.
    var textContent: String?

    /// Caminho absoluto do arquivo de imagem em disco, quando é imagem. `nil` para texto.
    var imagePath: String?

    /// Se `true`, o item é preservado permanentemente (não conta no limite de recentes).
    var isFavorite: Bool

    /// Momento em que o item foi capturado.
    var createdAt: Date

    init(
        id: UUID = UUID(),
        textContent: String? = nil,
        imagePath: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.textContent = textContent
        self.imagePath = imagePath
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
}

// MARK: - Conveniências

extension ClipboardItem {
    /// Tipo de conteúdo do item, útil para a UI decidir qual preview renderizar.
    enum Kind {
        case text
        case image
        case unknown
    }

    var kind: Kind {
        if textContent != nil { return .text }
        if imagePath != nil { return .image }
        return .unknown
    }

    /// Uma representação textual curta para busca e acessibilidade.
    var searchableText: String {
        textContent ?? (imagePath.map { "[imagem] \($0)" } ?? "")
    }
}
