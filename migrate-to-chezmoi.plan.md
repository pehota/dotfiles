# Chezmoi Migration Plan

## Context

**Repo:** `~/.dotfiles`  
**Branch:** `macos`  
**Date:** 2026-04-30  

### Current setup

| Aspect | Detail |
|---|---|
| Mechanism | GNU Stow + custom bash hooks |
| Entry point | `scripts/install.sh` |
| Package installer | `scripts/install-packages.sh` |
| Package root | `dotfiles/<pkg>/[content/]<mirror-of-home>` |
| Hooks | `pre-install` / `post-install` shell scripts inside each package dir |
| Templating | None — all files are static |
| Secrets | None detected |

### Package inventory

| Package | Hook? | Notes |
|---|---|---|
| `alacritty` | No | Pure static config |
| `bash` | No | `.bash_profile` |
| `fish` | `post-install` | fnm, fisher, fish_plugins, set default shell |
| `git` | No | `.gitconfig` with `includeIf` for work |
| `karabiner-elements` | No | Static JSON |
| `killport` | No | `.noinstall` marker — only stow, no brew install |
| `kitty` | No | Pure static config |
| `nvim` | `pre-install` + `post-install` | Pre: backup+rm existing, clone LazyVim starter. Post: npm globals (elm, elm-test) |
| `tmux` | `post-install` | Clone TPM |
| `raycast` | No | Untracked in git status — needs `chezmoi add` |
| `zed` | No | Untracked in git status — needs `chezmoi add` |

### Stow path → chezmoi path mapping rule

- Leading `.` → `dot_` prefix
- Directory separator preserved
- `dotfiles/<pkg>/content/` prefix stripped (content subdir is a stow workaround for hooks)
- `.tmpl` suffix added when templating is needed

Examples:

| Stow source | Chezmoi source |
|---|---|
| `dotfiles/git/.gitconfig` | `dot_gitconfig` |
| `dotfiles/fish/content/.config/fish/config.fish` | `dot_config/fish/config.fish` |
| `dotfiles/nvim/content/.config/nvim/lua/plugins/ai.lua` | `dot_config/nvim/lua/plugins/ai.lua` |
| `dotfiles/tmux/content/.tmux.conf` | `dot_tmux.conf` |
| `dotfiles/kitty/.config/kitty/kitty.conf` | `dot_config/kitty/kitty.conf` |

---

## Migration strategy

Run chezmoi alongside Stow. Migrate one package at a time, removing Stow symlinks as each is adopted. No big-bang rewrite.

---

## Phase 1 — Bootstrap (~1h)

1. Add chezmoi to `Brewfile`:
   ```
   brew "chezmoi"
   ```

2. Flatten repo structure — chezmoi source dir = repo root. Move all package contents up:
   ```sh
   # For packages with content/ subdir:
   cp -r dotfiles/fish/content/. .
   cp -r dotfiles/tmux/content/. .
   cp -r dotfiles/nvim/content/. .

   # For packages without content/:
   cp -r dotfiles/git/. .
   cp -r dotfiles/alacritty/. .
   cp -r dotfiles/kitty/. .
   cp -r dotfiles/bash/. .
   cp -r dotfiles/karabiner-elements/. .
   cp -r dotfiles/killport/. .
   ```

3. Rename files/dirs with leading `.` to chezmoi convention:
   ```sh
   # chezmoi add handles this automatically when using `chezmoi add <live-file>`
   # Recommended: use chezmoi add rather than manual rename
   ```

4. Initialize chezmoi pointing at this repo:
   ```sh
   chezmoi init --source ~/.dotfiles
   chezmoi diff   # verify before applying anything
   ```

---

## Phase 2 — File migration, package by package (~2h)

**Migration order** (simplest first):

For each package, the pattern is:
```sh
# 1. Add to chezmoi source WHILE stow symlink still exists (reads through it)
chezmoi add ~/.<config-path>

# 2. Apply — replaces symlink with a real managed copy (--force overwrites symlink)
chezmoi apply --force ~/.<config-path>

# 3. Remove the now-redundant stow symlink (file already exists as real copy)
stow -D <pkg> -d ~/.dotfiles/dotfiles -t ~

# 4. Verify
chezmoi diff
```

> **WARNING:** Do NOT run `stow -D` before `chezmoi apply --force`. The symlink must
> exist when `chezmoi add` runs, otherwise the file is missing and the command fails.
> Migrate high-risk packages (fish, nvim) during a dedicated terminal session so you
> can restart the shell immediately after.

Order:
1. `alacritty`
2. `kitty`
3. `bash`
4. `zed`
5. `karabiner-elements`
6. `git`
7. `tmux` (before hook migration)
8. `fish` (before hook migration)
9. `nvim` (before hook migration)
10. `killport` — use `.chezmoiignore` for the `.noinstall` marker file; manage scripts normally

---

## Phase 3 — Hook migration (~2h)

Stow hooks → chezmoi `run_once_` / `run_onchange_` scripts.

Scripts live at the chezmoi source root. Naming convention:
- `run_once_before_<name>.sh` — runs once (hash-tracked), before apply
- `run_once_after_<name>.sh` — runs once, after apply
- `run_onchange_after_<name>.sh` — re-runs whenever file content changes

### nvim pre-install → `run_once_before_install-nvim.sh`

```sh
#!/bin/sh
# Guard: skip if already set up
[ -d "$HOME/.local/share/nvim" ] && exit 0

# Backup existing config
[ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
[ -d "$HOME/.local/share/nvim" ] && mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak"
[ -d "$HOME/.local/state/nvim" ] && mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak"
[ -d "$HOME/.cache/nvim" ] && mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bak"

git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"
```

### nvim post-install → `run_once_after_install-nvim-deps.sh`

```sh
#!/bin/sh
npm install -g elm elm-test
```

### fish post-install → `run_onchange_after_install-fish-plugins.sh`

Trigger re-run whenever fish_plugins changes:

```sh
#!/bin/sh
# Hash: {{ include "dot_config/fish/fish_plugins" | sha256sum }}
# (chezmoi re-runs this script when fish_plugins content changes)

# Install fnm if not present
command -v fnm >/dev/null 2>&1 || brew install fnm

# Install fisher if not present
fish -c "functions -q fisher || curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"

# Sync plugins
fish -c "fisher update"

# Set fish as default shell
grep -q "$(which fish)" /etc/shells || echo "$(which fish)" | sudo tee -a /etc/shells
[ "$SHELL" != "$(which fish)" ] && chsh -s "$(which fish)"
```

Note: This script needs `.tmpl` suffix to use the `include` template function:
`run_onchange_after_install-fish-plugins.sh.tmpl`

### tmux post-install → `run_once_after_install-tpm.sh`

```sh
#!/bin/sh
TPM_DIR="$HOME/.tmux/plugins/tpm"
[ -d "$TPM_DIR" ] && exit 0
git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
```

---

## Phase 4 — Templating (optional, ~1h)

Create `~/.config/chezmoi/chezmoi.toml` (not in repo — machine-local):

```toml
[data]
  email = "d.apostolov@gmail.com"
  work = false
```

Files that benefit from templating (rename to add `.tmpl` suffix):

| File | Template use |
|---|---|
| `dot_gitconfig.tmpl` | `email = {{ "{{" }} .email {{ "}}" }}` per machine |
| `dot_config/fish/config.fish.tmpl` | Conditionally source work-specific paths |

---

## Phase 5 — Replace install.sh (~1h)

| Current step | Chezmoi replacement |
|---|---|
| Install Homebrew | `run_once_before_install-homebrew.sh` |
| `brew bundle` | `run_onchange_after_install-brewfile.sh` (watches `Brewfile`) |
| `stow` each package | `chezmoi apply` |
| Per-package hooks | `run_once_` / `run_onchange_` scripts |

New `run_once_before_install-homebrew.sh`:
```sh
#!/bin/sh
command -v brew >/dev/null 2>&1 && exit 0
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

New `run_onchange_after_install-brewfile.sh`:
```sh
#!/bin/sh
# Brewfile hash: {{ include "Brewfile" | sha256sum }}
brew bundle --file="{{ "{{" }} .chezmoi.sourceDir {{ "}}" }}/Brewfile"
```

New machine bootstrap (single command):
```sh
chezmoi init --apply git@github.com:<user>/dotfiles.git
```

---

## Phase 6 — Cleanup (~30m)

- Remove `scripts/install-packages.sh`
- Remove all `pre-install` / `post-install` files
- Remove `stow` from `Brewfile`
- Remove `dotfiles/` subdirectory after all packages migrated
- Keep `scripts/utils.sh` only if sourced by run scripts
- Archive or delete `.backup/` (chezmoi handles backups via `chezmoi diff`)
- Add `.chezmoiignore` for files to exclude:
  ```
  assets/
  migrate-to-chezmoi.plan.md
  2024-12-26.rayconfig
  ```

---

## Risks & gotchas

| Risk | Mitigation |
|---|---|
| nvim pre-install wipes config | Idempotency guard (`[ -d ... ] && exit 0`) already in plan above |
| `fish_variablesqkMDAjepGb` stray file in git status | Investigate before migrating fish dir — likely a corrupted fish_variables file |
| `run_onchange_` scripts need `.tmpl` suffix for template functions | Remember to add `.tmpl` when using `{{ "{{" }} include ... {{ "}}" }}` |
| chezmoi apply vs stow coexistence | Stow symlinks and chezmoi-managed files conflict — always `stow -D` before `chezmoi add` |
| `killport/.noinstall` has no chezmoi equivalent | Add to `.chezmoiignore` |
| Untracked `raycast/` and `zed/` dirs | Add with `chezmoi add ~/.config/raycast` etc. during Phase 2 |

---

## Effort estimate

| Phase | Effort |
|---|---|
| 1 — Bootstrap & restructure | ~1h |
| 2 — File migration (10 packages) | ~2h |
| 3 — Hook migration (4 hooks) | ~2h |
| 4 — Templating (optional) | ~1h |
| 5 — Replace install.sh | ~1h |
| 6 — Cleanup | ~30m |
| **Total** | **~7–8h** |

---

## Resume checklist

- [ ] Phase 1: Add chezmoi to Brewfile, flatten repo, `chezmoi init`
- [ ] Phase 2: Migrate packages in order (alacritty → kitty → bash → zed → karabiner → git → tmux → fish → nvim → killport)
- [ ] Phase 3: Create run_once/run_onchange scripts for nvim, fish, tmux hooks
- [ ] Phase 4: Add chezmoi.toml + template dot_gitconfig (optional)
- [ ] Phase 5: Replace install.sh with run_once bootstrap scripts
- [ ] Phase 6: Remove stow, dotfiles/ subdir, old hooks
