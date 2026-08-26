#!/usr/bin/env bash

set -euo pipefail

readonly SOURCE="moepig/skills"
readonly MINIMUM_NODE_VERSION="22.20.0"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v node >/dev/null 2>&1 || die "Node.js ${MINIMUM_NODE_VERSION} or later is required"
command -v npx >/dev/null 2>&1 || die "npx is required (install npm with Node.js)"
command -v git >/dev/null 2>&1 || die "Git is required"

node -e '
  const current = process.versions.node.split(".").map(Number);
  const minimum = [22, 20, 0];
  const difference = current.findIndex((part, index) => part !== minimum[index]);
  const supported = difference === -1 || current[difference] > minimum[difference];
  process.exit(supported ? 0 : 1);
' || die "Node.js ${MINIMUM_NODE_VERSION} or later is required (found $(node --version))"

if [[ $# -eq 0 ]]; then
  set -- \
    --global \
    --skill '*' \
    --agent claude-code \
    --agent codex \
    --yes
fi

exec npx --yes skills add "${SOURCE}" "$@"
