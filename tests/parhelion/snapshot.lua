local function hex(n) return n and string.format("#%06x", n) or nil end

local function resolve(name)
	local seen, current = {}, name
	while true do
		local hl = vim.api.nvim_get_hl(0, { name = current })
		if not hl.link then return hl end
		assert(not seen[current], "link cycle at " .. current)
		seen[current] = true
		current = hl.link
	end
end

local function resolved_group(name)
	local out = {}
	for key, value in pairs(resolve(name)) do
		if key == "fg" or key == "bg" or key == "sp" then
			out[key] = hex(value)
		elseif key ~= "default" then
			out[key] = value
		end
	end
	return out
end

local groups, links = {}, {}
for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
	groups[name] = resolved_group(name)
	links[name] = hl.link
end

local terminal = {}
for i = 0, 15 do
	local color = vim.g["terminal_color_" .. i]
	terminal[tostring(i)] = color and color:lower() or vim.NIL
end

return vim.json.encode { background = vim.o.background, groups = groups, links = links, terminal = terminal }
