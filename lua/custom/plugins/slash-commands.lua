-- Typing `/theme<CR>` or `/font<CR>` in normal mode runs an action instead
-- of a literal search, at explicit request. `/` is Neovim's native
-- search-forward trigger, not a command prefix -- this works by hooking
-- `CmdlineLeave` and setting `v:event.abort = true` before the search would
-- actually run, which is the documented way to cancel a pending
-- command-line command (`:help CmdlineLeave`: "abort (mutable) ... can only
-- be changed from false to true").
--
-- Typing `/theme` or `/font` to search for that literal text still works
-- fine everywhere else -- only an EXACT, whole match against one of the
-- names below is intercepted; `/theme` followed by more text (e.g.
-- `/themepark`) is untouched.

local colorscheme = require 'custom.plugins.colorscheme'

local ACTIONS = {
  theme = colorscheme.pick,
  -- Font is a terminal-level property, not something Neovim itself can
  -- change -- this shells out to the standalone `alacritty-font-picker`
  -- script (~/.local/bin/, outside this repo) in a terminal split. Alacritty
  -- picks up the change live regardless of which process wrote its config.
  --
  -- `:terminal` opens in terminal-NORMAL mode, not terminal-INSERT mode --
  -- without `startinsert`, keystrokes go to Neovim itself (not the fzf
  -- process inside), which is exactly why the picker looked unresponsive and
  -- "impossible to exit": Esc/arrows were being interpreted as Neovim
  -- commands over the terminal buffer, never reaching fzf at all. The
  -- `TermClose` autocmd below closes the split automatically once the script
  -- exits (confirmed or cancelled), so there's no terminal-mode mechanics to
  -- deal with afterwards either.
  font = function()
    vim.cmd 'vsplit'
    vim.cmd.terminal 'alacritty-font-picker'
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_create_autocmd('TermClose', {
      buffer = buf,
      once = true,
      callback = function()
        if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
      end,
    })
    vim.cmd.startinsert()
  end,
}

vim.api.nvim_create_autocmd('CmdlineLeave', {
  callback = function()
    if vim.fn.getcmdtype() ~= '/' then return end
    local action = ACTIONS[vim.fn.getcmdline()]
    if not action then return end
    vim.v.event.abort = true
    vim.schedule(action)
  end,
})
