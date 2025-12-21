-- Plugin entry point for runner.nvim
-- This file is loaded automatically by Neovim when the plugin is installed

-- Prevent loading the plugin twice
if vim.g.loaded_runner then
  return
end
vim.g.loaded_runner = true

-- The actual plugin setup is done in lua/runner/init.lua
-- Users need to call require('runner').setup() in their config
