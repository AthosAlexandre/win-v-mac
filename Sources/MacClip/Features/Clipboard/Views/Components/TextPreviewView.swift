import SwiftUI

/// Preview de um item de texto. Mostra até 3 linhas.
struct TextPreviewView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .lineLimit(3)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }
}
