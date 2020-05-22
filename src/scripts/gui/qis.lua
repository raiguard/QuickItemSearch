local qis_gui = {}

local gui = require("__flib__.gui")

local constants = require("scripts.constants")
local gui_functions = require("scripts.gui.functions")
local player_data = require("scripts.player-data")
local util = require("scripts.util")

local string = string

gui.add_templates{
  logistic_request_setter = function(name, max_value)
    return {type="flow", style_mods={vertical_align="center", horizontal_spacing=10}, children={
      {type="slider", name="qis_setter_"..name.."_slider", style_mods={minimal_width=130, horizontally_stretchable=true}, minimum_value=0,
        maximum_value=max_value, handlers="request.setter.slider", save_as="request."..name.."_setter.slider"},
      {type="textfield", name="qis_setter_"..name.."_textfield", style_mods={width=60, horizontal_align="center"}, numeric=true, lose_focus_on_confirm=true,
        clear_and_focus_on_right_click=true, handlers="request.setter.textfield", save_as="request."..name.."_setter.textfield"}
    }}
  end,
  pushers = {
    horizontal = {type="empty-widget", style_mods={horizontally_stretchable=true}},
    vertical = {type="empty-widget", style_mods={vertically_stretchable=true}}
  },
  set_request_button = function(name)
    return {type="button", name="qis_set_"..name.."_request", style_mods={horizontally_stretchable=true, right_margin=2},
      caption={"qis-gui.set-"..name.."-request"}, tooltip={"qis-gui.set-"..name.."-request-description"}, handlers="request.set_request_button",
      save_as="request.set_"..name.."_request_button"}
  end
}

gui.add_handlers{
  search = {
    result_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui
        local element = e.element
        local _, _, action_type = string.find(string.gsub(element.style.name, "qis_active", "qis"), "qis_slot_button_(.*)")
        local item_name = util.sprite_to_item_name(element.sprite)

        if e.keyboard_confirm then
          gui_data.search.used_keyboard_confirm = true
        end

        if gui_functions.take_action(player, player_table, action_type, item_name, element.number or 0, e.shift) then
          qis_gui.destroy(player, player_table)
        elseif not e.keyboard_confirm and gui_data.state == "set_min_request" then
          gui_data.search.textfield.text = player_table.translations[util.sprite_to_item_name(element.sprite)]
        end
      end
    },
    results_scrollpane = {
      on_gui_closed = function(e)
        local player_table = global.players[e.player_index]
        if player_table.gui.state == "select_result" then
          gui.handlers.search.textfield.on_gui_click{player_index=e.player_index, element=player_table.gui.search.textfield}
        end
      end
    },
    textfield = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui
        local element = e.element

        if gui_data.state ~= "search" then
          if gui_data.search.selected_index then
            qis_gui.cancel_selection(gui_data)
          end

          gui_data.search.pane.visible = true
          gui_data.request.pane.visible = false

          gui_data.state = "search"
          element.text = gui_data.search.query
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
      on_gui_confirmed = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui

        if #gui_data.search.results_table.children > 0 then
          qis_gui.move_result(player_table)

          gui_data.state = "select_result"
          player.opened = gui_data.search.results_scrollpane
        end
      end,
      on_gui_text_changed = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local query = e.text
        player_table.gui.search.query = query

        -- fuzzy search
        if player_table.settings.fuzzy_search then
          query = string.gsub(query, ".", "%1.*")
        end
        -- input sanitization
        for pattern, replacement in pairs(constants.input_sanitizers) do
          query = string.gsub(query, pattern, replacement)
        end

        if query == "" then
          player_table.gui.search.results_table.clear()
          return
        end

        gui_functions.search(player, player_table, query)
      end
    }
  },
  request = {
    setter = {
      slider = {
        on_gui_value_changed = function(e)
          local _, _, type = string.find(e.element.name, "qis_setter_(.-)_slider")
          local gui_data = global.players[e.player_index].gui

          if gui_data.state ~= "set_min_request" then
            gui_data.state = "switching_to_slider"
            game.get_player(e.player_index).opened = gui_data.request.min_setter.textfield
            gui_data.state = "set_min_request"
          end

          gui_functions.set_value(
            global.players[e.player_index].gui.request,
            type,
            constants.slider_mapping.slider_to_textfield[e.element.slider_value],
            "slider"
          )
        end
      },
      textfield = {
        on_gui_click = function(e)
          local _, _, type = string.find(e.element.name, "qis_setter_(.-)_textfield")
          local player = game.get_player(e.player_index)
          local player_table = global.players[e.player_index]
          local gui_data = player_table.gui

          if type == "min" and gui_data.state ~= "set_min_request" then
            gui_data.state = "set_min_request"
            local textfield = gui_data.request.min_setter.textfield
            textfield.select_all()
            textfield.focus()
            player.opened = textfield
            if gui_data.request.selected_type then
              gui_data.request["set_"..gui_data.request.selected_type.."_request_button"].style = "button"
              gui_data.request.selected_type = nil
            end
          elseif type == "max" and gui_data.state ~= "set_max_request"then
            gui_data.state = "set_max_request"
            local textfield = gui_data.request.max_setter.textfield
            textfield.select_all()
            textfield.focus()
            if textfield.text == "" or textfield.text == "inf" then
              textfield.text = ""
            end
            player.opened = textfield
            if gui_data.request.selected_type then
              gui_data.request["set_"..gui_data.request.selected_type.."_request_button"].style = "button"
              gui_data.request.selected_type = nil
            end
          end
        end,
        on_gui_closed = function(e)
          local _, _, type = string.find(e.element.name, "qis_setter_(.-)_textfield")
          local player = game.get_player(e.player_index)
          local player_table = global.players[e.player_index]
          local gui_data = player_table.gui

          if type == "min" and gui_data.state == "set_min_request" then
            -- gui_functions.set_value(gui_data.request, type, gui_data.request.data[type])
            gui_data.search.pane.visible = true
            gui_data.request.pane.visible = false

            if gui_data.search.used_keyboard_confirm then
              gui_data.search.used_keyboard_confirm = nil
              gui_data.state = "select_result"
              gui_data.search.results_scrollpane.focus()
              player.opened = gui_data.search.results_scrollpane
            else
              gui.handlers.search.textfield.on_gui_click{player_index=e.player_index, element=gui_data.search.textfield}
            end
          elseif type == "max" and gui_data.state == "set_max_request" then
            gui_functions.set_value(gui_data.request, type, gui_data.request.data[type])
            -- gui_functions.validate_request_amounts(gui_data.request)
            gui.handlers.request.setter.textfield.on_gui_click{player_index=e.player_index, element=gui_data.request.min_setter.textfield}
          elseif type == "max" and gui_data.state == "switching_to_slider" then
            gui_functions.set_value(gui_data.request, type, gui_data.request.data[type])
          end
        end,
        on_gui_confirmed = function(e)
          local _, _, type = string.find(e.element.name, "qis_setter_(.-)_textfield")
          local player = game.get_player(e.player_index)
          local player_table = global.players[e.player_index]
          local gui_data = player_table.gui

          gui_functions.set_value(gui_data.request, type, gui_data.request.data[type])

          if type == "min" then
            gui.handlers.request.setter.textfield.on_gui_click{player_index=e.player_index, element=gui_data.request.max_setter.textfield}
          elseif type == "max" then
            gui_data.state = "select_request_type"
            gui_data.request.selected_type = "temporary"
            local button = gui_data.request.set_temporary_request_button
            button.style = "qis_active_button"
            player.opened = button
          end
        end,
        on_gui_text_changed = function(e)
          local _, _, type = string.find(e.element.name, "qis_setter_(.-)_textfield")
          local request_gui_data = global.players[e.player_index].gui.request

          if type == "min" then
            request_gui_data.data.min = tonumber(e.text) or 0
          elseif type == "max" then
            request_gui_data.data.max = tonumber(e.text) or constants.max_integer
          end
        end
      }
    },
    set_request_button = {
      on_gui_click = function(e)
        local player = game.get_player(e.player_index)
        local player_table = global.players[e.player_index]
        local _, _, type = string.find(e.element.name, "qis_set_(.-)_request")
        if player_data.set_request(player, player_table, player_table.gui.request.data, type == "temporary") then
          qis_gui.destroy(player, player_table)
        end
      end,
      on_gui_closed = function(e)
        -- only the temporary request button ever gets opened, so we don't need to check the type
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui

        if gui_data.state == "select_request_type" then
          gui_data.request["set_"..gui_data.request.selected_type.."_request_button"].style = "button"
          gui_data.request.selected_type = nil
          gui.handlers.request.setter.textfield.on_gui_click{player_index=e.player_index, element=gui_data.request.max_setter.textfield}
        elseif gui_data.state == "switching_to_slider" then
          gui_data.request["set_"..gui_data.request.selected_type.."_request_button"].style = "button"
        end
      end
    }
  }
}

function qis_gui.create(player, player_table)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", save_as="window", children={
      {type="textfield", style="qis_search_textfield", clear_and_focus_on_right_click=true, handlers="search.textfield", save_as="search.textfield"},
      {type="flow", children={
        {type="frame", style="qis_content_frame", style_mods={padding=12}, elem_mods={visible=true}, save_as="search.pane", children={
          {type="frame", style="qis_results_frame", children={
            {type="scroll-pane", style="qis_results_scroll_pane", handlers="search.results_scrollpane", save_as="search.results_scrollpane", children={
              {type="table", style="qis_results_table", column_count=5, save_as="search.results_table"}
            }}
          }}
        }},
        {type="frame", style="qis_content_frame", style_mods={padding=0}, direction="vertical", elem_mods={visible=false}, save_as="request.pane", children={
          {type="frame", style="subheader_frame", style_mods={height=30}, children={
            {type="label", style="caption_label", style_mods={left_margin=4}, save_as="request.label"},
            {template="pushers.horizontal"}
          }},
          {type="flow", style_mods={top_padding=2, left_padding=10, right_padding=8, bottom_padding=8}, direction="vertical", children={
            gui.templates.logistic_request_setter("min", 37),
            gui.templates.logistic_request_setter("max", 38),
            {template="pushers.vertical"},
            gui.templates.set_request_button("temporary"),
            gui.templates.set_request_button("persistent")

          }}
        }}
      }}
    }}
  })

  gui.update_filters("search.result_button", player.index, {"qis_result_button"}, "add")

  gui_data.window.force_auto_center()
  gui_data.search.textfield.focus()

  player.opened = gui_data.search.textfield
  gui_data.state = "search"

  player_table.gui = gui_data

  player.set_shortcut_toggled("qis-search", true)
end

function qis_gui.destroy(player, player_table)
  gui.update_filters("search", player.index, nil, "remove")
  gui.update_filters("request", player.index, nil, "remove")
  player_table.gui.window.destroy()
  player_table.gui = nil

  player.set_shortcut_toggled("qis-search", false)
end

function qis_gui.toggle(player, player_table)
  if player_table.gui then
    qis_gui.destroy(player, player_table)
  elseif player_table.flags.can_open_gui then
    qis_gui.create(player, player_table)
  else
    player.print{"qis-message.cannot-open-gui"}
    player_table.flags.show_message_after_translation = true
  end
end

function qis_gui.cancel_selection(gui_data)
  local selected_index = gui_data.search.selected_index
  local selected_element = gui_data.search.results_table.children[selected_index]
  selected_element.style = string.gsub(selected_element.style.name, "qis_active", "qis")
  gui_data.search.selected_index = nil
end

function qis_gui.move_result(player_table, offset)
  local gui_data = player_table.gui
  local children = gui_data.search.results_table.children
  local selected_index = gui_data.search.selected_index
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
  gui_data.search.results_scrollpane.scroll_to_element(selected_element)
  -- update item name in textfield
  gui_data.search.textfield.text = player_table.translations[util.sprite_to_item_name(selected_element.sprite)]
  -- update index in global
  gui_data.search.selected_index = selected_index
end

function qis_gui.confirm_result(player_index, gui_data, input_name)
  gui.handlers.search.result_button.on_gui_click{
    player_index = player_index,
    element = gui_data.search.results_table.children[gui_data.search.selected_index],
    shift = input_name == "qis-nav-shift-confirm",
    keyboard_confirm = true
  }
end

function qis_gui.move_request_type(player_table)
  local request_gui_data = player_table.gui.request
  local selected_type = request_gui_data.selected_type
  request_gui_data["set_"..selected_type.."_request_button"].style = "button"
  local new_type = constants.request_type_switcheroos[selected_type]
  request_gui_data["set_"..new_type.."_request_button"].style = "qis_active_button"
  request_gui_data.selected_type = new_type
end

function qis_gui.confirm_request_type(player_index, player_table)
  local request_gui_data = player_table.gui.request
  local element = request_gui_data["set_"..request_gui_data.selected_type.."_request_button"]
  gui.handlers.request.set_request_button.on_gui_click{player_index=player_index, element=element}
end

return qis_gui