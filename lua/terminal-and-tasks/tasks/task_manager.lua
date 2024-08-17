local config = require("terminal-and-tasks.config").config

-- This whole module (file) il like a class and in this table below I define public methods or fields
local M = {}

-- These are private fields of this imaginable class
local files_with_tasks_need_to_be_reloaded = {}
local last_runned_task = nil
local loaded_tasks = {}
-- THIS TABLE CONTAINS TASK CONTAINERS AS BELOW
-- local loaded_tasks = {
--   [name] = {  -- this 'name' key duplucate the task name
--     task_source_file_path = string,
--     task_begin_line_number = number,
--     task = {
--       name = string,
--       env = {},
--       cmd = string,
--       cwd = string,
--       is_available = function,
--     }
--   }
-- }

function M.clear_tasks_loaded_from_file(file_path)
  for key, value in pairs(loaded_tasks) do
    if value.task_source_file_path == file_path then
      loaded_tasks[key] = nil
    end
  end
end


function M.clear_tasks_loaded_from_files(files)
  for _, file_path in ipairs(files) do
    M.clear_tasks_loaded_from_file(file_path)
  end
end


local is_available_default = function() return true end
function M.load_tasks_from_file(file_path)
  local is_success, module_with_tasks = pcall(dofile, file_path)
  if not is_success or not module_with_tasks or not module_with_tasks.tasks then
    return false
  end

  local file_with_tasks_lines = io.open(file_path, "r"):lines()
  local line_number = 0
  local is_available_default_for_file = module_with_tasks.is_available or is_available_default

  for _, task in ipairs(module_with_tasks.tasks) do
    task.is_available = task.is_available or is_available_default_for_file
    for line in file_with_tasks_lines do
      line_number = line_number + 1
      if string.find(line, task.name) then
        break
      end
    end

    local task_container = {
      task_source_file_path = file_path,
      task = task,
      task_begin_line_number = line_number,
    }
    loaded_tasks[task.name] = task_container
  end
  return true
end

function M.load_tasks_from_files(files)
  for _, file_path in ipairs(files) do
    local is_success = M.load_tasks_from_file(file_path)
    if not is_success then
      -- multiline notification will require to press enter to continue
      vim.notify("Can't load file from " .. file_path, vim.log.levels.ERROR)
    end
  end
end


function M.update_tasks_from_file(file_path)
  M.clear_tasks_loaded_from_file(file_path)
  local is_success = M.load_tasks_from_file(file_path)
  if config.disable_resource_messages then
    return
  end

  --WARNING: This should return {is_success = boolen, error_msg = string} instead printing (for unit testing, etc..)
  if not is_success then
    vim.notify(string.format("Unable to reload: %s", vim.fn.fnamemodify(file_path, ":~")), vim.log.levels.ERROR)
  else
    vim.notify(string.format("Reloaded: %s", vim.fn.fnamemodify(file_path, ":~")), vim.log.levels.INFO)
  end
end


function M.update_tasks_from_files(files)
  for file_path, _ in pairs(files) do
    M.update_tasks_from_file(file_path)
    files_with_tasks_need_to_be_reloaded[file_path] = nil
  end
end


function M.collect_tasks()
  local tasks = {}
  M.update_tasks_from_files(files_with_tasks_need_to_be_reloaded)
  for _, task_container in pairs(loaded_tasks) do
    if type(task_container.task.is_available) ~= "function" or task_container.task.is_available() then
      table.insert(tasks, task_container)
    end
  end
  return tasks
end

function M.register_file_with_tasks_for_update(file_path)
  files_with_tasks_need_to_be_reloaded[file_path] = true
end

function M.get_last_runned_task()
  return last_runned_task
end

function M.run_task(task)
  local launch_result = {is_success = false, error_msg = nil}
  if task.env and (type(task.env) ~= "table" or next(task.env) == nil) then
    launch_result.error_msg = "Env variable must be no empty table or nil!"
    return launch_result
  elseif type(task.cmd) ~= "table" then
    launch_result.error_msg = "CMD field must be table!"
    return launch_result
  elseif type(task.is_available) ~= "function" then
    launch_result.error_msg = "is_available must be function and return bool value!"
    return launch_result
  end

  last_runned_task = task
  vim.cmd("tabnew")
  local job_id = vim.fn.termopen(vim.o.shell, { detach = true, env = task.env})
  for _, command in ipairs(task.cmd) do
    vim.fn.chansend(job_id, { command, "" })
  end
  -- It throws error in some cases. Need to fix
  -- vim.api.nvim_buf_set_name(0, string.format("TerminalTask: %s", task.name))
  launch_result.is_success = true
  return launch_result
end

return M
