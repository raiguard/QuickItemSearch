log(serpent.block(mods))

local spawn_item_tooltip = {
  "",
  {"mod-setting-description.qis-spawn-items-when-cheating"},
  mods["space-exploration"] and {"", "\n\n", {"mod-setting-description.qis-spawn-items-when-cheating-se-addendum"}} or ""
}

data:extend{
  {
    type = "bool-setting",
    name = "qis-search-inventory",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "aa"
  },
  {
    type = "bool-setting",
    name = "qis-search-logistics",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ab"
  },
  {
    type = "bool-setting",
    name = "qis-search-unavailable",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ac"
  },
  {
    type = "bool-setting",
    name = "qis-search-hidden",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ad"
  },
  {
    type = "bool-setting",
    name = "qis-fuzzy-search",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ae"
  },
  {
    type = "bool-setting",
    name = "qis-spawn-items-when-cheating",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "af",
    localised_description = spawn_item_tooltip
  },
  {
    type = "string-setting",
    name = "qis-quick-trash-all-excludes",
    setting_type = "runtime-per-user",
    default_value = "[]",
    order = "b"
  }
}