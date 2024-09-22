local M = {}
local Local = {}

local function CreateWeztermTerminalHandler(pane_id)
  ---@type ITerminalHandler
  local handler = {
    execute_command = function(command)
      local cmd = { "wezterm", "cli", "send-text", "--pane-id", pane_id, "--no-paste", command .. "\n" }
      vim.system(cmd):wait()
    end,
    focus = function()
      vim.system({ "wezterm", "cli", "activate-pane", "--pane-id", pane_id }):wait()
    end,
    is_alive = function()
      return Local.is_pane_alive(pane_id)
    end,
    get_info_to_reattach = function()
      return pane_id
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
    attach = Local.attach,
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
    attach = Local.attach,
  }

  return provider
end

function M.CreateVerticalHorizontalSplitProvider()
  local split_direction = "right"

  ---@type ITerminalProvider
  local provider = {
    create = function()
      local right_pane = Local.get_right_pane()
      local cmd =
        { "wezterm", "cli", "split-pane", "--" .. split_direction, "--pane-id", right_pane, "--cwd", vim.uv.cwd() }
      local obj = vim.system(cmd, {}):wait()
      local pane_id = string.gsub(obj.stdout, "\n$", "")

      split_direction = split_direction == "right" and "bottom" or "right"
      return CreateWeztermTerminalHandler(pane_id)
    end,
    attach = Local.attach,
  }

  return provider
end

function Local.get_right_pane()
  local res = vim.system({ "wezterm", "cli", "get-pane-direction", "Right" }):wait()
  return res.stdout == "" and vim.fn.getenv("WEZTERM_PANE") or string.gsub(res.stdout, "\n$", "")
end

function Local.is_pane_alive(pane_id)
  -- I pick just random subcommand without any side effect
  local obj = vim.system({ "wezterm", "cli", "get-pane-direction", "--pane-id", pane_id, "Next" }):wait()
  return obj.code == 0
end

function Local.attach(info)
  if not Local.is_pane_alive(info) then
    return nil
  end
  return CreateWeztermTerminalHandler(info)
end

return M
