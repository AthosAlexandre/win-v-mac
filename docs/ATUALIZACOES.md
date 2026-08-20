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

## ⚠️ Primeira abertura no macOS (Gatekeeper)

Como o app é assinado **ad-hoc** (sem Developer ID / notarização — não há conta Apple
paga), na **primeira** abertura o macOS **bloqueia** com o aviso
*"A Apple não pode verificar se o item está livre de malware…"*.

**Isso é normal e esperado.** É só liberar uma vez, assim (macOS Sequoia/Tahoe):

1. Dê dois cliques no **MacClip.app**. Vai aparecer o aviso *"Abrir o Item MacClip?"*.
   - Se o aviso já tiver o botão **"Abrir Mesmo Assim"**, clique nele e pule para o passo 4.
   - Se só tiver **"Mover para o Lixo / OK"**, clique em **OK** e siga para o passo 2.
2. Abra o menu Apple  → **Ajustes do Sistema** → **Privacidade e Segurança**.
3. Role até a seção **Segurança**. Vai aparecer *"MacClip foi bloqueado…"* com o botão
   **"Abrir Mesmo Assim"** → clique nele.
4. Confirme com **Touch ID** ou a **senha** do Mac.

Pronto — a partir daí o MacClip abre normalmente, sempre. Esse aviso **só acontece na
primeira vez**.

> **Nota:** no macOS mais novo, o antigo "botão direito → Abrir" nem sempre funciona;
> o caminho confiável é o **Ajustes do Sistema → Privacidade e Segurança → Abrir Mesmo Assim** acima.

Nas **atualizações** o próprio updater remove o `quarantine` do app baixado, então esse
aviso **não se repete** a cada update.

Para eliminar o aviso de vez (distribuição limpa, sem nenhum passo extra pro usuário),
seria preciso **Developer ID + notarização** — o que exige conta Apple Developer (US$ 99/ano)
e o Xcode completo. Fica como evolução futura (ADR-0007).

## Arquivos envolvidos

- `Sources/MacClip/Core/Services/UpdateService.swift` — checagem, download e troca do app.
- `Sources/MacClip/App/AppDelegate.swift` — checagem no launch, popup e ações.
- `Scripts/release.sh` — empacota uma versão para publicar.
