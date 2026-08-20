# Atualizações automáticas — MacClip

O MacClip tem um sistema de atualização **próprio e leve**, usando as **GitHub Releases**
como fonte. Não usa Sparkle nem dependências externas (ver ADR-0007).

## Como funciona (para o usuário)

1. Alguns segundos depois de abrir, o app consulta a última release publicada no GitHub.
2. Se houver uma versão mais nova, aparece um **popup**:
   - Título: *"Atualização disponível — MacClip X.Y.Z"*
   - As **novidades** (o que mudou) — vêm da descrição da release.
   - Botões: **Atualizar agora** · **Ver no GitHub** · **Depois**.
3. Em **Atualizar agora**, o app baixa o `.zip`, troca o app instalado e reabre sozinho na nova versão.
4. Também dá para checar na hora pelo botão 🔄 no topo do painel (**Verificar atualizações**).

> A verificação só roda no **app instalado** (`.app`), não em `swift run`.

## Como você publica uma atualização (para o dev)

1. **Suba a versão** e gere o pacote:
   ```bash
   ./Scripts/release.sh 1.1.0
   ```
   Isso compila o app com a versão `1.1.0`, monta o `.app` e gera `dist/MacClip-1.1.0.zip`.

2. **Commit + push** do código dessa versão.

3. No GitHub (**AthosAlexandre/win-v-mac**) → **Releases** → **Draft a new release**:
   - **Tag:** `v1.1.0` (create new tag, target `main`).
   - **Title:** `MacClip 1.1.0`.
   - **Description:** escreva o que mudou — **esse texto vira as "novidades" no popup**.
   - **Attach binaries:** arraste o `dist/MacClip-1.1.0.zip`.
   - **Publish release**.

Pronto: os apps instalados na versão anterior vão detectar a `1.1.0` e mostrar o popup.

### Regras de versão

- A comparação é **semver** (`1.1.0 > 1.0.9 > 1.0.0`).
- A **tag** (`vX.Y.Z`) e a versão passada ao `release.sh` devem ser **iguais** — o número
  fica gravado no `Info.plist` do app, e é ele que o updater compara.
- A primeira release (igual à versão instalada) não dispara popup; serve de base.

## ⚠️ Gatekeeper (distribuição sem conta Apple)

Como o app é assinado **ad-hoc** (sem Developer ID / notarização — você não tem conta
Apple paga), na **primeira** abertura em outro Mac o macOS mostra o aviso
*"desenvolvedor não identificado"*. Solução do usuário: **botão direito no app → Abrir → Abrir**
(só uma vez).

Nas **atualizações**, o próprio updater remove o atributo de `quarantine` do app baixado,
então o aviso não se repete a cada update.

Para eliminar o aviso de vez (distribuição limpa), seria preciso **Developer ID + notarização**
— o que exige conta Apple Developer (US$ 99/ano) e o Xcode completo. Fica como evolução futura.

## Arquivos envolvidos

- `Sources/MacClip/Core/Services/UpdateService.swift` — checagem, download e troca do app.
- `Sources/MacClip/App/AppDelegate.swift` — checagem no launch, popup e ações.
- `Scripts/release.sh` — empacota uma versão para publicar.
