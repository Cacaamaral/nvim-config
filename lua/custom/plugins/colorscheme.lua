-- Extra colorschemes, installed alongside kickstart's default (tokyonight,
-- set active in init.lua Section 2). None of these are activated here —
-- switch with `:colorscheme <name>` or set one active via
-- `vim.cmd.colorscheme(...)` in this file.
--
-- Available after this file loads:
--   tokyonight-night   (kickstart default, active)
--   catppuccin         (:colorscheme catppuccin / catppuccin-mocha / -latte / -frappe / -macchiato)
--   rose-pine          (:colorscheme rose-pine / rose-pine-moon / rose-pine-dawn)
--   cerne, cerne-light (:colorscheme cerne / cerne-light — from Cerne17/cerne.nvim, see github.com/Cerne17/cerne.nvim)

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add {
  gh 'catppuccin/nvim',
  gh 'rose-pine/neovim',
  gh 'Cerne17/cerne.nvim',
}

require('catppuccin').setup { flavour = 'mocha' }
require('rose-pine').setup {}

-- Persisted colorscheme choice: saved on selection, loaded on startup, kept
-- under stdpath('state') (not this git-tracked config dir -- generated
-- state stays out of git, see CUSTOM.md's NFR-05 note).
local STATE_FILE = vim.fs.joinpath(vim.fn.stdpath 'state', 'colorscheme')

local function save_colorscheme(name)
  local fd = io.open(STATE_FILE, 'w')
  if not fd then return end
  fd:write(name)
  fd:close()
end

local function load_saved_colorscheme()
  local fd = io.open(STATE_FILE, 'r')
  if not fd then return end
  local name = fd:read '*l'
  fd:close()
  if name and name ~= '' then
    local ok = pcall(vim.cmd.colorscheme, name)
    if not ok then vim.notify(('Saved colorscheme "%s" not found, keeping the default'):format(name), vim.log.levels.WARN) end
  end
end

-- Runs after every colorscheme plugin above (and kickstart's own
-- tokyonight in init.lua Section 4) is already installed and available, so
-- overriding the Section 4 default here is safe regardless of which
-- colorscheme was actually saved.
load_saved_colorscheme()

require('which-key').add { { '<leader>u', group = '[U]I' } }

local M = {}

-- `enable_preview = true` makes Telescope apply each colorscheme live as you
-- move the cursor through the list (Esc/<C-c> reverts to whatever was active
-- before opening the picker); the selection on <CR> is saved to disk here so
-- it survives a restart.
--
-- Exposed as `M.pick` (not just a bare keymap callback) so custom.plugins.
-- slash-commands can also trigger it from `/theme`.
function M.pick()
  -- Telescope's colorscheme picker always forces the CURRENTLY active theme
  -- to the top of the list, ahead of everything else -- breaking alphabetical
  -- order there even though `vim.fn.getcompletion('', 'color')` itself is
  -- already sorted. Passing an explicit, pre-sorted `colors` list (which
  -- already contains the current theme in its rightful place) sidesteps that
  -- forced-reorder, since it only fires when the current theme is NOT
  -- already present in the list you hand it.
  local colors = vim.fn.getcompletion('', 'color')
  table.sort(colors, function(a, b) return a:lower() < b:lower() end)

  require('telescope.builtin').colorscheme {
    enable_preview = true,
    colors = colors,
    -- Telescope's own default (`sorting_strategy = "descending"`) draws
    -- result #1 at the BOTTOM of the list, so even a perfectly A-Z sorted
    -- `colors` array above still reads Z-A top-to-bottom on screen unless
    -- overridden here.
    sorting_strategy = 'ascending',
    attach_mappings = function(prompt_bufnr, _)
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          vim.cmd.colorscheme(selection.value)
          save_colorscheme(selection.value)
        end
      end)
      return true
    end,
  }
end

vim.keymap.set('n', '<leader>uC', M.pick, { desc = '[U]I: [C]olorscheme picker (saves your choice)' })

return M
