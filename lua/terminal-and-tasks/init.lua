-- https://miguelcrespo.co/posts/how-to-write-a-neovim-plugin-in-lua/
-- this file executes when we run require("terminal-and-tasks")
-- print("Hello from init.lua")

local M = {}

local config = require("terminal-and-tasks.config")

function M.setup(opts)
  config.config = vim.tbl_deep_extend("force", {}, config.config, opts or {})
  require("terminal-and-tasks.terminal_tweaks")
  require("terminal-and-tasks.tabs_tweaks")
  require("terminal-and-tasks.tasks")
end


return M



