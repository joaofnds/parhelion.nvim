if not package.loaded.parhelion then
  local root = debug.getinfo(1, "S").source:match "^@(.*[/\\])colors[/\\]"
  package.loaded.parhelion = assert(loadfile(root .. "lua/parhelion/init.lua"))()
end

package.loaded.parhelion.load()
