To always show hidden files:

```
defaults write com.apple.finder AppleShowAllFiles TRUE; killall Finder
```

1. Install Developer tools (e.g. git)

check

```
xcode-select -p

xcode-select --install
```

2. Install Homebrew

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile

eval "$(/opt/homebrew/bin/brew shellenv)"
``` 

<br />

3. Install snapcraft

```
brew install snapcraft
```

4. Install Python + Pip + Jupyter Notebook + Conda

3.9.6 default.

```
python3 --version
pip3 --version
```

Miniconda install

```
Go to https://docs.conda.io/en/latest/miniconda.html

Select M1 version and download 'pkg' format. 

Run the installer and select custom and "only for this user"

It will now be active on a new shell. -- NOPE!

Add to .zshrc 
export PATH="/Users/isaac/miniconda/bin:$PATH"

pip3 install jupyter

upgrade pip with:
/Library/Developer/CommandLineTools/usr/bin/python3 -m pip install --upgrade pip

Create an environment
https://docs.conda.io/projects/conda/en/4.6.0/_downloads/52a95608c49671267e40c689e0bc00ca/conda-cheatsheet.pdf

conda create --name py311 python=3.11
```

<br />

5. Install Java

```
brew install openjdk@17 
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
java --version

brew install gradle@8.2

brew install maven@3.9.3

```

6. Install C / C++

```
xcode-select --install

```

7. Install Rust

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

brew install rustup

rustup install stable
rustup default stable

rustup update

rustup doc
rustfmt
```

8. Install Go

```
Go to website and follow install instructions. Refresh shell once done.
https://go.dev/dl/
go version
```

9. Install R

```
https://cran.r-project.org/bin/macosx/
```

10. Install C#

```
https://dotnet.microsoft.com/en-us/download/dotnet/7.0
```

11. Install Docker + Docker Compose

```
Install Rosetta 2
softwareupdate --install-rosetta

Download from the official docker website.

sudo docker --version
sudo docker-compose --version
sudo docker run hello-world
```

12. Install AWS Cli

```
brew install awscli
```

13. Install GCP Cli

```
https://cloud.google.com/sdk/docs/install-sdk
```

14. Install Azure Cli

```
brew update && brew install azure-cli
```

15. Install Powershell

```
brew install --cask powershell
pwsh
```

16. Install Ruby

```
brew install ruby
```

17. Install Julia

```
https://julialang.org/downloads/
```

18. To ruin your prompt...
Powerlevel 10k
brew install romkatv/powerlevel10k/powerlevel10k\
echo "source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
source /opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme

brew remove romkatv/powerlevel10k/powerlevel10k

<br />

19. Oh My ZSH

```
https://ohmyz.sh/#install
```
