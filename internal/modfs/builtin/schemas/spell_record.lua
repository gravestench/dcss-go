-- One entity per player/spell pair. This is the authoritative library,
-- knowledge, and future innate schedule for a run.
register.component{
    id = "character.spell",
    version = 2,
    -- Library, learned slot, letter slot, and future level share one authoritative player-spell record.
    fields = {
        owner = {
            type = "entity",
        },

        spell_id = {
            type = "string",
            default = "",
        },

        in_library = {
            type = "bool",
            default = false,
        },

        -- A temporary god offer shares this record with later book knowledge.
        offered_by = {
            type = "string",
            default = "",
        },

        known_slot = {
            type = "int64",
            default = 0,
        },

        letter_slot = {
            type = "int64",
            default = 0,
        },

        future_level = {
            type = "int64",
            default = 0,
        },
    },
}
