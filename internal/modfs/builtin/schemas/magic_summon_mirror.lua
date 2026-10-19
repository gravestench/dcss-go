-- Mirror copies save what body they copied and how much life the spell gave
-- them. Their original may die before a save is restored.
local schema = {
    id = "magic.summon_mirror",
    version = 1,
    fields = {
        origin_kind_id = {
            type = "string",
            default = "",
        },

        hp_percent = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
