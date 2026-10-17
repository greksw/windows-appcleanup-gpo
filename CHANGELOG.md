# Reconstructed source history

These changes are derived from the supplied files, **not historical Git commits**. Every public snapshot is redacted and has not been re-executed on Windows. Historical samples prevent accidental enforcement.

## v1.4 — specific Yandex Music identity

- Added the exact Appx name `A025C540.Yandex.Music` verified on one Windows 11 pilot host.
- Updated version/comment metadata from `1.3` to `1.4`.
- Retained the v1.3 protected-package and Outlook process handling.

## v1.3 — guarded Appx list

- Expanded the exact-name list with Xbox overlays, Copilot/Cortana, Office Hub, new Outlook, Maps/People/Bing and protected SystemApps candidates.
- Added `NonRemovable`, `IsPartOfSystem` and `Windows\SystemApps` checks; logs `PROTECTED` without attempting forced deletion.
- Defers new Outlook removal when `olk.exe` is active.
- Expanded start/end operational logs with version, SID, OS build and protected count.

## v1.0 — baseline current-user inventory/removal

- `Audit` by default, exact Appx `Name` matching for `Remove-AppxPackage` in `Enforce` mode.
- Rejects `SYSTEM`, skips servers by default, user mutex, per-user logging.
- HKCU Win32 entries are inventory only, separate opt-in for per-user OneDrive.

## CMD wrapper history

The three real launchers ran v1.0, v1.3, v1.4 with `-Mode Enforce`. Public copies use **Audit** intentionally and are not byte-identical.

## Public-only modifications

- Replaced internal domain, organization, host names and paths.
- Removed `UninstallString` / `QuietUninstallString` from diagnostic logs to avoid leaking sensitive command-line arguments.
- Current sample requires explicit enforcement acknowledgement; historical samples disable enforcement altogether.
