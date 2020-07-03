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
    name = "qis-search-utility-items",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ad"
  },
  {
    type = "bool-setting",
    name = "qis-search-hidden",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "b"
  },
  {
    type = "bool-setting",
    name = "qis-fuzzy-search",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "c"
  },
  {
    type = "string-setting",
    name = "qis-quick-trash-all-excludes",
    setting_type = "runtime-per-user",
    default_value = "[]",
    order = "d"
  }
}