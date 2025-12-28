-- =====================================================================
-- Terminal management for runner.nvim
-- Handles creating and managing terminal windows with clean state
-- management to prevent window/buffer leaks and stacking issues.
-- =====================================================================

local M = {}

-- =====================================================================
-- STATE MANAGEMENT
-- =====================================================================

-- Persistent terminal state for bottom split terminal
local runner_term_buf = nil
local runner_term_win = nil

-- =====================================================================
-- HELPER FUNCTIONS
-- =====================================================================

--- Close terminal window if it exists and is valid
--- Cleans up the window state to prevent stacking
local function close_existing_terminal()
  if runner_term_win and vim.api.nvim_win_is_valid(runner_term_win) then
    pcall(vim.api.nvim_win_close, runner_term_win, true)
    runner_term_win = nil
  end
end

--- Create a new bottom split terminal window
--- @return number Buffer handle for the terminal
local function create_bottom_split()
  vim.cmd("botright 15split")
  vim.cmd("enew")
  
  runner_term_buf = vim.api.nvim_get_current_buf()
  runner_term_win = vim.api.nvim_get_current_win()
  
  return vim.api.nvim_get_current_buf()
end

--- Start a terminal job with the given command
--- @param cmd string Command to execute
--- @param on_complete function|nil Optional callback on job exit
local function start_terminal_job(cmd, on_complete)
  if on_complete then
    vim.fn.termopen(cmd, {
      on_exit = function()
        vim.schedule(on_complete)
      end,
    })
  else
    vim.fn.termopen(cmd)
  end
  
  vim.cmd("startinsert")
end

--- Calculate centered position for floating window
--- @param width number Window width
--- @param height number Window height
--- @return number row, number col
local function calculate_center_position(width, height)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  return row, col
end

--- Create a floating window configuration
--- @return table Window configuration for nvim_open_win
local function create_float_config()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)
  local row, col = calculate_center_position(width, height)
  
  return {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }
end

--- Get shell command for floating terminal
--- @param cmd string|table|nil Command to run
--- @return table Shell command array
local function get_shell_command(cmd)
  if type(cmd) == 'string' and #cmd > 0 then
    return { 'bash', '--noprofile', '-c', cmd .. '; exec bash' }
  elseif type(cmd) == 'table' then
    return cmd
  else
    return { 'bash', '--noprofile' }
  end
end

-- =====================================================================
-- PUBLIC API - Bottom Split Terminal
-- =====================================================================

--- Open a bottom split terminal running a command
--- Automatically closes any existing terminal to prevent stacking
--- @param cmd string Command to execute
--- @param on_complete function|nil Optional callback on command completion
--- @return number Buffer handle
function M.open_bottom(cmd, on_complete)
  -- Close existing terminal to avoid stacking
  close_existing_terminal()
  
  -- Create new terminal
  local buf = create_bottom_split()
  
  -- Start the command
  start_terminal_job(cmd, on_complete)
  
  return buf
end

-- =====================================================================
-- PUBLIC API - Floating Terminal
-- =====================================================================

--- Open a brand-new floating terminal and run a command
--- Creates a disposable floating terminal (not persistent)
--- @param cmd string|table|nil Command to run
--- @return number buf, number win Buffer and window handles
function M.open_floating(cmd)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, create_float_config())
  
  vim.fn.termopen(get_shell_command(cmd))
  vim.cmd('startinsert')
  
  return buf, win
end

--- Toggle a persistent floating terminal
--- Reuses the same buffer/window across toggles for a persistent shell
function M.toggle_floating()
  local win = vim.g._runner_float_win
  local buf = vim.g._runner_float_buf
  
  -- If window is open, close it
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
    vim.g._runner_float_win = nil
    return
  end
  
  -- If buffer exists but window is closed, reopen window
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.g._runner_float_win = vim.api.nvim_open_win(buf, true, create_float_config())
    vim.cmd('startinsert')
    return
  end
  
  -- Create new buffer and window
  buf = vim.api.nvim_create_buf(false, true)
  vim.g._runner_float_buf = buf
  vim.g._runner_float_win = vim.api.nvim_open_win(buf, true, create_float_config())
  vim.fn.termopen({ 'bash', '--noprofile' })
  vim.cmd('startinsert')
end

return M
