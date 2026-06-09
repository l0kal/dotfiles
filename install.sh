#!/bin/bash

# --- Configuration ---
DOTFILES_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${OMZ_DIR}/custom"
SOURCE_ZSHRC="${DOTFILES_REPO_DIR}/.zshrc"
TARGET_ZSHRC="$HOME/.zshrc"

show_usage() {
        cat <<EOF
Usage: $(basename "$0") [all|zsh|extensions]...

Runs dotfiles setup steps.

Arguments:
    all         Run all setup steps (default when no args are provided)
    zsh         Run Zsh setup (Oh My Zsh, default shell, plugins, .zshrc copy)
    extensions  Install Cursor/VS Code extensions
    -h, --help  Show this help message
EOF
}

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
    redhat.vscode-yaml
    shd101wyy.markdown-preview-enhanced
    streetsidesoftware.code-spell-checker
    streetsidesoftware.code-spell-checker-norwegian-bokmal
    takumii.markdowntable
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

install_oh_my_zsh() {
    if [ ! -d "$OMZ_DIR" ]; then
        echo "➡️ Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        echo "✅ Oh My Zsh installation complete."
    else
        echo "✅ Oh My Zsh already installed. Skipping."
    fi
}

set_zsh_as_default_shell() {
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "➡️ Setting Zsh as default shell..."
        sudo chsh -s "$(which zsh)" "$(id -un)"
    else
        echo "✅ Zsh is already the default shell."
    fi
}

install_custom_zsh_plugins() {
    echo -e "\n➡️ Installing custom Zsh plugins..."
    safe_clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    safe_clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    safe_clone https://github.com/grigorii-zander/zsh-npm-scripts-autocomplete.git "${ZSH_CUSTOM}/plugins/zsh-npm-scripts-autocomplete"
    safe_clone https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"
}

copy_zshrc() {
    echo -e "\n➡️ Copying .zshrc..."
    if [ -f "$SOURCE_ZSHRC" ]; then
        if [ -L "$TARGET_ZSHRC" ]; then
            rm -f "$TARGET_ZSHRC"
            echo "➡️ Removed existing symlink: $TARGET_ZSHRC"
        elif [ -e "$TARGET_ZSHRC" ]; then
            cp "$TARGET_ZSHRC" "$TARGET_ZSHRC.bak"
            echo "➡️ Backed up existing file to: $TARGET_ZSHRC.bak"
        fi

        cp "$SOURCE_ZSHRC" "$TARGET_ZSHRC"
        echo "✅ Copied file to: $TARGET_ZSHRC"
    else
        echo "❌ ERROR: Source .zshrc not found at $SOURCE_ZSHRC"
    fi
}

install_editor_extensions() {
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
}

run_zsh_setup() {
    install_oh_my_zsh
    set_zsh_as_default_shell
    install_custom_zsh_plugins
    copy_zshrc
}

run_all() {
    run_zsh_setup
    install_editor_extensions
}

# --- Argument Parsing ---
RUN_ZSH=false
RUN_EXTENSIONS=false

if [ $# -eq 0 ]; then
    RUN_ZSH=true
    RUN_EXTENSIONS=true
else
    for arg in "$@"; do
        case "$arg" in
            all)
                RUN_ZSH=true
                RUN_EXTENSIONS=true
                ;;
            zsh)
                RUN_ZSH=true
                ;;
            extensions|vscode-extensions|vscode)
                RUN_EXTENSIONS=true
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "❌ Unknown argument: $arg"
                show_usage
                exit 1
                ;;
        esac
    done
fi

# --- Run Selected Steps ---
if [ "$RUN_ZSH" = true ]; then
    run_zsh_setup
fi

if [ "$RUN_EXTENSIONS" = true ]; then
    install_editor_extensions
fi

echo -e "\n\n🚀 Dotfiles setup complete! Please log out and log back in (or run 'exec zsh') to fully apply changes."