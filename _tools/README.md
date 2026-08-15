# _tools

リポジトリのスキルを Claude Code のユーザースキルディレクトリへ導入するツール。

## スクリプト

環境ごとのスクリプトと起動方法を、以下にまとめる。

| 環境 | スクリプト | 起動 |
| --- | --- | --- |
| Linux, macOS, WSL | `install.sh` | `./_tools/install.sh [OPTIONS] [SKILL...]` |
| Windows | `install.ps1` | `.\_tools\install.ps1 [OPTIONS] [SKILL...]` |

両者は同一の機能を持つ。オプション名の接頭辞と、link モードで作成するリンクの形式のみが異なる。以降の記述は両者に共通する。

リポジトリ直下のスキルを、インストール先ディレクトリへリンクまたは実体コピーとして配置する。`SKILL...` を省略した場合は全スキルが対象となる。

> [!IMPORTANT]
> `install.ps1` の実行には、スクリプトの実行を許可する実行ポリシーが必要である。既定値が `Restricted` の環境では `powershell -ExecutionPolicy Bypass -File .\_tools\install.ps1` として起動する。

## オプション

| install.sh | install.ps1 | 説明 |
| --- | --- | --- |
| `--copy` | `-Copy` | リンクではなく実体をコピーする |
| `--force`, `-f` | `-Force`, `-f` | インストール先に既存のファイルがあっても上書きする |
| `--dry-run`, `-n` | `-DryRun`, `-n` | 変更を行わず、実行される操作を表示する |
| `--uninstall` | `-Uninstall` | インストール済みのスキルを削除する |
| `--target DIR` | `-Target DIR` | インストール先ディレクトリを指定する |
| `--list`, `-l` | `-List`, `-l` | インストール可能なスキルを一覧表示する |
| `--help`, `-h` | `-Help`, `-h` | ヘルプを表示する |

## インストール先

| 変数 | 説明 |
| --- | --- |
| `CLAUDE_SKILLS_DIR` | インストール先ディレクトリの既定値 |

インストール先の決定順序は `--target` (`-Target`)、`CLAUDE_SKILLS_DIR`、既定値。既定値は `install.sh` が `~/.claude/skills`、`install.ps1` が `%USERPROFILE%\.claude\skills`。

## リンクの形式

`install.sh` は symlink を作成する。

`install.ps1` は symlink の作成を試み、失敗した場合は junction を作成する。Windows における symlink の作成には管理者権限または開発者モードが必要であり、Windows PowerShell 5.1 は開発者モードでも非特権での作成に対応しないためである。どちらの形式でも、リポジトリ側の編集は即座に反映される。

## 削除

`--uninstall` (`-Uninstall`) は、インストール先がこのリポジトリ内を指すリンクである場合にのみ削除する。実体ディレクトリおよび他所を指すリンクは、`--force` (`-Force`) を併用しない限り削除されない。リンクの削除はリンク自体のみを対象とし、リンク先の内容には影響しない。

## 出力

各スキルに対し、以下のいずれかの行を出力する。

| 表記 | 意味 |
| --- | --- |
| `install` | 新規に配置した |
| `replace` | 既存を上書きして配置した |
| `remove` | 削除した |
| `ok` | 既に同一のリンクが存在するため何もしなかった |
| `skip` | 削除対象が存在しなかった |
| `warning` | 既存の非対象ファイルにより処理しなかった (標準エラー出力) |

`install.ps1` は、link モードで配置した行に続けて、作成したリンクの形式 (`symlink` または `junction`) と配置先を出力する。

末尾に、インストール先と処理件数・スキップ件数・失敗件数の要約を出力する。

## 終了ステータス

| 値 | 条件 |
| --- | --- |
| `0` | 失敗件数が 0 |
| `1` | 失敗件数が 1 以上、または引数が不正 |

## 使用例

Linux, macOS, WSL では次のとおりである。

```sh
# 全スキルをインストールする
./_tools/install.sh

# 対象を確認する
./_tools/install.sh --list
./_tools/install.sh --dry-run

# 特定のスキルのみを、既存を上書きしてインストールする
./_tools/install.sh --force code-comment-edit

# 別ディレクトリへ実体としてインストールする
./_tools/install.sh --copy --target ./dist/skills

# インストールを解除する
./_tools/install.sh --uninstall
```

Windows では次のとおりである。

```powershell
# 全スキルをインストールする
.\_tools\install.ps1

# 対象を確認する
.\_tools\install.ps1 -List
.\_tools\install.ps1 -DryRun

# 特定のスキルのみを、既存を上書きしてインストールする
.\_tools\install.ps1 -Force code-comment-edit

# 別ディレクトリへ実体としてインストールする
.\_tools\install.ps1 -Copy -Target .\dist\skills

# インストールを解除する
.\_tools\install.ps1 -Uninstall
```
