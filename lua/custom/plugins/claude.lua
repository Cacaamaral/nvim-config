-- Claude Code integration via coder/claudecode.nvim: a pure-Lua WebSocket/MCP
-- client implementing the same protocol as Anthropic's official VS Code/
-- JetBrains extensions (diff review, resume/continue, model switch, sending
-- buffer/selection/explorer context). Requires the `claude` CLI on PATH.
--
-- Its terminal provider is folke/snacks.nvim, set up once in
-- custom/plugins/snacks.lua (required before this file, see init.lua Section
-- 10) -- do not call `require('snacks').setup{}` again here, it would
-- silently clobber that file's config.
--
-- All keymaps live under the <leader>a "[A]I" group; `<leader>a` itself is
-- never bound to an action, only the group label.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'coder/claudecode.nvim' }

require('claudecode').setup {}

require('which-key').add { { '<leader>a', group = '[A]I' } }

vim.keymap.set('n', '<leader>ac', '<cmd>ClaudeCode<cr>', { desc = '[A]I: Toggle [C]laude' })
vim.keymap.set('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', { desc = '[A]I: [F]ocus Claude' })
vim.keymap.set('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', { desc = '[A]I: [R]esume Claude' })
vim.keymap.set('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', { desc = '[A]I: [C]ontinue Claude' })
vim.keymap.set('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', { desc = '[A]I: Select [M]odel' })
vim.keymap.set('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = '[A]I: Add current [B]uffer' })
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = '[A]I: [S]end selection' })
vim.keymap.set('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = '[A]I: [A]ccept diff' })
vim.keymap.set('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = '[A]I: [D]eny diff' })

-- Sending a file from Oil (the primary explorer, see custom/plugins/oil.lua)
-- reuses <leader>as, matching claudecode.nvim's own explorer-integration key.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'oil',
  callback = function(ev) vim.keymap.set('n', '<leader>as', '<cmd>ClaudeCodeTreeAdd<cr>', { buffer = ev.buf, desc = '[A]I: Add file from explorer' }) end,
})
