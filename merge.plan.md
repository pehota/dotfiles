# Dotfiles Merge Plan: `macos` + `omarchy` → `main`

## Goal

Single branch managing dotfiles for both macOS and Arch Linux (omarchy), using chezmoi for all OS-specific logic.

---

## Step 1 — Create working branch ✓

```bash
git checkout -b main origin/macos
```

---

## Step 2 — Bring files from `omarchy` branch ✓

Cherry-pick or copy these files (they don't exist in `macos`):

- `dot_config/hypr/` (all files)
- `dot_config/waybar/config.jsonc`
- `dot_config/waybar/style.css`
- `dot_config/mako/symlink_config`
- `dot_config/omarchy/` (all files)
- `dot_git-templates/hooks/executable_pre-push`
- `Downloads/executable_omarchy-mac-setup.sh`
- `run_once_after_omarchy-mac-setup.sh.tmpl`

```bash
git checkout origin/omarchy -- \
  dot_config/hypr \
  dot_config/waybar \
  dot_config/mako \
  dot_config/tmux \
  dot_config/omarchy \
  dot_git-templates \
  Downloads \
  run_once_after_omarchy-mac-setup.sh.tmpl
```

---

## Step 3 — Create `.chezmoidata/packages.yaml` ✓

```bash
mkdir -p .chezmoidata
```

Replace the omarchy version with the unified cross-platform version:

```yaml
packages:
  arch:
    - claude-code
    - bun-bin
    - ferdium
    - enpass-bin
    - wtype
    - eza
    - fnm
    - fish
    - neovim
    - tmux
    - chezmoi
    - bat
    - direnv
    - fzf
    - python
    - ripgrep
  darwin:
    formulas:
      - chezmoi
      - bash
      - bat
      - direnv
      - eza
      - fish
      - fnm
      - fzf
      - neovim
      - python@3.10
      - ripgrep
      - tmux
      - bun
      - claude-code
    casks:
      - alacritty
      - ferdium
      - enpass
      - font-fira-code-nerd-font
      - font-jetbrains-mono-nerd-font
      - karabiner-elements
      - raycast
      - zed
```

---

## Step 4 — Delete files no longer needed ✓

```bash
rm Brewfile
rm run_once_after_install-nvim-deps.sh   # elm LSP removed
rm run_onchange_after_install-brewfile.sh.tmpl  # replaced by unified packages script
rm -f run_onchange_arch-install-packages.sh.tmpl   # merged into unified packages script; only exists on omarchy branch
rm dot_tmux.conf                                # replaced by dot_config/tmux/tmux.conf.tmpl
```

---

## Step 5 — Update `.chezmoiignore` ✓

Replace current content with OS-gated version, preserving all unconditional entries from the existing file:

```
# Repo management files — not dotfiles
scripts/
assets/
.backup/
migrate-to-chezmoi.plan.md
2024-12-26.rayconfig

# tmux — plugins installed by run_once_after_install-tpm.sh
dot_tmux/plugins/

# nvim — only manage custom lua files; everything else is LazyVim boilerplate
dot_config/nvim/dot_git/
dot_config/nvim/init.lua
dot_config/nvim/lazy-lock.json
dot_config/nvim/lazyvim.json
dot_config/nvim/dot_gitignore
dot_config/nvim/dot_neoconf.json
dot_config/nvim/stylua.toml
dot_config/nvim/LICENSE
dot_config/nvim/README.md
dot_config/nvim/spell/

# fish — plugin-generated files (managed by fisher, not by us)
dot_config/fish/fish_variables
dot_config/fish/fishd.tmp.*
dot_config/fish/empty_fish_variables*
dot_config/fish/completions/symlink_docker.fish
dot_config/fish/completions/symlink_kubectl.fish
dot_config/fish/conf.d/fish_frozen_theme.fish
dot_config/fish/conf.d/fish-ssh-agent.fish
dot_config/fish/conf.d/fnm.fish
dot_config/fish/conf.d/fzf.fish
dot_config/fish/conf.d/pisces.fish
dot_config/fish/conf.d/z.fish
dot_config/fish/functions/__bass.py
dot_config/fish/functions/__fzf_*.fish
dot_config/fish/functions/__fzfcmd.fish
dot_config/fish/functions/__ssh_agent_*.fish
dot_config/fish/functions/__z*.fish
dot_config/fish/functions/_pisces_*.fish
dot_config/fish/functions/bass.fish
dot_config/fish/functions/fenv.fish
dot_config/fish/functions/fenv.main.fish
dot_config/fish/functions/fisher.fish
dot_config/fish/themes/

# karabiner — auto-generated backups
dot_config/private_karabiner/private_automatic_backups/

# zed — backup file
dot_config/zed/private_settings_backup.json

# Linux-only
{{ if ne .chezmoi.os "linux" }}
dot_config/hypr
dot_config/waybar
dot_config/mako
dot_config/omarchy
Downloads
run_once_after_omarchy-mac-setup.sh.tmpl
{{ end }}

# macOS-only
{{ if ne .chezmoi.os "darwin" }}
dot_config/alacritty
dot_config/private_karabiner
dot_config/zed
run_once_before_install-homebrew.sh
{{ end }}
```

---

## Step 6 — Unify package installation script ✓

Delete old scripts, create `run_onchange_after_install-packages.sh.tmpl`:

```bash
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/sh
# Packages: {{ .packages.darwin.formulas | join " " }} {{ .packages.darwin.casks | join " " }}
{{ range .packages.darwin.formulas -}}
brew install {{ . }}
{{ end -}}
{{ range .packages.darwin.casks -}}
brew install --cask {{ . }}
{{ end -}}

{{ else if eq .chezmoi.os "linux" -}}
#!/bin/bash
# Packages: {{ .packages.arch | join " " }}
set -euo pipefail
yay -S --needed --noconfirm {{ .packages.arch | join " " }}
{{ end -}}
```

---

## Step 7 — Update TPM install script ✓

Update `run_once_after_install-tpm.sh` — standardize path to `~/.config/tmux` on both OSes (no template needed):

```bash
#!/bin/sh
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
[ -d "$TPM_DIR" ] && exit 0
git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
```

---

## Step 8 — Tmux config ✓

Use the omarchy version (`dot_config/tmux/tmux.conf`) as-is — it already uses `~/.config/tmux/plugins/tpm/tpm`. No template needed.

Delete `dot_tmux.conf`.

---

## Step 9 — Unify kitty config ✓

Rename `dot_config/kitty/kitty.conf` → `dot_config/kitty/kitty.conf.tmpl`.

Use the full `macos` kitty.conf as the base. Replace OS-specific lines with conditionals as follows:

**At the top** (before the Font section), insert:

```
{{ if eq .chezmoi.os "linux" -}}
include ~/.config/omarchy/current/theme/kitty.conf
{{ end -}}
```

**Font section** — replace the two font lines:

```
{{ if eq .chezmoi.os "linux" -}}
font_family JetBrainsMono Nerd Font
font_size 9.0
{{ else -}}
font_family FiraCode Nerd Font
font_size 12.0
{{ end -}}
```

**Window padding** — replace `window_padding_width 0.0`:

```
{{ if eq .chezmoi.os "linux" -}}
window_padding_width 14
hide_window_decorations yes
{{ else -}}
window_padding_width 0.0
{{ end -}}
```

**macOS-only block** — wrap the existing macOS lines:

```
{{ if eq .chezmoi.os "darwin" -}}
macos_option_as_alt yes
map alt+left send_text all \x1b\x62
map alt+right send_text all \x1b\x66
{{ end -}}
```

**Linux-only block** — add before `include ./gruvbox-dark.conf`:

```
{{ if eq .chezmoi.os "linux" -}}
map ctrl+insert copy_to_clipboard
map shift+insert paste_from_clipboard
allow_remote_control yes
cursor_shape block
cursor_blink_interval 0
shell_integration no-cursor
enable_audio_bell no
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted
tab_title_template {title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}
{{ end -}}
```

All other settings (`confirm_os_window_close`, `copy_on_select`, `scrollback_pager`, `enabled_layouts`, layout keybindings, etc.) remain unconditional — they are shared across both OSes.

---

## Step 10 — Update fish plugins script ✓

Edit `run_onchange_after_install-fish-plugins.sh.tmpl` — remove `brew install fnm` line (fnm now installed via packages step):

```bash
#!/bin/sh
# hash: {{ include "dot_config/fish/fish_plugins" | sha256sum }}

fish -c "functions -q fisher || curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fish -c "fisher update"

FISH_PATH="$(command -v fish)"
if [ "$SHELL" != "$FISH_PATH" ]; then
  grep -qF "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells
  chsh -s "$FISH_PATH"
fi
```

---

## Step 11 — Verify with chezmoi ✓

```bash
chezmoi doctor
chezmoi diff   # should show no unintended changes on current machine
```

---

## Step 12 — Rename and push ✓

```bash
git add -A
git commit -m "Merge macos and omarchy into unified cross-platform dotfiles"
git push origin main
```

Set `main` as default branch on remote, delete `macos` and `omarchy` branches.

---

## File summary

| Action                | Files                                                                                                                                                               |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Added from omarchy    | `dot_config/hypr/`, `dot_config/waybar/`, `dot_config/mako/`, `dot_config/omarchy/`, `dot_git-templates/`, `Downloads/`, `run_once_after_omarchy-mac-setup.sh.tmpl` |
| Created               | `.chezmoidata/packages.yaml`, `run_onchange_after_install-packages.sh.tmpl`, `dot_config/tmux/tmux.conf.tmpl`                                                       |
| Converted to template | `dot_config/kitty/kitty.conf` → `.tmpl`                                                                                                                             |
| Modified              | `.chezmoiignore`, `run_onchange_after_install-fish-plugins.sh.tmpl`                                                                                                 |
| Deleted               | `Brewfile`, `dot_tmux.conf`, `run_once_after_install-nvim-deps.sh`, `run_onchange_after_install-brewfile.sh.tmpl`, `run_onchange_arch-install-packages.sh.tmpl`     |
