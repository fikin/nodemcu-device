--
-- File: _init.lua
--[[

  This is a template for the LFS equivalent of the SPIFFS init.lua.

  It is tailored for Lua 5.3 only !

---------------------------------------------------------------------------------]]
--[[
  -------------------------------------------------------------------------------
  The second section adds the LFS to the require searchlist, so that you can
  require a Lua module 'jean' in the LFS by simply doing require "jean". However
  note that this is at the search entry following the FS searcher, so if you also
  have jean.lc or jean.lua in SPIFFS, then this SPIFFS version will get loaded into
  RAM instead of using. (Useful, for development).

  See docs/en/lfs.md and the 'loaders' array in app/lua/loadlib.c for more details.

---------------------------------------------------------------------------------]]
package.loaders[3] = function(module) -- loader_flash
  return node.LFS.get(module)
end

--[[
  ----------------------------------------------------------------------------
  These replace the builtins loadfile & dofile with ones which preferentially
  load from the filesystem and fall back to LFS.  Flipping the search order
  is an exercise left to the reader.-
------------------------------------------------------------------------------]]
local lf = loadfile
_G.loadfile = function(n)
  if file.exists(n) then
    return lf(n)
  end
  local mod = n:match("^([^\\.]+)")
  local fn = mod and node.LFS.get(mod)
  return (fn or error(("Cannot find '%s' in FS or LFS"):format(n))) and fn
end

-- Lua's dofile (luaB_dofile) reaches directly for luaL_loadfile; shim instead
_G.dofile = function(n)
  return assert(loadfile(n))()
end
