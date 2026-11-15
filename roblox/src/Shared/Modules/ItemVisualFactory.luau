--!strict
--[[
    ItemVisualFactory.luau
    Создает процедурные стилизованные 3D-модели оружия, щитов и аур
    в стиле «Резные фигурки» (дерево, сталь, латунь, кристаллы, антиматерия).
]]

local Rarities = require(script.Parent.Parent.Config.Rarities)

local ItemVisualFactory = {}

local BRASS_COLOR = Color3.fromRGB(212, 175, 55)
local STEEL_COLOR = Color3.fromRGB(195, 200, 205)
local OAK_COLOR = Color3.fromRGB(130, 85, 55)
local DIAMOND_COLOR = Color3.fromRGB(180, 230, 255)
local VOID_COLOR = Color3.fromRGB(35, 15, 50)
local ABSOLUTE_COLOR = Color3.fromRGB(255, 255, 255)

function ItemVisualFactory.CreateWeaponModel(itemId: string, rarity: number): Model
    local model = Instance.new("Model")
    model.Name = "Weapon_" .. itemId

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.3, 1.2, 0.3)
    handle.Material = Enum.Material.Wood
    handle.Color = OAK_COLOR
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = model
    model.PrimaryPart = handle

    -- Клинок
    local blade = Instance.new("Part")
    blade.Name = "Blade"
    blade.CanCollide = false
    blade.Massless = true

    if rarity == 7 then -- Absolute
        blade.Size = Vector3.new(0.4, 4.2, 0.8)
        blade.Material = Enum.Material.Neon
        blade.Color = ABSOLUTE_COLOR
    elseif rarity == 6 then -- Secret
        blade.Size = Vector3.new(0.4, 4.0, 0.7)
        blade.Material = Enum.Material.Glass
        blade.Color = VOID_COLOR
    elseif rarity == 5 then -- Legendary
        blade.Size = Vector3.new(0.35, 3.8, 0.6)
        blade.Material = Enum.Material.Neon
        blade.Color = Color3.fromRGB(255, 215, 60)
    elseif rarity == 4 then -- Mythic
        blade.Size = Vector3.new(0.3, 3.4, 0.5)
        blade.Material = Enum.Material.Neon
        blade.Color = Color3.fromRGB(255, 50, 40)
    elseif rarity == 3 then -- Epic
        blade.Size = Vector3.new(0.25, 3.0, 0.45)
        blade.Material = Enum.Material.SmoothPlastic
        blade.Color = Color3.fromRGB(180, 80, 240)
    elseif rarity >= 2 then -- Rare
        blade.Size = Vector3.new(0.2, 2.8, 0.4)
        blade.Material = Enum.Material.Metal
        blade.Color = STEEL_COLOR
    else -- Common / Uncommon
        blade.Size = Vector3.new(0.2, 2.2, 0.35)
        blade.Material = Enum.Material.Wood
        blade.Color = OAK_COLOR
    end

    blade.CFrame = handle.CFrame * CFrame.new(0, (handle.Size.Y + blade.Size.Y) / 2, 0)
    blade.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = blade
    weld.Parent = blade

    -- Гарда из латуни
    local guard = Instance.new("Part")
    guard.Name = "Guard"
    guard.Size = Vector3.new(1.4, 0.25, 0.5)
    guard.Material = Enum.Material.Metal
    guard.Color = BRASS_COLOR
    guard.CanCollide = false
    guard.Massless = true
    guard.CFrame = handle.CFrame * CFrame.new(0, handle.Size.Y / 2, 0)
    guard.Parent = model

    local guardWeld = Instance.new("WeldConstraint")
    guardWeld.Part0 = handle
    guardWeld.Part1 = guard
    guardWeld.Parent = guard

    -- Добавляем спецэффект частиц для Mythic, Legendary, Secret, Absolute
    if rarity >= 4 then
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "AuraParticles"
        emitter.Rate = (rarity == 7 and 45) or (rarity == 6 and 35) or 20
        emitter.Lifetime = NumberRange.new(0.6, 1.2)
        emitter.Speed = NumberRange.new(0.5, 2.0)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 0),
        })

        if rarity == 7 then -- Absolute
            emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(240, 245, 255))
            emitter.LightEmission = 1
        elseif rarity == 6 then -- Secret
            emitter.Color = ColorSequence.new(Color3.fromRGB(130, 40, 200), Color3.fromRGB(20, 10, 30))
            emitter.LightEmission = 0.6
        elseif rarity == 5 then -- Legendary
            emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 50), Color3.fromRGB(255, 160, 20))
            emitter.LightEmission = 0.9
        elseif rarity == 4 then -- Mythic
            emitter.Color = ColorSequence.new(Color3.fromRGB(255, 60, 40), Color3.fromRGB(180, 20, 30))
            emitter.LightEmission = 0.8
        end

        emitter.Parent = blade

        local light = Instance.new("PointLight")
        light.Brightness = (rarity == 7 and 3.5) or 2.0
        light.Range = 10
        light.Color = blade.Color
        light.Parent = blade
    end

    return model
end

function ItemVisualFactory.CreateShieldModel(itemId: string, rarity: number): Model
    local model = Instance.new("Model")
    model.Name = "Shield_" .. itemId

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.3, 0.8, 0.3)
    handle.Transparency = 1
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = model
    model.PrimaryPart = handle

    -- Щитовая пластина (резное дерево с эмалью)
    local plate = Instance.new("Part")
    plate.Name = "Plate"
    plate.Size = Vector3.new(2.4, 3.2, 0.3)
    plate.CanCollide = false
    plate.Massless = true
    plate.Material = Enum.Material.Wood
    plate.Color = (rarity >= 5 and BRASS_COLOR) or Color3.fromRGB(24, 52, 105)
    plate.CFrame = handle.CFrame * CFrame.new(0.3, 0, 0)
    plate.Parent = model

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = plate
    weld.Parent = plate

    -- Латунная окантовка и золотая корона
    local crown = Instance.new("Part")
    crown.Name = "CrownBadge"
    crown.Size = Vector3.new(1.2, 1.2, 0.2)
    crown.Material = Enum.Material.Metal
    crown.Color = BRASS_COLOR
    crown.CanCollide = false
    crown.Massless = true
    crown.CFrame = plate.CFrame * CFrame.new(0, 0, 0.2)
    crown.Parent = model

    local crownWeld = Instance.new("WeldConstraint")
    crownWeld.Part0 = plate
    crownWeld.Part1 = crown
    crownWeld.Parent = crown

    return model
end

return ItemVisualFactory
