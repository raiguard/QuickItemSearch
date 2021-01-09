local search = {}

function search.run(player, player_table, query)
  -- get the search settings
  local translations = player_table.translations
  local settings = player_table.settings

  local lookup = {}
  local results = {}
  local i = 0

  -- TODO: limit search result count

  local connected_to_network = false

  -- TODO: optimize
  local function match(name, type, count)
    local translation = translations[name]
    if translation and string.find(string.lower(translation), query) then
      local hidden = game.item_prototypes[name].has_flag("hidden")
      if settings.show_hidden or not hidden then
        if lookup[name] then
          results[lookup[name]][type] = (results[lookup[name]][type] or 0) + count
        else
          i = i + 1
          results[i] = {name = name, translation = translation, [type] = count, hidden = hidden}
          lookup[name] = i
        end
      end
    end
  end

  local main_inventory = player.get_main_inventory()
  if main_inventory and main_inventory.valid then
    for name, count in pairs(main_inventory.get_contents()) do
      match(name, "inventory", count)
    end
  end

  local point
  if player.character then
    point = player.character.get_logistic_point(defines.logistic_member_index.character_requester)
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

  for name in pairs(translations) do
    if not lookup[name] then
      -- "unavailable" is a dummy type - it won't be set because `count` is `nil`
      match(name, "unavailable")
    end
  end

  if player.character and point and point.valid then
    -- iterate item requests
    local filters = point.filters
    if filters then
      for _, filter_src in ipairs(filters) do
        -- the `filters` table only includes the minimum counts, so we must get the actual request from the character
        local filter = player.get_personal_logistic_slot(filter_src.index)
        if filter and filter.name then
          if lookup[filter.name] then
            results[lookup[filter.name]].request = {min = filter.min, max = filter.max}
          end
        end
      end
    end
  end

  return results, connected_to_network
end

return search
