local config = require("rittli.config").config

local SessionManager = {}

---@type string
SessionManager.last_runned_task_name = ""

---@class ActiveConnection
---@field task_name string
---@field terminal_handler ITerminalHandler

---@type {[string]: ActiveConnection}
local active_connections = {}

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

local connections_file_path = vim.fn.stdpath("cache") .. "/connections.json"

local function initialize_connections()
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

function print_connections()
  vim.print(active_connections)
  print(active_connections["PYTHON: Run"].terminal_handler.is_alive())
  print(active_connections["PYTHON: Run"].terminal_handler.get_info_to_reattach())
end

vim.api.nvim_create_autocmd("VimLeave", {
  group = vim.api.nvim_create_augroup("SaveConnnections", { clear = true }),
  callback = function()
    local file = io.open(connections_file_path, "w+")
    local encodable = {}
    for task_name, connection in pairs(active_connections) do
      if connection.terminal_handler.is_alive() then
        encodable[task_name] = connection.terminal_handler.get_info_to_reattach()
      else
        encodable[task_name] = "broken"
      end
    end
    local text = vim.json.encode(encodable)
    file:write(text)
  end,
})

initialize_connections()

return SessionManager
