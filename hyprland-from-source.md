# Building newer Hyprland from source on Fedora Asahi (aarch64, 16K pages)

How to run a **newer Hyprland than your COPR ships** on a MacBook (Apple Silicon, Fedora
Asahi Remix), **without breaking the system install**, by compiling it (and, for big jumps,
its whole library stack) into an **isolated prefix** and adding a separate login‑session entry.

This was done on a **MacBook Pro 14" M2 Pro**, Fedora Asahi Remix 44, where the
`solopasha/hyprland` COPR was stuck at **0.51.1** for `aarch64`. Two targets are documented:

| Target | Why | Complexity |
|---|---|---|
| **0.52.0** | Adds `render:non_shader_cm` → fixes the **green Chromium/Electron fullscreen** bug on the Apple **AGX** GPU (PR hyprwm/Hyprland#11900). | Easy — one binary against the system libs. |
| **0.55.2** | Latest stable; better scrolling, Lua configs, many fixes. | Hard — the whole `hypr*` + `aquamarine` + `lua` stack must be built too. |

> **The golden rule: never overwrite the distro's Hyprland.** Everything below installs into
> `~/.local/hyprland-0.5x` and adds a *new* entry to the login screen. Your RPM stays intact as
> a one‑click rollback (just pick the old session at login).

---

## 0. Why the version matters (plugins + config)

- **Plugins are version‑locked.** A `.so` built against 0.51 headers is *rejected* (or crashes)
  by 0.52, and vice‑versa. Every Hyprland you build needs its plugins rebuilt against *it*.
- **Config is mostly forward‑compatible 0.51→0.52** (only `misc:disable_hyprland_qtutils_check`
  was renamed to `…_guiutils_check`). **0.55 adds hard requirements** (Lua 5.5) and changed the
  scrolling plugin story (see §5).
- **Toolchain:** Fedora Asahi 44 ships **GCC 16**, which is stricter than the GCC 15 these
  releases were written against — expect a couple of "missing include / removed std symbol"
  patches (see §3).

Check what you have and what a target needs *before* starting:

```bash
hyprctl version                 # running compositor
rpm -q hyprland                 # COPR package + version
# minimum lib versions a target needs are in its CMakeLists.txt, e.g.:
curl -s https://raw.githubusercontent.com/hyprwm/Hyprland/v0.55.2/CMakeLists.txt | grep -i MINIMUM_VERSION
```

---

## 1. The easy case — Hyprland 0.52.0 against system libraries

0.52's dependency floors (`hyprutils≥0.8.2`, `hyprlang≥0.3.2`, `hyprgraphics≥0.1.6`,
`aquamarine≥0.9.3`, `hyprcursor≥0.1.7`) are **all satisfied by the 0.51.1‑era `-devel`
packages** already installed. So you only build the compositor.

```bash
SRC=~/.local/src/Hyprland-052
git clone --depth 1 --branch v0.52.0 --recurse-submodules \
    https://github.com/hyprwm/Hyprland "$SRC"
cd "$SRC"
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=~/.local/hyprland-0.52 -DBUILD_TESTING=OFF
cmake --build build -j"$(nproc)"
cmake --install build
```

### GCC 16 patch (0.52)
`src/managers/permissions/DynamicPermissionManager.cpp` uses `std::runtime_format`, which **GCC
16's libstdc++ no longer provides**. Replace each
`std::format(std::runtime_format(fmt), args…)` with the portable equivalent
`std::vformat(fmt, std::make_format_args(args…))` (bind temporaries to named lvalues first —
C++23 `make_format_args` wants lvalues), and add `#include <format>`. Then rebuild.

`BUILD_TESTING=OFF` avoids a separate failure in the `hyprtester` target (a generated
`color-management-v1.hpp` not on its include path) — you don't need the tests.

That's it: `~/.local/hyprland-0.52/bin/Hyprland --version` should print 0.52.0. Jump to §6 for
session wiring, and §7 for the green‑screen fix value.

---

## 2. The hard case — Hyprland 0.55.2 + the whole stack

0.55.2's floors are **higher than the COPR provides** and the COPR has **no newer builds for
aarch64**, so the libraries must be built too:

| Library | 0.55.2 needs | COPR/Fedora has | Build from source? |
|---|---|---|---|
| hyprutils | ≥0.13.1 | 0.10.0 | **yes** (v0.13.1) |
| hyprlang | ≥0.6.7 | 0.6.4 | **yes** (v0.6.8) |
| hyprgraphics | ≥0.5.1 | 0.2.0 | **yes** (v0.5.1) |
| aquamarine | ≥0.9.3 | 0.9.5 | **yes** (v0.12.0)¹ |
| hyprcursor | ≥0.1.7 | 0.1.13 | **yes** (v0.1.13)¹ |
| hyprwire | (any) | — | **yes** (v0.3.1) — new in 0.55, needed by `hyprctl` |
| Lua | **5.5** | 5.4.8 | **yes** (5.5.0) — Fedora has only 5.4 |
| hyprwayland-scanner | ≥0.3.10 | 0.4.5 | no (system tool is fine) |

> ¹ Even though the *version* is fine, `aquamarine`/`hyprcursor` link `hyprutils`. If you build a
> new `hyprutils` (SONAME `…so.9`→`…so.12`), loading the system `aquamarine` would drag the *old*
> hyprutils into the same process → **two hyprutils in one process** → symbol/type clashes →
> crashes. So they must be **rebuilt in the prefix** against the new hyprutils.

### Isolation strategy
Build everything into one prefix with **RPATH** baked in, so the 0.55 binary and all its libs
resolve *only* to the prefix (`$PREFIX/lib`) while the system 0.51 keeps using `/lib64`:

```bash
PREFIX=~/.local/hyprland-0.55
cmake … -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DCMAKE_PREFIX_PATH=$PREFIX \
        -DCMAKE_INSTALL_RPATH=$PREFIX/lib \
        -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
# and, for each component, export so it finds the ones already installed in the prefix:
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig
export CMAKE_PREFIX_PATH=$PREFIX
export PATH=$PREFIX/bin:$PATH    # so hyprwire-scanner etc. are found at build time
```

The full, re‑runnable script is **[`bin/build-hypr-055.sh`](bin/build-hypr-055.sh)**. Build
order (each links against the previous): `hyprutils → hyprlang → hyprgraphics → hyprcursor →
aquamarine → hyprwire → lua → Hyprland`.

### Extra system `-devel` packages 0.55 needs
Beyond what 0.52 used, install (one `dnf`/`pkexec` transaction):

```bash
pkexec dnf install -y \
    file-devel librsvg2-devel libzip-devel libjxl-devel \   # hyprgraphics / hyprcursor
    glslang-devel \                                          # Hyprland 0.55 (shader precompile)
    muParser-devel \                                         # Hyprland 0.55 (expr parser)
    pugixml-devel                                            # hyprwire scanner (XML)
```
(`glesv2`, `gl`, `egl` are already provided by `libglvnd-devel`; no `mesa-libGLES-devel`
needed.) `epoll-shim`, `libinotify`, `udis86`, `hyprland-protocols` are BSD‑only or vendored as
submodules — ignore the "not found" lines for them.

---

## 3. The gotchas (and their fixes)

These cost the most time; each is encoded in `build-hypr-055.sh`.

**a) GCC 16, `std::runtime_format`** — same as §1, only in 0.52's
`DynamicPermissionManager.cpp`. 0.55.2 builds clean on this point.

**b) aquamarine test targets link the *system* hyprutils.** aquamarine builds two example
binaries (`simpleWindow`, `attachments`) unconditionally; they pull `/usr/lib64/libhyprutils.so`
(old) and fail to link. Guard them out:
```cmake
# aquamarine/CMakeLists.txt — wrap the test block:
if(AQ_TESTS)
  …add_executable(simpleWindow …) … add_executable(attachments …) …
endif()
```

**c) `find_library` picks the *old* system hyprutils for aquamarine & hyprgraphics.** Their
`pkg_check_modules(deps … hyprutils …)` lists `hyprutils` *after* system modules (`drm`,
`libseat`), so the pkg‑config line is `-L/usr/lib64 … -L$PREFIX/lib -lhyprutils`. CMake's
`find_library` searches the `-L` dirs in order → finds `/usr/lib64/libhyprutils.so` (SONAME
`.so.9`) first and **caches the absolute path**. Result: the built `.so` has
`NEEDED libhyprutils.so.9` and at runtime you load **two** hyprutils. Fix by pre‑seeding the
cache entry with the right type so `find_library` doesn't search:
```bash
cmake … -Dpkgcfg_lib_deps_hyprutils:FILEPATH=$PREFIX/lib/libhyprutils.so
#         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ the :FILEPATH type is essential — an untyped -D is
#         treated as "not found yet" and gets overwritten by find_library.
```
Verify after building: `objdump -p $PREFIX/lib/libaquamarine.so.11 | grep hyprutils` must say
`libhyprutils.so.12`, **not** `.so.9`. Same check for `libhyprgraphics.so.4`.

**d) Lua 5.5 is required but Fedora has 5.4.** Build just the static lib (no readline) and write
a `.pc`:
```bash
curl -sL https://www.lua.org/ftp/lua-5.5.0.tar.gz | tar xz -C ~/.local/src
make -C ~/.local/src/lua-5.5.0/src MYCFLAGS="-fPIC" SYSCFLAGS="-DLUA_USE_LINUX" liblua.a
install -Dm644 .../liblua.a   $PREFIX/lib/liblua.a
install -Dm644 .../lua*.h*    $PREFIX/include/          # lua.h luaconf.h lualib.h lauxlib.h lua.hpp
# $PREFIX/lib/pkgconfig/lua5.5.pc  →  Version: 5.5.0 ; Libs: -L${libdir} -llua -lm -ldl
```

**e) Lua symbol clash with libinput.** `libinput` 1.31 has Lua‑based config plugins and links
the system **liblua‑5.4**. Hyprland links our static **lua 5.5** and is built with
`--export-dynamic` (for its plugin loader), so its `lua_*` symbols would be exported and could
**interpose** libinput's 5.4 calls → latent crash. Hide them:
```bash
cmake … -DCMAKE_EXE_LINKER_FLAGS=-Wl,--exclude-libs,liblua.a
# verify: `nm -D $PREFIX/bin/Hyprland | grep ' T lua_'` must be empty.
```
(The two Luas then coexist safely; `ldd` still showing `liblua-5.4.so` via libinput is fine.)

**f) Skip the heavy/irrelevant targets:** `-DBUILD_TESTING=OFF -DNO_HYPRPM=ON`.

### Final sanity check
```bash
ldd ~/.local/hyprland-0.55/bin/Hyprland | grep -iE 'hypr|aquamarine'
# every hypr*/aquamarine line must resolve to ~/.local/hyprland-0.55/lib (NOT /lib64),
# and there must be no second libhyprutils.so.9.
~/.local/hyprland-0.55/bin/Hyprland --version     # prints 0.55.2 → all libs load
```

---

## 4. `render:non_shader_cm` — the green‑fullscreen fix

On the Apple AGX GPU, the shader‑based color‑management path renders **solid green** when a
Chromium/Electron window goes fullscreen (Firefox is unaffected; an external monitor in *mirror*
mode launders the buffer so it doesn't show there). 0.52+ adds an integer option (a CHOICE):

| value | name | effect |
|---|---|---|
| 0 | disable | use the **shader** CM → the green bug |
| **1** | **always** | do CM via the **hardware CTM** whenever possible → **no green, colors correct** ← use this |
| 2 | ondemand | non‑shader only for direct‑scanout / passthrough |
| 3 | ignore | skip CM entirely (0.55's default) — no green, but no color management |

We set **`render:non_shader_cm = 1`** at runtime from the version guard (see §6), so it only
applies on 0.52+ and never errors on the 0.51 daily driver.

---

## 5. Scroller plugin per version

The PaperWM‑style layout this setup uses is the **cpiber `hyprscroller`** fork (with local
use‑after‑free patches, see `hyprscroller-crashes.patch`):

- **0.51** → `hyprscroller.so` (built against 0.51).
- **0.52** → rebuild the same fork against the 0.52 prefix → `hyprscroller-052.so`
  (`PKG_CONFIG_PATH` pointing at the 0.52 `hyprland.pc`).
- **0.55** → the cpiber fork **does not compile** against 0.55 (Hyprland's internal API moved:
  `m_lastMonitor`, `m_tags`, `CGradientValueData`, `Math::eDirection`, …). 0.55's recommended
  scroller is the **official `hyprscrolling`** plugin (hyprwm/hyprland-plugins), which must be
  built against the 0.55 prefix and uses **different dispatchers/config** (`layout = scrolling`,
  `plugin:hyprscrolling:*`). *This is the one piece still pending in the 0.55 session.*

> Don't let the guard load a wrong‑version `.so` — it will crash the compositor.

---

## 6. Session integration (coexist + rollback)

Three pieces let multiple Hyprland versions coexist and be chosen at the login screen.

**a) A launcher per prefix** — prepends the prefix `bin/` to `PATH` so the session's
`hyprctl`/scanners match the compositor (libs come via RPATH, so no `LD_LIBRARY_PATH`):

```bash
# ~/.local/hyprland-0.55/start-session
#!/bin/bash
export PATH="$HOME/.local/hyprland-0.55/bin:$PATH"
exec "$HOME/.local/hyprland-0.55/bin/Hyprland" "$@"
```

**b) A version guard** run from `autostart.conf` (`exec-once = hypr-session-tweaks`) that loads
the *correct* plugin and applies version‑specific keywords — so a **single shared config** works
for every session. See **[`bin/hypr-session-tweaks`](bin/hypr-session-tweaks)**. It branches on
the running `hyprctl version`:
- 0.51 → load `hyprscroller.so`
- 0.52–0.54 → load `hyprscroller-052.so` + `render:non_shader_cm 1`
- 0.55+ → `render:non_shader_cm 1` + `general:layout dwindle` (no scroller yet)

**c) A login‑session entry** the greeter can see. The greeter (`plasma-login-manager`) runs as
its own user and only scans **system** dirs, so it must go in `/usr/share/wayland-sessions/`
(a user `~/.local/share/...` entry is *not* picked up). The `Exec` runs *after* auth as you, so
it can point into your `~/.local`:

```ini
# /usr/share/wayland-sessions/hyprland-055.desktop   (install with: pkexec install -m644 …)
[Desktop Entry]
Name=Hyprland 0.55 (local)
Exec=/home/<you>/.local/hyprland-0.55/start-session
Type=Application
DesktopNames=Hyprland
```

Result at the login screen: **Hyprland** (0.51 RPM) · **Hyprland 0.52 (local)** ·
**Hyprland 0.55 (local)** · Plasma. Pick one; if a build misbehaves, log out and pick another —
the RPM is untouched.

---

## 7. Rollback & cleanup

- **Rollback:** just choose a different session at login. Nothing in `/usr` (except the small
  `.desktop` files) was modified; the COPR Hyprland still runs from `/usr/bin`.
- **Remove a build:** `rm -rf ~/.local/hyprland-0.55` and
  `pkexec rm /usr/share/wayland-sessions/hyprland-055.desktop`.
- The extra `-devel` packages from §2 are harmless to keep.

## Known‑good versions (June 2026, this machine)
Hyprland 0.55.2 · hyprutils 0.13.1 · hyprlang 0.6.8 · hyprgraphics 0.5.1 · hyprcursor 0.1.13 ·
aquamarine 0.12.0 · hyprwire 0.3.1 · lua 5.5.0 · GCC 16.1.1 · Fedora Asahi Remix 44.

## Status
0.52 and 0.55.2 both build, install isolated, and boot as separate sessions. **Pending for
0.55:** build the official `hyprscrolling` plugin and port the scroller binds/layout to it.
