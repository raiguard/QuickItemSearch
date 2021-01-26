local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")

local constants = require("constants")

local request_gui = {}

function request_gui.build(player, player_table)
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
        on_click = {gui = "request", action = "close"}
      }
    },
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "request", action = "close"}
      },
      children = {
        {
          type = "flow",
          ref = {"titlebar_flow"},
          actions = {
            on_click = {gui = "request", action = "recenter"}
          },
          children = {
            {type = "label", style = "frame_title", caption = {"qis-gui.set-request"}, ignored_by_interaction = true},
            {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
            {
              type = "sprite-button",
              style = "frame_action_button",
              sprite = "utility/close_white",
              hovered_sprite = "utility/close_black",
              clicked_sprite = "utility/close_black",
              actions = {
                on_click = {gui = "request", action = "close"}
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
                style = "slider_value_textfield",
                numeric = true,
                clear_and_focus_on_right_click = true,
                text = "0",
                ref = {"logistic_setter", "min", "textfield"},
                actions = {
                  on_confirmed = {gui = "request", action = "confirm"},
                  on_text_changed = {
                    gui = "search",
                    action = "update_logistic_request",
                    elem = "textfield",
                    bound = "min"
                  }
                }
              },
              {type = "flow", direction = "vertical", children = {
                {
                  type = "slider",
                  style = "notched_slider",
                  style_mods = {horizontally_stretchable = true},
                  minimum_value = 0,
                  maximum_value = 500,
                  value_step = 50,
                  value = 0,
                  discrete_slider = true,
                  discrete_values = true,
                  ref = {"logistic_setter", "max", "slider"},
                  actions = {
                    on_value_changed = {
                      gui = "search",
                      action = "update_logistic_request",
                      elem = "slider",
                      bound = "max"
                    }
                  }
                },
                {
                  type = "slider",
                  style = "notched_slider",
                  style_mods = {horizontally_stretchable = true},
                  minimum_value = 0,
                  maximum_value = 500,
                  value_step = 50,
                  value = 500,
                  discrete_slider = true,
                  discrete_values = true,
                  ref = {"logistic_setter", "min", "slider"},
                  actions = {
                    on_value_changed = {
                      gui = "search",
                      action = "update_logistic_request",
                      elem = "slider",
                      bound = "min"
                    }
                  }
                }
              }},
              {
                type = "textfield",
                style = "slider_value_textfield",
                numeric = true,
                clear_and_focus_on_right_click = true,
                text = constants.infinity_rep,
                ref = {"logistic_setter", "max", "textfield"},
                actions = {
                  on_confirmed = {gui = "request", action = "confirm"},
                  on_text_changed = {
                    gui = "search",
                    action = "update_logistic_request",
                    elem = "textfield",
                    bound = "max"
                  }
                }
              },
              {
                type = "sprite-button",
                style = "item_and_count_select_confirm",
                sprite = "utility/check_mark",
                tooltip = {"qis-gui.set-request"},
                ref = {"logistic_setter", "set_request_button"}
              },
              {
                type = "sprite-button",
                style = "flib_tool_button_light_green",
                style_mods = {top_margin = 1},
                sprite = "qis_temporary_request",
                tooltip = {"qis-gui.set-temporary-request"},
                ref = {"logistic_setter", "set_temporary_request_button"}
              }
            }
          }
        }}
      }
    }
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player_table.guis.request = {
    refs = refs,
    state = {
      item_data = nil,
      visible = false
    }
  }
end

function request_gui.destroy(player_table)
  player_table.guis.request.refs.window.destroy()
  player_table.guis.request = nil
end

function request_gui.open(player, player_table, item_data)
  local gui_data = player_table.guis.request
  local refs = gui_data.refs
  local state = gui_data.state

  state.visible = true

  refs.item_label.caption = "[item="..item_data.name.."]  "..item_data.translation

  -- update logistic setter
  local request = item_data.request or {min = 0, max = math.max_uint}
  local stack_size = game.item_prototypes[item_data.name].stack_size
  local logistic_setter = refs.logistic_setter
  for _, type in ipairs{"min", "max"} do
    local elems = logistic_setter[type]
    local count = request[type]
    elems.textfield.enabled = true
    if count == math.max_uint then
      elems.textfield.text = constants.infinity_rep
    else
      elems.textfield.text = tostring(count)
    end
    elems.slider.enabled = true
    elems.slider.set_slider_minimum_maximum(0, stack_size * 10)
    elems.slider.set_slider_value_step(stack_size)
    elems.slider.slider_value = math.round(count / stack_size) * stack_size
  end
  refs.logistic_setter.min.textfield.select_all()
  refs.logistic_setter.min.textfield.focus()

  -- update window
  refs.focus_frame.visible = true
  refs.focus_frame.bring_to_front()
  refs.window.visible = true
  refs.window.bring_to_front()

  -- set opened
  player.opened = refs.window
end

function request_gui.close(player, player_table)
  local gui_data = player_table.guis.request
  gui_data.state.visible = false
  gui_data.refs.focus_frame.visible = false
  gui_data.refs.window.visible = false
  if not player.opened then
    player.opened = player_table.guis.search.refs.window
  end
end

function request_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.request
  local refs = gui_data.refs
  local state = gui_data.state

  if msg.action == "close" then
    request_gui.close(player, player_table)
  elseif msg.action == "bring_to_front" then
    refs.window.bring_to_front()
  end
end

function request_gui.update_focus_frame_size(player, player_table)
  local gui_data = player_table.guis.request
  if gui_data then
    local resolution = player.display_resolution
    local scale = player.display_scale
    local size = {resolution.width / scale, resolution.height / scale}
    gui_data.refs.focus_frame.style.size = size
  end
end

return request_gui
