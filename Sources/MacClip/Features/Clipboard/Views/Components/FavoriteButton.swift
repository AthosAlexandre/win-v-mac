import SwiftUI

/// Botão de alternar favorito (estrela). Componente reutilizável e sem lógica de negócio.
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundStyle(isFavorite ? .yellow : .secondary)
        }
        .buttonStyle(.plain)
        .help(isFavorite ? "Remover dos favoritos" : "Adicionar aos favoritos")
    }
}
