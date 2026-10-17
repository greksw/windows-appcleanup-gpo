# Security model and limitations

| Area | Source behavior |
| --- | --- |
| Principal | Current interactive user; returns code 10 under SYSTEM |
| Scope | Current-user Appx only, neither provisioned packages nor machine-wide Win32 apps |
| Default | Audit; original production CMD used Enforce; public CMD uses Audit |
| SystemApps | Skips `NonRemovable`, `IsPartOfSystem`, packages under `Windows\SystemApps` |
| Servers | Skips by default; `-IncludeServers` needs separate RDS review |
| New Outlook | Defers removal while `olk.exe` runs |
| OneDrive | Separate per-user uninstall opt-in, never a blanket machine-wide uninstall |
| HKCU Uninstall | Inventory only; public adaptation omits uninstall command-line logging |
| User scope | GPO OU/security filtering, not built-in username suffix checks |

## Caveats

- Business software may depend on Xbox identity, new Outlook, Copilot, or other listed packages; inventory is not evidence that removal is safe.
- The `Local\<SID>` named mutex only serializes attempts within its Windows session namespace. Multiple interactive/RDS sessions may not be mutually exclusive.
- Return code `0` may mean a deliberate skip, **not a successful removal**.
- Windows updates or user registration can restore removed packages. The script does not remove provisioned packages for new users.
- There is no general rollback implementation or full-fleet compliance verification in the supplied source.
- Original logs could contain hosts, usernames, SIDs and HKCU uninstall command strings; the public adaptation removes the latter but still requires redaction of exported logs.
