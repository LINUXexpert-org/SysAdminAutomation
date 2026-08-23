#!/bin/bash
# disk_cleanup.sh - Show disk usage and optionally clean temporary files
# 
# Copyright (C) 2025 LINUXexpert.org
# 
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the 
# Free Software Foundation, version 3 of the License.
# 
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
# for more details.
# 
# You should have received a copy of the GNU General Public License along 
# with this program. If not, see <https://www.gnu.org/licenses/>.
# 
# Usage: disk_cleanup.sh [OPTIONS]
# Options:
#   --clean              Perform cleanup of package caches and temporary files
#   --dry-run            Show what would be cleaned without actually removing files
#   --age DAYS           Set age threshold for temp file cleanup (default: 7)
#   --dirs DIR1,DIR2     Specify custom directories to clean (default: /tmp,/var/tmp)
#                        Protected system directories are refused.
#   --yes                Skip the confirmation prompt for non-default --dirs
#   --help               Display this help message
#
# Examples:
#   disk_cleanup.sh                              # Show disk usage overview
#   disk_cleanup.sh --clean                      # Perform cleanup with defaults
#   disk_cleanup.sh --dry-run                    # Preview cleanup actions
#   disk_cleanup.sh --clean --age 14 --dry-run   # Preview cleanup with 14-day threshold
#

set -o pipefail

# ===== CONFIGURATION =====
AGE_THRESHOLD=7
DIRS_TO_CLEAN=("/tmp" "/var/tmp")
DRY_RUN=false
CLEAN_MODE=false
ASSUME_YES=false
LOG_FILE="/var/log/disk_cleanup.log"

# ===== UTILITY FUNCTIONS =====

# Print usage information
usage() {
  # Print the comment block between the "# Usage:" line and the blank
  # comment that ends it. Previously this sliced fixed line numbers
  # (head -22 | tail -n +18), which silently truncated the output at
  # --age as soon as the block grew -- hiding --dirs entirely.
  sed -n '/^# Usage:/,/^#$/p' "$0" | sed 's/^# \{0,1\}//'
}

# Log messages to file and stdout
log() {
  local message="$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE" 2>/dev/null || echo "$message"
}

# Error handler
error_exit() {
  local message="$1"
  local exit_code="${2:-1}"
  echo "ERROR: $message" >&2
  exit "$exit_code"
}

# Check for required commands
check_dependencies() {
  local dependencies=("df" "find" "awk" "sort")
  local missing_deps=()
  
  for cmd in "${dependencies[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      missing_deps+=("$cmd")
    fi
  done
  
  if [ ${#missing_deps[@]} -gt 0 ]; then
    error_exit "Missing required commands: ${missing_deps[*]}"
  fi
}

# Verify root privileges
check_root() {
  if [ $EUID -ne 0 ]; then
    error_exit "This action requires root privileges. Please run with sudo." 1
  fi
}

# Refuse to run -delete against paths that are not plausibly scratch
# space. --dirs previously accepted anything: `--clean --dirs /home`
# removed every file in /home older than the age threshold, and
# `--dirs /` did it system-wide, as root, with no confirmation.
validate_clean_dirs() {
  local dir real
  local protected=(
    / /bin /boot /dev /etc /home /lib /lib32 /lib64 /opt /proc /root
    /run /sbin /srv /sys /usr /var
  )

  for dir in "${DIRS_TO_CLEAN[@]}"; do
    [ -n "$dir" ] || error_exit "Empty directory in --dirs list." 1

    case "$dir" in
      /*) ;;
      *) error_exit "--dirs requires absolute paths; got '$dir'." 1 ;;
    esac

    # Compare the resolved path, so symlinks and /tmp/../home cannot
    # smuggle a protected directory past the check.
    real="$(readlink -f -- "$dir" 2>/dev/null || echo "$dir")"
    # Normalise to a trailing-slash-free form, except "/" itself, which
    # must stay "/" -- stripping it yields "" and matches nothing.
    [ "$real" = "/" ] || real="${real%/}"
    [ -n "$real" ] || real=/

    for p in "${protected[@]}"; do
      if [ "$real" = "$p" ]; then
        error_exit "Refusing to clean '$dir' (resolves to '$real'): protected directory." 1
      fi
    done
  done
}

# Anything outside the built-in defaults gets an explicit confirmation,
# because that is where the destructive surprises live.
confirm_nondefault_dirs() {
  local dir nondefault=()
  for dir in "${DIRS_TO_CLEAN[@]}"; do
    case "$dir" in
      /tmp|/var/tmp) ;;
      *) nondefault+=("$dir") ;;
    esac
  done

  [ ${#nondefault[@]} -eq 0 ] && return 0
  [ "$DRY_RUN" = true ] && return 0
  [ "$ASSUME_YES" = true ] && return 0

  if [ ! -t 0 ]; then
    error_exit "Non-default --dirs (${nondefault[*]}) need confirmation; pass --yes to run unattended." 1
  fi

  echo "About to delete files older than $AGE_THRESHOLD days from:"
  printf '  %s\n' "${nondefault[@]}"
  read -r -p "Proceed? (yes/NO): " reply
  [ "$reply" = "yes" ] || error_exit "Cancelled." 0
}

# ===== DISPLAY FUNCTIONS =====

# Show disk usage overview
show_disk_usage() {
  echo "==== Disk Usage Overview ===="
  df -h -x tmpfs -x devtmpfs || error_exit "Failed to get disk usage information"
  
  echo -e "\n==== Top 10 Largest Files ===="
  find / -type f -printf '%s %p\n' 2>/dev/null | sort -nr | head -n 10 | \
    awk '{size=$1/1024/1024; printf("%.1f MB - ", size); $1=""; print $0}' || \
    echo "Warning: Could not retrieve largest files"
}

# ===== CLEANUP FUNCTIONS =====

# Clean package manager caches
clean_package_caches() {
  local cleaned=false
  
  if command -v apt-get &> /dev/null; then
    log "Cleaning apt package cache..."
    if [ "$DRY_RUN" = false ]; then
      apt-get clean || log "Warning: apt-get clean failed"
    fi
    cleaned=true
  fi
  
  if command -v dnf &> /dev/null; then
    log "Cleaning dnf package cache..."
    if [ "$DRY_RUN" = false ]; then
      dnf clean all -y &> /dev/null || log "Warning: dnf clean failed"
    fi
    cleaned=true
  fi
  
  if command -v yum &> /dev/null; then
    log "Cleaning yum package cache..."
    if [ "$DRY_RUN" = false ]; then
      yum clean all -y &> /dev/null || log "Warning: yum clean failed"
    fi
    cleaned=true
  fi
  
  if command -v pacman &> /dev/null; then
    log "Cleaning pacman package cache..."
    if [ "$DRY_RUN" = false ]; then
      pacman -Scc --noconfirm &> /dev/null || log "Warning: pacman clean failed"
    fi
    cleaned=true
  fi
  
  if [ "$cleaned" = false ]; then
    log "Warning: No supported package manager found"
  fi
}

# Clean temporary files
clean_temporary_files() {
  for dir in "${DIRS_TO_CLEAN[@]}"; do
    if [ ! -d "$dir" ]; then
      log "Warning: Directory $dir does not exist, skipping..."
      continue
    fi
    
    log "Cleaning files older than $AGE_THRESHOLD days in $dir..."
    
    # Count files that would be deleted
    local file_count
    file_count=$(find "$dir" -type f -mtime +"$AGE_THRESHOLD" 2>/dev/null | wc -l)
    
    if [ "$file_count" -gt 0 ]; then
      if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Would remove $file_count files from $dir"
        find "$dir" -type f -mtime +"$AGE_THRESHOLD" 2>/dev/null | head -n 5 | while read -r file; do
          log "  - $file"
        done
        if [ "$file_count" -gt 5 ]; then
          log "  ... and $((file_count - 5)) more files"
        fi
      else
        if find "$dir" -type f -mtime +"$AGE_THRESHOLD" -delete 2>/dev/null; then
          log "Removed $file_count old files from $dir"
        else
          log "Warning: Failed to remove all files from $dir"
        fi
      fi
    else
      log "No files older than $AGE_THRESHOLD days found in $dir"
    fi
    
    # Clean empty directories
    if [ "$DRY_RUN" = false ]; then
      find "$dir" -type d -empty -mtime +"$AGE_THRESHOLD" -delete 2>/dev/null || true
    fi
  done
}

# ===== PARSE ARGUMENTS =====

parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --clean)
        CLEAN_MODE=true
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      --yes)
        ASSUME_YES=true
        ;;
      --age)
        if [ -z "$2" ] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
          error_exit "Invalid age value. Must be a number." 1
        fi
        AGE_THRESHOLD="$2"
        shift
        ;;
      --dirs)
        if [ -z "$2" ]; then
          error_exit "Missing directory list for --dirs option." 1
        fi
        IFS=',' read -ra DIRS_TO_CLEAN <<< "$2"
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        error_exit "Unknown option: $1. Use --help for usage information." 1
        ;;
    esac
    shift
  done
}

# ===== MAIN EXECUTION =====

main() {
  check_dependencies
  parse_arguments "$@"
  
  if [ "$CLEAN_MODE" = false ]; then
    # Display mode
    show_disk_usage
    echo -e "\n(To actually free space, run: sudo $0 --clean)"
  else
    # Cleanup mode
    check_root
    validate_clean_dirs
    confirm_nondefault_dirs
    
    if [ "$DRY_RUN" = true ]; then
      log "DRY RUN MODE - No files will be deleted"
    fi
    
    log "Starting disk cleanup process..."
    clean_package_caches
    clean_temporary_files
    
    log "Disk cleanup process completed."
  fi
}

main "$@"