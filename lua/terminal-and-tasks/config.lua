local M = {}

M.config = {
  folder_name_with_tasks = "tasks",
  disable_resource_messages = false,
  disable_local_tasks_updater_messages = false,
  show_file_path_in_telescope_picker = true,
  should_register_terminal_enter = function()
    return vim.fn.expand("%") ~= "NeogitConsole"
  end,
  remember_last_task = true,
  create_window_for_terminal = function(bufnr)
    vim.cmd("tabnew")
    local tab_bufnr = vim.fn.bufnr("%")
    vim.api.nvim_command("b " .. bufnr)
    vim.api.nvim_buf_delete(tab_bufnr, {})
  end
}

return M
