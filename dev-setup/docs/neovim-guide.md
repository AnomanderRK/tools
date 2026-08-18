# Neovim Reference Guide

Your Neovim is built on **LazyVim** — a full IDE config using the best community
plugins. This guide covers everything you need day-to-day.

Open this file any time:  `nvim ~/.config/nvim/GUIDE.md`

---

## The basics: modal editing

Neovim has **modes**. This is the biggest change from VSCode.

| Mode | How to enter | What it does |
|---|---|---|
| **Normal** | `Esc` or `<Esc><Esc>` | Navigate, run commands — this is home base |
| **Insert** | `i` (before cursor), `a` (after), `o` (new line below) | Type text |
| **Visual** | `v` (char), `V` (line), `Ctrl+v` (block) | Select text |
| **Command** | `:` | Run editor commands like `:w`, `:q` |

The status bar at the bottom always shows your current mode.

**Most important rule:** if anything feels stuck, press `Esc` a couple of times
to get back to Normal mode.

---

## Starting up

```bash
nvim                    # open with file explorer (like VSCode startup)
nvim .                  # open current directory
nvim myfile.py          # open a specific file
ccnvim my-project       # cd to project + activate venv + open nvim
```

---

## Layout (what you see)

```
┌─────────────────────────────────────────────────────────────────┐
│  file1.py  ×   file2.ts  ×                   ← buffer tabs      │
├──────────────┬──────────────────────────────────────────────────┤
│              │  1  import os                  ← editor          │
│  Explorer    │  2  import sys                                    │
│              │  3                                                │
│  📁 src/     │  4  def main():                                   │
│    app.py    │  5    print("hello")                             │
│    utils.py  │  6                                                │
│  📄 README   │                                                   │
│              │                                                   │
├──────────────┴──────────────────────────────────────────────────┤
│  NORMAL   main.py   python   ln 5, col 1          ← status bar  │
└─────────────────────────────────────────────────────────────────┘
```

- **Tabs** at top = open buffers (like VSCode editor tabs)
- **Left panel** = file explorer (neo-tree, like VSCode sidebar)
- **Status bar** = mode, file, language, position

---

## File navigation

| Key | Action |
|---|---|
| `Ctrl+P` | Find file by name (fuzzy — just type part of the name) |
| `Ctrl+Shift+F` | Search text across all files |
| `Space+e` | Toggle file explorer sidebar |
| `Shift+H` | Go to previous tab/buffer |
| `Shift+L` | Go to next tab/buffer |
| `<Space>q` | Close current buffer (tab) |
| `:b <Tab>` | Pick buffer by name from command line |
| Inside explorer: `Enter` | Open file |
| Inside explorer: `a` | New file |
| Inside explorer: `d` | Delete file |
| Inside explorer: `r` | Rename file |
| Inside explorer: `?` | Show all explorer keys |
| `Ctrl+W l` | Move focus from explorer to editor |
| `Ctrl+W h` | Move focus from editor to explorer |
| `Ctrl+W w` | Cycle focus between all open windows |

**Example — open a file quickly:**
Press `Ctrl+P`, type `app` — fuzzy matches `src/app.py`, `components/App.tsx`, etc.
Arrow keys or `Ctrl+J/K` to move, `Enter` to open.

---

## Editing

### Basic text operations (Normal mode)

| Key | Action |
|---|---|
| `i` | Insert before cursor |
| `a` | Insert after cursor |
| `o` | New line below, enter Insert |
| `O` | New line above, enter Insert |
| `dd` | Delete (cut) current line |
| `yy` | Yank (copy) current line |
| `p` | Paste below / after |
| `P` | Paste above / before |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `Ctrl+S` | Save (works in any mode) |

### Moving around (Normal mode)

| Key | Action |
|---|---|
| `h j k l` | Left / Down / Up / Right (or use arrow keys) |
| `w` / `b` | Next / previous word |
| `0` / `$` | Start / end of line |
| `gg` / `G` | Top / bottom of file |
| `Ctrl+d` / `Ctrl+u` | Half page down / up |
| `zz` | Center screen on cursor |
| `gd` or `F12` | Go to definition |
| `gr` or `Shift+F12` | Find references |
| `Ctrl+o` | Jump back (like Alt+Left in VSCode) |
| `Ctrl+i` | Jump forward |

### Selection and multi-edit

| Key | Action |
|---|---|
| `v` then move | Select characters |
| `V` then move | Select lines |
| `Ctrl+v` | Block (column) select |
| `y` (in visual) | Copy selection |
| `d` (in visual) | Delete selection |
| `gc` (in visual) | Toggle comment on selection |
| `gcc` (normal) | Toggle comment on current line |

**Example — comment out a block:**
Press `V`, move down to select lines, then `gc` — all selected lines are toggled.

---

## Code intelligence (LSP)

These work when a file is open with an active language server.
The colored dot ● in the status bar shows if LSP is attached.

| Key | Action |
|---|---|
| `F12` or `gd` | Go to definition |
| `Shift+F12` or `gr` | Find all references |
| `F2` | Rename symbol (renames everywhere in project) |
| `Ctrl+.` | Code actions (quick fixes, imports, etc.) |
| `K` | Hover documentation |
| `<Space>ca` | Code actions (alternative) |
| `<Space>cd` | Line diagnostics (show error detail) |
| `[d` / `]d` | Jump to previous / next diagnostic |

**Example — fix a missing import:**
Cursor on an unresolved name → press `Ctrl+.` → select "Add import" from the list.

**Example — rename a function across the whole project:**
Cursor anywhere on the function name → `F2` → type new name → `Enter`.
Every file that references it is updated.

### After first launch — install LSPs

On very first open, Mason installs language servers automatically.
Check progress with `:Mason` or `:checkhealth`.

Installed servers:
- `pyright` — Python type checking + autocomplete
- `ruff_lsp` — Python linting + formatting
- `typescript-tools` — TypeScript + React Native (faster than ts_ls)
- `lua_ls` — Lua
- `bashls` — Bash

---

## Terminal

| Key | Action |
|---|---|
| `Ctrl+T` | Toggle terminal (horizontal split at bottom) |
| `<Space>cc` | Claude Code in a large floating window |
| `Esc Esc` (in terminal) | Leave terminal insert mode (float stays open) |
| `<Space>cc` (in terminal) | Hide the Claude float |
| `i` or `a` (in terminal) | Re-enter terminal insert mode |
| `:terminal` | Open a terminal in a new buffer |

Inside the terminal you can run any shell command, use your `cc` / `ccnvim`
functions, git, etc. — it's a full shell.

**Example — run tests without leaving Neovim:**
`Ctrl+T` opens a split at the bottom. Type `pytest tests/` and see output inline.
`Ctrl+T` again to hide it; your editor state is untouched.

**Example — ask Claude about the code you're looking at:**
`<Space>cc` opens Claude Code in a large float. Paste a snippet, ask a question,
then `<Space>cc` again to hide and go back to editing. The session persists.

---

## Search and replace

| Key | Action |
|---|---|
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n` / `N` | Next / previous match |
| `Esc` | Clear search highlights |
| `Ctrl+Shift+F` | Telescope live grep (search across files) |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all with confirmation |

**Example — find all usages of a string across the repo:**
`Ctrl+Shift+F`, type the string. Results update live. `Enter` to jump to a match.

**Example — rename a variable in the current file:**
`:%s/old_name/new_name/gc` — replaces each one and asks to confirm (`y/n/a/q`).

---

## Git

| Key | Action |
|---|---|
| `<Space>gg` | LazyGit TUI (if installed) |
| `<Space>gD` | Diffview — side-by-side diff of all staged changes |
| `<Space>gh` | Diffview — current file git history |
| `<Space>gH` | Diffview — full repo git history |
| `<Space>gx` | Close diffview |
| `<Space>gb` | Git blame (current file) |
| `<Space>gd` | Git diff |
| `<Space>gs` | Git status |
| `]c` / `[c` | Jump to next / previous git change |
| `<Space>ghr` | Reset git hunk (discard change) |
| `<Space>ghs` | Stage git hunk |

Gitsigns shows colored indicators in the left gutter:
- `+` green = added line
- `~` blue = changed line
- `-` red = deleted line

**Example — review your changes before committing:**
`<Space>gD` opens a split with the diff on the right and file list on the left.
Navigate files with `j/k`, jump to next change with `]c`. `<Space>gx` to close.

**Example — see who wrote a line:**
`<Space>gb` toggles inline blame at the end of every line — author, date, message.

**Example — stage just one hunk, not the whole file:**
Navigate to the changed block → `<Space>ghs` stages that hunk only.
`<Space>ghr` discards it instead.

---

## Diagnostics and errors (Trouble)

| Key | Action |
|---|---|
| `<Space>xx` | Toggle diagnostics panel (whole project) |
| `<Space>xb` | Toggle diagnostics panel (current buffer only) |
| `<Space>xs` | Symbols panel (functions, classes, variables) |
| `<Space>xl` | LSP definitions / references panel |
| `[d` / `]d` | Jump to previous / next diagnostic inline |
| `<Space>cd` | Show current line diagnostic detail |

**Example — see all errors in the project at once:**
`<Space>xx` opens a panel at the bottom listing every warning and error across
all open files. Navigate with `j/k`, press `Enter` to jump to the location.
`<Space>xx` again to close.

**Example — browse all functions in a file:**
`<Space>xs` opens the symbols panel — a tree of every class, function, and
variable. Jump to any of them instantly.

---

## TODO comments

`TODO:`, `FIXME:`, `HACK:`, `NOTE:`, `BUG:` in comments are highlighted with
distinct colors and are searchable across the whole project.

| Key | Action |
|---|---|
| `<Space>ft` | Find all TODOs in project (Telescope) |
| `]t` / `[t` | Jump to next / previous TODO |

**Example — audit all unfinished work before a release:**
`<Space>ft` opens a Telescope picker listing every `TODO` and `FIXME` in the
codebase with file and line number. Jump to any one with `Enter`.

**Writing them in code:**
```python
# TODO: add pagination support
# FIXME: this crashes when list is empty
# HACK: workaround for upstream bug #123
# NOTE: called from both login and signup flows
```

---

## Python virtualenv

| Key | Action |
|---|---|
| `<Space>vs` | Select a virtualenv (opens Telescope picker) |
| `<Space>vc` | Show which venv is currently active |

The selected venv is picked up by pyright automatically — no need to restart Neovim.

**Example — switch venv for a different project:**
Open a Python file → `<Space>vs` → Telescope lists all venvs it finds (`.venv`,
`venv`, pyenv versions, etc.) → select one → pyright reattaches to that interpreter.

**Tip:** if you use `ccnvim my-project`, the venv is activated in the shell before
Neovim opens, so pyright picks it up automatically without needing `<Space>vs`.

---

## Markdown

Markdown files render in-buffer in Normal mode: headings become bold and colored,
code blocks get a background, bullets become `•` symbols, and checkboxes render as
`☐` / `☑`. Switch to Insert mode to edit the raw text; rendering resumes on `Esc`.

**Example — read this guide with formatting:**
```bash
nvim ~/.config/nvim/GUIDE.md
```
Press `Esc` to be in Normal mode and the file renders with full formatting.
Press `i` to edit the raw Markdown source.

---

## Surround (nvim-surround)

Add, change, or delete surrounding brackets, quotes, or any character pair —
without selecting first.

| Key | Action | Example |
|---|---|---|
| `ysiw"` | Surround word under cursor with `"` | `hello` → `"hello"` |
| `ysiw)` | Surround word with `()` | `hello` → `(hello)` |
| `ysiw]` | Surround word with `[]` | `hello` → `[hello]` |
| `cs"'` | Change surrounding `"` to `'` | `"hello"` → `'hello'` |
| `cs({` | Change `()` to `{}` | `(hello)` → `{hello}` |
| `ds"` | Delete surrounding `"` | `"hello"` → `hello` |
| `ds(` | Delete surrounding `()` | `(hello)` → `hello` |
| `S"` (Visual) | Surround selection with `"` | select `hello` → `"hello"` |

**How to read `ysiw"`:**
- `ys` = "you surround"
- `iw` = "inner word" (the word under cursor)
- `"` = the character to wrap with

**Example — wrap a variable in a function call:**
Cursor on `my_var` → `ysiw)` → `my_var` becomes `(my_var)` → then type the
function name before it with `i`.

---

## Oil file browser

Edit the filesystem like a text buffer. Open a directory listing, then rename
files by editing the text, delete files by deleting lines, create files by
adding lines — then save with `Ctrl+S` to apply all changes at once.

| Key | Action |
|---|---|
| `<Space>o` | Open Oil in current directory |
| `Ctrl+S` | Apply all changes (rename / delete / create) |
| `-` | Go up one directory level |
| `Enter` | Open file or enter directory |
| `Esc` or `q` | Discard changes and close |
| `g?` | Show all Oil keybindings |

**Example — rename several files at once:**
`<Space>o` → directory opens as a buffer → edit the filenames inline (use Normal
mode editing: `cw` to change a word, etc.) → `Ctrl+S` → all renames happen.

**Example — reorganize a folder:**
Delete lines to delete files, add new lines to create empty files, edit names
to rename. `Ctrl+S` applies everything in one shot.

---

## Window and split management

| Key | Action |
|---|---|
| `Ctrl+W v` | Vertical split |
| `Ctrl+W s` | Horizontal split |
| `Ctrl+W h/j/k/l` | Move between splits |
| `Ctrl+W >` / `<` | Resize split width |
| `Ctrl+W =` | Equalize split sizes |
| `Ctrl+W q` | Close split |

**Example — compare two files side by side:**
Open `file1.py` → `Ctrl+W v` → `:e file2.py` → both files open in vertical splits.
`Ctrl+W h/l` to switch between them.

---

## Quitting and restarting

Press `Esc` first to make sure you're in Normal mode, then:

| Command | Action |
|---|---|
| `:q` | Quit (fails if there are unsaved changes) |
| `:q!` | Quit and discard unsaved changes |
| `:wq` | Save and quit |
| `:qa` | Quit all open buffers |
| `:qa!` | Quit everything, discard all changes |

To reload config without quitting (after editing a Lua file):

| Command | Action |
|---|---|
| `:source %` | Reload the current file |
| `:Lazy reload` | Reload all plugins |

---

## Plugin manager (`:Lazy`)

Open with `:Lazy`, close with `q`.

| Key (inside `:Lazy`) | Action |
|---|---|
| `q` | Close the panel |
| `U` | Update all plugins |
| `S` | Sync (install missing, remove unused) |
| `C` | Check for updates without installing |
| `X` | Clean unused plugins |
| `R` | Restore plugins to lockfile versions |
| `Enter` | Show details for highlighted plugin |

| Command | Action |
|---|---|
| `:Lazy` | Open plugin manager |
| `:Lazy update` | Update all plugins |
| `:Mason` | Open LSP / tool manager (close with `q`) |
| `:checkhealth` | Diagnose any issues |

---

## Command line (`:` mode)

The command line popup shows autocomplete options as you type. Navigation:

| Key | Action |
|---|---|
| `Ctrl+N` | Move down the list |
| `Ctrl+P` | Move up the list |
| `Tab` | Complete / select highlighted option |
| `Enter` | Execute the command |
| `Ctrl+E` | Close popup, keep what you typed |
| `Esc` | Cancel and return to Normal mode |

Arrow keys don't work inside the command line — use `Ctrl+N` / `Ctrl+P` instead.

---

## Command palette

Press `<Space>` (leader key) alone and wait — **which-key** shows every
available command grouped by category. This is your command palette, similar
to `Ctrl+Shift+P` in VSCode.

Useful `<Space>` groups:
- `<Space>f` — find (files, text, buffers, symbols...)
- `<Space>g` — git
- `<Space>c` — code (actions, diagnostics...)
- `<Space>u` — UI toggles (line numbers, wrap, etc.)
- `<Space>x` — diagnostics list
- `<Space>cc` — Claude Code

---

## Config files

All config lives in `~/.config/nvim/`:

```
~/.config/nvim/
├── init.lua                    # entry point (don't edit)
├── GUIDE.md                    # this file
└── lua/
    ├── config/
    │   ├── lazy.lua            # plugin list and lazy.nvim setup
    │   ├── options.lua         # editor settings (numbers, tabs, etc.)
    │   └── keymaps.lua         # all custom keybindings
    └── plugins/
        ├── colorscheme.lua     # your chosen theme
        ├── ui.lua              # layout (explorer, tabs, statusline)
        ├── lsp.lua             # LSP, formatting, linting
        ├── tools.lua           # terminal, telescope, treesitter
        └── extras.lua          # markdown, surround, todo, trouble, diffview, oil
```

To change a setting, edit the relevant file and save. Most changes take effect
immediately (no restart needed) because LazyVim hot-reloads config.

To add a new plugin, add a spec to any file in `lua/plugins/` and run `:Lazy`.

---

## Troubleshooting

### Icons show as boxes or question marks

You need a Nerd Font installed on the Windows side. Run the included script
once from **PowerShell (Windows, not WSL)**:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# path shown at the end of the neovim-wizard run, or find it in the repo:
\\wsl$\Ubuntu\home\<you>\github\personal\tools\dev-setup\install-nerd-font.ps1
```

Then in **Windows Terminal** → Settings → your WSL profile → Appearance → Font face,
set it to `JetBrainsMono Nerd Font Mono` and restart the terminal.

If you can't run PowerShell scripts, install the font manually:
1. Download: `https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip`
2. Extract → select all `.ttf` files → right-click → **Install**
3. Set font in Windows Terminal as above

### `:Lazy` / `:Mason` panel won't close

Press `q` in Normal mode. If you're stuck in Insert mode first press `Esc`, then `q`.

### LSP not working on a file

Run `:checkhealth` and `:Mason` to confirm the server is installed.
For Python, make sure you're inside a project directory (pyright looks for `pyproject.toml` or `setup.py`).

### Neovim feels slow on first open

The first launch downloads ~50 plugins (~2 min). Subsequent opens are instant.
Progress is visible with `:Lazy`.

---

## Quick reference card

```
Esc          → Normal mode (always safe to press)
i / a / o    → Insert mode
v / V        → Visual mode (select)
:            → Command mode

Ctrl+P       → find file
Ctrl+Shift+F → search in files
Space+e      → toggle explorer
Ctrl+T       → toggle terminal
Space+cc     → Claude Code

F12 / gd     → go to definition
Shift+F12    → find references
F2           → rename symbol across project
Ctrl+.       → code actions (fix imports, etc.)
K            → hover docs

Shift+H/L    → prev/next tab
Space+q      → close tab

u            → undo
Ctrl+R       → redo
Ctrl+S       → save

Space+xx     → diagnostics panel (all errors)
Space+ft     → find all TODOs
Space+vs     → select Python venv
Space+o      → Oil file browser
Space+gD     → git diff view
Space+gg     → LazyGit

ysiw"        → surround word with "
cs"'         → change " to '
ds(          → delete surrounding ()

Space        → command palette (wait 300ms)
:q / :qa     → quit / quit all
:q! / :qa!   → quit discarding changes
:wq          → save and quit
:checkhealth → diagnose issues
:Lazy        → plugin manager (close with q)
:Mason       → LSP manager (close with q)
```
