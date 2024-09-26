local utils = require("rittli.utils")

local M = {}

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
    get_name = function()
      return vim.api.nvim_buf_get_name(bufnr)
    end,
  }

  return handler
end

local function CreateNeovimTerminalProvider(create_win_for_buf)
  local function attach(buf_name)
    local buff_with_term = utils.find_bufnr_by_name(buf_name)
    if not buff_with_term then
      return nil
    end

    if not vim.api.nvim_buf_is_loaded(buff_with_term) then
      vim.fn.bufload(buff_with_term)
    end

    local chan_id = vim.api.nvim_get_option_value("channel", { buf = buff_with_term })
    if chan_id == 0 then
      return nil
    end
    return CreateNeovimTerminalHandler(chan_id, buff_with_term, create_win_for_buf)
  end

  ---@type ITerminalProvider
  local provider = {
    create = function(opts)
      local bufnr = vim.api.nvim_create_buf(true, false)
      create_win_for_buf(bufnr)
      local chan_id = vim.fn.termopen(vim.o.shell, { detach = true, env = opts.env })
      return CreateNeovimTerminalHandler(chan_id, bufnr, create_win_for_buf)
    end,
    attach = attach,
    get_all_available_handlers = function()
      local result = {}
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        if string.sub(buf_name, 1, 7) == "term://" then
          print("go attach")
          table.insert(result, attach(buf_name))
        end
      end
      return result
    end,
  }

  return provider
end

function M.CreateTabProvider()
  local function create_win_for_buf(bufnr)
    vim.cmd("tabnew")
    local tab_bufnr = vim.fn.bufnr("%")
    vim.api.nvim_command("b " .. bufnr)
    vim.api.nvim_buf_delete(tab_bufnr, {})
  end
  return CreateNeovimTerminalProvider(create_win_for_buf)
end

---@param direction string? Split direction. Possible values: left, right, below, above. Default: below
---@param height number? Split height. Default: 15
function M.CreateSplitProvider(direction, height)
  direction = direction or "below"
  height = height or 15
  local function create_win_for_buf(bufnr)
    vim.api.nvim_open_win(bufnr, true, { split = direction, height = height })
  end
  return CreateNeovimTerminalProvider(create_win_for_buf)
end

function M.CreateFloatProvider()
  local create_win_for_buf = function(bufnr)
    local curved = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
    local width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 20)))
    local height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 10)))

    local row = math.ceil(vim.o.lines - height) * 0.5 - 1
    local col = math.ceil(vim.o.columns - width) * 0.5 - 1

    local win_settings = { row = row, col = col, relative = "editor", width = width, height = height, border = curved }
    vim.api.nvim_open_win(bufnr, true, win_settings)
  end
  return CreateNeovimTerminalProvider(create_win_for_buf)
end

return M
