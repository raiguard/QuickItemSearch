local constants = require("constants")

return function(player, player_table, query)
  local requests_by_name = player_table.requests.by_name
  local settings = player_table.settings
  local translations = player_table.translations

  local item_prototypes = game.item_prototypes
  local character = player.character

  -- settings
  local show_hidden = settings.show_hidden

  local connected_to_network = false
  local lookup = {}
  local results = {}

  local main_inventory = player.get_main_inventory()
  -- don't bother doing anything if they don't have an inventory
  if main_inventory and main_inventory.valid then
    -- get contents of all player inventories and cursor stack
    local inventory_contents = main_inventory.get_contents()
    local cursor_stack = player.cursor_stack
    if cursor_stack and cursor_stack.valid_for_read then
      inventory_contents[cursor_stack.name] = (inventory_contents[cursor_stack.name] or 0) + cursor_stack.count
    end
    for _, inventory_def in ipairs{
      defines.inventory.character_ammo,
      defines.inventory.character_guns
    } do
      local inventory = player.get_inventory(inventory_def)
      if inventory and inventory.valid then
        for name, count in pairs(inventory.get_contents() or {}) do
          inventory_contents[name] = (inventory_contents[name] or 0) + count
        end
      end
    end

    local contents = {
      inbound = {},
      inventory = inventory_contents,
      logistic = {},
      outbound = {}
    }

    -- get logistic network and related contents
    if character and character.valid then
      for _, data in ipairs(constants.logistic_point_data) do
        local point = character.get_logistic_point(data.logistic_point)
        if point and point.valid then
          contents[data.deliveries_table] = point[data.source_table]
          if data.point_name == "requester" then
            local logistic_network = point.logistic_network
            if logistic_network.valid then
              connected_to_network = true
              contents.logistic = logistic_network.get_contents()
            end
          end
        end
      end
    end

    -- perform search
    local i = 0
    for name, translation in pairs(translations) do
      if string.find(string.lower(translation), query) then
        local hidden = item_prototypes[name].has_flag("hidden")
        if show_hidden or not hidden then
          local inventory_count = contents.inventory[name]
          local logistic_count = contents.logistic[name]
          local result = {
            hidden = hidden,
            inventory = inventory_count,
            logistic = logistic_count and math.max(logistic_count, 0) or nil,
            name = name,
            translation = translation,
          }
          -- add logistic request, if one exists
          local request = requests_by_name[name]
          if request then
            result.request = {min = request.min, max = request.max}
          end
          -- determine logistic request color
          local color
          if contents.inbound[name] then
            color = "inbound"
          elseif contents.outbound[name] then
            color = "outbound"
          elseif request and (inventory_count or 0) < request.min then
            color = "unsatisfied"
          else
            color = "normal"
          end
          result.request_color = color

          i = i + 1
          results[i] = result
          lookup[name] = result
        end
      end
      if i > constants.results_limit then break end
    end

    -- if in editor, iterate infinity filters
    if player.controller_type == defines.controllers.editor then
      for _, filter in ipairs(player.infinity_inventory_filters) do
        local result = lookup[filter.name]
        if result then
          result.infinity_filter = constants.infinity_filter_mode_to_symbol[filter.mode].." "..filter.count
        end
      end
    end
  end

  return results, connected_to_network
end
