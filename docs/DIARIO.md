# Diário de Desenvolvimento — MacClip

Registro do que foi feito, quando e por quê. Ordem cronológica (mais recente no topo).

---

## 2026-08-19 — Dedup + "sobe pro topo" (comportamento tipo Win+V)

**Objetivo:** Item repetido não deve duplicar no histórico; deve ir para o topo
(virar o mais recente). Vale nos dois casos:
1. Copiar de novo algo que já está no histórico.
2. Selecionar um item do histórico para colar.

**Feito:**
- `StorageService.store(...)` passou a fazer **dedup por conteúdo em toda a lista**
  (antes só comparava com o item mais recente):
  - Texto: compara `textContent`.
  - Imagem: compara os **bytes PNG** contra os arquivos já salvos (`indexOfImage`).
  - Se já existe, chama `moveToTop` (atualiza `createdAt = agora`) em vez de inserir.
- Novo método público `moveToTop(_:)`; `saveImageToDisk` agora recebe `Data`
  (os bytes são calculados uma vez, reaproveitados na comparação e na gravação).
- `ClipboardViewModel.paste(_:)` move o item para o topo na hora (feedback imediato,
  sem esperar o polling de 0.5s do monitor).
- Build verde ✅. Registrado como ADR-0006.

---

## 2026-08-19 — Bootstrap do projeto

**Objetivo:** Sair de um repositório vazio (só README) para a estrutura base de um
app de clipboard nativo, documentado e componentizado.

**Feito:**
- Definida a stack e a arquitetura (SwiftUI + AppKit + SwiftData, MVVM). Ver ARQUITETURA.md.
- Criado `Package.swift` (SwiftPM, target executável, macOS 14+).
- Criado `.gitignore` (build SwiftPM, Xcode, macOS).
- Documentação inicial:
  - `README.md` — visão geral e como rodar.
  - `docs/ARQUITETURA.md` — camadas, pastas e fluxo de dados.
  - `docs/DECISOES.md` — ADR-0001 a ADR-0004 (SwiftPM, Carbon hotkey, SwiftData, menu bar).
  - `docs/SETUP.md` — ambiente, execução, permissões, distribuição futura.

**Decisões-chave do dia:** ver ADR-0001..0004 em DECISOES.md.

**Feito (continuação):**
- Camada Core: `ClipboardItem`, `PasteboardMonitor`, `StorageService`, `HotKeyService` + extensões.
- Feature Clipboard: `ClipboardViewModel` + `ClipboardPopoverView` + 5 componentes reutilizáveis.
- App: `MacClipApp` + `AppDelegate` (status item + popover + injeção de dependências).
- **Build verde** (`swift build`) ✅.

**Imprevistos e correções (documentados como ADR):**
- **SwiftData não compila só com Command Line Tools** — o macro plugin `SwiftDataMacros`
  não existe no toolchain das CLT (só no Xcode completo). Migramos a persistência para
  **JSON (`Codable`)** com o `StorageService` como `ObservableObject`. Ver ADR-0003 (revisado).
- **MenuBarExtra não abre por atalho global** — trocado por `NSStatusItem` + `NSPopover`
  gerenciados no `AppDelegate`. Ver ADR-0004 (revisado).
- Fixado **modo de linguagem Swift 5** no `Package.swift` para evitar erros de strict
  concurrency (Timer + tipos `@MainActor`). Ver ADR-0005.

**Estado atual:** app compila e está pronto para rodar (`swift run`). Atalho padrão `⌘⇧V`.

**Próximos passos (ideias):**
- [ ] Testar `swift run` numa sessão interativa (barra de status + atalho).
- [ ] Ícone próprio para a barra de status.
- [ ] Colar automático (simular ⌘V) — requer permissão de Acessibilidade.
- [ ] Testes unitários do `StorageService` (limite, favoritos, dedup).
- [ ] Migrar para SwiftData + Swift 6 quando houver Xcode.
