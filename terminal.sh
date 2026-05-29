#!/usr/bin/env bash

set -euo pipefail

OWNER="${VERGO_REPO_OWNER:-${POWER10K_REPO_OWNER:-FayaaDev}}"
REPO="${VERGO_REPO_NAME:-${POWER10K_REPO_NAME:-VErgo}}"
BRANCH="${VERGO_REPO_BRANCH:-${POWER10K_REPO_BRANCH:-main}}"
RAW_BASE="${VERGO_RAW_BASE:-${POWER10K_RAW_BASE:-https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}}}"

log() {
  printf '[vergo] %s\n' "$*"
}

warn() {
  printf '[vergo] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[vergo] ERROR: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

download_to() {
  local url="$1"
  local path="$2"
  curl -fsSL "$url" -o "$path"
}

backup_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    cp -a "$path" "$BACKUP_DIR/$(basename "$path")"
  fi
}

brew_cmd() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
  elif [ -x /opt/homebrew/bin/brew ]; then
    printf '/opt/homebrew/bin/brew\n'
  elif [ -x /usr/local/bin/brew ]; then
    printf '/usr/local/bin/brew\n'
  else
    return 1
  fi
}

ensure_homebrew() {
  if brew_cmd >/dev/null 2>&1; then
    return
  fi

  log 'Installing Homebrew'
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_macos_packages() {
  ensure_homebrew

  local brew
  brew="$(brew_cmd)"

  log 'Installing macOS packages with Homebrew'
  "$brew" install zsh git curl eza zoxide fzf gh tmux neovim node chezmoi cloudflared cocoapods
  "$brew" install --cask wezterm font-jetbrains-mono font-jetbrains-mono-nerd-font 1password-cli
}

install_ubuntu_packages() {
  need_cmd sudo
  need_cmd apt-get

  log 'Installing Ubuntu packages with apt'
  sudo apt-get update
  sudo apt-get install -y zsh git curl eza zoxide fzf gh tmux neovim nodejs npm
}

install_zi() {
  need_cmd git

  log 'Installing Zi plugin manager'
  mkdir -p "$HOME/.zi"

  if [ -d "$HOME/.zi/bin/.git" ]; then
    git -C "$HOME/.zi/bin" pull --ff-only
  else
    rm -rf "$HOME/.zi/bin"
    git clone --depth 1 https://github.com/z-shell/zi.git "$HOME/.zi/bin"
  fi
}

install_fonts() {
  local font_dir
  local names
  local base
  local i

  base='https://github.com/romkatv/powerlevel10k-media/raw/master'
  names=(
    'MesloLGS NF Regular.ttf'
    'MesloLGS NF Bold.ttf'
    'MesloLGS NF Italic.ttf'
    'MesloLGS NF Bold Italic.ttf'
  )

  case "$PLATFORM" in
    mac)
      font_dir="$HOME/Library/Fonts"
      ;;
    ubuntu)
      font_dir="$HOME/.local/share/fonts"
      ;;
    *)
      return
      ;;
  esac

  mkdir -p "$font_dir"
  log "Installing Meslo Nerd Font files into $font_dir"

  for i in "${names[@]}"; do
    download_to "$base/${i// /%20}" "$font_dir/$i"
  done

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir" >/dev/null 2>&1 || true
  fi
}

install_shell_files() {
  local template="zshrc.${PLATFORM}.zsh"
  local env_template="zshenv.${PLATFORM}.zsh"

  log 'Backing up existing shell files'
  if [ "$PLATFORM" = 'mac' ]; then
    backup_if_exists "$HOME/.zprofile"
  fi
  backup_if_exists "$HOME/.zshrc"
  backup_if_exists "$HOME/.zshenv"
  backup_if_exists "$HOME/.p10k.zsh"
  backup_if_exists "$HOME/.gitconfig"
  backup_if_exists "$HOME/.tmux.conf"

  log 'Installing shell templates'
  if [ "$PLATFORM" = 'mac' ]; then
    download_to "$RAW_BASE/files/.zprofile" "$HOME/.zprofile"
  fi
  download_to "$RAW_BASE/templates/$template"     "$HOME/.zshrc"
  download_to "$RAW_BASE/templates/$env_template" "$HOME/.zshenv"
  download_to "$RAW_BASE/files/.p10k.zsh"         "$HOME/.p10k.zsh"
  download_to "$RAW_BASE/files/.gitconfig"        "$HOME/.gitconfig"
  download_to "$RAW_BASE/files/.tmux.conf"        "$HOME/.tmux.conf"
  if [ "$PLATFORM" = 'mac' ]; then
    chmod 644 "$HOME/.zprofile"
  fi
  chmod 644 "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.p10k.zsh" "$HOME/.gitconfig" "$HOME/.tmux.conf"
}

install_wezterm_config() {
  log 'Backing up existing WezTerm config'
  backup_if_exists "$HOME/.wezterm.lua"

  log 'Installing WezTerm config'
  download_to "$RAW_BASE/files/.wezterm.lua" "$HOME/.wezterm.lua"
  chmod 644 "$HOME/.wezterm.lua"
}

install_nvim_config() {
  local rel
  local dest

  log 'Backing up existing Neovim config'
  backup_if_exists "$HOME/.config/nvim"

  log 'Installing Neovim config'
  for rel in \
    'init.lua' \
    'lazyvim.json' \
    'lazy-lock.json' \
    'stylua.toml' \
    '.gitignore' \
    '.neoconf.json' \
    'lua/config/autocmds.lua' \
    'lua/config/keymaps.lua' \
    'lua/config/lazy.lua' \
    'lua/config/options.lua' \
    'lua/plugins/example.lua'
  do
    dest="$HOME/.config/nvim/$rel"
    mkdir -p "$(dirname "$dest")"
    download_to "$RAW_BASE/files/.config/nvim/$rel" "$dest"
    chmod 644 "$dest"
  done
}

report_shell_status() {
  local zsh_path
  zsh_path="$(command -v zsh || true)"

  [ -n "$zsh_path" ] || die 'zsh was not installed correctly'

  if [ "${SHELL:-}" != "$zsh_path" ]; then
    warn "Default shell is ${SHELL:-unknown}. Run: chsh -s $zsh_path"
  fi
}

need_cmd curl

case "$(uname -s)" in
  Darwin)
    PLATFORM='mac'
    install_macos_packages
    ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      PLATFORM='ubuntu'
      install_ubuntu_packages
    else
      die 'Unsupported Linux distro. This installer currently supports Ubuntu-style systems with apt.'
    fi
    ;;
  *)
    die 'Unsupported operating system. This installer currently supports macOS and Ubuntu.'
    ;;
esac

BACKUP_DIR="$HOME/.backup-vergo/$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

install_zi
install_fonts
install_shell_files
install_wezterm_config
install_nvim_config
report_shell_status

log "Backups saved to $BACKUP_DIR"
log 'Install complete'
log 'Next steps:'
log '1. Restart your shell with: exec zsh'
log '2. Set your terminal font to MesloLGS NF for the exact Powerlevel10k look'
log '3. Launch WezTerm — it will pick up ~/.wezterm.lua automatically'
