#!/usr/bin/env bash
set -e

echo "========================================"
echo " 🧩 Linux Development Environment Setup "
echo "========================================"

# 1. 필수 패키지 설치
echo "[1/7] Installing essential packages..."
sudo apt update -y
sudo apt install -y git curl wget tmux build-essential clang clangd xz-utils neovim

# 2. tmux 설정
echo "[2/7] Setting up tmux configuration..."
cat > ~/.tmux.conf << 'EOF'
# --- Basic tmux configuration ---
set -g default-terminal "screen-256color"
set -sg escape-time 10
set -g focus-events on
setw -g mode-keys vi
EOF
echo "tmux configuration applied."

# 3. Neovim 기본 설정
echo "[3/7] Setting up basic Neovim configuration..."
mkdir -p ~/.config/nvim
cat > ~/.config/nvim/init.vim << 'EOF'
" --- Basic Neovim configuration ---
set nocompatible
set number
set smartindent
set tabstop=4
set expandtab
set shiftwidth=4
syntax on
EOF
echo "Neovim configuration applied."

# 4. clangd 설정
echo "[4/7] Configuring clangd..."
if ! command -v clangd &> /dev/null; then
	    echo "clangd not found. Installing..."
	        sudo apt install -y clangd
fi

# clangd symlink 보정 (버전별 이름 문제 방지)
if [ ! -f /usr/bin/clangd ]; then
	    sudo ln -s $(which clangd-14 || which clangd-15 || which clangd-16) /usr/bin/clangd || true
fi

# Neovim LSP 설정 파일 (선택적)
mkdir -p ~/.config/nvim/lua
cat > ~/.config/nvim/lua/clangd_setup.lua << 'EOF'
-- clangd LSP auto setup (requires nvim-lspconfig)
local ok, lspconfig = pcall(require, "lspconfig")
if ok then
  lspconfig.clangd.setup {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_dir = lspconfig.util.root_pattern("compile_commands.json", ".git"),
    on_attach = function(client, bufnr)
      -- Key mappings for clangd LSP
      local opts = { noremap=true, silent=true, buffer=bufnr }
      
      -- Go to definition
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      -- Go to declaration
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
      -- Show hover information
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      -- Go to implementation
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
      -- Show signature help
      vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
      -- Rename symbol
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
      -- Code action
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
      -- Find references
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
      -- Format code
      vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
      -- Show diagnostics
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
      -- Go to previous diagnostic
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
      -- Go to next diagnostic
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    end,
  }
end
EOF
echo "clangd configured for Neovim with key bindings."

# 5. Bash 프롬프트 (2줄 + 색상)
echo "[5/7] Customizing colorful two-line Bash prompt..."
cat >> ~/.bashrc << 'EOF'

# --- Custom colorful two-line prompt ---
if [ "$PS1" ]; then
  GREEN="\[\033[0;32m\]"
  BLUE="\[\033[0;34m\]"
  GRAY="\[\033[0;37m\]"
  RESET="\[\033[0m\]"

  PS1="${GREEN}[\u${RESET}@${BLUE}\h${RESET}:${GRAY}\w${GREEN}]${RESET}\n$ "
fi
EOF
echo "Colorful two-line prompt applied (reload with 'source ~/.bashrc')."

# 6. Git 전역 설정
echo "[6/7] Setting up Git global configuration..."
git config --global alias.sts 'status -s'
git config --global alias.graph 'log --oneline --graph --all'
git config --global user.email 'wjsalswns0733@gmail.com'
git config --global user.name 'jmj073'

echo "Git aliases and user info configured."
echo "  - git sts   → short status"
echo "  - git graph → oneline commit graph"

# 7. 버전 확인
echo "[7/7] Verifying installations..."
echo "git:     $(git --version)"
echo "tmux:    $(tmux -V)"
echo "nvim:    $(nvim --version | head -n 1)"
echo "clangd:  $(clangd --version | head -n 1)"

echo "======================================"
echo " ✅ Setup Complete!"
echo "======================================"
echo "👉 Run 'tmux' to start a session."
echo "👉 Run 'nvim' to launch Neovim."
echo "👉 Run 'source ~/.bashrc' to apply the new prompt."
