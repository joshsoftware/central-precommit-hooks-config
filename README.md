# Company Centralized Pre-Commit Hook Configuration

This repository contains scripts that configure Git to use the company's centralized **pre-commit hook**.

The scripts do **not install Git, curl, Python, Ruby, Node.js, or any other development software**.

They configure Git on the developer's machine so that Git uses a centralized pre-commit hook from:

```text
~/.company-git-hooks/pre-commit
```

The configuration is applied through Git's global:

```text
core.hooksPath
```

Once configured, developers do not need to manually copy the pre-commit hook into individual repositories.

---

## 1. How It Works

The configuration process is:

```text
Developer Machine
│
├── Git Global Configuration
│   └── core.hooksPath
│       │
│       ▼
│   ~/.company-git-hooks
│
└── ~/.company-git-hooks/
    └── pre-commit
             │
             │ HTTPS
             ▼
    Company Security Service
```

The configuration script:

1. Verifies that Git is available.
2. Verifies that `curl` is available.
3. Checks the existing global `core.hooksPath`.
4. Creates the centralized hooks directory.
5. Downloads the company's centralized pre-commit hook.
6. Performs basic validation of the downloaded hook.
7. Places the hook in the centralized hooks directory.
8. Makes the hook executable on Linux/macOS.
9. Configures Git's global `core.hooksPath`.
10. Verifies the Git configuration and hook.
11. Registers the developer's Git identity with the security service when configured.

### Important

The script is a **configuration/bootstrap utility**.

It does not install a new development tool or Git itself. It configures the developer's existing Git installation and places the company pre-commit hook in the user's home directory.

---

# 2. Why `core.hooksPath`?

Normally, Git looks for hooks inside each repository:

```text
repo-1/.git/hooks/
repo-2/.git/hooks/
repo-3/.git/hooks/
```

This would require the company pre-commit hook to be configured separately for every repository.

Instead, Git's `core.hooksPath` can be configured globally:

```text
~/.company-git-hooks
```

Git will then use:

```text
~/.company-git-hooks/pre-commit
```

as the pre-commit hook for repositories that do not override `core.hooksPath` locally.

### Benefits

* No manual copying of the hook into every repository.
* One centralized hook location per developer machine.
* Existing repositories can use the configuration.
* New repositories automatically use the configuration.
* Re-running the configuration script can update the centralized hook.
* Developers do not need to configure every repository individually.
* DevOps can maintain the centralized hook endpoint.

---

# 3. Repository Contents

```text
central-precommit-hooks-path-poc/
├── README.md
├── configure.sh
└── configure.ps1
```

### `configure.sh`

Used on:

* Linux
* macOS

### `configure.ps1`

Used on:

* Windows PowerShell

---

# 4. Prerequisites

The configuration scripts expect the following software to already exist on the developer's machine:

### Linux / macOS

* Git
* curl
* Bash

### Windows

* Git
* curl
* PowerShell

The scripts do not automatically install these dependencies.

---

# 5. Configuration — Linux / macOS

Make the script executable:

```bash
chmod +x configure.sh
```

Run:

```bash
./configure.sh
```

The script configures:

```text
~/.company-git-hooks/
└── pre-commit
```

and:

```text
git config --global core.hooksPath ~/.company-git-hooks
```

---

# 6. Configuration — Windows

Run the PowerShell script:

```powershell
.\configure.ps1
```

If PowerShell's execution policy prevents execution:

```powershell
powershell -ExecutionPolicy Bypass -File .\configure.ps1
```

The PowerShell script performs the same logical configuration as the Linux/macOS script.

---

# 7. Installation vs Configuration

This project intentionally uses the term **configuration** rather than **installation**.

The scripts do not install a new software package or development framework.

The configuration process consists of:

```text
Existing Git installation
        │
        ▼
Configure Git global core.hooksPath
        │
        ▼
Create ~/.company-git-hooks
        │
        ▼
Download company pre-commit hook
        │
        ▼
Configure Git to use that hook
```

Therefore:

```text
configure.sh
configure.ps1
```

are used instead of:

```text
install.sh
install.ps1
```

---

# 8. Centralized Hook Location

After successful configuration, the hook is stored in:

```text
~/.company-git-hooks/pre-commit
```

On Linux/macOS this normally resolves to:

```text
/home/<username>/.company-git-hooks/pre-commit
```

On Windows it is created under the user's home directory.

The hook is **not copied into individual repositories**.

For example, this is not required:

```text
repo-1/.git/hooks/pre-commit
repo-2/.git/hooks/pre-commit
repo-3/.git/hooks/pre-commit
```

Instead, the developer has one centralized hook:

```text
~/.company-git-hooks/pre-commit
```

---

# 9. Git Configuration

After configuration, verify:

```bash
git config --global --get core.hooksPath
```

Expected:

```text
/home/<username>/.company-git-hooks
```

You can also verify where the setting originated:

```bash
git config --show-origin --global --get core.hooksPath
```

---

# 10. Verify the Active Hooks Directory

For a repository, run:

```bash
git rev-parse --git-path hooks
```

If the global company configuration is active, the result should point to:

```text
/home/<username>/.company-git-hooks
```

This confirms that Git is using the centralized hooks directory instead of:

```text
<repository>/.git/hooks
```

---

# 11. Existing Global `core.hooksPath`

The configuration scripts intentionally do **not blindly overwrite** an existing global `core.hooksPath`.

There are three primary scenarios.

## Scenario 1 — No existing global configuration

If:

```bash
git config --global --get core.hooksPath
```

returns nothing, the configuration script will configure:

```text
~/.company-git-hooks
```

---

## Scenario 2 — Company hooks directory is already configured

If the existing configuration already points to:

```text
~/.company-git-hooks
```

the script continues.

It can download the current centralized hook and repair/update the existing configuration.

This allows the same configuration script to be executed again when the centralized hook is updated.

---

## Scenario 3 — Another hooks directory is configured

For example:

```text
/home/developer/.my-existing-hooks
```

The script will stop instead of overwriting the existing configuration.

This is intentional.

An existing `core.hooksPath` may be required by another development workflow.

The developer should contact the Manager or DevOps team before changing the existing configuration.

---

# 12. Repository-Specific `core.hooksPath`

A repository can override the global `core.hooksPath`.

For example:

```bash
git config --local core.hooksPath .project-hooks
```

In that case, Git will use:

```text
<repository>/.project-hooks
```

instead of:

```text
~/.company-git-hooks
```

You can verify the effective configuration with:

```bash
git config --show-origin --get core.hooksPath
```

Example:

```text
file:.git/config    .project-hooks
```

### Important

The configuration scripts do not modify repository-local `core.hooksPath`.

If a project intentionally has its own hooks configuration, the centralized company hook will not automatically override it.

---

# 13. Hook Updates

The centralized hook is downloaded from the company's security service when the configuration script is executed.

For example:

```text
Initial configuration
        │
        ▼
pre-commit V1
        │
        │ Run configure.sh / configure.ps1 again
        ▼
pre-commit V2
```

The updated hook is stored at:

```text
~/.company-git-hooks/pre-commit
```

Repositories using the global company `core.hooksPath` automatically use the updated hook.

No repository-by-repository hook replacement is required.

---

# 14. Important Git Behavior

The centralized pre-commit hook is not expected to appear inside:

```text
.git/hooks/
```

For example, after:

```bash
git init
```

Git may create its standard sample hooks:

```text
.git/hooks/
├── applypatch-msg.sample
├── commit-msg.sample
├── fsmonitor-watchman.sample
├── post-update.sample
├── pre-applypatch.sample
├── pre-commit.sample
├── pre-merge-commit.sample
├── pre-push.sample
├── pre-rebase.sample
├── pre-receive.sample
├── prepare-commit-msg.sample
├── push-to-checkout.sample
└── update.sample
```

The company pre-commit hook can remain outside the repository:

```text
~/.company-git-hooks/pre-commit
```

Git determines the active hooks directory using:

```bash
git rev-parse --git-path hooks
```

---

# 15. Testing the Configuration

After running the configuration script, create a temporary repository:

```bash
cd /tmp
rm -rf central-hooks-test
mkdir central-hooks-test
cd central-hooks-test
```

Initialize Git:

```bash
git init
```

Verify the hooks directory:

```bash
git rev-parse --git-path hooks
```

Expected:

```text
/home/<username>/.company-git-hooks
```

Create a test file:

```bash
echo "centralized hook test" > test.txt
```

Stage it:

```bash
git add test.txt
```

Commit:

```bash
git commit -m "Test centralized pre-commit hook"
```

The centralized pre-commit hook should execute during the commit.

---

# 16. Verify the Hook Directly

Linux/macOS:

```bash
ls -l ~/.company-git-hooks/pre-commit
```

Verify that it is executable:

```bash
test -x ~/.company-git-hooks/pre-commit && echo "Executable" || echo "Not executable"
```

Inspect the hook:

```bash
cat ~/.company-git-hooks/pre-commit
```

---

# 17. Installation Registration

After configuring the hook, the scripts attempt to register the developer's Git identity with the company security service.

The registration uses:

```text
Git user.name
Git user.email
```

These values can be checked using:

```bash
git config --get user.name
git config --get user.email
```

If either value is missing, the hook configuration can still succeed, but registration is skipped.

Configure them with:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"
```

The registration request is separate from the actual Git hook configuration.

If registration fails after the hook has been configured successfully, the hook remains installed and active.

---

# 18. Security Behavior

The centralized pre-commit hook communicates with the company's security service over HTTPS.

The hook evaluates staged Git changes according to the company's configured security policy.

The commit can be:

```text
Allowed
```

or:

```text
Blocked
```

depending on the security scan result.

If the security service cannot be reached, the hook follows the configured security policy.

Developers should contact the DevOps team if they experience unexpected scanning, connectivity, or blocking behavior.

---

# 19. Developer Responsibility

The intended developer workflow is simple.

### Linux / macOS

```bash
./configure.sh
```

### Windows

```powershell
.\configure.ps1
```

After successful configuration:

* No manual hook copying is required.
* No per-repository hook configuration is required.
* No manual `chmod` is required for individual repository hooks.
* Existing repositories using the global configuration can use the centralized hook.
* New repositories can use the centralized hook automatically.
* Re-running the configuration script can update the centralized hook.

---

# 20. What This POC Demonstrates

This POC demonstrates whether Git's global:

```text
core.hooksPath
```

can be used as a centralized mechanism for distributing and managing a company pre-commit hook on developer machines.

The POC specifically addresses:

1. Centralized hook location.
2. Global Git configuration.
3. Existing repository compatibility.
4. New repository behavior.
5. Hook update behavior.
6. Existing `core.hooksPath` handling.
7. Repository-level `core.hooksPath` overrides.
8. Linux/macOS configuration.
9. Windows configuration.
10. Basic installation validation.
11. Developer registration with the centralized security service.

---

# 21. Limitations and Considerations

The global `core.hooksPath` approach has important considerations.

### Repository-local override

A repository can override the global configuration:

```bash
git config --local core.hooksPath <path>
```

Such a repository will not use the company global hook.

### User-level configuration

The configuration is applied to the developer's Git environment.

Another user account on the same machine would require its own configuration.

### Bypass

Git allows users to bypass client-side hooks with:

```bash
git commit --no-verify
```

Therefore, a client-side pre-commit hook should not be considered the only security enforcement mechanism for organization-wide security requirements.

For mandatory enforcement, server-side or CI/CD controls should be considered as a complementary layer.

### Existing developer workflows

Some developers may already use:

```text
core.hooksPath
```

for their own hooks or development tooling.

The configuration scripts intentionally detect and protect these existing configurations.

### Hook execution environment

The actual centralized hook must remain compatible with the operating systems, Git versions, shell environments, network requirements, and security-service behavior supported by the organization.

---

# 22. Troubleshooting

## Git is not installed

Verify:

```bash
git --version
```

Install/configure Git according to the organization's standard workstation setup, then run the configuration script again.

---

## curl is not installed

Verify:

```bash
curl --version
```

Install/configure `curl` according to the organization's standard workstation setup, then run the configuration script again.

---

## Another `core.hooksPath` is configured

Check:

```bash
git config --global --get core.hooksPath
```

If it points to another directory, do not change it without checking with the Manager or DevOps team.

---

## Hook is not executing

First check:

```bash
git config --global --get core.hooksPath
```

Then, from the repository:

```bash
git rev-parse --git-path hooks
```

Verify that the hook exists:

```bash
ls -l ~/.company-git-hooks/pre-commit
```

On Linux/macOS:

```bash
test -x ~/.company-git-hooks/pre-commit && echo "Executable" || echo "Not executable"
```

---

## Repository is not using the centralized hook

Check whether the repository has its own configuration:

```bash
git config --local --get core.hooksPath
```

If a value is returned, the repository-local configuration is overriding the global configuration.

Check all relevant configuration sources:

```bash
git config --show-origin --get-all core.hooksPath
```

---

## Check the installed hook

Linux/macOS:

```bash
cat ~/.company-git-hooks/pre-commit
```

Windows PowerShell:

```powershell
Get-Content "$HOME\.company-git-hooks\pre-commit"
```

---

# 23. Recommended POC Validation Matrix

The following scenarios should be tested before considering the POC successful:

| Test | Expected Result |
|---|---|
| Git available | Configuration continues |
| Git unavailable | Configuration stops |
| curl available | Configuration continues |
| curl unavailable | Configuration stops |
| No existing `core.hooksPath` | Company path is configured |
| Existing company `core.hooksPath` | Configuration continues |
| Existing different `core.hooksPath` | Configuration stops |
| Hook download succeeds | Hook is configured |
| Hook download fails | Existing Git configuration is not intentionally replaced |
| Empty hook downloaded | Configuration stops |
| Invalid hook downloaded | Configuration stops |
| Hook file created | File exists in centralized location |
| Linux/macOS hook executable | Hook is executable |
| Global configuration verified | Company path is returned |
| New Git repository | Global hook is used |
| Existing Git repository | Global hook is used if no local override exists |
| Repository-local `core.hooksPath` | Local path takes precedence |
| Hook update | Existing repositories use updated hook |
| Missing Git identity | Hook configuration succeeds; registration is skipped |
| Registration failure | Hook remains configured |
| Commit test | Centralized pre-commit hook executes |

---

# 24. Support

If there are any issues, doubts, or unexpected behavior during configuration or while using the centralized pre-commit hook, please contact the **DevOps team**.
