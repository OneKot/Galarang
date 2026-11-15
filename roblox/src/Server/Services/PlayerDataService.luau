--!strict
--[[
    PlayerDataService.luau
    Управление профилями игроков, инвентарем и сохранением данных.
    Работает с DataStoreService с защитой от сбоев (pcall + сессионный кэш).
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DATA_VERSION = "v1.0"
local DATA_STORE_NAME = "GalarangPlayerData_" .. DATA_VERSION

export type PlayerProfile = {
    TotalRolls: number,
    Inventory: { [number]: { Id: string, Rarity: number, Timestamp: number } },
    Equipped: {
        Weapon: string?,
        Armor: string?,
        Shield: string?,
        Relic: string?,
    },
    Coins: number,
    UnlockedIndex: { [string]: boolean },
    LuckMultiplier: number,
}

local PlayerDataService = {}
local Profiles: { [Player]: PlayerProfile } = {}
local PlayerDataStore = nil

-- Инициализация DataStore только в реальной игре (в студии с выключенным API не блокирует работу)
pcall(function()
    PlayerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
end)

local function createDefaultProfile(): PlayerProfile
    return {
        TotalRolls = 0,
        Inventory = {},
        Equipped = {
            Weapon = "wooden_dagger",
            Armor = nil,
            Shield = nil,
            Relic = nil,
        },
        Coins = 0,
        UnlockedIndex = {
            ["wooden_dagger"] = true,
        },
        LuckMultiplier = 1.0,
    }
end

function PlayerDataService.Init()
    Players.PlayerAdded:Connect(PlayerDataService.OnPlayerAdded)
    Players.PlayerRemoving:Connect(PlayerDataService.OnPlayerRemoving)

    -- Автосохранение при закрытии сервера
    game:BindToClose(function()
        for player, _ in pairs(Profiles) do
            PlayerDataService.SavePlayer(player)
        end
    end)
end

function PlayerDataService.OnPlayerAdded(player: Player)
    local profile: PlayerProfile = createDefaultProfile()

    if PlayerDataStore and not RunService:IsStudio() then
        local key = "player_" .. player.UserId
        local success, data = pcall(function()
            return PlayerDataStore:GetAsync(key)
        end)

        if success and data then
            for k, v in pairs(data) do
                (profile :: any)[k] = v
            end
        end
    end

    Profiles[player] = profile
end

function PlayerDataService.OnPlayerRemoving(player: Player)
    PlayerDataService.SavePlayer(player)
    Profiles[player] = nil
end

function PlayerDataService.SavePlayer(player: Player)
    local profile = Profiles[player]
    if not profile or not PlayerDataStore or RunService:IsStudio() then
        return
    end

    local key = "player_" .. player.UserId
    pcall(function()
        PlayerDataStore:SetAsync(key, profile)
    end)
end

function PlayerDataService.GetProfile(player: Player): PlayerProfile?
    return Profiles[player]
end

function PlayerDataService.AddRollResult(player: Player, itemId: string, rarity: number)
    local profile = Profiles[player]
    if not profile then
        return
    end

    profile.TotalRolls += 1
    profile.UnlockedIndex[itemId] = true

    table.insert(profile.Inventory, {
        Id = itemId,
        Rarity = rarity,
        Timestamp = os.time(),
    })
end

function PlayerDataService.AddItem(player: Player, itemId: string, rarity: number)
    local profile = Profiles[player]
    if not profile then return end

    profile.UnlockedIndex[itemId] = true
    table.insert(profile.Inventory, {
        Id = itemId,
        Rarity = rarity,
        Timestamp = os.time(),
    })
end

function PlayerDataService.AddCoins(player: Player, amount: number)
    local profile = Profiles[player]
    if not profile then return end
    profile.Coins = (profile.Coins or 0) + math.max(0, amount)
end

function PlayerDataService.RemoveCoins(player: Player, amount: number): boolean
    local profile = Profiles[player]
    if not profile then return false end
    if (profile.Coins or 0) >= amount then
        profile.Coins -= amount
        return true
    end
    return false
end

function PlayerDataService.RemoveItemCopies(player: Player, itemId: string, count: number): boolean
    local profile = Profiles[player]
    if not profile then return false end

    local indicesToRemove = {}
    for i, item in ipairs(profile.Inventory) do
        if item.Id == itemId then
            table.insert(indicesToRemove, i)
            if #indicesToRemove == count then
                break
            end
        end
    end

    if #indicesToRemove < count then
        return false
    end

    -- Удаляем с конца, чтобы не сбить индексы
    for i = #indicesToRemove, 1, -1 do
        table.remove(profile.Inventory, indicesToRemove[i])
    end

    return true
end

return PlayerDataService
