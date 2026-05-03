--[[
    Velvet UI — Elements.lua
    All interactive and static element builders.
    Returns a factory table; each function receives (parent, theme, animator, config, utils, opts).
    MIT License
--]]

local UserInputService = game:GetService("UserInputService")

local Elements = {}

-- Injected references (set by Core._init)
local _theme, _animator, _config, _utils

function Elements._init(theme, animator, config, utils)
    _theme    = theme
    _animator = animator
    _config   = config
    _utils    = utils
end

-- ── Shared helpers ────────────────────────────────────────────────────────────

local L = nil  -- assigned after _init via getter
local function layout() return _utils.Layout end

-- Build a standard element row container.
local function makeRow(parent, name, height)
    local row = _utils.frame({
        name         = name or "Row",
        size         = UDim2.new(1, 0, 0, height or layout().elementHeight),
        color        = _theme.get().surface,
        transparency = 0,
        clip         = false,
        parent       = parent,
    })
    _utils.corner(row, layout().radiusElement)
    _utils.stroke(row, _theme.get().border, layout().strokeTransparency)
    return row
end

-- Add a leading label to a row and return the remaining right side x offset.
local function makeRowLabel(row, text, font)
    local T = _theme.get()
    local lbl = _utils.label({
        name   = "Label",
        text   = text,
        font   = font or layout().fontLabel,
        size   = layout().sizeElement,
        color  = T.text,
        xAlign = Enum.TextXAlignment.Left,
        size2  = UDim2.new(0.55, -8, 1, 0),
        pos    = UDim2.new(0, layout().groupPaddingH, 0, 0),
        parent = row,
    })
    return lbl
end

-- Visibility helpers shared by all elements.
local function makeVisibilityControl(root)
    return {
        Hide  = function() root.Visible = false end,
        Show  = function() root.Visible = true  end,
    }
end

-- ── Button ────────────────────────────────────────────────────────────────────

function Elements.Button(parent, text, callback, flag)
    local T = _theme.get()
    local L = layout()
    local _locked   = false
    local _text     = text

    local row = _utils.frame({
        name         = "ButtonRow",
        size         = UDim2.new(1, 0, 0, L.elementHeight),
        color        = T.surface,
        transparency = 0,
        clip         = false,
        parent       = parent,
    })
    _utils.corner(row, L.radiusButton)
    _utils.stroke(row, T.border, L.strokeTransparency)

    local btn = _utils.button({
        name        = "Btn",
        text        = text,
        font        = L.fontLabel,
        textSize    = L.sizeElement,
        textColor   = T.text,
        color       = T.surface,
        transparency = 0,
        size        = UDim2.new(1, 0, 1, 0),
        parent      = row,
    })
    _utils.corner(btn, L.radiusButton)

    -- Accent left bar (3px, indicates interactability)
    local bar = _utils.frame({
        name         = "AccentBar",
        size         = UDim2.new(0, 3, 0.6, 0),
        pos          = UDim2.new(0, 0, 0.2, 0),
        color        = T.accent,
        parent       = btn,
    })
    _utils.corner(bar, 2)

    _animator.attachHover(btn, T.surface, T.card)
    _animator.attachPressScale(btn)

    btn.MouseButton1Click:Connect(function()
        if _locked then return end
        if callback then
            local ok, err = pcall(callback)
            if not ok then warn("[Velvet/Button] Callback error: " .. tostring(err)) end
        end
    end)

    local self = makeVisibilityControl(row)

    function self.SetText(t)
        _text = t
        btn.Text = t
    end

    function self.Lock()
        _locked = true
        btn.TextColor3 = T.muted
        _animator.tween(bar, "FAST", { BackgroundColor3 = T.muted })
    end

    function self.Unlock()
        _locked = false
        btn.TextColor3 = T.text
        _animator.tween(bar, "FAST", { BackgroundColor3 = T.accent })
    end

    return self
end

-- ── Switch ────────────────────────────────────────────────────────────────────

function Elements.Switch(parent, name, default, callback, flag)
    local T    = _theme.get()
    local L    = layout()
    local _on  = default == true

    local row = makeRow(parent, "SwitchRow")
    makeRowLabel(row, name)

    -- Switch container (pill shape)
    local TRACK_W, TRACK_H = 44, 24
    local THUMB_SIZE        = TRACK_H - 6  -- 18px
    local THUMB_TRAVEL      = TRACK_W - THUMB_SIZE - 6  -- how far thumb slides

    local track = _utils.frame({
        name         = "Track",
        size         = UDim2.new(0, TRACK_W, 0, TRACK_H),
        pos          = UDim2.new(1, -(TRACK_W + L.groupPaddingH), 0.5, -TRACK_H / 2),
        color        = _on and T.switchOn or T.switchOff,
        parent       = row,
    })
    _utils.corner(track, L.radiusSwitch)

    local thumb = _utils.frame({
        name         = "Thumb",
        size         = UDim2.new(0, THUMB_SIZE, 0, THUMB_SIZE),
        pos          = _on
            and UDim2.new(0, THUMB_TRAVEL + 3, 0.5, -THUMB_SIZE / 2)
            or  UDim2.new(0, 3,               0.5, -THUMB_SIZE / 2),
        color        = T.sliderThumb,
        parent       = track,
    })
    _utils.corner(thumb, L.radiusSliderThumb)

    local function setVisual(on)
        _animator.tween(track, "FAST", { BackgroundColor3 = on and T.switchOn or T.switchOff })
        _animator.tween(thumb, "FAST", {
            Position = on
                and UDim2.new(0, THUMB_TRAVEL + 3, 0.5, -THUMB_SIZE / 2)
                or  UDim2.new(0, 3,               0.5, -THUMB_SIZE / 2),
        })
    end

    -- Clicking anywhere on the row toggles
    local btn = _utils.button({
        name         = "HitTarget",
        color        = T.surface,
        transparency = 1,
        size         = UDim2.new(1, 0, 1, 0),
        parent       = row,
    })

    btn.MouseButton1Click:Connect(function()
        _on = not _on
        setVisual(_on)
        if flag then _config.save(flag, _on) end
        if callback then
            local ok, err = pcall(callback, _on)
            if not ok then warn("[Velvet/Switch] Callback error: " .. tostring(err)) end
        end
    end)

    if flag then
        _config.register(flag, default, function(v)
            _on = v
            setVisual(v)
        end)
    end

    local self = makeVisibilityControl(row)

    function self.Flip()
        btn.MouseButton1Click:Fire()
    end

    function self.SetState(bool)
        if bool == _on then return end
        _on = bool
        setVisual(bool)
        if flag then _config.save(flag, bool) end
    end

    function self.GetState()
        return _on
    end

    return self
end

-- ── Slider ────────────────────────────────────────────────────────────────────

function Elements.Slider(parent, name, min, max, default, callback, flag)
    local T    = _theme.get()
    local L    = layout()
    local _min = min or 0
    local _max = max or 100
    local _val = _utils.clamp(default or _min, _min, _max)

    -- Two-row element: label row + slider row
    local wrapper = _utils.frame({
        name         = "SliderWrapper",
        size         = UDim2.new(1, 0, 0, L.elementHeight + 20),
        color        = T.surface,
        clip         = false,
        parent       = parent,
    })
    _utils.corner(wrapper, L.radiusElement)
    _utils.stroke(wrapper, T.border, L.strokeTransparency)

    -- Label row
    local topRow = _utils.frame({
        name   = "TopRow",
        size   = UDim2.new(1, 0, 0, 26),
        color  = T.surface,
        transparency = 1,
        parent = wrapper,
    })
    makeRowLabel(topRow, name)

    -- Value display (right-aligned)
    local valLbl = _utils.label({
        name   = "ValueLabel",
        text   = tostring(_utils.round(_val, 1)),
        font   = L.fontLabel,
        size   = L.sizeElement,
        color  = T.rose,
        xAlign = Enum.TextXAlignment.Right,
        size2  = UDim2.new(0, 60, 1, 0),
        pos    = UDim2.new(1, -(60 + L.groupPaddingH), 0, 0),
        parent = topRow,
    })

    -- Track area
    local TRACK_H    = 6
    local THUMB_SIZE = 16
    local PADDING_H  = L.groupPaddingH + THUMB_SIZE / 2

    local trackBg = _utils.frame({
        name         = "TrackBg",
        size         = UDim2.new(1, -(PADDING_H * 2), 0, TRACK_H),
        pos          = UDim2.new(0, PADDING_H, 0, 30),
        color        = T.sliderTrack,
        clip         = true,
        parent       = wrapper,
    })
    _utils.corner(trackBg, L.radiusSliderTrack)

    local trackFill = _utils.frame({
        name         = "Fill",
        size         = UDim2.new((_val - _min) / (_max - _min), 0, 1, 0),
        color        = T.sliderFill,
        parent       = trackBg,
    })
    _utils.corner(trackFill, L.radiusSliderTrack)

    local thumb = _utils.frame({
        name         = "Thumb",
        size         = UDim2.new(0, THUMB_SIZE, 0, THUMB_SIZE),
        pos          = UDim2.new((_val - _min) / (_max - _min), -THUMB_SIZE / 2, 0, -THUMB_SIZE / 2 + TRACK_H / 2),
        color        = T.sliderThumb,
        parent       = trackBg,
    })
    _utils.corner(thumb, L.radiusSliderThumb)
    _utils.stroke(thumb, T.accent, 0.5, 2)

    -- Drag logic (works for mouse and touch)
    local _dragging = false

    local function applyValue(v)
        v = _utils.clamp(v, _min, _max)
        local pct = (v - _min) / (_max - _min)
        _val = v
        valLbl.Text = tostring(_utils.round(v, 1))
        trackFill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -THUMB_SIZE / 2, 0, -THUMB_SIZE / 2 + TRACK_H / 2)
        if flag then _config.save(flag, v) end
        if callback then
            local ok, err = pcall(callback, v)
            if not ok then warn("[Velvet/Slider] Callback error: " .. tostring(err)) end
        end
    end

    local function mousePosToValue(x)
        local abs = trackBg.AbsolutePosition.X
        local wid = trackBg.AbsoluteSize.X
        local pct = _utils.clamp((x - abs) / wid, 0, 1)
        return _min + pct * (_max - _min)
    end

    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            _dragging = true
        end
    end)

    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            applyValue(mousePosToValue(inp.Position.X))
            _dragging = true
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not _dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
            applyValue(mousePosToValue(inp.Position.X))
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            _dragging = false
        end
    end)

    if flag then
        _config.register(flag, default, function(v)
            applyValue(v)
        end)
    end

    local self = makeVisibilityControl(wrapper)

    function self.SetValue(v)   applyValue(v) end
    function self.GetValue()    return _val    end
    function self.SetRange(mn, mx)
        _min, _max = mn, mx
        applyValue(_utils.clamp(_val, mn, mx))
    end

    return self
end

-- ── TextField ─────────────────────────────────────────────────────────────────

function Elements.TextField(parent, name, placeholder, callback, flag)
    local T = _theme.get()
    local L = layout()

    local row = makeRow(parent, "TextFieldRow", L.elementHeight + 12)
    makeRowLabel(row, name)

    -- Input box (right half)
    local INPUT_W = 160
    local box = _utils.textbox({
        name             = "Input",
        placeholder      = placeholder or "",
        color            = T.bg,
        textColor        = T.text,
        placeholderColor = T.muted,
        size             = UDim2.new(0, INPUT_W, 0, 30),
        pos              = UDim2.new(1, -(INPUT_W + L.groupPaddingH), 0.5, -15),
        parent           = row,
    })
    _utils.corner(box, L.radiusElement)
    _utils.stroke(box, T.border, L.strokeTransparency)
    _utils.padding(box, 0, 8, 0, 8)

    -- Focus animation
    local stroke = box:FindFirstChildOfClass("UIStroke")
    box.Focused:Connect(function()
        if stroke then stroke.Transparency = L.strokeFocused end
    end)
    box.FocusLost:Connect(function(enter)
        if stroke then stroke.Transparency = L.strokeTransparency end
        local val = box.Text
        if flag then _config.save(flag, val) end
        if callback then
            local ok, err = pcall(callback, val, enter)
            if not ok then warn("[Velvet/TextField] Callback error: " .. tostring(err)) end
        end
    end)

    if flag then
        _config.register(flag, box.Text, function(v)
            box.Text = v or ""
        end)
    end

    local self = makeVisibilityControl(row)
    function self.SetText(t) box.Text = t end
    function self.GetText()  return box.Text end
    function self.Clear()    box.Text = "" end

    return self
end

-- ── Dropdown ──────────────────────────────────────────────────────────────────

function Elements.Dropdown(parent, name, options, default, callback, flag)
    local T         = _theme.get()
    local L         = layout()
    local _options  = options or {}
    local _selected = default or (_options[1] and _options[1] or "")
    local _open     = false
    local _isMobile = _utils.isMobile()

    local DROPDOWN_W = 160
    local ROW_H      = L.elementHeight

    local row = makeRow(parent, "DropdownRow", ROW_H)
    makeRowLabel(row, name)

    -- Display button
    local dispBtn = _utils.button({
        name        = "DispBtn",
        text        = _selected,
        font        = L.fontBody,
        textSize    = L.sizeElement,
        textColor   = T.text,
        color       = T.bg,
        size        = UDim2.new(0, DROPDOWN_W, 0, 30),
        pos         = UDim2.new(1, -(DROPDOWN_W + L.groupPaddingH), 0.5, -15),
        parent      = row,
    })
    _utils.corner(dispBtn, L.radiusDropdown)
    _utils.stroke(dispBtn, T.border, L.strokeTransparency)

    -- Chevron icon (simple "▾" text)
    local chevron = _utils.label({
        name   = "Chevron",
        text   = "▾",
        font   = L.fontBody,
        size   = 14,
        color  = T.muted,
        xAlign = Enum.TextXAlignment.Right,
        size2  = UDim2.new(0, 20, 1, 0),
        pos    = UDim2.new(1, -22, 0, 0),
        parent = dispBtn,
    })

    -- Popup list (absolutely positioned, high ZIndex)
    local POPUP_MAX_H  = math.min(#_options * 36 + 8, 200)
    local popup = _utils.frame({
        name         = "Popup",
        size         = UDim2.new(0, DROPDOWN_W, 0, POPUP_MAX_H),
        color        = T.card,
        transparency = 0,
        clip         = true,
        zIndex       = 10,
        parent       = row,
    })
    popup.Position = UDim2.new(1, -(DROPDOWN_W + L.groupPaddingH), 1, 4)
    popup.Visible  = false
    _utils.corner(popup, L.radiusDropdown)
    _utils.stroke(popup, T.border, L.strokeTransparency)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size                  = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel        = 0
    scroll.ScrollBarThickness     = 3
    scroll.ScrollBarImageColor3   = T.accent
    scroll.CanvasSize             = UDim2.new(0, 0, 0, #_options * 36 + 8)
    scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    scroll.ZIndex                 = 10
    scroll.Parent                 = popup

    local optLayout = _utils.listLayout(scroll, { spacing = 2 })
    _utils.padding(scroll, 4, 4, 4, 4)

    local _optionBtns = {}

    local function rebuildOptions()
        for _, b in ipairs(_optionBtns) do b:Destroy() end
        _optionBtns = {}

        for _, opt in ipairs(_options) do
            local obtn = _utils.button({
                name      = "Opt_" .. opt,
                text      = opt,
                font      = L.fontBody,
                textSize  = L.sizeBody,
                textColor = (opt == _selected) and T.accent or T.text,
                color     = (opt == _selected) and T.surface or T.card,
                size      = UDim2.new(1, 0, 0, 32),
                xAlign    = Enum.TextXAlignment.Left,
                zIndex    = 11,
                parent    = scroll,
            })
            _utils.corner(obtn, 6)
            _utils.padding(obtn, 0, 0, 0, 10)

            _animator.attachHover(obtn, (opt == _selected) and T.surface or T.card, T.surface)

            obtn.MouseButton1Click:Connect(function()
                _selected = opt
                dispBtn.Text = opt
                for _, b in ipairs(_optionBtns) do
                    b.BackgroundColor3 = T.card
                    b.TextColor3       = T.text
                end
                obtn.BackgroundColor3 = T.surface
                obtn.TextColor3       = T.accent

                -- Close
                _open = false
                _animator.tween(popup, "FAST", { Size = UDim2.new(0, DROPDOWN_W, 0, 0) })
                task.delay(0.15, function() popup.Visible = false end)
                _animator.tween(chevron, "FAST", { Rotation = 0 })

                if flag then _config.save(flag, opt) end
                if callback then
                    local ok, err = pcall(callback, opt)
                    if not ok then warn("[Velvet/Dropdown] Callback error: " .. tostring(err)) end
                end
            end)
            table.insert(_optionBtns, obtn)
        end
    end

    rebuildOptions()

    dispBtn.MouseButton1Click:Connect(function()
        _open = not _open
        if _open then
            popup.Size    = UDim2.new(0, DROPDOWN_W, 0, 0)
            popup.Visible = true
            _animator.tween(popup, "MEDIUM", { Size = UDim2.new(0, DROPDOWN_W, 0, POPUP_MAX_H) })
            _animator.tween(chevron, "FAST", { Rotation = 180 })
        else
            _animator.tween(popup, "FAST", { Size = UDim2.new(0, DROPDOWN_W, 0, 0) })
            task.delay(0.15, function() popup.Visible = false end)
            _animator.tween(chevron, "FAST", { Rotation = 0 })
        end
    end)

    if flag then
        _config.register(flag, default, function(v)
            _selected = v
            dispBtn.Text = v
        end)
    end

    local self = makeVisibilityControl(row)

    function self.Select(opt)
        for _, b in ipairs(_optionBtns) do
            if b.Name == "Opt_" .. opt then
                b.MouseButton1Click:Fire()
                return
            end
        end
    end

    function self.GetSelected()
        return _selected
    end

    function self.ReplaceOptions(list)
        _options = list
        _selected = list[1] or ""
        dispBtn.Text = _selected
        rebuildOptions()
    end

    return self
end

-- ── ColorSelect ───────────────────────────────────────────────────────────────

function Elements.ColorSelect(parent, name, default, callback, flag)
    local T       = _theme.get()
    local L       = layout()
    local _color  = default or Color3.fromRGB(255, 100, 100)
    local _open   = false

    local SWATCH_SIZE = 30
    local PICKER_W, PICKER_H = 200, 180

    local row = makeRow(parent, "ColorSelectRow")
    makeRowLabel(row, name)

    -- Colour swatch button
    local swatch = _utils.frame({
        name   = "Swatch",
        size   = UDim2.new(0, SWATCH_SIZE, 0, SWATCH_SIZE),
        pos    = UDim2.new(1, -(SWATCH_SIZE + L.groupPaddingH), 0.5, -SWATCH_SIZE / 2),
        color  = _color,
        parent = row,
    })
    _utils.corner(swatch, 6)
    _utils.stroke(swatch, T.border, L.strokeTransparency)

    local hitBtn = _utils.button({
        color        = Color3.new(1,1,1),
        transparency = 1,
        size         = UDim2.new(1, 0, 1, 0),
        parent       = swatch,
    })

    -- Simple HSV picker popup
    local picker = _utils.frame({
        name         = "Picker",
        size         = UDim2.new(0, PICKER_W, 0, PICKER_H),
        pos          = UDim2.new(1, -(PICKER_W + L.groupPaddingH), 1, 8),
        color        = T.card,
        clip         = true,
        zIndex       = 12,
        parent       = row,
    })
    picker.Visible = false
    _utils.corner(picker, L.radiusDropdown)
    _utils.stroke(picker, T.border, L.strokeTransparency)
    _utils.padding(picker, 10, 10, 10, 10)

    -- Hue gradient strip
    local HUE_H = 16
    local hueSV = _utils.frame({
        name  = "HueSV",
        size  = UDim2.new(1, 0, 1, -(HUE_H + 16)),
        color = Color3.fromHSV(0, 1, 1),
        zIndex = 13,
        parent = picker,
    })
    _utils.corner(hueSV, 4)
    -- White → transparent horizontal
    local whiteGrad = Instance.new("UIGradient")
    whiteGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1, Color3.new(1,1,1)),
    })
    whiteGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    whiteGrad.Parent = hueSV

    -- Black bottom overlay
    local blackFrame = _utils.frame({
        name         = "BlackOverlay",
        size         = UDim2.new(1, 0, 1, 0),
        color        = Color3.new(0,0,0),
        transparency = 0,
        zIndex       = 14,
        parent       = hueSV,
    })
    _utils.corner(blackFrame, 4)
    local blackGrad = Instance.new("UIGradient")
    blackGrad.Color = ColorSequence.new(Color3.new(0,0,0))
    blackGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    blackGrad.Rotation = 270
    blackGrad.Parent = blackFrame

    -- SV thumb
    local _h, _s, _v = Color3.toHSV(_color)
    local svThumb = _utils.frame({
        name         = "SVThumb",
        size         = UDim2.new(0, 12, 0, 12),
        pos          = UDim2.new(_s, -6, 1 - _v, -6),
        color        = Color3.new(1,1,1),
        zIndex       = 15,
        parent       = hueSV,
    })
    _utils.corner(svThumb, 6)
    _utils.stroke(svThumb, Color3.new(0,0,0), 0.3)

    -- Hue strip
    local hueStrip = _utils.frame({
        name   = "HueStrip",
        size   = UDim2.new(1, 0, 0, HUE_H),
        pos    = UDim2.new(0, 0, 1, -(HUE_H)),
        color  = Color3.new(1,0,0),
        zIndex = 13,
        parent = picker,
    })
    _utils.corner(hueStrip, 4)
    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromHSV(0,   1,1)),
        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1,1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
        ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5, 1,1)),
        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1,1)),
        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
        ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,   1,1)),
    })
    hueGrad.Parent = hueStrip

    local function updateColor()
        _color = Color3.fromHSV(_h, _s, _v)
        swatch.BackgroundColor3 = _color
        hueSV.BackgroundColor3  = Color3.fromHSV(_h, 1, 1)
        svThumb.Position = UDim2.new(_s, -6, 1 - _v, -6)
        if flag then _config.save(flag, { _color.R, _color.G, _color.B }) end
        if callback then
            local ok, err = pcall(callback, _color)
            if not ok then warn("[Velvet/ColorSelect] Callback error: " .. tostring(err)) end
        end
    end

    -- Drag on SV area
    local _draggingSV = false
    hueSV.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            _draggingSV = true
            local rel = hueSV.AbsolutePosition
            local sz  = hueSV.AbsoluteSize
            _s = _utils.clamp((inp.Position.X - rel.X) / sz.X, 0, 1)
            _v = 1 - _utils.clamp((inp.Position.Y - rel.Y) / sz.Y, 0, 1)
            updateColor()
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not _draggingSV then return end
        local rel = hueSV.AbsolutePosition
        local sz  = hueSV.AbsoluteSize
        _s = _utils.clamp((inp.Position.X - rel.X) / sz.X, 0, 1)
        _v = 1 - _utils.clamp((inp.Position.Y - rel.Y) / sz.Y, 0, 1)
        updateColor()
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            _draggingSV = false
        end
    end)

    -- Drag on hue strip
    local _draggingHue = false
    hueStrip.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            _draggingHue = true
            local rel = hueStrip.AbsolutePosition
            local sz  = hueStrip.AbsoluteSize
            _h = _utils.clamp((inp.Position.X - rel.X) / sz.X, 0, 1)
            updateColor()
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not _draggingHue then return end
        local rel = hueStrip.AbsolutePosition
        local sz  = hueStrip.AbsoluteSize
        _h = _utils.clamp((inp.Position.X - rel.X) / sz.X, 0, 1)
        updateColor()
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            _draggingHue = false
        end
    end)

    hitBtn.MouseButton1Click:Connect(function()
        _open = not _open
        if _open then
            picker.Size    = UDim2.new(0, PICKER_W, 0, 0)
            picker.Visible = true
            _animator.tween(picker, "MEDIUM", { Size = UDim2.new(0, PICKER_W, 0, PICKER_H) })
        else
            _animator.tween(picker, "FAST", { Size = UDim2.new(0, PICKER_W, 0, 0) })
            task.delay(0.15, function() picker.Visible = false end)
        end
    end)

    if flag then
        _config.register(flag, { _color.R, _color.G, _color.B }, function(v)
            if type(v) == "table" then
                _color = Color3.new(v[1], v[2], v[3])
                _h, _s, _v = Color3.toHSV(_color)
                swatch.BackgroundColor3 = _color
                hueSV.BackgroundColor3  = Color3.fromHSV(_h, 1, 1)
                svThumb.Position = UDim2.new(_s, -6, 1 - _v, -6)
            end
        end)
    end

    local self = makeVisibilityControl(row)
    function self.SetColor(c)
        _color = c
        _h, _s, _v = Color3.toHSV(c)
        swatch.BackgroundColor3 = c
    end
    function self.GetColor() return _color end

    return self
end

-- ── Keybind ───────────────────────────────────────────────────────────────────

function Elements.Keybind(parent, name, defaultKey, callback, flag)
    local T        = _theme.get()
    local L        = layout()
    local _key     = defaultKey or "None"
    local _binding = false

    -- Hide on mobile automatically
    if _utils.isMobile() then
        local dummy = { Hide = function() end, Show = function() end, Bind = function() end,
                        GetKey = function() return _key end, Clear = function() end }
        return dummy
    end

    local row = makeRow(parent, "KeybindRow")
    makeRowLabel(row, name)

    local keyBtn = _utils.button({
        name      = "KeyBtn",
        text      = "[" .. _key .. "]",
        font      = L.fontBody,
        textSize  = L.sizeElement,
        textColor = T.rose,
        color     = T.bg,
        size      = UDim2.new(0, 90, 0, 28),
        pos       = UDim2.new(1, -(90 + L.groupPaddingH), 0.5, -14),
        parent    = row,
    })
    _utils.corner(keyBtn, L.radiusElement)
    _utils.stroke(keyBtn, T.border, L.strokeTransparency)
    _animator.attachHover(keyBtn, T.bg, T.surface)

    keyBtn.MouseButton1Click:Connect(function()
        _binding = true
        keyBtn.Text      = "[...]"
        keyBtn.TextColor3 = T.accent
    end)

    UserInputService.InputBegan:Connect(function(inp, processed)
        if not _binding then
            -- Fire callback if bound key pressed
            if inp.KeyCode.Name == _key and not processed then
                if callback then pcall(callback, _key) end
            end
            return
        end
        if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
        _key     = inp.KeyCode.Name
        _binding = false
        keyBtn.Text       = "[" .. _key .. "]"
        keyBtn.TextColor3 = T.rose
        if flag then _config.save(flag, _key) end
        if callback then pcall(callback, _key) end
    end)

    if flag then
        _config.register(flag, defaultKey, function(v)
            _key = v
            keyBtn.Text = "[" .. v .. "]"
        end)
    end

    local self = makeVisibilityControl(row)
    function self.Bind(key) _key = key; keyBtn.Text = "[" .. key .. "]" end
    function self.GetKey()  return _key end
    function self.Clear()   _key = "None"; keyBtn.Text = "[None]" end

    return self
end

-- ── Label ─────────────────────────────────────────────────────────────────────

function Elements.Label(parent, text, icon, color)
    local T = _theme.get()
    local L = layout()

    local row = _utils.frame({
        name         = "LabelRow",
        size         = UDim2.new(1, 0, 0, 32),
        color        = T.surface,
        transparency = 1,
        parent       = parent,
    })

    local lbl = _utils.label({
        name   = "Text",
        text   = (icon and (icon .. "  ") or "") .. text,
        font   = L.fontLabel,
        size   = L.sizeLabel,
        color  = color or T.muted,
        xAlign = Enum.TextXAlignment.Left,
        size2  = UDim2.new(1, -L.groupPaddingH * 2, 1, 0),
        pos    = UDim2.new(0, L.groupPaddingH, 0, 0),
        parent = row,
    })

    local self = makeVisibilityControl(row)
    function self.SetText(t) lbl.Text = (icon and (icon .. "  ") or "") .. t end
    function self.SetIcon(i) icon = i; lbl.Text = (i and (i .. "  ") or "") .. text end
    function self.SetColor(c) lbl.TextColor3 = c end

    return self
end

-- ── Paragraph ─────────────────────────────────────────────────────────────────

function Elements.Paragraph(parent, title, body)
    local T = _theme.get()
    local L = layout()

    local row = _utils.frame({
        name         = "ParagraphRow",
        size         = UDim2.new(1, 0, 0, 70),
        color        = T.surface,
        parent       = parent,
    })
    _utils.corner(row, L.radiusElement)
    _utils.stroke(row, T.border, L.strokeTransparency)
    _utils.padding(row, 10, L.groupPaddingH, 10, L.groupPaddingH)

    local vLayout = _utils.listLayout(row, { spacing = 4 })

    local titleLbl = _utils.label({
        name   = "Title",
        text   = title,
        font   = L.fontLabel,
        size   = L.sizeLabel,
        color  = T.text,
        size2  = UDim2.new(1, 0, 0, 18),
        parent = row,
    })

    local bodyLbl = _utils.label({
        name        = "Body",
        text        = body,
        font        = L.fontBody,
        size        = 12,
        color       = T.muted,
        size2       = UDim2.new(1, 0, 0, 0),
        rich        = false,
        parent      = row,
    })
    bodyLbl.AutomaticSize  = Enum.AutomaticSize.Y
    bodyLbl.TextWrapped    = true

    -- Auto-size the row
    vLayout.Changed:Connect(function()
        row.Size = UDim2.new(1, 0, 0, vLayout.AbsoluteContentSize.Y + 20)
    end)

    local self = makeVisibilityControl(row)
    function self.Rewrite(t, b)
        titleLbl.Text = t
        bodyLbl.Text  = b
    end

    return self
end

return Elements
