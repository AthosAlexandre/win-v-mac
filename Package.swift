// swift-tools-version: 6.0
import PackageDescription

// MacClip — Gerenciador de área de transferência nativo para macOS.
// Inspirado no "Win + V" do Windows: histórico de cópias, favoritos e suporte a imagens.
//
// Estruturado como Swift Package (SwiftPM) para compilar/rodar apenas com as
// Command Line Tools (sem depender do Xcode completo). Ver docs/DECISOES.md (ADR-0001).
let package = Package(
    name: "MacClip",
    platforms: [
        // macOS 14+ é o mínimo para SwiftData e MenuBarExtra estáveis.
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MacClip",
            path: "Sources/MacClip",
            swiftSettings: [
                // Modo de linguagem Swift 5: concorrência não-estrita.
                // Evita fricção do strict concurrency do Swift 6 nesta 1ª versão.
                // Migração para Swift 6 fica registrada como trabalho futuro (ADR-0005).
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
