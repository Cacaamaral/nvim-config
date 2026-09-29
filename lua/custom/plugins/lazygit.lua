-- LazyGit, opened through kdheepak/lazygit.nvim (not Snacks' bundled LazyGit
-- integration, which is explicitly disabled in custom/plugins/claude.lua so
-- <leader>gg stays unambiguous).
-- https://github.com/kdheepak/lazygit.nvim
--
-- Requires the `lazygit` binary on PATH (not detected on this machine as of
-- writing this file -- install it separately; the command will just error
-- with a clear message until then).

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'kdheepak/lazygit.nvim' }
vim.g.lazygit_floating_window_use_plenary = 0

vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<cr>', { desc = '[G]it: Lazy[g]it' })
