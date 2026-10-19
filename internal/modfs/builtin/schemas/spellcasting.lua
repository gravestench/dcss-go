-- Casting selection and memorisation delay survive save and restore.
register.component{
    id = "character.spellcasting",
    version = 1,
    -- The last spell choice is separate from an unfinished memorisation delay.
    fields = {
        last_spell_id = {
            type = "string",
            default = "",
        },

        learning_spell_id = {
            type = "string",
            default = "",
        },

        learning_remaining = {
            type = "int64",
            default = 0,
        },
    },
}
