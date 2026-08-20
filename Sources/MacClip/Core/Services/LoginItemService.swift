import Foundation
import ServiceManagement

/// Gerencia o "Iniciar no login" do MacClip usando `SMAppService` (macOS 13+).
///
/// Substitui abordagens externas (LaunchAgent manual): o próprio app registra/remove
/// um Login Item que aparece em **Ajustes do Sistema → Geral → Itens de Início**.
///
/// `SMAppService.mainApp` só funciona quando o processo roda como um bundle `.app`
/// (com `Info.plist`/bundle id). Ao rodar via `swift run` o executável é "solto" e a
/// API não se aplica — por isso o serviço se marca como indisponível (`isSupported`).
@MainActor
final class LoginItemService: ObservableObject {

    /// `true` quando roda como `.app` (única forma de `SMAppService` operar).
    let isSupported: Bool

    /// Estado atual do item de login, refletindo `SMAppService.status`.
    @Published private(set) var isEnabled: Bool = false

    /// Marca que a preferência inicial já foi aplicada (evita reativar após o usuário desligar).
    private let defaultsKey = "loginItem.didApplyInitialDefault"

    init() {
        // Bundle "de verdade" tem identifier e caminho terminando em .app.
        self.isSupported = Bundle.main.bundleIdentifier != nil
            && Bundle.main.bundlePath.hasSuffix(".app")
        refresh()
    }

    /// Sincroniza `isEnabled` com o estado real do sistema.
    func refresh() {
        guard isSupported else {
            isEnabled = false
            return
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    /// Liga/desliga o item de login. Silenciosamente no-op quando não suportado.
    func setEnabled(_ enabled: Bool) {
        guard isSupported else { return }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("MacClip: falha ao \(enabled ? "registrar" : "remover") item de login: \(error.localizedDescription)")
        }
        refresh()
    }

    /// No primeiro launch, ativa o "Iniciar no login" por padrão (uma única vez).
    /// Depois disso a escolha do usuário no toggle é respeitada.
    func applyInitialDefaultIfNeeded() {
        guard isSupported else { return }
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: defaultsKey) else { return }
        defaults.set(true, forKey: defaultsKey)
        setEnabled(true)
    }
}
