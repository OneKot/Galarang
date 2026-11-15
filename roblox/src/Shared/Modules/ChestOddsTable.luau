--!strict
--[[
    ChestOddsTable.luau
    Порт рулетки сундука из Galarang.Core.ChestOddsTable.
    Основан на 30 000 000 целочисленных делений.
]]

export type ChestItemInput = {
    Id: string,
    Rarity: number,
    OneInN: number,
}

export type ChestRollResult = {
    Id: string,
    Rarity: number,
}

type Entry = {
    Id: string,
    Rarity: number,
    OneInN: number,
    Divisions: number,
}

export type RandomSource = {
    NextInteger: (self: RandomSource, min: number, max: number) -> number,
}

local ChestOddsTable = {}
ChestOddsTable.__index = ChestOddsTable

ChestOddsTable.TotalDivisions = 30000000
ChestOddsTable.RareThreshold = 2 -- Rarity.Rare = 2

function ChestOddsTable.IsRareOrHigher(rarity: number): boolean
    return rarity >= ChestOddsTable.RareThreshold
end

local function Scale(divisions: number, multiplier: number): number
    if multiplier <= 1.0 then
        return divisions
    end
    return math.max(1, math.floor(divisions * multiplier))
end

local function DistributeProportionally(group: { Entry }, pool: number)
    if #group == 0 then
        return
    end

    local groupSum = 0
    for _, e in ipairs(group) do
        groupSum += e.Divisions
    end

    if groupSum <= 0 then
        group[1].Divisions = pool
        return
    end

    local placed = 0
    for _, e in ipairs(group) do
        local share = math.floor(pool * (e.Divisions / groupSum))
        e.Divisions = share
        placed += share
    end

    local leftover = pool - placed
    if leftover > 0 then
        -- Находим элемент с минимальным OneInN (самый частый)
        local anchor = group[1]
        for i = 2, #group do
            if group[i].OneInN < anchor.OneInN then
                anchor = group[i]
            end
        end
        anchor.Divisions += leftover
    end
end

function ChestOddsTable.fromItems(items: { ChestItemInput })
    assert(items ~= nil and #items > 0, "Сектор должен содержать хотя бы один предмет.")

    local entries: { Entry } = {}
    local sum = 0

    for _, item in ipairs(items) do
        local divisions = math.round(ChestOddsTable.TotalDivisions / item.OneInN)
        divisions = math.max(1, divisions)
        table.insert(entries, {
            Id = item.Id,
            Rarity = item.Rarity,
            OneInN = item.OneInN,
            Divisions = divisions,
        })
        sum += divisions
    end

    -- Находим самый частый предмет сектора
    local anchor = entries[1]
    for i = 2, #entries do
        if entries[i].OneInN < anchor.OneInN then
            anchor = entries[i]
        end
    end

    anchor.Divisions += (ChestOddsTable.TotalDivisions - sum)
    assert(anchor.Divisions >= 1, "Шансы сектора не нормализуются: сумма шансов превышает 100%.")

    local self = setmetatable({}, ChestOddsTable)
    self._entries = entries
    return self
end

function ChestOddsTable:BuildEffective(probability: number?, goldenOpening: boolean?): { Entry }
    local prob = probability or 1.0
    if prob ~= prob or prob < 1.0 then -- проверка на NaN или < 1
        prob = 1.0
    end

    local multiplier = prob * (goldenOpening and 10.0 or 1.0)

    local effective: { Entry } = {}
    local rareSum = 0

    for _, e in ipairs(self._entries) do
        local isRare = ChestOddsTable.IsRareOrHigher(e.Rarity)
        local div = isRare and Scale(e.Divisions, multiplier) or e.Divisions
        local entryCopy = {
            Id = e.Id,
            Rarity = e.Rarity,
            OneInN = e.OneInN,
            Divisions = div,
        }
        table.insert(effective, entryCopy)
        if isRare then
            rareSum += div
        end
    end

    if rareSum >= ChestOddsTable.TotalDivisions then
        local remaining = ChestOddsTable.TotalDivisions

        -- Группируем по редкостям от самых редких к менее редким (7 -> 6 -> 5 -> 4 -> 3 -> 2)
        for rarity = 7, ChestOddsTable.RareThreshold, -1 do
            local group: { Entry } = {}
            for _, e in ipairs(effective) do
                if e.Rarity == rarity then
                    table.insert(group, e)
                end
            end

            if #group > 0 then
                -- Сортируем внутри группы по OneInN
                table.sort(group, function(a, b)
                    return a.OneInN < b.OneInN
                end)

                if remaining == 0 then
                    for _, e in ipairs(group) do
                        e.Divisions = 0
                    end
                else
                    local groupSum = 0
                    for _, e in ipairs(group) do
                        groupSum += e.Divisions
                    end

                    if groupSum <= remaining then
                        remaining -= groupSum
                    else
                        DistributeProportionally(group, remaining)
                        remaining = 0
                    end
                end
            end
        end

        -- Обычные и необычные получают 0
        for _, e in ipairs(effective) do
            if not ChestOddsTable.IsRareOrHigher(e.Rarity) then
                e.Divisions = 0
            end
        end
    else
        local commonList: { Entry } = {}
        for _, e in ipairs(effective) do
            if not ChestOddsTable.IsRareOrHigher(e.Rarity) then
                table.insert(commonList, e)
            end
        end
        DistributeProportionally(commonList, ChestOddsTable.TotalDivisions - rareSum)
    end

    return effective
end

function ChestOddsTable:GetEffectiveDivisions(probability: number?, goldenOpening: boolean?): { number }
    local effective = self:BuildEffective(probability, goldenOpening)
    local result = {}
    for i, e in ipairs(effective) do
        result[i] = e.Divisions
    end
    return result
end

function ChestOddsTable:Roll(randomSource: RandomSource?, probability: number?, goldenOpening: boolean?): ChestRollResult
    local effective = self:BuildEffective(probability, goldenOpening)
    
    local rollNumber: number
    if randomSource ~= nil then
        rollNumber = randomSource:NextInteger(0, ChestOddsTable.TotalDivisions - 1)
    else
        rollNumber = math.random(0, ChestOddsTable.TotalDivisions - 1)
    end

    local cumulative = 0
    for _, e in ipairs(effective) do
        if e.Divisions > 0 then
            cumulative += e.Divisions
            if rollNumber < cumulative then
                return {
                    Id = e.Id,
                    Rarity = e.Rarity,
                }
            end
        end
    end

    error("Рулетка покрывает диапазон не полностью — проверьте нормализацию шансов.")
end

return ChestOddsTable
