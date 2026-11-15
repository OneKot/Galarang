--!strict
--[[
    EquipService.luau
    Серверная служба экипировки предметов.
    Привязывает оружие и щиты к рукам персонажа и сохраняет выбор в профиле игрока.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Modules = Shared:WaitForChild("Modules")

local Items = require(Config:WaitForChild("Items") :: any)
local ItemVisualFactory = require(Modules:WaitForChild("ItemVisualFactory") :: any)
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService") :: any)

local EquipService = {}

function EquipService.Init(remotesFolder: Folder)
    local equipFunc = remotesFolder:FindFirstChild("EquipItem") :: RemoteFunction
    if not equipFunc then
        equipFunc = Instance.new("RemoteFunction")
        equipFunc.Name = "EquipItem"
        equipFunc.Parent = remotesFolder
    end

    equipFunc.OnServerInvoke = function(player: Player, itemId: string): any
        return EquipService.Equip(player, itemId)
    end

    -- При появлении персонажа восстанавливаем надетую экипировку
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(0.3)
            EquipService.RestoreEquipped(player, character)
        end)
    end)
end

function EquipService.RestoreEquipped(player: Player, character: Model)
    local profile = PlayerDataService.GetProfile(player)
    if not profile then return end

    if profile.Equipped.Weapon then
        EquipService.AttachVisual(character, profile.Equipped.Weapon, "Weapon")
    end
    if profile.Equipped.Shield then
        EquipService.AttachVisual(character, profile.Equipped.Shield, "Shield")
    end
end

function EquipService.Equip(player: Player, itemId: string): any
    local profile = PlayerDataService.GetProfile(player)
    if not profile then
        return { Success = false, Message = "Профиль не найден" }
    end

    local itemDef = Items.Items[itemId]
    if not itemDef then
        return { Success = false, Message = "Предмет не существует" }
    end

    -- Проверяем, есть ли предмет у игрока в инвентаре / индексе
    if not profile.UnlockedIndex[itemId] then
        return { Success = false, Message = "Этот предмет ещё не открыт" }
    end

    local slot = (itemDef.Type == "Shield" and "Shield") or "Weapon"
    profile.Equipped[slot] = itemId

    if player.Character then
        EquipService.AttachVisual(player.Character, itemId, slot)
    end

    return {
        Success = true,
        Slot = slot,
        ItemId = itemId,
    }
end

function EquipService.AttachVisual(character: Model, itemId: string, slot: string)
    local itemDef = Items.Items[itemId]
    if not itemDef then return end

    -- Удаляем старое оружие/щит из этого слота
    local oldVisual = character:FindFirstChild("Visual_" .. slot)
    if oldVisual then oldVisual:Destroy() end

    if slot == "Weapon" then
        local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
        if not rightHand or not rightHand:IsA("BasePart") then return end

        local model = ItemVisualFactory.CreateWeaponModel(itemId, itemDef.Rarity)
        model.Name = "Visual_Weapon"
        local targetCFrame = rightHand.CFrame * CFrame.new(0, -0.6, -0.4) * CFrame.Angles(math.rad(-90), 0, 0)
        model:PivotTo(targetCFrame)
        model.Parent = character

        local primary = model.PrimaryPart
        if primary then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = rightHand
            weld.Part1 = primary
            weld.Parent = primary
        end

    elseif slot == "Shield" then
        local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
        if not leftHand or not leftHand:IsA("BasePart") then return end

        local model = ItemVisualFactory.CreateShieldModel(itemId, itemDef.Rarity)
        model.Name = "Visual_Shield"
        local targetCFrame = leftHand.CFrame * CFrame.new(-0.4, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
        model:PivotTo(targetCFrame)
        model.Parent = character

        local primary = model.PrimaryPart
        if primary then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = leftHand
            weld.Part1 = primary
            weld.Parent = primary
        end
    end
end

return EquipService
