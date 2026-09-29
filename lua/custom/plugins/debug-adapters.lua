-- Python (debugpy) and C/C++ (codelldb) DAP adapters. The packages themselves
-- are installed by kickstart.plugins.debug's mason-nvim-dap `ensure_installed`
-- list; this file only wires the adapter/configurations once they're on
-- disk, and re-wires automatically the first time each finishes installing
-- (they install asynchronously on a fresh setup, so they may not exist yet
-- the moment this file is required).

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'mfussenegger/nvim-dap-python' }

local mason_registry = require 'mason-registry'

local function wire_python(pkg) require('dap-python').setup(pkg:get_install_path() .. '/venv/bin/python') end

local function wire_cpp(pkg)
  local dap = require 'dap'
  local codelldb_path = pkg:get_install_path() .. '/extension/adapter/codelldb'

  dap.adapters.codelldb = {
    type = 'server',
    port = '${port}',
    executable = { command = codelldb_path, args = { '--port', '${port}' } },
  }

  dap.configurations.cpp = {
    {
      name = 'Launch executable',
      type = 'codelldb',
      request = 'launch',
      program = function() return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file') end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
    },
    {
      name = 'Attach to process',
      type = 'codelldb',
      request = 'attach',
      pid = require('dap.utils').pick_process,
      cwd = '${workspaceFolder}',
    },
  }
  dap.configurations.c = dap.configurations.cpp
end

---@param name string
---@param wire fun(pkg: table)
local function wire_when_ready(name, wire)
  local pkg = mason_registry.get_package(name)
  if pkg:is_installed() then
    wire(pkg)
  else
    pkg:once('install:success', function() wire(pkg) end)
  end
end

wire_when_ready('debugpy', wire_python)
wire_when_ready('codelldb', wire_cpp)
