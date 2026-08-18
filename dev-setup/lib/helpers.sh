#!/usr/bin/env bash
# lib/helpers.sh — shared helpers for dev-setup wizards
#
# Sourced by shell-wizard.sh and neovim-wizard.sh.
# Requires $DRY_RUN to be set by the sourcing script BEFORE sourcing this file.
# Do not execute this file directly.

# ─── ANSI colors ──────────────────────────────────────────────────────────────
BOLD='\033[1m'; DIM='\033[2m'; CYAN='\033[0;36m'
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; RESET='\033[0m'

# ─── Output helpers ───────────────────────────────────────────────────────────
say()     { echo -e "${CYAN}${BOLD}==>${RESET}${BOLD} $*${RESET}"; }
ok()      { echo -e "    ${GREEN}✓${RESET} $*"; }
warn()    { echo -e "    ${YELLOW}⚠${RESET}  $*"; }
info()    { echo -e "    ${DIM}$*${RESET}"; }
divider() { echo -e "${DIM}────────────────────────────────────────────────${RESET}"; }

# ─── Prompt helpers ───────────────────────────────────────────────────────────
# All reads pull from /dev/tty so they work inside tmux, pipes, and subshells

ask_yn() {
  # ask_yn "Question" [default: y|n]  → returns 0 for yes, 1 for no
  local question="$1" default="${2:-y}"
  local hint="[Y/n]"; [[ "$default" == "n" ]] && hint="[y/N]"
  echo -en "${CYAN}?${RESET} $question $hint: "
  local answer; IFS= read -r answer </dev/tty
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

ask_choice() {
  # ask_choice "Question" default_num "opt1" "opt2" ...
  # prints the chosen option text; caller captures with $()
  local question="$1" default="$2"; shift 2
  local options=("$@")
  echo -e "${CYAN}?${RESET} $question" >&2
  for i in "${!options[@]}"; do
    local marker="  "; [[ $((i+1)) -eq $default ]] && marker="${BOLD}* ${RESET}"
    echo -e "  ${marker}${BOLD}$((i+1))${RESET}) ${options[$i]}" >&2
  done
  echo -en "  Choice [1-${#options[@]}] (default $default): " >&2
  local choice; IFS= read -r choice </dev/tty
  choice="${choice:-$default}"
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#options[@]} )); then
    choice="$default"
  fi
  echo "${options[$((choice-1))]}"
}

ask_input() {
  # ask_input "Question" "default_value"
  # prompt → stderr (safe inside $(...)); answer → stdout
  local question="$1" default="$2"
  local hint=""; [[ -n "$default" ]] && hint=" [${default}]"
  echo -en "${CYAN}?${RESET} ${question}${hint}: " >&2
  local answer; IFS= read -r answer </dev/tty
  echo "${answer:-$default}"
}

# ─── File helpers ─────────────────────────────────────────────────────────────

write_file() {
  local path="$1" content="$2"
  if $DRY_RUN; then
    echo -e "    ${DIM}[dry-run] would write: $path${RESET}"
    return
  fi
  if [[ -f "$path" ]]; then
    cp "$path" "${path}.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backed up existing $path"
  fi
  printf '%s' "$content" > "$path"
  ok "Written: $path"
}

append_if_missing() {
  local path="$1" marker="$2" content="$3"
  if $DRY_RUN; then
    echo -e "    ${DIM}[dry-run] would append to: $path${RESET}"
    return
  fi
  if grep -qF "$marker" "$path" 2>/dev/null; then
    warn "$path already contains marker — skipping append"
  else
    printf '%s' "$content" >> "$path"
    ok "Appended to $path"
  fi
}

# ─── Install report helpers ───────────────────────────────────────────────────
install_ok()   { ok "$1"; }
install_skip() { ok "Already installed: $1"; }
install_fail() { warn "Failed: $1 — $2"; }
install_dry()  { info "[dry-run] would install: $1"; }
