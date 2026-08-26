#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Source = 'moepig/skills'
$MinimumNodeVersion = [Version]'22.20.0'

function Stop-WithError {
  param([string]$Message)
  [Console]::Error.WriteLine("error: $Message")
  exit 1
}

function Get-RequiredCommand {
  param(
    [string[]]$Name,
    [string]$ErrorMessage
  )

  foreach ($candidate in $Name) {
    $command = Get-Command -Name $candidate -CommandType Application -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($null -ne $command) {
      return $command
    }
  }

  Stop-WithError -Message $ErrorMessage
}

$nodeCommand = Get-RequiredCommand -Name @('node.exe', 'node') -ErrorMessage "Node.js $MinimumNodeVersion or later is required"
$npxCommand = Get-RequiredCommand -Name @('npx.cmd', 'npx') -ErrorMessage 'npx is required (install npm with Node.js)'
$null = Get-RequiredCommand -Name @('git.exe', 'git') -ErrorMessage 'Git is required'

$nodeVersionText = (& $nodeCommand.Path --version).Trim()
if ($LASTEXITCODE -ne 0) {
  Stop-WithError -Message 'Failed to determine the Node.js version'
}
if ($nodeVersionText.StartsWith('v')) {
  $nodeVersionText = $nodeVersionText.Substring(1)
}

try {
  $nodeVersion = [Version]$nodeVersionText
} catch {
  Stop-WithError -Message "Failed to parse the Node.js version: $nodeVersionText"
}
if ($nodeVersion -lt $MinimumNodeVersion) {
  Stop-WithError -Message "Node.js $MinimumNodeVersion or later is required (found v$nodeVersion)"
}

$skillsArguments = @($args)
if ($skillsArguments.Count -eq 0) {
  $skillsArguments = @(
    '--global',
    '--skill', '*',
    '--agent', 'claude-code',
    '--agent', 'codex',
    '--yes'
  )
}

& $npxCommand.Path '--yes' 'skills' 'add' $Source @skillsArguments
exit $LASTEXITCODE
