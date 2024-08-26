local tasks_manager = require("rittl.tasks.task_manager")
local config = require("rittl.config").config

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
  local task_container = tasks_manager.get_task_container_by_name(cwd_last_task_name)
  if task_container then
    tasks_manager.last_runned_task_name = cwd_last_task_name
  end
end


initialize_last_runned_tasks()
set_last_task_for_cwd()

vim.api.nvim_create_autocmd("User", {
  pattern = "TaskLaunched",
  group = vim.api.nvim_create_augroup("LastTasksPerDirCacher", {clear = true}),
  callback = function()
    last_tasks_name_per_dir[vim.uv.cwd()] = tasks_manager.last_runned_task_name
  end
})

if config.reload_last_task_when_cwd_changes then
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("UpdateLastTask", {clear = true}),
    callback = function()
      set_last_task_for_cwd()
    end
  })
end

vim.api.nvim_create_autocmd("VimLeave", {
  group = vim.api.nvim_create_augroup("LastTasksSaveOnVimExit", {clear = true}),
  callback = function()
    serialize_last_runned_tasks()
  end
})
