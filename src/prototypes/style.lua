local constants = require("constants")

local styles = data.raw["gui-style"].default

-- LABEL STYLES

styles.qis_clickable_label = {
  type = "label_style",
  hovered_font_color = constants.colors.hovered,
  disabled_font_color = constants.colors.hovered
}

styles.qis_clickable_item_label = {
  type = "label_style",
  parent = "qis_clickable_label",
  horizontally_stretchable = "on"
}

-- SCROLLPANE STYLES

styles.qis_list_box_scroll_pane = {
  type = "scroll_pane_style",
  parent = "list_box_scroll_pane",
  graphical_set = {
    shadow = default_inner_shadow
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0,
    horizontally_stretchable = "on"
  }
}

-- TABLE STYLES

styles.qis_list_box_table = {
  type = "table_style",
  parent = "mods_table",
  top_margin = -6, -- to hide the strange first row styling
  column_alignments = {
    {column = 1, alignment = "left"},
    {column = 2, alignment = "center"},
    {column = 3, alignment = "center"},
  }
}
