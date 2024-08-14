require("terminal-and-tasks.tabs_tweaks")


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
    vim.api.nvim_command("set ft=terminal | startinsert")
    vim.api.nvim_command("setlocal nonumber norelativenumber signcolumn=no")
    register_terminal_enter()
  end,
})

vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  callback = function()
    if vim.bo.filetype == "terminal" then
      vim.api.nvim_command("startinsert")
      register_terminal_enter()
    end
  end,
})

return M
