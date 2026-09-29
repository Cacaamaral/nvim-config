-- Treesitter-powered function/class/parameter text objects and motions,
-- built on the `main`-branch nvim-treesitter core (the old incremental-
-- selection-era textobjects module doesn't exist for it -- this is the
-- actively maintained plugin built for the new API instead).
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
--
-- Deviation: the parameter/argument object is `aP`/`iP` (capital P), not the
-- more common `aa`/`ia` -- this config's mini.ai (init.lua Section 4) already
-- remapped its own around/inside-next objects onto lowercase `aa`/`ii` to
-- dodge Neovim's built-in Treesitter incremental-selection keys, so `aa` was
-- already taken before this file exists.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter-textobjects', version = 'main' } }

require('nvim-treesitter-textobjects').setup {
  select = { lookahead = true },
  move = { set_jumps = true },
}

local select = require 'nvim-treesitter-textobjects.select'
vim.keymap.set({ 'x', 'o' }, 'af', function() select.select_textobject('@function.outer', 'textobjects') end, { desc = 'Around function' })
vim.keymap.set({ 'x', 'o' }, 'if', function() select.select_textobject('@function.inner', 'textobjects') end, { desc = 'Inside function' })
vim.keymap.set({ 'x', 'o' }, 'ac', function() select.select_textobject('@class.outer', 'textobjects') end, { desc = 'Around class' })
vim.keymap.set({ 'x', 'o' }, 'ic', function() select.select_textobject('@class.inner', 'textobjects') end, { desc = 'Inside class' })
vim.keymap.set({ 'x', 'o' }, 'aP', function() select.select_textobject('@parameter.outer', 'textobjects') end, { desc = 'Around parameter' })
vim.keymap.set({ 'x', 'o' }, 'iP', function() select.select_textobject('@parameter.inner', 'textobjects') end, { desc = 'Inside parameter' })

local move = require 'nvim-treesitter-textobjects.move'
vim.keymap.set({ 'n', 'x', 'o' }, ']m', function() move.goto_next_start('@function.outer', 'textobjects') end, { desc = 'Next function start' })
vim.keymap.set({ 'n', 'x', 'o' }, ']M', function() move.goto_next_end('@function.outer', 'textobjects') end, { desc = 'Next function end' })
vim.keymap.set({ 'n', 'x', 'o' }, '[m', function() move.goto_previous_start('@function.outer', 'textobjects') end, { desc = 'Previous function start' })
vim.keymap.set({ 'n', 'x', 'o' }, '[M', function() move.goto_previous_end('@function.outer', 'textobjects') end, { desc = 'Previous function end' })
