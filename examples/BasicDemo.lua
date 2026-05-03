--[[
    Velvet UI — examples/BasicDemo.lua
    Full demonstration of every API surface in Velvet UI.
    Place this as a LocalScript inside StarterPlayerScripts (or StarterGui).
    Adjust the require path to match where you placed the VelvetUi folder.
--]]

-- Adjust this path to where VelvetUi lives in your project.
local VelvetUi = require(game.ReplicatedStorage.VelvetUi)

-- ── Optional setup ────────────────────────────────────────────────────────────

VelvetUi:SetScaleMode("Auto")  -- auto-detect mobile vs desktop
-- VelvetUi:EnableDebugMode()  -- uncomment to see logs

-- Register a custom theme (optional — Midnight Velvet is used by default)
VelvetUi:DefineTheme("Cherry Velvet", {
    accent      = Color3.fromRGB(210, 60,  100),
    accentLight = Color3.fromRGB(230, 80,  120),
    rose        = Color3.fromRGB(255, 140, 160),
})

-- ── Build the window ──────────────────────────────────────────────────────────

local window = VelvetUi:BuildWindow({
    Title      = "Velvet Demo",
    Icon       = "◈",
    Theme      = "Midnight Velvet",   -- swap to "Cherry Velvet" to test custom theme
    Key        = "RightShift",        -- toggle window visibility with this key
    SaveConfig = true,                -- auto-restore saved values on start
})

window:Animate("Brisk")   -- "Calm" | "Brisk" | "Bouncy"

-- ── Tab: Visuals ──────────────────────────────────────────────────────────────

local visualsTab = window:AddTab("Visuals", "🎨")

local appearGroup = visualsTab:Group("Appearance")

local colorSelect = visualsTab:ColorSelect(
    "Accent Colour",
    Color3.fromRGB(123, 47, 190),
    function(colour)
        print("Accent colour changed:", colour)
    end,
    "demo_accentColour"  -- flag for auto-save
)

local themeDropdown = visualsTab:Dropdown(
    "Theme",
    { "Midnight Velvet", "Cherry Velvet" },
    "Midnight Velvet",
    function(selected)
        window:Dress(selected)
        print("Theme switched to:", selected)
    end,
    "demo_theme"
)

local uiScaleGroup = visualsTab:Group("UI Scale")

local scaleMode = visualsTab:Dropdown(
    "Scale Mode",
    { "Auto", "Desktop", "Mobile" },
    "Auto",
    function(mode)
        VelvetUi:SetScaleMode(mode)
    end
)

-- ── Tab: Gameplay ─────────────────────────────────────────────────────────────

local gameTab = window:AddTab("Gameplay", "⚔️")

local movementGroup = gameTab:Group("Movement")

local speedSwitch = gameTab:Switch(
    "Speed Boost",
    false,
    function(enabled)
        print("Speed boost:", enabled)
        -- game logic would go here
    end,
    "demo_speedBoost"
)

local speedSlider = gameTab:Slider(
    "Walk Speed",
    16, 100, 16,
    function(value)
        print("Walk speed:", value)
        -- game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
    "demo_walkSpeed"
)

local jumpSlider = gameTab:Slider(
    "Jump Power",
    50, 300, 50,
    function(value)
        print("Jump power:", value)
    end,
    "demo_jumpPower"
)

local combatGroup = gameTab:Group("Combat")

local aimbotSwitch = gameTab:Switch(
    "Auto Aim",
    false,
    function(enabled)
        print("Auto aim:", enabled)
    end,
    "demo_autoAim"
)

local rangeSlider = gameTab:Slider(
    "Aim Range",
    10, 500, 100,
    function(value)
        print("Aim range:", value)
    end,
    "demo_aimRange"
)

-- Keybind (hidden automatically on mobile)
local triggerKey = gameTab:Keybind(
    "Trigger Key",
    "E",
    function(key)
        print("Trigger key activated / rebound to:", key)
    end,
    "demo_triggerKey"
)

-- ── Tab: Player ───────────────────────────────────────────────────────────────

local playerTab = window:AddTab("Player", "👤")

local identityGroup = playerTab:Group("Identity")

playerTab:Label("Customise your player appearance.", "✦", Color3.fromRGB(138, 131, 145))

local nameField = playerTab:TextField(
    "Display Name",
    "Enter your name…",
    function(text, submitted)
        if submitted then
            print("Display name set to:", text)
        end
    end,
    "demo_displayName"
)

local colourGroup = playerTab:Group("Character Colours")

local bodyColor = playerTab:ColorSelect(
    "Body Colour",
    Color3.fromRGB(200, 180, 160),
    function(c) print("Body colour:", c) end,
    "demo_bodyColour"
)

local shirtColor = playerTab:ColorSelect(
    "Shirt Colour",
    Color3.fromRGB(40, 100, 200),
    function(c) print("Shirt colour:", c) end,
    "demo_shirtColour"
)

-- ── Tab: Settings ─────────────────────────────────────────────────────────────

local settingsTab = window:AddTab("Settings", "⚙️")

local uiGroup = settingsTab:Group("Interface")

local notifSwitch = settingsTab:Switch(
    "Show Notifications",
    true,
    function(on) print("Notifications:", on) end,
    "demo_notifs"
)

local animGroup = settingsTab:Group("Animation")

local animDropdown = settingsTab:Dropdown(
    "Window Animation",
    { "Brisk", "Calm", "Bouncy" },
    "Brisk",
    function(style)
        window:Animate(style)
    end,
    "demo_animStyle"
)

local debugGroup = settingsTab:Group("Debug")

settingsTab:Paragraph(
    "About Velvet UI",
    "Velvet UI v" .. VelvetUi:GetVersion() .. " — A luxurious, modern, and lightweight GUI library "
    .. "for Roblox with first-class mobile support. Built from scratch, zero dependencies."
)

settingsTab:Button("Send Test Notification", function()
    VelvetUi:Whisper({
        Title    = "Velvet UI",
        Message  = "Everything looks great! Notification system is working.",
        Duration = 4,
        Icon     = "✅",
        Action   = {
            Text     = "Dismiss",
            Callback = function() print("Notification dismissed.") end,
        }
    })
end)

settingsTab:Button("Copy Version to Clipboard", function()
    if setclipboard then
        setclipboard("Velvet UI v" .. VelvetUi:GetVersion())
        VelvetUi:Whisper({ Title = "Copied", Message = "Version copied to clipboard.", Duration = 2 })
    else
        warn("[VelvetDemo] setclipboard not available in this environment.")
    end
end)

local dangerGroup = settingsTab:Group("Danger Zone")

local destroyBtn = settingsTab:Button("Destroy All Windows", function()
    VelvetUi:DestroyAll()
    print("[VelvetDemo] All windows destroyed.")
end)

-- ── Initial notification ──────────────────────────────────────────────────────

task.delay(1, function()
    VelvetUi:Whisper({
        Title   = "Welcome to Velvet UI",
        Message = "Press RightShift to toggle the window.",
        Duration = 5,
        Icon    = "◈",
    })
end)
