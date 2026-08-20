# MacClip

Gerenciador de área de transferência (clipboard) **nativo para macOS**, inspirado no **Win + V** do Windows.

Copie qualquer coisa (texto ou imagem) e acesse rapidamente o histórico das últimas cópias por um atalho global. Marque itens como favoritos para mantê-los salvos permanentemente.

## Funcionalidades

- 📋 **Histórico de cópias** — mantém as últimas 15 cópias recentes (texto e imagem).
- ⭐ **Favoritos** — fixe itens importantes fora do limite do histórico.
- 🖼️ **Suporte a imagens** — imagens são salvas em disco (Application Support), não no banco.
- 🔍 **Busca** — filtre o histórico por conteúdo.
- 🗑️ **Limpar** — botão para zerar a aba aberta (Recentes ou Favoritos), com confirmação.
- ⌨️ **Atalho global** — abre o painel de qualquer app (padrão: `⌘ + ⇧ + V`).
- 🍎 **Menu bar** — roda discreto na barra de status, sem ícone no Dock.

## Stack

- **SwiftUI** para a interface (popover na barra de status via `NSStatusItem`/`NSPopover`).
- **AppKit / NSPasteboard** para escutar o clipboard.
- **Persistência em JSON** (`Codable`) para histórico e favoritos; imagens em disco.
  (SwiftData era a intenção, mas seus macros não existem sem o Xcode completo — ver ADR-0003.)
- **Carbon (RegisterEventHotKey)** para o atalho global nativo, sem dependências externas.
- **Arquitetura MVVM** com separação por camadas (App / Core / Features).

## Como rodar

Requer apenas as **Command Line Tools** do Xcode (Swift 6+). Não precisa do Xcode completo para desenvolver.

```bash
swift build      # compila
swift run        # roda o app
```

Detalhes em [docs/SETUP.md](docs/SETUP.md).

## Documentação

Este projeto documenta **tudo**. Veja a pasta [`docs/`](docs/):

- [ARQUITETURA.md](docs/ARQUITETURA.md) — estrutura de pastas, camadas e fluxo de dados.
- [DECISOES.md](docs/DECISOES.md) — registro de decisões técnicas (ADR).
- [SETUP.md](docs/SETUP.md) — como configurar o ambiente e rodar.
- [DIARIO.md](docs/DIARIO.md) — diário de desenvolvimento (o que foi feito, quando e por quê).
