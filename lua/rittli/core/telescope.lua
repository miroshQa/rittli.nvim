local M = {}

local session_manager = require("rittli.core.session_manager")
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
  local template_name = vim.fn.input({ prompt = "Enter template name" })
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
  if not selection then
    return
  end
  actions.close(prompt_bufnr)
  ---@type Task
  local task = selection.value
  M.launch_task(task)
end

custom_actions.attach_to_terminal_handler_and_launch = function()
  local selection = action_state.get_selected_entry()
  M.terminal_handlers_picker({}, selection.value)
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
      map({ "i", "n" }, "<C-a>", custom_actions.attach_to_terminal_handler_and_launch)
      map({ "i", "n" }, "<Enter>", custom_actions.launch_the_picked_task)
      return true
    end,
    on_complete = {
      -- this function executes when whe open a picker. Post below helps me a lot
      -- https://www.reddit.com/r/neovim/comments/1cdu23m/multiselect_in_telescope_is_it_possible_for_me_to/
      -- We use this option to preselect the entry with the last runned task!

      function(picker)
        local last_runned_task_name = session_manager.get_last_runned_task_name()
        if not last_runned_task_name then
          return
        end

        local i = 1
        for entry in picker.manager:iter() do
          if entry.value.name == last_runned_task_name then
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

---@param task_to_launch Task
M.terminal_handlers_picker = function(opts, task_to_launch)
  opts = {}
  local picker = pickers.new(opts, {
    prompt_title = "SelectTerminalToLaunchTask",
    finder = finders.new_table({
      results = session_manager.get_all_lonely_terminal_handlers(),
      ---@param handler ITerminalHandler
      entry_maker = function(handler)
        local id = handler.get_info_to_reattach()
        return {
          value = handler,
          display = id,
          ordinal = id,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map({ "i", "n" }, "<Enter>", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value.focus then
          return
        end
        session_manager.register_connection(task_to_launch.name, selection.value)
        actions.close(prompt_bufnr)
        M.launch_task(task_to_launch)
      end)
      return true
    end,
  })
  picker:find()
end

---@param task Task
function M.launch_task(task)
  local connection = session_manager.find_connection(task.name)
  if connection then
    task:rerun(connection.terminal_handler)
    connection.terminal_handler.focus()
  else
    local res = task:launch(config.terminal_provider)
    if not res.is_success then
      vim.notify(string.format("ABORT: %s", res.error_msg), vim.log.levels.ERROR)
      vim.cmd("Telescope resume")
      return
    end
    session_manager.register_connection(task.name, res.terminal_handler)
  end
end

return M
