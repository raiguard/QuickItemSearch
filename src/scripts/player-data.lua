local translation = require("__flib__.translation")

local search_gui = require("scripts.gui.search")

local player_data = {}

function player_data.init(player_index)
  global.players[player_index] = {
    flags = {
      can_open_gui = false,
      show_message_after_translation = false,
      translate_on_join = false,
    },
    guis = {},
    settings = {}
  }
end

function player_data.refresh(player, player_table)
  -- destroy GUI
  if player_table.guis.search then
    search_gui.destroy(player_table)
  end

  -- set shortcut state
  player.set_shortcut_toggled("qis-search", false)
  player.set_shortcut_available("qis-search", false)

  -- update settings
  -- player_data.update_settings(player, player_table)

  -- run translations
  player_table.translations = {}
  if player.connected then
    player_data.start_translations(player.index)
  else
    player_table.flags.translate_on_join = true
  end
end

function player_data.start_translations(player_index)
  translation.add_requests(player_index, global.strings)
  REGISTER_ON_TICK()
end

return player_data
