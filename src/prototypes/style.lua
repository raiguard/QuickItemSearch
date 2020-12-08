local styles = data.raw["gui-style"].default

-- BUTTON STYLES

styles.qis_active_button = {
  type = "button_style",
  parent = "button",
  default_graphical_set = {
    base = {position = {34, 17}, corner_size = 8},
    shadow = default_dirt,
    -- glow = default_glow(default_glow_color, 0.5) -- no glow!
  }
}

styles.qis_set_request_button = {
  type = "button_style",
  horizontally_stretchable = "on",
  right_margin = 2
}

-- EMPTY WIDGET STYLES

styles.qis_horizontal_pusher = {
  type = "empty_widget_style",
  horizontally_stretchable = "on"
}

styles.qis_vertical_pusher = {
  type = "empty_widget_style",
  vertically_stretchable = "on"
}

-- FLOW STYLES

styles.qis_request_content_flow = {
  type = "vertical_flow_style",
  bottom_padding = 8,
  left_padding = 10,
  right_padding = 8,
  top_padding = 6
}

styles.qis_request_setter_flow = {
  type = "horizontal_flow_style",
  vertical_align = "center",
  horizontal_spacing = 10
}

-- FRAME STYLES

styles.qis_content_frame = {
  type = "frame_style",
  parent = "inside_shallow_frame",
  width = 224,
  height = 184,
  top_margin = 6
}

styles.qis_search_content_frame = {
  type = "frame_style",
  parent = "qis_content_frame",
  padding = 12,
  right_padding = 0
}

styles.qis_short_toolbar_frame = {
  type = "frame_style",
  parent = "subheader_frame",
  height = 30
}

-- LABEL STYLES

styles.qis_request_label = {
  type = "label_style",
  parent = "caption_label",
  left_margin = 4
}

-- SCROLLPANE STYLES

styles.qis_results_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 0,
  height = 160,
  minimal_width = 200,
  horizontally_squashable = "off",
  background_graphical_set = {
    base = {
      position = {282, 17},
      corner_size = 8,
      overall_tiling_horizontal_padding = 4,
      overall_tiling_horizontal_size = 32,
      overall_tiling_horizontal_spacing = 8,
      overall_tiling_vertical_padding = 4,
      overall_tiling_vertical_size = 32,
      overall_tiling_vertical_spacing = 8
    }
  }
}

-- SLIDER STYLES

styles.qis_request_setter_slider = {
  type = "slider_style",
  minimal_width = 0,
  horizontally_stretchable = "on"
}

-- TABLE STYLES

styles.qis_results_table = {
  type = "table_style",
  parent = "slot_table",
  width = 200
}

-- TEXTFIELD STYLES

styles.qis_search_textfield = {
  type = "textbox_style",
  width = 0,
  horizontally_stretchable = "on",
  bottom_margin = 6
}

styles.qis_request_setter_textfield = {
  type = "textbox_style",
  width = 60,
  horizontal_align = "center"
}