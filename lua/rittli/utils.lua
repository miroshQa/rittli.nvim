local M = {}

function M.shrink_line(line, max_length)
  if #line > max_length then
    return line:sub(1, max_length - 3) .. "..."
  else
    return line
  end
end

function M.justify_str_left(line, new_len, filler)
  if new_len <= #line then
    return line
  end
  local len_diff = new_len - #line
  return line .. string.rep(filler, len_diff)
end

function M.split_string(str, delimiter)
  local result = {}
  for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

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
