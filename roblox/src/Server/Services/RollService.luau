--!strict
--[[
    RollService.luau
    Серверная авторитарная служба бросков (роллов) рулетки сундука.
    Полная защита от читов: генерация случайных чисел происходит строго на сервере.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Modules = Shared:WaitForChild("Modules")

local Items = require(Config:WaitForChild("Items") :: any)
local Rarities = require(Config:WaitForChild("Rarities") :: any)
local ChestOddsTable = require(Modules:WaitForChild("ChestOddsTable") :: any)

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService") :: any)

local RollService = {}
local TableInstance = nil
local PlayerCooldowns: { [Player]: number } = {}
local ROLL_COOLDOWN = 1.0 -- Минимальный интервал между бросками (сек)

function RollService.Init(remotesFolder: Folder)
    -- Инициализируем таблицу шансов из списка предметов первого сектора
    TableInstance = ChestOddsTable.fromItems(Items.ItemsList)

    local requestRollFunc = remotesFolder:WaitForChild("RequestRoll") :: RemoteFunction
    local broadcastEvent = remotesFolder:WaitForChild("RollBroadcast") :: RemoteEvent

    requestRollFunc.OnServerInvoke = function(player: Player, isGolden: boolean?): any
        return RollService.ExecuteRoll(player, isGolden, broadcastEvent)
    end
end

function RollService.ExecuteRoll(player: Player, isGolden: boolean?, broadcastEvent: RemoteEvent): any
    local now = os.clock()
    local lastRoll = PlayerCooldowns[player] or 0

    if now - lastRoll < ROLL_COOLDOWN then
        return {
            Success = false,
            Error = "TooFast",
            Message = "Слишком часто! Подождите секунду.",
        }
    end
    PlayerCooldowns[player] = now

    local profile = PlayerDataService.GetProfile(player)
    if not profile then
        return {
            Success = false,
            Error = "ProfileNotLoaded",
            Message = "Данные игрока загружаются...",
        }
    end

    local luck = profile.LuckMultiplier or 1.0
    local golden = isGolden == true

    -- Бросок на сервере
    local rollResult = TableInstance:Roll(nil, luck, golden)
    local itemDef = Items.Items[rollResult.Id]
    if not itemDef then
        error("Предмет не найден в каталоге: " .. tostring(rollResult.Id))
    end

    -- Запись в профиль
    PlayerDataService.AddRollResult(player, itemDef.Id, itemDef.Rarity)

    -- Если редкость высокая (Mythic, Legendary, Secret, Absolute) — объявляем на весь сервер!
    local rarityInfo = Rarities.Rarities[itemDef.Rarity]
    if rarityInfo and rarityInfo.AnnouncementTier then
        broadcastEvent:FireAllClients({
            PlayerName = player.DisplayName,
            ItemName = itemDef.NameRu,
            RarityId = itemDef.Rarity,
            RarityName = rarityInfo.DisplayNameRu,
            Color = rarityInfo.Color,
            OneInN = itemDef.OneInN,
        })
    end

    return {
        Success = true,
        ItemId = itemDef.Id,
        NameRu = itemDef.NameRu,
        Rarity = itemDef.Rarity,
        OneInN = itemDef.OneInN,
        Description = itemDef.Description,
        Type = itemDef.Type,
        TotalRolls = profile.TotalRolls,
    }
end

return RollService
