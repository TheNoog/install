#!/bin/bash

<<COMMENT

  Summary: Setup everything I need in Arch linux.

COMMENT


# Make sure system is updated
sudo pacman -Syyu

# Add Asian fonts
sudo pacman -S ttf-fireflysung

# video codecs
sudo pacman -S mplayer ffmpeg4.4 unzip

# Install Yay
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si


# Turn on bluetooth
sudo systemctl start bluetooth.service
sudo systemctl enable bluetooth.service


# Install Snap
cd ~/
git clone https://aur.archlinux.org/snapd.git
cd snapd
makepkg -si
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap

# Install Codium
sudo snap install codium --classic

# Docker
sudo pacman -S docker docker-compose
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo usermod -aG docker $USER
docker version
docker-compose version


# Install Steam
sudo snap install steam
# sudo pacman -S steam


# Setup NVidia settings
lspci -k | grep -A 2 -E "(VGA|3D)"
sudo pacman -S nvidia nvidia-utils nvidia-settings xorg-server-devel opencl-nvidia nvidia-prime nvidia-libgl lib32-nvidia-libgl 
sudo nvidia-smi
prime-run glxinfo | grep 1650

# https://github.com/Askannz/optimus-manager
yay -S optimus-manager
sudo systemctl enable optimus-manager.service
sudo systemctl start optimus-manager.service
sudo lspci -v | grep -i "nvidia"
# https://github.com/Askannz/optimus-manager
optimus-manager --switch hybrid
sudo systemctl enable --now nvidia-resume.service


# Install Python 3.11.3
sudo pacman -Syyu python
sudo pacman -S pyenv
pyenv install -l | grep 3.11
pyenv install 3.11.3

pyenv shell 3.11.3 # Use this version only for this shell session
pyenv local 3.11.3 # Use this version only when you are in this directory
pyenv global 3.11.3 # Use this version as the default version


# Install Go
GO_VERSION=go1.20.3.linux-amd64.tar.gz

curl -OL https://go.dev/dl/${GO_VERSION}
sha256sum ${GO_VERSION}
sudo tar -C /usr/local -xvf ${GO_VERSION}

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile
go version

rm ${GO_VERSION}

# Install NASM
sudo pacman -S nasm

# Install Zig
# https://ziglang.org/builds/zig-linux-x86_64-0.11.0-dev.2868+1a455b2dd.tar.xz

# Install Java 17 / Kotlin / Gradle
sudo snap install --classic kotlin


# Gradle install
# sudo snap install gradle --classic
# https://linuxhint.com/installing_gradle_ubuntu/
export GRADLE_VERSION=8.0.1
wget -c https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp
ls /tmp
sudo unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip
ls /opt/gradle

# Setup gradle executeable
echo "export GRADLE_HOME=/opt/gradle/gradle-8.0.1" >> gradle.sh
echo 'export PATH=${GRADLE_HOME}/bin:${PATH}' >> gradle.sh
sudo mv gradle.sh /etc/profile.d/gradle.sh
sudo chmod +x /etc/profile.d/gradle.sh
source /etc/profile.d/gradle.sh
echo "source /etc/profile.d/gradle.sh" >> ~/.bashrc


# Install aws / azure / gcp
PWD=$(pwd)
mkdir $HOME/.aws
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$HOME/awscliv2.zip"
sudo unzip $HOME/awscliv2.zip
sudo mv $PWD/aws/* $HOME/.aws
sudo bash $HOME/.aws/install --update
# aws configure

sudo pacman -S python-pip  
sudo pip3 install azure-cli
# az login --use-device-code
# az login --allow-no-subscriptions

sudo snap install google-cloud-cli --classic
# gcloud auth-login
