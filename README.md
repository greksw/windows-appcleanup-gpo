# Windows AppCleanup GPO — user-scoped Appx inventory and cleanup

[Русский](README.ru.md) · [Changelog](CHANGELOG.md) · [GPO setup](docs/gpo-setup.md)

An October 2026 case study of controlling selected **current-user Appx packages** on Windows 10/11 with **User Configuration GPO → logon script → Windows PowerShell 5.1**. Source snapshots v1.0, v1.3, v1.4 and three corresponding CMD launchers were supplied for review.

**Public source adaptation, not a drop-in production script.** Internal identifiers have been redacted, historical `Enforce` execution is disabled, the current sample requires `-AcknowledgeAppRemoval` for enforcement, and the published CMD wrapper defaults to `Audit` whereas the operational original used `Enforce`. No post-redaction Windows execution has been performed.

## Execution and scope

- `-Mode Audit` (default) inventories and logs without removing apps.
- `-Mode Enforce` uses exact Appx `Name` identities and `Remove-AppxPackage` in the **interactive user context** only; the public sample additionally requires explicit acknowledgement.
- Never run under `SYSTEM`. Windows Server is excluded unless `-IncludeServers` is intentionally supplied after separate RDS review.
- Skips `NonRemovable` / `IsPartOfSystem` packages and any package installed under `Windows\SystemApps`.
- Defers removal of new Outlook if `olk.exe` is active; inventory-only HKCU uninstall entries do not trigger Win32 application removal.
- OneDrive per-user uninstall is a separate opt-in and will defer while OneDrive is running.
- Does not modify provisioned apps for new profiles, the Windows image, machine-wide Win32 apps, Office desktop or classic Outlook.

**Do not infer that all similarly named packages are safe to remove.** Several historic identities are candidates; confirm exact identities per OS build and test business workflows. The reported Yandex Music identity was verified on one pilot workstation only.

GPO scoping is external: OU, security filtering, inheritance, and optionally loopback processing. The script itself does not apply username-suffix or organizational account-exception rules.

## Layout

- `scripts/Remove-UserApps.ps1`: sanitized current v1.4 with public enforcement guard.
- `scripts/Run-AppCleanup.cmd`: **Audit-only by default** example launcher.
- `scripts/Get-AppxCleanupInventory.ps1`: new read-only helper.
- `history/`: sanitized v1.0 / v1.3 / v1.4 and CMD stages, enforcement disabled.
- `docs/`: RU/EN deployment and risk/validation notes.
- `.github/workflows/ci.yml`: syntax and accidental identifier checks only.

## License

No reuse license has been selected. Public availability does not imply unrestricted redistribution rights.
