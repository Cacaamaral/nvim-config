-- Trouble: persistent list views for diagnostics, symbols, LSP results, and
-- the quickfix/location lists. Uses the plugin's own documented default
-- keymap convention (<leader>x*) since the reference shortcut contract this
-- config is otherwise built from doesn't specify one.
-- https://github.com/folke/trouble.nvim

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'folke/trouble.nvim' }
require('trouble').setup {}

vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (Trouble)' })
vim.keymap.set('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Buffer diagnostics (Trouble)' })
vim.keymap.set('n', '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', { desc = 'Symbols (Trouble)' })
vim.keymap.set('n', '<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', { desc = 'LSP results (Trouble)' })
vim.keymap.set('n', '<leader>xQ', '<cmd>Trouble quickfix toggle<cr>', { desc = 'Quickfix (Trouble)' })
vim.keymap.set('n', '<leader>xL', '<cmd>Trouble loclist toggle<cr>', { desc = 'Location list (Trouble)' })
