namespace Galarang.Core
{
    /// <summary>Источник случайности рулетки. Абстракция — для детерминированных тестов
    /// и будущей серверной валидации (бросок должен происходить на сервере).</summary>
    public interface IRandomSource
    {
        /// <summary>Равномерное целое в диапазоне [0, maxExclusive).</summary>
        long NextLong(long maxExclusive);
    }
}
