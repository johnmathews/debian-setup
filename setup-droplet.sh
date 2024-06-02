#!/bin/bash

############################################################################################
#
#      ABOUT THIS SCROPT:
#
#  This script is intended to makes a new droplet feel familiar and productive.
#  It installs docker, neovim (with my debian config), git, oh-my-zsh, atuin, lazygit,
#
#  Logs: /var/log/setup-droplet.log
#  Restart: `(sudo) reboot`
#
#  The script creates a user called "github"
#
#  Passwords are passed in using the "do_pwd" environment variable.

# BEFORE SOURCE CONTROL SET TO XXXXX
export do_pwd=XXXX

#
#  LOG FILE at /var/log/setup-droplet.log
#
############################################################################################

# Exit on error and on error in pipeline
set -eo pipefail

# this diverts all of stdout and stderr (from this script) into the log file.
# You can follow it using `tail -f /var/log/setup-droplet.log`
# You can log into the droplet before this script has completed
exec >/var/log/setup-droplet.log 2>&1

echo "*** Starting setup..."

# Update the package database
apt-get update
echo "*** apt-get update done."

# Install required packages
apt-get install -y apt-transport-https ca-certificates curl cmake software-properties-common fzf tree xclip npm apache2-utils gnupg lsb-release
echo "*** apt-get install command finished."
echo "*** Installed apt-transport-https ca-certificates curl cmake software-properties-common fzf tree xclip npm apache2-utils gnupg lsb-release "

# Install neovim 0.9
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version

# Check if squashfs-root is not already in the root directory
if [ ! -d "/squashfs-root" ]; then
	# Attempt to move squashfs-root to /, but continue even if this fails
	sudo mv squashfs-root / || echo "Move operation failed, but continuing..."
else
	echo "squashfs-root already exists at /, no need to move."
fi

sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
echo "*** Installed Neovim"

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "*** Docker GPG key added."

# Add Docker repository
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "*** Docker repository added."

# Update the package database with Docker packages
apt-get update

# Install Docker CE
apt-get install -y docker-ce
echo "*** Docker CE installed."

# Configure Docker to start on boot
systemctl enable docker
echo "*** Docker enabled to start on boot."

# begin setup for portainer
# https://docs.portainer.io/start/install-ce/server/docker/linux
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest


mkdir -p ~/.config/nvim/
echo "*** Created ~/.config/nvim/"

max_attempts=5
attempt_num=1
while true; do
	if git clone https://github.com/johnmathews/neovim-debian /root/.config/nvim; then
		echo "*** Cloned neovim-debian repo into ~/.config/nvim successfully."
		break # Clone successful, exit the loop
	else
		if [ "$attempt_num" -lt "$max_attempts" ]; then
			((attempt_num++))
			echo "*** Attempt $attempt_num of $max_attempts."
			# Optional: wait before retrying, progressively increasing the delay
			sleep $((attempt_num * 5))
		else
			echo "*** Attempt $attempt_num failed. No more attempts left."
			exit 1
		fi
	fi
done

echo "*** About to install all the neovim plugins. this could take a minute or two"
nvim --headless +qall
echo "*** Plugin installation process completed."

# MAKE THE SHELL NICER
# Install Zsh
sudo apt-get install -y zsh
echo "*** Installed zsh"

# Install Oh My Zsh without user interaction
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
echo "*** Installed oh-my-zsh."

# Configure .zshrc (e.g., setting ZSH_THEME="agnoster")
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' ~/.zshrc
echo "*** set oh-my-zsh theme"

## ALIASES
# Check if ~/.aliases file already exists
if [ -f "/root/.aliases" ]; then
	echo "*** ~/.aliases file already exists. Appending to it..."
else
	echo "*** Creating ~/.aliases file..."
	touch "/root/.aliases"
fi

# Append common aliases to ~/.aliases
cat <<EOF >>"/root/.aliases"
# vim: ft=zsh:

# Vim not vi so that macvim compile options are used (for vimwiki links)
alias vi="nvim"
alias ld="lazydocker"

alias cl="clear"
alias b="clear"
alias readme="vi readme.md"

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec $SHELL -l"

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# TODO
alias todo='grep -rHn "TODO" --exclude="*.{.pyc,.swp,}" --exclude-dir={.git,htmlcov,}'

alias ll='ls -l'
alias l='ls -CF'

# System updates
alias update='sudo apt-get update && sudo apt-get upgrade'
alias install='sudo apt-get install'
EOF

echo "*** Wrote aliases into ~/.aliases."

echo 'source /root/.aliases' >>/root/.zshrc
echo 'source /root/.aliases' >>/root/.bashrc

echo "*** Sourced ~/.aliases in zshrc and bashrc"

# Set Zsh as the default shell
# you need to change the password before doing this, due to policies
echo "root:${do_pwd}" | sudo chpasswd
chsh -s "$(which zsh)"
echo "*** Changed the default shell to zsh"

# install lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
echo "*** Installed lazygit"

# install lazydocker
curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep "browser_download_url.*Linux_x86_64.tar.gz" | cut -d : -f 2,3 | tr -d \" | wget -qi -
tar zxvf lazydocker_*_Linux_x86_64.tar.gz lazydocker
chmod +x lazydocker
sudo mv lazydocker /usr/local/bin
rm lazydocker_*_Linux_x86_64.tar.gz
echo "*** Installed lazydocker"

# set default editor to neovim
echo 'export EDITOR=nvim' >>~/.zshrc
echo "*** Set EDITOR to nvim"

# install zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
sed -i "/^plugins=(/ s/)/ docker docker-compose colorize z vi-mode zsh-autosuggestions zsh-syntax-highlighting)/" "/root/.zshrc"
echo "*** Installed zsh plugins"

# new users
useradd -D -s "$(which zsh)" # all useradd commands will now create users with zsh as their shell
echo "*** made zsh the default shell for all new users"

cp -r /root/.oh-my-zsh/ /etc/skel/
cp -r /root/.config /etc/skel/
cp ~/.zshrc /etc/skel/
cp ~/.aliases /etc/skel/
echo "*** copied dotfiles to /etc/skel/ for new users"

useradd -m github # Create the user with a home directory and set default shell
echo "github:${do_pwd}" | chpasswd
echo "*** Created user github."

usermod -aG docker github
echo "*** Added github to docker group."

bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
echo "*** Installed Atuin shell history"

echo 'eval "$(atuin init zsh)"' >>~/.zshrc

atuin register -u johnmathews -e mthwsjc@gmail.com
echo "*** Installed Atuin shell history"

# install nvm for user `github`
su -c 'export NVM_DIR=~/.nvm && curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash' github

# install node and enable corepack so that yarn is available, for user `github`
su -c 'nvm install node && corepack enable' github

echo "*** Setup complete. Good job!"

timedatectl set-timezone Europe/Amsterdam
echo "*** Set timezone to Europe/Amsterdam."

echo "*** About to reboot"
sudo reboot
