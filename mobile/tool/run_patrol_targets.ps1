param(
  [string]$Device = "emulator-5554",
  [string]$AndroidSdk = "D:\Tool\Learn\AndroidAVD"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $ProjectRoot

$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk

$PubCacheBin = Join-Path $env:USERPROFILE "AppData\Local\Pub\Cache\bin"
$PlatformTools = Join-Path $AndroidSdk "platform-tools"
$env:Path = "$env:Path;$PubCacheBin;$PlatformTools"

$Patrol = Join-Path $PubCacheBin "patrol.bat"
$ResultDir = Join-Path $ProjectRoot "test-results"
$ResultFile = Join-Path $ResultDir "patrol-targets-result.txt"

if (!(Test-Path $ResultDir)) {
  New-Item -ItemType Directory -Path $ResultDir | Out-Null
}

if (Test-Path $ResultFile) {
  Remove-Item $ResultFile
}

$Targets = @(
  "patrol_tests\authentication_test.dart",
  "patrol_tests\export_test.dart",
  "patrol_tests\journal_test.dart",
  "patrol_tests\keyword_test.dart",
  "patrol_tests\profile_test.dart",
  "patrol_tests\publication_test.dart",
  "patrol_tests\remote_config_test.dart"
)

$FailedTargets = @()

foreach ($Target in $Targets) {
  $Header = @"

================================================================
Running: $Target
Device : $Device
================================================================
"@
  Write-Host $Header
  Add-Content -Path $ResultFile -Value $Header -Encoding UTF8

  $CurrentResultFile = Join-Path $ResultDir "patrol-target-current.txt"
  $CommandLine = "chcp 65001 >NUL & `"$Patrol`" test --target `"$Target`" -d `"$Device`" > `"$CurrentResultFile`" 2>&1"
  cmd.exe /d /c $CommandLine
  $ExitCode = $LASTEXITCODE

  $TargetOutput = Get-Content $CurrentResultFile -Raw -Encoding UTF8
  Write-Host $TargetOutput
  Add-Content -Path $ResultFile -Value $TargetOutput -Encoding UTF8

  if ($ExitCode -ne 0) {
    $FailedTargets += $Target
    Add-Content -Path $ResultFile -Value "FAILED: $Target (exit code $ExitCode)" -Encoding UTF8
  } else {
    Add-Content -Path $ResultFile -Value "PASSED: $Target" -Encoding UTF8
  }
}

Remove-Item (Join-Path $ResultDir "patrol-target-current.txt") -ErrorAction SilentlyContinue

if ($FailedTargets.Count -gt 0) {
  Write-Host "Failed targets:" -ForegroundColor Red
  $FailedTargets | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
  exit 1
}

Write-Host "All Patrol target groups passed. Result: $ResultFile" -ForegroundColor Green
exit 0
