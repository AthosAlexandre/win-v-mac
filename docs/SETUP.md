# Setup — MacClip

## Pré-requisitos

- macOS 14 (Sonoma) ou superior — desenvolvido/testado em macOS 26.
- **Command Line Tools** do Xcode com Swift 6+:
  ```bash
  xcode-select --install     # se ainda não tiver
  swift --version            # deve mostrar Swift 6.x
  ```
  > Não é necessário o Xcode completo para **desenvolver e rodar**.

## Rodando o app

Na raiz do projeto (`win-v-mac/`):

```bash
swift build      # compila
swift run        # compila e executa
```

Ao rodar, o app aparece como um ícone na **barra de status** (topo direito). Não há ícone no Dock (é um app "accessory").

### Atalho global

O painel abre com **`⌘ + ⇧ + V`** (Command + Shift + V) de qualquer aplicativo.

### Iniciar no login

O MacClip pode subir sozinho ao logar, gerenciado pelo próprio app via `SMAppService`
(macOS 13+). No **1º launch** a opção já vem **ligada** por padrão; depois disso a sua
escolha é respeitada. Para ligar/desligar:

- No painel: clique no ícone de **engrenagem** (⚙️) no cabeçalho → **Iniciar no login**.
- Ou em **Ajustes do Sistema → Geral → Itens de Início**, onde o MacClip aparece listado.

> Não é preciso configurar LaunchAgent manualmente — o app registra/remove o item de
> login por conta própria. O toggle só funciona quando o MacClip roda como `.app`
> instalado; via `swift run` (executável solto, sem bundle) a opção fica indisponível.

## Gerar o .app instalável

Para ter o MacClip como um aplicativo de verdade (abre pelo Launchpad/Finder, sem
precisar do terminal), use o script de build que monta o bundle `.app`:

```bash
./Scripts/build_app.sh            # gera build/MacClip.app
./Scripts/build_app.sh --install  # gera e instala em /Applications
```

O script: compila em release (`swift build -c release`), monta `MacClip.app` com o
`Info.plist` (incluindo `LSUIElement = true`, para não aparecer no Dock) e assina
localmente (ad-hoc). Não precisa do Xcode completo.

Depois de instalar, abra por:
```bash
open -a MacClip
```
ou pelo Launchpad. O ícone aparece na barra de status; o painel abre com `⌘⇧V`.

> **Primeira abertura / Gatekeeper:** como a assinatura é ad-hoc (sem Developer ID),
> ao abrir em outro Mac o macOS pode bloquear. Na sua própria máquina costuma abrir
> direto; se reclamar, clique com o botão direito no app → **Abrir** → **Abrir**.
> Para distribuir a outros Macs sem esse aviso, é preciso assinar com Developer ID e
> notarizar (requer Xcode/conta de desenvolvedor — ver ADR-0001).

## Permissões do macOS

- O atalho global usa **Carbon HotKey**, que **não** exige permissão de Acessibilidade.
- A leitura/escrita do clipboard (`NSPasteboard`) não exige permissão especial.

## Distribuição (futuro)

Para gerar um `.app` assinado e notarizado (instalável em outros Macs), será necessário:

1. Instalar o **Xcode completo** (App Store).
2. Portar/abrir o pacote no Xcode e configurar:
   - `Info.plist` com `LSUIElement = true` (app sem Dock).
   - Ícone do app e da menu bar em `Assets.xcassets`.
   - Assinatura de código (Developer ID) e notarização.

Isso está registrado como consequência no ADR-0001 (ver [DECISOES.md](DECISOES.md)).

## Solução de problemas

| Sintoma | Causa provável | Solução |
|---|---|---|
| `swift: command not found` | CLT não instaladas | `xcode-select --install` |
| App não aparece | Rodando sem terminal ativo | Verifique a barra de status (topo) |
| Atalho não funciona | Conflito com outro app usando `⌘⇧V` | Alterar o atalho no `HotKeyService` |
| "Iniciar no login" indisponível | Rodando via `swift run` (sem bundle) | Use o `.app` instalado (`./Scripts/build_app.sh --install`) |
| Não sobe no login | Item desativado nos Ajustes | Ajustes do Sistema → Geral → Itens de Início → ligar MacClip |
