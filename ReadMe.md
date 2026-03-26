# Docker Desktop汉化包
本仓库提供最新版本Docker Desktop 汉化包。

Docker汉化  Docker中文版  Docker Desktop汉化 Docker Windows Docker MAC

~~Windows arm 用户只能使用脚本进行汉化。这个架构的汉化包本仓库不予提供。~~

**注意: 自 4.39 版本后, 汉化 Asar 包会跟随 DockerDesktop 安装程序一起发布在 [Releases](https://github.com/asxez/DockerDesktop-CN/releases) 页面**
<br>

<font color=red>已发布汉化脚本，有需要的自行前往，但请遵守仓库相关许可，否则后果自负。</font>

<font color=red><big><u>**注意：本仓库仍然会发布各个版本的汉化包！！！**</u></big></font>

<font color=red>汉化脚本仓库【 https://github.com/asxez/DDCS 】</font>

## 下载指南

- Windows
  - 使用 Intel/AMD 的 x64 芯片（**较为普遍**），则下载 DockerDesktop-x.x.x-Windows-x86.exe（本体）和 app-Windows-x86.asar（汉化包）
  - 使用 arm 芯片（**较为稀有**），则下载 DockerDesktop-x.x.x-Windows-arm.exe（本体）和 app-Windows-arm.asar（汉化包）
- Mac
  - 使用 M 系列芯片（**新款**），则下载 DockerDesktop-x.x.x-Mac-apple.dmg（本体）和 app-Mac-apple.asar （汉化包）
  - 使用 Intel x64 芯片（**2020前旧款**），则下载 DockerDesktop-x.x.x-Mac-intel.dmg（本体）和 app-Mac-intel.asar （汉化包）
- Linux 
  - Ubuntu/Debian  
    - 使用 Intel/AMD 的 x64 芯片（**较为普遍**），则下载 DockerDesktop-x.x.x-Debian-x86.deb（本体）和 app-Debian-x86.asar（汉化包）
    - 使用 arm 芯片（**较为稀有**），暂不支持
  - Fedora/Arch/RHEL 暂不支持

## 使用方法
1. 关闭Docker Desktop
2. 在Docker安装目录找到app.asar文件并将其备份，防止出现意外。
   - Windows下默认为`C:\Program Files\Docker\Docker\frontend\resources`
   - Macos下默认为`/Applications/Docker.app/Contents/MacOS/Docker Desktop.app/Contents/Resources`
   - Ubuntu/Debian下默认为`/opt/docker-desktop/resources`
3. 将从本仓库下载的asar文件改名为app.asar后替换原文件

### Windows 一键安装脚本

- 本仓库包含一个用于 Windows 的自动安装脚本：install-zh-windows.ps1。
- 用法（以管理员身份运行 PowerShell）：

  1. 将下载的汉化包 `app-Windows-x86.asar` 放到仓库根目录，或指定完整路径。
  2. 以管理员身份打开 PowerShell，运行：

     .\install-zh-windows.ps1 -AsarPath ".\app-Windows-x86.asar"

- 脚本会备份原始 `app.asar`（添加时间戳）、替换为汉化包并尝试重启 Docker Desktop。
- 如果脚本找不到 Docker 的资源目录，会提示手动指定或手动替换。

### 自动下载并安装（推荐）

- 本仓库附带 `auto-install-zh.ps1` 脚本，它会尝试检测本机的 Docker Desktop 版本和系统架构，
  从本仓库的 Releases 中下载匹配的 `asar` 资产并调用安装脚本完成替换。
- 用法（以管理员权限在仓库根目录运行）：

  1. 直接运行自动下载并安装：

    .\auto-install-zh.ps1

  2. 指定本地 asar 并安装：

    .\auto-install-zh.ps1 -AsarPath ".\app-Windows-x86.asar"

  3. 指定架构（可选）：

    .\auto-install-zh.ps1 -Arch arm

- 脚本会在替换前备份原始 `app.asar`，并在安装后尝试重启 Docker Desktop。

## 最新版本效果图
### Windows
![](images/4.38/w1.png)
![](images/4.38/w2.png)

### Mac
![img_1.png](images/4.38/img_1.png)
![img.png](images/4.38/img.png)

## 更多问题？
有问题的可以扫码加群咨询。
![](images/1.jpg)

## 仓库已打包的汉化包

- 我已在本地从当前安装的 Docker Desktop 资源目录导出并打包：

- 文件：`app-Windows-x86-4.66.0.222299.asar.zip`
- 路径：仓库根目录（[release-draft-4.66.0-zh.md](release-draft-4.66.0-zh.md) 包含 SHA256 校验）

- 你可以直接使用 `install-zh-windows.ps1` 安装或将此 `.zip` 上传到 GitHub Releases 作为发行资产。

## Stars
如果你觉得本仓库对你有用的话，请点上一颗star。
