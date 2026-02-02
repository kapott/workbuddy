#!/bin/bash
# Install oh-my-zsh

set -e

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
