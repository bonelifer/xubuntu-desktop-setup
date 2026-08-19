#!/usr/bin/bash

#
# Script: uninstall-old-zulu.sh
# Description: Keep only the latest LTS (25) Zulu JDK, install it if
#              missing, and uninstall only packages that are actually
#              installed.
#

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    DRY_RUN=true
    echo "🧪 DRY RUN – no changes will be made."
fi

LTS_VERSIONS=(8 11 17 21 25)
LATEST_LTS=25

# ----------------------------------------------------------------------
# Helper: detect package manager
# ----------------------------------------------------------------------
detect_pkg_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# ----------------------------------------------------------------------
# Helper: find the exact package name for a given Zulu version (for installation)
# ----------------------------------------------------------------------
find_zulu_package() {
    local ver=$1
    local pkg_manager=$2
    local candidates=()

    case "$pkg_manager" in
        apt)
            local all_pkgs
            all_pkgs=$(apt-cache search --names-only '^zulu' 2>/dev/null | awk '{print $1}' | sort -u)
            for pattern in "zulu-${ver}-jdk" "zulu${ver}-jdk" "zulu-${ver}" "zulu${ver}"; do
                if echo "$all_pkgs" | grep -q "^${pattern}$"; then
                    candidates+=("$pattern")
                fi
            done
            if [[ ${#candidates[@]} -eq 0 ]]; then
                while IFS= read -r pkg; do
                    if [[ "$pkg" == *"zulu"*"${ver}"* ]] || [[ "$pkg" == *"zulu"*"-${ver}"* ]]; then
                        candidates+=("$pkg")
                    fi
                done <<< "$all_pkgs"
            fi
            ;;
        dnf|yum)
            for pattern in "zulu-${ver}-jdk" "zulu${ver}-jdk"; do
                if rpm -q --quiet "$pattern" 2>/dev/null; then
                    candidates+=("$pattern")
                fi
            done
            if command -v yum &>/dev/null; then
                available=$(yum list available "zulu*" 2>/dev/null | awk '/zulu/ {print $1}')
                for pkg in $available; do
                    if [[ "$pkg" == *"zulu"*"${ver}"* ]]; then
                        candidates+=("$pkg")
                    fi
                done
            fi
            ;;
        zypper)
            for pattern in "zulu-${ver}-jdk" "zulu${ver}-jdk"; do
                candidates+=("$pattern")
            done
            ;;
        *)
            return 1
            ;;
    esac

    if [[ ${#candidates[@]} -gt 0 ]]; then
        for pkg in "zulu-${ver}-jdk" "zulu${ver}-jdk" "zulu-${ver}" "zulu${ver}"; do
            for cand in "${candidates[@]}"; do
                if [[ "$cand" == "$pkg" ]]; then
                    echo "$cand"
                    return 0
                fi
            done
        done
        echo "${candidates[0]}"
        return 0
    else
        return 1
    fi
}

# ----------------------------------------------------------------------
# Helper: install Java 25 (with discovery and manual fallback)
# ----------------------------------------------------------------------
install_java_25() {
    local pkg_manager
    pkg_manager=$(detect_pkg_manager)
    local pkg_name=""

    if [[ "$pkg_manager" == "apt" ]]; then
        echo "Updating package lists..."
        sudo apt update
        pkg_name=$(find_zulu_package "$LATEST_LTS" "$pkg_manager") || true
        if [[ -z "$pkg_name" ]]; then
            echo "❌ No Zulu package for version $LATEST_LTS found in your repositories."
            read -p "Would you like to download and install the .deb manually now? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Visit https://www.azul.com/downloads/ to download the .deb package."
                echo "After downloading, install with: sudo dpkg -i <file>.deb"
                echo "Then re-run this script."
                return 1
            else
                return 1
            fi
        else
            echo "📦 Found package: $pkg_name"
            if [[ "$DRY_RUN" == true ]]; then
                echo "   (DRY RUN – would run: sudo apt install -y $pkg_name)"
                return 0
            fi
            sudo apt install -y "$pkg_name"
            return $?
        fi
    elif [[ "$pkg_manager" == "dnf" ]] || [[ "$pkg_manager" == "yum" ]]; then
        pkg_name=$(find_zulu_package "$LATEST_LTS" "$pkg_manager") || true
        if [[ -z "$pkg_name" ]]; then
            echo "❌ No Zulu package for version $LATEST_LTS found."
            read -p "Would you like to download the RPM manually? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Download from https://www.azul.com/downloads/ and install with: sudo rpm -ivh <file>.rpm"
                return 1
            else
                return 1
            fi
        else
            echo "📦 Found package: $pkg_name"
            if [[ "$DRY_RUN" == true ]]; then
                echo "   (DRY RUN – would run: sudo $pkg_manager install -y $pkg_name)"
                return 0
            fi
            sudo "$pkg_manager" install -y "$pkg_name"
            return $?
        fi
    elif [[ "$pkg_manager" == "zypper" ]]; then
        pkg_name=$(find_zulu_package "$LATEST_LTS" "$pkg_manager") || true
        if [[ -z "$pkg_name" ]]; then
            echo "❌ No Zulu package for version $LATEST_LTS found."
            echo "Please install manually from https://www.azul.com/downloads/"
            return 1
        else
            echo "📦 Found package: $pkg_name"
            if [[ "$DRY_RUN" == true ]]; then
                echo "   (DRY RUN – would run: sudo zypper install -y $pkg_name)"
                return 0
            fi
            sudo zypper install -y "$pkg_name"
            return $?
        fi
    else
        echo "❌ Unsupported package manager. Please install Java $LATEST_LTS manually."
        return 1
    fi
}

# ----------------------------------------------------------------------
# Helper: set JAVA_HOME and update alternatives
# ----------------------------------------------------------------------
set_java_home() {
    local keep_ver=$1
    local java_home=""

    # Determine JAVA_HOME path
    if [[ -n "${installed_dirs[$keep_ver]:-}" ]]; then
        java_home="${installed_dirs[$keep_ver]}"
    elif [[ -n "${installed_pkgs[$keep_ver]:-}" ]]; then
        local possible_paths=("/usr/lib/jvm/zulu-${keep_ver}" "/usr/lib/jvm/zulu-${keep_ver}-jdk" "/usr/lib/jvm/zulu${keep_ver}")
        for path in "${possible_paths[@]}"; do
            if [[ -d "$path" && -f "$path/bin/java" ]]; then
                java_home="$path"
                break
            fi
        done
        if [[ -z "$java_home" ]] && command -v dpkg &>/dev/null; then
            # The version may map to several packages (jdk, jre, doc, ...);
            # only one of them actually ships bin/java, so check each.
            local vpkgs pkg java_bin
            read -ra vpkgs <<< "${installed_pkgs[$keep_ver]}"
            for pkg in "${vpkgs[@]}"; do
                java_bin=$(dpkg -L "$pkg" 2>/dev/null | grep -E '/bin/java$' | head -n1)
                if [[ -n "$java_bin" ]]; then
                    java_home=$(dirname "$(dirname "$java_bin")")
                    break
                fi
            done
        fi
    fi

    if [[ -z "$java_home" || ! -f "$java_home/bin/java" ]]; then
        echo "❌ Could not determine JAVA_HOME for the kept version ($keep_ver)."
        echo "   Please set it manually."
        return 1
    fi

    echo "✅ Found JAVA_HOME: $java_home"

    # Update alternatives (system default)
    if command -v update-alternatives &>/dev/null; then
        echo "Setting Java as default via update-alternatives..."
        local java_bin="$java_home/bin/java"
        local javac_bin="$java_home/bin/javac"
        if [[ -f "$java_bin" ]]; then
            sudo update-alternatives --install /usr/bin/java java "$java_bin" 1 2>/dev/null || true
            sudo update-alternatives --set java "$java_bin" 2>/dev/null || true
        fi
        if [[ -f "$javac_bin" ]]; then
            sudo update-alternatives --install /usr/bin/javac javac "$javac_bin" 1 2>/dev/null || true
            sudo update-alternatives --set javac "$javac_bin" 2>/dev/null || true
        fi
    fi

    # Ask where to set JAVA_HOME permanently
    echo ""
    echo "Where would you like to set JAVA_HOME?"
    echo "  1) ~/.bashrc (recommended – user, interactive shells)"
    echo "  2) ~/.profile (user, all login shells)"
    echo "  3) /etc/environment (system-wide, requires sudo)"
    echo "  4) Skip"
    read -p "Choose (1-4): " choice

    local file=""
    case "$choice" in
        1) file="$HOME/.bashrc" ;;
        2) file="$HOME/.profile" ;;
        3) file="/etc/environment" ;;
        4) echo "Skipping permanent JAVA_HOME."; return 0 ;;
        *) echo "Invalid – skipping."; return 0 ;;
    esac

    local export_line="export JAVA_HOME=$java_home"
    local path_line='export PATH="$JAVA_HOME/bin:$PATH"'

    if [[ "$file" == "/etc/environment" ]]; then
        export_line="JAVA_HOME=$java_home"
        path_line=""
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo "   (DRY RUN – would add to $file:)"
        echo "     $export_line"
        [[ -n "$path_line" ]] && echo "     $path_line"
        return 0
    fi

    if grep -q "^export JAVA_HOME=" "$file" 2>/dev/null || grep -q "^JAVA_HOME=" "$file" 2>/dev/null; then
        sudo sed -i "s|^.*JAVA_HOME=.*|$export_line|" "$file"
    else
        echo "$export_line" | sudo tee -a "$file" >/dev/null
    fi

    if [[ -n "$path_line" ]]; then
        if grep -q "^export PATH=.*JAVA_HOME" "$file" 2>/dev/null; then
            sudo sed -i "s|^export PATH=.*|$path_line|" "$file"
        else
            echo "$path_line" | sudo tee -a "$file" >/dev/null
        fi
    fi

    echo "✅ JAVA_HOME set in $file."

    export JAVA_HOME="$java_home"
    export PATH="$JAVA_HOME/bin:$PATH"

    echo "✅ Environment variables exported for this session."
    echo ""
    echo "ℹ️  For new terminals, the variables will be automatically set."
    if [[ "$file" == "/etc/environment" ]]; then
        echo "   To apply them to this terminal, run: source /etc/environment"
    else
        echo "   To apply them to this terminal, run: source $file"
    fi

    return 0
}

# ----------------------------------------------------------------------
# Helper: confirm a dpkg-reported package actually has files on disk.
# dpkg status 'ii' only means dpkg's database thinks it's installed —
# it doesn't guarantee the files are still there (e.g. something got
# deleted outside of dpkg). Skip packages that fail this check instead
# of offering to keep/remove a record that no longer matches reality.
# ----------------------------------------------------------------------
pkg_has_files_on_disk() {
    local pkg=$1
    local f
    while IFS= read -r f; do
        [[ -e "$f" ]] && return 0
    done < <(dpkg -L "$pkg" 2>/dev/null)
    return 1
}

# ----------------------------------------------------------------------
# 1. Find **installed** package-managed Zulu JDKs (only status 'ii')
# ----------------------------------------------------------------------
declare -A installed_pkgs   # version -> package name
if command -v dpkg &>/dev/null; then
    # List only installed packages (status 'ii')
    while IFS= read -r pkg; do
        # Match patterns: zulu-<ver>-jdk, zulu<ver>-jdk, etc. Store the
        # exact package name as reported by dpkg, not a truncated regex
        # capture group, so later "apt remove" calls target a package
        # that actually exists — otherwise removal silently targets a
        # phantom name (e.g. "zulu25" instead of "zulu25-jdk") and the
        # version keeps reappearing as still-installed on every rerun.
        #
        # A single version can have several real packages installed at
        # once (e.g. zulu21-jdk-headless, zulu21-jre-headless,
        # zulu21-doc). Append rather than overwrite, otherwise only the
        # last match for a version survives and its siblings are never
        # offered for removal — they just resurface on a later run once
        # the one that "won" is gone, looking like nothing was removed.
        if [[ "$pkg" =~ ^zulu-([0-9]+)-jdk ]] || [[ "$pkg" =~ ^zulu([0-9]+) ]]; then
            ver="${BASH_REMATCH[1]}"
            if pkg_has_files_on_disk "$pkg"; then
                installed_pkgs["$ver"]="${installed_pkgs[$ver]:-}$pkg "
            else
                echo "⚠️  Skipping $pkg: dpkg lists it as installed but no files were found on disk." >&2
            fi
        fi
    done < <(dpkg -l 2>/dev/null | grep '^ii' | awk '{print $2}' | sort -u)
fi

# ----------------------------------------------------------------------
# 2. Find directory-based installations
# ----------------------------------------------------------------------
declare -A installed_dirs
JVM_DIRS=("/usr/lib/jvm" "/usr/java" "/opt" "$HOME/.java" "/Library/Java/JavaVirtualMachines")

for base in "${JVM_DIRS[@]}"; do
    if [[ -d "$base" ]]; then
        while IFS= read -r dir; do
            if [[ "$dir" =~ zulu-([0-9]+)\.jdk$ ]] || [[ "$dir" =~ zulu-?([0-9]+) ]]; then
                ver="${BASH_REMATCH[1]}"
                installed_dirs["$ver"]="$dir"
            fi
        done < <(find "$base" -maxdepth 1 -type d -name "*zulu*" 2>/dev/null | sort)
    fi
done

# ----------------------------------------------------------------------
# 3. Helper: check if a version is installed
# ----------------------------------------------------------------------
has_version() {
    local ver=$1
    [[ -n "${installed_pkgs[$ver]:-}" ]] || [[ -n "${installed_dirs[$ver]:-}" ]]
}

# ----------------------------------------------------------------------
# 4. List all installed LTS versions
# ----------------------------------------------------------------------
found_lts=()
for ver in "${!installed_pkgs[@]}"; do
    if [[ " ${LTS_VERSIONS[*]} " =~ " ${ver} " ]]; then
        found_lts+=("$ver")
    fi
done
for ver in "${!installed_dirs[@]}"; do
    if [[ " ${LTS_VERSIONS[*]} " =~ " ${ver} " ]]; then
        if [[ ! " ${found_lts[*]} " =~ " ${ver} " ]]; then
            found_lts+=("$ver")
        fi
    fi
done

IFS=$'\n' found_lts=($(sort -n <<<"${found_lts[*]}"))
unset IFS

# ----------------------------------------------------------------------
# 5. Ensure Java 25 is present (install if missing)
# ----------------------------------------------------------------------
keep_ver=""

if has_version "$LATEST_LTS"; then
    keep_ver="$LATEST_LTS"
    echo "✅ Java $LATEST_LTS (latest LTS) is already installed. It will be kept."
else
    echo "⚠️  Java $LATEST_LTS (the latest LTS) is NOT installed."
    echo ""
    read -p "🔧 Would you like me to install Java $LATEST_LTS now? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if install_java_25; then
            # Re-scan for version 25 after installation (same exact-name
            # rule as the initial scan above — see comment there).
            if command -v dpkg &>/dev/null; then
                while IFS= read -r pkg; do
                    if [[ "$pkg" =~ ^zulu-${LATEST_LTS}-jdk ]] || [[ "$pkg" =~ ^zulu${LATEST_LTS} ]]; then
                        if pkg_has_files_on_disk "$pkg"; then
                            installed_pkgs["$LATEST_LTS"]="${installed_pkgs[$LATEST_LTS]:-}$pkg "
                        fi
                    fi
                done < <(dpkg -l 2>/dev/null | grep '^ii' | awk '{print $2}' | sort -u)
            fi
            for base in "${JVM_DIRS[@]}"; do
                if [[ -d "$base" ]]; then
                    while IFS= read -r dir; do
                        if [[ "$dir" =~ zulu-${LATEST_LTS}\.jdk$ ]] || [[ "$dir" =~ zulu-?${LATEST_LTS} ]]; then
                            installed_dirs["$LATEST_LTS"]="$dir"
                        fi
                    done < <(find "$base" -maxdepth 1 -type d -name "*zulu*" 2>/dev/null | sort)
                fi
            done

            if has_version "$LATEST_LTS"; then
                keep_ver="$LATEST_LTS"
                echo "✅ Java $LATEST_LTS is now installed and will be kept."
            else
                echo "❌ Installation succeeded but I still can't detect Java $LATEST_LTS."
                echo "   Please verify manually and re-run the script."
                exit 1
            fi
        else
            echo "Installation failed or was skipped."
            if [[ ${#found_lts[@]} -gt 0 ]]; then
                echo ""
                echo "Installed LTS versions found: ${found_lts[*]}"
                read -p "Proceed WITHOUT Java $LATEST_LTS? (Will keep highest installed LTS: ${found_lts[-1]}) [y/N]: " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    keep_ver="${found_lts[-1]}"
                    echo "Keeping LTS version: $keep_ver"
                else
                    echo "Aborted. Please install Java $LATEST_LTS manually and re-run."
                    exit 0
                fi
            else
                echo "No LTS versions found at all. Cannot proceed."
                echo "Please install Java $LATEST_LTS manually and re-run."
                exit 1
            fi
        fi
    else
        # User said no to installation
        if [[ ${#found_lts[@]} -gt 0 ]]; then
            echo ""
            echo "Installed LTS versions found: ${found_lts[*]}"
            read -p "Proceed WITHOUT Java $LATEST_LTS? (Will keep highest installed LTS: ${found_lts[-1]}) [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                keep_ver="${found_lts[-1]}"
                echo "Keeping LTS version: $keep_ver"
            else
                echo "Aborted."
                exit 0
            fi
        else
            echo "No LTS versions found. Please install Java $LATEST_LTS first."
            exit 1
        fi
    fi
fi

# ----------------------------------------------------------------------
# 6. Display what will be kept / removed (only truly installed packages)
# ----------------------------------------------------------------------
echo ""
echo "📦 Installed Zulu packages (dpkg):"
if [[ ${#installed_pkgs[@]} -eq 0 ]]; then
    echo "   (none)"
else
    for ver in "${!installed_pkgs[@]}"; do
        read -ra vpkgs <<< "${installed_pkgs[$ver]}"
        for pkg in "${vpkgs[@]}"; do
            if [[ "$ver" == "$keep_ver" ]]; then
                echo "   ✅ KEEP: $pkg (LTS $ver)"
            else
                echo "   ❌ REMOVE: $pkg (version $ver)"
            fi
        done
    done
fi

echo ""
echo "📁 Zulu directories found:"
if [[ ${#installed_dirs[@]} -eq 0 ]]; then
    echo "   (none)"
else
    for ver in "${!installed_dirs[@]}"; do
        dir="${installed_dirs[$ver]}"
        if [[ "$ver" == "$keep_ver" ]]; then
            echo "   ✅ KEEP: $dir (LTS $ver)"
        else
            echo "   ❌ REMOVE: $dir (version $ver)"
        fi
    done
fi

# ----------------------------------------------------------------------
# 7. Perform uninstall (unless dry-run, or there's nothing to remove)
# ----------------------------------------------------------------------
anything_to_remove=false
for ver in "${!installed_pkgs[@]}" "${!installed_dirs[@]}"; do
    if [[ "$ver" != "$keep_ver" ]]; then
        anything_to_remove=true
        break
    fi
done

if [[ "$anything_to_remove" == false ]]; then
    echo ""
    echo "✅ Nothing to remove — only LTS $keep_ver is installed."
    exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "🧪 DRY RUN completed – no changes made."
    echo "   Remove the --dry-run flag to actually uninstall."
    exit 0
fi

echo ""
read -p "⚠️  Proceed with uninstalling ALL older versions (keeping only LTS $keep_ver)? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Remove packages
for ver in "${!installed_pkgs[@]}"; do
    if [[ "$ver" != "$keep_ver" ]]; then
        read -ra vpkgs <<< "${installed_pkgs[$ver]}"
        for pkg in "${vpkgs[@]}"; do
            echo "Removing package: $pkg"
            if command -v apt &>/dev/null; then
                sudo apt purge -y "$pkg"
            elif command -v dnf &>/dev/null; then
                sudo dnf remove -y "$pkg"
            elif command -v yum &>/dev/null; then
                sudo yum remove -y "$pkg"
            elif command -v zypper &>/dev/null; then
                sudo zypper remove -y "$pkg"
            else
                echo "⚠️  Unknown package manager. Remove manually: sudo dpkg -P $pkg"
            fi
        done
    fi
done

# Remove directories
for ver in "${!installed_dirs[@]}"; do
    if [[ "$ver" != "$keep_ver" ]]; then
        dir="${installed_dirs[$ver]}"
        echo "Removing directory: $dir"
        sudo rm -rf "$dir"
    fi
done

echo ""
echo "✅ Done. Remaining Zulu JDK:"
[[ -n "${installed_pkgs[$keep_ver]:-}" ]] && echo "   Package: ${installed_pkgs[$keep_ver]}"
[[ -n "${installed_dirs[$keep_ver]:-}" ]] && echo "   Directory: ${installed_dirs[$keep_ver]}"

# ----------------------------------------------------------------------
# 8. Set JAVA_HOME (optional)
# ----------------------------------------------------------------------
echo ""
read -p "🔧 Would you like to set JAVA_HOME to the kept version and update alternatives? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    set_java_home "$keep_ver"
else
    echo "You can manually set JAVA_HOME later."
fi
