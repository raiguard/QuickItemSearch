local constants = require("constants")

local search = {}

function search.run(player, player_table, query)
  local translations = player_table.translations
  local settings = player_table.settings

  local item_prototypes = game.item_prototypes
  local character = player.character

  local get_slot = player.get_personal_logistic_slot

  -- settings
  local show_hidden = settings.show_hidden

  -- TODO: limit search result count
  local connected_to_network = false
  local i = 0
  local lookup = {}
  local results = {}

  local function match(name, type, count)
    local translation = translations[name]
    if translation and string.find(string.lower(translation), query) then
      local hidden = item_prototypes[name].has_flag("hidden")
      if show_hidden or not hidden then
        local existing_index = lookup[name]
        if existing_index then
          local result = results[existing_index]
          result[type] = (result[type] or 0) + count
        else
          i = i + 1
          results[i] = {name = name, translation = translation, [type] = count, hidden = hidden}
          lookup[name] = i
        end
      end
    end
  end

  local main_inventory = player.get_main_inventory()
  -- don't bother doing anything if they don't have an inventory
  if main_inventory and main_inventory.valid then
    -- iterate inventory contents
    local inventory_contents = main_inventory.get_contents()
    for name, count in pairs(inventory_contents) do
      match(name, "inventory", count)
    end

    -- iterate logistic network contents
    local point
    if character then
      point = character.get_logistic_point(defines.logistic_member_index.character_requester)
      if point and point.valid then
        -- iterate logistic network contents
        local network = point.logistic_network
        if network and network.valid then
          connected_to_network = true
          for name, count in pairs(network.get_contents()) do
            match(name, "logistic", count)
          end
        end
      end
    end

    -- iterate all other items
    for name in pairs(translations) do
      if not lookup[name] then
        -- "unavailable" is a dummy type - it won't be set because `count` is `nil`
        match(name, "unavailable")
      end
    end

    if character and point and point.valid then
      -- iterate item requests
      local filters = point.filters
      if filters then
        for _, filter_src in ipairs(filters) do
          -- the `filters` table only includes the minimum counts, so we must get the actual request from the character
          local filter = get_slot(filter_src.index)
          if filter and filter.name then
            local name = filter.name
            local existing_index = lookup[name]
            if existing_index then
              local result = results[existing_index]
              result.request = {min = filter.min, max = filter.max}
              local color
              if point.targeted_items_deliver[name] then
                color = "on_the_way"
              elseif (inventory_contents[name] or 0) < filter.min then
                color = "unsatisfied"
              else
                color = "normal"
              end
              result.request_color = color
            end
          end
        end
      end
      -- iterate items being picked up
      local provider_point = character.get_logistic_point(defines.logistic_member_index.character_provider)
      if provider_point and provider_point.valid then
        for name in pairs(provider_point.targeted_items_pickup) do
          local existing_index = lookup[name]
          if existing_index then
            results[existing_index].request_color = "emptying"
          end
        end
      end
    elseif player.controller_type == defines.controllers.editor then
      -- if in editor, iterate infinity filters
      for _, filter in ipairs(player.infinity_inventory_filters) do
        local existing_index = lookup[filter.name]
        if existing_index then
          results[existing_index].infinity_filter = (
            constants.infinity_filter_mode_to_symbol[filter.mode].." "..filter.count
          )
        end
      end
    end
  end

  return results, connected_to_network
end

return search
