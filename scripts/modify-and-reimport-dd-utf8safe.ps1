# modify-and-reimport-dd-utf8safe.ps1
$ErrorActionPreference = 'Stop'
$work = 'D:\DockerData'
if (-not (Test-Path $work)) { New-Item -ItemType Directory -Path $work -Force | Out-Null }
$LogFile = Join-Path $work 'modify-dd.log'
function Log($s){ $t=(Get-Date).ToString('s'); "$t $s" | Out-File -FilePath $LogFile -Append -Encoding UTF8; Write-Output $s }

Log '=== start modify-and-reimport-dd-utf8safe ==='
$tar = Join-Path $work 'docker-desktop-data.tar'
$modtar = Join-Path $work 'docker-desktop-data-mod.tar'
$extract = Join-Path $work 'ddroot'
$importPath = 'D:\DockerData\docker-desktop-data'

if (-not (Test-Path 'D:\')) { Log 'ERROR: D: drive not found, abort'; exit 10 }
New-Item -ItemType Directory -Path $work -Force | Out-Null

Log 'Stopping Docker Desktop and shutdown WSL'
Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue | ForEach-Object { Log "Stopping PID $($_.Id)"; Stop-Process -Id $_.Id -Force }
wsl --shutdown
Start-Sleep -Seconds 3

$ls = (wsl --list --verbose) 2>&1 | Out-String
Log "wsl list: $ls"
if ($ls -notmatch 'docker-desktop-data') { Log 'ERROR: docker-desktop-data not found, abort'; exit 11 }

if (Test-Path $tar) { Remove-Item -Force -Path $tar }
Log "Exporting docker-desktop-data to $tar"
$exp = wsl --export docker-desktop-data "$tar" 2>&1 | Out-String
Log $exp
if (-not (Test-Path $tar)) { Log 'ERROR: export failed, tar missing'; exit 12 }

if (Test-Path $extract) { Remove-Item -Recurse -Force $extract }
New-Item -ItemType Directory -Path $extract -Force | Out-Null
Log "Extracting tar to $extract"
& tar -xf "$tar" -C "$extract" 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8
Log 'Extraction complete'

$etcDocker = Join-Path $extract 'etc\docker'
if (-not (Test-Path $etcDocker)) { New-Item -ItemType Directory -Path $etcDocker -Force | Out-Null }
$daemonJson = '{"registry-mirrors":["https://hub-mirror.c.163.com","https://docker.mirrors.ustc.edu.cn","https://registry.docker-cn.com"]}'
$daemonPath = Join-Path $etcDocker 'daemon.json'
Set-Content -Path $daemonPath -Value $daemonJson -Encoding UTF8
Log "Wrote $daemonPath"

$systemdDir = Join-Path $extract 'etc\systemd\system\docker.service.d'
if (-not (Test-Path $systemdDir)) { New-Item -ItemType Directory -Path $systemdDir -Force | Out-Null }
$httpProxyConf = "[Service]`nEnvironment=""HTTP_PROXY=http://127.0.0.1:17788""`nEnvironment=""HTTPS_PROXY=http://127.0.0.1:17788""`nEnvironment=""NO_PROXY=127.0.0.1,localhost,::1"""
$httpProxyPath = Join-Path $systemdDir 'http-proxy.conf'
Set-Content -Path $httpProxyPath -Value $httpProxyConf -Encoding UTF8
Log "Wrote $httpProxyPath"

if (Test-Path $modtar) { Remove-Item -Force $modtar }
Log "Packing modified rootfs to $modtar"
& tar -C "$extract" -cf "$modtar" . 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8
if (-not (Test-Path $modtar)) { Log 'ERROR: packing failed'; exit 13 }
Log 'Packing complete'

Log 'Unregistering docker-desktop-data'
wsl --unregister docker-desktop-data 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8
Start-Sleep -Seconds 2

Log "Importing docker-desktop-data to $importPath"
wsl --import docker-desktop-data "$importPath" "$modtar" --version 2 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8

Log 'Starting Docker Desktop'
Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
Log 'Waiting initialization 20s'
Start-Sleep -Seconds 20

Log 'Writing docker info to log'
try { docker info --format '{{json .}}' 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { Log "docker info failed: $_" }

Log 'Attempt docker pull hello-world'
try { docker pull hello-world 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { Log "docker pull failed: $_" }

Log '=== done modify-and-reimport-dd-utf8safe ==='
exit 0
