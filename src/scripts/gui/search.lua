local gui = require("__flib__.gui-beta")

local constants = require("constants")

local search = require("scripts.search")

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

    local results_table = refs.results_table

    if #e.text > 1 then
      local i = 0
      local results, connected_to_network = search.run(player, player_table, query)
      for _, row in ipairs(results) do
        i = i + 1
        if not results_table.children[(i * 3) + 1] then
          for j = 1, 3 do
            results_table.add{type = "label", style = j == 1 and "qis_clickable_label" or nil}
          end
        end
        local hidden_abbrev = row.hidden and "[font=default-semibold](H)[/font]  " or ""
        results_table.children[(i * 3) + 1].caption = hidden_abbrev.."[item="..row.name.."]  "..row.translation
        if player.controller_type == defines.controllers.character and connected_to_network then
          results_table.children[(i * 3) + 2].caption = (row.inventory or 0).." / [color=128, 206, 240]"..(row.logistic or 0).."[/color]"
        else
          results_table.children[(i * 3) + 2].caption = (row.inventory or 0)
        end
        local request = row.request or {min = 0}
        local max = request.max or "inf"
        if max == constants.max_integer then
          max = "inf"
        end
        if player.controller_type == defines.controllers.editor then
          results_table.children[(i * 3) + 3].caption = row.infinity_filter or "--"
        else
          results_table.children[(i * 3) + 3].caption = request.min.." / "..max
          results_table.children[(i * 3) + 3].style.font_color = constants.colors[row.request_color or "normal"]
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
  elseif msg == "enter_result_selection" then
  end
end

return search_gui
