-- friendly-snippets (community VS Code-format snippets for most languages)
-- plus this repo's own editable VS Code-style snippet collection under
-- lua/custom/snippets/. Edit the .json files there directly to add more --
-- LuaSnip picks them up on next load, no code changes needed.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'rafamadriz/friendly-snippets' }

local loader = require 'luasnip.loaders.from_vscode'
loader.lazy_load()
loader.lazy_load { paths = { vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'snippets') } }
