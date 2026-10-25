-- These are the pinned source's spatial scales and layout identities.
-- Keep the vocabulary in one place so Lua systems, generation, and mods
-- speak about the same 80x70 moving window and independent morph clock.
local abyss = {
    -- Ordinary branch floors use numeric_id * 100 + depth. Keep these
    -- permanent regions above that namespace so Slime:1 cannot alias the
    -- transit region when a saved branch stair is validated.
    LEVEL_ID = 1000000000,
    TRANSIT_LEVEL_ID = 1000000001,
    WIDTH = 80,
    HEIGHT = 70,
    CENTRE_X = 40,
    CENTRE_Y = 35,
    SHIFT_RADIUS = 10,
    SHIFT_MARGIN = 12,
    SESSION_STATE = "abyss",
    VAULT_FAMILY = "abyss",

    EXIT_BASE_CHANCE = 7250,
    EXIT_DEPTH_STEP = 1250,
    EXIT_DEPTH_CAP = 5,
    STAIR_CHANCE = 1750,
    EXIT_XP_COST = 10,
    SHIFT_MONSTERS_BASE = 15,
    POCKET_ALTAR_RADIUS = 8,
    PROTO_RADIUS = 8,
    PROTO_FALLOFF = 0.98,
    PROTO_CHANCE_SCALE = 255,
    RUNE_MIN_DEPTH = 3,
    RUNE_MAX_ROLL = 60,
    RUNE_CHANCE_BASE = 100,
    RUNE_CHANCE_DIVISOR = 6,

    MORPH_SPEED_BONUS = 40,
    MORPH_SPEED_DIVISOR = 200,
    MORPH_DEFAULT_MULTIPLIER = 2,
    MORPH_PHASE_DIVISOR = 100,
    MORPH_BASE_RATE = 0.2,
    MORPH_WAVE_RATE = 2.8,
    MORPH_WAVE_POWER = 10,

    WASTES_LIMIT = 0x7FFFFFF,
    WORLEY_OFFSET_SCALE = 5000,
    WORLEY_BASE_SCALE = 5.0,
    WORLEY_COMPLEX_SCALE = 6.1,
    ROILING_SEED_A = 8675309,
    ROILING_SEED_B = 7654321,
    ROILING_SEED_C = 24324,
    ROILING_SEED_D = 24816,
    NEW_ABYSS_SEED = 7629,
    RIVER_SEED = 1800,
    BASE_WORLEY_SEED = 314159,
    MIXED_WORLEY_SEED = 4321,
    REGULAR_WORLEY_SEED = 123456,
    COMPLEX_WORLEY_SEED = 23571113,
    STATIC_CHANGE = 4096,
}

return abyss
