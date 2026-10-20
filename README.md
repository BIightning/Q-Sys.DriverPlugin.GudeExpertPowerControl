<img src="assets/logo.svg" width="300" height="auto"><br>
# Viscon Q-SYS plugin template

An empty Q-SYS plugin with the Viscon build system. The source is split into small Lua files that
`plugin.lua` joins with `#include` directives. The build compiles them into one `.qplug` file and
copies it to the Q-SYS Designer Plugins folder.

## Prerequisites

- Windows with Visual Studio Code. The build tasks are defined for Windows only.
- A POSIX `sh` on `PATH`, for example from Git for Windows. The version script uses `sh`, `grep`,
  `cut`, `sed` and `unix2dos`.
- Q-SYS Designer, to load and test the compiled plugin.

## Starting a new plugin

1. Copy this folder and rename it. The folder name becomes the subfolder in
   `Documents\QSC\Q-Sys Designer\Plugins\`.
2. In [info.lua](info.lua), set `PluginName`, `Author` and `Description`. Keep `Id = "<guid>"`: the
   first build replaces it with a new GUID.
3. In [catalog.lua](src/shared/catalog.lua), set `log_tag`, the prefix of every Debug Output line.
4. Build the plugin (see below) and commit `info.lua` with the generated `Id`.

> **Important:** Never copy the `Id` of another plugin. Q-SYS Designer identifies a plugin by its
> `Id`, so two plugins with the same `Id` replace each other.

## Building the plugin

1. Open the plugin folder in Visual Studio Code.
2. Run **Terminal > Run Build Task** (default shortcut **Ctrl+Shift+B**).
3. Select a version increment. The default is `ver_dev`.
4. Wait for the three build steps to finish.
5. In Q-SYS Designer, reload the plugin in the design.

The build task **Compile QSD Plugin** runs three steps in sequence:

| Step | Task label | Script | Result |
| --- | --- | --- | --- |
| 1 | `-` | `plugincompile/compile_plugin.sh <increment>` | Updates `BuildVersion` in `info.lua`. Generates a plugin ID when `Id` is `<guid>`. |
| 2 | `--` | `plugincompile/compile_plugin_named.cmd` | Resolves all `#include` directives from `plugin.lua` and writes `<Manufacturer> <PluginName> v<BuildVersion>.qplug` to the plugin folder. |
| 3 | `Compile QSD Plugin` | `plugincompile/copy_plugin.cmd` | Deletes older builds from `Documents\QSC\Q-Sys Designer\Plugins\<plugin folder>\` and copies the new build there. |

### Version increments

`BuildVersion` has four numbers: `MAJOR.MINOR.FIX.DEV`.

| Increment | Effect | Example from `1.1.0.1` |
| --- | --- | --- |
| `ver_maj` | Major change. Resets the other numbers. | `2.0.0.0` |
| `ver_min` | Minor change. Resets FIX and DEV. | `1.2.0.0` |
| `ver_fix` | Bug fix. Resets DEV. | `1.1.1.0` |
| `ver_dev` | Development build. | `1.1.0.2` |
| `ver_none` | No change. | `1.1.0.1` |
| `CANCEL` | Stops the build. | — |

## Plugin structure

### Two load phases

A `.qplug` file is one Lua chunk. Q-SYS runs it in two phases:

| Phase | Who runs it | `Controls` | What runs |
| --- | --- | --- | --- |
| Design time | Q-SYS Designer | `nil` | Top-level code. Designer then calls `GetProperties`, `GetControls`, `GetControlLayout` and the other `Get*` functions. |
| Run time | The Core, or Designer in emulation | Set | Top-level code again, then the `if Controls then` block at the end of `plugin.lua`. |

Top-level code runs in both phases. Keep it free of side effects: only definitions of constants,
tables and functions.

### Include model

PLUGCC replaces each `--[[ #include "path" ]]` line with the content of the file. Paths are relative
to the plugin folder. An include is plain text substitution, so the included file runs in the scope
of the include line:

- `properties.lua` sees the local `props` of `GetProperties`.
- A file in `src/controls/` sees `ctrls` and `props` of `GetControls`.
- A file in `src/layout/` sees `layout`, `graphics`, `props` and `current_page` of
  `GetControlLayout`.
- A file in `src/runtime/` runs inside `if Controls then`.

A `local` in an included file stays visible to every later file in the same function. Wrap the
content of each layout file in its `if current_page == … then` block to keep its locals to that
page.

> **Note:** Lua allows 200 locals per function. All layout files share one function, so keep page
> locals inside the page block.

### Where code goes

| Folder | Included in | Phase | Content | Must not |
| --- | --- | --- | --- | --- |
| `src/shared/` | Top level of `plugin.lua` | Both | Constants, names, page list, pure helpers (`util`, `catalog`, `control_kit`, `layout_kit`) | Touch `Controls`, `Properties` or `Timer` |
| `src/controls/` | `GetControls` | Design time | Control declarations with `control_kit` | Hold logic or state |
| `src/layout/` | `GetControlLayout` | Design time | One `if current_page == … then` block, placed with `layout_kit` | Lay out other pages |
| `src/runtime/` | `if Controls then` | Run time | Event handlers, timers, connections | Run before its dependencies |

Each page has one file with the same name in each of `src/controls/`, `src/layout/` and
`src/runtime/`. For example, the **Main** page is `src/controls/main.lua`, `src/layout/main.lua`
and `src/runtime/main.lua`.

### Names in one place

Design time and run time are separate calls, so they share nothing except the top-level code. Put
every control name, property name, page name, count and limit in
[catalog.lua](src/shared/catalog.lua). The controls, the layout and the runtime then read the same
value and cannot disagree.

A control with `Count` > 1 is a group. Q-SYS names its elements `"<Name> 1"` … `"<Name> N"`. Build
these names with `indexed_name(name, index)`. A control with `Count = 1` is one object named
`"<Name>"`, and `Controls["<Name>"][1]` raises an error.

### Runtime modules

- Each runtime file creates one global table, named after the file, for example `example = {}`.
- [runtime.lua](runtime.lua) includes the files in dependency order. Top-level statements of a file
  can use only the files included before it.
- Bind control handlers in a `startup.on_ready(function() … end)` hook, not at the top level of the
  file. [boot.lua](src/runtime/boot.lua) is included last and runs every hook, so a handler can
  call any module.
- Read properties from `config.values["<Property Name>"]`. At run time, `props` does not exist, and
  `Properties` has a different form on some firmware.
- Print with `log.tx`, `log.rx`, `log.fn` and `log.error`, not with `print`, so that **Debug Print**
  controls the output.
- Store a `Timer` in a module table, not in a `local` of a function. The garbage collector stops a
  timer that nothing references.

The Q-SYS behavior details are in the `qsys-plugin` skill in
[.claude/skills/qsys-plugin/](.claude/skills/qsys-plugin/SKILL.md).

## Adding a page

The example uses the page name `Example`. It follows [Plugin structure](#plugin-structure).

1. In [catalog.lua](src/shared/catalog.lua), add `example_page_name = "Example";` and add it to
   `PageNames`.
2. Create `src/controls/example.lua` and declare the controls with `control_kit`.
3. Add `--[[ #include "src/controls/example.lua" ]]` to [controls.lua](controls.lua).
4. Create `src/layout/example.lua`. Wrap the content in
   `if current_page == example_page_name then … end` and place the controls with `layout_kit`.
5. Add `--[[ #include "src/layout/example.lua" ]]` to [layout.lua](layout.lua).
6. Create `src/runtime/example.lua`. Bind the control handlers in `startup.on_ready`.
7. Add `--[[ #include "src/runtime/example.lua" ]]` to [runtime.lua](runtime.lua) before the
   `boot.lua` line.

## Debugging

1. In Q-SYS Designer, turn on the debug info display. Designer then sets `plugin_show_debug`, and
   [rectify_properties.lua](rectify_properties.lua) shows the **Debug Print** property.
2. Set **Debug Print** on the plugin. `log.tx`, `log.rx` and `log.fn` print only at the matching
   level. `log.error` always prints.
3. Open the plugin's **Debug Output** window in Q-SYS Designer while the design runs.

## Repository layout

```text
plugin.lua              Plugin entry point; includes every other file
info.lua                PluginInfo, PluginName and BuildVersion
properties.lua          Design-time properties
rectify_properties.lua  Hides and shows properties
pages.lua               Builds the page list from PageNames
controls.lua            Includes src/controls/*.lua
layout.lua              Includes src/layout/*.lua
runtime.lua             Includes src/runtime/*.lua in dependency order
components.lua          Optional internal components
pins.lua                Optional pins without a control
wiring.lua              Optional wiring of internal components
src/shared/             Code shared by design time and runtime
src/controls/           Control declarations per page
src/layout/             UI layout per page
src/runtime/            Runtime logic
plugincompile/          Build tools (PLUGCC compiler and scripts)
EzSVG.md                EzSVG reference
.claude/skills/         Claude Code skills for Q-SYS plugin work and documentation
```
