# skills

Claude Code のユーザースキル集。各スキルはリポジトリ直下のディレクトリとして格納され、`~/.claude/skills/` へインストールして使用する。

## 収録スキル

| スキル | 用途 |
| --- | --- |
| [code-comment-edit](code-comment-edit/SKILL.md) | ソースコード中のコメントの書式と記述内容の規約 |
| [document-markdown-edit](document-markdown-edit/SKILL.md) | Markdown ドキュメントの書式、ファイル分割方針、文章の規約 |
| [ja-techdoc-format](ja-techdoc-format/SKILL.md) | 日本語の技術文書の文体、語り手、見出し、図表の導入、参照、補足ブロックの規約 |
| [ja-writing](ja-writing/SKILL.md) | 日本語の用語選択の規約。分かりにくい訳語への言い換えを避ける |

## リポジトリ構成

```
.
├── <skill-name>/
│   └── SKILL.md    スキル本体。YAML frontmatter (name, description) と規約本文からなる
└── _tools/         インストールスクリプト (install.sh, install.ps1)。先頭が `_` のディレクトリはスキルとして扱われない
```

## インストール

Linux, macOS, WSL では次のスクリプトを実行する。

```sh
./_tools/install.sh
```

Windows では次のスクリプトを実行する。

```powershell
.\_tools\install.ps1
```

リポジトリ直下の全スキルが、ユーザースキルディレクトリ (`~/.claude/skills/`) へリンクされる。オプション、個別スキルの指定方法、Windows での実行ポリシーの扱いは、[_tools/README.md](_tools/README.md) を参照。

## スキルの追加

1. リポジトリ直下にスキル名のディレクトリを作成する。
2. その中に `SKILL.md` を配置する。frontmatter の `name` にはディレクトリ名と同じ値を、`description` にはスキルの対象と使用する作業を記述する。Claude はこの `description` によって起動を判断する。
3. インストールスクリプトを実行する。

リンクでインストールされているため、既存スキルの `SKILL.md` を編集した場合は再インストール不要。
