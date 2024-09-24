local config = require("rittli.config").config

local SessionManager = {}

---@class ActiveConnection
---@field task_name string
---@field terminal_handler ITerminalHandler

---@type {[string]: ActiveConnection}
local active_connections = {}

---@type string
local last_tasks_name_per_dir = {}

---@param task_name string
---@param terminal_handler ITerminalHandler
function SessionManager.register_connection(task_name, terminal_handler)
  local connnection = { task_name = task_name, terminal_handler = terminal_handler }
  active_connections[task_name] = connnection
end

---@param task_name string
---@return ActiveConnection?
function SessionManager.find_connection(task_name)
  for name, connection in pairs(active_connections) do
    if name == task_name then
      if not connection.terminal_handler.is_alive() then
        active_connections[name] = nil
        return nil
      end
      return connection
    end
  end
end

function SessionManager.get_all_lonely_terminal_handlers()
  local all = config.terminal_provider.get_all_available_handlers()
  local lonely_handlers = {}
  for _, handler in ipairs(all) do
    local handler_signature = handler.get_info_to_reattach()
    local is_handler_lonely = true
    for _, connection in pairs(active_connections) do
      if connection.terminal_handler.get_info_to_reattach() == handler_signature then
        is_handler_lonely = false
        break
      end
    end
    if is_handler_lonely then
      table.insert(lonely_handlers, handler)
    end
  end
  return lonely_handlers
end

---@return string
function SessionManager.get_last_runned_task_name()
  local result =  last_tasks_name_per_dir[vim.uv.cwd()]
  return result
end

local cache_dir = vim.fn.stdpath("cache") .. "/rittli"
local last_tasks_file_path = cache_dir .. "/last_tasks.json"
local connections_file_path = cache_dir .. "/connections.json"

local Local = {}

function Local.restore_session()
  Local.restore_connections()
  Local.restore_last_tasks()
end

function Local.save_session()
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir)
  end
  Local.save_last_runned_tasks()
  Local.save_connections()
end

function Local.restore_connections()
  if vim.fn.filereadable(connections_file_path) == 1 then
    local file = io.open(connections_file_path, "r")
    local text = file:read("*a")
    local is_success, res = pcall(vim.json.decode, text)
    if not is_success then
      os.remove(connections_file_path)
      return
    end

    for task_name, info_to_attach in pairs(res) do
      local ret = config.terminal_provider.attach(info_to_attach)
      if ret then
        active_connections[task_name] = { task_name = task_name, terminal_handler = ret }
      end
    end
  end
end

function Local.restore_last_tasks()
  if vim.fn.filereadable(last_tasks_file_path) == 1 then
    local file = io.open(last_tasks_file_path, "r")
    local text = file:read("*a")
    local is_success, res = pcall(vim.json.decode, text)
    if not is_success then
      os.remove(last_tasks_file_path)
      return
    end
    last_tasks_name_per_dir = res
  end
end

function Local.save_last_runned_tasks()
  local file = io.open(last_tasks_file_path, "w+")
  local text = vim.json.encode(last_tasks_name_per_dir)
  file:write(text)
end

function Local.save_connections()
  local file = io.open(connections_file_path, "w+")
  local encodable = {}
  for task_name, connection in pairs(active_connections) do
    if connection.terminal_handler.is_alive() then
      encodable[task_name] = connection.terminal_handler.get_info_to_reattach()
    end
  end
  local text = vim.json.encode(encodable)
  file:write(text)
end

vim.api.nvim_create_autocmd("User", {
  pattern = "TaskExecuted",
  group = vim.api.nvim_create_augroup("SaveLastRunnedTask", { clear = true }),
  callback = function(data)
    local task_name = data.data
    last_tasks_name_per_dir[vim.uv.cwd()] = task_name
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  group = vim.api.nvim_create_augroup("SaveSession", { clear = true }),
  callback = function()
    Local.save_session()
  end,
})

-- On require
Local.restore_session()

return SessionManager
