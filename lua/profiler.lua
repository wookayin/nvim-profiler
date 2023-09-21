--- Simple Lua profiler for neovim

local M = {}

local jit = require("jit")
assert(20199 == jit.version_num,
  "LuaJIT version 2.1.0 (20199) or higher is required, current: " .. jit.version ..
  ". Please upgrade your neovim to v0.9.2 or higher.")

local p = require("jit.p")  -- $VIMRUNTIME/lua/jit/p.lua
local state = {
  started = false,
  logfile = nil,
  start_time = nil,
}

local uv = vim.uv or vim.loop or error("vim.uv does not exist")


function M.echo(msg, level)
  vim.notify(msg, level, { title = 'profiler' })
end

--- Reload all built-in vim.* modules that are pre-compiled and pre-loaded from the binary,
--- from $VIMRUNTIME source (see $VIMRUNTIME/lua/vim/_meta.lua). This hurts performance a bit,
--- but allows debugging information (e.g. linenumber) about which function is being executed
--- instead of showing [vim._editor:0].
---
--- This may have some subtle side-effects, such as losing internal states.
function M.reload_builtin_modules()
  for name, _ in pairs(package.preload) do
    -- vim.*, except for some packages that can break everything
    if name:sub(1, 4) == "vim." and (
      name ~= "vim._init_packages"
    ) then
      package.loaded[name] = nil
      package.preload[name] = nil
      -- reload from $VIMRUNTIME source with debugging info
      vim[name:sub(5)] = require(name)
    end
  end
end

---@class profiler.opts
---@field logfile string  -- TODO: open results in a scratch/floating buffer.
---@field stack_depth integer


--- Start a new profiling session.
---@param opts profiler.opts? optional parametres
function M.start(opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend("keep", opts, {
    logfile = "/tmp/profiling.log",   -- TODO: use tempfile
    stack_depth = 10,
  })
  assert(not state.started, "Already started")

  -- See $VIMRUNTIME/lua/jit/p.lua
  -- https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/lj_profile.c
  mode = table.concat({
    tostring(opts.stack_depth), -- stack depth: 99
    "s",  -- Split at the second stack level.
    "p",  -- Show full path for module names
    "l",  -- Stack dump, show full file module:line
    "v",  -- Show VM states (e.g. C code, GC, Interpreted, etc.)
    "r",  -- show sample counts instead of percentage (it's like millisecs)
    -- "a",  -- with annotated source code excerpts
    "m0", -- minimum sample percentage is 0, show all entries
    "i1", -- sample every 1 milliseconds
  }, ",")
  p.start(mode, opts.logfile)
  state.started = true
  state.logfile = opts.logfile
  state.start_time = uv.hrtime()
  M.echo(("Started profiling: %s"):format(state.logfile))
end

--- Stop the current profiling session.
function M.stop()
  if not state.started then
    error("Profiler is not running.")
  end
  p.stop()
  local elapsed = (uv.hrtime() - state.start_time) / 1e9   -- in seconds

  local msg_result = "\n" .. "Run `:LuaProfile result` to see the result."
  M.echo(("Stopped profiling (Elapsed: %.3f s): %s" .. msg_result):format(elapsed, state.logfile))
  state.started = false
end

---Execute a function {fn} with profiling enabled.
---
---@generic R
---@param fn fun(): R
---@param opts profiler.opts?
---@return R
function M.runcall(fn, opts)
  M.start(opts)
  local ret

  ok, ret = xpcall(function()
    return vim.F.pack_len(fn())
  end, function(err)
    -- TODO: exception handling
  end)
  M.stop()

  if not ok then
    error(ret)
  end
  return vim.F.unpack_len(ret)
end

---Wrap a function to enable profiling around its execution.
---
---@generic P, R
---@param fn fun(...: P): R
---@param opts profiler.opts?
---@return fun(...: P): R
function M.wrap(fn, opts)
  return function(...)
    local args = vim.F.pack_len(...)
    local wrapped = function()
      return fn(vim.F.unpack_len(args))
    end
    local ret = M.runcall(wrapped, opts)
    return ret
  end
end

---@class profiler.run_opts: profiler.opts
---@field duration? integer
---@field reload_builtin? boolean

--- Run LuaJIT profiler for some fixed duration.
---@param opts profiler.run_opts?
function M.run(opts) -- TODO change name
  opts = vim.tbl_deep_extend("force", {
    duration = 5000,
    reload_builtin = false,
    open_result = true,
  }, opts or {})

  if opts.reload_builtin then
    M.reload_builtin_modules()
  end

  M.start()
  vim.defer_fn(function()
    if not state.started then
      return  -- probably canceled
    end
    M.stop()
    if opts.open_result then
      vim.cmd [[ tabnew /tmp/profiling.log ]]
    end
  end, opts.duration)
end

return M
