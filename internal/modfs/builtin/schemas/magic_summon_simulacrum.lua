-- A derived simulacrum retains the species it copied before its target died.
local schema = {
    id = "magic.summon_simulacrum",
    version = 1,
    -- Base kind ID lets a simulacrum retain the copied monster traits after its source is gone.
    fields = {
        base_kind_id = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema
