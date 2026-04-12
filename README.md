# power10k

Fayaa's portable terminal bootstrap for macOS and Ubuntu.

## One-line install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/FayaaDev/power10k/main/install.sh)"
```

## What it installs

- `zsh`
- `zi`
- `powerlevel10k`
- `zsh-autosuggestions`
- `fast-syntax-highlighting`
- `zsh-completions`
- `eza`
- `zoxide`
- `fzf`
- your exact `~/.p10k.zsh`
- a portable `~/.zshrc` for macOS or Ubuntu
- Meslo Nerd Font files

## Behavior

- Supports macOS and Ubuntu-style Linux systems with `apt`
- Backs up existing `~/.zshrc` and `~/.p10k.zsh` into `~/.backup-power10k/<timestamp>/`
- Preserves optional integrations if they already exist on the machine:
  - `OpenClaw`
  - `bun`
  - `nvm`
  - `opencode`
  - Docker completions
  - Android SDK paths

## After install

```bash
exec zsh
```

If the prompt icons do not render correctly, set your terminal font to `MesloLGS NF`.

## Repository layout

- `install.sh`: hosted installer entrypoint
- `files/.p10k.zsh`: exact prompt config
- `templates/zshrc.mac.zsh`: macOS shell template
- `templates/zshrc.ubuntu.zsh`: Ubuntu shell template

## Publishing

The one-line install command expects these files to be pushed to the `main` branch of `FayaaDev/power10k`.
