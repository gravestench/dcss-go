-- Source Sewer timing and hearing bands belong to this one portal domain.
-- Named values keep generation, the ECS clock, warnings, and restore in
-- agreement without copying the source numbers through unrelated files.
local sewer = {
    ENTRY_FAMILY = "sewer_entry",
    DESTINATION_FAMILY = "sewer",
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

    -- player_can_hear defaults to 999 cells; the smaller thresholds below
    -- change wording, not whether the sound reaches the player.
    MAX_HEARING_DISTANCE = 999,
    VERY_DISTANT_AT = 28,
    DISTANT_AT = 21,
    NEARBY_AT = 14,
    VERY_NEARBY_AT = 7,
}

return sewer
