local last_entered_tab = nil
local tabs_list_before_close = {}
-- Default behaviour when close tab:
-- If tab is on the last position then go to the previous tab.
-- If tab is not on the last position the go to the next tab
-- Desired behaviour: Go always to the previous tab
vim.api.nvim_create_autocmd("TabEnter", {
  callback = function()
    last_entered_tab = vim.api.nvim_win_get_tabpage(0)
    tabs_list_before_close = vim.api.nvim_list_tabpages()
  end
})

vim.api.nvim_create_autocmd("TabClosed", {
  callback = function()
    if tabs_list_before_close[#tabs_list_before_close] ~= last_entered_tab then
      vim.cmd("tabp")
    end
  end
})
