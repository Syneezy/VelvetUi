-- Icon1.lua
-- Velvet Icon System (Entry Point)

local Icons = {}

-- 🔥 Atlas Asset IDs (GANTI INI)
local AtlasIds = {
    [0] = "rbxassetid://ATLAS_1",
    [1] = "rbxassetid://ATLAS_2",
    [2] = "rbxassetid://ATLAS_3",
    [3] = "rbxassetid://ATLAS_4",
}

-- 🔥 Import mapping besar
local Map = require(script.Icon2)

--[[

📦 FORMAT MAPPING (REFERENCE UNTUK AI / DEV)

["icon_name"] = {
    atlas = 0,   -- index atlas (0-based)
    x = 2,       -- posisi X (pixel)
    y = 2,       -- posisi Y (pixel)
    w = 24,      -- width icon
    h = 24       -- height icon
}

Contoh:
["activity"] = { atlas = 0, x = 114, y = 2, w = 24, h = 24 }

]]

-- 🔧 APPLY ICON KE ImageLabel / ImageButton
function Icons.Apply(guiObject, iconName)
    local data = Map[iconName]

    if not data then
        warn("[Velvet Icons] Icon not found:", iconName)
        return
    end

    local atlas = AtlasIds[data.atlas]
    if not atlas then
        warn("[Velvet Icons] Atlas missing:", data.atlas)
        return
    end

    guiObject.Image = atlas
    guiObject.ImageRectOffset = Vector2.new(data.x, data.y)
    guiObject.ImageRectSize = Vector2.new(data.w, data.h)

    -- default styling
    guiObject.BackgroundTransparency = 1
end

-- 🔎 GET RAW DATA
function Icons.Get(iconName)
    return Map[iconName]
end

-- 🔢 CHECK EXIST
function Icons.Exists(iconName)
    return Map[iconName] ~= nil
end

-- 📊 DEBUG (OPTIONAL)
function Icons.Count()
    local count = 0
    for _ in pairs(Map) do
        count += 1
    end
    return count
end

return Icons
