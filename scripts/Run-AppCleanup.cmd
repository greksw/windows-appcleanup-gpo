@echo off
REM PUBLIC EXAMPLE: AUDIT only. Do not run the original Enforce wrapper without a pilot.
REM Adapt this path to an authenticated read-only distribution share.
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "\\ad.example.com\NETLOGON\Software\AppCleanup\Remove-UserApps.ps1" -Mode Audit
exit /b %ERRORLEVEL%
