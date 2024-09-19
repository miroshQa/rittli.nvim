local terminal_provider = require("rittli.tasks.terminal_providers.neovim")

local M = {}

---@class Rittli.Config
M.config = {
  global_tasks_dir_path_tail = vim.fn.stdpath('config') .. "/lua",
  folder_name_with_tasks = "tasks",
  -- full path to global tasks dir = global_tasks_dir_path_tail + "/" + folder_name_with_tasks
  disable_resource_messages = false,
  disable_local_tasks_updater_messages = false,

  remember_last_task = true,
  reload_last_task_when_cwd_changes = true,

  make_entry_display = function(entry)
    local str_custom = require("rittli.utils.string_custom_functions")
    local task_name_max_len = 15
    local task_name = str_custom.shrink_line(entry.task.name, task_name_max_len)
    task_name = str_custom.justify_str_left(task_name, task_name_max_len + 5, " ")
    local file_path = vim.fn.fnamemodify(entry.task_source_file_path, ":~")

    return task_name .. string.format("[%s]", file_path)
  end,

  terminal_provider = terminal_provider,
}

return M
