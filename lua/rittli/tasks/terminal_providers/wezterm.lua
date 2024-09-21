local M = {}

---@param pane_id string
---@return WeztermTerminalHandler
local function CreateWeztermTerminalHandler(pane_id)
  ---@class WeztermTerminalHandler: ITerminalHandler
  local terminal_handler = {}

  terminal_handler.execute_command = function(command)
    local cmd = {
      "wezterm",
      "cli",
      "send-text",
      "--pane-id",
      pane_id,
      "--no-paste",
      command .. "\n",
    }
    vim.system(cmd):wait()
  end

  terminal_handler.focus = function()
    vim.system({ "wezterm", "cli", "activate-pane", "--pane-id", pane_id }):wait()
  end

  terminal_handler.is_alive = function()
    -- I pick just random subcommand without any side effect
    local obj = vim.system({ "wezterm", "cli", "get-pane-direction", "--pane-id", pane_id, "Next" }):wait()
    return obj.code == 0
  end

  return terminal_handler
end

function M.CreateTabProvider()
  ---@class WeztermTabTerminalProvider: ITerminalProvider
  local provider = {}

  provider.create = function()
    local cmd = { "wezterm", "cli", "spawn", "--cwd", vim.uv.cwd() }
    local obj = vim.system(cmd, {}):wait()
    local pane_id = string.gsub(obj.stdout, "\n$", "")
    return CreateWeztermTerminalHandler(pane_id)
  end

  return provider
end

---@param split_direction string? Specify split direction. Default is 'bottom'. Possible values: 'left', 'right', 'top'
---@param percent number? Specify the number of cells that the new split should have, expressed as a percentage of the available space. Default is 50
function M.CreateSplitProvider(split_direction, percent)
  split_direction = split_direction or "bottom"
  percent = 50 or percent
  ---@class WeztermSplitTerminalProvider: ITerminalProvider
  local provider = {}

  provider.create = function()
    local cmd =  { "wezterm", "cli", "split-pane", "--" .. split_direction, "--percent", percent, "--cwd", vim.uv.cwd()}
    local obj = vim.system(cmd, {}):wait()
    local pane_id = string.gsub(obj.stdout, "\n$", "")
    return CreateWeztermTerminalHandler(pane_id)
  end

  return provider
end

return M
