@echo off
REM 以管理员运行此脚本以设置 WinHTTP 代理并把结果输出到 Temp 文件
netsh winhttp set proxy 127.0.0.1:17788
netsh winhttp show proxy > "%LOCALAPPDATA%\Temp\winhttp_after.txt"
type "%LOCALAPPDATA%\Temp\winhttp_after.txt"
pause
