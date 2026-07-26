# skills

Claude Code のユーザースキル集。各スキルはリポジトリ直下のディレクトリとして格納され、`~/.claude/skills/` へインストールして使用する。

## 収録スキル

| スキル | 用途 |
| --- | --- |
| [code-comment-edit](code-comment-edit/SKILL.md) | ソースコード中のコメントの書式と記述内容の規約 |
| [document-markdown-edit](document-markdown-edit/SKILL.md) | Markdown ドキュメントの書式、ファイル分割方針、文章の規約 |

## リポジトリ構成

```
.
├── <skill-name>/
│   └── SKILL.md    スキル本体。YAML frontmatter (name, description) と規約本文からなる
└── _tools/         インストールスクリプト。先頭が `_` のディレクトリはスキルとして扱われない
```

## インストール

```sh
./_tools/install.sh
```

リポジトリ直下の全スキルが `~/.claude/skills/` へ symlink される。オプションおよび個別スキルの指定方法は [_tools/README.md](_tools/README.md) を参照。

## スキルの追加

1. リポジトリ直下にスキル名のディレクトリを作成する。
2. その中に `SKILL.md` を配置する。frontmatter の `name` にはディレクトリ名と同じ値を、`description` にはスキルの対象と使用する作業を記述する。Claude はこの `description` によって起動を判断する。
3. `./_tools/install.sh` を実行する。

symlink でインストールされているため、既存スキルの `SKILL.md` を編集した場合は再インストール不要。
