local player_data = {}

local translation = require("__flib__.control.translation")

local string = string

function player_data.init(player_index)
  global.players[player_index] = {
    flags = {
      can_open_gui = false,
      translate_on_join = false,
      show_message_after_translation = false
    },
    gui = nil,
    translations = nil,
    settings = nil
  }
  player_data.refresh(game.get_player(player_index), global.players[player_index])
end

function player_data.update_settings(player, player_table)
  local settings = {}
  for name, t in pairs(player.mod_settings) do
    if string.sub(name, 1,4) == "qis-" then
      name = string.gsub(name, "qis%-", "")
      settings[string.gsub(name, "%-", "_")] = t.value
    end
  end
  player_table.settings = settings
end

function player_data.refresh(player, player_table)
  -- TODO: destroy GUI(s)
  -- set flag
  player_table.flags.can_open_gui = false

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
end

return player_data