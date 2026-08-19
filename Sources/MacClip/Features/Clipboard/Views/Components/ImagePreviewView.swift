import SwiftUI

/// Preview de um item de imagem, carregada do disco pelo caminho salvo.
struct ImagePreviewView: View {
    let imagePath: String

    var body: some View {
        if let nsImage = NSImage(contentsOfFile: imagePath) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 100, alignment: .leading)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Label("Imagem indisponível", systemImage: "photo")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
