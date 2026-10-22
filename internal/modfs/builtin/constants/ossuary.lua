-- Ossuary entrance and destination rules share these source values.
-- The timed clock, DES hook, and save validator must use one definition.
local ossuary = {
    ENTRY_FAMILY = "ossuary_entry",
    DESTINATION_FAMILY = "ossuary",
    EXPIRED_MARKER_FLOOR = "expired_portal",

    MIN_DURATION_TURNS = 600,
    MAX_DURATION_TURNS = 800,
    DURATION_RANGE_TURNS = 201,

    FIRST_NOTICE_AUT = 500,
    LONG_NOTICE_AUT = 500,
    SHORT_NOTICE_AUT = 250,
    SHORT_NOTICE_BELOW_AUT = 900,
    FINAL_WARNING_AUT = 100,

    SLOW_ABOVE_AUT = 5000,
    ORDINARY_ABOVE_AUT = 4000,
    BRISK_ABOVE_AUT = 2500,
    QUICK_ABOVE_AUT = 1500,

    MAX_HEARING_DISTANCE = 999,
    VERY_DISTANT_AT = 28,
    DISTANT_AT = 21,
    NEARBY_AT = 14,
    VERY_NEARBY_AT = 7,
}

return ossuary
