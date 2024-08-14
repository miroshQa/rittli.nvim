local M = {}


local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local previewers = require "telescope.previewers"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local tasks = require "terminal-and-tasks.tasks"

M.tasks_picker = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "SelectTaskToLaunch",
    finder = finders.new_table({
      results = tasks.collect_tasks(),
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.task.name,
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
