--[[
    Velvet UI — Core.lua
    Builds and manages Window, Tab, and Group objects.

    Layout anatomy:
        ScreenGui
        └── CanvasGroup (WindowRoot) — for uniform fade in/out
            ├── Topbar (full width, fixed height)
            │   ├── AppIcon  ─ TitleLabel  ─ CloseButton
            └── Body (below topbar)
                ├── Sidebar (left strip, collapsible on mobile)
                │   └── TabList (UIListLayout)
                │         └── TabButton × N
                └── ContentFrame (right, remaining width)
                    └── TabContent × N (one per tab, lazy-visible)
                          └── ScrollingFrame
                                └── Group × N
                                      ├── GroupHeader
                                      └── ElementList (UIListLayout)

    MIT License
--]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local Core = {}

-- Injected references
local _theme, _animator, _config, _utils, _elements, _sharedState

function Core._init(state, theme, animator, config, utils, elements)
    _sharedState = state
    _theme       = theme
    _animator    = animator
    _config      = config
    _utils       = utils
    _elements    = elements
end

-- ── Internal helpers ──────────────────────────────────────────────────────────

local function getPlayer()
    return Players.LocalPlayer
end

local function getPlayerGui()
    local p = getPlayer()
    return p and p:WaitForChild("PlayerGui", 5)
end

-- Make a frame draggable via a handle element.
local function makeDraggable(handle, target)
    local _dragging, _dragStart, _startPos = false, nil, nil

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        _dragging  = true
        _dragStart = inp.Position
        _startPos  = target.Position
    end)

    handle.InputChanged:Connect(function(inp)
        if not _dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - _dragStart
        target.Position = UDim2.new(
            _startPos.X.Scale, _startPos.X.Offset + delta.X,
            _startPos.Y.Scale, _startPos.Y.Offset + delta.Y
        )
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            _dragging = false
        end
    end)
end

-- ── Notification layer ────────────────────────────────────────────────────────

local _notifGui = nil
local _notifQueue = {}
local _notifActive = 0
local MAX_NOTIFS = 3

local function ensureNotifGui()
    if _notifGui and _notifGui.Parent then return _notifGui end
    local pg = getPlayerGui()
    if not pg then return end

    _notifGui = Instance.new("ScreenGui")
    _notifGui.Name            = "VelvetNotifications"
    _notifGui.ResetOnSpawn    = false
    _notifGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    _notifGui.DisplayOrder    = 99
    _notifGui.Parent          = pg
    return _notifGui
end

function Core.ShowNotification(opts, state)
    local T       = _theme.get()
    local L       = _utils.Layout
    local isMob   = _utils.isMobile()
    local gui     = ensureNotifGui()
    if not gui then return end

    local NOTIF_W = 320
    local NOTIF_H = 76

    -- Position: top-centre on mobile, top-right on desktop
    local xScale  = isMob and 0.5 or 1
    local xOffset = isMob and -(NOTIF_W / 2) or -(NOTIF_W + 16)
    local yOffset = 16 + _notifActive * (NOTIF_H + 8)

    local frame = Instance.new("CanvasGroup")
    frame.Size                  = UDim2.new(0, NOTIF_W, 0, NOTIF_H)
    frame.Position              = UDim2.new(xScale, xOffset, 0, yOffset)
    frame.BackgroundColor3      = T.notifBg
    frame.GroupTransparency     = 1
    frame.BorderSizePixel       = 0
    frame.ZIndex                = 20
    frame.Parent                = gui
    _utils.corner(frame, L.radiusNotif)
    _utils.stroke(frame, T.border, 0.80)

    -- Accent top bar
    local accent = _utils.frame({
        name   = "AccentBar",
        size   = UDim2.new(1, 0, 0, 3),
        color  = T.accent,
        parent = frame,
    })
    _utils.corner(accent, 2)

    -- Icon label (optional)
    local iconLbl = _utils.label({
        name   = "Icon",
        text   = opts.Icon or "🔔",
        size   = 18,
        size2  = UDim2.new(0, 32, 1, -3),
        pos    = UDim2.new(0, 10, 0, 3),
        xAlign = Enum.TextXAlignment.Center,
        font   = Enum.Font.Gotham,
        color  = T.text,
        parent = frame,
    })

    local textX = 48
    -- Title
    local titleLbl = _utils.label({
        name   = "Title",
        text   = opts.Title or "Notification",
        font   = L.fontLabel,
        size   = L.sizeLabel,
        color  = T.text,
        size2  = UDim2.new(1, -(textX + 12), 0, 18),
        pos    = UDim2.new(0, textX, 0, 12),
        parent = frame,
    })

    -- Message
    local msgLbl = _utils.label({
        name   = "Message",
        text   = opts.Message or "",
        font   = L.fontBody,
        size   = 12,
        color  = T.muted,
        size2  = UDim2.new(1, -(textX + 12), 0, 28),
        pos    = UDim2.new(0, textX, 0, 32),
        parent = frame,
    })
    msgLbl.TextWrapped = true

    -- Optional action button
    if opts.Action and opts.Action.Text then
        local actBtn = _utils.button({
            name      = "ActionBtn",
            text      = opts.Action.Text,
            font      = L.fontLabel,
            textSize  = 11,
            textColor = T.accent,
            color     = T.surface,
            size      = UDim2.new(0, 70, 0, 22),
            pos       = UDim2.new(1, -82, 1, -30),
            parent    = frame,
        })
        _utils.corner(actBtn, 6)
        _animator.attachHover(actBtn, T.surface, T.card)
        actBtn.MouseButton1Click:Connect(function()
            if opts.Action.Callback then pcall(opts.Action.Callback) end
        end)
    end

    _notifActive = math.min(_notifActive + 1, MAX_NOTIFS)

    -- Animate in
    local targetPos = frame.Position
    frame.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset - 60)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Expo, Enum.EasingDirection.Out), {
        Position        = targetPos,
        GroupTransparency = 0,
    }):Play()

    -- Auto-dismiss
    local dur = opts.Duration or 3.5
    task.delay(dur, function()
        local t = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position          = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset - 50),
            GroupTransparency = 1,
        })
        t:Play()
        t.Completed:Connect(function()
            frame:Destroy()
            _notifActive = math.max(0, _notifActive - 1)
        end)
    end)
end

-- ── Group builder ─────────────────────────────────────────────────────────────

local function buildGroup(scrollParent, name, theme, layoutOrder)
    local T = theme.get()
    local L = _utils.Layout

    local container = _utils.frame({
        name         = "Group_" .. name,
        size         = UDim2.new(1, 0, 0, 0),
        color        = T.card,
        parent       = scrollParent,
    })
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.LayoutOrder   = layoutOrder or 1
    _utils.corner(container, L.radiusGroup)
    _utils.stroke(container, T.border, L.strokeTransparency)

    -- Group header
    local header = _utils.frame({
        name         = "Header",
        size         = UDim2.new(1, 0, 0, L.groupTitleHeight),
        color        = T.card,
        transparency = 1,
        parent       = container,
    })
    local headerPad = _utils.padding(header, 0, L.groupPaddingH, 0, L.groupPaddingH)

    local headerTitle = _utils.label({
        name   = "GroupTitle",
        text   = string.upper(name),
        font   = Enum.Font.GothamBold,
        size   = L.sizeGroupHdr,
        color  = T.muted,
        xAlign = Enum.TextXAlignment.Left,
        size2  = UDim2.new(1, 0, 1, 0),
        parent = header,
    })

    -- Divider below header
    local divider = _utils.frame({
        name         = "Divider",
        size         = UDim2.new(1, -(L.groupPaddingH * 2), 0, 1),
        pos          = UDim2.new(0, L.groupPaddingH, 0, L.groupTitleHeight - 1),
        color        = T.border,
        transparency = 0.5,
        parent       = container,
    })

    -- Element list
    local elemList = _utils.frame({
        name         = "Elements",
        size         = UDim2.new(1, 0, 0, 0),
        pos          = UDim2.new(0, 0, 0, L.groupTitleHeight + 4),
        color        = T.card,
        transparency = 1,
        parent       = container,
    })
    elemList.AutomaticSize = Enum.AutomaticSize.Y

    local elemLayout = _utils.listLayout(elemList, { spacing = L.elementSpacing })
    _utils.padding(elemList,
        4,
        L.groupPaddingH,
        L.groupPaddingV,
        L.groupPaddingH
    )

    -- Group object
    local Group = {}

    function Group:Rename(newName)
        headerTitle.Text = string.upper(newName)
        container.Name   = "Group_" .. newName
    end

    function Group:Clear()
        for _, child in ipairs(elemList:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end
    end

    function Group:Destroy()
        container:Destroy()
    end

    -- Reference to elemList for Tab to add elements into
    Group._elementParent = elemList

    return Group
end

-- ── Tab builder ───────────────────────────────────────────────────────────────

local function buildTab(contentArea, name, tabState)
    -- Content frame for this tab (lazy: created once, toggled visible)
    local T = _theme.get()
    local L = _utils.Layout

    local contentFrame = _utils.frame({
        name         = "TabContent_" .. name,
        size         = UDim2.new(1, 0, 1, 0),
        color        = T.bg,
        transparency = 1,
        clip         = true,
        parent       = contentArea,
    })
    contentFrame.Visible = false

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                   = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel        = 0
    scroll.ScrollBarThickness     = 4
    scroll.ScrollBarImageColor3   = T.accent
    scroll.ScrollBarImageTransparency = 0.6
    scroll.Parent                 = contentFrame

    local scrollLayout = _utils.listLayout(scroll, { spacing = L.groupSpacing })
    _utils.padding(scroll,
        L.contentPaddingV,
        L.contentPaddingH,
        L.contentPaddingV,
        L.contentPaddingH
    )

    -- Tab object
    local Tab       = {}
    local _groups   = {}
    local _lastGroup = nil
    local _layoutOrder = 0

    -- Line separator
    function Tab:Line()
        local line = _utils.frame({
            name         = "Line",
            size         = UDim2.new(1, 0, 0, 1),
            color        = T.border,
            transparency = 0.4,
            parent       = scroll,
        })
        line.LayoutOrder = _layoutOrder
        _layoutOrder += 1
    end

    -- Vertical spacer
    function Tab:Spacer(height)
        local sp = _utils.frame({
            name         = "Spacer",
            size         = UDim2.new(1, 0, 0, height or 16),
            color        = T.bg,
            transparency = 1,
            parent       = scroll,
        })
        sp.LayoutOrder = _layoutOrder
        _layoutOrder  += 1
    end

    -- Create a new Group section
    function Tab:Group(gname)
        local g = buildGroup(scroll, gname, _theme, _layoutOrder)
        _layoutOrder += 1
        _lastGroup = g
        table.insert(_groups, g)
        return g
    end

    -- Ensure there is always a group to add elements into.
    local function ensureGroup()
        if not _lastGroup then
            _lastGroup = Tab:Group("General")
        end
        return _lastGroup
    end

    -- ── Element factories on Tab ──────────────────────────────────────────────

    function Tab:Button(text, callback)
        return _elements.Button(ensureGroup()._elementParent, text, callback)
    end

    function Tab:Switch(name, state, callback, flag)
        return _elements.Switch(ensureGroup()._elementParent, name, state, callback, flag)
    end

    function Tab:Slider(name, min, max, default, callback, flag)
        return _elements.Slider(ensureGroup()._elementParent, name, min, max, default, callback, flag)
    end

    function Tab:TextField(name, placeholder, callback, flag)
        return _elements.TextField(ensureGroup()._elementParent, name, placeholder, callback, flag)
    end

    function Tab:Dropdown(name, options, default, callback, flag)
        return _elements.Dropdown(ensureGroup()._elementParent, name, options, default, callback, flag)
    end

    function Tab:ColorSelect(name, default, callback, flag)
        return _elements.ColorSelect(ensureGroup()._elementParent, name, default, callback, flag)
    end

    function Tab:Keybind(name, defaultKey, callback, flag)
        return _elements.Keybind(ensureGroup()._elementParent, name, defaultKey, callback, flag)
    end

    function Tab:Label(text, icon, color)
        return _elements.Label(ensureGroup()._elementParent, text, icon, color)
    end

    function Tab:Paragraph(title, body)
        return _elements.Paragraph(ensureGroup()._elementParent, title, body)
    end

    -- Internals used by Window
    Tab._contentFrame = contentFrame
    Tab._scroll       = scroll

    return Tab
end

-- ── Window builder ────────────────────────────────────────────────────────────

function Core.BuildWindow(opts, state)
    local T       = _theme.get(opts.Theme)
    local L       = _utils.Layout
    local isMobile = _utils.isMobile()

    local W, H    = _utils.windowSize()
    local sideW   = _utils.sidebarWidth()
    local animStyle = "Brisk"

    -- ── PlayerGui container ───────────────────────────────────────────────────

    local pg = getPlayerGui()
    assert(pg, "[Velvet] Failed to get PlayerGui.")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name           = "VelvetUI_" .. _utils.uid()
    screenGui.ResetOnSpawn   = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder   = 10
    screenGui.Parent         = pg

    -- ── Root canvas group (used for window open/close fade) ───────────────────

    local root = Instance.new("CanvasGroup")
    root.Name                 = "WindowRoot"
    root.Size                 = UDim2.new(0, W, 0, H)
    root.Position             = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
    root.BackgroundColor3     = T.bg
    root.GroupTransparency    = 1
    root.BorderSizePixel      = 0
    root.Parent               = screenGui
    _utils.corner(root, L.radiusWindow)
    _utils.stroke(root, T.border, 0.75)

    -- Subtle depth gradient on the window background
    _utils.gradient(root,
        ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(24, 20, 34)),
            ColorSequenceKeypoint.new(1,   T.bg),
        }),
        110
    )

    -- ── Topbar ────────────────────────────────────────────────────────────────

    local topbar = _utils.frame({
        name         = "Topbar",
        size         = UDim2.new(1, 0, 0, L.topbarHeight),
        color        = T.topbar,
        parent       = root,
    })
    -- Faint bottom border on topbar
    local topbarBorder = _utils.frame({
        name         = "TopbarBorder",
        size         = UDim2.new(1, 0, 0, 1),
        pos          = UDim2.new(0, 0, 1, -1),
        color        = T.border,
        transparency = 0.5,
        parent       = topbar,
    })

    -- App icon
    local iconLbl = _utils.label({
        name   = "AppIcon",
        text   = opts.Icon or "◈",
        font   = Enum.Font.GothamBold,
        size   = 18,
        color  = T.accent,
        size2  = UDim2.new(0, L.topbarHeight, 1, 0),
        pos    = UDim2.new(0, 0, 0, 0),
        xAlign = Enum.TextXAlignment.Center,
        parent = topbar,
    })

    -- Title label
    local titleLbl = _utils.label({
        name   = "Title",
        text   = opts.Title or "Velvet UI",
        font   = L.fontTitle,
        size   = L.sizeTitle,
        color  = T.text,
        size2  = UDim2.new(1, -(L.topbarHeight * 2 + 8), 1, 0),
        pos    = UDim2.new(0, L.topbarHeight + 4, 0, 0),
        xAlign = Enum.TextXAlignment.Left,
        parent = topbar,
    })

    -- Close button
    local closeBtn = _utils.button({
        name        = "CloseBtn",
        text        = "✕",
        font        = Enum.Font.GothamBold,
        textSize    = 12,
        textColor   = T.muted,
        color       = T.topbar,
        transparency = 0,
        size        = UDim2.new(0, L.topbarHeight, 1, 0),
        pos         = UDim2.new(1, -L.topbarHeight, 0, 0),
        parent      = topbar,
    })
    _animator.attachHover(closeBtn, T.topbar, T.danger)

    -- Make topbar draggable
    makeDraggable(topbar, root)

    -- ── Body (sidebar + content) ──────────────────────────────────────────────

    local body = _utils.frame({
        name         = "Body",
        size         = UDim2.new(1, 0, 1, -L.topbarHeight),
        pos          = UDim2.new(0, 0, 0, L.topbarHeight),
        color        = T.bg,
        transparency = 1,
        parent       = root,
    })

    -- ── Sidebar ───────────────────────────────────────────────────────────────

    local sidebar = _utils.frame({
        name         = "Sidebar",
        size         = UDim2.new(0, sideW, 1, 0),
        color        = T.sidebar,
        parent       = body,
    })

    -- Right border on sidebar
    local sidebarBorder = _utils.frame({
        name         = "SidebarBorder",
        size         = UDim2.new(0, 1, 1, 0),
        pos          = UDim2.new(1, -1, 0, 0),
        color        = T.border,
        transparency = 0.5,
        parent       = sidebar,
    })

    -- Tab button list inside sidebar
    local tabList = _utils.frame({
        name         = "TabList",
        size         = UDim2.new(1, 0, 1, 0),
        color        = T.sidebar,
        transparency = 1,
        parent       = sidebar,
    })
    local tabListLayout = _utils.listLayout(tabList, { spacing = 2 })
    _utils.padding(tabList, 8, 6, 8, 6)

    -- Mobile collapse/expand button
    local _sidebarExpanded = not isMobile
    local collapseBtn = nil

    if isMobile then
        collapseBtn = _utils.button({
            name        = "CollapseBtn",
            text        = "≡",
            font        = Enum.Font.GothamBold,
            textSize    = 18,
            textColor   = T.muted,
            color       = T.sidebar,
            transparency = 0,
            size        = UDim2.new(1, 0, 0, 40),
            parent      = tabList,
        })
        _animator.attachHover(collapseBtn, T.sidebar, T.surface)
        collapseBtn.LayoutOrder = -1

        collapseBtn.MouseButton1Click:Connect(function()
            _sidebarExpanded = not _sidebarExpanded
            local targetW = _sidebarExpanded and L.sidebarWidthDesktop or L.sidebarWidthMobile
            _animator.tween(sidebar, "MEDIUM", { Size = UDim2.new(0, targetW, 1, 0) })
            -- Also shift content area
            local contentArea = body:FindFirstChild("ContentArea")
            if contentArea then
                _animator.tween(contentArea, "MEDIUM", {
                    Size     = UDim2.new(1, -targetW, 1, 0),
                    Position = UDim2.new(0, targetW, 0, 0),
                })
            end
        end)
    end

    -- ── Content area ──────────────────────────────────────────────────────────

    local contentArea = _utils.frame({
        name         = "ContentArea",
        size         = UDim2.new(1, -sideW, 1, 0),
        pos          = UDim2.new(0, sideW, 0, 0),
        color        = T.bg,
        transparency = 0,
        clip         = true,
        parent       = body,
    })

    -- ── Window state ──────────────────────────────────────────────────────────

    local _tabs      = {}
    local _activeTab = nil
    local _tabBtns   = {}
    local _visible   = true

    local function activateTab(id)
        local prev = _tabs[_activeTab]
        local next = _tabs[id]
        if not next then return end

        -- Update sidebar button visuals
        for tabId, btn in pairs(_tabBtns) do
            local isActive = (tabId == id)
            _animator.tween(btn.bg, "FAST", {
                BackgroundColor3     = isActive and T.surface or T.sidebar,
                BackgroundTransparency = isActive and 0 or 0,
            })
            _animator.tween(btn.accent, "FAST", {
                BackgroundTransparency = isActive and 0 or 1,
            })
            btn.lbl.TextColor3 = isActive and T.text or T.muted
            if btn.iconLbl then
                btn.iconLbl.TextColor3 = isActive and T.accent or T.muted
            end
        end

        -- Cross-fade content
        local outFrame = prev and prev._contentFrame or nil
        local inFrame  = next._contentFrame

        -- Lazy-show: ensure the frame is initialised
        if outFrame and outFrame ~= inFrame then
            _animator.tween(outFrame, "TAB", { BackgroundTransparency = 1 })
            task.delay(0.12, function()
                outFrame.Visible = false
            end)
        end

        task.delay(0.05, function()
            inFrame.BackgroundTransparency = 1
            inFrame.Visible = true
            _animator.tween(inFrame, "TAB", { BackgroundTransparency = 0 })
        end)

        _activeTab = id
    end

    -- ── Window object ─────────────────────────────────────────────────────────

    local Window = {}

    function Window:AddTab(name, icon)
        local id  = _utils.uid()
        local tab = buildTab(contentArea, name, { _activeTab = id })
        _tabs[id] = tab

        -- Create sidebar button
        local btnH = isMobile and L.tabButtonHeightM or L.tabButtonHeightD

        local btnBg = _utils.frame({
            name         = "TabBtn_" .. name,
            size         = UDim2.new(1, 0, 0, btnH),
            color        = T.sidebar,
            parent       = tabList,
        })
        _utils.corner(btnBg, 8)

        -- Accent bar (left edge, visible when active)
        local accentBar = _utils.frame({
            name         = "Accent",
            size         = UDim2.new(0, 3, 0.6, 0),
            pos          = UDim2.new(0, 0, 0.2, 0),
            color        = T.accent,
            parent       = btnBg,
        })
        _utils.corner(accentBar, 2)
        accentBar.BackgroundTransparency = 1  -- hidden by default

        -- Icon label (always visible on sidebar)
        local iconLabel = nil
        if icon then
            iconLabel = _utils.label({
                name   = "Icon",
                text   = icon,
                font   = Enum.Font.Gotham,
                size   = L.tabIconSize,
                color  = T.muted,
                size2  = UDim2.new(0, btnH, 1, 0),
                pos    = UDim2.new(0, 0, 0, 0),
                xAlign = Enum.TextXAlignment.Center,
                parent = btnBg,
            })
        end

        -- Text label (hidden on mobile collapsed)
        local textX = icon and btnH or 12
        local textLabel = _utils.label({
            name   = "TabLabel",
            text   = name,
            font   = L.fontLabel,
            size   = L.sizeLabel,
            color  = T.muted,
            size2  = UDim2.new(1, -(textX + 4), 1, 0),
            pos    = UDim2.new(0, textX, 0, 0),
            xAlign = Enum.TextXAlignment.Left,
            parent = btnBg,
        })
        textLabel.Visible = not (isMobile and not _sidebarExpanded)

        -- Hit button
        local hitBtn = _utils.button({
            name         = "Hit",
            color        = Color3.new(1,1,1),
            transparency = 1,
            size         = UDim2.new(1, 0, 1, 0),
            parent       = btnBg,
        })
        hitBtn.MouseButton1Click:Connect(function()
            activateTab(id)
        end)
        _animator.attachHover(hitBtn, Color3.new(1,1,1), Color3.new(1,1,1))

        _tabBtns[id] = {
            bg      = btnBg,
            accent  = accentBar,
            lbl     = textLabel,
            iconLbl = iconLabel,
        }

        -- Auto-activate first tab
        if not _activeTab then
            activateTab(id)
        end

        return tab
    end

    function Window:Dress(themeName)
        -- Full re-skin is complex; we just update the active theme pointer
        -- and adjust key colours for a live preview feel.
        _theme.setActive(themeName)
        local NT = _theme.get(themeName)
        root.BackgroundColor3 = NT.bg
        topbar.BackgroundColor3 = NT.topbar
        sidebar.BackgroundColor3 = NT.sidebar
        contentArea.BackgroundColor3 = NT.bg
        -- Note: element-level re-theming would require a full rebuild.
        -- For a full re-theme, call Window:Destroy() and rebuild.
    end

    function Window:Animate(style)
        animStyle = style
        _animator.setDefaultStyle(style)
    end

    function Window:Show()
        _visible = true
        _animator.openWindow(root, animStyle)
    end

    function Window:Hide()
        _visible = false
        _animator.closeWindow(root, animStyle)
    end

    function Window:Rename(newTitle)
        titleLbl.Text = newTitle
    end

    function Window:_destroy()
        screenGui:Destroy()
    end

    function Window:_applyFont(font)
        -- Recursively update all TextLabel and TextButton fonts
        local function apply(inst)
            for _, child in ipairs(inst:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    pcall(function() child.Font = font end)
                end
            end
        end
        apply(root)
    end

    -- Close button wires to Hide
    closeBtn.MouseButton1Click:Connect(function()
        Window:Hide()
    end)

    -- Toggle key support
    if opts.Key then
        UserInputService.InputBegan:Connect(function(inp, processed)
            if processed then return end
            if inp.KeyCode.Name == opts.Key then
                if _visible then
                    Window:Hide()
                else
                    Window:Show()
                end
            end
        end)
    end

    -- Open with animation
    Window:Show()

    return Window
end

return Core
