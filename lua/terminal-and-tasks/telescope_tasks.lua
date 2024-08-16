local M = {}


local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local previewers = require "telescope.previewers"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local tasks = require "terminal-and-tasks.tasks"
local config = require("terminal-and-tasks.config").config

local custom_actions = {}
custom_actions.reuse_as_template = function(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  local path_to_folder_with_tasks = string.format("%s/%s/", vim.uv.cwd(), config.folder_name_with_tasks)
  if vim.fn.isdirectory(path_to_folder_with_tasks) == 0 then
    vim.fn.mkdir(path_to_folder_with_tasks)
  end

  local copy_to = path_to_folder_with_tasks .. vim.fs.basename(entry.filename)
  if vim.fn.filereadable(copy_to) == 1 then
    vim.notify("ABORT: This template already exists!", vim.log.levels.ERROR)
    return
  end

  vim.uv.fs_copyfile(entry.filename, copy_to)
  actions.close(prompt_bufnr)
  vim.cmd(string.format("edit %s", copy_to))
end

local function make_display(entry)
  if not config.show_file_path_in_telescope_picker then
    return entry.task.name
  end

  local file_path = vim.fn.fnamemodify(entry.task_source_file_path, ":~")
  return entry.task.name .. string.format("        [%s]", file_path)
end


M.tasks_picker = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "SelectTaskToLaunch",
    finder = finders.new_table({
      results = tasks.collect_tasks(),
      entry_maker = function(entry)
        return {
          value = entry,
          display = make_display(entry),
          ordinal = entry.task.name,
          filename = entry.task_source_file_path,
          lnum = entry.task_begin_line_number,
        }
      end
    }),
    previewer = conf.grep_previewer({}),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        tasks.run_task(selection.value.task)
        vim.fn.feedkeys("i", "n")
      end)

      map("i", "<C-r>", custom_actions.reuse_as_template)
      return true

    end,
  }):find()
end

M.run_last_runned_task = function(opts)
  if tasks.last_runned_task then
    tasks.run_task(tasks.last_runned_task)
  else
    M.tasks_picker(opts)
  end
end


return M
