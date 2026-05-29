# Enable Powerlevel10k instant prompt. Keep near the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Disable the gitstatus background worker when there's no job control
# (e.g., tools that open an interactive shell without a TTY).
if [[ -o interactive ]] && ! [[ -t 0 && -t 1 ]]; then
  typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true
fi

typeset -A ZI
ZI[BIN_DIR]="${HOME}/.zi/bin"
source "${ZI[BIN_DIR]}/zi.zsh"

# Keep the plugin manager available after zoxide takes over `zi`.
functions[ziplugin]=$functions[zi]

if [[ -o interactive ]]; then
  [[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)

  # Completions must load before compinit runs.
  ziplugin light zsh-users/zsh-completions

  autoload -Uz compinit
  # Rebuild dump at most once per 24h for faster interactive startup.
  _zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
  if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
    compinit -d "$_zcompdump"
  else
    compinit -C -d "$_zcompdump"
  fi
  unset _zcompdump

  autoload -Uz _zi
  (( ${+_comps} )) && _comps[ziplugin]=_zi

  ziplugin light romkatv/powerlevel10k
  ziplugin light zsh-users/zsh-autosuggestions

  alias ls="eza --icons=always"
  eval "$(zoxide init zsh)"
  alias cd="z"
fi

alias pip="python3 -m pip"
alias pip3="python3 -m pip"
alias vim="nvim"

export EDITOR="nvim"
export VISUAL="nvim"

export NVM_DIR="$HOME/.nvm"
if [[ -o interactive ]]; then
  [[ -s "$NVM_DIR/nvm.sh" ]]          && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

  [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

  _disable_terminal_mouse_reporting() {
    [[ -t 1 ]] || return
    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1005l\e[?1006l\e[?1015l'
  }

  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _disable_terminal_mouse_reporting
fi

if [[ -o interactive ]] && command -v openclaw >/dev/null 2>&1; then
  source <(openclaw completion --shell zsh 2>/dev/null)
fi

if [[ -o interactive ]] && command -v agent-browser >/dev/null 2>&1; then
  if [[ -f "$HOME/MyProjects/agenting/browser-agent/stream.html" ]] && command -v open >/dev/null 2>&1; then
    alias view-browser="open $HOME/MyProjects/agenting/browser-agent/stream.html"
  fi

  agent-browser() {
    if [[ "$1" == "stream" ]]; then
      shift
      export AGENT_BROWSER_STREAM_PORT=${AGENT_BROWSER_STREAM_PORT:-9223}

      echo 'Enter the port number to open (e.g., 3000, 8080):'
      read -r target_port

      if [[ -z "$target_port" ]]; then
        target_url='about:blank'
      else
        target_url="http://localhost:$target_port"
      fi

      command agent-browser open "$target_url" wait 9999999 "$@"
    elif [[ "$1" == "view" ]]; then
      if [[ -f "$HOME/MyProjects/agenting/browser-agent/stream.html" ]] && command -v open >/dev/null 2>&1; then
        open "$HOME/MyProjects/agenting/browser-agent/stream.html"
      fi
    else
      command agent-browser "$@"
    fi
  }

  alias browser-agent="agent-browser"
fi

# Keep syntax highlighting last so it sees the final widget state.
if [[ -o interactive ]]; then
  ziplugin light zdharma-continuum/fast-syntax-highlighting
fi

# --- user overlay ---
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"   # pipx

# gws: prefer encrypted credential store over OAuth client_secret.json
if [[ "${GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE:-}" == "$HOME/.config/gws/client_secret.json" ]]; then
  unset GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE
fi

## beads dolt credentials
export DOLT_REMOTE_USER="fayaadev"
if [[ -z "${DOLT_REMOTE_PASSWORD:-}" && -f "$HOME/.config/beads/dolt.env" ]]; then
  . "$HOME/.config/beads/dolt.env"
fi
# Beads helpers
beads_pullpush() {
  bd dolt pull --json && bd dolt push --json
}
beads_start() {
  bd dolt pull --json && bd ready --json
}
beads_end() {
  bd dolt push --json
}

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/fayaamini/projy/aiterminal/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/fayaamini/projy/aiterminal/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/fayaamini/projy/aiterminal/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/fayaamini/projy/aiterminal/google-cloud-sdk/completion.zsh.inc'; fi
