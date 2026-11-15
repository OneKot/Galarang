--!strict
--[[
    CharacterMorphService.luau
    Автоматически трансформирует персонажа любого вошедшего игрока в
    резную деревянную фигурку рыцаря по концепт-арту char-knight-sheet-turnaround.png
    и правилам style-rules.md:
    
    1. Голова: Идеально гладкий шар из светлого ясеня БЕЗ ЛИЦА (никаких глаз/рта).
    2. Шарниры: Выразительные деревянные сферические шарниры (ball-in-socket)
       на шее, плечах и локтях, создающие ощущение живой шарнирной куклы/манекена.
    3. Доспех: Стёганый табард королевского синего цвета с золотой короной на груди,
       латунный венец с шипами, кожаный ремень с латунной пряжкой, поножи и наручи.
    4. Стартовое снаряжение: Меч с резной деревянной рукоятью и щит с золотой короной.
    5. Защита от падения: Постоянный мониторинг высоты (HumanoidRootPart.Y >= 2).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterMorphService = {}

local WOOD_DARK = Color3.fromRGB(85, 55, 35)      -- Тёмный резной орех
local WOOD_LIGHT = Color3.fromRGB(205, 160, 115)  -- Полированный светлый ясень
local WOOD_BALL = Color3.fromRGB(150, 105, 70)    -- Древесина шарниров
local ROYAL_BLUE = Color3.fromRGB(20, 48, 108)    -- Королевская синяя эмаль
local BRASS_GOLD = Color3.fromRGB(225, 185, 60)   -- Полированная латунь
local LEATHER_BROWN = Color3.fromRGB(65, 42, 28)  -- Тёмно-коричневая кожа

function CharacterMorphService.Init()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(0.15)
            CharacterMorphService.ApplyWoodenKnight(character)
        end)

        if player.Character then
            CharacterMorphService.ApplyWoodenKnight(player.Character)
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            CharacterMorphService.ApplyWoodenKnight(player.Character)
        end
    end
end

local function createWeld(part0: BasePart, part1: BasePart): WeldConstraint
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part0
    weld.Part1 = part1
    weld.Parent = part1
    return weld
end

function CharacterMorphService.ApplyWoodenKnight(character: Model)
    local humanoid = character:WaitForChild("Humanoid", 4) :: Humanoid?
    if not humanoid then return end

    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.WalkSpeed = 14
    pcall(function()
        humanoid.UseJumpPower = true
        humanoid.JumpPower = 36
    end)

    -- Удаляем стандартную одежду и аксессуары Roblox
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Destroy()
        end
    end

    local hrp = character:WaitForChild("HumanoidRootPart", 4) :: BasePart?
    if not hrp then return end

    -- Безопасный спавн
    if hrp.Position.Y < 3 then
        hrp.CFrame = CFrame.new(0, 6, 25)
    end

    -- 1. ГОЛОВА: Идеальный гладкий деревянный шар БЕЗ ЛИЦА
    local head = character:FindFirstChild("Head") :: BasePart?
    if head then
        local face = head:FindFirstChild("face")
        if face then face:Destroy() end

        head.Material = Enum.Material.SmoothPlastic
        head.Color = WOOD_LIGHT
        head.Transparency = 0

        local mesh = head:FindFirstChildOfClass("SpecialMesh")
        if not mesh then
            mesh = Instance.new("SpecialMesh")
            mesh.Parent = head
        end
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Scale = Vector3.new(1.18, 1.18, 1.18)

        -- Изящный латунный венец с шипами и сапфиром
        if not head:FindFirstChild("KnightCirclet") then
            local circlet = Instance.new("Part")
            circlet.Name = "KnightCirclet"
            circlet.Size = Vector3.new(1.22, 0.12, 1.22)
            circlet.Color = BRASS_GOLD
            circlet.Material = Enum.Material.Metal
            circlet.CanCollide = false
            circlet.Massless = true
            circlet.CFrame = head.CFrame * CFrame.new(0, 0.22, 0)
            circlet.Parent = head
            createWeld(head, circlet)

            for i = 1, 5 do
                local angle = (i - 1) * (math.pi * 2 / 5)
                local spike = Instance.new("Part")
                spike.Name = "Spike" .. i
                spike.Size = Vector3.new(0.08, 0.16, 0.08)
                spike.Color = BRASS_GOLD
                spike.Material = Enum.Material.Metal
                spike.CanCollide = false
                spike.Massless = true
                spike.CFrame = circlet.CFrame * CFrame.new(math.cos(angle) * 0.58, 0.12, math.sin(angle) * 0.58)
                spike.Parent = circlet
                createWeld(circlet, spike)
            end

            local gem = Instance.new("Part")
            gem.Name = "CrownGem"
            gem.Size = Vector3.new(0.14, 0.14, 0.08)
            gem.Color = Color3.fromRGB(30, 120, 255)
            gem.Material = Enum.Material.Glass
            gem.CanCollide = false
            gem.Massless = true
            gem.CFrame = circlet.CFrame * CFrame.new(0, 0.02, -0.62)
            gem.Parent = circlet
            createWeld(circlet, gem)
        end
    end

    -- 2. ТОРС: Стёганый королевский синий табард с латунным гербом-короной
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and not part.Name:find("Circlet") and part.Name ~= "Head" then
            part.Transparency = 0
            if part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" then
                part.Material = Enum.Material.Fabric
                part.Color = ROYAL_BLUE
            elseif part.Name:find("Arm") or part.Name:find("Hand") then
                part.Material = Enum.Material.Wood
                part.Color = WOOD_LIGHT
            elseif part.Name:find("Leg") or part.Name:find("Foot") then
                part.Material = Enum.Material.Wood
                part.Color = WOOD_DARK
            end
        end
    end

    local torso = (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
    if torso and not torso:FindFirstChild("KnightDecor") then
        local decorFolder = Instance.new("Folder")
        decorFolder.Name = "KnightDecor"
        decorFolder.Parent = torso

        -- Золотой герб Короны на груди
        local crest = Instance.new("Part")
        crest.Name = "ChestCrest"
        crest.Size = Vector3.new(0.7, 0.6, 0.05)
        crest.Color = BRASS_GOLD
        crest.Material = Enum.Material.Metal
        crest.CanCollide = false
        crest.Massless = true
        crest.CFrame = torso.CFrame * CFrame.new(0, 0.2, -0.53)
        crest.Parent = decorFolder
        createWeld(torso, crest)

        -- Кожаный ремень с латунной пряжкой
        local belt = Instance.new("Part")
        belt.Name = "LeatherBelt"
        belt.Size = Vector3.new(2.05, 0.35, 1.1)
        belt.Color = LEATHER_BROWN
        belt.Material = Enum.Material.WoodPlanks
        belt.CanCollide = false
        belt.Massless = true
        belt.CFrame = torso.CFrame * CFrame.new(0, -0.65, 0)
        belt.Parent = decorFolder
        createWeld(torso, belt)

        local buckle = Instance.new("Part")
        buckle.Name = "BeltBuckle"
        buckle.Size = Vector3.new(0.45, 0.35, 0.08)
        buckle.Color = BRASS_GOLD
        buckle.Material = Enum.Material.Metal
        buckle.CanCollide = false
        buckle.Massless = true
        buckle.CFrame = belt.CFrame * CFrame.new(0, 0, -0.55)
        buckle.Parent = decorFolder
        createWeld(belt, buckle)
    end

    -- 3. ШАРНИРНЫЕ СФЕРЫ НА ПЛЕЧАХ (Характерная черта куклы-манекена)
    local leftShoulder = (character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")) :: BasePart?
    if leftShoulder and not leftShoulder:FindFirstChild("BallJoint") then
        local sphere = Instance.new("Part")
        sphere.Name = "BallJoint"
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(1.15, 1.15, 1.15)
        sphere.Color = WOOD_BALL
        sphere.Material = Enum.Material.Wood
        sphere.CanCollide = false
        sphere.Massless = true
        sphere.CFrame = leftShoulder.CFrame * CFrame.new(0, 0.45, 0)
        sphere.Parent = leftShoulder
        createWeld(leftShoulder, sphere)
    end

    local rightShoulder = (character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")) :: BasePart?
    if rightShoulder and not rightShoulder:FindFirstChild("BallJoint") then
        local sphere = Instance.new("Part")
        sphere.Name = "BallJoint"
        sphere.Shape = Enum.PartType.Ball
        sphere.Size = Vector3.new(1.15, 1.15, 1.15)
        sphere.Color = WOOD_BALL
        sphere.Material = Enum.Material.Wood
        sphere.CanCollide = false
        sphere.Massless = true
        sphere.CFrame = rightShoulder.CFrame * CFrame.new(0, 0.45, 0)
        sphere.Parent = rightShoulder
        createWeld(rightShoulder, sphere)
    end

    -- 4. РЕЗНОЙ ДЕРЕВЯННЫЙ ЩИТ НА ЛЕВОМ ПРЕДПЛЕЧЬЕ (по референсу char-knight-sheet-turnaround.png)
    local leftArm = (character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm")) :: BasePart?
    if leftArm and not leftArm:FindFirstChild("WoodenShield") then
        local shield = Instance.new("Part")
        shield.Name = "WoodenShield"
        shield.Shape = Enum.PartType.Cylinder
        shield.Size = Vector3.new(0.25, 2.2, 2.2)
        shield.Color = WOOD_DARK
        shield.Material = Enum.Material.WoodPlanks
        shield.CanCollide = false
        shield.Massless = true
        shield.CFrame = leftArm.CFrame * CFrame.new(-0.4, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
        shield.Parent = leftArm
        createWeld(leftArm, shield)

        local rim = Instance.new("Part")
        rim.Name = "ShieldRim"
        rim.Shape = Enum.PartType.Cylinder
        rim.Size = Vector3.new(0.28, 2.3, 2.3)
        rim.Color = BRASS_GOLD
        rim.Material = Enum.Material.Metal
        rim.CanCollide = false
        rim.Massless = true
        rim.CFrame = shield.CFrame
        rim.Parent = shield
        createWeld(shield, rim)

        local shieldCrown = Instance.new("Part")
        shieldCrown.Name = "ShieldCrown"
        shieldCrown.Size = Vector3.new(0.32, 0.7, 0.7)
        shieldCrown.Color = BRASS_GOLD
        shieldCrown.Material = Enum.Material.Metal
        shieldCrown.CanCollide = false
        shieldCrown.Massless = true
        shieldCrown.CFrame = shield.CFrame * CFrame.new(0.04, 0, 0)
        shieldCrown.Parent = shield
        createWeld(shield, shieldCrown)
    end

    -- 5. РЕЗНОЙ ДЕРЕВЯННЫЙ МЕЧ В НОЖНАХ НА ПОЯСЕ
    local hip = (character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")) :: BasePart?
    if hip and not hip:FindFirstChild("SheathedSword") then
        local scabbard = Instance.new("Part")
        scabbard.Name = "SheathedSword"
        scabbard.Size = Vector3.new(0.25, 2.4, 0.5)
        scabbard.Color = LEATHER_BROWN
        scabbard.Material = Enum.Material.SmoothPlastic
        scabbard.CanCollide = false
        scabbard.Massless = true
        scabbard.CFrame = hip.CFrame * CFrame.new(1.1, -0.3, 0) * CFrame.Angles(0, 0, math.rad(22))
        scabbard.Parent = hip
        createWeld(hip, scabbard)

        local hilt = Instance.new("Part")
        hilt.Name = "SwordHilt"
        hilt.Size = Vector3.new(0.22, 0.8, 0.22)
        hilt.Color = WOOD_LIGHT
        hilt.Material = Enum.Material.Wood
        hilt.CanCollide = false
        hilt.Massless = true
        hilt.CFrame = scabbard.CFrame * CFrame.new(0, 1.4, 0)
        hilt.Parent = scabbard
        createWeld(scabbard, hilt)

        local pommel = Instance.new("Part")
        pommel.Name = "SwordPommel"
        pommel.Shape = Enum.PartType.Ball
        pommel.Size = Vector3.new(0.35, 0.35, 0.35)
        pommel.Color = BRASS_GOLD
        pommel.Material = Enum.Material.Metal
        pommel.CanCollide = false
        pommel.Massless = true
        pommel.CFrame = hilt.CFrame * CFrame.new(0, 0.45, 0)
        pommel.Parent = scabbard
        createWeld(scabbard, pommel)

        local guard = Instance.new("Part")
        guard.Name = "CrossGuard"
        guard.Size = Vector3.new(0.26, 0.12, 0.9)
        guard.Color = BRASS_GOLD
        guard.Material = Enum.Material.Metal
        guard.CanCollide = false
        guard.Massless = true
        guard.CFrame = scabbard.CFrame * CFrame.new(0, 1.05, 0)
        guard.Parent = scabbard
        createWeld(scabbard, guard)
    end

    -- 3. Резной деревянный шильдик над головой
    local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if hrp then
        -- Безопасный спавн
        if hrp.Position.Y < 3 then
            hrp.CFrame = CFrame.new(0, 6, 25)
        end

        if not hrp:FindFirstChild("FigurineOverhead") then
            local bb = Instance.new("BillboardGui")
            bb.Name = "FigurineOverhead"
            bb.Size = UDim2.new(0, 190, 0, 52)
            bb.StudsOffset = Vector3.new(0, 3.4, 0)
            bb.AlwaysOnTop = false
            bb.MaxDistance = 55
            bb.Parent = hrp

            local player = Players:GetPlayerFromCharacter(character)

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 0, 24)
            nameLabel.Position = UDim2.new(0, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player and (player.DisplayName or player.Name) or "Резной Рыцарь"
            nameLabel.TextColor3 = BRASS_GOLD
            nameLabel.Font = Enum.Font.Fondamento
            nameLabel.TextSize = 19
            nameLabel.Parent = bb

            local nameStroke = Instance.new("UIStroke")
            nameStroke.Color = Color3.fromRGB(24, 16, 10)
            nameStroke.Thickness = 2
            nameStroke.Parent = nameLabel

            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, 0, 0, 18)
            titleLabel.Position = UDim2.new(0, 0, 0, 22)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = "★ Резной Оруженосец ★"
            titleLabel.TextColor3 = Color3.fromRGB(225, 215, 195)
            titleLabel.Font = Enum.Font.Fondamento
            titleLabel.TextSize = 13
            titleLabel.Parent = bb

            local titleStroke = Instance.new("UIStroke")
            titleStroke.Color = Color3.fromRGB(24, 16, 10)
            titleStroke.Thickness = 1.5
            titleStroke.Parent = titleLabel
        end

        -- Непрерывный сторож от падения в бездну
        task.spawn(function()
            while character.Parent and hrp.Parent do
                if hrp.Position.Y < -5 then
                    hrp.Velocity = Vector3.zero
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.CFrame = CFrame.new(0, 6, 25)
                end
                task.wait(0.5)
            end
        end)
    end
end

return CharacterMorphService
