-- Shared layout geometry so every page lines its columns and rows up identically.
-- Included at plugin top level; consumed by src/layout/*.lua.
--
-- Page grid, top to bottom (y in pixels with the default constants):
--
--   y = 10   page title       page_title()             title_y()
--   y = 34   column headers   add_header()             header_y()
--   y = 54   row 1            place(), place_led()     row_y(1)
--   y = 76   row 2                                     row_y(2)
--   ...      every row is row_height + row_gap = 22 px further down
--
-- Columns run left to right from x = margin with col_gap between them. Describe them once with
-- build_columns() and place every control by column and row, so a width change moves every page.
--
-- Two kinds of output, matching the two tables of GetControlLayout:
--   layout    controls, keyed by control name   place_at(), place(), place_led()
--   graphics  labels and boxes, a list          page_title(), add_header(), label(), group()
--
-- Example, a page with one row per input:
--
--   if current_page == example_page_name then
--     local cols = layout_kit.build_columns({
--       { key = "name",   label = "Name",   width = 120 },
--       { key = "gain",   label = "Gain",   width = 60 },
--       { key = "active", label = "Active", width = 40 },
--     });
--     layout_kit.page_title(graphics, "Example", cols.right_edge - layout_kit.margin);
--     layout_kit.add_header(graphics, cols);
--     for i = 1, input_count do
--       layout_kit.place(layout, indexed_name("input_name", i), cols.name, i, { Style = "Text" });
--       layout_kit.place(layout, indexed_name("input_gain", i), cols.gain, i, { Style = "Knob" });
--       layout_kit.place_led(layout, indexed_name("input_active", i), cols.active, i);
--     end
--   end
--
-- Control names: a control with Count > 1 is laid out as "<Name> <i>" (see indexed_name). A
-- control with Count = 1 is laid out as "<Name>" alone.

layout_kit = {};

-- Geometry, in pixels.
layout_kit.margin = 10;        -- Left edge of the first column and top edge of the page title.
layout_kit.col_gap = 4;        -- Horizontal space between two columns.
layout_kit.row_height = 20;    -- Height of a control row, a label() and an LED.
layout_kit.row_gap = 2;        -- Vertical space between two rows.
layout_kit.title_height = 18;  -- Height of the page title.
layout_kit.header_height = 16; -- Height of the column header labels.

-- Colors for layout entries, as { r, g, b } tables (0..255).
layout_kit.label_color = { 60, 60, 60 };     -- Text of headers and labels.
layout_kit.readout_color = { 235, 235, 235 }; -- Background of read-only text controls.
layout_kit.success_color = { 0, 200, 0 };    -- LED or text for a good state.
layout_kit.failure_color = { 200, 0, 0 };    -- LED or text for a bad state.
-- Runtime Control.Color needs a hex string, unlike the layout's RGB-table Color fields above.
layout_kit.success_color_hex = "#00C800";
layout_kit.failure_color_hex = "#C80000";

--- Y position of the page title.
---@return number
function layout_kit.title_y()
  return layout_kit.margin;
end

--- Y position of the column header line, below the page title.
---@return number
function layout_kit.header_y()
  return layout_kit.title_y() + layout_kit.title_height + 6;
end

--- Y position of a control row. Row 1 is the first row below the column headers.
---@param row_index number 1-based row number.
---@return number
function layout_kit.row_y(row_index)
  local first = layout_kit.header_y() + layout_kit.header_height + 4;
  return first + (row_index - 1) * (layout_kit.row_height + layout_kit.row_gap);
end

--- Y position just below the last of `row_count` rows. Use it to place content under a table,
--- for example a group() or a second block of rows.
---@param row_count number Number of rows above.
---@return number
function layout_kit.rows_bottom(row_count)
  return layout_kit.row_y(row_count + 1);
end

--- Copies every field of `opts` into `entry`, overwriting fields of the same name.
--- All place and label functions use it for their optional `opts` argument.
---@param entry table Layout or graphics entry.
---@param opts table|nil Extra fields, for example { Style = "Text", Color = layout_kit.readout_color }.
---@return table entry
function layout_kit.apply(entry, opts)
  return merge_into(entry, opts);
end

--- Lays out columns left to right, starting at `margin`, with `col_gap` between them.
---
--- Returns a table with:
---   cols[key]        one column: { key, label, x, width }
---   cols.order       the columns in the order of `defs`, for add_header()
---   cols.right_edge  x of the right edge of the last column, for title and group widths
---@param defs table Ordered list of { key = string, label = string|nil, width = number }.
---@return table cols
function layout_kit.build_columns(defs)
  local cols = { order = {} };
  local x = layout_kit.margin;
  for _, def in ipairs(defs) do
    local col = { key = def.key, label = def.label or "", x = x, width = def.width };
    cols[def.key] = col;
    table.insert(cols.order, col);
    x = x + def.width + layout_kit.col_gap;
  end
  cols.right_edge = x - layout_kit.col_gap;
  return cols;
end

--- Adds the header label of one column at header_y(). Does nothing when the label is empty.
---@param graphics table The graphics list of GetControlLayout.
---@param col table One column from build_columns().
function layout_kit.add_header_label(graphics, col)
  if col.label == "" then
    return;
  end
  table.insert(graphics, {
    Type = "Label",
    Text = col.label,
    Position = { col.x, layout_kit.header_y() },
    Size = { col.width, layout_kit.header_height },
    FontSize = 11,
    HTextAlign = "Left",
    Color = layout_kit.label_color,
  });
end

--- Adds the header labels of all columns, in column order.
---@param graphics table The graphics list of GetControlLayout.
---@param cols table The result of build_columns().
function layout_kit.add_header(graphics, cols)
  for _, col in ipairs(cols.order) do
    layout_kit.add_header_label(graphics, col);
  end
end

--- Places a control at an exact position and size. Use it for controls outside the column grid.
---@param layout table The layout table of GetControlLayout.
---@param ctrl_name string Control name, for example indexed_name("input_gain", 2).
---@param x number Left edge.
---@param y number Top edge.
---@param width number
---@param height number
---@param opts table|nil Extra layout fields, for example Style, PrettyName, Color, HTextAlign.
---@return table entry The layout entry, to change it further.
function layout_kit.place_at(layout, ctrl_name, x, y, width, height, opts)
  local entry = { Position = { x, y }, Size = { width, height } };
  layout_kit.apply(entry, opts);
  layout[ctrl_name] = entry;
  return entry;
end

--- Places a control in a grid cell. The control fills the column width and row_height.
---@param layout table The layout table of GetControlLayout.
---@param ctrl_name string Control name.
---@param col table One column from build_columns().
---@param row_index number 1-based row number, see row_y().
---@param opts table|nil Extra layout fields, see place_at().
---@return table entry
function layout_kit.place(layout, ctrl_name, col, row_index, opts)
  return layout_kit.place_at(layout, ctrl_name, col.x, layout_kit.row_y(row_index),
    col.width, layout_kit.row_height, opts);
end

--- Places an LED as a row_height square, centred in a grid cell.
-- LEDs stretch to an oval if given the full column width, so keep them square and centred.
---@param layout table The layout table of GetControlLayout.
---@param ctrl_name string Control name.
---@param col table One column from build_columns().
---@param row_index number 1-based row number, see row_y().
---@param opts table|nil Extra layout fields, for example { Color = layout_kit.success_color }.
---@return table entry
function layout_kit.place_led(layout, ctrl_name, col, row_index, opts)
  local size = layout_kit.row_height;
  local x = col.x + math.floor((col.width - size) / 2);
  return layout_kit.place_at(layout, ctrl_name, x, layout_kit.row_y(row_index), size, size, opts);
end

--- Adds the bold page title at the top left of the page.
---@param graphics table The graphics list of GetControlLayout.
---@param text string Title text.
---@param width number Label width. cols.right_edge - layout_kit.margin spans all columns.
function layout_kit.page_title(graphics, text, width)
  table.insert(graphics, {
    Type = "Label",
    Text = text,
    Position = { layout_kit.margin, layout_kit.title_y() },
    Size = { width, layout_kit.title_height },
    FontSize = 14,
    FontStyle = "Bold",
    HTextAlign = "Left",
  });
end

--- Adds a grey group box with a caption and a 1 px border, to frame related controls.
---@param graphics table The graphics list of GetControlLayout.
---@param text string Caption.
---@param x number Left edge.
---@param y number Top edge.
---@param width number
---@param height number
function layout_kit.group(graphics, text, x, y, width, height)
  table.insert(graphics, {
    Type = "GroupBox",
    Text = text,
    Position = { x, y },
    Size = { width, height },
    Fill = { 222, 222, 222 },
    StrokeWidth = 1,
    CornerRadius = 6,
  });
end

--- Adds a row_height text label. The text is right-aligned, so the label sits flush against a
--- control placed to its right. Pass { HTextAlign = "Left" } for free text.
---@param graphics table The graphics list of GetControlLayout.
---@param text string Label text.
---@param x number Left edge.
---@param y number Top edge, usually row_y(row_index).
---@param width number
---@param opts table|nil Extra graphics fields, for example FontStyle, HTextAlign, Size.
---@return table entry The graphics entry, to change it further.
function layout_kit.label(graphics, text, x, y, width, opts)
  local entry = {
    Type = "Label",
    Text = text,
    Position = { x, y },
    Size = { width, layout_kit.row_height },
    FontSize = 11,
    HTextAlign = "Right",
    Color = layout_kit.label_color,
  };
  layout_kit.apply(entry, opts);
  table.insert(graphics, entry);
  return entry;
end

--- Fills a page that has no controls yet with a title and one line of text.
---@param graphics table The graphics list of GetControlLayout.
---@param page_name string Title text.
---@param message string Text below the title.
function layout_kit.stub_page(graphics, page_name, message)
  layout_kit.page_title(graphics, page_name, 400);
  table.insert(graphics, {
    Type = "Label",
    Text = message,
    Position = { layout_kit.margin, layout_kit.header_y() + 10 },
    Size = { 400, 40 },
    FontSize = 12,
    HTextAlign = "Left",
    Color = layout_kit.label_color,
  });
end
