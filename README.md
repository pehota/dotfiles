# dotfiles

Personal dotfiles for macOS and Arch Linux (omarchy), managed with [chezmoi](https://chezmoi.io).

## Quick start

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply pehota
```

This will install chezmoi and apply the dotfiles in one step.

## What's included

| Config                | macOS | Linux |
| --------------------- | :---: | :---: |
| kitty                 |   ✓   |   ✓   |
| fish + fisher plugins |   ✓   |   ✓   |
| neovim (LazyVim)      |   ✓   |   ✓   |
| tmux + TPM            |   ✓   |   ✓   |
| alacritty             |   ✓   |       |
| zed                   |   ✓   |       |
| karabiner-elements    |   ✓   |       |
| raycast               |   ✓   |       |
| hyprland              |       |   ✓   |
| waybar                |       |   ✓   |
| mako                  |       |   ✓   |
| omarchy               |       |   ✓   |

## How it works

OS-specific logic is handled via chezmoi templates and `.chezmoiignore`. Package installation runs automatically on `chezmoi apply`:

- **macOS**: Homebrew formulas + casks
- **Arch Linux**: `yay` packages

Scripts that run automatically:

| Script                                            | When                                             |
| ------------------------------------------------- | ------------------------------------------------ |
| `run_once_before_install-homebrew.sh`             | Once, before apply (macOS only)                  |
| `run_onchange_after_install-packages.sh.tmpl`     | When `packages.yaml` changes                     |
| `run_onchange_after_install-fish-plugins.sh.tmpl` | When `fish_plugins` changes                      |
| `run_once_after_install-tpm.sh`                   | Once, clones TPM to `~/.config/tmux/plugins/tpm` |
| `run_once_after_omarchy-mac-setup.sh.tmpl`        | Once, on MacBooks running omarchy (Linux only)   |

## Updating

```sh
chezmoi update
```
