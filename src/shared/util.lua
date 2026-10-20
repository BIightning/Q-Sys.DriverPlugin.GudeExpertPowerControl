function merge_into(target, extra)
  if not extra then
    return target;
  end
  for key, value in pairs(extra) do
    target[key] = value;
  end
  return target;
end

function clamp(value, min_value, max_value)
  if value < min_value then
    return min_value;
  end
  if value > max_value then
    return max_value;
  end
  return value;
end

function trim(value)
  if value == nil then
    return "";
  end
  return (tostring(value):gsub("^%s*(.-)%s*$", "%1"));
end
