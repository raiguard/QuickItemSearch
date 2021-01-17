if __DebugAdapter then
  __DebugAdapter.defineGlobal("REGISTER_ON_TICK")
end

local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local migration = require("__flib__.migration")
local translation = require("__flib__.translation")

local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local request = require("scripts.request")

local search_gui = require("scripts.gui.search")

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  translation.init()

  global_data.init()
  global_data.build_strings()

  for i in pairs(game.players) do
    player_data.init(i)
    player_data.refresh(game.get_player(i), global.players[i])
  end
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- reset running translations
    translation.init()

    global_data.build_strings()

    for i, player_table in pairs(global.players) do
      player_data.refresh(game.get_player(i), player_table)
    end
  end
end)

-- CUSTOM INPUT

event.register("qis-search", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player_table.flags.can_open_gui then
    search_gui.toggle(player, player_table)
  end

  -- DEBUG
  request.set(player, player_table, "transport-belt", {min = 10, max = 20})
end)

event.register({"qis-nav-up", "qis-nav-down"}, function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.can_open_gui then
    local gui_data = player_table.guis.search
    if gui_data.state.visible then
      local offset = string.find(e.input_name, "down") and 1 or -1
      search_gui.handle_action({player_index = e.player_index}, {action = "update_selected_index", offset = offset})
    end
  end
end)

-- ENTITY

event.on_entity_logistic_slot_changed(function(e)
  local entity = e.entity
  if entity and entity.valid and entity.type == "character" then
    local player = entity.player -- event does not provide player_index every time
    local player_table = global.players[player.index]
    request.update(player, player_table, e.slot_index)
  end
end)

-- GUI

gui.hook_events(function(e)
  local msg = gui.read_action(e)
  if msg then
    if msg.gui == "search" then
      search_gui.handle_action(e, msg)
    end
  end
end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)
  player_data.refresh(game.get_player(e.player_index), global.players[e.player_index])
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    player_data.start_translations(e.player_index)
  end
end)

event.on_player_left_game(function(e)
  local player_table = global.players[e.player_index]
  if translation.is_translating(e.player_index) then
    translation.cancel(e.player_index)
    player_table.flags.translate_on_join = true
  end
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if string.sub(e.setting, 1, 4) == "qis-" and e.setting_type == "runtime-per-user" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_data.update_settings(player, player_table)
  end
end)

-- SHORTCUT

event.on_lua_shortcut(function(e)
  if e.prototype_name == "qis-search" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    if player_table.flags.can_open_gui then
      search_gui.toggle(player, player_table)
    end
  end
end)

-- TICK
-- TODO: update the search results on inventory changed, player moved, or every two seconds

local function on_tick(e)
  if translation.translating_players_count() > 0 then
    translation.iterate_batch(e)
  else
    event.on_tick(nil)
  end
end

REGISTER_ON_TICK = function()
  if translation.translating_players_count() > 0 then
    event.on_tick(on_tick)
  end
end

-- TRANSLATIONS

event.on_string_translated(function(e)
  local names, finished = translation.process_result(e)
  if names then
    local player_table = global.players[e.player_index]
    local translations = player_table.translations
    local internal_names = names.items
    for i = 1, #internal_names do
      local internal_name = internal_names[i]
      translations[internal_name] = e.translated and e.result or internal_name
    end
  end
  if finished then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    -- show message if needed
    if player_table.flags.show_message_after_translation then
      player.print{'qis-message.can-open-gui'}
    end
    -- update flags
    player_table.flags.can_open_gui = true
    player_table.flags.translate_on_join = false
    player_table.flags.show_message_after_translation = false
    -- create GUI
    search_gui.build(player, player_table)
    -- enable shortcut
    player.set_shortcut_available("qis-search", true)
  end
end)
