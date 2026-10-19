local component = require("constants.component")

-- Word of Recall is a delayed monster action. Save both the chant and its
-- breath cooldown so loading cannot repeat or skip the reinforcement call.
local schema = {
    id = component.MONSTER_RECALL,
    version = 1,
    fields = {
        foe = {
            type = "entity",
        },
        chant_aut = {
            type = "int64",
            default = 0,
        },
        breath_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
