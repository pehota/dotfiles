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

## Claude Code

`~/.claude` holds the Claude Code rules (`MY_RULES.md`), profile and writing voice (`ME.md`, `ME_VOICE.md`), and the prompt nudges (`nudges/`).

`nudges/nudge.sh` is a `UserPromptSubmit` hook. It shows a one-line self-improvement nudge, at most once per pattern per day. It never blocks the prompt. State and hit log stay local in `~/.local/state/claude-nudges/`. Tests: `bash ~/.claude/nudges/test_nudge.sh`.

`settings.json` is not managed by chezmoi. Register the hook once per machine (needs `jq`) by adding this entry to `hooks.UserPromptSubmit`:

```json
{ "hooks": [{ "type": "command", "command": "[ -e ~/.claude/nudges/nudge.sh ] || exit 0; bash ~/.claude/nudges/nudge.sh", "timeout": 5 }] }
```

## Updating

```sh
chezmoi update
```
