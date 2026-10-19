-- The selected source spell and rolled HD are part of the summoned actor.
local schema = {
    id = "magic.summon_servitor",
    version = 2,
    -- The servitor keeps its chosen spell and rolled hit dice instead of selecting a new spell each turn.
    fields = {
        spell_id = {
            type = "string",
            default = "",
        },
        hd = {
            type = "int64",
            default = 0,
        },

        -- Monster casters copy their eligible slots once. Parallel arrays
        -- retain source priority even when an overlay adds new spell IDs.
        spell_ids = {
            type = "list<string>",
            default = {},
        },

        frequencies = {
            type = "list<int64>",
            default = {},
        },
    },
}

register.component(schema)

return schema
