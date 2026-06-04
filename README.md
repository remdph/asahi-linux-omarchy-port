# asahi-linux-omarchy-port

Port of the **Omarchy** (DHH) look/UX onto **Fedora Asahi Remix 44 (KDE)** on a **MacBook Pro 14" M2 Pro** (aarch64, 16K memory pages) running **Hyprland**. Docs, configs and scripts to reproduce it — including how to replicate it on another Omarchy PC.

> Notes under `memory/` = the assistant's working notes. The VPN section (personal infra) was intentionally stripped.

## Prerequisites (important!)

This is an **adaptation applied ON TOP of an existing install**, not a full OS:

1. **Hardware:** an **Apple Silicon — M1 / M2** Mac (the range Asahi supports well; this machine was a MacBook Pro 14" M2 Pro). Apple-SoC specifics apply: **16K** memory pages, some missing accelerations, Broadcom RF, etc.
2. **First install Asahi Linux with the FULL KDE desktop:** use the **Fedora Asahi Remix** image and pick the **KDE Plasma (full desktop) edition**, not the minimal/server one. This adaptation **depends** on the KDE stack already being present:
   - The **login** reuses `plasma-login-manager` (ships with the KDE edition).
   - **Dolphin** theming uses KDE's `plasma-integration` / `kdeglobals`.
   - Several KDE packages (Qt, Breeze, Dolphin) are assumed installed.
3. **Only then** clone this repo and apply the port (Hyprland + Omarchy look) on top of that KDE. The idea: KDE stays as the base/login, Hyprland is the working desktop.

> In short: **install Fedora Asahi Remix (KDE) → boot and confirm KDE works → then apply this adaptation.** Don't start from a KDE-less install.

## ⚠️ Work in progress

This repo is **under construction**. For now it contains only **documentation (MDs)** and
**individual scripts/configs** — you apply them by hand following the guides. **There is NO automatic
installer yet.**

**Coming soon:** an **installer** that automates the whole port (install packages, build/patch the
plugin, copy configs and hooks) in one step. For now, apply the docs/configs/scripts manually.

> **Project language: English.** New docs, commits and notes in this repo are written in English.

---

## Documents
- **`omarchy-asahi-setup.md`** — COMPLETE reference of the MacBook setup (everything, incl. Apple hardware).
- **`hyprland-from-source.md`** — build a **newer Hyprland than your COPR ships** (0.52 and the full
  0.55.2 stack) into an **isolated prefix** + a separate login session, without breaking the system
  install. Covers every aarch64/GCC‑16/Lua‑5.5/RPATH gotcha and the AGX green‑fullscreen fix.
- **`hyprscroller-crashes.patch`** — patches for the 2 plugin crashes when closing windows.

## Config files (real, ready to copy)
- **`hypr/hyprlock.conf`** — **lockscreen** (hyprlock): clock, date, blur, password field; colors come
  from the active theme. Goes to `~/.config/hypr/hyprlock.conf`.
- **`hooks/theme-set.d/`** — **hooks fired on theme change** (Omarchy runs everything under
  `~/.config/omarchy/hooks/theme-set.d/`):
  - `20-kde-dolphin` → calls `bin/omarchy-theme-set-kde` (Dolphin accent + folder colors).
  - `greeter` → calls `omarchy-greeter-sync` (syncs **login** wallpaper + colors with the theme).
- **`bin/omarchy-theme-set-kde`** — script that themes Dolphin (goes to `~/.local/bin/`).
- **`login-conf/`** — **login greeter** config (plasma-login-manager), from `/etc`:
  - `plasmalogin.conf` (with the Omarchy wallpaper block), `sysconfig-plasmalogin`,
    `theme-set.d_greeter` (copy of the greeter hook).

## Tree
```
asahi-linux-omarchy-port/
├── README.md
├── omarchy-asahi-setup.md              # full reference (VPN-stripped)
├── hyprscroller-crashes.patch          # plugin crash fixes
├── hypr/hyprlock.conf                  # lockscreen
├── hooks/theme-set.d/
│   ├── 20-kde-dolphin                  # theme hook -> Dolphin
│   └── greeter                         # theme hook -> login
├── bin/
│   ├── omarchy-theme-set-kde           # theme script (Dolphin)
│   └── omarchy-greeter-sync            # sync login greeter wallpaper+colors with theme
├── systemd/                            # user units: resync greeter on background-only change
│   ├── omarchy-greeter-bg.path
│   └── omarchy-greeter-bg.service
├── login-conf/                         # greeter (from /etc)
│   ├── plasmalogin.conf
│   ├── sysconfig-plasmalogin
│   └── theme-set.d_greeter
└── memory/                             # assistant working notes
```

> To use on another machine: `git clone https://github.com/remdph/asahi-linux-omarchy-port` and follow
> the docs. Remember to make the hooks/scripts executable on the target (`chmod +x`).
