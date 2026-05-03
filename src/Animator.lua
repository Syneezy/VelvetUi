--[[
    Velvet UI — Animator.lua
    TweenService wrapper with named presets and animation helpers.
    Three window-level animation styles: Calm, Brisk, Bouncy.
    MIT License
--]]

local TweenService = game:GetService("TweenService")

local Animator = {}

-- ── Tween info constants ──────────────────────────────────────────────────────
-- Never construct TweenInfo in hot paths — use these constants.

local INFO = {
    -- Micro interactions (hover, state change)
    MICRO  = TweenInfo.new(0.10, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    -- Standard UI transitions
    FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    MEDIUM = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.40, Enum.EasingStyle.Expo,  Enum.EasingDirection.Out),
    -- Tab/panel transitions
    TAB    = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
    -- Entrance with feel
    ENTER  = TweenInfo.new(0.35, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    -- Exit (ease-in so it feels intentional)
    EXIT   = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
    -- Notification slide
    NOTIF  = TweenInfo.new(0.30, Enum.EasingStyle.Expo,  Enum.EasingDirection.Out),
}

-- ── Window animation style presets ───────────────────────────────────────────
-- Mapped to Window:Animate(style). Applied to open/close tweens.

local STYLE_PRESETS = {
    Calm = {
        open  = TweenInfo.new(0.55, Enum.EasingStyle.Expo,  Enum.EasingDirection.Out),
        close = TweenInfo.new(0.30, Enum.EasingStyle.Expo,  Enum.EasingDirection.In),
        tab   = TweenInfo.new(0.30, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut),
    },
    Brisk = {
        open  = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        close = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.In),
        tab   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    },
    Bouncy = {
        open  = TweenInfo.new(0.50, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
        close = TweenInfo.new(0.20, Enum.EasingStyle.Quint,  Enum.EasingDirection.In),
        tab   = TweenInfo.new(0.35, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    },
}

-- Current active style (per-window override or library default)
local _defaultStyle = STYLE_PRESETS.Brisk

-- ── Core tween helper ─────────────────────────────────────────────────────────

-- Play a tween and return it. Props is {property = targetValue}.
function Animator.tween(instance, infoKey, props)
    if not instance or not instance.Parent then return end
    local info = INFO[infoKey] or INFO.MEDIUM
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

-- Play a tween with a raw TweenInfo object (used by style presets).
function Animator.tweenRaw(instance, tweenInfo, props)
    if not instance or not instance.Parent then return end
    local t = TweenService:Create(instance, tweenInfo, props)
    t:Play()
    return t
end

-- ── Common animation primitives ───────────────────────────────────────────────

-- Fade an element in. Sets Visible = true before tweening.
function Animator.fadeIn(instance, speed)
    if not instance then return end
    instance.BackgroundTransparency = 1
    instance.Visible = true
    return Animator.tween(instance, speed or "MEDIUM", { BackgroundTransparency = 0 })
end

-- Fade an element out. Sets Visible = false on completion.
function Animator.fadeOut(instance, speed, callback)
    if not instance then return end
    local t = Animator.tween(instance, speed or "FAST", { BackgroundTransparency = 1 })
    if t then
        t.Completed:Connect(function()
            instance.Visible = false
            if callback then callback() end
        end)
    end
    return t
end

-- Slide in from an offset UDim2. Instance must already have its target Position set.
function Animator.slideIn(instance, offsetUDim2, speed)
    if not instance then return end
    local target = instance.Position
    instance.Position = target + offsetUDim2
    instance.Visible = true
    return Animator.tween(instance, speed or "MEDIUM", { Position = target })
end

-- ── Window open / close ───────────────────────────────────────────────────────

function Animator.openWindow(frame, style)
    local preset = STYLE_PRESETS[style] or _defaultStyle
    frame.GroupTransparency = 1
    frame.Visible = true
    -- Animate the CanvasGroup's transparency so all children fade together
    Animator.tweenRaw(frame, preset.open, { GroupTransparency = 0 })
end

function Animator.closeWindow(frame, style, callback)
    local preset = STYLE_PRESETS[style] or _defaultStyle
    local t = Animator.tweenRaw(frame, preset.close, { GroupTransparency = 1 })
    if t then
        t.Completed:Connect(function()
            frame.Visible = false
            if callback then callback() end
        end)
    end
end

-- ── Tab switching ─────────────────────────────────────────────────────────────

-- Cross-fade between two tab content frames.
function Animator.switchTab(outContent, inContent, style)
    local preset = STYLE_PRESETS[style] or _defaultStyle

    -- Fade out old
    if outContent then
        local t = Animator.tweenRaw(outContent, preset.tab, { BackgroundTransparency = 1 })
        if t then
            t.Completed:Connect(function()
                outContent.Visible = false
            end)
        end
    end

    -- Fade in new with a small delay to avoid a "flash"
    task.delay(0.08, function()
        if not inContent then return end
        inContent.BackgroundTransparency = 1
        inContent.Visible = true
        Animator.tweenRaw(inContent, preset.tab, { BackgroundTransparency = 0 })
    end)
end

-- ── Interactive element feedback ──────────────────────────────────────────────

-- Hover highlight for a button-like element.
function Animator.attachHover(btn, defaultColor, hoverColor)
    btn.MouseEnter:Connect(function()
        Animator.tween(btn, "MICRO", { BackgroundColor3 = hoverColor })
    end)
    btn.MouseLeave:Connect(function()
        Animator.tween(btn, "MICRO", { BackgroundColor3 = defaultColor })
    end)
end

-- Press scale-down feedback (adds a UIScale child).
function Animator.attachPressScale(btn)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = btn

    btn.MouseButton1Down:Connect(function()
        Animator.tween(scale, "MICRO", { Scale = 0.96 })
    end)
    btn.MouseButton1Up:Connect(function()
        Animator.tween(scale, "FAST", { Scale = 1.0 })
    end)
    -- Catch mouse leaving while held
    btn.MouseLeave:Connect(function()
        Animator.tween(scale, "FAST", { Scale = 1.0 })
    end)
end

-- Touch-safe press feedback (scale + color flash).
function Animator.attachTouchFeedback(btn, defaultColor, pressColor)
    btn.MouseButton1Down:Connect(function()
        Animator.tween(btn, "MICRO", { BackgroundColor3 = pressColor })
    end)
    local function release()
        Animator.tween(btn, "FAST", { BackgroundColor3 = defaultColor })
    end
    btn.MouseButton1Up:Connect(release)
    btn.MouseLeave:Connect(release)
end

-- ── Notification helpers ──────────────────────────────────────────────────────

-- Slide in from top (desktop) or centre-top (mobile).
function Animator.notifEnter(frame)
    local targetPos = frame.Position
    frame.Position = UDim2.new(
        targetPos.X.Scale, targetPos.X.Offset,
        targetPos.Y.Scale, targetPos.Y.Offset - 80
    )
    frame.BackgroundTransparency = 1
    frame.Visible = true
    Animator.tween(frame, "NOTIF", {
        Position            = targetPos,
        BackgroundTransparency = 0,
    })
end

-- Slide out and hide.
function Animator.notifExit(frame, callback)
    local current = frame.Position
    local t = Animator.tween(frame, "EXIT", {
        Position            = UDim2.new(current.X.Scale, current.X.Offset, current.Y.Scale, current.Y.Offset - 60),
        BackgroundTransparency = 1,
    })
    if t then
        t.Completed:Connect(function()
            frame.Visible = false
            if callback then callback() end
        end)
    end
end

-- ── Stagger reveal ────────────────────────────────────────────────────────────

-- Stagger-reveal a list of items top-to-bottom with fade.
function Animator.stagger(items, baseDelay, stepDelay, fn)
    baseDelay = baseDelay or 0
    stepDelay = stepDelay or 0.04
    for i, item in ipairs(items) do
        task.delay(baseDelay + (i - 1) * stepDelay, function()
            if fn then
                fn(item, i)
            else
                item.BackgroundTransparency = 1
                item.Visible = true
                Animator.tween(item, "MEDIUM", { BackgroundTransparency = 0 })
            end
        end)
    end
end

-- ── Style management ──────────────────────────────────────────────────────────

function Animator.getStyle(name)
    return STYLE_PRESETS[name] or _defaultStyle
end

function Animator.setDefaultStyle(name)
    if STYLE_PRESETS[name] then
        _defaultStyle = STYLE_PRESETS[name]
    else
        warn("[Velvet/Animator] Unknown animation style: " .. tostring(name))
    end
end

return Animator
