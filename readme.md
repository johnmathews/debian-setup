Some scripts to help create and setup a VM on Digital Ocean.

Runs on Debian.

# How it works

1. Make sure that `create-droplet.sh` can be executed. Use `chmod +x <file>`
2. Set the correct values in `droplet-config.sh`
3. Run `create-droplet.sh`

`create-droplet.sh` will collect the parameters from `droplet-config.yaml` and
once the VM is created, the `setup-droplet.sh` script will be run on the new VM.

## setup-droplet.sh

This script is intended to makes a new droplet feel familiar and productive. It
installs docker, neovim (with a debian config), git, oh-my-zsh, atuin, lazygit,

Logs: /var/log/setup-droplet.log Restart: `(sudo) reboot`

The script creates a user called "github"

Passwords are passed in using the "do_pwd" environment variable.

LOG FILE at /var/log/setup-droplet.log
