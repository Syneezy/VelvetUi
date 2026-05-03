-- Icon1.lua
-- Velvet Icon System (Advanced / Production Ready)

local Icons = {}

--// 🔥 Atlas Asset IDs (1-based indexing)
local AtlasIds = {
    "rbxassetid://103814300206079",
    "rbxassetid://110883881134391",
    "rbxassetid://85588482759059",
    "rbxassetid://106285411531362"
}

--// 🔥 Large icon mapping (generated)
local Map = require(script.Icon2)

--// 🔥 Internal cache to avoid redundant updates
local Cache = setmetatable({}, { __mode = "k" }) -- weak keys (auto GC)

--// 🔧 Internal: validate GUI object
local function isValidGui(obj)
    return typeof(obj) == "Instance"
        and (obj:IsA("ImageLabel") or obj:IsA("ImageButton"))
end

--// 🔧 Internal: resolve icon data
local function resolve(iconName)
    local data = Map[iconName]
    if not data then
        warn("[Velvet Icons] Icon not found:", iconName)
        return nil
    end

    local atlas = AtlasIds[data.atlas + 1]
    if not atlas then
        warn("[Velvet Icons] Atlas missing:", data.atlas)
        return nil
    end

    return data, atlas
end

--// 🚀 Apply icon to a GUI object
--// @param guiObject (ImageLabel / ImageButton)
--// @param iconName (string)
--// @param options (optional table)
--//    tint = Color3
--//    size = boolean (auto apply size)
function Icons.Apply(guiObject, iconName, options)
    if not isValidGui(guiObject) then
        warn("[Velvet Icons] Invalid GUI object")
        return
    end

    local data, atlas = resolve(iconName)
    if not data then return end

    --// 🔁 Skip if already applied (cache)
    local cached = Cache[guiObject]
    if cached
        and cached.name == iconName
        and cached.atlas == atlas then
        return
    end

    --// 🎯 Apply atlas + rect
    guiObject.Image = atlas
    guiObject.ImageRectOffset = Vector2.new(data.x, data.y)
    guiObject.ImageRectSize = Vector2.new(data.w, data.h)

    --// 🎨 Optional tint
    if options and options.tint then
        guiObject.ImageColor3 = options.tint
    end

    --// 📐 Optional auto size
    if options and options.size then
        guiObject.Size = UDim2.fromOffset(data.w, data.h)
    end

    --// 🧼 Default styling
    guiObject.BackgroundTransparency = 1

    --// 💾 Save cache
    Cache[guiObject] = {
        name = iconName,
        atlas = atlas
    }
end

--// 🔎 Get raw mapping data
function Icons.Get(iconName)
    return Map[iconName]
end

--// 🔎 Check if icon exists
function Icons.Exists(iconName)
    return Map[iconName] ~= nil
end

--// 📊 Count total icons
function Icons.Count()
    local count = 0
    for _ in pairs(Map) do
        count += 1
    end
    return count
end

--// 🎨 Change tint dynamically (without reapply)
function Icons.SetTint(guiObject, color)
    if isValidGui(guiObject) then
        guiObject.ImageColor3 = color
    end
end

--// ♻️ Clear cache for a specific object
function Icons.Clear(guiObject)
    Cache[guiObject] = nil
end

--// 🧹 Clear all cache
function Icons.ClearAll()
    for k in pairs(Cache) do
        Cache[k] = nil
    end
end

return Icons
