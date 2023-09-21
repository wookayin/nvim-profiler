# A simple Lua Profiler for Neovim

*Work-in-progress. Not intended for stable use yet.*


Usage (Commands):

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

Programmatic (Lua API) Usage:

```lua
require("profiler").runcall(function()
  -- some heavy operations ...
end)
```


License
-------

Apache 2.0 License
