-- Project-wide search & replace.
-- https://github.com/MagicDuck/grug-far.nvim
--
-- Bound to <leader>sR (not <leader>sr, which is already Telescope's
-- "search resume" in this config's Section 5 search group).

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'MagicDuck/grug-far.nvim' }
require('grug-far').setup {}

vim.keymap.set('n', '<leader>sR', '<cmd>GrugFar<cr>', { desc = '[S]earch/[R]eplace across project' })
vim.keymap.set('x', '<leader>sR', '<cmd>GrugFarWithin<cr>', { desc = '[S]earch/[R]eplace within selection' })
