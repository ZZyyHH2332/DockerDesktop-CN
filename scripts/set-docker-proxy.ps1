# set-docker-proxy.ps1
$LogFile = Join-Path $PSScriptRoot 'set-docker-proxy.log'
function Log($s){ $t=(Get-Date).ToString('s'); "$t $s" | Out-File -FilePath $LogFile -Append -Encoding UTF8; Write-Output $s }

Log '=== start set-docker-proxy ==='
$proxy = 'http://127.0.0.1:17788'
$noProxy = '127.0.0.1,localhost,::1'
$paths = @("$env:APPDATA\Docker\settings.json","$env:LOCALAPPDATA\Docker\settings.json")
foreach ($p in $paths) {
  try {
    $dir = Split-Path $p -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $p) {
      $bak = "$p.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
      Copy-Item -Path $p -Destination $bak -Force
      Log "Backed up $p -> $bak"
      $existing = Get-Content -Path $p -Raw -ErrorAction SilentlyContinue
      try { $obj = $existing | ConvertFrom-Json -ErrorAction Stop } catch { $obj = @{} }
    } else {
      Log "Creating new settings file: $p"
      $obj = @{}
    }
    $obj.proxies = @{ default = @{ httpProxy = $proxy; httpsProxy = $proxy; noProxy = $noProxy } }
    $json = $obj | ConvertTo-Json -Depth 10
    $json | Set-Content -Path $p -Encoding UTF8
    Log "Wrote proxies to $p"
  } catch { Log ("Error writing {0}: {1}" -f $p, $_) }
}

# Restart Docker Desktop
Log 'Restarting Docker Desktop'
Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue | ForEach-Object { Log ("Stopping PID {0}" -f $_.Id); Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
Log 'Waiting 20s for initialization'
Start-Sleep -Seconds 20

Log 'Collecting docker info'
try { docker info --format '{{json .}}' 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { Log ("docker info failed: {0}" -f $_) }

Log 'Attempt docker pull hello-world'
try { docker pull hello-world 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { Log ("docker pull failed: {0}" -f $_) }

Log '=== done set-docker-proxy ==='
exit 0
