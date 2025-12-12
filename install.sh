#!/bin/bash

# Define the custom plugins directory
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# 1. Change the default shell to Zsh for the current user
echo "Setting Zsh as default shell..."
sudo chsh -s "$(which zsh)" "$(id -un)"

# 2. Install custom Zsh plugins required by .zshrc
echo "Installing custom Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

# 3. Create symlink for .zshrc from dotfiles repo to home directory
# This assumes your .zshrc is in the root of your dotfiles repository
echo "Creating symlink for .zshrc..."
ln -sf "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"

echo "Dotfiles setup complete!"