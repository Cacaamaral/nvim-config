-- clangd-specific UI/commands beyond plain LSP: source/header switching,
-- inlay hints tuning, AST/symbol-info views, memory usage tree.
-- https://github.com/p00f/clangd_extensions.nvim
--
-- clangd itself (background-index, clang-tidy, completion flags, fallback
-- style) is configured in init.lua Section 6's `servers.clangd` entry; this
-- plugin only adds the extra UI on top of that running client.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'p00f/clangd_extensions.nvim' }
require('clangd_extensions').setup {
  server = {},
  extensions = {
    -- Inlay hints (type/parameter hints) off by default; the baseline
    -- kickstart `<leader>th` toggle (init.lua Section 6) still works if you
    -- ever want them on.
    autoSetHints = false,
  },
}

vim.keymap.set('n', '<leader>ch', '<cmd>ClangdSwitchSourceHeader<cr>', { desc = '[C]ode: switch source/[h]eader' })
