local M = {}
local Local = {}

local function CreateNeovimTerminalHandler(chan_id, bufnr, create_win_for_buf)
  --- We have to make a lua table (class kind of) that implements interface ITerminalHandler
  ---@type ITerminalHandler
  local handler = {
    execute_command = function(command)
      vim.fn.chansend(chan_id, { command, "" })
    end,
    focus = function()
      local windows = vim.fn.win_findbuf(bufnr)
      local win_id = #windows > 0 and windows[1] or -1
      if win_id == -1 then
        create_win_for_buf(bufnr)
      else
        vim.fn.win_gotoid(win_id)
      end
    end,
    is_alive = function()
      return vim.fn.bufexists(bufnr) == 1
    end,
    get_info_to_reattach = function()
      return vim.api.nvim_buf_get_name(bufnr)
    end,
  }

  return handler
end

function M.CreateTabProvider()
  local function create_win_for_buf(bufnr)
    vim.cmd("tabnew")
    local tab_bufnr = vim.fn.bufnr("%")
    vim.api.nvim_command("b " .. bufnr)
    vim.api.nvim_buf_delete(tab_bufnr, {})
  end

  ---@type ITerminalProvider
  local provider = {
    create = function(opts)
      local bufnr = vim.api.nvim_create_buf(true, false)
      create_win_for_buf(bufnr)
      local chan_id = vim.fn.termopen(vim.o.shell, { detach = true, env = opts.env })
      return CreateNeovimTerminalHandler(chan_id, bufnr, create_win_for_buf)
    end,
    attach = function(buf_name)
      return Local.attach(buf_name, create_win_for_buf)
    end,
  }

  return provider
end

function M.CreateSplitProvider()
  local function create_win_for_buf(bufnr)
    vim.api.nvim_open_win(bufnr, true, { split = "below", height = 15 })
  end

  ---@type ITerminalProvider
  local provider = {
    create = function(data)
      local bufnr = vim.api.nvim_create_buf(true, false)
      create_win_for_buf(bufnr)
      local chan_id = vim.fn.termopen(vim.o.shell, { detach = true, env = data.env })
      return CreateNeovimTerminalHandler(chan_id, bufnr, create_win_for_buf)
    end,
    attach = function(buf_name)
      return Local.attach(buf_name, create_win_for_buf)
    end,
  }

  return provider
end

function Local.attach(buf_name, create_win_for_buf)
  local buff_with_term = nil
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == buf_name then
      buff_with_term = bufnr
      break
    end
  end

  if not buff_with_term then
    return nil
  end

  local chan_id = vim.api.nvim_get_option_value("channel", { buf = buff_with_term })
  return CreateNeovimTerminalHandler(chan_id, buff_with_term, create_win_for_buf)
end

return M
