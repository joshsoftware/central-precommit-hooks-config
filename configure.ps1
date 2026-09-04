# ============================================================================
# Company Centralized Pre-Commit Hook Configurator
#
# Windows / PowerShell
#
# This script does not install any software or Git packages.
# It only configures Git and places the company-managed hook locally.
# ============================================================================

$ErrorActionPreference = "Stop"

# ============================================================================
# Configuration
# ============================================================================

$HooksDirectory = Join-Path $HOME ".company-git-hooks"
$HookFile = Join-Path $HooksDirectory "pre-commit"

$CentralHookUrl = "https://code-security.joshsoftware.com/installations/pre-commit"
$RegistrationUrl = "https://code-security.joshsoftware.com/installations/register"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Separator {
    Write-Host ""
    Write-Host "==========================================================================" 
}

function Fail-Configuration {
    param (
        [string]$Message
    )

    Write-Host ""
    Write-Host "ERROR"
    Write-Host "-----"
    Write-Host $Message
    Write-Host ""
    Write-Host "Configuration was not completed."
    Write-Host ""

    exit 1
}

# ============================================================================
# Resolve Expected Hooks Directory
# ============================================================================

try {
    $ResolvedExpectedHooksDirectory = [System.IO.Path]::GetFullPath($HooksDirectory)
}
catch {
    Fail-Configuration "Unable to resolve the company Git hooks directory:`n$HooksDirectory"
}

# ============================================================================
# Header
# ============================================================================

Write-Separator
Write-Host "Company Centralized Pre-Commit Hook Configurator"
Write-Separator
Write-Host ""
Write-Host "This configurator will configure Git to use the company"
Write-Host "centralized pre-commit hook through Git core.hooksPath."
Write-Host ""
Write-Host "The hook will be stored in one centralized location on this machine"
Write-Host "and will be used by Git repositories that do not override"
Write-Host "core.hooksPath locally."
Write-Host ""
Write-Host "No software or Git package will be installed."
Write-Host ""

# ============================================================================
# Verify Git
# ============================================================================

$GitCommand = Get-Command git -ErrorAction SilentlyContinue

if (-not $GitCommand) {
    Fail-Configuration "Git was not found on this machine.`n`nPlease install/configure Git and run this configurator again."
}

try {
    $GitVersion = (& git --version 2>&1).ToString().Trim()
}
catch {
    Fail-Configuration "Git was detected but could not be executed.`n`nPlease verify your Git installation and PATH configuration."
}

Write-Host "Git detected:"
Write-Host "  $GitVersion"
Write-Host ""

# ============================================================================
# Verify curl
# ============================================================================

$CurlCommand = Get-Command curl.exe -ErrorAction SilentlyContinue

if (-not $CurlCommand) {
    Write-Host "curl was not found."
    Write-Host ""
    Write-Host "Please install curl using your approved package manager"
    Write-Host "or install a current version of Git for Windows."
    Write-Host ""
    Write-Host "The configurator will not modify the developer's system"
    Write-Host "by automatically installing curl."
    Write-Host ""

    Fail-Configuration "curl is required to download the centralized pre-commit hook."
}

try {
    $CurlVersion = (& curl.exe --version 2>&1 | Select-Object -First 1).ToString().Trim()
}
catch {
    Fail-Configuration "curl was detected but could not be executed."
}

Write-Host "curl detected:"
Write-Host "  $CurlVersion"
Write-Host ""

# ============================================================================
# Check Existing Git core.hooksPath
# ============================================================================

try {
    $ExistingHooksPath = (& git config --global --get core.hooksPath 2>$null).Trim()
}
catch {
    $ExistingHooksPath = ""
}

if ([string]::IsNullOrWhiteSpace($ExistingHooksPath)) {

    Write-Host "No Git core.hooksPath is currently configured."
    Write-Host "The company Git hooks path will be configured."
    Write-Host ""

}
else {

    Write-Host "Existing Git core.hooksPath:"
    Write-Host "  $ExistingHooksPath"
    Write-Host ""

    try {
        $ResolvedExistingHooksPath = [System.IO.Path]::GetFullPath(
            [Environment]::ExpandEnvironmentVariables($ExistingHooksPath)
        )
    }
    catch {
        $ResolvedExistingHooksPath = $ExistingHooksPath
    }

    if ($ResolvedExistingHooksPath.TrimEnd('\') -ne $ResolvedExpectedHooksDirectory.TrimEnd('\')) {

        Write-Host "The existing core.hooksPath points to a different location:"
        Write-Host "  $ExistingHooksPath"
        Write-Host ""

        Write-Host "Expected company hooks directory:"
        Write-Host "  $HooksDirectory"
        Write-Host ""

        Fail-Configuration "Git core.hooksPath is already configured to another location.`n`nPlease contact your Manager or DevOps team before changing this configuration."
    }

    Write-Host "Git core.hooksPath is already configured correctly."
    Write-Host ""
    Write-Host "The configurator will repair/update the company pre-commit hook."
    Write-Host ""
}

# ============================================================================
# Create Hooks Directory
# ============================================================================

Write-Host "Creating company Git hooks directory..."

try {
    New-Item -ItemType Directory -Path $HooksDirectory -Force | Out-Null
}
catch {
    Fail-Configuration "Unable to create the company Git hooks directory:`n$HooksDirectory`n`nPlease check filesystem permissions and try again."
}

Write-Host "Hooks directory:"
Write-Host "  $HooksDirectory"
Write-Host ""

# ============================================================================
# Download Centralized Hook
# ============================================================================

Write-Host "Downloading centralized pre-commit hook..."
Write-Host ""
Write-Host "Source:"
Write-Host "  $CentralHookUrl"
Write-Host ""

$TemporaryHookFile = Join-Path $env:TEMP "company-pre-commit-$([guid]::NewGuid()).tmp"

try {

    & curl.exe `
        --fail `
        --silent `
        --show-error `
        --location `
        --output $TemporaryHookFile `
        $CentralHookUrl

    if ($LASTEXITCODE -ne 0) {
        throw "curl returned exit code $LASTEXITCODE"
    }

}
catch {

    if (Test-Path $TemporaryHookFile) {
        Remove-Item $TemporaryHookFile -Force -ErrorAction SilentlyContinue
    }

    Fail-Configuration "Failed to download the centralized pre-commit hook.`n`nPlease verify network connectivity and contact the DevOps team if the problem continues."
}

# ============================================================================
# Validate Download
# ============================================================================

if (-not (Test-Path $TemporaryHookFile)) {
    Fail-Configuration "The centralized pre-commit hook was not downloaded."
}

$DownloadedHook = Get-Item $TemporaryHookFile

if ($DownloadedHook.Length -eq 0) {

    Remove-Item $TemporaryHookFile -Force -ErrorAction SilentlyContinue

    Fail-Configuration "The downloaded pre-commit hook is empty.`n`nThe configuration has been stopped to prevent installing an invalid hook."
}

# ============================================================================
# Basic Hook Validation
# ============================================================================

try {
    $FirstLine = Get-Content -Path $TemporaryHookFile -TotalCount 1 -ErrorAction Stop
}
catch {

    Remove-Item $TemporaryHookFile -Force -ErrorAction SilentlyContinue

    Fail-Configuration "The downloaded pre-commit hook could not be read.`n`nPlease contact the DevOps team."
}

if (
    [string]::IsNullOrWhiteSpace($FirstLine) -or
    -not $FirstLine.StartsWith("#!")
) {

    Remove-Item $TemporaryHookFile -Force -ErrorAction SilentlyContinue

    Fail-Configuration "The downloaded file does not appear to be a valid executable script.`n`nThe configuration has been stopped.`n`nPlease contact the DevOps team."
}

# ============================================================================
# Configure Local Hook
# ============================================================================

Write-Host "Configuring centralized pre-commit hook..."

try {
    Move-Item -Path $TemporaryHookFile -Destination $HookFile -Force
}
catch {

    if (Test-Path $TemporaryHookFile) {
        Remove-Item $TemporaryHookFile -Force -ErrorAction SilentlyContinue
    }

    Fail-Configuration "Unable to place the centralized pre-commit hook at:`n$HookFile`n`nPlease check filesystem permissions and try again."
}

# ============================================================================
# Verify Hook
# ============================================================================

if (-not (Test-Path $HookFile)) {
    Fail-Configuration "The pre-commit hook could not be configured at:`n$HookFile"
}

$InstalledHook = Get-Item $HookFile

if ($InstalledHook.Length -eq 0) {
    Fail-Configuration "The configured pre-commit hook is empty."
}

# ============================================================================
# Configure Git
# ============================================================================

Write-Host "Configuring Git core.hooksPath..."

try {

    & git config --global core.hooksPath $HooksDirectory

    if ($LASTEXITCODE -ne 0) {
        throw "Git config returned exit code $LASTEXITCODE"
    }

}
catch {

    Fail-Configuration "Unable to configure Git core.hooksPath.`n`nPlease contact the DevOps team."
}

# ============================================================================
# Verify Git Configuration
# ============================================================================

try {
    $ConfiguredHooksDirectory = (& git config --global --get core.hooksPath 2>$null).Trim()
}
catch {
    $ConfiguredHooksDirectory = ""
}

if ([string]::IsNullOrWhiteSpace($ConfiguredHooksDirectory)) {

    Fail-Configuration "Git core.hooksPath verification failed.`n`nExpected:`n$HooksDirectory`n`nActual:`nNo core.hooksPath configuration found."
}

try {

    $ResolvedConfiguredHooksDirectory = [System.IO.Path]::GetFullPath(
        [Environment]::ExpandEnvironmentVariables($ConfiguredHooksDirectory)
    )

}
catch {

    $ResolvedConfiguredHooksDirectory = $ConfiguredHooksDirectory
}

if (
    $ResolvedConfiguredHooksDirectory.TrimEnd('\') -ne
    $ResolvedExpectedHooksDirectory.TrimEnd('\')
) {

    Fail-Configuration "Git core.hooksPath verification failed.`n`nExpected:`n$HooksDirectory`n`nActual:`n$ConfiguredHooksDirectory"
}

Write-Host "Git core.hooksPath configured successfully:"
Write-Host "  $ConfiguredHooksDirectory"
Write-Host ""

# ============================================================================
# Final Verification
# ============================================================================

Write-Separator
Write-Host "Configuration Verification"
Write-Separator
Write-Host ""

Write-Host "Git:"
Write-Host "  $GitVersion"
Write-Host ""

Write-Host "curl:"
Write-Host "  $CurlVersion"
Write-Host ""

Write-Host "Git core.hooksPath:"
Write-Host "  $ConfiguredHooksDirectory"
Write-Host ""

Write-Host "Pre-commit hook:"
Write-Host "  $HookFile"
Write-Host ""

Write-Host "Hook size:"
Write-Host "  $($InstalledHook.Length) bytes"
Write-Host ""

Write-Host "Hook validation:"
Write-Host "  Passed"
Write-Host ""

# ============================================================================
# Configuration Registration
# ============================================================================

Write-Host "Registering configuration with company security server..."
Write-Host ""

try {
    $GitUsername = (& git config --get user.name 2>$null).Trim()
}
catch {
    $GitUsername = ""
}

try {
    $GitEmail = (& git config --get user.email 2>$null).Trim()
}
catch {
    $GitEmail = ""
}

if (
    [string]::IsNullOrWhiteSpace($GitUsername) -or
    [string]::IsNullOrWhiteSpace($GitEmail)
) {

    Write-Host "WARNING"
    Write-Host "-------"
    Write-Host "Pre-commit hook configuration was successful,"
    Write-Host "but configuration registration was skipped."
    Write-Host ""
    Write-Host "Git user.name and/or user.email is not configured."
    Write-Host ""
    Write-Host "Please configure:"
    Write-Host ""
    Write-Host '  git config --global user.name "Your Name"'
    Write-Host '  git config --global user.email "your.email@company.com"'
    Write-Host ""

}
else {

    try {

        $RegistrationResponse = & curl.exe `
            --fail `
            --silent `
            --show-error `
            --location `
            --max-time 10 `
            --request POST `
            --data-urlencode "username=$GitUsername" `
            --data-urlencode "email=$GitEmail" `
            $RegistrationUrl

        if ($LASTEXITCODE -ne 0) {
            throw "curl returned exit code $LASTEXITCODE"
        }

        Write-Host "Configuration registration completed successfully."
        Write-Host "  Username: $GitUsername"
        Write-Host "  Email   : $GitEmail"
        Write-Host ""

    }
    catch {

        Write-Host "WARNING"
        Write-Host "-------"
        Write-Host "Pre-commit hook configuration was successful,"
        Write-Host "but configuration registration could not be completed."
        Write-Host ""
        Write-Host "The hook remains fully configured and active."
        Write-Host "Please contact the DevOps team if this problem persists."
        Write-Host ""
    }
}

# ============================================================================
# Success
# ============================================================================

Write-Separator
Write-Host "SUCCESS"
Write-Host "-------"
Write-Separator
Write-Host ""

Write-Host "Company centralized pre-commit hook has been configured successfully."
Write-Host ""

Write-Host "Git will now use the company centralized pre-commit hook from:"
Write-Host ""

Write-Host "  $HookFile"
Write-Host ""

Write-Host "All Git repositories using the global core.hooksPath configuration"
Write-Host "will use this centralized hook."
Write-Host ""

Write-Host "No software was installed."
Write-Host ""

Write-Host "You do not need to manually copy the hook into each repository."
Write-Host ""

Write-Separator
