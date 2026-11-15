--!strict
--[[
    Items.luau
    Конфигурация предметов первого сектора (Резные фигурки и оружие).
    Каждый предмет имеет уникальный Id, привязку к редкости и базовый шанс «1 из N».
]]

local Rarities = require(script.Parent.Rarities)
local R = Rarities.Enum

export type ItemDef = {
    Id: string,
    NameRu: string,
    Rarity: number,
    OneInN: number,
    Type: "Weapon" | "Armor" | "Shield" | "Relic",
    Description: string,
}

local Items: { [string]: ItemDef } = {
    -- Common (1/4 .. 1/10)
    ["wooden_dagger"] = {
        Id = "wooden_dagger",
        NameRu = "Деревянный стилет",
        Rarity = R.Common,
        OneInN = 4,
        Type = "Weapon",
        Description = "Простая резная палочка с остриём.",
    },
    ["carved_club"] = {
        Id = "carved_club",
        NameRu = "Дубовая дубина",
        Rarity = R.Common,
        OneInN = 5,
        Type = "Weapon",
        Description = "Тяжёлый сук, зашлифованный до блеска.",
    },
    ["splint_shield"] = {
        Id = "splint_shield",
        NameRu = "Лучинный щиток",
        Rarity = R.Common,
        OneInN = 8,
        Type = "Shield",
        Description = "Связка сосновых плашек.",
    },
    ["pine_sword"] = {
        Id = "pine_sword",
        NameRu = "Сосновый меч",
        Rarity = R.Common,
        OneInN = 10,
        Type = "Weapon",
        Description = "Учебный клинок резного рыцаря.",
    },

    -- Uncommon (1/12 .. 1/40)
    ["ironwood_axe"] = {
        Id = "ironwood_axe",
        NameRu = "Топор из железного дерева",
        Rarity = R.Uncommon,
        OneInN = 12,
        Type = "Weapon",
        Description = "Твёрдый как сталь, но пахнет смолой.",
    },
    ["brass_buckler"] = {
        Id = "brass_buckler",
        NameRu = "Латунный баклер",
        Rarity = R.Uncommon,
        OneInN = 15,
        Type = "Shield",
        Description = "Круглый щиток с латунной заклёпкой-короной.",
    },
    ["ash_spear"] = {
        Id = "ash_spear",
        NameRu = "Ясеневое копьё",
        Rarity = R.Uncommon,
        OneInN = 20,
        Type = "Weapon",
        Description = "Длинное древко с гранёным навершием.",
    },
    ["guard_tabard"] = {
        Id = "guard_tabard",
        NameRu = "Табард стража",
        Rarity = R.Uncommon,
        OneInN = 30,
        Type = "Armor",
        Description = "Синее полотно с вышитой короной.",
    },
    ["reinforced_helm"] = {
        Id = "reinforced_helm",
        NameRu = "Резной шлем с забралом",
        Rarity = R.Uncommon,
        OneInN = 40,
        Type = "Armor",
        Description = "Пустая тёмная прорезь без глаз.",
    },

    -- Rare (1/60 .. 1/200)
    ["walnut_broadsword"] = {
        Id = "walnut_broadsword",
        NameRu = "Палаш тёмного ореха",
        Rarity = R.Rare,
        OneInN = 60,
        Type = "Weapon",
        Description = "Клинок с филигранной резьбой по долу.",
    },
    ["blue_enamel_shield"] = {
        Id = "blue_enamel_shield",
        NameRu = "Щит синей эмали",
        Rarity = R.Rare,
        OneInN = 75,
        Type = "Shield",
        Description = "Покрыт густой синей эмалью и латунными уголками.",
    },
    ["amber_mace"] = {
        Id = "amber_mace",
        NameRu = "Янтарная булава",
        Rarity = R.Rare,
        OneInN = 100,
        Type = "Weapon",
        Description = "Навершие из монолитного куска смоляного янтаря.",
    },
    ["gilded_breastplate"] = {
        Id = "gilded_breastplate",
        NameRu = "Позолоченный нагрудник",
        Rarity = R.Rare,
        OneInN = 150,
        Type = "Armor",
        Description = "Тонкая золотая фольга по морёному дубу.",
    },
    ["knight_halberd"] = {
        Id = "knight_halberd",
        NameRu = "Рыцарская алебарда",
        Rarity = R.Rare,
        OneInN = 200,
        Type = "Weapon",
        Description = "Парадное церемониальное оружие замковой стражи.",
    },

    -- Epic (1/250 .. 1/1 000)
    ["verdant_scythe"] = {
        Id = "verdant_scythe",
        NameRu = "Изумрудная коса",
        Rarity = R.Epic,
        OneInN = 250,
        Type = "Weapon",
        Description = "Оплетённая живым мхом и янтарными каплями.",
    },
    ["brass_automaton_fist"] = {
        Id = "brass_automaton_fist",
        NameRu = "Кулак автоматона",
        Rarity = R.Epic,
        OneInN = 300,
        Type = "Weapon",
        Description = "Заводной шарнирный кулак с латунными шестернями.",
    },
    ["sunburst_shield"] = {
        Id = "sunburst_shield",
        NameRu = "Щит золотого солнца",
        Rarity = R.Epic,
        OneInN = 400,
        Type = "Shield",
        Description = "Геометрические лучи расходятся от латунного ядра.",
    },
    ["royal_greatsword"] = {
        Id = "royal_greatsword",
        NameRu = "Королевский двуручник",
        Rarity = R.Epic,
        OneInN = 500,
        Type = "Weapon",
        Description = "Тяжёлый клинок с гравировкой трех корон.",
    },
    ["moss_carved_plate"] = {
        Id = "moss_carved_plate",
        NameRu = "Панцирь древнего треанта",
        Rarity = R.Epic,
        OneInN = 1000,
        Type = "Armor",
        Description = "Окаменевшая кора векового дерева.",
    },

    -- Mythic (1/1 250 .. 1/4 000)
    ["crimson_thorn"] = {
        Id = "crimson_thorn",
        NameRu = "Багровый шип",
        Rarity = R.Mythic,
        OneInN = 1250,
        Type = "Weapon",
        Description = "Остриё из красного янтаря, пульсирующее теплом.",
    },
    ["crown_of_dominion"] = {
        Id = "crown_of_dominion",
        NameRu = "Венец владыки",
        Rarity = R.Mythic,
        OneInN = 2000,
        Type = "Armor",
        Description = "Геометрическая зубчатая корона чистой латуни.",
    },
    ["heartwood_relic"] = {
        Id = "heartwood_relic",
        NameRu = "Сердцевина древа жизни",
        Rarity = R.Mythic,
        OneInN = 2500,
        Type = "Relic",
        Description = "Ядро реликтового леса со светящимся светом внутри.",
    },
    ["celestial_claymore"] = {
        Id = "celestial_claymore",
        NameRu = "Небесный клеймор",
        Rarity = R.Mythic,
        OneInN = 4000,
        Type = "Weapon",
        Description = "Стальной клинок, впитавший цвет вечерней авроры.",
    },

    -- Legendary (1/8 000 .. 1/25 000)
    ["diamond_frost_blade"] = {
        Id = "diamond_frost_blade",
        NameRu = "Ледяной алмазный меч",
        Rarity = R.Legendary,
        OneInN = 8000,
        Type = "Weapon",
        Description = "Гранёный бело-голубой кристалл, сверкающий гранями.",
    },
    ["aegis_of_kings"] = {
        Id = "aegis_of_kings",
        NameRu = "Эгида королей",
        Rarity = R.Legendary,
        OneInN = 20000,
        Type = "Shield",
        Description = "Несокрушимый щит с золотой филигранью и короной.",
    },
    ["aurora_cuirass"] = {
        Id = "aurora_cuirass",
        NameRu = "Кираса северного сияния",
        Rarity = R.Legendary,
        OneInN = 25000,
        Type = "Armor",
        Description = "Прозрачный кристаллический доспех небесного сияния.",
    },

    -- Secret (1/1 500 000 .. 1/2 500 000)
    ["void_nebula_blade"] = {
        Id = "void_nebula_blade",
        NameRu = "Клинок антиматерии",
        Rarity = R.Secret,
        OneInN = 1500000,
        Type = "Relic",
        Description = "Сгусток космической туманности в форме меча.",
    },
    ["shadow_core_relic"] = {
        Id = "shadow_core_relic",
        NameRu = "Тёмное ядро колосса",
        Rarity = R.Secret,
        OneInN = 2000000,
        Type = "Relic",
        Description = "Чёрный дым и фиолетовое холодное свечение.",
    },
    ["eclipse_sovereign"] = {
        Id = "eclipse_sovereign",
        NameRu = "Владыка затмения",
        Rarity = R.Secret,
        OneInN = 2500000,
        Type = "Weapon",
        Description = "Поглощает весь свет в радиусе вокруг себя.",
    },

    -- Absolute (1/10 000 000)
    ["absolute_genesis"] = {
        Id = "absolute_genesis",
        NameRu = "АБСОЛЮТ: ПЕРВОСВЕТ",
        Rarity = R.Absolute,
        OneInN = 10000000,
        Type = "Relic",
        Description = "Чистый сияющий белый свет творения без единой тени.",
    },
}

-- Упорядоченный список для генератора рулетки
local ItemsList: { ItemDef } = {}
for _, item in pairs(Items) do
    table.insert(ItemsList, item)
end
table.sort(ItemsList, function(a, b)
    if a.Rarity ~= b.Rarity then
        return a.Rarity < b.Rarity
    end
    return a.OneInN < b.OneInN
end)

local function getItem(id: string): ItemDef?
    return Items[id]
end

local function getItemsByRarity(rarity: number): { ItemDef }
    local result = {}
    for _, item in ipairs(ItemsList) do
        if item.Rarity == rarity then
            table.insert(result, item)
        end
    end
    return result
end

return {
    Items = Items,
    ItemsList = ItemsList,
    GetItem = getItem,
    GetItemsByRarity = getItemsByRarity,
}
