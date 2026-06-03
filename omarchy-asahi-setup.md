# Setup Omarchy-on-Asahi — resumen

**Equipo:** MacBook Pro 14" (M2 Pro) · Fedora Asahi Remix 44 (KDE) · Hyprland **0.51.1** (COPR solopasha) · **páginas 16K** · login = **plasmalogin** (Plasma Login Manager) · lock = hyprlock.

> Regla de oro Asahi: **prefiere RPM/COPR nativo sobre Flatpak para apps Electron/Chromium** — el Flatpak suele traer binarios mal alineados para 16K y crashea (SIGSEGV al cargar).

> **KDE adelgazado (2026-05-30):** se quitaron los grupos `kde-pim`, `kde-media`, `kde-apps` + autoremove (~1.3 GiB) ya que el escritorio es Hyprland. **NO quitar el núcleo de Plasma** (`kwin`, `plasma-workspace`, frameworks KF6/Qt6): el login `plasma-login-manager` corre su greeter **bajo kwin-wayland** y enlaza `libkworkspace6`/`libklookandfeel` → borrarlo rompe el login. `kwin-wayland` es un *provide* del paquete `kwin` (no un paquete literal). Verificar siempre con dry-run (`dnf ... --assumeno`) + `rpm -e --test plasma-login-manager` antes de borrar más.

---

## Estructura de config (Hyprland)
`~/.config/hypr/hyprland.conf` sourcea, en capas:
- Defaults de Omarchy: `~/.local/share/omarchy/default/hypr/bindings/{media,clipboard,tiling-v2,utilities}.conf` + `envs.conf` + `looknfeel.conf` + tema.
- Overrides míos: `monitors.conf` (escala 2.0), `input.conf`, `bindings.conf`, `autostart.conf`, `windowrules.conf`.
- **NO** se sourcea `windows.conf` (sintaxis 0.53+, rompe 0.51.1). `env = PATH …` al inicio para que los `omarchy-*` de keybinds funcionen.

## Look Omarchy
- Repo (tarball) en `~/.local/share/omarchy`. Motor de temas = bash+sed (`omarchy-theme-set <nombre>`, `omarchy-theme-list`).
- Apps cablean al tema vía `~/.config/omarchy/current/theme/<app>`. Fuente JetBrainsMono Nerd + starship instalados.
- Menú Omarchy (botón logo waybar / **Super+Alt+Space**), atajos 1:1 de Omarchy (~192). **Super+K** = chuleta de atajos.

## Atajos personalizados (en `~/.config/hypr/bindings.conf`)
- **Super+Q** = cerrar ventana · **Super+W** = cerrar pestaña (Ctrl+W) · **Super+T** = nueva pestaña (Ctrl+T).
- **Brillo de PANTALLA**: las teclas de **sol** (fila de función) emiten `XF86MonBrightnessDown/Up` al pulsarlas **solas** → Omarchy ±5% (`omarchy-brightness-display`); **Shift+sol** = mín/máx, **Alt+sol** = ±1%. (Con **Fn**, esas mismas teclas dan `KEY_F1`/`KEY_F2`.) Backlight de pantalla: `apple-panel-bl` (max 500).
- **Backlight del TECLADO** = **SUPER + sol-abajo / SUPER + sol-arriba** (`SUPER + XF86MonBrightnessDown/Up` → `~/.local/bin/kbd-backlight down/up`, `bindeld`, con OSD). LED en `/sys/class/leds/kbd_backlight` (max 255); arranca en 0 → `autostart.conf` lo enciende al **50%** al iniciar sesión. `kbd-backlight` usa los % nativos de `brightnessctl` (no `omarchy-brightness-keyboard`, que salta 10%) con **paso adaptativo**: a **≤5%** ±1% (fino), por encima de 5% ±5%. (Antes se probó un submap `fnkbd` con la tecla Fn —`KEY_FN`/`code:472`, sí emite evento— pero se quitó por redundante al elegir SUPER+sol.)
- **Super+Shift+F** = explorador de archivos (**Dolphin**, ya instalado) · **Super+Alt+Shift+F** = Dolphin en el cwd de la terminal activa. NOTA: el default de Omarchy usaba `nautilus`, que NO está instalado (no llegó / se fue con la limpieza de KDE); se cambió a `dolphin --new-window`.
- **Super+flechas = teclas de navegación reinyectadas a la ventana activa** (`sendshortcut`): **Super+↑**=Page Up, **Super+↓**=Page Down, **Super+→**=End, **Super+←**=Home. Sobrescribe el `movefocus` por defecto de Omarchy (`tiling.conf`), por eso hay `unbind = SUPER, UP/DOWN/LEFT/RIGHT` antes de los `bindd`.
- **Super+Tab = foco a la ventana de la derecha · Super+Shift+Tab = izquierda** (`movefocus r` / `movefocus l`), **sin cambiar de workspace**. Se usa `movefocus` (espacial) en vez de `cyclenext` para que la dirección coincida con el orden visual del scroller (cyclenext cicla por orden interno y con 2 ventanas no distingue dirección). Sobrescribe el `workspace e+1/e-1` por defecto de Omarchy (`unbind` previo).
- **Foco vs mover ventana:** **Alt+←/→** = cambiar **foco** entre ventanas (`movefocus l/r`; movido desde Super+Shift, que quedó libre — OJO: Alt+←/→ es atrás/adelante en navegadores, ahora lo captura Hyprland). **Super+Ctrl+←/→** = **mover** la ventana/tile (`scroller:movewindow`, solo eje horizontal en PaperWM). **Super+Ctrl+↑/↓** = foco vertical (`movefocus u/d`, el scroller no mueve en vertical). Requiere `unbind` previo del `changegroupactive` de Omarchy en `Super+Ctrl+←/→`. (Super+Shift+↑/↓ siguen siendo `swapwindow` por defecto.)
- **Super+Shift+Enter** = abre kitty con `claude --dangerously-skip-permissions --resume`, fijada a **⅓ de ancho** (solo esa ventana), en el **cwd de la terminal activa**. **Super+Alt+Enter** = lo mismo pero **siempre en `~/`** (antes era Tmux). Ambos via `~/.local/bin/claude-term` (clase única `claude-resume`, detecta la ventana nueva por dirección, le aplica `scroller:setwidth onethird`): sin arg = cwd; `home`/`~` = HOME; `<dir>` = ese dir. El default global sigue en ⅞. (Ojo: la descripción de un `bindd` NO puede llevar comas — separan los campos.)
- **Super+Shift+4** = captura de área (script `~/.local/bin/screenshot-area`): copia al portapapeles + notif; **clic en la notif = editar con satty**.
- **Super+Shift+click-izq** = redimensionar (además de Super+click-der).
- Trackpad (`input.conf`): scroll natural, **tap-to-click DESACTIVADO** (clic = pulsar; evita taps accidentales), 3 dedos = drag&drop (`drag_3fg`), 4 dedos horiz = cambiar workspace.
- Teclado (`input.conf`): layout **us-intl with dead keys** (`kb_layout=us`, `kb_variant=intl`). `kb_options` **vacío**: antes tenía `compose:caps` que convertía Caps Lock en tecla Compose (Caps Lock no funcionaba ni encendía su LED) — se quitó para tener **Caps Lock normal**; los acentos siguen por AltGr + teclas muertas del propio us-intl.

## Layout PaperWM (hyprscroller) — DEFAULT, mosaico desactivado
- Plugin compilado: `~/.local/share/hyprland/hyprscroller.so` (cpiber fork tag 0.51.1). Cargado en `autostart.conf`.
- **scroller es el layout por defecto** y los anchos van como **bloque de config ESTÁTICO** en `autostart.conf` (`general { layout = scroller }` + `plugin { scroller { column_default_width / column_widths } }`). IMPORTANTE: tiene que ser config estática, NO `keyword`/`exec-once` — un `hyprctl reload` revierte los valores puestos por `keyword` a los defaults del plugin (fue el bug de los pasos perdidos). dwindle desactivado.
- **Super+L** = (re)asegurar scroller (ya no alterna).
- **Super + `=` / `-`** = ensanchar/estrechar columna manteniendo las otras (`~/.local/bin/hypr-resize` → `scroller:cyclesize`). Pasos (`column_widths`, 6): ⅓ ½ ⅔ ¾ ⅞ 1.
- **Super+Shift+←/→** = mover la columna en el orden (`scroller:movewindow`).
- Ancho inicial nuevas ventanas: `seveneighths` (⅞).
- Resize por **teclado** mantiene las otras; el arrastre con ratón redistribuye (inherente).

## Apps instaladas / compiladas
- **walker** (Rust, lanzador) + **elephant** (Go, backend, `elephant.service` + 12 providers `.so` en `~/.config/elephant/providers/`) + **swayosd** — compilados, en `~/.local/bin`.
- **VSCode**: RPM oficial de Microsoft (repo `/etc/yum.repos.d/vscode.repo` + `dnf install code`) — NO Flatpak (crasheaba por 16K). Override `~/.local/share/applications/code.desktop` con `--ozone-platform-hint=auto --force-device-scale-factor=2` (Wayland + HiDPI).
- **Chromium**: `dnf` (no existe Chrome para ARM). Flags Wayland/HiDPI en `/etc/chromium/chromium.conf`.
- **Spotify** = **ncspot** nativo (`~/.local/bin/ncspot`, compilado con `--features crossterm_backend,pulseaudio_backend,notify`; requiere Premium). Lanzador `~/.local/share/applications/ncspot.desktop`. (El web no va: DRM Widevine.)
- **Widevine (DRM)**: instalado con AsahiLinux/widevine-installer (v4.10.2662.3, nativo 16K). Habilita Netflix/Spotify-web/etc. en Chromium y Firefox. Requiere relogin.
- **Control TUIs**: wiremix (audio, Super+Ctrl+A), bluetui (Super+Ctrl+B), nmtui (wifi, Super+Ctrl+W — impala NO sirve, se usa NetworkManager).

## Menú Install (de-Arch'd) → `~/.local/bin/pkg-install-{dnf,flatpak,copr}`
- Package=dnf, Flatpak=Flathub (lee catálogo appstream local, rápido), COPR=búsqueda+enable. Todos con `-y`. Refrescan walker al instalar.

## Energía (estilo macOS) — `~/.config/hypr/hypridle.conf` (GENERADO)
- Tiempos **base en batería**: atenuar 1:50, pantalla off **2 min**, lock **2 min**, suspender **10 min**. Tapa cerrada = suspende (systemd). **Botón de power = suspender** (corta) / apagar (larga) — drop-in `/etc/systemd/logind.conf.d/10-power-suspend.conf` (`HandlePowerKey=suspend`, `HandlePowerKeyLongPress=poweroff`). Gestión CPU: **tuned-ppd** activo (`balanced-battery` en batería; `tuned-adm` es la herramienta, NO powerprofilesctl).
- **Enchufado a AC: todos los tiempos ×5** (pantalla 10 min, lock 10 min, suspender **50 min**). hypridle no tiene perfiles AC/batería, así que `hypridle.conf` se **genera** y hypridle se reinicia al cambiar de corriente:
  - `~/.local/bin/hypridle-apply` = genera el conf (base ×1, AC ×5 detectando `power_supply` type=Mains online=1 → `macsmc-ac`) y reinicia hypridle. **Con debounce** (estado en `~/.cache/hypridle-power.state`): solo actúa si el estado AC↔batería cambia de verdad — si no, los eventos de % de batería reiniciarían el contador de idle sin parar.
  - `~/.local/bin/hypridle-power-watch` = arranca hypridle + escucha eventos `power_supply` de udev (`udevadm monitor`, event-driven, sin polling). **Reemplaza** `exec-once = hypridle` en `autostart.conf`.
  - `hypridle.conf` lleva cabecera "GENERADO — NO editar a mano". Para cambiar los tiempos base o el multiplicador, editar las variables en `hypridle-apply`.
  - **Mientras corre Claude Code: solo atenúa** — 2026-06-03: los listeners de *apagar pantalla*, *bloquear* y *suspender* llevan un guard `on-timeout = pgrep -x claude >/dev/null || <comando>`. Si hay un proceso `claude` vivo, el `||` corta el comando, así que **solo se atenúa el brillo** (110s); **NO** se apaga la pantalla, **NO** se bloquea ni se suspende (las tareas en marcha no se cortan). El listener de *atenuar* es el único sin guard. **Sin polling**: aprovecha el temporizador propio de hypridle (reevalúa el `pgrep` en cada ciclo de idle). Los guards están en `hypridle-apply` (no en el conf, que se regenera). Copia versionada del script en `bin/hypridle-apply`. **OJO**: el cierre de tapa lo gestiona systemd-logind (`HandleLidSwitch=suspend`), ruta aparte que NO pasa por estos guards → cerrar la tapa suspende igual, con Claude o sin él.

## Recuperación RF: WiFi/BT colgados (Apple `brcmfmac` / `hci_bcm4377`) — 2026-05-30
Los controladores WiFi/BT del SoC Apple a veces se cuelgan (`hci0 … tx timeout`, `brcmfmac firmware has halted`) o tardan mucho en volver tras abrir la tapa. Dos servicios cubren los dos casos. Ambos corren como **root** (necesitan `modprobe`/`rfkill`) y registran en el journal.
- **Cuelgue EN USO → `rf-watchdog`** (reactivo, event-driven): `systemctl` system service `/etc/systemd/system/rf-watchdog.service` → `/usr/local/bin/rf-watchdog`. Sigue `journalctl -kf` y al ver las firmas de cuelgue resetea el módulo: BT `hci_bcm4377` (rfkill + reload + restart bluetooth), WiFi `brcmfmac` (reload). Salvaguardas: **3 firmas en 20 s** (ignora timeouts aislados) + **cooldown 90 s/dispositivo** (no entra en bucle) + arranca desde "ahora" (`-n0`). Ver: `journalctl -u rf-watchdog -f`. Sensibilidad: `WINDOW`/`THRESHOLD`/`COOLDOWN` al inicio del script.
- **Resume lento (abrir tapa) → hook system-sleep** (proactivo, condicional): `/usr/lib/systemd/system-sleep/50-rf-resume` lanza en background `/usr/local/bin/rf-resume-kick` (no retrasa el resume). Da una **gracia ~15 s** y SOLO si no volvieron solos: WiFi (detecta el dispositivo `wifi` por nmcli, p.ej. `wld0`) → recarga `brcmfmac`; BT → reconecta los dispositivos `Trusted: yes` que no hayan vuelto. Ver: `journalctl -t rf-resume`. (Nota: un dispositivo BT confiable apagado hace que cada resume gaste ~10 s intentando reconectarlo en background, inofensivo.)
- Desactivar: `sudo systemctl disable --now rf-watchdog` y/o `sudo rm /usr/lib/systemd/system-sleep/50-rf-resume`.

## Dolphin / apps Qt-KDE siguen el accent + carpetas de Omarchy — 2026-05-30
Dolphin es Qt/KDE, no se tematiza con el GTK de Omarchy. Se enganchó al motor de temas para que **accent** y **color de carpetas** sigan al tema Omarchy:
- **Hook**: `~/.config/omarchy/hooks/theme-set.d/20-kde-dolphin` → llama a `~/.local/bin/omarchy-theme-set-kde` (Omarchy ya invoca `omarchy-hook theme-set` al final de `omarchy-theme-set`; este dir `.d` es a prueba de actualizaciones).
- **Qué hace el script**: lee `accent` de `~/.config/omarchy/current/theme/colors.toml`; escribe `AccentColor` + `Colors:Selection/DecorationFocus/Hover` + `Icons Theme=Papirus-Dark` en `~/.config/kdeglobals` (con `kwriteconfig6`, sin root); elige el **color Papirus más cercano** al accent (distancia RGB sobre un mapa de hex extraído de `Papirus-Dark/64x64/places/folder-*.svg`) y recolorea con `papirus-folders` (necesita root → `pkexec`, prompt gráfico vía hyprpolkitagent al cambiar de tema); y fija `gtk-icon-theme-name=Papirus-Dark` en GTK 3/4.
- **Requisito clave**: Qt solo lee el esquema/accent de `kdeglobals` si está activo el platform theme de KDE → `QT_QPA_PLATFORMTHEME=kde` (y se vacía `QT_STYLE_OVERRIDE`, porque kvantum NO está instalado). Persistido en **`~/.config/environment.d/20-qt-kde.conf`** y en `~/.config/hypr/autostart.conf` (`env =`, declarado tras el `envs.conf` de Omarchy). **Toma efecto al reiniciar sesión** (uwsm congela el entorno al inicio).
- Efecto: con el platform theme activo Dolphin adopta el esquema oscuro de `kdeglobals` + accent naranja (`#faa968` → `250,169,104`) + carpetas `paleorange`. Tema actual: accent ⇒ carpetas paleorange.
- Paquetes: `papirus-icon-theme` (RPM) + script `papirus-folders` en `/usr/local/bin` (bash, upstream). `plasma-integration` ya estaba (provee `KDEPlasmaPlatformTheme6.so`).
- Revertir: borra el hook `20-kde-dolphin` y `~/.config/environment.d/20-qt-kde.conf` + las 2 líneas `env` de autostart.conf.

## Compartir pantalla (Firefox/Chromium) — portal roto, arreglado — 2026-05-31
Screen share en Wayland necesita `xdg-desktop-portal` (+ backend que capture en Hyprland) y PipeWire. Estaba roto por DOS causas y se arregló así:
1. **`xdg-desktop-portal` no arrancaba** porque su `Requisite=graphical-session.target` **no estaba activo** (montamos Hyprland sin uwsm, así que nada lo activaba). Fix: `~/.config/systemd/user/hyprland-session.target` (`BindsTo`+`Before` de graphical-session.target) y `exec-once = systemctl --user start hyprland-session.target` en `autostart.conf`. (También dependía de `sockets.target`, que fallaba por `drkonqi-coredump-launcher.socket` huérfano de KDE → **enmascarado**.)
2. **El frontend se colgaba (timeout) esperando al backend KDE** (`xdg-desktop-portal-kde`, no puede inicializar sin Plasma). No se puede desinstalar (lo requiere `plasma-workspace` del login), así que se **enmascaró**: `systemctl --user mask xdg-desktop-portal-kde.service`. El portal usa `hyprland;gtk` (`/usr/share/xdg-desktop-portal/hyprland-portals.conf`).
3. **`xdg-desktop-portal-gtk` en bucle de fallo → waybar tardaba ~1 min en aparecer** (2026-05-31). El backend GTK no registraba su nombre y systemd lo reintentaba (timeout 45 s, en bucle); las apps **GTK** (waybar, swayosd) consultan el portal **Settings** al arrancar y se **bloqueaban ~45 s** esperándolo. (El entorno del manager ya tenía `WAYLAND_DISPLAY/GDK_BACKEND/DISPLAY`, no era eso — el propio portal-gtk se cuelga.) Fix: **enmascarado** `systemctl --user mask xdg-desktop-portal-gtk.service` → la consulta Settings falla rápido y waybar dibuja en **~1 s**. Coste: las apps GTK usan su selector de archivos nativo (no el del portal); el ScreenCast (hyprland) y el resto siguen OK.
- Env para los backends: `autostart.conf` exporta el entorno gráfico **completo** lo antes posible con `exec-once = dbus-update-activation-environment --systemd --all` (PRIMER exec-once), porque las apps GTK lanzadas vía systemd fallan con "cannot open display" si arrancan antes.
- Verificar: `busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop | grep ScreenCast`. Backend activo: `xdg-desktop-portal-hyprland`; **KDE y GTK enmascarados**.

## SSH desde kitty: `ssh` = `kitten ssh` (terminfo xterm-kitty) — 2026-05-31
- kitty exporta `TERM=xterm-kitty`; al hacer `ssh` **plano** a un servidor que no tiene ese terminfo (p.ej. Ubuntu), `clear`/`vim`/`htop`/`tput` fallan con `'xterm-kitty': unknown terminal type`.
- Fix en `~/.bashrc`: `command -v kitten >/dev/null && alias ssh='kitten ssh'`. `kitten ssh` copia el terminfo de kitty al remoto (en su `~/.terminfo`, **sin root**) en la 1ª conexión, así `xterm-kitty` se reconoce.
- Solo afecta shells **interactivos** (no scripts); `scp`/`rsync` quedan igual. Saltar el alias puntualmente: `\ssh …` o `command ssh …`. Alternativas: `apt install kitty-terminfo` en el server, o `TERM=xterm-256color ssh …`.

## Lock de sesión (hyprlock) — distinto del greeter de plasma-login
- Locker: **hyprlock** (`~/.config/hypr/hyprlock.conf`) que hace `source` de `~/.config/omarchy/current/theme/hyprlock.conf` → los `$color/$inner_color/$outer_color/$font_color/$check_color` y el fondo cambian **con el tema** (los reescribe `omarchy-theme-set`).
- **Disparadores**: tecla **`SUPER+CTRL+L`** (`omarchy-system-lock`, default de Omarchy) y **hypridle** (`lock_cmd` por timeout de inactividad + `before_sleep_cmd = loginctl lock-session` antes de suspender).
- **Personalización del layout** (en `hyprlock.conf`): fondo = mismo wallpaper del escritorio con **blur** (passes 3, size 8); **reloj** `$TIME` a font_size 72; **fecha** `date +"%A, %d de %B"` (refresca cada 60 s); **input-field** 350×60 redondeado (rounding 8, outline 3, JetBrainsMono Nerd Font), placeholder **"Contraseña…"**, fail con nº de intentos; `animations` off, `hide_cursor`, `ignore_empty_input`, huella deshabilitada.
- Es el **bloqueo en caliente** de la sesión ya iniciada; el **greeter de arranque** es `plasma-login-manager` (ver sección de login), son cosas distintas.

## Suspend = calor/consumo en la maleta (limitación Asahi, NO es config) — 2026-05-30
Apple Silicon bajo Asahi **solo tiene `s2idle`** (`/sys/power/mem_sleep → [s2idle]`, no existe `deep`/S3). La tapa **sí suspende bien** (verificado en journal: duerme horas sin despertares espurios), pero s2idle **no apaga el hardware** → se va ~**2 %/h** y **se calienta** (la radio Broadcom BCM4388, GPU, USB-C PD siguen alimentados). El deep-sleep real es trabajo de kernel **pendiente** en Asahi, sin solución por config: issues [AsahiLinux/linux#262](https://github.com/AsahiLinux/linux/issues/262), [asahi-installer#252](https://github.com/AsahiLinux/asahi-installer/issues/252), [UbuntuAsahi#180](https://github.com/UbuntuAsahi/ubuntu-asahi/issues/180) (todos abiertos, jun/jul 2025).
- **Mitigación → hook `/usr/lib/systemd/system-sleep/40-rf-suspend`**: en `pre` apaga WiFi+BT (`rfkill block`) y **desarma el wake-source PCI** de la Broadcom (`echo disabled > /sys/bus/pci/devices/0000:01:00.0/power/wakeup`); en `post` los restaura (`rfkill unblock`). Corre antes que `50-rf-resume` (que reconecta los BT). Baja el calor/fuga sin convertirlo en S3. Ver: `journalctl -t rf-suspend`.
- Desactivar: `sudo rm /usr/lib/systemd/system-sleep/40-rf-suspend` (al reactivar WiFi tras reboot el wake-source vuelve a `enabled` solo).

## Greeter (plasmalogin) + Locker (hyprlock) temáticos
Ambos cambian **color + fondo** con el tema de Omarchy.
- **Locker**: `~/.config/hypr/hyprlock.conf` reescrito → `source`a `current/theme/hyprlock.conf` (colores `$variables`) + `path = current/background` (blur). Cambia solo, sin root, al instante. Backup: `hyprlock.conf.bak-static`.
- **Login/greeter**: usa el sistema de wallpaper de Plasma (`plasma-login-wallpaper`) + `kdeglobals`.
  - Dir compartido **propiedad del usuario**, legible por el greeter (uid `plasmalogin` 985): `/var/lib/omarchy-greeter/{background,kdeglobals}`.
  - `/etc/plasmalogin.conf` → `[Greeter][Wallpaper][org.kde.image][General] Image=file:///var/lib/omarchy-greeter/background` (backup `/etc/plasmalogin.conf.omarchy-bak`).
  - `kdeglobals` del greeter (`/var/lib/plasmalogin/.config/kdeglobals`) es **symlink** a `/var/lib/omarchy-greeter/kdeglobals` (backup `.omarchy-bak`).
  - Generador: `~/.local/bin/omarchy-greeter-sync` (lee `current/theme/colors.toml`, copia el fondo y genera el esquema KDE; SIN root).
  - Auto-update: hook `~/.config/omarchy/hooks/theme-set.d/greeter` (lo dispara `omarchy-hook theme-set`).
  - **Cambiar SOLO el fondo** (menú Omarchy / `omarchy-theme-bg-next`/`-set`) NO dispara el hook theme-set, así que un **path unit de systemd-user** vuelve a sincronizar: `omarchy-greeter-bg.path` vigila el **directorio** `~/.config/omarchy/current` (PathChanged sobre el symlink no sirve: sigue al destino; sobre el dir sí detecta el `ln -nsf background`) → corre `omarchy-greeter-bg.service` → `omarchy-greeter-sync`. Habilitado (`WantedBy=default.target`).
  - **Aplica en el siguiente arranque del greeter** (logout/reboot), no en vivo. Setup root (1 vez): `/tmp/omarchy-greeter-setup.sh`.
  - Revertir greeter: borrar bloque Omarchy de `/etc/plasmalogin.conf` (o restaurar `.omarchy-bak`) y `ln -sfn` no — restaurar `kdeglobals.omarchy-bak` sobre el symlink.

## Webapps en Firefox (PWAsForFirefox / firefoxpwa) — alternativa a las de Chromium
Motivo: el vídeo a pantalla completa en Chromium sale **verde** (bug Mesa/AGX con el buffer GPU fullscreen; solo se quita bajando la GPU = lento). Firefox no lo sufre → webapps en Firefox.
- Compilado de fuente (aarch64) desde `/tmp/PWAsForFirefox` (Rust, `cargo build --release` en `native/`); versión fijada a **2.18.2** (editar `version=` en `native/Cargo.toml` para que la extensión no se queje).
- Instalado: `firefoxpwa`→`/usr/bin`, `firefoxpwa-connector`→`/usr/libexec`, manifest native-messaging en `/usr/lib{,64}/mozilla/native-messaging-hosts/firefoxpwa.json`, userchrome en `/usr/share/firefoxpwa/`.
- **Runtime ENLAZADO** (no descargado de Mozilla, que rompería en 16K): `firefoxpwa runtime install --link` usa el Firefox del sistema. Necesitó symlink `/usr/lib/firefox → /usr/lib64/firefox` (el código busca en lib, Fedora usa lib64) y un **parche en `native/src/components/runtime.rs`**: `create_dir_all(&self.directory)` antes del bucle de link + corregir `entry.join("defaults/pref/...")`→`entry.join("pref/...")`. Runtime en `~/.local/share/firefoxpwa/runtime/`.
- **La extensión de AMO ya NO existe (404)** y Firefox release exige extensiones firmadas → se usa **solo por CLI**. Truco clave: el manifest se pasa como **`data:` URL** (en `site.rs` el código usa el `--document-url` para el origen cuando el manifest es `data:`), evitando el error de "mismo origen" y sin necesitar extensión.
- **Helper propio**: `~/.local/bin/firefox-webapp`:
  - `firefox-webapp <url> "<Nombre>" [icon-url]` → instala (genera manifest data: con icono de Google favicon 128px embebido; crea `.desktop` + iconos en `~/.local/share/icons/hicolor` → sale en Walker).
  - `firefox-webapp --list` / `firefox-webapp --remove <ULID>`.
  - Lanzar: el `.desktop` ejecuta `firefoxpwa site launch <ULID>`.
- Ejemplo instalado: YouTube. Warning cosmético al abrir: `Couldn't sanitize GL_RENDERER "AGX G13/G14"` (inofensivo). Fuente compilada (con los parches) en `~/.local/src/PWAsForFirefox/native` (`cargo build --release` para reconstruir).
- **Spotify**: se mantiene como **PWA de Chromium** (`Spotify.desktop` → `omarchy-launch-webapp https://open.spotify.com/`). Se probó migrarlo a firefoxpwa (2026-05-30) pero se revirtió a Chromium por preferencia. (El icono `file://` no lo acepta firefoxpwa; si se reintenta, el `.desktop` debe apuntar `Icon=` por ruta absoluta a `~/.local/share/applications/icons/Spotify.png`.)
- **DRM/Widevine en firefoxpwa (CRÍTICO para cualquier PWA con DRM: Netflix, Spotify-en-firefox, etc.)**: el runtime enlazado NO traía `defaults/pref/gmpwidevine.js`, así que las PWAs no activaban EME ni el Widevine del sistema. Fix: `cp /usr/lib64/firefox/defaults/pref/gmpwidevine.js ~/.local/share/firefoxpwa/runtime/defaults/pref/` (activa `media.eme.enabled` + `media.gmp-widevinecdm.version=system-installed`). Lo heredan todas las PWAs. Hay que recopiarlo si se reconstruye/re-enlaza el runtime.

## Gotchas / recuperación
- **Audio sin sonido / mala calidad**: el ruteo se atasca tras reboot/suspend o el BT entra en HFP (mono). Fix: `systemctl --user restart wireplumber` (recrea altavoces `audio_effect.j414-convolver` / renegocia A2DP del Bluetooth).
- **Audio BT se entrecorta (Sony WH-1000XM5)**: el cuello de botella era el códec **LDAC (~990 kbps)** saturando el enlace, agravado porque **WiFi 2.4 GHz comparte antena con BT** en el MacBook (el hotspot del iPhone sale en 2.4G salvo que se desactive "Maximizar compatibilidad" → 5 GHz). Fix: forzar **AAC** (~256 kbps, mucho más estable) vía drop-in `~/.config/wireplumber/wireplumber.conf.d/51-bluez-aac.conf` → `monitor.bluez.properties { bluez5.codecs = [ aac sbc_xq sbc ] }` (deshabilita LDAC/aptX; AAC necesita `fdk-aac-free` + `libspa-codec-bluez5-aac.so`, ya presentes). Aplicar: `systemctl --user restart wireplumber` + reconectar los cascos (renegocia el códec). Verificar: `pactl list sinks | grep api.bluez5.codec` → `aac`. Volver a LDAC = borrar el drop-in y reiniciar wireplumber.
- **Teclas de volumen muertas**: `systemctl --user restart swayosd-server.service` (falla si arranca antes que Wayland; se desactivó su auto-start systemd, lo arranca el exec-once).
- **Error config tras cambiar tema** ("source globbing no match"): era carrera del swap del tema; parcheado en `omarchy-theme-set` (swap casi atómico). Si aparece: `hyprctl reload`.
- **Layout vuelve a dwindle** tras `hyprctl reload` manual: pulsa **Super+L**.
- **Hyprland NO se actualiza** aún (solopasha solo tiene 0.51.1 aarch64; aquamarine 0.9.5 es build manual local). No actualizar sin recompilar la pila.
- **Sesión se cierra al cerrar una ventana (crash hyprscroller)** — varios bugs en la ruta de quitar ventana (SIGSEGV → vuelve al login). Fuente parcheada en `~/.local/src/hyprscroller`, recompilada (`rm -rf Release && make release`) e instalada en `~/.local/share/hyprland/hyprscroller.so`. **Activo solo desde el siguiente login** (no hot-reload). El patch completo está en el repo (`hyprscroller-crashes.patch`, aplica limpio sobre el commit `01a1014`).
  1. **`Column::remove_window` null-deref** (2026-05-30): cherry-pick del commit upstream `248d5c1` (chequeo de `active` nulo).
  2. **Patrón use-after-free `container.erase(X); delete X->data();`** (2026-05-30/31): `list.h::erase` hace `delete it` (libera el ListNode), así que `X->data()` después lee basura → `delete` sobre puntero corrupto → SIGSEGV. **Aparece en 4 sitios**, todos arreglados capturando el puntero ANTES del erase (`auto d = X->data(); …erase(X); delete d;`):
     - `scroller.cpp` `onWindowRemovedTiling` (cerrar la última ventana de un row) — se usa `delete s` (el Row ya conocido).
     - `column.cpp` `Column::remove_window` (`windows.erase(win); delete win->data()`) ← este causaba el crash del 2026-05-31.
     - `scroller.cpp` limpieza de filas vacías (`rows.erase(row); delete row->data()`) y `trail_delete` (`trails.erase(active); delete active->data()`).
     - `row.cpp` `remove_window` (`columns.erase(col); delete col->data()`).
  - Backups del `.so`: `.bak-buggy-20260530`, `.bak-colfix-20260530`, `.bak-2uaf-*`.
- **drkonqi en bucle de SIGSEGV** (tras quitar KDE quedó huérfano y se autocae al manejar cualquier coredump): enmascarado con `systemctl --user mask drkonqi-coredump-launcher@.service`. Los coredumps se siguen guardando vía systemd-coredump.
- **Keyring roto tras quitar KDE**: falta el `.service` D-Bus de `org.freedesktop.secrets` (KWallet); por eso `git-credential-libsecret` falla ("name is not activatable"). Para keyring seguro: instalar `gnome-keyring`. Mientras tanto git usa el helper `store`.
- Backups de scripts omarchy parcheados: `*.bak*` en `~/.local/share/omarchy/bin/`.

## Git / GitLab self-hosted (2026-05-30)
- **gh** (GitHub CLI) instalado por dnf (2.92.0).
- **GitLab self-hosted** (host y usuario omitidos): autenticado por **PAT** con el helper **`store`** (`git config --global credential.helper store`; token en `~/.git-credentials`, perms 600, como `oauth2:<token>@<gitlab-host>`). Se cambió de `libsecret` a `store` porque el keyring quedó roto al quitar KDE (ver arriba). Probado con `git ls-remote` autenticado OK.
