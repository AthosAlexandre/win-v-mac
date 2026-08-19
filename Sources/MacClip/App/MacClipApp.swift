import SwiftUI

/// Ponto de entrada do MacClip.
///
/// O app não tem janela principal: toda a UI vive num popover na barra de status,
/// gerenciado pelo `AppDelegate`. A cena `Settings` existe apenas para satisfazer
/// o protocolo `App` sem abrir janela. Ver ADR-0004 em docs/DECISOES.md.
@main
struct MacClipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
