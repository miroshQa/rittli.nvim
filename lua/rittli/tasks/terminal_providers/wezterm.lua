local M = {}

local function TerminalHandler(info)
  local terminal_handler = {}

  terminal_handler.execute_command = function(command)
    local cmd = {
      "wezterm",
      "cli",
      "send-text",
      "--pane-id",
      info.pane_id,
      "--no-paste",
      command .. "\n",
    }
    vim.system(cmd):wait()
  end

  terminal_handler.focus = function() end

  return terminal_handler
end

M.TabProvider = function(opts)
  ---@class WeztermTabProvider
  local tab_provider = {}

  tab_provider.create = function()
    local pane_id = ""
    local function catch_pane_id(obj)
      pane_id = string.gsub(obj.stdout, "\n$", "")
    end
    local obj = vim.system({ "wezterm", "cli", "spawn" }, {}, catch_pane_id):wait()
    return TerminalHandler({ pane_id = pane_id })
  end

  return tab_provider
end

M.SplitProvider = function(opts)
  local split_provider = {}

  split_provider.create = function(opts)
    local pane_id = ""
    local function catch_pane_id(obj)
      pane_id = string.gsub(obj.stdout, "\n$", "")
    end

    local obj = vim.system({ "wezterm", "cli", "split-pane" }, {}, catch_pane_id):wait()
    return TerminalHandler({ pane_id = pane_id })
  end
end

return M
