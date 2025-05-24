#!/bin/bash

<<COMMENT

  Summary:
  The following code will install Docker Engine and Docker Compose (v2, as a plugin)
  to use for testing Docker containers and building Dockerfiles.

  It automatically detects the Linux distribution and adjusts the installation
  steps accordingly.

  NOTE: Permissions will also be added to the current user to enable them to
  run Docker commands with the 'docker' group. You may need to log out and
  log back in for the group changes to take effect.

COMMENT

# --- Functions ---

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---

echo "--- Docker and Docker Compose Installation Script ---"

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
    OS_CODENAME=$VERSION_CODENAME # Used for Debian/Ubuntu repos
elif type lsb_release >/dev/null 2>&1; then
    OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    OS_VERSION_ID=$(lsb_release -rs)
    OS_CODENAME=$(lsb_release -cs)
else
    OS_ID=$(uname -s | tr '[:upper:]' '[:lower:]')
    OS_VERSION_ID=""
    OS_CODENAME=""
fi

echo "Detected OS: $OS_ID (Version: $OS_VERSION_ID, Codename: $OS_CODENAME)"

case "$OS_ID" in
    ubuntu|debian)
        PACKAGE_MANAGER="apt"
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update"
        ;;
    centos|rhel|fedora)
        PACKAGE_MANAGER="yum_dnf"
        INSTALL_CMD="sudo yum install -y" # Will try dnf first if available
        UPDATE_CMD="sudo yum check-update" # Or dnf check-update
        ;;
    arch)
        PACKAGE_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -Sy --noconfirm"
        UPDATE_CMD="sudo pacman -Sy"
        ;;
    *)
        echo "Unsupported OS for automatic Docker installation. Please install Docker and Docker Compose manually."
        exit 1
        ;;
esac

# Ensure common prerequisites are installed
echo "Ensuring 'curl' and 'gnupg' are installed..."
if ! command_exists curl; then
    echo "curl not found. Installing..."
    case "$PACKAGE_MANAGER" in
        apt) $INSTALL_CMD curl ;;
        yum_dnf) sudo yum install -y curl || sudo dnf install -y curl ;;
        pacman) $INSTALL_CMD curl ;;
    esac
fi
if ! command_exists gnupg; then
    echo "gnupg not found. Installing..."
    case "$PACKAGE_MANAGER" in
        apt) $INSTALL_CMD gnupg ;;
        yum_dnf) sudo yum install -y gnupg || sudo dnf install -y gnupg ;;
        pacman) $INSTALL_CMD gnupg ;;
    esac
fi

# --- Install Docker Engine ---
echo "Installing Docker Engine..."

$UPDATE_CMD || { echo "Failed to update package lists. Exiting."; exit 1; }

case "$PACKAGE_MANAGER" in
    apt)
        # Add Docker's official GPG key:
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the repository to Apt sources:
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$OS_CODENAME" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        $UPDATE_CMD

        # Install Docker packages
        $INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    yum_dnf)
        # Add Docker repository
        if command_exists dnf; then
            sudo dnf install -y yum-utils
            sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $INSTALL_CMD docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi
        ;;
    pacman)
        # Docker is in the official Arch Linux repositories
        $INSTALL_CMD docker
        # Docker Compose v2 is usually part of the `docker-compose` package on Arch
        $INSTALL_CMD docker-compose
        ;;
esac

# Start and enable Docker service (if not Arch, as Arch uses systemctl enable/start directly after install)
if [[ "$PACKAGE_MANAGER" != "pacman" ]]; then
    echo "Starting and enabling Docker service..."
    sudo systemctl start docker.service
    sudo systemctl enable docker.service
fi

# Verify Docker installation
echo "Verifying Docker Engine installation..."
if command_exists docker; then
    echo "Docker Engine installed successfully:"
    sudo docker version --format '{{.Server.Version}}'
else
    echo "Docker Engine command not found after installation. Please check for errors."
    exit 1
fi

# --- Add current user to 'docker' group ---
echo "Adding current user '$USER' to the 'docker' group..."
sudo usermod -aG docker "$USER"
if [ $? -eq 0 ]; then
    echo "User '$USER' successfully added to 'docker' group."
    echo "NOTE: You may need to log out and log back in for the group changes to take effect."
    echo "After logging back in, you can test by running 'docker run hello-world' without 'sudo'."
else
    echo "Failed to add user '$USER' to 'docker' group. Please check permissions."
fi

# --- Verify Docker Compose (v2) installation ---
echo "Verifying Docker Compose (v2) installation..."
if command_exists docker; then
    if docker compose version &> /dev/null; then # Check if 'docker compose' (v2) works
        echo "Docker Compose (v2) installed successfully:"
        docker compose version
    elif command_exists docker-compose; then # Fallback for v1 if it was installed
        echo "Docker Compose (v1) installed (older version):"
        docker-compose version
    else
        echo "Docker Compose not found. Please check for errors during installation."
    fi
else
    echo "Docker command not found, cannot verify Docker Compose."
fi

echo "--- Docker and Docker Compose Installation Complete ---"
