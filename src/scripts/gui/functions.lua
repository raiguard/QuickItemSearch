local gui_functions = {}

function gui_functions.search(player, player_table, query)
  local player_settings = player_table.settings
  local results_table = player_table.gui.results_table
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
              set_result("logistics", name, count)
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

function gui_functions.take_action(player, player_table, type, name, count, control, shift)
  --[[
    Inventory:
    default: put stack into cursor
    Logistic:
    default: request a temporary stack from the network
    shift: set custom temporary request
    control: set ghost cursor
    Unavailable:
    default: set ghost cursor
    shift (cheat mode): spawn stack into cursor
    Editor:
    default: put/spawn stack into cursor
    shift: put/spawn stack into cursor, set inventory filter for a stack
  ]]
  local prototype = global.item_prototypes[name]
  local function set_ghost_cursor(player, name)
    if prototype.place_result then
      if player.clean_cursor() then

      end
    end
  end
end

function gui_functions.set_request()
  -- TODO
end

return gui_functions