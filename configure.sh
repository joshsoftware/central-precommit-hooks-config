#!/usr/bin/env bash

set -u

###############################################################################
# Company Centralized Pre-Commit Hook Configurator
#
# Supported OS:
#   - Linux
#   - macOS
#
# What this script does:
#   1. Verifies Git is available
#   2. Verifies curl is available
#   3. Checks existing Git core.hooksPath configuration
#   4. Creates the company Git hooks directory
#   5. Downloads the centralized pre-commit hook
#   6. Validates the downloaded hook
#   7. Makes the hook executable
#   8. Configures Git core.hooksPath
#   9. Verifies the configuration
#  10. Registers the configuration with the company server
#
# Note:
#   This script does not install any software or Git packages.
#   It only configures Git and places the company-managed hook locally.
#
###############################################################################

###############################################################################
# Configuration
###############################################################################

HOOKS_DIR="${HOME}/.company-git-hooks"
HOOK_FILE="${HOOKS_DIR}/pre-commit"

HOOK_URL="https://code-security.joshsoftware.com/installations/pre-commit"

REGISTRATION_URL="https://code-security.joshsoftware.com/installations/register"

###############################################################################
# Helper Functions
###############################################################################

print_separator() {
    echo "=========================================================================="
}

print_error() {
    echo
    print_separator
    echo "ERROR"
    print_separator
    echo
    echo "$1"
    echo
    print_separator
    echo
}

print_success() {
    echo
    print_separator
    echo "SUCCESS"
    print_separator
    echo
    echo "$1"
    echo
    print_separator
    echo
}

###############################################################################
# Configuration Start
###############################################################################

echo
print_separator
echo "Company Centralized Pre-Commit Hook Configurator"
print_separator
echo
echo "This configurator will configure Git to use the company"
echo "centralized pre-commit hook through Git core.hooksPath."
echo
echo "No software or Git package will be installed."
echo

###############################################################################
# 1. Verify Git
###############################################################################

if ! command -v git >/dev/null 2>&1; then

    print_error \
        "Git is not installed or is not available in PATH.

Please install/configure Git on your system and run this configurator again."

    exit 1
fi

GIT_VERSION="$(git --version 2>/dev/null)"

echo "Git detected:"
echo "  ${GIT_VERSION}"
echo

###############################################################################
# 2. Verify curl
###############################################################################

if ! command -v curl >/dev/null 2>&1; then

    print_error \
        "curl is not installed or is not available in PATH.

Please install curl using your operating system's package manager
and run this configurator again."

    exit 1
fi

CURL_VERSION="$(curl --version 2>/dev/null | head -n 1)"

echo "curl detected:"
echo "  ${CURL_VERSION}"
echo

###############################################################################
# 3. Check existing core.hooksPath
###############################################################################

CURRENT_HOOKS_PATH="$(git config --global --get core.hooksPath 2>/dev/null || true)"

EXPECTED_HOOKS_DIR="${HOOKS_DIR}"

if [ -n "${CURRENT_HOOKS_PATH}" ]; then

    echo "Existing Git core.hooksPath detected:"
    echo
    echo "  ${CURRENT_HOOKS_PATH}"
    echo

    case "${CURRENT_HOOKS_PATH}" in
        "~/"*)
            CURRENT_HOOKS_PATH_EXPANDED="${HOME}/${CURRENT_HOOKS_PATH#~/}"
            ;;
        *)
            CURRENT_HOOKS_PATH_EXPANDED="${CURRENT_HOOKS_PATH}"
            ;;
    esac

    if [ "${CURRENT_HOOKS_PATH_EXPANDED}" != "${EXPECTED_HOOKS_DIR}" ]; then

        print_error \
            "Another Git hooks path is already configured.

Configured:
  ${CURRENT_HOOKS_PATH}

Company hooks directory:
  ${EXPECTED_HOOKS_DIR}

The configurator will not overwrite an existing Git core.hooksPath
configuration pointing to another directory.

Please check with your Manager or the DevOps team before changing
your Git core.hooksPath configuration."

        exit 1
    fi

    echo "The existing core.hooksPath points to the company hooks directory."
    echo "The configurator will repair/update the company pre-commit hook."
    echo

else

    echo "No Git core.hooksPath is currently configured."
    echo "The company Git hooks path will be configured."
    echo

fi

###############################################################################
# 4. Create company hooks directory
###############################################################################

echo "Creating company Git hooks directory..."

if ! mkdir -p "${HOOKS_DIR}"; then

    print_error \
        "Unable to create:

  ${HOOKS_DIR}

Please check filesystem permissions and try again."

    exit 1
fi

echo "Hooks directory:"
echo "  ${HOOKS_DIR}"
echo

###############################################################################
# 5. Download centralized pre-commit hook
###############################################################################

TEMP_HOOK="${HOOK_FILE}.tmp.$$"

echo "Downloading centralized pre-commit hook..."
echo
echo "Source:"
echo "  ${HOOK_URL}"
echo

if ! curl \
    --fail \
    --silent \
    --show-error \
    --location \
    "${HOOK_URL}" \
    --output "${TEMP_HOOK}"; then

    rm -f "${TEMP_HOOK}"

    print_error \
        "Unable to download the centralized pre-commit hook.

URL:
  ${HOOK_URL}

Please verify that you have network access to the company security
server and try again.

Your existing Git core.hooksPath configuration has not been changed."

    exit 1
fi

###############################################################################
# 6. Validate downloaded hook
###############################################################################

if [ ! -s "${TEMP_HOOK}" ]; then

    rm -f "${TEMP_HOOK}"

    print_error \
        "The centralized pre-commit hook was downloaded but the file is empty.

Configuration has been stopped.

Please contact the DevOps team."

    exit 1
fi

###############################################################################
# Basic validation
###############################################################################

if ! head -n 1 "${TEMP_HOOK}" | grep -q "^#!"; then

    rm -f "${TEMP_HOOK}"

    print_error \
        "The downloaded file does not appear to be a valid executable script.

Configuration has been stopped.

Please contact the DevOps team."

    exit 1
fi

###############################################################################
# 7. Configure local hook
###############################################################################

echo "Configuring centralized pre-commit hook..."

if ! mv "${TEMP_HOOK}" "${HOOK_FILE}"; then

    rm -f "${TEMP_HOOK}"

    print_error \
        "Unable to place the centralized pre-commit hook at:

  ${HOOK_FILE}

Please check filesystem permissions and try again."

    exit 1
fi

###############################################################################
# 8. Make hook executable
###############################################################################

echo "Setting executable permission..."

if ! chmod +x "${HOOK_FILE}"; then

    print_error \
        "The pre-commit hook was downloaded but could not be made executable:

  ${HOOK_FILE}

Please check filesystem permissions."

    exit 1
fi

###############################################################################
# 9. Configure core.hooksPath
###############################################################################

echo "Configuring Git core.hooksPath..."

if ! git config --global core.hooksPath "${HOOKS_DIR}"; then

    print_error \
        "Unable to configure Git core.hooksPath.

Please contact the DevOps team."

    exit 1
fi

###############################################################################
# 10. Verify configuration
###############################################################################

CONFIGURED_HOOKS_PATH="$(git config --global --get core.hooksPath 2>/dev/null || true)"

case "${CONFIGURED_HOOKS_PATH}" in
    "~/"*)
        CONFIGURED_HOOKS_PATH_EXPANDED="${HOME}/${CONFIGURED_HOOKS_PATH#~/}"
        ;;
    *)
        CONFIGURED_HOOKS_PATH_EXPANDED="${CONFIGURED_HOOKS_PATH}"
        ;;
esac

if [ "${CONFIGURED_HOOKS_PATH_EXPANDED}" != "${EXPECTED_HOOKS_DIR}" ]; then

    print_error \
        "Git core.hooksPath verification failed.

Expected:
  ${EXPECTED_HOOKS_DIR}

Actual:
  ${CONFIGURED_HOOKS_PATH}

Please contact the DevOps team."

    exit 1
fi

###############################################################################
# 11. Verify hook
###############################################################################

if [ ! -f "${HOOK_FILE}" ]; then

    print_error \
        "The pre-commit hook could not be found after configuration:

  ${HOOK_FILE}

Please contact the DevOps team."

    exit 1
fi

if [ ! -x "${HOOK_FILE}" ]; then

    print_error \
        "The pre-commit hook exists but is not executable:

  ${HOOK_FILE}

Please contact the DevOps team."

    exit 1
fi

###############################################################################
# 12. Configuration Summary
###############################################################################

echo
print_separator
echo "Configuration Verification"
print_separator
echo
echo "Git:"
echo "  ${GIT_VERSION}"
echo
echo "curl:"
echo "  ${CURL_VERSION}"
echo
echo "Git core.hooksPath:"
echo "  ${CONFIGURED_HOOKS_PATH}"
echo
echo "Pre-commit hook:"
echo "  ${HOOK_FILE}"
echo
echo "Executable:"
echo "  Yes"
echo

###############################################################################
# 13. Configuration Registration
###############################################################################

echo "Registering configuration with company security server..."
echo

GIT_USERNAME="$(git config --get user.name 2>/dev/null || true)"
GIT_EMAIL="$(git config --get user.email 2>/dev/null || true)"

GIT_USERNAME="$(printf '%s' "${GIT_USERNAME}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
GIT_EMAIL="$(printf '%s' "${GIT_EMAIL}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [ -z "${GIT_USERNAME}" ] || [ -z "${GIT_EMAIL}" ]; then

    echo "WARNING"
    echo "-------"
    echo "Pre-commit hook configuration was successful,"
    echo "but configuration registration was skipped."
    echo
    echo "Git user.name and/or user.email is not configured."
    echo
    echo "Please configure:"
    echo
    echo "  git config --global user.name \"Your Name\""
    echo "  git config --global user.email \"your.email@company.com\""
    echo

else

    if curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --max-time 10 \
        --request POST \
        --data-urlencode "username=${GIT_USERNAME}" \
        --data-urlencode "email=${GIT_EMAIL}" \
        "${REGISTRATION_URL}" \
        >/dev/null; then

        echo "Configuration registration completed successfully."
        echo "  Username: ${GIT_USERNAME}"
        echo "  Email   : ${GIT_EMAIL}"
        echo

    else

        echo "WARNING"
        echo "-------"
        echo "Pre-commit hook configuration was successful,"
        echo "but configuration registration could not be completed."
        echo
        echo "The hook remains fully configured and active."
        echo "Please contact the DevOps team if this problem persists."
        echo
    fi

fi

###############################################################################
# 14. Final Success
###############################################################################

print_success \
"Company centralized pre-commit hook has been configured successfully.

Git will now use the company centralized pre-commit hook from:

  ${HOOK_FILE}

All Git repositories using the global core.hooksPath configuration
will use this centralized hook.

No software was installed.

You do not need to manually copy the hook into each repository."

exit 0
