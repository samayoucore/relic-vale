$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$engine=Join-Path $root 'tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$env:APPDATA=Join-Path $root 'downloads/phase10/regression-userdata'
$reports=@()
foreach($name in @('phase9-stories-reload','phase9-events-reload','phase8-test','phase8-reload','phase8-final','phase9-polish')) {
    $log=Join-Path $root "downloads/phase10/regression/$name.log"
    $args=@('--headless','--path',(Join-Path $root 'relic_vale'),'--log-file',$log,'--',"--$name")
    if($name -eq 'phase9-polish') { $args=@('--audio-driver','Dummy','--path',(Join-Path $root 'relic_vale'),'--log-file',$log,'--',"--$name") }
    & $engine @args *> ($log+'.console')
    $code=$LASTEXITCODE
    $bad=[bool](Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:|WARNING:|PHASE[0-9]+ FAIL' -Quiet)
    $report=@{name=$name;exit_code=$code;log_errors=$bad;result=@(Select-String -LiteralPath $log -Pattern 'RESULT' | ForEach-Object {$_.Line})}
    $reports+=$report
    $reports | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $root 'relic_vale/docs/PHASE_10_REGRESSION.json')
    Write-Output ($report | ConvertTo-Json -Compress)
}
