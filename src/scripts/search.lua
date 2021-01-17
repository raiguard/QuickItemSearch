local constants = require("constants")

local search = {}

function search.run(player, player_table, query)
  local requests_by_name = player_table.requests.by_name
  local settings = player_table.settings
  local translations = player_table.translations

  local item_prototypes = game.item_prototypes
  local character = player.character

  -- settings
  local show_hidden = settings.show_hidden

  local connected_to_network = false
  local i = 0
  local lookup = {}
  local results = {}

  local main_inventory = player.get_main_inventory()
  -- don't bother doing anything if they don't have an inventory
  if main_inventory and main_inventory.valid then
    local inventory_contents = main_inventory.get_contents()

    -- get outbound and inbound items
    local logistic_network
    local deliveries = {
      inbound = {},
      outbound = {}
    }
    if character and character.valid then
      for _, data in ipairs(constants.logistic_point_data) do
        local point = character.get_logistic_point(data.logistic_point)
        if point and point.valid then
          deliveries[data.deliveries_table] = point[data.source_table]
          if data.point_name == "requester" then
            logistic_network = point.logistic_network
          end
        end
      end
    end

    local function match(name, type, count)
      local translation = translations[name]
      if translation and string.find(string.lower(translation), query) then
        local hidden = item_prototypes[name].has_flag("hidden")
        if show_hidden or not hidden then
          local result = lookup[name]
          if result then
            -- increment count
            result[type] = (result[type] or 0) + count
          else
            -- increment counter and create result
            i = i + 1
            result = {name = name, translation = translation, [type] = count, hidden = hidden}

            -- add logistic request, if one exists
            local request = requests_by_name[name]
            if request then
              result.request = {min = request.min, max = request.max}
            end
            -- determine logistic request color
            local color
            if deliveries.inbound[name] then
              color = "inbound"
            elseif deliveries.outbound[name] then
              color = "outbound"
            elseif request and (inventory_contents[name] or 0) < request.min then
              color = "unsatisfied"
            else
              color = "normal"
            end
            result.request_color = color

            -- add references
            results[i] = result
            lookup[name] = result
          end
        end
      end
    end

    -- iterate inventory contents
    for name, count in pairs(inventory_contents) do
      match(name, "inventory", count)
      if i > constants.results_limit then goto limit end
    end

    -- iterate logistic network contents
    if logistic_network then
      -- iterate logistic network contents
      if logistic_network and logistic_network.valid then
        connected_to_network = true
        for name, count in pairs(logistic_network.get_contents()) do
          -- add to results
          match(name, "logistic", count)
          if i > constants.results_limit then goto limit end
        end
      end
    end

    -- iterate all other items
    for name in pairs(translations) do
      if not lookup[name] then
        -- "unavailable" is a dummy type - it won't be set because `count` is `nil`
        match(name, "unavailable")
        if i > constants.results_limit then goto limit end
      end
    end

    ::limit::

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

return search
