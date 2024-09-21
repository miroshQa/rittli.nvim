local neovim_terminal_provider = require("rittli.core.terminal_providers.neovim").CreateTabProvider()
local utils = require("rittli.utils.other")

local M = {}

---@class TerminalEnterInfo
---@field bufnr number
---@field winid number
---@field window_config vim.api.keyset.win_config
---@field windows_in_the_tab number[]

---@type TerminalEnterInfo[]
local terminals_enters_stack = {}

local function keep_pop_until_find_existing_terminal()
  while #terminals_enters_stack ~= 0 do
    local enter_info = terminals_enters_stack[#terminals_enters_stack]
    if vim.api.nvim_buf_is_valid(enter_info.bufnr) then
      return
    end
    table.remove(terminals_enters_stack)
  end
end

local function register_terminal_enter()
  ---@type TerminalEnterInfo
  local enter_info = {
    winid = vim.fn.win_getid(),
    bufnr = vim.fn.bufnr("%"),
    windows_in_the_tab = utils.get_all_windows_in_cur_tabpage(),
    window_config = vim.api.nvim_win_get_config(0),
  }
  table.insert(terminals_enters_stack, enter_info)
end

function M.toggle_last_openned_terminal()
  keep_pop_until_find_existing_terminal()
  if #terminals_enters_stack == 0 then
    neovim_terminal_provider.create({})
    return
  end

  local last_enter_info = terminals_enters_stack[#terminals_enters_stack]

  -- Case when the terminal is currently focused
  if last_enter_info.winid == vim.fn.win_getid() then
    vim.api.nvim_command("hide")
    return
  end

  -- Case when the terminal is not currently focused (Buffer exists and window does not)
  if vim.api.nvim_win_is_valid(last_enter_info.winid) then
    vim.fn.win_gotoid(last_enter_info.winid)
  else
    -- HACK: We need this hack because window_config can't restore window properly if it was opened in a new tab
    if #last_enter_info.windows_in_the_tab == 1 then
      vim.cmd("tabnew")
      local tab_bufnr = vim.fn.bufnr("%")
      vim.api.nvim_command("b " .. last_enter_info.bufnr)
      vim.api.nvim_buf_delete(tab_bufnr, {})
    else
      vim.api.nvim_open_win(last_enter_info.bufnr, true, last_enter_info.window_config)
    end
  end
end

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.api.nvim_command("set ft=terminal")
    -- Doesn't work without vim.schedule properly
    -- I definitely should read about main event-loop somewhere
    -- https://en.wikipedia.org/wiki/Event_loop
    -- :help event-loop
    vim.schedule(function()
      vim.api.nvim_command("startinsert")
    end)
    vim.api.nvim_command("setlocal nonumber norelativenumber signcolumn=no")
    register_terminal_enter()
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("TerminalEnterRegistrator", { clear = true }),
  callback = function()
    if vim.bo.filetype == "terminal" then
      vim.schedule(function()
        vim.api.nvim_command("startinsert")
      end)
      register_terminal_enter()
    end
  end,
})

return M