if current_page == main_page_name then
  layout_kit.stub_page(graphics, PluginName .. " v" .. PluginInfo.Version, "This page has no controls yet.");
  -- Place controls with layout_kit, for example:
  -- layout_kit.place_at(layout, "enable", layout_kit.margin, layout_kit.row_y(1), 60, layout_kit.row_height);
end
