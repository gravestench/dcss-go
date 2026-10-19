local component = require("constants.component")

-- Spell and Chaos sources grant the same actor-owned boons. Separate timers
-- let dispelling, turn aging, and saves agree on the effect's remaining life.
local schema = {
    id = component.MONSTER_BOONS,
    version = 1,
    fields = {
        haste_aut = {
            type = "int64",
            default = 0,
        },

        might_aut = {
            type = "int64",
            default = 0,
        },

        swift_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
