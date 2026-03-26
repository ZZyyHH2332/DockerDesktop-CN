# 迁移脚本：设置 WinHTTP 代理并迁移 docker-desktop-data 到 D:\DockerData
# 用法：以管理员运行本脚本（会从本脚本直接设置代理并操作 WSL distro）

$ErrorActionPreference = 'Stop'
function Log($s){ $t=(Get-Date).ToString('s'); "$t $s" | Out-File -FilePath "D:\DockerData\migrate-docker.log" -Append -Encoding UTF8; Write-Output $s }

Log '----- 开始迁移脚本（需要管理员） -----'

$Proxy = '127.0.0.1:17788'
$TargetDir = 'D:\DockerData\docker-desktop-data'
$TarPath = 'D:\DockerData\docker-desktop-data.tar'
$DockerDesktopExe = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'

# 检查 D: 驱动器
if (-not (Test-Path 'D:\')){ Log 'ERROR: D: 驱动器未找到，终止迁移'; exit 10 }
$drive = Get-PSDrive -Name D -ErrorAction SilentlyContinue
Log ("D: 剩余空间 (bytes): {0}" -f $drive.Free)
if ($drive.Free -lt 5GB){ Log 'WARNING: D: 可用空间少于 5GB，继续可能失败' }

# 停止 Docker Desktop 与 WSL
Log '停止 Docker Desktop 进程并shutdown WSL' 
Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue | ForEach-Object { Log "Stopping PID $($_.Id)"; Stop-Process -Id $_.Id -Force }
wsl --shutdown
Start-Sleep -Seconds 3

# 设置 WinHTTP 代理
Log "设置 WinHTTP 代理为 $Proxy"
try {
    netsh winhttp set proxy $Proxy 2>&1 | Out-String | ForEach-Object { Log $_ }
    netsh winhttp show proxy 2>&1 | Out-String | ForEach-Object { Log $_ }
} catch { Log "netsh 设置失败: $_"; exit 11 }

# 检查 docker-desktop-data 是否存在
$ls = wsl --list --verbose 2>&1 | Out-String
if ($ls -notmatch 'docker-desktop-data') { Log 'ERROR: 找不到 docker-desktop-data distro，取消迁移'; Log $ls; exit 20 }

# 创建目标目录
New-Item -ItemType Directory -Path (Split-Path $TarPath) -Force | Out-Null
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

# 导出 distro
Log "导出 docker-desktop-data 到 $TarPath（可能耗时，取决于数据量）"
$exp = wsl --export docker-desktop-data $TarPath 2>&1 | Out-String
Log $exp
if ($LASTEXITCODE -ne 0){ Log 'ERROR: wsl --export 失败'; exit 21 }

# 注销原始 distro
Log '注销 docker-desktop-data (wsl --unregister)'
$un = wsl --unregister docker-desktop-data 2>&1 | Out-String
Log $un
if ($LASTEXITCODE -ne 0){ Log 'ERROR: wsl --unregister 失败'; exit 22 }

# 导入到 D: 指定位置
Log "导入 docker-desktop-data 到 $TargetDir"
$imp = wsl --import docker-desktop-data $TargetDir $TarPath --version 2 2>&1 | Out-String
Log $imp
if ($LASTEXITCODE -ne 0){ Log 'ERROR: wsl --import 失败'; exit 23 }

# 启动 Docker Desktop
Log '启动 Docker Desktop...'
Start-Process -FilePath $DockerDesktopExe
Start-Sleep -Seconds 10
Log '等待 Docker 初始化...'
Start-Sleep -Seconds 15

# 输出 docker info 到日志
Log 'docker info 输出：'
try { docker info 2>&1 | Out-File -FilePath "D:\DockerData\migrate-docker.log" -Append -Encoding UTF8 } catch { Log "执行 docker info 失败：$_" }

Log '----- 迁移脚本完成 -----'

exit 0
