#!/bin/bash
#
# fedora-dwm Installation Script
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================
# COLORS AND LOGGING
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# HELPER FUNCTIONS
# ============================================

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    else
        DISTRO="unknown"
    fi
    export DISTRO
}

detect_display_manager() {
    DM_USED=""

    # Check systemd graphical target and enabled DMs
    if command -v systemctl &>/dev/null; then
        local dm_target=$(systemctl get-default 2>/dev/null)
        if [[ "$dm_target" == "graphical.target" ]]; then
            for dm in gdm gdm3 sddm lightdm lxdm ly greetd; do
                if systemctl is-enabled "${dm}.service" &>/dev/null; then
                    DM_USED="$dm"
                    break
                fi
            done
        fi
    fi

    # Check for running DMs
    if [ -z "$DM_USED" ]; then
        for dm in gdm gdm3 sddm lightdm lxdm ly greetd; do
            if pgrep -x "$dm" &>/dev/null; then
                DM_USED="$dm"
                break
            fi
        done
    fi

    if [ -n "$DM_USED" ]; then
        log_info "Display manager detected: $DM_USED"
    else
        log_info "No display manager detected (using startx/xinit)"
    fi

    export DM_USED
}

# ============================================
# SYSTEM DEPENDENCIES
# ============================================

install_dependencies() {
    log_info "Installing system dependencies..."

    case "$DISTRO" in
        fedora|rhel|centos|rocky|alma)
            # NOTE: `dnf groupinstall` is gone under dnf5 (Fedora 41+, the
            # default since this repo started) - it's `dnf group install`,
            # and it wants the group *id*, not the display name.
            sudo dnf group install -y development-tools
            sudo dnf install -y \
                git \
                libX11-devel \
                libXft-devel \
                libXinerama-devel \
                xorg-x11-server-Xorg \
                xorg-x11-xinit \
                xrandr \
                xsetroot
            # dmenu built from zythros/dmenu (patched with center support)
            ;;

        *)
            log_error "Unsupported distro: $DISTRO (this repo targets Fedora/RHEL-family)"
            log_warn "Please install manually: gcc make git libX11-devel libXft-devel libXinerama-devel xorg-x11-server-Xorg xorg-x11-xinit xrandr xsetroot"
            return 1
            ;;
    esac

    log_success "System dependencies installed"
}

install_nerd_font() {
    local font_dir="$HOME/.local/share/fonts"
    local marker="$font_dir/JetBrainsMonoNerdFont-Regular.ttf"

    if [ -f "$marker" ]; then
        log_info "JetBrains Mono Nerd Font already installed"
        return
    fi

    log_info "Installing JetBrains Mono Nerd Font..."

    local tmp
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/JetBrainsMono.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"; then
        mkdir -p "$font_dir"
        unzip -oq "$tmp/JetBrainsMono.zip" -d "$font_dir" '*.ttf'
        fc-cache -f "$font_dir" >/dev/null
        log_success "Installed JetBrains Mono Nerd Font to $font_dir"
    else
        log_warn "Could not download Nerd Font - falls back to plain monospace (config.def.h has a fallback entry)"
    fi
    rm -rf "$tmp"
}

# ============================================
# CORE FUNCTIONS
# ============================================

build_dwm() {
    log_info "Building dwm..."
    cd "$SCRIPT_DIR"

    make clean 2>/dev/null || true

    if ! make; then
        log_error "Build failed"
        exit 1
    fi

    log_success "Build complete"
}

install_dwm() {
    log_info "Installing dwm..."
    cd "$SCRIPT_DIR"

    if ! sudo make install; then
        log_error "Installation failed"
        exit 1
    fi

    # Symlink keybinds reference to config directory (read by MOD+space)
    mkdir -p "$HOME/.config/dwm"
    ln -sf "$SCRIPT_DIR/keybinds.txt" "$HOME/.config/dwm/keybinds.txt"

    log_success "dwm installed to /usr/local/bin/dwm"
}

build_dmenu() {
    log_info "Building dmenu..."

    local dmenu_dir="$SCRIPT_DIR/../dmenu"
    local dmenu_repo="https://github.com/zythros/dmenu.git"

    if [ ! -d "$dmenu_dir" ]; then
        log_info "Cloning dmenu (patched with center support)..."
        git clone "$dmenu_repo" "$dmenu_dir"
    fi

    cd "$dmenu_dir"
    make clean 2>/dev/null || true

    if ! make; then
        log_error "dmenu build failed"
        return 1
    fi

    if ! sudo make install; then
        log_error "dmenu installation failed"
        return 1
    fi

    cd "$SCRIPT_DIR"
    log_success "dmenu installed to /usr/local/bin/dmenu"
}

build_slstatus() {
    log_info "Building slstatus..."

    local slstatus_dir="$SCRIPT_DIR/../slstatus"
    local slstatus_repo="https://github.com/zythros/slstatus.git"

    if [ ! -d "$slstatus_dir" ]; then
        log_info "Cloning slstatus..."
        git clone "$slstatus_repo" "$slstatus_dir"
    fi

    cd "$slstatus_dir"
    make clean 2>/dev/null || true

    if ! make; then
        log_error "slstatus build failed"
        return 1
    fi

    if ! sudo make install; then
        log_error "slstatus installation failed"
        return 1
    fi

    cd "$SCRIPT_DIR"
    log_success "slstatus installed to /usr/local/bin/slstatus"
}

install_archlinux_logout() {
    log_info "Installing archlinux-logout..."

    local logout_dir="$SCRIPT_DIR/../archlinux-logout"
    local logout_repo="https://github.com/zythros/archlinux-logout.git"

    if [ ! -d "$logout_dir" ]; then
        log_info "Cloning archlinux-logout..."
        git clone "$logout_repo" "$logout_dir"
    fi

    # Python/GTK deps for the logout menu (MOD+x). betterlockscreen (its lock
    # action) isn't packaged for Fedora - the app degrades gracefully without
    # it, printing a warning instead of locking.
    sudo dnf install -y \
        python3-gobject \
        python3-psutil \
        python3-cairo \
        python3-distro \
        libwnck3

    # Install files
    sudo cp -r "$logout_dir/usr/bin/"* /usr/bin/
    sudo cp -r "$logout_dir/usr/share/"* /usr/share/
    [ -d "$logout_dir/etc" ] && sudo cp -r "$logout_dir/etc/"* /etc/ 2>/dev/null

    log_success "archlinux-logout installed"
}

setup_gtk_theme() {
    log_info "Setting up GTK dark theme..."

    local gtk3_dir="$HOME/.config/gtk-3.0"
    local gtk3_conf="$gtk3_dir/settings.ini"

    mkdir -p "$gtk3_dir"

    if [ -f "$gtk3_conf" ]; then
        log_info "GTK config already exists at $gtk3_conf"
        return
    fi

    cat > "$gtk3_conf" << 'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
EOF

    log_success "Created GTK config at $gtk3_conf"
}

setup_picom_config() {
    log_info "Setting up picom config..."

    local picom_dir="$HOME/.config/picom"
    local picom_conf="$picom_dir/picom.conf"

    mkdir -p "$picom_dir"

    if [ -f "$picom_conf" ]; then
        log_info "picom config already exists at $picom_conf"
        return
    fi

    cat > "$picom_conf" << 'EOF'
# picom config for dwm

# Backend - use glx for blur support
backend = "glx";
vsync = true;
glx-no-stencil = true;
use-damage = true;

# Shadows (disabled for cleaner look)
shadow = false;

# Fading
fading = false;

# Opacity
inactive-opacity = 1.0;
active-opacity = 1.0;
frame-opacity = 1.0;
inactive-opacity-override = false;

# Blur
blur-method = "dual_kawase";
blur-size = 12;
blur-strength = 6;
blur-background = true;
blur-background-frame = false;
blur-background-fixed = false;
blur-kern = "3x3box";

blur-background-exclude = [
    "window_type = 'menu'",
    "window_type = 'dropdown_menu'",
    "window_type = 'popup_menu'",
    "window_type = 'tooltip'",
    "window_type = 'utility'",
];

# Corners
corner-radius = 0;

# Opacity rules
opacity-rule = [
    "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'",
    "90:class_g = 'Rofi'",
    "100:window_type = 'menu'",
    "100:window_type = 'dropdown_menu'",
    "100:window_type = 'popup_menu'",
    "100:window_type = 'tooltip'",
    "100:window_type = 'utility'",
];

# Window detection
mark-wmwin-focused = false;
mark-ovredir-focused = false;
detect-rounded-corners = true;
detect-client-opacity = true;
detect-transient = true;
use-ewmh-active-win = true;

# Window types
wintypes:
{
    tooltip = { fade = true; shadow = true; opacity = 0.75; focus = true; };
    dock = { shadow = false; clip-shadow-above = true; };
    dnd = { shadow = false; };
    popup_menu = { opacity = 0.8; };
    dropdown_menu = { opacity = 0.8; };
};

log-level = "warn";
EOF

    log_success "Created picom config at $picom_conf"
}

create_desktop_entry() {
    log_info "Creating dwm desktop entry..."

    local desktop_entry="[Desktop Entry]
Name=dwm
Comment=Dynamic Window Manager
Exec=/usr/local/bin/dwm-session
Type=XSession"

    sudo mkdir -p /usr/share/xsessions
    echo "$desktop_entry" | sudo tee /usr/share/xsessions/dwm.desktop > /dev/null

    log_success "Desktop entry created at /usr/share/xsessions/dwm.desktop"
}

create_session_wrapper() {
    log_info "Creating session wrapper..."

    sudo tee /usr/local/bin/dwm-session > /dev/null << 'EOF'
#!/bin/bash
# dwm session wrapper - runs autostart then dwm

# Source system xinitrc scripts
if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
        [ -x "$f" ] && . "$f"
    done
fi

# Run user autostart
[ -x "$HOME/.dwm/autostart.sh" ] && "$HOME/.dwm/autostart.sh" &

# Start dwm (loop allows restart without logout)
while true; do
    dwm 2>/dev/null
    [ $? -eq 0 ] && break
done
EOF

    sudo chmod +x /usr/local/bin/dwm-session
    log_success "Created /usr/local/bin/dwm-session"
}

install_scripts() {
    log_info "Installing user scripts..."

    mkdir -p "$HOME/.local/bin"
    install -m 755 "$SCRIPT_DIR/scripts/wallpaper.sh" "$HOME/.local/bin/"

    log_success "Installed scripts to ~/.local/bin/"
}

setup_autostart() {
    local autostart_dir="$HOME/.dwm"
    local autostart="$autostart_dir/autostart.sh"

    mkdir -p "$autostart_dir"

    if [ -f "$autostart" ]; then
        log_info "Autostart script already exists at $autostart"
        return
    fi

    log_info "Creating autostart script..."

    cat > "$autostart" << 'EOF'
#!/bin/bash
#
# dwm autostart - runs when dwm session starts
# Edit this file to customize your startup
#

# --------------------------------------------
# WALLPAPER
# --------------------------------------------
WALLPAPER_DIR="$HOME/.local/share/wallpapers"
WALLPAPER_REPO="https://github.com/zythros/wallpaper.git"

if [ ! -d "$WALLPAPER_DIR" ]; then
    git clone "$WALLPAPER_REPO" "$WALLPAPER_DIR" 2>/dev/null
fi

# Restore last wallpaper (or first if no state)
if [ -x "$HOME/.local/bin/wallpaper.sh" ]; then
    "$HOME/.local/bin/wallpaper.sh" restore
elif [ -d "$WALLPAPER_DIR" ] && command -v feh &>/dev/null; then
    feh --bg-fill "$(find "$WALLPAPER_DIR" -maxdepth 1 -type f | sort | head -1)" 2>/dev/null
fi

# --------------------------------------------
# COMPOSITOR (skip in VMs - causes display issues)
# --------------------------------------------
is_vm() {
    systemd-detect-virt -q 2>/dev/null && return 0
    grep -qiE 'hypervisor|vmware|virtualbox|qemu|kvm' /proc/cpuinfo 2>/dev/null && return 0
    [ -d /proc/vz ] && return 0
    return 1
}

if command -v picom &>/dev/null; then
    pkill -x picom 2>/dev/null
    if is_vm; then
        : # Skip picom in VMs
    else
        picom -b 2>/dev/null
    fi
fi

# --------------------------------------------
# NOTIFICATIONS
# --------------------------------------------
if command -v dunst &>/dev/null; then
    pkill -x dunst 2>/dev/null
    dunst &
fi

# --------------------------------------------
# STATUS BAR (slstatus)
# --------------------------------------------
if command -v slstatus &>/dev/null; then
    pkill -x slstatus 2>/dev/null
    slstatus &
fi
EOF

    chmod +x "$autostart"
    log_success "Created autostart script at $autostart"
}

setup_xinitrc() {
    local xinitrc="$HOME/.xinitrc"

    if [ -f "$xinitrc" ]; then
        if grep -q "exec dwm" "$xinitrc"; then
            log_info "~/.xinitrc already configured for dwm"
            return
        else
            log_warn "~/.xinitrc exists but doesn't start dwm"
            log_warn "Add 'exec dwm' to the end of your ~/.xinitrc"
            return
        fi
    fi

    log_info "Creating ~/.xinitrc..."

    cat > "$xinitrc" << 'EOF'
#!/bin/sh

# Source xprofile if it exists
[ -f ~/.xprofile ] && . ~/.xprofile

# Compositor (skip in VMs)
if ! systemd-detect-virt -q 2>/dev/null; then
    picom -b &
fi

# Wallpaper
[ -d "$HOME/.local/share/wallpapers" ] && "$HOME/.local/bin/wallpaper.sh" restore &

# Status bar
slstatus &

# Start dwm
exec dwm
EOF

    chmod +x "$xinitrc"
    log_success "Created ~/.xinitrc"
}

print_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  fedora-dwm Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Display manager: ${DM_USED:-none (use startx)}"
    echo ""
    echo "To start dwm:"
    if [ -n "$DM_USED" ]; then
        echo "  - Log out and select 'dwm' from session menu"
    else
        echo "  - Run: startx"
    fi
    echo ""
    echo "Key bindings (MOD = Super):"
    echo "  MOD + Return    : Terminal (kitty)"
    echo "  MOD + d         : App launcher (dmenu)"
    echo "  MOD + q         : Close window"
    echo "  MOD + j/k       : Focus windows"
    echo "  MOD + Shift+j/k : Move windows"
    echo "  MOD + Shift+f   : Fullscreen"
    echo "  MOD + [1-9]     : Switch tags"
    echo "  MOD + space     : Show full keybind list"
    echo "  MOD + Shift+q   : Quit dwm"
    echo ""
    echo "Configuration: $SCRIPT_DIR/config.def.h"
    echo "After editing, rebuild: make && sudo make install"
    echo ""
}

# ============================================
# MAIN
# ============================================

main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║       fedora-dwm Installer            ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"

    detect_distro
    log_info "Detected distro: $DISTRO"

    # ----------------------------------------
    # SYSTEM DEPENDENCIES (required)
    # ----------------------------------------

    install_dependencies
    install_nerd_font

    # ----------------------------------------
    # CORE INSTALLATION
    # ----------------------------------------

    build_dwm
    install_dwm
    build_dmenu
    build_slstatus
    install_archlinux_logout

    detect_display_manager
    create_session_wrapper
    create_desktop_entry
    install_scripts
    setup_autostart
    setup_gtk_theme
    setup_picom_config
    setup_xinitrc

    print_summary
}

# Handle arguments
case "$1" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help      Show this help"
        echo ""
        echo "To skip certain setup steps, comment out the corresponding"
        echo "function calls in install.sh's main()."
        exit 0
        ;;
    *)
        main
        ;;
esac
