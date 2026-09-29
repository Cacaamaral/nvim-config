-- Recent-project switching (root detected via .git/build files), exposed as
-- a Telescope picker.
-- https://github.com/ahmedkhalf/project.nvim

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'ahmedkhalf/project.nvim' }
require('project_nvim').setup {
  detection_methods = { 'pattern', 'lsp' },
  patterns = { '.git', 'Makefile', 'package.json', 'pyproject.toml', 'CMakeLists.txt' },
}
require('telescope').load_extension 'projects'

vim.keymap.set('n', '<leader>sp', '<cmd>Telescope projects<cr>', { desc = '[S]earch [P]rojects' })
