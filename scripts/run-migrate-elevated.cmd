@echo off
REM 以管理员权限执行迁移 PowerShell 脚本（会导出并导入 docker-desktop-data 到 D:）
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\新建文件夹\GitHub\DockerDesktop-CN\scripts\migrate-docker-to-d.ps1"
pause
