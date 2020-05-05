local event = require("__flib__.control.event")
local gui = require("__flib__.control.gui")
local migration = require("__flib__.control.migration")
local translation = require("__flib__.control.translation")

local constants = require("scripts.constants")
local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local on_tick_manager = require("scripts.on-tick-manager")
local player_data = require("scripts.player-data")
local qis_gui = require("scripts.gui.qis")

local string = string

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("QuickItemSearch", " [parameter]\nrefresh-player-data - retranslate dictionaries and update settings",
  function(e)
    if e.parameter == "refresh-player-data" then
      local player = game.get_player(e.player_index)
      local player_table = global.players[e.player_index]
      if player_table.gui then
        qis_gui.destroy(player, player_table)
      end
      player_data.refresh(player, player_table)
    end
  end
)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- on_tick handler is kept in scripts.on-tick-manager

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
  on_tick_manager.update()
  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- update translation data
    global_data.build_prototypes()
    -- refresh all player information
    for i, player in pairs(game.players) do
      local player_table = global.players[i]
      if player_table.gui then
        qis_gui.destroy(player, player_table)
      end
      player_data.refresh(player, player_table)
    end
  end
end)

-- GUI

gui.register_handlers()

event.register(constants.nav_arrow_events, function(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui
  if gui_data then
    if gui_data.state == "select_result" then
      qis_gui.move_result(player_table, constants.results_nav_offsets[string.gsub(e.input_name, "qis%-nav%-", "")])
    elseif gui_data.state == "select_request_type" then
      qis_gui.move_request_type(player_table)
    end
  end
end)

event.register(constants.nav_confirm_events, function(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.gui
  if gui_data then
    if gui_data.state == "select_result" then
      qis_gui.confirm_result(e.player_index, gui_data, e.input_name)
    elseif gui_data.state == "select_request_type" then
      qis_gui.confirm_request_type(e.player_index, player_table)
    end
  end
end)

event.register("qis-search", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if not player.opened then
    qis_gui.toggle(player, player_table)
  end
end)

event.on_lua_shortcut(function(e)
  if e.prototype_name == "qis-search" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    qis_gui.toggle(player, player_table)
  end
end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)
end)

event.on_player_joined_game(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.translate_on_join then
    player_table.flags.translate_on_join = false
    player_data.start_translations(e.player_index)
  end
end)

event.on_player_main_inventory_changed(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player.controller_type == defines.controllers.character and player_table.flags.has_temporary_requests then
    player_data.check_temporary_requests(player, player_table)
  end
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.register("qis-quick-trash-all", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  player_data.quick_trash_all(player, player_table)
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if string.sub(e.setting, 1, 4) == "qis-" then
    player_data.update_settings(game.get_player(e.player_index), global.players[e.player_index])
  end
end)

-- TRANSLATIONS

event.on_string_translated(function(e)
  local names, finished = translation.process_result(e)
  if e.translated and names then
    local player_table = global.players[e.player_index]
    local translations = player_table.translations
    local internal_names = names.items
    for i=1,#internal_names do
      translations[internal_names[i]] = e.result
    end
  end
  if finished then
    -- add translations to player table
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
    -- enable shortcut
    player.set_shortcut_available("qis-search", true)
    -- update on_tick
    on_tick_manager.update()
  end
end)