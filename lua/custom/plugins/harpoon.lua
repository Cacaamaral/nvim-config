-- Harpoon 2: fast file marks scoped by cwd + current git branch, so switching
-- branches (or opening a worktree/submodule) swaps to that branch's own mark
-- list automatically. Non-git directories just key off cwd.
--
-- Branch detection reads `.git/HEAD` directly instead of shelling out to git,
-- so adding/jumping to a mark never spawns a subprocess.
--
-- Deviation from the usual Harpoon keymap contract: [A]dd is <leader>H
-- (capital), not <leader>h — this config's Git hunk group already owns
-- <leader>h (see init.lua Section 4, gitsigns on_attach). Menu (<C-e>) and
-- jump (<leader>1-9) match the usual contract exactly.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { { src = gh 'ThePrimeagen/harpoon', version = 'harpoon2' } }

local function read_file(path)
  local fd = io.open(path, 'r')
  if not fd then return nil end
  local content = fd:read '*a'
  fd:close()
  return content
end

--- Resolve the real git-dir for a path, following `.git` FILE pointers used
--- by worktrees and submodules (`gitdir: <path>`), without a git subprocess.
---@param start_path string
---@return string?
local function resolve_gitdir(start_path)
  local dir = start_path
  while dir and dir ~= '' do
    local git_path = dir .. '/.git'
    local stat = vim.uv.fs_stat(git_path)
    if stat and stat.type == 'directory' then
      return git_path
    elseif stat and stat.type == 'file' then
      local content = read_file(git_path)
      local gitdir = content and content:match 'gitdir:%s*(.-)%s*$'
      if gitdir then
        if not gitdir:match '^/' and not gitdir:match '^%a:[\\/]' then gitdir = dir .. '/' .. gitdir end
        return vim.fs.normalize(gitdir)
      end
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then break end
    dir = parent
  end
  return nil
end

--- Harpoon list key: plain cwd for non-git dirs, cwd+branch for git dirs.
--- Detached HEAD keys off the commit instead of a branch name.
---@param cwd string
---@return string
local function branch_scoped_key(cwd)
  local gitdir = resolve_gitdir(cwd)
  if not gitdir then return cwd end

  local head = read_file(gitdir .. '/HEAD')
  if not head then return cwd end

  local branch = head:match 'ref:%s*refs/heads/(.-)%s*$'
  if branch then return cwd .. '::' .. branch end

  local sha = head:match '^(%x+)'
  if sha then return cwd .. '::detached-' .. sha:sub(1, 12) end

  return cwd
end

local harpoon = require 'harpoon'
harpoon:setup {
  settings = {
    save_on_toggle = true,
    key = function() return branch_scoped_key(vim.loop.cwd()) end,
  },
}

vim.keymap.set('n', '<leader>H', function() harpoon:list():add() end, { desc = 'Harpoon: add file' })
vim.keymap.set('n', '<C-e>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon: menu' })
for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, function() harpoon:list():select(i) end, { desc = 'Harpoon: jump to mark ' .. i })
end
