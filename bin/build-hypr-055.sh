#!/bin/bash
# build-hypr-055.sh — build Hyprland 0.55.2 + its WHOLE library stack into an ISOLATED prefix
# (~/.local/hyprland-0.55) with RPATH, without touching the distro RPM (which keeps using
# /lib64) or any other local build. Re-runnable: reuses clones (keeps local patches) and builds
# incrementally. See hyprland-from-source.md for the full rationale and the gotchas below.
#
# Build order (each links against the previously-installed ones in the prefix):
#   hyprutils -> hyprlang -> hyprgraphics -> hyprcursor -> aquamarine -> hyprwire -> lua -> Hyprland
# hyprwayland-scanner is used from the system (codegen tool only).
#
# Extra system -devel needed first (one transaction):
#   pkexec dnf install -y file-devel librsvg2-devel libzip-devel libjxl-devel \
#                         glslang-devel muParser-devel pugixml-devel
set -euo pipefail

PREFIX="$HOME/.local/hyprland-0.55"
SRC="$HOME/.local/src/hypr-055"
JOBS="$(nproc)"
mkdir -p "$SRC" "$PREFIX"

# so each build finds the libs already installed in the prefix + the prefix's scanners
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"
export CMAKE_PREFIX_PATH="$PREFIX"
export PATH="$PREFIX/bin:$PATH"

log(){ printf '\n========== %s ==========\n' "$*"; }

# clone only if missing (re-runs keep local patches and build incrementally)
fetch(){ local repo="$1" tag="$2" dir="$SRC/$1"
  if [ -d "$dir/.git" ]; then echo "(already cloned, reusing $tag)"; return 0; fi
  git clone --depth 1 --branch "$tag" --recurse-submodules "https://github.com/hyprwm/$repo" "$dir"
}

# configure + build + install with RPATH to the prefix and a consistent libdir=lib
cm(){ local dir="$1"; shift
  cmake -S "$dir" -B "$dir/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_INSTALL_RPATH="$PREFIX/lib" \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    "$@"
  cmake --build "$dir/build" -j"$JOBS"
  cmake --install "$dir/build"
}

log "hyprutils 0.13.1";    fetch hyprutils    v0.13.1; cm "$SRC/hyprutils"
log "hyprlang 0.6.8";      fetch hyprlang     v0.6.8;  cm "$SRC/hyprlang"

# GOTCHA (c): aquamarine & hyprgraphics list 'hyprutils' next to system libs in their
# pkg_check_modules; the system -L/usr/lib64 (from drm/seat) precedes the prefix's -L, so CMake's
# find_library caches the OLD system libhyprutils.so (SONAME .so.9). Force the prefix path with a
# TYPED (:FILEPATH) cache entry so find_library doesn't search.
HU_OVR="-Dpkgcfg_lib_deps_hyprutils:FILEPATH=$PREFIX/lib/libhyprutils.so"
log "hyprgraphics 0.5.1";  fetch hyprgraphics v0.5.1;  cm "$SRC/hyprgraphics" "$HU_OVR"
log "hyprcursor 0.1.13";   fetch hyprcursor   v0.1.13; cm "$SRC/hyprcursor"

# GOTCHA (b): aquamarine builds example/test binaries unconditionally; they link the system
# hyprutils and fail. Guard the test block behind if(AQ_TESTS) (off by default) before building.
if ! grep -q 'if(AQ_TESTS)' "$SRC/aquamarine/CMakeLists.txt" 2>/dev/null; then
  sed -i 's/^# tests$/# tests (guarded: link system hyprutils and unneeded)\nif(AQ_TESTS)/' "$SRC/aquamarine/CMakeLists.txt"
  # close the if() right before the install section
  sed -i 's/^# Installation$/endif()\n\n# Installation/' "$SRC/aquamarine/CMakeLists.txt"
fi
log "aquamarine 0.12.0";   fetch aquamarine   v0.12.0; cm "$SRC/aquamarine" "$HU_OVR"

log "hyprwire 0.3.1";      fetch hyprwire     v0.3.1;  cm "$SRC/hyprwire"

# GOTCHA (d): Hyprland 0.55 REQUIRES Lua 5.5 but Fedora 44 ships only 5.4. Build just the static
# lib (no readline) and write a pkg-config file so it resolves as 'lua5.5'.
log "lua 5.5.0"
if [ ! -f "$PREFIX/lib/liblua.a" ]; then
  ldir="$SRC/lua-5.5.0"
  [ -d "$ldir" ] || curl -fsSL https://www.lua.org/ftp/lua-5.5.0.tar.gz | tar xz -C "$SRC"
  make -C "$ldir/src" MYCFLAGS="-fPIC" SYSCFLAGS="-DLUA_USE_LINUX" liblua.a
  install -Dm644 "$ldir/src/liblua.a" "$PREFIX/lib/liblua.a"
  for h in lua.h luaconf.h lualib.h lauxlib.h lua.hpp; do install -Dm644 "$ldir/src/$h" "$PREFIX/include/$h"; done
  cat > "$PREFIX/lib/pkgconfig/lua5.5.pc" <<EOF
prefix=$PREFIX
includedir=\${prefix}/include
libdir=\${prefix}/lib

Name: Lua
Description: Lua 5.5 (local build for Hyprland 0.55)
Version: 5.5.0
Libs: -L\${libdir} -llua -lm -ldl
Cflags: -I\${includedir}
EOF
else echo "(liblua.a already installed)"; fi

# GOTCHA (e): hide the static Lua 5.5 symbols from the dynamic table (Hyprland uses
# --export-dynamic for plugins) so they don't interpose libinput's liblua-5.4 -> avoids a latent
# 5.4/5.5 clash. GOTCHA (f): skip tests and hyprpm.
log "Hyprland 0.55.2";     fetch Hyprland     v0.55.2; \
  cm "$SRC/Hyprland" -DBUILD_TESTING=OFF -DNO_HYPRPM=ON -DCMAKE_EXE_LINKER_FLAGS=-Wl,--exclude-libs,liblua.a

log "STACK COMPLETE -> $PREFIX/bin/Hyprland"
"$PREFIX/bin/Hyprland" --version | head -1
echo
echo "Sanity check (every hypr*/aquamarine line must point to $PREFIX/lib, no libhyprutils.so.9):"
ldd "$PREFIX/bin/Hyprland" | grep -iE 'hypr|aquamarine' || true
