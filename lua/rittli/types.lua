---@class ITerminalProvider
---@field create fun(opts: { env: table<string, string> }): ITerminalHandler

---@class ITerminalHandler
---@field focus fun(): nil
---@field is_alive fun(): boolean
---@field execute_command fun(cmd: string): nil

---@class TasksModule
---@field is_available fun(): boolean
---@field tasks RawTask[]

---@class BuilderResult
---@field cmd string[]
---@field env table<string, string> 

---@class RawTask
---@field name string
---@field builder fun(cache: table): BuilderResult
---@field is_available fun(): boolean

---@class TaskLaunchResult
---@field is_success boolean
---@field error_msg string?
---@field terminal_handler ITerminalHandler
