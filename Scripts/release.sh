#!/bin/bash
#
# release.sh - Gera o pacote de uma nova versao para publicar no GitHub Releases.
#
# Uso:
#   ./Scripts/release.sh 1.1.0
#
# O que faz:
#   1. Compila e monta o MacClip.app com a versao informada.
#   2. Compacta em dist/MacClip-<versao>.zip (formato que o updater baixa).
#   3. Imprime o passo a passo para publicar a release no GitHub.
#
# Depois de publicar, os apps instalados detectam a nova versao e mostram
# o popup de atualizacao. Ver docs/ATUALIZACOES.md.

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    echo "Uso: ./Scripts/release.sh <versao>   (ex: ./Scripts/release.sh 1.1.0)"
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

export VERSION
echo "==> Gerando o app na versao $VERSION..."
./Scripts/build_app.sh

DIST_DIR="dist"
ZIP="$DIST_DIR/MacClip-$VERSION.zip"
mkdir -p "$DIST_DIR"
rm -f "$ZIP"

echo "==> Compactando -> $ZIP"
/usr/bin/ditto -c -k --keepParent "build/MacClip.app" "$ZIP"

echo ""
echo "==> Pronto: $ZIP"
echo ""
echo "Proximos passos para publicar a atualizacao:"
echo "  1. Faca commit e push do codigo desta versao."
echo "  2. No GitHub (AthosAlexandre/win-v-mac): Releases -> Draft a new release."
echo "  3. Choose a tag: v$VERSION  (Create new tag, target: main)."
echo "  4. Release title: MacClip $VERSION."
echo "  5. Description: escreva o que mudou -> isso vira as 'novidades' no popup."
echo "  6. Attach binaries: arraste o arquivo $ZIP."
echo "  7. Publish release."
echo ""
echo "Feito isso, os apps instalados na v-anterior mostrarao o popup de atualizacao."
