-- =====================================================================
-- Default configuration for runner.nvim
-- =====================================================================

local M = {}

M.default = {
  -- Build directory for compiled languages
  build_dir = '.build',
  
  -- Test directory
  test_dir = 'tests',
  
  -- Input/output files
  input_file = 'input.txt',
  output_file = 'output.txt',
  
  -- Show execution time after running
  show_time = true,
  
  -- Terminal configuration
  terminal = {
    split_height = 15,  -- Height of horizontal split
    position = 'botright',  -- Position of terminal split
  },
  
  -- Current optimization profile per filetype
  current_profile = {},
  
  -- Runner configurations for different languages
  runners = {
    -- C++ Configuration
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
    
    -- C Configuration
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
    
    -- Python Configuration
    python = {
      type = 'interpreted',
      command = 'python3 $FILE',
    },
    
    -- JavaScript/Node.js Configuration
    javascript = {
      type = 'interpreted',
      command = 'node $FILE',
    },
    
    -- TypeScript Configuration (using ts-node)
    typescript = {
      type = 'interpreted',
      command = 'ts-node $FILE',
    },
    
    -- Go Configuration
    go = {
      type = 'compiled',
      compiler = 'go',
      command = 'go run $FILE',  -- Go can compile and run in one command
    },
    
    -- Rust Configuration
    rust = {
      type = 'compiled',
      compiler = 'rustc',
      profiles = {
        {
          name = 'Debug',
          flags = '',
        },
        {
          name = 'Release',
          flags = '-C opt-level=3',
        },
      },
    },
    
    -- Java Configuration
    java = {
      type = 'compiled',
      compiler = 'javac',
      run_command = 'java',  -- Special case: javac compiles, java runs
    },
    
    -- Lua Configuration
    lua = {
      type = 'interpreted',
      command = 'lua $FILE',
    },
    
    -- Ruby Configuration
    ruby = {
      type = 'interpreted',
      command = 'ruby $FILE',
    },
    
    -- Perl Configuration
    perl = {
      type = 'interpreted',
      command = 'perl $FILE',
    },
    
    -- PHP Configuration
    php = {
      type = 'interpreted',
      command = 'php $FILE',
    },
    
    -- Shell Script Configuration
    sh = {
      type = 'interpreted',
      command = 'bash $FILE',
    },
    
    -- Bash Configuration
    bash = {
      type = 'interpreted',
      command = 'bash $FILE',
    },
    
    -- Zsh Configuration
    zsh = {
      type = 'interpreted',
      command = 'zsh $FILE',
    },
    
    -- R Configuration
    r = {
      type = 'interpreted',
      command = 'Rscript $FILE',
    },
    
    -- Julia Configuration
    julia = {
      type = 'interpreted',
      command = 'julia $FILE',
    },
    
    -- Haskell Configuration
    haskell = {
      type = 'compiled',
      compiler = 'ghc',
      profiles = {
        {
          name = 'Debug',
          flags = '',
        },
        {
          name = 'O2',
          flags = '-O2',
        },
      },
    },
    
    -- Swift Configuration
    swift = {
      type = 'interpreted',
      command = 'swift $FILE',
    },
    
    -- Kotlin Configuration
    kotlin = {
      type = 'compiled',
      compiler = 'kotlinc',
      run_command = 'kotlin',
    },
    
    -- Dart Configuration
    dart = {
      type = 'interpreted',
      command = 'dart run $FILE',
    },
    
    -- Elixir Configuration
    elixir = {
      type = 'interpreted',
      command = 'elixir $FILE',
    },
    
    -- Nim Configuration
    nim = {
      type = 'compiled',
      compiler = 'nim',
      command = 'nim c -r $FILE',  -- Nim can compile and run in one command
    },
    
    -- Zig Configuration
    zig = {
      type = 'compiled',
      compiler = 'zig',
      command = 'zig run $FILE',
    },
    
    -- OCaml Configuration
    ocaml = {
      type = 'interpreted',
      command = 'ocaml $FILE',
    },
    
    -- Scala Configuration
    scala = {
      type = 'interpreted',
      command = 'scala $FILE',
    },
    
    -- D Configuration
    d = {
      type = 'compiled',
      compiler = 'dmd',
      profiles = {
        {
          name = 'Debug',
          flags = '-g',
        },
        {
          name = 'Release',
          flags = '-O -release',
        },
      },
    },
  },
}

return M
