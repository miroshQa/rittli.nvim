-- https://miguelcrespo.co/posts/how-to-write-a-neovim-plugin-in-lua/
-- this file executes when we run require("terminal-and-tasks")
-- print("Hello from init.lua")


local M = {}

local config = require("terminal-and-tasks.config")

function M.setup(opts)
  config.setup(opts)
end

return M



