local cmd = {}

--- :LuaProfile {subcommand} [args...]
cmd.LuaProfile = {
  _dispatcher = ...,
  _complete = ...,
  start = function()
    require("profiler").start()
  end,
  stop = function()
    require("profiler").stop()
  end,
  result = function()
    -- open the result
    vim.cmd [[ tabnew /tmp/profiling.log ]]
  end,
  run = function(duration)
    if duration == nil or tonumber(duration) == nil then
      return vim.api.nvim_err_writeln("Integer argument required: {duration} (ms)")
    end
    duration = tonumber(duration)
    require("profiler").run({
      duration = duration --[[ @as integer ]],
    })
  end,
}

function cmd.LuaProfile._complete()
  return { "start", "stop", "result", "run" }
end

---@param subcommand string
function cmd.LuaProfile._dispatcher(subcommand, ...)
  local args = { ... }
  local fn = cmd.LuaProfile[subcommand]
  if fn then
    xpcall(function()
      fn(unpack(args))
    end, function(err)
      local msg = "`:LuaProfile` ran into an error!\n\n" .. err
      msg = debug.traceback(msg, 1)
      vim.notify(msg, vim.log.levels.ERROR, { title = "profiler" })
    end)
  else
    vim.api.nvim_err_writeln("Unknown command: " .. subcommand)
  end
end

vim.api.nvim_create_user_command("LuaProfile", function(args)
  cmd.LuaProfile._dispatcher(unpack(args.fargs))
end, { nargs = "+", bar = true, complete = cmd.LuaProfile._complete })
