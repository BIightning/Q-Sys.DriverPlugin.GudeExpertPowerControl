:: %1 workspaceFolder             C:\qsys_plugins\plugin
:: %2 workspaceFolderBasename     plugin

FOR /F "tokens=*" %%g IN ('powershell "(new-object -COM Shell.Application).Namespace(0x05).Self.Path"') do (SET DocumentsFolder=%%g)

:: Ship the file under "<Manufacturer> <PluginName> v<BuildVersion>" from info.lua instead of the repo folder name
FOR /F "tokens=*" %%v IN ('powershell "(Select-String -Path '%~1\info.lua' -Pattern 'BuildVersion\s*=\s*.([\d.]+).').Matches[0].Groups[1].Value"') do (SET BuildVersion=%%v)
FOR /F "tokens=*" %%v IN ('powershell "(Select-String -Path '%~1\info.lua' -Pattern 'PluginName\s*=\s*.([^\x22]+).').Matches[0].Groups[1].Value"') do (SET PluginName=%%v)
FOR /F "tokens=*" %%v IN ('powershell "(Select-String -Path '%~1\info.lua' -Pattern 'Manufacturer\s*=\s*.([^\x22]+).').Matches[0].Groups[1].Value"') do (SET Manufacturer=%%v)
SET BaseName=%Manufacturer% %PluginName%
SET OutName=%BaseName% v%BuildVersion%

if not exist "%DocumentsFolder%\QSC\Q-Sys Designer\Plugins\%~2" mkdir "%DocumentsFolder%\QSC\Q-Sys Designer\Plugins\%~2"

:: Remove older versions of this plugin so the plugins folder doesn't accumulate stale .qplug files
DEL /F /Q "%DocumentsFolder%\QSC\Q-Sys Designer\Plugins\%~2\%BaseName% v*.qplug" 2>nul

:: COPY locks the file while it writes, so QSD cannot read a partial script on a file changed
:: notification. (TYPE ... > target did not lock and QSD sometimes loaded a half-written file.)
COPY /Y "%~1\%OutName%.qplug" "%DocumentsFolder%\QSC\Q-Sys Designer\Plugins\%~2\%OutName%.qplug"
