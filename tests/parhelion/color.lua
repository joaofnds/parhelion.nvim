local M = {}

local srgb_to_xyz = {
  { 0.4124564, 0.3575761, 0.1804375 },
  { 0.2126729, 0.7151522, 0.0721750 },
  { 0.0193339, 0.1191920, 0.9503041 },
}
local xyz_to_lms = {
  { 0.8189330101, 0.3618667424, -0.1288597137 },
  { 0.0329845436, 0.9293118715, 0.0361456387 },
  { 0.0482003018, 0.2643662691, 0.6338517070 },
}
local lms_to_perceptual_lab = {
  { 0.2104542553, 0.7936177850, -0.0040720468 },
  { 1.9779984951, -2.4285922050, 0.4505937099 },
  { 0.0259040371, 0.7827717662, -0.8086757660 },
}
local d65 = { 0.95047, 1.0, 1.08883 }

local function times(matrix, vector)
  local product = {}
  for row = 1, 3 do
    product[row] = matrix[row][1] * vector[1] + matrix[row][2] * vector[2] + matrix[row][3] * vector[3]
  end

  return product
end

local function channels(color)
  return {
    tonumber(color:sub(2, 3), 16) / 255,
    tonumber(color:sub(4, 5), 16) / 255,
    tonumber(color:sub(6, 7), 16) / 255,
  }
end

local function decoded(channel, threshold)
  if channel <= threshold then return channel / 12.92 end
  return ((channel + 0.055) / 1.055) ^ 2.4
end

function M.mix(first, second, share)
  local a, b = channels(first), channels(second)
  local function step(index) return math.floor(255 * (a[index] + (b[index] - a[index]) * share) + 0.5) end

  return string.format("#%02x%02x%02x", step(1), step(2), step(3))
end

local function xyz(color)
  local linear = vim.tbl_map(function(channel) return decoded(channel, 0.04045) end, channels(color))
  return times(srgb_to_xyz, linear)
end

local function relative_luminance(color)
  local rgb = vim.tbl_map(function(channel) return decoded(channel, 0.03928) end, channels(color))
  return 0.2126 * rgb[1] + 0.7152 * rgb[2] + 0.0722 * rgb[3]
end

function M.contrast_ratio(a, b)
  local lighter, darker = relative_luminance(a), relative_luminance(b)
  if darker > lighter then
    lighter, darker = darker, lighter
  end

  return (lighter + 0.05) / (darker + 0.05)
end

local function screen_luminance(color)
  local rgb = channels(color)
  local y = 0.2126729 * rgb[1] ^ 2.4 + 0.7151522 * rgb[2] ^ 2.4 + 0.0721750 * rgb[3] ^ 2.4
  if y > 0.022 then return y end

  return y + (0.022 - y) ^ 1.414
end

function M.lightness_contrast(text, background)
  local t, b = screen_luminance(text), screen_luminance(background)
  if math.abs(b - t) < 0.0005 then return 0 end

  if b > t then
    local contrast = (b ^ 0.56 - t ^ 0.57) * 1.14
    return contrast < 0.1 and 0 or (contrast - 0.027) * 100
  end

  local contrast = (b ^ 0.65 - t ^ 0.62) * 1.14
  return contrast > -0.1 and 0 or (contrast + 0.027) * 100
end

function M.lab(color)
  local function f(t)
    if t > 216 / 24389 then return t ^ (1 / 3) end
    return (24389 / 27 * t + 16) / 116
  end

  local x = xyz(color)
  local fx, fy, fz = f(x[1] / d65[1]), f(x[2] / d65[2]), f(x[3] / d65[3])
  return { 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz) }
end

local function cube_root(value)
  if value < 0 then return -((-value) ^ (1 / 3)) end
  return value ^ (1 / 3)
end

function M.perceptual_lab_from_xyz(sample)
  return times(lms_to_perceptual_lab, vim.tbl_map(cube_root, times(xyz_to_lms, sample)))
end

function M.perceptual_lch(color)
  local lab = M.perceptual_lab_from_xyz(xyz(color))
  return {
    lightness = lab[1],
    chroma = math.sqrt(lab[2] ^ 2 + lab[3] ^ 2),
    hue = math.deg(math.atan2(lab[3], lab[2])) % 360,
  }
end

local function signed(degrees) return degrees > 180 and degrees - 360 or degrees end

function M.signed_hue(color) return signed(M.perceptual_lch(color).hue) end

function M.hue_shift(from, to) return signed((M.perceptual_lch(to).hue - M.perceptual_lch(from).hue) % 360) end

local function hue_of(b, a)
  if a == 0 and b == 0 then return 0 end
  return math.deg(math.atan2(b, a)) % 360
end

function M.color_difference_of_labs(first, second)
  local l1, a1, b1 = first[1], first[2], first[3]
  local l2, a2, b2 = second[1], second[2], second[3]

  local mean_chroma = (math.sqrt(a1 ^ 2 + b1 ^ 2) + math.sqrt(a2 ^ 2 + b2 ^ 2)) / 2
  local g = 0.5 * (1 - math.sqrt(mean_chroma ^ 7 / (mean_chroma ^ 7 + 25 ^ 7)))
  local a1p, a2p = (1 + g) * a1, (1 + g) * a2
  local c1, c2 = math.sqrt(a1p ^ 2 + b1 ^ 2), math.sqrt(a2p ^ 2 + b2 ^ 2)
  local h1, h2 = hue_of(b1, a1p), hue_of(b2, a2p)
  local neutral = c1 * c2 == 0

  local hue_difference = 0
  if not neutral then
    hue_difference = h2 - h1
    if hue_difference > 180 then
      hue_difference = hue_difference - 360
    elseif hue_difference < -180 then
      hue_difference = hue_difference + 360
    end
  end

  local mean_hue = h1 + h2
  if not neutral then
    if math.abs(h1 - h2) <= 180 then
      mean_hue = (h1 + h2) / 2
    elseif h1 + h2 < 360 then
      mean_hue = (h1 + h2 + 360) / 2
    else
      mean_hue = (h1 + h2 - 360) / 2
    end
  end

  local function cosine(degrees) return math.cos(math.rad(degrees)) end

  local t = 1
    - 0.17 * cosine(mean_hue - 30)
    + 0.24 * cosine(2 * mean_hue)
    + 0.32 * cosine(3 * mean_hue + 6)
    - 0.20 * cosine(4 * mean_hue - 63)
  local mean_l, mean_c = (l1 + l2) / 2, (c1 + c2) / 2
  local sl = 1 + 0.015 * (mean_l - 50) ^ 2 / math.sqrt(20 + (mean_l - 50) ^ 2)
  local sc = 1 + 0.045 * mean_c
  local sh = 1 + 0.015 * mean_c * t
  local rotation = -math.sin(math.rad(60 * math.exp(-(((mean_hue - 275) / 25) ^ 2))))
    * 2
    * math.sqrt(mean_c ^ 7 / (mean_c ^ 7 + 25 ^ 7))

  local dl = (l2 - l1) / sl
  local dc = (c2 - c1) / sc
  local dh = 2 * math.sqrt(c1 * c2) * math.sin(math.rad(hue_difference / 2)) / sh

  return math.sqrt(dl ^ 2 + dc ^ 2 + dh ^ 2 + rotation * dc * dh)
end

function M.color_difference(a, b) return M.color_difference_of_labs(M.lab(a), M.lab(b)) end

local deficiency_matrices = {
  deuteranopia = {
    { 0.367322, 0.860646, -0.227968 },
    { 0.280085, 0.672501, 0.047413 },
    { -0.011820, 0.042940, 0.968881 },
  },
  protanopia = {
    { 0.152286, 1.052583, -0.204868 },
    { 0.114503, 0.786281, 0.099216 },
    { -0.003882, -0.048116, 1.051998 },
  },
}

local function encoded(channel)
  local clamped = math.max(0, math.min(1, channel))
  local value = clamped <= 0.0031308 and 12.92 * clamped or 1.055 * clamped ^ (1 / 2.4) - 0.055
  return math.floor(value * 255 + 0.5)
end

function M.simulated(color, deficiency)
  local linear = vim.tbl_map(function(channel) return decoded(channel, 0.04045) end, channels(color))
  local rgb = times(deficiency_matrices[deficiency], linear)
  return string.format("#%02x%02x%02x", encoded(rgb[1]), encoded(rgb[2]), encoded(rgb[3]))
end

return M
