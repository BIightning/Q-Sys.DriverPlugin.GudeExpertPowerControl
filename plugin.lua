-- Main file for the plugin.

-- Information block for the plugin
--[[ #include "info.lua" ]]

-- Shared foundation, kept at top level so every Get* function and the runtime block can see it.
--[[ #include "src/shared/util.lua" ]]
--[[ #include "src/shared/catalog.lua" ]]
--[[ #include "src/shared/layout_kit.lua" ]]
--[[ #include "src/shared/control_kit.lua" ]]

-- Define the color of the plugin object in the design
function GetColor(props)
  return { 102, 102, 102 }
end

-- The name that will initially display when dragged into a design
function GetPrettyName(props)
  return PluginName .. " v" .. PluginInfo.Version
end

-- Define User configurable Properties of the plugin
function GetProperties()
  local props = {}
  --[[ #include "properties.lua" ]]
  return props
end

-- Optional function to update available properties when properties are altered by the user
function RectifyProperties(props)
  --[[ #include "rectify_properties.lua" ]]
  return props
end

-- Optional function to define model if plugin supports more than one model. Uncomment if you have a Property named "Model" and don't define Model in PluginInfo
-- function GetModel(props)
--   local model = {}
--   return model
-- end

-- Optional function used if plugin has multiple pages
-- PageNames is defined in src/shared/catalog.lua
function GetPages(props)
  local pages = {}
  --[[ #include "pages.lua" ]]
  return pages
end

-- Defines the Controls used within the plugin
function GetControls(props)
  local ctrls = {}
  --[[ #include "controls.lua" ]]
  return ctrls
end

--Layout of controls and graphics for the plugin UI to display
function GetControlLayout(props)
  local layout = {}
  local graphics = {}
  --[[ #include "layout.lua" ]]
  return layout, graphics
end

-- Optional function to define components used within the plugin
function GetComponents(props)
  local components = {}
  --[[ #include "components.lua" ]]
  return components
end

-- Optional function to define pins on the plugin that are not connected to a Control
function GetPins(props)
  local pins = {}
  --[[ #include "pins.lua" ]]
  return pins
end

-- Optional function to define wiring of components used within the plugin
function GetWiring(props)
  local wiring = {}
  --[[ #include "wiring.lua" ]]
  return wiring
end

--Start event based logic
if Controls then
  --[[ #include "runtime.lua" ]]
end
