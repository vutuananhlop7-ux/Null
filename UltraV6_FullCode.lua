--[[
    ██╗   ██╗██╗  ████████╗██████╗  █████╗     ██╗   ██╗ ██████╗
    ██║   ██║██║  ╚══██╔══╝██╔══██╗██╔══██╗    ██║   ██║ ██╔════╝
    ██║   ██║██║     ██║   ██████╔╝███████║    ██║   ██║ ███████╗
    ██║   ██║██║     ██║   ██╔══██╗██╔══██║    ╚██╗ ██╔╝ ╚════██║
    ╚██████╔╝███████╗██║   ██║  ██║██║  ██║     ╚████╔╝  ███████║
     ╚═════╝ ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝      ╚═══╝   ╚══════╝
    ULTRA V6 PANEL — Full Code với Chibi & Background vẽ bằng Frame
--]]

-- ╔══════════════════════════════════════╗
-- ║           SERVICES                   ║
-- ╚══════════════════════════════════════╝
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ╔══════════════════════════════════════╗
-- ║           STATES                     ║
-- ╚══════════════════════════════════════╝
local espMode        = "HIGHLIGHT_ONLY"
local noclipEnabled  = false
local espCache       = {}
local premiumUnlocked = false
local premiumMultiplier = 1.5
local activeTab      = nil
local VALID_KEY      = "FREE_KEY"
local tabButtons     = {}

-- ╔══════════════════════════════════════╗
-- ║           COLOR PALETTE              ║
-- ╚══════════════════════════════════════╝
local C = {
    BG       = Color3.fromRGB(14, 13, 24),
    SIDEBAR  = Color3.fromRGB(18, 17, 32),
    TOP      = Color3.fromRGB(20, 18, 36),
    ACCENT   = Color3.fromRGB(110, 85, 230),
    ACCENT2  = Color3.fromRGB(180, 120, 255),
    TEXT     = Color3.new(1, 1, 1),
    SUBTEXT  = Color3.fromRGB(160, 155, 185),
    BTN      = Color3.fromRGB(30, 28, 50),
    BTN_HOV  = Color3.fromRGB(48, 44, 78),
    SUCCESS  = Color3.fromRGB(80, 210, 130),
    ERROR    = Color3.fromRGB(230, 70, 70),
    GOLD     = Color3.fromRGB(255, 210, 60),
    PINK     = Color3.fromRGB(255, 140, 180),
    CYAN     = Color3.fromRGB(80, 210, 240),
    SKY      = Color3.fromRGB(135, 206, 235),
}

-- ╔══════════════════════════════════════╗
-- ║           HELPERS                    ║
-- ╚══════════════════════════════════════╝
local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function pad(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.PaddingTop    = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.Parent = parent
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color or Color3.new(1,1,1)
    s.Thickness    = thickness or 1.5
    s.Transparency = transparency or 0
    s.Parent       = parent
    return s
end

local function tween(obj, props, t, style, dir)
    return TweenService:Create(obj,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle = handle or frame
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ╔══════════════════════════════════════╗
-- ║           BLUR                       ║
-- ╚══════════════════════════════════════╝
local blur = Lighting:FindFirstChild("UltraBlur") or Instance.new("BlurEffect")
blur.Name    = "UltraBlur"
blur.Size    = 10
blur.Enabled = true
blur.Parent  = Lighting

-- ╔══════════════════════════════════════╗
-- ║           GUI ROOT                   ║
-- ╚══════════════════════════════════════╝
local gui = Instance.new("ScreenGui")
gui.Name           = "UltraV6"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- ╔══════════════════════════════════════╗
-- ║     🎨 CHIBI DRAW (Frame art)        ║
-- ╚══════════════════════════════════════╝
-- Vẽ chibi nhân vật nón lá bằng Frame thuần
local function drawChibi(parent, x, y, scale)
    scale = scale or 1
    local s = scale

    local function circ(px, py, w, h, col, zi, trans)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(0, w*s, 0, h*s)
        f.Position         = UDim2.new(0, px*s, 0, py*s)
        f.BackgroundColor3 = col
        f.BackgroundTransparency = trans or 0
        f.BorderSizePixel  = 0
        f.ZIndex           = zi or 2
        f.Parent           = parent
        corner(f, math.floor(math.min(w,h)*s/2))
        return f
    end

    local function rect(px, py, w, h, col, zi, rad, trans)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(0, w*s, 0, h*s)
        f.Position         = UDim2.new(0, px*s, 0, py*s)
        f.BackgroundColor3 = col
        f.BackgroundTransparency = trans or 0
        f.BorderSizePixel  = 0
        f.ZIndex           = zi or 2
        f.Parent           = parent
        if rad then corner(f, rad) end
        return f
    end

    -- Offset gốc
    local ox, oy = x, y

    -- == NÓN LÁ ==
    -- Thân nón (hình thang dùng nhiều ellipse xếp chồng)
    for i = 0, 14 do
        local w = 62 - i*0.5
        local h = 3
        local col = Color3.fromRGB(200 - i*3, 175 - i*2, 60 - i*2)
        circ(ox + 1 + i*0.25, oy + i*3.5, w, h, col, 3)
    end
    -- Vành nón (brim)
    circ(ox - 4, oy + 46, 72, 10, Color3.fromRGB(180, 155, 50), 4)
    -- Đỉnh nón
    circ(ox + 20, oy, 24, 10, Color3.fromRGB(210, 185, 70), 4)
    -- Highlight nón
    circ(ox + 24, oy + 6, 10, 4, Color3.fromRGB(240, 220, 130), 5, 0.3)

    -- Sticker cô gái trên nón
    local stickerBg = circ(ox + 8, oy + 12, 14, 16, Color3.fromRGB(245, 230, 215), 6)
    -- Mặt sticker
    circ(ox + 11, oy + 13, 8, 8, Color3.fromRGB(255, 220, 195), 7)
    -- Tóc sticker
    rect(ox + 10, oy + 12, 10, 5, Color3.fromRGB(60, 40, 30), 8, 2)
    circ(ox + 10, oy + 13, 4, 8, Color3.fromRGB(60, 40, 30), 8)
    circ(ox + 17, oy + 13, 4, 8, Color3.fromRGB(60, 40, 30), 8)

    -- Sticker ba lô
    local bp = rect(ox + 38, oy + 10, 14, 16, Color3.fromRGB(100, 160, 220), 6, 3)
    -- Quai ba lô
    circ(ox + 41, oy + 10, 4, 3, Color3.fromRGB(70, 130, 190), 7)
    circ(ox + 47, oy + 10, 4, 3, Color3.fromRGB(70, 130, 190), 7)
    -- Túi ba lô
    rect(ox + 40, oy + 18, 10, 6, Color3.fromRGB(70, 130, 190), 7, 2)

    -- == THÂN ==
    -- Body trắng tròn
    circ(ox + 8, oy + 50, 48, 52, Color3.fromRGB(250, 248, 248), 3)

    -- == ĐẦU ==
    circ(ox + 10, oy + 36, 44, 42, Color3.fromRGB(255, 250, 248), 5)
    -- Má hồng
    circ(ox + 12, oy + 58, 10, 6, Color3.fromRGB(255, 180, 180), 6, 0.3)
    circ(ox + 42, oy + 58, 10, 6, Color3.fromRGB(255, 180, 180), 6, 0.3)

    -- == MẮT NHẮM ==
    -- Mắt trái (đường cong)
    rect(ox + 17, oy + 55, 10, 2, Color3.fromRGB(80, 60, 50), 7, 1)
    circ(ox + 15, oy + 54, 7, 4, Color3.fromRGB(80, 60, 50), 7, 0.5)
    -- Mắt phải
    rect(ox + 37, oy + 55, 10, 2, Color3.fromRGB(80, 60, 50), 7, 1)
    circ(ox + 36, oy + 54, 7, 4, Color3.fromRGB(80, 60, 50), 7, 0.5)

    -- == MIỆNG HÉ MỞ ==
    circ(ox + 27, oy + 66, 10, 7, Color3.fromRGB(200, 100, 100), 7)
    -- Răng trắng
    rect(ox + 28, oy + 66, 8, 3, Color3.fromRGB(255, 252, 252), 8, 1)

    -- == TAY TRÁI ==
    circ(ox + 2, oy + 74, 14, 18, Color3.fromRGB(250, 248, 248), 4)
    circ(ox + 1, oy + 84, 12, 12, Color3.fromRGB(250, 248, 248), 4)

    -- == TAY PHẢI (cầm vật) ==
    circ(ox + 47, oy + 74, 14, 18, Color3.fromRGB(250, 248, 248), 4)

    -- == KHĂN QUÀNG ==
    -- Khăn kẻ ô
    local scarf = rect(ox + 14, oy + 76, 36, 18, Color3.fromRGB(200, 210, 230), 6, 4)
    -- Ô kẻ
    for i = 0, 3 do
        rect(ox + 14 + i*9, oy + 76, 1, 18, Color3.fromRGB(170, 180, 200), 7)
    end
    for i = 0, 2 do
        rect(ox + 14, oy + 76 + i*6, 36, 1, Color3.fromRGB(170, 180, 200), 7)
    end

    -- == VẬT CẦM (bánh mì / taco) ==
    circ(ox + 4, oy + 86, 18, 10, Color3.fromRGB(210, 160, 80), 5)
    circ(ox + 6, oy + 88, 14, 7, Color3.fromRGB(180, 130, 60), 6)
    -- Nhân
    circ(ox + 7, oy + 86, 5, 4, Color3.fromRGB(200, 80, 80), 7)
    circ(ox + 12, oy + 86, 5, 4, Color3.fromRGB(100, 180, 80), 7)

    return parent
end

-- ╔══════════════════════════════════════╗
-- ║     🌸 ANIME BG DRAW                 ║
-- ╚══════════════════════════════════════╝
-- Vẽ background anime: bầu trời + mây + hoa + ánh sáng
local function drawAnimeBG(parent)
    -- Sky gradient (nhiều dải màu)
    local skyCols = {
        {Color3.fromRGB(15, 12, 35),  0,   1.0},
        {Color3.fromRGB(25, 20, 55),  0.1, 1.0},
        {Color3.fromRGB(40, 28, 80),  0.25, 1.0},
        {Color3.fromRGB(70, 40, 100), 0.4, 1.0},
        {Color3.fromRGB(100, 55, 120),0.55, 1.0},
        {Color3.fromRGB(140, 70, 110),0.68, 1.0},
        {Color3.fromRGB(180, 90, 90), 0.78, 1.0},
        {Color3.fromRGB(200, 130, 80),0.88, 1.0},
        {Color3.fromRGB(210, 160, 90),1.0, 1.0},
    }
    for i = 1, #skyCols - 1 do
        local s = skyCols[i]
        local e = skyCols[i+1]
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, math.ceil((e[2]-s[2]) * 320 + 2))
        f.Position         = UDim2.new(0, 0, s[2], 0)
        f.BackgroundColor3 = s[1]
        f.BorderSizePixel  = 0
        f.ZIndex           = 1
        f.Parent           = parent
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, s[1]),
            ColorSequenceKeypoint.new(1, e[1]),
        })
        g.Rotation = 90
        g.Parent   = f
    end

    -- Stars / bokeh dots
    local starData = {
        {0.08, 0.05, 3}, {0.2, 0.08, 2}, {0.35, 0.03, 4}, {0.5, 0.07, 2},
        {0.65, 0.04, 3}, {0.78, 0.09, 2}, {0.9, 0.05, 4}, {0.15, 0.14, 2},
        {0.42, 0.12, 3}, {0.72, 0.15, 2}, {0.85, 0.18, 3}, {0.03, 0.18, 2},
        {0.55, 0.02, 2}, {0.92, 0.12, 4}, {0.28, 0.19, 2},
    }
    for _, sd in ipairs(starData) do
        local star = Instance.new("Frame")
        star.Size             = UDim2.new(0, sd[3], 0, sd[3])
        star.Position         = UDim2.new(sd[1], 0, sd[2], 0)
        star.BackgroundColor3 = Color3.new(1, 1, 1)
        star.BackgroundTransparency = 0.3
        star.BorderSizePixel  = 0
        star.ZIndex           = 2
        star.Parent           = parent
        corner(star, sd[3])
        -- Twinkle
        task.spawn(function()
            while star and star.Parent do
                local delay = math.random(10, 40) / 10
                task.wait(delay)
                tween(star, {BackgroundTransparency = 0.85}, 0.6, Enum.EasingStyle.Sine)
                task.wait(0.6)
                tween(star, {BackgroundTransparency = 0.2}, 0.6, Enum.EasingStyle.Sine)
                task.wait(0.6)
            end
        end)
    end

    -- Moon
    local moon = Instance.new("Frame")
    moon.Size             = UDim2.new(0, 48, 0, 48)
    moon.Position         = UDim2.new(0.75, 0, 0.04, 0)
    moon.BackgroundColor3 = Color3.fromRGB(255, 248, 210)
    moon.BorderSizePixel  = 0
    moon.ZIndex           = 3
    moon.Parent           = parent
    corner(moon, 24)
    -- Moon glow
    local moonGlow = Instance.new("Frame")
    moonGlow.Size             = UDim2.new(0, 70, 0, 70)
    moonGlow.Position         = UDim2.new(0.75, -11, 0.04, -11)
    moonGlow.BackgroundColor3 = Color3.fromRGB(255, 248, 180)
    moonGlow.BackgroundTransparency = 0.75
    moonGlow.BorderSizePixel  = 0
    moonGlow.ZIndex           = 2
    moonGlow.Parent           = parent
    corner(moonGlow, 35)
    -- Moon crater
    local crater = Instance.new("Frame")
    crater.Size             = UDim2.new(0, 10, 0, 10)
    crater.Position         = UDim2.new(0.75, 14, 0.04, 10)
    crater.BackgroundColor3 = Color3.fromRGB(240, 230, 180)
    crater.BorderSizePixel  = 0
    crater.ZIndex           = 4
    crater.Parent           = parent
    corner(crater, 5)
    local crater2 = Instance.new("Frame")
    crater2.Size             = UDim2.new(0, 6, 0, 6)
    crater2.Position         = UDim2.new(0.75, 26, 0.04, 24)
    crater2.BackgroundColor3 = Color3.fromRGB(240, 230, 180)
    crater2.BorderSizePixel  = 0
    crater2.ZIndex           = 4
    crater2.Parent           = parent
    corner(crater2, 3)

    -- Clouds (mây)
    local cloudData = {
        {0.05, 0.22, 1.2}, {0.3, 0.17, 0.9}, {0.58, 0.25, 1.0}, {0.8, 0.19, 0.85},
    }
    for _, cd in ipairs(cloudData) do
        local cx, cy, cs = cd[1], cd[2], cd[3]
        local cloudPuffs = {
            {0, 0, 38*cs, 18*cs}, {12*cs, -8*cs, 28*cs, 22*cs},
            {26*cs, -2*cs, 32*cs, 16*cs}, {40*cs, 2*cs, 22*cs, 14*cs},
        }
        for _, p in ipairs(cloudPuffs) do
            local puff = Instance.new("Frame")
            puff.Size             = UDim2.new(0, p[3], 0, p[4])
            puff.Position         = UDim2.new(cx, p[1], cy, p[2])
            puff.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            puff.BackgroundTransparency = 0.25
            puff.BorderSizePixel  = 0
            puff.ZIndex           = 4
            puff.Parent           = parent
            corner(puff, math.floor(math.min(p[3],p[4])/2))
        end
    end

    -- Aurora / light rays
    local rayColors = {
        Color3.fromRGB(120, 80, 200),
        Color3.fromRGB(200, 100, 160),
        Color3.fromRGB(80, 160, 220),
    }
    for i, rc in ipairs(rayColors) do
        local ray = Instance.new("Frame")
        ray.Size             = UDim2.new(0, 3, 0.6, 0)
        ray.Position         = UDim2.new(0.2 + i*0.18, 0, 0.05, 0)
        ray.BackgroundColor3 = rc
        ray.BackgroundTransparency = 0.7
        ray.BorderSizePixel  = 0
        ray.ZIndex           = 2
        ray.Rotation         = -15 + i*5
        ray.Parent           = parent
        -- Shimmer ray
        task.spawn(function()
            while ray and ray.Parent do
                task.wait(math.random(20,50)/10)
                tween(ray, {BackgroundTransparency = 0.45}, 0.8, Enum.EasingStyle.Sine)
                task.wait(0.8)
                tween(ray, {BackgroundTransparency = 0.82}, 1.2, Enum.EasingStyle.Sine)
                task.wait(1.2)
            end
        end)
    end

    -- Floating sakura petals
    local petalColors = {
        Color3.fromRGB(255, 190, 210),
        Color3.fromRGB(255, 220, 235),
        Color3.fromRGB(255, 160, 190),
    }
    local petalPositions = {
        {0.12, 0.55}, {0.25, 0.42}, {0.45, 0.6}, {0.6, 0.38},
        {0.72, 0.5}, {0.88, 0.44}, {0.05, 0.68}, {0.38, 0.72},
        {0.55, 0.48}, {0.82, 0.62},
    }
    for i, pp in ipairs(petalPositions) do
        local petal = Instance.new("Frame")
        petal.Size             = UDim2.new(0, 8, 0, 5)
        petal.Position         = UDim2.new(pp[1], 0, pp[2], 0)
        petal.BackgroundColor3 = petalColors[(i-1)%3+1]
        petal.BackgroundTransparency = 0.2
        petal.BorderSizePixel  = 0
        petal.ZIndex           = 5
        petal.Rotation         = i * 37
        petal.Parent           = parent
        corner(petal, 3)
        -- Float animation
        local startY = pp[2]
        task.spawn(function()
            while petal and petal.Parent do
                local drift = (math.random()-0.5) * 0.08
                tween(petal, {
                    Position = UDim2.new(pp[1]+drift, 0, startY - 0.05, 0),
                    Rotation = petal.Rotation + 45,
                    BackgroundTransparency = 0.6
                }, 2.5, Enum.EasingStyle.Sine)
                task.wait(2.5)
                tween(petal, {
                    Position = UDim2.new(pp[1], 0, startY, 0),
                    Rotation = petal.Rotation - 45,
                    BackgroundTransparency = 0.2
                }, 2.5, Enum.EasingStyle.Sine)
                task.wait(2.5)
            end
        end)
    end

    -- Ground / horizon glow
    local horizon = Instance.new("Frame")
    horizon.Size             = UDim2.new(1, 0, 0, 40)
    horizon.Position         = UDim2.new(0, 0, 0.72, 0)
    horizon.BackgroundColor3 = Color3.fromRGB(220, 140, 80)
    horizon.BackgroundTransparency = 0
    horizon.BorderSizePixel  = 0
    horizon.ZIndex           = 3
    horizon.Parent           = parent
    local hGrad = Instance.new("UIGradient")
    hGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 140, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 100, 60)),
    })
    hGrad.Rotation = 90
    hGrad.Parent   = horizon

    -- Ground dark
    local ground = Instance.new("Frame")
    ground.Size             = UDim2.new(1, 0, 0.3, 0)
    ground.Position         = UDim2.new(0, 0, 0.78, 0)
    ground.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    ground.BorderSizePixel  = 0
    ground.ZIndex           = 3
    ground.Parent           = parent

    -- Trees silhouette (cây)
    local treeData = {
        {0.05, 0.55, 22, 55}, {0.12, 0.52, 18, 65}, {0.18, 0.57, 20, 48},
        {0.72, 0.53, 24, 60}, {0.8, 0.50, 20, 70}, {0.88, 0.56, 18, 50},
        {0.93, 0.52, 22, 62},
    }
    for _, td in ipairs(treeData) do
        -- Trunk
        local trunk = Instance.new("Frame")
        trunk.Size             = UDim2.new(0, 5, 0, td[4]*0.4)
        trunk.Position         = UDim2.new(td[1], td[3]/2-2, td[2]+0.15, 0)
        trunk.BackgroundColor3 = Color3.fromRGB(30, 20, 15)
        trunk.BorderSizePixel  = 0
        trunk.ZIndex           = 4
        trunk.Parent           = parent
        corner(trunk, 2)
        -- Canopy (3 tiers)
        for tier = 0, 2 do
            local w = td[3] - tier*4
            local h = td[4]*0.3 - tier*5
            local treePart = Instance.new("Frame")
            treePart.Size             = UDim2.new(0, w, 0, h)
            treePart.Position         = UDim2.new(td[1], (td[3]-w)/2, td[2] - tier*0.06, -tier*5)
            treePart.BackgroundColor3 = Color3.fromRGB(15 + tier*3, 10 + tier*3, 25 + tier*3)
            treePart.BorderSizePixel  = 0
            treePart.ZIndex           = 4 + tier
            treePart.Parent           = parent
            corner(treePart, w/2)
        end
    end

    -- Water reflection (hồ nước)
    local lake = Instance.new("Frame")
    lake.Size             = UDim2.new(0.5, 0, 0.12, 0)
    lake.Position         = UDim2.new(0.25, 0, 0.82, 0)
    lake.BackgroundColor3 = Color3.fromRGB(30, 45, 80)
    lake.BorderSizePixel  = 0
    lake.ZIndex           = 5
    lake.Parent           = parent
    corner(lake, 20)
    local lakeGrad = Instance.new("UIGradient")
    lakeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 60, 120)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 90, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 45, 90)),
    })
    lakeGrad.Rotation = 90
    lakeGrad.Parent   = lake
    -- Moon reflection in lake
    local moonRef = Instance.new("Frame")
    moonRef.Size             = UDim2.new(0, 12, 0, 30)
    moonRef.Position         = UDim2.new(0.25+0.5*0.75-0.02, 0, 0.82, 5)
    moonRef.BackgroundColor3 = Color3.fromRGB(255, 248, 200)
    moonRef.BackgroundTransparency = 0.5
    moonRef.BorderSizePixel  = 0
    moonRef.ZIndex           = 6
    moonRef.Parent           = parent
    corner(moonRef, 6)
    -- Ripple
    task.spawn(function()
        while moonRef and moonRef.Parent do
            tween(moonRef, {BackgroundTransparency = 0.75}, 1, Enum.EasingStyle.Sine)
            task.wait(1)
            tween(moonRef, {BackgroundTransparency = 0.35}, 1, Enum.EasingStyle.Sine)
            task.wait(1)
        end
    end)

    -- Overlay tối phủ lên để text đọc được
    local darkOverlay = Instance.new("Frame")
    darkOverlay.Size             = UDim2.new(1, 0, 1, 0)
    darkOverlay.BackgroundColor3 = Color3.fromRGB(8, 6, 18)
    darkOverlay.BackgroundTransparency = 0.38
    darkOverlay.BorderSizePixel  = 0
    darkOverlay.ZIndex           = 10
    darkOverlay.Parent           = parent

    -- Sidebar dark overlay
    local sideOverlay = Instance.new("Frame")
    sideOverlay.Size             = UDim2.new(0, 155, 1, 0)
    sideOverlay.BackgroundColor3 = Color3.fromRGB(10, 8, 22)
    sideOverlay.BackgroundTransparency = 0.1
    sideOverlay.BorderSizePixel  = 0
    sideOverlay.ZIndex           = 11
    sideOverlay.Parent           = parent
    local soGrad = Instance.new("UIGradient")
    soGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.85, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    soGrad.Rotation = 0
    soGrad.Parent   = sideOverlay
end

-- ╔══════════════════════════════════════╗
-- ║           MAIN FRAME                 ║
-- ╚══════════════════════════════════════╝
local main = Instance.new("Frame")
main.Size             = UDim2.new(0, 650, 0, 360)
main.Position         = UDim2.new(0.5, -325, 0.5, -180)
main.BackgroundColor3 = C.BG
main.BorderSizePixel  = 0
main.ClipsDescendants = true
main.Parent           = gui
corner(main, 14)

-- Shadow
local shadow = Instance.new("Frame")
shadow.Size             = UDim2.new(1, 20, 1, 20)
shadow.Position         = UDim2.new(0, -10, 0, -10)
shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.55
shadow.BorderSizePixel  = 0
shadow.ZIndex           = main.ZIndex - 1
shadow.Parent           = main
corner(shadow, 18)

-- 🌸 Draw anime background
drawAnimeBG(main)

-- ╔══════════════════════════════════════╗
-- ║           TOPBAR                     ║
-- ╚══════════════════════════════════════╝
local top = Instance.new("Frame")
top.Size             = UDim2.new(1, 0, 0, 42)
top.BackgroundColor3 = Color3.fromRGB(12, 10, 24)
top.BackgroundTransparency = 0.2
top.BorderSizePixel  = 0
top.ZIndex           = 20
top.Parent           = main
corner(top, 14)

local topFix = Instance.new("Frame")
topFix.Size             = UDim2.new(1, 0, 0.5, 0)
topFix.Position         = UDim2.new(0, 0, 0.5, 0)
topFix.BackgroundColor3 = top.BackgroundColor3
topFix.BackgroundTransparency = 0.2
topFix.BorderSizePixel  = 0
topFix.ZIndex           = 20
topFix.Parent           = top

-- Accent line
local accentLine = Instance.new("Frame")
accentLine.Size             = UDim2.new(1, 0, 0, 2)
accentLine.Position         = UDim2.new(0, 0, 1, 0)
accentLine.BackgroundColor3 = C.ACCENT
accentLine.BorderSizePixel  = 0
accentLine.ZIndex           = 21
accentLine.Parent           = top
local accentGrad = Instance.new("UIGradient")
accentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   C.ACCENT),
    ColorSequenceKeypoint.new(0.5, C.ACCENT2),
    ColorSequenceKeypoint.new(1,   C.PINK),
})
accentGrad.Rotation = 0
accentGrad.Parent   = accentLine

-- Title
local titleLbl = Instance.new("TextLabel")
titleLbl.Size              = UDim2.new(1, -90, 1, 0)
titleLbl.Position          = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3        = C.TEXT
titleLbl.TextXAlignment    = Enum.TextXAlignment.Left
titleLbl.Font              = Enum.Font.GothamBold
titleLbl.TextSize          = 15
titleLbl.Text              = "✦  ULTRA V6  ✦"
titleLbl.ZIndex            = 22
titleLbl.Parent            = top

local subLbl = Instance.new("TextLabel")
subLbl.Size              = UDim2.new(0, 120, 1, 0)
subLbl.Position          = UDim2.new(0, 130, 0, 0)
subLbl.BackgroundTransparency = 1
subLbl.TextColor3        = C.SUBTEXT
subLbl.TextXAlignment    = Enum.TextXAlignment.Left
subLbl.Font              = Enum.Font.Gotham
subLbl.TextSize          = 11
subLbl.Text              = "Game Enhancement"
subLbl.ZIndex            = 22
subLbl.Parent            = top

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 28, 0, 28)
closeBtn.Position         = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
closeBtn.Text             = "✕"
closeBtn.TextColor3       = C.TEXT
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 12
closeBtn.BorderSizePixel  = 0
closeBtn.ZIndex           = 22
closeBtn.Parent           = top
corner(closeBtn, 6)

makeDraggable(main, top)

-- ╔══════════════════════════════════════╗
-- ║           MINI ICON                  ║
-- ╚══════════════════════════════════════╝
local mini = Instance.new("Frame")
mini.Size             = UDim2.new(0, 78, 0, 90)
mini.Position         = UDim2.new(0, 20, 1, -110)
mini.BackgroundColor3 = Color3.fromRGB(18, 16, 32)
mini.BorderSizePixel  = 0
mini.ClipsDescendants = false
mini.Visible          = false
mini.Parent           = gui
corner(mini, 12)

-- BG gradient mini
local miniGrad = Instance.new("UIGradient")
miniGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 25, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 12, 28)),
})
miniGrad.Rotation = 135
miniGrad.Parent   = mini

-- Viền accent pulse
local miniStroke = stroke(mini, C.ACCENT, 2)
task.spawn(function()
    while mini and mini.Parent do
        tween(miniStroke, {Color=C.ACCENT2, Transparency=0.6}, 1.2, Enum.EasingStyle.Sine)
        task.wait(1.2)
        tween(miniStroke, {Color=C.ACCENT, Transparency=0}, 1.2, Enum.EasingStyle.Sine)
        task.wait(1.2)
    end
end)

-- Chibi vẽ bên trong mini icon (scale nhỏ)
local miniChibiCanvas = Instance.new("Frame")
miniChibiCanvas.Size             = UDim2.new(1, 0, 1, -22)
miniChibiCanvas.BackgroundTransparency = 1
miniChibiCanvas.ClipsDescendants = true
miniChibiCanvas.ZIndex           = 3
miniChibiCanvas.Parent           = mini
drawChibi(miniChibiCanvas, -5, -2, 0.75)

-- Label dưới mini
local miniLabel = Instance.new("TextLabel")
miniLabel.Size              = UDim2.new(1, 0, 0, 20)
miniLabel.Position          = UDim2.new(0, 0, 1, -22)
miniLabel.BackgroundColor3  = C.ACCENT
miniLabel.BackgroundTransparency = 0.3
miniLabel.TextColor3        = C.TEXT
miniLabel.Font              = Enum.Font.GothamBold
miniLabel.TextSize          = 10
miniLabel.Text              = "ULTRA V6"
miniLabel.ZIndex            = 4
miniLabel.Parent            = mini
local mlCorner = Instance.new("UICorner")
mlCorner.CornerRadius = UDim.new(0, 0)
mlCorner.Parent = miniLabel
local mlFixTop = Instance.new("Frame")
mlFixTop.Size             = UDim2.new(1, 0, 0.5, 0)
mlFixTop.BackgroundColor3 = C.ACCENT
mlFixTop.BackgroundTransparency = 0.3
mlFixTop.BorderSizePixel  = 0
mlFixTop.ZIndex           = 3
mlFixTop.Parent           = miniLabel
corner(miniLabel, 6)

-- Hover mini
local miniBtn = Instance.new("TextButton")
miniBtn.Size             = UDim2.new(1, 0, 1, 0)
miniBtn.BackgroundTransparency = 1
miniBtn.Text             = ""
miniBtn.ZIndex           = 10
miniBtn.Parent           = mini

makeDraggable(mini, miniBtn)

miniBtn.MouseEnter:Connect(function()
    tween(mini, {Size = UDim2.new(0, 86, 0, 100)}, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)
miniBtn.MouseLeave:Connect(function()
    tween(mini, {Size = UDim2.new(0, 78, 0, 90)}, 0.18)
end)

-- Open/close
closeBtn.MouseButton1Click:Connect(function()
    main.Visible  = false
    mini.Visible  = true
    blur.Enabled  = false
end)
miniBtn.MouseButton1Click:Connect(function()
    main.Visible  = true
    mini.Visible  = false
    blur.Enabled  = true
end)

-- ╔══════════════════════════════════════╗
-- ║           SIDEBAR                    ║
-- ╚══════════════════════════════════════╝
local sidebar = Instance.new("Frame")
sidebar.Size             = UDim2.new(0, 148, 1, -42)
sidebar.Position         = UDim2.new(0, 0, 0, 42)
sidebar.BackgroundTransparency = 1
sidebar.BorderSizePixel  = 0
sidebar.ZIndex           = 15
sidebar.Parent           = main

local sideList = Instance.new("UIListLayout")
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Padding   = UDim.new(0, 4)
sideList.Parent    = sidebar
pad(sidebar, 7)

-- Separator
local sep = Instance.new("Frame")
sep.Size             = UDim2.new(0, 1, 1, -42)
sep.Position         = UDim2.new(0, 148, 0, 42)
sep.BackgroundColor3 = C.ACCENT
sep.BackgroundTransparency = 0.5
sep.BorderSizePixel  = 0
sep.ZIndex           = 16
sep.Parent           = main

-- ╔══════════════════════════════════════╗
-- ║           CONTENT AREA               ║
-- ╚══════════════════════════════════════╝
local content = Instance.new("ScrollingFrame")
content.Size             = UDim2.new(1, -153, 1, -48)
content.Position         = UDim2.new(0, 153, 0, 46)
content.BackgroundTransparency = 1
content.BorderSizePixel  = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = C.ACCENT
content.CanvasSize       = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.ZIndex           = 15
content.Parent           = main
pad(content, 10)

local contentList = Instance.new("UIListLayout")
contentList.SortOrder = Enum.SortOrder.LayoutOrder
contentList.Padding   = UDim.new(0, 6)
contentList.Parent    = content

local function clearContent()
    for _, v in ipairs(content:GetChildren()) do
        if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
            v:Destroy()
        end
    end
end

-- ╔══════════════════════════════════════╗
-- ║           NOTIFY                     ║
-- ╚══════════════════════════════════════╝
local notifyStack = 0
local function notify(msg, isError)
    notifyStack = notifyStack + 1
    local yOff = 16 + (notifyStack - 1) * 48
    local nf = Instance.new("Frame")
    nf.Size             = UDim2.new(0, 290, 0, 38)
    nf.Position         = UDim2.new(0.5, -145, 0, yOff)
    nf.BackgroundColor3 = isError and C.ERROR or C.SUCCESS
    nf.BackgroundTransparency = 0.1
    nf.BorderSizePixel  = 0
    nf.ZIndex           = 100
    nf.Parent           = gui
    corner(nf, 10)
    local nt = Instance.new("TextLabel")
    nt.Size              = UDim2.new(1, -12, 1, 0)
    nt.Position          = UDim2.new(0, 12, 0, 0)
    nt.BackgroundTransparency = 1
    nt.TextColor3        = C.TEXT
    nt.Font              = Enum.Font.GothamBold
    nt.TextSize          = 13
    nt.TextXAlignment    = Enum.TextXAlignment.Left
    nt.Text              = msg
    nt.ZIndex            = 101
    nt.Parent            = nf
    task.delay(2, function()
        tween(nf, {BackgroundTransparency=1}, 0.4, Enum.EasingStyle.Sine)
        tween(nt, {TextTransparency=1}, 0.4, Enum.EasingStyle.Sine)
        task.wait(0.45)
        if nf and nf.Parent then nf:Destroy() end
        notifyStack = math.max(0, notifyStack - 1)
    end)
end

-- ╔══════════════════════════════════════╗
-- ║           UI COMPONENTS              ║
-- ╚══════════════════════════════════════╝
local function makeBtn(text, parent, lo)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = C.BTN
    b.BackgroundTransparency = 0.3
    b.Text             = text
    b.TextColor3       = C.TEXT
    b.Font             = Enum.Font.Gotham
    b.TextSize         = 13
    b.BorderSizePixel  = 0
    b.LayoutOrder      = lo or 0
    b.ZIndex           = 16
    b.Parent           = parent
    corner(b, 7)
    b.MouseEnter:Connect(function()
        tween(b, {BackgroundColor3=C.BTN_HOV, BackgroundTransparency=0.1}, 0.15)
    end)
    b.MouseLeave:Connect(function()
        tween(b, {BackgroundColor3=C.BTN, BackgroundTransparency=0.3}, 0.15)
    end)
    return b
end

local function makeLbl(text, parent, lo, col)
    local l = Instance.new("TextLabel")
    l.Size              = UDim2.new(1, 0, 0, 22)
    l.BackgroundTransparency = 1
    l.TextColor3        = col or C.SUBTEXT
    l.Font              = Enum.Font.Gotham
    l.TextSize          = 12
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Text              = text
    l.LayoutOrder       = lo or 0
    l.ZIndex            = 16
    l.Parent            = parent
    return l
end

local function makeCard(parent, lo)
    local c = Instance.new("Frame")
    c.Size             = UDim2.new(1, 0, 0, 0)
    c.AutomaticSize    = Enum.AutomaticSize.Y
    c.BackgroundColor3 = Color3.fromRGB(18, 16, 34)
    c.BackgroundTransparency = 0.2
    c.BorderSizePixel  = 0
    c.LayoutOrder      = lo or 0
    c.ZIndex           = 16
    c.Parent           = parent
    corner(c, 10)
    local cList = Instance.new("UIListLayout")
    cList.SortOrder = Enum.SortOrder.LayoutOrder
    cList.Padding   = UDim.new(0, 5)
    cList.Parent    = c
    pad(c, 10)
    return c
end

-- ╔══════════════════════════════════════╗
-- ║           SIDEBAR TABS               ║
-- ╚══════════════════════════════════════╝
local function createTab(name, icon, lo, fn)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = C.BTN
    b.BackgroundTransparency = 0.5
    b.Text             = icon .. "  " .. name
    b.TextColor3       = C.SUBTEXT
    b.Font             = Enum.Font.Gotham
    b.TextSize         = 13
    b.TextXAlignment   = Enum.TextXAlignment.Left
    b.BorderSizePixel  = 0
    b.LayoutOrder      = lo
    b.ZIndex           = 16
    b.Parent           = sidebar
    corner(b, 7)
    pad(b, 9)
    tabButtons[name] = b

    b.MouseButton1Click:Connect(function()
        for _, tb in pairs(tabButtons) do
            tween(tb, {BackgroundColor3=C.BTN, TextColor3=C.SUBTEXT, BackgroundTransparency=0.5}, 0.15)
        end
        tween(b, {BackgroundColor3=C.ACCENT, TextColor3=C.TEXT, BackgroundTransparency=0.15}, 0.15)
        activeTab = name
        clearContent()
        fn()
    end)
    return b
end

-- ╔══════════════════════════════════════╗
-- ║           ESP                        ║
-- ╚══════════════════════════════════════╝
local function clearESP(char)
    if espCache[char] then
        for _, v in pairs(espCache[char]) do
            if v and v.Parent then v:Destroy() end
        end
        espCache[char] = nil
    end
end

local function createESP(plr, char)
    if not char or espCache[char] then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    if not hum or not head then return end
    local objs = {}
    local hl = Instance.new("Highlight")
    hl.FillColor        = Color3.fromRGB(255, 60, 60)
    hl.OutlineColor     = Color3.fromRGB(255, 180, 180)
    hl.FillTransparency = 0.5
    hl.Parent           = char
    table.insert(objs, hl)
    if espMode == "FULL" then
        local bill = Instance.new("BillboardGui")
        bill.Size        = UDim2.new(0, 200, 0, 44)
        bill.StudsOffset = Vector3.new(0, 3.2, 0)
        bill.AlwaysOnTop = true
        bill.Parent      = head
        local tl = Instance.new("TextLabel")
        tl.Size              = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.TextScaled        = true
        tl.TextColor3        = Color3.new(1,1,1)
        tl.Font              = Enum.Font.GothamBold
        tl.TextStrokeTransparency = 0.4
        tl.Parent            = bill
        local conn
        local function update()
            if not hum or not hum.Parent then
                if conn then conn:Disconnect() end return
            end
            tl.Text = plr.Name .. "  ❤ " .. math.floor(hum.Health)
        end
        conn = hum.HealthChanged:Connect(update)
        update()
        table.insert(objs, bill)
    end
    espCache[char] = objs
    char.AncestryChanged:Connect(function()
        if not char.Parent then clearESP(char) end
    end)
end

local function refreshESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if plr.Character then clearESP(plr.Character) end
            if plr.Character then createESP(plr, plr.Character) end
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        createESP(plr, char)
    end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player and plr.Character then
        createESP(plr, plr.Character)
    end
end

-- ╔══════════════════════════════════════╗
-- ║           NOCLIP                     ║
-- ╚══════════════════════════════════════╝
RunService.Heartbeat:Connect(function()
    if not noclipEnabled then return end
    local char = player.Character
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            v.CanCollide = false
        end
    end
end)

-- ╔══════════════════════════════════════╗
-- ║           SPECTATE                   ║
-- ╚══════════════════════════════════════╝
local function spectate(plr)
    if plr.Character then
        camera.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid")
            or plr.Character:FindFirstChild("HumanoidRootPart")
        notify("👁 Đang xem: " .. plr.Name)
    end
end

local function resetCamera()
    local char = player.Character
    if char then
        camera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
    end
    notify("🎥 Camera reset")
end

-- ╔══════════════════════════════════════╗
-- ║           PREMIUM                    ║
-- ╚══════════════════════════════════════╝
local function applyBuff()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = 16 * premiumMultiplier
    hum.JumpPower = 50 * premiumMultiplier
end

-- Shimmer helper
local function addShimmer(frame)
    local sh = Instance.new("Frame")
    sh.Size             = UDim2.new(0.3, 0, 1, 0)
    sh.Position         = UDim2.new(-0.35, 0, 0, 0)
    sh.BackgroundColor3 = Color3.new(1,1,1)
    sh.BackgroundTransparency = 0.82
    sh.BorderSizePixel  = 0
    sh.ZIndex           = frame.ZIndex + 1
    sh.Parent           = frame
    local sg = Instance.new("UIGradient")
    sg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   1),
        NumberSequenceKeypoint.new(0.5, 0.72),
        NumberSequenceKeypoint.new(1,   1),
    })
    sg.Rotation = 20
    sg.Parent   = sh
    task.spawn(function()
        while sh and sh.Parent do
            tween(sh, {Position=UDim2.new(1.1,0,0,0)}, 1.4, Enum.EasingStyle.Linear)
            task.wait(3.8)
            sh.Position = UDim2.new(-0.35,0,0,0)
        end
    end)
end

local function makePulseDot(parent, col, zidx)
    local d = Instance.new("Frame")
    d.Size             = UDim2.new(0, 9, 0, 9)
    d.BackgroundColor3 = col or C.SUCCESS
    d.BorderSizePixel  = 0
    d.ZIndex           = zidx or 20
    d.Parent           = parent
    corner(d, 5)
    task.spawn(function()
        while d and d.Parent do
            tween(d, {BackgroundTransparency=0.65}, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.7)
            tween(d, {BackgroundTransparency=0}, 0.7, Enum.EasingStyle.Sine)
            task.wait(0.7)
        end
    end)
    return d
end

local function makeStatRow(parent, icon, label, value, col, lo)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = Color3.fromRGB(28, 25, 50)
    row.BackgroundTransparency = 0.1
    row.BorderSizePixel  = 0
    row.LayoutOrder      = lo or 0
    row.ZIndex           = 17
    row.Parent           = parent
    corner(row, 8)

    local badge = Instance.new("Frame")
    badge.Size             = UDim2.new(0, 28, 0, 28)
    badge.Position         = UDim2.new(0, 4, 0.5, -14)
    badge.BackgroundColor3 = col or C.ACCENT
    badge.BackgroundTransparency = 0.5
    badge.BorderSizePixel  = 0
    badge.ZIndex           = 18
    badge.Parent           = row
    corner(badge, 6)

    local iconL = Instance.new("TextLabel")
    iconL.Size              = UDim2.new(1,0,1,0)
    iconL.BackgroundTransparency = 1
    iconL.Text              = icon
    iconL.TextSize          = 14
    iconL.ZIndex            = 19
    iconL.Parent            = badge

    local nameL = Instance.new("TextLabel")
    nameL.Size              = UDim2.new(0.55,0,1,0)
    nameL.Position          = UDim2.new(0,40,0,0)
    nameL.BackgroundTransparency = 1
    nameL.TextColor3        = C.SUBTEXT
    nameL.Font              = Enum.Font.Gotham
    nameL.TextSize          = 12
    nameL.TextXAlignment    = Enum.TextXAlignment.Left
    nameL.Text              = label
    nameL.ZIndex            = 18
    nameL.Parent            = row

    local valL = Instance.new("TextLabel")
    valL.Size              = UDim2.new(0,70,1,0)
    valL.Position          = UDim2.new(1,-74,0,0)
    valL.BackgroundTransparency = 1
    valL.TextColor3        = col or C.ACCENT
    valL.Font              = Enum.Font.GothamBold
    valL.TextSize          = 13
    valL.TextXAlignment    = Enum.TextXAlignment.Right
    valL.Text              = "0"
    valL.ZIndex            = 18
    valL.Parent            = row

    -- Count-up
    task.spawn(function()
        local target = tonumber(tostring(value):match("%d+%.?%d*")) or 0
        for i = 1, 20 do
            task.wait(0.03)
            if valL and valL.Parent then
                valL.Text = tostring(math.floor(target*(i/20)))
            end
        end
        if valL and valL.Parent then valL.Text = tostring(value) end
    end)
    return row
end

-- ╔══════════════════════════════════════╗
-- ║           TAB DEFINITIONS            ║
-- ╚══════════════════════════════════════╝

-- ── ESP ──────────────────────────────
createTab("ESP", "🔴", 1, function()
    local c1 = makeCard(content, 1)
    makeLbl("Chế độ: " .. espMode, c1, 0, C.SUBTEXT)

    local togBtn = makeBtn(
        espMode == "FULL" and "→ Highlight Only" or "→ Full ESP (Tên + Máu)",
        c1, 1)
    togBtn.MouseButton1Click:Connect(function()
        espMode = (espMode == "HIGHLIGHT_ONLY") and "FULL" or "HIGHLIGHT_ONLY"
        refreshESP()
        notify("ESP: " .. espMode)
        clearContent()
        tabButtons["ESP"].MouseButton1Click:Fire()
    end)
    makeLbl("Highlight: khung đỏ. Full: tên + thanh máu.", c1, 2)
end)

-- ── NOCLIP ───────────────────────────
createTab("Noclip", "🧊", 2, function()
    local c1 = makeCard(content, 1)
    local statusLbl = makeLbl(
        "Trạng thái: " .. (noclipEnabled and "🟢 Bật" or "🔴 Tắt"),
        c1, 0, noclipEnabled and C.SUCCESS or C.ERROR)

    local togBtn = makeBtn(noclipEnabled and "Tắt Noclip" or "Bật Noclip", c1, 1)
    togBtn.BackgroundColor3 = noclipEnabled and C.ERROR or C.SUCCESS
    togBtn.BackgroundTransparency = 0.3

    togBtn.MouseButton1Click:Connect(function()
        noclipEnabled = not noclipEnabled
        notify(noclipEnabled and "🧊 Noclip: BẬT" or "🧊 Noclip: TẮT")
        clearContent()
        tabButtons["Noclip"].MouseButton1Click:Fire()
    end)
    makeLbl("Đi xuyên tường và vật thể trong game.", c1, 2)
end)

-- ── CAMERA ───────────────────────────
createTab("Camera", "🎯", 3, function()
    local c1 = makeCard(content, 1)
    makeLbl("Spectate người chơi:", c1, 0)

    local resetBtn = makeBtn("🔄  Reset về nhân vật mình", c1, 1)
    resetBtn.MouseButton1Click:Connect(resetCamera)

    local count = 2
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local pb = makeBtn("👤  " .. plr.Name, c1, count)
            pb.MouseButton1Click:Connect(function() spectate(plr) end)
            count += 1
        end
    end
    if count == 2 then
        makeLbl("Không có người chơi nào khác.", c1, 2, C.ERROR)
    end
end)

-- ── PREMIUM ──────────────────────────
createTab("⭐ Premium", "🔐", 4, function()

    -- === ĐÃ UNLOCK ===
    if premiumUnlocked then
        -- Header
        local hCard = Instance.new("Frame")
        hCard.Size             = UDim2.new(1, 0, 0, 80)
        hCard.BackgroundColor3 = Color3.fromRGB(75, 50, 175)
        hCard.BorderSizePixel  = 0
        hCard.LayoutOrder      = 1
        hCard.ZIndex           = 17
        hCard.Parent           = content
        corner(hCard, 12)
        local hGrad = Instance.new("UIGradient")
        hGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 75, 225)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 38, 135)),
        })
        hGrad.Rotation = 125
        hGrad.Parent   = hCard
        addShimmer(hCard)

        local hTitle = Instance.new("TextLabel")
        hTitle.Size              = UDim2.new(1, 0, 0.6, 0)
        hTitle.BackgroundTransparency = 1
        hTitle.TextColor3        = C.TEXT
        hTitle.Font              = Enum.Font.GothamBold
        hTitle.TextSize          = 20
        hTitle.Text              = "✦  PREMIUM  ✦"
        hTitle.ZIndex            = 19
        hTitle.Parent            = hCard

        -- Status badge
        local statusRow = Instance.new("Frame")
        statusRow.Size             = UDim2.new(0, 110, 0, 22)
        statusRow.Position         = UDim2.new(0.5, -55, 1, -28)
        statusRow.BackgroundColor3 = Color3.fromRGB(0,0,0)
        statusRow.BackgroundTransparency = 0.45
        statusRow.BorderSizePixel  = 0
        statusRow.ZIndex           = 19
        statusRow.Parent           = hCard
        corner(statusRow, 11)

        local dot = makePulseDot(statusRow, C.SUCCESS, 20)
        dot.Position = UDim2.new(0, 8, 0.5, -4)

        local activeLbl = Instance.new("TextLabel")
        activeLbl.Size              = UDim2.new(1,-26,1,0)
        activeLbl.Position          = UDim2.new(0,22,0,0)
        activeLbl.BackgroundTransparency = 1
        activeLbl.TextColor3        = C.SUCCESS
        activeLbl.Font              = Enum.Font.GothamBold
        activeLbl.TextSize          = 11
        activeLbl.TextXAlignment    = Enum.TextXAlignment.Left
        activeLbl.Text              = "ACTIVE"
        activeLbl.ZIndex            = 20
        activeLbl.Parent            = statusRow

        -- Chibi nhỏ trang trí góc phải
        local chibiDeco = Instance.new("Frame")
        chibiDeco.Size             = UDim2.new(0, 70, 0, 80)
        chibiDeco.Position         = UDim2.new(1, -78, 0, -2)
        chibiDeco.BackgroundTransparency = 1
        chibiDeco.ClipsDescendants = true
        chibiDeco.ZIndex           = 18
        chibiDeco.Parent           = hCard
        drawChibi(chibiDeco, -8, -5, 0.65)

        -- Stats
        local sCard = makeCard(content, 2)
        makeLbl("BUFF STATS", sCard, 0, C.SUBTEXT)
        makeStatRow(sCard, "🏃", "WalkSpeed", math.floor(16*premiumMultiplier),
            Color3.fromRGB(100,205,255), 1)
        makeStatRow(sCard, "⬆️", "JumpPower", math.floor(50*premiumMultiplier),
            Color3.fromRGB(255,185,80), 2)
        makeStatRow(sCard, "✦", "Multiplier", premiumMultiplier.."x",
            Color3.fromRGB(185,105,255), 3)

        -- Re-apply
        local reBtn = makeBtn("⚡  Áp dụng lại Buff", content, 3)
        reBtn.BackgroundColor3 = C.ACCENT
        reBtn.BackgroundTransparency = 0
        reBtn.MouseButton1Click:Connect(function()
            applyBuff()
            tween(reBtn, {BackgroundColor3=Color3.fromRGB(255,255,180)}, 0.1)
            task.wait(0.12)
            tween(reBtn, {BackgroundColor3=C.ACCENT}, 0.35)
            notify("⚡ Buff đã áp dụng!")
        end)
        return
    end

    -- === CHƯA UNLOCK ===

    -- Lock card
    local lockCard = Instance.new("Frame")
    lockCard.Size             = UDim2.new(1, 0, 0, 88)
    lockCard.BackgroundColor3 = Color3.fromRGB(24, 22, 44)
    lockCard.BackgroundTransparency = 0.1
    lockCard.BorderSizePixel  = 0
    lockCard.LayoutOrder      = 1
    lockCard.ZIndex           = 17
    lockCard.Parent           = content
    corner(lockCard, 12)
    local lcGrad = Instance.new("UIGradient")
    lcGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 33, 65)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 16, 35)),
    })
    lcGrad.Rotation = 125
    lcGrad.Parent   = lockCard

    -- Lock icon bounce
    local lockIcon = Instance.new("TextLabel")
    lockIcon.Size              = UDim2.new(0, 44, 0, 44)
    lockIcon.Position          = UDim2.new(0.5, -22, 0, 6)
    lockIcon.BackgroundColor3  = Color3.fromRGB(42, 38, 72)
    lockIcon.BackgroundTransparency = 0
    lockIcon.TextColor3        = Color3.fromRGB(200,170,255)
    lockIcon.Font              = Enum.Font.GothamBold
    lockIcon.TextSize          = 22
    lockIcon.Text              = "🔒"
    lockIcon.BorderSizePixel   = 0
    lockIcon.ZIndex            = 18
    lockIcon.Parent            = lockCard
    corner(lockIcon, 10)
    task.spawn(function()
        while lockIcon and lockIcon.Parent do
            tween(lockIcon, {Position=UDim2.new(0.5,-22,0,2)}, 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            task.wait(0.45)
            tween(lockIcon, {Position=UDim2.new(0.5,-22,0,7)}, 0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            task.wait(2.2)
        end
    end)

    local lockLbl = Instance.new("TextLabel")
    lockLbl.Size              = UDim2.new(1,0,0,20)
    lockLbl.Position          = UDim2.new(0,0,1,-26)
    lockLbl.BackgroundTransparency = 1
    lockLbl.TextColor3        = C.SUBTEXT
    lockLbl.Font              = Enum.Font.Gotham
    lockLbl.TextSize          = 12
    lockLbl.Text              = "Nhập key để mở khoá"
    lockLbl.ZIndex            = 18
    lockLbl.Parent            = lockCard

    -- Perks preview card
    local perksCard = makeCard(content, 2)
    makeLbl("QUYỀN LỢI KHI MỞ KHOÁ", perksCard, 0, C.SUBTEXT)

    local perks = {
        {"🏃", "WalkSpeed ×"..premiumMultiplier, Color3.fromRGB(100,205,255)},
        {"⬆️", "JumpPower ×"..premiumMultiplier, Color3.fromRGB(255,185,80)},
        {"⭐", "Badge Premium độc quyền",          C.GOLD},
        {"🎮", "Tính năng ẩn được mở khoá",        C.PINK},
    }
    for i, pk in ipairs(perks) do
        local pRow = Instance.new("Frame")
        pRow.Size             = UDim2.new(1,0,0,30)
        pRow.BackgroundColor3 = Color3.fromRGB(30,27,54)
        pRow.BackgroundTransparency = 0.1
        pRow.BorderSizePixel  = 0
        pRow.LayoutOrder      = i
        pRow.ZIndex           = 17
        pRow.Position         = UDim2.new(-1,0,0,0)
        pRow.Parent           = perksCard
        corner(pRow, 7)

        local pIco = Instance.new("TextLabel")
        pIco.Size              = UDim2.new(0,24,1,0)
        pIco.Position          = UDim2.new(0,6,0,0)
        pIco.BackgroundTransparency = 1
        pIco.Text              = pk[1]
        pIco.TextSize          = 14
        pIco.ZIndex            = 18
        pIco.Parent            = pRow

        local pTxt = Instance.new("TextLabel")
        pTxt.Size              = UDim2.new(1,-36,1,0)
        pTxt.Position          = UDim2.new(0,34,0,0)
        pTxt.BackgroundTransparency = 1
        pTxt.TextColor3        = pk[3]
        pTxt.Font              = Enum.Font.Gotham
        pTxt.TextSize          = 12
        pTxt.TextXAlignment    = Enum.TextXAlignment.Left
        pTxt.Text              = pk[2]
        pTxt.ZIndex            = 18
        pTxt.Parent            = pRow

        -- Slide in
        task.delay(i*0.1, function()
            if pRow and pRow.Parent then
                tween(pRow, {Position=UDim2.new(0,0,0,0)}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            end
        end)
    end

    -- Input card
    local inputCard = makeCard(content, 3)
    makeLbl("NHẬP KEY", inputCard, 0, C.SUBTEXT)

    local inputWrap = Instance.new("Frame")
    inputWrap.Size             = UDim2.new(1,0,0,38)
    inputWrap.BackgroundColor3 = C.ACCENT
    inputWrap.BackgroundTransparency = 0.6
    inputWrap.BorderSizePixel  = 0
    inputWrap.LayoutOrder      = 1
    inputWrap.ZIndex           = 17
    inputWrap.Parent           = inputCard
    corner(inputWrap, 8)

    local box = Instance.new("TextBox")
    box.Size              = UDim2.new(1,-4,1,-4)
    box.Position          = UDim2.new(0,2,0,2)
    box.BackgroundColor3  = Color3.fromRGB(18,16,34)
    box.TextColor3        = C.TEXT
    box.PlaceholderText   = "Nhập key tại đây..."
    box.PlaceholderColor3 = C.SUBTEXT
    box.Font              = Enum.Font.Gotham
    box.TextSize          = 13
    box.BorderSizePixel   = 0
    box.ClearTextOnFocus  = false
    box.ZIndex            = 18
    box.Parent            = inputWrap
    corner(box, 7)
    pad(box, 10)

    box.Focused:Connect(function()
        tween(inputWrap, {BackgroundTransparency=0.15}, 0.2)
    end)
    box.FocusLost:Connect(function()
        tween(inputWrap, {BackgroundTransparency=0.6}, 0.2)
    end)

    -- Unlock button
    local unlockWrap = Instance.new("Frame")
    unlockWrap.Size             = UDim2.new(1,0,0,38)
    unlockWrap.BackgroundColor3 = Color3.fromRGB(95,65,215)
    unlockWrap.BorderSizePixel  = 0
    unlockWrap.LayoutOrder      = 2
    unlockWrap.ClipsDescendants = true
    unlockWrap.ZIndex           = 17
    unlockWrap.Parent           = inputCard
    corner(unlockWrap, 8)
    local uwGrad = Instance.new("UIGradient")
    uwGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(130,90,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(75,48,175)),
    })
    uwGrad.Rotation = 90
    uwGrad.Parent   = unlockWrap
    addShimmer(unlockWrap)

    local unlockBtn = Instance.new("TextButton")
    unlockBtn.Size             = UDim2.new(1,0,1,0)
    unlockBtn.BackgroundTransparency = 1
    unlockBtn.Text             = "🔓  UNLOCK PREMIUM"
    unlockBtn.TextColor3       = C.TEXT
    unlockBtn.Font             = Enum.Font.GothamBold
    unlockBtn.TextSize         = 13
    unlockBtn.BorderSizePixel  = 0
    unlockBtn.ZIndex           = 18
    unlockBtn.Parent           = unlockWrap

    unlockBtn.MouseEnter:Connect(function()
        tween(unlockWrap, {BackgroundColor3=Color3.fromRGB(145,105,255)}, 0.15)
    end)
    unlockBtn.MouseLeave:Connect(function()
        tween(unlockWrap, {BackgroundColor3=Color3.fromRGB(95,65,215)}, 0.15)
    end)

    unlockBtn.MouseButton1Click:Connect(function()
        if box.Text:gsub("%s+","") == VALID_KEY then
            tween(unlockWrap, {BackgroundColor3=C.SUCCESS}, 0.15)
            task.wait(0.35)
            premiumUnlocked = true
            applyBuff()
            notify("✅ Premium đã mở khoá!")
            clearContent()
            tabButtons["⭐ Premium"].MouseButton1Click:Fire()
        else
            -- Shake
            tween(unlockWrap, {BackgroundColor3=C.ERROR}, 0.1)
            for i = 1, 3 do
                tween(unlockWrap, {Position=UDim2.new(0,6,unlockWrap.Position.Y.Scale,unlockWrap.Position.Y.Offset)}, 0.06)
                task.wait(0.06)
                tween(unlockWrap, {Position=UDim2.new(0,-6,unlockWrap.Position.Y.Scale,unlockWrap.Position.Y.Offset)}, 0.06)
                task.wait(0.06)
            end
            tween(unlockWrap, {
                Position=UDim2.new(0,0,unlockWrap.Position.Y.Scale,unlockWrap.Position.Y.Offset),
                BackgroundColor3=Color3.fromRGB(95,65,215)
            }, 0.1)
            notify("❌ Sai key!", true)
        end
    end)
end)

-- ╔══════════════════════════════════════╗
-- ║  Auto-open first tab                 ║
-- ╚══════════════════════════════════════╝
task.wait(0.1)
tabButtons["ESP"].MouseButton1Click:Fire()
