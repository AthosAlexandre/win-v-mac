import AppKit
import Carbon.HIToolbox

/// Registra um atalho de teclado **global** (funciona mesmo com o app em background).
///
/// Usa a API Carbon `RegisterEventHotKey`, que — diferente de
/// `NSEvent.addGlobalMonitorForEvents` — **não exige permissão de Acessibilidade**.
/// Ver ADR-0002 em docs/DECISOES.md.
///
/// Padrão: `⌘ + ⇧ + V` (Command + Shift + V).
final class HotKeyService {

    /// Chamado (na main thread) toda vez que o atalho é pressionado.
    var onHotKey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    /// Assinatura de 4 bytes que identifica os hotkeys deste app ('MCLP').
    private static let signature: OSType = 0x4D434C50

    /// Registra o atalho.
    /// - Parameters:
    ///   - keyCode: código virtual da tecla (padrão: `V`).
    ///   - modifiers: modificadores Carbon (padrão: Command + Shift).
    func register(
        keyCode: UInt32 = UInt32(kVK_ANSI_V),
        modifiers: UInt32 = UInt32(cmdKey | shiftKey)
    ) {
        // Evita registro duplo.
        unregister()

        // 1. Instala o handler que recebe o evento de "hotkey pressionada".
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                // Callback C: sem captura de contexto — recuperamos `self` via userData.
                guard let userData else { return noErr }
                let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
                service.onHotKey?()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        // 2. Registra o atalho em si.
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    /// Remove o atalho e o handler.
    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        unregister()
    }
}
