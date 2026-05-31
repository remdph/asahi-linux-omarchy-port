---
name: system-asahi-hyprland
description: "User's machine — Fedora Asahi Remix 44 on MacBook Pro 14\" M2 Pro, switched WM to Hyprland (KDE kept)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 053e0386-4675-4ea5-b8a0-f0c9cc50ae83
---

User's machine: **MacBook Pro 14" (Apple M2 Pro, eDP-1 3024x1890@120Hz)** running **Fedora Asahi Remix 44** (aarch64), Wayland. Mesa 26.0.3 from the @asahi mesa COPR; OpenGL ES 3.2 available.

On 2026-05-29 we **switched the desktop from KDE Plasma to Hyprland**, keeping KDE installed as a fallback (selectable in SDDM / `plasmalogin`). Login now offers `hyprland`, `hyprland-uwsm`, and `plasma` sessions.

**Hyprland comes from the `solopasha/hyprland` COPR** (it has fedora-44-aarch64 builds).

**Important caveat — aquamarine:** the COPR's `aquamarine-0.9.5-2.fc44.aarch64` was built (Oct 2025) against `libdisplay-info.so.2` (v0.2), but Fedora 44 GA ships `libdisplay-info 0.3.0` (`.so.3`), so the COPR binary is uninstallable. Fix applied: **rebuilt aquamarine from its SRPM** against libdisplay-info 0.3 (`rpmbuild --rebuild`, sources kept in `~/aqua-rebuild/`). The locally-built rpm requires `libdisplay-info.so.3` and is installed.
**Why:** future `dnf upgrade`/`distro-sync` may try to pull a newer COPR aquamarine still linked to `.so.2` and break Hyprland.
**How to apply:** if a Hyprland/aquamarine upgrade fails on `libdisplay-info.so.2`, rebuild aquamarine again from the COPR SRPM (`dnf download --source aquamarine` → `rpmbuild --rebuild`) — or check whether the COPR finally rebuilt it. Consider a `versionlock` on aquamarine.

Configs written (no sudo needed): `~/.config/hypr/{hyprland.conf,hyprlock.conf,hypridle.conf}`, `~/.config/waybar/{config.jsonc,style.css}`. Keyboard layout is **us-intl**; monitor scale set to **1.6**. Mod key is SUPER (the Mac ⌘).

`pkexec` works for privileged installs (KDE polkit agent provides the GUI prompt); I cannot run `sudo` directly.
