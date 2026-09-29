-- Single source of truth for folke/snacks.nvim setup (calling `.setup()` more
-- than once would let the last call silently clobber the others' config).
-- Used for two things in this config:
--   1. The startup dashboard (RIPATO banner + a duck, at the user's own
--      explicit request -- this is personal, not the reference spec's
--      Cerne branding, which was explicitly declined).
--   2. Backing claudecode.nvim's in-editor terminal (custom/plugins/claude.lua).
-- Every other Snacks module is explicitly disabled so it doesn't duplicate
-- mini.nvim/gitsigns/lazygit.nvim/telescope.nvim, which already cover the
-- same ground elsewhere in this config.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'folke/snacks.nvim' }

-- "RIPATO" (ansi_shadow figlet font, block characters) + a duck floating
-- beside it. The real bug behind the earlier "crooked" look was NOT the
-- font/terminal (that was a misdiagnosis) -- it was that this header's own
-- lines had different total lengths, and Snacks' dashboard centers each
-- header line INDIVIDUALLY based on its own width, so unequal line lengths
-- produce a staircase-like left-margin offset regardless of what renders the
-- glyphs.
--
-- Padding every line to equal width has to happen AT RUNTIME (via
-- `string.rep`), not as literal trailing spaces in this file: stylua strips
-- trailing whitespace at end-of-line even inside a `[[...]]` long string --
-- confirmed directly, `-- stylua: ignore` does NOT protect against it -- so
-- any padding stored as literal spaces here would silently disappear the
-- next time this file gets formatted.
local RIPATO_LINES = {
  '██████╗ ██╗██████╗  █████╗ ████████╗ ██████╗ ',
  '██╔══██╗██║██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗',
  '██████╔╝██║██████╔╝███████║   ██║   ██║   ██║',
  '██╔══██╗██║██╔═══╝ ██╔══██║   ██║   ██║   ██║',
  '██║  ██║██║██║     ██║  ██║   ██║   ╚██████╔╝',
  '╚═╝  ╚═╝╚═╝╚═╝     ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ',
}
local DUCK_LINES = {
  '   __',
  ' <(o )___',
  '  ( ._> /',
  "   `---'",
  ' ~~~~~~~~~',
  '~~~~~~~~~~~',
}

---@param s string
---@param width integer
---@return string
local function pad_right(s, width)
  local w = vim.fn.strdisplaywidth(s)
  return w >= width and s or (s .. string.rep(' ', width - w))
end

local HEADER
do
  local ripato_width = 0
  for _, l in ipairs(RIPATO_LINES) do
    ripato_width = math.max(ripato_width, vim.fn.strdisplaywidth(l))
  end

  local merged = {}
  for i, r in ipairs(RIPATO_LINES) do
    merged[i] = pad_right(r, ripato_width) .. '  ' .. DUCK_LINES[i]
  end

  local total_width = 0
  for _, l in ipairs(merged) do
    total_width = math.max(total_width, vim.fn.strdisplaywidth(l))
  end
  for i, l in ipairs(merged) do
    merged[i] = pad_right(l, total_width)
  end

  HEADER = table.concat(merged, '\n')
end

-- If the process's original working directory was deleted out from under it
-- (e.g. the branch/worktree it was opened in got removed), `vim.fn.getcwd()`
-- can keep returning a dead path -- fall back to $HOME before running a
-- dashboard action instead of letting it error.
local function ensure_valid_cwd()
  local ok, cwd = pcall(vim.fn.getcwd)
  if not ok or cwd == '' or not vim.uv.fs_stat(cwd) then vim.cmd.lcd(vim.fn.expand '~') end
end

local function safe(fn)
  return function()
    ensure_valid_cwd()
    fn()
  end
end

require('snacks').setup {
  bigfile = { enabled = true }, -- perf safeguard on very large files
  quickfile = { enabled = true },
  terminal = { enabled = true }, -- backs claudecode.nvim's terminal provider
  dashboard = {
    enabled = true,
    -- Snacks' default `sections` include a "startup" section that
    -- unconditionally does `require('lazy.stats')` with no guard -- that's
    -- lazy.nvim-specific and always errors on a vim.pack setup like this one
    -- (nothing to do with any particular plugin; it's inherent to that
    -- section). Dropped it; header + keys is everything this config needs.
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
    },
    width = 60, -- Snacks' own default; the header (49 cols) fits comfortably
    preset = {
      header = HEADER,
      keys = {
        { icon = ' ', key = 'f', desc = 'Find File', action = safe(function() require('telescope.builtin').find_files() end) },
        { icon = ' ', key = 'g', desc = 'Find Text', action = safe(function() require('telescope.builtin').live_grep() end) },
        { icon = ' ', key = 'r', desc = 'Recent Files', action = safe(function() require('telescope.builtin').oldfiles() end) },
        { icon = ' ', key = 'e', desc = 'Oil Explorer', action = safe(function() vim.cmd.Oil() end) },
        { icon = ' ', key = 's', desc = 'Restore Session', action = safe(function() require('persistence').load() end) },
        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
      },
    },
  },
  -- Indentation guides, at explicit request.
  indent = { enabled = true },
  -- Everything else off: mini.nvim/gitsigns/lazygit.nvim/telescope.nvim
  -- already cover this ground.
  input = { enabled = false },
  notifier = { enabled = false },
  scroll = { enabled = false },
  statuscolumn = { enabled = false },
  words = { enabled = false },
  picker = { enabled = false },
  explorer = { enabled = false },
  lazygit = { enabled = false }, -- kdheepak/lazygit.nvim owns <leader>gg instead
  scratch = { enabled = false },
  zen = { enabled = false },
  image = { enabled = false },
}
