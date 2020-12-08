local gui = require("__flib__.gui-beta")

local search_gui = {}

function search_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {on_closed = "close"},
      children = {
        {type = "textfield", style = "qis_search_textfield"},
        {type = "frame", style = "inside_shallow_frame", direction = "vertical", children = {
          {type = "frame", style = "deep_frame_in_shallow_frame", style_mods = {margin = 12}, children = {
            {type = "scroll-pane", style = "qis_results_scroll_pane"}
          }}
        }
      }
    }}
  })

  refs.window.force_auto_center()

  player_table.guis.search = {
    refs = refs,
    state = {
      visible = false
    }
  }
end

function search_gui.destroy(player_table)
  player_table.guis.search.refs.window.destroy()
  player_table.guis.search = nil
end

function search_gui.open(player, player_table)
  local gui_data = player_table.guis.search
  gui_data.refs.window.visible = true
  gui_data.state.visible = true
  player.set_shortcut_toggled("qis-search", true)
  player.opened = gui_data.refs.window
end

function search_gui.close(player, player_table)
  local gui_data = player_table.guis.search
  gui_data.refs.window.visible = false
  gui_data.state.visible = false
  player.set_shortcut_toggled("qis-search", false)
  if player.opened == gui_data.refs.window then
    player.opened = nil
  end
end

function search_gui.toggle(player, player_table)
  local gui_data = player_table.guis.search
  if gui_data.state.visible then
    search_gui.close(player, player_table)
  else
    search_gui.open(player, player_table)
  end
end

function search_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.search
  local refs = gui_data.refs
  local state = gui_data.state

  if msg == "close" then
    search_gui.close(player, player_table)
  end
end

return search_gui