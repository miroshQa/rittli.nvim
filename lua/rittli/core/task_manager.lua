local config = require("rittli.config").config
local Task = require("rittli.core.Task")

-- This whole module (file) il like a class and in this table below I define public / private methods or fields
local M = {}

M.last_runned_task_name = ""

local files_with_tasks_need_to_be_reloaded = {}

---@type table<string, Task>
---First table parameter is the task name. Second is the task itself
local loaded_tasks = {}

function M.clear_tasks_loaded_from_file(file_path)
  for key, task in pairs(loaded_tasks) do
    if task.task_source_file_path == file_path then
      loaded_tasks[key] = nil
    end
  end
end

function M.clear_tasks_loaded_from_files(files)
  for _, file_path in ipairs(files) do
    M.clear_tasks_loaded_from_file(file_path)
  end
end

local is_available_default = function()
  return true
end

---@param file_path string
---@return boolean is_success
function M.load_tasks_from_file(file_path)
  local is_success, module_with_tasks = pcall(dofile, file_path)
  if not is_success or not module_with_tasks or not module_with_tasks.tasks then
    return false
  end

  local file_with_tasks_lines = io.open(file_path, "r"):lines()
  local line_number = 0
  local is_available_default_for_file = module_with_tasks.is_available or is_available_default

  for _, raw_task in ipairs(module_with_tasks.tasks) do
    raw_task.is_available = raw_task.is_available or is_available_default_for_file
    for line in file_with_tasks_lines do
      line_number = line_number + 1
      if string.find(line, raw_task.name) then
        break
      end
    end

    loaded_tasks[raw_task.name] = Task:new(raw_task, file_path, line_number)
  end

  return true
end

---@param files string[]
function M.load_tasks_from_files(files)
  for _, file_path in ipairs(files) do
    local is_success = M.load_tasks_from_file(file_path)
    if not is_success then
      -- multiline notification will require to press enter to continue
      vim.notify("Can't load file from " .. file_path, vim.log.levels.ERROR)
    end
  end
end

---@param file_path string
function M.update_tasks_from_file(file_path)
  M.clear_tasks_loaded_from_file(file_path)
  local is_success = M.load_tasks_from_file(file_path)
  if config.disable_resource_messages then
    return
  end

  if not is_success then
    vim.notify(string.format("Unable to reload: %s", vim.fn.fnamemodify(file_path, ":~")), vim.log.levels.ERROR)
  else
    vim.notify(string.format("Reloaded: %s", vim.fn.fnamemodify(file_path, ":~")), vim.log.levels.INFO)
  end
end

function M.reload_registered_files_with_tasks()
  for file_path, old_mtime in pairs(files_with_tasks_need_to_be_reloaded) do
    local curr_mtime = vim.uv.fs_stat(file_path).mtime
    if curr_mtime.sec ~= old_mtime.sec or curr_mtime.nsec ~= old_mtime.nsec then
      M.update_tasks_from_file(file_path)
    end
    files_with_tasks_need_to_be_reloaded[file_path] = nil
  end
end

function M.collect_tasks()
  local tasks = {}
  M.reload_registered_files_with_tasks()
  for _, task in pairs(loaded_tasks) do
    if task.is_available() then
      table.insert(tasks, task)
    end
  end
  table.sort(tasks, function(a, b)
    return a.name < b.name
  end)
  return tasks
end

function M.register_file_with_tasks_for_update(file_path)
  -- https://linux.die.net/man/2/stat
  files_with_tasks_need_to_be_reloaded[file_path] = vim.uv.fs_stat(file_path).mtime
end

---@param task_name string
function M.get_task_by_name(task_name)
  M.reload_registered_files_with_tasks()
  return loaded_tasks[task_name]
end

return M
