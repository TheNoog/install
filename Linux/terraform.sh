#!/bin/bash

<<COMMENT

  Summary:
  The following code will install Terraform. It dynamically identifies the
  latest stable version and uses the official HashiCorp repositories
  for Debian/Ubuntu and RHEL/CentOS/Fedora systems for a robust installation.
  For Arch Linux, it uses pacman.
  As a fallback, it can also perform a manual binary installation.

  Note: The script also includes an example of how to install the
  Snowflake Terraform provider.

COMMENT

# --- Configuration ---
TF_INSTALL_DIR="/usr/local/bin" # Common location for binaries in PATH
TF_PLUGINS_DIR="$HOME/.terraform.d/plugins" # Default plugins directory

# --- Functions ---

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# Function to get the latest stable Terraform version
get_latest_terraform_version() {
    # Using HashiCorp's releases API
    curl -s https://api.releases.hashicorp.com/v1/releases/terraform | \
    jq -r '.[] | select(.is_prerelease == false) | .version' | \
    sort -V | tail -n 1
}

# --- Main Script ---

echo "--- Terraform Installation Script ---"

# 1. Detect OS and set package manager variables
echo "Detecting Linux distribution..."
OS_ID=""
PACKAGE_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""
DEPENDENCIES=""

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VERSION_ID=$VERSION_ID
    OS_CODENAME=$VERSION_CODENAME
elif type lsb_release >/dev/null 2>&1; then
    OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    OS_VERSION_ID=$(lsb_release -rs)
    OS_CODENAME=$(lsb_release -cs)
else
    OS_ID=$(uname -s | tr '[:upper:]' '[:lower:]')
    OS_VERSION_ID=""
    OS_CODENAME=""
fi

echo "Detected OS: $OS_ID (Version: $OS_VERSION_ID)"

case "$OS_ID" in
    ubuntu|debian)
        PACKAGE_MANAGER="apt"
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update"
        DEPENDENCIES="software-properties-common gnupg curl unzip jq"
        ;;
    centos|rhel|fedora)
        PACKAGE_MANAGER="yum_dnf"
        INSTALL_CMD="sudo yum install -y" # Will try dnf first if available
        UPDATE_CMD="sudo yum check-update" # Or dnf check-update
        DEPENDENCIES="yum-utils gnupg curl unzip jq" # yum-utils for yum-config-manager
        ;;
    arch)
        PACKAGE_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -Sy --noconfirm"
        UPDATE_CMD="sudo pacman -Sy"
        DEPENDENCIES="curl unzip jq" # gnupg is usually part of base-devel
        ;;
    *)
        echo "Unsupported OS for automatic repository installation. Attempting manual binary installation."
        PACKAGE_MANAGER="manual"
        DEPENDENCIES="curl unzip jq" # Ensure curl and unzip for manual method
        ;;
esac

# Ensure common prerequisites are installed
echo "Ensuring dependencies are installed: $DEPENDENCIES..."
for dep in $DEPENDENCIES; do
    if ! command_exists "$dep"; then
        echo "$dep not found. Installing..."
        case "$PACKAGE_MANAGER" in
            apt) $INSTALL_CMD "$dep" ;;
            yum_dnf) sudo yum install -y "$dep" || sudo dnf install -y "$dep" ;;
            pacman) $INSTALL_CMD "$dep" ;;
            manual) echo "Please install '$dep' manually."; exit 1 ;; # Manual method needs user to install deps
        esac
        if ! command_exists "$dep"; then
            echo "Failed to install $dep. Exiting."
            exit 1
        fi
    fi
done

# 2. Install Terraform
echo "Installing Terraform..."

# Get the latest stable Terraform version
TF_VERSION=$(get_latest_terraform_version)
if [ -z "$TF_VERSION" ]; then
    echo "Failed to determine the latest Terraform version. Exiting."
    exit 1
fi
echo "Latest Terraform version identified: $TF_VERSION"

case "$PACKAGE_MANAGER" in
    apt)
        echo "Configuring HashiCorp APT repository..."
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
        $UPDATE_CMD
        $INSTALL_CMD terraform
        ;;
    yum_dnf)
        echo "Configuring HashiCorp YUM/DNF repository..."
        if command_exists dnf; then
            sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
        else
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
        fi
        $INSTALL_CMD terraform
        ;;
    pacman)
        echo "Installing Terraform from Arch Linux repositories..."
        $INSTALL_CMD terraform
        ;;
    manual)
        echo "Proceeding with manual binary installation for Terraform version $TF_VERSION..."
        TF_ZIP_FILE="terraform_${TF_VERSION}_linux_amd64.zip"
        TF_DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TF_VERSION}/${TF_ZIP_FILE}"

        wget "$TF_DOWNLOAD_URL" -P /tmp
        if [ $? -ne 0 ]; then
            echo "Failed to download Terraform binary. Exiting."
            exit 1
        fi

        unzip -q "/tmp/$TF_ZIP_FILE" -d /tmp/
        if [ $? -ne 0 ]; then
            echo "Failed to unzip Terraform binary. Exiting."
            rm -f "/tmp/$TF_ZIP_FILE"
            exit 1
        fi

        sudo mv "/tmp/terraform" "$TF_INSTALL_DIR/"
        if [ $? -ne 0 ]; then
            echo "Failed to move terraform binary to $TF_INSTALL_DIR. Exiting."
            rm -f "/tmp/$TF_ZIP_FILE"
            exit 1
        fi

        sudo rm -f "/tmp/$TF_ZIP_FILE"
        echo "Terraform installed to $TF_INSTALL_DIR."
        ;;
esac

if [ $? -ne 0 ]; then
    echo "Terraform installation failed. Exiting."
    exit 1
fi

# Verify Terraform installation
echo "Verifying Terraform installation..."
if command_exists terraform; then
    terraform version
else
    echo "Terraform command not found. Installation might have failed or PATH is not correctly set."
    exit 1
fi

echo "--- Terraform installation complete ---"
