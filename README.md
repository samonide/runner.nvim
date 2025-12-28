# runner.nvim

<div align="center">

🚀 **A universal, intelligent code runner for Neovim**

[![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Made%20with%20Lua-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](./LICENSE)

Automatically detects file types and executes code with the appropriate command.

Perfect for **competitive programming**, **learning**, and **quick prototyping**!

</div>

---

## ✨ Features

- **Multi-language support**: C, C++, Python, JavaScript, TypeScript, Go, Rust, Java, Lua, Ruby, Perl, PHP, Shell scripts, R, Julia, Haskell, Swift, Kotlin, Dart, Elixir, Nim, Zig, OCaml, Scala, D, and more!
- **Smart detection**: Automatically determines the correct runner based on file type
- **Compiled languages**: Built-in compilation support with optimization profiles
- **Interpreted languages**: Direct execution support
- **Intelligent terminal management**: Clean terminal handling - closes previous terminal before creating new one (no stacking!)
- **Binary existence check**: Prompts to build if binary is missing before running
- **Detailed error reporting**: Captures and displays compiler stdout/stderr for better debugging
- **Flexible terminals**: Run in bottom split or floating terminal
- **Test runner**: Run multiple test cases from a `tests/` directory
- **Input/Output handling**: Support for `input.txt` and `output.txt` redirection
- **Optimization profiles**: Cycle through different compiler optimization flags (Debug, O2, Ofast)
- **Execution timing**: Automatically tracks and displays execution time
- **Watch mode**: Auto-run code on file save
- **Run history**: Keep track of recent executions with timestamps
- **Clean builds**: Easy cleanup of build artifacts, optional auto-cleanup after run
- **Highly configurable**: Easy to add new languages or customize existing ones

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'samonide/runner.nvim',
  config = function()
    require('runner').setup({
      -- Your custom configuration here (optional)
    })
  end,
  keys = {
    { '<leader>cr', '<cmd>RunCode<cr>', desc = 'Run code' },
    { '<leader>cb', '<cmd>RunBuild<cr>', desc = 'Build only' },
    { '<leader>ce', '<cmd>RunLast<cr>', desc = 'Run last build' },
    { '<leader>ci', '<cmd>RunWithInput<cr>', desc = 'Run with input.txt' },
    { '<leader>ct', '<cmd>RunFloat<cr>', desc = 'Run in floating terminal' },
    { '<leader>ctt', '<cmd>RunTests<cr>', desc = 'Run all tests' },
    { '<leader>co', '<cmd>RunProfile<cr>', desc = 'Cycle optimization profile' },
    { '<leader>cw', '<cmd>RunWatch<cr>', desc = 'Toggle watch mode' },
    { '<leader>ch', '<cmd>RunHistory<cr>', desc = 'Show run history' },
    { '<leader>cc', '<cmd>RunClean<cr>', desc = 'Clean build directory' },
    { '<C-A-n>', '<cmd>RunIOFiles<cr>', desc = 'Run with input.txt -> output.txt' },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'samonide/runner.nvim',
  config = function()
    require('runner').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'samonide/runner.nvim'

lua << EOF
require('runner').setup()
EOF
```

## 🎯 Usage

### Commands

| Command | Description |
|---------|-------------|
| `:RunCode` | Compile (if needed) and run the current file. Checks for binary existence and prompts to build if missing |
| `:RunFile` | Alias for `:RunCode` |
| `:RunBuild` | Build/compile only (no execution) |
| `:RunLast` | Run the last compiled executable (without recompiling) |
| `:RunWithInput` | Run with `input.txt` as stdin |
| `:RunFloat` | Run in a floating terminal window |
| `:RunTests` | Run all test cases from `tests/` directory with pass/fail reporting |
| `:RunIOFiles` | Run with `input.txt` -> `output.txt` redirection |
| `:RunProfile` | Cycle through optimization profiles (Debug → O2 → Ofast) |
| `:RunWatch` | Toggle watch mode (auto-run on save) |
| `:RunHistory` | Show execution history with timings and timestamps |
| `:RunClean` | Clean build directory (removes all compiled binaries) |

### Default Key Mappings

```lua
<leader>cr  -- Run code
<leader>cb  -- Build only
<leader>ce  -- Execute last build
<leader>ci  -- Run with input.txt
<leader>ct  -- Run in floating terminal
<leader>ctt -- Run all tests
<leader>co  -- Cycle optimization profile
<leader>cw  -- Toggle watch mode
<leader>ch  -- Show run history
<leader>cc  -- Clean build directory
<C-A-n>     -- Run with input.txt -> output.txt
```

## 🚀 Quick Start

1. **Install the plugin** using your plugin manager (see above)
2. **Open any file** (e.g., `main.cpp`, `script.py`, `app.js`)
3. **Press** `<leader>cr` or run `:RunCode`
4. **Watch your code execute** in a terminal split!

### Example Workflow

```bash
# Competitive Programming
1. Create solution.cpp
2. Create tests/1.in and tests/1.out
3. Press <leader>cr to run
4. Press <leader>ctt to test all cases
5. Press <leader>co to optimize
```ader>ctt -- Run all tests
<leader>co  -- Cycle optimization profile
<C-A-n>     -- Run with input.txt -> output.txt
```

## ⚙️ Configuration

### Default Configuration

```lua
require('runner').setup({
  -- Build directory for compiled languages
  build_dir = '.build',
  
  -- Test directory
  test_dir = 'tests',
  
  -- Input/output files
  input_file = 'input.txt',
  output_file = 'output.txt',
  
  -- Show execution time after running
  show_time = true,
  
  -- Clean build artifacts after successful run (removes binary after execution)
  -- Useful for competitive programming to avoid outdated binaries
  clean_after_run = false,
  
  -- Terminal configuration
  terminal = {
    split_height = 15,
    position = 'botright',
  },
  
  -- Runners are auto-configured for many languages
  -- See below for customization
})
```

### Customizing Language Runners

You can add or override language configurations:

```lua
require('runner').setup({
  runners = {
    -- Add a new language
    fortran = {
      type = 'compiled',
      compiler = 'gfortran',
      profiles = {
        { name = 'Debug', flags = '-g -Wall' },
        { name = 'Release', flags = '-O3' },
      },
    },
    
    -- Override Python to use a specific version
    python = {
      type = 'interpreted',
      command = 'python3.11 $FILE',
    },
    
    -- Override C++ profiles
    cpp = {
      type = 'compiled',
      compiler = 'g++',
      profiles = {
        { name = 'Debug', flags = '-std=c++20 -g -Wall' },
        { name = 'Contest', flags = '-std=c++20 -O2 -DLOCAL' },
        { name = 'Release', flags = '-std=c++20 -O3 -march=native' },
      },
    },
  },
})
```

### Runner Configuration Fields

#### For Interpreted Languages

```lua
{
  type = 'interpreted',
  command = 'python3 $FILE',  -- $FILE is replaced with the file path
}
```

#### For Compiled Languages

```lua
{
  type = 'compiled',
  compiler = 'g++',
  profiles = {
    {
      name = 'Profile Name',
      flags = '-O2 -Wall',
    },
  },
}
```

#### Special Cases

Some languages have special handling:

- **Java**: Uses `javac` to compile and `java` to run
- **Go**: Can use `go run` to compile and run in one step
- **Nim**: Can use `nim c -r` to compile and run in one step
- **Zig**: Can use `zig run` to compile and run in one step

## 🧪 Test Runner

Create a `tests/` directory with test cases:

```
tests/
  1.in     # Input for test 1
  1.out    # Expected output for test 1
  2.in     # Input for test 2
  2.out    # Expected output for test 2
  ...
```

Run `:RunTests` to execute all tests and see which ones pass/fail.

## 🎨 Supported Languages

### Compiled Languages
- C, C++
- Rust
- Go
- Java
- Haskell
- Kotlin
- D
- Nim
- Zig

### Interpreted Languages
- Python
- JavaScript (Node.js)
- TypeScript (ts-node)
- Lua
- Ruby
- Perl
- PHP
- Shell scripts (bash, zsh, sh)
- R
- Julia
- Swift
- Dart
- Elixir
- OCaml
- Scala

## 📝 Examples

### Competitive Programming Workflow

1. Write your C++ solution: `solution.cpp`
2. Create test cases: `tests/1.in`, `tests/1.out`, etc.
3. Press `<leader>cr` to compile and run
   - If binary doesn't exist, you'll be prompted to build first
4. Press `<leader>ctt` to run all tests with pass/fail reporting
5. Press `<leader>co` to cycle optimization profiles (Debug → O2 → Ofast)
6. Press `<leader>ci` to test with `input.txt`
7. Press `<leader>ce` to quickly run last build without recompiling

### Better Error Debugging

When build fails, you now get detailed compiler output:
```
Build failed (exit code 1):
main.cpp:5:10: error: expected ';' after expression
    return 0
         ^
         ;
```

### Clean Build Management

```vim
" Option 1: Manual cleanup
:RunClean  " Removes all binaries from .build/

" Option 2: Auto cleanup after each run (in your config)
require('runner').setup({
  clean_after_run = true,  " Automatically removes binary after execution
})
```

### Watch Mode for Rapid Development

```vim
:RunWatch  " Enable watch mode
" Now every time you save, code runs automatically!
:RunWatch  " Toggle off when done
```

### Terminal Management

The plugin intelligently manages terminals:
- Pressing `<leader>ci` multiple times closes the previous terminal before opening a new one
- No more terminal stacking issues!
- Clean, predictable behavior

### Check Execution History

```vim
:RunHistory  " See your last 10 runs with execution times and timestamps
```

Output example:
```
📊 Run History (Last 10):
═══════════════════════════
1. [14:23:45] solution.cpp (cpp) - 0.234s
2. [14:22:10] test.py (python) - 1.456s
3. [14:20:05] app.js (javascript) - 0.089s
```

### Quick Script Execution

For interpreted languages (Python, JavaScript, etc.), just press `<leader>cr` to run immediately with execution time tracking.

## 🎓 Advanced Usage

### Custom Language Configuration

```lua
require('runner').setup({
  runners = {
    -- Add a new language
    fortran = {
      type = 'compiled',
      compiler = 'gfortran',
      profiles = {
        { name = 'Debug', flags = '-g -Wall' },
        { name = 'Release', flags = '-O3' },
      },
    },
    
    -- Override existing
    python = {
      type = 'interpreted',
      command = 'python3.11 $FILE',
    },
  },
  
  -- Customize settings
  show_time = true,  -- Show execution time
  clean_after_run = false,  -- Auto-cleanup binaries after run
  build_dir = '.build',
})
```

### Recommended Setup for Competitive Programming

```lua
require('runner').setup({
  show_time = true,  -- Always show execution time
  clean_after_run = false,  -- Keep binaries for quick re-runs with <leader>ce
  
  runners = {
    cpp = {
      type = 'compiled',
      compiler = 'g++',
      profiles = {
        { name = 'Debug', flags = '-std=c++17 -g -Wall -Wextra -Wshadow -fsanitize=address,undefined' },
        { name = 'Contest', flags = '-std=c++17 -O2 -DLOCAL' },
        { name = 'Ofast', flags = '-std=c++17 -Ofast -march=native' },
      },
    },
  },
})
```

### Project-Specific Settings

Create `.nvim.lua` in your project root:

```lua
local runner = require('runner')
runner.config.current_profile['cpp'] = 2  -- Start with O2
runner.config.build_dir = 'build'
```

## 🤝 Contributing

Contributions welcome! To add a new language:

1. Fork the repo
2. Edit `lua/runner/config.lua` and add your language configuration
3. Test it thoroughly
4. Submit a PR

For bugs or feature requests, please open an issue on GitHub.

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details

## 🙏 Credits

Created by [@samonide](https://github.com/samonide) - Built with ❤️ for developers who value speed and simplicity!

Extracted and enhanced from a competitive programming Neovim setup.
