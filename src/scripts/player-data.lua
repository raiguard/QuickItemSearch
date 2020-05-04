local player_data = {}

local translation = require("__flib__.control.translation")

local constants = require("scripts.constants")
local on_tick_manager = require("scripts.on-tick-manager")

local string = string

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
    translations = nil,
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
  player_table.translations = nil
  if player.connected then
    player_data.start_translations(player.index)
  else
    player_table.flags.translate_on_join = true
  end
end

function player_data.start_translations(player_index)
  translation.start(player_index, "items", global.translation_data, {include_failed_translations=true})
  on_tick_manager.update()
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

  player.character.set_personal_logistic_slot(request_data.index, request_data)
  if temporary_request then
    player_table.flags.has_temporary_requests = true
    table.insert(player_table.temporary_requests, {temporary_request=request_data, previous_request=existing_request})
  end
  return true
end

function player_data.check_temporary_requests(player, player_table)
  local inventory_contents = player.get_main_inventory().get_contents()
  local temporary_requests = player_table.temporary_requests
  local character = player.character
  local set_request = character.set_personal_logistic_slot
  local get_request = character.get_personal_logistic_slot
  local num_requests = 0
  for i, requests in ipairs(temporary_requests) do
    num_requests = num_requests + 1
    local temporary_request = requests.temporary_request
    local item_count = inventory_contents[temporary_request.name] or 0

    -- check if request still exists
    local remove_request = false
    local current_request = get_request(temporary_request.index)
    if tostring(current_request.name) == temporary_request.name then
      -- check request fulfillment
      if item_count >= temporary_request.min and item_count <= temporary_request.max then
        local previous_request = requests.previous_request
        set_request(temporary_request.index, previous_request)
        remove_request = true
      end
    else
      remove_request = true
    end
    if remove_request then
      table.remove(temporary_requests, i)
      num_requests = num_requests - 1
    end
  end

  if num_requests == 0 then
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