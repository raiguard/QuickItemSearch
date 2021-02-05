local gui = require("__flib__.gui-beta")

local crafting_gui = {}

function crafting_gui.build(player, player_table)
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
        on_click = {gui = "crafting", action = "close", reopen_after_subwindow = true}
      }
    },
    {
      type = "frame",
      name = "qis_crafting_window",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "crafting", action = "close", reopen_after_subwindow = true}
      },
      children = {
        {
          type = "flow",
          style = "flib_titlebar_flow",
          ref = {"titlebar_flow"},
          actions = {
            on_click = {gui = "crafting", action = "recenter"}
          },
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = {"gui.crafting"},
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
                on_click = {gui = "crafting", action = "close", reopen_after_subwindow = true}
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
            children = {
              {
                type = "textfield",
                numeric = true,
                ref = {"textfield"},
                actions = {
                  on_text_changed = {gui = "crafting", action = "update_count"}
                }
              }
            }
          }
        }}
      }
    }
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player_table.guis.crafting = {
    refs = refs,
    state = {
      item_data = nil,
      visible = false
    }
  }
end

function crafting_gui.destroy(player_table)
  player_table.guis.crafting.refs.window.destroy()
  player_table.guis.crafting = nil
end

function crafting_gui.open(player, player_table, item_data)
  local gui_data = player_table.guis.crafting
  local refs = gui_data.refs
  local state = gui_data.state

  -- update window
  refs.focus_frame.visible = true
  refs.focus_frame.bring_to_front()
  refs.window.visible = true
  refs.window.bring_to_front()

  -- info bar
  refs.item_label.caption = "[item="..item_data.name.."]  "..item_data.translation

  -- set opened
  player.opened = refs.window
end

function crafting_gui.close(player, player_table)
  local gui_data = player_table.guis.crafting
  gui_data.state.visible = false
  gui_data.refs.focus_frame.visible = false
  gui_data.refs.window.visible = false
  if not player.opened then
    player.opened = player_table.guis.search.refs.window
  end
end

function crafting_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.infinity_filter
  local refs = gui_data.refs
  local state = gui_data.state

  if msg.action == "close" then
    crafting_gui.close(player, player_table)
  end
end

return crafting_gui
