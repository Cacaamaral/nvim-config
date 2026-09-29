-- LSP rename with a live preview of every occurrence before committing.
-- https://github.com/smjonas/inc-rename.nvim
--
-- Kept alongside kickstart's own `grn` (vim.lsp.buf.rename, no preview) --
-- this is purely additive.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'smjonas/inc-rename.nvim' }
require('inc_rename').setup {}

require('which-key').add { { '<leader>c', group = '[C]ode' } }

vim.keymap.set('n', '<leader>cr', function() return ':IncRename ' .. vim.fn.expand '<cword>' end, { expr = true, desc = '[C]ode: [R]ename (live preview)' })
