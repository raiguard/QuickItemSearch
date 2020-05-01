local qis_gui = {}

local gui = require("__flib__.control.gui")

local gui_functions = require("scripts.gui.functions")
local util = require("scripts.util")

local string = string

local sanitizers = {
  ["%("] = "%%(",
  ["%)"] = "%%)",
  ["%.^[%*]"] = "%%.",
  ["%+"] = "%%+",
  ["%-"] = "%%-",
  ["^[%.]%*"] = "%%*",
  ["%?"] = "%%?",
  ["%["] = "%%[",
  ["%]"] = "%%]",
  ["%^"] = "%%^",
  ["%$"] = "%%$"
}

gui.add_templates{
  logistic_request_setter = {type="flow", style_mods={vertical_align="center", horizontal_spacing=10}, children={
    {type="slider", style_mods={minimal_width=130, horizontally_stretchable=true}},
    {type="textfield", style_mods={width=60, horizontal_align="center"}, numerical=true, lose_focus_on_confirm=true}
  }}
}

gui.add_handlers{
  search = {
    search_textfield = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui
        local element = e.element

        if gui_data.state == "select_result" then
          qis_gui.cancel_selection(gui_data)

          gui_data.state = "search"
          element.text = gui_data.search_query
          element.focus()
          player.opened = element
        end
      end,
      on_gui_closed = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui
        if gui_data.state == "search" then
          qis_gui.destroy(player, player_table)
        end
      end,
      on_gui_text_changed = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local query = e.text
        player_table.gui.search_query = query

        -- fuzzy search
        if player_table.settings.fuzzy_search then
          query = string.gsub(query, ".", "%1.*")
        end
        -- input sanitization
        for pattern, replacement in pairs(sanitizers) do
          query = string.gsub(query, pattern, replacement)
        end

        -- TODO: non-essential search smarts
        if query == "" then
          player_table.gui.results_table.clear()
          return
        end

        gui_functions.search(player, player_table, query)
      end,
      on_gui_confirmed = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui

        if #gui_data.results_table.children > 0 then
          qis_gui.move_selection(player_table)

          gui_data.state = "select_result"
          player.opened = gui_data.results_scrollpane
        end
      end
    },
    results_scrollpane = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        gui.handlers.search.search_textfield.on_gui_click{player_index=e.player_index, element=player_table.gui.search_textfield}
      end
    },
    result_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local element = e.element
        local _, _, action_type = string.find(string.gsub(element.style.name, "qis_active", "qis"), "qis_slot_button_(.*)")
        local item_name = util.sprite_to_item_name(element.sprite)

        if gui_functions.take_action(player, player_table, action_type, item_name, element.number or 0, e.control, e.shift) then
          qis_gui.destroy(player, player_table)
        end
      end
    }
  }
}

function qis_gui.create(player, player_table)
  -- GUI prototyping
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", save_as="window", children={
      {type="textfield", style="qis_main_textfield", clear_and_focus_on_right_click=true, handlers="search.search_textfield", save_as="search_textfield"},
      {type="flow", children={
        {type="frame", style="qis_content_frame", style_mods={padding=12}, mods={visible=true}, children={
          {type="frame", style="qis_results_frame", children={
            {type="scroll-pane", style="qis_results_scroll_pane", handlers="search.results_scrollpane", save_as="results_scrollpane", children={
              {type="table", style="qis_results_table", column_count=5, save_as="results_table"}
            }}
          }}
        }},
        {type="frame", style="qis_content_frame", style_mods={padding=0}, direction="vertical", mods={visible=false}, children={
          {type="frame", style="subheader_frame", style_mods={height=30}, children={
            {type="label", style="caption_label", style_mods={left_margin=4}, caption="Logistics request"},
            {type="empty-widget", style_mods={horizontally_stretchable=true}},
            {type="sprite-button", style="green_button", style_mods={width=24, height=24, padding=0, top_margin=1}, sprite="utility/confirm_slot"}
          }},
          {type="flow", style_mods={top_padding=2, left_padding=10, right_padding=8}, direction="vertical", children={
            {template="logistic_request_setter"},
            {template="logistic_request_setter"}
          }}
        }}
      }}
    }}
  })

  gui.update_filters("search.result_button", player.index, {"qis_result_button"}, "add")

  gui_data.window.force_auto_center()
  gui_data.search_textfield.focus()

  player.opened = gui_data.search_textfield
  gui_data.state = "search"

  player_table.gui = gui_data
end

function qis_gui.destroy(player, player_table)
  gui.update_filters("search", player.index, nil, "remove")
  player_table.gui.window.destroy()
  player_table.gui = nil
end

function qis_gui.cancel_selection(gui_data)
  local selected_index = gui_data.selected_index
  local selected_element = gui_data.results_table.children[selected_index]
  selected_element.style = string.gsub(selected_element.style.name, "qis_active", "qis")
  gui_data.selected_index = nil
end

function qis_gui.move_selection(player_table, offset)
  local gui_data = player_table.gui
  local children = gui_data.results_table.children
  local selected_index = gui_data.selected_index
  if offset then
    qis_gui.cancel_selection(gui_data)
    -- set new selected index
    selected_index = util.clamp(selected_index + offset, 1, #children)
  else
    selected_index = 1
  end
  -- set new selected style
  local selected_element = children[selected_index]
  selected_element.style = string.gsub(selected_element.style.name, "qis", "qis_active")
  selected_element.focus()
  -- scroll to selection
  gui_data.results_scrollpane.scroll_to_element(selected_element)
  -- update item name in textfield
  gui_data.search_textfield.text = player_table.translations[util.sprite_to_item_name(selected_element.sprite)]
  -- update index in global
  gui_data.selected_index = selected_index
end

function qis_gui.confirm_selection(player_index, gui_data, input_name)
  gui.handlers.search.result_button.on_gui_click{
    player_index = player_index,
    element = gui_data.results_table.children[gui_data.selected_index],
    shift = input_name == "qis-nav-shift-confirm",
    control = input_name == "qis-nav-control-confirm"
  }
end

return qis_gui