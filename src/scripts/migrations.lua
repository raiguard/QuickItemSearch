local gui = require("__flib__.gui")
local mod_gui = require("__core__.lualib.mod-gui")
local translation = require("__flib__.translation")

local player_data = require("scripts.player-data")

local function check_for_and_destroy_gui(parent)
  if parent.qis_window then
    parent.qis_window.destroy()
  end
end

return {
  ["1.5.0"] = function()
    gui.init()
    translation.init()
    global.__lualib = nil

    for i, player in pairs(game.players) do
      -- destroy any open GUIs
      check_for_and_destroy_gui(mod_gui.get_frame_flow(player))
      check_for_and_destroy_gui(player.gui.screen)

      -- completely reset player data
      player_data.init(i, true)
    end
  end,
  ["1.5.6"] = function()
    -- the last version would set this to true for absolutely everyone, so unset it for absolutely everyone
    for _, player_table in pairs(global.players) do
      player_table.flags.show_message_after_translation = false
      player_table.flags.translate_on_join = false
    end
  end
}