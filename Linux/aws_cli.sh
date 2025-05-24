#!/usr/bin/env bash

<<COMMENT

  Summary:
    The following code will install the AWS Command Line Interface (CLI) v2.
    It automatically detects the Linux distribution to ensure 'unzip' and 'curl' are installed.

  Configure by running the command:
    aws configure --profile account1
    aws configure --profile account2

  To use the different accounts:
    aws dynamodb list-tables --profile account1
    aws s3 ls --profile account2

  Use the following setup (note, an admin user may need to create the keys if you don't have access):
    AWS Access Key ID: (created in IAM dashboard for user)
    AWS Secret Access Key: (only available the first time the access key is created.)
    Default region name: ap-southeast-2
    Default output format: json

COMMENT

# --- Configuration ---
AWS_CLI_TEMP_DIR="$HOME/awsclitmp"
AWS_CLI_ZIP_FILE="$AWS_CLI_TEMP_DIR/awscliv2.zip"
AWS_CLI_EXTRACT_DIR="$AWS_CLI_TEMP_DIR/aws" # The installer extracts into a directory named 'aws'

# --- Functions ---

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---

echo "--- AWS CLI Installation Script ---"

# 1. Create a temporary directory for download and extraction
echo "Creating temporary directory: $AWS_CLI_TEMP_DIR"
mkdir -p "$AWS_CLI_TEMP_DIR" || { echo "Failed to create temporary directory. Exiting."; exit 1; }

# 2. Detect OS and install prerequisites (unzip, curl)
echo "Detecting Linux distribution and installing prerequisites..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VERSION_ID=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    OS_VERSION_ID=$(lsb_release -rs)
else
    OS_ID=$(uname -s | tr '[:upper:]' '[:lower:]') # Convert to lowercase
    OS_VERSION_ID=""
fi

echo "Detected OS: $OS_ID (Version: $OS_VERSION_ID)"

# Install unzip and curl if not present
if ! command_exists unzip; then
    echo "unzip not found. Attempting to install..."
    case "$OS_ID" in
        ubuntu|debian)
            sudo apt-get update && sudo apt-get install -y unzip
            ;;
        centos|rhel|fedora)
            sudo yum install -y unzip || sudo dnf install -y unzip
            ;;
        arch)
            sudo pacman -Sy --noconfirm unzip
            ;;
        *)
            echo "Unsupported OS for automatic 'unzip' installation. Please install 'unzip' manually."
            exit 1
            ;;
    esac
    if ! command_exists unzip; then
        echo "Failed to install unzip. Exiting."
        exit 1
    fi
fi

if ! command_exists curl; then
    echo "curl not found. Attempting to install..."
    case "$OS_ID" in
        ubuntu|debian)
            sudo apt-get update && sudo apt-get install -y curl
            ;;
        centos|rhel|fedora)
            sudo yum install -y curl || sudo dnf install -y curl
            ;;
        arch)
            sudo pacman -Sy --noconfirm curl
            ;;
        *)
            echo "Unsupported OS for automatic 'curl' installation. Please install 'curl' manually."
            exit 1
            ;;
    esac
    if ! command_exists curl; then
        echo "Failed to install curl. Exiting."
        exit 1
    fi
fi

# 3. Download the AWS CLI v2 installer
echo "Downloading AWS CLI v2 installer..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$AWS_CLI_ZIP_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to download AWS CLI zip. Exiting."
    rm -rf "$AWS_CLI_TEMP_DIR" # Clean up
    exit 1
fi

# 4. Unzip the installer
echo "Unzipping AWS CLI installer..."
unzip "$AWS_CLI_ZIP_FILE" -d "$AWS_CLI_TEMP_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to unzip AWS CLI. Exiting."
    rm -rf "$AWS_CLI_TEMP_DIR" # Clean up
    exit 1
fi

# 5. Run the AWS CLI install script
echo "Running AWS CLI installation script..."
# The install script places binaries in /usr/local/bin by default
# --update flag ensures it updates an existing installation
sudo "$AWS_CLI_EXTRACT_DIR/install" --update
if [ $? -ne 0 ]; then
    echo "AWS CLI installation failed. Exiting."
    rm -rf "$AWS_CLI_TEMP_DIR" # Clean up
    exit 1
fi

# 6. Verify installation
echo "Verifying AWS CLI installation..."
if command_exists aws; then
    echo "AWS CLI installed successfully:"
    aws --version
else
    echo "AWS CLI command not found after installation. Please check your PATH."
    echo "You might need to add /usr/local/bin to your PATH environment variable."
fi

# 7. Create .aws directory for configuration if it doesn't exist
echo "Ensuring ~/.aws directory exists for configuration..."
mkdir -p "$HOME/.aws"

# 8. Clean up temporary files
echo "Cleaning up temporary installation files..."
rm -rf "$AWS_CLI_TEMP_DIR"

echo "--- AWS CLI Installation Complete ---"
echo "Remember to configure your AWS CLI by running:"
echo "  aws configure --profile account1"
echo "  aws configure --profile account2"
echo "And follow the prompts for Access Key ID, Secret Access Key, Default region (e.g., ap-southeast-2), and Default output format (e.g., json)."
