local M = {}

local default_config = {
  folder_name_with_tasks = "tasks",
  disable_resource_messages = false,
  should_register_terminal_enter = function()
    return vim.fn.expand("%") ~= "NeogitConsole"
  end
}

M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", {}, default_config, opts or {})
end

return M
