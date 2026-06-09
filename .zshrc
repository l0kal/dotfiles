# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ----------------------------------------------------------------------
# Oh My Zsh Configuration
# ----------------------------------------------------------------------

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# 1. THEME
# Highly customizable and fast theme. Requires a Nerd Font, which Codespaces
# usually support, especially in the VS Code desktop app.
# If you don't want to deal with fonts, use "agnoster" or "robbyrussell"
#ZSH_THEME="robbyrussell" 
ZSH_THEME="powerlevel10k/powerlevel10k" 
# ZSH_THEME="agnoster" # Use this if you install a Powerline/Nerd Font

# 2. PLUGINS
# Plugins are loaded from $ZSH/plugins/* and $ZSH_CUSTOM/plugins/*
plugins=(
  git
  docker
  docker-compose
  node
  yarn
  # Essential Productivity Plugins (Must be cloned to ZSH_CUSTOM/plugins)
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-npm-scripts-autocomplete
  # Navigation & History
  z
  history
  # Utility Plugins
  extract       # Universal archive extractor: use 'extract file.zip'
  sudo          # Press ESC twice to prepend 'sudo' to the current command
)

# Source Oh My Zsh. MUST be at the end of the config block.
source $ZSH/oh-my-zsh.sh

# ----------------------------------------------------------------------
# Custom Aliases & Functions (Your Personal Touches)
# ----------------------------------------------------------------------

# General Aliases
alias cls='clear'
alias ll='ls -alF' # Long listing, show all, classify files
alias lsa='ls -a'
alias ..='cd ..'
alias ...='cd ../..'

# Git Aliases (These supplement the 'git' plugin aliases)
alias glog='git log --oneline --decorate --all --graph'
alias gcl='git clone'
alias gpl='git pull'

# Codespace-specific aliases (If you use the 'code' CLI in the Codespace)
alias cdd='code .' 

# ----------------------------------------------------------------------
# Plugin Specific Configuration
# ----------------------------------------------------------------------

# Configure zsh-autosuggestions: Change color to something visible (e.g., grey)
# Note: fg=8 is a common muted grey.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

# ----------------------------------------------------------------------
# History Configuration
# ----------------------------------------------------------------------

# Commands you don't want saved to history (useful in Codespaces)
export HISTORY_IGNORE="& ls rm clear exit"

# Set history size
HISTSIZE=10000
SAVEHIST=10000

# Share history across sessions
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#source ~/.forward_ssh_agent.sh -q
