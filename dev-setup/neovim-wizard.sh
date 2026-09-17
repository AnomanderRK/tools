#!/usr/bin/env bash
# neovim-wizard.sh — Neovim + LazyVim setup wizard
# Installs Neovim, Node.js, ripgrep, fd, and writes a full LazyVim config
# tuned for Python, React Native, and Claude Code integration.
#
# Usage:
#   bash neovim-wizard.sh              # interactive wizard
#   bash neovim-wizard.sh --dry-run    # preview what would be written, no changes

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/helpers.sh
source "$SCRIPT_DIR/lib/helpers.sh"

# ─── Banner ───────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}${CYAN}"
cat << 'BANNER'
  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
                    + LazyVim
BANNER
echo -e "${RESET}"
$DRY_RUN && echo -e "  ${YELLOW}DRY RUN — no files will be written${RESET}\n"
divider

# ─── Gather preferences ───────────────────────────────────────────────────────
say "Preferences"
echo

THEME_LABEL=$(ask_choice "Color theme (should match your shell theme for consistency):" 3 \
  "Nord (dark, blue-purple)" \
  "Catppuccin Mocha (dark, pastel)" \
  "Tokyo Night (dark, neon)" \
  "Solarized Light" \
  "Classic (LazyVim default)")
echo

case "$THEME_LABEL" in
  Nord*)        THEME="nord" ;;
  Catppuccin*)  THEME="catppuccin" ;;
  Tokyo*)       THEME="tokyo" ;;
  Solarized*)   THEME="solarized" ;;
  *)            THEME="classic" ;;
esac

DO_NODE=true
if ! ask_yn "Install Node.js via nvm? (required for TypeScript/Python/Bash LSP servers)" y; then
  DO_NODE=false
fi
echo

SET_EDITOR=true
if ! ask_yn "Set nvim as \$EDITOR and \$VISUAL?" y; then
  SET_EDITOR=false
fi
echo

ADD_ALIASES=true
if ! ask_yn "Add vi/vim → nvim aliases?" y; then
  ADD_ALIASES=false
fi
echo

DO_COPILOT=false
if ask_yn "Install GitHub Copilot plugin? (requires a Copilot subscription)" n; then
  DO_COPILOT=true
fi
echo

DO_LAZYGIT=false
if ask_yn "Install LazyGit integration? (beautiful TUI git client)" n; then
  DO_LAZYGIT=true
fi
echo

divider
say "Summary"
echo -e "  Theme             : ${BOLD}$THEME_LABEL${RESET}"
echo -e "  Install Node.js   : ${BOLD}$DO_NODE${RESET}"
echo -e "  Set as \$EDITOR    : ${BOLD}$SET_EDITOR${RESET}"
echo -e "  vi/vim aliases    : ${BOLD}$ADD_ALIASES${RESET}"
echo -e "  Copilot plugin    : ${BOLD}$DO_COPILOT${RESET}"
echo -e "  LazyGit           : ${BOLD}$DO_LAZYGIT${RESET}"
divider
echo
echo -e "  ${DIM}LSPs installed on first nvim launch via Mason:${RESET}"
echo -e "  Python (pyright + ruff), TypeScript (tsserver), Lua (lua_ls), Bash (bashls)"
echo

if ! $DRY_RUN; then
  if ! ask_yn "Proceed and write files?" y; then echo "Aborted."; exit 0; fi
fi
echo

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"
OUTDIR="$HOME/.config/dev-setup"
mkdir -p "$OUTDIR"

# ═══════════════════════════════════════════════════════════════════════════════
# Tool installs
# ═══════════════════════════════════════════════════════════════════════════════
say "Installing tools"
echo

# ── Neovim ────────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}neovim${RESET} (text editor)... "
if command -v nvim &>/dev/null; then
  install_skip "$(nvim --version 2>/dev/null | head -1)"
elif $DRY_RUN; then
  install_dry "neovim"
else
  NV_TAG=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  ARCH=$(uname -m)
  if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    NV_ASSET="nvim-linux-arm64"
  else
    NV_ASSET="nvim-linux-x86_64"
  fi
  NV_URL="https://github.com/neovim/neovim/releases/download/${NV_TAG}/${NV_ASSET}.tar.gz"
  if curl -fsSL "$NV_URL" | tar -xz -C "$HOME/.local" --strip-components=1 2>/dev/null; then
    install_ok "installed ${NV_TAG}"
  else
    install_fail "neovim" "see https://github.com/neovim/neovim/releases"
  fi
fi

# ── Node.js via nvm ───────────────────────────────────────────────────────────
if $DO_NODE; then
  echo -en "  ${BOLD}nvm + Node.js LTS${RESET} (required for LSP servers)... "
  if [[ -d "$HOME/.nvm" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.nvm/nvm.sh" 2>/dev/null || true
    if command -v node &>/dev/null; then
      install_skip "node $(node --version 2>/dev/null)"
    elif $DRY_RUN; then
      install_dry "node LTS"
    else
      nvm install --lts >/dev/null 2>&1 && nvm use --lts >/dev/null 2>&1
      install_ok "node $(node --version 2>/dev/null)"
    fi
  elif $DRY_RUN; then
    install_dry "nvm + node LTS"
  else
    if curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash >/dev/null 2>&1; then
      export NVM_DIR="$HOME/.nvm"
      # shellcheck disable=SC1090
      source "$NVM_DIR/nvm.sh" 2>/dev/null
      nvm install --lts >/dev/null 2>&1 && nvm use --lts >/dev/null 2>&1
      install_ok "nvm + node $(node --version 2>/dev/null)"
    else
      install_fail "nvm" "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash"
    fi
  fi
fi

# ── neovim npm package (required by LSP providers) ───────────────────────────
if $DO_NODE; then
  echo -en "  ${BOLD}neovim npm package${RESET} (LSP provider)... "
  if npm list -g neovim &>/dev/null 2>&1; then
    install_skip "neovim npm package"
  elif $DRY_RUN; then
    install_dry "neovim (npm)"
  else
    if npm install -g neovim >/dev/null 2>&1; then
      install_ok "installed"
    else
      install_fail "neovim (npm)" "npm install -g neovim"
    fi
  fi
fi

# ── ripgrep ───────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}ripgrep${RESET} (fast grep, used by Telescope)... "
if command -v rg &>/dev/null; then
  install_skip "$(rg --version 2>/dev/null | head -1)"
elif $DRY_RUN; then
  install_dry "ripgrep"
else
  if sudo apt-get install -y ripgrep >/dev/null 2>&1; then
    install_ok "installed via apt"
  else
    install_fail "ripgrep" "sudo apt install ripgrep"
  fi
fi

# ── fd-find ───────────────────────────────────────────────────────────────────
echo -en "  ${BOLD}fd${RESET} (fast find, used by Telescope)... "
if command -v fd &>/dev/null || command -v fdfind &>/dev/null; then
  install_skip "$(fd --version 2>/dev/null || fdfind --version 2>/dev/null | head -1)"
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    if ! $DRY_RUN; then
      ln -sf "$(command -v fdfind)" "$INSTALL_DIR/fd"
      ok "Symlinked fdfind → $INSTALL_DIR/fd"
    fi
  fi
elif $DRY_RUN; then
  install_dry "fd-find"
else
  if sudo apt-get install -y fd-find >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "$INSTALL_DIR/fd" 2>/dev/null || true
    install_ok "installed via apt (symlinked as fd)"
  else
    install_fail "fd-find" "sudo apt install fd-find"
  fi
fi

# ── LazyGit ───────────────────────────────────────────────────────────────────
if $DO_LAZYGIT; then
  echo -en "  ${BOLD}lazygit${RESET} (TUI git client)... "
  if command -v lazygit &>/dev/null; then
    install_skip "$(lazygit --version 2>/dev/null | head -1)"
  elif $DRY_RUN; then
    install_dry "lazygit"
  else
    LG_TAG=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4)
    LG_VER="${LG_TAG#v}"
    LG_URL="https://github.com/jesseduffield/lazygit/releases/download/${LG_TAG}/lazygit_${LG_VER}_Linux_x86_64.tar.gz"
    if curl -fsSL "$LG_URL" | tar -xz -C "$INSTALL_DIR" lazygit 2>/dev/null; then
      install_ok "installed ${LG_TAG}"
    else
      install_fail "lazygit" "https://github.com/jesseduffield/lazygit/releases"
    fi
  fi
fi

# ── lazygit + delta config ────────────────────────────────────────────────────
# Wire delta as lazygit's diff pager so diffs inside lazygit get the same
# syntax highlighting and side-by-side layout as plain `git diff`.
if $DO_LAZYGIT && command -v delta &>/dev/null; then
  LAZYGIT_CONFIG='git:
  paging:
    colorArg: always
    pager: delta --paging=never --side-by-side --line-numbers
'
  if ! $DRY_RUN; then
    mkdir -p "$HOME/.config/lazygit"
    write_file "$HOME/.config/lazygit/config.yml" "$LAZYGIT_CONFIG"
  else
    info "[dry-run] would write ~/.config/lazygit/config.yml"
  fi
fi
echo -en "  ${BOLD}delta${RESET} (git diff pager)... "
if command -v delta &>/dev/null; then
  install_skip "$(delta --version 2>/dev/null)"
elif $DRY_RUN; then
  install_dry "delta"
else
  DELTA_TAG=$(curl -fsSL https://api.github.com/repos/dandavison/delta/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  DELTA_VER="${DELTA_TAG#v}"
  DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_TAG}/delta-${DELTA_VER}-x86_64-unknown-linux-musl.tar.gz"
  if curl -fsSL "$DELTA_URL" | tar -xz --strip-components=1 -C "$INSTALL_DIR" \
      "delta-${DELTA_VER}-x86_64-unknown-linux-musl/delta" 2>/dev/null; then
    install_ok "installed ${DELTA_TAG}"
  else
    install_fail "delta" "https://github.com/dandavison/delta/releases"
  fi
fi

echo

# ═══════════════════════════════════════════════════════════════════════════════
# Neovim config (~/.config/nvim)
# ═══════════════════════════════════════════════════════════════════════════════
say "Writing Neovim config (~/.config/nvim)"

if ! $DRY_RUN; then
  NVIM_CONF="$HOME/.config/nvim"
  if [[ -d "$NVIM_CONF" ]] && [[ -n "$(ls -A "$NVIM_CONF" 2>/dev/null)" ]]; then
    BACKUP_DIR="${NVIM_CONF}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$NVIM_CONF" "$BACKUP_DIR"
    warn "Backed up existing ~/.config/nvim → $BACKUP_DIR"
  fi
  mkdir -p "$HOME/.config/nvim/lua/config" "$HOME/.config/nvim/lua/plugins"
else
  echo -e "    ${DIM}[dry-run] would backup and recreate ~/.config/nvim/${RESET}"
fi

# ── init.lua ──────────────────────────────────────────────────────────────────
INIT_LUA='-- Entry point. All config lives in lua/config/ and lua/plugins/.
require("config.lazy")
'
write_file "$HOME/.config/nvim/init.lua" "$INIT_LUA"

# ── lua/config/lazy.lua ───────────────────────────────────────────────────────
LAZY_LUA='-- Bootstrap lazy.nvim (auto-clones on first launch)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n" .. out, "ErrorMsg" } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim base: loads all default plugins and settings
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Language extras (treesitter grammars + LSP defaults)
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    -- Our custom plugin overrides
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
'
write_file "$HOME/.config/nvim/lua/config/lazy.lua" "$LAZY_LUA"

# ── lua/config/options.lua ────────────────────────────────────────────────────
IS_WSL=false
grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=true

if $IS_WSL; then
  CLIPBOARD_BLOCK='-- WSL clipboard: copy via clip.exe, paste via powershell
vim.g.clipboard = {
  name = "WslClipboard",
  copy  = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
  paste = {
    ["+"] = "powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace(\"`r\", \"\"))",
    ["*"] = "powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace(\"`r\", \"\"))",
  },
  cache_enabled = 0,
}'
else
  CLIPBOARD_BLOCK='vim.opt.clipboard = "unnamedplus"'
fi

OPTIONS_LUA="-- Editor options
local opt = vim.opt

-- Line numbers: absolute on current line, relative above/below (great for jumps)
opt.number         = true
opt.relativenumber = true

-- Indentation (2-space; LSP/treesitter overrides per filetype)
opt.tabstop        = 2
opt.shiftwidth     = 2
opt.expandtab      = true
opt.smartindent    = true

-- Splits: open right and below (matches VSCode defaults)
opt.splitright     = true
opt.splitbelow     = true

-- Keep context lines visible when scrolling
opt.scrolloff      = 8
opt.sidescrolloff  = 8

-- Snappy which-key popup
opt.timeoutlen     = 300

-- No swap, but keep persistent undo history across sessions
opt.swapfile       = false
opt.undofile       = true

-- Case-insensitive search unless you type a capital letter
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = true

-- Appearance
opt.termguicolors  = true
opt.signcolumn     = \"yes\"        -- always show gutter (git signs, diagnostics)
opt.cursorline     = true          -- highlight current line
opt.wrap           = false
opt.showmode       = false         -- lualine shows the mode already

-- Folding via treesitter (all folds open by default)
opt.foldmethod     = \"expr\"
opt.foldexpr       = \"nvim_treesitter#foldexpr()\"
opt.foldenable     = false
opt.foldlevel      = 99

-- Completion popup
opt.completeopt    = \"menu,menuone,noselect\"
opt.pumheight      = 10

-- Show invisible characters subtly
opt.list           = true
opt.listchars      = { tab = \"» \", trail = \"·\", nbsp = \"␣\" }

opt.updatetime     = 200

$CLIPBOARD_BLOCK
"
write_file "$HOME/.config/nvim/lua/config/options.lua" "$OPTIONS_LUA"

# ── lua/config/keymaps.lua ────────────────────────────────────────────────────
if $DO_LAZYGIT; then
  LAZYGIT_KEYMAP='
-- LazyGit
map("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })'
else
  LAZYGIT_KEYMAP=''
fi

KEYMAPS_LUA="-- Keymaps — VSCode-familiar bindings layered on LazyVim defaults
local map = vim.keymap.set

-- ── File operations ──────────────────────────────────────────────────────────
map({ \"n\", \"i\", \"v\" }, \"<C-s>\", \"<cmd>w<cr><esc>\", { desc = \"Save file\" })

-- ── Buffer navigation (like VSCode tabs) ─────────────────────────────────────
map(\"n\", \"<S-h>\", \"<cmd>bprevious<cr>\", { desc = \"Prev buffer\" })
map(\"n\", \"<S-l>\", \"<cmd>bnext<cr>\",     { desc = \"Next buffer\" })
map(\"n\", \"<leader>q\", \"<cmd>bd<cr>\",    { desc = \"Close buffer\" })

-- ── File picker / search ─────────────────────────────────────────────────────
map(\"n\", \"<C-p>\", \"<cmd>Telescope find_files<cr>\", { desc = \"Find files (Ctrl+P)\" })
map(\"n\", \"<C-S-p>\", \"<cmd>Telescope commands<cr>\",  { desc = \"Commands palette\" })
map(\"n\", \"<leader>/\", \"<cmd>Telescope live_grep<cr>\",  { desc = \"Search in files\" })
map(\"n\", \"<leader>f/\", \"<cmd>Telescope current_buffer_fuzzy_find<cr>\", { desc = \"Fuzzy find in buffer\" })

-- ── File tree (<Space>e — Ctrl+B conflicts with tmux prefix) ─────────────────
map(\"n\", \"<leader>e\", \"<cmd>Neotree toggle<cr>\", { desc = \"Toggle file tree\" })

-- ── LSP actions (F-keys like VSCode) ─────────────────────────────────────────
map(\"n\", \"<F12>\",   vim.lsp.buf.definition,      { desc = \"Go to definition\" })
map(\"n\", \"<S-F12>\", vim.lsp.buf.references,       { desc = \"Find references\" })
map(\"n\", \"<F2>\",    vim.lsp.buf.rename,            { desc = \"Rename symbol\" })
map({ \"n\", \"v\" }, \"<C-.>\", vim.lsp.buf.code_action, { desc = \"Code actions\" })

-- ── Clear search highlight ────────────────────────────────────────────────────
map(\"n\", \"<Esc>\", \"<cmd>nohlsearch<cr>\", { desc = \"Clear search\" })

-- ── Close special panels with q (Lazy, Mason, help, quickfix, etc.) ──────────
vim.api.nvim_create_autocmd(\"FileType\", {
  pattern = { \"lazy\", \"mason\", \"help\", \"qf\", \"lspinfo\", \"checkhealth\", \"notify\" },
  callback = function(event)
    vim.keymap.set(\"n\", \"q\", \"<cmd>close<cr>\",
      { buffer = event.buf, silent = true, desc = \"Close panel\" })
  end,
})

-- ── File path copy ───────────────────────────────────────────────────────────
map(\"n\", \"<leader>cp\", function() vim.fn.setreg(\"+\", vim.fn.expand(\"%:p\")) end, { desc = \"Copy absolute path\" })
map(\"n\", \"<leader>cr\", function() vim.fn.setreg(\"+\", vim.fn.expand(\"%:.\")) end,  { desc = \"Copy relative path\" })
map(\"n\", \"<leader>cf\", function() vim.fn.setreg(\"+\", vim.fn.expand(\"%:t\")) end,  { desc = \"Copy filename\" })
$LAZYGIT_KEYMAP
"
write_file "$HOME/.config/nvim/lua/config/keymaps.lua" "$KEYMAPS_LUA"

# ── lua/plugins/colorscheme.lua ───────────────────────────────────────────────
case "$THEME" in
  tokyo)
    COLORSCHEME_LUA='return {
  {
    "folke/tokyonight.nvim",
    lazy     = false,
    priority = 1000,
    opts = {
      style       = "night",
      transparent = false,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
      },
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight" } },
}
'
    ;;
  catppuccin)
    COLORSCHEME_LUA='return {
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    lazy     = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      integrations = {
        bufferline = true,
        cmp        = true,
        gitsigns   = true,
        neotree    = true,
        telescope  = { enabled = true },
        treesitter = true,
        which_key  = true,
        mason      = true,
      },
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
'
    ;;
  nord)
    COLORSCHEME_LUA='return {
  {
    "gbprod/nord.nvim",
    lazy     = false,
    priority = 1000,
    opts = {
      transparent = false,
      diff        = { mode = "bg" },
      borders     = true,
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "nord" } },
}
'
    ;;
  solarized)
    COLORSCHEME_LUA='return {
  {
    "ishan9299/nvim-solarized-lua",
    lazy     = false,
    priority = 1000,
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "solarized" } },
}
'
    ;;
  *)
    COLORSCHEME_LUA='-- Classic: no custom colorscheme, LazyVim default applies
return {}
'
    ;;
esac

write_file "$HOME/.config/nvim/lua/plugins/colorscheme.lua" "$COLORSCHEME_LUA"

# ── lua/plugins/ui.lua — VSCode-like layout ───────────────────────────────────
# neo-tree: open on startup (left sidebar, like VSCode explorer)
# bufferline: tabs across the top (like VSCode editor tabs)
# lualine: status bar at the bottom
UI_LUA='return {
  -- File explorer: open on the left by default, like VSCode
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        position = "left",
        width    = 30,
      },
      filesystem = {
        filtered_items = {
          visible        = false,
          hide_dotfiles  = false,  -- show .env, .gitignore etc
          hide_gitignored = true,
        },
        follow_current_file = { enabled = true },  -- auto-reveal open file
      },
      -- Close neo-tree when opening a file (feels more like VSCode)
      event_handlers = {
        {
          event = "file_opened",
          handler = function()
            require("neo-tree.command").execute({ action = "close" })
          end,
        },
      },
    },
  },

  -- Open neo-tree automatically when nvim opens a directory
  {
    "LazyVim/LazyVim",
    opts = {
      -- Show a dashboard only when nvim is opened with no file argument
    },
  },

  -- Buffer tabs at the top (like VSCode editor tabs)
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        mode             = "buffers",
        numbers          = "none",
        close_command    = "bdelete! %d",
        diagnostics      = "nvim_lsp",   -- show error/warning icons on tabs
        show_buffer_close_icons = true,
        show_close_icon  = false,
        separator_style  = "thin",
        always_show_bufferline = true,
        offsets = {
          {
            filetype   = "neo-tree",
            text       = "  Explorer",
            highlight  = "Directory",
            separator  = true,
          },
        },
      },
    },
  },

  -- Scrollbar with git changes, diagnostics, and search marks (like VSCode)
  {
    "lewis6991/satellite.nvim",
    event = "BufReadPost",
    opts = {
      current_only = false,
      winblend     = 50,
      handlers = {
        cursor      = { enable = true },
        gitsigns    = { enable = true },
        diagnostic  = { enable = true },
        search      = { enable = true },
      },
    },
  },

  -- Status bar at the bottom
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme            = "auto",
        globalstatus     = true,
        section_separators   = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },  -- show relative path
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
}
'
write_file "$HOME/.config/nvim/lua/plugins/ui.lua" "$UI_LUA"

# ── lua/plugins/lsp.lua ───────────────────────────────────────────────────────
LSP_LUA='return {
  -- Mason: installs and manages LSP servers, formatters, linters
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "black", "isort", "prettier", "stylua", "shfmt",
        "ruff", "eslint_d", "shellcheck",
      },
    },
  },

  -- Bridge between Mason and lspconfig (auto-installs servers)
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_installation = true,
      ensure_installed = {
        "pyright",  -- Python type checking
        "ruff_lsp", -- Python fast linting
        "lua_ls",   -- Lua (editing nvim config)
        "bashls",   -- Bash
        -- ts_ls replaced by typescript-tools.nvim (faster, own LSP engine)
      },
    },
  },

  -- LSP server option overrides
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Show diagnostic inline (like VSCode squiggles)
      diagnostics = {
        virtual_text = { prefix = "●" },
        signs        = true,
        underline    = true,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      },
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode       = "basic",
                autoSearchPaths        = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace   = { checkThirdParty = false },
              telemetry   = { enable = false },
            },
          },
        },
      },
    },
  },

  -- Format on save
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = {
        timeout_ms   = 3000,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        python          = { "isort", "black" },
        javascript      = { "prettier" },
        typescript      = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json            = { "prettier" },
        markdown        = { "prettier" },
        lua             = { "stylua" },
        sh              = { "shfmt" },
        bash            = { "shfmt" },
      },
    },
  },

  -- Lint on write / read
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python          = { "ruff" },
        javascript      = { "eslint_d" },
        typescript      = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        sh              = { "shellcheck" },
        bash            = { "shellcheck" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function() lint.try_lint() end,
      })
    end,
  },
}
'
write_file "$HOME/.config/nvim/lua/plugins/lsp.lua" "$LSP_LUA"

# ── lua/plugins/tools.lua ─────────────────────────────────────────────────────
if $DO_LAZYGIT; then
  LAZYGIT_SPEC='
  -- LazyGit TUI inside Neovim (<Space>gg)
  {
    "kdheepak/lazygit.nvim",
    cmd          = { "LazyGit", "LazyGitConfig" },
    dependencies = { "nvim-lua/plenary.nvim" },
  },'
else
  LAZYGIT_SPEC=''
fi

if $DO_COPILOT; then
  COPILOT_SPEC='
  -- GitHub Copilot — run :Copilot setup on first use
  {
    "zbirenbaum/copilot.lua",
    cmd   = "Copilot",
    event = "InsertEnter",
    opts  = {
      suggestion = { enabled = false },
      panel      = { enabled = false },
    },
  },
  {
    "zbirenbaum/copilot-cmp",
    config = function() require("copilot_cmp").setup() end,
  },'
else
  COPILOT_SPEC=''
fi

TOOLS_LUA="return {
  -- Split terminal: <C-t>
  {
    \"akinsho/toggleterm.nvim\",
    version = \"*\",
    keys = {
      { \"<C-t>\", \"<cmd>ToggleTerm direction=horizontal<cr>\", desc = \"Toggle terminal\" },
    },
    opts = {
      size            = 15,
      shade_terminals = false,
      start_in_insert = true,
    },
  },

  -- Fuzzy finder: Telescope
  {
    \"nvim-telescope/telescope.nvim\",
    opts = {
      defaults = {
        file_ignore_patterns = {
          \"node_modules/\", \".git/\", \"__pycache__/\",
          \"dist/\", \".next/\", \".expo/\", \"%.lock\",
        },
        -- Ctrl+J/K to move inside picker (in addition to arrow keys)
        mappings = {
          i = {
            [\"<C-j>\"] = \"move_selection_next\",
            [\"<C-k>\"] = \"move_selection_previous\",
          },
        },
        layout_config = { horizontal = { preview_width = 0.55 } },
      },
    },
  },

  -- Treesitter: syntax highlight + code-aware features
  {
    \"nvim-treesitter/nvim-treesitter\",
    opts = {
      ensure_installed = {
        \"python\", \"typescript\", \"tsx\", \"javascript\",
        \"lua\", \"bash\", \"json\", \"markdown\", \"markdown_inline\",
        \"yaml\", \"html\", \"css\",
      },
      highlight    = { enable = true },
      indent       = { enable = true },
      auto_install = true,
    },
  },
$LAZYGIT_SPEC
$COPILOT_SPEC
}
"
write_file "$HOME/.config/nvim/lua/plugins/tools.lua" "$TOOLS_LUA"

# ── lua/plugins/neo-tree-autoopen.lua ─────────────────────────────────────────
# Open neo-tree sidebar automatically when nvim starts with no file argument,
# then focus the main editor window (mirrors VSCode's startup layout).
AUTOOPEN_LUA='-- Open file explorer on startup when nvim is launched with no file argument.
-- Must return a plugin spec table so lazy.nvim can load it correctly.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          if vim.fn.argc() == 0 then
            vim.defer_fn(function()
              require("neo-tree.command").execute({ action = "show", position = "left" })
              vim.cmd("wincmd p")  -- move focus back to editor
            end, 100)
          end
        end,
      })
    end,
  },
}
'
write_file "$HOME/.config/nvim/lua/plugins/neo-tree-autoopen.lua" "$AUTOOPEN_LUA"

# ── lua/plugins/extras.lua ────────────────────────────────────────────────────
EXTRAS_LUA='return {
  -- Render markdown in-buffer: headings, bold, tables, code blocks
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {
      enabled      = true,
      render_modes = { "n", "c" },
      heading = { enabled = true },
      code    = { enabled = true, style = "full" },
      bullet  = { enabled = true },
    },
  },

  -- Live markdown preview in the browser (WSL: opens in Windows default browser)
  {
    "iamcco/markdown-preview.nvim",
    cmd   = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft    = { "markdown" },
    build = "cd app && npx --yes yarn install",
    keys  = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown preview (browser)" },
    },
    init = function()
      vim.g.mkdp_browser    = "explorer.exe"  -- WSL: open in Windows default browser
      vim.g.mkdp_auto_close = 1               -- close browser tab when leaving buffer
      vim.g.mkdp_refresh_slow = 0             -- live sync
    end,
  },

  -- Auto-close brackets, parens, quotes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts  = {
      check_ts         = true,
      disable_filetype = { "TelescopePrompt" },
    },
  },

  -- Add/change/delete surrounding brackets/quotes: cs"'"'"' ds( ysiw)
  {
    "kylechui/nvim-surround",
    version = "*",
    event   = "VeryLazy",
    opts    = {},
  },

  -- Highlight and list TODO / FIXME / HACK / NOTE comments
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event        = "VeryLazy",
    opts         = { signs = true },
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
      { "]t",  function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t",  function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
    },
  },

  -- Pick Python virtualenv from inside Neovim
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
    ft   = "python",
    opts = { auto_refresh = true },
    keys = {
      { "<leader>vs", "<cmd>VenvSelect<cr>",        desc = "Select venv" },
      { "<leader>vc", "<cmd>VenvSelectCurrent<cr>",  desc = "Show current venv" },
    },
  },

  -- Better diagnostics panel
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { use_diagnostic_signs = true },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                        desc = "Diagnostics (project)" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",           desc = "Diagnostics (buffer)" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>",                desc = "Symbols" },
      { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP definitions" },
    },
  },

  -- Edit filesystem like a buffer
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = false,
      view_options = { show_hidden = true },
    },
    keys = {
      { "<leader>o", "<cmd>Oil<cr>", desc = "Oil file browser" },
    },
  },

  -- Side-by-side git diff viewer
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd  = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gD", "<cmd>DiffviewOpen<cr>",          desc = "Diff view" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>",  desc = "File git history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>",    desc = "Repo git history" },
      { "<leader>gx", "<cmd>DiffviewClose<cr>",          desc = "Close diff view" },
    },
  },

  -- Faster TypeScript / React Native LSP (replaces ts_ls)
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    ft  = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints        = "all",
          includeInlayFunctionReturnTypeHints   = true,
        },
      },
    },
  },

  -- Claude Code IDE integration (context tracking, diffs, selection send)
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    event = "VeryLazy",
    config = true,
    keys = {
      { "<leader>cc", "<cmd>ClaudeCode<cr>",            desc = "Claude Code (toggle)" },
      { "<leader>cS", "<cmd>ClaudeCodeSend<cr>",        mode = "v", desc = "Claude send selection" },
      { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Claude add buffer" },
      { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Claude accept diff" },
      { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Claude reject diff" },
    },
  },
}
'
write_file "$HOME/.config/nvim/lua/plugins/extras.lua" "$EXTRAS_LUA"

# ═══════════════════════════════════════════════════════════════════════════════
# Reference guide (~/.config/nvim/GUIDE.md)
# ═══════════════════════════════════════════════════════════════════════════════
say "Writing reference guide (~/.config/nvim/GUIDE.md)"

GUIDE_MD="$(cat "$SCRIPT_DIR/docs/neovim-guide.md")"
write_file "$HOME/.config/nvim/GUIDE.md" "$GUIDE_MD"

# ═══════════════════════════════════════════════════════════════════════════════
# Shell config snippet
# ═══════════════════════════════════════════════════════════════════════════════
say "Shell config ($OUTDIR/bashrc_neovim.sh)"

EDITOR_BLOCK=""
if $SET_EDITOR; then
  EDITOR_BLOCK='
# ── nvim as default editor ────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"'
fi

ALIAS_BLOCK=""
if $ADD_ALIASES; then
  ALIAS_BLOCK='
# ── nvim aliases ──────────────────────────────────────────────────────────────
alias vi="nvim"
alias vim="nvim"'
fi

BASHRC_NEOVIM="# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Neovim setup snippet — sourced from ~/.bashrc
# Edit this file directly; changes take effect on next shell open.
# Generated by neovim-wizard.sh
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── PATH: nvim lives in ~/.local/bin ─────────────────────────────────────────
pathadd() { [[ \":\$PATH:\" != *\":\$1:\"* ]] && export PATH=\"\$1:\$PATH\"; }
pathadd \"\$HOME/.local/bin\"
$EDITOR_BLOCK
$ALIAS_BLOCK

# ── nvm (Node.js version manager) ─────────────────────────────────────────────
export NVM_DIR=\"\$HOME/.nvm\"
[[ -s \"\$NVM_DIR/nvm.sh\" ]] && source \"\$NVM_DIR/nvm.sh\"
[[ -s \"\$NVM_DIR/bash_completion\" ]] && source \"\$NVM_DIR/bash_completion\"

# ── ccnvim: cd to project, activate venv, open in nvim ───────────────────────
# Usage: ccnvim my-project    (uses WORKSPACE_ROOT from shell-wizard)
ccnvim() {
  local base=\"\${WORKSPACE_ROOT:-\$HOME/github}\"
  if [[ -z \"\${1:-}\" ]]; then
    { _cc_venv 2>/dev/null || true; }
    nvim .
    return
  fi
  local dir=\"\$base/\$1\"
  if [[ ! -d \"\$dir\" ]]; then
    echo \"Not found: \$dir\"
    echo \"Projects:\"; ls -1 \"\$base\" 2>/dev/null
    return 1
  fi
  cd \"\$dir\" && { _cc_venv 2>/dev/null || true; } && nvim .
}

_ccnvim_complete() {
  local base=\"\${WORKSPACE_ROOT:-\$HOME/github}\"
  COMPREPLY=(\$(compgen -W \"\$(ls -1 \"\$base\" 2>/dev/null)\" -- \"\${COMP_WORDS[COMP_CWORD]}\"))
}
complete -F _ccnvim_complete ccnvim
"
write_file "$OUTDIR/bashrc_neovim.sh" "$BASHRC_NEOVIM"

# ── Wire into ~/.bashrc ───────────────────────────────────────────────────────
say "Wiring into ~/.bashrc"

MARKER="# >>> neovim-setup <<<"
BASHRC_LINE="
$MARKER
[[ -f \"\$HOME/.config/dev-setup/bashrc_neovim.sh\" ]] && source \"\$HOME/.config/dev-setup/bashrc_neovim.sh\"
# <<< neovim-setup >>>
"
append_if_missing "$HOME/.bashrc" "$MARKER" "$BASHRC_LINE"

echo

# ═══════════════════════════════════════════════════════════════════════════════
# Nerd Font — compute Windows path to the repo script for the done message
# ═══════════════════════════════════════════════════════════════════════════════
FONT_SCRIPT_WIN="$(wslpath -w "$SCRIPT_DIR/install-nerd-font.ps1" 2>/dev/null)" || FONT_SCRIPT_WIN='<repo>\install-nerd-font.ps1'

# ═══════════════════════════════════════════════════════════════════════════════
# Done
# ═══════════════════════════════════════════════════════════════════════════════
divider
say "Done"
divider
echo
echo -e "  ${BOLD}Files written:${RESET}"
echo -e "    ${GREEN}~/.config/nvim/init.lua${RESET}"
echo -e "    ${GREEN}~/.config/nvim/lua/config/{lazy,options,keymaps}.lua${RESET}"
echo -e "    ${GREEN}~/.config/nvim/lua/plugins/{colorscheme,ui,lsp,tools,extras}.lua${RESET}"
echo -e "    ${GREEN}~/.config/nvim/lua/plugins/neo-tree-autoopen.lua${RESET}"
echo -e "    ${GREEN}~/.config/nvim/GUIDE.md${RESET}  ← reference guide"
echo -e "    ${GREEN}~/.config/dev-setup/bashrc_neovim.sh${RESET}"
echo
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "    1.  ${CYAN}source ~/.bashrc${RESET}"
echo -e "    2.  ${CYAN}nvim${RESET}                       first launch (~2 min to download plugins)"
echo -e "    3.  ${CYAN}:checkhealth${RESET}               inside nvim — diagnose any issues"
echo -e "    4.  ${CYAN}:Mason${RESET}                     inside nvim — confirm LSPs installed"
$DO_COPILOT && \
  echo -e "    5.  ${CYAN}:Copilot setup${RESET}             inside nvim — authenticate Copilot"
echo
echo -e "  ${BOLD}${YELLOW}Icons look broken? Install the Nerd Font on Windows:${RESET}"
echo -e "    1.  Open ${CYAN}PowerShell${RESET} (Windows, not WSL)"
echo -e "    2.  Run:  ${CYAN}Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned${RESET}"
echo -e "    3.  Run:  ${CYAN}${FONT_SCRIPT_WIN}${RESET}"
echo -e "    4.  In Windows Terminal → your WSL profile → Appearance → Font face:"
echo -e "        set to ${CYAN}JetBrainsMono Nerd Font Mono${RESET} and restart the terminal"
echo
echo -e "  ${BOLD}Key bindings quick reference:${RESET}"
echo -e "    ${CYAN}Ctrl+P${RESET}         Find file                   ${DIM}(like VSCode)${RESET}"
echo -e "    ${CYAN}Space+/${RESET}        Search in files             ${DIM}(live grep)${RESET}"
echo -e "    ${CYAN}Space+e${RESET}        Toggle file explorer         ${DIM}(Space then e)${RESET}"
echo -e "    ${CYAN}Ctrl+T${RESET}         Toggle terminal (split)      ${DIM}(like VSCode)${RESET}"
echo -e "    ${CYAN}Space cc${RESET}       Toggle Claude Code (context-aware)"
echo -e "    ${CYAN}Space cS${RESET}       Send selection to Claude     ${DIM}(Visual mode)${RESET}"
echo -e "    ${CYAN}Space cb${RESET}       Add current buffer to Claude"
echo -e "    ${CYAN}Space ca${RESET}       Accept Claude diff"
echo -e "    ${CYAN}Space cd${RESET}       Reject Claude diff"
echo -e "    ${CYAN}F12${RESET}            Go to definition"
echo -e "    ${CYAN}F2${RESET}             Rename symbol"
echo -e "    ${CYAN}Ctrl+.${RESET}         Code actions"
echo -e "    ${CYAN}K${RESET}              Hover documentation"
echo -e "    ${CYAN}Space${RESET}          Command palette (wait 300ms)"
echo -e "    ${CYAN}Esc${RESET}            Return to Normal mode (always safe)"
echo
echo -e "  ${BOLD}Full guide:${RESET}"
echo -e "    ${CYAN}nvim ~/.config/nvim/GUIDE.md${RESET}"
echo
echo -e "  ${DIM}Backups: any overwritten file/dir → <original>.bak.TIMESTAMP${RESET}"
divider
echo
