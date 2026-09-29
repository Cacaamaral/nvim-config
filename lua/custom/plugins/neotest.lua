-- Neotest: run nearest/file/suite, summary + output views, stop.
-- Python adapter only for now -- add another adapter (e.g. neotest-jest) the
-- same way if/when a JS/TS test runner is actually in use.
-- https://github.com/nvim-neotest/neotest

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add {
  gh 'nvim-neotest/nvim-nio',
  gh 'nvim-neotest/neotest',
  gh 'nvim-neotest/neotest-python',
}

require('neotest').setup {
  adapters = { require 'neotest-python' {} },
}

require('which-key').add { { '<leader>T', group = '[T]ests' } }

local neotest = require 'neotest'
vim.keymap.set('n', '<leader>Tn', function() neotest.run.run() end, { desc = 'Test: run nearest' })
vim.keymap.set('n', '<leader>Tf', function() neotest.run.run(vim.fn.expand '%') end, { desc = 'Test: run file' })
vim.keymap.set('n', '<leader>Ts', function() neotest.run.run(vim.uv.cwd()) end, { desc = 'Test: run suite' })
vim.keymap.set('n', '<leader>Tx', function() neotest.run.stop() end, { desc = 'Test: stop' })
vim.keymap.set('n', '<leader>TS', function() neotest.summary.toggle() end, { desc = 'Test: toggle summary' })
vim.keymap.set('n', '<leader>To', function() neotest.output.open { enter = true } end, { desc = 'Test: show output' })
vim.keymap.set('n', '<leader>TO', function() neotest.output_panel.toggle() end, { desc = 'Test: toggle output panel' })
