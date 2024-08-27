local M = {}

M.config = {
  global_tasks_dir_path_tail = vim.fn.stdpath('config') .. "/lua",
  folder_name_with_tasks = "tasks",
  -- full path to global tasks dir = global_tasks_dir_path_tail + "/" + folder_name_with_tasks
  disable_resource_messages = false,
  disable_local_tasks_updater_messages = false,
  show_file_path_in_telescope_picker = true,
  should_register_terminal_enter = function()
    return vim.fn.expand("%") ~= "NeogitConsole"
  end,
  remember_last_task = true,
  reload_last_task_when_cwd_changes = true,
  create_window_for_terminal = function(bufnr)
    vim.cmd("tabnew")
    local tab_bufnr = vim.fn.bufnr("%")
    vim.api.nvim_command("b " .. bufnr)
    vim.api.nvim_buf_delete(tab_bufnr, {})
  end,
}

return M
