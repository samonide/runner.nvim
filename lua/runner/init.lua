-- =====================================================================
-- runner.nvim - Multi-language code runner for Neovim
-- A universal code execution plugin that intelligently runs code based
-- on file type with customizable configurations per language
-- =====================================================================

local M = {}
local config = require('runner.config')
local terminal = require('runner.terminal')
local builders = require('runner.builders')

-- Plugin state
M.config = config.default
M.last_build = {}
M.run_history = {}
M.watch_mode = false

-- Setup function to initialize the plugin with user configuration
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', config.default, opts or {})
  
  -- Create user commands
  vim.api.nvim_create_user_command('RunCode', function()
    M.run()
  end, { desc = 'Run current file' })
  
  vim.api.nvim_create_user_command('RunFile', function()
    M.run()
  end, { desc = 'Run current file' })
  
  vim.api.nvim_create_user_command('RunWithInput', function()
    M.run_with_input()
  end, { desc = 'Run current file with input.txt' })
  
  vim.api.nvim_create_user_command('RunTests', function()
    M.run_tests()
  end, { desc = 'Run tests from tests/ directory' })
  
  vim.api.nvim_create_user_command('RunBuild', function()
    M.build_only()
  end, { desc = 'Build without running' })
  
  vim.api.nvim_create_user_command('RunLast', function()
    M.run_last()
  end, { desc = 'Run last built executable' })
  
  vim.api.nvim_create_user_command('RunFloat', function()
    M.run_float()
  end, { desc = 'Run in floating terminal' })
  
  vim.api.nvim_create_user_command('RunIOFiles', function()
    M.run_with_io_files()
  end, { desc = 'Run with input.txt -> output.txt' })
  
  vim.api.nvim_create_user_command('RunProfile', function()
    M.cycle_profile()
  end, { desc = 'Cycle optimization profile' })
  
  vim.api.nvim_create_user_command('RunWatch', function()
    M.toggle_watch()
  end, { desc = 'Toggle watch mode (auto-run on save)' })
  
  vim.api.nvim_create_user_command('RunHistory', function()
    M.show_history()
  end, { desc = 'Show run history' })
  
  vim.api.nvim_create_user_command('RunClean', function()
    M.clean_build()
  end, { desc = 'Clean build directory' })
end

-- Main run function
function M.run()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner then
    vim.notify('No runner configured for filetype: ' .. ft, vim.log.levels.WARN)
    return
  end
  
  -- Save file before running
  pcall(vim.cmd, 'write')
  
  -- Record start time
  local start_time = vim.loop.hrtime()
  
  local function on_complete()
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
      vim.notify(string.format('✓ Execution completed in %.3fs', elapsed), vim.log.levels.INFO)
    end
  end
  
  if runner.type == 'compiled' then
    builders.build_and_run(ft, runner, M.config, M.last_build, on_complete)
  elseif runner.type == 'interpreted' then
    local filepath = vim.fn.expand('%:p')
    local cmd = runner.command:gsub('$FILE', filepath)
    terminal.open_bottom(cmd, on_complete)
  end
end

-- Build without running
function M.build_only()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner then
    vim.notify('No runner configured for filetype: ' .. ft, vim.log.levels.WARN)
    return
  end
  
  if runner.type ~= 'compiled' then
    vim.notify('This filetype does not require compilation', vim.log.levels.INFO)
    return
  end
  
  pcall(vim.cmd, 'write')
  builders.build_only(ft, runner, M.config, M.last_build)
end

-- Run last built executable
function M.run_last()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner or runner.type ~= 'compiled' then
    vim.notify('Not a compiled language', vim.log.levels.WARN)
    return
  end
  
  local base = vim.fn.expand('%:t:r')
  local bin = vim.fn.getcwd() .. '/' .. M.config.build_dir .. '/' .. base
  
  if vim.fn.filereadable(bin) == 0 then
    vim.notify('Binary not found. Build first with :RunBuild or :RunCode', vim.log.levels.WARN)
    return
  end
  
  terminal.open_bottom(bin)
end

-- Run with input.txt
function M.run_with_input()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner then
    vim.notify('No runner configured for filetype: ' .. ft, vim.log.levels.WARN)
    return
  end
  
  local input_file = M.config.input_file
  
  -- Create input.txt if it doesn't exist
  if vim.fn.filereadable(input_file) == 0 then
    vim.fn.writefile({''}, input_file)
    vim.notify('Created empty ' .. input_file, vim.log.levels.INFO)
  end
  
  pcall(vim.cmd, 'write')
  
  if runner.type == 'compiled' then
    builders.build_and_run_with_input(ft, runner, M.config, M.last_build, input_file)
  elseif runner.type == 'interpreted' then
    local filepath = vim.fn.expand('%:p')
    local cmd = runner.command:gsub('$FILE', filepath) .. ' < ' .. input_file
    terminal.open_bottom(cmd)
  end
end

-- Run in floating terminal
function M.run_float()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner then
    vim.notify('No runner configured for filetype: ' .. ft, vim.log.levels.WARN)
    return
  end
  
  pcall(vim.cmd, 'write')
  
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

-- Run with input.txt -> output.txt
function M.run_with_io_files()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner then
    vim.notify('No runner configured for filetype: ' .. ft, vim.log.levels.WARN)
    return
  end
  
  local input_file = M.config.input_file
  local output_file = M.config.output_file
  
  -- Create input.txt if it doesn't exist
  if vim.fn.filereadable(input_file) == 0 then
    vim.fn.writefile({''}, input_file)
    vim.notify('Created empty ' .. input_file, vim.log.levels.INFO)
  end
  
  pcall(vim.cmd, 'write')
  
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
    local base = vim.fn.expand('%:t:r')
    local bin = vim.fn.getcwd() .. '/' .. M.config.build_dir .. '/' .. base
    
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

-- Run all tests from tests/ directory
function M.run_tests()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner then
    vim.notify('No runner configured for filetype: ' .. ft, vim.log.levels.WARN)
    return
  end
  
  local test_dir = M.config.test_dir
  
  if vim.fn.isdirectory(test_dir) == 0 then
    vim.notify('No ' .. test_dir .. ' directory found', vim.log.levels.WARN)
    return
  end
  
  local inputs = vim.fn.globpath(test_dir, '*.in', false, true)
  
  if #inputs == 0 then
    vim.notify('No *.in test files found in ' .. test_dir, vim.log.levels.WARN)
    return
  end
  
  local function run_tests(bin_or_cmd)
    local passed, total = 0, #inputs
    local results = {}
    
    for _, infile in ipairs(inputs) do
      local stem = infile:match('(.+)%.in$') or infile
      local expected_file = stem .. '.out'
      local cmd = string.format('%s < %s', bin_or_cmd, infile)
      local actual = vim.fn.system(cmd)
      local expected = ''
      local has_expected = vim.fn.filereadable(expected_file) == 1
      
      if has_expected then
        expected = table.concat(vim.fn.readfile(expected_file), '\n') .. '\n'
      end
      
      if has_expected and actual == expected then
        passed = passed + 1
        table.insert(results, '✓ ' .. vim.fn.fnamemodify(infile, ':t') .. ' PASS')
      elseif has_expected then
        table.insert(results, '✗ ' .. vim.fn.fnamemodify(infile, ':t') .. ' FAIL')
        table.insert(results, '  expected: ' .. expected:gsub('\n$', ''))
        table.insert(results, '  actual  : ' .. actual:gsub('\n$', ''))
      else
        table.insert(results, '… ' .. vim.fn.fnamemodify(infile, ':t') .. ' (no expected .out file)')
      end
    end
    
    table.insert(results, string.format('\nResult: %d/%d passed', passed, total))
    vim.notify(
      table.concat(results, '\n'),
      passed == total and vim.log.levels.INFO or vim.log.levels.WARN,
      { title = 'Test Results' }
    )
  end
  
  pcall(vim.cmd, 'write')
  
  if runner.type == 'compiled' then
    local base = vim.fn.expand('%:t:r')
    local bin = vim.fn.getcwd() .. '/' .. M.config.build_dir .. '/' .. base
    
    if vim.fn.filereadable(bin) == 0 then
      builders.build_only(ft, runner, M.config, M.last_build, run_tests)
    else
      run_tests(bin)
    end
  elseif runner.type == 'interpreted' then
    local filepath = vim.fn.expand('%:p')
    local cmd = runner.command:gsub('$FILE', filepath)
    run_tests(cmd)
  end
end

-- Cycle through optimization profiles (for compiled languages)
function M.cycle_profile()
  local ft = vim.bo.filetype
  local runner = M.config.runners[ft]
  
  if not runner or runner.type ~= 'compiled' or not runner.profiles then
    vim.notify('No profiles available for this filetype', vim.log.levels.WARN)
    return
  end
  
  M.config.current_profile = M.config.current_profile or {}
  local current = M.config.current_profile[ft] or 1
  current = current % #runner.profiles + 1
  M.config.current_profile[ft] = current
  
  vim.notify('Profile: ' .. runner.profiles[current].name, vim.log.levels.INFO)
end

-- Toggle watch mode (auto-run on save)
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

-- Show run history
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
  
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Runner History' })
end

-- Clean build directory
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
