-- A protected monster keeps its original protector and remaining bond time.
-- Source: mon-ench.cc:ENCH_INJURY_BOND and monster.cc:monster::hurt.
local component = require("constants.component")

local schema = {
    id = component.MONSTER_INJURY_BOND,
    version = 1,
    fields = {
        protector = {
            type = "entity",
        },

        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
