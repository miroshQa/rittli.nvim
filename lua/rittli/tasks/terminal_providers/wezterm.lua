local function create_terminal_handler(info)
  local terminal_handler = {}

  terminal_handler.execute_command = function(command)
    local cmd = {
      "wezterm", "cli", "send-text", "--pane-id", info.pane_id, "--no-paste", command .. "\n"
    }
    vim.system(cmd):wait()
  end

  terminal_handler.focus = function()
  end

  return terminal_handler
end


local terminal_provider = {}


terminal_provider.create = function(opts)

  local pane_id = "";
  local function catch_pane_id(obj)
    pane_id =  string.gsub(obj.stdout, "\n$", "")
    print(string.format("pane id is %s", pane_id))
  end

  -- We need vim.system cmd field can only accept 2 arguments!!! First argument is the program to execute.
  -- Second and further arguments is the arguments
  -- It is like unix exec family functions
  -- like in C. int main(int argc, char** argv). cmd[1] = argv[1], cmd[2] = argv[2], cmd[3] = argv[3]
  local obj = vim.system({"wezterm", "cli", "spawn"}, {}, catch_pane_id):wait()
  return create_terminal_handler({pane_id = pane_id})
end


return terminal_provider
