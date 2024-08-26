# Configuration recipes

## Open a terminal in float window

```lua
opts = {
  create_window_for_terminal = function(bufnr)
    local curved = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }

    local width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 20)))
    local height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 10)))

    local row = math.ceil(vim.o.lines - height) * 0.5 - 1
    local col = math.ceil(vim.o.columns - width) * 0.5 - 1


    local win_settings = {
      row = row,
      col = col,
      relative = "editor",
      width = width,
      height = height,
      border = curved,
    }
    vim.api.nvim_open_win(bufnr, true, win_settings)
  end
}
```

## Open in vertical split below
```lua
opts = {
  create_window_for_terminal = function(bufnr)
    vim.api.nvim_open_win(bufnr, true, {split = "below", height = 15})
  end
}
```
