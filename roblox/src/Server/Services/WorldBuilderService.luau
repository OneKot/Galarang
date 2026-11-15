--!strict
--[[
    WorldBuilderService.luau
    Полное процедурное воссоздание локации «Лагерь в Зелёной долине» (Green Safezone Camp)
    в строгом соответствии с design/refs/locations/loc-green-safezone-camp.png и batch-01:
    
    1. Ландшафт-диорама:
       - Массивный трёхъярусный постамент из тёмного резного ореха с латунной окантовкой.
       - Рельефный зелёный мох, перепады высот, скальные утёсы на заднем плане.
       - Река из прозрачной смолы (Resin River) с водопадом и деревянным арочным мостиком.
       - Далёкий сказочный замок на скале (фон диорамы).
    
    2. Объекты лагеря (Сейф-зона):
       - Центральный королевский сундук на каменном постаменте со ступенями и факелами.
       - Деревянный частокол (палисад) из заостренных бревен с королевскими синими баннерами.
       - Кузница под открытым небом: каменный очаг с тлеющими углями, наковальня на пне, молот.
       - Торговая лавка алхимика: деревянный прилавок, полосатый тент, полки с зельями.
       - Кострище с кругом из камней и деревянными резными табуретами.
       - Сторожевая деревянная башня с флагом.
    
    3. Интерактивные ресурсные узлы:
       - Золотая жила в скале (добыча руды и монет).
       - Пень с топором и поленница (рубка дров).
       - Рыбацкий пирс с удочкой над рекой (рыбалка).
       - Алтарь четырёхлистного клевера (бафф удачи x2).
       - Резная доска рекордов диорамы.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("SoundManager") :: any)

local WorldBuilderService = {}

-- Цветовая палитра стиля «Резные фигурки»
local C_DARK_WOOD = Color3.fromRGB(48, 32, 22)
local C_MEDIUM_WOOD = Color3.fromRGB(78, 52, 34)
local C_LIGHT_WOOD = Color3.fromRGB(135, 95, 62)
local C_BRASS = Color3.fromRGB(218, 175, 55)
local C_ROYAL_BLUE = Color3.fromRGB(20, 48, 105)
local C_MOSS_DEEP = Color3.fromRGB(52, 98, 40)
local C_MOSS_BRIGHT = Color3.fromRGB(68, 125, 48)
local C_STONE = Color3.fromRGB(115, 110, 105)
local C_RIVER_WATER = Color3.fromRGB(60, 145, 170)

function WorldBuilderService.Init(rollService: any, broadcastEvent: RemoteEvent, playerDataService: any)
    print("[WorldBuilder] Начинаем постройку полноценного мира-диорамы...")

    -- Очищаем старые модели диорамы если они были
    local oldIsland = Workspace:FindFirstChild("DioramaWorld")
    if oldIsland then oldIsland:Destroy() end

    local world = Instance.new("Model")
    world.Name = "DioramaWorld"
    world.Parent = Workspace

    -- 1. Создаем постамент и ландшафт
    WorldBuilderService.BuildPedestalAndTerrain(world)
    
    -- 2. Река, водопад и арочный мост
    WorldBuilderService.BuildRiverAndBridge(world)

    -- 3. Центральный королевский сундук со ступенями
    WorldBuilderService.BuildRoyalChestDais(world, rollService, broadcastEvent)

    -- 4. Палисадные стены, сторожевая башня и ворота
    WorldBuilderService.BuildPalisadeAndTower(world)

    -- 5. Лагерь: кузница, лавка алхимика, кострище
    WorldBuilderService.BuildCampFacilities(world, playerDataService)

    -- 6. Ресурсные узлы (золотая скала, пень с топором, пирс)
    WorldBuilderService.BuildResourceNodes(world, playerDataService)

    -- 7. Резные деревья и растительность по периметру
    WorldBuilderService.BuildVegetation(world)

    -- 8. Силуэт замка на скале вдалеке
    WorldBuilderService.BuildDistantCastle(world)

    -- 9. Настройка кинематографичного макро-освещения
    WorldBuilderService.SetupLighting()

    print("[WorldBuilder] Полноценный мир-диорама «Зелёная долина» успешно построен!")
end

-- ========================================================
-- 1. ПОСТАМЕНТ И ЛАНДШАФТ
-- ========================================================
function WorldBuilderService.BuildPedestalAndTerrain(world: Model)
    local terrainFolder = Instance.new("Folder")
    terrainFolder.Name = "TerrainAndPedestal"
    terrainFolder.Parent = world

    -- Ярус 1: Нижняя плита стола (Тёмный полированный орех)
    local base1 = Instance.new("Part")
    base1.Name = "PedestalTier1"
    base1.Size = Vector3.new(160, 8, 160)
    base1.Position = Vector3.new(0, -6, 0)
    base1.Anchored = true
    base1.Material = Enum.Material.WoodPlanks
    base1.Color = C_DARK_WOOD
    base1.Parent = terrainFolder

    -- Ярус 2: Средняя резная плита с выступами
    local base2 = Instance.new("Part")
    base2.Name = "PedestalTier2"
    base2.Size = Vector3.new(154, 4, 154)
    base2.Position = Vector3.new(0, -2, 0)
    base2.Anchored = true
    base2.Material = Enum.Material.Wood
    base2.Color = C_MEDIUM_WOOD
    base2.Parent = terrainFolder

    -- Латунный широкий оклад по периметру
    local brassTrim = Instance.new("Part")
    brassTrim.Name = "BrassFrame"
    brassTrim.Size = Vector3.new(156, 1.4, 156)
    brassTrim.Position = Vector3.new(0, 0, 0)
    brassTrim.Anchored = true
    brassTrim.Material = Enum.Material.Metal
    brassTrim.Color = C_BRASS
    brassTrim.Parent = terrainFolder

    -- Основной массив мха (Верхнее плато)
    local mossGround = Instance.new("Part")
    mossGround.Name = "MainMossPlateau"
    mossGround.Size = Vector3.new(148, 4, 148)
    mossGround.Position = Vector3.new(0, 2, 0)
    mossGround.Anchored = true
    mossGround.Material = Enum.Material.Grass
    mossGround.Color = C_MOSS_DEEP
    mossGround.Parent = terrainFolder

    -- Холмистые возвышенности на востоке и западе
    local hillLeft = Instance.new("Part")
    hillLeft.Name = "WestRidge"
    hillLeft.Size = Vector3.new(36, 6, 80)
    hillLeft.Position = Vector3.new(-54, 5, 10)
    hillLeft.Anchored = true
    hillLeft.Material = Enum.Material.Grass
    hillLeft.Color = C_MOSS_BRIGHT
    hillLeft.Parent = terrainFolder

    local hillRight = Instance.new("Part")
    hillRight.Name = "EastRidge"
    hillRight.Size = Vector3.new(34, 7, 70)
    hillRight.Position = Vector3.new(54, 5.5, -15)
    hillRight.Anchored = true
    hillRight.Material = Enum.Material.Grass
    hillRight.Color = C_MOSS_BRIGHT
    hillRight.Parent = terrainFolder

    -- Северная скалистая стена (утёс)
    local northCliff = Instance.new("Part")
    northCliff.Name = "NorthCliffWall"
    northCliff.Size = Vector3.new(140, 16, 28)
    northCliff.Position = Vector3.new(0, 10, -60)
    northCliff.Anchored = true
    northCliff.Material = Enum.Material.Slate
    northCliff.Color = C_STONE
    northCliff.Parent = terrainFolder

    -- Спавн игроков (Невидимый спавн на пышной траве поляны)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "DioramaSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.Position = Vector3.new(0, 4.4, 25)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Duration = 0
    spawn.Transparency = 1 -- Скрываем спавн-пад, игрок стоит на живой траве
    spawn.Parent = terrainFolder

    -- Круглая декоративная руническая плита под ногами спавна
    local spawnRing = Instance.new("Part")
    spawnRing.Name = "SpawnRunePad"
    spawnRing.Shape = Enum.PartType.Cylinder
    spawnRing.Size = Vector3.new(0.3, 10, 10)
    spawnRing.Position = Vector3.new(0, 4.25, 25)
    spawnRing.Orientation = Vector3.new(0, 0, 90)
    spawnRing.Anchored = true
    spawnRing.Material = Enum.Material.Slate
    spawnRing.Color = Color3.fromRGB(75, 72, 68)
    spawnRing.Parent = terrainFolder

    -- Невидимые физические барьеры по 4 краям диорамы (игрок не может упасть со стола)
    local barrierConfigs = {
        { Size = Vector3.new(160, 50, 4), Position = Vector3.new(0, 25, -74) }, -- Север
        { Size = Vector3.new(160, 50, 4), Position = Vector3.new(0, 25, 74) },  -- Юг
        { Size = Vector3.new(4, 50, 160), Position = Vector3.new(-74, 25, 0) }, -- Запад
        { Size = Vector3.new(4, 50, 160), Position = Vector3.new(74, 25, 0) },  -- Восток
    }
    for i, cfg in ipairs(barrierConfigs) do
        local barrier = Instance.new("Part")
        barrier.Name = "SafetyWall_" .. i
        barrier.Size = cfg.Size
        barrier.Position = cfg.Position
        barrier.Anchored = true
        barrier.CanCollide = true
        barrier.Transparency = 1
        barrier.Parent = terrainFolder
    end

    -- Нижняя страховочная сетка с авто-телепортом на спавн
    local safetyCatcher = Instance.new("Part")
    safetyCatcher.Name = "SafetyVoidCatcher"
    safetyCatcher.Size = Vector3.new(400, 4, 400)
    safetyCatcher.Position = Vector3.new(0, -15, 0)
    safetyCatcher.Anchored = true
    safetyCatcher.CanCollide = true
    safetyCatcher.Transparency = 1
    safetyCatcher.Parent = terrainFolder

    safetyCatcher.Touched:Connect(function(hit)
        local character = hit.Parent
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
            hrp.CFrame = CFrame.new(0, 8, 25)
        end
    end)

    -- Земляная извилистая тропа от спавна через лагерь к сундуку
    for z = 24, 7, -2.5 do
        local stone = Instance.new("Part")
        stone.Name = "PathSlab"
        stone.Size = Vector3.new(math.random(5, 7), 0.3, 2.4)
        stone.Position = Vector3.new(math.random(-1, 1) * 0.8, 4.2, z)
        stone.Anchored = true
        stone.Material = Enum.Material.Ground
        stone.Color = Color3.fromRGB(115, 88, 62)
        stone.Parent = terrainFolder
    end
end

-- ========================================================
-- 2. РЕКА ИЗ СМОЛЫ, ВОДОПАД И АРОЧНЫЙ МОСТ
-- ========================================================
function WorldBuilderService.BuildRiverAndBridge(world: Model)
    local riverFolder = Instance.new("Folder")
    riverFolder.Name = "ResinRiver"
    riverFolder.Parent = world

    -- Русло реки (извилистая голубая смола с прозрачностью и блеском)
    local river1 = Instance.new("Part")
    river1.Name = "RiverSegment1"
    river1.Size = Vector3.new(14, 2, 90)
    river1.Position = Vector3.new(-24, 3.2, 0)
    river1.Orientation = Vector3.new(0, 12, 0)
    river1.Anchored = true
    river1.Material = Enum.Material.Glass
    river1.Color = C_RIVER_WATER
    river1.Transparency = 0.35
    river1.Parent = riverFolder
    SoundManager.AttachLoop(river1, "RiverLoop", 40, 0.45)

    -- Маленький водопад, стекающий с северной скалы
    local waterfall = Instance.new("Part")
    waterfall.Name = "WaterfallResin"
    waterfall.Size = Vector3.new(10, 12, 2.5)
    waterfall.Position = Vector3.new(-26, 10, -48)
    waterfall.Anchored = true
    waterfall.Material = Enum.Material.Glass
    waterfall.Color = Color3.fromRGB(180, 230, 250)
    waterfall.Transparency = 0.4
    waterfall.Parent = riverFolder
    SoundManager.AttachLoop(waterfall, "RiverLoop", 35, 0.65)

    -- Брызги и белая пена водопада
    local foam = Instance.new("ParticleEmitter")
    foam.Color = ColorSequence.new(Color3.fromRGB(240, 250, 255))
    foam.Size = NumberSequence.new(0.5, 1.2)
    foam.Rate = 25
    foam.Speed = NumberRange.new(1, 3)
    foam.Lifetime = NumberRange.new(0.4, 0.8)
    foam.Parent = waterfall

    -- Деревянный арочный мостик через реку
    local bridge = Instance.new("Model")
    bridge.Name = "ArchedWoodenBridge"
    bridge.Parent = riverFolder

    local bridgeDeck = Instance.new("Part")
    bridgeDeck.Name = "Deck"
    bridgeDeck.Size = Vector3.new(18, 0.8, 7)
    bridgeDeck.Position = Vector3.new(-24, 5.2, 8)
    bridgeDeck.Anchored = true
    bridgeDeck.Material = Enum.Material.WoodPlanks
    bridgeDeck.Color = C_MEDIUM_WOOD
    bridgeDeck.Parent = bridge

    -- Перила мостика с двух сторон
    for _, zOff in ipairs({ -3.2, 3.2 }) do
        local railing = Instance.new("Part")
        railing.Size = Vector3.new(18, 1.8, 0.4)
        railing.Position = bridgeDeck.Position + Vector3.new(0, 1.2, zOff)
        railing.Anchored = true
        railing.Material = Enum.Material.Wood
        railing.Color = C_DARK_WOOD
        railing.Parent = bridge
    end
end

-- ========================================================
-- 3. ЦЕНТРАЛЬНЫЙ СУНДУК СО СТУПЕНЯМИ И ФАКЕЛАМИ
-- ========================================================
function WorldBuilderService.BuildRoyalChestDais(world: Model, rollService: any, broadcastEvent: RemoteEvent)
    local dais = Instance.new("Model")
    dais.Name = "RoyalChestDais"
    dais.Parent = world

    -- Каменное круглое возвышение (пьедестал) со ступенями
    local baseStep = Instance.new("Part")
    baseStep.Name = "DaisStep1"
    baseStep.Size = Vector3.new(16, 1.2, 16)
    baseStep.Position = Vector3.new(0, 4.6, 0)
    baseStep.Anchored = true
    baseStep.Material = Enum.Material.Slate
    baseStep.Color = Color3.fromRGB(65, 62, 60)
    baseStep.Parent = dais

    -- Латунная окантовка ступени пьедестала
    local step1Trim = Instance.new("Part")
    step1Trim.Name = "Step1Trim"
    step1Trim.Size = Vector3.new(16.4, 0.3, 16.4)
    step1Trim.Position = Vector3.new(0, 5.1, 0)
    step1Trim.Anchored = true
    step1Trim.Material = Enum.Material.Metal
    step1Trim.Color = C_BRASS
    step1Trim.Parent = dais

    local topStep = Instance.new("Part")
    topStep.Name = "DaisStep2"
    topStep.Size = Vector3.new(12, 1.2, 12)
    topStep.Position = Vector3.new(0, 5.8, 0)
    topStep.Anchored = true
    topStep.Material = Enum.Material.Slate
    topStep.Color = Color3.fromRGB(80, 76, 72)
    topStep.Parent = dais

    -- 4 Каменных столбика с чашами вечного огня по углам
    local torchOffsets = {
        Vector3.new(-5.6, 0, -5.6),
        Vector3.new(5.6, 0, -5.6),
        Vector3.new(-5.6, 0, 5.6),
        Vector3.new(5.6, 0, 5.6),
    }

    for _, off in ipairs(torchOffsets) do
        local pillar = Instance.new("Part")
        pillar.Size = Vector3.new(1.2, 3.5, 1.2)
        pillar.Position = topStep.Position + off + Vector3.new(0, 2.2, 0)
        pillar.Anchored = true
        pillar.Material = Enum.Material.Slate
        pillar.Color = Color3.fromRGB(70, 68, 65)
        pillar.Parent = dais

        local brazier = Instance.new("Part")
        brazier.Size = Vector3.new(1.8, 1, 1.8)
        brazier.Position = pillar.Position + Vector3.new(0, 2, 0)
        brazier.Anchored = true
        brazier.Material = Enum.Material.Metal
        brazier.Color = Color3.fromRGB(45, 42, 40)
        brazier.Parent = dais

        local fireLight = Instance.new("PointLight")
        fireLight.Color = Color3.fromRGB(255, 175, 75)
        fireLight.Brightness = 1.8
        fireLight.Range = 14
        fireLight.Parent = brazier

        -- Реалистичные тлеющие угли вместо кислотного неонового куба
        local fireEmbers = Instance.new("Part")
        fireEmbers.Size = Vector3.new(1.2, 0.4, 1.2)
        fireEmbers.Position = brazier.Position + Vector3.new(0, 0.5, 0)
        fireEmbers.Anchored = true
        fireEmbers.Material = Enum.Material.Slate
        fireEmbers.Color = Color3.fromRGB(60, 35, 25)
        fireEmbers.Parent = dais

        local fireParticles = Instance.new("ParticleEmitter")
        fireParticles.Color = ColorSequence.new(Color3.fromRGB(255, 160, 40), Color3.fromRGB(255, 80, 20))
        fireParticles.Size = NumberSequence.new(0.3, 0.8)
        fireParticles.Rate = 6
        fireParticles.Speed = NumberRange.new(1, 2)
        fireParticles.Lifetime = NumberRange.new(0.5, 1.0)
        fireParticles.Parent = fireEmbers
    end

    -- ================= СУНДУК =================
    local chestModel = Instance.new("Model")
    chestModel.Name = "AncientRoyalChest"
    chestModel.Parent = dais

    -- 3D МОДЕЛЬ КОРОЛЕВСКОГО СУНДУКА (Hero 3D Asset: royal_treasure_chest)
    local chestBase = Instance.new("Part")
    chestBase.Name = "ChestBase"
    chestBase.Size = Vector3.new(6.7, 4.8, 4.4)
    chestBase.Position = Vector3.new(0, 8.8, 0)
    chestBase.Anchored = true
    chestBase.CanCollide = true
    chestBase.Material = Enum.Material.SmoothPlastic
    chestBase.Color = Color3.fromRGB(255, 255, 255)
    chestBase.Parent = chestModel

    local chestMesh = Instance.new("SpecialMesh")
    chestMesh.Name = "RoyalChest3DMesh"
    chestMesh.MeshType = Enum.MeshType.FileMesh
    chestMesh.MeshId = "rbxasset://models/galarang/royal_treasure_chest.mesh"
    chestMesh.TextureId = "rbxasset://textures/galarang/royal_chest_atlas.png"
    chestMesh.Scale = Vector3.new(3.8, 3.8, 3.8)
    chestMesh.Offset = Vector3.new(0, -2.4, 0)
    chestMesh.Parent = chestBase

    -- Мягкое внутреннее золотое свечение и волшебная пыльца
    local chestLight = Instance.new("PointLight")
    chestLight.Name = "InteriorChestLight"
    chestLight.Color = Color3.fromRGB(255, 210, 90)
    chestLight.Brightness = 1.8
    chestLight.Range = 14
    chestLight.Parent = chestBase

    local auraEmitter = Instance.new("ParticleEmitter")
    auraEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 225, 120), Color3.fromRGB(255, 180, 50))
    auraEmitter.Size = NumberSequence.new(0.2, 0.5)
    auraEmitter.Rate = 12
    auraEmitter.Speed = NumberRange.new(1.5, 3.0)
    auraEmitter.Lifetime = NumberRange.new(0.8, 1.5)
    auraEmitter.LightEmission = 0.6
    auraEmitter.Parent = chestBase

    -- Вертикальный столб добычи (Beam / Loot Beam по референсу ui-chest-loot-beams.png)
    local beamAttTop = Instance.new("Attachment")
    beamAttTop.Name = "BeamTop"
    beamAttTop.Position = Vector3.new(0, 24, 0)
    beamAttTop.Parent = chestBase

    local beamAttBottom = Instance.new("Attachment")
    beamAttBottom.Name = "BeamBottom"
    beamAttBottom.Position = Vector3.new(0, 1.2, 0)
    beamAttBottom.Parent = chestBase

    local lootBeam = Instance.new("Beam")
    lootBeam.Name = "LootBeam"
    lootBeam.Attachment0 = beamAttBottom
    lootBeam.Attachment1 = beamAttTop
    lootBeam.Width0 = 3.5
    lootBeam.Width1 = 5.5
    lootBeam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100))
    lootBeam.Transparency = NumberSequence.new(1) -- Включается при открытии
    lootBeam.LightEmission = 0.8
    lootBeam.FaceCamera = true
    lootBeam.Parent = chestBase
    chestLight.Brightness = 1.8
    chestLight.Range = 14
    chestLight.Parent = chestBase

    local auraEmitter = Instance.new("ParticleEmitter")
    auraEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 225, 120), Color3.fromRGB(255, 180, 50))
    auraEmitter.Size = NumberSequence.new(0.2, 0.5)
    auraEmitter.Rate = 12
    auraEmitter.Speed = NumberRange.new(1.5, 3.0)
    auraEmitter.Lifetime = NumberRange.new(0.8, 1.5)
    auraEmitter.LightEmission = 0.6
    auraEmitter.Parent = chestBase

    -- ProximityPrompt: «ОТКРЫТЬ СУНДУК [E]»
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ChestPrompt"
    prompt.ObjectText = "ДРЕВНИЙ СУНДУК КОРОЛЕЙ"
    prompt.ActionText = "Открыть сундук [E]"
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 11
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.RequiresLineOfSight = false
    prompt.Parent = chestBase

    local isOpening = false
    prompt.Triggered:Connect(function(player)
        if rollService and not isOpening then
            isOpening = true

            -- Плавная анимация откидывания крышки вверх и назад
            local origPos = Vector3.new(0, 10.8, 0)
            local openPos = Vector3.new(0, 12.6, -1.2)
            
            local openTween = TweenService:Create(chestLid, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = openPos
            })
            local ribbonOpen = TweenService:Create(blueRibbon, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = openPos
            })
            local crownOpen = TweenService:Create(lidCrown, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = openPos + Vector3.new(0, 0.3, 2.35)
            })

            local closeTween = TweenService:Create(chestLid, TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                Position = origPos
            })
            local ribbonClose = TweenService:Create(blueRibbon, TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                Position = origPos
            })
            local crownClose = TweenService:Create(lidCrown, TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
                Position = origPos + Vector3.new(0, 0.3, 2.35)
            })

            SoundManager.PlaySound("ChestOpen", 1.0, 0.9)
            openTween:Play()
            ribbonOpen:Play()
            crownOpen:Play()

            task.delay(0.65, function()
                closeTween:Play()
                ribbonClose:Play()
                crownClose:Play()
                closeTween.Completed:Connect(function()
                    isOpening = false
                end)
            end)

            rollService.ExecuteRoll(player, false, broadcastEvent)
        end
    end)
end

-- ========================================================
-- 4. ПАЛИСАДНЫЕ СТЕНЫ, СТОРОЖЕВАЯ БАШНЯ И ВОРОТА
-- ========================================================
function WorldBuilderService.BuildPalisadeAndTower(world: Model)
    local defense = Instance.new("Folder")
    defense.Name = "CampDefenses"
    defense.Parent = world

    -- Заостренные бревна частокола по южной границе (кроме ворот)
    for x = -65, 65, 3.2 do
        if math.abs(x) > 12 then -- оставляем проход для ворот в центре
            local log = Instance.new("Part")
            log.Name = "PalisadeLog"
            log.Size = Vector3.new(2.4, math.random(8, 11), 2.4)
            log.Position = Vector3.new(x, 7, 58)
            log.Anchored = true
            log.Material = Enum.Material.Wood
            log.Color = (math.random(1, 2) == 1 and C_DARK_WOOD or C_MEDIUM_WOOD)
            log.Parent = defense
        end
    end

    -- Ворота лагеря: два высоких столба с перекладиной и синим знаменем
    local gateLeft = Instance.new("Part")
    gateLeft.Size = Vector3.new(3, 14, 3)
    gateLeft.Position = Vector3.new(-12, 9, 58)
    gateLeft.Anchored = true
    gateLeft.Material = Enum.Material.Wood
    gateLeft.Color = C_DARK_WOOD
    gateLeft.Parent = defense

    local gateRight = Instance.new("Part")
    gateRight.Size = Vector3.new(3, 14, 3)
    gateRight.Position = Vector3.new(12, 9, 58)
    gateRight.Anchored = true
    gateRight.Material = Enum.Material.Wood
    gateRight.Color = C_DARK_WOOD
    gateRight.Parent = defense

    local gateBeam = Instance.new("Part")
    gateBeam.Size = Vector3.new(27, 2.5, 3)
    gateBeam.Position = Vector3.new(0, 15, 58)
    gateBeam.Anchored = true
    gateBeam.Material = Enum.Material.Wood
    gateBeam.Color = C_DARK_WOOD
    gateBeam.Parent = defense

    -- Большой синий баннер над воротами с золотой короной
    local banner = Instance.new("Part")
    banner.Size = Vector3.new(10, 8, 0.3)
    banner.Position = Vector3.new(0, 11, 58)
    banner.Anchored = true
    banner.Material = Enum.Material.Fabric
    banner.Color = C_ROYAL_BLUE
    banner.Parent = defense

    local bannerCrown = Instance.new("Part")
    bannerCrown.Size = Vector3.new(3.5, 3.5, 0.5)
    bannerCrown.Position = Vector3.new(0, 11.5, 57.6)
    bannerCrown.Anchored = true
    bannerCrown.Material = Enum.Material.Metal
    bannerCrown.Color = C_BRASS
    bannerCrown.Parent = defense

    -- Сторожевая деревянная башня на холме слева
    local tower = Instance.new("Model")
    tower.Name = "WatchTower"
    tower.Parent = defense

    local towerLegs = {
        Vector3.new(-48, 8, 48),
        Vector3.new(-40, 8, 48),
        Vector3.new(-48, 8, 40),
        Vector3.new(-40, 8, 40),
    }
    for _, legPos in ipairs(towerLegs) do
        local post = Instance.new("Part")
        post.Size = Vector3.new(1.6, 20, 1.6)
        post.Position = legPos
        post.Anchored = true
        post.Material = Enum.Material.Wood
        post.Color = C_DARK_WOOD
        post.Parent = tower
    end

    local towerPlatform = Instance.new("Part")
    towerPlatform.Size = Vector3.new(12, 1.2, 12)
    towerPlatform.Position = Vector3.new(-44, 18, 44)
    towerPlatform.Anchored = true
    towerPlatform.Material = Enum.Material.WoodPlanks
    towerPlatform.Color = C_MEDIUM_WOOD
    towerPlatform.Parent = tower

    local towerRoof = Instance.new("Part")
    towerRoof.Size = Vector3.new(14, 4, 14)
    towerRoof.Position = Vector3.new(-44, 23, 44)
    towerRoof.Anchored = true
    towerRoof.Material = Enum.Material.Wood
    towerRoof.Color = C_DARK_WOOD
    towerRoof.Parent = tower
end

-- ========================================================
-- 5. ЛАГЕРЬ: КУЗНИЦА, ЛАВКА АЛХИМИКА, КОСТРИЩЕ
-- ========================================================
function WorldBuilderService.BuildCampFacilities(world: Model, playerDataService: any)
    local camp = Instance.new("Folder")
    camp.Name = "CampBuildings"
    camp.Parent = world

    -- 1. КУЗНИЦА ПОД ОТКРЫТЫМ НЕБОМ (Диорама средневековой кузницы)
    local forge = Instance.new("Model")
    forge.Name = "BlacksmithForge"
    forge.Parent = camp

    -- Каменный массивный очаг и дымоход
    local hearth = Instance.new("Part")
    hearth.Name = "StoneHearth"
    hearth.Size = Vector3.new(8, 6, 6)
    hearth.Position = Vector3.new(-18, 7, 22)
    hearth.Anchored = true
    hearth.Material = Enum.Material.Slate
    hearth.Color = Color3.fromRGB(65, 62, 60)
    hearth.Parent = forge

    local chimney = Instance.new("Part")
    chimney.Name = "Chimney"
    chimney.Size = Vector3.new(4, 8, 4)
    chimney.Position = hearth.Position + Vector3.new(0, 7, 0)
    chimney.Anchored = true
    chimney.Material = Enum.Material.Slate
    chimney.Color = Color3.fromRGB(55, 52, 50)
    chimney.Parent = forge

    -- Деревянный навес на брёвнах
    local canopyRoof = Instance.new("Part")
    canopyRoof.Name = "ForgeCanopy"
    canopyRoof.Size = Vector3.new(14, 1.2, 12)
    canopyRoof.Position = Vector3.new(-18, 14, 18)
    canopyRoof.Anchored = true
    canopyRoof.Material = Enum.Material.WoodPlanks
    canopyRoof.Color = C_DARK_WOOD
    canopyRoof.Parent = forge

    for _, pX in ipairs({ -23, -13 }) do
        local post = Instance.new("Part")
        post.Size = Vector3.new(1.4, 10, 1.4)
        post.Position = Vector3.new(pX, 9, 13)
        post.Anchored = true
        post.Material = Enum.Material.Wood
        post.Color = C_DARK_WOOD
        post.Parent = forge
    end

    -- Тлеющие угли в очаге и атмосферное освещение
    local coals = Instance.new("Part")
    coals.Size = Vector3.new(4.5, 0.8, 3.5)
    coals.Position = hearth.Position + Vector3.new(0, -1.8, 0)
    coals.Anchored = true
    coals.Material = Enum.Material.Slate
    coals.Color = Color3.fromRGB(50, 32, 24)
    coals.Parent = forge

    local forgeLight = Instance.new("PointLight")
    forgeLight.Color = Color3.fromRGB(255, 125, 40)
    forgeLight.Brightness = 2.2
    forgeLight.Range = 16
    forgeLight.Parent = coals

    local smoke = Instance.new("ParticleEmitter")
    smoke.Color = ColorSequence.new(Color3.fromRGB(130, 130, 130))
    smoke.Size = NumberSequence.new(0.6, 2.5)
    smoke.Rate = 10
    smoke.Speed = NumberRange.new(2, 4)
    smoke.Lifetime = NumberRange.new(1.5, 2.5)
    smoke.Parent = chimney

    -- Пень с тёмной наковальней
    local stump = Instance.new("Part")
    stump.Size = Vector3.new(2.8, 2.6, 2.8)
    stump.Position = Vector3.new(-18, 5.5, 14)
    stump.Anchored = true
    stump.Material = Enum.Material.Wood
    stump.Color = C_MEDIUM_WOOD
    stump.Parent = forge

    local anvil = Instance.new("Part")
    anvil.Size = Vector3.new(2.8, 1.4, 1.4)
    anvil.Position = stump.Position + Vector3.new(0, 1.9, 0)
    anvil.Anchored = true
    anvil.Material = Enum.Material.Metal
    anvil.Color = Color3.fromRGB(48, 48, 52)
    anvil.Parent = forge

    -- 2. ТОРГОВАЯ ЛАВКА (Резной средневековый прилавок с сине-золотым тентом)
    local stall = Instance.new("Model")
    stall.Name = "AlchemistStall"
    stall.Parent = camp

    local counter = Instance.new("Part")
    counter.Name = "Counter"
    counter.Size = Vector3.new(12, 3.2, 4.5)
    counter.Position = Vector3.new(20, 5.8, 22)
    counter.Anchored = true
    counter.Material = Enum.Material.WoodPlanks
    counter.Color = C_LIGHT_WOOD
    counter.Parent = stall

    -- Полосатый королевский тент над прилавком
    local canopy = Instance.new("Part")
    canopy.Size = Vector3.new(13, 1.4, 6.5)
    canopy.Position = Vector3.new(20, 11.5, 22)
    canopy.Anchored = true
    canopy.Material = Enum.Material.Fabric
    canopy.Color = C_ROYAL_BLUE
    canopy.Parent = stall

    local canopyStripe = Instance.new("Part")
    canopyStripe.Size = Vector3.new(3.5, 1.45, 6.55)
    canopyStripe.Position = canopy.Position
    canopyStripe.Anchored = true
    canopyStripe.Material = Enum.Material.Fabric
    canopyStripe.Color = C_BRASS
    canopyStripe.Parent = stall

    -- Стойки навеса
    for _, sX in ipairs({ 14.5, 25.5 }) do
        local post = Instance.new("Part")
        post.Size = Vector3.new(0.8, 8, 0.8)
        post.Position = Vector3.new(sX, 8, 20)
        post.Anchored = true
        post.Material = Enum.Material.Wood
        post.Color = C_DARK_WOOD
        post.Parent = stall
    end

    -- Стойка со светящимися колбами зелий
    local potionColors = {
        Color3.fromRGB(60, 255, 100), -- Зелье Удачи
        Color3.fromRGB(255, 75, 75),  -- Зелье Здоровья
        Color3.fromRGB(60, 160, 255), -- Зелье Эфира
    }
    for i, col in ipairs(potionColors) do
        local bottle = Instance.new("Part")
        bottle.Size = Vector3.new(0.8, 1.4, 0.8)
        bottle.Position = counter.Position + Vector3.new((i - 2) * 2.6, 2.2, 0)
        bottle.Anchored = true
        bottle.Material = Enum.Material.Neon
        bottle.Color = col
        bottle.Parent = stall

        local pLight = Instance.new("PointLight")
        pLight.Color = col
        pLight.Brightness = 1.6
        pLight.Range = 8
        pLight.Parent = bottle
    end

    -- Интерактив лавки: Купить Зелье Удачи за 50 монет
    local stallPrompt = Instance.new("ProximityPrompt")
    stallPrompt.ObjectText = "ЛАВКА ТОРГОВЦА"
    stallPrompt.ActionText = "Купить Зелье Удачи (50 монет)"
    stallPrompt.HoldDuration = 0.5
    stallPrompt.MaxActivationDistance = 10
    stallPrompt.Parent = counter

    stallPrompt.Triggered:Connect(function(player)
        local profile = playerDataService and playerDataService.GetProfile(player)
        if profile then
            if (profile.Coins or 0) >= 50 then
                profile.Coins -= 50
                profile.LuckMultiplier = 2.5 -- x2.5 Удачи
                SoundManager.PlaySound("Pray", 1.2, 0.9)
                task.delay(120, function()
                    if profile.LuckMultiplier == 2.5 then
                        profile.LuckMultiplier = 1.0
                    end
                end)
            else
                SoundManager.PlaySound("Error", 0.9, 0.7)
            end
        end
    end)

    -- 3. КОСТРИЩЕ С ТАБУРЕТАМИ
    local campfire = Instance.new("Model")
    campfire.Name = "RestCampfire"
    campfire.Parent = camp

    local pit = Instance.new("Part")
    pit.Size = Vector3.new(3, 0.6, 3)
    pit.Position = Vector3.new(16, 4.3, 36)
    pit.Anchored = true
    pit.Material = Enum.Material.Cobblestone
    pit.Color = C_STONE
    pit.Parent = campfire

    -- Поленья костра с частицами огня (без неонового куба)
    local fire = Instance.new("Part")
    fire.Size = Vector3.new(1.6, 0.8, 1.6)
    fire.Position = pit.Position + Vector3.new(0, 0.6, 0)
    fire.Anchored = true
    fire.Material = Enum.Material.Wood
    fire.Color = Color3.fromRGB(55, 36, 25)
    fire.Parent = campfire

    local fireFx = Instance.new("ParticleEmitter")
    fireFx.Color = ColorSequence.new(Color3.fromRGB(255, 180, 50), Color3.fromRGB(255, 80, 20))
    fireFx.Size = NumberSequence.new(0.4, 1.2)
    fireFx.Rate = 12
    fireFx.Speed = NumberRange.new(1.2, 2.4)
    fireFx.Lifetime = NumberRange.new(0.6, 1.2)
    fireFx.Parent = fire

    local cLight = Instance.new("PointLight")
    cLight.Color = Color3.fromRGB(255, 140, 50)
    cLight.Brightness = 2.0
    cLight.Range = 12
    cLight.Parent = fire
    SoundManager.AttachLoop(fire, "CampfireLoop", 30, 0.6)

    -- 3 Резных круглых табурета вокруг костра
    for angle = 0, 240, 120 do
        local rad = math.rad(angle)
        local stool = Instance.new("Part")
        stool.Size = Vector3.new(1.8, 1.2, 1.8)
        stool.Position = pit.Position + Vector3.new(math.cos(rad) * 4.2, 0.6, math.sin(rad) * 4.2)
        stool.Anchored = true
        stool.Material = Enum.Material.Wood
        stool.Color = C_DARK_WOOD
        stool.Parent = campfire
    end

    -- Тренога с чугунным котлом над костром (как на референсе loc-green-safezone-camp.png)
    local tripod = Instance.new("Model")
    tripod.Name = "CampTripod"
    tripod.Parent = campfire

    for _, xOff in ipairs({ -1.4, 1.4 }) do
        local pole = Instance.new("Part")
        pole.Size = Vector3.new(0.3, 4.2, 0.3)
        pole.Position = pit.Position + Vector3.new(xOff, 2.0, 0)
        pole.Orientation = Vector3.new(0, 0, xOff * -15)
        pole.Anchored = true
        pole.Material = Enum.Material.Wood
        pole.Color = C_DARK_WOOD
        pole.Parent = tripod
    end

    local pot = Instance.new("Part")
    pot.Name = "IronPot"
    pot.Shape = Enum.PartType.Cylinder
    pot.Size = Vector3.new(1.4, 1.6, 1.6)
    pot.Position = pit.Position + Vector3.new(0, 2.2, 0)
    pot.Orientation = Vector3.new(0, 0, 90)
    pot.Anchored = true
    pot.Material = Enum.Material.Metal
    pot.Color = Color3.fromRGB(40, 38, 38)
    pot.Parent = tripod

    local potSteam = Instance.new("ParticleEmitter")
    potSteam.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
    potSteam.Size = NumberSequence.new(0.3, 1.2)
    potSteam.Rate = 8
    potSteam.Speed = NumberRange.new(1, 2)
    potSteam.Lifetime = NumberRange.new(0.8, 1.5)
    potSteam.Parent = pot

    -- 4. БОЛЬШОЙ КОРОЛЕВСКИЙ СИНИЙ ШАТЁР (Королевский павильон из референса)
    local tent = Instance.new("Model")
    tent.Name = "GrandRoyalTent"
    tent.Parent = camp

    local tentBase = Instance.new("Part")
    tentBase.Name = "TentBase"
    tentBase.Size = Vector3.new(20, 10, 20)
    tentBase.Position = Vector3.new(0, 9.2, -22)
    tentBase.Anchored = true
    tentBase.CanCollide = true
    tentBase.Material = Enum.Material.Fabric
    tentBase.Color = C_ROYAL_BLUE
    tentBase.Parent = tent

    -- Конический купол шатра
    local tentCanopy = Instance.new("Part")
    tentCanopy.Name = "TentCanopy"
    tentCanopy.Size = Vector3.new(22, 10, 22)
    tentCanopy.Position = Vector3.new(0, 18, -22)
    tentCanopy.Anchored = true
    tentCanopy.CanCollide = false
    tentCanopy.Material = Enum.Material.Fabric
    tentCanopy.Color = C_ROYAL_BLUE
    tentCanopy.Parent = tent

    local coneMesh = Instance.new("SpecialMesh")
    coneMesh.MeshType = Enum.MeshType.Cone
    coneMesh.Parent = tentCanopy

    -- Золотая окантовка по периметру карниза
    local valance = Instance.new("Part")
    valance.Name = "GoldenValance"
    valance.Size = Vector3.new(21.4, 0.8, 21.4)
    valance.Position = Vector3.new(0, 13.8, -22)
    valance.Anchored = true
    valance.Material = Enum.Material.Metal
    valance.Color = C_BRASS
    valance.Parent = tent

    -- Центральный шпиль с флагом-вымпелом
    local spire = Instance.new("Part")
    spire.Size = Vector3.new(0.6, 7, 0.6)
    spire.Position = Vector3.new(0, 25, -22)
    spire.Anchored = true
    spire.Material = Enum.Material.Wood
    spire.Color = C_DARK_WOOD
    spire.Parent = tent

    local finial = Instance.new("Part")
    finial.Shape = Enum.PartType.Ball
    finial.Size = Vector3.new(1.4, 1.4, 1.4)
    finial.Position = spire.Position + Vector3.new(0, 3.5, 0)
    finial.Anchored = true
    finial.Material = Enum.Material.Metal
    finial.Color = C_BRASS
    finial.Parent = tent

    local pennant = Instance.new("Part")
    pennant.Size = Vector3.new(0.2, 2.2, 4.2)
    pennant.Position = spire.Position + Vector3.new(0, 2.0, 2.1)
    pennant.Anchored = true
    pennant.Material = Enum.Material.Fabric
    pennant.Color = C_ROYAL_BLUE
    pennant.Parent = tent

    -- Золотой герб Короны над входом
    local entranceCrown = Instance.new("Part")
    entranceCrown.Size = Vector3.new(3.2, 2.2, 0.4)
    entranceCrown.Position = Vector3.new(0, 11, -11.8)
    entranceCrown.Anchored = true
    entranceCrown.Material = Enum.Material.Metal
    entranceCrown.Color = C_BRASS
    entranceCrown.Parent = tent

    -- 5. ОГОРОД С ДЕРЕВЯННОЙ ИЗГОРОДЬЮ (Как на ui-main-safezone-screen.png справа)
    local garden = Instance.new("Model")
    garden.Name = "VegetableGarden"
    garden.Parent = camp

    local gardenSoil = Instance.new("Part")
    gardenSoil.Name = "TilledSoil"
    gardenSoil.Size = Vector3.new(18, 0.5, 16)
    gardenSoil.Position = Vector3.new(32, 4.2, 40)
    gardenSoil.Anchored = true
    gardenSoil.Material = Enum.Material.Ground
    gardenSoil.Color = Color3.fromRGB(60, 42, 28)
    gardenSoil.Parent = garden

    -- Деревянный заборчик вокруг огорода
    local fenceSegments = {
        { Size = Vector3.new(18, 2, 0.6), Pos = Vector3.new(32, 5.2, 32) },
        { Size = Vector3.new(18, 2, 0.6), Pos = Vector3.new(32, 5.2, 48) },
        { Size = Vector3.new(0.6, 2, 16), Pos = Vector3.new(23, 5.2, 40) },
        { Size = Vector3.new(0.6, 2, 16), Pos = Vector3.new(41, 5.2, 40) },
    }
    for _, f in ipairs(fenceSegments) do
        local fence = Instance.new("Part")
        fence.Size = f.Size
        fence.Position = f.Pos
        fence.Anchored = true
        fence.Material = Enum.Material.Wood
        fence.Color = C_MEDIUM_WOOD
        fence.Parent = garden
    end

    -- Ряды зелёных ростков
    for rx = -6, 6, 4 do
        for rz = -5, 5, 3.5 do
            local sprout = Instance.new("Part")
            sprout.Shape = Enum.PartType.Ball
            sprout.Size = Vector3.new(1.4, 1.0, 1.4)
            sprout.Position = gardenSoil.Position + Vector3.new(rx, 0.6, rz)
            sprout.Anchored = true
            sprout.Material = Enum.Material.Grass
            sprout.Color = Color3.fromRGB(50, 160, 40)
            sprout.Parent = garden
        end
    end

    -- 6. МАГИЧЕСКИЙ РУНИЧЕСКИЙ КОНТУР СЕЙФ-ЗОНЫ (Светящееся голубое кольцо)
    local runeRing = Instance.new("Model")
    runeRing.Name = "SafezoneRuneRing"
    runeRing.Parent = camp

    for angle = 0, 350, 10 do
        local rad = math.rad(angle)
        local radius = 62
        local segment = Instance.new("Part")
        segment.Size = Vector3.new(3.2, 0.25, 0.8)
        segment.Position = Vector3.new(math.cos(rad) * radius, 4.15, math.sin(rad) * radius)
        segment.Orientation = Vector3.new(0, -angle, 0)
        segment.Anchored = true
        segment.Material = Enum.Material.Neon
        segment.Color = Color3.fromRGB(65, 175, 255)
        segment.Transparency = 0.35
        segment.Parent = runeRing
    end

    -- 7. ДЕРЕВЯННЫЕ ШАРНИРНЫЕ ФИГУРКИ NPC (Без лиц, строго по правилу референса)
    local npcsFolder = Instance.new("Folder")
    npcsFolder.Name = "CampNPCs"
    npcsFolder.Parent = camp

    local function spawnNpcMannequin(name: string, pos: Vector3, facing: number, robeColor: Color3, role: string)
        local npc = Instance.new("Model")
        npc.Name = "NPC_" .. name
        npc.Parent = npcsFolder

        -- Голова-шар из светлого ясеня без лица
        local head = Instance.new("Part")
        head.Name = "Head"
        head.Shape = Enum.PartType.Ball
        head.Size = Vector3.new(1.8, 1.8, 1.8)
        head.Position = pos + Vector3.new(0, 4.6, 0)
        head.Anchored = true
        head.Material = Enum.Material.SmoothPlastic
        head.Color = Color3.fromRGB(205, 160, 115)
        head.Parent = npc

        -- Шарнирное тело манекена
        local body = Instance.new("Part")
        body.Name = "Torso"
        body.Size = Vector3.new(2.4, 3.2, 1.5)
        body.Position = pos + Vector3.new(0, 2.5, 0)
        body.Orientation = Vector3.new(0, facing, 0)
        body.Anchored = true
        body.Material = Enum.Material.Wood
        body.Color = robeColor
        body.Parent = npc

        -- Шаровые шарниры на плечах
        for _, sX in ipairs({ -1.3, 1.3 }) do
            local ball = Instance.new("Part")
            ball.Shape = Enum.PartType.Ball
            ball.Size = Vector3.new(1.1, 1.1, 1.1)
            ball.Position = body.Position + Vector3.new(sX, 1.2, 0)
            ball.Anchored = true
            ball.Material = Enum.Material.Wood
            ball.Color = Color3.fromRGB(150, 105, 70)
            ball.Parent = npc
        end

        -- Табличка над головой
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 160, 0, 42)
        bb.StudsOffset = Vector3.new(0, 2.2, 0)
        bb.AlwaysOnTop = false
        bb.MaxDistance = 45
        bb.Parent = head

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 1, 0)
        title.BackgroundTransparency = 1
        title.Text = "★ " .. role .. " ★"
        title.TextColor3 = Color3.fromRGB(255, 225, 120)
        title.Font = Enum.Font.Fondamento
        title.TextSize = 14
        title.Parent = bb

        local st = Instance.new("UIStroke")
        st.Color = Color3.fromRGB(25, 15, 10)
        st.Thickness = 1.5
        st.Parent = title
    end

    -- Кузнец у очага
    spawnNpcMannequin("Blacksmith", Vector3.new(-18, 4.2, 18), 90, Color3.fromRGB(75, 45, 30), "Кузнец Лагеря")
    -- Алхимик за прилавком
    spawnNpcMannequin("Alchemist", Vector3.new(20, 4.2, 24), -90, Color3.fromRGB(45, 25, 85), "Алхимик Таинств")
    -- Страж у ворот
    spawnNpcMannequin("Guard", Vector3.new(-9, 4.2, 54), 0, C_ROYAL_BLUE, "Королевский Страж")
end

-- ========================================================
-- 6. РЕСУРСНЫЕ УЗЛЫ: ЗОЛОТО, ДРОВА, РЫБАЛКА, АЛТАРЬ
-- ========================================================
function WorldBuilderService.BuildResourceNodes(world: Model, playerDataService: any)
    local nodes = Instance.new("Folder")
    nodes.Name = "ResourceNodes"
    nodes.Parent = world

    -- 1. СКАЛЬНЫЙ ВЫСТУП С ЗОЛОТОЙ РУДОЙ (Северо-восток)
    local oreRock = Instance.new("Part")
    oreRock.Name = "GoldVeinRock"
    oreRock.Size = Vector3.new(10, 8, 8)
    oreRock.Position = Vector3.new(38, 7, -30)
    oreRock.Anchored = true
    oreRock.Material = Enum.Material.Slate
    oreRock.Color = C_STONE
    oreRock.Parent = nodes

    for i = 1, 4 do
        local crystal = Instance.new("Part")
        crystal.Size = Vector3.new(1.4, 2.2, 1.4)
        crystal.Position = oreRock.Position + Vector3.new((i - 2.5) * 2.2, 1, -3.5)
        crystal.Orientation = Vector3.new(15, i * 45, 0)
        crystal.Anchored = true
        crystal.Material = Enum.Material.Metal
        crystal.Color = Color3.fromRGB(255, 215, 0)
        crystal.Parent = nodes
    end

    local orePrompt = Instance.new("ProximityPrompt")
    orePrompt.ObjectText = "ЖИЛА ЗОЛОТОЙ РУДЫ"
    orePrompt.ActionText = "Добыть самородки киркой"
    orePrompt.HoldDuration = 0.6
    orePrompt.MaxActivationDistance = 9
    orePrompt.Parent = oreRock

    orePrompt.Triggered:Connect(function(player)
        local prof = playerDataService and playerDataService.GetProfile(player)
        if prof then
            local mined = math.random(10, 25)
            prof.Coins = (prof.Coins or 0) + mined
            SoundManager.PlaySound("Mining", 1.0, 0.9)
        end
    end)

    -- 2. ПЕНЬ С ТОПОРОМ И ПОЛЕННИЦА (Лесозаготовка)
    local chopWood = Instance.new("Model")
    chopWood.Name = "WoodChoppingNode"
    chopWood.Parent = nodes

    local chopStump = Instance.new("Part")
    chopStump.Size = Vector3.new(3.5, 2.4, 3.5)
    chopStump.Position = Vector3.new(-38, 5.2, 28)
    chopStump.Anchored = true
    chopStump.Material = Enum.Material.Wood
    chopStump.Color = C_DARK_WOOD
    chopStump.Parent = chopWood

    local axe = Instance.new("Part")
    axe.Size = Vector3.new(0.4, 2.2, 1.2)
    axe.Position = chopStump.Position + Vector3.new(0, 1.8, 0)
    axe.Orientation = Vector3.new(20, 0, 0)
    axe.Anchored = true
    axe.Material = Enum.Material.Metal
    axe.Color = Color3.fromRGB(180, 185, 190)
    axe.Parent = chopWood

    local axePrompt = Instance.new("ProximityPrompt")
    axePrompt.ObjectText = "МЕСТО РУБКИ ЛЕСА"
    axePrompt.ActionText = "Порубить дрова"
    axePrompt.HoldDuration = 0.5
    axePrompt.MaxActivationDistance = 8
    axePrompt.Parent = chopStump

    axePrompt.Triggered:Connect(function(player)
        local prof = playerDataService and playerDataService.GetProfile(player)
        if prof then
            prof.Coins = (prof.Coins or 0) + math.random(5, 12)
            SoundManager.PlaySound("Woodcut", 1.0, 0.9)
        end
    end)

    -- 3. РЫБАЦКИЙ ПИРС НАД РЕКОЙ
    local pier = Instance.new("Model")
    pier.Name = "FishingPier"
    pier.Parent = nodes

    local pierPlanks = Instance.new("Part")
    pierPlanks.Size = Vector3.new(6, 0.6, 14)
    pierPlanks.Position = Vector3.new(-24, 4.4, -22)
    pierPlanks.Anchored = true
    pierPlanks.Material = Enum.Material.WoodPlanks
    pierPlanks.Color = C_MEDIUM_WOOD
    pierPlanks.Parent = pier

    local fishPrompt = Instance.new("ProximityPrompt")
    fishPrompt.ObjectText = "РЫБАЦКИЙ МОСТИК"
    fishPrompt.ActionText = "Забросить удочку"
    fishPrompt.HoldDuration = 0.8
    fishPrompt.MaxActivationDistance = 8
    fishPrompt.Parent = pierPlanks

    fishPrompt.Triggered:Connect(function(player)
        local prof = playerDataService and playerDataService.GetProfile(player)
        if prof then
            prof.Coins = (prof.Coins or 0) + math.random(8, 20)
            SoundManager.PlaySound("Splash", 1.0, 0.9)
        end
    end)

    -- 4. АЛТАРЬ ЧЕТЫРЁХЛИСТНОГО КЛЕВЕРА
    local shrineAltar = Instance.new("Part")
    shrineAltar.Size = Vector3.new(5, 2.6, 5)
    shrineAltar.Position = Vector3.new(38, 5.3, 2)
    shrineAltar.Anchored = true
    shrineAltar.Material = Enum.Material.Cobblestone
    shrineAltar.Color = C_STONE
    shrineAltar.Parent = nodes

    local clover = Instance.new("Part")
    clover.Size = Vector3.new(2.4, 2.4, 0.5)
    clover.Position = shrineAltar.Position + Vector3.new(0, 2.2, 0)
    clover.Anchored = true
    clover.Material = Enum.Material.Neon
    clover.Color = Color3.fromRGB(40, 240, 80)
    clover.Parent = nodes

    local cPrompt = Instance.new("ProximityPrompt")
    cPrompt.ObjectText = "АЛТАРЬ КЛЕВЕРА"
    cPrompt.ActionText = "Благословение (+100% к Удаче на 60 сек)"
    cPrompt.HoldDuration = 0.5
    cPrompt.MaxActivationDistance = 9
    cPrompt.Parent = clover

    cPrompt.Triggered:Connect(function(player)
        local prof = playerDataService and playerDataService.GetProfile(player)
        if prof then
            prof.LuckMultiplier = 2.0
            SoundManager.PlaySound("Pray", 1.0, 0.9)
            task.delay(60, function()
                if prof.LuckMultiplier == 2.0 then
                    prof.LuckMultiplier = 1.0
                end
            end)
        end
    end)
end

-- ========================================================
-- 7. РЕЗНЫЕ ДЕРЕВЬЯ И РАСТИТЕЛЬНОСТЬ ДИОРАМЫ
-- ========================================================
function WorldBuilderService.BuildVegetation(world: Model)
    local foliageFolder = Instance.new("Folder")
    foliageFolder.Name = "DioramaVegetation"
    foliageFolder.Parent = world

    local treeSpots = {
        Vector3.new(-52, 4, 32),
        Vector3.new(-54, 4, -12),
        Vector3.new(-42, 4, -40),
        Vector3.new(48, 4, 30),
        Vector3.new(52, 4, -36),
        Vector3.new(44, 4, 48),
        Vector3.new(-20, 4, 48),
    }

    for i, pos in ipairs(treeSpots) do
        local tree = Instance.new("Model")
        tree.Name = "MiniaturePineTree" .. i
        tree.Parent = foliageFolder

        -- Ствол из тёмного мореного дуба
        local trunk = Instance.new("Part")
        trunk.Name = "Trunk"
        trunk.Size = Vector3.new(2.2, 16, 2.2)
        trunk.Position = pos + Vector3.new(0, 8, 0)
        trunk.Anchored = true
        trunk.Material = Enum.Material.Wood
        trunk.Color = C_DARK_WOOD
        trunk.Parent = tree

        -- 5 ярусов конической хвои с природным цветовым градиентом (Табличная диорама)
        local pineTiers = {
            { y = 8.5, size = Vector3.new(13.5, 4.5, 13.5), col = Color3.fromRGB(36, 72, 34) },
            { y = 12.0, size = Vector3.new(10.5, 4.2, 10.5), col = Color3.fromRGB(46, 88, 40) },
            { y = 15.2, size = Vector3.new(7.8, 3.8, 7.8), col = Color3.fromRGB(58, 108, 48) },
            { y = 18.2, size = Vector3.new(5.0, 3.4, 5.0), col = Color3.fromRGB(72, 128, 56) },
            { y = 20.6, size = Vector3.new(2.6, 3.0, 2.6), col = Color3.fromRGB(85, 145, 65) },
        }

        for tierIdx, t in ipairs(pineTiers) do
            local frond = Instance.new("Part")
            frond.Name = "PineTier_" .. tierIdx
            frond.Size = t.size
            frond.Position = pos + Vector3.new(0, t.y, 0)
            frond.Anchored = true
            frond.Material = Enum.Material.Grass
            frond.Color = t.col
            frond.Parent = tree

            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Cone
            mesh.Parent = frond
        end
    end

    -- Поляны миниатюрных полевых цветов (Ромашки, лютики, незабудки как на референсе)
    local flowerColors = {
        Color3.fromRGB(250, 250, 245), -- Белые ромашки
        Color3.fromRGB(255, 220, 60),  -- Жёлтые лютики
        Color3.fromRGB(100, 180, 255), -- Голубые незабудки
    }
    local flowerFolder = Instance.new("Folder")
    flowerFolder.Name = "Wildflowers"
    flowerFolder.Parent = foliageFolder

    local flowerSeeds = {
        Vector3.new(-8, 4.2, 16), Vector3.new(-12, 4.2, 28), Vector3.new(-5, 4.2, 34),
        Vector3.new(8, 4.2, 14), Vector3.new(12, 4.2, 26), Vector3.new(6, 4.2, 38),
        Vector3.new(22, 4.2, 12), Vector3.new(-28, 4.2, 36), Vector3.new(24, 4.2, 48),
    }

    for _, seed in ipairs(flowerSeeds) do
        for k = 1, 4 do
            local f = Instance.new("Part")
            f.Shape = Enum.PartType.Ball
            f.Size = Vector3.new(0.65, 0.45, 0.65)
            f.Position = seed + Vector3.new((k % 2) * 1.2 - 0.6, 0, (k > 2 and 1.1 or -0.5))
            f.Anchored = true
            f.Material = Enum.Material.Grass
            f.Color = flowerColors[(k % #flowerColors) + 1]
            f.CanCollide = false
            f.Parent = flowerFolder
        end
    end
end

-- ========================================================
-- 8. СИЛУЭТ ДАЛЁКОГО ЗАМКА НА СКАЛЕ (ФОН ДИОРАМЫ)
-- ========================================================
function WorldBuilderService.BuildDistantCastle(world: Model)
    local castleFolder = Instance.new("Folder")
    castleFolder.Name = "DistantCastleBackdrop"
    castleFolder.Parent = world

    -- Высокий утёс вдалеке за северной стеной
    local castleCliff = Instance.new("Part")
    castleCliff.Size = Vector3.new(80, 55, 30)
    castleCliff.Position = Vector3.new(0, 26, -110)
    castleCliff.Anchored = true
    castleCliff.Material = Enum.Material.Slate
    castleCliff.Color = Color3.fromRGB(80, 75, 70)
    castleCliff.Parent = castleFolder

    -- Башни сказочного замка (стилизованные резные цилиндры)
    local towerPositions = {
        Vector3.new(-22, 58, -110),
        Vector3.new(0, 66, -110),
        Vector3.new(22, 58, -110),
    }

    for _, tPos in ipairs(towerPositions) do
        local castleTower = Instance.new("Part")
        castleTower.Shape = Enum.PartType.Cylinder
        castleTower.Size = Vector3.new(22, 10, 10)
        castleTower.Position = tPos
        castleTower.Orientation = Vector3.new(0, 0, 90)
        castleTower.Anchored = true
        castleTower.Material = Enum.Material.Slate
        castleTower.Color = Color3.fromRGB(115, 112, 110)
        castleTower.Parent = castleFolder

        -- Конический синий купол
        local roof = Instance.new("Part")
        roof.Size = Vector3.new(12, 10, 12)
        roof.Position = tPos + Vector3.new(0, 14, 0)
        roof.Anchored = true
        roof.Material = Enum.Material.Wood
        roof.Color = C_ROYAL_BLUE
        roof.Parent = castleFolder
    end
end

-- ========================================================
-- 9. ОСВЕЩЕНИЕ И АТМОСФЕРА МАКРО-ДИОРАМЫ (ЗОЛОТОЙ ЗАКАЗАТ / TILT-SHIFT)
-- ========================================================
function WorldBuilderService.SetupLighting()
    pcall(function()
        Lighting.ClockTime = 17.2 -- Золотой закатный час (по style-rules.md: "зелёная: золотой день/закат, длинные мягкие тени")
        Lighting.GeographicLatitude = 45
        Lighting.Brightness = 2.6
        Lighting.OutdoorAmbient = Color3.fromRGB(155, 125, 100)
        Lighting.Ambient = Color3.fromRGB(105, 88, 75)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 225, 170)
        Lighting.ColorShift_Bottom = Color3.fromRGB(100, 75, 55)

        Lighting.FogColor = Color3.fromRGB(230, 185, 145)
        Lighting.FogStart = 70
        Lighting.FogEnd = 260
    end)

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
            child:Destroy()
        end
    end

    -- Атмосфера золотого часа с мягкой дымкой
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.25
    atmosphere.Offset = 0.18
    atmosphere.Color = Color3.fromRGB(240, 200, 160)
    atmosphere.Decay = Color3.fromRGB(180, 130, 95)
    atmosphere.Haze = 1.2
    atmosphere.Glare = 0.45
    atmosphere.Parent = Lighting

    -- Теплые солнечные лучи сквозь кроны деревьев
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.18
    sunRays.Spread = 0.65
    sunRays.Parent = Lighting

    -- Цветокоррекция: глубокие оттенки полированного ореха, изумрудного мха и сияющей латуни
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.03
    cc.Contrast = 0.16
    cc.Saturation = 0.26
    cc.TintColor = Color3.fromRGB(255, 246, 232)
    cc.Parent = Lighting

    -- Мягкое свечение углей, золотых жил и латунных венцов
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.22
    bloom.Size = 18
    bloom.Threshold = 1.3
    bloom.Parent = Lighting

    -- Выразительный макро-эффект Tilt-Shift (настольная миниатюрная диорама)
    local dof = Instance.new("DepthOfFieldEffect")
    dof.Name = "MacroDioramaTiltShift"
    dof.FocusDistance = 28
    dof.InFocusRadius = 18
    dof.NearIntensity = 0.65 -- Кинематографичное размытие переднего края стола
    dof.FarIntensity = 0.85  -- Мягкое размытие силуэта замка и дальних гор
    dof.Parent = Lighting
end

return WorldBuilderService
