# terminal-and-tasks 🥷

Intuitive tasks launcher with integration with telescope and builtin terminal enhancement! ✨

![Preview](./demo/preview.png)


## ✨ Features
- Toggle last terminal in tab
- Create tasks using lua and launch them in terminal using telescope
- Task preview in telescope
- Tasks auto update (auto resource)


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
     opts = {
     },
 }

 -- You also need telescope to be installed
```



## 🚀 Usage

## ⚙️ Configuration

## Documentation is coming soon 🚀
