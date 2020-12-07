local util = require("__core__.lualib.util")

local string = string

function util.sprite_to_item_name(sprite_name)
  return string.gsub(sprite_name, "item/", "")
end

-- because Lua doesn't have a math.round...
-- from http://lua-users.org/wiki/SimpleRound
function util.round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

return util