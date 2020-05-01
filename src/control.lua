local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")
local migration = require("__flib__.control.migration")
local translation = require("__flib__.control.translation")

local constants = require("scripts.constants")
local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local qis_gui = require("scripts.gui")

local string_gsub = string.gsub
local string_sub = string.sub

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("QuickItemSearch", " [parameter]\nrefresh-player-data - retranslate dictionaries and update settings",
  function(e)
    if e.parameter == "refresh-player-data" then
      player_data.refresh(game.get_player(e.player_index), global.players[e.player_index])
    end
  end
)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  gui.init()
  translation.init()

  global_data.init()
  for i in pairs(game.players) do
    player_data.init(i)
  end

  gui.build_lookup_tables()
end)

event.on_load(function()
  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- update translation data
    global_data.build_prototypes()
    -- refresh all player information
    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

-- GUI

gui.register_handlers()

event.register("qis-search", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player_table.flags.can_open_gui then
    qis_gui.create(player, player_table)
  else
    player.print{"qis-message.cannot-open-gui"}
    player_table.flags.show_message_after_translation = true
  end
end)

event.register(constants.nav_arrow_events, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui
  if gui_data and gui_data.state == "select_result" then
    qis_gui.move_selection(player_table, constants.nav_offsets[string_gsub(e.input_name, "qis%-nav%-", "")])
  end
end)

event.register(constants.nav_confirm_events, function(e)
  local gui_data = global.players[e.player_index].gui
  if gui_data and gui_data.state == "select_result" then
    qis_gui.confirm_selection(e.player_index, gui_data, e.input_name)
  end
end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    player_data.start_translations(e.player_index)
  end
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if string_sub(e.setting, 1, 4) == "qis-" then
    player_data.update_settings(game.get_player(e.player_index), global.players[e.player_index])
  end
end)

-- TICK
-- TODO register this conditionally

event.on_tick(function()
  if global.__flib.translation.active_translations_count > 0 then
    translation.translate_batch()
  end
end)

-- TRANSLATIONS

event.on_string_translated(function(e)
  translation.sort_string(e)
end)

translation.on_finished(function(e)
  -- add translations to player table
  local player_table = global.players[e.player_index]
  player_table.translations = e.translations
  -- show message if needed
  if player_table.flags.show_message_after_translation then
    game.get_player(e.player_index).print{'qis-message.can-open-gui'}
  end
  -- update flags
  player_table.flags.can_open_gui = true
  player_table.flags.translate_on_join = false
  player_table.flags.show_message_after_translation = false
end)