-- =====================================================================
-- runner.nvim - Multi-language code runner for Neovim
-- A universal code execution plugin that intelligently runs code based
-- on file type with customizable configurations per language.
--
-- Features:
--   - Multi-language support with automatic detection
--   - Compilation with optimization profiles
--   - Test runner with input/output validation
--   - Execution timing and history tracking
--   - Watch mode for auto-run on save
-- =====================================================================

local M = {}
local config = require('runner.config')
local terminal = require('runner.terminal')
local builders = require('runner.builders')

-- =====================================================================
-- PLUGIN STATE
-- =====================================================================

M.config = config.default
M.last_build = {}      -- Cache of last built binaries per filetype
M.run_history = {}     -- History of recent executions
M.watch_mode = false   -- Watch mode state

-- =====================================================================
-- SETUP AND INITIALIZATION
-- =====================================================================

--- Initialize the plugin with user configuration
--- @param opts table|nil User configuration options
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', config.default, opts or {})
  
  -- Register all user commands
  M._create_user_commands()
end

--- Create all user commands for the plugin
--- @private
function M._create_user_commands()
  local commands = {
    { 'RunCode',      M.run,              'Run current file' },
    { 'RunFile',      M.run,              'Run current file' },
    { 'RunWithInput', M.run_with_input,   'Run current file with input.txt' },
    { 'RunTests',     M.run_tests,        'Run tests from tests/ directory' },
    { 'RunBuild',     M.build_only,       'Build without running' },
    { 'RunLast',      M.run_last,         'Run last built executable' },
    { 'RunFloat',     M.run_float,        'Run in floating terminal' },
    { 'RunIOFiles',   M.run_with_io_files, 'Run with input.txt -> output.txt' },
    { 'RunProfile',   M.cycle_profile,    'Cycle optimization profile' },
    { 'RunWatch',     M.toggle_watch,     'Toggle watch mode (auto-run on save)' },
    { 'RunHistory',   M.show_history,     'Show run history' },
    { 'RunClean',     M.clean_build,      'Clean build directory' },
  }
  
  for _, cmd in ipairs(commands) do
    vim.api.nvim_create_user_command(cmd[1], cmd[2], { desc = cmd[3] })
  end
end

-- =====================================================================
-- HELPER FUNCTIONS
-- =====================================================================

--- Get runner configuration for current filetype
--- @return string|nil filetype Current filetype
--- @return table|nil runner Runner configuration
local function get_runner()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner then
    vim.notify('No runner configured for filetype: ' .. ft, vim.log.levels.WARN)
    return nil, nil
  end
  
  return ft, runner
end

--- Save current buffer and suppress errors
local function save_current_buffer()
  pcall(vim.cmd, 'write')
end

--- Create a completion callback that records execution time
--- @param ft string Filetype
--- @param start_time number Start time in nanoseconds
--- @return function Completion callback
local function create_completion_callback(ft, start_time)
  return function()
    local elapsed = (vim.loop.hrtime() - start_time) / 1e9
    local filename = vim.fn.expand('%:t')
    
    -- Add to history
    table.insert(M.run_history, 1, {
      file = filename,
      filetype = ft,
      time = elapsed,
      timestamp = os.date('%H:%M:%S'),
    })
    
    -- Keep only last 10 runs
    if #M.run_history > 10 then
      table.remove(M.run_history)
    end
    
    if M.config.show_time then
      vim.notify(
        string.format('✓ Execution completed in %.3fs', elapsed),
        vim.log.levels.INFO
      )
    end
  end
end

--- Get binary path for current file
--- @return string Binary path
local function get_binary_path()
  local base = vim.fn.expand('%:t:r')
  return vim.fn.getcwd() .. '/' .. M.config.build_dir .. '/' .. base
end

--- Check if binary exists and prompt user to build
--- @param bin string Binary path
--- @return boolean True if should continue, false if cancelled
local function check_binary_exists(bin)
  if vim.fn.filereadable(bin) == 1 then
    return true
  end
  
  local choice = vim.fn.confirm(
    'Binary not found. Do you want to build first?',
    '&Yes\n&No',
    1
  )
  
  if choice ~= 1 then
    vim.notify('Cancelled', vim.log.levels.INFO)
    return false
  end
  
  return true
end

--- Clean binary after run if configured
--- @param bin string Binary path
local function clean_binary_if_configured(bin)
  if M.config.clean_after_run and vim.fn.filereadable(bin) == 1 then
    vim.fn.delete(bin)
    vim.notify('🗑️  Binary removed', vim.log.levels.INFO)
  end
end

--- Execute interpreted language
--- @param runner table Runner configuration
--- @param on_complete function Completion callback
local function execute_interpreted(runner, on_complete)
  local filepath = vim.fn.expand('%:p')
  local cmd = runner.command:gsub('$FILE', filepath)
  terminal.open_bottom(cmd, on_complete)
end

--- Execute compiled language
--- @param ft string Filetype
--- @param runner table Runner configuration
--- @param on_complete function Completion callback
local function execute_compiled(ft, runner, on_complete)
  local bin = get_binary_path()
  
  -- Check if binary exists and ask to build if not
  if not check_binary_exists(bin) then
    return
  end
  
  builders.build_and_run(ft, runner, M.config, M.last_build, function()
    on_complete()
    clean_binary_if_configured(bin)
  end)
end

-- =====================================================================
-- CORE EXECUTION FUNCTIONS
-- =====================================================================

--- Main run function - compile (if needed) and execute
function M.run()
  local ft, runner = get_runner()
  if not runner then return end
  
  save_current_buffer()
  
  local start_time = vim.loop.hrtime()
  local on_complete = create_completion_callback(ft, start_time)
  
  if runner.type == 'compiled' then
    execute_compiled(ft, runner, on_complete)
  elseif runner.type == 'interpreted' then
    execute_interpreted(runner, on_complete)
  end
end

--- Build without running
function M.build_only()
  local ft, runner = get_runner()
  if not runner then return end
  
  if runner.type ~= 'compiled' then
    vim.notify('This filetype does not require compilation', vim.log.levels.INFO)
    return
  end
  
  save_current_buffer()
  builders.build_only(ft, runner, M.config, M.last_build)
end

--- Run last built executable without recompiling
function M.run_last()
  local ft, runner = get_runner()
  if not runner then return end
  
  if runner.type ~= 'compiled' then
    vim.notify('Not a compiled language', vim.log.levels.WARN)
    return
  end
  
  local bin = get_binary_path()
  
  if vim.fn.filereadable(bin) == 0 then
    vim.notify(
      'Binary not found. Please build first with <leader>cb (RunBuild)',
      vim.log.levels.WARN
    )
    return
  end
  
  local start_time = vim.loop.hrtime()
  
  local function on_complete()
    local elapsed = (vim.loop.hrtime() - start_time) / 1e9
    
    if M.config.show_time then
      vim.notify(
        string.format('✓ Execution completed in %.3fs', elapsed),
        vim.log.levels.INFO
      )
    end
    
    clean_binary_if_configured(bin)
  end
  
  terminal.open_bottom(bin, on_complete)
end

-- =====================================================================
-- INPUT/OUTPUT HANDLING
-- =====================================================================

--- Ensure input file exists, create if needed
--- @param input_file string Path to input file
local function ensure_input_file_exists(input_file)
  if vim.fn.filereadable(input_file) == 0 then
    vim.fn.writefile({''}, input_file)
    vim.notify('Created empty ' .. input_file, vim.log.levels.INFO)
  end
end

--- Run with input.txt redirected to stdin
function M.run_with_input()
  local ft, runner = get_runner()
  if not runner then return end
  
  local input_file = M.config.input_file
  ensure_input_file_exists(input_file)
  save_current_buffer()
  
  if runner.type == 'compiled' then
    builders.build_and_run_with_input(ft, runner, M.config, M.last_build, input_file)
  elseif runner.type == 'interpreted' then
    local filepath = vim.fn.expand('%:p')
    local cmd = runner.command:gsub('$FILE', filepath) .. ' < ' .. input_file
    terminal.open_bottom(cmd)
  end
end

--- Run with input.txt -> output.txt redirection
function M.run_with_io_files()
  local ft, runner = get_runner()
  if not runner then return end
  
  local input_file = M.config.input_file
  local output_file = M.config.output_file
  
  ensure_input_file_exists(input_file)
  save_current_buffer()
  
  --- Execute with I/O redirection
  --- @param bin_or_cmd string Binary path or command
  local function execute_with_io(bin_or_cmd)
    local cmd = string.format('%s < %s > %s', bin_or_cmd, input_file, output_file)
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    
    if exit_code == 0 then
      vim.notify('Success! Output written to ' .. output_file, vim.log.levels.INFO)
    else
      vim.notify('Runtime error (code ' .. exit_code .. ')', vim.log.levels.ERROR)
    end
  end
  
  if runner.type == 'compiled' then
    local bin = get_binary_path()
    
    if vim.fn.filereadable(bin) == 0 then
      builders.build_only(ft, runner, M.config, M.last_build, execute_with_io)
    else
      execute_with_io(bin)
    end
  elseif runner.type == 'interpreted' then
    local filepath = vim.fn.expand('%:p')
    local cmd = runner.command:gsub('$FILE', filepath)
    execute_with_io(cmd)
  end
end

-- =====================================================================
-- FLOATING TERMINAL
-- =====================================================================

--- Run in floating terminal
function M.run_float()
  local ft, runner = get_runner()
  if not runner then return end
  
  save_current_buffer()
  
  if runner.type == 'compiled' then
    builders.build_only(ft, runner, M.config, M.last_build, function(bin)
      terminal.open_floating(bin)
    end)
  elseif runner.type == 'interpreted' then
    local filepath = vim.fn.expand('%:p')
    local cmd = runner.command:gsub('$FILE', filepath)
    terminal.open_floating(cmd)
  end
end

-- =====================================================================
-- TEST RUNNER
-- =====================================================================

--- Check if test directory exists
--- @return boolean True if tests directory exists
local function test_directory_exists()
  local test_dir = M.config.test_dir
  
  if vim.fn.isdirectory(test_dir) == 0 then
    vim.notify('No ' .. test_dir .. ' directory found', vim.log.levels.WARN)
    return false
  end
  
  return true
end

--- Get test input files
--- @return table|nil Array of test input file paths
local function get_test_input_files()
  local test_dir = M.config.test_dir
  local inputs = vim.fn.globpath(test_dir, '*.in', false, true)
  
  if #inputs == 0 then
    vim.notify('No *.in test files found in ' .. test_dir, vim.log.levels.WARN)
    return nil
  end
  
  return inputs
end

--- Run a single test case
--- @param bin_or_cmd string Binary or command to run
--- @param infile string Input file path
--- @return boolean passed True if test passed
--- @return string result_message Result message
local function run_single_test(bin_or_cmd, infile)
  local stem = infile:match('(.+)%.in$') or infile
  local expected_file = stem .. '.out'
  local cmd = string.format('%s < %s', bin_or_cmd, infile)
  
  local actual = vim.fn.system(cmd)
  local has_expected = vim.fn.filereadable(expected_file) == 1
  
  if not has_expected then
    return nil, '… ' .. vim.fn.fnamemodify(infile, ':t') .. ' (no expected .out file)'
  end
  
  local expected = table.concat(vim.fn.readfile(expected_file), '\n') .. '\n'
  
  if actual == expected then
    return true, '✓ ' .. vim.fn.fnamemodify(infile, ':t') .. ' PASS'
  else
    local msg = '✗ ' .. vim.fn.fnamemodify(infile, ':t') .. ' FAIL\n'
    msg = msg .. '  expected: ' .. expected:gsub('\n$', '') .. '\n'
    msg = msg .. '  actual  : ' .. actual:gsub('\n$', '')
    return false, msg
  end
end

--- Run all tests from tests/ directory
function M.run_tests()
  local ft, runner = get_runner()
  if not runner then return end
  
  if not test_directory_exists() then return end
  
  local inputs = get_test_input_files()
  if not inputs then return end
  
  --- Execute all tests
  --- @param bin_or_cmd string Binary or command to run
  local function run_all_tests(bin_or_cmd)
    local passed, total = 0, #inputs
    local results = {}
    
    for _, infile in ipairs(inputs) do
      local test_passed, result_msg = run_single_test(bin_or_cmd, infile)
      table.insert(results, result_msg)
      
      if test_passed then
        passed = passed + 1
      end
    end
    
    table.insert(results, string.format('\nResult: %d/%d passed', passed, total))
    
    vim.notify(
      table.concat(results, '\n'),
      passed == total and vim.log.levels.INFO or vim.log.levels.WARN,
      { title = 'Test Results' }
    )
  end
  
  save_current_buffer()
  
  if runner.type == 'compiled' then
    local bin = get_binary_path()
    
    if vim.fn.filereadable(bin) == 0 then
      builders.build_only(ft, runner, M.config, M.last_build, run_all_tests)
    else
      run_all_tests(bin)
    end
  elseif runner.type == 'interpreted' then
    local filepath = vim.fn.expand('%:p')
    local cmd = runner.command:gsub('$FILE', filepath)
    run_all_tests(cmd)
  end
end

-- =====================================================================
-- UTILITY FUNCTIONS
-- =====================================================================

--- Cycle through optimization profiles (for compiled languages)
function M.cycle_profile()
  local ft, runner = get_runner()
  if not runner then return end
  
  if runner.type ~= 'compiled' or not runner.profiles then
    vim.notify('No profiles available for this filetype', vim.log.levels.WARN)
    return
  end
  
  M.config.current_profile = M.config.current_profile or {}
  local current = M.config.current_profile[ft] or 1
  current = current % #runner.profiles + 1
  M.config.current_profile[ft] = current
  
  vim.notify('Profile: ' .. runner.profiles[current].name, vim.log.levels.INFO)
end

--- Toggle watch mode (auto-run on save)
function M.toggle_watch()
  M.watch_mode = not M.watch_mode
  
  if M.watch_mode then
    -- Create autocommand to run on save
    vim.api.nvim_create_autocmd('BufWritePost', {
      group = vim.api.nvim_create_augroup('RunnerWatch', { clear = true }),
      pattern = '*',
      callback = function()
        local ft = vim.bo.filetype
        if M.config.runners[ft] then
          vim.notify('🔄 Watch mode: Running...', vim.log.levels.INFO)
          vim.defer_fn(function()
            M.run()
          end, 100)
        end
      end,
    })
    vim.notify('👁 Watch mode: ON (auto-run on save)', vim.log.levels.INFO)
  else
    -- Clear autocommand
    pcall(vim.api.nvim_del_augroup_by_name, 'RunnerWatch')
    vim.notify('👁 Watch mode: OFF', vim.log.levels.INFO)
  end
end

--- Show run history with timestamps and execution times
function M.show_history()
  if #M.run_history == 0 then
    vim.notify('No run history yet', vim.log.levels.INFO)
    return
  end
  
  local lines = { '📊 Run History (Last 10):', '═══════════════════════════' }
  
  for i, entry in ipairs(M.run_history) do
    table.insert(lines, string.format(
      '%d. [%s] %s (%s) - %.3fs',
      i,
      entry.timestamp,
      entry.file,
      entry.filetype,
      entry.time
    ))
  end
  
  vim.notify(
    table.concat(lines, '\n'),
    vim.log.levels.INFO,
    { title = 'Runner History' }
  )
end

--- Clean build directory
function M.clean_build()
  local build_dir = vim.fn.getcwd() .. '/' .. M.config.build_dir
  
  if vim.fn.isdirectory(build_dir) == 0 then
    vim.notify('Build directory does not exist', vim.log.levels.INFO)
    return
  end
  
  local choice = vim.fn.confirm(
    'Clean build directory: ' .. build_dir .. '?',
    '&Yes\n&No',
    2
  )
  
  if choice == 1 then
    vim.fn.delete(build_dir, 'rf')
    vim.notify('🗑️  Build directory cleaned', vim.log.levels.INFO)
    M.last_build = {}
  end
end

return M
