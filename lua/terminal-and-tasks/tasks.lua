require("terminal-and-tasks.terminal_tweaks")
local config = require("terminal-and-tasks.config").config

-- to fina all files in local directory

local M = {}

M.all_tasks = {}
-- THIS TABLE CONTAINS TASK CONTAINERS AS BELOW
-- M.all_tasks = {
--   [name] = {  -- this 'name' key duplucate the task name
--     task_source_file_path = nil,
--     task_begin_line_number = nil,
--     task_begin_line_number = nil,
--     task = {
--       name = nil,
--       env = nil,
--       cmd = nil,
--       cwd = nil
--     }
--   }
-- }
M.last_runned_task = nil
-- We have to launch this function before load tasks frome file again (before resoruce)
local function clear_tasks_loaded_from_file(file_path)
  for key, value in pairs(M.all_tasks) do
    if value.task_source_file_path == file_path then
      M.all_tasks[key] = nil
    end
  end
end

local function find_task_begin_line_number_by_name(file_with_tasks, name)
  file_with_tasks:seek("set", 0)
  local lines = file_with_tasks:lines()
  local line_number = 1
  for line in lines do
    if string.find(line, name) then
      return line_number
    end
    line_number = line_number + 1
  end
end

local function load_tasks_from_file(file_path)
  local is_success, module_with_tasks = pcall(dofile, file_path)
  if not is_success then
    return false
  end

  local file_with_tasks = io.open(file_path, "r")

  for _, task in ipairs(module_with_tasks.tasks) do
    local task_container = {
      task_source_file_path = file_path,
      task = task,
      task_begin_line_number = find_task_begin_line_number_by_name(file_with_tasks, task.name)
    }
    M.all_tasks[task.name] = task_container
  end
  return true
end

local function load_tasks_from_files(files)
  for _, file_path in ipairs(files) do
    local is_success = load_tasks_from_file(file_path)
    if not is_success then
      vim.print("Can't load file from " .. file_path)
    end
  end
end


function M.collect_tasks()
  local tasks = {}
  for _, value in pairs(M.all_tasks) do
    table.insert(tasks, value)
  end
  return tasks
end

function M.run_task(task)
  M.last_runned_task = task
  vim.cmd("tabnew")
  local job_id = vim.fn.termopen(vim.o.shell, { detach = true })
  vim.fn.chansend(job_id, { task.cmd, "" })
end




-- vim.print(vim.fn.glob(global_tasks_pattern, false, true)) 
-- vim.print(vim.fn.glob(local_tasks_pattern, false, true))
local global_tasks_pattern = string.format("%s/lua/%s/**/*.lua", vim.fn.stdpath("config"), config.folder_name_with_tasks)
local local_tasks_pattern = string.format("%s/%s/**/*.lua", vim.uv.cwd(), config.folder_name_with_tasks)
load_tasks_from_files(vim.fn.glob(global_tasks_pattern, false, true))
load_tasks_from_files(vim.fn.glob(local_tasks_pattern, false, true))



-- see :help autocmd-pattern
-- We need to dublicate code unfortunately
local patterns = {
  string.format("%s/lua/%s/*/*.lua", vim.fn.stdpath("config"), config.folder_name_with_tasks),
  string.format("%s/lua/%s/*.lua", vim.fn.stdpath("config"), config.folder_name_with_tasks),
  string.format("%s/%s/*.lua", vim.uv.cwd(), config.folder_name_with_tasks),
  string.format("%s/%s/*/*.lua", vim.uv.cwd(), config.folder_name_with_tasks),
}

vim.api.nvim_create_autocmd("BufLeave", {
  pattern = patterns,
  group = vim.api.nvim_create_augroup("TasksReloader", { clear = true }),
  callback = function(data)
    clear_tasks_loaded_from_file(data.match)
    local is_success = load_tasks_from_file(data.match)
    if config.disable_resource_messages then
      return
    end

    if not is_success then
      vim.print(string.format("Unable to reload tasks. FILE: %s", data.match))
    else
      vim.print(string.format("Reload success. FILE: %s", data.match))
    end
  end
})


return M
