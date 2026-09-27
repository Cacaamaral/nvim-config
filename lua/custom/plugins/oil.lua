-- File explorer that edits the filesystem like a normal Neovim buffer.
-- https://github.com/stevearc/oil.nvim

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'stevearc/oil.nvim' }
require('oil').setup {
  default_file_explorer = true,
  view_options = {
    show_hidden = true,
  },
}

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
vim.keymap.set('n', '<leader>e', '<CMD>Oil<CR>', { desc = '[E]xplore files' })
