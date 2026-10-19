-- Chaos duplication creates another ordinary actor, not a spell summon.
local schema = {
    id = "combat.chaos_clone",
    version = 1,
    -- Record the copied roster kind and creation time so a chaos duplicate remains distinguishable from its source.
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
