-- Interactive Python virtualenv/conda/pyenv/poetry selector; re-points
-- Pyright and DAP (debugpy) at whichever interpreter you pick.
-- https://github.com/linux-cultist/venv-selector.nvim

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'linux-cultist/venv-selector.nvim' }
require('venv-selector').setup {}

vim.keymap.set('n', '<leader>cv', '<cmd>VenvSelect<cr>', { desc = '[C]ode: [V]env selector' })
