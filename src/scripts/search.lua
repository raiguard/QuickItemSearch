local search = {}

function search.run(player, player_table, query)
  -- get the search settings
  local settings = player_table.settings

  local results = {
    inventory = {},
    logistic = {},
    unavailable = {}
  }
  
  if settings.search_inventory then
    local main_inventory = player.get_main_inventory()
    if main_inventory then
      for i = 1, #main_inventory do
        local stack = main_inventory[i]
        if stack and stack.valid_for_read then
          --[[
            SEARCH METHODS:
            - name
            - if item with entity data:
          ]]
        end
      end
    end
  end
end

return search
