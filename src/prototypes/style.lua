local styles = data.raw["gui-style"].default

-- BUTTON STYLES

local tileset = "__QuickItemSearch__/graphics/button-tileset.png"

local function slot_button(y, glow_color, default_x)
  return {
    type = "button_style",
    parent = "quick_bar_slot_button",
    default_graphical_set = {
      base = {border=4, position={(default_x or 0),y}, size=80, filename=tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    },
    hovered_graphical_set = {
      base = {border=4, position={80,y}, size=80, filename=tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
      glow = offset_by_2_rounded_corners_glow(glow_color)
    },
    clicked_graphical_set = {
      base = {border=4, position={160,y}, size=80, filename=tileset},
      shadow = offset_by_2_rounded_corners_glow(default_dirt_color),
    }
  }
end

local slot_button_data = {
  {name="inventory", y=0, glow=default_glow_color},
  -- {name="light_grey", y=80, glow=default_glow_color},
  {name="unavailable", y=160, glow={255,166,123,128}},
  -- {name="recipe", y=240, glow={34,255,75,128}},
  {name="logistic", y=320, glow={34,181,255,128}},
}

for _,data in ipairs(slot_button_data) do
  styles["qis_slot_button_"..data.name] = slot_button(data.y, data.glow)
  styles["qis_active_slot_button_"..data.name] = slot_button(data.y, data.glow, 80)
end

styles.qis_active_button = {
  type = "button_style",
  parent = "button",
  default_graphical_set = {
    base = {position = {34, 17}, corner_size = 8},
    shadow = default_dirt,
    -- glow = default_glow(default_glow_color, 0.5) -- no glow!
  }
}

-- FRAME STYLES

styles.qis_content_frame = {
  type = "frame_style",
  parent = "window_content_frame",
  width = 224,
  height = 184,
  top_margin = 6
}

styles.qis_results_frame = {
  type = "frame_style",
  parent = "inside_deep_frame",
  padding = 0,
  graphical_set = {
    base = {
      position = {85,0},
      corner_size = 8,
      draw_type = "outer",
      center = {position={42,8}, size=1}
    },
    shadow = default_inner_shadow
  }
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

-- TABLE STYLES

styles.qis_results_table = {
  type = "table_style",
  parent = "filter_slot_table",
  width = 200
}

-- TEXTFIELD STYLES

styles.qis_search_textfield = {
  type = "textbox_style",
  width = 224
}