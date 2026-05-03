--[[
    Velvet UI — themes/Midnight.lua
    Standalone export of the "Midnight Velvet" colour palette.
    Can be required directly and passed into DefineTheme, or used for reference.

    Usage:
        local Midnight = require(path.to.VelvetUi.themes.Midnight)
        Velvet:DefineTheme("My Custom", {
            accent = Color3.fromRGB(255, 80, 120),  -- override just one token
            -- everything else inherits from Midnight
        })
--]]

return table.freeze({
    -- ── Backgrounds ───────────────────────────────────────────────────────────
    bg      = Color3.fromRGB(13,  13,  18),   -- deepest window background
    surface = Color3.fromRGB(22,  22,  31),   -- raised interactive surface
    card    = Color3.fromRGB(28,  28,  38),   -- group / card container
    sidebar = Color3.fromRGB(18,  18,  23),   -- sidebar navigation strip
    topbar  = Color3.fromRGB(16,  16,  21),   -- topbar strip

    -- ── Accents ───────────────────────────────────────────────────────────────
    accent      = Color3.fromRGB(123, 47,  190),  -- primary purple
    accentLight = Color3.fromRGB(148, 72,  215),  -- hover purple
    accentDark  = Color3.fromRGB(98,  32,  158),  -- pressed / deep purple
    rose        = Color3.fromRGB(201, 169, 110),  -- gold / secondary accent
    roseDark    = Color3.fromRGB(170, 138, 82),   -- pressed gold

    -- ── Borders ───────────────────────────────────────────────────────────────
    border      = Color3.fromRGB(42,  42,  58),   -- standard 1px border
    borderFocus = Color3.fromRGB(123, 47,  190),  -- focused / active border

    -- ── Text ──────────────────────────────────────────────────────────────────
    text        = Color3.fromRGB(237, 232, 240),  -- primary readable text
    muted       = Color3.fromRGB(138, 131, 145),  -- secondary / hint text
    textInverse = Color3.fromRGB(13,  13,  18),   -- text on bright backgrounds

    -- ── Semantic ──────────────────────────────────────────────────────────────
    success = Color3.fromRGB(72,  199, 142),
    warning = Color3.fromRGB(255, 183, 77),
    danger  = Color3.fromRGB(240, 80,  80),

    -- ── Interactive states ────────────────────────────────────────────────────
    switchOn    = Color3.fromRGB(123, 47,  190),
    switchOff   = Color3.fromRGB(55,  55,  72),
    sliderTrack = Color3.fromRGB(42,  42,  58),
    sliderFill  = Color3.fromRGB(123, 47,  190),
    sliderThumb = Color3.fromRGB(237, 232, 240),

    -- ── Overlays ──────────────────────────────────────────────────────────────
    overlay  = Color3.fromRGB(0,   0,   0),
    notifBg  = Color3.fromRGB(26,  26,  36),
})
