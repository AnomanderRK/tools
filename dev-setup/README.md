# dev-setup

Interactive wizards to configure a terminal-based developer environment on WSL or bare Linux.

---

## Wizards

| Script | Purpose |
|---|---|
| `shell-wizard.sh` | Shell prompt (Starship), Python toolchain, Kubernetes CLI, ArgoCD, Claude Code launcher, tmux, Windows Terminal theming |
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

Sets up Starship prompt, pyenv, uv, kubectl, tmux, Claude Code launcher, and Windows Terminal theme.

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

Theme choices: **Nord**, **Catppuccin Mocha**, **Tokyo Night**, **Solarized Light**, or Classic ANSI. The same palette drives both Starship and the tmux status bar.

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
| `tmux` | Terminal multiplexer (via apt) |

Already-installed tools are detected and skipped.

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
| `Space+q` | Close buffer |
| `Shift+H` / `Shift+L` | Prev / next buffer |
| `Ctrl+W l` / `Ctrl+W h` | Move focus editor ↔ explorer |
| `F12` | Go to definition |
| `Shift+F12` | Find references |
| `F2` | Rename symbol |
| `Ctrl+.` | Code actions |
| `Space` (alone) | Show all keybindings (which-key) |
| `<Space>cc` | Toggle Claude Code (context-aware) |
| `<Space>gg` | LazyGit (if installed) |

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
kctx / kns                        # switch context / namespace
kgctx                             # list all contexts
klns <namespace> <prefix>         # tail logs by namespace + pod prefix
wkns <namespace>                  # watch pods (refreshes every 2s)
```

### ArgoCD

```bash
acd / acdal / acdas / acdaw   # argocd / app list / app sync / app wait
argo_sync my-app               # sync + wait --health in one command
argo_logs my-app               # stream live app logs
```

### Git

```bash
gs / gd / gds        # status / diff / diff --staged
ga / gc / gp / gpl   # add / commit / push / pull --rebase
gl                   # log --oneline --graph (last 20)
gco / gb / gst       # checkout / branch -vv / stash
```

### WSL helpers

```bash
explore                          # open Windows Explorer here
pbcopy                           # copy to Windows clipboard
winpath .                        # print Windows path for current dir
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
| `~/.tmux.conf` | tmux config |
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
