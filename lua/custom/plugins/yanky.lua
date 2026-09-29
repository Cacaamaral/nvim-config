-- Yank ring + searchable yank history.
-- https://github.com/gbprod/yanky.nvim

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'gbprod/yanky.nvim' }

require('yanky').setup {}
require('telescope').load_extension 'yank_history'

vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)', { desc = 'Yank text' })
vim.keymap.set({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)', { desc = 'Put yanked text after cursor' })
vim.keymap.set({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)', { desc = 'Put yanked text before cursor' })
vim.keymap.set('n', ']p', '<Plug>(YankyCycleForward)', { desc = 'Cycle forward through yank history' })
vim.keymap.set('n', '[p', '<Plug>(YankyCycleBackward)', { desc = 'Cycle backward through yank history' })

vim.keymap.set('n', '<leader>P', '<cmd>Telescope yank_history<cr>', { desc = 'Yank history' })
