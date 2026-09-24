param([switch]$SkipValidation)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'tools/release/build.ps1') -SkipValidation:$SkipValidation
exit $LASTEXITCODE
