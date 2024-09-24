local neovim = require("rittli.core.terminal_providers.neovim")

local M = {}

---@class Rittli.config
---@field terminal_provider ITerminalProvider
M.config = {
  --- full path to global tasks dir = global_tasks_dir_path_tail + "/lua/" + folder_name_with_tasks
  --- Default: stdpath("config"). Usually ~/.config/nvim on linux
  global_tasks_dir_path_tail = vim.fn.stdpath("config") .. "/lua",
  folder_name_with_tasks = "tasks",
  disable_resource_messages = false,
  disable_local_tasks_updater_messages = false,
  reload_last_task_when_cwd_changes = true,
  terminal_provider = neovim.CreateTabProvider(),

  conveniences = {
    ---You may want to turn off this if you are going to use westerw instead of the built-in neovim terminal
    enable = true,
    should_register_terminal_enter = function()
      return vim.fn.expand("%") ~= "NeogitConsole"
    end,
    ---You must pass here a TerminalProvider only from rittli.core.terminal_providers.neovim
    terminal_provider = neovim.CreateTabProvider(),
  },
}

return M
