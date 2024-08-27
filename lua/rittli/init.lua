-- https://miguelcrespo.co/posts/how-to-write-a-neovim-plugin-in-lua/
-- this file executes when we run require("rittli")
-- print("Hello from init.lua")

local M = {}

local config = require("rittli.config")

function M.setup(opts)
  config.config = vim.tbl_deep_extend("force", {}, config.config, opts or {})
  require("rittli.terminal_tweaks")
  require("rittli.tab_tweaks")
  require("rittli.tasks")
end

return M
