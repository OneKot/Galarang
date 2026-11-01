using System;
using System.Collections.Generic;
using System.Linq;
using NUnit.Framework;

namespace Galarang.Core.Tests
{
    public class ChestOddsTableTests
    {
        const int Rolls = 200_000;

        /// <summary>Первый сектор из «баланса и формул», раздел 3 — 30 предметов.</summary>
        static ChestOddsTable FirstSector()
        {
            var items = new List<ChestItem>
            {
                new("c1", Rarity.Common, 4),
                new("c2", Rarity.Common, 5),
                new("c3", Rarity.Common, 8),
                new("c4", Rarity.Common, 10),
                new("u1", Rarity.Uncommon, 12),
                new("u2", Rarity.Uncommon, 15),
                new("u3", Rarity.Uncommon, 20),
                new("u4", Rarity.Uncommon, 30),
                new("u5", Rarity.Uncommon, 40),
                new("r1", Rarity.Rare, 60),
                new("r2", Rarity.Rare, 75),
                new("r3", Rarity.Rare, 100),
                new("r4", Rarity.Rare, 150),
                new("r5", Rarity.Rare, 200),
                new("e1", Rarity.Epic, 250),
                new("e2", Rarity.Epic, 300),
                new("e3", Rarity.Epic, 400),
                new("e4", Rarity.Epic, 500),
                new("e5", Rarity.Epic, 1000),
                new("m1", Rarity.Mythic, 1250),
                new("m2", Rarity.Mythic, 2000),
                new("m3", Rarity.Mythic, 2500),
                new("m4", Rarity.Mythic, 4000),
                new("l1", Rarity.Legendary, 8000),
                new("l2", Rarity.Legendary, 20000),
                new("l3", Rarity.Legendary, 25000),
                new("s1", Rarity.Secret, 1_500_000),
                new("s2", Rarity.Secret, 2_000_000),
                new("s3", Rarity.Secret, 2_500_000),
                new("a1", Rarity.Absolute, 10_000_000),
            };
            return ChestOddsTable.FromOneInN(items);
        }

        static double Bucket(IRandomSource rng, ChestOddsTable table,
            Func<Rarity, bool> filter, double probability = 1.0, bool golden = false)
        {
            int hits = 0;
            for (int i = 0; i < Rolls; i++)
            {
                var roll = table.Roll(rng, probability, golden);
                if (filter(roll.Rarity)) hits++;
            }
            return hits / (double)Rolls;
        }

        [Test]
        public void Build_SumOfDivisionsIsExactlyTotal()
        {
            var table = FirstSector();
            Assert.AreEqual(ChestOddsTable.TotalDivisions, table.GetEffectiveDivisions().Sum());
        }

        [Test]
        public void Build_KnownOddsMapToExactDivisions()
        {
            var table = FirstSector();
            var divisions = table.GetEffectiveDivisions();

            Assert.AreEqual(7_500_000, divisions[0]);  // c1, 1 к 4
            Assert.AreEqual(3_000_000, divisions[3]);  // c4, 1 к 10
            Assert.AreEqual(3, divisions[29]);         // a1, АБСОЛЮТ 1 к 10 000 000
        }

        [Test]
        public void Roll_WithoutLuck_CommonBucketMatchesDesign()
        {
            var table = FirstSector();
            var rng = new SystemRandomSource(1234);

            double commonOnly = Bucket(rng, table, r => r == Rarity.Common);
            double uncommon = Bucket(rng, table, r => r == Rarity.Uncommon);

            Assert.AreEqual(0.675, commonOnly, 0.015);
            Assert.AreEqual(0.258, uncommon, 0.012);
        }

        [Test]
        public void Roll_LuckDoubles_RareBucketDoubles()
        {
            var table = FirstSector();
            var rng = new SystemRandomSource(5678);

            double rareAndAbove = Bucket(rng, table, ChestOddsTable.IsRareOrHigher, probability: 2.0);

            Assert.AreEqual(0.1333, rareAndAbove, 0.010);
        }

        [Test]
        public void Roll_GoldenOpening_RareBucketScalesTenfold()
        {
            var table = FirstSector();
            var rng = new SystemRandomSource(9012);

            double rareAndAbove = Bucket(rng, table, ChestOddsTable.IsRareOrHigher, golden: true);

            Assert.AreEqual(0.6665, rareAndAbove, 0.015);
        }

        [Test]
        public void Roll_GoldenAtMaxLuck_NoCommonOrUncommon()
        {
            var table = FirstSector();
            var rng = new SystemRandomSource(3456);

            for (int i = 0; i < 20_000; i++)
            {
                var roll = table.Roll(rng, probability: 3.5, goldenOpening: true);
                Assert.IsTrue(ChestOddsTable.IsRareOrHigher(roll.Rarity),
                    $"Выпал {roll.Rarity}, хотя редкие заняли весь сектор.");
            }
        }

        [Test]
        public void Roll_AlwaysReturnsConfiguredItem()
        {
            var table = FirstSector();
            var rng = new SystemRandomSource(7890);
            var known = new[]
            {
                "c1", "c2", "c3", "c4", "u1", "u2", "u3", "u4", "u5",
                "r1", "r2", "r3", "r4", "r5", "e1", "e2", "e3", "e4", "e5",
                "m1", "m2", "m3", "m4", "l1", "l2", "l3",
                "s1", "s2", "s3", "a1",
            }.ToHashSet();

            for (int i = 0; i < 20_000; i++)
            {
                var roll = table.Roll(rng, probability: 3.5, goldenOpening: true);
                Assert.IsTrue(known.Contains(roll.ItemId), $"Неизвестный предмет: {roll.ItemId}");
            }
        }

        [Test]
        public void Roll_SameSeedProducesSameSequence()
        {
            var table = FirstSector();
            var a = new SystemRandomSource(42);
            var b = new SystemRandomSource(42);

            for (int i = 0; i < 1_000; i++)
                Assert.AreEqual(table.Roll(a).ItemId, table.Roll(b).ItemId);
        }

        [Test]
        public void FromOneInN_RejectsInvalidInput()
        {
            Assert.Throws<ArgumentException>(() => ChestOddsTable.FromOneInN(new List<ChestItem>()));
            Assert.Throws<ArgumentOutOfRangeException>(() =>
                ChestOddsTable.FromOneInN(new List<ChestItem> { new("x", Rarity.Common, 0) }));
        }
    }
}
