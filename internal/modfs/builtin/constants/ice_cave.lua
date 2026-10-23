-- Ice Cave's source gate and destination agree on these saved values.
local ice_cave = {
    ENTRY_FAMILY = "ice_cave_entry",
    DESTINATION_FAMILY = "ice_cave",
    EXPIRED_MARKER_FLOOR = "expired_portal",
    CLOSURE_NONE = "",
    CLOSURE_ENTRY = "entry",
    CLOSURE_EXPIRY = "expiry",

    EARLIEST_DUNGEON_DEPTH = 11,
    HARD_DUNGEON_DEPTH = 14,

    MIN_DURATION_TURNS = 600,
    MAX_DURATION_TURNS = 800,
    DURATION_RANGE_TURNS = 201,

    FIRST_NOTICE_AUT = 500,
    LONG_NOTICE_AUT = 500,
    SHORT_NOTICE_AUT = 250,
    SHORT_NOTICE_BELOW_AUT = 900,
    FINAL_WARNING_AUT = 100,

    FAINT_ABOVE_AUT = 5000,
    PLAIN_ABOVE_AUT = 4000,
    STEADY_ABOVE_AUT = 2500,
    QUICK_ABOVE_AUT = 1500,

    MAX_HEARING_DISTANCE = 999,
    VERY_DISTANT_AT = 28,
    DISTANT_AT = 21,
    NEARBY_AT = 14,
    VERY_NEARBY_AT = 7,
}

return ice_cave
