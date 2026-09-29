-- Code screenshots: copy the current visual selection as an image.
-- https://github.com/mistricky/codesnap.nvim
--
-- Styling: left at the plugin's own defaults (no Cerne-brand colors baked
-- in) with the watermark and file-path breadcrumb both switched off, so a
-- shared screenshot never carries workspace/path metadata.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'mistricky/codesnap.nvim' }

require('codesnap').setup {
  save_path = vim.fn.stdpath 'cache' .. '/codesnap',
  watermark = { content = '' },
  code_config = {
    breadcrumbs = { enable = false },
  },
}

-- Normal capture vs. tinted/highlighted-lines capture are separate commands
-- upstream (`CodeSnap` vs `CodeSnapHighlight`); kept as two distinct keymaps
-- so pressing one never accidentally triggers the other's line-highlight UI.
vim.keymap.set('x', '<leader>cp', '<cmd>CodeSnap<cr>', { desc = '[C]ode: [P]hoto (copy to clipboard)' })
vim.keymap.set('x', '<leader>cP', '<cmd>CodeSnapHighlight<cr>', { desc = '[C]ode: [P]hoto with highlighted lines' })
