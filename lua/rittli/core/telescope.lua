local M = {}
---@type string
M.last_runned_task_name = ""


local task_manager = require("rittli.core.task_manager")
local config = require("rittli.config").config
local str_custom = require("rittli.utils.string_custom_functions")

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")

local custom_actions = {}

custom_actions.reuse_as_template = function(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  local path_to_folder_with_tasks = string.format("%s/%s/", vim.uv.cwd(), config.folder_name_with_tasks)
  if vim.fn.isdirectory(path_to_folder_with_tasks) == 0 then
    vim.fn.mkdir(path_to_folder_with_tasks)
  end

  actions.close(prompt_bufnr)
  local template_name = vim.fn.input({prompt = "Enter template name"})
  local copy_to = path_to_folder_with_tasks .. template_name .. ".lua"
  if vim.fn.filereadable(copy_to) == 1 then
    vim.notify("ABORT: File with this name already exists!", vim.log.levels.ERROR)
    return
  end

  vim.uv.fs_copyfile(entry.filename, copy_to)
  vim.cmd(string.format("edit %s", copy_to))
  vim.cmd(string.format("%s", entry.lnum))
end

custom_actions.launch_the_picked_task = function(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  actions.close(prompt_bufnr)
  ---@type Task
  local task = selection.value
  M.launch_task(task)
end

M.tasks_picker = function(opts)
  opts = opts or {}
  local picker = pickers.new(opts, {
    prompt_title = "SelectTaskToLaunch",
    finder = finders.new_table({
      results = task_manager.collect_tasks(),
      entry_maker = function(task)
        return {
          value = task,
          display = function()
            local str_custom = require("rittli.utils.string_custom_functions")
            local task_name_max_len = 15
            local task_name = str_custom.shrink_line(task.name, task_name_max_len)
            task_name = str_custom.justify_str_left(task_name, task_name_max_len + 5, " ")
            local file_path = vim.fn.fnamemodify(task.task_source_file_path, ":~")

            return task_name .. string.format("[%s]", file_path)
          end,
          ordinal = task.name,
          filename = task.task_source_file_path,
          lnum = task.task_begin_line_number,
        }
      end,
    }),
    previewer = conf.grep_previewer({}),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map({ "i", "n" }, "<C-r>", custom_actions.reuse_as_template)
      map({ "i", "n" }, "<Enter>", custom_actions.launch_the_picked_task)
      return true
    end,
    on_complete = {
      -- this function executes when whe open a picker. Post below helps me a lot
      -- https://www.reddit.com/r/neovim/comments/1cdu23m/multiselect_in_telescope_is_it_possible_for_me_to/
      -- We use this option to preselect the entry with the last runned task!

      function(picker)
        if not M.last_runned_task_name then
          return
        end

        local i = 1
        for entry in picker.manager:iter() do
          if entry.value.name == M.last_runned_task_name then
            picker:set_selection(picker:get_row(i))
            return
          end
          i = i + 1
        end
      end,
    },
  })
  picker:find()
end

M.run_last_runned_task = function(opts)
  local task = task_manager.get_task_by_name(M.last_runned_task_name)
  if not task then
    M.tasks_picker(opts)
  else
    M.launch_task(task)
  end
end

---@param task Task
function M.launch_task(task)
  if task.last_terminal_handler and task.last_terminal_handler.is_alive() then
    task:rerun(task.last_terminal_handler)
    task.last_terminal_handler.focus()
    M.last_runned_task_name = task.name
    vim.api.nvim_exec_autocmds("User", { pattern = "TaskLaunched" })
  else
    local res = task:launch(config.terminal_provider)
    if not res.is_success then
      vim.notify(string.format("ABORT: %s", res.error_msg), vim.log.levels.ERROR)
      vim.cmd("Telescope resume")
    end
  end
end

return M