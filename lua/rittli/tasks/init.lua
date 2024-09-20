local config = require("rittli.config").config
local task_manager = require("rittli.tasks.task_manager")

local global_tasks_glob_pattern =
  string.format("%s/%s/**/*.lua", config.global_tasks_dir_path_tail, config.folder_name_with_tasks)
local current_local_tasks_glob_pattern = string.format("%s/%s/**/*.lua", vim.uv.cwd(), config.folder_name_with_tasks)

local function on_startup()
  task_manager.load_tasks_from_files(vim.fn.glob(global_tasks_glob_pattern, false, true))
  task_manager.load_tasks_from_files(vim.fn.glob(current_local_tasks_glob_pattern, false, true))
end

on_startup()

-- Enable additional (not necessary) modules
-- require("rittli.tasks.auto_update")
--
-- if config.remember_last_task then
--   require("rittli.tasks.last_task_cacher")
-- end
