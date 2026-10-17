@REM Sanitized historical wrapper; changed to Audit to prevent unintended deletion.
@echo off
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "\\ad.example.com\NETLOGON\Software\AppCleanup\Remove-UserApps-v1.0.ps1" -Mode Audit
exit /b %ERRORLEVEL%
