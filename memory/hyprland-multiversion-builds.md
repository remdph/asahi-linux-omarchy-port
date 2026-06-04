---
name: hyprland-multiversion-builds
description: "Three coexisting Hyprland versions (0.51 RPM, 0.52, 0.55.2) built from source in isolated prefixes, each a separate login session"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5d2f44f1-25f3-420b-8bd5-47b5079ace80
---

The COPR `solopasha/hyprland` is frozen at **0.51.1 for aarch64**, so newer Hyprland is built
from source into **isolated `~/.local/hyprland-0.5x` prefixes** (RPATH-baked), leaving the system
RPM untouched as rollback. Three versions coexist, chosen at the `plasma-login-manager` screen:

- **Hyprland** = 0.51.1 RPM (`/usr/bin`, system libs in `/lib64`).
- **Hyprland 0.52 (local)** = `~/.local/hyprland-0.52` — single binary vs system libs; fixes the
  AGX green Chromium fullscreen via `render:non_shader_cm`.
- **Hyprland 0.55 (local)** = `~/.local/hyprland-0.55` — full stack built (hyprutils 0.13.1,
  hyprlang 0.6.8, hyprgraphics 0.5.1, hyprcursor 0.1.13, aquamarine 0.12.0, hyprwire 0.3.1, lua
  5.5.0) via `~/.local/src/build-hypr-055.sh`. **Bootable but scroller-less** (layout dwindle).
  Uses a **dedicated converted config** `~/.config/hypr-055/` (launcher passes `--config`), NOT
  the shared `~/.config/hypr` (that errors on 0.55). Converted: windowrulev2→windowrule+match:
  (float/center need `on`), scroller:movewindow→movewindow l/r, no plugin{scroller} block,
  static render:non_shader_cm=1. Validated with `Hyprland --verify-config` → "config ok".

Session wiring (shared config, one guard): `~/.local/bin/hypr-session-tweaks` (run from
autostart.conf) branches on `hyprctl version` to load the right scroller `.so` + set
`render:non_shader_cm 1`. Launchers `~/.local/hyprland-0.5x/start-session` prepend the prefix
`bin/` to PATH. Session entries live in `/usr/share/wayland-sessions/hyprland-05x.desktop`
(greeter only scans system dirs; install via `pkexec install -m644 …`).

Key gotchas (all in the build script + documented): GCC 16 dropped `std::runtime_format` (→
`std::vformat`); aquamarine/hyprgraphics `find_library` grabs the old system `libhyprutils.so.9`
unless overridden with `-Dpkgcfg_lib_deps_hyprutils:FILEPATH=…` (typed!); Fedora has only Lua 5.4
so Lua 5.5 is built static + `.pc`; `-Wl,--exclude-libs,liblua.a` hides its symbols from
libinput's liblua-5.4. **pkexec must run with a live parent** (no `& disown` → "Refusing to
render service to dead parents") — use the harness background mode.

**Pending for 0.55:** build the official `hyprscrolling` plugin against the 0.55 prefix and port
the scroller binds/layout to it (the cpiber `hyprscroller` fork does NOT compile against 0.55).
Also pending: the "some errors" the user saw in the 0.52 session (not yet diagnosed).

Full guide: `hyprland-from-source.md` in [[work-repo-asahi-omarchy]]. Scroller fork crashes &
patches relate to [[omarchy-look-port]].
