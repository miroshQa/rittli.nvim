local tasks_manager = require("terminal-and-tasks.tasks.task_manager")

local cache_file_path = vim.fn.stdpath("cache") .. "/last_tasks_cache.json"
local last_tasks_name_per_dir = {}

local function initialize_last_runned_tasks()
  if vim.fn.filereadable(cache_file_path) == 1 then
    local file = io.open(cache_file_path, "r")
    local text = file:read("*a")
    local is_success, res = pcall(vim.json.decode, text)
    if not is_success then
      os.remove(cache_file_path)
      return
    end
    last_tasks_name_per_dir = res
  end
end

local function serialize_last_runned_tasks()
  local file = io.open(cache_file_path, "w+")
  local text = vim.json.encode(last_tasks_name_per_dir)
  file:write(text)
end

local function set_last_task_for_cwd()
  local cwd_last_task_name = last_tasks_name_per_dir[vim.uv.cwd()]
  if cwd_last_task_name then
    tasks_manager.set_new_last_runned_task_by_name(cwd_last_task_name)
  end
end


initialize_last_runned_tasks()
set_last_task_for_cwd()

vim.api.nvim_create_autocmd("User", {
  pattern = "TaskLaunched",
  group = vim.api.nvim_create_augroup("LastTasksPerDirCacher", {clear = true}),
  callback = function()
    last_tasks_name_per_dir[vim.uv.cwd()] = tasks_manager.get_last_runned_task().name
  end
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = vim.api.nvim_create_augroup("UpdateLastTask", {clear = true}),
  callback = function()
    set_last_task_for_cwd()
  end
})

vim.api.nvim_create_autocmd("VimLeave", {
  group = vim.api.nvim_create_augroup("LastTasksSaveOnVimExit", {clear = true}),
  callback = function()
    serialize_last_runned_tasks()
  end
})