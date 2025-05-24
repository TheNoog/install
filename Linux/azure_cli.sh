#!/usr/bin/env bash

<<COMMENT

  Summary:
  The following code will install the Azure Command Line Interface (CLI).
  It automatically detects the Linux distribution to ensure necessary prerequisites are installed.

  Note: Pass through the current subscription when running the
    command.

  To configure after installation:
    az login --use-device-code
    az account set --subscription <YOUR_SUBSCRIPTION_ID_OR_NAME>

COMMENT

# --- Functions ---

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---

echo "--- Azure CLI Installation Script ---"

# 1. Detect OS and install prerequisites
echo "Detecting Linux distribution and installing prerequisites for Azure CLI..."

# Initialize OS_ID
OS_ID=""

# Prefer /etc/os-release for detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VERSION_ID=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # Fallback to lsb_release if /etc/os-release is not found
    OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    OS_VERSION_ID=$(lsb_release -rs)
else
    # Generic detection if neither of the above works
    OS_ID=$(uname -s | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    OS_VERSION_ID=""
fi

echo "Detected OS: $OS_ID (Version: $OS_VERSION_ID)"

# Install prerequisites based on detected OS
case "$OS_ID" in
    ubuntu|debian)
        echo "Detected Ubuntu/Debian. Installing necessary packages..."
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
        # Add Microsoft GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
        # Add Azure CLI repository
        AZ_REPO=$(lsb_release -cs)
        echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
        ;;
    centos|rhel|fedora)
        echo "Detected CentOS/RHEL/Fedora. Installing necessary packages..."
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
        sudo yum install -y epel-release # For CentOS/RHEL, dnf users may skip
        sudo yum install -y curl
        ;;
    arch)
        echo "Detected Arch Linux. Installing necessary packages..."
        # Azure CLI is typically available in the AUR (Arch User Repository)
        # We'll install via pip as a fallback, as AUR requires an AUR helper (like yay)
        # If you have an AUR helper, you could use: yay -S azure-cli
        sudo pacman -Sy --noconfirm curl python python-pip
        ;;
    *)
        echo "Unsupported OS for direct Azure CLI package installation. Attempting installation via pip."
        echo "Please ensure 'python3' and 'python3-pip' are installed."
        # Attempt to install python3-pip using common package managers as a fallback
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y python3-pip
        elif command_exists yum; then
            sudo yum install -y python3-pip
        elif command_exists dnf; then
            sudo dnf install -y python3-pip
        elif command_exists pacman; then
            sudo pacman -Sy --noconfirm python-pip
        fi
        # If pip3 is still not found, exit
        if ! command_exists pip3; then
            echo "python3-pip not found and could not be installed automatically. Please install it manually."
            exit 1
        fi
        ;;
esac

# 2. Install Azure CLI
echo "Installing Azure CLI..."

# Use the recommended package manager method if applicable, otherwise fall back to pip
if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    sudo apt-get update
    sudo apt-get install -y azure-cli
elif [[ "$OS_ID" == "centos" || "$OS_ID" == "rhel" || "$OS_ID" == "fedora" ]]; then
    sudo dnf install -y azure-cli || sudo yum install -y azure-cli
else # Fallback to pip for other distributions like Arch or unrecognized ones
    echo "Installing Azure CLI via pip3..."
    sudo pip3 install azure-cli
    if [ $? -ne 0 ]; then
        echo "pip3 installation of Azure CLI failed. Exiting."
        exit 1
    fi
fi

# 3. Verify installation
echo "Verifying Azure CLI installation..."
if command_exists az; then
    echo "Azure CLI installed successfully:"
    az --version
else
    echo "Azure CLI command not found after installation. Please check your PATH."
fi

echo "--- Azure CLI Installation Complete ---"
echo "Remember to configure your Azure CLI by running:"
echo "  az login --use-device-code"
echo "  az account set --subscription <YOUR_SUBSCRIPTION_ID_OR_NAME>"
