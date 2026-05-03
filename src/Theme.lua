--[[
    Velvet UI — Theme.lua
    Manages the theme registry and provides colour tokens to all modules.
    Each theme is a flat table of named Color3 tokens.
    MIT License
--]]

local Theme = {}

-- ── Built-in palette ──────────────────────────────────────────────────────────

local MIDNIGHT = {
    -- Backgrounds
    bg      = Color3.fromRGB(13,  13,  18),   -- deepest background
    surface = Color3.fromRGB(22,  22,  31),   -- raised element surface
    card    = Color3.fromRGB(28,  28,  38),   -- card / group container
    sidebar = Color3.fromRGB(18,  18,  23),   -- sidebar strip
    topbar  = Color3.fromRGB(16,  16,  21),   -- topbar strip

    -- Accents
    accent      = Color3.fromRGB(123, 47,  190),  -- primary purple
    accentLight = Color3.fromRGB(148, 72,  215),  -- hover purple
    accentDark  = Color3.fromRGB(98,  32,  158),  -- pressed purple
    rose        = Color3.fromRGB(201, 169, 110),  -- gold rose (secondary accent)
    roseDark    = Color3.fromRGB(170, 138, 82),   -- pressed gold

    -- Borders
    border      = Color3.fromRGB(42,  42,  58),   -- standard border
    borderFocus = Color3.fromRGB(123, 47,  190),  -- focused / active border

    -- Text
    text        = Color3.fromRGB(237, 232, 240),  -- primary readable text
    muted       = Color3.fromRGB(138, 131, 145),  -- secondary / hint text
    textInverse = Color3.fromRGB(13,  13,  18),   -- text on bright surface

    -- Semantic
    success = Color3.fromRGB(72,  199, 142),
    warning = Color3.fromRGB(255, 183, 77),
    danger  = Color3.fromRGB(240, 80,  80),

    -- Interactive states
    switchOn    = Color3.fromRGB(123, 47,  190),
    switchOff   = Color3.fromRGB(55,  55,  72),
    sliderTrack = Color3.fromRGB(42,  42,  58),
    sliderFill  = Color3.fromRGB(123, 47,  190),
    sliderThumb = Color3.fromRGB(237, 232, 240),

    -- Overlay
    overlay     = Color3.fromRGB(0,   0,   0),
    notifBg     = Color3.fromRGB(26,  26,  36),
}

-- ── Registry ─────────────────────────────────────────────────────────────────

local _registry = {
    ["Midnight Velvet"] = MIDNIGHT,
}

local _current = "Midnight Velvet"

-- Register a new custom theme. Missing keys fall back to Midnight Velvet.
function Theme.define(name, tbl)
    local merged = {}
    for k, v in pairs(MIDNIGHT) do
        merged[k] = tbl[k] or v
    end
    -- Allow extra custom keys too
    for k, v in pairs(tbl) do
        merged[k] = v
    end
    _registry[name] = table.freeze(merged)
end

-- Return a frozen theme table by name (fallback to Midnight if not found).
function Theme.get(name)
    local t = _registry[name or _current]
    if not t then
        warn("[Velvet/Theme] Unknown theme '" .. tostring(name) .. "', falling back to Midnight Velvet.")
        return _registry["Midnight Velvet"]
    end
    return t
end

-- Set the active global theme name.
function Theme.setActive(name)
    if not _registry[name] then
        warn("[Velvet/Theme] Cannot activate unknown theme '" .. tostring(name) .. "'.")
        return
    end
    _current = name
end

function Theme.getActive()
    return _current
end

-- Seal the built-in theme so it cannot be mutated at runtime.
_registry["Midnight Velvet"] = table.freeze(MIDNIGHT)

return Theme
