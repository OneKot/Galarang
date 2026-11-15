--!strict
--[[
    ClientMain.client.luau
    Главная входная точка клиента Galarang (Roblox).
    Аутентичный интерфейс по дизайн-документу style-rules.md:
    «Материал UI: расписное тёмное дерево + латунь + королевская эмаль».
    - Латунные угловые накладки с заклепками по 4 углам панелей.
    - Металлические и древесные градиенты (UIGradient).
    - Шрифты резной гравировки (Cinzel / Fondamento).
    - Окно Коллекции: сетка карточек, редкие и секретные предметы.
    - Звуковые перезвоны и световые вспышки при открытии.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Rarities = require(Config:WaitForChild("Rarities") :: any)
local Items = require(Config:WaitForChild("Items") :: any)
local SoundManager = require(Shared:WaitForChild("Modules"):WaitForChild("SoundManager") :: any)
local ItemAssetRegistry = require(Shared:WaitForChild("Modules"):WaitForChild("ItemAssetRegistry") :: any)

local Controllers = script.Parent:WaitForChild("Controllers")
local RollCutsceneController = require(Controllers:WaitForChild("RollCutsceneController") :: any)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestRoll = Remotes:WaitForChild("RequestRoll") :: RemoteFunction
local RollBroadcast = Remotes:WaitForChild("RollBroadcast") :: RemoteEvent
local GetProfile = Remotes:WaitForChild("GetProfile") :: RemoteFunction
local EquipItem = Remotes:WaitForChild("EquipItem") :: RemoteFunction
local RequestFusion = Remotes:WaitForChild("RequestFusion") :: RemoteFunction

local FONT_CARVED = Enum.Font.Fondamento

local isRolling = false
local autoRollEnabled = false
local fastRollEnabled = false
local lastRolledItemId = ""

-- Настройка камеры для макро-съёмки настольной диорамы
local camera = Workspace.CurrentCamera
if camera then
    camera.FieldOfView = 50
end
LocalPlayer.CameraMaxZoomDistance = 45
LocalPlayer.CameraMinZoomDistance = 12

local function setupDioramaCamera()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
    if hrp and camera then
        camera.CameraType = Enum.CameraType.Custom
        camera.FieldOfView = 50
    end
end
LocalPlayer.CharacterAdded:Connect(setupDioramaCamera)
if LocalPlayer.Character then
    task.spawn(setupDioramaCamera)
end

-- Динамический фокус макро-линзы Tilt-Shift: держит резкий фокус на персонаже
RunService.RenderStepped:Connect(function()
    local dof = Lighting:FindFirstChild("MacroDioramaTiltShift") :: DepthOfFieldEffect?
    if dof and camera then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if hrp then
            local dist = (camera.CFrame.Position - hrp.Position).Magnitude
            dof.FocusDistance = dist
        end
    end
end)

-- Создаем ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GalarangHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

local function hexToColor3(hex: string): Color3
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 255
    local g = tonumber(hex:sub(3, 4), 16) or 255
    local b = tonumber(hex:sub(5, 6), 16) or 255
    return Color3.fromRGB(r, g, b)
end

local function formatNumber(n: number): string
    local formatted = tostring(n)
    while true do
        local k
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1 %2")
        if k == 0 then break end
    end
    return formatted
end

-- Вспомогательная функция: добавляет латунные резные уголки с заклёпками по 4 углам панели
local function addBrassCorners(parent: GuiObject)
    local cornerSize = 14
    local offsets = {
        { UDim2.new(0, 0, 0, 0), Vector2.new(0, 0) },
        { UDim2.new(1, 0, 0, 0), Vector2.new(1, 0) },
        { UDim2.new(0, 0, 1, 0), Vector2.new(0, 1) },
        { UDim2.new(1, 0, 1, 0), Vector2.new(1, 1) },
    }

    for _, offset in ipairs(offsets) do
        local bracket = Instance.new("Frame")
        bracket.Name = "BrassBracket"
        bracket.Size = UDim2.new(0, cornerSize, 0, cornerSize)
        bracket.Position = offset[1]
        bracket.AnchorPoint = offset[2]
        bracket.BackgroundColor3 = Color3.fromRGB(225, 185, 75)
        bracket.BorderSizePixel = 0
        bracket.ZIndex = parent.ZIndex + 1
        bracket.Parent = parent

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 3)
        c.Parent = bracket

        local rivet = Instance.new("Frame")
        rivet.Size = UDim2.new(0, 4, 0, 4)
        rivet.AnchorPoint = Vector2.new(0.5, 0.5)
        rivet.Position = UDim2.new(0.5, 0, 0.5, 0)
        rivet.BackgroundColor3 = Color3.fromRGB(130, 95, 30)
        rivet.BorderSizePixel = 0
        rivet.ZIndex = bracket.ZIndex + 1
        rivet.Parent = bracket

        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(1, 0)
        rc.Parent = rivet
    end
end

-- ========================================================
-- Звуки
-- ========================================================
local soundFolder = Instance.new("Folder")
soundFolder.Name = "GalarangSounds"
soundFolder.Parent = screenGui

local function playChime(pitch: number)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://9114223175"
    s.Volume = 0.7
    s.PlaybackSpeed = pitch
    s.Parent = soundFolder
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

local function playFanfare()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://9119713951"
    s.Volume = 1.0
    s.Parent = soundFolder
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- ========================================================
-- Flash-эффект на весь экран для редких дропов
-- ========================================================
local flashFrame = Instance.new("Frame")
flashFrame.Name = "ScreenFlash"
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.ZIndex = 25
flashFrame.Parent = screenGui

local function triggerScreenFlash(color: Color3)
    flashFrame.BackgroundColor3 = color
    flashFrame.BackgroundTransparency = 0.15
    local tween = TweenService:Create(flashFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    })
    tween:Play()
end

-- ========================================================
-- Верхняя панель: Ресурсная плашка (слева) и меню (справа)
-- В точном соответствии с референсом ui-main-safezone-screen.png
-- ========================================================
local topCurrencyPlaque = Instance.new("Frame")
topCurrencyPlaque.Name = "TopCurrencyPlaque"
topCurrencyPlaque.Size = UDim2.new(0, 340, 0, 48)
topCurrencyPlaque.Position = UDim2.new(0, 24, 0, 60)
topCurrencyPlaque.BackgroundColor3 = Color3.fromRGB(36, 24, 16)
topCurrencyPlaque.BorderSizePixel = 0
topCurrencyPlaque.Parent = screenGui

local curCorner = Instance.new("UICorner")
curCorner.CornerRadius = UDim.new(0, 12)
curCorner.Parent = topCurrencyPlaque

local curStroke = Instance.new("UIStroke")
curStroke.Color = Color3.fromRGB(212, 175, 55)
curStroke.Thickness = 2.5
curStroke.Parent = topCurrencyPlaque
addBrassCorners(topCurrencyPlaque)

-- Иконка золотой монеты с короной из референса item-currency-resources.png
local coinIcon = Instance.new("ImageLabel")
coinIcon.Name = "CoinIcon"
coinIcon.Size = UDim2.new(0, 32, 0, 32)
coinIcon.Position = UDim2.new(0, 10, 0.5, -16)
coinIcon.BackgroundTransparency = 1
coinIcon.Image = ItemAssetRegistry.Icons.Coin
coinIcon.ScaleType = Enum.ScaleType.Fit
coinIcon.Parent = topCurrencyPlaque

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(0, 120, 1, 0)
coinLabel.Position = UDim2.new(0, 48, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "МОНЕТЫ: 0"
coinLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
coinLabel.Font = FONT_CARVED
coinLabel.TextSize = 16
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = topCurrencyPlaque

-- Иконка синего алмаза / клевера удачи
local gemIcon = Instance.new("ImageLabel")
gemIcon.Name = "GemIcon"
gemIcon.Size = UDim2.new(0, 32, 0, 32)
gemIcon.Position = UDim2.new(0, 175, 0.5, -16)
gemIcon.BackgroundTransparency = 1
gemIcon.Image = ItemAssetRegistry.Icons.Gem
gemIcon.ScaleType = Enum.ScaleType.Fit
gemIcon.Parent = topCurrencyPlaque

local luckLabel = Instance.new("TextLabel")
luckLabel.Name = "LuckLabel"
luckLabel.Size = UDim2.new(0, 120, 1, 0)
luckLabel.Position = UDim2.new(0, 212, 0, 0)
luckLabel.BackgroundTransparency = 1
luckLabel.Text = "УДАЧА: x1.0"
luckLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
luckLabel.Font = FONT_CARVED
luckLabel.TextSize = 16
luckLabel.TextXAlignment = Enum.TextXAlignment.Left
luckLabel.Parent = topCurrencyPlaque

-- Верхний правый ряд резных кнопок меню (Опущен ниже системного бара Roblox)
local topMenuBar = Instance.new("Frame")
topMenuBar.Name = "TopMenuBar"
topMenuBar.Size = UDim2.new(0, 430, 0, 48)
topMenuBar.Position = UDim2.new(1, -454, 0, 60)
topMenuBar.BackgroundTransparency = 1
topMenuBar.Parent = screenGui

-- Кнопка «КОЛЛЕКЦИЯ»
local collectionBtn = Instance.new("TextButton")
collectionBtn.Name = "CollectionBtn"
collectionBtn.Size = UDim2.new(0, 100, 1, 0)
collectionBtn.Position = UDim2.new(0, 0, 0, 0)
collectionBtn.BackgroundColor3 = Color3.fromRGB(20, 46, 88)
collectionBtn.Text = "📖 КАРТЫ"
collectionBtn.TextColor3 = Color3.fromRGB(255, 240, 200)
collectionBtn.Font = FONT_CARVED
collectionBtn.TextSize = 14
collectionBtn.Parent = topMenuBar

local collCorner = Instance.new("UICorner")
collCorner.CornerRadius = UDim.new(0, 10)
collCorner.Parent = collectionBtn

local collStroke = Instance.new("UIStroke")
collStroke.Color = Color3.fromRGB(218, 175, 55)
collStroke.Thickness = 2
collStroke.Parent = collectionBtn

-- Кнопка «ИНВЕНТАРЬ»
local inventoryBtn = Instance.new("TextButton")
inventoryBtn.Name = "InventoryBtn"
inventoryBtn.Size = UDim2.new(0, 100, 1, 0)
inventoryBtn.Position = UDim2.new(0, 108, 0, 0)
inventoryBtn.BackgroundColor3 = Color3.fromRGB(48, 34, 24)
inventoryBtn.Text = "🎒 СУМКА"
inventoryBtn.TextColor3 = Color3.fromRGB(240, 230, 210)
inventoryBtn.Font = FONT_CARVED
inventoryBtn.TextSize = 14
inventoryBtn.Parent = topMenuBar

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 10)
invCorner.Parent = inventoryBtn

local invStroke = Instance.new("UIStroke")
invStroke.Color = Color3.fromRGB(180, 140, 50)
invStroke.Thickness = 2
invStroke.Parent = inventoryBtn

-- Кнопка «СПЛАВ» (5 в 1)
local fusionBtn = Instance.new("TextButton")
fusionBtn.Name = "FusionBtn"
fusionBtn.Size = UDim2.new(0, 100, 1, 0)
fusionBtn.Position = UDim2.new(0, 216, 0, 0)
fusionBtn.BackgroundColor3 = Color3.fromRGB(72, 36, 22)
fusionBtn.Text = "⚒️ СПЛАВ"
fusionBtn.TextColor3 = Color3.fromRGB(255, 225, 170)
fusionBtn.Font = FONT_CARVED
fusionBtn.TextSize = 14
fusionBtn.Parent = topMenuBar

local fusCorner = Instance.new("UICorner")
fusCorner.CornerRadius = UDim.new(0, 10)
fusCorner.Parent = fusionBtn

local fusStroke = Instance.new("UIStroke")
fusStroke.Color = Color3.fromRGB(218, 145, 55)
fusStroke.Thickness = 2
fusStroke.Parent = fusionBtn

-- Кнопка «МУЗЫКА»
local musicBtn = Instance.new("TextButton")
musicBtn.Name = "MusicBtn"
musicBtn.Size = UDim2.new(0, 100, 1, 0)
musicBtn.Position = UDim2.new(0, 324, 0, 0)
musicBtn.BackgroundColor3 = Color3.fromRGB(42, 32, 24)
musicBtn.Text = "🎵 ЗВУК"
musicBtn.TextColor3 = Color3.fromRGB(200, 195, 185)
musicBtn.Font = FONT_CARVED
musicBtn.TextSize = 14
musicBtn.Parent = topMenuBar

local musCorner = Instance.new("UICorner")
musCorner.CornerRadius = UDim.new(0, 10)
musCorner.Parent = musicBtn

local musStroke = Instance.new("UIStroke")
musStroke.Color = Color3.fromRGB(150, 120, 50)
musStroke.Thickness = 1.5
musStroke.Parent = musicBtn

-- ========================================================
-- Нижняя панель действий (Главный резной постамент)
-- ========================================================
local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(0, 520, 0, 96)
bottomBar.Position = UDim2.new(0.5, -260, 1, -118)
bottomBar.BackgroundColor3 = Color3.fromRGB(36, 24, 16)
bottomBar.BorderSizePixel = 0
bottomBar.Parent = screenGui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 14)
barCorner.Parent = bottomBar

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(212, 175, 55)
barStroke.Thickness = 3
barStroke.Parent = bottomBar

local barGrad = Instance.new("UIGradient")
barGrad.Color = ColorSequence.new(Color3.fromRGB(48, 32, 22), Color3.fromRGB(26, 17, 11))
barGrad.Rotation = 45
barGrad.Parent = bottomBar
addBrassCorners(bottomBar)

-- Кнопка «ОТКРЫТЬ СУНДУК»
local rollButton = Instance.new("TextButton")
rollButton.Name = "RollButton"
rollButton.Size = UDim2.new(0, 220, 0, 64)
rollButton.Position = UDim2.new(0, 16, 0.5, -32)
rollButton.BackgroundColor3 = Color3.fromRGB(20, 46, 88)
rollButton.Text = ""
rollButton.AutoButtonColor = true
rollButton.Parent = bottomBar

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = rollButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(225, 185, 75)
btnStroke.Thickness = 2
btnStroke.Parent = rollButton

local btnGrad = Instance.new("UIGradient")
btnGrad.Color = ColorSequence.new(Color3.fromRGB(30, 68, 130), Color3.fromRGB(15, 34, 68))
btnGrad.Rotation = 90
btnGrad.Parent = rollButton

-- Иконка сундука из референса item-chest-states.png
local chestBtnIcon = Instance.new("ImageLabel")
chestBtnIcon.Name = "ChestIcon"
chestBtnIcon.Size = UDim2.new(0, 46, 0, 42)
chestBtnIcon.Position = UDim2.new(0, 10, 0.5, -21)
chestBtnIcon.BackgroundTransparency = 1
chestBtnIcon.Image = ItemAssetRegistry.Icons.ChestClosed
chestBtnIcon.ScaleType = Enum.ScaleType.Fit
chestBtnIcon.Parent = rollButton

local rollBtnText = Instance.new("TextLabel")
rollBtnText.Name = "BtnText"
rollBtnText.Size = UDim2.new(1, -62, 1, 0)
rollBtnText.Position = UDim2.new(0, 58, 0, 0)
rollBtnText.BackgroundTransparency = 1
rollBtnText.Text = "ОТКРЫТЬ [СУНДУК]"
rollBtnText.TextColor3 = Color3.fromRGB(255, 235, 175)
rollBtnText.Font = FONT_CARVED
rollBtnText.TextSize = 17
rollBtnText.Parent = rollButton

-- Кнопка «АВТО»
local autoButton = Instance.new("TextButton")
autoButton.Name = "AutoButton"
autoButton.Size = UDim2.new(0, 120, 0, 64)
autoButton.Position = UDim2.new(0, 248, 0.5, -32)
autoButton.BackgroundColor3 = Color3.fromRGB(48, 34, 24)
autoButton.Text = "АВТО: ВЫКЛ"
autoButton.TextColor3 = Color3.fromRGB(210, 205, 195)
autoButton.Font = FONT_CARVED
autoButton.TextSize = 15
autoButton.Parent = bottomBar

local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 10)
autoCorner.Parent = autoButton

local autoStroke = Instance.new("UIStroke")
autoStroke.Color = Color3.fromRGB(160, 130, 60)
autoStroke.Thickness = 2
autoStroke.Parent = autoButton

-- Кнопка «БЫСТРО» (пропуск анимаций для скоростных открытий)
local fastButton = Instance.new("TextButton")
fastButton.Name = "FastButton"
fastButton.Size = UDim2.new(0, 120, 0, 64)
fastButton.Position = UDim2.new(0, 380, 0.5, -32)
fastButton.BackgroundColor3 = Color3.fromRGB(48, 34, 24)
fastButton.Text = "⚡ БЫСТРО: ВЫКЛ"
fastButton.TextColor3 = Color3.fromRGB(210, 205, 195)
fastButton.Font = FONT_CARVED
fastButton.TextSize = 14
fastButton.Parent = bottomBar

local fastCorner = Instance.new("UICorner")
fastCorner.CornerRadius = UDim.new(0, 10)
fastCorner.Parent = fastButton

local fastStroke = Instance.new("UIStroke")
fastStroke.Color = Color3.fromRGB(160, 130, 60)
fastStroke.Thickness = 2
fastStroke.Parent = fastButton

-- Счётчик открытий, монет и удачи (Над нижней панелью)
local rollsCounter = Instance.new("TextLabel")
rollsCounter.Name = "RollsCounter"
rollsCounter.Size = UDim2.new(0, 520, 0, 32)
rollsCounter.Position = UDim2.new(0.5, -260, 1, -156)
rollsCounter.BackgroundColor3 = Color3.fromRGB(24, 16, 11)
rollsCounter.BackgroundTransparency = 0.2
rollsCounter.TextColor3 = Color3.fromRGB(255, 235, 190)
rollsCounter.Font = FONT_CARVED
rollsCounter.TextSize = 15
rollsCounter.Text = "Всего открытий: 0   |   💰 Монеты: 0   |   🍀 Удача: x1.0"
rollsCounter.Parent = screenGui

local rcCorner = Instance.new("UICorner")
rcCorner.CornerRadius = UDim.new(0, 8)
rcCorner.Parent = rollsCounter

local rcStroke = Instance.new("UIStroke")
rcStroke.Color = Color3.fromRGB(180, 140, 50)
rcStroke.Thickness = 1.5
rcStroke.Parent = rollsCounter

-- ========================================================
-- Карточка результата открытия (Таро-карточка коллекционера)
-- ========================================================
local resultCard = Instance.new("Frame")
resultCard.Name = "ResultCard"
resultCard.Size = UDim2.new(0, 340, 0, 480)
resultCard.Position = UDim2.new(0.5, -170, 0.5, -240)
resultCard.BackgroundColor3 = Color3.fromRGB(22, 16, 12)
resultCard.Visible = false
resultCard.ZIndex = 20
resultCard.Parent = screenGui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 16)
cardCorner.Parent = resultCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = Color3.fromRGB(225, 185, 75)
cardStroke.Thickness = 3
cardStroke.Parent = resultCard

local cardGrad = Instance.new("UIGradient")
cardGrad.Color = ColorSequence.new(Color3.fromRGB(36, 26, 18), Color3.fromRGB(16, 12, 8))
cardGrad.Rotation = 90
cardGrad.Parent = resultCard
addBrassCorners(resultCard)

-- Кнопка закрытия карточки [✕] в верхнем правом углу
local cardCloseBtn = Instance.new("TextButton")
cardCloseBtn.Name = "CardCloseBtn"
cardCloseBtn.Size = UDim2.new(0, 28, 0, 28)
cardCloseBtn.Position = UDim2.new(1, -36, 0, 10)
cardCloseBtn.BackgroundColor3 = Color3.fromRGB(45, 32, 22)
cardCloseBtn.Text = "✕"
cardCloseBtn.TextColor3 = Color3.fromRGB(220, 200, 180)
cardCloseBtn.Font = Enum.Font.SourceSansBold
cardCloseBtn.TextSize = 16
cardCloseBtn.ZIndex = 25
cardCloseBtn.Parent = resultCard

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = cardCloseBtn

cardCloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(resultCard, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 260, 0, 360)
    }):Play()
    task.delay(0.18, function()
        resultCard.Visible = false
    end)
end)

-- Верхняя плашка редкости (Pill)
local rarityPill = Instance.new("Frame")
rarityPill.Name = "RarityPill"
rarityPill.Size = UDim2.new(0, 180, 0, 26)
rarityPill.Position = UDim2.new(0.5, -90, 0, 16)
rarityPill.BackgroundColor3 = Color3.fromRGB(15, 10, 8)
rarityPill.BackgroundTransparency = 0.2
rarityPill.ZIndex = 21
rarityPill.Parent = resultCard

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(0, 13)
pillCorner.Parent = rarityPill

local pillStroke = Instance.new("UIStroke")
pillStroke.Name = "PillStroke"
pillStroke.Color = Color3.fromRGB(218, 175, 55)
pillStroke.Thickness = 1.5
pillStroke.Parent = rarityPill

local rarityBadge = Instance.new("TextLabel")
rarityBadge.Name = "RarityBadge"
rarityBadge.Size = UDim2.new(1, 0, 1, 0)
rarityBadge.BackgroundTransparency = 1
rarityBadge.Text = "✦ ОБЫЧНЫЙ ✦"
rarityBadge.Font = FONT_CARVED
rarityBadge.TextSize = 15
rarityBadge.ZIndex = 22
rarityBadge.Parent = rarityPill

-- Название предмета (Крупный резной золотой шрифт)
local itemNameLabel = Instance.new("TextLabel")
itemNameLabel.Name = "ItemName"
itemNameLabel.Size = UDim2.new(1, -32, 0, 36)
itemNameLabel.Position = UDim2.new(0, 16, 0, 50)
itemNameLabel.BackgroundTransparency = 1
itemNameLabel.TextColor3 = Color3.fromRGB(255, 245, 220)
itemNameLabel.Font = FONT_CARVED
itemNameLabel.TextSize = 24
itemNameLabel.TextScaled = true
itemNameLabel.ZIndex = 21
itemNameLabel.Parent = resultCard

local itemNameStroke = Instance.new("UIStroke")
itemNameStroke.Color = Color3.fromRGB(24, 15, 8)
itemNameStroke.Thickness = 2
itemNameStroke.Parent = itemNameLabel

-- Центр: Окно предмета с резной рамкой и мягким фоновым свечением
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.Size = UDim2.new(0, 160, 0, 160)
iconContainer.Position = UDim2.new(0.5, -80, 0, 94)
iconContainer.BackgroundColor3 = Color3.fromRGB(14, 10, 8)
iconContainer.BackgroundTransparency = 0.3
iconContainer.ZIndex = 21
iconContainer.Parent = resultCard

local iconContainerCorner = Instance.new("UICorner")
iconContainerCorner.CornerRadius = UDim.new(0, 14)
iconContainerCorner.Parent = iconContainer

local iconContainerStroke = Instance.new("UIStroke")
iconContainerStroke.Color = Color3.fromRGB(120, 90, 45)
iconContainerStroke.Thickness = 1.5
iconContainerStroke.Parent = iconContainer

-- Резная рамка редкости
local cardItemFrame = Instance.new("ImageLabel")
cardItemFrame.Name = "CardItemFrame"
cardItemFrame.Size = UDim2.new(1, 0, 1, 0)
cardItemFrame.BackgroundTransparency = 1
cardItemFrame.ScaleType = Enum.ScaleType.Fit
cardItemFrame.ZIndex = 22
cardItemFrame.Parent = iconContainer

-- Чистая иконка предмета (Без искажений и фоновых наложений)
local cardItemIcon = Instance.new("ImageLabel")
cardItemIcon.Name = "CardItemIcon"
cardItemIcon.Size = UDim2.new(0, 128, 0, 128)
cardItemIcon.Position = UDim2.new(0.5, -64, 0.5, -64)
cardItemIcon.BackgroundTransparency = 1
cardItemIcon.ScaleType = Enum.ScaleType.Fit
cardItemIcon.ZIndex = 23
cardItemIcon.Parent = iconContainer

-- Плашка шанса выпадения
local oddsPill = Instance.new("Frame")
oddsPill.Name = "OddsPill"
oddsPill.Size = UDim2.new(0, 180, 0, 26)
oddsPill.Position = UDim2.new(0.5, -90, 0, 268)
oddsPill.BackgroundColor3 = Color3.fromRGB(18, 14, 10)
oddsPill.BackgroundTransparency = 0.4
oddsPill.ZIndex = 21
oddsPill.Parent = resultCard

local oddsCorner = Instance.new("UICorner")
oddsCorner.CornerRadius = UDim.new(0, 8)
oddsCorner.Parent = oddsPill

local oddsLabel = Instance.new("TextLabel")
oddsLabel.Name = "OddsLabel"
oddsLabel.Size = UDim2.new(1, 0, 1, 0)
oddsLabel.BackgroundTransparency = 1
oddsLabel.TextColor3 = Color3.fromRGB(240, 205, 95)
oddsLabel.Font = Enum.Font.SourceSansBold
oddsLabel.TextSize = 16
oddsLabel.ZIndex = 22
oddsLabel.Parent = oddsPill

-- Художественное описание предмета
local descBox = Instance.new("Frame")
descBox.Name = "DescBox"
descBox.Size = UDim2.new(1, -36, 0, 68)
descBox.Position = UDim2.new(0, 18, 0, 304)
descBox.BackgroundColor3 = Color3.fromRGB(16, 12, 10)
descBox.BackgroundTransparency = 0.5
descBox.ZIndex = 21
descBox.Parent = resultCard

local descCorner = Instance.new("UICorner")
descCorner.CornerRadius = UDim.new(0, 8)
descCorner.Parent = descBox

local descLabel = Instance.new("TextLabel")
descLabel.Name = "Description"
descLabel.Size = UDim2.new(1, -16, 1, -8)
descLabel.Position = UDim2.new(0, 8, 0, 4)
descLabel.BackgroundTransparency = 1
descLabel.TextColor3 = Color3.fromRGB(205, 195, 180)
descLabel.Font = Enum.Font.SourceSansItalic
descLabel.TextSize = 15
descLabel.TextWrapped = true
descLabel.ZIndex = 22
descLabel.Parent = descBox

-- Кнопка «НАДЕТЬ» в карточке дропа
local equipCardBtn = Instance.new("TextButton")
equipCardBtn.Name = "EquipCardBtn"
equipCardBtn.Size = UDim2.new(0, 190, 0, 46)
equipCardBtn.Position = UDim2.new(0.5, -95, 0, 396)
equipCardBtn.BackgroundColor3 = Color3.fromRGB(20, 52, 100)
equipCardBtn.Text = "⚔️ НАДЕТЬ"
equipCardBtn.TextColor3 = Color3.fromRGB(255, 240, 200)
equipCardBtn.Font = FONT_CARVED
equipCardBtn.TextSize = 18
equipCardBtn.ZIndex = 22
equipCardBtn.Parent = resultCard

local eqCorner = Instance.new("UICorner")
eqCorner.CornerRadius = UDim.new(0, 10)
eqCorner.Parent = equipCardBtn

local eqStroke = Instance.new("UIStroke")
eqStroke.Color = Color3.fromRGB(218, 175, 55)
eqStroke.Thickness = 2
eqStroke.Parent = equipCardBtn

equipCardBtn.MouseButton1Click:Connect(function()
    if lastRolledItemId ~= "" then
        EquipItem:InvokeServer(lastRolledItemId)
        equipCardBtn.Text = "✅ В РУКАХ!"
        task.delay(1.2, function()
            equipCardBtn.Text = "⚔️ НАДЕТЬ"
        end)
    end
end)

-- Баннер глобальных объявлений (Сверху)
local broadcastBanner = Instance.new("TextLabel")
broadcastBanner.Name = "BroadcastBanner"
broadcastBanner.Size = UDim2.new(1, 0, 0, 52)
broadcastBanner.Position = UDim2.new(0, 0, 0, 24)
broadcastBanner.BackgroundColor3 = Color3.fromRGB(20, 14, 10)
broadcastBanner.BackgroundTransparency = 0.2
broadcastBanner.TextColor3 = Color3.fromRGB(255, 215, 0)
broadcastBanner.Font = FONT_CARVED
broadcastBanner.TextSize = 20
broadcastBanner.Visible = false
broadcastBanner.ZIndex = 30
broadcastBanner.Parent = screenGui

local bStroke = Instance.new("UIStroke")
bStroke.Color = Color3.fromRGB(218, 165, 32)
bStroke.Thickness = 2
bStroke.Parent = broadcastBanner

-- ========================================================
-- Модальное окно: «КОЛЛЕКЦИЯ И ИНВЕНТАРЬ»
-- ========================================================
local modalFrame = Instance.new("Frame")
modalFrame.Name = "ModalFrame"
modalFrame.Size = UDim2.new(0, 620, 0, 480)
modalFrame.Position = UDim2.new(0.5, -310, 0.5, -240)
modalFrame.BackgroundColor3 = Color3.fromRGB(34, 22, 15)
modalFrame.Visible = false
modalFrame.ZIndex = 15
modalFrame.Parent = screenGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 16)
modalCorner.Parent = modalFrame

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(218, 175, 55)
modalStroke.Thickness = 3
modalStroke.Parent = modalFrame

local modalGrad = Instance.new("UIGradient")
modalGrad.Color = ColorSequence.new(Color3.fromRGB(44, 28, 18), Color3.fromRGB(22, 14, 9))
modalGrad.Rotation = 90
modalGrad.Parent = modalFrame
addBrassCorners(modalFrame)

local modalTitle = Instance.new("TextLabel")
modalTitle.Name = "Title"
modalTitle.Size = UDim2.new(1, -90, 0, 54)
modalTitle.Position = UDim2.new(0, 24, 0, 12)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "📖 КОЛЛЕКЦИЯ РЕЗНЫХ ФИГУРОК"
modalTitle.TextColor3 = Color3.fromRGB(255, 215, 60)
modalTitle.Font = FONT_CARVED
modalTitle.TextSize = 24
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.ZIndex = 16
modalTitle.Parent = modalFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -52, 0, 18)
closeBtn.BackgroundColor3 = Color3.fromRGB(90, 30, 22)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 240, 220)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 20
closeBtn.ZIndex = 16
closeBtn.Parent = modalFrame

local modalCloseCorner = Instance.new("UICorner")
modalCloseCorner.CornerRadius = UDim.new(0, 8)
modalCloseCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    modalFrame.Visible = false
end)

local scrollList = Instance.new("ScrollingFrame")
scrollList.Name = "ScrollList"
scrollList.Size = UDim2.new(1, -48, 1, -90)
scrollList.Position = UDim2.new(0, 24, 0, 72)
scrollList.BackgroundTransparency = 1
scrollList.ScrollBarThickness = 8
scrollList.ScrollBarImageColor3 = Color3.fromRGB(218, 175, 55)
scrollList.ZIndex = 16
scrollList.Parent = modalFrame

local uilist = Instance.new("UIListLayout")
uilist.Padding = UDim.new(0, 8)
uilist.Parent = scrollList

local function refreshCollection()
    local profile = GetProfile:InvokeServer()
    if not profile then return end

    for _, c in ipairs(scrollList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    for _, item in ipairs(Items.ItemsList) do
        local isUnlocked = profile.UnlockedIndex[item.Id] == true
        local rInfo = Rarities.Rarities[item.Rarity]
        local color = isUnlocked and (rInfo and hexToColor3(rInfo.Color) or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(90, 85, 80)

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -14, 0, 56)
        row.BackgroundColor3 = isUnlocked and Color3.fromRGB(46, 32, 22) or Color3.fromRGB(24, 18, 14)
        row.BorderSizePixel = 0
        row.ZIndex = 17
        row.Parent = scrollList

        local rCorner = Instance.new("UICorner")
        rCorner.CornerRadius = UDim.new(0, 8)
        rCorner.Parent = row

        local rStroke = Instance.new("UIStroke")
        rStroke.Color = color
        rStroke.Thickness = isUnlocked and 2 or 1
        rStroke.Parent = row

        -- Иконка оружия из референса
        local iconImg = Instance.new("ImageLabel")
        iconImg.Name = "ItemIcon"
        iconImg.Size = UDim2.new(0, 42, 0, 42)
        iconImg.Position = UDim2.new(0, 8, 0.5, -21)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = isUnlocked and ItemAssetRegistry.GetItemIcon(item.Id, item.Type) or ItemAssetRegistry.Icons.ChestClosed
        iconImg.ImageColor3 = isUnlocked and Color3.new(1, 1, 1) or Color3.fromRGB(70, 70, 70)
        iconImg.ScaleType = Enum.ScaleType.Fit
        iconImg.ZIndex = 18
        iconImg.Parent = row

        local nameText = Instance.new("TextLabel")
        nameText.Size = UDim2.new(0.50, 0, 1, 0)
        nameText.Position = UDim2.new(0, 56, 0, 0)
        nameText.BackgroundTransparency = 1
        nameText.Text = isUnlocked and string.format("[%s] %s", rInfo and rInfo.DisplayNameRu or "", item.NameRu) or "??? [Заблокировано]"
        nameText.TextColor3 = isUnlocked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(115, 110, 105)
        nameText.Font = FONT_CARVED
        nameText.TextSize = 16
        nameText.TextXAlignment = Enum.TextXAlignment.Left
        nameText.ZIndex = 18
        nameText.Parent = row

        local chanceText = Instance.new("TextLabel")
        chanceText.Size = UDim2.new(0.24, 0, 1, 0)
        chanceText.Position = UDim2.new(0.55, 0, 0, 0)
        chanceText.BackgroundTransparency = 1
        chanceText.Text = string.format("1 из %s", formatNumber(item.OneInN))
        chanceText.TextColor3 = Color3.fromRGB(225, 185, 75)
        chanceText.Font = Enum.Font.SourceSansBold
        chanceText.TextSize = 15
        chanceText.ZIndex = 18
        chanceText.Parent = row

        if isUnlocked then
            local eqBtn = Instance.new("TextButton")
            eqBtn.Size = UDim2.new(0, 92, 0, 38)
            eqBtn.Position = UDim2.new(1, -104, 0.5, -19)
            eqBtn.BackgroundColor3 = Color3.fromRGB(22, 60, 105)
            eqBtn.Text = "Надеть"
            eqBtn.TextColor3 = Color3.fromRGB(255, 245, 220)
            eqBtn.Font = FONT_CARVED
            eqBtn.TextSize = 15
            eqBtn.ZIndex = 18
            eqBtn.Parent = row

            local eqc = Instance.new("UICorner")
            eqc.CornerRadius = UDim.new(0, 6)
            eqc.Parent = eqBtn

            local eqs = Instance.new("UIStroke")
            eqs.Color = Color3.fromRGB(218, 175, 55)
            eqs.Thickness = 1.5
            eqs.Parent = eqBtn

            eqBtn.MouseButton1Click:Connect(function()
                EquipItem:InvokeServer(item.Id)
                eqBtn.Text = "В руках!"
                task.delay(1.2, function() eqBtn.Text = "Надеть" end)
            end)
        end
    end

    scrollList.CanvasSize = UDim2.new(0, 0, 0, #Items.ItemsList * 64)
end

-- ========================================================
-- Окно СПЛАВА (5 в 1)
-- ========================================================
local function refreshFusionModal()
    for _, child in ipairs(scrollList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local profile = GetProfile:InvokeServer()
    if not profile then return end

    local playerCoins = profile.Coins or 0
    local itemCounts: { [string]: number } = {}
    for _, it in ipairs(profile.Inventory or {}) do
        itemCounts[it.Id] = (itemCounts[it.Id] or 0) + 1
    end

    local fusionCosts = {
        [0] = 50,
        [1] = 200,
        [2] = 600,
        [3] = 1800,
        [4] = 5000,
        [5] = 25000,
        [6] = 100000,
    }

    local yOffset = 0
    for _, item in ipairs(Items.ItemsList) do
        -- Нельзя сплавлять Абсолют (тир 7)
        if item.Rarity < 7 then
            local count = itemCounts[item.Id] or 0
            local cost = fusionCosts[item.Rarity] or 50
            local canFuse = (count >= 5) and (playerCoins >= cost)

            local rInfo = Rarities.Rarities[item.Rarity]
            local col = rInfo and hexToColor3(rInfo.Color) or Color3.fromRGB(200, 200, 200)

            local itemRow = Instance.new("Frame")
            itemRow.Name = "FusionRow_" .. item.Id
            itemRow.Size = UDim2.new(1, -16, 0, 68)
            itemRow.Position = UDim2.new(0, 8, 0, yOffset)
            itemRow.BackgroundColor3 = Color3.fromRGB(34, 23, 16)
            itemRow.Parent = scrollList

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 8)
            rowCorner.Parent = itemRow

            local rowStroke = Instance.new("UIStroke")
            rowStroke.Color = canFuse and Color3.fromRGB(255, 215, 60) or col
            rowStroke.Thickness = canFuse and 2.5 or 1.5
            rowStroke.Parent = itemRow

            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 86, 0, 24)
            badge.Position = UDim2.new(0, 8, 0, 8)
            badge.BackgroundColor3 = Color3.fromRGB(20, 14, 10)
            badge.Text = rInfo and rInfo.DisplayNameRu or "ОБЫЧНЫЙ"
            badge.TextColor3 = col
            badge.Font = FONT_CARVED
            badge.TextSize = 13
            badge.Parent = itemRow

            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 6)
            bc.Parent = badge

            local nameText = Instance.new("TextLabel")
            nameText.Size = UDim2.new(0, 240, 0, 24)
            nameText.Position = UDim2.new(0, 102, 0, 8)
            nameText.BackgroundTransparency = 1
            nameText.Text = item.NameRu
            nameText.TextColor3 = Color3.fromRGB(240, 230, 210)
            nameText.Font = FONT_CARVED
            nameText.TextSize = 15
            nameText.TextXAlignment = Enum.TextXAlignment.Left
            nameText.Parent = itemRow

            local progressText = Instance.new("TextLabel")
            progressText.Size = UDim2.new(0, 320, 0, 22)
            progressText.Position = UDim2.new(0, 10, 0, 38)
            progressText.BackgroundTransparency = 1
            progressText.Text = string.format("Наличие: %d/5 шт.   |   Стоимость: %d монет   %s",
                count, cost, canFuse and "✨ ГОТОВ К СПЛАВУ!" or (count < 5 and "(Нужно еще)" or "(Не хватает монет)"))
            progressText.TextColor3 = canFuse and Color3.fromRGB(255, 225, 120) or Color3.fromRGB(180, 170, 160)
            progressText.Font = Enum.Font.SourceSansBold
            progressText.TextSize = 13
            progressText.TextXAlignment = Enum.TextXAlignment.Left
            progressText.Parent = itemRow

            local fuseBtn = Instance.new("TextButton")
            fuseBtn.Name = "FuseBtn"
            fuseBtn.Size = UDim2.new(0, 110, 0, 44)
            fuseBtn.Position = UDim2.new(1, -118, 0.5, -22)
            fuseBtn.BackgroundColor3 = canFuse and Color3.fromRGB(150, 75, 25) or Color3.fromRGB(48, 36, 28)
            fuseBtn.Text = canFuse and "⚒️ СПЛАВИТЬ" or string.format("%d/5", count)
            fuseBtn.TextColor3 = canFuse and Color3.fromRGB(255, 240, 190) or Color3.fromRGB(150, 140, 130)
            fuseBtn.Font = FONT_CARVED
            fuseBtn.TextSize = 14
            fuseBtn.AutoButtonColor = canFuse
            fuseBtn.Parent = itemRow

            local fbc = Instance.new("UICorner")
            fbc.CornerRadius = UDim.new(0, 8)
            fbc.Parent = fuseBtn

            local fbs = Instance.new("UIStroke")
            fbs.Color = canFuse and Color3.fromRGB(255, 215, 60) or Color3.fromRGB(80, 65, 50)
            fbs.Thickness = 1.5
            fbs.Parent = fuseBtn

            if canFuse then
                fuseBtn.MouseButton1Click:Connect(function()
                    fuseBtn.Text = "КУЁМ..."
                    SoundManager.PlaySound("AnvilHit", 1.0, 0.9)

                    local res = RequestFusion:InvokeServer(item.Id)
                    if res and res.Success then
                        triggerScreenFlash(Color3.fromRGB(255, 215, 60))
                        SoundManager.PlaySound("LegendaryDrop", 1.0, 1.0)
                        fuseBtn.Text = "ВЫКОВАНО!"
                        task.wait(0.6)
                        refreshFusionModal()
                    else
                        fuseBtn.Text = "ОШИБКА"
                        task.delay(1.0, function()
                            fuseBtn.Text = "⚒️ СПЛАВИТЬ"
                        end)
                    end
                end)
            end

            yOffset += 76
        end
    end

    scrollList.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

collectionBtn.MouseButton1Click:Connect(function()
    modalTitle.Text = "📖 КОЛЛЕКЦИЯ РЕЗНЫХ ФИГУРОК"
    refreshCollection()
    modalFrame.Visible = true
end)

inventoryBtn.MouseButton1Click:Connect(function()
    modalTitle.Text = "🎒 ВАШ ИНВЕНТАРЬ"
    refreshCollection()
    modalFrame.Visible = true
end)

fusionBtn.MouseButton1Click:Connect(function()
    modalTitle.Text = "⚒️ ПЕЧЬ СПЛАВА 5 В 1 (КУЗНИЦА)"
    refreshFusionModal()
    modalFrame.Visible = true
end)

-- Управление фоновой музыкой
local musicPlaying = false
local bgMusicInstance: Sound? = nil

musicBtn.MouseButton1Click:Connect(function()
    musicPlaying = not musicPlaying
    if musicPlaying then
        musicBtn.Text = "🎵 МУЗЫКА: ВКЛ"
        musicBtn.BackgroundColor3 = Color3.fromRGB(28, 62, 118)
        musicBtn.TextColor3 = Color3.fromRGB(255, 240, 200)

        if not bgMusicInstance then
            bgMusicInstance = Instance.new("Sound")
            bgMusicInstance.Name = "GalarangDioramaMusic"
            bgMusicInstance.SoundId = SoundManager.Sounds.MusicLoop
            bgMusicInstance.Looped = true
            bgMusicInstance.Volume = 0.5
            bgMusicInstance.Parent = game:GetService("SoundService")
        end
        bgMusicInstance:Play()
    else
        musicBtn.Text = "🎵 МУЗЫКА: ВЫКЛ"
        musicBtn.BackgroundColor3 = Color3.fromRGB(42, 32, 24)
        musicBtn.TextColor3 = Color3.fromRGB(200, 195, 185)

        if bgMusicInstance then
            bgMusicInstance:Stop()
        end
    end
end)

-- Переключатель скоростного режима (Skip Cutscenes)
fastButton.MouseButton1Click:Connect(function()
    fastRollEnabled = not fastRollEnabled
    if fastRollEnabled then
        fastButton.Text = "⚡ БЫСТРО: ВКЛ"
        fastButton.BackgroundColor3 = Color3.fromRGB(180, 110, 20)
        fastButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        fastButton.Text = "⚡ БЫСТРО: ВЫКЛ"
        fastButton.BackgroundColor3 = Color3.fromRGB(48, 34, 24)
        fastButton.TextColor3 = Color3.fromRGB(210, 205, 195)
    end
end)

-- ========================================================
-- Логика броска (Roll)
-- ========================================================
local function triggerRoll()
    if isRolling then return end
    isRolling = true

    rollBtnText.Text = "ОТКРЫВАЕМ..."

    local result = RequestRoll:InvokeServer(false)
    if result and result.Success then
        lastRolledItemId = result.ItemId

        local rInfo = Rarities.Rarities[result.Rarity]
        local color = rInfo and hexToColor3(rInfo.Color) or Color3.fromRGB(255, 255, 255)

        -- Для высоких тиров (Legendary, Secret, Absolute) запускаем катсцену
        if result.Rarity >= 5 and not fastRollEnabled then
            local cutsceneDone = false
            RollCutsceneController.PlayReveal({
                ItemId = result.ItemId,
                NameRu = result.NameRu,
                Rarity = result.Rarity,
                OneInN = result.OneInN,
                Description = result.Description,
                Color = color,
                SkipAnimation = false,
            }, function()
                cutsceneDone = true
            end)

            local startWait = os.clock()
            while not cutsceneDone and (os.clock() - startWait) < 6.5 do
                task.wait(0.1)
            end
        elseif result.Rarity >= 4 then
            triggerScreenFlash(color)
            playFanfare()
        else
            playChime(1.0 + (result.Rarity :: number) * 0.12)
        end

        rarityBadge.Text = "✦ " .. string.upper(rInfo and rInfo.DisplayNameRu or "ОБЫЧНЫЙ") .. " ✦"
        rarityBadge.TextColor3 = color
        cardStroke.Color = color
        local pStroke = rarityPill:FindFirstChild("PillStroke") :: UIStroke?
        if pStroke then pStroke.Color = color end

        cardItemIcon.Image = ItemAssetRegistry.GetItemIcon(result.ItemId, result.Type)
        cardItemFrame.Image = ItemAssetRegistry.GetFrame(result.Rarity)

        itemNameLabel.Text = result.NameRu
        oddsLabel.Text = string.format("Шанс: 1 из %s", formatNumber(result.OneInN))
        descLabel.Text = result.Description
        rollsCounter.Text = string.format("Всего открытий: %s", formatNumber(result.TotalRolls))

        resultCard.Visible = true
        resultCard.Size = UDim2.new(0, 300, 0, 420)
        TweenService:Create(resultCard, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 340, 0, 480)
        }):Play()
    end

    task.wait(0.8)
    rollBtnText.Text = "ОТКРЫТЬ [СУНДУК]"
    isRolling = false
end

rollButton.MouseButton1Click:Connect(triggerRoll)

autoButton.MouseButton1Click:Connect(function()
    autoRollEnabled = not autoRollEnabled
    if autoRollEnabled then
        autoButton.Text = "АВТО: ВКЛ"
        autoButton.BackgroundColor3 = Color3.fromRGB(34, 139, 34)
        autoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        autoButton.Text = "АВТО: ВЫКЛ"
        autoButton.BackgroundColor3 = Color3.fromRGB(48, 34, 24)
        autoButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- Цикл авто-ролла
task.spawn(function()
    while true do
        task.wait(1.0)
        if autoRollEnabled and not isRolling then
            triggerRoll()
        end
    end
end)

-- Слушатель глобального оповещения на весь сервер
RollBroadcast.OnClientEvent:Connect(function(data)
    local prefix = data.IsFusion and "⚒️ СПЛАВ:" or "👑 НАХОДКА:"
    broadcastBanner.Text = string.format("%s %s получил [%s] (Редкость: %s | 1 из %s)!",
        prefix, data.PlayerName, data.ItemName, data.RarityName, formatNumber(data.OneInN))
    broadcastBanner.TextColor3 = hexToColor3(tostring(data.Color or "#FFD700"))
    broadcastBanner.Visible = true

    task.delay(5.0, function()
        broadcastBanner.Visible = false
    end)
end)

-- Обновление счетчика открытий и монет
task.spawn(function()
    while true do
        task.wait(2.0)
        local profile = GetProfile:InvokeServer()
        if profile then
            local rolls = profile.TotalRolls or 0
            local coins = profile.Coins or 0
            local luck = profile.LuckMultiplier or 1.0
            coinLabel.Text = string.format("👑 МОНЕТЫ: %s", formatNumber(coins))
            luckLabel.Text = string.format("🍀 УДАЧА: x%.1f", luck)
            rollsCounter.Text = string.format("Всего открытий: %s   |   💰 Монеты: %d   |   🍀 Удача: x%.1f",
                formatNumber(rolls), coins, luck)
        end
    end
end)

print("[Galarang Client] Аутентичный резной интерфейс инициализирован!")
