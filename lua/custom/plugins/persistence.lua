-- Persistent sessions (auto-saved per working directory).
-- https://github.com/folke/persistence.nvim
--
-- Deviation: bound under <leader>Q (capital), not <leader>q -- this config's
-- bare <leader>q already opens the diagnostic quickfix list (init.lua
-- Section 2); adding <leader>qs/qS/ql/qd on top of that would make <leader>q
-- itself wait out `timeoutlen` before firing, a real (if small) regression
-- in existing behavior. <leader>Q avoids that entirely.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'folke/persistence.nvim' }
require('persistence').setup {}

require('which-key').add { { '<leader>Q', group = 'Sessions' } }

vim.keymap.set('n', '<leader>Qs', function() require('persistence').load() end, { desc = 'Session: restore current dir' })
vim.keymap.set('n', '<leader>QS', function() require('persistence').select() end, { desc = 'Session: select' })
vim.keymap.set('n', '<leader>Ql', function() require('persistence').load { last = true } end, { desc = 'Session: restore last' })
vim.keymap.set('n', '<leader>Qd', function() require('persistence').stop() end, { desc = 'Session: stop saving' })
