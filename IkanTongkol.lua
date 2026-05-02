--======================================================================

  --FILE 1: WiseHub.lua  (Library — upload ke GitHub)

--======================================================================



--[[

╔══════════════════════════════════════════════════════════════╗

║                   WISE HUB — Library                         ║

║          github.com/yourname/wise-hub/WiseHub.lua            ║

║                                                              ║

║  File ini adalah mesin GUI-nya. JANGAN DIEDIT.               ║

║  Edit hub-config.lua untuk tambah fitur.                     ║

╚══════════════════════════════════════════════════════════════╝

]]



local WiseHub = {}

WiseHub.__index = WiseHub



-- Services

local Players           = game:GetService("Players")

local UserInputService  = game:GetService("UserInputService")

local TweenService      = game:GetService("TweenService")

local LocalPlayer       = Players.LocalPlayer

local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")



-- ── Helper ────────────────────────────────────────────────────────



local function New(class, props, parent)

    local obj = Instance.new(class)

    for k, v in pairs(props) do obj[k] = v end

    if parent then obj.Parent = parent end

    return obj

end



local function Tween(obj, props, t)

    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()

end



local function HexToColor(hex)

    hex = hex:gsub("#", "")

    return Color3.fromRGB(

        tonumber(hex:sub(1,2), 16),

        tonumber(hex:sub(3,4), 16),

        tonumber(hex:sub(5,6), 16)

    )

end



-- ── Buat Hub ──────────────────────────────────────────────────────



function WiseHub.new(options)

    local self      = setmetatable({}, WiseHub)

    self.Name       = options.Name    or "WISE HUB"

    self.Game       = options.Game    or "Unknown Game"

    self.Version    = options.Version or "1.0.0"

    self._tabs      = {}

    self._activeTab = nil

    self:_buildGUI()

    return self

end



function WiseHub:_buildGUI()

    -- Hapus GUI lama kalau ada

    pcall(function()

        if PlayerGui:FindFirstChild("WiseHub") then

            PlayerGui:FindFirstChild("WiseHub"):Destroy()

        end

    end)



    -- ScreenGui

    local gui = New("ScreenGui", {

        Name           = "WiseHub",

        ResetOnSpawn   = false,

        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

    }, PlayerGui)

    self._gui = gui



    -- Window utama

    local win = New("Frame", {

        Name             = "Window",

        Size             = UDim2.new(0, 480, 0, 440),

        Position         = UDim2.new(0.5, -240, 0.5, -220),

        BackgroundColor3 = Color3.fromRGB(10, 10, 18),

        BorderSizePixel  = 0,

    }, gui)

    New("UICorner",  { CornerRadius = UDim.new(0, 10) }, win)

    New("UIStroke",  { Color = Color3.fromRGB(40, 40, 60), Thickness = 1 }, win)

    self._win = win



    -- ── Title bar ─────────────────────────────────────────────────

    local titlebar = New("Frame", {

        Name             = "TitleBar",

        Size             = UDim2.new(1, 0, 0, 44),

        BackgroundColor3 = Color3.fromRGB(14, 14, 24),

        BorderSizePixel  = 0,

    }, win)

    New("UICorner", { CornerRadius = UDim.new(0, 10) }, titlebar)

    -- patch sudut bawah supaya tidak bulat

    New("Frame", {

        Size             = UDim2.new(1, 0, 0.5, 0),

        Position         = UDim2.new(0, 0, 0.5, 0),

        BackgroundColor3 = Color3.fromRGB(14, 14, 24),

        BorderSizePixel  = 0,

    }, titlebar)



    self._titleDot = New("Frame", {

        Size             = UDim2.new(0, 8, 0, 8),

        Position         = UDim2.new(0, 12, 0.5, -4),

        BackgroundColor3 = Color3.fromRGB(0, 200, 255),

        BorderSizePixel  = 0,

    }, titlebar)

    New("UICorner", { CornerRadius = UDim.new(1, 0) }, self._titleDot)



    New("TextLabel", {

        Text             = self.Name .. "   v" .. self.Version,

        Size             = UDim2.new(1, -120, 1, 0),

        Position         = UDim2.new(0, 26, 0, 0),

        BackgroundTransparency = 1,

        TextColor3       = Color3.fromRGB(220, 220, 235),

        TextSize         = 12,

        Font             = Enum.Font.GothamBold,

        TextXAlignment   = Enum.TextXAlignment.Left,

    }, titlebar)



    -- Tombol minimize

    local minimized = false

    local minBtn = New("TextButton", {

        Text             = "−",

        Size             = UDim2.new(0, 34, 0, 34),

        Position         = UDim2.new(1, -76, 0, 5),

        BackgroundTransparency = 1,

        TextColor3       = Color3.fromRGB(100, 100, 130),

        TextSize         = 18,

        Font             = Enum.Font.GothamBold,

    }, titlebar)

    minBtn.MouseButton1Click:Connect(function()

        minimized = not minimized

        Tween(win, { Size = minimized and UDim2.new(0, 480, 0, 44) or UDim2.new(0, 480, 0, 440) }, 0.2)

    end)

    minBtn.MouseEnter:Connect(function() minBtn.TextColor3 = Color3.fromRGB(220, 220, 235) end)

    minBtn.MouseLeave:Connect(function() minBtn.TextColor3 = Color3.fromRGB(100, 100, 130) end)



    -- Tombol close

    local closeBtn = New("TextButton", {

        Text             = "✕",

        Size             = UDim2.new(0, 34, 0, 34),

        Position         = UDim2.new(1, -40, 0, 5),

        BackgroundTransparency = 1,

        TextColor3       = Color3.fromRGB(100, 100, 130),

        TextSize         = 13,

        Font             = Enum.Font.GothamBold,

    }, titlebar)

    closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)

    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80) end)

    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(100, 100, 130) end)



    -- Drag window

    local dragging, dragStart, dragOrigin = false, nil, nil

    titlebar.InputBegan:Connect(function(inp)

        if inp.UserInputType == Enum.UserInputType.MouseButton1 then

            dragging  = true

            dragStart = inp.Position

            dragOrigin = win.Position

        end

    end)

    UserInputService.InputChanged:Connect(function(inp)

        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then

            local d = inp.Position - dragStart

            win.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X,

                                     dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)

        end

    end)

    UserInputService.InputEnded:Connect(function(inp)

        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end

    end)



    -- ── Body ──────────────────────────────────────────────────────

    local body = New("Frame", {

        Name             = "Body",

        Size             = UDim2.new(1, 0, 1, -44),

        Position         = UDim2.new(0, 0, 0, 44),

        BackgroundTransparency = 1,

        BorderSizePixel  = 0,

    }, win)



    -- Sidebar

    local sidebar = New("Frame", {

        Size             = UDim2.new(0, 76, 1, 0),

        BackgroundColor3 = Color3.fromRGB(7, 7, 14),

        BorderSizePixel  = 0,

    }, body)

    New("Frame", {   -- garis kanan sidebar

        Size             = UDim2.new(0, 1, 1, 0),

        Position         = UDim2.new(1, -1, 0, 0),

        BackgroundColor3 = Color3.fromRGB(35, 35, 55),

        BorderSizePixel  = 0,

    }, sidebar)



    local tabList = New("ScrollingFrame", {

        Size                 = UDim2.new(1, 0, 1, 0),

        BackgroundTransparency = 1,

        BorderSizePixel      = 0,

        ScrollBarThickness   = 0,

        ScrollingDirection   = Enum.ScrollingDirection.Y,

        AutomaticCanvasSize  = Enum.AutomaticSize.Y,

        CanvasSize           = UDim2.new(0, 0, 0, 0),

    }, sidebar)

    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, tabList)

    New("UIPadding", {

        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),

        PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5),

    }, tabList)

    self._tabList = tabList



    -- Area konten

    local content = New("Frame", {

        Size             = UDim2.new(1, -76, 1, 0),

        Position         = UDim2.new(0, 76, 0, 0),

        BackgroundTransparency = 1,

        BorderSizePixel  = 0,

    }, body)



    -- Header konten

    local headerRow = New("Frame", {

        Size             = UDim2.new(1, 0, 0, 36),

        BackgroundTransparency = 1,

        BorderSizePixel  = 0,

    }, content)

    New("Frame", {

        Size             = UDim2.new(1, 0, 0, 1),

        Position         = UDim2.new(0, 0, 1, -1),

        BackgroundColor3 = Color3.fromRGB(35, 35, 55),

        BorderSizePixel  = 0,

    }, headerRow)

    self._headerLabel = New("TextLabel", {

        Text             = "",

        Size             = UDim2.new(1, -10, 1, 0),

        Position         = UDim2.new(0, 10, 0, 0),

        BackgroundTransparency = 1,

        TextColor3       = Color3.fromRGB(0, 200, 255),

        TextSize         = 11,

        Font             = Enum.Font.GothamBold,

        TextXAlignment   = Enum.TextXAlignment.Left,

    }, headerRow)



    -- ScrollFrame fitur

    local scroll = New("ScrollingFrame", {

        Size                 = UDim2.new(1, 0, 1, -36),

        Position             = UDim2.new(0, 0, 0, 36),

        BackgroundTransparency = 1,

        BorderSizePixel      = 0,

        ScrollBarThickness   = 3,

        ScrollBarImageColor3 = Color3.fromRGB(50, 50, 80),

        ScrollingDirection   = Enum.ScrollingDirection.Y,

        AutomaticCanvasSize  = Enum.AutomaticSize.Y,

        CanvasSize           = UDim2.new(0, 0, 0, 0),

    }, content)

    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, scroll)

    New("UIPadding", {

        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),

        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),

    }, scroll)

    self._scroll = scroll

end



-- ── Tambah Tab ────────────────────────────────────────────────────



function WiseHub:CreateTab(label, options)

    options = options or {}

    local color = options.Color and HexToColor(options.Color) or Color3.fromRGB(0, 200, 255)



    local tabData = {

        label    = label,

        color    = color,

        controls = {},

    }



    -- Tombol tab di sidebar

    local btn = New("TextButton", {

        Size                 = UDim2.new(1, 0, 0, 54),

        BackgroundTransparency = 1,

        Text                 = "",

        BorderSizePixel      = 0,

        LayoutOrder          = #self._tabs + 1,

    }, self._tabList)

    New("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)



    local dot = New("Frame", {

        Size             = UDim2.new(0, 8, 0, 8),

        Position         = UDim2.new(0.5, -4, 0, 9),

        BackgroundColor3 = Color3.fromRGB(60, 60, 80),

        BorderSizePixel  = 0,

    }, btn)

    New("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)



    local lbl = New("TextLabel", {

        Text             = label,

        Size             = UDim2.new(1, -4, 0, 18),

        Position         = UDim2.new(0, 2, 0, 22),

        BackgroundTransparency = 1,

        TextColor3       = Color3.fromRGB(60, 60, 80),

        TextSize         = 9,

        Font             = Enum.Font.GothamBold,

        TextWrapped      = true,

    }, btn)



    local line = New("Frame", {

        Size             = UDim2.new(0, 2, 0.55, 0),

        Position         = UDim2.new(0, 0, 0.22, 0),

        BackgroundColor3 = color,

        BorderSizePixel  = 0,

        Visible          = false,

    }, btn)

    New("UICorner", { CornerRadius = UDim.new(1, 0) }, line)



    tabData._btn  = btn

    tabData._dot  = dot

    tabData._lbl  = lbl

    tabData._line = line



    btn.MouseButton1Click:Connect(function() self:_switchTab(tabData) end)

    btn.MouseEnter:Connect(function()

        if self._activeTab ~= tabData then

            btn.BackgroundTransparency = 0

            Tween(btn, { BackgroundColor3 = Color3.fromRGB(18, 18, 30) }, 0.1)

        end

    end)

    btn.MouseLeave:Connect(function()

        if self._activeTab ~= tabData then btn.BackgroundTransparency = 1 end

    end)



    table.insert(self._tabs, tabData)



    -- Auto-pilih tab pertama

    if #self._tabs == 1 then self:_switchTab(tabData) end



    -- ── Objek Tab yang dikembalikan ke user ──────────────────────

    local hubRef  = self

    local Tab     = {}



    function Tab:CreateSection(name)

        table.insert(tabData.controls, { kind = "section", name = name })

        if hubRef._activeTab == tabData then hubRef:_rebuild() end

        return self

    end



    function Tab:CreateToggle(opts)

        table.insert(tabData.controls, {

            kind     = "toggle",

            name     = opts.Name,

            value    = opts.CurrentValue == true,

            callback = opts.Callback,

        })

        if hubRef._activeTab == tabData then hubRef:_rebuild() end

        return self

    end



    function Tab:CreateSlider(opts)

        table.insert(tabData.controls, {

            kind     = "slider",

            name     = opts.Name,

            min      = opts.Range[1],

            max      = opts.Range[2],

            value    = opts.CurrentValue or opts.Range[1],

            unit     = opts.Suffix or "",

            callback = opts.Callback,

        })

        if hubRef._activeTab == tabData then hubRef:_rebuild() end

        return self

    end



    function Tab:CreateButton(opts)

        table.insert(tabData.controls, {

            kind     = "button",

            name     = opts.Name,

            callback = opts.Callback,

        })

        if hubRef._activeTab == tabData then hubRef:_rebuild() end

        return self

    end



    function Tab:CreateDropdown(opts)

        table.insert(tabData.controls, {

            kind     = "dropdown",

            name     = opts.Name,

            options  = opts.Options,

            value    = opts.CurrentOption or (opts.Options[1] or ""),

            callback = opts.Callback,

        })

        if hubRef._activeTab == tabData then hubRef:_rebuild() end

        return self

    end



    function Tab:CreateTextbox(opts)

        table.insert(tabData.controls, {

            kind        = "textbox",

            name        = opts.Name,

            placeholder = opts.PlaceholderText or "Ketik di sini...",

            value       = opts.CurrentValue or "",

            callback    = opts.Callback,

        })

        if hubRef._activeTab == tabData then hubRef:_rebuild() end

        return self

    end



    return Tab

end



-- ── Switch tab aktif ──────────────────────────────────────────────



function WiseHub:_switchTab(tabData)

    for _, t in ipairs(self._tabs) do

        t._btn.BackgroundTransparency = 1

        Tween(t._dot, { BackgroundColor3 = Color3.fromRGB(60, 60, 80) }, 0.1)

        Tween(t._lbl, { TextColor3      = Color3.fromRGB(60, 60, 80) }, 0.1)

        t._line.Visible = false

    end

    self._activeTab = tabData

    tabData._btn.BackgroundTransparency = 0

    tabData._btn.BackgroundColor3 = Color3.fromRGB(

        math.floor(tabData.color.R * 25),

        math.floor(tabData.color.G * 25),

        math.floor(tabData.color.B * 25)

    )

    Tween(tabData._dot, { BackgroundColor3 = tabData.color }, 0.1)

    Tween(tabData._lbl, { TextColor3      = tabData.color }, 0.1)

    tabData._line.Visible = true



    self._headerLabel.Text      = tabData.label:upper()

    self._headerLabel.TextColor3 = tabData.color

    self._titleDot.BackgroundColor3 = tabData.color



    self:_rebuild()

end



-- ── Bangun ulang daftar fitur ─────────────────────────────────────



function WiseHub:_rebuild()

    -- Hapus semua anak kecuali layout/padding

    for _, child in ipairs(self._scroll:GetChildren()) do

        if child:IsA("GuiObject") then child:Destroy() end

    end

    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3) }, self._scroll)

    New("UIPadding", {

        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),

        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),

    }, self._scroll)



    if not self._activeTab then return end

    local c = self._activeTab.color



    for i, ctrl in ipairs(self._activeTab.controls) do



        -- ── Section ──────────────────────────────────────────────

        if ctrl.kind == "section" then

            local row = New("Frame", {

                Size             = UDim2.new(1, 0, 0, 26),

                BackgroundTransparency = 1,

                BorderSizePixel  = 0,

                LayoutOrder      = i,

            }, self._scroll)

            New("TextLabel", {

                Text             = ctrl.name:upper(),

                Size             = UDim2.new(0.55, 0, 1, 0),

                BackgroundTransparency = 1,

                TextColor3       = Color3.fromRGB(math.floor(c.R*153), math.floor(c.G*153), math.floor(c.B*153)),

                TextSize         = 9,

                Font             = Enum.Font.GothamBold,

                TextXAlignment   = Enum.TextXAlignment.Left,

            }, row)

            New("Frame", {

                Size             = UDim2.new(0.43, 0, 0, 1),

                Position         = UDim2.new(0.57, 0, 0.5, 0),

                BackgroundColor3 = Color3.fromRGB(30, 30, 50),

                BorderSizePixel  = 0,

            }, row)



        -- ── Toggle ───────────────────────────────────────────────

        elseif ctrl.kind == "toggle" then

            local row = New("Frame", {

                Size             = UDim2.new(1, 0, 0, 40),

                BackgroundColor3 = Color3.fromRGB(15, 15, 25),

                BorderSizePixel  = 0,

                LayoutOrder      = i,

            }, self._scroll)

            New("UICorner", { CornerRadius = UDim.new(0, 7) }, row)

            New("UIStroke", { Color = Color3.fromRGB(32, 32, 50), Thickness = 1 }, row)



            local rowDot = New("Frame", {

                Size             = UDim2.new(0, 6, 0, 6),

                Position         = UDim2.new(0, 10, 0.5, -3),

                BackgroundColor3 = ctrl.value and c or Color3.fromRGB(55, 55, 75),

                BorderSizePixel  = 0,

            }, row)

            New("UICorner", { CornerRadius = UDim.new(1, 0) }, rowDot)



            local rowLbl = New("TextLabel", {

                Text             = ctrl.name,

                Size             = UDim2.new(1, -70, 1, 0),

                Position         = UDim2.new(0, 22, 0, 0),

                BackgroundTransparency = 1,

                TextColor3       = ctrl.value and Color3.fromRGB(215, 215, 230) or Color3.fromRGB(120, 120, 145),

                TextSize         = 12,

                Font             = Enum.Font.Gotham,

                TextXAlignment   = Enum.TextXAlignment.Left,

            }, row)



            local pill = New("Frame", {

                Size             = UDim2.new(0, 40, 0, 22),

                Position         = UDim2.new(1, -50, 0.5, -11),

                BackgroundColor3 = ctrl.value and c or Color3.fromRGB(38, 38, 58),

                BorderSizePixel  = 0,

            }, row)

            New("UICorner", { CornerRadius = UDim.new(1, 0) }, pill)



            local knob = New("Frame", {

                Size             = UDim2.new(0, 16, 0, 16),

                Position         = ctrl.value and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),

                BackgroundColor3 = Color3.fromRGB(255, 255, 255),

                BorderSizePixel  = 0,

            }, pill)

            New("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)



            local clickArea = New("TextButton", {

                Size             = UDim2.new(1, 0, 1, 0),

                BackgroundTransparency = 1,

                Text             = "",

            }, row)

            clickArea.MouseButton1Click:Connect(function()

                ctrl.value = not ctrl.value

                Tween(pill,   { BackgroundColor3 = ctrl.value and c or Color3.fromRGB(38, 38, 58) }, 0.15)

                Tween(knob,   { Position = ctrl.value and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }, 0.15)

                Tween(rowDot, { BackgroundColor3 = ctrl.value and c or Color3.fromRGB(55, 55, 75) }, 0.1)

                Tween(rowLbl, { TextColor3 = ctrl.value and Color3.fromRGB(215, 215, 230) or Color3.fromRGB(120, 120, 145) }, 0.1)

                if ctrl.callback then ctrl.callback(ctrl.value) end

            end)



        -- ── Slider ───────────────────────────────────────────────

        elseif ctrl.kind == "slider" then

            local row = New("Frame", {

                Size             = UDim2.new(1, 0, 0, 60),

                BackgroundColor3 = Color3.fromRGB(15, 15, 25),

                BorderSizePixel  = 0,

                LayoutOrder      = i,

            }, self._scroll)

            New("UICorner", { CornerRadius = UDim.new(0, 7) }, row)

            New("UIStroke", { Color = Color3.fromRGB(32, 32, 50), Thickness = 1 }, row)



            New("TextLabel", {

                Text             = ctrl.name,

                Size             = UDim2.new(0.6, 0, 0, 30),

                Position         = UDim2.new(0, 12, 0, 0),

                BackgroundTransparency = 1,

                TextColor3       = Color3.fromRGB(175, 175, 195),

                TextSize         = 12,

                Font             = Enum.Font.Gotham,

                TextXAlignment   = Enum.TextXAlignment.Left,

            }, row)



            local valLbl = New("TextLabel", {

                Text             = tostring(ctrl.value) .. ctrl.unit,

                Size             = UDim2.new(0.4, -12, 0, 30),

                Position         = UDim2.new(0.6, 0, 0, 0),

                BackgroundTransparency = 1,

                TextColor3       = c,

                TextSize         = 11,

                Font             = Enum.Font.Code,

                TextXAlignment   = Enum.TextXAlignment.Right,

            }, row)



            local track = New("Frame", {

                Size             = UDim2.new(1, -24, 0, 6),

                Position         = UDim2.new(0, 12, 0, 38),

                BackgroundColor3 = Color3.fromRGB(30, 30, 50),

                BorderSizePixel  = 0,

            }, row)

            New("UICorner", { CornerRadius = UDim.new(1, 0) }, track)



            local pct  = (ctrl.value - ctrl.min) / (ctrl.max - ctrl.min)

            local fill = New("Frame", {

                Size             = UDim2.new(pct, 0, 1, 0),

                BackgroundColor3 = c,

                BorderSizePixel  = 0,

            }, track)

            New("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)



            local slideDrag = false

            local function applySlider(x)

                local abs  = track.AbsolutePosition.X

                local size = track.AbsoluteSize.X

                local t    = math.clamp((x - abs) / size, 0, 1)

                local val  = math.floor(ctrl.min + t * (ctrl.max - ctrl.min))

                ctrl.value = val

                fill.Size  = UDim2.new(t, 0, 1, 0)

                valLbl.Text = tostring(val) .. ctrl.unit

                if ctrl.callback then ctrl.callback(val) end

            end



            local sBtn = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, track)

            sBtn.InputBegan:Connect(function(inp)

                if inp.UserInputType == Enum.UserInputType.MouseButton1

                or inp.UserInputType == Enum.UserInputType.Touch then

                    slideDrag = true

                    applySlider(inp.Position.X)

                end

            end)

            UserInputService.InputChanged:Connect(function(inp)

                if slideDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement

                or inp.UserInputType == Enum.UserInputType.Touch) then

                    applySlider(inp.Position.X)

                end

            end)

            UserInputService.InputEnded:Connect(function(inp)

                if inp.UserInputType == Enum.UserInputType.MouseButton1

                or inp.UserInputType == Enum.UserInputType.Touch then

                    slideDrag = false

                end

            end)



        -- ── Button ───────────────────────────────────────────────

        elseif ctrl.kind == "button" then

            local btn = New("TextButton", {

                Text             = "▶  " .. ctrl.name,

                Size             = UDim2.new(1, 0, 0, 38),

                BackgroundColor3 = Color3.fromRGB(18, 18, 32),

                BorderSizePixel  = 0,

                TextColor3       = c,

                TextSize         = 11,

                Font             = Enum.Font.GothamBold,

                LayoutOrder      = i,

            }, self._scroll)

            New("UICorner", { CornerRadius = UDim.new(0, 7) }, btn)

            New("UIStroke", { Color = Color3.fromRGB(math.floor(c.R*100), math.floor(c.G*100), math.floor(c.B*100)), Thickness = 1 }, btn)

            btn.MouseButton1Click:Connect(function()

                if ctrl.callback then ctrl.callback() end

            end)

            btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = Color3.fromRGB(28, 28, 46) }, 0.1) end)

            btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = Color3.fromRGB(18, 18, 32) }, 0.1) end)



        -- ── Dropdown ─────────────────────────────────────────────

        elseif ctrl.kind == "dropdown" then

            local row = New("Frame", {

                Size             = UDim2.new(1, 0, 0, 68),

                BackgroundColor3 = Color3.fromRGB(15, 15, 25),

                BorderSizePixel  = 0,

                LayoutOrder      = i,

                ClipsDescendants = true,

            }, self._scroll)

            New("UICorner", { CornerRadius = UDim.new(0, 7) }, row)

            New("UIStroke", { Color = Color3.fromRGB(32, 32, 50), Thickness = 1 }, row)



            New("TextLabel", {

                Text             = ctrl.name,

                Size             = UDim2.new(1, -20, 0, 30),

                Position         = UDim2.new(0, 12, 0, 0),

                BackgroundTransparency = 1,

                TextColor3       = Color3.fromRGB(175, 175, 195),

                TextSize         = 12,

                Font             = Enum.Font.Gotham,

                TextXAlignment   = Enum.TextXAlignment.Left,

            }, row)



            local selLbl = New("TextLabel", {

                Text             = "▼  " .. ctrl.value,

                Size             = UDim2.new(1, -24, 0, 28),

                Position         = UDim2.new(0, 12, 0, 32),

                BackgroundColor3 = Color3.fromRGB(22, 22, 36),

                BorderSizePixel  = 0,

                TextColor3       = c,

                TextSize         = 11,

                Font             = Enum.Font.GothamBold,

                TextXAlignment   = Enum.TextXAlignment.Left,

            }, row)

            New("UICorner", { CornerRadius = UDim.new(0, 5) }, selLbl)

            New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, selLbl)



            -- Klik = putar pilihan

            local idx = 1

            for j, opt in ipairs(ctrl.options) do if opt == ctrl.value then idx = j end end

            local clickArea = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "" }, row)

            clickArea.MouseButton1Click:Connect(function()

                idx = idx % #ctrl.options + 1

                ctrl.value = ctrl.options[idx]

                selLbl.Text = "▼  " .. ctrl.value

                if ctrl.callback then ctrl.callback(ctrl.value) end

            end)



        -- ── Textbox ──────────────────────────────────────────────

        elseif ctrl.kind == "textbox" then

            local row = New("Frame", {

                Size             = UDim2.new(1, 0, 0, 68),

                BackgroundColor3 = Color3.fromRGB(15, 15, 25),

                BorderSizePixel  = 0,

                LayoutOrder      = i,

            }, self._scroll)

            New("UICorner", { CornerRadius = UDim.new(0, 7) }, row)

            New("UIStroke", { Color = Color3.fromRGB(32, 32, 50), Thickness = 1 }, row)



            New("TextLabel", {

                Text             = ctrl.name,

                Size             = UDim2.new(1, -20, 0, 30),

                Position         = UDim2.new(0, 12, 0, 0),

                BackgroundTransparency = 1,

                TextColor3       = Color3.fromRGB(175, 175, 195),

                TextSize         = 12,

                Font             = Enum.Font.Gotham,

                TextXAlignment   = Enum.TextXAlignment.Left,

            }, row)



            local tbox = New("TextBox", {

                PlaceholderText  = ctrl.placeholder,

                Text             = ctrl.value,

                Size             = UDim2.new(1, -24, 0, 28),

                Position         = UDim2.new(0, 12, 0, 32),

                BackgroundColor3 = Color3.fromRGB(22, 22, 36),

                BorderSizePixel  = 0,

                TextColor3       = Color3.fromRGB(200, 200, 220),

                PlaceholderColor3 = Color3.fromRGB(70, 70, 95),

                TextSize         = 11,

                Font             = Enum.Font.Code,

                TextXAlignment   = Enum.TextXAlignment.Left,

                ClearTextOnFocus = false,

            }, row)

            New("UICorner",  { CornerRadius = UDim.new(0, 5) }, tbox)

            New("UIPadding", { PaddingLeft  = UDim.new(0, 8) }, tbox)

            tbox.FocusLost:Connect(function()

                ctrl.value = tbox.Text

                if ctrl.callback then ctrl.callback(ctrl.value) end

            end)

        end

    end

end



-- ── Destroy ───────────────────────────────────────────────────────



function WiseHub:Destroy()

    if self._gui then self._gui:Destroy() end

end



return WiseHub
