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
