# 🥷 Terminal-and-tasks 

🔥  Intuitive tasks launcher with integration with telescope and builtin terminal enhancement!

![Preview](./demo/preview.png)


## ✨ Features
- 🔭 Create tasks in lua. Pick them using telescope and launch in the terminal
- 📺 Task preview in telescope
- 🤖 Tasks auto update (auto resource)
- ⚡️ Toggle last openned terminal
- 🌎 Define local and global tasks
- 👻 Reuse global tasks as template for local tasks




## 📦 Installation
Install the plugin using lazy.nvim plugin manager:

```lua
 {
     "miron2363/terminal-and-tasks",
     lazy = true,
     keys = {
         { "<C-t>",     function() require("terminal-and-tasks.terminal_tweaks").toggle_last_openned_terminal() end, mode = { "n", "t" } },
         { "<leader>r", function() require("terminal-and-tasks.telescope_tasks").tasks_picker() end },
         { "<leader>R", function() require("terminal-and-tasks.telescope_tasks").run_last_runned_task() end },
         { "<leader><leader>", function() require('telescope.builtin').buffers({path_display = {'tail'}, sort_mru = true, ignore_current_buffer = true}) end}
     },
     opts = {},
 }

 -- You also need telescope to be installed
```


## 🚀 Usage
### 1. How to create global tasks
- To define your own tasks you need to create "tasks" folder inside your user configuration directory in lua folder.  
- Then you can create lua files what must return lua table with field "tasks" where your own tasks should be defined.
```lua
-- ~/user/.config/nvim/lua/tasks/some_tasks.lua 
local M = {}

M.tasks = {
  {
    name = "List all the files and print hello",
    cmd = "ls -la ; echo $greeting",
    env = {greeting = "Hello"},
    cwd = "",
  },
}

return M

```

### 2. How to launch tasks
- After you define your tasks press "leader + r".
- That will open telescope picker where you can select needed task and launch by pressing "Enter".

### 3. How to change tasks
- Open telescope tasks picker (press "leader + r") and select needed task.      
- Now you can press "ctrl + t" to open buffer with task in new tab and edit task.   
- When you open telescope tasks picker again your tasks will be updated and you will receive an correspionding notification about that

### 4. I started the task. What's next?
- When you select the task in the telescope tasks picker and press Enter tasks will be immediately launched
- While tasks is running and haven't completed yet you can close terminal using ctrl + t. (You can open this terminal again pressing ctrl + t again)
- IN PROGRESS...
- Tabs? Buffers? Windows? Wtf is that? If so then it is highly recommended to read [this](https://betterprogramming.pub/50-vim-mode-tips-for-ide-users-f7b525a794b3#:~:text=colorless%20diff%20command.-,67.%20Vim%20tabs,-It%20must%20be) and watch [this](https://www.youtube.com/watch?v=_6OqJrdbfs0&t=221s) video

## ⚙️ Configuration
You can check the default configuration [here](./lua/terminal-and-tasks/config.lua). To override default options just pass new values in opts table
```lua
opts = {
    folder_name_with_tasks = "MyTasks",
    disable_resource_messages = true,
}
```



## ❔ Explanation
What this plugin does and why is it called like that?   
IN PROGRESS...

