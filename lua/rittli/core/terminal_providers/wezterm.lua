local M = {}

local function CreateWeztermTerminalHandler(pane_id)
  ---@type ITerminalHandler
  local handler = {
    execute_command = function(command)
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
    end,

    focus = function()
      vim.system({ "wezterm", "cli", "activate-pane", "--pane-id", pane_id }):wait()
    end,

    is_alive = function()
      -- I pick just random subcommand without any side effect
      local obj = vim.system({ "wezterm", "cli", "get-pane-direction", "--pane-id", pane_id, "Next" }):wait()
      return obj.code == 0
    end,
  }

  return handler
end

function M.CreateTabProvider()
  ---@type ITerminalProvider
  local provider = {
    create = function(opts)
      local cmd = { "wezterm", "cli", "spawn", "--cwd", vim.uv.cwd() }
      local obj = vim.system(cmd, { env = opts.env }):wait()
      local pane_id = string.gsub(obj.stdout, "\n$", "")
      return CreateWeztermTerminalHandler(pane_id)
    end,
  }

  return provider
end

---@param split_direction string? Specify split direction. Default is 'bottom'. Possible values: 'left', 'right', 'top'
---@param percent number? Specify the number of cells that the new split should have, expressed as a percentage of the available space. Default is 50
function M.CreateSplitProvider(split_direction, percent)
  split_direction = split_direction or "bottom"
  percent = 50 or percent
  ---@type ITerminalProvider
  local provider = {
    create = function(opts)
      local cmd =
      { "wezterm", "cli", "split-pane", "--" .. split_direction, "--percent", percent, "--cwd", vim.uv.cwd() }
      local obj = vim.system(cmd, { env = opts.env }):wait()
      local pane_id = string.gsub(obj.stdout, "\n$", "")
      return CreateWeztermTerminalHandler(pane_id)
    end,
  }

  return provider
end

function M.CreateVerticalHorizontalSplitProvider()
  local split_direction = "right"
  local prev_pane_id = nil

  ---@type ITerminalProvider
  local provider = {
    create = function()
      prev_pane_id = prev_pane_id or vim.fn.getenv("WEZTERM_PANE")
      local cmd =
      { "wezterm", "cli", "split-pane", "--" .. split_direction, "--pane-id", prev_pane_id, "--cwd", vim.uv.cwd() }
      local obj = vim.system(cmd, {}):wait()
      local pane_id = string.gsub(obj.stdout, "\n$", "")
      prev_pane_id = pane_id

      split_direction = split_direction == "right" and "bottom" or "right"
      return CreateWeztermTerminalHandler(pane_id)
    end,
  }

  return provider
end

return M
