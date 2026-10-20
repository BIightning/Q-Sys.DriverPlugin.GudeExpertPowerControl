BuildVersion = "1.0.0.0" -- updated by the compiler
PluginName = "Example Plugin" -- also names the compiled .qplug file, see plugincompile/*.cmd
PluginInfo = {
  Name = "Viscon GmbH~" .. PluginName .. " v" .. BuildVersion, -- preferred format is "manufacturer~plugin name version"
  Version = BuildVersion,
  Id = "<guid>", -- replaced with a new GUID by the first build
  Author = "Viscon GmbH",
  Description = "A Q-SYS plugin template.",
  Manufacturer = "Viscon GmbH",
}
