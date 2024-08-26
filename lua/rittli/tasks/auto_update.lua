local config = require("rittli.config").config
local task_manager = require("rittli.tasks.task_manager")

-- see :help autocmd-pattern
-- We need to dublicate code unfortunately
local patterns = {
  string.format("%s/lua/%s/*/*.lua", vim.fn.stdpath("config"), config.folder_name_with_tasks),
  string.format("%s/lua/%s/*.lua", vim.fn.stdpath("config"), config.folder_name_with_tasks),
  string.format("%s/%s/*.lua", vim.uv.cwd(), config.folder_name_with_tasks),
  string.format("%s/%s/*/*.lua", vim.uv.cwd(), config.folder_name_with_tasks),
}

vim.api.nvim_create_autocmd("DirChangedPre", {
  pattern = { "window", "global" }, -- window pattern is required for NeoTree
  group = vim.api.nvim_create_augroup("LocalTasksUpdater", { clear = true }),
  callback = function()
    local new_cwd = vim.v.event.directory
    local current_cwd = vim.uv.cwd()
    local current_local_tasks_pattern = string.format("%s/%s/**/*.lua", current_cwd, config.folder_name_with_tasks)
    local files = vim.fn.glob(current_local_tasks_pattern, false, true)

    task_manager.clear_tasks_loaded_from_files(files)
    local new_local_tasks_pattern = string.format("%s/%s/**/*.lua", new_cwd, config.folder_name_with_tasks)
    task_manager.load_tasks_from_files(vim.fn.glob(new_local_tasks_pattern, false, true))
    patterns[3] = string.format("%s/%s/*.lua", new_cwd, config.folder_name_with_tasks)
    patterns[4] = string.format("%s/%s/*/*.lua", new_cwd, config.folder_name_with_tasks)

    if not config.disable_local_tasks_updater_messages then
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.notify(
        string.format("Local tasks reloaded: New cwd: %s", vim.fn.fnamemodify(new_cwd, ":~")),
        vim.log.levels.INFO
      )
    end
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = patterns,
  group = vim.api.nvim_create_augroup("TasksReloaderRegistrator", { clear = true }),
  callback = function(data)
    local file_path = data.match
    task_manager.register_file_with_tasks_for_update(file_path)
  end,
})
