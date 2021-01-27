local math = require("__flib__.math")
local table = require("__flib__.table")

local search = require("scripts.search")

local request = {}

function request.set(player, player_table, name, counts, is_temporary)
  local requests = player_table.requests
  local request_data = requests.by_name[name]
  local request_index
  if request_data then
    request_index = request_data.index
  else
    request_data = {min = 0, max = math.max_uint}
    -- search for first empty slot
    local i = 1
    while true do
      local existing_request = player.get_personal_logistic_slot(i)
      if existing_request.name then
        i = i + 1
      else
        request_index = i
        break
      end
    end
  end

  -- save previous request if this one is temporary
  if is_temporary then
    requests.temporary[name] = table.deep_copy(request_data)
  else
    -- delete temporary request for this item if there is one
    requests.temporary[name] = nil
  end

  -- set on player
  -- this will create or update the data in the requests table automatically
  player.set_personal_logistic_slot(request_index, {
    name = name,
    min = counts.min,
    max = counts.max
  })
end

function request.update(player, player_table, slot_index)
  local requests = player_table.requests
  local existing_request = player.get_personal_logistic_slot(slot_index)
  if existing_request then
    local request_data = requests.by_index[slot_index]
    if request_data then
      if request_data.name == existing_request.name then
        -- update counts
        request_data.min = existing_request.min
        request_data.max = existing_request.max
      else
        requests.by_name[request_data.name] = nil
        if existing_request.name then
          existing_request.index = slot_index
          requests.by_index[slot_index] = existing_request
          requests.by_name[existing_request.name] = existing_request
        else
          -- delete this request's data entirely
          requests.by_index[slot_index] = nil
        end
      end
    elseif existing_request.name then
      existing_request.index = slot_index
      requests.by_index[slot_index] = existing_request
      requests.by_name[existing_request.name] = existing_request
    end
  end
end

function request.refresh(player, player_table)
  local requests = {
    by_index = {},
    by_name = {},
    temporary = {}
  }
  local character = player.character
  if character then
    for i = 1, character.request_slot_count do
      local filter = player.get_personal_logistic_slot(i)
      if filter and filter.name then
        filter.index = i
        requests.by_index[i] = filter
        requests.by_name[filter.name] = filter
      end
    end
  end
  -- TODO: check temporary requests for validity
  player_table.requests = requests
end

function request.update_temporaries(player, player_table)
  local requests = player_table.requests
  local temporary_requests = requests.temporary
  -- TODO: deduplicate this from updating the search results
  local combined_contents, has_main_inventory = search.get_combined_inventory_contents(player)
  if has_main_inventory then
    for name, old_request_data in pairs(temporary_requests) do
      local existing_request_data = requests.by_name[name]
      local has_count = combined_contents[name] or 0
      -- if the request has been satisfied
      if has_count >= existing_request_data.min and has_count <= existing_request_data.max then
        -- clear the temporary request data first to avoid setting the slot twice
        temporary_requests[name] = nil
        -- set the former request
        player.set_personal_logistic_slot(existing_request_data.index, old_request_data)
      end
    end
  end
end

return request
