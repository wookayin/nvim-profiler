# A simple Lua Profiler for Neovim

*Work-in-progress. Not intended for stable use yet.*


Usage: Commands
---------------

```vim
" Run a profiling session for the next 5000 milliseconds
:LuaProfile run 5000
```

```vim
:LuaProfile start

" do some heavy operations (in Lua)

:LuaProfile stop
:LuaProfile result
```

FlameGraph (requires [flamegraph] installed):

```vim
:LuaProfile run 5000 --flamegraph
```

```vim
:LuaProfile start --flamegraph
" do some heavy operations ...
:LuaProfile stop | LuaProfile result
```


Usage: Programmatic (Lua API)
-----------------------------

```lua
require("profiler").runcall(function()
  -- some heavy operations ...
end, { }) -- opts
```

[flamegraph]: https://github.com/flamegraph-rs/flamegraph

License
-------

Apache 2.0 License
