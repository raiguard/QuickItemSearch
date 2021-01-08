local styles = data.raw["gui-style"].default

-- BUTTON STYLES

styles.qis_list_box_item = {
  type = "button_style",
  parent = "list_box_item",
  left_padding = 4,
  right_padding = 4,
  horizontally_squashable = "on",
  horizontally_stretchable = "on",
  disabled_graphical_set = styles.list_box_item.default_graphical_set,
  disabled_font_color = styles.list_box_item.default_font_color
}

styles.qis_invisible_list_box_item = {
  type = "button_style",
  parent = "list_box_item",
  padding = 0,
  margin = 0,
  -- graphical_set = {}
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
