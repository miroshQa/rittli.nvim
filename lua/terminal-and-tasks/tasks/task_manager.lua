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


function M.collect_tasks()
  local tasks = {}
  for file_path, old_mtime in pairs(files_with_tasks_need_to_be_reloaded) do
    local curr_mtime = vim.uv.fs_stat(file_path).mtime
    if curr_mtime.sec ~= old_mtime.sec or curr_mtime.nsec ~= old_mtime.nsec then
      M.update_tasks_from_file(file_path)
    end
    files_with_tasks_need_to_be_reloaded[file_path] = nil
  end

  for _, task_container in pairs(loaded_tasks) do
    if type(task_container.task.is_available) ~= "function" or task_container.task.is_available() then
      table.insert(tasks, task_container)
    end
  end
  return tasks
end

function M.register_file_with_tasks_for_update(file_path)
  -- https://linux.die.net/man/2/stat
  files_with_tasks_need_to_be_reloaded[file_path] = vim.uv.fs_stat(file_path).mtime
end

function M.get_last_runned_task()
  return last_runned_task
end

function M.validiate_task(task)
  local validation_result = {is_success = false, error_msg = nil, builder_result = nil}
  if task.builder and (task.env or task.cmd) then
    validation_result.error_msg = "You can't have the fields 'cmd' and 'env' if you use builder!"
    return validation_result
  elseif type(task.builder) ~= "function" then
    validation_result.error_msg = "Builder must be a function!"
  end

  local env = task.env
  local cmd = task.cmd

  if task.builder then
    validation_result.builder_result = task.builder()
    if not validation_result.builder_result then
      validation_result.error_msg = "Builder must return lua table with fields 'cmd', env, ... !"
      return validation_result
    end
    cmd = validation_result.builder_result.cmd
    env = validation_result.builder_result.env
  end

  if env and (type(env) ~= "table" or next(env) == nil) then
    validation_result.error_msg = "Env variable must be no empty table or nil!"
    return validation_result
  elseif type(cmd) ~= "table" then
    validation_result.error_msg = "CMD field must be table!"
    return validation_result
  elseif type(task.is_available) ~= "function" then
    validation_result.error_msg = "is_available must be function and return bool value!"
    return validation_result
  end
  validation_result.is_success = true
  return validation_result
end

function M.run_task(task)
  local validation_result = M.validiate_task(task)
  if not validation_result.is_success then
    return validation_result
  end

  local cmd = task.cmd
  local env = task.env

  if validation_result.builder_result then
    cmd = validation_result.builder_result.cmd
    env = validation_result.builder_result.env
  end

  last_runned_task = task
  local bufnr = vim.api.nvim_create_buf(true, false)
  config.create_window_for_terminal(bufnr)
  local job_id = vim.fn.termopen(vim.o.shell, { detach = true, env = env})
  for _, command in ipairs(cmd) do
    vim.fn.chansend(job_id, { command, "" })
  end
  -- It throws error in some cases. Need to fix
  -- pcall(vim.api.nvim_buf_set_name, 0, string.format("%s [%s]", vim.api.nvim_buf_get_name(0), task.name))
  return validation_result
end

return M
