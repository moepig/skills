# skills

Claude Code と Codex で共用できるユーザースキル集。各スキルはリポジトリ直下のディレクトリとして格納する。

## 収録スキル

| スキル | 用途 |
| --- | --- |
| [code-comment-edit](code-comment-edit/SKILL.md) | ソースコード中のコメントの書式と記述内容の規約 |
| [document-markdown-edit](document-markdown-edit/SKILL.md) | Markdown ドキュメントの書式、ファイル分割方針、文章の規約 |
| [ja-techdoc-format](ja-techdoc-format/SKILL.md) | 日本語の技術文書の文体、語り手、見出し、図表の導入、参照、補足ブロックの規約 |
| [ja-writing](ja-writing/SKILL.md) | 日本語の用語選択の規約。分かりにくい訳語への言い換え、擬人化した語、自作の総称を避ける |

## リポジトリ構成

```
.
├── <skill-name>/
│   └── SKILL.md          スキル本体。YAML frontmatter (name, description) と規約本文からなる
└── _tools/
    ├── install-npx.*     npx skills を使うインストールスクリプト
    └── install.*         ローカルリポジトリからリンクまたはコピーする従来のスクリプト
```

## `npx skills` でインストール

Node.js 22.20.0 以降と Git が必要である。

Linux, macOS, WSL では次のスクリプトを実行する。

```sh
./_tools/install-npx.sh
```

Windows では次のスクリプトを実行する。

```powershell
.\_tools\install-npx.ps1
```

引数を省略すると、リポジトリ内の全スキルを Claude Code と Codex のユーザーディレクトリへインストールする。個別スキルや別のエージェントを指定する方法は、[_tools/README.md](_tools/README.md) を参照。

## ローカルリポジトリからインストール

従来のスクリプトも引き続き利用できる。Linux, macOS, WSL では `./_tools/install.sh`、Windows では `.\_tools\install.ps1` を実行する。

リポジトリ直下の全スキルが、Claude Code のユーザースキルディレクトリ (`~/.claude/skills/`) へリンクされる。リポジトリ側の編集を即座に反映したい場合や、任意のディレクトリへコピーしたい場合に使用する。オプションは [_tools/README.md](_tools/README.md) を参照。

## スキルの追加

1. リポジトリ直下にスキル名のディレクトリを作成する。
2. その中に `SKILL.md` を配置する。frontmatter の `name` にはディレクトリ名と同じ値を、`description` にはスキルの対象と使用する作業を記述する。エージェントはこの `description` によって起動を判断する。
3. `npx skills` 方式では変更を公開した後にインストールスクリプトを再実行する。従来のリンク方式では再インストールは不要である。
