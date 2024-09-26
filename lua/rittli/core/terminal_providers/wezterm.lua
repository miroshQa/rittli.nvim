local utils = require("rittli.utils")

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
    get_name = function()
      return "Wezterm pane_id: " .. pane_id
    end
  }
  return handler
end


function CreateTmuxTerminalProvider(create_function)
  ---@type ITerminalProvider
  local provider = {
    create = function(opts)
      return create_function(opts)
    end,
    attach = Local.attach,
    get_all_available_handlers = function()
      local res = {}
      local panes = vim.json.decode(vim.system({"wezterm", "cli", "list", "--format", "json"}):wait().stdout)
      if not panes then
        return res
      end
      for _, pane_info in ipairs(panes) do
        if os.getenv("WEZTERM_PANE") ~= pane_info.pane_id then
          table.insert(res, CreateWeztermTerminalHandler(pane_info.pane_id))
        end
      end
      return res
    end,
  }
  return provider
end

function M.CreateTabProvider()
  local function create_function(opts)
    local cmd = { "wezterm", "cli", "spawn", "--cwd", vim.uv.cwd() }
    local obj = vim.system(cmd, { env = opts.env }):wait()
    local pane_id = utils.rm_endline(obj.stdout)
    return CreateWeztermTerminalHandler(pane_id)
  end
  return CreateTmuxTerminalProvider(create_function)
end

---@param split_direction string? Specify split direction. Default is 'bottom'. Possible values: 'left', 'right', 'top'
---@param percent number? Specify the number of cells that the new split should have, expressed as a percentage of the available space. Default is 50
function M.CreateSplitProvider(split_direction, percent)
  split_direction = split_direction or "bottom"
  percent = 50 or percent
  local function create_function(opts)
    local cmd = { "wezterm", "cli", "split-pane", "--" .. split_direction, "--percent", percent, "--cwd", vim.uv.cwd() }
    ---BUG: This code below doesn't set env variables
    local obj = vim.system(cmd, { env = opts.env }):wait()
    local pane_id = utils.rm_endline(obj)
    return CreateWeztermTerminalHandler(pane_id)
  end

  return CreateTmuxTerminalProvider(create_function)
end

function M.CreateMasterLayoutProvider()
  local split_direction = "bottom"

  local function create_function(opts)
    local right_pane = Local.get_right_pane()
    if right_pane == vim.fn.getenv("WEZTERM_PANE") then
      split_direction = "right"
    end

    local cmd =
    { "wezterm", "cli", "split-pane", "--" .. split_direction, "--pane-id", right_pane, "--cwd", vim.uv.cwd() }
    local obj = vim.system(cmd, {}):wait()
    local pane_id = utils.rm_endline(obj.stdout)

    split_direction = "bottom"
    return CreateWeztermTerminalHandler(pane_id)
  end

  return CreateTmuxTerminalProvider(create_function)
end

function Local.get_right_pane()
  local res = vim.system({ "wezterm", "cli", "get-pane-direction", "Right" }):wait()
  return res.stdout == "" and vim.fn.getenv("WEZTERM_PANE") or utils.rm_endline(res.stdout)
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
