$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$archivePath = Join-Path $workspace 'downloads/RelicVale-v0.9-baseline.zip'
if (Test-Path -LiteralPath $archivePath) { throw 'The Phase 9 archive already exists; inspect it before replacing it.' }
$entries = [System.Collections.Generic.List[object]]::new()
$project = Join-Path $workspace 'relic_vale'
foreach ($file in Get-ChildItem -LiteralPath $project -File -Recurse) {
    $relative = [IO.Path]::GetRelativePath($workspace,$file.FullName).Replace('\','/')
    if ($relative -match '/\.godot/' -or $relative -match '/docs/screenshots/.*\.import$') { continue }
    $entries.Add(@{ Path=$file.FullName; Name=$relative })
}
foreach ($relative in @('README.md','Launch Relic Vale.bat','Edit Relic Vale.bat','tools/godot/Godot_v4.7.2-stable_win64.exe','tools/godot/Godot_v4.7.2-stable_win64_console.exe')) {
    $entries.Add(@{ Path=(Join-Path $workspace $relative); Name=$relative })
}
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $workspace 'tools/godot') -File) {
    if ($file.Extension -in @('.txt','.md')) { $entries.Add(@{Path=$file.FullName;Name=('tools/godot/'+$file.Name)}) }
}
$stream = [IO.File]::Open($archivePath,[IO.FileMode]::CreateNew)
$zip = [IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($entry in $entries) {
        $record=$zip.CreateEntry($entry.Name,[IO.Compression.CompressionLevel]::Optimal)
        $source=[IO.File]::OpenRead($entry.Path); $destination=$record.Open()
        try { $source.CopyTo($destination) } finally { $destination.Dispose(); $source.Dispose() }
    }
} finally { $zip.Dispose(); $stream.Dispose() }
$stream=[IO.File]::OpenRead($archivePath)
$zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Read)
$verified=0
try {
    foreach ($entry in $entries) {
        $record=$zip.GetEntry($entry.Name)
        if (-not $record) { throw ('Missing ZIP entry: '+$entry.Name) }
        $source=[IO.File]::OpenRead($entry.Path); $packed=$record.Open()
        $sha=[Security.Cryptography.SHA256]::Create()
        try {
            $sourceHash=[Convert]::ToHexString($sha.ComputeHash($source))
            $packedHash=[Convert]::ToHexString($sha.ComputeHash($packed))
            if ($sourceHash -ne $packedHash) { throw ('ZIP hash mismatch: '+$entry.Name) }
            $verified++
        } finally { $sha.Dispose(); $source.Dispose(); $packed.Dispose() }
    }
} finally { $zip.Dispose(); $stream.Dispose() }
$receipt=@{archive='RelicVale-v0.9-baseline.zip';verified_files=$verified;bytes=(Get-Item -LiteralPath $archivePath).Length;sha256=(Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash;user_saves_included=$false}
$receipt | ConvertTo-Json | Set-Content -LiteralPath ($archivePath.Replace('.zip','.receipt.json')) -Encoding utf8
$receipt | ConvertTo-Json -Compress

