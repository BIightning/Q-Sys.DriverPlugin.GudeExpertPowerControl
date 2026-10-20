:: %1 workspaceFolder      C:\qsys_plugins\plugin
:: %2 pluginLuaPath        C:\qsys_plugins\plugin\plugin.lua

:: Compile under "<Manufacturer> <PluginName> v<BuildVersion>" from info.lua instead of the repo folder name
FOR /F "tokens=*" %%v IN ('powershell "(Select-String -Path '%~1\info.lua' -Pattern 'BuildVersion\s*=\s*.([\d.]+).').Matches[0].Groups[1].Value"') do (SET BuildVersion=%%v)
FOR /F "tokens=*" %%v IN ('powershell "(Select-String -Path '%~1\info.lua' -Pattern 'PluginName\s*=\s*.([^\x22]+).').Matches[0].Groups[1].Value"') do (SET PluginName=%%v)
FOR /F "tokens=*" %%v IN ('powershell "(Select-String -Path '%~1\info.lua' -Pattern 'Manufacturer\s*=\s*.([^\x22]+).').Matches[0].Groups[1].Value"') do (SET Manufacturer=%%v)
SET OutName=%Manufacturer% %PluginName% v%BuildVersion%

"%~dp0PLUGCC.exe" "%OutName%" "%~2"
