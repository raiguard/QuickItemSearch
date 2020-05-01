local util = require("__core__.lualib.util")

local string = string

function util.sprite_to_item_name(sprite_name)
  return string.gsub(sprite_name, "item/", "")
end

return util