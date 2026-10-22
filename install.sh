#!/bin/bash

# --- Configuration ---
DOTFILES_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMZ_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${OMZ_DIR}/custom"
SOURCE_ZSHRC="${DOTFILES_REPO_DIR}/.zshrc"
TARGET_ZSHRC="$HOME/.zshrc"
CURSOR_SOURCE_DIR="${DOTFILES_REPO_DIR}/cursor"
CURSOR_CONFIG_FILES=(settings.json keybindings.json)

show_usage() {
        cat <<EOF
Usage: $(basename "$0") [all|zsh|extensions|cursor]...

Runs dotfiles setup steps.

Arguments:
    all         Run all setup steps (default when no args are provided)
    zsh         Run Zsh setup (Oh My Zsh, default shell, plugins, .zshrc copy)
    extensions  Install Cursor/VS Code extensions
    cursor      Copy Cursor user settings and keybindings from the repo
    -h, --help  Show this help message

Environment:
    CURSOR_USER_DIR  Override the target Cursor User directory
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

is_wsl() {
    grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null \
        || [ -n "${WSL_DISTRO_NAME:-}" ] \
        || [ -n "${WSLENV:-}" ]
}

get_windows_username() {
    local win_user=""

    if command -v cmd.exe >/dev/null 2>&1; then
        win_user="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')"
    elif command -v whoami.exe >/dev/null 2>&1; then
        win_user="$(whoami.exe 2>/dev/null | tr -d '\r\n')"
    fi

    if [ -n "$win_user" ] && [ -d "/mnt/c/Users/$win_user" ]; then
        echo "$win_user"
    fi
}

get_wsl_cursor_user_dir() {
    local win_user cursor_dir user_home

    win_user="$(get_windows_username)"
    if [ -n "$win_user" ]; then
        echo "/mnt/c/Users/${win_user}/AppData/Roaming/Cursor/User"
        return 0
    fi

    for cursor_dir in /mnt/c/Users/*/AppData/Roaming/Cursor/User; do
        if [ -d "$cursor_dir" ]; then
            echo "$cursor_dir"
            return 0
        fi
    done

    for user_home in /mnt/c/Users/*/; do
        win_user="$(basename "$user_home")"
        case "$win_user" in
            "All Users"|Default|"Default User"|Public) continue ;;
        esac
        echo "/mnt/c/Users/${win_user}/AppData/Roaming/Cursor/User"
        return 0
    done
}

get_cursor_user_dir() {
    if [ -n "${CURSOR_USER_DIR:-}" ]; then
        echo "$CURSOR_USER_DIR"
        return 0
    fi

    if is_wsl && [ -d /mnt/c/Users ]; then
        local wsl_cursor_dir
        wsl_cursor_dir="$(get_wsl_cursor_user_dir)"
        if [ -n "$wsl_cursor_dir" ]; then
            echo "$wsl_cursor_dir"
            return 0
        fi
        echo "⚠️ WSL detected but Windows user profile not found. Falling back to Linux Cursor path." >&2
    fi

    echo "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User"
}

copy_cursor_config_file() {
    local filename=$1
    local target_dir=$2
    local source="${CURSOR_SOURCE_DIR}/${filename}"
    local target="${target_dir}/${filename}"

    if [ ! -f "$source" ]; then
        echo "⚠️ Source not found, skipping: $source"
        return 0
    fi

    mkdir -p "$target_dir"

    if [ -L "$target" ]; then
        rm -f "$target"
        echo "➡️ Removed existing symlink: $target"
    elif [ -e "$target" ]; then
        cp "$target" "${target}.bak"
        echo "➡️ Backed up existing file to: ${target}.bak"
    fi

    if cp "$source" "$target"; then
        echo "✅ Copied $filename to: $target"
    else
        echo "❌ ERROR: Failed to copy $filename to: $target"
        return 1
    fi
}

install_cursor_settings() {
    echo -e "\n➡️ Installing Cursor user settings..."

    if [ ! -d "$CURSOR_SOURCE_DIR" ]; then
        echo "❌ ERROR: Cursor config directory not found at $CURSOR_SOURCE_DIR"
        return 1
    fi

    local cursor_user_dir
    cursor_user_dir="$(get_cursor_user_dir)"
    echo "Using Cursor User directory: $cursor_user_dir"

    local filename
    for filename in "${CURSOR_CONFIG_FILES[@]}"; do
        copy_cursor_config_file "$filename" "$cursor_user_dir"
    done

    echo "✅ Cursor settings installation complete."
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
    install_cursor_settings
    install_editor_extensions
}

# --- Argument Parsing ---
RUN_ZSH=false
RUN_CURSOR=false
RUN_EXTENSIONS=false

if [ $# -eq 0 ]; then
    RUN_ZSH=true
    RUN_CURSOR=true
    RUN_EXTENSIONS=true
else
    for arg in "$@"; do
        case "$arg" in
            all)
                RUN_ZSH=true
                RUN_CURSOR=true
                RUN_EXTENSIONS=true
                ;;
            zsh)
                RUN_ZSH=true
                ;;
            cursor)
                RUN_CURSOR=true
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

if [ "$RUN_CURSOR" = true ]; then
    install_cursor_settings
fi

if [ "$RUN_EXTENSIONS" = true ]; then
    install_editor_extensions
fi

echo -e "\n\n🚀 Dotfiles setup complete! Please log out and log back in (or run 'exec zsh') to fully apply changes."