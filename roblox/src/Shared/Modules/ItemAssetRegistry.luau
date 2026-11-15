--!strict
--[[
    ItemAssetRegistry.luau
    Централизованный реестр графических ассетов и спрайтов Galarang:
    Обеспечивает 100% соответствие утверждённым концепт-артам из design/refs/.
    Все спрайты нарезаны из оригинальных PNG-файлов высокого разрешения.
]]

local ItemAssetRegistry = {}

local BASE_PATH = "rbxasset://textures/galarang/"

-- Карты фонов карточек редкостей (из ui-inventory-cards.png)
ItemAssetRegistry.RarityCards = {
    [0] = BASE_PATH .. "card_common.png",
    [1] = BASE_PATH .. "card_uncommon.png",
    [2] = BASE_PATH .. "card_rare.png",
    [3] = BASE_PATH .. "card_epic.png",
    [4] = BASE_PATH .. "card_mythic.png",
    [5] = BASE_PATH .. "card_legendary.png",
    [6] = BASE_PATH .. "card_secret.png",
    [7] = BASE_PATH .. "card_absolute.png",
}

-- Резные рамки редкостей (из ui-rarity-frames.png)
ItemAssetRegistry.RarityFrames = {
    [0] = BASE_PATH .. "frame_common.png",
    [1] = BASE_PATH .. "frame_uncommon.png",
    [2] = BASE_PATH .. "frame_rare.png",
    [3] = BASE_PATH .. "frame_epic.png",
    [4] = BASE_PATH .. "frame_mythic.png",
    [5] = BASE_PATH .. "frame_legendary.png",
    [6] = BASE_PATH .. "frame_secret.png",
    [7] = BASE_PATH .. "frame_absolute.png",
}

-- Иконки валют и ресурсов (из item-currency-resources.png)
ItemAssetRegistry.Icons = {
    Coin = BASE_PATH .. "coin.png",
    Gem = BASE_PATH .. "gem.png",
    Key = BASE_PATH .. "key.png",
    GoldOre = BASE_PATH .. "gold_ore.png",
    VoidCrystal = BASE_PATH .. "void_crystal.png",
    WoodLog = BASE_PATH .. "wood_log.png",
    Fish = BASE_PATH .. "fish.png",
    ChestClosed = BASE_PATH .. "chest_closed.png",
    ChestOpening = BASE_PATH .. "chest_opening.png",
    ChestOpen = BASE_PATH .. "chest_open.png",
    ChestGolden = BASE_PATH .. "chest_golden.png",
}

-- Иконки оружия (из item-weapons-set.png)
ItemAssetRegistry.WeaponIcons = {
    Dagger = BASE_PATH .. "wep_dagger.png",
    Sword = BASE_PATH .. "wep_sword.png",
    Spear = BASE_PATH .. "wep_spear.png",
    Halberd = BASE_PATH .. "wep_halberd.png",
    Axe = BASE_PATH .. "wep_axe.png",
    Mace = BASE_PATH .. "wep_mace.png",
    Hammer = BASE_PATH .. "wep_hammer.png",
    Bow = BASE_PATH .. "wep_bow.png",
    Crossbow = BASE_PATH .. "wep_crossbow.png",
    Shield = BASE_PATH .. "wep_shield.png",
    Relic = BASE_PATH .. "void_crystal.png",
}

-- Определение типа спрайта по ID предмета
function ItemAssetRegistry.GetItemIcon(itemId: string, itemType: string?): string
    local id = string.lower(itemId)
    if id:find("dagger") or id:find("стилет") or id:find("кинжал") then
        return ItemAssetRegistry.WeaponIcons.Dagger
    elseif id:find("axe") or id:find("топор") or id:find("секира") then
        return ItemAssetRegistry.WeaponIcons.Axe
    elseif id:find("spear") or id:find("копь") or id:find("пика") then
        return ItemAssetRegistry.WeaponIcons.Spear
    elseif id:find("halberd") or id:find("глефа") then
        return ItemAssetRegistry.WeaponIcons.Halberd
    elseif id:find("mace") or id:find("булав") or id:find("морген") then
        return ItemAssetRegistry.WeaponIcons.Mace
    elseif id:find("hammer") or id:find("молот") or id:find("дубин") or id:find("club") then
        return ItemAssetRegistry.WeaponIcons.Hammer
    elseif id:find("bow") or id:find("лук") then
        return ItemAssetRegistry.WeaponIcons.Bow
    elseif id:find("cross") or id:find("арбалет") then
        return ItemAssetRegistry.WeaponIcons.Crossbow
    elseif id:find("shield") or id:find("щит") or itemType == "Shield" then
        return ItemAssetRegistry.WeaponIcons.Shield
    elseif id:find("crystal") or id:find("осколок") or id:find("antimatter") or itemType == "Relic" then
        return ItemAssetRegistry.Icons.VoidCrystal
    else
        return ItemAssetRegistry.WeaponIcons.Sword
    end
end

function ItemAssetRegistry.GetCardBg(rarity: number): string
    return ItemAssetRegistry.RarityCards[rarity] or ItemAssetRegistry.RarityCards[0]
end

function ItemAssetRegistry.GetFrame(rarity: number): string
    return ItemAssetRegistry.RarityFrames[rarity] or ItemAssetRegistry.RarityFrames[0]
end

return ItemAssetRegistry
