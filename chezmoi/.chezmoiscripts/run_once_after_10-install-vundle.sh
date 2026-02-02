#!/bin/bash
# Install Vundle and vim plugins

set -e

VUNDLE_DIR="$HOME/.vim/bundle/Vundle.vim"

if [ -d "$VUNDLE_DIR" ]; then
    echo "Vundle is already installed, updating..."
    cd "$VUNDLE_DIR" && git pull
else
    echo "Installing Vundle..."
    git clone https://github.com/VundleVim/Vundle.vim.git "$VUNDLE_DIR"
fi

echo "Installing vim plugins..."
vim +PluginInstall +qall

echo "Vundle and plugins installed successfully!"
