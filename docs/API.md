# Velvet UI — API Reference

> Version 1.0.0 · MIT License

---

## Table of Contents

1. [Setup](#setup)
2. [Velvet (Root API)](#velvet-root-api)
3. [Window](#window)
4. [Tab](#tab)
5. [Group](#group)
6. [Elements — Interactive](#elements--interactive)
7. [Elements — Static](#elements--static)
8. [Notifications](#notifications)
9. [Themes](#themes)
10. [Animation Styles](#animation-styles)
11. [Config / Save System](#config--save-system)
12. [Device & Scale Modes](#device--scale-modes)

---

## Setup

```lua
-- Place VelvetUi folder in ReplicatedStorage (or wherever suits your project).
local VelvetUi = require(game.ReplicatedStorage.VelvetUi)
```

That's it. No additional setup required.

---

## Velvet (Root API)

The root module returned by `require`. All methods are called with `:`.

---

### `Velvet:BuildWindow(opts)` → `Window`

Creates a new GUI window and returns the Window control object.

| Field | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"Velvet UI"` | Text shown in the topbar |
| `Icon` | string | `"◈"` | Emoji or Unicode icon in the topbar |
| `Theme` | string | `"Midnight Velvet"` | Theme name to apply |
| `Key` | string | `nil` | `Enum.KeyCode.Name` to toggle the window |
| `SaveConfig` | bool | `false` | Auto-call `LoadConfig` after building |

```lua
local win = VelvetUi:BuildWindow({
    Title      = "My Script",
    Icon       = "⚡",
    Theme      = "Midnight Velvet",
    Key        = "RightShift",
    SaveConfig = true,
})
```

---

### `Velvet:LoadConfig()`

Reads all saved flag values and calls the registered element callbacks,
restoring the UI to its last known state.

Call this after all elements have been added, or pass `SaveConfig = true` to `BuildWindow`.

---

### `Velvet:DestroyAll()`

Destroys every active Velvet window and clears internal window references.

---

### `Velvet:SetFont(fontId)`

Overrides the font for all text elements across all windows.

```lua
VelvetUi:SetFont(Enum.Font.SourceSansSemibold)
```

---

### `Velvet:GetVersion()` → `string`

Returns the library version string, e.g. `"1.0.0"`.

---

### `Velvet:EnableDebugMode()`

Enables verbose logging to the Roblox output console.

---

### `Velvet:SetScaleMode(mode)`

Controls how Velvet determines layout sizing.

| Mode | Behaviour |
|---|---|
| `"Auto"` | Detects device automatically (default) |
| `"Desktop"` | Forces desktop sizing regardless of device |
| `"Mobile"` | Forces mobile sizing (compact sidebar, larger touch targets) |

Call before `BuildWindow` to apply to new windows.

---

### `Velvet:DefineTheme(name, colorsTable)`

Register a custom theme. Any colour token not provided falls back to Midnight Velvet.

```lua
VelvetUi:DefineTheme("Crimson", {
    accent      = Color3.fromRGB(200, 40, 70),
    accentLight = Color3.fromRGB(220, 60, 90),
    rose        = Color3.fromRGB(255, 130, 150),
})
```

See [Themes](#themes) for the full list of colour tokens.

---

### `Velvet:Whisper(opts)`

Show a toast notification. See [Notifications](#notifications).

---

## Window

Object returned by `Velvet:BuildWindow(...)`.

---

### `Window:AddTab(name, icon?)` → `Tab`

Add a navigation tab to the sidebar. Returns the Tab object used to add content.

```lua
local tab = window:AddTab("Combat", "⚔️")
```

- `name` — Display label (shown on desktop, hidden on collapsed mobile).
- `icon` — Optional emoji/Unicode shown left of the label (and alone on mobile).

The first tab added is automatically made active.

---

### `Window:Dress(themeName)`

Switch the window's active theme by name.

```lua
window:Dress("Cherry Velvet")
```

> Note: Full re-theming of existing elements requires a window rebuild. `Dress` updates the window chrome (topbar, sidebar, background) immediately.

---

### `Window:Animate(style)`

Set the animation preset for open/close and tab transitions.

```lua
window:Animate("Calm")    -- slow, gentle
window:Animate("Brisk")   -- fast, clean (default)
window:Animate("Bouncy")  -- Back easing with slight overshoot
```

---

### `Window:Show()`

Reveal the window with the current animation style.

---

### `Window:Hide()`

Dismiss the window with the current animation style.

---

### `Window:Rename(title)`

Update the topbar title text in-place.

```lua
window:Rename("My Script v2")
```

---

## Tab

Object returned by `Window:AddTab(...)`.

---

### `Tab:Group(name)` → `Group`

Create a labelled section container. Elements added after this call belong to this group until a new one is created.

```lua
local group = tab:Group("Movement")
```

---

### `Tab:Line()`

Insert a thin horizontal divider line.

---

### `Tab:Spacer(height?)`

Insert vertical empty space. Default height: `16`.

---

### Element shorthand methods

All element methods are available directly on `Tab`. They add to the most recently created Group. If no Group has been created yet, a default `"General"` group is created automatically.

See [Elements — Interactive](#elements--interactive) and [Elements — Static](#elements--static) for full signatures.

---

## Group

Object returned by `Tab:Group(name)`.

---

### `Group:Rename(name)`

Change the group's header label.

---

### `Group:Clear()`

Remove all elements inside the group while keeping the group container.

---

### `Group:Destroy()`

Remove the group and all its elements entirely.

---

## Elements — Interactive

All interactive elements accept an optional `flag` string as their last argument. When provided, the element's value is automatically saved and restored via the Config system.

---

### `Tab:Button(text, callback)` → ElementControl

A standard clickable button.

```lua
local btn = tab:Button("Teleport", function()
    -- teleport logic
end)
```

**Methods:**

| Method | Description |
|---|---|
| `btn.SetText(str)` | Change button label |
| `btn.Lock()` | Disable interaction (muted appearance) |
| `btn.Unlock()` | Re-enable interaction |
| `btn.Hide()` | Hide the element |
| `btn.Show()` | Show the element |

---

### `Tab:Switch(name, state, callback, flag?)` → ElementControl

A toggle on/off switch.

```lua
local sw = tab:Switch("Godmode", false, function(enabled)
    -- apply enabled state
end, "my_godmode")
```

**Methods:**

| Method | Description |
|---|---|
| `sw.Flip()` | Toggle current state |
| `sw.SetState(bool)` | Set state without firing callback |
| `sw.GetState()` → `bool` | Read current state |
| `sw.Hide()` / `sw.Show()` | Visibility |

---

### `Tab:Slider(name, min, max, default, callback, flag?)` → ElementControl

A draggable numeric slider. Works with mouse and touch.

```lua
local sl = tab:Slider("Walk Speed", 16, 100, 16, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end, "my_walkspeed")
```

**Methods:**

| Method | Description |
|---|---|
| `sl.SetValue(num)` | Set value programmatically |
| `sl.GetValue()` → `number` | Read current value |
| `sl.SetRange(min, max)` | Change min/max limits |
| `sl.Hide()` / `sl.Show()` | Visibility |

---

### `Tab:TextField(name, placeholder, callback, flag?)` → ElementControl

A text input field. Callback fires on `FocusLost` with `(text, submitted)`.

```lua
local tf = tab:TextField("Player Name", "Enter name…", function(text, enter)
    if enter then print("Submitted:", text) end
end, "my_name")
```

**Methods:**

| Method | Description |
|---|---|
| `tf.SetText(str)` | Set field content |
| `tf.GetText()` → `string` | Read current content |
| `tf.Clear()` | Clear the field |
| `tf.Hide()` / `tf.Show()` | Visibility |

---

### `Tab:Dropdown(name, options, default, callback, flag?)` → ElementControl

A selection dropdown. On mobile the popup opens in-place above other elements.

```lua
local dd = tab:Dropdown("Team", {"Red", "Blue", "Green"}, "Red", function(choice)
    print("Team:", choice)
end, "my_team")
```

**Methods:**

| Method | Description |
|---|---|
| `dd.Select(name)` | Select an option by label |
| `dd.GetSelected()` → `string` | Read current selection |
| `dd.ReplaceOptions(list)` | Swap the options list |
| `dd.Hide()` / `dd.Show()` | Visibility |

---

### `Tab:ColorSelect(name, default, callback, flag?)` → ElementControl

An HSV colour picker with swatch preview.

```lua
local cs = tab:ColorSelect("Highlight", Color3.fromRGB(255, 100, 50), function(c)
    print("Colour:", c)
end)
```

**Methods:**

| Method | Description |
|---|---|
| `cs.SetColor(Color3)` | Set colour programmatically |
| `cs.GetColor()` → `Color3` | Read current colour |
| `cs.Hide()` / `cs.Show()` | Visibility |

---

### `Tab:Keybind(name, defaultKey, callback, flag?)` → ElementControl

A keyboard binding element. Click to rebind. **Automatically hidden on mobile.**

```lua
local kb = tab:Keybind("Sprint Key", "LeftShift", function(key)
    print("Sprint key:", key)
end, "my_sprint_key")
```

**Methods:**

| Method | Description |
|---|---|
| `kb.Bind(key)` | Set key by `KeyCode.Name` string |
| `kb.GetKey()` → `string` | Read current key name |
| `kb.Clear()` | Reset to `"None"` |
| `kb.Hide()` / `kb.Show()` | Visibility |

---

## Elements — Static

---

### `Tab:Label(text, icon?, color?)` → ElementControl

A single-line text label. Useful for section notes or info lines.

```lua
tab:Label("Hover over elements for tooltips.", "ℹ️", Color3.fromRGB(100, 100, 120))
```

**Methods:**

| Method | Description |
|---|---|
| `lbl.SetText(str)` | Update text content |
| `lbl.SetIcon(icon)` | Update leading icon |
| `lbl.SetColor(Color3)` | Change text colour |
| `lbl.Hide()` / `lbl.Show()` | Visibility |

---

### `Tab:Paragraph(title, body)` → ElementControl

A two-part text block for longer descriptions or changelogs.

```lua
tab:Paragraph(
    "Patch Notes v2.0",
    "Added speed boost. Fixed teleport exploit. Improved mobile layout."
)
```

**Methods:**

| Method | Description |
|---|---|
| `para.Rewrite(title, body)` | Replace both title and body |
| `para.Hide()` / `para.Show()` | Visibility |

---

## Notifications

### `Velvet:Whisper(opts)`

| Field | Type | Default | Description |
|---|---|---|---|
| `Title` | string | `"Notification"` | Notification title |
| `Message` | string | `""` | Body text |
| `Duration` | number | `3.5` | Auto-dismiss time in seconds |
| `Icon` | string | `"🔔"` | Leading icon |
| `Action` | table | `nil` | Optional button: `{ Text = "...", Callback = fn }` |

```lua
VelvetUi:Whisper({
    Title    = "Download Complete",
    Message  = "Config saved successfully.",
    Duration = 4,
    Icon     = "✅",
    Action   = {
        Text     = "Open",
        Callback = function() print("open config") end,
    },
})
```

On **desktop**: toast appears top-right.
On **mobile**: toast appears top-centre.

Up to 3 notifications stack simultaneously.

---

## Themes

Colour tokens available in every theme table:

| Token | Role |
|---|---|
| `bg` | Deepest window background |
| `surface` | Interactive element surface |
| `card` | Group / card container |
| `sidebar` | Sidebar strip background |
| `topbar` | Topbar strip background |
| `accent` | Primary accent colour |
| `accentLight` | Hover state of accent |
| `accentDark` | Pressed state of accent |
| `rose` | Secondary accent (gold) |
| `roseDark` | Pressed secondary |
| `border` | 1px element border |
| `borderFocus` | Focused/active border |
| `text` | Primary text |
| `muted` | Secondary/hint text |
| `textInverse` | Text on bright surfaces |
| `success` | Positive semantic colour |
| `warning` | Cautionary semantic colour |
| `danger` | Destructive semantic colour |
| `switchOn` | Switch on-state track |
| `switchOff` | Switch off-state track |
| `sliderTrack` | Slider track background |
| `sliderFill` | Slider filled portion |
| `sliderThumb` | Slider drag thumb |
| `overlay` | Modal backdrop |
| `notifBg` | Notification background |

---

## Animation Styles

Set via `Window:Animate(style)` or globally via `Animator.setDefaultStyle(style)`.

| Style | Character |
|---|---|
| `"Calm"` | Slow, gentle — `Expo Out` at 0.55s open / 0.30s close |
| `"Brisk"` | Fast, clean — `Quint Out` at 0.20s open / 0.14s close (default) |
| `"Bouncy"` | Overshoot — `Back Out` at 0.50s open / 0.20s close |

---

## Config / Save System

Any element that receives a `flag` string parameter participates in automatic save/restore.

```lua
-- Flag makes this value persist across sessions (in executor environments)
local sw = tab:Switch("Speed", false, callback, "my_speed_flag")
```

- Flags must be **unique** across all elements.
- `Velvet:LoadConfig()` restores all saved values by calling each element's callback.
- In executor environments with `writefile`/`readfile`: values persist to `velvet_config.json`.
- In standard Roblox: values persist in-memory for the session duration.

---

## Device & Scale Modes

Velvet UI detects the device at require-time and adjusts:

| Feature | Desktop | Mobile |
|---|---|---|
| Sidebar | Full (icon + text, 168px) | Collapsed (icon only, 56px) with expand button |
| Element height | 44px | 44px (touch-safe) |
| Keybind elements | Shown | Hidden automatically |
| Notifications | Top-right | Top-centre |
| Window size | 680 × 440 | 360 × 500 |
| Tab text labels | Visible | Hidden when collapsed |

Override detection with:

```lua
VelvetUi:SetScaleMode("Mobile")   -- always use mobile layout
VelvetUi:SetScaleMode("Desktop")  -- always use desktop layout
VelvetUi:SetScaleMode("Auto")     -- detect automatically (default)
```
