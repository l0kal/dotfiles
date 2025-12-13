#!/bin/bash

# --- Configuration ---
DOTFILES_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${OMZ_DIR}/custom"
# The source .zshrc in your dotfiles repo
SOURCE_ZSHRC="${DOTFILES_REPO_DIR}/.zshrc"
TARGET_ZSHRC="$HOME/.zshrc"

# --- Helper Functions ---

# Function to check if a directory exists and clone if not
safe_clone() {
    local repo_url=$1
    local target_dir=$2
    local plugin_name=$(basename "$target_dir")
    
    if [ -d "$target_dir" ]; then
        echo "✅ Plugin '$plugin_name' already exists. Skipping clone."
    else
        echo "➡️ Installing plugin: '$plugin_name'..."
        if git clone --depth 1 "$repo_url" "$target_dir"; then
            echo "✅ Plugin '$plugin_name' installed successfully."
        else
            echo "❌ ERROR: Failed to clone '$plugin_name' from $repo_url"
        fi
    fi
}

# --- Installation Steps ---

## Step 1: Install Oh My Zsh (Crucial prerequisite for your plugins)
if [ ! -d "$OMZ_DIR" ]; then
    echo "➡️ Installing Oh My Zsh..."
    # The official Oh My Zsh install script handles the chsh part optionally
    # We use the curl method for simplicity and reliability
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh installation complete."
else
    echo "✅ Oh My Zsh already installed. Skipping."
fi

## Step 2: Set Zsh as default shell (If not done by Oh My Zsh installer)
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "➡️ Setting Zsh as default shell for the current user..."
    if sudo chsh -s "$(which zsh)" "$(id -un)"; then
        echo "✅ Zsh set as default shell. You may need to log out/in."
    else
        echo "❌ ERROR: Failed to change default shell. Check sudo permissions."
    fi
else
    echo "✅ Zsh is already the default shell. Skipping."
fi

## Step 3: Install custom Zsh plugins
echo -e "\n➡️ Installing custom Zsh plugins..."
safe_clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
safe_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"

## Step 4: Create symlink for .zshrc
echo -e "\n➡️ Creating symlink for .zshrc..."
if [ -f "$SOURCE_ZSHRC" ]; then
    # Check if target file exists and is not already the correct symlink
    if [ -e "$TARGET_ZSHRC" ] && [ ! -L "$TARGET_ZSHRC" ]; then
        # Back up existing file if it's not a symlink
        echo "⚠️  Found existing non-symlink file at $TARGET_ZSHRC. Backing up to $TARGET_ZSHRC.bak"
        mv "$TARGET_ZSHRC" "$TARGET_ZSHRC.bak"
    fi
    
    # Create the symlink (force overwrite if existing symlink)
    ln -sf "$SOURCE_ZSHRC" "$TARGET_ZSHRC"
    echo "✅ Symlink created: $TARGET_ZSHRC -> $SOURCE_ZSHRC"
else
    echo "❌ ERROR: Source .zshrc file not found at $SOURCE_ZSHRC. Make sure your dotfiles repo is cloned."
fi

echo -e "\n\n🚀 Dotfiles setup complete! Please log out and log back in (or run 'exec zsh') to fully apply changes."