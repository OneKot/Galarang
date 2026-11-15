--!strict
--[[
    ServerMain.server.luau
    Главная входная точка сервера Galarang.
    Создает инфраструктуру Remote-объектов и инициализирует все сервисы.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[Galarang Server] Запуск серверного ядра...")

-- Создаем контейнер для сетевых событий
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local function ensureRemoteFunction(name: string): RemoteFunction
    local remote = remotesFolder:FindFirstChild(name) :: RemoteFunction
    if not remote then
        remote = Instance.new("RemoteFunction")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote
end

local function ensureRemoteEvent(name: string): RemoteEvent
    local remote = remotesFolder:FindFirstChild(name) :: RemoteEvent
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    return remote
end

-- Регистрируем ремоуты
ensureRemoteFunction("RequestRoll")
ensureRemoteFunction("GetProfile")
ensureRemoteFunction("EquipItem")
ensureRemoteFunction("RequestFusion")
ensureRemoteEvent("RollBroadcast")

-- Инициализируем сервисы
local Services = script.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService") :: any)
local RollService = require(Services:WaitForChild("RollService") :: any)
local EquipService = require(Services:WaitForChild("EquipService") :: any)
local WorldBuilderService = require(Services:WaitForChild("WorldBuilderService") :: any)
local CharacterMorphService = require(Services:WaitForChild("CharacterMorphService") :: any)
local FusionService = require(Services:WaitForChild("FusionService") :: any)

PlayerDataService.Init()
RollService.Init(remotesFolder)
EquipService.Init(remotesFolder)
CharacterMorphService.Init()
WorldBuilderService.Init(RollService, remotesFolder:WaitForChild("RollBroadcast") :: RemoteEvent, PlayerDataService)
FusionService.Init(remotesFolder, PlayerDataService, remotesFolder:WaitForChild("RollBroadcast") :: RemoteEvent)

-- Обработчик запроса профиля клиентом
local getProfileFunc = remotesFolder:WaitForChild("GetProfile") :: RemoteFunction
getProfileFunc.OnServerInvoke = function(player: Player)
    return PlayerDataService.GetProfile(player)
end

print("[Galarang Server] Ядро успешно запущено! Сервер готов к приёму игроков.")
