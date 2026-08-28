#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2034
# =============================================================================
# Package Manager Inventory Script
# =============================================================================
# Purpose: Lists all installed applications across apt, snap, flatpak, pip, npm
#          and identifies those with 'classic' installation mode (mainly snaps)
#          Filters out OS base packages for APT section
#          Prevents file manager lockups with .nopreview marker files
# Outputs: Results saved to a dedicated directory (not in current folder)
# Usage: ./package_inventory.sh [--classic-only] [--verbose] [--dry-run] [--json] [--show-os-packages] [--help]
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration - PREVENT FILE MANAGER LOCKUP
# =============================================================================

# Use a dedicated directory alongside this repo's other backup output,
# regardless of the directory from which this script is launched.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$SCRIPT_DIR/backup/.system_reports"  # Hidden directory (dot prefix)

# Create the directory if it doesn't exist
mkdir -p "$REPORT_DIR" 2>/dev/null || {
    # Fallback to /tmp if we can't create in home
    REPORT_DIR="/tmp/system_reports_$(whoami)"
    mkdir -p "$REPORT_DIR" 2>/dev/null
}

# Resolve to an absolute path now -- this script later cd's to /tmp (see
# "Change to a safe directory" below) for file-manager safety, and a
# relative REPORT_DIR would silently start pointing at the wrong place
# once that happens.
REPORT_DIR="$(cd "$REPORT_DIR" && pwd)"

# =============================================================================
# SOLUTION 3: Create marker files to prevent file manager indexing
# =============================================================================

# .nopreview - Tells file managers not to generate thumbnails/previews
touch "${REPORT_DIR}/.nopreview" 2>/dev/null

# .nomedia - Tells file managers not to scan for media files
touch "${REPORT_DIR}/.nomedia" 2>/dev/null

# .hidden - Tells GNOME/Thunar to hide the directory (optional)
touch "${REPORT_DIR}/.hidden" 2>/dev/null

# .metadata_never_index - Tells Tracker (GNOME search) to ignore this directory
touch "${REPORT_DIR}/.metadata_never_index" 2>/dev/null

# Additionally, set the directory to be excluded from indexing
if command -v gio >/dev/null 2>&1; then
    # GNOME: Mark directory as non-indexable
    gio set -t unset "${REPORT_DIR}" metadata::indexed 2>/dev/null || true
    gio set -t bool "${REPORT_DIR}" metadata::indexed false 2>/dev/null || true
fi

# Output file naming
OUTPUT_FILE="installed_packages_inventory.txt"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FULL_OUTPUT="${REPORT_DIR}/${TIMESTAMP}_${OUTPUT_FILE}"

# Script flags
SHOW_ONLY_CLASSIC=false
VERBOSE=false
DRY_RUN=false
JSON_OUTPUT=false
SHOW_OS_PACKAGES=false
SHOW_UBUNTU_SNAPS=false

# Ubuntu/system-provided snap names -- base runtimes, snapd infrastructure,
# and GNOME/GTK/KDE/Mesa platform content snaps that come bundled with
# Ubuntu, not something the user chose to install. Filtered out of the snap
# section by default.
UBUNTU_SNAP_PATTERN='^(core[0-9]*|snapd|bare|gtk[0-9]*-common-themes|gnome-[0-9]+-[0-9]+(-[0-9]+)?|kde-frameworks-[0-9]+-[0-9]+-qt-[0-9]+-[0-9]+-[0-9]+-core[0-9]+|kf[0-9]+-[0-9]+-[0-9]+-qt-[0-9]+-[0-9]+-[0-9]+-core[0-9]+|mesa-[0-9]+|snap-store|snapd-desktop-integration|firmware-updater)[[:space:]]'

# Colors for terminal output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    NC=''
fi

# Cleanup function for temp files
cleanup() {
    rm -f /tmp/snap_*_$$.txt 2>/dev/null
    rm -f /tmp/flatpak_*_$$.txt 2>/dev/null
    rm -f /tmp/npm_*_$$.txt 2>/dev/null
    rm -f /tmp/pip_*_$$.txt 2>/dev/null
    rm -f /tmp/json_*_$$.txt 2>/dev/null
    rm -f /tmp/apt_*_$$.txt 2>/dev/null
}
trap cleanup EXIT

# Function: Print colored message to stderr
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_section() {
    echo -e "${BLUE}[SECTION]${NC} $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    fi
}

# Function: Safely get numeric count from output
safe_count() {
    local output="$1"
    if [[ -z "$output" ]]; then
        echo 0
    else
        echo "$output" | grep -c . 2>/dev/null || echo 0
    fi
}

# Function: Safely add numbers (handles empty/whitespace)
safe_add() {
    local a="${1:-0}"
    local b="${2:-0}"
    a=$(echo "$a" | tr -d '[:space:]')
    b=$(echo "$b" | tr -d '[:space:]')
    [[ -z "$a" || ! "$a" =~ ^[0-9]+$ ]] && a=0
    [[ -z "$b" || ! "$b" =~ ^[0-9]+$ ]] && b=0
    echo $((a + b))
}

# Function: Write to output file (respects dry-run)
write_output() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would write: $1" >&2
    else
        echo "$1" >> "$FULL_OUTPUT"
    fi
}

# Function: Write section to output file
write_section() {
    local section_title="$1"
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would write section: $section_title" >&2
    else
        echo "=============================================================================" >> "$FULL_OUTPUT"
        echo "$section_title" >> "$FULL_OUTPUT"
        echo "=============================================================================" >> "$FULL_OUTPUT"
        echo "" >> "$FULL_OUTPUT"
    fi
}

# Function: Start timing for performance metrics
start_timer() {
    if command_exists bc; then
        echo "$(date +%s.%N)"
    else
        echo "$(date +%s)"
    fi
}

# Function: End timing and report duration
end_timer() {
    local start_time="$1"
    local section_name="$2"
    if command_exists bc; then
        local end_time duration
        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
        log_verbose "Section '$section_name' completed in ${duration}s"
    else
        local end_time duration
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        log_verbose "Section '$section_name' completed in ${duration}s"
    fi
}

# Function: Check if command exists and is executable
command_exists() {
    command -v "$1" &> /dev/null
}

# Function: Filter Ubuntu/system-provided snaps out of `snap list` output
# (reads snap-list-style lines on stdin). Respects --show-ubuntu-snaps.
filter_ubuntu_snaps() {
    if [[ "$SHOW_UBUNTU_SNAPS" == true ]]; then
        cat
    else
        grep -vE "$UBUNTU_SNAP_PATTERN" || true
    fi
}

# Function: Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --classic-only)
                SHOW_ONLY_CLASSIC=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --show-os-packages)
                SHOW_OS_PACKAGES=true
                shift
                ;;
            --show-ubuntu-snaps)
                SHOW_UBUNTU_SNAPS=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --classic-only      Only show classic confinement snaps (skip other sections)"
                echo "  --verbose           Enable verbose/debug output"
                echo "  --dry-run           Show what would be done without writing output"
                echo "  --json              Output in JSON format (machine-readable)"
                echo "  --show-os-packages  Show OS base packages in APT section (filtered out by default)"
                echo "  --show-ubuntu-snaps Show Ubuntu/system snaps in Snap section (filtered out by default)"
                echo "  --help              Show this help message"
                echo ""
                echo "Output: Reports are saved to: $REPORT_DIR"
                echo "        File managers are prevented from indexing/locking this directory"
                echo ""
                echo "Examples:"
                echo "  $0 --classic-only"
                echo "  $0 --verbose"
                echo "  $0 --json"
                echo "  $0 --show-os-packages"
                echo "  $0 --show-ubuntu-snaps"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Function: Get OS base packages
get_os_packages() {
    local os_packages_file="/tmp/apt_os_packages_$$.txt"
    
    log_verbose "Identifying OS base packages..."
    
    # Method 1: Check for packages installed on system installation date
    local install_date
    install_date=$(dpkg-query -W -f='${Package}\t${Status}\t${Installed-Date}\n' 2>/dev/null | \
        grep -E "install ok installed" | \
        head -1 | \
        awk -F'\t' '{print $3}' | \
        cut -d' ' -f1 | \
        grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" || echo "")

    if [[ -n "$install_date" ]]; then
        log_verbose "OS install date detected: $install_date"
        dpkg-query -W -f='${Package}\t${Installed-Date}\n' 2>/dev/null | \
            grep "$install_date" | \
            awk -F'\t' '{print $1}' > "$os_packages_file"
    fi

    # Method 2: Use popularity-contest data if available
    if [[ ! -s "$os_packages_file" ]] && [[ -f /var/log/installer/syslog ]]; then
        log_verbose "Using installer logs to identify OS packages..."
        grep " installed " /var/log/installer/syslog 2>/dev/null | \
            awk '{print $NF}' | \
            sort -u > "$os_packages_file"
    fi

    # Method 3: Use package priority
    if [[ ! -s "$os_packages_file" ]]; then
        log_verbose "Using package priority to identify OS packages..."
        dpkg-query -W -f='${Package}\t${Priority}\n' 2>/dev/null | \
            grep -E "(required|important|standard)" | \
            awk -F'\t' '{print $1}' > "$os_packages_file"
    fi
    
    # Method 4: Manual list of common OS packages (fallback)
    if [[ ! -s "$os_packages_file" ]]; then
        log_verbose "Using fallback list of common OS packages..."
        cat > "$os_packages_file" << 'EOF'
systemd
systemd-sysv
systemd-timesyncd
systemd-resolved
systemd-networkd
systemd-journald
systemd-logind
systemd-udevd
kernel
linux-base
linux-firmware
linux-headers
linux-image
linux-modules
util-linux
coreutils
bash
bash-completion
grep
sed
awk
findutils
gzip
tar
dpkg
apt
apt-utils
gnupg
openssl
ca-certificates
curl
wget
perl
python3
python3-minimal
gcc
g++
make
build-essential
openssh-server
openssh-client
netplan.io
network-manager
net-tools
iproute2
iputils-ping
dnsutils
rsyslog
cron
anacron
man-db
manpages
nano
vim-tiny
less
sudo
adduser
passwd
login
rsync
ssh
grub-common
initramfs-tools
udev
usbutils
pciutils
dmidecode
lshw
EOF
    fi
    
    echo "$os_packages_file"
}

# Function: Detect pip command
detect_pip() {
    local python_cmd
    
    log_verbose "Detecting Python pip..."
    
    for python_cmd in python3 python; do
        if command_exists "$python_cmd"; then
            log_verbose "Checking $python_cmd -m pip..."
            if "$python_cmd" -m pip --version >/dev/null 2>&1; then
                echo "$python_cmd -m pip"
                return 0
            fi
        fi
    done
    
    if command_exists pip3; then
        log_verbose "Using standalone pip3"
        echo "pip3"
        return 0
    elif command_exists pip; then
        log_verbose "Using standalone pip"
        echo "pip"
        return 0
    fi
    
    for python_cmd in pip3.12 pip3.11 pip3.10; do
        if command_exists "$python_cmd"; then
            log_verbose "Using $python_cmd"
            echo "$python_cmd"
            return 0
        fi
    done
    
    log_verbose "No pip found"
    echo ""
    return 1
}

# Function: Get npm packages
get_npm_packages() {
    local npm_output_file="/tmp/npm_$$.txt"
    
    log_verbose "Getting npm packages..."
    
    if command_exists jq; then
        log_verbose "Using npm with JSON output"
        if npm list -g --depth=0 --json 2>/dev/null > "$npm_output_file"; then
            if jq -r '.dependencies | keys[]' "$npm_output_file" 2>/dev/null | grep -q .; then
                jq -r '.dependencies | keys[]' "$npm_output_file" 2>/dev/null | sort
                rm -f "$npm_output_file"
                return 0
            fi
        fi
        rm -f "$npm_output_file"
    fi
    
    log_verbose "Using npm with text parsing"
    npm list -g --depth=0 2>/dev/null | \
        grep -E '^[^@]*@[0-9]' | \
        awk -F'@' '{if (NF>=2) print $1}' | \
        sort
}

# Function: Get environment information
get_environment_info() {
    local section_start
    section_start=$(start_timer)
    log_verbose "Collecting environment information..."
    
    write_section "ENVIRONMENT INFORMATION"
    
    write_output "Hostname: $(hostname 2>/dev/null || echo 'N/A')"
    write_output "Username: $(whoami 2>/dev/null || echo 'N/A')"
    write_output "Date/Time: $(date)"
    write_output "Uptime: $(uptime -p 2>/dev/null || echo 'N/A')"
    write_output ""
    write_output "--- Operating System ---"
    if [[ -f /etc/os-release ]]; then
        grep -E "^(PRETTY_NAME|NAME|VERSION|ID)=" /etc/os-release 2>/dev/null | sed 's/^/  /' | while read -r line; do
            write_output "$line"
        done || write_output "  Unable to read OS info"
    else
        write_output "  OS: $(uname -s 2>/dev/null || echo 'Unknown')"
    fi
    write_output ""
    write_output "--- Kernel ---"
    write_output "  Kernel: $(uname -r 2>/dev/null || echo 'N/A')"
    write_output "  Architecture: $(uname -m 2>/dev/null || echo 'N/A')"
    write_output ""
    write_output "--- System Resources ---"
    write_output "  CPU: $(nproc 2>/dev/null || echo 'N/A') cores"
    write_output "  Memory: $(free -h 2>/dev/null | grep -E '^Mem:' | awk '{print $2}' || echo 'N/A')"
    write_output "  Disk: $(df -h / 2>/dev/null | awk 'NR==2 {print $2 " total, " $4 " available"}' || echo 'N/A')"
    write_output ""
    write_output "--- User Environment ---"
    write_output "  Shell: $SHELL"
    write_output "  Home: $HOME"
    write_output "  PATH: $(echo $PATH | tr ':' '\n' | head -5 | tr '\n' ':' | sed 's/:$//')..."
    write_output ""
    
    end_timer "$section_start" "Environment Information"
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    # Parse command line arguments
    parse_args "$@"
    
    log_info "Starting package inventory scan..."
    log_verbose "Verbose mode enabled"
    log_info "Reports will be saved to: $REPORT_DIR"
    log_info "File managers will NOT index/lock this directory (marker files created)"
    
    if [[ "$SHOW_OS_PACKAGES" == false ]]; then
        log_info "APT: OS base packages will be filtered out (use --show-os-packages to include them)"
    else
        log_info "APT: OS base packages will be included"
    fi

    if [[ "$SHOW_UBUNTU_SNAPS" == false ]]; then
        log_info "Snap: Ubuntu/system snaps will be filtered out (use --show-ubuntu-snaps to include them)"
    else
        log_info "Snap: Ubuntu/system snaps will be included"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN mode - No files will be written"
    fi
    
    # Change to a safe directory to prevent any file manager interaction
    cd /tmp 2>/dev/null || cd / 2>/dev/null || {
        log_error "Cannot change to safe directory"
        exit 1
    }
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        log_info "JSON output mode enabled"
        if [[ "$DRY_RUN" != true ]]; then
            echo "{" > "$FULL_OUTPUT"
            echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "$FULL_OUTPUT"
            echo "  \"hostname\": \"$(hostname 2>/dev/null || echo 'N/A')\"," >> "$FULL_OUTPUT"
            echo "  \"packages\": {" >> "$FULL_OUTPUT"
        fi
    else
        log_info "Output file: $FULL_OUTPUT"
        
        if [[ "$DRY_RUN" != true ]]; then
            {
                echo "============================================================================="
                echo "INSTALLED PACKAGES INVENTORY REPORT"
                echo "Generated: $(date)"
                echo "Host: $(hostname 2>/dev/null || echo 'N/A')"
                echo "============================================================================="
                echo ""
            } > "$FULL_OUTPUT" || {
                log_error "Failed to write to output file"
                exit 1
            }
        else
            log_info "DRY RUN: Would write report header"
        fi
    fi
    
    # Get environment information
    if [[ "$JSON_OUTPUT" != true ]]; then
        if [[ "$DRY_RUN" != true ]]; then
            get_environment_info
        else
            log_info "DRY RUN: Would collect environment information"
        fi
    fi

    # --classic-only mode
    if [[ "$SHOW_ONLY_CLASSIC" == true ]]; then
        local section_start
        section_start=$(start_timer)
        log_section "Classic-only mode - showing only classic confinement snaps"
        
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "    \"classic_snaps\": ["
        else
            write_section "CLASSIC CONFINEMENT SNAPS ONLY"
        fi
        
        if command_exists snap; then
            log_info "Scanning for classic confinement snaps..."
            
            snap_classic_output=$(snap list --classic 2>/dev/null | tail -n +2 | filter_ubuntu_snaps || true)
            classic_count=$(safe_count "$snap_classic_output")

            if [[ $classic_count -gt 0 ]]; then
                if [[ "$JSON_OUTPUT" == true ]]; then
                    local first=true
                    echo "$snap_classic_output" | while IFS= read -r line; do
                        if [[ -n "$line" ]]; then
                            local snap_name snap_version snap_channel
                            snap_name=$(echo "$line" | awk '{print $1}')
                            snap_version=$(echo "$line" | awk '{print $3}')
                            snap_channel=$(echo "$line" | awk '{print $4}')
                            if [[ "$first" == true ]]; then
                                write_output "      {\"name\": \"$snap_name\", \"version\": \"$snap_version\", \"channel\": \"$snap_channel\", \"confinement\": \"classic\"}"
                                first=false
                            else
                                write_output "      ,{\"name\": \"$snap_name\", \"version\": \"$snap_version\", \"channel\": \"$snap_channel\", \"confinement\": \"classic\"}"
                            fi
                        fi
                    done
                else
                    echo "$snap_classic_output" | while IFS= read -r line; do
                        if [[ -n "$line" ]]; then
                            write_output "[CLASSIC] $line"
                        fi
                    done
                    write_output ""
                    write_output "Total classic snaps: $classic_count"
                fi
                log_info "Found $classic_count classic snaps"
            else
                if [[ "$JSON_OUTPUT" == true ]]; then
                    write_output "      ]"
                else
                    write_output "(no classic confinement snaps detected)"
                fi
                log_info "No classic snaps found"
            fi
        else
            log_warn "snap command not found"
            if [[ "$JSON_OUTPUT" == true ]]; then
                write_output "      ]"
            else
                write_output "Snap: Not available on this system"
            fi
        fi
        
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "    ]"
            write_output "  }"
            write_output "}"
        fi
        
        end_timer "$section_start" "Classic-only scan"
        log_info "Classic snap scan complete!"
        log_info "Report saved to: $FULL_OUTPUT"
        exit 0
    fi

    # =========================================================================
    # SECTION 1: APT Installed Packages (Filtered)
    # =========================================================================
    local section_start
    section_start=$(start_timer)
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    \"apt\": {"
    else
        write_section "SECTION 1: APT INSTALLED PACKAGES"
        if [[ "$SHOW_OS_PACKAGES" == false ]]; then
            write_output "NOTE: OS base packages and auto-installed dependencies (lib*-dev, old kernel"
            write_output "packages, etc.) are filtered out -- only packages you explicitly installed are"
            write_output "shown. Use --show-os-packages to include them."
            write_output ""
        fi
    fi

    if command_exists dpkg-query; then
        log_section "Scanning apt/dpkg packages..."

        os_packages_file=""
        manual_packages_file=""
        if [[ "$SHOW_OS_PACKAGES" == false ]]; then
            os_packages_file=$(get_os_packages)
            log_verbose "OS packages file: $os_packages_file"
            os_package_count=$(safe_count "$(cat "$os_packages_file" 2>/dev/null || true)")
            log_verbose "Found $os_package_count OS base packages to filter"

            # apt-mark distinguishes packages you actually asked for from
            # ones apt pulled in automatically as a dependency (lib*-dev,
            # lib*-perl transitive deps, and old kernel image/header/modules
            # packages superseded by a newer one -- those are all "auto"
            # once a newer kernel meta-package depends on the latest).
            # Strip any ":arch" suffix apt-mark adds so this matches on the
            # same bare package name used for filtering below.
            if command_exists apt-mark; then
                manual_packages_file="/tmp/apt_manual_packages_$$.txt"
                apt-mark showmanual 2>/dev/null | sed 's/:.*//' | sort -u > "$manual_packages_file"
                manual_package_count=$(safe_count "$(cat "$manual_packages_file" 2>/dev/null || true)")
                log_verbose "Restricting to $manual_package_count manually-installed packages"
            fi
        fi

        # Package and Architecture are kept as separate fields so a genuine
        # multiarch duplicate (the same package name installed for two
        # architectures) can be told apart from a package that merely
        # supports Multi-Arch: same -- only the former gets an ":arch"
        # suffix in the final display, decided after filtering below.
        all_packages_raw=$(dpkg-query -W -f='${Package}\t${Architecture}\t${Version}\t${Installed-Size}\n' 2>/dev/null | \
            grep -v "deinstall\|purge\|config-files" || true)

        if [[ "$SHOW_OS_PACKAGES" == false ]] && [[ -f "$os_packages_file" ]]; then
            log_verbose "Filtering out OS base packages..."
            all_packages_raw=$(echo "$all_packages_raw" | \
                awk -F'\t' 'NR==FNR {os[$1]=1; next} !($1 in os)' \
                "$os_packages_file" - 2>/dev/null || echo "$all_packages_raw")
        fi

        if [[ "$SHOW_OS_PACKAGES" == false ]] && [[ -n "$manual_packages_file" ]] && [[ -s "$manual_packages_file" ]]; then
            log_verbose "Filtering out auto-installed dependency packages..."
            all_packages_raw=$(echo "$all_packages_raw" | \
                awk -F'\t' 'NR==FNR {man[$1]=1; next} ($1 in man)' \
                "$manual_packages_file" - 2>/dev/null || echo "$all_packages_raw")
        fi

        apt_packages_output=$(awk -F'\t' '
            NR==FNR { cnt[$1]++; next }
            {
                name = $1
                if (cnt[name] > 1) name = name ":" $2
                print name "\t" $3 "\t" $4
            }
        ' <(echo "$all_packages_raw") <(echo "$all_packages_raw"))

        total_size=$(echo "$apt_packages_output" | \
            awk -F'\t' '{s+=$3}END{printf "%.1f", s/1024}' 2>/dev/null || echo "N/A")
        
        apt_count=$(safe_count "$apt_packages_output")
        
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "      \"total_size_mb\": \"$total_size\","
            write_output "      \"count\": $apt_count,"
            if [[ "$SHOW_OS_PACKAGES" == false ]]; then
                write_output "      \"os_packages_filtered\": true,"
                write_output "      \"os_package_count\": $os_package_count,"
            fi
            write_output "      \"packages\": ["
            local first=true
            echo "$apt_packages_output" | while IFS=$'\t' read -r pkg_name pkg_version pkg_size; do
                if [[ -n "$pkg_name" ]]; then
                    if [[ "$first" == true ]]; then
                        write_output "        {\"name\": \"$pkg_name\", \"version\": \"$pkg_version\", \"size_kb\": ${pkg_size:-null}}"
                        first=false
                    else
                        write_output "        ,{\"name\": \"$pkg_name\", \"version\": \"$pkg_version\", \"size_kb\": ${pkg_size:-null}}"
                    fi
                fi
            done
            write_output "      ]"
        else
            write_output "Total installed size (user-installed): ${total_size} MB"
            
            if [[ "$SHOW_OS_PACKAGES" == false ]]; then
                write_output "OS packages filtered out: $os_package_count"
            fi
            write_output ""
            write_output "Installed Packages (Non-OS):"
            echo "$apt_packages_output" | while IFS=$'\t' read -r pkg_name pkg_version pkg_size; do
                if [[ -n "$pkg_name" ]]; then
                    write_output "$pkg_name"
                fi
            done
            write_output ""
            write_output "Total user-installed APT packages: $apt_count"
            
            if [[ "$SHOW_OS_PACKAGES" == false ]] && [[ -f "$os_packages_file" ]]; then
                write_output ""
                write_output "--- OS BASE PACKAGES (filtered out) ---"
                write_output "To include these, run with: --show-os-packages"
                write_output ""
                cat "$os_packages_file" 2>/dev/null | head -20 | while IFS= read -r pkg; do
                    write_output "  $pkg"
                done
                if [[ $os_package_count -gt 20 ]]; then
                    write_output "  ... and $((os_package_count - 20)) more"
                fi
                write_output ""
            fi
        fi
        
        log_info "Found $apt_count user-installed APT packages"
    else
        log_warn "dpkg-query not found - skipping APT scan"
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "      \"available\": false,"
            write_output "      \"error\": \"dpkg-query not found\""
        else
            write_output "APT: Not available on this system"
        fi
    fi
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    },"
    else
        write_output ""
    fi
    
    end_timer "$section_start" "APT Scan"

    # =========================================================================
    # SECTION 2: Snap Installed Packages
    # =========================================================================
    section_start=$(start_timer)
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    \"snap\": {"
    else
        write_section "SECTION 2: SNAP INSTALLED PACKAGES (Classic vs Non-Classic)"
        if [[ "$SHOW_UBUNTU_SNAPS" == false ]]; then
            write_output "NOTE: Ubuntu/system snaps are filtered out. Use --show-ubuntu-snaps to include them."
            write_output ""
        fi
    fi

    if command_exists snap; then
        log_section "Scanning snap packages..."

        snap_classic_output=$(snap list --classic 2>/dev/null | tail -n +2 | filter_ubuntu_snaps || true)
        snap_all_output=$(snap list --all 2>/dev/null | tail -n +2 | filter_ubuntu_snaps || true)
        
        classic_count=$(safe_count "$snap_classic_output")
        non_classic_count=$(safe_count "$(echo "$snap_all_output" | grep -v classic || true)")
        total_snaps=$(safe_add "$classic_count" "$non_classic_count")
        
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "      \"count\": $total_snaps,"
            write_output "      \"classic_count\": $classic_count,"
            write_output "      \"non_classic_count\": $non_classic_count,"
            write_output "      \"classic_snaps\": ["
            
            local first=true
            echo "$snap_classic_output" | while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    local snap_name snap_version snap_channel snap_rev
                    snap_name=$(echo "$line" | awk '{print $1}')
                    snap_version=$(echo "$line" | awk '{print $3}')
                    snap_channel=$(echo "$line" | awk '{print $4}')
                    snap_rev=$(echo "$line" | awk '{print $2}')
                    if [[ "$first" == true ]]; then
                        write_output "        {\"name\": \"$snap_name\", \"version\": \"$snap_version\", \"channel\": \"$snap_channel\", \"revision\": \"$snap_rev\", \"confinement\": \"classic\"}"
                        first=false
                    else
                        write_output "        ,{\"name\": \"$snap_name\", \"version\": \"$snap_version\", \"channel\": \"$snap_channel\", \"revision\": \"$snap_rev\", \"confinement\": \"classic\"}"
                    fi
                fi
            done
            write_output "      ],"
            write_output "      \"non_classic_snaps\": ["
            
            first=true
            echo "$snap_all_output" | grep -v classic | while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    local snap_name snap_version snap_confinement
                    snap_name=$(echo "$line" | awk '{print $1}')
                    snap_version=$(echo "$line" | awk '{print $3}')
                    snap_confinement=$(echo "$line" | awk '{print $6}')
                    if [[ "$first" == true ]]; then
                        write_output "        {\"name\": \"$snap_name\", \"version\": \"$snap_version\", \"confinement\": \"$snap_confinement\"}"
                        first=false
                    else
                        write_output "        ,{\"name\": \"$snap_name\", \"version\": \"$snap_version\", \"confinement\": \"$snap_confinement\"}"
                    fi
                fi
            done
            write_output "      ]"
        else
            write_output "--- CLASSIC CONFINEMENT SNAPS ---"
            write_output ""
            if [[ $classic_count -gt 0 ]]; then
                echo "$snap_classic_output" | while IFS= read -r line; do
                    if [[ -n "$line" ]]; then
                        write_output "$(echo "$line" | awk '{print $1}')"
                    fi
                done
            else
                write_output "(none detected)"
            fi
            write_output ""

            write_output "--- NON-CLASSIC CONFINEMENT SNAPS ---"
            write_output ""
            if [[ $non_classic_count -gt 0 ]]; then
                echo "$snap_all_output" | grep -v classic | while IFS= read -r line; do
                    if [[ -n "$line" ]]; then
                        write_output "$(echo "$line" | awk '{print $1}')"
                    fi
                done
            else
                write_output "(none detected)"
            fi
            write_output ""
            
            write_output "SNAP SUMMARY:"
            write_output "  Classic snaps: $classic_count"
            write_output "  Non-classic snaps: $non_classic_count"
            write_output "  Total snaps: $total_snaps"
            write_output ""
        fi
        
        log_info "Snap scan complete - Found $classic_count classic snaps, $non_classic_count non-classic snaps"
    else
        log_warn "snap command not found - skipping Snap scan"
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "      \"available\": false,"
            write_output "      \"error\": \"snap command not found\""
        else
            write_output "Snap: Not available on this system"
        fi
    fi
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    },"
    else
        write_output ""
    fi
    
    end_timer "$section_start" "Snap Scan"

    # =========================================================================
    # SECTION 3: Flatpak Installed Packages
    # =========================================================================
    section_start=$(start_timer)
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    \"flatpak\": {"
    else
        write_section "SECTION 3: FLATPAK INSTALLED PACKAGES"
    fi

    if command_exists flatpak; then
        log_section "Scanning flatpak packages..."
        
        # Explicit --columns= instead of relying on flatpak's default column
        # layout, which isn't application-id-first and varies by version --
        # that mismatch was showing the app's Name/vendor field where the
        # application ID was expected.
        flatpak_user_output=$(flatpak list --app --user --columns=application,name,version,branch,origin 2>/dev/null || true)
        flatpak_system_output=$(flatpak list --app --system --columns=application,name,version,branch,origin 2>/dev/null || true)
        
        flatpak_user_count=$(safe_count "$flatpak_user_output")
        flatpak_system_count=$(safe_count "$flatpak_system_output")
        flatpak_total=$(safe_add "$flatpak_user_count" "$flatpak_system_count")
        
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "      \"count\": $flatpak_total,"
            write_output "      \"user_count\": $flatpak_user_count,"
            write_output "      \"system_count\": $flatpak_system_count,"
            write_output "      \"user_packages\": ["
            
            local first=true
            echo "$flatpak_user_output" | while IFS=$'\t' read -r app_id app_name version branch origin; do
                if [[ -n "$app_id" ]]; then
                    if [[ "$first" == true ]]; then
                        write_output "        {\"id\": \"$app_id\", \"name\": \"$app_name\", \"version\": \"$version\", \"origin\": \"$origin\"}"
                        first=false
                    else
                        write_output "        ,{\"id\": \"$app_id\", \"name\": \"$app_name\", \"version\": \"$version\", \"origin\": \"$origin\"}"
                    fi
                fi
            done
            write_output "      ],"
            write_output "      \"system_packages\": ["
            
            first=true
            echo "$flatpak_system_output" | while IFS=$'\t' read -r app_id app_name version branch origin; do
                if [[ -n "$app_id" ]]; then
                    if [[ "$first" == true ]]; then
                        write_output "        {\"id\": \"$app_id\", \"name\": \"$app_name\", \"version\": \"$version\", \"origin\": \"$origin\"}"
                        first=false
                    else
                        write_output "        ,{\"id\": \"$app_id\", \"name\": \"$app_name\", \"version\": \"$version\", \"origin\": \"$origin\"}"
                    fi
                fi
            done
            write_output "      ]"
        else
            write_output "USER INSTALLATIONS:"
            if [[ $flatpak_user_count -gt 0 ]]; then
                echo "$flatpak_user_output" | while IFS=$'\t' read -r app_id app_name version branch origin; do
                    if [[ -n "$app_id" ]]; then
                        write_output "$app_id"
                    fi
                done
            else
                write_output "(none)"
            fi
            write_output ""

            write_output "SYSTEM INSTALLATIONS:"
            if [[ $flatpak_system_count -gt 0 ]]; then
                echo "$flatpak_system_output" | while IFS=$'\t' read -r app_id app_name version branch origin; do
                    if [[ -n "$app_id" ]]; then
                        write_output "$app_id"
                    fi
                done
            else
                write_output "(none)"
            fi
            write_output ""

            write_output "FLATPAK SUMMARY:"
            write_output "  User installations: $flatpak_user_count"
            write_output "  System installations: $flatpak_system_count"
            write_output "  Total Flatpak packages: $flatpak_total"
            write_output ""
        fi
        
        log_info "Flatpak scan complete - Found $flatpak_total packages ($flatpak_user_count user, $flatpak_system_count system)"
    else
        log_warn "flatpak command not found - skipping Flatpak scan"
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "      \"available\": false,"
            write_output "      \"error\": \"flatpak command not found\""
        else
            write_output "Flatpak: Not available on this system"
        fi
    fi
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    },"
    else
        write_output ""
    fi
    
    end_timer "$section_start" "Flatpak Scan"

    # =========================================================================
    # SECTION 4: Python pip/pip3 Installed Packages
    # =========================================================================
    section_start=$(start_timer)
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    \"python_pip\": {"
    else
        write_section "SECTION 4: PYTHON PIP/PIP3 INSTALLED PACKAGES"
    fi

    pip_cmd=$(detect_pip)
    if [[ -n "$pip_cmd" ]]; then
        log_section "Scanning Python packages with: $pip_cmd"
        
        if [[ "$JSON_OUTPUT" != true ]]; then
            write_output "PYTHON PACKAGES:"
        fi
        
        pip_output_file="/tmp/pip_$$.txt"
        if eval "$pip_cmd list --format=freeze" 2>/dev/null > "$pip_output_file"; then
            pip_count=$(safe_count "$(cat "$pip_output_file" 2>/dev/null || true)")
            
            if [[ "$JSON_OUTPUT" == true ]]; then
                write_output "      \"count\": $pip_count,"
                write_output "      \"packages\": ["
                local first=true
                while IFS='==' read -r pkg_name pkg_version; do
                    if [[ -n "$pkg_name" ]]; then
                        if [[ "$first" == true ]]; then
                            write_output "        {\"name\": \"$pkg_name\", \"version\": \"$pkg_version\"}"
                            first=false
                        else
                            write_output "        ,{\"name\": \"$pkg_name\", \"version\": \"$pkg_version\"}"
                        fi
                    fi
                done < "$pip_output_file"
                write_output "      ]"
            else
                if [[ $pip_count -gt 0 ]]; then
                    cat "$pip_output_file" | sort | while IFS= read -r line; do
                        write_output "${line%%==*}"
                    done
                    write_output ""
                    write_output "Total pip packages: $pip_count"
                else
                    write_output "(none)"
                    write_output ""
                    write_output "Total pip packages: 0"
                fi
            fi
            rm -f "$pip_output_file"
        else
            log_warn "Failed to get pip packages"
            if [[ "$JSON_OUTPUT" == true ]]; then
                write_output "      \"error\": \"Failed to query pip packages\""
            else
                write_output "(unable to query pip packages)"
            fi
        fi
        
        if [[ "$JSON_OUTPUT" != true ]]; then
            write_output ""
        fi
        
        log_info "Python scan complete"
    else
        log_warn "pip/pip3 not found - skipping Python scan"
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "      \"available\": false,"
            write_output "      \"error\": \"pip not found\""
        else
            write_output "pip: Not available on this system"
            write_output ""
        fi
    fi
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    },"
    fi
    
    end_timer "$section_start" "Python pip Scan"

    # =========================================================================
    # SECTION 5: NPM Global Packages
    # =========================================================================
    section_start=$(start_timer)
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    \"npm\": {"
    else
        write_section "SECTION 5: NPM GLOBAL PACKAGES"
    fi

    if command_exists npm; then
        log_section "Scanning npm global packages..."
        
        if [[ "$JSON_OUTPUT" != true ]]; then
            write_output "NPM GLOBAL PACKAGES:"
        fi
        
        npm_packages=$(get_npm_packages)
        if [[ -n "$npm_packages" ]]; then
            npm_count=$(echo "$npm_packages" | wc -l | tr -d '[:space:]')
            [[ -z "$npm_count" ]] && npm_count=0
            
            if [[ "$JSON_OUTPUT" == true ]]; then
                write_output "      \"count\": $npm_count,"
                write_output "      \"packages\": ["
                local first=true
                echo "$npm_packages" | while IFS= read -r pkg_name; do
                    if [[ -n "$pkg_name" ]]; then
                        if [[ "$first" == true ]]; then
                            write_output "        {\"name\": \"$pkg_name\"}"
                            first=false
                        else
                            write_output "        ,{\"name\": \"$pkg_name\"}"
                        fi
                    fi
                done
                write_output "      ]"
            else
                echo "$npm_packages" | while IFS= read -r line; do
                    write_output "$line"
                done
                write_output ""
                write_output "Total npm global packages: $npm_count"
            fi
        else
            if [[ "$JSON_OUTPUT" == true ]]; then
                write_output "      \"count\": 0,"
                write_output "      \"packages\": []"
            else
                write_output "(none)"
                write_output ""
                write_output "Total npm global packages: 0"
            fi
        fi
        
        if [[ "$JSON_OUTPUT" != true ]]; then
            write_output ""
        fi
        
        log_info "npm scan complete"
    else
        log_warn "npm not found - skipping npm scan"
        if [[ "$JSON_OUTPUT" == true ]]; then
            write_output "      \"available\": false,"
            write_output "      \"error\": \"npm not found\""
        else
            write_output "npm: Not available on this system"
            write_output ""
        fi
    fi
    
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "    }"
    fi
    
    end_timer "$section_start" "NPM Scan"

    # =========================================================================
    # SECTION 6: Summary
    # =========================================================================
    if [[ "$JSON_OUTPUT" == true ]]; then
        write_output "  }"
        write_output "}"
    else
        write_section "FINAL SUMMARY"
        
        if command_exists dpkg-query; then
            apt_total=$(dpkg-query -W -f='${Package}\n' 2>/dev/null | wc -l | tr -d '[:space:]')
            [[ -z "$apt_total" ]] && apt_total=0
            
            if [[ -n "${apt_count:-}" ]]; then
                write_output "APT packages (user-installed): $apt_count (filtered from $apt_total total)"
            else
                write_output "APT packages: $apt_total"
            fi
        else
            write_output "APT packages: Not available"
        fi
        
        if command_exists snap; then
            if [[ -n "${classic_count:-}" ]] && [[ -n "${non_classic_count:-}" ]]; then
                snap_total=$(safe_add "$classic_count" "$non_classic_count")
                write_output "Snap packages: $snap_total total ($classic_count classic, $non_classic_count non-classic)"
            else
                snap_classic=$(snap list --classic 2>/dev/null | tail -n +2 | filter_ubuntu_snaps | wc -l | tr -d '[:space:]')
                snap_non_classic=$(snap list --all 2>/dev/null | tail -n +2 | grep -v classic | filter_ubuntu_snaps | wc -l | tr -d '[:space:]')
                [[ -z "$snap_classic" ]] && snap_classic=0
                [[ -z "$snap_non_classic" ]] && snap_non_classic=0
                snap_total=$((snap_classic + snap_non_classic))
                write_output "Snap packages: $snap_total total ($snap_classic classic, $snap_non_classic non-classic)"
            fi
        else
            write_output "Snap packages: Not available"
        fi
        
        if command_exists flatpak; then
            flatpak_user=$(flatpak list --app --user 2>/dev/null | wc -l | tr -d '[:space:]')
            flatpak_system=$(flatpak list --app --system 2>/dev/null | wc -l | tr -d '[:space:]')
            [[ -z "$flatpak_user" ]] && flatpak_user=0
            [[ -z "$flatpak_system" ]] && flatpak_system=0
            flatpak_total=$((flatpak_user + flatpak_system))
            write_output "Flatpak packages: $flatpak_total total ($flatpak_user user, $flatpak_system system)"
        else
            write_output "Flatpak packages: Not available"
        fi
        
        if command_exists npm; then
            npm_total=$(npm list -g --depth=0 2>/dev/null | grep -E '^[^@]*@[0-9]' | wc -l | tr -d '[:space:]')
            [[ -z "$npm_total" ]] && npm_total=0
            write_output "NPM global packages: $npm_total"
        else
            write_output "NPM global packages: Not available"
        fi
        
        pip_cmd=$(detect_pip)
        if [[ -n "$pip_cmd" ]]; then
            pip_total=$(eval "$pip_cmd list --format=freeze" 2>/dev/null | wc -l | tr -d '[:space:]')
            [[ -z "$pip_total" ]] && pip_total=0
            write_output "Python pip packages: $pip_total"
        else
            write_output "Python pip packages: Not available"
        fi
        
        write_output ""
        write_output "============================================================================="
        write_output "Report completed: $(date)"
        write_output "============================================================================="
        
        log_info ""
        log_info "Inventory complete! Report saved to: $FULL_OUTPUT"
        log_info "Report directory: $REPORT_DIR (protected from file manager indexing)"
        
        echo ""
        log_info "Summary:"
        [[ -n "${apt_count:-}" ]] && log_info "  APT (user-installed): $apt_count packages"
        [[ -n "${snap_total:-}" ]] && log_info "  Snap: $snap_total packages"
        [[ -n "${flatpak_total:-}" ]] && log_info "  Flatpak: $flatpak_total packages"
        [[ -n "${npm_total:-}" ]] && log_info "  NPM: $npm_total global packages"
        [[ -n "${pip_total:-}" ]] && log_info "  Python pip: $pip_total packages"
        
        log_info ""
        log_info "To view the report: cat $FULL_OUTPUT"
        log_info "To open in less: less $FULL_OUTPUT"
    fi
}

# Execute main function
main "$@"
