local M = {}

local function CreateNeovimTerminalHandler(job_id, bufnr, create_win_for_buf)
  ---@class NeovimTerminalHandler: ITerminalHandler
  local terminal_handler = {}

  terminal_handler.execute_command = function(command)
    vim.fn.chansend(job_id, { command, "" })
  end

  terminal_handler.focus = function()
    local windows = vim.fn.win_findbuf(bufnr)
    local win_id = #windows > 0 and windows[1] or -1
    if win_id == -1 then
      create_win_for_buf(bufnr)
    else
      vim.fn.win_gotoid(win_id)
    end
  end

  terminal_handler.is_alive = function()
    return vim.fn.bufexists(bufnr) == 1
  end

  return terminal_handler
end

function M.CreateTabProvider()
  ---@class NeovimTabTerminalProvider: ITerminalProvider
  local provider = {}

  local function create_win_for_buf(bufnr)
    vim.cmd("tabnew")
    local tab_bufnr = vim.fn.bufnr("%")
    vim.api.nvim_command("b " .. bufnr)
    vim.api.nvim_buf_delete(tab_bufnr, {})
  end

  provider.create = function(data)
    local bufnr = vim.api.nvim_create_buf(true, false)
    create_win_for_buf(bufnr)
    local job_id = vim.fn.termopen(vim.o.shell, { detach = true, env = data.env })
    return CreateNeovimTerminalHandler(job_id, bufnr, create_win_for_buf)
  end

  return provider
end

function M.CreateSplitProvider()
  ---@class NeovimSplitTerminalProvider: ITerminalProvider
  local provider = {}

  local function create_win_for_buf(bufnr)
    vim.api.nvim_open_win(bufnr, true, { split = "below", height = 15 })
  end

  provider.create = function(data)
    local bufnr = vim.api.nvim_create_buf(true, false)
    create_win_for_buf(bufnr)
    local job_id = vim.fn.termopen(vim.o.shell, { detach = true, env = data.env })
    return CreateNeovimTerminalHandler(job_id, bufnr, create_win_for_buf)
  end

  return provider
end

return M
