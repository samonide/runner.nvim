-- =====================================================================
-- Build and compile logic for runner.nvim
-- Handles compiling source code for compiled languages with detailed
-- error reporting and support for multiple language-specific compilation
-- strategies.
-- =====================================================================

local M = {}
local terminal = require('runner.terminal')

-- =====================================================================
-- CONSTANTS
-- =====================================================================

local LANGUAGES_WITH_DIRECT_RUN = {
  go = true,
  nim = true,
  zig = true,
}

-- =====================================================================
-- HELPER FUNCTIONS
-- =====================================================================

--- Get file information for current buffer
--- @return table File info with filename, filepath, base name, and output directory
local function get_file_info(build_dir)
  return {
    filename = vim.fn.expand('%:t'),
    filepath = vim.fn.expand('%:p'),
    base = vim.fn.expand('%:t:r'),
    outdir = vim.fn.getcwd() .. '/' .. build_dir,
  }
end

--- Get the active compiler profile for the given filetype
--- @param ft string Filetype (e.g., 'cpp', 'c', 'rust')
--- @param runner table Runner configuration
--- @param config table Global configuration
--- @return table Profile with name and flags
local function get_active_profile(ft, runner, config)
  local profile_idx = config.current_profile[ft] or 1
  local profile = runner.profiles and runner.profiles[profile_idx]
  
  return profile or { name = 'Default', flags = '' }
end

--- Create build command for standard compiled languages
--- @param runner table Runner configuration
--- @param file_info table File information
--- @param flags string Compiler flags
--- @return string Build command
local function create_standard_build_command(runner, file_info, flags)
  return string.format(
    '%s %s "%s" -o "%s"',
    runner.compiler,
    flags,
    file_info.filepath,
    file_info.outdir .. '/' .. file_info.base
  )
end

--- Create build command for Java
--- @param runner table Runner configuration
--- @param file_info table File information
--- @param flags string Compiler flags
--- @return string Build command
local function create_java_build_command(runner, file_info, flags)
  return string.format(
    '%s %s "%s" -d "%s"',
    runner.compiler,
    flags,
    file_info.filepath,
    file_info.outdir
  )
end

--- Check if language supports direct run without separate compilation
--- @param ft string Filetype
--- @param runner table Runner configuration
--- @return boolean True if language uses direct run command
local function uses_direct_run(ft, runner)
  return LANGUAGES_WITH_DIRECT_RUN[ft] and runner.command ~= nil
end

--- Get direct run command for languages that support it
--- @param runner table Runner configuration
--- @param filepath string Full file path
--- @return string Run command
local function get_direct_run_command(runner, filepath)
  return runner.command:gsub('$FILE', filepath)
end

--- Capture and collect output from build process
--- @return table Output lines, function to add stdout, function to add stderr
local function create_output_collector()
  local output_lines = {}
  
  local function add_output(_, data)
    if data then
      for _, line in ipairs(data) do
        if line ~= '' then
          table.insert(output_lines, line)
        end
      end
    end
  end
  
  return output_lines, add_output, add_output
end

--- Handle successful build
--- @param ft string Filetype
--- @param bin string Binary path
--- @param last_build table Last build cache
--- @param on_success function|nil Success callback
--- @param runner table Runner configuration
--- @param file_info table File information
local function handle_build_success(ft, bin, last_build, on_success, runner, file_info)
  last_build[ft] = bin
  vim.notify('✓ Build success', vim.log.levels.INFO)
  
  if on_success then
    if ft == 'java' then
      -- Java requires running with java command in the output directory
      local run_cmd = string.format(
        'cd "%s" && %s %s',
        file_info.outdir,
        runner.run_command,
        file_info.base
      )
      on_success(run_cmd)
    else
      on_success(bin)
    end
  end
end

--- Handle failed build with detailed error reporting
--- @param code number Exit code
--- @param output_lines table Collected output lines
local function handle_build_failure(code, output_lines)
  local error_msg = 'Build failed (exit code ' .. code .. ')'
  
  if #output_lines > 0 then
    error_msg = error_msg .. ':\n' .. table.concat(output_lines, '\n')
  end
  
  vim.notify(error_msg, vim.log.levels.ERROR)
end

-- =====================================================================
-- CORE BUILD FUNCTIONS
-- =====================================================================

--- Build a compiled file with proper error handling
--- @param ft string Filetype
--- @param runner table Runner configuration
--- @param config table Global configuration
--- @param last_build table Last build cache
--- @param on_success function|nil Callback on successful build
local function build(ft, runner, config, last_build, on_success)
  local file_info = get_file_info(config.build_dir)
  
  -- Create build directory if it doesn't exist
  vim.fn.mkdir(file_info.outdir, 'p')
  
  local bin = file_info.outdir .. '/' .. file_info.base
  
  -- Handle languages with direct run commands (Go, Nim, Zig)
  if uses_direct_run(ft, runner) then
    if on_success then
      on_success(get_direct_run_command(runner, file_info.filepath))
    end
    return
  end
  
  -- Get compiler profile and flags
  local profile = get_active_profile(ft, runner, config)
  local flags = profile.flags or ''
  
  -- Create build command based on language
  local cmd
  if ft == 'java' then
    cmd = create_java_build_command(runner, file_info, flags)
  else
    cmd = create_standard_build_command(runner, file_info, flags)
  end
  
  -- Notify user about build start
  vim.notify(
    string.format('Building (%s): %s', profile.name, file_info.filename),
    vim.log.levels.INFO
  )
  
  -- Setup output collection
  local output_lines, on_stdout, on_stderr = create_output_collector()
  
  -- Start build job
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = on_stdout,
    on_stderr = on_stderr,
    on_exit = function(_, code)
      if code == 0 then
        handle_build_success(ft, bin, last_build, on_success, runner, file_info)
      else
        handle_build_failure(code, output_lines)
      end
    end,
  })
end

-- =====================================================================
-- PUBLIC API
-- =====================================================================

--- Build and run the compiled program
--- @param ft string Filetype
--- @param runner table Runner configuration
--- @param config table Global configuration
--- @param last_build table Last build cache
--- @param on_complete function|nil Callback on completion
function M.build_and_run(ft, runner, config, last_build, on_complete)
  build(ft, runner, config, last_build, function(bin)
    terminal.open_bottom(bin, on_complete)
  end)
end

--- Build only without running
--- @param ft string Filetype
--- @param runner table Runner configuration
--- @param config table Global configuration
--- @param last_build table Last build cache
--- @param callback function|nil Callback on build completion
function M.build_only(ft, runner, config, last_build, callback)
  build(ft, runner, config, last_build, callback)
end

--- Build and run with input file redirection
--- @param ft string Filetype
--- @param runner table Runner configuration
--- @param config table Global configuration
--- @param last_build table Last build cache
--- @param input_file string Path to input file
function M.build_and_run_with_input(ft, runner, config, last_build, input_file)
  build(ft, runner, config, last_build, function(bin)
    local cmd = string.format('%s < %s', bin, input_file)
    terminal.open_bottom(cmd)
  end)
end

return M
