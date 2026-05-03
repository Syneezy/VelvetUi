<div align="center">

```
██╗   ██╗███████╗██╗     ██╗   ██╗███████╗████████╗    ██╗   ██╗██╗
██║   ██║██╔════╝██║     ██║   ██║██╔════╝╚══██╔══╝    ██║   ██║██║
██║   ██║█████╗  ██║     ██║   ██║█████╗     ██║       ██║   ██║██║
╚██╗ ██╔╝██╔══╝  ██║     ╚██╗ ██╔╝██╔══╝     ██║       ██║   ██║██║
 ╚████╔╝ ███████╗███████╗ ╚████╔╝ ███████╗   ██║       ╚██████╔╝██║
  ╚═══╝  ╚══════╝╚══════╝  ╚═══╝  ╚══════╝   ╚═╝        ╚═════╝ ╚═╝
```

**A luxurious, modern, and lightweight GUI library for Roblox.**  
First-class mobile support. Zero dependencies. Built from scratch.

![Version](https://img.shields.io/badge/version-1.0.0-7b2fbe?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-c9a96e?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Roblox-e52207?style=flat-square)
![Language](https://img.shields.io/badge/language-Luau-00a2ff?style=flat-square)
![Mobile](https://img.shields.io/badge/mobile-first-48c78e?style=flat-square)

</div>

---

## What is Velvet UI?

Velvet UI is a premium GUI library for Roblox written entirely in Luau — no forks, no templates, no borrowed code. It gives script developers a clean, expressive API to build beautiful interfaces that feel polished on every device.

The philosophy is simple: **visually luxurious, performant by default, syntactically minimal.**

---

## Features

- **Signature sidebar layout** — vertical tab navigation on the left, grouped content on the right, fixed topbar with window controls on top
- **Mobile-first** — automatic device detection; sidebar collapses to icon-only on touch devices, touch targets are always ≥ 44px, keybinds hide themselves, notifications reposition
- **Scale modes** — `Auto` / `Desktop` / `Mobile` override at any time
- **Rich element set** — Button, Switch, Slider, TextField, Dropdown, ColorSelect, Keybind, Label, Paragraph
- **Per-element save/restore** — pass a `flag` string to any interactive element; values persist automatically
- **Notification system** — `Whisper()` toasts with optional action buttons, up to 3 stacked, mobile-aware positioning
- **Three animation styles** — `Calm`, `Brisk` (default), `Bouncy` — applied to open/close and tab transitions
- **Custom themes** — register any theme with `DefineTheme()`, missing tokens fall back to Midnight Velvet gracefully
- **No globals** — every window is isolated; multiple instances never conflict
- **TweenService only** — no RunService animation loops; all motion is state-driven and 60fps-safe

---

## Layout Anatomy

```
┌──────────────────────────────────────────────────────┐
│  ◈  Velvet Demo                                   ✕  │  ← Topbar (draggable)
├──────────┬───────────────────────────────────────────┤
│  🎨      │                                           │
│  Visuals │   ┌─ APPEARANCE ──────────────────────┐  │
│          │   │  Accent Colour          [ ████ ]   │  │
│  ⚔️      │   │  Theme        [ Midnight Velvet ▾] │  │
│  Gameplay│   └───────────────────────────────────┘  │
│          │                                           │
│  👤      │   ┌─ UI SCALE ────────────────────────┐  │
│  Player  │   │  Scale Mode         [ Auto      ▾] │  │
│          │   └───────────────────────────────────┘  │
│  ⚙️      │                                           │
│  Settings│                                           │
└──────────┴───────────────────────────────────────────┘
  Sidebar       Content Area
  (collapsible  (scrollable, grouped)
   on mobile)
```

---

## Installation

### Method 1 — Roblox Studio (recommended)

1. Copy the entire `VelvetUi` folder into `ReplicatedStorage` (or any location accessible from a LocalScript).
2. Make sure `init.lua` is the ModuleScript named `VelvetUi` at the root, with a `src` folder as a child containing all sub-modules.
3. Require it in a `LocalScript`:

```lua
local VelvetUi = require(game.ReplicatedStorage.VelvetUi)
```

### Method 2 — Executor / Loadstring

```lua
-- Host the files on a raw GitHub URL and loadstring them,
-- or use a file loader that respects the module structure.
-- See examples/BasicDemo.lua for usage after loading.
```

---

## Quick Start

```lua
local VelvetUi = require(game.ReplicatedStorage.VelvetUi)

-- Build a window
local window = VelvetUi:BuildWindow({
    Title      = "My Script",
    Icon       = "⚡",
    Key        = "RightShift",   -- toggle key
    SaveConfig = true,
})

-- Add a tab
local tab = window:AddTab("Settings", "⚙️")

-- Add a group
local group = tab:Group("Gameplay")

-- Add elements
tab:Switch("Speed Boost", false, function(on)
    -- your logic here
end, "my_speed")

tab:Slider("Walk Speed", 16, 100, 16, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end, "my_walkspeed")

tab:Button("Reset Character", function()
    game.Players.LocalPlayer.Character.Humanoid.Health = 0
end)

-- Show a notification
VelvetUi:Whisper({
    Title   = "Loaded",
    Message = "Script is ready.",
    Icon    = "✅",
})
```

---

## All Elements at a Glance

```lua
-- Interactive
tab:Button("Label", callback)
tab:Switch("Label", defaultBool, callback, flag?)
tab:Slider("Label", min, max, default, callback, flag?)
tab:TextField("Label", placeholder, callback, flag?)
tab:Dropdown("Label", {options}, default, callback, flag?)
tab:ColorSelect("Label", Color3, callback, flag?)
tab:Keybind("Label", "KeyName", callback, flag?)  -- auto-hidden on mobile

-- Static
tab:Label("text", icon?, Color3?)
tab:Paragraph("title", "body text")

-- Layout
tab:Group("Section Name")   -- returns Group object
tab:Line()                   -- horizontal divider
tab:Spacer(height?)          -- vertical gap
```

---

## Themes

### Using a Built-In Theme

```lua
local window = VelvetUi:BuildWindow({ Theme = "Midnight Velvet" })
```

### Defining a Custom Theme

Only override the tokens you want to change — everything else inherits from Midnight Velvet.

```lua
VelvetUi:DefineTheme("Cherry", {
    accent      = Color3.fromRGB(210, 60, 100),
    accentLight = Color3.fromRGB(230, 80, 120),
    rose        = Color3.fromRGB(255, 140, 160),
})

window:Dress("Cherry")
```

### Full Token Reference

| Token | Midnight Velvet | Role |
|---|---|---|
| `bg` | `13, 13, 18` | Window background |
| `surface` | `22, 22, 31` | Element surface |
| `card` | `28, 28, 38` | Group container |
| `sidebar` | `18, 18, 23` | Sidebar background |
| `topbar` | `16, 16, 21` | Topbar background |
| `accent` | `123, 47, 190` | Primary purple |
| `rose` | `201, 169, 110` | Secondary gold |
| `text` | `237, 232, 240` | Primary text |
| `muted` | `138, 131, 145` | Secondary text |
| `border` | `42, 42, 58` | Element borders |
| `success` | `72, 199, 142` | Positive state |
| `warning` | `255, 183, 77` | Warning state |
| `danger` | `240, 80, 80` | Destructive state |

---

## Animation Styles

```lua
window:Animate("Calm")    -- Expo easing, 0.55s — slow and silky
window:Animate("Brisk")   -- Quint easing, 0.20s — quick and clean (default)
window:Animate("Bouncy")  -- Back easing, 0.50s — slight overshoot
```

---

## Config System

Any element with a `flag` string saves its value automatically.

```lua
-- Value is saved on every change, restored on LoadConfig()
local sw = tab:Switch("Godmode", false, callback, "godmode_flag")

-- Load all saved values (typically called once at startup)
VelvetUi:LoadConfig()
```

In executor environments with file I/O (`writefile`/`readfile`): values persist to `velvet_config.json` between sessions.

In standard Roblox Studio or game sessions: values persist in-memory for the session duration.

---

## Mobile Support

Velvet UI detects the device automatically and adjusts the entire layout:

| | Desktop | Mobile |
|---|---|---|
| Sidebar | Icon + text, 168px | Icon only, 56px (tap to expand) |
| Element height | 44px | 44px (touch-safe always) |
| Keybinds | Shown | Hidden automatically |
| Notifications | Top-right | Top-centre |
| Window size | 680 × 440 | 360 × 500 |

Override at any time:

```lua
VelvetUi:SetScaleMode("Mobile")   -- force mobile layout
VelvetUi:SetScaleMode("Desktop")  -- force desktop layout
VelvetUi:SetScaleMode("Auto")     -- auto-detect (default)
```

---

## File Structure

```
VelvetUi/
├── init.lua              ← Entry point — require this
├── src/
│   ├── Core.lua          ← Window, Tab, Group, layout engine
│   ├── Elements.lua      ← All interactive and static elements
│   ├── Theme.lua         ← Theme registry and colour tokens
│   ├── Animator.lua      ← TweenService wrapper and animation presets
│   ├── Config.lua        ← Flag-based save/load system
│   └── Utils.lua         ← Device detection, factory helpers, constants
├── themes/
│   └── Midnight.lua      ← Standalone Midnight Velvet palette export
├── examples/
│   └── BasicDemo.lua     ← Full demo using every element
├── docs/
│   └── API.md            ← Complete API reference
├── LICENSE
└── README.md
```

---

## Full API Summary

```lua
-- Root
VelvetUi:BuildWindow({ Title, Icon, Theme, Key, SaveConfig }) → Window
VelvetUi:LoadConfig()
VelvetUi:DestroyAll()
VelvetUi:SetFont(Enum.Font)
VelvetUi:GetVersion() → string
VelvetUi:EnableDebugMode()
VelvetUi:SetScaleMode("Auto"|"Desktop"|"Mobile")
VelvetUi:DefineTheme(name, colorsTable)
VelvetUi:Whisper({ Title, Message, Duration, Icon, Action })

-- Window
Window:AddTab(name, icon?) → Tab
Window:Dress(themeName)
Window:Animate("Calm"|"Brisk"|"Bouncy")
Window:Show()
Window:Hide()
Window:Rename(title)

-- Tab
Tab:Group(name) → Group
Tab:Line()
Tab:Spacer(height?)
Tab:Button(text, cb) → { SetText, Lock, Unlock, Hide, Show }
Tab:Switch(name, bool, cb, flag?) → { Flip, SetState, GetState, Hide, Show }
Tab:Slider(name, min, max, def, cb, flag?) → { SetValue, GetValue, SetRange, Hide, Show }
Tab:TextField(name, placeholder, cb, flag?) → { SetText, GetText, Clear, Hide, Show }
Tab:Dropdown(name, opts, def, cb, flag?) → { Select, GetSelected, ReplaceOptions, Hide, Show }
Tab:ColorSelect(name, Color3, cb, flag?) → { SetColor, GetColor, Hide, Show }
Tab:Keybind(name, key, cb, flag?) → { Bind, GetKey, Clear, Hide, Show }
Tab:Label(text, icon?, Color3?) → { SetText, SetIcon, SetColor, Hide, Show }
Tab:Paragraph(title, body) → { Rewrite, Hide, Show }

-- Group
Group:Rename(name)
Group:Clear()
Group:Destroy()
```

---

## License

MIT License © 2025 VelvetUi Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
