import SwiftUI

/// Linha de um item do histórico. Agrega preview (texto/imagem), data,
/// botão de favorito e ação de apagar. Clicar na linha "cola" o item.
///
/// Componente burro: recebe dados e closures, não conhece Services.
struct ClipboardRowView: View {
    let item: ClipboardItem
    let onPaste: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Conteúdo dinâmico conforme o tipo do item.
            VStack(alignment: .leading, spacing: 4) {
                switch item.kind {
                case .text:
                    TextPreviewView(text: item.textContent ?? "")
                case .image:
                    ImagePreviewView(imagePath: item.imagePath ?? "")
                case .unknown:
                    Text("Conteúdo desconhecido").foregroundStyle(.secondary)
                }

                Text(item.createdAt.relativeShort)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 4)

            // Ações
            VStack(spacing: 8) {
                FavoriteButton(isFavorite: item.isFavorite, action: onToggleFavorite)

                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Apagar item")
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color(nsColor: .selectedControlColor).opacity(0.35)
                                 : Color(nsColor: .controlBackgroundColor))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onPaste)
        .onHover { isHovering = $0 }
        .help("Clique para copiar de volta")
    }
}
