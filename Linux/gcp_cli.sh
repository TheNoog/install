#!/usr/bin/env bash

<<COMMENT

  Summary:
  The following code will install the Google Cloud SDK.
  It automatically detects your Linux distribution and uses the appropriate package manager.

  To configure after installation:
    gcloud auth login

COMMENT

# --- Functions ---

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---

echo "--- Google Cloud SDK Installation Script ---"

# 1. Detect OS and set package manager variables
echo "Detecting Linux distribution..."
OS_ID=""
OS_VERSION_ID=""
PACKAGE_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VERSION_ID=$VERSION_ID
    # VERSION_CODENAME is used for Debian/Ubuntu repos
    OS_CODENAME=$VERSION_CODENAME
elif type lsb_release >/dev/null 2>&1; then
    OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    OS_VERSION_ID=$(lsb_release -rs)
    OS_CODENAME=$(lsb_release -cs)
else
    OS_ID=$(uname -s | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    OS_VERSION_ID=""
    OS_CODENAME=""
fi

echo "Detected OS: $OS_ID (Version: $OS_VERSION_ID, Codename: $OS_CODENAME)"

# Ensure 'curl' and 'gnupg' (or equivalent) are installed as they are common prerequisites
echo "Ensuring 'curl' and 'gnupg' are installed..."
if ! command_exists curl; then
    echo "curl not found. Attempting to install..."
    case "$OS_ID" in
        ubuntu|debian) sudo apt-get update && sudo apt-get install -y curl ;;
        centos|rhel|fedora) sudo yum install -y curl || sudo dnf install -y curl ;;
        arch) sudo pacman -Sy --noconfirm curl ;;
        *) echo "Cannot install 'curl' automatically on this OS. Please install manually."; exit 1 ;;
    esac
fi
if ! command_exists gnupg; then
    echo "gnupg not found. Attempting to install..."
    case "$OS_ID" in
        ubuntu|debian) sudo apt-get update && sudo apt-get install -y gnupg ;;
        centos|rhel|fedora) sudo yum install -y gnupg || sudo dnf install -y gnupg ;;
        arch) sudo pacman -Sy --noconfirm gnupg ;;
        *) echo "Cannot install 'gnupg' automatically on this OS. Please install manually."; exit 1 ;;
    esac
fi


# --- Install Google Cloud SDK ---
echo "Installing Google Cloud SDK..."

case "$OS_ID" in
    ubuntu|debian)
        echo "Detected Ubuntu/Debian. Using apt for installation."
        # Add the Google Cloud SDK distribution URI
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null

        # Import the Google Cloud public key
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        if [ $? -ne 0 ]; then
            echo "Failed to add Google Cloud GPG key. Exiting."
            exit 1
        fi

        # Install necessary packages for apt over HTTPS
        sudo apt-get install -y apt-transport-https ca-certificates gnupg

        # Update the package list and install the Cloud SDK
        sudo apt-get update && sudo apt-get install -y google-cloud-sdk
        ;;
    centos|rhel|fedora)
        echo "Detected CentOS/RHEL/Fedora. Using yum/dnf for installation."
        # Create the yum repo file
        sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el$(cut -d: -f5 /etc/system-release-cpe | cut -d. -f1)-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
        # Install the Cloud SDK
        if command_exists dnf; then
            sudo dnf install -y google-cloud-sdk
        else
            sudo yum install -y google-cloud-sdk
        fi
        ;;
    arch)
        echo "Detected Arch Linux. Google Cloud SDK is available in the official repositories or AUR."
        echo "Attempting to install via pacman (official repo). If it fails, consider using an AUR helper like 'yay -S google-cloud-sdk'."
        sudo pacman -Sy --noconfirm google-cloud-sdk
        ;;
    *)
        echo "Unsupported OS for automatic Google Cloud SDK installation. Please refer to the official documentation."
        exit 1
        ;;
esac

# 3. Verify installation
echo "Verifying Google Cloud SDK installation..."
if command_exists gcloud; then
    echo "Google Cloud SDK installed successfully:"
    gcloud --version
else
    echo "Google Cloud SDK command 'gcloud' not found after installation. Please check for errors."
    exit 1
fi

echo "--- Google Cloud SDK Installation Complete ---"
echo "Remember to configure your GCP access by running:"
echo "  gcloud auth login"
