# modify-and-reimport-dd.ps1
# 导出 docker-desktop-data，修改 /etc/docker/daemon.json 与 systemd 代理配置，重新导入到 D:\DockerData
$ErrorActionPreference = 'Stop'
$LogFile = 'D:\DockerData\modify-dd.log'
function Log($s){ $t=(Get-Date).ToString('s'); "$t $s" | Out-File -FilePath $LogFile -Append -Encoding UTF8; Write-Output $s }

Log '=== 开始 modify-and-reimport-dd ==='

$work = 'D:\DockerData'
$tar = Join-Path $work 'docker-desktop-data.tar'
$modtar = Join-Path $work 'docker-desktop-data-mod.tar'
$extract = Join-Path $work 'ddroot'
$importPath = 'D:\DockerData\docker-desktop-data'

if (-not (Test-Path 'D:\')) { Log 'ERROR: D: 驱动器不存在，取消'; exit 10 }
New-Item -ItemType Directory -Path $work -Force | Out-Null

Log '停止 Docker Desktop 并 shutdown WSL'
Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue | ForEach-Object { Log "Stopping PID $($_.Id)"; Stop-Process -Id $_.Id -Force }
wsl --shutdown
Start-Sleep -Seconds 3

# 确认 distro 名称
$ls = (wsl --list --verbose) 2>&1 | Out-String
Log "wsl list: $ls"
if ($ls -notmatch 'docker-desktop-data') { Log 'ERROR: docker-desktop-data 不存在，取消'; exit 11 }

# 导出
if (Test-Path $tar) { Remove-Item -Force -Path $tar }
Log "开始导出 docker-desktop-data 到 $tar"
$exp = wsl --export docker-desktop-data "$tar" 2>&1 | Out-String
Log $exp
if (-not (Test-Path $tar)) { Log 'ERROR: 导出失败，未生成 tar'; exit 12 }

# 解压到 $extract
if (Test-Path $extract) { Remove-Item -Recurse -Force $extract }
New-Item -ItemType Directory -Path $extract -Force | Out-Null
Log "解压 tar 到 $extract（可能耗时）"
# 使用系统 tar 解包
& tar -xf "$tar" -C "$extract" 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8
Log '解压完成'

# 写入 /etc/docker/daemon.json
$etcDocker = Join-Path $extract 'etc\docker'
if (-not (Test-Path $etcDocker)) { New-Item -ItemType Directory -Path $etcDocker -Force | Out-Null }
$daemonJson = @'
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ]
}
'@
$daemonPath = Join-Path $etcDocker 'daemon.json'
Set-Content -Path $daemonPath -Value $daemonJson -Encoding UTF8
Log "已写入 $daemonPath"

# 尝试写入 systemd drop-in 以设置守护进程环境变量（若 systemd 存在则生效）
$systemdDir = Join-Path $extract 'etc\systemd\system\docker.service.d'
if (-not (Test-Path $systemdDir)) { New-Item -ItemType Directory -Path $systemdDir -Force | Out-Null }
$httpProxyConf = @'
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:17788"
Environment="HTTPS_PROXY=http://127.0.0.1:17788"
Environment="NO_PROXY=127.0.0.1,localhost,::1"
'@
$httpProxyPath = Join-Path $systemdDir 'http-proxy.conf'
Set-Content -Path $httpProxyPath -Value $httpProxyConf -Encoding UTF8
Log "已写入 $httpProxyPath"

# 重新打包为 mod tar
if (Test-Path $modtar) { Remove-Item -Force $modtar }
Log "开始打包修改后的根文件系统到 $modtar（可能耗时）"
& tar -C "$extract" -cf "$modtar" . 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8
if (-not (Test-Path $modtar)) { Log 'ERROR: 重新打包失败'; exit 13 }
Log '打包完成'

# 注销并重新导入
Log '注销原 docker-desktop-data...'
wsl --unregister docker-desktop-data 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8
Start-Sleep -Seconds 2

Log "导入为 docker-desktop-data 到路径 $importPath"
wsl --import docker-desktop-data "$importPath" "$modtar" --version 2 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8

Log '启动 Docker Desktop'
Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
Log '等待初始化 20s'
Start-Sleep -Seconds 20

# 输出 docker info 到日志
Log '写入 docker info 到日志'
try { docker info --format '{{json .}}' 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { Log "docker info 执行失败：$_" }

# 测试拉取镜像
Log '尝试 docker pull hello-world'
try { docker pull hello-world 2>&1 | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { Log "docker pull 失败：$_" }

Log '=== 完成 modify-and-reimport-dd ==='
exit 0
