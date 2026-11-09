if not package.loaded.parhelion then
  local root = debug.getinfo(1, "S").source:match "^@(.*[/\\])colors[/\\]"
  ---@module "parhelion"
  local parhelion = assert(loadfile(root .. "lua/parhelion/init.lua"))()
  package.loaded.parhelion = parhelion
end

package.loaded.parhelion.load()
