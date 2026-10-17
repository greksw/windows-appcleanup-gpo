# PUBLIC, ANONYMIZED SOURCE ADAPTATION. NOT PRODUCTION-READY.
# Review target package identities and GPO scope before enabling removal.
# The public variant omits uninstall command lines from diagnostic logs.
#requires -Version 5.1
<#
.SYNOPSIS
  Example AppCleanup v1.4 for Windows 10/11: Audit by default, exact Appx identities only.
.DESCRIPTION
  Run as the INTERACTIVE USER at logon on Windows 10 or Windows 11. Never run as SYSTEM.
  Does not change provisioned packages or machine-wide Win32 applications.
  SystemApps and NonRemovable Appx packages are detected but never forcibly removed.
  Logs to %LOCALAPPDATA%\Example\AppCleanup\cleanup.log.
#>
[CmdletBinding()]
param(
    [ValidateSet('Audit','Enforce')]
    [string]$Mode = 'Audit',

    [switch]$RemovePerUserOneDrive,

    [switch]$IncludeServers,

    # Explicit acknowledgement required by the PUBLIC sample only.
    [switch]$AcknowledgeAppRemoval
)

$ErrorActionPreference = 'Stop'
# This public adaptation is intentionally not a drop-in production logon script.
if ($Mode -eq 'Enforce' -and -not $AcknowledgeAppRemoval) {
    throw 'Public sample: use Audit first; Enforce requires -AcknowledgeAppRemoval after explicit review.'
}

$LogDirectory = Join-Path $env:LOCALAPPDATA 'Example\AppCleanup'
$LogFile = Join-Path $LogDirectory 'cleanup.log'
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

function Write-AppCleanupLog {
    param([string]$Level, [string]$Message)
    $line = '{0} [{1}] [{2}] [{3}] {4}' -f (Get-Date -Format o), $env:COMPUTERNAME, $env:USERNAME, $Level, $Message
    Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
}

try {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if ($Identity.User.Value -eq 'S-1-5-18') {
        Write-AppCleanupLog 'ERROR' 'SYSTEM context detected: per-user operation aborted.'
        exit 10
    }

    $Os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    if (-not $IncludeServers -and [int]$Os.ProductType -ne 1) {
        Write-AppCleanupLog 'SKIP' 'Server OS detected; Workstations-only policy (use -IncludeServers only after explicit RDS approval).'
        exit 0
    }

    $Mutex = New-Object System.Threading.Mutex($false, ('Local\Example-AppCleanup-' + $Identity.User.Value))
    $Acquired = $false
    try {
        $Acquired = $Mutex.WaitOne([TimeSpan]::FromSeconds(2))
        if (-not $Acquired) {
            Write-AppCleanupLog 'SKIP' 'Another cleanup run is active in this user session.'
            exit 0
        }

        # Exact internal package identity only. Never use broad *Office*, *Xbox*, or *Skype* wildcards for deletion.
        # Yandex Music: exact Appx identity confirmed on an anonymized Windows 11 pilot workstation (Windows 11).
        $Targets = @{
            'Microsoft.XboxApp'             = 'Xbox Console Companion'
            'Microsoft.XboxIdentityProvider' = 'Xbox Live identity provider'
            'Microsoft.XboxSpeechToTextOverlay' = 'Xbox speech-to-text overlay'
            'Microsoft.XboxGameOverlay' = 'Xbox Game Overlay'
            'Microsoft.XboxGamingOverlay' = 'Xbox Game Bar'
            'Microsoft.XboxGameCallableUI' = 'Xbox Game Callable UI (Windows SystemApps; inspect protection)'
            'Microsoft.Windows.PeopleExperienceHost' = 'People Experience Host (Windows SystemApps; inspect protection)'
            'Microsoft.SkypeApp'             = 'Skype Store app (not Skype for Business)'
            'Microsoft.MicrosoftOfficeHub'   = 'Microsoft 365 Copilot/Office hub (not Word or Excel)'
            'Microsoft.Copilot'              = 'Microsoft Copilot app'
            'Microsoft.549981C3F5F10'       = 'Cortana (standalone Appx package)'
            'Microsoft.ZuneVideo'            = 'Movies and TV'
            'Microsoft.WindowsMaps'          = 'Maps'
            'Microsoft.People'               = 'People (contacts app)'
            'Microsoft.BingSearch'           = 'Microsoft Bing Search app (not Windows Search)'
            'Microsoft.OutlookForWindows'    = 'New Outlook for Windows (not classic Outlook)'
            'A025C540.Yandex.Music'         = 'Yandex Music (confirmed Appx identity)'
            'Yandex.Music'                   = 'Yandex Music Store app (candidate identity)'
            'Yandex.YandexMusic'             = 'Yandex Music Store app (candidate identity)'
            'YandexMusic'                    = 'Yandex Music Store app (candidate identity)'
        }

        Write-AppCleanupLog 'INFO' ("Begin Version=1.4 Mode={0}, SID={1}, OS={2}, Build={3}" -f $Mode, $Identity.User.Value, $Os.Caption, $Os.BuildNumber)
        $Installed = @(Get-AppxPackage -ErrorAction Stop)
        $Found = 0
        $Removed = 0
        $Failed = 0
        $Unknown = 0
        $Protected = 0
        $SystemAppsRoot = (Join-Path $env:windir 'SystemApps') + '\'

        foreach ($App in $Installed) {
            if ($Targets.ContainsKey($App.Name)) {
                $Found++
                Write-AppCleanupLog 'FOUND' ("Appx Name='{0}' Version='{1}' Family='{2}' Label='{3}'" -f $App.Name, $App.Version, $App.PackageFamilyName, $Targets[$App.Name])

                # Protected Windows system packages cannot be safely removed in a user logon script.
                # Do not attempt to take ownership of C:\Windows\SystemApps or delete app folders.
                $InSystemApps = ($null -ne $App.InstallLocation) -and ([string]$App.InstallLocation).StartsWith($SystemAppsRoot, [StringComparison]::OrdinalIgnoreCase)
                $IsProtected = [bool]$App.NonRemovable -or [bool]$App.IsPartOfSystem -or $InSystemApps
                if ($IsProtected) {
                    $Protected++
                    Write-AppCleanupLog 'PROTECTED' ("Appx {0} remains installed: NonRemovable={1}, IsPartOfSystem={2}, InSystemApps={3}. No forced removal." -f $App.Name, [bool]$App.NonRemovable, [bool]$App.IsPartOfSystem, $InSystemApps)
                    continue
                }
                if ($Mode -eq 'Enforce') {
                    if ($App.Name -eq 'Microsoft.OutlookForWindows' -and @(Get-Process -Name 'olk' -ErrorAction SilentlyContinue).Count -gt 0) {
                        Write-AppCleanupLog 'DEFER' 'New Outlook process olk.exe is running; application not removed.'
                        continue
                    }
                    try {
                        Remove-AppxPackage -Package $App.PackageFullName -ErrorAction Stop
                        $Removed++
                        Write-AppCleanupLog 'REMOVED' ("Appx {0}" -f $App.Name)
                    }
                    catch {
                        $Failed++
                        Write-AppCleanupLog 'ERROR' ("Appx {0}: {1}" -f $App.Name, $_.Exception.Message)
                    }
                }
            }
            elseif ($App.Name -match '(?i)xbox|skype|copilot|officehub|onedrive|yandex|music|cortana|549981C3F5F10|zunevideo|windowsmaps|people|bing|outlook') {
                $Unknown++
                Write-AppCleanupLog 'REVIEW' ("Unrecognized app package (not removed): Name='{0}', Family='{1}'" -f $App.Name, $App.PackageFamilyName)
            }
        }

        # HKCU uninstall registrations are INVENTORY ONLY: silent uninstall options are vendor-specific.
        $UninstallRoots = @(
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )
        foreach ($Root in $UninstallRoots) {
            if (Test-Path -LiteralPath $Root) {
                foreach ($Key in @(Get-ChildItem -LiteralPath $Root -ErrorAction SilentlyContinue)) {
                    try {
                        $Entry = Get-ItemProperty -LiteralPath $Key.PSPath -ErrorAction Stop
                        if ($Entry.DisplayName -match '(?i)^(microsoft onedrive|onedrive|skype|yandex[. -]?music|яндекс[. -]?музыка|microsoft 365 copilot)$') {
                            Write-AppCleanupLog 'REVIEW' ("Win32 HKCU (NOT removed): DisplayName='{0}', Publisher='{1}'" -f $Entry.DisplayName, $Entry.Publisher)
                        }
                    }
                    catch {
                        Write-AppCleanupLog 'WARN' ("HKCU uninstall key unreadable: {0}" -f $Key.PSChildName)
                    }
                }
            }
        }

        # OneDrive desktop is not an Appx package. Opt-in, per-user installation only.
        $OneDriveUserSetup = Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\Update\OneDriveSetup.exe'
        $OneDriveUserExe = Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\OneDrive.exe'
        if ((Test-Path -LiteralPath $OneDriveUserExe) -or (Test-Path -LiteralPath $OneDriveUserSetup)) {
            Write-AppCleanupLog 'FOUND' ("OneDrive per-user files: EXE={0}, Setup={1}" -f (Test-Path -LiteralPath $OneDriveUserExe), (Test-Path -LiteralPath $OneDriveUserSetup))
            if ($Mode -eq 'Enforce' -and $RemovePerUserOneDrive) {
                if (-not (Test-Path -LiteralPath $OneDriveUserSetup)) {
                    Write-AppCleanupLog 'REVIEW' 'Per-user OneDriveSetup.exe unavailable. Machine-wide uninstall requires separate admin workflow.'
                }
                elseif (@(Get-Process -Name OneDrive -ErrorAction SilentlyContinue).Count -gt 0) {
                    Write-AppCleanupLog 'DEFER' 'OneDrive is running; avoid interrupting synchronization. No uninstall performed.'
                }
                else {
                    try {
                        $Proc = Start-Process -FilePath $OneDriveUserSetup -ArgumentList '/uninstall' -PassThru -Wait -WindowStyle Hidden -ErrorAction Stop
                        Write-AppCleanupLog 'INFO' ("OneDrive per-user uninstaller exit code: {0}" -f $Proc.ExitCode)
                        if ($Proc.ExitCode -ne 0) { $Failed++ }
                    }
                    catch {
                        $Failed++
                        Write-AppCleanupLog 'ERROR' ("OneDrive per-user uninstall failed: {0}" -f $_.Exception.Message)
                    }
                }
            }
            else {
                Write-AppCleanupLog 'REVIEW' 'OneDrive per-user not removed: requires -Mode Enforce -RemovePerUserOneDrive and application closed.'
            }
        }

        Write-AppCleanupLog 'INFO' ("Finished: FoundAppx={0}, RemovedAppx={1}, Protected={2}, Failed={3}, UnrecognizedCandidates={4}" -f $Found, $Removed, $Protected, $Failed, $Unknown)
        if ($Failed -gt 0) { exit 1 }
        exit 0
    }
    finally {
        if ($Acquired) { $Mutex.ReleaseMutex() | Out-Null }
        $Mutex.Dispose()
    }
}
catch {
    Write-AppCleanupLog 'FATAL' $_.Exception.Message
    exit 1
}
