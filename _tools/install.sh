#!/usr/bin/env bash
# このリポジトリのスキルをユーザーの ~/.claude/skills/ へインストールする。
#
# 既定では symlink を張るため、リポジトリ側の編集が即座に反映される。
# --copy を指定した場合は実体をコピーする。

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGET_DIR="${CLAUDE_SKILLS_DIR:-${HOME}/.claude/skills}"
MODE="link"
FORCE=0
DRY_RUN=0
UNINSTALL=0
SELECTED=()

usage() {
  cat <<'EOF'
Usage: _tools/install.sh [OPTIONS] [SKILL...]

このリポジトリのスキルを ~/.claude/skills/ へインストールする。
SKILL を省略した場合はリポジトリ内の全スキルが対象になる。

Options:
  --copy              symlink ではなく実体をコピーする
  --force, -f         インストール先に既存のファイルがあっても上書きする
  --dry-run, -n       実際には変更せず、実行内容のみ表示する
  --uninstall         インストール済みのスキルを削除する
                      (このリポジトリを指す symlink、または --force 指定時のみ)
  --target DIR        インストール先ディレクトリ (既定: ~/.claude/skills)
  --list, -l          インストール可能なスキルを一覧表示する
  --help, -h          このヘルプを表示する

Environment:
  CLAUDE_SKILLS_DIR   インストール先ディレクトリの既定値を上書きする
EOF
}

log()  { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# リポジトリ直下の、SKILL.md を持つディレクトリ名を列挙する。
# 先頭が `_` または `.` のディレクトリは補助的なものとして除外する。
discover_skills() {
  local path name
  for path in "${REPO_DIR}"/*/; do
    name="$(basename -- "${path}")"
    case "${name}" in
      _*|.*) continue ;;
    esac
    [[ -f "${path}SKILL.md" ]] || continue
    printf '%s\n' "${name}"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)        MODE="copy"; shift ;;
    --force|-f)    FORCE=1; shift ;;
    --dry-run|-n)  DRY_RUN=1; shift ;;
    --uninstall)   UNINSTALL=1; shift ;;
    --target)      [[ $# -ge 2 ]] || die "--target には値が必要"; TARGET_DIR="$2"; shift 2 ;;
    --target=*)    TARGET_DIR="${1#*=}"; shift ;;
    --list|-l)     discover_skills; exit 0 ;;
    --help|-h)     usage; exit 0 ;;
    --)            shift; SELECTED+=("$@"); break ;;
    -*)            die "不明なオプション: $1" ;;
    *)             SELECTED+=("$1"); shift ;;
  esac
done

mapfile -t AVAILABLE < <(discover_skills)
[[ ${#AVAILABLE[@]} -gt 0 ]] || die "${REPO_DIR} にスキルが見つからない"

if [[ ${#SELECTED[@]} -eq 0 ]]; then
  SKILLS=("${AVAILABLE[@]}")
else
  SKILLS=()
  for name in "${SELECTED[@]}"; do
    name="${name%/}"
    found=0
    for available in "${AVAILABLE[@]}"; do
      [[ "${available}" == "${name}" ]] && found=1 && break
    done
    [[ ${found} -eq 1 ]] || die "スキルが存在しない: ${name} (--list で一覧表示)"
    SKILLS+=("${name}")
  done
fi

run() {
  if [[ ${DRY_RUN} -eq 1 ]]; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# リンク先がこのリポジトリ内を指しているかを判定する。
points_into_repo() {
  local dest="$1" resolved
  [[ -L "${dest}" ]] || return 1
  resolved="$(readlink -f -- "${dest}" 2>/dev/null)" || return 1
  [[ "${resolved}" == "${REPO_DIR}/"* ]]
}

installed=0
skipped=0
failed=0

if [[ ${DRY_RUN} -eq 0 ]]; then
  mkdir -p -- "${TARGET_DIR}"
fi

for skill in "${SKILLS[@]}"; do
  src="${REPO_DIR}/${skill}"
  dest="${TARGET_DIR}/${skill}"

  if [[ ${UNINSTALL} -eq 1 ]]; then
    if [[ ! -e "${dest}" && ! -L "${dest}" ]]; then
      log "skip     ${skill} (未インストール)"
      skipped=$((skipped + 1))
      continue
    fi
    if ! points_into_repo "${dest}" && [[ ${FORCE} -eq 0 ]]; then
      warn "${skill}: このリポジトリの symlink ではないため削除しない (--force で強制削除)"
      failed=$((failed + 1))
      continue
    fi
    log "remove   ${skill}"
    run rm -rf -- "${dest}"
    installed=$((installed + 1))
    continue
  fi

  if [[ -e "${dest}" || -L "${dest}" ]]; then
    if [[ "${MODE}" == "link" ]] && [[ -L "${dest}" ]] \
       && [[ "$(readlink -f -- "${dest}" 2>/dev/null)" == "${src}" ]]; then
      log "ok       ${skill} (インストール済み)"
      skipped=$((skipped + 1))
      continue
    fi
    if [[ ${FORCE} -eq 0 ]]; then
      warn "${skill}: ${dest} が既に存在する (--force で上書き)"
      failed=$((failed + 1))
      continue
    fi
    log "replace  ${skill}"
    run rm -rf -- "${dest}"
  else
    log "install  ${skill}"
  fi

  if [[ "${MODE}" == "link" ]]; then
    run ln -s -- "${src}" "${dest}"
  else
    run cp -R -- "${src}" "${dest}"
  fi
  installed=$((installed + 1))
done

log ""
log "${TARGET_DIR}: ${installed} 件処理, ${skipped} 件スキップ, ${failed} 件失敗"
[[ ${failed} -eq 0 ]]
