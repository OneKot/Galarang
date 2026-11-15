--!strict
--[[
    FusionService.luau
    Сервис «Сплава 5 в 1» по дизайн-документу style-rules.md (Раздел 4):
    «5 одинаковых предметов одной редкости сплавляются в предмет следующего тира!»
    - Сталь -> Золото -> Бело-голубой кристалл (Алмазный) -> Антиматерия -> Первосвет
    - Серверно-авторитетный: проверяет наличие 5 копий и баланс монет.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Items = require(Config:WaitForChild("Items") :: any)
local Rarities = require(Config:WaitForChild("Rarities") :: any)

local FusionService = {}

local PlayerData = nil
local BroadcastEvent: RemoteEvent? = nil

local FUSION_COSTS: { [number]: number } = {
    [0] = 50,     -- Обычный -> Необычный
    [1] = 200,    -- Необычный -> Редкий
    [2] = 600,    -- Редкий -> Эпический
    [3] = 1800,   -- Эпический -> Мифический
    [4] = 5000,   -- Мифический -> Легендарный
    [5] = 25000,  -- Легендарный -> Секретный
    [6] = 100000, -- Секретный -> Абсолют
}

function FusionService.Init(remotesFolder: Folder, playerDataService: any, rollBroadcastEvent: RemoteEvent)
    PlayerData = playerDataService
    BroadcastEvent = rollBroadcastEvent

    local requestFusion = remotesFolder:FindFirstChild("RequestFusion") :: RemoteFunction
    if not requestFusion then
        requestFusion = Instance.new("RemoteFunction")
        requestFusion.Name = "RequestFusion"
        requestFusion.Parent = remotesFolder
    end

    requestFusion.OnServerInvoke = function(player: Player, itemId: string)
        return FusionService.ProcessFusion(player, itemId)
    end

    print("[FusionService] Сервис сплава 5 в 1 инициализирован!")
end

function FusionService.GetFusionCost(rarity: number): number
    return FUSION_COSTS[rarity] or 999999
end

function FusionService.ProcessFusion(player: Player, itemId: string)
    if not PlayerData then
        return { Success = false, Message = "Сервис недоступен" }
    end

    local profile = PlayerData.GetProfile(player)
    if not profile then
        return { Success = false, Message = "Профиль игрока не найден" }
    end

    local sourceItem = Items.GetItem(itemId)
    if not sourceItem then
        return { Success = false, Message = "Неизвестный предмет для сплава" }
    end

    if sourceItem.Rarity >= 7 then
        return { Success = false, Message = "Абсолют — высшая ступень бытия, дальнейший сплав невозможен!" }
    end

    -- Подсчитываем количество копий предмета в инвентаре
    local count = 0
    for _, item in ipairs(profile.Inventory) do
        if item.Id == itemId then
            count += 1
        end
    end

    if count < 5 then
        return {
            Success = false,
            Message = string.format("Недостаточно предметов: нужно 5 шт. (в наличии %d/5)", count),
            CurrentCount = count,
            RequiredCount = 5,
        }
    end

    local cost = FusionService.GetFusionCost(sourceItem.Rarity)
    if (profile.Coins or 0) < cost then
        return {
            Success = false,
            Message = string.format("Недостаточно монет: требуется %d (у вас %d)", cost, profile.Coins or 0),
            Cost = cost,
            CurrentCoins = profile.Coins or 0,
        }
    end

    -- Находим подходящий предмет следующего тира
    local nextTier = sourceItem.Rarity + 1
    local candidateItems = Items.GetItemsByRarity(nextTier)
    if #candidateItems == 0 then
        return { Success = false, Message = "Не найден следующий тир для сплава" }
    end

    -- Стараемся подобрать оружие под тип исходного предмета
    local targetItem = candidateItems[1]
    local sameTypeCandidates = {}
    for _, candidate in ipairs(candidateItems) do
        if candidate.Type == sourceItem.Type then
            table.insert(sameTypeCandidates, candidate)
        end
    end
    if #sameTypeCandidates > 0 then
        targetItem = sameTypeCandidates[math.random(1, #sameTypeCandidates)]
    else
        targetItem = candidateItems[math.random(1, #candidateItems)]
    end

    -- Списываем 5 копий и монеты
    local removeCoinsSuccess = PlayerData.RemoveCoins(player, cost)
    if not removeCoinsSuccess then
        return { Success = false, Message = "Ошибка списания монет" }
    end

    local removeItemsSuccess = PlayerData.RemoveItemCopies(player, itemId, 5)
    if not removeItemsSuccess then
        -- Возвращаем монеты в случае сбоя
        PlayerData.AddCoins(player, cost)
        return { Success = false, Message = "Ошибка удаления предметов из инвентаря" }
    end

    -- Выдаём новый улучшенный предмет
    PlayerData.AddItem(player, targetItem.Id, targetItem.Rarity)

    -- Если редкость Mythic+, оповещаем весь сервер
    if targetItem.Rarity >= 4 and BroadcastEvent then
        local rInfo = Rarities.Rarities[targetItem.Rarity]
        BroadcastEvent:FireAllClients({
            PlayerName = player.DisplayName or player.Name,
            ItemName = targetItem.NameRu,
            RarityName = rInfo and rInfo.DisplayNameRu or "Редкий",
            OneInN = targetItem.OneInN,
            Color = rInfo and rInfo.Color or "#FFFFFF",
            IsFusion = true,
        })
    end

    return {
        Success = true,
        Message = string.format("Сплав успешно завершён! Выкован [%s]!", targetItem.NameRu),
        NewItem = targetItem,
        Cost = cost,
        Rarity = targetItem.Rarity,
    }
end

return FusionService