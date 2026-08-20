import SwiftUI

/// Painel principal do MacClip, exibido no popover da barra de status.
///
/// Composto por: cabeçalho (tabs) + busca + lista de itens. Os dados vêm do
/// `StorageService` (`@Published items`); a apresentação (filtro/ordem) é delegada ao ViewModel.
struct ClipboardPopoverView: View {
    @EnvironmentObject private var viewModel: ClipboardViewModel

    /// Fonte de verdade dos itens (observada de forma reativa).
    @EnvironmentObject private var store: StorageService

    /// Preferência de "Iniciar no login" (SMAppService).
    @EnvironmentObject private var loginItem: LoginItemService

    /// Ação para fechar o popover após colar (injetada pelo AppDelegate).
    var onPasteAndClose: (() -> Void)?

    /// Ação para verificar atualizações (injetada pelo AppDelegate).
    var onCheckUpdates: (() -> Void)?

    /// Controla o diálogo de confirmação da limpeza.
    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 10) {
            header
            SearchBarView(text: $viewModel.searchText)
            content
        }
        .padding(12)
        .frame(width: 340, height: 460)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Label("MacClip", systemImage: "doc.on.clipboard")
                    .font(.headline)
                Spacer()

                if let onCheckUpdates {
                    Button(action: onCheckUpdates) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Verificar atualizações")
                }

                Button {
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Limpar \(viewModel.selectedTab.rawValue.lowercased())")
                .confirmationDialog(
                    "Limpar \(viewModel.selectedTab.rawValue.lowercased())?",
                    isPresented: $showClearConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Limpar", role: .destructive) { viewModel.clearVisible() }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text("Essa ação não pode ser desfeita.")
                }

                Menu {
                    if loginItem.isSupported {
                        Toggle("Iniciar no login", isOn: Binding(
                            get: { loginItem.isEnabled },
                            set: { loginItem.setEnabled($0) }
                        ))
                    } else {
                        Text("Iniciar no login indisponível (rode como app instalado)")
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Preferências")

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Sair do MacClip")
            }

            Picker("", selection: $viewModel.selectedTab) {
                ForEach(ClipboardViewModel.Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var content: some View {
        let visible = viewModel.present(store.items)

        if visible.isEmpty {
            Spacer()
            Text(viewModel.emptyMessage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(visible) { item in
                        ClipboardRowView(
                            item: item,
                            onPaste: {
                                viewModel.paste(item)
                                onPasteAndClose?()
                            },
                            onToggleFavorite: { viewModel.toggleFavorite(item) },
                            onDelete: { viewModel.delete(item) }
                        )
                    }
                }
            }
        }
    }
}
