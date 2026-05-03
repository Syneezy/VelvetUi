-- Velvet UI — BasicDemoExc.lua
-- Executor-only demo loader for VelvetUi.
--
-- How to use:
-- 1) Host your VelvetUi source/bundle on a raw URL.
-- 2) Set SOURCE_URL below.
-- 3) Execute this script in your executor.
--
-- If VelvetUi is already inside the game (ReplicatedStorage), this script will
-- try require(game.ReplicatedStorage.VelvetUi) first.

local SOURCE_URL = "https://raw.githubusercontent.com/Syneezy/VelvetUi/main/loader.lua" 

local function httpGet(url)
    if typeof(game) == "Instance" and game.HttpGet then
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(result) == "string" and #result > 0 then
            return result
        end
    end

    local requestFn = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request

    if requestFn then
        local ok, response = pcall(function()
            return requestFn({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Mozilla/5.0",
                    ["Accept"] = "*/*",
                },
            })
        end)

        if ok and response then
            local body = response.Body or response.body
            if type(body) == "string" and #body > 0 then
                return body
            end
        end
    end

    error("[VelvetDemo] No supported HTTP method found in this executor.")
end

local function loadVelvet()
    -- Try in-game module first.
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local existing = replicatedStorage:FindFirstChild("VelvetUi")
    if existing and existing:IsA("ModuleScript") then
        local ok, mod = pcall(require, existing)
        if ok and type(mod) == "table" then
            return mod
        end
        warn("[VelvetDemo] Require from ReplicatedStorage failed, falling back to HTTP.")
    end

    local source = httpGet(SOURCE_URL)
    local chunk, err = loadstring(source)
    if not chunk then
        error("[VelvetDemo] loadstring failed: " .. tostring(err))
    end

    local ok, mod = pcall(chunk)
    if not ok then
        error("[VelvetDemo] Velvet loader runtime error: " .. tostring(mod))
    end

    return mod
end

local VelvetUi = loadVelvet()

-- Global setup
VelvetUi:SetScaleMode("Auto")
VelvetUi:EnableDebugMode() -- comment out if you do not want console logs

VelvetUi:DefineTheme("Cherry Velvet", {
    accent      = Color3.fromRGB(210, 60, 100),
    accentLight = Color3.fromRGB(230, 80, 120),
    accentDark  = Color3.fromRGB(170, 40, 80),
    rose        = Color3.fromRGB(255, 140, 160),
    roseDark    = Color3.fromRGB(210, 110, 130),
})

local window = VelvetUi:BuildWindow({
    Title      = "Velvet Demo (Executor)",
    Icon       = "◈",
    Theme      = "Midnight Velvet",
    Key        = "RightShift",
    SaveConfig = true,
})

window:Animate("Brisk")

-- Visuals tab
local visualsTab = window:AddTab("Visuals", "🎨")
visualsTab:Group("Appearance")

local accentPicker = visualsTab:ColorSelect(
    "Accent Colour",
    Color3.fromRGB(123, 47, 190),
    function(c)
        print("[VelvetDemo] Accent colour:", c)
    end,
    "demo_accentColour"
)

local themeDropdown = visualsTab:Dropdown(
    "Theme",
    { "Midnight Velvet", "Cherry Velvet" },
    "Midnight Velvet",
    function(selected)
        window:Dress(selected)
        print("[VelvetDemo] Theme switched to:", selected)
    end,
    "demo_theme"
)

visualsTab:Group("UI Scale")
visualsTab:Dropdown(
    "Scale Mode",
    { "Auto", "Desktop", "Mobile" },
    "Auto",
    function(mode)
        VelvetUi:SetScaleMode(mode)
        VelvetUi:Whisper({
            Title = "Scale Mode",
            Message = "Changed to " .. mode,
            Icon = "📐",
            Duration = 2,
        })
    end,
    "demo_scaleMode"
)

-- Gameplay tab
local gameTab = window:AddTab("Gameplay", "⚔️")
gameTab:Group("Movement")

gameTab:Switch(
    "Speed Boost",
    false,
    function(enabled)
        print("[VelvetDemo] Speed boost:", enabled)
    end,
    "demo_speedBoost"
)

gameTab:Slider(
    "Walk Speed",
    16, 100, 16,
    function(value)
        print("[VelvetDemo] Walk speed:", value)
    end,
    "demo_walkSpeed"
)

gameTab:Slider(
    "Jump Power",
    50, 300, 50,
    function(value)
        print("[VelvetDemo] Jump power:", value)
    end,
    "demo_jumpPower"
)

gameTab:Group("Combat")

gameTab:Switch(
    "Auto Aim",
    false,
    function(enabled)
        print("[VelvetDemo] Auto aim:", enabled)
    end,
    "demo_autoAim"
)

gameTab:Slider(
    "Aim Range",
    10, 500, 100,
    function(value)
        print("[VelvetDemo] Aim range:", value)
    end,
    "demo_aimRange"
)

gameTab:Keybind(
    "Trigger Key",
    "E",
    function(key)
        print("[VelvetDemo] Trigger key:", key)
    end,
    "demo_triggerKey"
)

-- Player tab
local playerTab = window:AddTab("Player", "👤")
playerTab:Group("Identity")
playerTab:Label("Customise your player appearance.", "✦", Color3.fromRGB(138, 131, 145))

playerTab:TextField(
    "Display Name",
    "Enter your name…",
    function(text, submitted)
        if submitted then
            print("[VelvetDemo] Display name:", text)
        end
    end,
    "demo_displayName"
)

playerTab:Group("Character Colours")
playerTab:ColorSelect(
    "Body Colour",
    Color3.fromRGB(200, 180, 160),
    function(c)
        print("[VelvetDemo] Body colour:", c)
    end,
    "demo_bodyColour"
)

playerTab:ColorSelect(
    "Shirt Colour",
    Color3.fromRGB(40, 100, 200),
    function(c)
        print("[VelvetDemo] Shirt colour:", c)
    end,
    "demo_shirtColour"
)

-- Settings tab
local settingsTab = window:AddTab("Settings", "⚙️")
settingsTab:Group("Interface")

settingsTab:Switch(
    "Show Notifications",
    true,
    function(on)
        print("[VelvetDemo] Notifications:", on)
    end,
    "demo_notifs"
)

settingsTab:Group("Animation")
settingsTab:Dropdown(
    "Window Animation",
    { "Brisk", "Calm", "Bouncy" },
    "Brisk",
    function(style)
        window:Animate(style)
    end,
    "demo_animStyle"
)

settingsTab:Group("Actions")

settingsTab:Button("Send Test Notification", function()
    VelvetUi:Whisper({
        Title = "Velvet UI",
        Message = "Everything is running.",
        Duration = 4,
        Icon = "✅",
        Action = {
            Text = "Dismiss",
            Callback = function()
                print("[VelvetDemo] Notification dismissed.")
            end,
        },
    })
end)

settingsTab:Button("Copy Version", function()
    local version = "Velvet UI v" .. VelvetUi:GetVersion()
    if setclipboard then
        setclipboard(version)
        VelvetUi:Whisper({
            Title = "Copied",
            Message = version,
            Duration = 2,
            Icon = "📋",
        })
    else
        warn("[VelvetDemo] setclipboard not available in this executor.")
    end
end)

settingsTab:Button("Destroy All Windows", function()
    VelvetUi:DestroyAll()
    print("[VelvetDemo] All windows destroyed.")
end)

-- Welcome toast
 task.delay(1, function()
    VelvetUi:Whisper({
        Title = "Welcome",
        Message = "Press RightShift to toggle the window.",
        Duration = 5,
        Icon = "◈",
    })
end)

window:Show()
