-- https://miguelcrespo.co/posts/how-to-write-a-neovim-plugin-in-lua/
-- this file executes when we run require("rittl")
-- print("Hello from init.lua")

local M = {}

local config = require("rittl.config")

function M.setup(opts)
  config.config = vim.tbl_deep_extend("force", {}, config.config, opts or {})
  require("rittl.terminal_tweaks")
  require("rittl.tabs_tweaks")
  require("rittl.tasks")
end

return M
