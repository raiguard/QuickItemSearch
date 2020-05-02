local util = require("__core__.lualib.util")

local string = string

function util.sprite_to_item_name(sprite_name)
  return string.gsub(sprite_name, "item/", "")
end

-- util.textfield = {}

-- -- clamps numeric textfields to between two values, and sets the textfield style if it is invalid
-- function util.textfield.clamp_number_input(element, clamps, last_value)
--   local text = element.text
--   if text == ""
--   or (clamps[1] and tonumber(text) < clamps[1])
--   or (clamps[2] and tonumber(text) > clamps[2]) then
--     element.style = "ee_invalid_value_textfield"
--   else
--     element.style = "textfield"
--     last_value = text
--   end
--   return last_value
-- end

-- -- sets the numeric textfield to the last valid value and resets the style
-- function util.textfield.set_last_valid_value(element, last_value)
--   if element.text ~= last_value then
--     element.text = last_value
--     element.style = "textfield"
--   end
--   return element.text
-- end

return util