local task_manager = require("terminal-and-tasks.tasks.task_manager")
local config = require("terminal-and-tasks.config").config
require("terminal-and-tasks.tasks.auto_update")

local global_tasks_glob_pattern = string.format("%s/lua/%s/**/*.lua", vim.fn.stdpath("config"), config.folder_name_with_tasks)
local current_local_tasks_glob_pattern = string.format("%s/%s/**/*.lua", vim.uv.cwd(), config.folder_name_with_tasks)

local function on_startup()
  task_manager.load_tasks_from_files(vim.fn.glob(global_tasks_glob_pattern, false, true))
  task_manager.load_tasks_from_files(vim.fn.glob(current_local_tasks_glob_pattern, false, true))
end

on_startup()



