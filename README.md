# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io).

## Clean install

### Prerequisites

- Arch Linux with [Omarchy](https://omarchy.org) installed
- `yay` AUR helper available
- `chezmoi` installed (`sudo pacman -S chezmoi`)

### Apply

```bash
chezmoi init --apply https://github.com/dapostolv/dotfiles
```

This single command will:

1. Clone this repo to `~/.local/share/chezmoi`
2. Install packages (`claude-code`, `bun-bin`, `ferdium`, `enpass-bin`, `wtype`) via `yay`
3. Apply all dotfiles to `~`
4. On Apple hardware: run `omarchy-mac-setup.sh` with sudo (once), which configures MacBook-specific keyboard, touchpad, and keybindings

### What gets configured

| File | Description |
|------|-------------|
| `~/.config/hypr/input.conf` | MacBook keyboard model, BG phonetic layout, `Ctrl+Space` to switch layouts |
| `~/.config/hypr/bindings.conf` | i3-style `Super+hjkl` navigation, `Ctrl+[` → Escape, workspace bindings |
| `~/.gitconfig` | Git identity and settings |
| `~/.gitignore` | Global gitignore |
| `~/Downloads/omarchy-mac-setup.sh` | One-shot Mac hardware setup script |

### Re-applying after changes

```bash
chezmoi apply
```

Run scripts only re-execute when their content changes (`run_onchange_`) or never again (`run_once_`).

### Editing dotfiles

```bash
chezmoi edit ~/.config/hypr/input.conf   # opens in $EDITOR
chezmoi re-add ~/.config/hypr/input.conf # sync live changes back to chezmoi
chezmoi diff                             # preview pending changes
```
