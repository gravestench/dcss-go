-- The protected actor owns its persistent guardian link and observed HP.
local schema = {
    id = "magic.summon_bond",
    version = 1,
    -- The protected actor remembers guardian and last observed HP to detect damage for bond reactions.
    fields = {
        guardian = {
            type = "entity",
        },
        observed_hp = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
