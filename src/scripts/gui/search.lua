local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")

local constants = require("constants")
local cursor = require("scripts.cursor")
local search = require("scripts.search")

local function perform_search(player, player_table, state, refs)
  local query = state.query
  local results_table = refs.results_table
  local children = results_table.children

  if #query > 1 then
    local i = 0
    local results, connected_to_network = search.run(player, player_table, query)
    for _, row in ipairs(results) do
      i = i + 1
      local i3 = i * 3
      if not results_table.children[i3 + 1] then
        results_table.add{
          type = "label",
          style = "qis_clickable_label",
          tags = {
            [script.mod_name] = {
              flib = {
                on_click = "handle_item_click"
              }
            }
          }
        }
        for _ = 1, 2 do
          results_table.add{type = "label"}
        end
        -- update our copy of the table
        children = results_table.children
      end
      -- item label
      local item_label = children[i3 + 1]
      local hidden_abbrev = row.hidden and "[font=default-semibold](H)[/font]  " or ""
      item_label.caption = hidden_abbrev.."[item="..row.name.."]  "..row.translation
      -- item counts
      if player.controller_type == defines.controllers.character and connected_to_network then
        children[i3 + 2].caption = (row.inventory or 0).." / [color=128, 206, 240]"..(row.logistic or 0).."[/color]"
      else
        children[i3 + 2].caption = (row.inventory or 0)
      end
      -- request / infinity filter
      local request_label = children[i3 + 3]
      if player.controller_type == defines.controllers.editor then
        request_label.caption = row.infinity_filter or "--"
      else
        local request = row.request or {min = 0}
        local max = request.max or "inf"
        if max == math.max_uint then
          max = "inf"
        end
        request_label.caption = request.min.." / "..max
        request_label.style.font_color = constants.colors[row.request_color or "normal"]
      end
    end
    for j = #results_table.children, ((i + 1) * 3) + 1, -1 do
      results_table.children[j].destroy()
    end
  elseif #results_table.children > 3 then
    -- clear results
    results_table.clear()
    -- add new dummy elements
    for _ = 1, 3 do
      results_table.add{type = "empty-widget"}
    end
    results_table.children[1].style.horizontally_stretchable = true
  end
end

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
        {
          type = "flow",
          ref = {"titlebar_flow"},
          actions = {
            on_click = "recenter"
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
                on_click = "close"
              }
            }
          }
        },
        {
          type = "frame",
          style = "inside_shallow_frame_with_padding",
          style_mods = {top_padding = 9},
          direction = "vertical",
          children = {
            {
              type = "textfield",
              style_mods = {width = 400},
              ref = {"search_textfield"},
              actions = {
                on_confirmed = "enter_result_selection",
                on_text_changed = "update_search_query"
              }
            },
            {type = "frame", style = "deep_frame_in_shallow_frame", style_mods = {top_margin = 10}, children = {
              {type = "scroll-pane", style = "qis_list_box_scroll_pane", style_mods = {height = 28 * 10}, children = {
                {type = "table", style = "qis_list_box_table", column_count = 3, ref = {"results_table"}, children = {
                  -- dummy elements for the borked first row
                  -- the first column needs to be stretchy
                  {type = "empty-widget", style_mods = {horizontally_stretchable = true}},
                  {type = "empty-widget"},
                  {type = "empty-widget"}
                }},
              }}
            }}
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
      mode = "search",
      query = "",
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

  -- TODO: set state to search
  gui_data.refs.search_textfield.focus()
  gui_data.refs.search_textfield.select_all()

  -- update the table right away
  perform_search(player, player_table, gui_data.state, gui_data.refs)
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
  elseif msg == "recenter" and e.button == defines.mouse_button_type.middle then
    refs.window.force_auto_center()
  elseif msg == "update_search_query" then
    local query = e.text
    for pattern, replacement in pairs(constants.input_sanitizers) do
      query = string.gsub(query, pattern, replacement)
    end
    state.query = query
    perform_search(player, player_table, state, refs)
  elseif msg == "perform_search" then
    -- perform search without updating query
    perform_search(player, player_table, state, refs)
  elseif msg == "enter_result_selection" then
  elseif msg == "handle_item_click" then
    local _, _, item = string.find(e.element.caption, "^.-%[item=(.-)%]  .*$")
    if not e.shift and not e.control then
      cursor.set_stack(player, player.cursor_stack, player_table, item)
    end
  end
end

return search_gui
