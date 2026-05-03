--[[
    Velvet UI — Utils.lua
    Device detection, layout scaling, instance factory helpers, and misc utilities.
    MIT License
--]]

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local Utils = {}

-- ── Device detection ──────────────────────────────────────────────────────────

local _scaleMode = "Auto"  -- "Auto" | "Desktop" | "Mobile"

-- Returns true if the device is considered mobile / touch-first.
function Utils.isMobile()
    if _scaleMode == "Mobile"  then return true  end
    if _scaleMode == "Desktop" then return false end
    -- Auto: touch-capable and no mouse
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

function Utils.setScaleMode(mode)
    _scaleMode = mode
end

function Utils.getScaleMode()
    return _scaleMode
end

-- ── Layout constants (change here, apply everywhere) ─────────────────────────

-- Shared across Core and Elements via Utils.Layout
Utils.Layout = {
    -- Sidebar
    sidebarWidthDesktop = 168,
    sidebarWidthMobile  = 56,
    tabButtonHeightD    = 40,   -- desktop tab button height
    tabButtonHeightM    = 48,   -- mobile tab button height (44px+ for touch)
    tabIconSize         = 20,   -- icon size inside tab button

    -- Topbar
    topbarHeight        = 48,
    appIconSize         = 26,
    closeButtonSize     = 28,

    -- Window defaults
    windowWidthDesktop  = 680,
    windowHeightDesktop = 440,
    windowWidthMobile   = 360,
    windowHeightMobile  = 500,

    -- Content area
    contentPaddingH     = 16,
    contentPaddingV     = 12,
    groupPaddingH       = 14,
    groupPaddingV       = 10,
    elementHeight       = 44,   -- min touch-safe height
    elementSpacing      = 6,
    groupSpacing        = 12,
    groupTitleHeight    = 28,

    -- Corner radii (one or two values only — visual consistency rule)
    radiusElement       = 8,
    radiusPanel         = 12,
    radiusWindow        = 14,
    radiusButton        = 8,
    radiusGroup         = 10,
    radiusNotif         = 12,
    radiusSwitch        = 11,   -- pill shape half-height
    radiusSliderTrack   = 4,
    radiusSliderThumb   = 8,
    radiusDropdown      = 8,

    -- Stroke
    strokeWidth         = 1,
    strokeTransparency  = 0.88, -- subtle border
    strokeFocused       = 0.55, -- active / focused border

    -- Typography (Gotham family only)
    fontTitle    = Enum.Font.GothamBold,
    fontLabel    = Enum.Font.GothamMedium,
    fontBody     = Enum.Font.Gotham,
    fontMono     = Enum.Font.Code,

    -- Type scale
    sizeTitle    = 15,
    sizeLabel    = 13,
    sizeBody     = 13,
    sizeMuted    = 11,
    sizeElement  = 13,
    sizeGroupHdr = 11,
}

-- Return correct sidebar width based on device.
function Utils.sidebarWidth()
    return Utils.isMobile()
        and Utils.Layout.sidebarWidthMobile
        or  Utils.Layout.sidebarWidthDesktop
end

-- Return correct window size based on device.
function Utils.windowSize()
    if Utils.isMobile() then
        return Utils.Layout.windowWidthMobile, Utils.Layout.windowHeightMobile
    end
    return Utils.Layout.windowWidthDesktop, Utils.Layout.windowHeightDesktop
end

-- ── Instance factory helpers ──────────────────────────────────────────────────
-- Thin wrappers to reduce boilerplate in Core and Elements.

-- Create a Frame with common defaults.
function Utils.frame(props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.color or Color3.fromRGB(0, 0, 0)
    f.BackgroundTransparency = props.transparency or 0
    f.BorderSizePixel = 0
    f.Size = props.size or UDim2.new(1, 0, 0, 40)
    f.Position = props.pos or UDim2.new(0, 0, 0, 0)
    f.Name = props.name or "Frame"
    f.ZIndex = props.zIndex or 1
    f.ClipsDescendants = props.clip or false
    if props.parent then f.Parent = props.parent end
    return f
end

-- Create a TextLabel.
function Utils.label(props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = props.font or Enum.Font.GothamMedium
    l.TextSize = props.size or 13
    l.TextColor3 = props.color or Color3.new(1, 1, 1)
    l.Text = props.text or ""
    l.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
    l.TextYAlignment = props.yAlign or Enum.TextYAlignment.Center
    l.TextTruncate = props.truncate or Enum.TextTruncate.AtEnd
    l.RichText = props.rich or false
    l.Size = props.size2 or UDim2.new(1, 0, 1, 0)
    l.Position = props.pos or UDim2.new(0, 0, 0, 0)
    l.Name = props.name or "Label"
    l.ZIndex = props.zIndex or 1
    if props.parent then l.Parent = props.parent end
    return l
end

-- Create a TextButton.
function Utils.button(props)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false  -- always manage hover manually
    b.BackgroundColor3 = props.color or Color3.fromRGB(50, 50, 70)
    b.BackgroundTransparency = props.transparency or 0
    b.BorderSizePixel = 0
    b.Font = props.font or Enum.Font.GothamMedium
    b.TextSize = props.textSize or 13
    b.TextColor3 = props.textColor or Color3.new(1, 1, 1)
    b.Text = props.text or ""
    b.TextXAlignment = props.xAlign or Enum.TextXAlignment.Center
    b.Size = props.size or UDim2.new(1, 0, 0, 44)
    b.Position = props.pos or UDim2.new(0, 0, 0, 0)
    b.Name = props.name or "Button"
    b.ZIndex = props.zIndex or 1
    if props.parent then b.Parent = props.parent end
    return b
end

-- Create a TextBox.
function Utils.textbox(props)
    local t = Instance.new("TextBox")
    t.BackgroundColor3 = props.color or Color3.fromRGB(22, 22, 31)
    t.BackgroundTransparency = props.transparency or 0
    t.BorderSizePixel = 0
    t.Font = props.font or Enum.Font.Gotham
    t.TextSize = props.textSize or 13
    t.TextColor3 = props.textColor or Color3.new(1, 1, 1)
    t.PlaceholderText = props.placeholder or ""
    t.PlaceholderColor3 = props.placeholderColor or Color3.fromRGB(100, 95, 108)
    t.Text = props.text or ""
    t.ClearTextOnFocus = props.clearOnFocus or false
    t.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
    t.Size = props.size or UDim2.new(1, 0, 0, 44)
    t.Position = props.pos or UDim2.new(0, 0, 0, 0)
    t.Name = props.name or "TextBox"
    t.ZIndex = props.zIndex or 1
    t.ClipsDescendants = true
    if props.parent then t.Parent = props.parent end
    return t
end

-- Add UICorner to an instance.
function Utils.corner(instance, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or Utils.Layout.radiusElement)
    c.Parent = instance
    return c
end

-- Add UIStroke to an instance.
function Utils.stroke(instance, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(42, 42, 58)
    s.Transparency = transparency or Utils.Layout.strokeTransparency
    s.Thickness = thickness or Utils.Layout.strokeWidth
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = instance
    return s
end

-- Add UIListLayout to a parent frame.
function Utils.listLayout(parent, props)
    local l = Instance.new("UIListLayout")
    l.FillDirection = props.direction or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, props.spacing or Utils.Layout.elementSpacing)
    l.HorizontalAlignment = props.hAlign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment = props.vAlign or Enum.VerticalAlignment.Top
    l.Parent = parent
    return l
end

-- Add UIPadding to a parent frame.
function Utils.padding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.Parent = parent
    return p
end

-- Add UIGradient (structural depth gradient only, not decorative).
function Utils.gradient(parent, colourSeq, rotation)
    local g = Instance.new("UIGradient")
    g.Color    = colourSeq
    g.Rotation = rotation or 90
    g.Parent   = parent
    return g
end

-- Auto-size a ScrollingFrame to its content using UIListLayout's AbsoluteContentSize.
function Utils.autoSizeScroll(scroll, layout)
    layout.Changed:Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
    end)
end

-- ── Misc ──────────────────────────────────────────────────────────────────────

-- Clamp a number between min and max.
function Utils.clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

-- Round a number to a number of decimal places.
function Utils.round(n, dec)
    local m = 10 ^ (dec or 0)
    return math.floor(n * m + 0.5) / m
end

-- Shallow copy a table.
function Utils.shallowCopy(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

-- Generate a simple unique id string.
local _idCounter = 0
function Utils.uid()
    _idCounter += 1
    return "velvet_" .. _idCounter
end

-- Log helper (only prints if debug mode is on).
local _debug = false
function Utils.setDebug(on)
    _debug = on
end

function Utils.log(...)
    if _debug then
        print("[Velvet]", ...)
    end
end

return Utils
