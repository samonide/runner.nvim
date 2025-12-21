-- =====================================================================
-- Build and compile logic for runner.nvim
-- Handles compiling source code for compiled languages
-- =====================================================================

local M = {}
local terminal = require('runner.terminal')

-- Build a compiled file
local function build(ft, runner, config, last_build, on_success)
  local filename = vim.fn.expand('%:t')
  local filepath = vim.fn.expand('%:p')
  local base = vim.fn.expand('%:t:r')
  local outdir = vim.fn.getcwd() .. '/' .. config.build_dir
  
  vim.fn.mkdir(outdir, 'p')
  
  local bin = outdir .. '/' .. base
  
  -- Get current profile
  local profile_idx = config.current_profile[ft] or 1
  local profile = runner.profiles and runner.profiles[profile_idx] or { name = 'Default', flags = '' }
  local flags = profile.flags or ''
  
  local cmd
  
  -- Special handling for different languages
  if ft == 'java' then
    -- Java: compile with javac, run with java
    cmd = string.format('%s %s "%s" -d "%s"', runner.compiler, flags, filepath, outdir)
  elseif ft == 'go' and runner.command then
    -- Go: use 'go run' directly if command is specified
    if on_success then
      on_success(runner.command:gsub('$FILE', filepath))
    end
    return
  elseif ft == 'nim' and runner.command then
    -- Nim: use 'nim c -r' if command is specified
    if on_success then
      on_success(runner.command:gsub('$FILE', filepath))
    end
    return
  elseif ft == 'zig' and runner.command then
    -- Zig: use 'zig run' if command is specified
    if on_success then
      on_success(runner.command:gsub('$FILE', filepath))
    end
    return
  else
    -- Standard compilation (C, C++, Rust, etc.)
    cmd = string.format('%s %s "%s" -o "%s"', runner.compiler, flags, filepath, bin)
  end
  
  vim.notify(
    string.format('Building (%s): %s', profile.name, filename),
    vim.log.levels.INFO
  )
  
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code)
      if code == 0 then
        last_build[ft] = bin
        vim.notify('Build success', vim.log.levels.INFO)
        if on_success then
          if ft == 'java' then
            -- For Java, run the class file
            on_success(string.format('cd "%s" && %s %s', outdir, runner.run_command, base))
          else
            on_success(bin)
          end
        end
      else
        vim.notify('Build failed (exit code ' .. code .. ')', vim.log.levels.ERROR)
      end
    end,
  })
end

-- Build and run
function M.build_and_run(ft, runner, config, last_build, on_complete)
  build(ft, runner, config, last_build, function(bin)
    terminal.open_bottom(bin, on_complete)
  end)
end

-- Build only
function M.build_only(ft, runner, config, last_build, callback)
  build(ft, runner, config, last_build, callback)
end

-- Build and run with input file
function M.build_and_run_with_input(ft, runner, config, last_build, input_file)
  build(ft, runner, config, last_build, function(bin)
    local cmd = string.format('%s < %s', bin, input_file)
    terminal.open_bottom(cmd)
  end)
end

return M
