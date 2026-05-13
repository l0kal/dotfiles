#!/bin/bash

# --- Configuration ---
DOTFILES_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${OMZ_DIR}/custom"
SOURCE_ZSHRC="${DOTFILES_REPO_DIR}/.zshrc"
TARGET_ZSHRC="$HOME/.zshrc"

# --- Extension List ---
EXTENSIONS=(
    anysphere.csharp
    anysphere.cursorpyright
    bierner.markdown-preview-github-styles
    darkriszty.markdown-table-prettify
    davidanson.vscode-markdownlint
    dbaeumer.vscode-eslint
    editorconfig.editorconfig
    esbenp.prettier-vscode
    github.vscode-github-actions
    hashicorp.terraform
    mechatroner.rainbow-csv
    ms-azuretools.vscode-containers
    ms-azuretools.vscode-docker
    ms-dotnettools.vscode-dotnet-runtime
    ms-python.python
    ms-toolsai.jupyter
    ms-toolsai.jupyter-keymap
    ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags
    ms-toolsai.vscode-jupyter-slideshow
    redhat.vscode-yaml
    shd101wyy.markdown-preview-enhanced
    streetsidesoftware.code-spell-checker
    streetsidesoftware.code-spell-checker-norwegian-bokmal
    takumii.markdowntable
    vadimcn.vscode-lldb
    vue.volar
    yzhang.markdown-all-in-one
)

# --- Helper Functions ---

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

## Step 1: Install Oh My Zsh
if [ ! -d "$OMZ_DIR" ]; then
    echo "➡️ Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh installation complete."
else
    echo "✅ Oh My Zsh already installed. Skipping."
fi

## Step 2: Set Zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "➡️ Setting Zsh as default shell..."
    sudo chsh -s "$(which zsh)" "$(id -un)"
else
    echo "✅ Zsh is already the default shell."
fi

## Step 3: Install custom Zsh plugins
echo -e "\n➡️ Installing custom Zsh plugins..."
safe_clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
safe_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
safe_clone https://github.com/grigorii-zander/zsh-npm-scripts-autocomplete.git "${ZSH_CUSTOM}/plugins/zsh-npm-scripts-autocomplete"
safe_clone https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"

## Step 4: Create symlink for .zshrc
echo -e "\n➡️ Creating symlink for .zshrc..."
if [ -f "$SOURCE_ZSHRC" ]; then
    if [ -e "$TARGET_ZSHRC" ] && [ ! -L "$TARGET_ZSHRC" ]; then
        mv "$TARGET_ZSHRC" "$TARGET_ZSHRC.bak"
    fi
    ln -sf "$SOURCE_ZSHRC" "$TARGET_ZSHRC"
    echo "✅ Symlink created: $TARGET_ZSHRC"
fi

## Step 5: Install Cursor/VS Code Extensions
echo -e "\n➡️ Installing Editor Extensions..."

# Detect which binary to use (Cursor on local, Code on Codespaces)
if command -v cursor >/dev/null 2>&1; then
    EDITOR_BIN="cursor"
elif command -v code >/dev/null 2>&1; then
    EDITOR_BIN="code"
else
    EDITOR_BIN=""
    echo "⚠️ Neither 'cursor' nor 'code' CLI found. Skipping extension install."
fi

if [ -n "$EDITOR_BIN" ]; then
    echo "Using '$EDITOR_BIN' to install extensions..."
    for ext in "${EXTENSIONS[@]}"; do
        echo "Installing $ext..."
        $EDITOR_BIN --install-extension "$ext" --force
    done
    echo "✅ Extension installation process finished."
fi

echo -e "\n\n🚀 Dotfiles setup complete! Please log out and log back in (or run 'exec zsh') to fully apply changes."