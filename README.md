# 🥷 rittli.nvim

Revolutionary and Intuitive Terminal Tasks Launcher with tight telescope integration! 🔥

![Preview](./demo/preview.png)


## ✨ Features
- 🔭 Create tasks in lua. Pick them using Telescope and launch in the *neovim* terminal
- 👀 Task preview in telescope
- 🤖 Tasks auto update (auto resource)
- ⚡️ Built-in Neovim terminal improvements (Toggle the last openned terminal)
- 🌎 Define local and global tasks
- 👻 Reuse global tasks as template for local tasks
- 🌟 Last tasks is rememberd for each directory
- 🔥 Create tasks dynamically! (My favorite use: Write all buffers before launch)
- 🧓 Cache the task if you want!

*You can see some features preview [here](/demo/gallery.md)*

## ❗Warning
This plugin isn't ready yet! Breaking changes are expected and the documentation may not be complete

## 📦 Installation
Install the plugin using lazy.nvim plugin manager:

```lua
 {
   "miroshQa/rittli.nvim",
   lazy = true,
   dependencies = {
     'nvim-telescope/telescope.nvim'
   },
   keys = {
     { "<C-t>",     function() require("rittli.terminal_tweaks").toggle_last_openned_terminal() end, mode = { "n", "t" }},
     {"<Esc><Esc>", "<C-\\><C-n>", mode = "t"},
     { "<leader>r", function() require("rittli.tasks.telescope").run_last_runned_task() end, desc = "Rerun the last task or pick a new one" },
     { "<leader>R", function() require("rittli.tasks.telescope").tasks_picker() end, desc = "Pick the task" },
     { "<leader><leader>", function() require('telescope.builtin').buffers({path_display = {'tail'}, sort_mru = true, ignore_current_buffer = true}) end}
   },
   opts = {},
 }

 -- You also need telescope to be installed
```


## 🚀 Tutorial
### 1. Create global tasks
1. Create "tasks" folder inside your user configuration directory in the "lua" folder.  
2. Create lua files what return lua table with the field "tasks", where your own tasks defined.

```lua
-- ~/.config/nvim/lua/tasks/some_tasks.lua 
local M = {}

M.tasks = {
  {
    name = "List all the files and print Hello!",
    builder = function() 
      local task = {
        cmd = {"ls -la", "echo $greeting"},
        env = {greeting = "Hello"}
      }

      return task
    end,
  },
  {
    name = "Build and Run current CPP or C file with Args",
    builder = function(cache)
      vim.cmd("wa")
      if vim.fn.isdirectory("build") == 0 then vim.fn.mkdir("build") end

      local task = {}
      local cur_file = vim.fn.expand("%")
      local bin_name = vim.fn.fnamemodify(cur_file, ":t:r")
      local compiler = vim.bo.filetype == "c" and "gcc" or "g++"
      if not cache.args then
        cache.args = vim.fn.input({prompt = "Enter exe arguments: "})
        -- Launch this task pressing leader + R to clear cache
      end

      task.cmd = {
        string.format("%s %s -o build/%s", compiler, cur_file, bin_name),
        string.format("./build/%s %s", bin_name, cache.args)
      }
      return task
    end,
  }
}

return M

```

**Notes:**
- Global tasks will be available everywhere
- File loads and updates recursively. You can create other folders in "tasks" directory and create lua files with tasks there!


### 2. Launch tasks
1. Press "leader + r" to open telescope tasks picker.
2. Select the desired task and launch it by pressing "Enter".

**Notes:**:
- You can hide the terminal (opened on launch in new tab) and open again using "ctrl + t"


### 3. Launch multiple tasks
1. Hide the terminal with the task you have launched by pressing "ctrl + t.
2. Press "leader + r" again, pick a new task and launch.
3. In the same way you can launch how many tasks as you want!
4. To open one of these opened and then hidden terminals, press "leader + leader", select the desired terminal and press "ctrl + t"

**Notes:**
- You can CLOSE (not hide) the terminal, simply type "exit" in the shell or press "ctrl + d" and press any key in insert mode

### 4. Edit tasks
1. Open the Telescope tasks picker (press "leader + r") and select the desired task.      
2. Press "ctrl + t" to open a buffer with the task in a new tab and edit it
3. When you open Telescope tasks picker again, your tasks will be updated, and you will receive a correspionding notification about that

**Notes:**
- Tabs? Buffers? Windows? Wtf is that? If so, it is highly recommended to read [this](https://betterprogramming.pub/50-vim-mode-tips-for-ide-users-f7b525a794b3#:~:text=colorless%20diff%20command.-,67.%20Vim%20tabs,-It%20must%20be) (section 67) and watch [this](https://www.youtube.com/watch?v=_6OqJrdbfs0&t=221s) video

### 5. Create local tasks
1. Create a folder in your current working directory named "tasks" and add lua files with tasks as usual

**Notes:**
- If the local task has the same name as global task, then the local task will override the global task (task from local directory will be used)

### 6. Reuse global tasks as template for local tasks
1. Open the Telescope tasks picker, select the task you want to reuse, and press "ctrl + r". This will clone the file containing this task into your local tasks folder (or create it if it doesn't exist yet) and open it in a new buffer
2. Edit newly cloned file as you want, add new tasks. When you open tasks picker again, all tasks from this file will be loaded!


## ⚙️ Configuration
You can check the default configuration [here](./lua/rittli/config.lua). To override default options, simply pass new values in the opts table
```lua
opts = {
  folder_name_with_tasks = "MyTasks",
  disable_resource_messages = true,
}
```

*You can find some configuration recipes [here](/demo/configuration-recipes.md)*


## ❔ Explanation
What this plugin does and why is it called like that?   
IN PROGRESS...

