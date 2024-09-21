local M = {}

local config = require("rittli.config")

---@param opts Rittli.config
function M.setup(opts)
  config.config = vim.tbl_deep_extend("force", {}, config.config, opts or {})
  require("rittli.core")

  if config.config.conveniences.enable then
    require("rittli.conveniences.tab_tweaks")
    require("rittli.conveniences.terminal_tweaks")
  end
end

return M
