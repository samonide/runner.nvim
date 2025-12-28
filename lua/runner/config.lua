-- =====================================================================
-- Default configuration for runner.nvim
--
-- This file contains all default settings and language runner configs.
-- Users can override any of these in their setup() call.
--
-- Configuration Structure:
--   - Global settings (build_dir, test_dir, etc.)
--   - Terminal settings
--   - Language runners (compiled and interpreted)
--
-- Runner Types:
--   - 'compiled': Requires compilation step (C, C++, Rust, etc.)
--   - 'interpreted': Direct execution (Python, JavaScript, etc.)
-- =====================================================================

local M = {}

-- =====================================================================
-- GLOBAL CONFIGURATION
-- =====================================================================

M.default = {
  -- Directory for compiled binaries (created if doesn't exist)
  build_dir = '.build',
  
  -- Directory containing test cases (*.in and *.out files)
  test_dir = 'tests',
  
  -- Input file for stdin redirection
  input_file = 'input.txt',
  
  -- Output file for stdout redirection
  output_file = 'output.txt',
  
  -- Display execution time after running
  show_time = true,
  
  -- Automatically remove binary after successful execution
  -- Useful for competitive programming to avoid stale binaries
  clean_after_run = false,
  
  -- Terminal window configuration
  terminal = {
    split_height = 15,        -- Height of horizontal split (in lines)
    position = 'botright',    -- Position: 'botright', 'topleft', 'vertical', etc.
  },
  
  -- Current active optimization profile per filetype
  -- Automatically managed by cycle_profile()
  current_profile = {},
  
  -- ===================================================================
  -- LANGUAGE RUNNER CONFIGURATIONS
  -- ===================================================================
  
  runners = {
    -- =================================================================
    -- COMPILED LANGUAGES
    -- =================================================================
    
    --- C++ Configuration
    -- Supports multiple optimization profiles for different use cases
    cpp = {
      type = 'compiled',
      compiler = 'g++',
      profiles = {
        {
          name = 'Debug',
          flags = '-std=c++17 -g -Wall -Wextra -Wshadow -pedantic',
        },
        {
          name = 'O2',
          flags = '-std=c++17 -O2 -Wall -Wextra -Wshadow -pedantic',
        },
        {
          name = 'Ofast',
          flags = '-std=c++17 -Ofast -march=native -DNDEBUG -Wall -Wextra -Wshadow',
        },
      },
    },
    
    --- C Configuration
    c = {
      type = 'compiled',
      compiler = 'gcc',
      profiles = {
        {
          name = 'Debug',
          flags = '-g -Wall -Wextra -pedantic',
        },
        {
          name = 'O2',
          flags = '-O2 -Wall -Wextra -pedantic',
        },
        {
          name = 'Ofast',
          flags = '-Ofast -march=native -DNDEBUG -Wall -Wextra',
        },
      },
    },
    
    --- Rust Configuration
    rust = {
      type = 'compiled',
      compiler = 'rustc',
      profiles = {
        { name = 'Debug', flags = '' },
        { name = 'Release', flags = '-C opt-level=3' },
      },
    },
    
    --- Java Configuration
    -- Special handling: javac compiles, java runs the class file
    java = {
      type = 'compiled',
      compiler = 'javac',
      run_command = 'java',
    },
    
    --- Haskell Configuration
    haskell = {
      type = 'compiled',
      compiler = 'ghc',
      profiles = {
        { name = 'Debug', flags = '' },
        { name = 'O2', flags = '-O2' },
      },
    },
    
    --- Kotlin Configuration
    kotlin = {
      type = 'compiled',
      compiler = 'kotlinc',
      run_command = 'kotlin',
    },
    
    --- D Language Configuration
    d = {
      type = 'compiled',
      compiler = 'dmd',
      profiles = {
        { name = 'Debug', flags = '-g' },
        { name = 'Release', flags = '-O -release' },
      },
    },
    
    -- =================================================================
    -- COMPILED LANGUAGES WITH DIRECT RUN
    -- These languages support compile-and-run in a single command
    -- =================================================================
    
    --- Go Configuration
    -- Uses 'go run' which compiles and executes in one step
    go = {
      type = 'compiled',
      compiler = 'go',
      command = 'go run $FILE',
    },
    
    --- Nim Configuration
    -- 'nim c -r' compiles and runs in one command
    nim = {
      type = 'compiled',
      compiler = 'nim',
      command = 'nim c -r $FILE',
    },
    
    --- Zig Configuration
    -- 'zig run' compiles and executes in one step
    zig = {
      type = 'compiled',
      compiler = 'zig',
      command = 'zig run $FILE',
    },
    
    -- =================================================================
    -- INTERPRETED LANGUAGES
    -- These languages run directly without compilation
    -- =================================================================
    
    --- Python Configuration
    python = {
      type = 'interpreted',
      command = 'python3 $FILE',
    },
    
    --- JavaScript/Node.js Configuration
    javascript = {
      type = 'interpreted',
      command = 'node $FILE',
    },
    
    --- TypeScript Configuration (requires ts-node)
    typescript = {
      type = 'interpreted',
      command = 'ts-node $FILE',
    },
    
    --- Lua Configuration
    lua = {
      type = 'interpreted',
      command = 'lua $FILE',
    },
    
    --- Ruby Configuration
    ruby = {
      type = 'interpreted',
      command = 'ruby $FILE',
    },
    
    --- Perl Configuration
    perl = {
      type = 'interpreted',
      command = 'perl $FILE',
    },
    
    --- PHP Configuration
    php = {
      type = 'interpreted',
      command = 'php $FILE',
    },
    
    --- Shell Script Configurations
    sh = {
      type = 'interpreted',
      command = 'bash $FILE',
    },
    
    bash = {
      type = 'interpreted',
      command = 'bash $FILE',
    },
    
    zsh = {
      type = 'interpreted',
      command = 'zsh $FILE',
    },
    
    --- R Configuration
    r = {
      type = 'interpreted',
      command = 'Rscript $FILE',
    },
    
    --- Julia Configuration
    julia = {
      type = 'interpreted',
      command = 'julia $FILE',
    },
    
    --- Swift Configuration
    swift = {
      type = 'interpreted',
      command = 'swift $FILE',
    },
    
    --- Dart Configuration
    dart = {
      type = 'interpreted',
      command = 'dart run $FILE',
    },
    
    --- Elixir Configuration
    elixir = {
      type = 'interpreted',
      command = 'elixir $FILE',
    },
    
    --- OCaml Configuration
    ocaml = {
      type = 'interpreted',
      command = 'ocaml $FILE',
    },
    
    --- Scala Configuration
    scala = {
      type = 'interpreted',
      command = 'scala $FILE',
    },
  },
}

return M
