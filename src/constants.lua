local constants = {}

constants.colors = {
  emptying = {69, 255, 69},
  normal = {255, 255, 255},
  on_the_way ={255, 240, 69},
  unsatisfied = {255, 69, 69},
}

constants.ignored_item_types = {
  ["blueprint-book"] = true,
  ["blueprint"] = true,
  ["copy-paste-tool"] = true,
  ["deconstruction-item"] = true,
  ["item-with-inventory"] = true,
  ["item-with-tags"] = true,
  ["selection-tool"] = true,
  ["upgrade-item"] = true
}

constants.input_sanitizers = {
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

constants.max_integer = 4294967295

constants.settings = {
  search_inventory = "qis-search-inventory",
  search_logistic_network = "qis-search-logistic-network",
  search_unavailable = "qis-search-unavailable",
  show_hidden = "qis-show-hidden",
  fuzzy_search = "qis-fuzzy-search",
  spawn_items_when_cheating = "qis-spawn-items-when-cheating"
}

return constants
