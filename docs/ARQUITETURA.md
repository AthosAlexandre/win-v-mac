# Arquitetura — MacClip

## Visão geral

MacClip segue **MVVM (Model-View-ViewModel)** com separação clara de responsabilidades em três grandes camadas: `App`, `Core` e `Features`. O objetivo é manter as Views burras (só apresentação), a lógica de estado no ViewModel e as regras de sistema (clipboard, disco, atalho) isoladas em Services testáveis.

## Estrutura de pastas

```
win-v-mac/
├── Package.swift                 # Manifesto do Swift Package (SwiftPM)
├── README.md
├── docs/                         # Toda a documentação do projeto
│
└── Sources/MacClip/
    ├── App/
    │   ├── MacClipApp.swift          # Ponto de entrada (@main) + cena MenuBarExtra
    │   └── AppDelegate.swift         # Ciclo de vida macOS (activation policy, hotkey)
    │
    ├── Core/
    │   ├── Models/
    │   │   └── ClipboardItem.swift   # struct Codable (texto OU caminho de imagem)
    │   ├── Services/
    │   │   ├── PasteboardMonitor.swift # Observa NSPasteboard via polling (changeCount)
    │   │   ├── StorageService.swift    # Repositório: JSON em disco + imagens; @Published
    │   │   └── HotKeyService.swift     # Atalho global (Carbon RegisterEventHotKey)
    │   └── Utilities/Extensions/
    │       ├── NSImage+Extensions.swift # Conversão PNG, thumbnails
    │       └── Date+Extensions.swift    # Formatação de datas ("agora", "há 5 min")
    │
    └── Features/Clipboard/
        ├── ViewModels/
        │   └── ClipboardViewModel.swift # Estado, busca, filtros, ação de colar/favoritar
        └── Views/
            ├── ClipboardPopoverView.swift # Container do painel (tabs, busca, lista)
            └── Components/                 # Componentes reutilizáveis (UI burra)
                ├── ClipboardRowView.swift  # Linha genérica de um item
                ├── TextPreviewView.swift   # Preview de texto
                ├── ImagePreviewView.swift  # Preview de imagem
                ├── FavoriteButton.swift    # Botão toggle de favorito
                └── SearchBarView.swift     # Campo de busca
```

## Camadas e responsabilidades

### App
Ponto de entrada e integração com o sistema operacional. O `AppDelegate` gerencia um `NSStatusItem` + `NSPopover` (que hospeda a View SwiftUI), esconde o app do Dock (activation policy `.accessory`) e liga o atalho global à ação de abrir/fechar o painel. Não usamos `MenuBarExtra` porque ele não pode ser aberto por atalho global — ver ADR-0004.

### Core
Coração independente de UI.

- **Models**: `ClipboardItem` é uma `struct Codable`. Guarda `textContent` **ou** `imagePath` (nunca o binário da imagem — só o caminho no disco), além de `isFavorite` e `createdAt`.
- **Services**:
  - `PasteboardMonitor` — como o macOS não emite callback ao copiar, usamos um `Timer` que checa `NSPasteboard.general.changeCount` a cada ~0.5s. Quando muda, extrai o conteúdo e avisa via callback.
  - `StorageService` — repositório e única porta de entrada/saída de dados (`ObservableObject` com `@Published items`). Persiste os itens em JSON, salva imagens em `Application Support/MacClip/Images/`, aplica o limite de 15 recentes e preserva favoritos.
  - `HotKeyService` — registra o atalho global via Carbon (`RegisterEventHotKey`), que **não exige permissão de Acessibilidade**.
- **Utilities**: extensões puras e sem estado.

### Features/Clipboard
- **ClipboardViewModel** (`ObservableObject`): mantém `searchText`, aba selecionada (recentes/favoritos), a lógica de filtro/ordenação (`present(_:)`) e expõe ações (`toggleFavorite`, `paste`, `delete`), delegando a persistência ao `StorageService`.
- **Views**: SwiftUI puro. `ClipboardPopoverView` é o container; os `Components/` são pequenos, reutilizáveis e sem lógica de negócio.

## Fluxo de dados (copiar → exibir → colar)

```
Usuário copia (⌘C)
        │
        ▼
PasteboardMonitor detecta changeCount mudou
        │  (callback com o conteúdo)
        ▼
StorageService.store(...)  ──►  imagem? salva PNG em disco, guarda o path
        │                        texto?  guarda a string
        │  aplica limite de 15 recentes (favoritos preservados) + salva JSON
        ▼
@Published items muda → SwiftUI atualiza a lista automaticamente
        │
        ▼
ClipboardViewModel.present() filtra por busca / aba
        │
        ▼
ClipboardPopoverView renderiza ClipboardRowView(s)
        │
        │  Usuário clica num item (ou ⌘⇧V + Enter)
        ▼
ClipboardViewModel.paste(item)  ──►  escreve no NSPasteboard de volta
```

## Princípios adotados

- **Views burras**: componentes recebem dados e closures, não conhecem Services.
- **Injeção de dependências**: Services são criados no App e injetados no ViewModel — facilita testes futuros.
- **Imagens fora do banco**: evita inchar o SwiftData e travar a UI; só o caminho é persistido.
- **Zero dependências externas**: hotkey nativo (Carbon), sem baixar libs — build offline e reproduzível.

## Referências cruzadas
- Decisões que justificam essas escolhas: [DECISOES.md](DECISOES.md).
