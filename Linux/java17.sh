#!/bin/bash

<<COMMENT

  Summary:
  The following code will install Java (OpenJDK 17), Apache Maven, and Gradle.
  It automatically detects the Linux distribution and uses the appropriate package manager
  and installation methods.

  The versions are output at the end of the install as confirmation.

  NOTE: Environment variables for Java, Maven, and Gradle are set in /etc/profile.d/.
  You may need to log out and log back in (or run 'source /etc/profile') for these
  changes to be fully reflected in new shell sessions.

  Maven example:
    mvn -B archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes -DgroupId=com.mycompany.app -DartifactId=my-app -X

COMMENT

# --- Configuration ---
MAVEN_VERSION="3.9.6" # Updated to a more recent stable version
GRADLE_VERSION="8.7" # Updated to a more recent stable version

# --- Functions ---

# Function to check if a command exists
command_exists () {
  command -v "$1" >/dev/null 2>&1
}

# Function to dynamically find JAVA_HOME
get_java_home() {
    if command_exists java; then
        # Use readlink -f to resolve symlinks and get the absolute path
        # Then remove the 'bin/java' part to get the JAVA_HOME
        JAVA_BIN_PATH=$(readlink -f "$(which java)")
        JAVA_HOME_PATH=$(dirname "$(dirname "$JAVA_BIN_PATH")")
        echo "$JAVA_HOME_PATH"
    else
        echo "" # Return empty if java not found
    fi
}

# --- Main Script ---

echo "--- Java, Maven, and Gradle Installation Script ---"

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
        echo "Unsupported OS for automatic installation. Please install Java, Maven, and Gradle manually."
        exit 1
        ;;
esac

# Ensure common prerequisites are installed
echo "Ensuring 'wget', 'unzip', 'curl' are installed..."
for cmd in wget unzip curl; do
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

# --- Install Java (OpenJDK 17) ---
echo "Installing OpenJDK 17..."
$UPDATE_CMD || { echo "Failed to update package lists. Exiting."; exit 1; }

case "$PACKAGE_MANAGER" in
    apt)
        $INSTALL_CMD openjdk-17-jdk openjdk-17-jre
        ;;
    yum_dnf)
        # On RHEL/CentOS/Fedora, it's typically java-17-openjdk-devel for JDK
        $INSTALL_CMD java-17-openjdk-devel
        ;;
    pacman)
        $INSTALL_CMD jdk17-openjdk
        ;;
esac

if [ $? -ne 0 ]; then
    echo "Java (OpenJDK 17) installation failed. Exiting."
    exit 1
fi

# --- Install Maven ---
echo "Installing Apache Maven ${MAVEN_VERSION}..."
MAVEN_TAR_GZ="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
MAVEN_DOWNLOAD_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_TAR_GZ}"
MAVEN_DIR="/opt/apache-maven-${MAVEN_VERSION}"
MAVEN_SYMLINK="/opt/maven"

sudo wget "$MAVEN_DOWNLOAD_URL" -P /tmp
if [ $? -ne 0 ]; then
    echo "Failed to download Maven. Exiting."
    exit 1
fi

sudo tar xf "/tmp/${MAVEN_TAR_GZ}" -C /opt
if [ $? -ne 0 ]; then
    echo "Failed to extract Maven. Exiting."
    exit 1
fi

sudo rm -f "$MAVEN_SYMLINK" # Remove existing symlink if any
sudo ln -s "$MAVEN_DIR" "$MAVEN_SYMLINK"
if [ $? -ne 0 ]; then
    echo "Failed to create Maven symlink. Exiting."
    exit 1
fi

# Clean up downloaded tar.gz
sudo rm -f "/tmp/${MAVEN_TAR_GZ}"

# --- Install Gradle ---
echo "Installing Gradle ${GRADLE_VERSION}..."
GRADLE_ZIP="gradle-${GRADLE_VERSION}-bin.zip"
GRADLE_DOWNLOAD_URL="https://services.gradle.org/distributions/${GRADLE_ZIP}"
GRADLE_INSTALL_DIR="/opt/gradle/gradle-${GRADLE_VERSION}" # Unzips into a versioned directory inside /opt/gradle

sudo mkdir -p /opt/gradle # Ensure parent directory exists

sudo wget -c "$GRADLE_DOWNLOAD_URL" -P /tmp
if [ $? -ne 0 ]; then
    echo "Failed to download Gradle. Exiting."
    exit 1
fi

sudo unzip -q "/tmp/${GRADLE_ZIP}" -d /opt/gradle # Unzip quietly
if [ $? -ne 0 ]; then
    echo "Failed to unzip Gradle. Exiting."
    exit 1
fi

# Clean up downloaded zip
sudo rm -f "/tmp/${GRADLE_ZIP}"

# --- Setup Environment Variables ---
echo "Setting up environment variables..."

# JAVA_HOME
JAVA_HOME_PATH=$(get_java_home)
if [ -z "$JAVA_HOME_PATH" ]; then
    echo "Warning: Could not determine JAVA_HOME automatically. Please set it manually."
    # Fallback to common path if auto-detection fails, but warn user
    case "$OS_ID" in
        ubuntu|debian) JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64" ;;
        centos|rhel|fedora) JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk" ;;
        arch) JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk" ;;
        *) JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk" ;; # Generic fallback
    esac
fi

# Create profile scripts in /etc/profile.d/
echo "Creating /etc/profile.d/java.sh..."
sudo tee /etc/profile.d/java.sh > /dev/null << EOM
export JAVA_HOME="$JAVA_HOME_PATH"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOM
sudo chmod +x /etc/profile.d/java.sh

echo "Creating /etc/profile.d/maven.sh..."
sudo tee /etc/profile.d/maven.sh > /dev/null << EOM
export M2_HOME="$MAVEN_SYMLINK"
export MAVEN_HOME="$MAVEN_SYMLINK"
export PATH="\$MAVEN_HOME/bin:\$PATH"
EOM
sudo chmod +x /etc/profile.d/maven.sh

echo "Creating /etc/profile.d/gradle.sh..."
sudo tee /etc/profile.d/gradle.sh > /dev/null << EOM
export GRADLE_HOME="$GRADLE_INSTALL_DIR"
export PATH="\$GRADLE_HOME/bin:\$PATH"
EOM
sudo chmod +x /etc/profile.d/gradle.sh

# Source the new profile scripts to apply changes to the current shell
echo "Sourcing new environment variables for current session..."
source /etc/profile.d/java.sh
source /etc/profile.d/maven.sh
source /etc/profile.d/gradle.sh

# --- Verify Installations ---
echo "--- Verifying Installations ---"

echo "Java Version:"
if command_exists java; then
    java --version
else
    echo "Java command not found."
fi

echo -e "\nMvn Version:"
if command_exists mvn; then
    mvn -version
else
    echo "Maven command not found."
fi

echo -e "\nGradle Version:"
if command_exists gradle; then
    gradle -v
else
    echo "Gradle command not found."
fi

echo -e "\n--- Installation Complete ---"
echo "NOTE: For the environment variables to be fully active in new terminal sessions,"
echo "you might need to log out and log back in, or run 'source /etc/profile'."
