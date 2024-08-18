local config = require("terminal-and-tasks.config").config

local M = {}

local terminals_enters_stack = {}
-- It stores the followings items
-- local terminals_enters_stack = {
--   {
--     openned_terminal_buffer_number = nil,
--     openned_terminal_window_id = nil,
--   }
-- }


local function keep_pop_until_find_existing_terminal()
  while #terminals_enters_stack ~= 0 do
    local enter_info = terminals_enters_stack[#terminals_enters_stack]
    if vim.api.nvim_buf_is_valid(enter_info.openned_terminal_buffer_number) then
      return
    end
    table.remove(terminals_enters_stack)
  end
end

local function register_terminal_enter()
  local openned_terminal_info = {
    openned_terminal_window_id = vim.fn.win_getid(),
    openned_terminal_buffer_number = vim.fn.bufnr('%')
  }
  table.insert(terminals_enters_stack, openned_terminal_info)
end


function M.toggle_last_openned_terminal()
  keep_pop_until_find_existing_terminal()
  if #terminals_enters_stack == 0 then
    vim.api.nvim_command("tabnew | terminal")
    return
  end

  local last_enter_info = terminals_enters_stack[#terminals_enters_stack]
  if last_enter_info.openned_terminal_window_id == vim.fn.win_getid() then
    vim.api.nvim_command("hide")
  elseif vim.api.nvim_win_is_valid(last_enter_info.openned_terminal_window_id)  then
    vim.fn.win_gotoid(last_enter_info.openned_terminal_window_id)
  else
    vim.api.nvim_command("tab sb " .. last_enter_info.openned_terminal_buffer_number)
    last_enter_info.openned_terminal_window_id = vim.fn.win_getid()
  end
end

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.api.nvim_command("set ft=terminal")
    -- Doesn't work without vim.schedule properly
    -- I definitely should read about main event-loop somewhere
    -- https://en.wikipedia.org/wiki/Event_loop
    -- :help event-loop
    vim.schedule(function() vim.api.nvim_command("startinsert") end)
    vim.api.nvim_command("setlocal nonumber norelativenumber signcolumn=no")
    if config.should_register_terminal_enter() then
      register_terminal_enter()
    end
  end,
})

vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  group = vim.api.nvim_create_augroup("TerminalEnterRegistrator", {clear = true}),
  callback = function()
    if vim.bo.filetype == "terminal" and config.should_register_terminal_enter() then
      vim.schedule(function() vim.api.nvim_command("startinsert") end)
      register_terminal_enter()
    end
  end,
})

return M
