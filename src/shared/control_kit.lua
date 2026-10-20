-- Control factories so src/controls/*.lua stay declarative.
-- Included at plugin top level; consumed inside GetControls.

control_kit = {};

function control_kit.add(ctrls, base, opts)
  merge_into(base, opts);
  table.insert(ctrls, base);
  return base;
end

function control_kit.text(ctrls, name, count, opts)
  return control_kit.add(ctrls, {
    Name = name,
    ControlType = "Text",
    TextType = "Text",
    Count = count,
    UserPin = true,
    PinStyle = "Both"
  }, opts);
end

function control_kit.readout(ctrls, name, count, opts)
  return control_kit.add(ctrls, {
    Name = name,
    ControlType = "Indicator",
    IndicatorType = "Text",
    Count = count,
    UserPin = true,
    PinStyle = "Output"
  }, opts);
end

function control_kit.led(ctrls, name, count, opts)
  return control_kit.add(ctrls, {
    Name = name,
    ControlType = "Indicator",
    IndicatorType = "Led",
    Count = count,
    UserPin = true,
    PinStyle = "Output"
  }, opts);
end

-- Numeric readouts must be Knobs: ControlType "Indicator"/"Meter" ignores ControlUnit and
-- forces a dB scale, which clamps real values to -100..+20.
function control_kit.number(ctrls, name, count, unit, min_value, max_value, opts)
  return control_kit.add(ctrls, {
    Name = name,
    ControlType = "Knob",
    ControlUnit = unit,
    Min = min_value,
    Max = max_value,
    Count = count,
    UserPin = true,
    PinStyle = "Output"
  }, opts);
end

function control_kit.knob(ctrls, name, count, unit, min_value, max_value, opts)
  return control_kit.add(ctrls, {
    Name = name,
    ControlType = "Knob",
    ControlUnit = unit,
    Min = min_value,
    Max = max_value,
    Count = count,
    UserPin = true,
    PinStyle = "Both"
  }, opts);
end

function control_kit.toggle(ctrls, name, count, opts)
  return control_kit.add(ctrls, {
    Name = name,
    ControlType = "Button",
    ButtonType = "Toggle",
    Count = count,
    UserPin = true,
    PinStyle = "Both"
  }, opts);
end

function control_kit.trigger(ctrls, name, count, opts)
  return control_kit.add(ctrls, {
    Name = name,
    ControlType = "Button",
    ButtonType = "Trigger",
    Count = count,
    UserPin = true,
    PinStyle = "Input"
  }, opts);
end
