local request = {}

function request.set(player, player_table, name, counts, is_temporary)
  local requests = player_table.requests
  local request_data = requests.by_name[name]
  if not request_data then
    -- search for first empty slot
    local i = 1
    while not request_data do
      local filter = player.get_personal_logistic_slot(i)
      if filter.name then
        i = i + 1
      else
        -- create request data
        request_data = {index = i}
        requests.by_index[i] = request_data
        requests.by_name[name] = request_data
      end
    end
  end

  -- update properties
  request_data.name = name
  request_data.min = counts.min
  request_data.max = counts.max

  -- set on player
  player.set_personal_logistic_slot(request_data.index, request_data)

  -- TODO: temporary requests
end

function request.update(player, player_table, slot_index)
  local requests = player_table.requests
  local request = player.get_personal_logistic_slot(slot_index)
  if request then
    local request_data = requests.by_index[slot_index]
    if request_data then
      if request_data.name == request.name then
        -- update counts
        request_data.min = request.min
        request_data.max = request.max
      else
        requests.by_name[request_data.name] = nil
        if request.name then
          request.index = slot_index
          requests.by_index[slot_index] = request
          requests.by_name[request.name] = request
        else
          -- delete this request's data entirely
          requests.by_index[slot_index] = nil
        end
      end
    elseif request.name then
      request.index = slot_index
      requests.by_index[slot_index] = request
      requests.by_name[request.name] = request
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

return request
