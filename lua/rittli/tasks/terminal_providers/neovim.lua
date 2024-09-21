local M = {}

local function CreateNeovimTerminalHandler(info)
  ---@class NeovimTerminalHandler: ITerminalHandler
  local terminal_handler = {}

  terminal_handler.execute_command = function(command)
    vim.fn.chansend(info.job_id, { command, "" })
  end

  terminal_handler.focus = function() end

  terminal_handler.is_alive = function() end

  return terminal_handler
end

---@param create_window_for_terminal fun(bufnr: number): nil
---@return NeovimTerminalProvider
local function CreateNeovimTerminalProvider(create_window_for_terminal)
  ---@class NeovimTerminalProvider: ITerminalProvider
  local terminal_provider = {}

  terminal_provider.create = function(data)
    local bufnr = vim.api.nvim_create_buf(true, false)
    create_window_for_terminal(bufnr)
    local job_id = vim.fn.termopen(vim.o.shell, { detach = true, env = data.env })
    return CreateNeovimTerminalHandler({ job_id = job_id })
  end

  return terminal_provider
end

function M.CreateTabProvider()
  local function create_window_for_terminal(bufnr)
    vim.cmd("tabnew")
    local tab_bufnr = vim.fn.bufnr("%")
    vim.api.nvim_command("b " .. bufnr)
    vim.api.nvim_buf_delete(tab_bufnr, {})
  end

  return CreateNeovimTerminalProvider(create_window_for_terminal)
end

function M.CreateSplitProvider()
  local function create_window_for_terminal(bufnr)
    vim.api.nvim_open_win(bufnr, true, {split = "below", height = 15})
  end

  return CreateNeovimTerminalProvider(create_window_for_terminal)
end

return M
