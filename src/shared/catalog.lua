-- Single source of truth for names, counts and constants.
-- Included at plugin top level so design-time and runtime code cannot drift apart.

-- Prefix of every Debug Output line, as "[<log_tag>][<kind>] message".
log_tag = "plugin";

prop_debug = "Debug Print";

main_page_name = "Main";

-- Page order in Q-SYS Designer.
PageNames = { main_page_name };

function indexed_name(base, index)
  return base .. " " .. index;
end
