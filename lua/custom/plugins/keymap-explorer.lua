-- Custom Telescope-based keymap explorer: a category browser (with counts)
-- that drills into a flat, searchable list built from live
-- `nvim_get_keymap`/`nvim_buf_get_keymap` output.
--
-- Known limitations (see `:help nvim_get_keymap`):
--   * Buffer-local mappings only include the CURRENT buffer's, not every
--     loaded buffer's -- there is no API to enumerate other buffers' local
--     maps without switching to them first.
--   * A mapping a plugin registers through its own internal dispatch table
--     rather than `vim.keymap.set`/`:map` never reaches Neovim's keymap
--     tables at all, so it can't appear here. blink.cmp's insert-mode
--     completion keys (Section 8) are the clearest example in this config.
--   * Categorization below is a best-effort pattern match against this
--     config's OWN leader scheme (see `M.categorize`), not a general-purpose
--     classifier -- a mapping this config doesn't already know about lands
--     in "Configuration" as a catch-all.

local M = {}

local CATEGORY_ORDER = {
  'AI',
  'Debugging',
  'Tests',
  'Git',
  'Harpoon',
  'Diagnostics',
  'LSP',
  'Search',
  'Files',
  'Windows',
  'Editing',
  'Text objects',
  'UI',
  'Sessions',
  'Terminal',
  'Motions',
  'Configuration',
}

--- `<leader>ac` is stored internally with the leader key already substituted
--- (a literal space here, since mapleader = ' '), not the literal text
--- "<leader>". Convert it back to readable/matchable notation.
---@param lhs string
---@return string
local function normalize_lhs(lhs)
  local leader = vim.g.mapleader or ''
  local localleader = vim.g.maplocalleader or ''
  if leader ~= '' and lhs:sub(1, #leader) == leader then return '<leader>' .. lhs:sub(#leader + 1) end
  if localleader ~= '' and lhs:sub(1, #localleader) == localleader then return '<localleader>' .. lhs:sub(#localleader + 1) end
  return lhs
end

---@param display_lhs string
---@param desc string
---@return string
function M.categorize(display_lhs, desc)
  desc = desc:lower()

  local rules = {
    { '^<leader>a', 'AI' },
    { '^<[Ff]%d+>$', 'Debugging' },
    { '^<leader>[dDbB]', 'Debugging' },
    { '^<leader>T', 'Tests' },
    { '^<leader>x', 'Diagnostics' },
    { '^<leader>Q', 'Sessions' },
    { '^<leader>H$', 'Harpoon' },
    { '^<C%-e>$', 'Harpoon' },
    { '^<leader>[1-9]$', 'Harpoon' },
    { '^<leader>g', 'Git' },
    { '^<leader>h', 'Git' },
    { '^gr', 'LSP' },
    { '^g[OW]$', 'LSP' },
    { '^<leader>c[rvh]$', 'LSP' },
    { '^<leader>q$', 'Diagnostics' },
    { '^<leader>s', 'Search' },
    { '^<leader>e$', 'Files' },
    { '^%-$', 'Files' },
    { '^<C%-[hjkl]>$', 'Windows' },
    { '^g[sS]$', 'Motions' },
    { '^r$', 'Motions' },
    { '^R$', 'Motions' },
    { '^%]', 'Motions' },
    { '^%[', 'Motions' },
    { '^s[aAdrfFhn]$', 'Text objects' },
    { '^[ai][fcP]$', 'Text objects' },
    { '^<leader>c[pPm]$', 'UI' },
    { '^<leader>u', 'UI' },
    { '^<leader>t[bwh]$', 'UI' },
    { '^<leader>f$', 'Editing' },
    { '^y$', 'Editing' },
    { '^p$', 'Editing' },
    { '^P$', 'Editing' },
    { '^<leader>P$', 'Editing' },
  }

  for _, rule in ipairs(rules) do
    if display_lhs:match(rule[1]) then return rule[2] end
  end

  if desc:find 'lsp' then return 'LSP' end
  if desc:find 'git' or desc:find 'hunk' then return 'Git' end
  if desc:find 'diagnostic' then return 'Diagnostics' end
  if desc:find 'terminal' then return 'Terminal' end

  return 'Configuration'
end

local MODES = { 'n', 'v', 'x', 'o', 'i', 't', 'c' }

---@return table[]
function M.collect()
  local seen = {}
  local out = {}

  local function add(map, buffer_local)
    local raw_lhs = map.lhs
    if not raw_lhs or raw_lhs == '' then return end
    local mode = map.mode or 'n'
    local key = mode .. '\0' .. raw_lhs .. '\0' .. tostring(buffer_local)
    if seen[key] then return end
    seen[key] = true

    local display_lhs = normalize_lhs(raw_lhs)
    local desc = map.desc or ''
    if desc == '' and map.rhs then desc = map.rhs end

    local entry = {
      raw_lhs = raw_lhs,
      display_lhs = display_lhs,
      mode = mode,
      desc = desc,
      buffer_local = buffer_local,
      owner = map.callback and 'lua callback' or map.rhs,
    }
    entry.category = M.categorize(display_lhs, desc)
    table.insert(out, entry)
  end

  for _, mode in ipairs(MODES) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      add(map, false)
    end
  end

  local bufnr = vim.api.nvim_get_current_buf()
  for _, mode in ipairs(MODES) do
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(bufnr, mode)) do
      add(map, true)
    end
  end

  return out
end

local NORMAL_COMPATIBLE = { n = true }

---@param entry table
local function execute_mapping(entry)
  if not NORMAL_COMPATIBLE[entry.mode] then
    vim.notify(
      ('Keymap Explorer: "%s" is bound in %s-mode, not normal mode -- not executing it (switch mode and use it directly instead).'):format(
        entry.display_lhs,
        entry.mode
      ),
      vim.log.levels.WARN
    )
    return
  end
  local keys = vim.api.nvim_replace_termcodes(entry.raw_lhs, true, true, true)
  vim.api.nvim_feedkeys(keys, 'm', false)
end

---@param entries table[]
---@param title string
local function flat_picker(entries, title)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table {
        results = entries,
        entry_maker = function(entry)
          local desc = entry.desc ~= '' and entry.desc or '(no description)'
          local buf_tag = entry.buffer_local and ' [buffer]' or ''
          local display = string.format('%-4s %-22s %-14s %s%s', entry.mode, entry.display_lhs, entry.category, desc, buf_tag)
          return {
            value = entry,
            display = display,
            ordinal = table.concat({ entry.mode, entry.display_lhs, entry.category, desc }, ' '),
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then execute_mapping(selection.value) end
        end)
        return true
      end,
    })
    :find()
end

---Flat, searchable list of every discovered mapping, optionally pre-filtered
---to one category.
---@param category string?
function M.flat(category)
  local entries = M.collect()
  if category then entries = vim.tbl_filter(function(e) return e.category == category end, entries) end
  flat_picker(entries, category and ('Keymaps: ' .. category) or 'Keymaps: all')
end

--- Category list (with counts) -> <CR> drills into that category's flat list.
function M.categories()
  local entries = M.collect()
  local counts = {}
  for _, e in ipairs(entries) do
    counts[e.category] = (counts[e.category] or 0) + 1
  end

  local rows = {}
  for _, cat in ipairs(CATEGORY_ORDER) do
    if counts[cat] then table.insert(rows, { category = cat, count = counts[cat] }) end
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = 'Keymap categories',
      finder = finders.new_table {
        results = rows,
        entry_maker = function(row) return { value = row, display = string.format('%-16s (%d)', row.category, row.count), ordinal = row.category } end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then M.flat(selection.value.category) end
        end)
        return true
      end,
    })
    :find()
end

vim.api.nvim_create_user_command('KeymapExplorer', M.categories, { desc = 'Open the categorized keymap explorer' })

-- Deviation: the usual contract for this is <leader>fK / <leader>fA, but
-- <leader>f is already bound bare (to conform's format-buffer, Section 7) --
-- adding sub-mappings under it would make plain <leader>f wait out
-- `timeoutlen` before firing. Placed under <leader>s (Search), this config's
-- existing prefix for every other finder, instead.
vim.keymap.set('n', '<leader>sK', M.categories, { desc = '[S]earch: [K]eymap categories' })
vim.keymap.set('n', '<leader>sA', function() M.flat() end, { desc = '[S]earch: [A]ll keymaps (flat)' })

return M
