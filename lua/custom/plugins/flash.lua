-- Flash motions + Treesitter-based structural selection.
-- https://github.com/folke/flash.nvim
--
-- Deviation: flash.nvim's own default trigger is bare `s`/`S`, but this
-- config's mini.surround (init.lua Section 4) already owns the `s`-prefixed
-- keys (sa/sd/sr/...) for add/delete/replace surroundings. Binding flash to
-- `gs`/`gS` instead avoids that collision entirely rather than remapping
-- surround away from its already-established keys.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'folke/flash.nvim' }
require('flash').setup {}

vim.keymap.set({ 'n', 'x', 'o' }, 'gs', function() require('flash').jump() end, { desc = 'Flash jump' })
vim.keymap.set({ 'n', 'x', 'o' }, 'gS', function() require('flash').treesitter() end, { desc = 'Flash Treesitter (structural) selection' })
vim.keymap.set('o', 'r', function() require('flash').remote() end, { desc = 'Remote Flash' })
vim.keymap.set({ 'o', 'x' }, 'R', function() require('flash').treesitter_search() end, { desc = 'Treesitter search' })
