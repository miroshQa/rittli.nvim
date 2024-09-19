local function create_terminal_handler(info)
  ---@class TerminalHandler
  local terminal_handler = {}

  terminal_handler.execute_command = function(command)
    vim.fn.chansend(info.job_id, { command, "" })
  end

  terminal_handler.focus = function()
  end

  return terminal_handler
end


---@class TerminalProvider
local terminal_provider = {}

terminal_provider.create = function(opts)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.cmd("tabnew")
  local tab_bufnr = vim.fn.bufnr("%")
  vim.api.nvim_command("b " .. bufnr)
  vim.api.nvim_buf_delete(tab_bufnr, {})
  local job_id = vim.fn.termopen(vim.o.shell, { detach = true, env = opts.env })
  return create_terminal_handler({ job_id = job_id })
end


return terminal_provider
