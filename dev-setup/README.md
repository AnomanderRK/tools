# dev-setup

Interactive wizard to configure a developer environment for Bash on WSL or bare Linux.

Covers: shell prompt, Python toolchain, Kubernetes CLI, ArgoCD, Claude Code launcher,
tmux, and Windows Terminal theming — all from a single script.

---

## Requirements

- Bash 4+
- `curl`
- `python3` (for Windows Terminal patching, available in all Ubuntu WSL distros)
- `git`

Everything else is installed by the wizard.

---

## Usage

### Run the wizard

```bash
bash ~/dev-setup/setup-wizard.sh
```

The wizard asks a few questions, shows a summary, then writes all config files and
installs missing tools. Existing files are backed up with a `.bak.TIMESTAMP` suffix
before being overwritten.

### Preview without making any changes

```bash
bash ~/dev-setup/setup-wizard.sh --dry-run
```

Walks through every step and prints what would be written or installed — nothing is
touched.

### Activate changes in the current terminal

```bash
source ~/.bashrc
```

New terminals pick up the config automatically.

---

## What the wizard sets up

### Starship prompt

Two-line prompt showing: directory, git branch + status, Python virtualenv, kube
context, and command duration.

```
~/github/alerting-service on  feat/my-branch (! 2) via  3.12.3 ⎈ 🟢 dev took 3s
❯
```

Theme choices: **Nord**, **Catppuccin Mocha**, **Tokyo Night** (recommended),
**Solarized Light**, or Classic ANSI. The same palette drives both Starship and the
tmux status bar.

Config written to: `~/.config/starship.toml`

### Shell config

Sourced from `~/.bashrc` via a single line. Edit
`~/.config/dev-setup/bashrc_devsetup.sh` directly — changes take effect on next
shell open.

### Tools installed automatically

| Tool | Purpose |
|---|---|
| `starship` | Shell prompt |
| `pyenv` | Python version manager |
| `uv` | Fast Python package manager |
| `kubectl` | Kubernetes CLI |
| `kubecolor` | Colorized `kubectl` output |
| `argocd` | ArgoCD CLI (optional) |
| `tmux` | Terminal multiplexer (via apt) |

Already-installed tools are detected and skipped.

### Windows Terminal (WSL only)

- Injects the chosen color scheme into `settings.json`
- Downloads and installs **CaskaydiaCove NF** (Nerd Font) to your Windows user fonts
- Sets opacity 95%, acrylic blur, padding, hidden scrollbar on the Ubuntu profile

---

## Aliases and functions

### Claude Code

```bash
# Launch Claude Code in the current directory (activates venv if present)
cc

# cd into ~/github/my-project, activate venv, launch Claude Code
cc my-project

# Tab-complete project names from workspace root
cc my-<TAB>

# Jump to workspace root
cw
```

### kubectl

```bash
k get pods                        # k = kubectl (via kubecolor for color)
kgp                               # kubectl get pods
kgpa                              # kubectl get pods -A
kgn                               # kubectl get nodes
kgs                               # kubectl get services
kgd                               # kubectl get deployments
kge                               # kubectl get events --sort-by=.lastTimestamp
kl <pod>                          # kubectl logs
klf <pod>                         # kubectl logs -f
ke <pod> -- bash                  # kubectl exec -it
kaf manifests/deploy.yaml         # kubectl apply -f
kdf manifests/deploy.yaml         # kubectl delete -f
kctx my-cluster                   # switch kube context
kns my-namespace                  # set namespace on current context
kgctx                             # list all contexts

# Tail logs for first pod matching a prefix
klns my-namespace my-service

# Watch all pods in a namespace (refreshes every 2s)
wkns my-namespace
```

Example — find a crashing pod and tail its logs:

```bash
kgp                              # spot the CrashLoopBackOff
klns default my-service          # tail logs without copy-pasting the full pod name
```

### ArgoCD

```bash
acd                              # argocd
acdal                            # argocd app list
acdas my-app                     # argocd app sync my-app
acdaw my-app                     # argocd app wait my-app

# Sync and wait until healthy in one command
argo_sync my-app

# Stream live logs for an app
argo_logs my-app
```

### Git

```bash
gs       # git status -sb
gd       # git diff
gds      # git diff --staged
ga .     # git add
gc -m    # git commit -m
gp       # git push
gpl      # git pull --rebase
gl       # git log --oneline --graph (last 20)
gco -b   # git checkout -b
gb       # git branch -vv
gst      # git stash
gstp     # git stash pop
```

### WSL helpers

```bash
# Open Windows Explorer in the current directory
explore

# Copy command output to Windows clipboard
kubectl get pods | pbcopy

# Translate paths
winpath .                        # prints Windows path for current dir, e.g. \\wsl$\Ubuntu\home\...
wslpath_from_win 'C:\Users\...'  # convert Windows path to WSL path
```

---

## tmux

Start a session:

```bash
tmux new -s work
```

| Binding | Action |
|---|---|
| `Prefix + \|` | Vertical split (keeps current dir) |
| `Prefix + -` | Horizontal split (keeps current dir) |
| `Alt + arrows` | Navigate panes (no prefix needed) |
| `Shift + arrows` | Switch windows (no prefix needed) |
| `Prefix + h/j/k/l` | Navigate panes (vim style) |
| `Prefix + H/J/K/L` | Resize panes |
| `Prefix + c` | New window (keeps current dir) |
| `Prefix + r` | Reload `~/.tmux.conf` in place |
| `Prefix + S` | Choose session interactively |
| `Prefix + N` | New session |
| `Prefix + Enter` | Enter copy mode (vi keys) |
| `v` (copy mode) | Begin selection |
| `y` (copy mode) | Copy to Windows clipboard (`clip.exe`) |
| `Prefix + M-1..4` | Preset layouts (even-h, even-v, main-h, tiled) |

Status bar shows: session name, kube context, git branch, hostname, clock.

---

## Re-running the wizard

The wizard is safe to re-run at any time:

- Config files are backed up before being overwritten
- Already-installed tools are skipped with a version report
- The `~/.bashrc` source line is only added once (idempotent)

To switch themes, just re-run and pick a different one — Starship, tmux, and
Windows Terminal are all updated together.

---

## Files written

| Path | Purpose |
|---|---|
| `~/.config/starship.toml` | Starship prompt config |
| `~/.config/dev-setup/bashrc_devsetup.sh` | All aliases and functions |
| `~/.tmux.conf` | tmux config |
| `~/.bashrc` | Gets one `source` line appended |
| `C:\Users\<you>\AppData\Local\Microsoft\Windows\Fonts\` | Nerd Font TTFs (WSL only) |
| Windows Terminal `settings.json` | Color scheme + profile settings (WSL only) |

Backups: any overwritten file gets a copy at `<original>.bak.YYYYMMDDHHMMSS`.
