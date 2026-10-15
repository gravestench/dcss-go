-- Chaos duplication creates another ordinary actor, not a spell summon.
local schema = {
    id = "combat.chaos_clone",
    version = 1,
    fields = {
        roster_kind_id = {
            type = "string",
            default = "",
        },

        created_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
