using System;
using System.Collections.Generic;
using System.Linq;

namespace Galarang.Core
{
    /// <summary>
    /// Рулетка сундука по документу «GaLa RNG — баланс и формулы», раздел 3.
    /// Все шансы сектора в сумме дают ровно <see cref="TotalDivisions"/> делений,
    /// бросок — одно число в [0; TotalDivisions).
    /// Вероятность умножает шансы предметов от Редкого и выше; Обычные и Необычные
    /// делят остаток в прежних пропорциях. Если редкие занимают больше 100% —
    /// полностью ставятся самые редкие, Редкие урезаются, Обычные и Необычные
    /// не выпадают. Остаток от округления забирает самый частый предмет сектора.
    /// </summary>
    public sealed class ChestOddsTable
    {
        public const long TotalDivisions = 30_000_000;

        sealed class Entry
        {
            public string Id;
            public Rarity Rarity;
            public long OneInN;
            public long Divisions;
        }

        readonly List<Entry> _entries;

        ChestOddsTable(List<Entry> entries)
        {
            _entries = entries;
        }

        public int Count => _entries.Count;

        public static bool IsRareOrHigher(Rarity rarity) => rarity >= Rarity.Rare;

        public static ChestOddsTable FromOneInN(IReadOnlyList<ChestItem> items)
        {
            if (items == null) throw new ArgumentNullException(nameof(items));
            if (items.Count == 0)
                throw new ArgumentException("Сектор должен содержать хотя бы один предмет.", nameof(items));

            var entries = new List<Entry>(items.Count);
            foreach (var item in items)
            {
                long divisions = (long)Math.Round(TotalDivisions / (double)item.OneInN, MidpointRounding.AwayFromZero);
                entries.Add(new Entry
                {
                    Id = item.Id,
                    Rarity = item.Rarity,
                    OneInN = item.OneInN,
                    Divisions = Math.Max(1, divisions),
                });
            }

            long sum = 0;
            foreach (var e in entries) sum += e.Divisions;

            var anchor = entries.OrderBy(e => e.OneInN).First();
            anchor.Divisions += TotalDivisions - sum;

            if (anchor.Divisions < 1)
                throw new InvalidOperationException(
                    $"Шансы сектора не нормализуются к {TotalDivisions}: сумма шансов превышает 100%.");

            return new ChestOddsTable(entries);
        }

        /// <summary>
        /// Эффективные деления каждого предмета после применения Вероятности и Золотого
        /// открытия, в порядке добавления. Массив для тестов и серверной валидации.
        /// </summary>
        public long[] GetEffectiveDivisions(double probability = 1.0, bool goldenOpening = false)
        {
            var effective = BuildEffective(probability, goldenOpening);
            var result = new long[effective.Count];
            for (int i = 0; i < effective.Count; i++)
                result[i] = effective[i].Divisions;
            return result;
        }

        public ChestRoll Roll(IRandomSource random, double probability = 1.0, bool goldenOpening = false)
        {
            if (random == null) throw new ArgumentNullException(nameof(random));

            var effective = BuildEffective(probability, goldenOpening);
            long roll = random.NextLong(TotalDivisions);

            long cumulative = 0;
            foreach (var e in effective)
            {
                if (e.Divisions <= 0) continue;
                cumulative += e.Divisions;
                if (roll < cumulative)
                    return new ChestRoll(e.Id, e.Rarity);
            }

            throw new InvalidOperationException("Рулетка покрывает диапазон не полностью — проверьте нормализацию шансов.");
        }

        List<Entry> BuildEffective(double probability, bool goldenOpening)
        {
            if (double.IsNaN(probability) || probability < 1.0)
                probability = 1.0;
            double multiplier = probability * (goldenOpening ? 10.0 : 1.0);

            var effective = _entries.Select(e => new Entry
            {
                Id = e.Id,
                Rarity = e.Rarity,
                OneInN = e.OneInN,
                Divisions = IsRareOrHigher(e.Rarity) ? Scale(e.Divisions, multiplier) : e.Divisions,
            }).ToList();

            long rareSum = 0;
            foreach (var e in effective)
                if (IsRareOrHigher(e.Rarity)) rareSum += e.Divisions;

            if (rareSum >= TotalDivisions)
            {
                long remaining = TotalDivisions;
                foreach (var group in effective
                             .Where(e => IsRareOrHigher(e.Rarity))
                             .GroupBy(e => e.Rarity)
                             .OrderByDescending(g => (int)g.Key))
                {
                    var list = group.OrderBy(e => e.OneInN).ToList();
                    if (remaining == 0)
                    {
                        foreach (var e in list) e.Divisions = 0;
                        continue;
                    }

                    long groupSum = 0;
                    foreach (var e in list) groupSum += e.Divisions;

                    if (groupSum <= remaining)
                    {
                        remaining -= groupSum;
                    }
                    else
                    {
                        DistributeProportionally(list, remaining);
                        remaining = 0;
                    }
                }

                foreach (var e in effective)
                    if (!IsRareOrHigher(e.Rarity)) e.Divisions = 0;
            }
            else
            {
                var commonList = effective.Where(e => !IsRareOrHigher(e.Rarity)).ToList();
                DistributeProportionally(commonList, TotalDivisions - rareSum);
            }

            return effective;
        }

        static long Scale(long divisions, double multiplier)
        {
            if (multiplier <= 1.0) return divisions;
            return Math.Max(1, (long)Math.Floor(divisions * multiplier));
        }

        static void DistributeProportionally(List<Entry> group, long pool)
        {
            if (group.Count == 0) return;

            long groupSum = 0;
            foreach (var e in group) groupSum += e.Divisions;

            if (groupSum <= 0)
            {
                group[0].Divisions = pool;
                return;
            }

            long placed = 0;
            foreach (var e in group)
            {
                long share = (long)Math.Floor(pool * (e.Divisions / (double)groupSum));
                e.Divisions = share;
                placed += share;
            }

            long leftover = pool - placed;
            if (leftover > 0)
            {
                var anchor = group.OrderBy(e => e.OneInN).First();
                anchor.Divisions += leftover;
            }
        }
    }
}
