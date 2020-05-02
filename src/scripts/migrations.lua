local gui = require("__flib__.control.gui")
local translation = require("__flib__.control.translation")

return {
  ["1.5.0"] = function()
    gui.init()
    translation.init()
    global.__lualib = nil

    -- TODO migrate temporary requests
    -- for i, player_table in pairs(global.players) do
    --   player_table.flags.has
    -- end
  end
}