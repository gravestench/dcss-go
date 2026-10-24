-- Shared source parameters for Kiku's two recurring active powers. Keeping
-- costs and clocks in one named table lets ability, actor, and tests discuss
-- the same rule without unexplained numeric literals.
return {
    WRETCH_RANK = 1,
    WRETCH_MP = 3,
    WRETCH_PIETY = 4,
    WRETCH_FAIL_BASE = 40,
    WRETCH_FAIL_SCALE = 5,
    WRETCH_FAIL_PIETY = 20,
    WRETCH_RADIUS = 2,
    WRETCH_MIN_COUNT = 2,
    WRETCH_COUNT_SKILL_DIVISOR = 27,
    WRETCH_MIN_LIFE_AUT = 20,
    WRETCH_LIFE_SPAN_AUT = 10,
    WRETCH_PARALYSIS_AUT = 9999,

    TORMENT_RANK = 5,
    TORMENT_MP = 4,
    TORMENT_PIETY = 8,
    TORMENT_FAIL_BASE = 60,
    TORMENT_FAIL_SCALE = 5,
    TORMENT_FAIL_PIETY = 20,
}
