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
---@return TaskLaunchResult
function Task:launch(terminal_provider)
  ---VALIDATION
  if not self.builder or type(self.builder) ~= "function" then
    return { is_success = false, error_msg = "Builder must be a function"}
  end

  local builder_result = self.builder(self.cache)
  if  type(builder_result) ~= "table" then
    return { is_success = false, error_msg = "Builder must return lua table!" }
  end

  local cmd = builder_result.cmd
  local env = builder_result.env

  if env and (type(env) ~= "table" or next(env) == nil) then
    return { is_success = false, error_msg = "Env variable must be no empty table or nil!" }
  elseif type(cmd) ~= "table" then
    return { is_success = false, error_msg = "CMD field must be table!" }
  elseif type(self.is_available) ~= "function" then
    return { is_success = false, error_msg = "is_available must be function and return bool value!" }
  end

  --MAIN lAUNCH LOGIC
  local terminal_handler = terminal_provider.create({ env = builder_result.env })
  for _, command in ipairs(builder_result.cmd) do
    terminal_handler.execute_command(command)
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "TaskLaunched" })
  return {is_success = true, terminal_handler = terminal_handler}
end

---@param terminal_handler ITerminalHandler
function Task:rerun(terminal_handler)
  local builder_result = self.builder(self.cache)

  for _, command in ipairs(builder_result.cmd) do
    terminal_handler.execute_command(command)
  end
end

return Task
