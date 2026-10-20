---
name: qsys-plugin
description: Writing or debugging Q-SYS `.qplug` plugin code. Covers the two-phase load model, GetControls/GetControlLayout schemas, control value semantics, graphics, run-time styling, and the Q-SYS Lua extension globals (Timer, HttpClient, TcpSocket, Crypto, Component, rapidjson, EzSVG and the rest). Use when editing a .qplug file, designing a plugin's controls or layout, or answering "how does Q-SYS behave here".
metadata:
  verified-against: Q-SYS Designer, emulation mode, September 2026
---

# Q-SYS plugin development

Facts about how Q-SYS behaves. Entries marked *(Verified)* were tested directly
in Designer; everything else is from QSC documentation.

**Accuracy rule:** QSC's own reference contradicts QSC's own example code in
several places, and testing showed the reference wrong at least four times. If
this file and a QSC doc disagree, this file was tested. If neither covers it,
say so rather than guessing.

## The two-phase load

A `.qplug` is one Lua chunk loaded twice.

| Phase | `Controls` / `Properties` | What runs |
| --- | --- | --- |
| Design | `nil` | Only the `Get*` definitions. The host then calls them |
| Run | installed **before** the chunk loads | Everything, including the runtime block |

Guard the runtime block. Every real plugin does:

```lua
if Controls then
  Controls.go.EventHandler = function(c) ... end
end
```

A design-time-only check never executes that block, so an error inside it
surfaces only when the plugin actually runs.

## Reserved functions

All take the property table `props`; all are optional.

| Function | Returns | Notes |
| --- | --- | --- |
| `PluginInfo` | table | `Name`, `Version`, `Id`, `Author`, `Description` |
| `GetProperties()` | array | No arguments |
| `RectifyProperties(props)` | props | May mutate in place |
| `GetPrettyName(props)` | string | |
| `GetColor(props)` | `{r,g,b}` | Schematic block colour |
| `GetPages(props)` | `[{name=...}]` | |
| `GetControls(props)` | array | |
| `GetControlLayout(props)` | `layout, graphics` | **Called once per page.** Read `props["page_index"].Value` |
| `GetPins`, `GetComponents`, `GetWiring` | array | Pins, DSP components, internal wiring |

`props` entries are reachable **both** by 1-based index and by name; both reach
the same sub-table. `page_index` and `plugin_show_debug` are injected implicitly
— a plugin never declares them, and code that reads them unguarded will
`nil`-deref if a host omits them.

## Controls

```lua
{ Name = "gain", ControlType = "Knob", ControlUnit = "Integer",
  Min = 0, Max = 100, Count = 1, PrettyName = "Audio~Gain",
  UserPin = true, PinStyle = "Both" }
```

| Field | Values |
| --- | --- |
| `ControlType` | `Text`, `Indicator`, `Knob`, `Button` |
| `TextType` | `Text`, `TextArea`, `ComboBox` |
| `IndicatorType` | `Text`, `Led`, `Meter`, `Status` |
| `ButtonType` | `Momentary`, `Toggle`, `Trigger` |
| `ControlUnit` | `Integer`, `Float`, `Percent`, `Position`, `Seconds`, `Hertz`, `Decibel`, `Pan` |
| `Count` | `> 1` makes it a group |
| `PrettyName` | `~` separates pin folders |
| `PinStyle` | `Input`, `Output`, `Both` |

Element *n* of a group is addressed as `"<Name> <n>"` — in layout keys and saved
designs alike.

## Top five things that break code

1. **`Count == 1` does not accept `[1]`.** `Controls.foo[1]` raises
   `Property '1' does not exist`. Use `Controls.foo`. A group returns `nil` for
   an out-of-range index instead of raising, so `ipairs` terminates normally.
   Detect the group case by `pcall`-ing the index.
2. **Layout `Color` is a table; run-time `.Color` is a string.** `{0,200,0}` in
   `GetControlLayout`, `"#00C800"` at run time. Passing a table at run time
   **raises**. *(Verified)*
3. **Do not scope a `Timer` locally.** Lua's GC will collect it while it is
   still in use.
4. **`rapidjson` JSON `null` is not `nil`.** It decodes to a sentinel table, so
   `decoded.field or ""` yields the sentinel. Compare against `rapidjson.null`
   by identity, or coerce by type.
5. **An `Indicator`/`Meter` forces a −100..+20 dB scale**, ignoring
   `ControlUnit`. Use a `Knob` for numeric readouts.

Also: a numeric control initialises to `Min`, not zero. A script write does not
run that control's own `EventHandler` — only user and link writes do, which is
what stops a handler that refreshes a mirror control from recursing. An
`HttpClient` transport failure reports `code = 0` with a non-empty `err`.

## Layout entries

Common: `Position`, `Size`, `Style`, `PrettyName`, `Color`, `TextColor`,
`FontSize`, `Font`, `FontStyle`, `HTextAlign`, `VTextAlign`, `IsReadOnly`,
`Margin`, `Padding`, `StrokeColor`, `StrokeWidth`, `CornerRadius`/`Radius`,
`ZOrder`, `ClassName`.

`Style`: `Fader`, `Knob`, `Button`, `Text`, `Meter`, `Led`, `ListBox`,
`ComboBox`, `Media`, `None` — plus `Indicator` and `TextBox`, which QSC's own
example uses and its reference omits.

Button-only: `ButtonStyle` (`Toggle`, `Momentary`, `Trigger`, `StateTrigger`,
`On`, `Off`, `Custom`), `Legend`, `OffColor`, `UnlinkOffColor`,
`ButtonVisualStyle`, `IconColor`, `CustomButtonUp`/`Down`.
Text-only: `TextBoxStyle` (`Normal`, `Meter`, `NoBackground`).

## Graphics

`Type`: `Label`, `Text`, `GroupBox`, `Header`, `Image`, `Svg`, `MeterLegend`.

- `Text` is **undocumented but official** — QSC's own examples use it
  everywhere, and it is identical to `Label`. *(Verified)*
- `Image` and `Svg` carry their bytes in an **`Image`** field: base64 JPG, PNG
  or SVG.
- `MeterLegend` draws a dB scale from −80 to +20. *(Verified)*
- `GroupBox` defaults to `StrokeWidth = 0` — no border. *(Verified)*

## Verified visual behaviour

Tested in Designer. These contradict QSC documentation.

| Behaviour | Truth |
| --- | --- |
| `IsInvisible` in a **layout** entry | **Does nothing.** Hide a control by sizing it 1×1 or 5×5 — the standard idiom |
| `IsInvisible` at **run time** | Works: `Controls.foo.IsInvisible = true` |
| `WordWrap` on a button legend | **Ignored**, despite being documented. Legend clips |
| `WordWrap` on a Text control | Works |
| `WordWrap` on a graphic | Works, though undocumented |
| Unwrapped text | **Clips**; does not overflow |
| `UnlinkOffColor = false` | Off state is a **darkened `Color`** |
| `UnlinkOffColor = true` | Off state is `OffColor` |
| `IsBold` | Documented, but **no visible effect**. Use `FontStyle` |
| Unknown `Style` | Silently becomes a text control |
| Unknown graphic `Type` | Silently becomes centred text |
| Type and style names | Case-insensitive: `LED`, `Groupbox` both work |
| `Margin` / `Padding` | Standard box model. Margin outside the background, padding inside. Large values collapse the content box and the text vanishes |
| `CssClass` at run time | Accepted and ignored |
| `RampTime` on a text control | Accepted, no effect |
| Focusing a text control | Selects the entire contents |

### Run-time colour

```lua
Controls.result.Color = "#00C800"   -- hex
Controls.result.Color = "Green"     -- CSS name (its own palette, not the hex)
Controls.result.Color = "!00FFFF"   -- HSV, hue/sat/val
Controls.result.Color = {0,200,0}   -- RAISES
```

An unparseable string resolves to **black**, not an error. Reading `.Color`
returns an **empty string**. Applies to buttons and text controls alike.
*(All verified)*

### Icon legends

A `Legend` assigned JSON draws an image on the control face:

```lua
Controls.preview.Legend = rapidjson.encode({
  DrawChrome = false,                       -- false hides the button face
  IconData = Crypto.Base64Encode(svg),      -- SVG or PNG
})
```

Scales to the control, preserves aspect ratio, centres, and replaces the legend
text. *(Verified)*

## Lua extension globals

Always available; no `require`. Full signatures in
[references/lua-api.md](references/lua-api.md).

| Global | For |
| --- | --- |
| `Timer` | `Timer.New()`, `Timer.CallAfter(fn, secs)`, `Timer.Now()` |
| `HttpClient` | `Get`, `Post`, `Put`, `Delete`, `Download`, `Upload` |
| `TcpSocket`, `TcpSocketServer`, `UdpSocket`, `WebSocket` | Sockets, with TLS on TCP |
| `Crypto` | Base64, MD5, SHA, HMAC, PBKDF2, AES |
| `Component` | Reach controls in another named component |
| `Design`, `System`, `Network`, `Log` | Host and design metadata |
| `Ping` | ICMP |
| `Notifications` | Publish/subscribe between scripts |
| `NamedControl`, `Uci`, `Snapshot` | Named Controls, UCI state, snapshots |
| `SerialPorts`, `Ssh`, `SNMP`, `Email`, `Dante` | Transports and hardware |
| `EzSVG` | SVG generation — pairs with `IconData` |

Reached with `require`: `rapidjson`, `json`, `lpeg`, `bitstring`, `LuaXML`,
`date`, `QRCode`.

## References

Load only what the task needs.

| File | Contents |
| --- | --- |
| [references/lua-api.md](references/lua-api.md) | Every global's members, socket properties and events, with signatures |
| [references/layout-graphics.md](references/layout-graphics.md) | The complete layout and graphics field schema, with defaults |

QSC's own documentation is the fallback for anything neither file covers:
Q-SYS Developer Help for `GetControlLayout` and the reserved functions, and
Q-SYS Help for the Lua extension pages.

## Testing a plugin

Install into the plugins folder, then reload Designer:

- Windows: `Documents\QSC\Q-Sys Designer\Plugins\`
- macOS: `~/Documents/QSC/Q-Sys Designer/Plugins/`

Emulation mode exercises design time, layout, graphics and the runtime block
without a Core. `System.IsEmulating` is the flag a plugin checks to fake device
feedback while offline — it is a plain boolean field, so `if System.IsEmulating
then` works, but note that a stubbed `System` on a non-Q-SYS host may expose it
as a truthy callable instead.
