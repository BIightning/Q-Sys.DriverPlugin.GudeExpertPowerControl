-- Category modules register their control bindings here; boot.lua runs them once everything exists.
startup = {};
startup.hooks = {};

function startup.on_ready(hook)
  table.insert(startup.hooks, hook);
end

function startup.run()
  for _, hook in ipairs(startup.hooks) do
    hook();
  end
end
