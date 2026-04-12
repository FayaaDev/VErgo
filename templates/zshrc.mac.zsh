# Enable Powerlevel10k instant prompt. Keep near the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

typeset -A ZI
ZI[BIN_DIR]="${HOME}/.zi/bin"
source "${ZI[BIN_DIR]}/zi.zsh"

# Keep the plugin manager available after zoxide takes over `zi`.
functions[ziplugin]=$functions[zi]

if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

# Completions need to be available before compinit runs.
ziplugin light zsh-users/zsh-completions

autoload -Uz compinit
compinit

autoload -Uz _zi
(( ${+_comps} )) && _comps[ziplugin]=_zi

ziplugin light romkatv/powerlevel10k
ziplugin light zsh-users/zsh-autosuggestions

alias ls="eza --icons=always"
eval "$(zoxide init zsh)"
alias cd="z"

alias pip="python3 -m pip"
alias pip3="python3 -m pip"

export PATH="$PATH:$HOME/.local/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

[ -d "$HOME/.antigravity/antigravity/bin" ] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"

if [[ -d "$HOME/Library/Android/sdk" ]]; then
  export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
  export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"
fi

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if command -v openclaw >/dev/null 2>&1; then
  source <(openclaw completion --shell zsh 2>/dev/null)
fi

if command -v agent-browser >/dev/null 2>&1; then
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
ziplugin light zdharma-continuum/fast-syntax-highlighting
