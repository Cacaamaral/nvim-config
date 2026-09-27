-- Minimal Claude Code integration: toggle a terminal split running `claude`.
-- For tighter integration (inline diffs, apply-from-chat), see coder/claudecode.nvim instead.

require('which-key').add { { '<leader>a', group = '[A]I' } }

vim.keymap.set('n', '<leader>ac', '<CMD>vsplit | terminal claude<CR>', { desc = '[A]I: Open [C]laude Code' })
