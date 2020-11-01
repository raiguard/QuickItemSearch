local player_data = {}

local translation = require("__flib__.translation")

local on_tick = require("scripts.on-tick")

function player_data.init(player_index, skip_refresh)
  global.players[player_index] = {
    flags = {
      can_open_gui = false,
      has_temporary_requests = false,
      show_message_after_translation = false,
      translate_on_join = false
    },
    gui = nil,
    temporary_requests = {},
    translations = {},
    settings = nil
  }
  if not skip_refresh then
    player_data.refresh(game.get_player(player_index), global.players[player_index])
  end
end

function player_data.update_settings(player, player_table)
  local player_mod_settings = player.mod_settings
  local settings = {}
  settings.search_inventory = player_mod_settings["qis-search-inventory"].value
  settings.search_logistics = player_mod_settings["qis-search-logistics"].value
  settings.search_unavailable = player_mod_settings["qis-search-unavailable"].value
  settings.search_hidden = player_mod_settings["qis-search-hidden"].value
  settings.fuzzy_search = player_mod_settings["qis-fuzzy-search"].value
  settings.spawn_items_when_cheating = player_mod_settings["qis-spawn-items-when-cheating"].value

  local excludes = game.json_to_table(player_mod_settings["qis-quick-trash-all-excludes"].value)
  -- turn excludes list inside-out
  if excludes then
    for i=1,#excludes do
      local name = excludes[i]
      excludes[name] = true
      excludes[i] = nil
    end
  else
    player.print{"qis-message.invalid-quick-trash-all-excludes-format"}
    excludes = {}
  end
  settings.quick_trash_all_excludes = excludes

  player_table.settings = settings
end

function player_data.refresh(player, player_table)
  -- set flag
  player_table.flags.can_open_gui = false

  -- set shortcut state
  player.set_shortcut_toggled("qis-search", false)
  player.set_shortcut_available("qis-search", false)

  -- update settings
  player_data.update_settings(player, player_table)

  -- run translations
  player_table.translations = {}
  if player.connected then
    player_data.start_translations(player.index)
  else
    player_table.flags.translate_on_join = true
  end
end

function player_data.start_translations(player_index)
  translation.add_requests(player_index, global.translation_data)
  on_tick.update()
end

function player_data.find_request(player, item_name)
  local character = player.character
  local get_slot = character.get_personal_logistic_slot
  local request_data
  for i=1,character.character_logistic_slot_count do
    local slot = get_slot(i)
    if tostring(slot.name) == item_name then
      slot.index = i
      request_data = slot
      break
    end
  end
  return request_data
end

function player_data.set_request(player, player_table, request_data, temporary_request)
  local existing_request
  if request_data.index then
    -- correct slot index if it was changed
    existing_request = player.character.get_personal_logistic_slot(request_data.index)
    if tostring(existing_request.name) ~= request_data.name then
      existing_request = player_data.find_request(player, request_data.name)
      if existing_request then
        request_data.index = existing_request.index
      else
        -- find first empty slot
        existing_request = player_data.find_request(player, "nil")
        if existing_request then
          request_data.index = existing_request.index
        else
          player.print{"qis-message.no-available-logistic-request-slots"}
          return false
        end
      end
    end
  else
    -- find first empty slot
    existing_request = player_data.find_request(player, "nil")
    if existing_request then
      request_data.index = existing_request.index
    else
      player.print{"qis-message.no-available-logistic-request-slots"}
      return false
    end
  end

  player.character.clear_personal_logistic_slot(request_data.index)
  player.character.set_personal_logistic_slot(request_data.index, request_data)
  if temporary_request then
    player_table.flags.has_temporary_requests = true
    table.insert(player_table.temporary_requests, {temporary_request=request_data, previous_request=existing_request})
  end
  return true
end

function player_data.check_temporary_requests(player, player_table)
  -- get inventory contents
  local inventory_contents = player.get_main_inventory().get_contents()
  for _, inventory_type in ipairs{"character_guns", "character_ammo"} do
    for name, count in pairs(player.get_inventory(defines.inventory[inventory_type]).get_contents()) do
      inventory_contents[name] = count + (inventory_contents[name] or 0)
    end
  end
  local cursor_stack = player.cursor_stack
  if cursor_stack and cursor_stack.valid_for_read then
    inventory_contents[cursor_stack.name] = cursor_stack.count + (inventory_contents[cursor_stack.name] or 0)
  end

  -- check temporary requests
  local temporary_requests = player_table.temporary_requests
  local character = player.character
  local set_request = character.set_personal_logistic_slot
  local get_request = character.get_personal_logistic_slot
  local clear_request = character.clear_personal_logistic_slot
  local i = 1
  local next_request = temporary_requests[i]
  while next_request do
    local temporary_request = next_request.temporary_request
    local item_count = inventory_contents[temporary_request.name] or 0

    -- check if request still exists
    local remove_request = false
    local current_request = get_request(temporary_request.index)
    if tostring(current_request.name) == temporary_request.name then
      -- check if the conditions have changed
      if current_request.min ~= temporary_request.min or current_request.max ~= temporary_request.max then
        remove_request = true
      else
        -- check request fulfillment
        if item_count >= temporary_request.min and item_count <= temporary_request.max then
          local previous_request = next_request.previous_request
          clear_request(temporary_request.index)
          set_request(temporary_request.index, previous_request)
          remove_request = true
        end
      end
    else
      remove_request = true
    end
    if remove_request then
      table.remove(temporary_requests, i)
    else
      i = i + 1
    end
    next_request = temporary_requests[i]
  end

  if i == 1 then
    player_table.flags.has_temporary_requests = false
  end
end

function player_data.quick_trash(player, player_table, item_name)
  local request = player_data.find_request(player, item_name)
  if request then
    request.max = request.min
  else
    request = {name=item_name, min=0, max=0}
  end
  player_data.set_request(player, player_table, request, true)
end

-- TODO spread out over multiple ticks
function player_data.quick_trash_all(player, player_table)
  local contents = player.get_main_inventory().get_contents()
  local excludes = player_table.settings.quick_trash_all_excludes
  local item_data = global.item_data
  for name in pairs(contents) do
    if item_data[name] and not excludes[name] then
      player_data.quick_trash(player, player_table, name)
    end
  end
end

return player_data