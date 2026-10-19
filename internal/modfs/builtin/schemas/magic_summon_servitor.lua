-- The selected source spell and rolled HD are part of the summoned actor.
local schema = {
    id = "magic.summon_servitor",
    version = 1,
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
    },
}

register.component(schema)

return schema
