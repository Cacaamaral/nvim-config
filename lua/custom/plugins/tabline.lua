-- Tabline showing open buffers (not Vim's own :tabs, which mini.tabline
-- deliberately repurposes the tabline area for -- see `:help MiniTabline`).
-- Uses mini.nvim, already installed in init.lua Section 4, so no new plugin
-- is needed.

vim.o.showtabline = 2 -- always show it, not just when there are 2+ real :tabs

require('mini.tabline').setup {
  show_icons = vim.g.have_nerd_font,
}
