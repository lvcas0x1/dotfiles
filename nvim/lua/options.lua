vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- show line number and relative number
vim.opt.number = true
vim.opt.relativenumber = true

-- highlight cursor
vim.opt.cursorline = true

-- show sign column
vim.opt.signcolumn = "yes"

-- use 24bit color
vim.opt.termguicolors = true

-- split below and right
vim.opt.splitbelow = true
vim.opt.splitright = true

-- use space as tab, always set to 2
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

-- clipboard
vim.opt.clipboard = "unnamedplus"

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- update time
vim.opt.updatetime = 250

-- auto save and read
vim.opt.autowriteall = true
vim.opt.autoread = true
