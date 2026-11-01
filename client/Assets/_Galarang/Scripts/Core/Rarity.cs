namespace Galarang.Core
{
    /// <summary>Редкости по концепции. Порядок = возрастание редкости.
    /// Цвет фона ячейки: серый, зелёный, синий, фиолетовый, красный, жёлтый, чёрный, белый.</summary>
    public enum Rarity : byte
    {
        Common = 0,
        Uncommon = 1,
        Rare = 2,
        Epic = 3,
        Mythic = 4,
        Legendary = 5,
        Secret = 6,
        Absolute = 7,
    }
}
