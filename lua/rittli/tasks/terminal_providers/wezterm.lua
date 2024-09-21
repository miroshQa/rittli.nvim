local M = {}

---@param pane_id string
---@return WeztermTerminalHandler
local function TerminalHandler(pane_id)
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
    vim.system({"wezterm", "cli", "activate-pane", "--pane-id", pane_id}):wait()
  end

  terminal_handler.is_alive = function()
    -- I pick just random subcommand without any side effect
    local obj = vim.system({"wezterm", "cli", "get-pane-direction", "--pane-id", pane_id "Next"}):wait()
    return obj.code == 0
  end

  return terminal_handler
end

local function CreateWeztermProvider(cmd)
  ---@class WeztermTerminalProvider
  local tab_provider = {}

  tab_provider.create = function()
    local obj = vim.system(cmd, {}):wait()
    local pane_id = string.gsub(obj.stdout, "\n$", "")
    return TerminalHandler(pane_id)
  end

  return tab_provider
end


function M.CreateTabProvider()
  return CreateWeztermProvider({"wezterm", "cli", "spawn"})
end

function M.CreateSplitProvider()
  return CreateWeztermProvider({"wezterm", "cli", "split-pane"})
end


return M
