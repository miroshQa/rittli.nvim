---@class ITerminalProvider
---@field create fun(opts: { env: table<string, string> }): ITerminalHandler
---@field attach fun(info: string): ITerminalHandler?
---@field get_all_available_handlers fun(): ITerminalHandler[]

---@class ITerminalHandler
---@field focus fun(): nil
---@field is_alive fun(): boolean
---@field execute_command fun(cmd: string): nil
---@field get_info_to_reattach fun(): string It make sense to call this function only if is_alive return true
---@field get_name fun(): string
---@field get_text fun(): string[] This function must return any text that will used in the telescope preivew

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
