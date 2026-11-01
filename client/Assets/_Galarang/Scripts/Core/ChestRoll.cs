namespace Galarang.Core
{
    /// <summary>Результат одного броска рулетки сундука.</summary>
    public readonly struct ChestRoll
    {
        public readonly string ItemId;
        public readonly Rarity Rarity;

        public ChestRoll(string itemId, Rarity rarity)
        {
            ItemId = itemId;
            Rarity = rarity;
        }
    }
}
