local M = {}

local config = require("rittli.config")

function M.setup(opts)
  config.config = vim.tbl_deep_extend("force", {}, config.config, opts or {})
  require("rittli.tasks")
  require("rittli.conveniences.tab_tweaks")
  require("rittli.conveniences.terminal_tweaks")
end

return M
