-- Source: ATTR_TEMP_MUT_XP is one player attribute shared by every
-- temporary mutation, regardless of mutation ID.
local schema = {
    id = "character.mutation_timer",
    version = 1,
    fields = {
        remaining_xp = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
