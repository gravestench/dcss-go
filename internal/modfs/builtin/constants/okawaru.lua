-- Shared source parameters for Okawaru's three active abilities. Keeping
-- names here lets ability modules and status owners agree without a switch.
return {
    HEROISM_RANK = 1,
    HEROISM_MP = 2,
    HEROISM_PIETY = 1,
    HEROISM_FAIL_BASE = 30,
    HEROISM_FAIL_SCALE = 6,
    HEROISM_FAIL_PIETY = 20,

    FINESSE_RANK = 4,
    FINESSE_MP = 5,
    FINESSE_PIETY = 3,
    FINESSE_FAIL_BASE = 60,
    FINESSE_FAIL_SCALE = 4,
    FINESSE_FAIL_PIETY = 25,

    DUEL_RANK = 5,
    DUEL_MP = 7,
    DUEL_PIETY = 10,
    DUEL_FAIL_BASE = 80,
    DUEL_FAIL_SCALE = 4,
    DUEL_FAIL_PIETY = 20,

    STATUS_BASE_TURNS = 10,
    STATUS_CAP_AUT = 1000,
    HEROISM_SKILL_BONUS = 5,
    DUEL_RETURN_MIN_TURNS = 15,
    DUEL_RETURN_SPAN_TURNS = 11,
}
