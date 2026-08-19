import Foundation
import SwiftUI

/// Estado e regras de negócio da tela de clipboard.
///
/// Não busca dados diretamente (a fonte de verdade é o `StorageService.items`);
/// em vez disso, **filtra/ordena** a lista recebida e expõe as **ações**
/// (favoritar, colar, apagar), delegando a persistência ao `StorageService`.
final class ClipboardViewModel: ObservableObject {

    /// Aba atualmente selecionada no painel.
    enum Tab: String, CaseIterable, Identifiable {
        case recent = "Recentes"
        case favorites = "Favoritos"
        var id: String { rawValue }
    }

    @Published var searchText: String = ""
    @Published var selectedTab: Tab = .recent

    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
    }

    // MARK: - Apresentação

    /// Aplica aba + busca sobre a lista bruta vinda do SwiftData, já ordenada por data (desc).
    func present(_ items: [ClipboardItem]) -> [ClipboardItem] {
        let byTab = items.filter { item in
            selectedTab == .favorites ? item.isFavorite : !item.isFavorite
        }
        let sorted = byTab.sorted { $0.createdAt > $1.createdAt }

        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return sorted
        }
        return sorted.filter {
            $0.searchableText.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Mensagem exibida quando a lista filtrada está vazia.
    var emptyMessage: String {
        if !searchText.isEmpty { return "Nenhum resultado para \"\(searchText)\"." }
        return selectedTab == .favorites
            ? "Nenhum favorito ainda. Toque na ⭐ de um item."
            : "Seu histórico aparece aqui. Copie algo (⌘C)."
    }

    // MARK: - Ações

    func toggleFavorite(_ item: ClipboardItem) {
        storage.toggleFavorite(item)
    }

    /// Coloca o item de volta na área de transferência (pronto para ⌘V).
    func paste(_ item: ClipboardItem) {
        storage.copyToPasteboard(item)
    }

    func delete(_ item: ClipboardItem) {
        storage.delete(item)
    }
}
