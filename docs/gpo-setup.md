# User Group Policy deployment

This describes the pilot architecture, not a universal unwanted-app removal policy.

1. Link a **User Configuration GPO** to appropriate interactive-user OUs, with scoped security filtering. Real deployments may use local-workstation account conventions with explicit exceptions. Do not hardcode identity suffix rules or real user accounts into public scripts.
2. Invoke the CMD wrapper via **User Configuration → Policies → Windows Settings → Scripts (Logon)** under the signing-in user's token, **never SYSTEM**.
3. Pilot **Audit** mode, review exact Appx names and protected-package flags, validate business dependencies, and only then decide whether removal is acceptable.
4. Logon script processing occurs at sign-in, not retroactively inside existing sessions. Exclude RDS unless independently reviewed; do not enable `-IncludeServers` by default.
5. Protect write access to NETLOGON sources. `ExecutionPolicy Bypass` is not a security/trust boundary.

On a test client:

```powershell
whoami /user
gpresult /scope user /r
Get-AppxPackage | Select-Object Name, PackageFamilyName, NonRemovable
Get-Content "$env:LOCALAPPDATA\Example\AppCleanup\cleanup.log" -Tail 40
```

Logs include usernames, hosts and SIDs. Redact before sharing. The public example defaults to Audit and does not make machine-wide changes.
