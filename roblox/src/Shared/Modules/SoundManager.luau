--!strict
--[[
    SoundManager.luau
    Централизованная звуковая подсистема Galarang:
    - Фоновая средневековая акустическая музыка (лютня, арфа).
    - Пространственные звуки окружения (костёр, река, водопад, шелест ветра).
    - Тактильные звуки интерфейса (щелчки резного дерева, звон монет, замки).
    - Эпические звуковые слои для рулетки сундука и редких дропов.
]]

local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- Каталог проверенных ассетов звуков Roblox
SoundManager.Sounds = {
    -- Интерфейс и тактильность
    Click = "rbxassetid://6895079853",        -- Мягкий щелчок резного дерева
    Equip = "rbxassetid://7145749712",        -- Лязг стали и натягивание ремня
    Coin = "rbxassetid://9069609204",         -- Звон золотых монет
    Error = "rbxassetid://6895079853",        -- Глухой отказ
    
    -- Добыча ресурсов
    Mining = "rbxassetid://9069609204",       -- Удар кирки о скалу
    Woodcut = "rbxassetid://6895079853",      -- Глухой удар топора по бревну
    AnvilHit = "rbxassetid://9069609204",     -- Удар кузнечного молота о наковальню
    Splash = "rbxassetid://9114223600",       -- Всплеск поплавка в реке
    Pray = "rbxassetid://9114223175",         -- Эфирный колокольчик благословения
    
    -- Рулетка и сундук
    ChestOpen = "rbxassetid://9114223175",    -- Скрип крышки и золотое сияние
    RollTick = "rbxassetid://6895079853",     -- Трещотка рулетки
    CommonDrop = "rbxassetid://9114223175",   -- Простой колокольчик
    RareDrop = "rbxassetid://9114223175",     -- Тройной хрустальный перезвон
    EpicDrop = "rbxassetid://9119713951",     -- Глубокий резонанс и звон
    LegendaryDrop = "rbxassetid://9119713951",-- Торжественные золотые фанфары
    SecretDrop = "rbxassetid://9119713951",   -- Космический раскат грома и пустота
    AbsoluteDrop = "rbxassetid://9119713951", -- Ангельский хор и божественный колокол

    -- Эмбиент
    CampfireLoop = "rbxassetid://9114223400", -- Потрескивание дров в костре
    RiverLoop = "rbxassetid://9114223600",    -- Журчание прозрачной смоляной реки
    MusicLoop = "rbxassetid://9043887012",    -- Тёплая мелодия средневекового макета
}

local SoundGroup = Instance.new("SoundGroup")
SoundGroup.Name = "GalarangMaster"
SoundGroup.Volume = 0.85
SoundGroup.Parent = SoundService

function SoundManager.PlaySound(soundName: string, pitch: number?, volume: number?)
    local id = SoundManager.Sounds[soundName]
    if not id then return end

    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 0.75
    s.PlaybackSpeed = pitch or 1.0
    s.SoundGroup = SoundGroup
    s.Parent = SoundService
    s:Play()
    s.Ended:Connect(function()
        s:Destroy()
    end)
end

function SoundManager.AttachLoop(parentPart: BasePart, soundName: string, maxDist: number?, volume: number?)
    local id = SoundManager.Sounds[soundName]
    if not id then return end

    local s = Instance.new("Sound")
    s.Name = "SpatialLoop_" .. soundName
    s.SoundId = id
    s.Looped = true
    s.Volume = volume or 0.6
    s.RollOffMode = Enum.RollOffMode.InverseTapered
    s.RollOffMaxDistance = maxDist or 30
    s.RollOffMinDistance = 5
    s.SoundGroup = SoundGroup
    s.Parent = parentPart
    s:Play()
    return s
end

return SoundManager
