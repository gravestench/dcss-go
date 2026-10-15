-- One entity per player/spell pair. This is the authoritative library,
-- knowledge, and future innate schedule for a run.
register.component{
    id = "character.spell",
    version = 1,
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
