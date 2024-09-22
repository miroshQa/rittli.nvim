local M = {}
local Local = {}

local function CreateNeovimTerminalHandler(job_id, bufnr, create_win_for_buf)
  --- We have to make a lua table (class kind of) that implements interface ITerminalHandler
  ---@type ITerminalHandler
  local handler = {
    execute_command = function(command)
      vim.fn.chansend(job_id, { command, "" })
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
      return "NOT IMPLEMENTED"
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
      local job_id = vim.fn.termopen(vim.o.shell, { detach = true, env = opts.env })
      return CreateNeovimTerminalHandler(job_id, bufnr, create_win_for_buf)
    end,
    attach = Local.attach,
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
      local job_id = vim.fn.termopen(vim.o.shell, { detach = true, env = data.env })
      return CreateNeovimTerminalHandler(job_id, bufnr, create_win_for_buf)
    end,
    attach = Local.attach,
  }

  return provider
end

--- Currently not implemented and probably never will be
--- At least until neovim starts saving the terminal sessions himself
--- https://www.reddit.com/r/neovim/comments/16a3d4x/is_terminal_session_restore_possible/
function Local.attach(info)
  return nil
end

return M
