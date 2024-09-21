---@class ITerminalProvider
---@field create fun(opts: { env: table<string, string> }): ITerminalHandler

---@class ITerminalHandler
---@field focus fun(): nil
---@field is_alive fun(): boolean
---@field execute_command fun(cmd: string): nil

---@class TasksModule
---@field is_available fun(): boolean
---@field tasks RawTask[]

---@class RawTask
---@field name string
---@field builder fun(cache: table): { cmd: string[], env: table<string, string> }
---@field is_available fun(): boolean
