local gui_functions = {}

local constants = require("scripts.constants")
local player_data = require("scripts.player-data")

function gui_functions.search(player, player_table, query)
  local player_settings = player_table.settings
  local results_table = player_table.gui.search.results_table
  local children = results_table.children
  local translations = player_table.translations
  local item_data = global.item_data
  local add = results_table.add
  local index = 0
  local results = {}
  local button_indexes = {}

  local show_hidden = player_settings.search_hidden

  -- add or update the next result button
  local function set_result(type, name, number)
    index = index + 1
    results[name] = number
    local button = children[index]
    if button then
      button.style = "qis_slot_button_"..type
      button.sprite = "item/"..name
      button.tooltip = translations[name]
      button.number = number
    else
      button = add{type="sprite-button", name="qis_result_button__"..index, style="qis_slot_button_"..type, sprite="item/"..name, number=number,
        tooltip=translations[name], mouse_button_filter={"left"}}
    end
    button_indexes[index] = button.index
  end

  -- match the query to the given name
  local function match_query(name, translation, ignore_unique)
    return item_data[name] and (ignore_unique or not results[name]) and (show_hidden or not item_data[name].hidden)
      and string.find(string.lower(translation or translations[name]), query)
  end

  -- map editor
  if player.controller_type == defines.controllers.editor then
    local contents = player.get_main_inventory().get_contents()
    for internal,translated in pairs(translations) do
      -- we don't care about hidden or other results, so use an optimised condition
      if string.find(string.lower(translated), query) then
        set_result("inventory", internal, contents[internal])
      end
    end
  else
    -- player inventory
    if player_settings.search_inventory then
      local contents = player.get_main_inventory().get_contents()
      for name,count in pairs(contents) do
        if match_query(name) then
          set_result("inventory", name, count)
        end
      end
    end
    -- logistic network(s)
    if player.character and player_settings.search_logistics then
      local character = player.character
      local network_contents = {}
      local network = character.get_logistic_point(defines.logistic_member_index.character_requester).logistic_network
      if network.valid then
        local contents = network.get_contents()
        for name,count in pairs(contents) do
          if match_query(name, nil, not network_contents[name]) then
            network_contents[name] = count
            set_result("logistic", name, count)
          end
        end
      end
    end
    -- unavailable
    if player_settings.search_unavailable then
      for internal,translated in pairs(translations) do
        if match_query(internal, translated) then
          set_result("unavailable", internal)
        end
      end
    end
  end

  -- remove extra buttons, if any
  for i=index+1, #children do
    children[i].destroy()
  end
end

function gui_functions.take_action(player, player_table, action_type, item_name, item_count, shift)
  local item_data = global.item_data[item_name]
  local stack_size = item_data.stack_size
  local function set_ghost_cursor()
    if item_data.place_result then
      if player.clean_cursor() then
        player.cursor_ghost = item_name
      end
    end
  end

  local close_gui = false

  if action_type == "inventory" then
    local is_editor = player.controller_type == defines.controllers.editor
    if player.clean_cursor() then
      if is_editor then
        if item_count == 0 then
          player.cursor_stack.set_stack{name=item_name, count=stack_size}
        else
          player.cursor_stack.set_stack{name=item_name, count=player.get_main_inventory().remove{name=item_name, count=stack_size}}
        end
        if shift then
          local index = #player.infinity_inventory_filters + 1
          player.set_infinity_inventory_filter(index, {name=item_name, count=stack_size, mode="exactly", index=index})
        end
        close_gui = true
      else
        if shift then
          player_data.quick_trash(player, player_table, item_name)
          player.print{"qis-message.quick-trashed", player_table.translations[item_name]}
        else
          player.cursor_stack.set_stack{name=item_name, count=player.get_main_inventory().remove{name=item_name, count=stack_size}}
          close_gui = true
        end
      end
    end
  elseif action_type == "logistic" then
    if shift then
      set_ghost_cursor()
      close_gui = true
    else
      gui_functions.show_request_pane(player, player_table, item_name)
    end
  elseif action_type == "unavailable" then
    if shift then
      if player.cheat_mode then
        if player.clean_cursor() then
          player.cursor_stack.set_stack{name=item_name, count=stack_size}
          close_gui = true
        end
      else
        set_ghost_cursor()
      end
      close_gui = true
    else
      gui_functions.show_request_pane(player, player_table, item_name)
    end
  end

  return close_gui
end

function gui_functions.show_request_pane(player, player_table, item_name)
  local gui_data = player_table.gui
  local request_gui_data = gui_data.request

  local request_data = player_data.find_request(player, item_name)

  if request_data then
    request_gui_data.label.caption = {"qis-gui.edit-request"}
  else
    request_gui_data.label.caption = {"qis-gui.set-request"}
    request_data = {name=item_name, min=global.item_data[item_name].stack_size, max=constants.max_integer}
  end
  gui_data.request.data = request_data
  gui_functions.set_value(gui_data.request, "min", request_data.min)
  gui_functions.set_value(gui_data.request, "max", request_data.max)

  -- set GUI state
  gui_data.state = "set_min_request"
  gui_data.search.pane.visible = false
  request_gui_data.pane.visible = true
  request_gui_data.min_setter.textfield.select_all()
  request_gui_data.min_setter.textfield.focus()
  player.opened = request_gui_data.min_setter.textfield
end

function gui_functions.set_value(request_gui_data, type, value, source)
  local setter = request_gui_data[type.."_setter"]
  local request_data = request_gui_data.data

  if value == "" then value = constants.max_integer end

  if not source or source == "slider" then
    if value == constants.max_integer then
      setter.textfield.text = "inf"
    else
      setter.textfield.text = value
    end
  end

  if not source then
    if value ~= constants.max_integer then
      local round = util.round
      if value > 9 then
        value = round(value/10) * 10
        if value > 90 then
          value = round(value/100) * 100
          if value > 900 then
            value = round(value/1000) * 1000
          end
        end
      end
    end
    if value > 10000 then
      setter.slider.slider_value = 38
    else
      setter.slider.slider_value = constants.slider_mapping.textfield_to_slider[value]
    end
  end

  request_data[type] = value

  -- check values
  if type == "min" and request_data.min > request_data.max then
    request_data.max = request_data.min
    gui_functions.set_value(request_gui_data, "max", request_data.min)
  elseif type == "max" and request_data.min > request_data.max then
    request_data.min = request_data.max
    gui_functions.set_value(request_gui_data, "min", request_data.min)
  end
end

return gui_functions