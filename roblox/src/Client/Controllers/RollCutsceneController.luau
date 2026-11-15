--!strict
--[[
    RollCutsceneController.luau
    Кинематографичная система открытия сундука по референсам:
    - scene-drop-legendary.png (золотой солнечный взрыв)
    - scene-drop-secret.png (космическая туманность, фиолетово-чёрный дым)
    - scene-drop-absolute.png (ослепительный чистый белый первосвет)
    - ui-chest-loot-beams.png (лучи добычи из сундука)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SoundManager = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Modules"):WaitForChild("SoundManager") :: any)

local FONT_CARVED = Enum.Font.Fondamento

local RollCutsceneController = {}
local Camera = Workspace.CurrentCamera

export type CutsceneData = {
    ItemId: string,
    NameRu: string,
    Rarity: number,
    OneInN: number,
    Description: string,
    Color: Color3,
    SkipAnimation: boolean,
}

function RollCutsceneController.PlayReveal(data: CutsceneData, onComplete: () -> ())
    local screenGui = PlayerGui:FindFirstChild("GalarangHUD") :: ScreenGui
    if not screenGui then
        onComplete()
        return
    end

    local rarity = data.Rarity

    -- Анимация 3D-сундука в мире (откидывание крышки, световой луч добычи по референсу ui-chest-loot-beams.png)
    task.spawn(function()
        local diorama = Workspace:FindFirstChild("DioramaWorld")
        local dais = diorama and diorama:FindFirstChild("RoyalChestDais")
        local chestModel = dais and dais:FindFirstChild("AncientRoyalChest")
        if not chestModel then return end

        local chestBase = chestModel:FindFirstChild("ChestBase") :: BasePart?
        if not chestBase then return end

        local chestMesh = chestBase:FindFirstChildOfClass("SpecialMesh")
        local lootBeam = chestBase:FindFirstChild("LootBeam") :: Beam?
        local interiorLight = chestBase:FindFirstChild("InteriorChestLight") :: PointLight?

        local rarityColors = {
            [0] = Color3.fromRGB(220, 220, 220),
            [1] = Color3.fromRGB(90, 220, 90),
            [2] = Color3.fromRGB(70, 150, 255),
            [3] = Color3.fromRGB(180, 80, 255),
            [4] = Color3.fromRGB(255, 60, 50),
            [5] = Color3.fromRGB(255, 215, 50),
            [6] = Color3.fromRGB(150, 50, 220),
            [7] = Color3.fromRGB(255, 255, 255),
        }
        local beamColor = rarityColors[rarity] or Color3.fromRGB(255, 220, 100)
        local baseCF = chestBase.CFrame
        local baseScale = chestMesh and chestMesh.Scale or Vector3.new(3.8, 3.8, 3.8)

        -- Дрожание 3D-сундука перед открытием (магическая вибрация)
        if not data.SkipAnimation then
            for _ = 1, 4 do
                chestBase.CFrame = baseCF * CFrame.Angles(0, math.rad(math.random(-2, 2)), math.rad(math.random(-2, 2)))
                task.wait(0.04)
            end
            chestBase.CFrame = baseCF
        end

        -- Вспышка и упругая пульсация 3D-модели сундука
        if chestMesh then
            TweenService:Create(chestMesh, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Scale = baseScale * 1.12
            }):Play()
        end

        if interiorLight then
            interiorLight.Brightness = 5.0
            interiorLight.Range = 25
            interiorLight.Color = beamColor
        end

        if lootBeam then
            lootBeam.Color = ColorSequence.new(beamColor)
            lootBeam.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.15),
                NumberSequenceKeypoint.new(0.8, 0.35),
                NumberSequenceKeypoint.new(1, 1),
            })
        end

        local waitTime = (data.SkipAnimation and 0.5) or (rarity >= 5 and 3.2) or 1.5
        task.wait(waitTime)

        -- Плавный возврат в исходное состояние
        if chestMesh then
            TweenService:Create(chestMesh, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = baseScale
            }):Play()
        end

        if interiorLight then
            interiorLight.Brightness = 1.8
            interiorLight.Range = 14
            interiorLight.Color = Color3.fromRGB(255, 210, 90)
        end

        if lootBeam then
            lootBeam.Transparency = NumberSequence.new(1)
        end
    end)

    if data.SkipAnimation then
        -- Мгновенный показ для быстрого авто-ролла
        SoundManager.PlaySound("CommonDrop", 1.0 + data.Rarity * 0.1)
        onComplete()
        return
    end

    -- 1. Создаем оверлей катсцены
    local cutsceneFrame = Instance.new("Frame")
    cutsceneFrame.Name = "ActiveCutscene"
    cutsceneFrame.Size = UDim2.new(1, 0, 1, 0)
    cutsceneFrame.BackgroundTransparency = 1
    cutsceneFrame.BorderSizePixel = 0
    cutsceneFrame.ZIndex = 50
    cutsceneFrame.Parent = screenGui

    -- ========================================================
    -- АБСОЛЮТ (Тир 7, 1 к 10 000 000): Ослепительный Первосвет
    -- ========================================================
    if rarity == 7 then
        cutsceneFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        cutsceneFrame.BackgroundTransparency = 1

        SoundManager.PlaySound("AbsoluteDrop", 1.0, 1.0)

        -- 1 фаза: Затухание в ослепительно белый свет
        local flashIn = TweenService:Create(cutsceneFrame, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 0.05
        })
        flashIn:Play()

        -- Центральные лучи света (Вращающийся радиальный диск)
        local rays = Instance.new("ImageLabel")
        rays.Size = UDim2.new(0, 700, 0, 700)
        rays.Position = UDim2.new(0.5, -350, 0.5, -350)
        rays.BackgroundTransparency = 1
        rays.Image = "rbxassetid://4996891465" -- Радиальные лучи
        rays.ImageColor3 = Color3.fromRGB(255, 255, 240)
        rays.ImageTransparency = 0.2
        rays.ZIndex = 51
        rays.Parent = cutsceneFrame

        task.spawn(function()
            while cutsceneFrame.Parent do
                rays.Rotation += 1.5
                task.wait(0.02)
            end
        end)

        task.wait(2.2)

        -- 2 фаза: Раскрытие карточки АБСОЛЮТА
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 80)
        title.Position = UDim2.new(0, 0, 0.35, 0)
        title.BackgroundTransparency = 1
        title.Text = "✧ А Б С О Л Ю Т ✧"
        title.TextColor3 = Color3.fromRGB(255, 215, 60)
        title.Font = FONT_CARVED
        title.TextSize = 44
        title.ZIndex = 52
        title.Parent = cutsceneFrame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Thickness = 3
        stroke.Parent = title

        task.wait(2.5)

        local fadeOut = TweenService:Create(cutsceneFrame, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            cutsceneFrame:Destroy()
            onComplete()
        end)
        return

    -- ========================================================
    -- СЕКРЕТНЫЙ (Тир 6, 1 к 1 500 000+): Чёрный дым и антиматерия
    -- ========================================================
    elseif rarity == 6 then
        cutsceneFrame.BackgroundColor3 = Color3.fromRGB(15, 8, 22) -- Тёмный космический фиолетовый
        cutsceneFrame.BackgroundTransparency = 1

        SoundManager.PlaySound("SecretDrop", 0.9, 1.0)

        local blackout = TweenService:Create(cutsceneFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 0.1
        })
        blackout:Play()

        local voidText = Instance.new("TextLabel")
        voidText.Size = UDim2.new(1, 0, 0, 70)
        voidText.Position = UDim2.new(0, 0, 0.4, 0)
        voidText.BackgroundTransparency = 1
        voidText.Text = "★ С Е К Р Е Т Н Ы Й ★"
        voidText.TextColor3 = Color3.fromRGB(190, 80, 255)
        voidText.Font = FONT_CARVED
        voidText.TextSize = 38
        voidText.ZIndex = 52
        voidText.Parent = cutsceneFrame

        task.wait(2.2)

        local fadeOut = TweenService:Create(cutsceneFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            cutsceneFrame:Destroy()
            onComplete()
        end)
        return

    -- ========================================================
    -- ЛЕГЕНДАРНЫЙ (Тир 5, 1 к 8 000+): Золотой солнечный взрыв
    -- ========================================================
    elseif rarity == 5 then
        cutsceneFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 60)
        cutsceneFrame.BackgroundTransparency = 0.4

        SoundManager.PlaySound("LegendaryDrop", 1.0, 0.9)

        local flash = TweenService:Create(cutsceneFrame, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        flash:Play()
        flash.Completed:Connect(function()
            cutsceneFrame:Destroy()
            onComplete()
        end)
        return

    -- ========================================================
    -- МИФИЧЕСКИЙ (Тир 4, 1 к 1 250+): Багровый импульс
    -- ========================================================
    elseif rarity == 4 then
        cutsceneFrame.BackgroundColor3 = Color3.fromRGB(255, 50, 40)
        cutsceneFrame.BackgroundTransparency = 0.5

        SoundManager.PlaySound("EpicDrop", 1.0, 0.8)

        local flash = TweenService:Create(cutsceneFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        flash:Play()
        flash.Completed:Connect(function()
            cutsceneFrame:Destroy()
            onComplete()
        end)
        return

    -- ========================================================
    -- ОБЫЧНЫЙ .. РЕДКИЙ (0..3): Быстрый колокольчик
    -- ========================================================
    else
        cutsceneFrame:Destroy()
        SoundManager.PlaySound("CommonDrop", 1.0 + rarity * 0.12, 0.7)
        onComplete()
        return
    end
end

return RollCutsceneController
