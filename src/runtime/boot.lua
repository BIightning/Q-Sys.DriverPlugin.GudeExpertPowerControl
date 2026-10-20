-- Runs last so every module has registered its startup hooks first.
startup.run();

log.fn(PluginName .. " ready");
