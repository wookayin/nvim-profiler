--- profiler.utils
local M = {}

---@param extension ".svg"|".log"
function M.make_temp_file(extension)
  assert(vim.startswith(extension, "."), "Invalid extension : " .. extension)

  return vim.fn.tempname() .. "-profiling" .. extension
end

---@param path string
function M.open(path)
  if vim.ui.open then -- nvim 0.10+
    return vim.ui.open(path)
  end

  local cmd
  if vim.fn.has('mac') == 1 then
    cmd = { 'open', path }
  elseif vim.fn.has('win32') == 1 then
    cmd = { 'explorer', path }
  elseif vim.fn.executable('wslview') == 1 then
    cmd = { 'wslview', path }
  elseif vim.fn.executable('xdg-open') == 1 then
    cmd = { 'xdg-open', path }
  end
  if cmd then
    vim.fn.system(cmd)
  end
end

return M
