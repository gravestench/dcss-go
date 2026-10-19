-- A walking tome's chosen spell belongs to the summoned actor. Save it here
-- so a restored actor casts the same spell even if its owner has died.
local schema = {
    id = "magic.summon_living_spell",
    version = 1,
    fields = {
        spell_id = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema
