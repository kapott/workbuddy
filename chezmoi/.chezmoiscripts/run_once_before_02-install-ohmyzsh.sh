#!/bin/bash
# Install oh-my-zsh

set -e

# Arch and CachyOS package oh-my-zsh in /usr/share, and ~/.zshrc prefers that
# copy because pacman keeps it current. Cloning a second one into $HOME would
# leave two trees to update, and the one this script writes would be the stale
# one.
if [ -d /usr/share/oh-my-zsh ]; then
    echo "oh-my-zsh is installed system-wide in /usr/share/oh-my-zsh"
    exit 0
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh is already installed"
    exit 0
fi

echo "Installing oh-my-zsh..."

# Install oh-my-zsh without changing shell automatically
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh installed successfully!"
else
    echo "oh-my-zsh installation failed"
    exit 1
fi
