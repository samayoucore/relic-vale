param([string]$Output = 'downloads/phase10/baseline/RelicVale.exe', [string]$Script = 'tools/release/benchmark.gd')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$project = Join-Path $root 'relic_vale/project.godot'
$preset = Join-Path $root 'relic_vale/export_presets.cfg'
$original = [IO.File]::ReadAllText($project)
$originalPreset = [IO.File]::ReadAllText($preset)
$exe = Join-Path $root $Output
New-Item -ItemType Directory -Force -Path (Split-Path $exe) | Out-Null
try {
    Copy-Item -LiteralPath (Join-Path $root $Script) -Destination (Join-Path $root 'relic_vale/tests/phase10_active.gd') -Force
    [IO.File]::WriteAllText($project, $original.Replace('[autoload]', "[autoload]`nReleaseQA=`"*res://tests/phase10_launcher.gd`""))
    [IO.File]::WriteAllText($preset, $originalPreset.Replace('tests/*,', ''))
    & (Join-Path $root 'tools/godot/Godot_v4.7.2-stable_win64_console.exe') --headless --path (Join-Path $root 'relic_vale') --export-release 'Windows Desktop' $exe --log-file ($exe + '.export.log') *> ($exe + '.console.log')
    if ($LASTEXITCODE -ne 0) { throw 'QA export failed' }
    if (Select-String -LiteralPath ($exe + '.export.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw 'QA export reported errors' }
} finally {
    [IO.File]::WriteAllText($project, $original)
    [IO.File]::WriteAllText($preset, $originalPreset)
}
