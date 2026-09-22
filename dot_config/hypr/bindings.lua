-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- ============================================================
-- Ported from bindings.conf (Quattro moved bindings to Lua;
-- the old .conf file is no longer read by Hyprland).
-- ============================================================

-- Application bindings
-- (unbind Omarchy defaults on these same combos first — Lua binds stack
-- instead of replacing, unlike the old .conf source= chain)
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + ALT + RETURN")
hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + RETURN", "Terminal", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"')
o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" bash -c "tmux attach || tmux new -s Work"')
o.bind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")
hl.unbind("SUPER + SHIFT + F")
hl.unbind("SUPER + ALT + SHIFT + F")
hl.unbind("SUPER + SHIFT + B")
hl.unbind("SUPER + SHIFT + ALT + B")
hl.unbind("SUPER + SHIFT + M")
hl.unbind("SUPER + SHIFT + N")
hl.unbind("SUPER + SHIFT + D")
hl.unbind("SUPER + SHIFT + O")
hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + F", "File manager", "uwsm-app -- nautilus --new-window")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", 'uwsm-app -- nautilus --new-window "$(omarchy-cmd-terminal-cwd)"')
o.bind("SUPER + SHIFT + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + M", "Music", { focus = "spotify", launch = "spotify" })
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + O", "Obsidian", { focus = "^obsidian$", launch = "obsidian -disable-gpu --enable-wayland-ime" })
o.bind("SUPER + SHIFT + SLASH", "Passwords", "uwsm-app -- enpass")

-- Rebind SUPER ALT+F (was: Full width) to SUPER SHIFT+=
hl.unbind("SUPER + ALT + F")
o.bind("SUPER + SHIFT + equal", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Remap Ctrl+[ to Escape globally (wtype injects a clean Escape with no modifiers)
o.bind("CTRL + bracketleft", "Escape via wtype", "wtype -k escape")

-- ============================================================
-- i3-compat block (was: managed by omarchy-mac-setup.sh)
-- ============================================================

-- Unbind Omarchy defaults that conflict with hjkl navigation
hl.unbind("SUPER + J") -- was: togglesplit       -> use Super+e instead
hl.unbind("SUPER + K") -- was: show key bindings -> use Super+Alt+Space -> Omarchy menu
hl.unbind("SUPER + L") -- was: layout toggle     -> use Super+Alt+Space -> Omarchy menu

-- Focus movement (i3: $mod+hjkl)
o.bind("SUPER + h", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + j", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + k", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + l", "Focus right", hl.dsp.focus({ direction = "r" }))

-- Move/swap windows (i3: $mod+Shift+hjkl)
o.bind("SUPER + SHIFT + h", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + j", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + k", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + l", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- Split direction (i3: $mod+v / $mod+b)
o.bind("SUPER + v", "Preselect split down", hl.dsp.exec_raw("layoutmsg", "preselect d"))
o.bind("SUPER + b", "Preselect split right", hl.dsp.exec_raw("layoutmsg", "preselect r"))

-- Toggle split layout (i3: $mod+e)
o.bind("SUPER + e", "Toggle split layout", hl.dsp.layout("togglesplit"))

-- Close window (i3: $mod+Shift+q, mapped to Super+q for comfort)
o.bind("SUPER + q", "Close window", hl.dsp.window.close())

-- Workspaces 1-10 (i3 uses all 10; Omarchy default stops at 4)
local i3_workspace_keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
for index, key in ipairs(i3_workspace_keys) do
  local workspace = tostring(index == 10 and 10 or index)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = workspace }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end

-- Resize submap (i3: $mod+r -> resize mode, Escape/Enter to leave)
hl.define_submap("resize", "reset", function()
  hl.bind("h", hl.dsp.exec_raw("resizeactive", "-40 0"), { repeat_bind = true })
  hl.bind("l", hl.dsp.exec_raw("resizeactive", "40 0"), { repeat_bind = true })
  hl.bind("k", hl.dsp.exec_raw("resizeactive", "0 -40"), { repeat_bind = true })
  hl.bind("j", hl.dsp.exec_raw("resizeactive", "0 40"), { repeat_bind = true })
  hl.bind("left", hl.dsp.exec_raw("resizeactive", "-40 0"), { repeat_bind = true })
  hl.bind("right", hl.dsp.exec_raw("resizeactive", "40 0"), { repeat_bind = true })
  hl.bind("up", hl.dsp.exec_raw("resizeactive", "0 -40"), { repeat_bind = true })
  hl.bind("down", hl.dsp.exec_raw("resizeactive", "0 40"), { repeat_bind = true })
  hl.bind("Return", hl.dsp.submap("reset"), {})
  hl.bind("Escape", hl.dsp.submap("reset"), {})
end)
o.bind("SUPER + r", "Resize mode", hl.dsp.submap("resize"))
