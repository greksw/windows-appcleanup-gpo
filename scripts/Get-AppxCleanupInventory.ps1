# NEW supplemental helper: user-scope inventory only, no modifications.
# Windows PowerShell 5.1+, use as the interactive user (not SYSTEM).
#Requires -Version 5.1
[CmdletBinding()]
param([string]$NamePattern = '(?i)xbox|skype|copilot|outlook|yandex|music|officehub|maps|people|bing|zunevideo')
$ErrorActionPreference='Stop'
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
if ($identity.User.Value -eq 'S-1-5-18') { throw 'Run as interactive user, not SYSTEM.' }
Get-AppxPackage | Where-Object { $_.Name -match $NamePattern } |
  Select-Object Name, Version, PackageFamilyName, NonRemovable, IsPartOfSystem, InstallLocation |
  Sort-Object Name | Format-Table -AutoSize
