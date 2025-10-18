-- 基本设置
vim.opt.number = true           -- 显示行号
vim.opt.relativenumber = true   -- 相对行号
vim.opt.tabstop = 4             -- Tab 宽度
vim.opt.shiftwidth = 4          -- 自动缩进宽度
vim.opt.expandtab = true        -- 将 Tab 转换为空格
vim.opt.smartindent = true      -- 智能缩进
vim.opt.wrap = false            -- 不自动换行

-- 搜索设置
vim.opt.ignorecase = true       -- 忽略大小写
vim.opt.smartcase = true        -- 智能大小写

-- 外观设置
vim.opt.termguicolors = true    -- 真彩色支持
vim.opt.signcolumn = "yes"      -- 总是显示标记列
vim.opt.cursorline = true       -- 高亮当前行

-- 其他设置
vim.opt.mouse = "a"             -- 启用鼠标支持
vim.opt.clipboard = "unnamedplus" -- 系统剪贴板
vim.opt.undofile = true         -- 持久化撤销

-- 键位映射
local keymap = vim.keymap.set

-- 使用 <leader> 作为前缀键
vim.g.mapleader = " "

-- 快速保存
keymap("n", "<leader>w", ":w<CR>", { desc = "保存文件" })

-- 快速退出
keymap("n", "<leader>q", ":q<CR>", { desc = "退出" })

-- 窗口导航
keymap("n", "<C-h>", "<C-w>h", { desc = "切换到左侧窗口" })
keymap("n", "<C-j>", "<C-w>j", { desc = "切换到下方窗口" })
keymap("n", "<C-k>", "<C-w>k", { desc = "切换到上方窗口" })
keymap("n", "<C-l>", "<C-w>l", { desc = "切换到右侧窗口" })

-- 插件管理 (使用 packer.nvim)
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

require('packer').startup(function(use)
  -- 包管理器
  use 'wbthomason/packer.nvim'
  
  -- 主题
  use 'folke/tokyonight.nvim'
  
  -- 文件树
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- 文件图标
    }
  }
  
  -- 状态栏
  use 'nvim-lualine/lualine.nvim'
  
  -- 语法高亮
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  
  -- LSP 配置
  use {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig',
  }
  
  -- 自动补全
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
    }
  }
  
  -- 模糊查找
  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  if packer_bootstrap then
    require('packer').sync()
  end
end)

-- 主题配置
vim.cmd[[colorscheme tokyonight]]

-- nvim-tree 配置
require("nvim-tree").setup()

-- lualine 配置
require('lualine').setup({
  options = {
    theme = 'tokyonight'
  }
})

-- treesitter 配置
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "lua", "python", "javascript", "typescript", "json", "yaml", "cpp", "c", "vim" },
  highlight = {
    enable = true,
  },
}

-- LSP 配置
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "pyright" }
})

-- 自动补全配置
local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  })
})

-- Telescope 键位映射
keymap('n', '<leader>ff', require('telescope.builtin').find_files, { desc = '查找文件' })
keymap('n', '<leader>fg', require('telescope.builtin').live_grep, { desc = '实时搜索' })
keymap('n', '<leader>fb', require('telescope.builtin').buffers, { desc = '查找缓冲区' })
keymap('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = '查找帮助' })

-- nvim-tree 键位映射
keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = '切换文件树' })

-- 终端键位映射
keymap("n", "<C-`>", ":terminal<CR>", { desc = "打开终端" })
keymap("t", "<C-`>", "<C-\\><C-n>", { desc = "退出终端模式" })
