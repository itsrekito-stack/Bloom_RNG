local RS=game:GetService("ReplicatedStorage")
local Theme=require(RS.Config.UIThemeConfig)
local UIColors=Theme.Colors

local function part(parent: Instance, name: string, size: Vector3, color: Color3, shape: Enum.PartType?, material: Enum.Material?, transparency: number?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Anchored = true
    p.CanCollide = name == "Ground" or name == "Border"
    p.CanTouch = false
    p.CanQuery = true
    p.CastShadow = true
    p.Material = material or Enum.Material.SmoothPlastic
    p.Transparency = transparency or 0
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end

local function roundedBillboard(parent: BasePart, name: string, size: UDim2, studs: Vector3): (BillboardGui, TextLabel)
    local b = Instance.new("BillboardGui")
    b.Name = name
    b.Size = size
    b.StudsOffset = studs
    b.AlwaysOnTop = true
    b.MaxDistance = 125
    b.Parent = parent
    local t = Instance.new("TextLabel")
    t.Name = "Text"
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundColor3 = Color3.fromRGB(25, 35, 46)
    t.BackgroundTransparency = .10
    t.BorderSizePixel = 0
    t.TextColor3 = Color3.fromRGB(244, 249, 255)
    t.TextStrokeTransparency = .6
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextWrapped = true
    t.Parent = b
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = t
    return b, t
end

local function stem(parent: Model, pos: Vector3, h: number, color: Color3): Part
    local x = part(parent, "Stem", Vector3.new(h, .34, .34), color, Enum.PartType.Cylinder)
    x.CanCollide = false
    x.CFrame = CFrame.new(pos + Vector3.new(0, h * .5, 0)) * CFrame.Angles(0, 0, math.rad(90))
    return x
end

local function petal(parent: Model, name: string, center: Vector3, angle: number, dist: number, size: Vector3, color: Color3, tilt: number?): Part
    local x = part(parent, name, size, color, Enum.PartType.Ball)
    x.CanCollide = false
    x.CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)) * CFrame.Angles(math.rad(tilt or 10), angle, 0)
    return x
end

local function makeFlowerModel(slotId: number, species: any, position: Vector3): Model
    local m = Instance.new("Model")
    m.Name = string.format("FlowerSlot_%02d", slotId)
    local root = part(m, "Root", Vector3.new(.2, .2, .2), Color3.new(1, 1, 1), nil, nil, 1)
    root.CanCollide = false
    root.CanQuery = false
    root.CFrame = CFrame.new(position)
    m.PrimaryPart = root

    local angle = (slotId * 1.37) % (math.pi * 2)
    local h = 2.45
    stem(m, position, h, Color3.fromRGB(70, 159, 88))
    for leafIndex, leafAngle in ipairs({angle + .7, angle + 3.55}) do
        local y = leafIndex == 1 and .76 or 1.20
        local leaf = part(m, "Leaf" .. leafIndex, Vector3.new(.8, .16, 1.25), Color3.fromRGB(83, 178, 97), Enum.PartType.Ball)
        leaf.CanCollide = false
        leaf.CFrame = CFrame.new(position + Vector3.new(math.cos(leafAngle) * .46, y, math.sin(leafAngle) * .46)) * CFrame.Angles(math.rad(22), leafAngle, math.rad(28))
    end

    local center = position + Vector3.new(0, h + .18, 0)
    local bloom = part(m, "Bloom", Vector3.new(.58, .58, .58), species.AccentColor, Enum.PartType.Ball)
    bloom.CanCollide = false
    bloom.CFrame = CFrame.new(center)
    local key = species.ShapeKey
    if key == "Daisy" then
        for i = 1, 8 do petal(m, "Petal"..i, center, i / 8 * math.pi * 2, .58, Vector3.new(.52, .18, .98), species.Color, 12) end
    elseif key == "Tulip" then
        bloom.Size = Vector3.new(.45, .45, .45)
        for i = 1, 5 do
            local a = i / 5 * math.pi * 2
            local x = part(m, "Petal"..i, Vector3.new(.38, .76, .56), species.Color, Enum.PartType.Ball)
            x.CanCollide = false
            x.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * .2, .18, math.sin(a) * .2)) * CFrame.Angles(math.rad(-18), a, 0)
        end
    elseif key == "Sunflower" then
        bloom.Size = Vector3.new(.82, .82, .82)
        bloom.Color = species.AccentColor
        for i = 1, 12 do petal(m, "Petal"..i, center, i / 12 * math.pi * 2, .78, Vector3.new(.42, .15, 1.02), species.Color, 16) end
    elseif key == "Clover" then
        bloom:Destroy()
        for i = 1, 4 do
            local a = i / 4 * math.pi * 2 + math.rad(45)
            local x = part(m, "Petal"..i, Vector3.new(.78, .18, .78), species.Color, Enum.PartType.Ball)
            x.CanCollide = false
            x.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * .31, 0, math.sin(a) * .31))
        end
        bloom = part(m, "Bloom", Vector3.new(.24, .24, .24), species.AccentColor, Enum.PartType.Ball)
        bloom.CanCollide = false
        bloom.CFrame = CFrame.new(center)
    elseif key == "CrystalRose" or key == "PrismBloom" then
        bloom.Size = Vector3.new(.42, .42, .42)
        for i = 1, 7 do
            local a = i / 7 * math.pi * 2
            local x = part(m, "Crystal"..i, Vector3.new(.18, .72, .42), i % 2 == 0 and species.Color or species.AccentColor, Enum.PartType.Block, Enum.Material.Neon)
            x.CanCollide = false
            x.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * .34, .12, math.sin(a) * .34)) * CFrame.Angles(math.rad(28), a, math.rad(28))
        end
    elseif key == "FrostLily" or key == "MoonOrchid" then
        for i = 1, 6 do petal(m, "Petal"..i, center, i / 6 * math.pi * 2, .58, Vector3.new(.40, .14, 1.18), i % 2 == 0 and species.Color or species.AccentColor, 22) end
    elseif key == "VoidLotus" then
        bloom.Size = Vector3.new(.38, .38, .38)
        for i = 1, 9 do petal(m, "Petal"..i, center, i / 9 * math.pi * 2, .65, Vector3.new(.42, .14, 1.02), i % 2 == 0 and species.Color or species.AccentColor, 10) end
    elseif key == "StarBloom" then
        bloom.Size = Vector3.new(.30, .30, .30)
        for i = 1, 5 do
            local a = i / 5 * math.pi * 2
            local x = part(m, "Accent"..i, Vector3.new(.18, .18, 1.30), species.Color, Enum.PartType.Block, Enum.Material.Neon)
            x.CanCollide = false
            x.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * .27, 0, math.sin(a) * .27)) * CFrame.Angles(0, a, math.rad(45))
        end
    elseif key == "EmberDahlia" then
        bloom.Size = Vector3.new(.46, .46, .46)
        for ring = 1, 2 do
            for i = 1, 8 do petal(m, "Petal"..ring.."_"..i, center + Vector3.new(0, (ring - 1) * .08, 0), i / 8 * math.pi * 2, .38 + ring * .18, Vector3.new(.34, .12, .80), ring == 1 and species.AccentColor or species.Color, 18) end
        end
    else
        for i = 1, 6 do petal(m, "Petal"..i, center, i / 6 * math.pi * 2, .52, Vector3.new(.42, .16, .9), species.Color, 18) end
    end

    local info = Instance.new("BillboardGui")
    info.Name = "FlowerInfo"
    info.Size = UDim2.fromOffset(142, 46)
    info.StudsOffset = Vector3.new(0, 3.45, 0)
    info.AlwaysOnTop = true
    info.MaxDistance = 28
    info.LightInfluence = 0
    info.Enabled = false
    info.Parent = bloom

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.fromScale(1, 1)
    card.BackgroundColor3 = UIColors.Panel
    card.BackgroundTransparency = .08
    card.BorderSizePixel = 0
    card.Parent = info
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 9)
    cardCorner.Parent = card
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = UIColors.BorderDark
    cardStroke.Thickness = 1.25
    cardStroke.Transparency = .16
    cardStroke.Parent = card

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.fromOffset(3, 22)
    accent.Position = UDim2.fromOffset(7, 7)
    accent.BackgroundColor3 = species.AccentColor
    accent.BorderSizePixel = 0
    accent.Parent = card
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 2)
    accentCorner.Parent = accent

    local tx = Instance.new("TextLabel")
    tx.Name = "LevelText"
    tx.Position = UDim2.fromOffset(15, 4)
    tx.Size = UDim2.new(1, -22, 0, 22)
    tx.BackgroundTransparency = 1
    tx.TextColor3 = UIColors.Text
    tx.TextStrokeTransparency = 1
    tx.Font = Enum.Font.GothamBold
    tx.TextSize = 10
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.TextTruncate = Enum.TextTruncate.AtEnd
    tx.Text = species.DisplayName .. "  •  LV.1"
    tx.Parent = card

    local bg = Instance.new("Frame")
    bg.Name = "ProgressBG"
    bg.Position = UDim2.fromOffset(15, 31)
    bg.Size = UDim2.new(1, -23, 0, 6)
    bg.BackgroundColor3 = UIColors.PanelRaised
    bg.BorderSizePixel = 0
    bg.Parent = card
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = bg

    local fl = Instance.new("Frame")
    fl.Name = "ProgressFill"
    fl.Size = UDim2.fromScale(0, 1)
    fl.BackgroundColor3 = species.AccentColor
    fl.BorderSizePixel = 0
    fl.Parent = bg
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(1, 0)
    c2.Parent = fl
    return m
end


local S={}
S.Build=makeFlowerModel
return S
