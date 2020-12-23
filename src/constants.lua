local constants = {}

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

constants.settings = {
  search_inventory = "qis-search-inventory",
  search_logistic_network = "qis-search-logistic-network",
  search_unavailable = "qis-search-unavailable",
  show_hidden = "qis-show-hidden",
  fuzzy_search = "qis-fuzzy-search",
  spawn_items_when_cheating = "qis-spawn-items-when-cheating"
}

return constants
