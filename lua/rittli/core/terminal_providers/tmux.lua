local utils = require("rittli.utils")

local M = {}
local Local = {}

local function CreateTmuxTerminalHandler(pane_id)
  ---@type ITerminalHandler
  local handler = {
    execute_command = function(command)
      vim.system({ "tmux", "send-keys", "-t", pane_id, command, "C-m" }):wait()
    end,
    focus = function()
      vim.system({ "tmux", "select-pane", "-t", pane_id }):wait()
    end,
    is_alive = function()
      return Local.is_pane_alive(pane_id)
    end,
    get_info_to_reattach = function()
      return pane_id
    end,
    get_name = function()
      return "Tmux pane_id: " .. pane_id
    end,
    get_text = function()
      local res = {}
      local obj = vim.system({"tmux", "capture-pane", "-t", pane_id, "-p"}):wait()
      for s in string.gmatch(obj.stdout, "[^\r\n]+") do
        table.insert(res, s)
      end
      return res
    end,
  }
  return handler
end

function CreateTmuxTerminalProvider(create_function)
  ---@type ITerminalProvider
  local provider = {
    create = function(opts)
      return create_function(opts)
    end,
    attach = function(pane_id)
      if Local.is_pane_alive(pane_id) then
        return CreateTmuxTerminalHandler(pane_id)
      end
      return nil -- Not implemented yet
    end,
    get_all_available_handlers = function()
      local res = {}
      local panes = vim.system({ "tmux", "list-panes", "-F", "#{pane_id}" }):wait().stdout
      if not panes then
        return res
      end
      local focused_pane_id =
          utils.rm_endline(vim.system({ "tmux", "display-message", "-p", "#{pane_id}" }):wait().stdout)
      for pane_id in string.gmatch(panes, "([^\n]+)") do
        pane_id = utils.rm_endline(pane_id)
        if focused_pane_id ~= pane_id then
          table.insert(res, CreateTmuxTerminalHandler(pane_id))
        end
      end
      return res
    end,
  }
  return provider
end

function M.CreateSplitProvider()
  local function create_function()
    local cmd = { "tmux", "split-window", "-P", "-F", "#{pane_id}" }
    local obj = vim.system(cmd):wait()
    local pane_id = utils.rm_endline(obj.stdout)
    return CreateTmuxTerminalHandler(pane_id)
  end
  return CreateTmuxTerminalProvider(create_function)
end

function Local.is_pane_alive(pane_id)
  local cmd = { "tmux", "send-keys", "-t", pane_id }
  local obj = vim.system(cmd):wait()
  return obj.code == 0
end

return M
