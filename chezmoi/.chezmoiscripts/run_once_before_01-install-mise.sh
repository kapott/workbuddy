#!/bin/bash
# Install mise (formerly rtx) for tool version management

set -e

if command -v mise &> /dev/null; then
    echo "mise is already installed"
    mise --version
    exit 0
fi

echo "Installing mise..."

# Install mise via official installer
curl https://mise.run | sh

# Add mise to PATH for current session
export PATH="$HOME/.local/bin:$PATH"

if command -v mise &> /dev/null; then
    echo "mise installed successfully!"
    mise --version
else
    echo "mise installation failed"
    exit 1
fi
