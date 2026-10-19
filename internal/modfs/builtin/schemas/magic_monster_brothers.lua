local component = require("constants.component")

-- The source limits a berserker to two Brothers in Arms before Rage clears
-- the count. Store it on that caster so a reload cannot reset the limit.
local schema = {
    id = component.MONSTER_BROTHERS,
    version = 1,
    fields = {
        count = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
