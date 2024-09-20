---@class Task
local Task = {}


function Task:new(raw_task, task_source_file_path, task_begin_line_number)
  ---@class Task
  local newObj = {
    task_source_file_path = task_source_file_path,
    task_begin_line_number = task_begin_line_number,
    builder = raw_task.builder,
    name = raw_task.name,
    is_available = raw_task.is_available,
    cache = {},
  }

  self.__index = self
  return setmetatable(newObj, self)
end

---@param terminal_provider ITerminalProvider
---@return ITerminalHandler terminal_handler
function Task:launch(terminal_provider)
  local builder_result = self.builder(self.cache)
  local terminal_handler = terminal_provider.create({ env = builder_result.env })

  for _, command in ipairs(builder_result.cmd) do
    terminal_handler.execute_command(command)
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "TaskLaunched" })
  return terminal_handler
end

---@param terminal_handler ITerminalHandler
function Task:rerun(terminal_handler)
  local builder_result = self.builder(self.cache)

  for _, command in ipairs(builder_result.cmd) do
    terminal_handler.execute_command(command)
  end
end


local function validiate_task_container(task_container)
  local task = task_container.task
  local validation_result = { is_success = false, error_msg = nil, builder_result = nil }

  if not task.builder or type(task.builder) ~= "function" then
    validation_result.error_msg = "Builder must be a function!"
    return validation_result
  elseif task.builder then
    validation_result.builder_result = task.builder(task_container.cache)
    if not validation_result.builder_result then
      validation_result.error_msg = "Builder must return lua table!"
      return validation_result
    end
    cmd = validation_result.builder_result.cmd
    env = validation_result.builder_result.env

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
end


return Task
