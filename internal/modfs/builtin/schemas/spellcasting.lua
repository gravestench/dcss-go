-- Casting selection and memorisation delay survive save and restore.
register.component{
    id = "character.spellcasting",
    version = 1,
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
