local neovim = require("rittli.core.terminal_providers.neovim")
local wezterm = require("rittli.core.terminal_providers.wezterm")
require("rittli.types")

local M = {}

---@class Rittli.Config
M.config = {
  global_tasks_dir_path_tail = vim.fn.stdpath("config") .. "/lua",
  folder_name_with_tasks = "tasks",
  -- full path to global tasks dir = global_tasks_dir_path_tail + "/" + folder_name_with_tasks
  disable_resource_messages = false,
  disable_local_tasks_updater_messages = false,

  remember_last_task = true,
  reload_last_task_when_cwd_changes = true,

  terminal_provider = neovim.CreateTabProvider(),

}

return M
