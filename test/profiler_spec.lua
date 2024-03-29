-- plenary-harness tests for nvim-profiler.

local profiler = require("profiler")
local assert = require("luassert")

describe("runcall", function()
  after_each(function()
    vim.print("")
  end)

  it("works", function()
    local info, r1, r2 = profiler.runcall(function()
      vim.uv.sleep(50)
      return 42, 43
    end)
    vim.print(info)
    assert.equal(42, r1)
    assert.equal(43, r2)
    assert.equal("table", type(info))
    assert.equal("number", type(info.elapsed))
    assert.is_true(info.elapsed > 50)
  end)

  it("opts: logfile", function()
    local logfile = vim.fn.tempname() .. ".test"

    local opts  ---@type profiler.opts
    opts = { logfile = logfile }

    profiler.runcall(function() end, opts)
    assert.equal(logfile, profiler._state.logfile)
  end)

  it("opts: flamegraph", function()
    local opts  ---@type profiler.opts
    opts = { flamegraph = true }

    profiler.runcall(function() end, opts)
  end)
end)

describe("LuaProfile command", function()
  before_each(function()
    vim.cmd [[ source plugin/profiler.lua ]]
  end)
  after_each(function()
    vim.print("")
  end)

  it("works", function()
    vim.cmd [[ LuaProfile start ]]
    vim.cmd [[ sleep 100m ]]
    vim.cmd [[ LuaProfile stop ]]
  end)
end)
