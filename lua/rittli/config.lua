local neovim = require("rittli.core.terminal_providers.neovim")
local wezterm = require("rittli.core.terminal_providers.wezterm")
require("rittli.types")

local M = {}

---@class Rittli.config
---@field terminal_provider ITerminalProvider 
M.config = {
  global_tasks_dir_path_tail = vim.fn.stdpath("config") .. "/lua",
  folder_name_with_tasks = "tasks",
  -- full path to global tasks dir = global_tasks_dir_path_tail + "/" + folder_name_with_tasks
  disable_resource_messages = false,
  disable_local_tasks_updater_messages = false,

  remember_last_task = true,
  reload_last_task_when_cwd_changes = true,

  terminal_provider = wezterm.CreateSplitProvider('right'),

  conveniences = {
    ---You may want to turn off this if you are going to use western instead of the built-in neovim terminal
    enable = true,
    ---Some other plugins open terminals sometimes. You may not want to toggle this terminal instances back
    should_register_terminal_enter = function()
      return vim.fn.expand("%") ~= "NeogitConsole"
    end,

    ---You must pass here a TerminalProvider only from rittli.core.terminal_providers.neovim
    terminal_provider = wezterm.CreateSplitProvider('right'),
  },
}


return M
