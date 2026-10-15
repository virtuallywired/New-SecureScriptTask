$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..' 'New-SecureScriptTask.ps1')

function New-ScheduledTaskAction {
    param([string]$Execute, [string]$Argument)
    [pscustomobject]@{ Execute = $Execute; Argument = $Argument }
}

function New-ScheduledTaskPrincipal {
    param([string]$UserId, [string]$RunLevel)
    [pscustomobject]@{ UserId = $UserId; RunLevel = $RunLevel }
}

function Register-ScheduledTask {
    param(
        [string]$TaskName,
        [object]$Action,
        [string]$Description,
        [object]$Principal
    )
    [pscustomobject]@{
        TaskName   = $TaskName
        Action     = $Action
        Description = $Description
        Principal  = $Principal
    }
}

$TestRoot = Join-Path ([IO.Path]::GetTempPath()) "New-SecureScriptTask-$([guid]::NewGuid())"
$ScriptPath = Join-Path $TestRoot "script with 'quote.ps1"
$MarkerPath = Join-Path $TestRoot 'executed.txt'

try {
    $null = New-Item -ItemType Directory -Path $TestRoot
    $EscapedMarkerPath = $MarkerPath.Replace("'", "''")
    "Set-Content -LiteralPath '$EscapedMarkerPath' -Value 'executed'" |
        Set-Content -LiteralPath $ScriptPath

    $RegisteredTask = New-SecureScriptTask -ScriptPath $ScriptPath -TaskName 'Test task'
    $EncodedCommand = ($RegisteredTask.Action.Argument -split ' ')[-1]

    & pwsh -NoProfile -NonInteractive -EncodedCommand $EncodedCommand
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $MarkerPath)) {
        throw 'Expected a matching script to run successfully.'
    }

    Remove-Item -LiteralPath $MarkerPath
    Add-Content -LiteralPath $ScriptPath -Value '# modified after registration'

    & pwsh -NoProfile -NonInteractive -EncodedCommand $EncodedCommand
    if ($LASTEXITCODE -eq 0) {
        throw 'Expected a hash mismatch to return a non-zero exit code.'
    }
    if (Test-Path -LiteralPath $MarkerPath) {
        throw 'The modified script ran despite the hash mismatch.'
    }

    Write-Output 'PASS: matching scripts run; modified scripts fail with a non-zero exit code.'
}
finally {
    Remove-Item -LiteralPath $TestRoot -Recurse -Force -ErrorAction SilentlyContinue
}
