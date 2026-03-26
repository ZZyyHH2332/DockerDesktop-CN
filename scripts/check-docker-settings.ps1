# check-docker-settings.ps1
$LogFile = Join-Path $PSScriptRoot 'check-docker-settings.log'
function Log($s){ $t=(Get-Date).ToString('s'); "$t $s" | Out-File -FilePath $LogFile -Append -Encoding UTF8; Write-Output $s }
Log '=== start check-docker-settings ==='

$paths = @(
  "$env:APPDATA\Docker\settings.json",
  "$env:LOCALAPPDATA\Docker\settings.json",
  "$env:PROGRAMDATA\Docker\settings.json"
)
foreach ($p in $paths) {
  Log "Checking: $p"
  if (Test-Path $p) {
    Log "FOUND: $p"
    try { Get-Content -Path $p -ErrorAction Stop | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { Log ("Error reading {0}: {1}" -f $p, $_) }
  } else {
    Log "MISSING: $p"
  }
}

if (Test-Path "$env:LOCALAPPDATA\Docker") { 
  Log ("Listing first 200 entries under {0}" -f (Join-Path $env:LOCALAPPDATA 'Docker'))
  Get-ChildItem -Path "$env:LOCALAPPDATA\Docker" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 200 | Out-File -FilePath $LogFile -Append -Encoding UTF8
} else { Log "No LOCALAPPDATA\\Docker directory" }

Log 'Registry checks (HKCU)'
$keys = @('HKCU:\Software\Docker','HKCU:\Software\Docker Inc.')
foreach ($k in $keys) {
  try { $v = Get-ItemProperty -Path $k -ErrorAction Stop; Log "REG: $k"; $v | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { Log "REG MISSING: $k" }
}

Log '=== done check-docker-settings ==='
exit 0
