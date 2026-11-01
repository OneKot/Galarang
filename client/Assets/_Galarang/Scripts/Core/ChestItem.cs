using System;

namespace Galarang.Core
{
    /// <summary>Предмет сектора с его шансом выпадения в формате «1 к N».</summary>
    public readonly struct ChestItem : IEquatable<ChestItem>
    {
        public readonly string Id;
        public readonly Rarity Rarity;
        public readonly long OneInN;

        public ChestItem(string id, Rarity rarity, long oneInN)
        {
            if (string.IsNullOrWhiteSpace(id))
                throw new ArgumentException("Id предмета не должен быть пустым.", nameof(id));
            if (oneInN <= 0)
                throw new ArgumentOutOfRangeException(nameof(oneInN), "Шанс «1 к N» требует N > 0.");

            Id = id;
            Rarity = rarity;
            OneInN = oneInN;
        }

        public bool Equals(ChestItem other) => Id == other.Id;
        public override bool Equals(object obj) => obj is ChestItem other && Equals(other);
        public override int GetHashCode() => Id.GetHashCode();
    }
}
