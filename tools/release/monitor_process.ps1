param([Parameter(Mandatory=$true)][string]$ExecutablePath,[Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference='Stop'
$target=[IO.Path]::GetFullPath($ExecutablePath)
$rows=@()
$seen=$false
while ($true) {
    $process=Get-Process -Name RelicVale -ErrorAction SilentlyContinue | Where-Object {
        try { [IO.Path]::GetFullPath($_.Path) -eq $target } catch { $false }
    } | Select-Object -First 1
    if ($null -eq $process) {
        if ($seen) { break }
        Start-Sleep -Seconds 1
        continue
    }
    $seen=$true
    $rows+=@{utc=[DateTime]::UtcNow.ToString('o'); elapsed_s=([DateTime]::UtcNow-$process.StartTime.ToUniversalTime()).TotalSeconds; working_set_bytes=$process.WorkingSet64; private_bytes=$process.PrivateMemorySize64; cpu_seconds=$process.CPU; handles=$process.Handles; threads=$process.Threads.Count}
    $rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath
    Start-Sleep -Seconds 10
}
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutputPath
