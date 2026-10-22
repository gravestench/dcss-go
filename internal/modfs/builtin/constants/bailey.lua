-- Bailey's source gate chooses one weapon theme and one finite lifetime.
-- The same names are used by DES hooks, ECS state, and the destination draw.
local bailey = {
    AXE = "axe",
    POLEARM = "polearm",
    AXE_TAG = "bailey_axe",
    POLEARM_TAG = "bailey_polearm",
    ENTRY_FAMILY = "bailey_entry",
    DESTINATION_FAMILY = "bailey",
    MIN_DURATION_TURNS = 600,
    MAX_DURATION_TURNS = 800,
    DURATION_RANGE_TURNS = 201,
    EXPIRED_MARKER_FLOOR = "stone_arch",
    CLOSURE_NONE = "",
    CLOSURE_ENTRY = "entry",
    CLOSURE_EXPIRY = "expiry",

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

return bailey
