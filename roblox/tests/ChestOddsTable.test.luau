--!strict
--[[
    ChestOddsTable.test.luau
    Автономный тестовый раннер для проверки математического ядра рулетки в Luau CLI.
]]

local ChestOddsTable = require("../src/Shared/Modules/ChestOddsTable")

local function assertEqual(actual: any, expected: any, msg: string?)
    if actual ~= expected then
        error(string.format("ASSERTION FAILED: expected %s, got %s. %s", tostring(expected), tostring(actual), msg or ""), 2)
    end
end

local function assertTrue(condition: boolean, msg: string?)
    if not condition then
        error(string.format("ASSERTION FAILED: expected true. %s", msg or ""), 2)
    end
end

local function makeFirstSector()
    local items = {
        { Id = "c1", Rarity = 0, OneInN = 4 },
        { Id = "c2", Rarity = 0, OneInN = 5 },
        { Id = "c3", Rarity = 0, OneInN = 8 },
        { Id = "c4", Rarity = 0, OneInN = 10 },
        { Id = "u1", Rarity = 1, OneInN = 12 },
        { Id = "u2", Rarity = 1, OneInN = 15 },
        { Id = "u3", Rarity = 1, OneInN = 20 },
        { Id = "u4", Rarity = 1, OneInN = 30 },
        { Id = "u5", Rarity = 1, OneInN = 40 },
        { Id = "r1", Rarity = 2, OneInN = 60 },
        { Id = "r2", Rarity = 2, OneInN = 75 },
        { Id = "r3", Rarity = 2, OneInN = 100 },
        { Id = "r4", Rarity = 2, OneInN = 150 },
        { Id = "r5", Rarity = 2, OneInN = 200 },
        { Id = "e1", Rarity = 3, OneInN = 250 },
        { Id = "e2", Rarity = 3, OneInN = 300 },
        { Id = "e3", Rarity = 3, OneInN = 400 },
        { Id = "e4", Rarity = 3, OneInN = 500 },
        { Id = "e5", Rarity = 3, OneInN = 1000 },
        { Id = "m1", Rarity = 4, OneInN = 1250 },
        { Id = "m2", Rarity = 4, OneInN = 2000 },
        { Id = "m3", Rarity = 4, OneInN = 2500 },
        { Id = "m4", Rarity = 4, OneInN = 4000 },
        { Id = "l1", Rarity = 5, OneInN = 8000 },
        { Id = "l2", Rarity = 5, OneInN = 20000 },
        { Id = "l3", Rarity = 5, OneInN = 25000 },
        { Id = "s1", Rarity = 6, OneInN = 1500000 },
        { Id = "s2", Rarity = 6, OneInN = 2000000 },
        { Id = "s3", Rarity = 6, OneInN = 2500000 },
        { Id = "a1", Rarity = 7, OneInN = 10000000 },
    }
    return ChestOddsTable.fromItems(items)
end

print(">>> Запуск тестов ChestOddsTable (Luau)...")

-- Тест 1: Сумма делений ровно 30 000 000
do
    local tableObj = makeFirstSector()
    local divs = tableObj:GetEffectiveDivisions()
    local sum = 0
    for _, d in ipairs(divs) do
        sum += d
    end
    assertEqual(sum, ChestOddsTable.TotalDivisions, "Сумма делений должна быть ровно 30 000 000")
    print("  [PASS] Test 1: SumOfDivisionsIsExactlyTotal")
end

-- Тест 2: Проверка точных делений известных шансов
do
    local tableObj = makeFirstSector()
    local divs = tableObj:GetEffectiveDivisions()
    assertEqual(divs[1], 7500000, "c1 (1/4) должен быть 7 500 000")
    assertEqual(divs[4], 3000000, "c4 (1/10) должен быть 3 000 000")
    assertEqual(divs[30], 3, "a1 (1/10M) должен быть 3 деления")
    print("  [PASS] Test 2: KnownOddsMapToExactDivisions")
end

-- Тест 3: Вероятность x2 умножает редкие предметы
do
    local tableObj = makeFirstSector()
    local baseDivs = tableObj:GetEffectiveDivisions(1.0)
    local x2Divs = tableObj:GetEffectiveDivisions(2.0)
    
    -- r1 (индекс 10) редкий — должен удвоиться
    assertEqual(x2Divs[10], baseDivs[10] * 2, "Редкий предмет r1 должен удвоиться при x2")
    -- c1 (индекс 1) обычный — должен уменьшиться, отдавая деления редким
    assertTrue(x2Divs[1] < baseDivs[1], "Обычный предмет c1 должен уменьшиться в делениях")
    
    -- Но общая сумма делений ВСЕГДА 30 000 000
    local sum = 0
    for _, d in ipairs(x2Divs) do
        sum += d
    end
    assertEqual(sum, ChestOddsTable.TotalDivisions, "Сумма делений при x2 должна быть 30 000 000")
    print("  [PASS] Test 3: ProbabilityMultiplierScalesRares")
end

-- Тест 4: Золотое открытие (10x множитель)
do
    local tableObj = makeFirstSector()
    local goldenDivs = tableObj:GetEffectiveDivisions(1.0, true)
    local sum = 0
    for _, d in ipairs(goldenDivs) do
        sum += d
    end
    assertEqual(sum, ChestOddsTable.TotalDivisions, "Сумма делений при золотом открытии должна быть 30 000 000")
    print("  [PASS] Test 4: GoldenOpeningMultiplier")
end

-- Тест 5: Экстремальная удача (переполнение редких > 100%)
do
    local tableObj = makeFirstSector()
    -- При удаче x1000 редкие предметы займут больше 100%
    local superDivs = tableObj:GetEffectiveDivisions(1000.0)
    local sum = 0
    for _, d in ipairs(superDivs) do
        sum += d
    end
    assertEqual(sum, ChestOddsTable.TotalDivisions, "Сумма делений при гипер-удаче должна оставаться 30 000 000")
    -- Обычные и необычные должны стать строго 0
    for i = 1, 9 do
        assertEqual(superDivs[i], 0, string.format("Обычный/необычный предмет %d должен получить 0 делений", i))
    end
    print("  [PASS] Test 5: Over100PercentRareSaturationHandling")
end

-- Тест 6: Монте-Карло симуляция бросков (100 000 роллов)
do
    local tableObj = makeFirstSector()
    local pseudoRng = {
        _counter = 0,
        NextInteger = function(self, min, max)
            return math.random(min, max)
        end
    }

    local rolls = 100000
    local hitsByRarity = {}
    for r = 0, 7 do
        hitsByRarity[r] = 0
    end

    math.randomseed(12345)
    for _ = 1, rolls do
        local result = tableObj:Roll(pseudoRng, 1.0, false)
        hitsByRarity[result.Rarity] += 1
    end

    -- Большинство роллов должны быть Common (0) и Uncommon (1)
    local commonAndUncommon = hitsByRarity[0] + hitsByRarity[1]
    assertTrue(commonAndUncommon > 90000, "Common и Uncommon должны составлять свыше 90% бросков")
    -- Редкие выпали
    assertTrue(hitsByRarity[2] > 0, "Rare предметы должны были выпасть")
    
    print(string.format("  [PASS] Test 6: MonteCarlo100kRolls (Common+Uncommon: %.2f%%, Rare+: %.2f%%)",
        (commonAndUncommon / rolls) * 100, ((rolls - commonAndUncommon) / rolls) * 100))
end

print(">>> ВСЕ ТЕСТЫ УСПЕШНО ПРОЙДЕНЫ! (6/6 tests passed)")
