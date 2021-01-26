local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")

local constants = require("constants")

local infinity_filter_gui = {}

function infinity_filter_gui.build(player, player_table)
  local resolution = player.display_resolution
  local scale = player.display_scale
  local focus_frame_size = {resolution.width / scale, resolution.height / scale}

  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      style = "invisible_frame",
      style_mods = {size = focus_frame_size},
      ref = {"focus_frame"},
      visible = false,
      actions = {
        on_click = {gui = "infinity_filter", action = "close"}
      }
    },
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "infinity_filter", action = "close"}
      },
      children = {
        {
          type = "flow",
          ref = {"titlebar_flow"},
          actions = {
            on_click = {gui = "infinity_filter", action = "recenter"}
          },
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = {"qis-gui.set-infinity-filter"},
              ignored_by_interaction = true
            },
            {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "utility/close_white",
              hovered_sprite = "utility/close_black",
              clicked_sprite = "utility/close_black",
              actions = {
                on_click = {gui = "infinity_filter", action = "close"}
              }
            }
          }
        },
        {type = "frame", style = "inside_shallow_frame", direction = "vertical", children = {
          {type = "frame", style = "subheader_frame", children = {
            {type = "label", style = "subheader_caption_label", ref = {"item_label"}},
            {type = "empty-widget", style = "flib_horizontal_pusher"}
          }},
          {
            type = "flow",
            style_mods = {vertical_align = "center", horizontal_spacing = 8, padding = 12},
          }
        }}
      }
    }
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player_table.guis.infinity_filter = {
    refs = refs,
    state = {
      item_data = nil,
      visible = false
    }
  }
end

function infinity_filter_gui.destroy(player_table)
  player_table.guis.infinity_filter.refs.window.destroy()
  player_table.guis.infinity_filter = nil
end

function infinity_filter_gui.open(player, player_table, item_data)
  local gui_data = player_table.guis.infinity_filter
  local refs = gui_data.refs
  local state = gui_data.state

  -- update state
  local stack_size = game.item_prototypes[item_data.name].stack_size
  item_data.stack_size = stack_size
  state.item_data = item_data
  local infinity_filter_data = item_data.infinity_filter or {mode = "at-least", count = 0}
  state.infinity_filter = infinity_filter_data
  state.visible = true

  -- update item label
  refs.item_label.caption = "[item="..item_data.name.."]  "..item_data.translation

  -- update filter setter
  local filter_setter = refs.filter_setter

  -- update window
  refs.focus_frame.visible = true
  refs.focus_frame.bring_to_front()
  refs.window.visible = true
  refs.window.bring_to_front()

  -- set opened
  player.opened = refs.window
end

function infinity_filter_gui.close(player, player_table)
  local gui_data = player_table.guis.infinity_filter
  gui_data.state.visible = false
  gui_data.refs.focus_frame.visible = false
  gui_data.refs.window.visible = false
  if not player.opened then
    player.opened = player_table.guis.search.refs.window
  end
end

function infinity_filter_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.request
  local refs = gui_data.refs
  local state = gui_data.state

  if msg.action == "close" then
    infinity_filter_gui.close(player, player_table)
  end
end

return infinity_filter_gui
