log = {};
log.level = "None";

function log.set_level(level)
  log.level = level or "None";
end

function log.enabled(kind)
  if log.level == "None" then
    return false;
  end
  if log.level == "All" then
    return true;
  end
  if kind == "tx" then
    return log.level == "Tx" or log.level == "Tx/Rx";
  end
  if kind == "rx" then
    return log.level == "Rx" or log.level == "Tx/Rx";
  end
  if kind == "fn" then
    return log.level == "Function Calls";
  end
  return false;
end

function log.write(kind, message)
  if not log.enabled(kind) then
    return;
  end
  print("[" .. log_tag .. "][" .. kind .. "] " .. message);
end

function log.tx(message)
  log.write("tx", message);
end

function log.rx(message)
  log.write("rx", message);
end

function log.fn(message)
  log.write("fn", message);
end

function log.error(message)
  print("[" .. log_tag .. "][error] " .. message);
end
