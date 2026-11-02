#!/usr/bin/env bash
# shell-wizard.sh — Developer environment configurator
# Bash/zsh + Starship, pyenv, uv, kubectl, argocd, Claude Code, herdr/tmux
# Platforms: Linux, macOS, WSL
#
# Usage:
#   bash shell-wizard.sh              # interactive wizard
#   bash shell-wizard.sh --dry-run    # preview what would be written, no changes

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"
detect_platform
RC_FILE_SHORT="~${RC_FILE#$HOME}"

# ─── Banner ───────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${CYAN}"
cat << 'BANNER'
  ██████╗ ███████╗██╗   ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗
  ██╔══██╗██╔════╝██║   ██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
  ██║  ██║█████╗  ██║   ██║    ███████╗█████╗     ██║   ██║   ██║██████╔╝
  ██║  ██║██╔══╝  ╚██╗ ██╔╝    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
  ██████╔╝███████╗ ╚████╔╝     ███████║███████╗   ██║   ╚██████╔╝██║
  ╚═════╝ ╚══════╝  ╚═══╝      ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝
BANNER
echo -e "${RESET}"
$DRY_RUN && echo -e "  ${YELLOW}DRY RUN — no files will be written${RESET}\n"
divider

# ─── Gather preferences ───────────────────────────────────────────────────────
say "Preferences"
echo

THEME_LABEL=$(ask_choice "Color theme (Starship prompt + multiplexer status bar):" 1 \
  "Nord (dark, blue-purple)" \
  "Catppuccin Mocha (dark, pastel)" \
  "Tokyo Night (dark, neon)" \
  "Solarized Light" \
  "Classic (ANSI only)")
echo

case "$THEME_LABEL" in
  Nord*)        THEME="nord" ;;
  Catppuccin*)  THEME="catppuccin" ;;
  Tokyo*)       THEME="tokyo" ;;
  Solarized*)   THEME="solarized" ;;
  *)            THEME="classic" ;;
esac

KUBE_IN_PROMPT=false
if ask_yn "Show kube context/namespace in shell prompt?" y; then KUBE_IN_PROMPT=true; fi
echo

ARGO_ALIASES=false
if ask_yn "Include ArgoCD CLI aliases?" y; then ARGO_ALIASES=true; fi
echo

WORKSPACE_ROOT=$(ask_input "Projects workspace root" "$HOME/github")
echo

GIT_NAME=$(ask_input  "git user.name  (leave blank to skip)" "")
GIT_EMAIL=$(ask_input "git user.email (leave blank to skip)" "")
echo

MUX_LABEL=$(ask_choice "Terminal multiplexer:" 1 \
  "herdr  (agent-aware, recommended)" \
  "tmux   (classic, battle-tested)" \
  "skip   (none)")
echo

case "$MUX_LABEL" in
  herdr*) MUX=herdr ;;
  tmux*)  MUX=tmux  ;;
  *)      MUX=none  ;;
esac

HERDR_TUI=false
HERDR_UI=false
if [[ "$MUX" == "herdr" ]]; then
  HERDR_VARIANT_LABEL=$(ask_choice "herdr edition:" 1 \
    "TUI   (terminal app, original herdr)" \
    "UI    (native desktop app + herdr-core)" \
    "both  (TUI and UI; they don't share agents)")
  case "$HERDR_VARIANT_LABEL" in
    UI*)   HERDR_UI=true ;;
    both*) HERDR_TUI=true; HERDR_UI=true ;;
    *)     HERDR_TUI=true ;;
  esac
  echo
fi

RUN_NVIM_WIZARD=false
if ask_yn "Also run the Neovim wizard afterwards? (installs nvim + LazyVim)" y; then RUN_NVIM_WIZARD=true; fi
echo

TMUX_PREFIX="C-b"
if [[ "$MUX" == "tmux" ]]; then
  TMUX_PREFIX_LABEL=$(ask_choice "tmux prefix key:" 1 \
    "Ctrl+b (default)" \
    "Ctrl+a" \
    "Ctrl+Space")
  case "$TMUX_PREFIX_LABEL" in
    *Ctrl+a*)     TMUX_PREFIX="C-a" ;;
    *Ctrl+Space*) TMUX_PREFIX="C-Space" ;;
    *)            TMUX_PREFIX="C-b" ;;
  esac
  echo
fi

divider
say "Summary"
echo -e "  Platform       : ${BOLD}$OS/$ARCH${RESET}$($IS_WSL && echo " (WSL)")"
echo -e "  Shell rc file  : ${BOLD}$RC_FILE${RESET}"
echo -e "  Theme          : ${BOLD}$THEME_LABEL${RESET}"
echo -e "  Kube in prompt : ${BOLD}$KUBE_IN_PROMPT${RESET}"
echo -e "  ArgoCD aliases : ${BOLD}$ARGO_ALIASES${RESET}"
echo -e "  Workspace root : ${BOLD}$WORKSPACE_ROOT${RESET}"
echo -e "  Git identity   : ${BOLD}${GIT_NAME:-<skip>}${GIT_EMAIL:+ <$GIT_EMAIL>}${RESET}"
echo -e "  Multiplexer    : ${BOLD}$MUX${RESET}"
echo -e "  Neovim wizard  : ${BOLD}$RUN_NVIM_WIZARD${RESET}"
if [[ "$MUX" == "herdr" ]]; then
  _herdr_eds=""
  $HERDR_TUI && _herdr_eds+="TUI + "
  $HERDR_UI  && _herdr_eds+="UI + "
  echo -e "  herdr edition  : ${BOLD}${_herdr_eds% + }${RESET}"
  unset _herdr_eds
fi
[[ "$MUX" == "tmux" ]] && echo -e "  Tmux prefix    : ${BOLD}$TMUX_PREFIX${RESET}"
divider
echo

if ! $DRY_RUN; then
  if ! ask_yn "Proceed and write files?" y; then echo "Aborted."; exit 0; fi
fi
echo

OUTDIR="$HOME/.config/dev-setup"
mkdir -p "$OUTDIR"

# ═══════════════════════════════════════════════════════════════════════════════
# Theme palettes
# ═══════════════════════════════════════════════════════════════════════════════
case "$THEME" in
  nord)
    S_ACCENT="#88c0d0"; S_TEXT="#d8dee9"; S_GREEN="#a3be8c"
    S_YELLOW="#ebcb8b"; S_RED="#bf616a"; S_PURPLE="#b48ead"
    S_DIM="#4c566a"
    TM_BG="#2e3440"; TM_FG="#d8dee9"; TM_ACCENT="#88c0d0"
    TM_DIM="#4c566a"; TM_YELLOW="#ebcb8b"
    HERDR_THEME="nord"
    PALETTE='
[palettes.active]
accent = "#88c0d0"
text   = "#d8dee9"
green  = "#a3be8c"
yellow = "#ebcb8b"
red    = "#bf616a"
purple = "#b48ead"
dim    = "#4c566a"'
    ;;
  catppuccin)
    S_ACCENT="#89b4fa"; S_TEXT="#cdd6f4"; S_GREEN="#a6e3a1"
    S_YELLOW="#f9e2af"; S_RED="#f38ba8"; S_PURPLE="#cba6f7"
    S_DIM="#585b70"
    TM_BG="#1e1e2e"; TM_FG="#cdd6f4"; TM_ACCENT="#89b4fa"
    TM_DIM="#585b70"; TM_YELLOW="#f9e2af"
    HERDR_THEME="catppuccin"
    PALETTE='
[palettes.active]
accent = "#89b4fa"
text   = "#cdd6f4"
green  = "#a6e3a1"
yellow = "#f9e2af"
red    = "#f38ba8"
purple = "#cba6f7"
dim    = "#585b70"'
    ;;
  tokyo)
    S_ACCENT="#7aa2f7"; S_TEXT="#c0caf5"; S_GREEN="#9ece6a"
    S_YELLOW="#e0af68"; S_RED="#f7768e"; S_PURPLE="#bb9af7"
    S_DIM="#414868"
    TM_BG="#1a1b26"; TM_FG="#c0caf5"; TM_ACCENT="#7aa2f7"
    TM_DIM="#414868"; TM_YELLOW="#e0af68"
    HERDR_THEME="tokyo-night"
    PALETTE='
[palettes.active]
accent = "#7aa2f7"
text   = "#c0caf5"
green  = "#9ece6a"
yellow = "#e0af68"
red    = "#f7768e"
purple = "#bb9af7"
dim    = "#414868"'
    ;;
  solarized)
    S_ACCENT="#268bd2"; S_TEXT="#657b83"; S_GREEN="#859900"
    S_YELLOW="#b58900"; S_RED="#dc322f"; S_PURPLE="#6c71c4"
    S_DIM="#93a1a1"
    TM_BG="#fdf6e3"; TM_FG="#657b83"; TM_ACCENT="#268bd2"
    TM_DIM="#93a1a1"; TM_YELLOW="#b58900"
    HERDR_THEME="solarized-light"
    PALETTE='
[palettes.active]
accent = "#268bd2"
text   = "#657b83"
green  = "#859900"
yellow = "#b58900"
red    = "#dc322f"
purple = "#6c71c4"
dim    = "#93a1a1"'
    ;;
  *)
    TM_BG="default"; TM_FG="white"; TM_ACCENT="cyan"
    TM_DIM="brightblack"; TM_YELLOW="yellow"
    HERDR_THEME="dark"
    PALETTE='
[palettes.active]
accent = "cyan"
text   = "white"
green  = "green"
yellow = "yellow"
red    = "red"
purple = "magenta"
dim    = "bright_black"'
    ;;
esac

# ═══════════════════════════════════════════════════════════════════════════════
# Starship config
# ═══════════════════════════════════════════════════════════════════════════════
say "Starship prompt (~/.config/starship.toml)"

if $KUBE_IN_PROMPT; then
  KUBE_BLOCK=$(cat << 'KUBEEOF'

[kubernetes]
disabled = false
format   = '[$symbol$context( \($namespace\))]($style) '
symbol   = "⎈ "
style    = "bold accent"

[[kubernetes.contexts]]
context_pattern = ".*prod.*"
context_alias   = "🔴 prod"

[[kubernetes.contexts]]
context_pattern = ".*staging.*"
context_alias   = "🟡 staging"

[[kubernetes.contexts]]
context_pattern = ".*dev.*"
context_alias   = "🟢 dev"
KUBEEOF
)
else
  KUBE_BLOCK='
[kubernetes]
disabled = true'
fi

STARSHIP_CONTENT="# Starship config — shell-wizard.sh | theme: $THEME
# Swap palette values below to change the color scheme.

format = \"\"\"
\$username\
\$directory\
\$git_branch\
\$git_status\
\$python\
\$kubernetes\
\$cmd_duration\
\$line_break\
[\$character](bold accent)\"\"\"

palette = \"active\"
$PALETTE

[username]
show_always = false
style_user  = \"bold accent\"
style_root  = \"bold red\"
format      = \"[\$user](\$style)@[\$hostname](bold dim) \"

[hostname]
ssh_only = true

[directory]
truncation_length = 4
truncate_to_repo  = true
style             = \"bold accent\"
read_only         = \" 󰌾\"
home_symbol       = \"~\"

[git_branch]
symbol = \" \"
style  = \"bold purple\"
format = \"on [\$symbol\$branch](\$style) \"

[git_status]
format     = \"([\$all_status\$ahead_behind](\$style)) \"
style      = \"bold red\"
conflicted = \"⚡\"
ahead      = \"⇡\${count}\"
behind     = \"⇣\${count}\"
diverged   = \"⇕⇡\${ahead_count}⇣\${behind_count}\"
untracked  = \"?\${count}\"
stashed    = \"📦\"
modified   = \"!\${count}\"
staged     = \"+\${count}\"
deleted    = \"✘\${count}\"

[python]
symbol            = \" \"
style             = \"bold yellow\"
format            = \"via [\$symbol\$version( \\\\(\$virtualenv\\\\))](\$style) \"
detect_extensions = [\"py\"]
detect_files      = [\"pyproject.toml\", \"requirements.txt\", \".python-version\", \"uv.lock\"]
$KUBE_BLOCK

[cmd_duration]
min_time = 2000
format   = \"took [\$duration](bold yellow) \"

[character]
success_symbol = \"[❯](bold green)\"
error_symbol   = \"[❯](bold red)\"
vimcmd_symbol  = \"[❮](bold green)\"

[line_break]
disabled = false

[jobs]
symbol    = \"+\"
threshold = 1
"

mkdir -p "$HOME/.config"
write_file "$HOME/.config/starship.toml" "$STARSHIP_CONTENT"

# ═══════════════════════════════════════════════════════════════════════════════
# Shell config snippet
# ═══════════════════════════════════════════════════════════════════════════════
say "Shell config ($OUTDIR/bashrc_devsetup.sh)"

ARGO_BLOCK=""
if $ARGO_ALIASES; then
  ARGO_BLOCK='
# ── ArgoCD ────────────────────────────────────────────────────────────────────
if command -v argocd &>/dev/null; then
  alias acd="argocd"
  alias acdal="argocd app list"
  alias acdas="argocd app sync"
  alias acdaw="argocd app wait"
  alias acdah="argocd app history"

  argo_sync() { argocd app sync "$1" && argocd app wait "$1" --health --timeout "${2:-120}"; }
  argo_sync_only() { argocd app sync "$1"; }
  argo_logs()  { argocd app logs "$1" --follow; }
fi'
fi

BASHRC_SNIPPET="# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Dev setup snippet — sourced from your shell rc file (bash or zsh)
# Edit this file directly; changes take effect on next shell open.
# Generated by shell-wizard.sh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── Basics ────────────────────────────────────────────────────
export EDITOR=\"\${EDITOR:-vim}\"
export VISUAL=\"\$EDITOR\"
export HISTSIZE=50000
if [[ -n \"\${ZSH_VERSION:-}\" ]]; then
  _ds_shell=zsh
  export SAVEHIST=100000
  setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE EXTENDED_HISTORY
  autoload -Uz compinit && compinit -u
else
  _ds_shell=bash
  export HISTFILESIZE=100000
  export HISTCONTROL=ignoreboth:erasedups
  export HISTTIMEFORMAT=\"%F %T  \"
  shopt -s histappend
  PROMPT_COMMAND=\"\${PROMPT_COMMAND:+\$PROMPT_COMMAND; }history -a\"
fi
export LESS=\"-RFX\"

# ── Homebrew (macOS) ──────────────────────────────────────────
[[ -x /opt/homebrew/bin/brew ]] && eval \"\$(/opt/homebrew/bin/brew shellenv)\"
[[ -x /usr/local/bin/brew ]]    && eval \"\$(/usr/local/bin/brew shellenv)\"

# ── PATH helper ───────────────────────────────────────────────
pathadd() { [[ \":\$PATH:\" != *\":\$1:\"* ]] && export PATH=\"\$1:\$PATH\"; }
pathadd \"\$HOME/.local/bin\"
pathadd \"\$HOME/bin\"

# ── pyenv ─────────────────────────────────────────────────────
if [[ -d \"\$HOME/.pyenv\" ]]; then
  export PYENV_ROOT=\"\$HOME/.pyenv\"
  pathadd \"\$PYENV_ROOT/bin\"
  eval \"\$(pyenv init -)\"
  eval \"\$(pyenv virtualenv-init -)\" 2>/dev/null || true
fi

# ── Go ────────────────────────────────────────────────────────
[[ -d \"\$HOME/.local/go/bin\" ]] && pathadd \"\$HOME/.local/go/bin\"
export GOPATH=\"\$HOME/.local/share/go\"
[[ -d \"\$GOPATH/bin\" ]] && pathadd \"\$GOPATH/bin\"
command -v lazyworktree &>/dev/null && alias lwt='lazyworktree'

# ── uv ────────────────────────────────────────────────────────
[[ -d \"\$HOME/.local/share/uv/bin\" ]] && pathadd \"\$HOME/.local/share/uv/bin\"
if command -v uv &>/dev/null; then
  eval \"\$(uv generate-shell-completion \$_ds_shell 2>/dev/null)\" || true
fi

# ── Starship ──────────────────────────────────────────────────
command -v starship &>/dev/null && eval \"\$(starship init \$_ds_shell)\"

# ── Navigation ────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
# GNU ls uses --color=auto, BSD ls (macOS) uses -G
if ls --color=auto / &>/dev/null; then _ds_lsc='--color=auto'; else _ds_lsc='-G'; fi
alias ls=\"ls \$_ds_lsc -F\"
alias ll=\"ls -lhF \$_ds_lsc\"
alias la=\"ls -lAhF \$_ds_lsc\"
alias lt=\"ls -lhFt \$_ds_lsc\"
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -sh'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -pv'

# ── Git ───────────────────────────────────────────────────────
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gs='git status -sb'
alias gd='git diff'
alias gds='git diff --staged'
alias gdc='git diff main...HEAD'        # changes on current branch vs main
alias gp='git push'
alias gpl='git pull --rebase'
alias gb='git branch -vv'
alias gl='git log --oneline --graph --decorate --all -20'
alias gll='git log --oneline --graph --decorate --all'
alias grb='git rebase'
alias gst='git stash'
alias gstp='git stash pop'

# ── kubectl ───────────────────────────────────────────────────
if command -v kubectl &>/dev/null; then
  # Use kubecolor as a drop-in replacement when available (colorizes output)
  if command -v kubecolor &>/dev/null; then
    alias kubectl='kubecolor'
  fi
  alias k='kubectl'
  alias kgp='kubectl get pods'
  alias kgpa='kubectl get pods -A'
  alias kgn='kubectl get nodes'
  alias kgs='kubectl get services'
  alias kgd='kubectl get deployments'
  alias kgi='kubectl get ingress'
  alias kge='kubectl get events --sort-by=.lastTimestamp'
  alias kd='kubectl describe'
  alias kdp='kubectl describe pod'
  alias kl='kubectl logs'
  alias klf='kubectl logs -f'
  alias ke='kubectl exec -it'
  alias kaf='kubectl apply -f'
  alias kdf='kubectl delete -f'
  alias kctx='kubectl config use-context'
  alias kns='kubectl config set-context --current --namespace'
  alias kgctx='kubectl config get-contexts'
  # prefer kubectx/kubens interactive switchers when installed
  command -v kubectx &>/dev/null && alias kctx='kubectx'
  command -v kubens  &>/dev/null && alias kns='kubens'

  # Tail logs for first pod matching prefix: klns <namespace> <prefix>
  klns() {
    local pod
    pod=\$(kubectl get pod -n \"\$1\" --no-headers | awk \"/\$2/{print \$1; exit}\")
    [[ -z \"\$pod\" ]] && { echo \"No pod matching '\$2' in '\$1'\"; return 1; }
    kubectl logs -n \"\$1\" -f \"\$pod\"
  }

  # Watch pods in namespace: wkns <namespace>
  # (macOS has no watch by default — fall back to a loop)
  wkns() {
    if command -v watch &>/dev/null; then
      watch -n2 kubectl get pods -n \"\${1:-default}\"
    else
      while true; do clear; kubectl get pods -n \"\${1:-default}\"; sleep 2; done
    fi
  }

  source <(kubectl completion \$_ds_shell)
  if [[ \"\$_ds_shell\" == zsh ]]; then compdef k=kubectl; else complete -o default -F __start_kubectl k; fi
fi
$ARGO_BLOCK

# stern
if command -v stern &>/dev/null; then
  alias stn='stern'
  source <(stern --completion \$_ds_shell 2>/dev/null) || true
fi

# fzf — fuzzy finder shell integration
# Ctrl+R: fuzzy history search  Ctrl+T: fuzzy file picker  Alt+C: fuzzy cd
if command -v fzf &>/dev/null; then
  eval \"\$(fzf --\$_ds_shell 2>/dev/null)\" || source /usr/share/doc/fzf/examples/key-bindings.\$_ds_shell 2>/dev/null || true
fi

# ── WSL / macOS helpers ───────────────────────────────────────
if grep -qi microsoft /proc/version 2>/dev/null; then
  alias explore='explorer.exe .'
  alias open='explorer.exe'
  alias pbcopy='clip.exe'
  winpath()          { wslpath -w \"\${1:-.}\"; }
  wslpath_from_win() { wslpath -u \"\$1\"; }
elif [[ \"\$(uname -s)\" == Darwin ]]; then
  alias explore='open .'   # Finder
fi

# ── Claude Code + opencode ────────────────────────────────────
WORKSPACE_ROOT=\"$WORKSPACE_ROOT\"
[[ -d \"\$HOME/.opencode/bin\" ]] && pathadd \"\$HOME/.opencode/bin\"

# cc [project] — cd into workspace/project, activate venv, launch claude
cc() {
  if [[ -z \"\${1:-}\" ]]; then
    _cc_venv && claude; return
  fi
  local dir=\"\$WORKSPACE_ROOT/\$1\"
  if [[ ! -d \"\$dir\" ]]; then
    echo \"Not found: \$dir\"
    echo \"Projects:\"; ls -1 \"\$WORKSPACE_ROOT\" 2>/dev/null
    return 1
  fi
  cd \"\$dir\" && _cc_venv && claude
}

# oc [project] — cd into workspace/project, activate venv, launch opencode
oc() {
  if [[ -z \"\${1:-}\" ]]; then
    _cc_venv && opencode; return
  fi
  local dir=\"\$WORKSPACE_ROOT/\$1\"
  if [[ ! -d \"\$dir\" ]]; then
    echo \"Not found: \$dir\"
    echo \"Projects:\"; ls -1 \"\$WORKSPACE_ROOT\" 2>/dev/null
    return 1
  fi
  cd \"\$dir\" && _cc_venv && opencode
}

_cc_venv() {
  if [[ -d .venv/bin ]];   then source .venv/bin/activate  && echo \"→ .venv\";
  elif [[ -d venv/bin ]];  then source venv/bin/activate   && echo \"→ venv\";
  fi
}

if [[ \"\$_ds_shell\" == zsh ]]; then
  _cc_complete() { compadd -- \$(ls -1 \"\$WORKSPACE_ROOT\" 2>/dev/null); }
  compdef _cc_complete cc oc
else
  _cc_complete() {
    COMPREPLY=(\$(compgen -W \"\$(ls -1 \"\$WORKSPACE_ROOT\" 2>/dev/null)\" -- \"\${COMP_WORDS[COMP_CWORD]}\"))
  }
  complete -F _cc_complete cc
  complete -F _cc_complete oc
fi

alias cw='cd \"\$WORKSPACE_ROOT\"'
"

# ── herdr: relaunch nvim on restore ──────────────────────────────────────────
# When herdr restores a session, panes open as fresh shells. Any tab named
# "nvim" auto-relaunches nvim in the pane's working directory.
# New panes (revision=0) are skipped so ctrl+t opens a plain terminal.
if [[ "$MUX" == "herdr" ]] && $HERDR_TUI; then
  BASHRC_SNIPPET+=$(cat <<'HERDR_RESTORE'

# herdr pane restore
# Re-launch nvim automatically when herdr restores a pane whose tab is named
# "nvim". Also clears any stale Claude session ref on that pane so
# resume_agents_on_restore does not inject a claude --resume next time.
# Only fires on restored panes (revision >= 1); skips brand-new panes so that
# opening a new pane in an nvim-named tab gives a plain terminal, not nvim.
#
# TODO: revision check is broken — herdr restores panes with revision=0 so
# the guard blocks every restore. Need a better signal to distinguish a
# restored pane from a brand new one before this can work correctly.
# Options to explore:
#   - herdr API: check if pane existed in session.json before shell started
#   - sentinel file per pane ID written on clean nvim exit, absent = restore
#   - herdr expose a HERDR_PANE_RESTORED env var in future versions
if [[ -n "${HERDR_TAB_ID:-}" ]] && command -v herdr &>/dev/null; then
  _herdr_tab_name=$(herdr tab get "$HERDR_TAB_ID" 2>/dev/null \
    | grep -o '"label":"[^"]*"' | cut -d'"' -f4)
  if [[ "$_herdr_tab_name" == "nvim" ]]; then
    _herdr_pane_revision=$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null \
      | grep -o '"revision":[0-9]*' | cut -d: -f2)
    if [[ "${_herdr_pane_revision:-0}" -ge 1 ]]; then
      herdr pane release-agent --source herdr:claude --agent claude "$HERDR_PANE_ID" 2>/dev/null || true
      nvim .
    fi
    unset _herdr_pane_revision
  fi
  unset _herdr_tab_name
fi
HERDR_RESTORE
)
fi

write_file "$OUTDIR/bashrc_devsetup.sh" "$BASHRC_SNIPPET"

# ── Wire into shell rc file ($RC_FILE) ───────────────────────────────────────
say "Wiring into $RC_FILE"

MARKER="# >>> dev-setup <<<"
BASHRC_LINE="
$MARKER
[[ -f \"\$HOME/.config/dev-setup/bashrc_devsetup.sh\" ]] && source \"\$HOME/.config/dev-setup/bashrc_devsetup.sh\"
# <<< dev-setup >>>
"
append_if_missing "$RC_FILE" "$MARKER" "$BASHRC_LINE"

# ── Git globals ───────────────────────────────────────────────────────────────
say "Git global config"

if ! $DRY_RUN; then
  [[ -n "$GIT_NAME"  ]] && git config --global user.name  "$GIT_NAME"
  [[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL"
  git config --global core.autocrlf      input
  git config --global push.default       current
  git config --global pull.rebase        true
  git config --global rebase.autoStash   true
  git config --global fetch.prune        true
  git config --global diff.colorMoved    default
  git config --global init.defaultBranch main
  if command -v delta &>/dev/null; then
    git config --global core.pager        "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate    true
    git config --global delta.side-by-side true
    git config --global delta.line-numbers true
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved    default
  fi
  ok "Applied"
else
  info "[dry-run] would apply git globals"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# tmux config
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$MUX" == "tmux" ]]; then
  say "tmux (~/.tmux.conf)"

  if $IS_WSL; then TMUX_COPY_CMD="clip.exe"
elif [[ "$OS" == "macos" ]]; then TMUX_COPY_CMD="pbcopy"
elif command -v wl-copy &>/dev/null; then TMUX_COPY_CMD="wl-copy"
elif command -v xclip &>/dev/null; then TMUX_COPY_CMD="xclip -selection clipboard"
else TMUX_COPY_CMD="cat > /dev/null"
fi

  TMUX_CONTENT="# ~/.tmux.conf — shell-wizard.sh | theme: $THEME

# ── General ──────────────────────────────────────────────────────────────────
set  -g  default-terminal   \"tmux-256color\"
set  -ga terminal-overrides \",xterm-256color:Tc\"
set  -g  history-limit      50000
set  -g  mouse              on
set  -g  base-index         1
set  -g  pane-base-index    1
set  -g  renumber-windows   on
set  -sg escape-time        10
set  -g  focus-events       on
set  -g  status-interval    5

# ── Prefix ───────────────────────────────────────────────────────────────────
set -g prefix $TMUX_PREFIX
bind $TMUX_PREFIX send-prefix

# ── Bindings ─────────────────────────────────────────────────────────────────
bind r source-file ~/.tmux.conf \; display \"✓ reloaded\"

bind | split-window -h -c \"#{pane_current_path}\"
bind - split-window -v -c \"#{pane_current_path}\"
unbind '\"'
unbind %

bind c new-window -c \"#{pane_current_path}\"

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D

bind -n S-Left  previous-window
bind -n S-Right next-window

bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

bind M-1 select-layout even-horizontal
bind M-2 select-layout even-vertical
bind M-3 select-layout main-horizontal
bind M-4 select-layout tiled

# ── Copy mode ────────────────────────────────────────────────────────────────
set -g mode-keys vi
bind Enter copy-mode
bind -T copy-mode-vi v   send-keys -X begin-selection
bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind -T copy-mode-vi y   send-keys -X copy-pipe-and-cancel \"$TMUX_COPY_CMD\"

# ── Sessions ─────────────────────────────────────────────────────────────────
bind S choose-session
bind N new-session

# ── Pane borders ─────────────────────────────────────────────────────────────
set -g pane-border-style        \"fg=$TM_DIM\"
set -g pane-active-border-style \"fg=$TM_ACCENT\"

# ── Status bar ───────────────────────────────────────────────────────────────
set -g status          on
set -g status-position bottom
set -g status-style    \"bg=$TM_BG,fg=$TM_FG\"
set -g status-left-length  50
set -g status-right-length 120

set -g status-left  \"#[fg=$TM_ACCENT,bold] #S #[fg=$TM_DIM]│ \"
set -g status-right \"\
#[fg=$TM_YELLOW]#(kubectl config current-context 2>/dev/null | sed 's/^/⎈ /') \
#[fg=$TM_DIM]│ \
#[fg=$TM_FG]#(cd #{pane_current_path} && git branch --show-current 2>/dev/null | sed 's/^/ /') \
#[fg=$TM_DIM]│ #[fg=$TM_FG]#H \
#[fg=$TM_ACCENT] %H:%M#[fg=$TM_DIM] %d/%m\"

set -g window-status-style          \"fg=$TM_DIM,bg=$TM_BG\"
set -g window-status-current-style  \"fg=$TM_ACCENT,bold,bg=$TM_BG\"
set -g window-status-format         \" #I:#W#{?window_zoomed_flag, 🔍,} \"
set -g window-status-current-format \" #I:#W#{?window_zoomed_flag, 🔍,} \"
set -g window-status-separator      \"\"

set -g message-style         \"fg=$TM_ACCENT,bg=$TM_BG,bold\"
set -g message-command-style \"fg=$TM_YELLOW,bg=$TM_BG\"

set -g monitor-activity on
set -g visual-activity  off
set -g window-status-activity-style \"fg=$TM_YELLOW,bold\"

# ── TPM plugins (opt-in) ─────────────────────────────────────────────────────
# Install TPM: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Then uncomment and press Prefix+I to install:
#
# set -g @plugin 'tmux-plugins/tpm'
# set -g @plugin 'tmux-plugins/tmux-resurrect'
# set -g @plugin 'tmux-plugins/tmux-continuum'
# set -g @continuum-restore 'on'
# run '~/.tmux/plugins/tpm/tpm'
"

  write_file "$HOME/.tmux.conf" "$TMUX_CONTENT"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Tool installs
# ═══════════════════════════════════════════════════════════════════════════════
say "Installing tools"
echo
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# ── Starship ──────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}starship${RESET} (shell prompt)... "
if command -v starship &>/dev/null; then
  install_skip "$(starship --version 2>/dev/null | head -1)"
elif $DRY_RUN; then install_dry "starship"
else
  if curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$INSTALL_DIR" >/dev/null 2>&1; then
    install_ok "installed $(starship --version 2>/dev/null | head -1)"
  else install_fail "starship" "curl -sS https://starship.rs/install.sh | sh"
  fi
fi

# ── pyenv ─────────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}pyenv${RESET} (Python version manager)... "
if [[ -d "$HOME/.pyenv" ]]; then
  install_skip "$(pyenv --version 2>/dev/null)"
elif $DRY_RUN; then install_dry "pyenv"
else
  if curl -fsSL https://pyenv.run | bash >/dev/null 2>&1; then
    install_ok "installed — restart shell or source $RC_FILE_SHORT to activate"
  else install_fail "pyenv" "curl https://pyenv.run | bash"
  fi
fi

# ── uv ────────────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}uv${RESET} (Python package manager)... "
if command -v uv &>/dev/null; then
  install_skip "$(uv --version 2>/dev/null)"
elif $DRY_RUN; then install_dry "uv"
else
  if curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; then
    install_ok "installed"
  else install_fail "uv" "curl -LsSf https://astral.sh/uv/install.sh | sh"
  fi
fi

# ── kubectl ───────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}kubectl${RESET} (Kubernetes CLI)... "
if command -v kubectl &>/dev/null; then
  install_skip "$(kubectl version --client 2>/dev/null | head -1)"
elif $DRY_RUN; then install_dry "kubectl"
else
  KC_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt 2>/dev/null)
  KC_URL="https://dl.k8s.io/release/${KC_VER}/bin/${OS_GO}/${ARCH}/kubectl"
  if curl -fsSL "$KC_URL" -o "$INSTALL_DIR/kubectl" 2>/dev/null && chmod +x "$INSTALL_DIR/kubectl"; then
    install_ok "installed $KC_VER to $INSTALL_DIR/kubectl"
  else install_fail "kubectl" "see https://kubernetes.io/docs/tasks/tools/"
  fi
fi

# ── kubecolor ─────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}kubecolor${RESET} (colorized kubectl output)... "
if command -v kubecolor &>/dev/null; then
  install_skip "present"
elif $DRY_RUN; then install_dry "kubecolor"
else
  KC_TAG=$(curl -fsSL https://api.github.com/repos/kubecolor/kubecolor/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  KC_VER="${KC_TAG#v}"
  KC_URL="https://github.com/kubecolor/kubecolor/releases/download/${KC_TAG}/kubecolor_${KC_VER}_${OS_GO}_${ARCH}.tar.gz"
  if curl -fsSL "$KC_URL" | tar -xz -C "$INSTALL_DIR" kubecolor 2>/dev/null; then
    install_ok "installed $KC_TAG"
  else install_fail "kubecolor" "https://github.com/kubecolor/kubecolor/releases"
  fi
fi

# ── argocd CLI ────────────────────────────────────────────────────────────────
if $ARGO_ALIASES; then
  echo -en "  ${BOLD}argocd${RESET} (ArgoCD CLI)... "
  if command -v argocd &>/dev/null; then
    install_skip "$(argocd version --client --short 2>/dev/null | head -1)"
  elif $DRY_RUN; then install_dry "argocd"
  else
    ARGO_VER=$(curl -fsSL https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
    ARGO_URL="https://github.com/argoproj/argo-cd/releases/download/${ARGO_VER}/argocd-${OS_GO}-${ARCH}"
    if curl -fsSL "$ARGO_URL" -o "$INSTALL_DIR/argocd" 2>/dev/null && chmod +x "$INSTALL_DIR/argocd"; then
      install_ok "installed $ARGO_VER"
    else install_fail "argocd" "https://argo-cd.readthedocs.io/en/stable/cli_installation/"
    fi
  fi
fi

# ── k9s ───────────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}k9s${RESET} (Kubernetes TUI)... "
if command -v k9s &>/dev/null; then
  install_skip "$(k9s version --short 2>/dev/null | head -1)"
elif $DRY_RUN; then install_dry "k9s"
else
  K9S_TAG=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  K9S_URL="https://github.com/derailed/k9s/releases/download/${K9S_TAG}/k9s_${OS_TITLE}_${ARCH}.tar.gz"
  if curl -fsSL "$K9S_URL" | tar -xz -C "$INSTALL_DIR" k9s 2>/dev/null; then
    install_ok "installed ${K9S_TAG}"
  else install_fail "k9s" "https://github.com/derailed/k9s/releases"
  fi
fi

# ── stern ─────────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}stern${RESET} (multi-pod log tailing)... "
if command -v stern &>/dev/null; then
  install_skip "$(stern --version 2>/dev/null)"
elif $DRY_RUN; then install_dry "stern"
else
  STERN_TAG=$(curl -fsSL https://api.github.com/repos/stern/stern/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  STERN_VER="${STERN_TAG#v}"
  STERN_URL="https://github.com/stern/stern/releases/download/${STERN_TAG}/stern_${STERN_VER}_${OS_GO}_${ARCH}.tar.gz"
  if curl -fsSL "$STERN_URL" | tar -xz -C "$INSTALL_DIR" stern 2>/dev/null; then
    install_ok "installed ${STERN_TAG}"
  else install_fail "stern" "https://github.com/stern/stern/releases"
  fi
fi

# ── kubectx + kubens ──────────────────────────────────────────────────────────
echo -en "  ${BOLD}kubectx${RESET} + ${BOLD}kubens${RESET} (context/namespace switcher)... "
if command -v kubectx &>/dev/null && command -v kubens &>/dev/null; then
  install_skip "present"
elif $DRY_RUN; then install_dry "kubectx + kubens"
else
  KCTX_TAG=$(curl -fsSL https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  KCTX_URL="https://github.com/ahmetb/kubectx/releases/download/${KCTX_TAG}/kubectx_${KCTX_TAG}_${OS_GO}_${ARCH_ALT}.tar.gz"
  KNS_URL="https://github.com/ahmetb/kubectx/releases/download/${KCTX_TAG}/kubens_${KCTX_TAG}_${OS_GO}_${ARCH_ALT}.tar.gz"
  OK=true
  curl -fsSL "$KCTX_URL" | tar -xz -C "$INSTALL_DIR" kubectx 2>/dev/null || OK=false
  curl -fsSL "$KNS_URL"  | tar -xz -C "$INSTALL_DIR" kubens  2>/dev/null || OK=false
  if $OK; then
    install_ok "installed ${KCTX_TAG}"
  else install_fail "kubectx/kubens" "https://github.com/ahmetb/kubectx/releases"
  fi
fi

# ── fzf ───────────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}fzf${RESET} (fuzzy finder)... "
if command -v fzf &>/dev/null; then
  install_skip "$(fzf --version 2>/dev/null)"
elif $DRY_RUN; then install_dry "fzf"
else
  FZF_TAG=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
  FZF_VER="${FZF_TAG#v}"
  FZF_URL="https://github.com/junegunn/fzf/releases/download/${FZF_TAG}/fzf-${FZF_VER}-${OS_GO}_${ARCH}.tar.gz"
  if curl -fsSL "$FZF_URL" | tar -xz -C "$INSTALL_DIR" fzf 2>/dev/null; then
    install_ok "installed ${FZF_TAG}"
  else install_fail "fzf" "https://github.com/junegunn/fzf/releases"
  fi
fi

# ── Go ────────────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}go${RESET} (required for lazyworktree)... "
if [[ -x "$HOME/.local/go/bin/go" ]]; then
  install_skip "$("$HOME/.local/go/bin/go" version 2>/dev/null)"
elif $DRY_RUN; then install_dry "go"
else
  GO_VER=$(curl -fsSL "https://go.dev/dl/?mode=json" | grep -o '"version": *"go[^"]*"' | head -1 | cut -d'"' -f4 || true)
  [[ -n "$GO_VER" ]] || GO_VER="go1.24.0"   # fallback if go.dev lookup fails
  GO_URL="https://go.dev/dl/${GO_VER}.${OS_GO}-${ARCH}.tar.gz"
  if curl -fsSL "$GO_URL" | tar -xz -C "$HOME/.local" 2>/dev/null; then
    install_ok "installed ${GO_VER} to ~/.local/go"
  else install_fail "go" "https://go.dev/dl/"
  fi
fi

# ── lazyworktree ──────────────────────────────────────────────────────────────
echo -en "  ${BOLD}lazyworktree${RESET} (git worktree TUI)... "
if command -v lazyworktree &>/dev/null; then
  install_skip "$(lazyworktree --version 2>/dev/null || echo 'already installed')"
elif $DRY_RUN; then install_dry "lazyworktree"
else
  if PATH="$HOME/.local/go/bin:$PATH" GOPATH="$HOME/.local/share/go" \
      go install github.com/chmouel/lazyworktree/cmd/lazyworktree@latest 2>/dev/null; then
    ln -sf "$HOME/.local/share/go/bin/lazyworktree" "$INSTALL_DIR/lazyworktree" 2>/dev/null || true
    install_ok "installed via go install"
  else install_fail "lazyworktree" "go install github.com/chmouel/lazyworktree/cmd/lazyworktree@latest"
  fi
fi

# ── opencode ──────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}opencode${RESET} (AI coding agent)... "
if command -v opencode &>/dev/null; then
  install_skip "$(opencode --version 2>/dev/null || echo 'already installed')"
elif $DRY_RUN; then install_dry "opencode"
else
  if curl -fsSL https://opencode.ai/v2/install | bash >/dev/null 2>&1; then
    install_ok "installed to ~/.opencode/bin"
  else install_fail "opencode" "curl -fsSL https://opencode.ai/v2/install | bash"
  fi
fi

# ── lazyworktree config ───────────────────────────────────────────────────────
LAZYWORKTREE_CONFIG='custom_commands:
  universal:
    "o":
      description: Open in herdr workspace
      show_help: true
      herdr:
        mode: workspace
        attach: true
        on_exists: switch
        windows:
          - name: agents
            command: opencode
          - name: nvim
            command: nvim .
'
if ! $DRY_RUN; then
  mkdir -p "$HOME/.config/lazyworktree"
  write_file "$HOME/.config/lazyworktree/config.yaml" "$LAZYWORKTREE_CONFIG"
else
  info "[dry-run] would write ~/.config/lazyworktree/config.yaml"
fi

if [[ "$MUX" == "tmux" ]]; then
  echo -en "  ${BOLD}tmux${RESET}... "
  if command -v tmux &>/dev/null; then
    install_skip "$(tmux -V)"
  elif $DRY_RUN; then install_dry "tmux"
  else
    if [[ "$OS" == "macos" ]]; then
      if command -v brew &>/dev/null && brew install tmux >/dev/null 2>&1; then
        install_ok "installed via brew"
      else install_fail "tmux" "brew install tmux (install Homebrew first: https://brew.sh)"
      fi
    elif sudo apt-get install -y tmux >/dev/null 2>&1; then
      install_ok "installed via apt"
    else install_fail "tmux" "install tmux with your package manager (e.g. sudo apt install tmux)"
    fi
  fi
fi

# Fills BG/FG/ANSI color vars for $THEME. Returns 1 for the classic theme.
_load_term_palette() {
  case "$THEME" in
    nord)
      BG="#2E3440"; FG="#D8DEE9"; BOLD_FG="#ECEFF4"
      BLACK="#3B4252"; RED="#BF616A"; GREEN="#A3BE8C"; YELLOW="#EBCB8B"
      BLUE="#81A1C1"; MAGENTA="#B48EAD"; CYAN="#88C0D0"; WHITE="#E5E9F0"
      B_BLACK="#4C566A"; B_RED="#BF616A"; B_GREEN="#A3BE8C"; B_YELLOW="#EBCB8B"
      B_BLUE="#81A1C1"; B_MAGENTA="#B48EAD"; B_CYAN="#8FBCBB"; B_WHITE="#ECEFF4"
      CURSOR="#D8DEE9";;
    catppuccin)
      BG="#1E1E2E"; FG="#CDD6F4"; BOLD_FG="#CDD6F4"
      BLACK="#45475A"; RED="#F38BA8"; GREEN="#A6E3A1"; YELLOW="#F9E2AF"
      BLUE="#89B4FA"; MAGENTA="#CBA6F7"; CYAN="#94E2D5"; WHITE="#BAC2DE"
      B_BLACK="#585B70"; B_RED="#F38BA8"; B_GREEN="#A6E3A1"; B_YELLOW="#F9E2AF"
      B_BLUE="#89B4FA"; B_MAGENTA="#CBA6F7"; B_CYAN="#94E2D5"; B_WHITE="#A6ADC8"
      CURSOR="#F5C2E7";;
    tokyo)
      BG="#1A1B26"; FG="#C0CAF5"; BOLD_FG="#C0CAF5"
      BLACK="#15161E"; RED="#F7768E"; GREEN="#9ECE6A"; YELLOW="#E0AF68"
      BLUE="#7AA2F7"; MAGENTA="#BB9AF7"; CYAN="#7DCFFF"; WHITE="#A9B1D6"
      B_BLACK="#414868"; B_RED="#F7768E"; B_GREEN="#9ECE6A"; B_YELLOW="#E0AF68"
      B_BLUE="#7AA2F7"; B_MAGENTA="#BB9AF7"; B_CYAN="#7DCFFF"; B_WHITE="#ACB0D0"
      CURSOR="#C0CAF5";;
    solarized)
      BG="#FDF6E3"; FG="#657B83"; BOLD_FG="#657B83"
      BLACK="#073642"; RED="#DC322F"; GREEN="#859900"; YELLOW="#B58900"
      BLUE="#268BD2"; MAGENTA="#D33682"; CYAN="#2AA198"; WHITE="#EEE8D5"
      B_BLACK="#002B36"; B_RED="#CB4B16"; B_GREEN="#586E75"; B_YELLOW="#657B83"
      B_BLUE="#839496"; B_MAGENTA="#6C71C4"; B_CYAN="#93A1A1"; B_WHITE="#FDF6E3"
      CURSOR="#657B83";;
    *)
      return 1;;
  esac
}

# ── herdr UI (native app + herdr-core) ────────────────────────────────────────
# App installer also installs herdr-core when none exists. UI config
# (~/.config/herdr-app) is left to the app; the wizard does not write it.
if [[ "$MUX" == "herdr" ]] && $HERDR_UI; then
  echo -en "  ${BOLD}herdr UI${RESET}... "
  if command -v herdr-app &>/dev/null || [[ -x "$HOME/.local/bin/herdr-app" ]]; then
    install_skip "$("$HOME/.local/bin/herdr-app" --version 2>/dev/null || echo 'already installed')"
  elif $DRY_RUN; then install_dry "herdr UI"
  elif [[ "$OS" == "macos" && "$ARCH" != "arm64" ]]; then
    install_fail "herdr UI" "Intel Macs unsupported; build from source: https://github.com/herdrdev/herdr-app"
  else
    # herdr-core fails with "Permission denied" if ~/.local/state is root-owned
    if [[ -d "$HOME/.local/state" && ! -w "$HOME/.local/state" ]]; then
      warn "~/.local/state is not writable; run: sudo chown -R \"\$USER\" ~/.local/state"
    fi
    if curl -fsSL https://releases.herdr.dev/app/install.sh | sh >/dev/null 2>&1; then
      install_ok "installed via curl installer"
    else install_fail "herdr UI" "curl -fsSL https://releases.herdr.dev/app/install.sh | sh"
    fi
  fi

  # Enable the Files and Changes side panels (shared state key "workspace.panels").
  # shared.json is app-written; merge just this key. If the app is running it
  # may rewrite the file (latest write wins), so quit herdr-app first.
  echo -en "  ${BOLD}herdr UI panels${RESET}... "
  if $DRY_RUN; then
    info "[dry-run] would enable Files + Changes panels in shared.json"
  else
    HERDR_APP_DIR="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
    mkdir -p "$HERDR_APP_DIR"
    if python3 - "$HERDR_APP_DIR/shared.json" <<'PY' 2>/dev/null
import json, os, sys
p = sys.argv[1]
try:
    with open(p) as f: d = json.load(f)
except FileNotFoundError:
    d = {}
d["workspace.panels"] = ["files", "changes"]
tmp = p + ".tmp"
with open(tmp, "w") as f: json.dump(d, f)
os.replace(tmp, p)
PY
    then install_ok "Files + Changes enabled"
    else install_fail "herdr UI panels" "set \"workspace.panels\": [\"files\",\"changes\"] in ~/.config/herdr-app/shared.json"
    fi
  fi

  # Look: wizard theme as a herdr-app theme + Nerd Font (for starship glyphs).
  # settings.json holds the person's look; merge only theme/font keys.
  echo -en "  ${BOLD}herdr UI look${RESET}... "
  HERDR_FONT="CaskaydiaCove Nerd Font Mono"
  if $DRY_RUN; then
    info "[dry-run] would install $HERDR_FONT and set theme '$THEME' in settings.json"
  else
    HERDR_APP_DIR="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
    if [[ "$OS" == "macos" ]]; then FONT_DIR="$HOME/Library/Fonts"; else FONT_DIR="$HOME/.local/share/fonts"; fi
    mkdir -p "$FONT_DIR" "$HERDR_APP_DIR/themes"
    if ! ls "$FONT_DIR"/CaskaydiaCoveNerdFontMono-* &>/dev/null; then
      _ft=$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4 || true)
      _fz="$(mktemp -t nerdfont).zip"
      if [[ -n "$_ft" ]] && curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${_ft}/CascadiaCode.zip" -o "$_fz" 2>/dev/null; then
        python3 - "$_fz" "$FONT_DIR" <<'FONTPY' 2>/dev/null || true
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        if n.startswith('CaskaydiaCoveNerdFontMono-') and n.endswith('.ttf'):
            z.extract(n, sys.argv[2])
FONTPY
        command -v fc-cache &>/dev/null && fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || true
      fi
      rm -f "$_fz"
    fi
    _font_ok=false
    ls "$FONT_DIR"/CaskaydiaCoveNerdFontMono-* &>/dev/null && _font_ok=true

    HERDR_THEME_NAME=""
    # subshell: the palette vars (RED, GREEN, ...) would clobber the output colors
    if ( _load_term_palette ); then
      HERDR_THEME_NAME="dev-setup-$THEME"
      ( _load_term_palette
      cat > "$HERDR_APP_DIR/themes/$HERDR_THEME_NAME.json" <<THEMEEOF
{
  "background": "$BG",
  "foreground": "$FG",
  "selection": "$B_BLACK",
  "cursor": "$CURSOR",
  "ansi": [
    "$BLACK", "$RED", "$GREEN", "$YELLOW", "$BLUE", "$MAGENTA", "$CYAN", "$WHITE",
    "$B_BLACK", "$B_RED", "$B_GREEN", "$B_YELLOW", "$B_BLUE", "$B_MAGENTA", "$B_CYAN", "$B_WHITE"
  ]
}
THEMEEOF
      )
    fi
    if python3 - "$HERDR_APP_DIR/settings.json" "$HERDR_THEME_NAME" "$($_font_ok && echo "$HERDR_FONT")" <<'PY' 2>/dev/null
import json, os, sys
p, theme, font = sys.argv[1:4]
try:
    with open(p) as f: d = json.load(f)
except FileNotFoundError:
    d = {}
if theme: d["theme"] = theme
if font:  d["font"] = font
tmp = p + ".tmp"
with open(tmp, "w") as f: json.dump(d, f, indent=2)
os.replace(tmp, p)
PY
    then install_ok "theme ${HERDR_THEME_NAME:-<default>}, font $($_font_ok && echo "$HERDR_FONT" || echo '<default; font download failed>')"
    else install_fail "herdr UI look" "set \"theme\" and \"font\" in ~/.config/herdr-app/settings.json"
    fi
  fi

  # Keyboard navigation. The UI has no prefix mode (no ctrl+b), only single
  # chords, so add prefix-free pane keys. Modifiers: macOS cmd+ctrl, others
  # ctrl+shift (plain ctrl/alt+letter belong to programs and Mac/Windows text input).
  # Merged into keys.json "global"; the app's own defaults are kept.
  echo -en "  ${BOLD}herdr UI keys${RESET}... "
  HERDR_APP_DIR="${HERDR_APP_HOME:-$HOME/.config/herdr-app}"
  if $DRY_RUN; then
    info "[dry-run] would add pane navigation/split keys to keys.json"
  elif [[ ! -f "$HERDR_APP_DIR/keys.json" ]]; then
    warn "keys.json not created yet — launch herdr-app once, then re-run this wizard to add keys"
  else
    if python3 - "$HERDR_APP_DIR/keys.json" "$OS" <<'PY' 2>/dev/null
import json, os, sys
p, os_name = sys.argv[1:3]
mac = os_name == "macos"
m = "cmd-ctrl" if mac else "ctrl-shift"
add = {
    f"{m}-h": "pane.go:left",  f"{m}-j": "pane.go:down",
    f"{m}-k": "pane.go:up",    f"{m}-l": "pane.go:right",
    f"{m}-o": "pane.split:right", f"{m}-e": "pane.split:down",
}
if not mac:
    add["ctrl-shift-t"] = "tab.new"
with open(p) as f: d = json.load(f)
d.setdefault("global", {}).update(add)
tmp = p + ".tmp"
with open(tmp, "w") as f: json.dump(d, f, indent=2)
os.replace(tmp, p)
PY
    then install_ok "pane keys added"
    else install_fail "herdr UI keys" "add pane.go / pane.split bindings to ~/.config/herdr-app/keys.json"
    fi
  fi
fi

# ── herdr TUI ─────────────────────────────────────────────────────────────────
if [[ "$MUX" == "herdr" ]] && $HERDR_TUI; then
  echo -en "  ${BOLD}herdr${RESET}... "
  if command -v herdr &>/dev/null; then
    install_skip "$(herdr --version 2>/dev/null || echo 'already installed')"
  elif $DRY_RUN; then install_dry "herdr"
  else
    if curl -fsSL https://herdr.dev/install.sh | sh >/dev/null 2>&1; then
      install_ok "installed via curl installer"
    else install_fail "herdr" "curl -fsSL https://herdr.dev/install.sh | sh"
    fi
  fi

  HERDR_CONFIG="# ~/.config/herdr/config.toml — shell-wizard.sh | theme: $THEME

onboarding = false

[terminal]
default_shell = \"/bin/bash\"

[theme]
name = \"$HERDR_THEME\"

[ui]
tab_bar_position = \"bottom\"
status_indicators = \"symbols\"   # distinct shapes for working/blocked/idle
mouse_capture     = true
redraw_on_focus_gained = true

[session]
resume_agents_on_restore = true  # AI agents resume their sessions after restart

[worktrees]
directory = \"$WORKSPACE_ROOT\"   # herdr looks here when creating git worktrees

[keys]
prefix = \"ctrl+b\"

# ── Pane splitting (prefix + | / -) ──────────────────────────────────────────
split_horizontal = \"prefix+-\"
split_vertical   = \"prefix+|\"

# ── Tabs (prefix + c / Shift+arrows) ─────────────────────────────────────────
new_tab      = \"prefix+c\"
next_tab     = \"shift+right\"
previous_tab = \"shift+left\"
rename_tab   = \"prefix+shift+t\"

# ── Workspaces (prefix + N / w) ──────────────────────────────────────────────
new_workspace    = \"prefix+N\"
workspace_picker = \"prefix+w\"

# ── Worktrees (prefix + Shift+G) ─────────────────────────────────────────────
new_worktree = \"prefix+shift+g\"

# ── Pane navigation (prefix + h/j/k/l) ───────────────────────────────────────
focus_pane_left  = \"prefix+h\"
focus_pane_down  = \"prefix+j\"
focus_pane_up    = \"prefix+k\"
focus_pane_right = \"prefix+l\"

# ── Pane resize (prefix + H/J/K/L) ───────────────────────────────────────────
resize_pane_left  = \"prefix+H\"
resize_pane_down  = \"prefix+J\"
resize_pane_up    = \"prefix+K\"
resize_pane_right = \"prefix+L\"

# ── Session navigator + misc ──────────────────────────────────────────────────
goto          = \"prefix+S\"
reload_config = \"prefix+r\"
detach        = \"prefix+d\"

# ── Workspace navigation (prefix + [ / ]) ────────────────────────────────────
previous_workspace = \"prefix+[\"
next_workspace     = \"prefix+]\"

# ── Agent navigation (prefix + , / .) ────────────────────────────────────────
previous_agent = \"prefix+,\"
next_agent     = \"prefix+.\"

# ── Custom commands (must be last — TOML array tables absorb subsequent keys) ─

[[keys.command]]
key         = \"alt+left\"
type        = \"shell\"
command     = \"herdr pane focus --direction left\"
description = \"Focus pane left\"

[[keys.command]]
key         = \"alt+down\"
type        = \"shell\"
command     = \"herdr pane focus --direction down\"
description = \"Focus pane down\"

[[keys.command]]
key         = \"alt+up\"
type        = \"shell\"
command     = \"herdr pane focus --direction up\"
description = \"Focus pane up\"

[[keys.command]]
key         = \"alt+right\"
type        = \"shell\"
command     = \"herdr pane focus --direction right\"
description = \"Focus pane right\"

[[keys.command]]
key         = \"prefix+A\"
type        = \"pane\"
command     = \"claude\"
description = \"Launch Claude Code\"
"

  if ! $DRY_RUN; then
    mkdir -p "$HOME/.config/herdr"
    write_file "$HOME/.config/herdr/config.toml" "$HERDR_CONFIG"
  else
    info "[dry-run] would write ~/.config/herdr/config.toml (theme: $HERDR_THEME)"
  fi

  # Install Claude Code integration so herdr can resume agent sessions after restart
  echo -en "  ${BOLD}herdr claude integration${RESET}... "
  if herdr integration status 2>/dev/null | grep -q "^claude: current"; then
    install_skip "already installed"
  elif $DRY_RUN; then
    install_dry "herdr integration install claude"
  else
    if herdr integration install claude >/dev/null 2>&1; then
      install_ok "installed"
    else
      install_fail "herdr claude integration" "herdr integration install claude"
    fi
  fi
fi

echo

# ═══════════════════════════════════════════════════════════════════════════════
# Windows Terminal theme (WSL only)
# ═══════════════════════════════════════════════════════════════════════════════
if $IS_WSL; then say "Windows Terminal theme"; else say "Terminal theme"; fi

if ! $IS_WSL; then
  # ── Linux / macOS — detect terminal emulator and write its theme config ─────
  _apply_linux_terminal_theme() {
    _load_term_palette || { info "Classic theme — no terminal color config needed"; return; }

    # ── GNOME Terminal ──────────────────────────────────────────────────────
    if command -v gsettings &>/dev/null && gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Terminal"; then
      echo -en "  ${BOLD}GNOME Terminal${RESET}... "
      PROFILE_LIST=$(gsettings get org.gnome.Terminal.ProfilesList list 2>/dev/null)
      DEFAULT_ID=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
      if [[ -n "$DEFAULT_ID" ]]; then
        GSCHEMA="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${DEFAULT_ID}/"
        gsettings set $GSCHEMA background-color           "'$BG'"
        gsettings set $GSCHEMA foreground-color           "'$FG'"
        gsettings set $GSCHEMA bold-color                 "'$BOLD_FG'"
        gsettings set $GSCHEMA bold-color-same-as-fg      "false"
        gsettings set $GSCHEMA use-theme-colors           "false"
        gsettings set $GSCHEMA use-transparent-background "true"
        gsettings set $GSCHEMA background-transparency-percent "5"
        gsettings set $GSCHEMA cursor-colors-set          "true"
        gsettings set $GSCHEMA cursor-background-color    "'$CURSOR'"
        gsettings set $GSCHEMA palette \
          "['$BLACK','$RED','$GREEN','$YELLOW','$BLUE','$MAGENTA','$CYAN','$WHITE','$B_BLACK','$B_RED','$B_GREEN','$B_YELLOW','$B_BLUE','$B_MAGENTA','$B_CYAN','$B_WHITE']"
        ok "Applied $THEME_LABEL to default GNOME Terminal profile"
      else
        warn "No default GNOME Terminal profile found"
      fi

    # ── Tilix ──────────────────────────────────────────────────────────────
    elif command -v tilix &>/dev/null && command -v dconf &>/dev/null; then
      echo -en "  ${BOLD}Tilix${RESET}... "
      TILIX_PATH="/com/gexperts/Tilix/profiles/"
      DEFAULT_ID=$(dconf read ${TILIX_PATH}default 2>/dev/null | tr -d "'")
      [[ -z "$DEFAULT_ID" ]] && DEFAULT_ID="2b7c4080-0ddd-46c5-8f23-563fd3ba789d"
      TP="${TILIX_PATH}${DEFAULT_ID}/"
      dconf write ${TP}background-color    "'$BG'"
      dconf write ${TP}foreground-color    "'$FG'"
      dconf write ${TP}use-theme-colors    "false"
      dconf write ${TP}use-transparent-background "true"
      dconf write ${TP}background-transparency-percent "5"
      dconf write ${TP}palette \
        "['$BLACK','$RED','$GREEN','$YELLOW','$BLUE','$MAGENTA','$CYAN','$WHITE','$B_BLACK','$B_RED','$B_GREEN','$B_YELLOW','$B_BLUE','$B_MAGENTA','$B_CYAN','$B_WHITE']"
      ok "Applied $THEME_LABEL to default Tilix profile"

    # ── Kitty ──────────────────────────────────────────────────────────────
    elif command -v kitty &>/dev/null; then
      echo -en "  ${BOLD}Kitty${RESET}... "
      KITTY_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
      mkdir -p "$(dirname "$KITTY_CONF")"
      THEME_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/theme.conf"
      cat > "$THEME_CONF" << KITTYEOF
# $THEME_LABEL — generated by setup-wizard.sh
background            $BG
foreground            $FG
cursor                $CURSOR
color0  $BLACK
color1  $RED
color2  $GREEN
color3  $YELLOW
color4  $BLUE
color5  $MAGENTA
color6  $CYAN
color7  $WHITE
color8  $B_BLACK
color9  $B_RED
color10 $B_GREEN
color11 $B_YELLOW
color12 $B_BLUE
color13 $B_MAGENTA
color14 $B_CYAN
color15 $B_WHITE
KITTYEOF
      # Wire include into kitty.conf if not already there
      if ! grep -q "include theme.conf" "$KITTY_CONF" 2>/dev/null; then
        echo "include theme.conf" >> "$KITTY_CONF"
      fi
      ok "Applied $THEME_LABEL — reload kitty with Ctrl+Shift+F5"

    # ── Xresources fallback (xterm, urxvt) ─────────────────────────────────
    elif [[ "$OS" == "linux" && -n "${DISPLAY:-}" ]]; then
      echo -en "  ${BOLD}Xresources${RESET}... "
      XRES="$HOME/.Xresources"
      # Remove previous wizard block if present
      sed -i '/! >>> dev-setup theme/,/! <<< dev-setup theme/d' "$XRES" 2>/dev/null || true
      cat >> "$XRES" << XREOF
! >>> dev-setup theme: $THEME_LABEL
*background:  $BG
*foreground:  $FG
*cursorColor: $CURSOR
*color0:  $BLACK
*color1:  $RED
*color2:  $GREEN
*color3:  $YELLOW
*color4:  $BLUE
*color5:  $MAGENTA
*color6:  $CYAN
*color7:  $WHITE
*color8:  $B_BLACK
*color9:  $B_RED
*color10: $B_GREEN
*color11: $B_YELLOW
*color12: $B_BLUE
*color13: $B_MAGENTA
*color14: $B_CYAN
*color15: $B_WHITE
! <<< dev-setup theme
XREOF
      command -v xrdb &>/dev/null && xrdb -merge "$XRES"
      ok "Applied $THEME_LABEL to ~/.Xresources"

    else
      if [[ "$OS" == "macos" ]]; then
        warn "No supported terminal emulator detected (Kitty)"
        info "Terminal.app / iTerm2 / Ghostty: set the $THEME_LABEL colors in the app's settings"
      else
        warn "No supported terminal emulator detected (GNOME Terminal, Tilix, Kitty, xterm)"
        info "Supported: GNOME Terminal, Tilix, Kitty, xterm/urxvt"
      fi
    fi
  }

  if $DRY_RUN; then
    info "[dry-run] would apply $THEME_LABEL to terminal emulator"
  else
    _apply_linux_terminal_theme
  fi
else
  WT_WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n' || true)
  WT_SETTINGS_PATH="/mnt/c/Users/${WT_WIN_USER}/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
  WT_FONTS_DIR="/mnt/c/Users/${WT_WIN_USER}/AppData/Local/Microsoft/Windows/Fonts"
  WIN_FONTS_DIR="C:\\Users\\${WT_WIN_USER}\\AppData\\Local\\Microsoft\\Windows\\Fonts"

  # ── Install CaskaydiaCove Nerd Font ────────────────────────────────────────
  FONT_INSTALLED=false
  echo -en "  ${BOLD}CaskaydiaCove Nerd Font${RESET}... "
  if ls "$WT_FONTS_DIR"/CaskaydiaCove* &>/dev/null 2>&1; then
    install_skip "already in $WT_FONTS_DIR"
    FONT_INSTALLED=true
  elif $DRY_RUN; then
    install_dry "CaskaydiaCove Nerd Font"
  else
    mkdir -p "$WT_FONTS_DIR"
    FONT_TAG=$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest \
      | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${FONT_TAG}/CascadiaCode.zip"
    TMP_ZIP="/tmp/CascadiaCode_nf.zip"
    if curl -fsSL "$FONT_URL" -o "$TMP_ZIP" 2>/dev/null; then
      python3 - "$TMP_ZIP" "$WT_FONTS_DIR" "$WIN_FONTS_DIR" << 'FONTEOF'
import sys, zipfile, os

zip_path  = sys.argv[1]
dest      = sys.argv[2]
win_dest  = sys.argv[3]
os.makedirs(dest, exist_ok=True)

with zipfile.ZipFile(zip_path) as z:
    # Extract only the base variant (not Mono/Propo)
    for name in z.namelist():
        if name.startswith('CaskaydiaCoveNerdFont-') and name.endswith('.ttf'):
            z.extract(name, dest)

# Register in Windows registry via reg.exe
import subprocess, os.path
reg = '/mnt/c/Windows/system32/reg.exe'
reg_key = r'HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
for fname in os.listdir(dest):
    if fname.startswith('CaskaydiaCoveNerdFont-') and fname.endswith('.ttf'):
        reg_name = fname.replace('.ttf', '') + ' (TrueType)'
        win_path = win_dest + '\\' + fname
        subprocess.run([reg, 'add', reg_key, '/v', reg_name, '/t', 'REG_SZ',
                        '/d', win_path, '/f'], capture_output=True)
FONTEOF
      rm -f "$TMP_ZIP"
      install_ok "installed ${FONT_TAG} → $WT_FONTS_DIR"
      FONT_INSTALLED=true
    else
      install_fail "CaskaydiaCove Nerd Font" \
        "download manually from https://www.nerdfonts.com/font-downloads"
    fi
  fi

  if [[ ! -f "$WT_SETTINGS_PATH" ]]; then
    warn "Windows Terminal not found — install from the Microsoft Store, then re-run"
    info "  winget install Microsoft.WindowsTerminal"
  elif $DRY_RUN; then
    info "[dry-run] would patch: $WT_SETTINGS_PATH"
  else
    case "$THEME" in
      nord)
        WT_SCHEME_NAME="Nord"
        WT_SCHEME='{"name":"Nord","background":"#2E3440","foreground":"#D8DEE9","black":"#3B4252","brightBlack":"#4C566A","red":"#BF616A","brightRed":"#BF616A","green":"#A3BE8C","brightGreen":"#A3BE8C","yellow":"#EBCB8B","brightYellow":"#EBCB8B","blue":"#81A1C1","brightBlue":"#81A1C1","purple":"#B48EAD","brightPurple":"#B48EAD","cyan":"#88C0D0","brightCyan":"#8FBCBB","white":"#E5E9F0","brightWhite":"#ECEFF4","cursorColor":"#D8DEE9","selectionBackground":"#4C566A"}'
        ;;
      catppuccin)
        WT_SCHEME_NAME="Catppuccin Mocha"
        WT_SCHEME='{"name":"Catppuccin Mocha","background":"#1E1E2E","foreground":"#CDD6F4","black":"#45475A","brightBlack":"#585B70","red":"#F38BA8","brightRed":"#F38BA8","green":"#A6E3A1","brightGreen":"#A6E3A1","yellow":"#F9E2AF","brightYellow":"#F9E2AF","blue":"#89B4FA","brightBlue":"#89B4FA","purple":"#CBA6F7","brightPurple":"#CBA6F7","cyan":"#94E2D5","brightCyan":"#94E2D5","white":"#BAC2DE","brightWhite":"#A6ADC8","cursorColor":"#F5C2E7","selectionBackground":"#585B70"}'
        ;;
      tokyo)
        WT_SCHEME_NAME="Tokyo Night"
        WT_SCHEME='{"name":"Tokyo Night","background":"#1A1B26","foreground":"#C0CAF5","black":"#15161E","brightBlack":"#414868","red":"#F7768E","brightRed":"#F7768E","green":"#9ECE6A","brightGreen":"#9ECE6A","yellow":"#E0AF68","brightYellow":"#E0AF68","blue":"#7AA2F7","brightBlue":"#7AA2F7","purple":"#BB9AF7","brightPurple":"#BB9AF7","cyan":"#7DCFFF","brightCyan":"#7DCFFF","white":"#A9B1D6","brightWhite":"#ACB0D0","cursorColor":"#C0CAF5","selectionBackground":"#364A82"}'
        ;;
      solarized)
        WT_SCHEME_NAME="Solarized Light"
        WT_SCHEME='{"name":"Solarized Light","background":"#FDF6E3","foreground":"#657B83","black":"#073642","brightBlack":"#002B36","red":"#DC322F","brightRed":"#CB4B16","green":"#859900","brightGreen":"#586E75","yellow":"#B58900","brightYellow":"#657B83","blue":"#268BD2","brightBlue":"#839496","purple":"#D33682","brightPurple":"#6C71C4","cyan":"#2AA198","brightCyan":"#93A1A1","white":"#EEE8D5","brightWhite":"#FDF6E3","cursorColor":"#657B83","selectionBackground":"#EEE8D5"}'
        ;;
      *)
        WT_SCHEME_NAME="Campbell"
        WT_SCHEME=""
        ;;
    esac

    python3 - "$WT_SETTINGS_PATH" "$WT_SCHEME_NAME" "$WT_SCHEME" "$FONT_INSTALLED" << 'PYEOF'
import sys, json

settings_path  = sys.argv[1]
scheme_name    = sys.argv[2]
scheme_json    = sys.argv[3]
font_installed = sys.argv[4] == 'true'

def strip_jsonc(text):
    # Strip // comments without breaking URLs inside strings
    result, i = [], 0
    while i < len(text):
        if text[i] == '"':
            j = i + 1
            while j < len(text):
                if text[j] == '\\': j += 2; continue
                if text[j] == '"':  j += 1; break
                j += 1
            result.append(text[i:j]); i = j
        elif text[i:i+2] == '//':
            while i < len(text) and text[i] != '\n': i += 1
        else:
            result.append(text[i]); i += 1
    return ''.join(result)

with open(settings_path, 'r', encoding='utf-8-sig') as f:
    data = json.loads(strip_jsonc(f.read()))

if scheme_json:
    scheme  = json.loads(scheme_json)
    schemes = data.setdefault('schemes', [])
    data['schemes'] = [s for s in schemes if s.get('name') != scheme_name]
    data['schemes'].append(scheme)

for profile in data.get('profiles', {}).get('list', []):
    src    = profile.get('source', '')
    name   = profile.get('name', '')
    hidden = profile.get('hidden', False)
    if hidden:
        continue
    if 'Ubuntu' in name or 'wsl' in src.lower() or 'Canonical' in src:
        if scheme_json:
            profile['colorScheme']    = scheme_name
        if font_installed:
            profile['font']           = {'face': 'CaskaydiaCove NF', 'size': 11}
        profile['opacity']        = 95
        profile['useAcrylic']     = True
        profile['padding']        = '8'
        profile['scrollbarState'] = 'hidden'

with open(settings_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4)
PYEOF

    ok "Applied '$WT_SCHEME_NAME' to Windows Terminal Ubuntu profile"
    info "Restart Windows Terminal to see changes"
    info "Font warnings below are expected — they disappear after restart"
  fi
fi
echo
divider
say "Done"
divider
echo
echo -e "  ${BOLD}Files written:${RESET}"
echo -e "    ${GREEN}~/.config/starship.toml${RESET}"
echo -e "    ${GREEN}~/.config/dev-setup/bashrc_devsetup.sh${RESET}"
[[ "$MUX" == "tmux"  ]] && echo -e "    ${GREEN}~/.tmux.conf${RESET}"
[[ "$MUX" == "herdr" ]] && $HERDR_TUI && echo -e "    ${GREEN}~/.config/herdr/config.toml${RESET}"
echo
echo -e "  ${BOLD}Activate now:${RESET}  source $RC_FILE_SHORT"
echo
echo -e "  ${BOLD}Key aliases:${RESET}"
echo -e "    cc [project]       Claude Code launcher (auto-activates venv)"
echo -e "    cw                 cd to $WORKSPACE_ROOT"
echo -e "    k / kgp / klf      kubectl / get pods / logs -f"
echo -e "    kctx / kns         switch context / namespace"
echo -e "    klns <ns> <pfx>    tail logs by namespace + pod prefix"
echo -e "    wkns <ns>          watch pods"
$ARGO_ALIASES && echo -e "    argo_sync <app>          argocd sync + wait --health (120s timeout)"
$ARGO_ALIASES && echo -e "    argo_sync <app> <secs>   same with custom timeout"
$ARGO_ALIASES && echo -e "    argo_sync_only <app>     sync only, no health wait"
$IS_WSL && echo -e "    explore            Windows Explorer here (WSL)"
[[ "$OS" == "macos" ]] && echo -e "    explore            Finder here (macOS)"
echo
if [[ "$MUX" == "tmux" ]]; then
  echo -e "  ${BOLD}tmux bindings:${RESET}"
  echo -e "    Prefix + | / -       split pane (keeps dir)"
  echo -e "    Alt + arrows         navigate panes (no prefix)"
  echo -e "    Shift + arrows       switch windows (no prefix)"
  echo -e "    Prefix + h/j/k/l     navigate panes"
  echo -e "    Prefix + H/J/K/L     resize panes"
  echo -e "    Prefix + r           reload config"
  echo -e "    Prefix + Enter       copy mode (y → $TMUX_COPY_CMD)"
  echo
fi
if [[ "$MUX" == "herdr" ]] && $HERDR_UI; then
  echo -e "  ${BOLD}herdr UI:${RESET}"
  echo -e "    herdr-app            open the window (also in your app launcher)"
  echo -e "    hc ls / hc attach    manage terminals via herdr-core"
  if [[ "$OS" == "macos" ]]; then _k="Cmd+Ctrl"; else _k="Ctrl+Shift"; fi
  echo -e "    $_k + h/j/k/l   focus pane left/down/up/right"
  echo -e "    $_k + o / e     split right / down"
  unset _k
  echo -e "    Config: ~/.config/herdr-app (settings.json, keys.json)"
  echo
fi
if [[ "$MUX" == "herdr" ]] && $HERDR_TUI; then
  echo -e "  ${BOLD}herdr bindings:${RESET}"
  echo -e "    Prefix + | / -       split pane"
  echo -e "    Shift + arrows       switch tabs/windows"
  echo -e "    Prefix + h/j/k/l     navigate panes"
  echo -e "    Prefix + H/J/K/L     resize panes"
  echo -e "    Prefix + c           new tab"
  echo -e "    Prefix + S / N       pick session / new session"
  echo -e "    Prefix + r           reload config"
  echo -e "    Prefix + d           detach"
  echo
fi
echo -e "  ${DIM}Backups: <original>.bak.TIMESTAMP${RESET}"
divider
echo

if $RUN_NVIM_WIZARD; then
  say "Neovim wizard"
  if $DRY_RUN; then
    bash "$SCRIPT_DIR/neovim-wizard.sh" --dry-run
  else
    bash "$SCRIPT_DIR/neovim-wizard.sh" || warn "Neovim wizard failed — re-run: bash $SCRIPT_DIR/neovim-wizard.sh"
  fi
fi
