local table = require("__flib__.table")

local infinity_filter = {}

function infinity_filter.set(player, player_table, filter, is_temporary)
  local infinity_filters = player_table.infinity_filters
  local filter_data = infinity_filters.by_name[filter.name]
  local filter_index
  if filter_data then
    filter_index = filter_data.index
  else
    filter_index = #infinity_filters.by_index + 1
  end

  -- save previous request if this one is temporary
  if is_temporary then
    -- set to `false` if it needs to be cleared
    infinity_filters.temporary[filter.name] = filter_data and table.deep_copy(filter_data) or false
  else
    -- delete temporary request for this item if there is one
    infinity_filters.temporary[filter.name] = nil
  end

  -- set on player
  player.set_infinity_inventory_filter(
    filter_index,
    {name = filter.name, mode = filter.mode, count = filter.count, index = filter_index}
  )

  -- update stored requests
  infinity_filter.refresh(player, player_table, true)
end

function infinity_filter.clear(player, player_table, name)
  local infinity_filters = player_table.infinity_filters
  local filter_data = infinity_filters.by_name[name]
  if filter_data then
    player.set_infinity_inventory_filter(filter_data.index, nil)
    infinity_filter.refresh(player, player_table)
  end
end

function infinity_filter.refresh(player, player_table, preserve_temporaries)
  local infinity_filters = {
    by_index = {},
    by_name = {},
    temporary = preserve_temporaries and player_table.infinity_filters.temporary or {}
  }
  for i, existing_filter in pairs(player.infinity_inventory_filters) do
    infinity_filters.by_index[i] = existing_filter
    infinity_filters.by_name[existing_filter.name] = existing_filter
  end
  -- TODO: check temporary requests for validity
  player_table.infinity_filters = infinity_filters
end

function infinity_filter.update_temporaries(player, player_table)
  local infinity_filters = player_table.infinity_filters
  local temporary_filters = infinity_filters.temporary
  local main_inventory = player.get_main_inventory()
  if main_inventory and main_inventory.valid then
    for name, old_filter_data in pairs(temporary_filters) do
      local existing_filter_data = infinity_filters.by_name[name]
      -- infinity filters are guaranteed to be fulfilled, so we can safely remove temporaries immediately
      player.set_infinity_inventory_filter(existing_filter_data.index, old_filter_data or nil)
    end
  end
end

return infinity_filter
