local neovim = require("rittli.core.terminal_providers.neovim")
local utils = require("rittli.utils")

local M = {}

---@class Rittli.config
---@field terminal_provider ITerminalProvider
M.config = {
  --- full path to global tasks dir = global_tasks_dir_path_tail + "/lua/" + folder_name_with_tasks
  --- Default: stdpath("config") + "/lua" . Usually ~/.config/nvim/lua on linux
  global_tasks_dir_path_tail = vim.fn.stdpath("config") .. "/lua",
  folder_name_with_tasks = "tasks",
  disable_resource_messages = false,
  disable_local_tasks_updater_messages = false,
  reload_last_task_when_cwd_changes = true,
  terminal_provider = neovim.CreateTabProvider(),

  telescope_display_maker = function(entry)
    local task = entry.value
    local task_name_max_len = 35
    local task_name = utils.shrink_line(task.name, task_name_max_len)
    task_name = utils.justify_str_left(task_name, task_name_max_len + 5, " ")
    local file_path = vim.fn.fnamemodify(task.task_source_file_path, ":~")
    return task_name .. string.format("[%s]", file_path)
  end,

  conveniences = {
    ---You may want to turn off this if you are going to use westerw instead of the built-in neovim terminal
    enable = true,
    should_register_terminal_enter = function()
      return vim.fn.expand("%") ~= "NeogitConsole"
    end,
    ---You must pass here a TerminalProvider only from rittli.core.terminal_providers.neovim
    terminal_provider = neovim.CreateTabProvider(),
    auto_insert = true,
  },
}

return M
