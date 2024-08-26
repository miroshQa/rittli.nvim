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

return M
