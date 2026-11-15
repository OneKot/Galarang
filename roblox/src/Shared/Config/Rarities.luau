--!strict
--[[
    Rarities.luau
    Свод редкостей по дизайн-документу Galarang (8 редкостей).
    Порядок: от Common (0) до Absolute (7).
]]

export type RarityInfo = {
    Id: number,
    Name: string,
    DisplayNameRu: string,
    Color: string, -- Hex
    AnnouncementTier: boolean, -- Вызывать ли объявление на весь сервер
}

local Rarities: { [number]: RarityInfo } = {
    [0] = {
        Id = 0,
        Name = "Common",
        DisplayNameRu = "Обычный",
        Color = "#8E8E93",
        AnnouncementTier = false,
    },
    [1] = {
        Id = 1,
        Name = "Uncommon",
        DisplayNameRu = "Необычный",
        Color = "#34C759",
        AnnouncementTier = false,
    },
    [2] = {
        Id = 2,
        Name = "Rare",
        DisplayNameRu = "Редкий",
        Color = "#007AFF",
        AnnouncementTier = false,
    },
    [3] = {
        Id = 3,
        Name = "Epic",
        DisplayNameRu = "Эпический",
        Color = "#AF52DE",
        AnnouncementTier = false,
    },
    [4] = {
        Id = 4,
        Name = "Mythic",
        DisplayNameRu = "Мифический",
        Color = "#FF3B30",
        AnnouncementTier = true,
    },
    [5] = {
        Id = 5,
        Name = "Legendary",
        DisplayNameRu = "Легендарный",
        Color = "#FFD60A",
        AnnouncementTier = true,
    },
    [6] = {
        Id = 6,
        Name = "Secret",
        DisplayNameRu = "Секретный",
        Color = "#1A1A1A",
        AnnouncementTier = true,
    },
    [7] = {
        Id = 7,
        Name = "Absolute",
        DisplayNameRu = "АБСОЛЮТ",
        Color = "#FFFFFF",
        AnnouncementTier = true,
    },
}

local RarityEnum = {
    Common = 0,
    Uncommon = 1,
    Rare = 2,
    Epic = 3,
    Mythic = 4,
    Legendary = 5,
    Secret = 6,
    Absolute = 7,
}

return {
    Rarities = Rarities,
    Enum = RarityEnum,
    IsRareOrHigher = function(rarityId: number): boolean
        return rarityId >= RarityEnum.Rare
    end,
}
