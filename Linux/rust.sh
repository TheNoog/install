#!/bin/bash

<<COMMENT

  Summary:
  The following code will install the Rust programming language and its toolchain
  (rustc, cargo, rustup). It automatically detects the Linux distribution and
  installs necessary prerequisites.

  The versions are output at the end of the install as confirmation.

  NOTE: Rust's environment variables are typically set by 'rustup' in ~/.bashrc
  or ~/.profile. You may need to log out and log back in (or run 'source ~/.bashrc')
  for these changes to be fully reflected in new shell sessions.

COMMENT

# --- Functions ---

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---

echo "--- Rust Installation Script ---"

# 1. Detect OS and set package manager variables
echo "Detecting Linux distribution..."
OS_ID=""
PACKAGE_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VERSION_ID=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    OS_VERSION_ID=$(lsb_release -rs)
else
    OS_ID=$(uname -s | tr '[:upper:]' '[:lower:]')
    OS_VERSION_ID=""
fi

echo "Detected OS: $OS_ID (Version: $OS_VERSION_ID)"

case "$OS_ID" in
    ubuntu|debian)
        PACKAGE_MANAGER="apt"
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update"
        BUILD_TOOLS_PACKAGE="build-essential"
        ;;
    centos|rhel|fedora)
        PACKAGE_MANAGER="yum_dnf"
        INSTALL_CMD="sudo yum install -y" # Will try dnf first if available
        UPDATE_CMD="sudo yum check-update" # Or dnf check-update
        BUILD_TOOLS_PACKAGE="gcc make" # Common build tools
        ;;
    arch)
        PACKAGE_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -Sy --noconfirm"
        UPDATE_CMD="sudo pacman -Sy"
        BUILD_TOOLS_PACKAGE="base-devel" # Group for essential build tools
        ;;
    *)
        echo "Unsupported OS for automatic installation. Please install Rust manually."
        exit 1
        ;;
esac

# Ensure prerequisites are installed
echo "Ensuring 'curl' and build tools are installed..."
for cmd in curl; do
    if ! command_exists "$cmd"; then
        echo "$cmd not found. Installing..."
        case "$PACKAGE_MANAGER" in
            apt) $INSTALL_CMD "$cmd" ;;
            yum_dnf) sudo yum install -y "$cmd" || sudo dnf install -y "$cmd" ;;
            pacman) $INSTALL_CMD "$cmd" ;;
        esac
        if ! command_exists "$cmd"; then
            echo "Failed to install $cmd. Exiting."
            exit 1
        fi
    fi
done

# Install build tools
echo "Installing build tools ($BUILD_TOOLS_PACKAGE)..."
$UPDATE_CMD || { echo "Failed to update package lists. Continuing, but build tools might fail."; } # Non-fatal for update, but fatal for install

case "$PACKAGE_MANAGER" in
    apt) $INSTALL_CMD "$BUILD_TOOLS_PACKAGE" ;;
    yum_dnf) sudo yum install -y "$BUILD_TOOLS_PACKAGE" || sudo dnf install -y "$BUILD_TOOLS_PACKAGE" ;;
    pacman) $INSTALL_CMD "$BUILD_TOOLS_PACKAGE" ;;
esac

if [ $? -ne 0 ]; then
    echo "Warning: Build tools installation failed. Rust compilation might encounter issues."
    echo "Please ensure packages like 'gcc', 'make', 'libc-dev' (or equivalent) are installed."
fi

# --- Install Rust using rustup ---
echo "Installing Rust via rustup..."

# Check if rustup is already installed
if command_exists rustup; then
    echo "rustup is already installed. Updating Rust toolchain..."
    rustup update
    if [ $? -ne 0 ]; then
        echo "Failed to update Rust toolchain. Exiting."
        exit 1
    fi
else
    echo "rustup not found. Downloading and running rustup-init.sh..."
    # Download rustup-init.sh
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh
    if [ $? -ne 0 ]; then
        echo "Failed to download rustup-init.sh. Exiting."
        exit 1
    fi

    # Run the installer in non-interactive mode (default installation)
    # The -y flag confirms the default installation
    sh /tmp/rustup-init.sh -y
    if [ $? -ne 0 ]; then
        echo "Rust installation via rustup-init.sh failed. Exiting."
        rm -f /tmp/rustup-init.sh # Clean up
        exit 1
    fi

    # Clean up the downloaded script
    rm -f /tmp/rustup-init.sh

    # Source cargo's env file to make rustc and cargo available in the current shell
    # rustup typically adds this to ~/.bashrc or ~/.profile
    echo "Sourcing Rust environment variables for current session..."
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    else
        echo "Warning: ~/.cargo/env not found. You may need to manually source it or log out/in."
    fi
fi

# --- Verify Rust installation ---
echo "--- Verifying Rust Installation ---"

echo "rustc Version:"
if command_exists rustc; then
    rustc --version
else
    echo "rustc command not found. Rust compiler might not be installed correctly."
fi

echo -e "\nCargo Version:"
if command_exists cargo; then
    cargo --version
else
    echo "cargo command not found. Rust package manager might not be installed correctly."
fi

echo -e "\n--- Rust Installation Complete ---"
echo "NOTE: For Rust commands to be fully active in new terminal sessions,"
echo "you might need to log out and log back in, or run 'source \$HOME/.cargo/env'."
