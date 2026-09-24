param([switch]$SkipValidation)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$project=Join-Path $root 'relic_vale'
$godot=Join-Path $root 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$iscc=Join-Path $PSScriptRoot 'inno/ISCC.exe'
$node=(Get-Command node.exe -ErrorAction Stop).Source
$version=[regex]::Match([IO.File]::ReadAllText((Join-Path $project 'project.godot')),'config/version="(\d+\.\d+\.\d+)"').Groups[1].Value
if (!$version) { throw 'No valid game version in project.godot' }
foreach ($file in @($godot,$iscc,(Join-Path $PSScriptRoot 'templates/windows_release_x86_64.exe'))) {
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing build dependency: $file. See relic_vale/docs/RELEASE_PROCESS.md" }
}
$toolchain=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'toolchain.json') -Raw | ConvertFrom-Json
foreach ($pair in @(@($godot,$toolchain.godot_console_sha256),@((Join-Path $PSScriptRoot 'templates/windows_release_x86_64.exe'),$toolchain.windows_release_template_sha256),@($iscc,$toolchain.inno_compiler_sha256))) {
    if ((Get-FileHash -LiteralPath $pair[0] -Algorithm SHA256).Hash -ne $pair[1]) { throw "Toolchain hash mismatch: $($pair[0])" }
}
$dist=Join-Path $root 'dist'
$staging=Join-Path $root 'downloads/phase10/build'
$game=Join-Path $staging 'RelicVale'
if (Test-Path -LiteralPath $staging) {
    $resolved=[IO.Path]::GetFullPath($staging)
    if ($resolved -ne [IO.Path]::GetFullPath((Join-Path $root 'downloads/phase10/build'))) { throw 'Unsafe staging path' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $game | Out-Null
New-Item -ItemType Directory -Force -Path $dist | Out-Null
& $godot --headless --editor --path $project --import --quit --log-file (Join-Path $staging 'import.log') *> (Join-Path $staging 'import-console.log')
if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath (Join-Path $staging 'import.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet)) { throw "Godot import failed; see $staging/import.log" }
& $godot --headless --path $project --script (Join-Path $PSScriptRoot 'render_icon.gd') *> (Join-Path $staging 'assets.log')
if ($LASTEXITCODE -ne 0) { throw 'Icon/license preparation failed' }
& $node (Join-Path $PSScriptRoot 'prepare_assets.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Asset preparation failed' }
& $node (Join-Path $PSScriptRoot 'validate.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Static release validation failed' }
if (!$SkipValidation) {
    $savedAppData=$env:APPDATA
    try {
        $env:APPDATA=Join-Path $root 'downloads/phase10-build-userdata'
        New-Item -ItemType Directory -Force -Path $env:APPDATA | Out-Null
        & $godot --headless --path $project --log-file (Join-Path $staging 'save-validation.log') -- --phase10-save *> (Join-Path $staging 'save-validation-console.log')
        if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath (Join-Path $staging 'save-validation.log') -Pattern 'SCRIPT ERROR:|ERROR:|PHASE10_SAVE FAIL' -Quiet)) { throw 'Save regression failed' }
    } finally { $env:APPDATA=$savedAppData }
}
$exe=Join-Path $game 'RelicVale.exe'
& $godot --headless --path $project --export-release 'Windows Desktop' $exe --log-file (Join-Path $staging 'export.log') *> (Join-Path $staging 'export-console.log')
if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath (Join-Path $staging 'export.log') -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet)) { throw 'Windows release export failed' }
foreach ($filename in @('RelicVale.exe','RelicVale.pck')) {
    if (!(Test-Path -LiteralPath (Join-Path $game $filename))) { throw "Export missing $filename" }
}
& $node (Join-Path $PSScriptRoot 'audit_executable.mjs') (Join-Path $game 'RelicVale.exe') (Join-Path $staging 'pe-audit.json')
if ($LASTEXITCODE -ne 0) { throw 'Exported executable failed PE dependency audit' }
& $node (Join-Path $PSScriptRoot 'audit_pack.mjs') (Join-Path $game 'RelicVale.pck') (Join-Path $staging 'pack-audit.json')
if ($LASTEXITCODE -ne 0) { throw 'Exported PCK failed integrity/content audit' }
foreach ($filename in @('README.txt','RELEASE_NOTES.txt','LICENSE.txt')) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot $filename) -Destination $game }
Copy-Item -LiteralPath (Join-Path $project 'THIRD_PARTY_LICENSES.txt') -Destination $game
# Optional signing is supplied by the owner, using a real certificate and their own script.
if ($env:VALE_SIGN_SCRIPT) { & $env:VALE_SIGN_SCRIPT $exe; if ($LASTEXITCODE -ne 0) { throw 'Executable signing failed' } }
& $iscc "/DGameVersion=$version" "/DSourcePath=$game" "/DOutputPath=$staging" "/DIconPath=$(Join-Path $project 'assets/ui/relic_vale.ico')" (Join-Path $PSScriptRoot 'installer.iss') *> (Join-Path $staging 'installer.log')
if ($LASTEXITCODE -ne 0) { throw "Installer compilation failed; see $staging/installer.log" }
$setup=Join-Path $staging "RelicVale-$version-Setup.exe"
if ($env:VALE_SIGN_SCRIPT) { & $env:VALE_SIGN_SCRIPT $setup; if ($LASTEXITCODE -ne 0) { throw 'Installer signing failed' } }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=Join-Path $staging "RelicVale-$version-Portable.zip"
[IO.Compression.ZipFile]::CreateFromDirectory($game,$zip,[IO.Compression.CompressionLevel]::Optimal,$true)
# Publish complete artifacts only after every build step succeeds.
foreach ($artifact in @($setup,$zip)) { Copy-Item -LiteralPath $artifact -Destination $dist -Force }
foreach ($filename in @('README.txt','RELEASE_NOTES.txt','LICENSE.txt','THIRD_PARTY_LICENSES.txt')) { Copy-Item -LiteralPath (Join-Path $game $filename) -Destination $dist -Force }
$hashes=@()
foreach ($file in @("RelicVale-$version-Setup.exe","RelicVale-$version-Portable.zip",'README.txt','RELEASE_NOTES.txt','THIRD_PARTY_LICENSES.txt','LICENSE.txt')) { $hashes+=((Get-FileHash -LiteralPath (Join-Path $dist $file) -Algorithm SHA256).Hash.ToLower()+'  '+$file) }
[IO.File]::WriteAllLines((Join-Path $dist 'SHA256SUMS.txt'),$hashes)
$receipt=@{ version=$version; engine=$toolchain.godot_version; architecture='x86_64'; debug=$false; signed=[bool]$env:VALE_SIGN_SCRIPT; timestamp=[DateTime]::UtcNow.ToString('o'); artifacts=$hashes; pck_audit=(Get-Content -LiteralPath (Join-Path $staging 'pack-audit.json') -Raw | ConvertFrom-Json | Select-Object file_count,bytes,sha256) }
$receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $project 'docs/PHASE_10_BUILD.json')
Write-Host "VERSION: $version"
Write-Host "INSTALLER PATH: $(Join-Path $dist (Split-Path $setup -Leaf))"
Write-Host "PORTABLE PATH: $(Join-Path $dist (Split-Path $zip -Leaf))"
Write-Host "INSTALLER SHA256: $((Get-FileHash -LiteralPath (Join-Path $dist (Split-Path $setup -Leaf)) -Algorithm SHA256).Hash.ToLower())"
Write-Host "PORTABLE SHA256: $((Get-FileHash -LiteralPath (Join-Path $dist (Split-Path $zip -Leaf)) -Algorithm SHA256).Hash.ToLower())"
Write-Host 'BUILD STATUS: SUCCESS'
