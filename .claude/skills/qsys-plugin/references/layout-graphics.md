# Layout and graphics schema

The complete `GetControlLayout` schema, with defaults and verified behaviour.

`GetControlLayout(props)` returns two values: a `layout` table keyed by control
name, and a `graphics` array. It is called **once per page**; read
`props["page_index"].Value` to know which.

```lua
function GetControlLayout(props)
  local layout, graphics = {}, {}
  if props["page_index"].Value == 1 then
    layout["gain"] = { Style = "Knob", Position = {10,10}, Size = {36,36} }
    graphics[#graphics+1] = { Type = "Text", Text = "Gain",
                              Position = {10,50}, Size = {36,16} }
  end
  return layout, graphics
end
```

Entries marked *(Verified)* were tested directly in Designer and contradict, or
are absent from, QSC's reference.

## Layout entries — common fields

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `Position` | `{x,y}` | required | |
| `Size` | `{x,y}` | required | |
| `Style` | string | required | See below |
| `PrettyName` | string | — | `~` separates pin folders |
| `Color` | `{r,g,b,a}` | — | Alpha optional |
| `TextColor` | `{r,g,b,a}` | — | |
| `FontSize` | integer | — | Points |
| `Font` | string | `Roboto` | One of eleven families |
| `FontStyle` | string | `Regular` | Per-family; produces a real face change |
| `IsBold` | boolean | — | **No visible effect.** Use `FontStyle` *(Verified)* |
| `HTextAlign` | `Center`\|`Left`\|`Right` | `Center` | |
| `VTextAlign` | `Center`\|`Top`\|`Bottom` | `Center` | |
| `IsReadOnly` | boolean | — | Blocks run-time edits |
| `Margin` | integer | `0` | Outside the background |
| `Padding` | integer | `1` | Inside the background |
| `StrokeColor` | `{r,g,b,a}` | black | |
| `StrokeWidth` | integer | `1` | |
| `Radius` / `CornerRadius` | integer | — | Both spellings accepted |
| `ZOrder` | signed integer | — | Effect unverified |
| `ClassName` | string | — | Default CSS class when dragged onto a UCI |

Colours here are **tables**. The run-time `.Color` property is a **string** and
raises on a table.

`Margin` and `Padding` follow the standard box model. Values large relative to
the control's height collapse the content box — margin then hides the
background as well, padding keeps the background but loses the text.
*(Verified)*

## Layout entries — style-specific

| Field | Applies to | Values | Notes |
| --- | --- | --- | --- |
| `ButtonStyle` | Button | `Toggle`, `Momentary`, `Trigger`, `StateTrigger`, `On`, `Off`, `Custom` | `StateTrigger` behaves like a momentary *(Verified)* |
| `Legend` | Button | string | Also accepts `IconData` JSON |
| `OffColor` | Button | `{r,g,b,a}` | Only used when `UnlinkOffColor` is true |
| `UnlinkOffColor` | Button | boolean | See below |
| `WordWrap` | Button | boolean | **Ignored.** The legend clips *(Verified)* |
| `ButtonVisualStyle` | Button | `Flat`, `Gloss` | `Gloss` is the default |
| `CustomButtonUp` / `Down` | Button | string | `Custom` button style only |
| `IconColor` | Button | `{r,g,b,a}` | Icon tint |
| `WordWrap` | Text | boolean | Works *(Verified)* |
| `TextBoxStyle` | Text | `Normal`, `Meter`, `NoBackground` | |
| `ShowTextbox` | Fader, Meter | boolean | Fader `false`, Meter `true` |
| `MeterStyle` | Meter | `Level`, `Reduction`, `Gain`, `Standard` | Required on meters |
| `BackgroundColor` | Meter | `{r,g,b,a}` | |

### `UnlinkOffColor` (verified)

| Value | Off state |
| --- | --- |
| `false` or absent | A **darkened `Color`** |
| `true` | `OffColor` |

Setting `OffColor` without `UnlinkOffColor = true` has no effect.

## `Style` values

| Value | In QSC's reference | In QSC's examples | Renders as |
| --- | --- | --- | --- |
| `Fader`, `Knob`, `Button`, `Text`, `Meter`, `Led`, `ListBox`, `ComboBox`, `None` | Yes | Yes | As named |
| `Media` | Yes | — | A white surface; Designer calls it "Media Display" *(Verified)* |
| `Indicator` | No | Yes | A non-interactive grey box *(Verified)* |
| `TextBox` | No | Yes | An interactive text box *(Verified)* |

An unknown `Style` silently becomes a **text control** — no error, no
placeholder. *(Verified)*

Matching is case-insensitive: `LED` works where `Led` is documented.
*(Verified)*

## Graphics — common fields

| Field | Type | Notes |
| --- | --- | --- |
| `Position` | `{x,y}` | required |
| `Size` | `{x,y}` | required |
| `Type` | string | required |
| `ZOrder` | signed integer | Effect unverified |

## Graphic `Type` values

| Value | In QSC's reference | Notes |
| --- | --- | --- |
| `Label` | Yes | |
| `Text` | **No** | Used throughout QSC's own examples, and identical to `Label` *(Verified)* |
| `GroupBox` | Yes | |
| `Header` | Yes | A titled band |
| `Image`, `Svg` | Yes | Bytes go in the `Image` field |
| `MeterLegend` | Community docs only | Draws a dB scale −80 to +20 *(Verified)* |

An unknown `Type` silently becomes **centred text**. *(Verified)*

## Graphics — type-specific

| Field | Applies to | Default | Notes |
| --- | --- | --- | --- |
| `Text` | Label, Text, GroupBox, Header | — | Title or caption |
| `Color` | all text-bearing | — | Text colour |
| `Fill` | Label, Text, GroupBox | clear | |
| `StrokeColor` | Label, Text, GroupBox | black | |
| `StrokeWidth` | Label, Text | `1` | Range 0–64 |
| `StrokeWidth` | GroupBox | **`0`** | No border unless set *(Verified)* |
| `Radius` / `CornerRadius` | Label, Text, GroupBox | — | |
| `FontSize` | all text-bearing | — | |
| `Font` | all text-bearing | `Roboto` | |
| `FontStyle` | all text-bearing | `Regular` | |
| `IsBold` | all text-bearing | — | |
| `HTextAlign` | all text-bearing | `Right` for Label and Header | |
| `VTextAlign` | Label, Text | `Bottom` | |
| `Margin`, `Padding` | Label, Text | `0`, `1` | |
| `WordWrap` | any text-bearing | — | Undocumented, but works *(Verified)* |
| `Image` | Image, Svg | required | Base64 JPG, PNG or SVG |

```lua
{ Type = "Svg", Image = "PHN2ZyB4bWxu...", Position = {8,8}, Size = {60,60} }
```

## Fonts

Eleven families, each with its own permitted styles: Adamina, Droid Sans, Lato,
Montserrat, Noto Serif, Open Sans, Poppins, Roboto (default), Roboto Mono,
Roboto Slab, Slabo 27px. Roboto supports Thin, Light, Regular, Italic, Medium,
Bold, Black and their italics; other families differ.

`FontStyle` produces a genuinely different face. `IsBold` does nothing.
*(Verified)*

## Hiding a control

`IsInvisible` in the **layout table does nothing**. *(Verified)* QSC's own
example plugins hide storage controls by sizing them instead:

```lua
layout["code"] = { Style = "Text", Position = {0,0}, Size = {5,5} }
```

To hide at run time, which does work:

```lua
Controls.code.IsInvisible = true
```

## Text behaviour (verified)

| Case | Behaviour |
| --- | --- |
| `WordWrap` on a Text control or graphic | Wraps |
| `WordWrap` on a button legend | Ignored |
| No wrap, text too long | **Clips** — does not overflow |
| Focusing a text control | Selects the entire contents |
