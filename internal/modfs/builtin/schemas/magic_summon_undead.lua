-- Derived undead retain the source monster's attacks and hit dice.
local schema = {
    id = "magic.summon_undead",
    version = 1,
    -- Base kind ID supplies the original monster attacks and hit dice for a derived undead form.
    fields = {
        base_kind_id = { type = "string", default = "" },
    },
}

register.component(schema)

return schema
