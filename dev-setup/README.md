# dev-setup

Interactive wizards to configure a terminal-based developer environment on Linux, macOS, or WSL.

---

## Wizards

| Script | Purpose |
|---|---|
| `shell-wizard.sh` | Shell prompt (Starship), Python toolchain, Kubernetes CLI, ArgoCD, Claude Code launcher, herdr or tmux, Windows Terminal theming |
| `neovim-wizard.sh` | Neovim + LazyVim: editor, LSPs, formatter, linter, Claude Code integration |

`shell-wizard.sh` asks at the start whether to also run `neovim-wizard.sh` afterwards, so one run can set up both. Both wizards support Linux, macOS, and WSL.

Both wizards share a `lib/helpers.sh` library and follow the same pattern: gather all questions upfront, show a summary, confirm once, then write everything.

---

## Requirements

- Bash 3.2+ (macOS default works); zsh is supported as the interactive shell
- `curl`
- `python3` (for Windows Terminal patching, available in all Ubuntu WSL distros)
- `git`
- Linux/WSL: `sudo` / `apt` (for ripgrep, fd-find, tmux). macOS: [Homebrew](https://brew.sh) (only needed for tmux)

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
source ~/.bashrc   # or ~/.zshrc (zsh) / ~/.bash_profile (bash on macOS)
```

The shell wizard detects your shell and OS and wires into the right rc file. New terminals pick up the config automatically.

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
| `go` | Go toolchain (required for lazyworktree) |
| `lazyworktree` | TUI for managing git worktrees — create, switch, delete, view PR/CI status |
| `opencode` | Open source AI coding agent (companion to Claude Code) |
| `herdr` | Terminal multiplexer for AI agents, TUI edition (via curl installer) |
| `herdr-app` + `herdr-core` | herdr native desktop UI and its terminal runtime (via curl installer) |
| `tmux` | Terminal multiplexer, classic option (via apt) |

One multiplexer is installed depending on your choice — herdr is the default recommendation (TUI, UI, or both). Already-installed tools are detected and skipped.

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
| `node` + `npm` | Mason installs the `pyright`, `ts_ls` and `bashls` language servers with npm; also used by the `neovim` npm provider, the Markdown preview build, and Copilot. Optional: the wizard asks, and reuses an existing Node (via nvm otherwise) |
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
| `~/.bashrc` / `~/.zshrc` / `~/.bash_profile` | Gets one `source` line appended (zsh → `.zshrc`; bash → `.bashrc`, or `.bash_profile` on macOS) |

### Keybindings (VSCode-style)

| Key | Action |
|---|---|
| `Ctrl+P` | Find files |
| `Ctrl+Shift+P` | Commands palette |
| `Space+/` | Search in files |
| `Space+s.` | Search all files including hidden dirs (`.github`, etc.) |
| `Space+e` | Toggle file tree |
| `Ctrl+T` | Toggle terminal |
| `Ctrl+S` | Save file |
| `Space+bd` | Close buffer |
| `Shift+H` / `Shift+L` | Prev / next buffer |
| `Shift+ScrollUp` / `Shift+ScrollDown` | Scroll buffer horizontally (4 cols per notch) |
| `Ctrl+W l` / `Ctrl+W h` | Move focus editor ↔ explorer |
| `F12` | Go to definition |
| `Shift+F12` | Find references |
| `F2` | Rename symbol |
| `Ctrl+.` | Code actions |
| `Space` (alone) | Show all keybindings (which-key) |
| `<Space>cc` | Toggle Claude Code (context-aware) |
| `<Space>gg` | LazyGit (if installed) |
| `<Space>gm` | Fetch origin/main then open DiffView (branch vs origin/main) |
| `<Space>gM` | Close DiffView |
| `<Space>uw` | Toggle line wrap |
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

### Claude Code + opencode (from shell-wizard)

```bash
cc [project]       # cd into workspace/project, activate venv, launch claude
oc [project]       # cd into workspace/project, activate venv, launch opencode
cw                 # cd to workspace root
```

Both `cc` and `oc` tab-complete project names from your workspace root.

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
argo_sync my-app               # sync + wait --health (120s timeout)
argo_sync my-app 300           # sync + wait --health with custom timeout (seconds)
argo_sync_only my-app          # sync only, no health wait (useful for apps with Secret resources)
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

### Git worktrees — lazyworktree

lazyworktree is a keyboard-driven TUI for managing git worktrees. It shows all worktrees with their branch, PR/CI status (via `gh`), and lets you create, switch, and delete them interactively.

Worktrees are stored under `~/worktrees/` with three subdirectories:

| Directory | Purpose |
|---|---|
| `~/worktrees/work/` | Work repository branches |
| `~/worktrees/personal/` | Personal project branches |
| `~/worktrees/scratch/` | Throwaway / experimental branches |

```bash
lazyworktree    # open TUI in current repo
lwt             # alias for lazyworktree
```

| Key | Action |
|---|---|
| `↑` / `↓` | Navigate worktrees |
| `Enter` | Switch to selected worktree |
| `c` | Create new worktree from branch/PR |
| `d` | Delete worktree |
| `?` | Help |

Works alongside herdr's worktree support — use `lazyworktree` to browse and switch, `Prefix+Shift+G` to create directly from herdr.

### Worktree + nvim + agents workflow

**Start a new feature:**
```bash
lwt              # press c → type branch name → herdr opens it in a new workspace
# or: Prefix+Shift+G from herdr directly
```

**Set up the workspace** — in the new workspace open two tabs:
- Tab named `agents` → `oc` or `cc` to launch opencode or Claude Code
- Tab named `nvim` → `ccnvim` to open nvim in the worktree directory

Or press `o` in `lwt` to open the worktree automatically with both tabs pre-configured.

Both tools are automatically scoped to the worktree directory.

**Navigate while working:**
```
Prefix+[ / ]     switch between workspaces (feature branch ↔ main)
Prefix+, / .     jump between agents across workspaces
Prefix+w         workspace picker — fuzzy search by project name
```

**Review your changes before pushing:**
```bash
gdc              # quick terminal diff vs main
# or in nvim:
Space+gm         # full DiffView with file tree + delta highlighting
Space+gg         # lazygit to stage, commit, push
```

**Parallel features** — each worktree has its own herdr workspace with independent nvim and agent sessions. Agent status is visible in the sidebar across all workspaces — `Prefix+,/.` jumps to whichever agent needs attention next.

**Clean up after merge:**
```bash
lwt    # select the merged worktree → d to delete
```
Herdr removes the workspace, the worktree is gone, you're back on main.

---

## Terminal multiplexer

The wizard offers three options: **herdr** (default), **tmux**, or skip.

### herdr

herdr is an agent-aware terminal multiplexer built for AI coding workflows. Panes are automatically tagged as *working*, *blocked*, or *idle*, and you're alerted when an agent needs input. Sessions persist through disconnects and can be reattached from SSH or a mobile web UI.

The wizard asks which edition to install:

| Edition | Install | Config |
|---|---|---|
| **TUI** (default) | `curl -fsSL https://herdr.dev/install.sh \| sh` | `~/.config/herdr/config.toml` (written by the wizard) |
| **UI** (native app + `herdr-core`) | `curl -fsSL https://releases.herdr.dev/app/install.sh \| sh` | `~/.config/herdr-app/` (managed by the app; not written by the wizard) |
| **both** | both of the above | both |

The UI runs terminals through `herdr-core` (`hc`), which the app installer adds if missing. The UI self-updates. The wizard also writes your chosen color theme as `~/.config/herdr-app/themes/dev-setup-<theme>.json`, installs the CaskaydiaCove Nerd Font Mono (`~/Library/Fonts` on macOS, `~/.local/share/fonts` on Linux), and sets `theme` and `font` in `settings.json`. The UI has no `ctrl+b` prefix mode: its shortcuts are `cmd-` chords from `keys.json` (`cmd-d` split, `cmd-t` new tab, `cmd-alt-arrows` move between panes). The wizard also enables the **Files** and **Changes** side panels by setting `"workspace.panels": ["files", "changes"]` in `~/.config/herdr-app/shared.json` (quit `herdr-app` first, or it may overwrite the file). The TUI and UI don't share agents. UI limits: Apple Silicon only on macOS (Intel must build from source). If `~/.local/state` is root-owned, core fails with "Permission denied"; fix with `sudo chown -R "$USER" ~/.local/state`. The keybindings, worktree-restore snippet, and Claude integration below apply to the TUI only.

#### UI keyboard shortcuts

The UI has **no `ctrl+b` prefix mode**. It only supports single chords from `~/.config/herdr-app/keys.json`, so the TUI's `prefix + key` bindings do not exist there. The wizard merges prefix-free pane keys into `keys.json` (your other keys stay as they are, and re-running is safe):

| Action | macOS | Linux / WSL |
|---|---|---|
| Focus pane left / down / up / right | `Cmd+Ctrl + h / j / k / l` | `Ctrl+Shift + h / j / k / l` |
| Split right / down | `Cmd+Ctrl + o / e` | `Ctrl+Shift + o / e` |
| New tab | `Cmd+T` (app default) | `Ctrl+Shift+T` (added) |

Other macOS defaults from the app: `Cmd+D` split right, `Cmd+Shift+D` split down, `Cmd+Alt+arrows` focus pane, `Cmd+1..9` select tab, `Ctrl+1..9` select space, `Cmd+B` toggle sidebar, `Cmd+Shift+P` command palette, `Cmd+/` help. On Linux/WSL, open the help (`app.help`) or command palette to see the app's own defaults for your platform.

Notes:
- **Why those modifiers:** plain `Ctrl+letter` belongs to the program in the terminal (readline, nvim), and on many Mac keyboards `Option+letter` types characters like `[` or `@`. `Ctrl` + `Alt` is AltGr on Windows. So the wizard uses `Cmd+Ctrl` on macOS and `Ctrl+Shift` elsewhere.
- **Files / Changes panels:** reachable by mouse or `layout.toggle`, but not by pane-focus keys (their `mod.json` is not `focusable`).
- **Fresh install:** `keys.json` is created the first time the app runs. If the wizard says it doesn't exist yet, launch `herdr-app` once and re-run the wizard.
- **Customize:** edit `keys.json` (changes apply live). Run `herdr-app commands` to list every action, for example `pane.go:left`, `pane.split:right`, `tab.select:2`. If a key breaks things, `Ctrl+Alt+Shift+Esc` resets the layout and `keys.json`.
- **macOS conflicts:** the system or another app may already own a chord. Remap in `keys.json`.
- **WSL:** the wizard installs the Linux build, which runs under WSLg (so the Linux column applies). A native Windows install of the UI (`install.ps1`) keeps its config on the Windows side and is not configured by this wizard.

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
| `Prefix + [` | Previous workspace |
| `Prefix + ]` | Next workspace |
| `Prefix + ,` | Previous agent |
| `Prefix + .` | Next agent |
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
| `~/.config/herdr/config.toml` | herdr TUI config (if herdr TUI chosen) |
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
