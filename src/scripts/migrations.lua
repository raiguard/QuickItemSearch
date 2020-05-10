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
  end
}