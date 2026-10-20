config = {};

-- Properties arrives as an array of { Name, Value } in most firmware but keyed by name in some.
function config.read_properties()
  local map = {};
  if Properties == nil then
    return map;
  end
  for key, entry in pairs(Properties) do
    if type(entry) ~= "table" then
      map[key] = entry;
    elseif entry.Name ~= nil then
      map[entry.Name] = entry.Value;
    else
      map[key] = entry.Value;
    end
  end
  return map;
end

config.values = config.read_properties();

log.set_level(config.values[prop_debug]);
