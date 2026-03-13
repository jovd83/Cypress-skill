# Multi-Scope Conflict Examples

Use this reference when the same task label appears in more than one workspace, branch, or storage location and you need deterministic disambiguation.

## 1. Same Task Label Across Branches

Example:

- Active scope A
  - `Task label: checkout-auth-fix`
  - `Workspace root: C:\projects\shop-app`
  - `Branch: fix/auth-refresh`
- Active scope B
  - `Task label: checkout-auth-fix`
  - `Workspace root: C:\projects\shop-app`
  - `Branch: release/hotfix-auth`

Use:

```powershell
powershell -NoProfile -File .\scripts\find-handover.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/auth-refresh"
```

## 2. Same Task Label Across Workspace Clones

Example:

- Active scope A
  - `Task label: cart-regression`
  - `Workspace root: C:\projects\shop-app`
  - `Branch: feature/cart`
- Active scope B
  - `Task label: cart-regression`
  - `Workspace root: D:\scratch\shop-app`
  - `Branch: feature/cart`

Use:

```powershell
powershell -NoProfile -File .\scripts\overview-handovers.ps1 -TaskLabel "cart-regression"
```

Then rerun with the intended `-WorkspaceRoot`.

## 3. Same Scope Exists In Active And Archive

Example:

- Active scope
  - `Task label: checkout-auth-fix`
  - `Workspace root: C:\projects\shop-app`
  - `Branch: fix/auth-refresh`
- Archived scope
  - `Task label: checkout-auth-fix`
  - `Workspace root: C:\projects\shop-app`
  - `Branch: fix/auth-refresh`

Inspect first:

```powershell
powershell -NoProfile -File .\scripts\doctor-handover.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/auth-refresh"
```

If the active copy is correct, resolve the duplication by keeping active:

```powershell
powershell -NoProfile -File .\scripts\resolve-handover-location-conflict.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/auth-refresh" -KeepLocation active
```

If the archived copy is the source of truth, keep archive instead:

```powershell
powershell -NoProfile -File .\scripts\resolve-handover-location-conflict.ps1 -TaskLabel "checkout-auth-fix" -WorkspaceRoot "C:\projects\shop-app" -Branch "fix/auth-refresh" -KeepLocation archive
```
