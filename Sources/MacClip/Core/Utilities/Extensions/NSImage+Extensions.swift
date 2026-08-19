import AppKit

extension NSImage {
    /// Converte a imagem para dados PNG, prontos para gravar em disco.
    ///
    /// Retorna `nil` se a imagem não tiver uma representação bitmap válida.
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
