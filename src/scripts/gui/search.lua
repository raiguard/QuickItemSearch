local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")

local constants = require("constants")
local cursor = require("scripts.cursor")
local search = require("scripts.search")

local request_gui = require("scripts.gui.request")

local function perform_search(player, player_table, state, refs)
  local query = state.query
  local results_table = refs.results_table
  local children = results_table.children

  -- deselect highlighted entry
  if #results_table.children > 3 then
    results_table.children[state.selected_index * 3 + 1].style.font_color = constants.colors.normal
    refs.results_scroll_pane.scroll_to_top()
  end
  -- reset selected index
  state.selected_index = 1

  if #state.raw_query > 1 then
    local i = 0
    local results, connected_to_network = search.run(player, player_table, query)
    for _, row in ipairs(results) do
      i = i + 1
      local i3 = i * 3

      -- build row if nonexistent
      if not results_table.children[i3 + 1] then
        gui.build(results_table, {
          {
            type = "label",
            style = "qis_clickable_item_label",
            actions = {
              on_click = {gui = "search", action = "select_item", index = i}
            }
          },
          {type = "label"},
          {type = "label", style = "qis_clickable_label"}
        })
        -- update our copy of the table
        children = results_table.children
      end

      -- item label
      local item_label = children[i3 + 1]
      local hidden_abbrev = row.hidden and "[font=default-semibold](H)[/font]  " or ""
      item_label.caption = hidden_abbrev.."[item="..row.name.."]  "..row.translation
      -- item counts
      if player.controller_type == defines.controllers.character and connected_to_network then
        children[i3 + 2].caption = (
          (row.inventory or 0)
          .." / [color="
          ..constants.colors.logistic_str
          .."]"
          ..(row.logistic or 0)
          .."[/color]"
        )
      else
        children[i3 + 2].caption = (row.inventory or 0)
      end
      -- request / infinity filter
      local request_label = children[i3 + 3]
      if player.controller_type == defines.controllers.editor then
        request_label.caption = row.infinity_filter or "--"
      else
        local request = row.request
        if request then
          local max = request.max
          if max == math.max_uint then
            max = constants.infinity_rep
          end
          request_label.caption = request.min.." / "..max
          request_label.style.font_color = constants.colors[row.request_color or "normal"]
        else
          request_label.caption = "--"
        end
      end
    end
    -- destroy extraneous rows
    for j = #results_table.children, ((i + 1) * 3) + 1, -1 do
      results_table.children[j].destroy()
    end
    -- show or hide warning
    if player.controller_type == defines.controllers.character and not connected_to_network then
      refs.warning_subheader.visible = true
    else
      refs.warning_subheader.visible = false
    end
    -- add to state
    state.results = results
    state.connected_to_network = connected_to_network -- TODO: will go unused?
  -- clear table if it has contents
  elseif #results_table.children > 3 then
    -- clear results
    results_table.clear()
    state.results = {}
    -- add new dummy elements
    for _ = 1, 3 do
      results_table.add{type = "empty-widget"}
    end
  end
end

local search_gui = {}

function search_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      style = "qis_window_dimmer",
      style_mods = {size = {448, 390}},
      visible = false,
      ref = {"window_dimmer"}
    },
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "search", action = "close"},
        on_location_changed = {gui = "search", action = "update_dimmer_location"}
      },
      children = {
        {
          type = "flow",
          ref = {"titlebar_flow"},
          actions = {
            on_click = {gui = "search", action = "recenter"}
          },
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = {"mod-name.QuickItemSearch"},
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
                on_click = {gui = "search", action = "close"}
              }
            }
          }
        },
        {
          type = "frame",
          style = "inside_shallow_frame_with_padding",
          style_mods = {top_padding = -2},
          direction = "vertical",
          children = {
            -- dummy input action textfield
            {
              type = "textfield",
              style = "qis_disablable_textfield",
              style_mods = {width = 1, height = 1},
              numeric = true,
              ref = {"input_action_textfield"},
              actions = {
                on_confirmed = {gui = "search", action = "select_item"}
              }
            },
            {
              type = "textfield",
              style = "qis_disablable_textfield",
              style_mods = {width = 400, top_margin = 9},
              clear_and_focus_on_right_click = true,
              lose_focus_on_confirm = true,
              ref = {"search_textfield"},
              actions = {
                on_confirmed = {gui = "search", action = "enter_result_selection"},
                on_text_changed = {gui = "search", action = "update_search_query"}
              }
            },
            {
              type = "frame",
              style = "deep_frame_in_shallow_frame",
              style_mods = {top_margin = 10, height = 28 * 10},
              direction = "vertical",
              children = {
                {
                  type = "frame",
                  style = "negative_subheader_frame",
                  style_mods = {left_padding = 12, height = 28, horizontally_stretchable = true},
                  visible = false,
                  ref = {"warning_subheader"},
                  children = {
                    {
                      type = "label",
                      style = "bold_label",
                      caption = {"qis-gui.not-connected-to-logistic-network"}
                    }
                  }
                },
                {
                  type = "scroll-pane",
                  style = "qis_list_box_scroll_pane",
                  style_mods = {vertically_stretchable = true, bottom_padding = 2},
                  ref = {"results_scroll_pane"},
                  children = {
                    {
                      type = "table",
                      style = "qis_list_box_table",
                      column_count = 3,
                      ref = {"results_table"},
                      children = {
                        -- dummy elements for the borked first row
                        {type = "empty-widget"},
                        {type = "empty-widget"},
                        {type = "empty-widget"}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  })

  refs.window.force_auto_center()
  refs.titlebar_flow.drag_target = refs.window

  player_table.guis.search = {
    refs = refs,
    state = {
      query = "",
      raw_query = "",
      selected_index = 1,
      subwindow_open = true,
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

  gui_data.refs.search_textfield.focus()
  gui_data.refs.search_textfield.select_all()

  -- update the table right away
  perform_search(player, player_table, gui_data.state, gui_data.refs)
end

function search_gui.close(player, player_table)
  local gui_data = player_table.guis.search
  if not gui_data.state.subwindow_open then
    gui_data.refs.window.visible = false
    gui_data.state.visible = false
    player.set_shortcut_toggled("qis-search", false)
    if player.opened == gui_data.refs.window then
      player.opened = nil
    end
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

function search_gui.reopen_after_subwindow(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.search

  if gui_data then
    local refs = gui_data.refs
    local state = gui_data.state

    refs.input_action_textfield.enabled = true
    refs.search_textfield.enabled = true
    refs.window_dimmer.visible = false
    refs.input_action_textfield.focus()
    state.subwindow_open = false

    perform_search(player, player_table, state, refs)

    player.opened = gui_data.refs.window
  end
end

function search_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.search
  local refs = gui_data.refs
  local state = gui_data.state

  if msg.action == "close" then
    search_gui.close(player, player_table)
  elseif msg.action == "recenter" and e.button == defines.mouse_button_type.middle then
    refs.window.force_auto_center()
  elseif msg.action == "update_search_query" then
    local query = e.text
    -- fuzzy search
    if player_table.settings.fuzzy_search then
      query = string.gsub(query, ".", "%1.*")
    end
    -- input sanitization
    for pattern, replacement in pairs(constants.input_sanitizers) do
      query = string.gsub(query, pattern, replacement)
    end
    state.query = query
    state.raw_query = e.text
    perform_search(player, player_table, state, refs)
  elseif msg.action == "perform_search" then
    -- perform search without updating query
    perform_search(player, player_table, state, refs)
  elseif msg.action == "enter_result_selection" then
    if #refs.results_table.children == 3 then
      refs.search_textfield.focus()
      return
    end
    if state.selected_index > ((#refs.results_table.children - 3) / 3) then
      state.selected_index = 1
    end
    local results_table = refs.results_table
    results_table.children[state.selected_index * 3 + 1].style.font_color = constants.colors.hovered
    refs.input_action_textfield.focus()
  elseif msg.action == "update_selected_index" then
    local results_table = refs.results_table
    local selected_index = state.selected_index
    results_table.children[selected_index * 3 + 1].style.font_color = constants.colors.normal
    local new_selected_index = math.clamp(selected_index + msg.offset, 1, #results_table.children / 3 - 1)
    state.selected_index = new_selected_index
    results_table.children[new_selected_index * 3 + 1].style.font_color = constants.colors.hovered
    refs.results_scroll_pane.scroll_to_element(results_table.children[new_selected_index * 3 + 1], "top-third")
    -- in case it was defocused at some point
    refs.input_action_textfield.focus()
  elseif msg.action == "select_item" then
    local i = msg.index or state.selected_index
    local result = state.results[i]
    if result then -- TODO: always true?
      if e.shift then
        state.subwindow_open = true
        refs.input_action_textfield.enabled = false
        refs.search_textfield.enabled = false
        refs.window_dimmer.visible = true
        refs.window_dimmer.bring_to_front()
        request_gui.open(player, player_table, result)
      elseif e.control then

      else
        cursor.set_stack(player, player.cursor_stack, player_table, result.name)
      end
    end
  elseif msg.action == "update_dimmer_location" then
    refs.window_dimmer.location = refs.window.location
  end
end

return search_gui
