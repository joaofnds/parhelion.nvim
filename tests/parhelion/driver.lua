---@alias driver.Value string|number|boolean|table|userdata|nil

---@alias driver.GroupColors table<string, table<string, string>>

---@alias driver.Unpacker fun(chunk: string, pos: integer): unknown[]?, integer

---@class driver.Response
---@field err driver.Value
---@field result driver.Value

---@class driver.Colors
---@field fg string
---@field bg string
---@field sp string

---@class driver.Attr: table<string, integer|boolean|string>
---@field foreground? integer
---@field background? integer
---@field special? integer

---@class driver.HlItem
---@field id integer
---@field kind string
---@field hi_name? string

---@class driver.GridCell
---@field [1] string
---@field [2] integer

---@class driver.LineCell
---@field [1] string
---@field [2]? integer
---@field [3]? integer

---@class driver.DrawnWith
---@field kind string
---@field name? string
---@field bg? string

---@class driver.Style
---@field fg string
---@field bg string
---@field sp? string
---@field flags string

---@class driver.Cell: driver.Style
---@field text string
---@field drawn_with driver.DrawnWith[]

---@class driver.DrawnCell
---@field text string
---@field fg string
---@field bg string
---@field flags string

---@class driver.Position
---@field row integer
---@field col integer

---@class driver.Shot
---@field rows driver.Cell[][]
---@field defaults driver.Colors
---@field cursor driver.Position
---@field groups? driver.GroupColors
---@field view? string
---@field mode? string

---@class driver.SpawnOptions
---@field args string[]
---@field rows integer
---@field cols integer
---@field cwd? string
---@field env? table<string, string>

---@class driver.SettleOptions
---@field timeout? integer
---@field quiet? integer
---@field until_lua? string

---@class driver.Nvim
---@field responses table<integer, driver.Response>
---@field next_id integer
---@field grid table<integer, table<integer, driver.GridCell>>
---@field attrs table<integer, driver.Attr>
---@field items table<integer, driver.HlItem[]>
---@field rows integer
---@field cols integer
---@field cursor driver.Position
---@field last_change integer
---@field unpacker driver.Unpacker
---@field errors string[]
---@field stdin uv.uv_pipe_t
---@field stdout uv.uv_pipe_t
---@field stderr uv.uv_pipe_t
---@field handle uv.uv_process_t
---@field exited? boolean
---@field defaults driver.Colors
local Nvim = {}
Nvim.__index = Nvim

---@param n integer
---@return string
local function hex(n) return string.format("#%06x", n) end

---@param overrides? table<string, string>
---@return string[]
local function environment(overrides)
  ---@type table<string, string>
  local merged = vim.tbl_extend("force", vim.fn.environ(), overrides or {})
  local list = {}
  for k, v in pairs(merged) do
    table.insert(list, k .. "=" .. v)
  end
  return list
end

---@param opts driver.SpawnOptions
---@return driver.Nvim
function Nvim.spawn(opts)
  ---@type driver.Unpacker
  local unpacker = vim.mpack.Unpacker()
  ---@type driver.Nvim
  local self = setmetatable({
    responses = {},
    next_id = 1,
    grid = {},
    attrs = {},
    items = {},
    rows = opts.rows,
    cols = opts.cols,
    cursor = { row = 0, col = 0 },
    last_change = vim.uv.now(),
    unpacker = unpacker,
    errors = {},
  }, Nvim)

  self.stdin, self.stdout, self.stderr = assert(vim.uv.new_pipe()), assert(vim.uv.new_pipe()), assert(vim.uv.new_pipe())
  local args = vim.list_extend({ "--embed" }, opts.args)
  local handle, failure = vim.uv.spawn("nvim", {
    args = args,
    env = environment(opts.env),
    cwd = opts.cwd,
    stdio = { self.stdin, self.stdout, self.stderr },
  }, function() self.exited = true end)
  if not handle then
    for _, pipe in ipairs { self.stdin, self.stdout, self.stderr } do
      pipe:close()
    end
    error(failure, 0)
  end

  self.handle = handle

  self.stdout:read_start(function(err, chunk)
    assert(not err, err)
    if chunk then self:receive(chunk) end
  end)
  self.stderr:read_start(function(_, chunk)
    if chunk then table.insert(self.errors, chunk) end
  end)

  local started, err = xpcall(function()
    self:request("nvim_ui_attach", self.cols, self.rows, { rgb = true, ext_linegrid = true, ext_hlstate = true })
    self:wait_for_startup()
  end, debug.traceback)
  if not started then
    self:close()
    error(err, 0)
  end

  return self
end

---@param chunk string
function Nvim:receive(chunk)
  local pos = 1
  while pos <= #chunk do
    local message
    message, pos = self.unpacker(chunk, pos)
    if message ~= nil then self:dispatch(message) end
  end
end

---@param message unknown[]
function Nvim:dispatch(message)
  if message[1] == 1 then
    self.responses[message[2]] = { err = message[3], result = message[4] }
  elseif message[1] == 2 and message[2] == "redraw" then
    ---@type unknown[][]
    local batches = message[3]
    for _, batch in ipairs(batches) do
      ---@type fun(self: driver.Nvim, ...: unknown)?
      local handler = self["on_" .. batch[1]]
      if handler then
        for i = 2, #batch do
          handler(self, unpack(batch[i]))
        end
      end
    end
  end
end

---@param fg integer
---@param bg integer
---@param sp integer
function Nvim:on_default_colors_set(fg, bg, sp) self.defaults = { fg = hex(fg), bg = hex(bg), sp = hex(sp) } end

---@param id integer
---@param rgb driver.Attr
---@param info driver.HlItem[]
function Nvim:on_hl_attr_define(id, rgb, _, info)
  self.attrs[id] = rgb
  self.items[id] = info
end

---@param width integer
---@param height integer
function Nvim:on_grid_resize(_, width, height)
  self.cols, self.rows = width, height
  self:on_grid_clear()
end

function Nvim:on_grid_clear()
  self.last_change = vim.uv.now()
  for row = 0, self.rows - 1 do
    self.grid[row] = {}
    for col = 0, self.cols - 1 do
      self.grid[row][col] = { " ", 0 }
    end
  end
end

---@param row integer
---@param col integer
---@param cells driver.LineCell[]
function Nvim:on_grid_line(_, row, col, cells)
  local hl_id = 0
  for _, cell in ipairs(cells) do
    hl_id = cell[2] or hl_id
    for _ = 1, cell[3] or 1 do
      local current = self.grid[row][col]
      if current[1] ~= cell[1] or current[2] ~= hl_id then
        self.grid[row][col] = { cell[1], hl_id }
        self.last_change = vim.uv.now()
      end
      col = col + 1
    end
  end
end

---@param row integer
---@param col integer
function Nvim:on_grid_cursor_goto(_, row, col) self.cursor = { row = row, col = col } end

---@param top integer
---@param bot integer
---@param left integer
---@param right integer
---@param rows integer
function Nvim:on_grid_scroll(_, top, bot, left, right, rows)
  self.last_change = vim.uv.now()
  local from, to, step = top, bot - 1, 1
  if rows < 0 then
    from, to, step = bot - 1, top, -1
  end
  for row = from, to, step do
    local source = row + rows
    if source >= top and source < bot then
      for col = left, right - 1 do
        self.grid[row][col] = self.grid[source][col]
      end
    end
  end
end

---@param condition fun(): boolean?
---@param timeout integer
---@param what string
local function wait_until(condition, timeout, what)
  local ok = vim.wait(timeout, condition, 5)
  assert(ok, "timed out waiting for " .. what)
end

---@param method string
---@param ... unknown
---@return unknown
function Nvim:request(method, ...)
  local id = self.next_id
  self.next_id = id + 1
  self.stdin:write(vim.mpack.encode { 0, id, method, { ... } })

  wait_until(function() return self.responses[id] ~= nil or self.exited end, 30000, method)
  local response = assert(self.responses[id], "nvim exited during " .. method .. ": " .. table.concat(self.errors))
  self.responses[id] = nil
  assert(response.err == vim.NIL or response.err == nil, vim.inspect(response.err))
  return response.result
end

---@param code string
---@param ... unknown
---@return unknown
function Nvim:lua(code, ...) return self:request("nvim_exec_lua", code, { ... }) end

-- Quiet means the screen stopped changing. Flushes are no measure of that, because lualine refreshes
-- every second and each refresh flushes with nothing to draw.
---@param opts driver.SettleOptions
function Nvim:settle(opts)
  local deadline = vim.uv.now() + (opts.timeout or 20000)
  while true do
    vim.wait(20)
    local quiet = vim.uv.now() - self.last_change >= (opts.quiet or 400)
    if quiet and (not opts.until_lua or self:lua(opts.until_lua) == true) then return end
    if vim.uv.now() >= deadline then
      error(
        string.format(
          "view did not settle: %s\nlast change %d ms ago, %s",
          opts.until_lua or "",
          vim.uv.now() - self.last_change,
          self:lua [[return vim.inspect({
            filetype = vim.bo.filetype,
            lines = vim.api.nvim_buf_line_count(0),
            mode = vim.api.nvim_get_mode(),
            windows = vim.tbl_map(function(w) return vim.bo[vim.api.nvim_win_get_buf(w)].filetype end, vim.api.nvim_list_wins()),
            messages = vim.api.nvim_exec2("messages", { output = true }).output,
          }, { newline = " ", indent = "" })]]
        ),
        0
      )
    end
  end
end

-- A start that draws nothing for longer than a quiet window would otherwise count as quiet, and a command sent then
-- runs before what plugins defer to after startup, such as lazy.nvim's commands.
function Nvim:wait_for_startup()
  self:settle { quiet = 0, until_lua = "return vim.v.vim_did_enter == 1" }
  self.last_change = vim.uv.now()
end

---@param nvim driver.Nvim
---@param id integer
---@return driver.DrawnWith[]
local function drawn_with(nvim, id)
  return vim
    .iter(nvim.items[id] or {})
    :map(
      ---@param item driver.HlItem
      ---@return driver.DrawnWith
      function(item)
        local own = nvim.attrs[item.id] or {}
        return { kind = item.kind, name = item.hi_name, bg = own.background and hex(own.background) }
      end
    )
    :totable()
end

---@param attr driver.Attr
---@param defaults driver.Colors
---@return driver.Style
local function style_of(attr, defaults)
  local fg = attr.foreground and hex(attr.foreground) or defaults.fg
  local bg = attr.background and hex(attr.background) or defaults.bg
  local sp = attr.special and hex(attr.special) or nil
  local flags = {}
  ---@type table<string, integer|boolean|string>
  local attributes = attr
  for key, value in pairs(attributes) do
    if key ~= "foreground" and key ~= "background" and key ~= "special" and value and value ~= 0 then
      table.insert(flags, value == true and key or (key .. "=" .. tostring(value)))
    end
  end
  table.sort(flags)
  return { fg = fg, bg = bg, sp = sp, flags = table.concat(flags, ",") }
end

---@return driver.Shot
function Nvim:capture()
  self:request("nvim_command", "redraw!")
  self:settle { quiet = 150 }

  ---@type driver.Cell[][]
  local rows = {}
  for row = 0, self.rows - 1 do
    rows[row + 1] = {}
    for col = 0, self.cols - 1 do
      local cell = self.grid[row][col]
      local style = style_of(self.attrs[cell[2]] or {}, self.defaults)
      rows[row + 1][col + 1] = {
        text = cell[1],
        fg = style.fg,
        bg = style.bg,
        sp = style.sp,
        flags = style.flags,
        drawn_with = drawn_with(self, cell[2]),
      }
    end
  end
  return { rows = rows, defaults = self.defaults, cursor = { row = self.cursor.row + 1, col = self.cursor.col + 1 } }
end

-- Unlike capture, it forces no redraw, so it shows what Neovim chose to draw.
---@param row integer
---@return driver.DrawnCell[]
function Nvim:drawn_row(row)
  local cells = {}
  for col = 0, self.cols - 1 do
    local cell = self.grid[row - 1][col]
    local style = style_of(self.attrs[cell[2]] or {}, self.defaults)
    table.insert(cells, { text = cell[1], fg = style.fg, bg = style.bg, flags = style.flags })
  end

  return cells
end

function Nvim:close()
  if not self.exited then pcall(function() self.stdin:write(vim.mpack.encode { 2, "nvim_command", { "qa!" } }) end) end
  vim.wait(2000, function() return self.exited end, 10)
  if not self.exited then self.handle:kill "sigkill" end

  for _, handle in ipairs { self.stdin, self.stdout, self.stderr, self.handle } do
    if not handle:is_closing() then handle:close() end
  end
end

return Nvim
