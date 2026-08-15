#Requires -Version 5.1
# このリポジトリのスキルをユーザーの ~/.claude/skills/ へインストールする。
#
# 既定では link を張るため、リポジトリ側の編集が即座に反映される。
# -Copy を指定した場合は実体をコピーする。
#
# 本ファイルは UTF-8 BOM 付きで保存すること。Windows PowerShell 5.1 は BOM の無いスクリプトを
# システムの ANSI コードページとして解釈するためである。

# PositionalBinding を無効化し、位置指定の引数を SKILL のみに限定する。
[CmdletBinding(PositionalBinding = $false)]
param(
  [switch]$Copy,
  [Alias('f')][switch]$Force,
  [Alias('n')][switch]$DryRun,
  [switch]$Uninstall,
  [string]$Target,
  [Alias('l')][switch]$List,
  [Alias('h')][switch]$Help,
  [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Skill
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoDir = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath

function Show-Usage {
  Write-Host @'
Usage: _tools\install.ps1 [OPTIONS] [SKILL...]

このリポジトリのスキルを ~/.claude/skills/ へインストールする。
SKILL を省略した場合はリポジトリ内の全スキルが対象になる。

Options:
  -Copy               link ではなく実体をコピーする
  -Force, -f          インストール先に既存のファイルがあっても上書きする
  -DryRun, -n         実際には変更せず、実行内容のみ表示する
  -Uninstall          インストール済みのスキルを削除する
                      (このリポジトリを指す link、または -Force 指定時のみ)
  -Target DIR         インストール先ディレクトリ (既定: ~/.claude/skills)
  -List, -l           インストール可能なスキルを一覧表示する
  -Help, -h           このヘルプを表示する

Environment:
  CLAUDE_SKILLS_DIR   インストール先ディレクトリの既定値を上書きする
'@
}

function Write-Log { param([string]$Message) Write-Host $Message }

function Write-WarnLine {
  param([string]$Message)
  [Console]::Error.WriteLine("warning: $Message")
}

function Stop-WithError {
  param([string]$Message)
  [Console]::Error.WriteLine("error: $Message")
  exit 1
}

# 相対パス、および先頭の `~` を含むパスを絶対パスへ変換する。
# パスの存在を要求しないため、未作成のインストール先にも適用できる。
function Get-AbsolutePath {
  param([string]$Path)
  if ($Path -eq '~' -or $Path.StartsWith('~\') -or $Path.StartsWith('~/')) {
    $Path = Join-Path -Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath $Path.Substring(1).TrimStart('\', '/')
  }
  if (-not [System.IO.Path]::IsPathRooted($Path)) {
    $Path = Join-Path -Path (Get-Location).ProviderPath -ChildPath $Path
  }
  return [System.IO.Path]::GetFullPath($Path)
}

function Test-SamePath {
  param([string]$Left, [string]$Right)
  $l = $Left.TrimEnd('\', '/')
  $r = $Right.TrimEnd('\', '/')
  return $l -ieq $r
}

# リポジトリ直下の、SKILL.md を持つディレクトリ名を列挙する。
# 先頭が `_` または `.` のディレクトリは補助的なものとして除外する。
function Get-AvailableSkill {
  Get-ChildItem -LiteralPath $RepoDir -Directory -Force |
    Where-Object { $_.Name -notmatch '^[_.]' } |
    Where-Object { Test-Path -LiteralPath (Join-Path -Path $_.FullName -ChildPath 'SKILL.md') -PathType Leaf } |
    ForEach-Object { $_.Name }
}

# reparse point (symlink または junction) の解決先を絶対パスとして返す。
# reparse point でない場合、および解決先を取得できない場合は $null を返す。
function Get-LinkTarget {
  param([string]$Path)
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if ($null -eq $item) { return $null }
  if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne [System.IO.FileAttributes]::ReparsePoint) { return $null }

  $target = $null
  if ($item.PSObject.Properties['LinkTarget'] -and $item.LinkTarget) {
    $target = $item.LinkTarget
  } elseif ($item.PSObject.Properties['Target'] -and $item.Target) {
    $target = @($item.Target)[0]
  }
  if (-not $target) { return $null }

  # junction の解決先は NT パス形式 (\??\C:\...) で返る場合がある。
  if ($target.StartsWith('\??\')) { $target = $target.Substring(4) }
  # symlink の解決先は相対パスで記録される場合があり、リンク自体の位置を基準に解決する。
  if (-not [System.IO.Path]::IsPathRooted($target)) {
    $target = Join-Path -Path (Split-Path -Parent $Path) -ChildPath $target
  }
  return [System.IO.Path]::GetFullPath($target)
}

# リンク先がこのリポジトリ内を指しているかを判定する。
function Test-PointsIntoRepo {
  param([string]$Path)
  $target = Get-LinkTarget -Path $Path
  if ($null -eq $target) { return $false }
  return $target.StartsWith(($RepoDir.TrimEnd('\', '/') + '\'), [System.StringComparison]::OrdinalIgnoreCase)
}

# インストール先の項目を削除する。
# reparse point はリンク自体のみを削除し、解決先の内容には触れない。
function Remove-Installed {
  param([string]$Path)
  $item = Get-Item -LiteralPath $Path -Force
  if ($item.PSIsContainer -and $null -ne (Get-LinkTarget -Path $Path)) {
    [System.IO.Directory]::Delete($Path, $false)
    return
  }
  Remove-Item -LiteralPath $Path -Recurse -Force
}

# link モードでのリンクを作成し、作成した種別を返す。
# symlink を優先し、作成できない場合は junction へ切り替える。
# Windows における symlink の作成には管理者権限または開発者モードが必要であり、
# Windows PowerShell 5.1 は開発者モードでも非特権での作成に対応しないためである。
function New-SkillLink {
  param([string]$Path, [string]$TargetPath)
  try {
    $null = New-Item -ItemType SymbolicLink -Path $Path -Target $TargetPath -ErrorAction Stop
    return 'symlink'
  } catch {
    $null = New-Item -ItemType Junction -Path $Path -Target $TargetPath -ErrorAction Stop
    return 'junction'
  }
}

if ($Help) { Show-Usage; exit 0 }
if ($List) { Get-AvailableSkill | Write-Output; exit 0 }

if (-not $Target) {
  if ($env:CLAUDE_SKILLS_DIR) {
    $Target = $env:CLAUDE_SKILLS_DIR
  } else {
    $Target = Join-Path -Path ([Environment]::GetFolderPath('UserProfile')) -ChildPath '.claude\skills'
  }
}
$TargetDir = Get-AbsolutePath -Path $Target

$available = @(Get-AvailableSkill)
if ($available.Count -eq 0) { Stop-WithError "$RepoDir にスキルが見つからない" }

if ($null -eq $Skill -or $Skill.Count -eq 0) {
  $skills = $available
} else {
  $skills = @()
  foreach ($name in $Skill) {
    $name = $name.TrimEnd('\', '/')
    if ($available -notcontains $name) { Stop-WithError "スキルが存在しない: $name (-List で一覧表示)" }
    $skills += $name
  }
}

$installed = 0
$skipped = 0
$failed = 0

if (-not $DryRun) {
  $null = New-Item -ItemType Directory -Path $TargetDir -Force
}

foreach ($name in $skills) {
  $src = Join-Path -Path $RepoDir -ChildPath $name
  $dest = Join-Path -Path $TargetDir -ChildPath $name
  $exists = Test-Path -LiteralPath $dest

  if ($Uninstall) {
    if (-not $exists) {
      Write-Log "skip     $name (未インストール)"
      $skipped++
      continue
    }
    if (-not (Test-PointsIntoRepo -Path $dest) -and -not $Force) {
      Write-WarnLine "${name}: このリポジトリの link ではないため削除しない (-Force で強制削除)"
      $failed++
      continue
    }
    Write-Log "remove   $name"
    if ($DryRun) {
      Write-Log "  [dry-run] remove $dest"
    } else {
      Remove-Installed -Path $dest
    }
    $installed++
    continue
  }

  if ($exists) {
    $current = Get-LinkTarget -Path $dest
    if (-not $Copy -and $null -ne $current -and (Test-SamePath -Left $current -Right $src)) {
      Write-Log "ok       $name (インストール済み)"
      $skipped++
      continue
    }
    if (-not $Force) {
      Write-WarnLine "${name}: $dest が既に存在する (-Force で上書き)"
      $failed++
      continue
    }
    Write-Log "replace  $name"
    if ($DryRun) {
      Write-Log "  [dry-run] remove $dest"
    } else {
      Remove-Installed -Path $dest
    }
  } else {
    Write-Log "install  $name"
  }

  try {
    if ($Copy) {
      if ($DryRun) {
        Write-Log "  [dry-run] copy $src -> $dest"
      } else {
        Copy-Item -LiteralPath $src -Destination $dest -Recurse -Force
      }
    } else {
      if ($DryRun) {
        Write-Log "  [dry-run] link $dest -> $src"
      } else {
        $kind = New-SkillLink -Path $dest -TargetPath $src
        Write-Log "         $kind $dest -> $src"
      }
    }
  } catch {
    Write-WarnLine "${name}: 作成に失敗した: $($_.Exception.Message)"
    $failed++
    continue
  }
  $installed++
}

Write-Log ''
Write-Log "${TargetDir}: $installed 件処理, $skipped 件スキップ, $failed 件失敗"
if ($failed -gt 0) { exit 1 }
exit 0
