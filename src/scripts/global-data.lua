local global_data = {}

local constants = require("scripts.constants")

function global_data.init()
  global.flags = {}
  global.players = {}

  global_data.build_prototypes()
end

function global_data.build_prototypes()
  local item_data = {}
  local translation_data = {}
  local utility_items = {}
  for name, prototype in pairs(game.item_prototypes) do
    local type = prototype.type
    if not constants.ignored_item_types[type] then
      local is_utility_item = (constants.utility_item_types[type] and not constants.utility_item_blacklist[name]) or constants.utility_item_whitelist[name]
      item_data[name] = {
        hidden = prototype.has_flag("hidden"),
        localised_name = prototype.localised_name,
        place_result = prototype.place_result or prototype.place_as_tile_result,
        stack_size = prototype.stack_size,
        is_utility_item = is_utility_item
      }
      translation_data[#translation_data+1] = {dictionary="items", localised=prototype.localised_name, internal=prototype.name}
      if is_utility_item then
        utility_items[#utility_items+1] = name
      end
    end
  end
  global.item_data = item_data
  global.translation_data = translation_data
  global.utility_items = utility_items
end

return global_data