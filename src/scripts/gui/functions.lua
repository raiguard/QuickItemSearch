local gui_functions = {}

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
    return (ignore_unique or not results[name]) and (show_hidden or not item_data[name].hidden)
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
      local ignore_unique = not player_settings.logistics_unique_only
      local character = player.character
      local network_contents = {}
      for _,point in ipairs(character.get_logistic_point()) do
        local network = point.logistic_network
        if network.valid and network.all_logistic_robots > 0 then
          local contents = point.logistic_network.get_contents()
          for name,count in pairs(contents) do
            if match_query(name, nil, not network_contents[name] and ignore_unique) then
              network_contents[name] = count
              set_result("logistic", name, count)
            end
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

function gui_functions.take_action(player, player_table, action_type, name, count, control, shift)
  --[[
    Logistic:
      default: request a temporary stack from the network
      shift: set custom temporary request
  ]]
  local item_data = global.item_data[name]
  local stack_size = item_data.stack_size
  local function set_ghost_cursor()
    if item_data.place_result then
      if player.clean_cursor() then
        player.cursor_ghost = name
      end
    end
  end

  local close_gui = false

  if action_type == "inventory" then
    local is_editor = player.controller_type == defines.controllers.editor
    if player.clean_cursor() then
      if count == 0 and is_editor then
        player.cursor_stack.set_stack{name=name, count=stack_size}
      else
        player.cursor_stack.set_stack{name=name, count=player.get_main_inventory().remove{name=name, count=stack_size}}
      end
      if is_editor and shift then
        local index = #player.infinity_inventory_filters + 1
        player.set_infinity_inventory_filter(index, {name=name, count=stack_size, mode="exactly", index=index})
      end
      close_gui = true
    end
  elseif action_type == "logistic" then
    if control then
      set_ghost_cursor()
      close_gui = true
    elseif shift then

    else

    end
  elseif action_type == "unavailable" then
    if shift then
      if player.cheat_mode then
        if player.clean_cursor() then
          player.cursor_stack.set_stack{name=name, count=stack_size}
          close_gui = true
        end
      else
        player.print{'qis-message.not-in-cheat-mode'}
      end
    else
      set_ghost_cursor()
      close_gui = true
    end
  end

  return close_gui
end

function gui_functions.set_request()
  -- TODO
end

return gui_functions