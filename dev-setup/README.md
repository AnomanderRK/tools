# dev-setup

Interactive wizards to configure a terminal-based developer environment on WSL or bare Linux.

---

## Wizards

| Script | Purpose |
|---|---|
| `shell-wizard.sh` | Shell prompt (Starship), Python toolchain, Kubernetes CLI, ArgoCD, Claude Code launcher, herdr or tmux, Windows Terminal theming |
| `neovim-wizard.sh` | Neovim + LazyVim: editor, LSPs, formatter, linter, Claude Code integration |

Both wizards share a `lib/helpers.sh` library and follow the same pattern: gather all questions upfront, show a summary, confirm once, then write everything.

---

## Requirements

- Bash 4+
- `curl`
- `python3` (for Windows Terminal patching, available in all Ubuntu WSL distros)
- `git`
- `sudo` / `apt` (for ripgrep, fd-find, tmux)

Everything else is installed by the wizards.

---

## Usage

### Shell wizard

```bash
bash ~/dev-setup/shell-wizard.sh
```

Sets up Starship prompt, pyenv, uv, kubectl, herdr or tmux, Claude Code launcher, and Windows Terminal theme.

```bash
bash ~/dev-setup/shell-wizard.sh --dry-run    # preview only
```

### Neovim wizard

```bash
bash ~/dev-setup/neovim-wizard.sh
```

Installs Neovim, Node.js, ripgrep, fd, and writes a full LazyVim config tuned for Python and React Native development with Claude Code integration.

```bash
bash ~/dev-setup/neovim-wizard.sh --dry-run   # preview only
```

### Activate changes in the current terminal

```bash
source ~/.bashrc
```

New terminals pick up the config automatically.

---

## Shell wizard — what it sets up

### Starship prompt

Two-line prompt showing: directory, git branch + status, Python virtualenv, kube context, and command duration.

```
~/github/alerting-service on  feat/my-branch (! 2) via  3.12.3 ⎈ 🟢 dev took 3s
❯
```

Theme choices: **Nord**, **Catppuccin Mocha**, **Tokyo Night**, **Solarized Light**, or Classic ANSI. The same palette drives both Starship and the multiplexer status bar.

Config written to: `~/.config/starship.toml`

### Shell config

Sourced from `~/.bashrc` via a single line. Edit `~/.config/dev-setup/bashrc_devsetup.sh` directly — changes take effect on next shell open.

### Tools installed automatically

| Tool | Purpose |
|---|---|
| `starship` | Shell prompt |
| `pyenv` | Python version manager |
| `uv` | Fast Python package manager |
| `kubectl` | Kubernetes CLI |
| `kubecolor` | Colorized `kubectl` output |
| `argocd` | ArgoCD CLI (optional) |
| `k9s` | Kubernetes TUI — browse pods, logs, exec, ArgoCD apps |
| `stern` | Multi-pod log tailing across namespaces |
| `kubectx` + `kubens` | Interactive context and namespace switcher |
| `fzf` | Fuzzy finder — enhances kubectx/kubens, shell history, file picker |
| `herdr` | Terminal multiplexer for AI agents (via curl installer) |
| `tmux` | Terminal multiplexer, classic option (via apt) |

One multiplexer is installed depending on your choice — herdr is the default recommendation. Already-installed tools are detected and skipped.

### Windows Terminal (WSL only)

- Injects the chosen color scheme into `settings.json`
- Downloads and installs **CaskaydiaCove NF** (Nerd Font) to your Windows user fonts
- Sets opacity 95%, acrylic blur, padding, hidden scrollbar on the Ubuntu profile

---

## Neovim wizard — what it sets up

### Tools installed automatically

| Tool | Purpose |
|---|---|
| `neovim` | Editor (latest stable, from GitHub releases) |
| `node` + `npm` | Required by most LSP servers (via nvm) |
| `ripgrep` | Fast search, used by Telescope |
| `fd` | Fast file finder, used by Telescope |
| `lazygit` | TUI git client (optional) |
| `delta` | Git diff pager with syntax highlighting and side-by-side view |

### LSPs — installed on first `nvim` launch via Mason

| LSP | Language |
|---|---|
| `pyright` + `ruff_lsp` | Python (type checking + linting) |
| `ts_ls` | TypeScript / React Native |
| `lua_ls` | Lua (for editing your Neovim config) |
| `bashls` | Bash |

### Files written

| Path | Purpose |
|---|---|
| `~/.config/nvim/init.lua` | Entry point |
| `~/.config/nvim/lua/config/lazy.lua` | lazy.nvim bootstrap + LazyVim spec |
| `~/.config/nvim/lua/config/options.lua` | Editor options |
| `~/.config/nvim/lua/config/keymaps.lua` | VSCode-familiar keybindings |
| `~/.config/nvim/lua/plugins/colorscheme.lua` | Theme (matches your shell theme) |
| `~/.config/nvim/lua/plugins/lsp.lua` | Mason, LSPs, conform, nvim-lint |
| `~/.config/nvim/lua/plugins/tools.lua` | toggleterm, Telescope, LazyGit, Copilot |
| `~/.config/lazygit/config.yml` | lazygit config (delta pager wired in if both installed) |
| `~/.config/nvim/lua/plugins/extras.lua` | claudecode.nvim, markdown, surround, todo, trouble, diffview, oil, typescript-tools |
| `~/.config/dev-setup/bashrc_neovim.sh` | Shell aliases and functions |
| `~/.bashrc` | Gets one `source` line appended |

### Keybindings (VSCode-style)

| Key | Action |
|---|---|
| `Ctrl+P` | Find files |
| `Ctrl+Shift+P` | Commands palette |
| `Space+/` | Search in files |
| `Space+e` | Toggle file tree |
| `Ctrl+T` | Toggle terminal |
| `Ctrl+S` | Save file |
| `Space+bd` | Close buffer |
| `Shift+H` / `Shift+L` | Prev / next buffer |
| `Shift+Left` / `Shift+Right` | Scroll buffer horizontally (4 cols) |
| `Shift+ScrollUp` / `Shift+ScrollDown` | Scroll buffer horizontally (4 cols per notch) |
| `Ctrl+W l` / `Ctrl+W h` | Move focus editor ↔ explorer |
| `F12` | Go to definition |
| `Shift+F12` | Find references |
| `F2` | Rename symbol |
| `Ctrl+.` | Code actions |
| `Space` (alone) | Show all keybindings (which-key) |
| `<Space>cc` | Toggle Claude Code (context-aware) |
| `<Space>gg` | LazyGit (if installed) |
| `<Space>yp` | Copy absolute file path to clipboard |
| `<Space>yr` | Copy relative file path to clipboard |
| `<Space>yf` | Copy filename to clipboard |

### Claude Code integration

claudecode.nvim connects Neovim to the Claude Code CLI using the same protocol
as the official VSCode/JetBrains extensions. Claude is always aware of your
current file and selection — no copy-paste needed.

```bash
# Open Neovim in a project
ccnvim my-project       # cd + venv + nvim .
# Then use Space+cc to open Claude — it already knows your files
```

| Key | Action |
|---|---|
| `<Space>cc` | Toggle Claude window |
| `<Space>cS` | Send visual selection to Claude |
| `<Space>cb` | Add current buffer to Claude's context |
| `<Space>ca` | Accept Claude's proposed diff |
| `<Space>cd` | Reject Claude's proposed diff |
| `<Space>cr` | Resume last session |
| `<Space>cm` | Select model |

When Claude proposes code changes, they appear as a side-by-side diff.
Accept with `<Space>ca` (or `:w`), reject with `<Space>cd` (or `:q`).

---

## Shell aliases and functions

### Claude Code (from shell-wizard)

```bash
cc [project]       # cd into workspace/project, activate venv, launch claude
cw                 # cd to workspace root
```

### Neovim (from neovim-wizard)

```bash
ccnvim [project]   # cd into workspace/project, activate venv, open in nvim
                   # tab-completes project names
vi / vim           # → nvim (if aliases enabled)
```

### kubectl

```bash
k get pods                        # k = kubectl (via kubecolor for color)
kgp / kgpa                        # get pods / get pods -A
kgn / kgs / kgd                   # get nodes / services / deployments
kge                               # get events --sort-by=.lastTimestamp
kl / klf <pod>                    # logs / logs -f
ke <pod> -- bash                  # exec -it
kaf / kdf manifests/deploy.yaml   # apply -f / delete -f
kctx / kns                        # switch context / namespace (interactive picker with fzf)
kgctx                             # list all contexts
klns <namespace> <prefix>         # tail logs by namespace + pod prefix
wkns <namespace>                  # watch pods (refreshes every 2s)
```

### k9s

k9s is a TUI for the entire cluster — browse, inspect, exec, and manage resources without typing kubectl commands. Handles both raw pods and ArgoCD-managed apps.

```bash
k9s                        # open (uses current context + namespace)
k9s -n my-namespace        # open scoped to a namespace
k9s --context my-cluster   # open with a specific context
```

**Navigation** — k9s works like a browser. Type a resource name in the command bar to switch views:

| Command | View |
|---|---|
| `:pod` | Pods |
| `:svc` | Services |
| `:deploy` | Deployments |
| `:ing` | Ingresses |
| `:ns` | Namespaces |
| `:ctx` | Contexts |
| `:application` | ArgoCD apps (requires ArgoCD CRDs) |
| `/` | Filter by name in any view |
| `0` | Show all namespaces in current view |
| `Esc` | Go back |
| `?` | Full keybinding help |

**On a pod:**

| Key | Action |
|---|---|
| `l` | Tail logs (live, filterable with `/`) |
| `s` | Shell into it (`exec -it bash`) |
| `d` | Describe |
| `y` | View full YAML |
| `e` | Edit manifest live |
| `shift+f` | Port-forward (opens dialog) |
| `ctrl+k` | Delete/kill pod |

**Inside log view:**

| Key | Action |
|---|---|
| `/` | Filter log lines by pattern |
| `w` | Toggle line wrap |
| `f` | Fullscreen |
| `s` | Save logs to file |

**For ArgoCD apps** (`:application`):

| Key | Action |
|---|---|
| `s` | Sync the app |
| `l` | Tail app logs |
| `d` | Describe the Application resource |
| `y` | View full YAML |

**Contexts and namespaces without leaving k9s:**
- `:ctx` → pick a context with Enter to switch
- `:ns` → pick a namespace with Enter to switch

### stern

stern tails logs from multiple pods simultaneously, color-coded by pod name. Where `kubectl logs -f` covers one pod, stern covers all replicas and multiple services at once.

```bash
# All replicas of a service
stern my-service -n my-namespace

# Multiple services at once (regex)
stern "api|worker|scheduler" -n production

# Across all namespaces
stern my-service --all-namespaces

# Only lines matching a pattern
stern my-service --filter "ERROR|WARN"

# Last 15 minutes then live
stern my-service --since 15m

# Specific container in multi-container pods
stern my-service --container main

# With timestamps
stern my-service -t

# JSON output — pipe to jq for structured logs
stern my-service --output json | jq -r 'select(.level=="error") | .message'

stn my-service   # alias for stern
```

### kubectx + kubens

`kctx` and `kns` use kubectx/kubens with an interactive fzf picker when fzf is installed.

```bash
kctx              # fuzzy-search context picker
kctx my-cluster   # switch directly by name
kctx -            # toggle back to previous context

kns               # fuzzy-search namespace picker
kns my-namespace  # switch directly by name
kns -             # toggle back to previous namespace
```

The `-` toggle is the most useful day-to-day — switch to `production` to check something, then `kctx -` to go straight back.

### fzf

fzf is a general-purpose fuzzy finder wired into the shell. Once installed it enhances kubectx/kubens, shell history, and file navigation automatically.

| Shortcut | Action |
|---|---|
| `Ctrl+R` | Fuzzy search shell history (replaces default reverse-i-search) |
| `Ctrl+T` | Fuzzy search files and insert path at cursor |
| `Alt+C` | Fuzzy search directories and cd into selection |

```bash
# Use fzf inline in any command
vim $(fzf)                          # fuzzy-pick a file to open
k logs $(kubectl get pods | fzf)    # fuzzy-pick a pod to tail
```

### ArgoCD

```bash
acd / acdal / acdas / acdaw   # argocd / app list / app sync / app wait
argo_sync my-app               # sync + wait --health in one command
argo_logs my-app               # stream live app logs
```

For a visual overview of all app health and sync status, use k9s `:application` — it's faster than `argocd app list` for scanning many apps at once.

---

### Kubernetes debugging workflow

Typical flow for investigating an issue in a running service:

```bash
# 1. Switch to the right cluster and namespace
kctx          # pick cluster
kns           # pick namespace

# 2. Open k9s for a visual overview
k9s
# → :pod to check pod status
# → on a crashing pod: d (describe) to see events and error messages
# → l to tail logs, / to filter for ERROR

# 3. If you need logs from multiple replicas or services at once
stern my-service --since 30m --filter "ERROR|Exception"

# 4. For structured JSON logs
stern my-service --output json | jq -r 'select(.level=="error") | {time,message,trace}'

# 5. Check if ArgoCD shows the app as degraded
k9s → :application
# or
acdal | grep my-app

# 6. Sync if needed
argo_sync my-app      # sync + wait for health
# or from k9s: :application → s
```

### Git

```bash
gs / gd / gds        # status / diff / diff --staged
gdc                  # diff current branch vs main (what a PR would show)
ga / gc / gp / gpl   # add / commit / push / pull --rebase
gl                   # log --oneline --graph (last 20)
gco / gb / gst       # checkout / branch -vv / stash
```

### Git diff — delta + lazygit

**delta** replaces the default git pager. Every `git diff`, `git log -p`, `git show`, and `git blame` automatically gets syntax highlighting, line numbers, and side-by-side layout.

```bash
git diff                          # current working tree changes
gdc                               # current branch vs main (PR view)
git diff main..feat/my-branch     # all commits between two branches
git diff main...feat/my-branch    # only changes since branches diverged
git diff HEAD~3                   # last 3 commits
git show abc1234                  # single commit
git log -p                        # full history with inline diffs
```

Navigate hunks with `n` / `N` while in the pager.

**lazygit** gives you a full TUI for commits, branches, and PR-style diffs. When delta is installed, lazygit automatically uses it for all diff views — same syntax highlighting and side-by-side layout as the terminal pager.

```bash
lazygit          # open from terminal
# Space+gg       # open from inside nvim
```

Key lazygit bindings for diff navigation:

| Key | Action |
|---|---|
| `1-5` | Switch panels (Status / Files / Branches / Commits / Stash) |
| `Enter` | Drill into file diff |
| `[` / `]` | Previous / next file in diff |
| `←` / `→` | Scroll diff left/right |
| `{` / `}` | Previous / next hunk |
| `d` (on branch) | View diff against current branch |
| `space` (on commit) | Cherry-pick |
| `D` | Diff menu (choose base) |
| `?` | Help |

To compare two branches visually:
1. Open lazygit → go to Branches panel (`3`)
2. Navigate to the target branch, press `d` → **diff branch against current**

To review a PR locally:
```bash
gh pr checkout 123   # check out the PR branch
lazygit              # browse commits and file diffs in the PR
```

### WSL helpers

```bash
explore                          # open Windows Explorer here
pbcopy                           # copy to Windows clipboard
winpath .                        # print Windows path for current dir
wslpath_from_win 'C:\Users\...'  # convert Windows path to WSL path
```

---

## Terminal multiplexer

The wizard offers three options: **herdr** (default), **tmux**, or skip.

### herdr

herdr is an agent-aware terminal multiplexer built for AI coding workflows. Panes are automatically tagged as *working*, *blocked*, or *idle*, and you're alerted when an agent needs input. Sessions persist through disconnects and can be reattached from SSH or a mobile web UI.

Install: `curl -fsSL https://herdr.dev/install.sh | sh`

Config written to: `~/.config/herdr/config.toml`

Start a session:

```bash
herdr
```

Reattach after disconnect: run `herdr` again in any terminal.

#### Keybindings

| Binding | Action |
|---|---|
| `Prefix + \|` | Split pane vertically (side by side) |
| `Prefix + -` | Split pane horizontally (above/below) |
| `Shift + arrows` | Switch tabs (no prefix needed) |
| `Prefix + h/j/k/l` | Navigate panes (vim style) |
| `Alt + arrows` | Navigate panes (no prefix needed) |
| `Prefix + H/J/K/L` | Resize panes |
| `Prefix + c` | New tab |
| `Prefix + Shift+T` | Rename tab |
| `Prefix + N` | New workspace |
| `Prefix + w` | Workspace picker |
| `Prefix + S` | Session navigator |
| `Prefix + Shift+G` | New git worktree |
| `Prefix + A` | Launch Claude Code in new pane |
| `Prefix + r` | Reload `~/.config/herdr/config.toml` |
| `Prefix + d` | Detach |

Default prefix: `Ctrl+b` (same as tmux).

#### Agent awareness

herdr automatically detects Claude Code (and 20+ other agents) and tracks each pane's state:

- Pane status indicators: *working* / *blocked* / *idle* (shown as distinct symbols)
- Blocked state triggers an alert when the agent needs your input
- After a server restart, Claude Code sessions resume automatically (requires Claude Code v6+)

```bash
herdr agent explain claude     # debug detection for a pane
herdr agent rename claude "cc" # rename how a pane is labeled
herdr agent attach claude      # focus the Claude pane directly (detach: ctrl+b q)
```

#### Workspaces and worktrees

herdr *workspaces* group tabs per project — think of them as named sessions. *Worktrees* are git worktrees; herdr creates and manages them from `~/github` (your workspace root).

```bash
herdr worktree new feat/my-branch   # create worktree + open it in a new workspace
```

#### Session restore

After a full restart, herdr restores workspace layout, tabs, panes, and working directories. Running processes reopen as fresh shells — with two exceptions wired up by this wizard:

- **Claude Code** resumes its conversation automatically (see integration note below)
- **Neovim** relaunches in any pane whose tab is named `nvim` — name your nvim tabs consistently and they restore hands-free

Claude Code resumes its conversation automatically — this requires the herdr Claude integration, which the wizard installs automatically. To check or install manually:

```bash
herdr integration status          # check — should show "claude: current (vN)"
herdr integration install claude  # install if missing
```

The integration installs a hook at `~/.claude/hooks/herdr-agent-state.sh` that reports session identity back to herdr, enabling `resume_agents_on_restore = true` (set in `config.toml`) to work.

To also restore terminal scrollback output (disabled by default due to secret exposure risk):

```toml
[experimental]
pane_history = true
```

### tmux

Classic multiplexer, battle-tested option.

Install: `sudo apt install tmux`

Config written to: `~/.tmux.conf`

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

Default prefix is configurable: `Ctrl+b`, `Ctrl+a`, or `Ctrl+Space`.

Status bar shows: session name, kube context, git branch, hostname, clock.

---

## Re-running the wizards

Both wizards are safe to re-run at any time:

- Config files are backed up before being overwritten (`<path>.bak.TIMESTAMP`)
- The entire `~/.config/nvim` directory is backed up before rewriting
- Already-installed tools are skipped with a version report
- The `~/.bashrc` source lines are only added once (idempotent markers)

To switch themes, re-run the relevant wizard and pick a different one.

---

## Files written

### shell-wizard.sh

| Path | Purpose |
|---|---|
| `~/.config/starship.toml` | Starship prompt config |
| `~/.config/dev-setup/bashrc_devsetup.sh` | All aliases and functions |
| `~/.config/herdr/config.toml` | herdr config (if herdr chosen) |
| `~/.claude/hooks/herdr-agent-state.sh` | herdr Claude integration hook (if herdr chosen) |
| `~/.tmux.conf` | tmux config (if tmux chosen) |
| `~/.bashrc` | Gets one `source` line appended |
| `C:\Users\<you>\...\Fonts\` | Nerd Font TTFs (WSL only) |
| Windows Terminal `settings.json` | Color scheme + profile settings (WSL only) |

### neovim-wizard.sh

| Path | Purpose |
|---|---|
| `~/.config/nvim/` | Full LazyVim config (7 Lua files) |
| `~/.config/dev-setup/bashrc_neovim.sh` | nvim aliases and functions |
| `~/.bashrc` | Gets one `source` line appended |

### Nerd Font (WSL — icons in Neovim)

Icons in neo-tree, bufferline, and lualine require a Nerd Font installed on the Windows side.
Run the included script once from **PowerShell (Windows)**:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# path printed by the wizard at the end of its run:
\\wsl$\Ubuntu\home\<you>\github\personal\tools\dev-setup\install-nerd-font.ps1
```

Then set font to **JetBrainsMono Nerd Font Mono** in Windows Terminal → your WSL profile → Appearance.
