-- Rendered Markdown inside Neovim, plus a browser-based live preview.
-- (Language intelligence itself is marksman, wired as an LSP server in
-- init.lua Section 6.)

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add {
  gh 'MeanderingProgrammer/render-markdown.nvim',
  gh 'iamcco/markdown-preview.nvim',
}

require('render-markdown').setup {}

-- markdown-preview.nvim ships a JS app that needs `npm install` once, the
-- first time it's installed/updated -- that's handled by the existing global
-- PackChanged handler in init.lua Section 3 (registered before any
-- `vim.pack.add` calls run, unlike an autocmd added here).
vim.g.mkdp_auto_close = 0

vim.keymap.set('n', '<leader>cm', '<cmd>MarkdownPreviewToggle<cr>', { desc = '[C]ode: [M]arkdown preview (browser)' })
