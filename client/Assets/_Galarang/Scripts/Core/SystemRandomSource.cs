using System;

namespace Galarang.Core
{
    /// <summary>Источник случайности на System.Random с отсечением (rejection sampling) —
    /// равномерное распределение без смещения.</summary>
    public sealed class SystemRandomSource : IRandomSource
    {
        readonly Random _random;

        public SystemRandomSource(int? seed = null)
        {
            _random = seed.HasValue ? new Random(seed.Value) : new Random();
        }

        public long NextLong(long maxExclusive)
        {
            if (maxExclusive <= 0)
                throw new ArgumentOutOfRangeException(nameof(maxExclusive), "Диапазон должен быть положительным.");

            ulong range = (ulong)maxExclusive;
            ulong limit = ulong.MaxValue - (ulong.MaxValue % range);
            var buffer = new byte[sizeof(ulong)];

            while (true)
            {
                _random.NextBytes(buffer);
                ulong value = BitConverter.ToUInt64(buffer, 0);
                if (value < limit)
                    return (long)(value % range);
            }
        }
    }
}
