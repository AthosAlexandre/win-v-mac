# Decisões Técnicas (ADR)

Registro cronológico das decisões de arquitetura. Formato leve inspirado em ADR
(Architecture Decision Records). Cada entrada: contexto, decisão, alternativas e consequências.

---

## ADR-0001 — Swift Package (SwiftPM) em vez de projeto Xcode

**Data:** 2026-08-19
**Status:** Aceito

**Contexto:** A máquina de desenvolvimento tem apenas as *Command Line Tools* (Swift 6.3.3),
sem o Xcode completo (`xcodebuild` aponta para CLT) e sem Homebrew/XcodeGen.

**Decisão:** Estruturar o app como um Swift Package executável (`.executableTarget`),
compilável e executável com `swift build` / `swift run`.

**Alternativas consideradas:**
- Projeto `.xcodeproj` escrito à mão — frágil, difícil de versionar, impossível compilar aqui.
- Instalar XcodeGen via Homebrew — Homebrew não está instalado.

**Consequências:**
- ✅ Compila e roda imediatamente, sem Xcode.
- ✅ Estrutura de pastas limpa e versionável.
- ⚠️ Para **assinar e distribuir** um `.app` (notarização, ícone, entitlements finos),
  recomenda-se depois abrir/portar para o Xcode. Documentado em SETUP.md.

---

## ADR-0002 — Atalho global via Carbon, sem a lib externa `HotKey`

**Data:** 2026-08-19
**Status:** Aceito

**Contexto:** O app precisa abrir o painel por um atalho global mesmo em background.
Opções comuns: lib SPM `HotKey`, `NSEvent.addGlobalMonitorForEvents` ou Carbon.

**Decisão:** Implementar `HotKeyService` próprio usando a API Carbon
`RegisterEventHotKey`.

**Alternativas consideradas:**
- Lib `HotKey` (SPM) — adiciona dependência externa e fetch de rede; desnecessário.
- `NSEvent.addGlobalMonitorForEvents` — exige permissão de **Acessibilidade** do usuário.

**Consequências:**
- ✅ Zero dependências; build offline e reproduzível.
- ✅ Não exige permissão de Acessibilidade (Carbon hotkey funciona sem ela).
- ⚠️ Carbon é uma API antiga (mas ainda suportada e estável no macOS 26).

---

## ADR-0003 — Persistência em JSON (não SwiftData); imagens em disco

**Data:** 2026-08-19
**Status:** Aceito (revisado — SwiftData foi a intenção inicial)

**Contexto:** Precisamos persistir histórico e favoritos, incluindo imagens.
A intenção inicial era SwiftData (`@Model`/`@Query`). Porém, **os macros do SwiftData
(`SwiftDataMacros`) não estão presentes nas Command Line Tools** — só no Xcode completo.
Verificado: `usr/lib/swift/host/plugins/` só traz `libObservationMacros` e `libSwiftMacros`.
Resultado: `@Model`/`@Query` não compilam neste ambiente (erro "plugin SwiftDataMacros not found").

**Decisão:** Persistir os metadados dos itens em **JSON** (`Codable`) em
`~/Library/Application Support/MacClip/history.json`. Imagens são gravadas como PNG em
`.../Images/` e apenas o **caminho** é salvo. O `StorageService` é um `ObservableObject`
com `@Published items`, servindo como fonte de verdade reativa para a UI.

**Alternativas consideradas:**
- SwiftData — inviável sem Xcode completo (macro plugin ausente). Migração futura possível.
- Salvar o binário da imagem (`Data`) direto — inflaria o arquivo e travaria a UI.

**Consequências:**
- ✅ Compila e roda apenas com Command Line Tools.
- ✅ Store simples e legível (JSON); volume pequeno (15 recentes + favoritos).
- ✅ UI reativa via `@Published` (equivalente prático ao `@Query`).
- ⚠️ É preciso limpar arquivos de imagem órfãos ao remover um item (tratado no StorageService).
- 🔜 **Migração para SwiftData** fica trivial (trocar só o StorageService) quando houver Xcode.

---

## ADR-0004 — Barra de status via NSStatusItem + NSPopover (não MenuBarExtra)

**Data:** 2026-08-19
**Status:** Aceito (revisado — MenuBarExtra foi a intenção inicial)

**Contexto:** Apps de clipboard rodam discretos, sem janela principal nem Dock, e
precisam abrir o painel tanto por clique quanto pelo **atalho global** (Win+V).
O `MenuBarExtra` (SwiftUI) é mais simples, porém **não pode ser aberto
programaticamente** — inviabiliza abrir o painel pelo atalho global.

**Decisão:** Gerenciar `NSStatusItem` + `NSPopover` no `AppDelegate`. O popover
hospeda a View SwiftUI (`NSHostingController`) e pode ser alternado tanto pelo clique
no ícone quanto pelo callback do `HotKeyService`. Activation policy `.accessory`
(equivalente ao `LSUIElement = true`, definido via código pois não há Info.plist gerenciado).

**Consequências:**
- ✅ App discreto na barra de status, sem Dock.
- ✅ O atalho global consegue abrir/fechar o painel (requisito central).
- ⚠️ Um pouco mais de código AppKit no AppDelegate do que com `MenuBarExtra`.

---

## ADR-0005 — Modo de linguagem Swift 5 (concorrência não-estrita)

**Data:** 2026-08-19
**Status:** Aceito

**Contexto:** O toolchain é Swift 6.3. Sob o modo Swift 6, o *strict concurrency*
gera erros ao combinar `Timer`/callbacks com tipos `@MainActor` (StorageService,
ViewModel) — fricção alta para uma primeira versão.

**Decisão:** Fixar `swiftLanguageMode(.v5)` no `Package.swift`. Os serviços não usam
`@MainActor` e todas as interações ocorrem naturalmente na main thread (Timer, UI, hotkey).

**Consequências:**
- ✅ Build limpo, sem lutar contra o isolamento de atores agora.
- 🔜 Migrar para o modo Swift 6 (adotar `@MainActor`/`Sendable` corretamente) é trabalho futuro.

---

## ADR-0006 — Dedup por conteúdo com "sobe pro topo" (sem duplicar)

**Data:** 2026-08-19
**Status:** Aceito

**Contexto:** Comportamento esperado de um gerenciador de clipboard (como o Win+V):
copiar/selecionar um conteúdo que já está no histórico não deve criar uma cópia —
o item existente deve ir para o topo (virar o mais recente).

**Decisão:** No `StorageService.store(...)`, procurar por conteúdo idêntico em toda a
lista (texto por `textContent`; imagem comparando os **bytes PNG** com os arquivos já
salvos). Se existir, `moveToTop` atualiza `createdAt` para agora, reordenando; caso
contrário, insere um novo item. O `paste(_:)` também chama `moveToTop` para feedback imediato.

**Alternativas consideradas:**
- Comparar imagem por caminho/UUID — não detecta a mesma imagem recopiada de fora.
- Suprimir a próxima captura do monitor após colar — mais complexo; o dedup por conteúdo
  já torna a recaptura idempotente.

**Consequências:**
- ✅ Histórico limpo, sem repetições; recentes refletem o uso real.
- ⚠️ Dedup de imagem depende dos bytes PNG serem idênticos; uma reconversão de imagem
  ligeiramente diferente pode, em casos raros, não casar (aceitável para v1).

---

## ADR-0007 — Auto-update próprio via GitHub Releases (não Sparkle)

**Data:** 2026-08-20
**Status:** Aceito

**Contexto:** Queremos que usuários instalados recebam um popup quando há nova versão,
com as "novidades" e opção de atualizar. O padrão de mercado é o **Sparkle**.

**Decisão:** Implementar um `UpdateService` próprio que usa as **GitHub Releases** como
fonte: consulta `releases/latest` pela API, compara semver com a versão do `Info.plist`,
mostra um `NSAlert` com as notas da release e, ao confirmar, baixa o `.zip`, remove o
`quarantine`, troca o `.app` instalado (via helper) e reabre.

**Alternativas consideradas:**
- **Sparkle** — robusto e completo, mas exige embutir um framework (mais complexo sem
  Xcode), chaves de assinatura (EdDSA) e fica realmente bom com app **notarizado**. Como
  não há conta Apple Developer paga, o ganho não compensa a complexidade agora.

**Consequências:**
- ✅ Sem dependências externas; funciona com SwiftPM + Command Line Tools.
- ✅ As "novidades" do popup são a própria descrição da release (dev escreve uma vez).
- ⚠️ Sem notarização, a **primeira** abertura em cada Mac exige "botão direito → Abrir";
  o updater remove o `quarantine` para não repetir o aviso nas atualizações.
- 🔜 Migrar para Sparkle + notarização se/quando houver conta Apple Developer.
