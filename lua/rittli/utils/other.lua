local M = {}

-- https://www.reddit.com/r/neovim/comments/thynt9/what_api_to_get_the_current_count_of_windows/
function M.get_all_windows_in_cur_tabpage()
  local list = vim.api.nvim_tabpage_list_wins(0)
  local res = {}
  local function is_floating(win_id)
    local cfg = vim.api.nvim_win_get_config(win_id)
    if cfg.relative > "" or cfg.external then
      return true
    end
    return false
  end

  for _, win_id in pairs(list) do
    if not is_floating(win_id) then
      table.insert(res, win_id)
    end
  end
  return res
end

return M
