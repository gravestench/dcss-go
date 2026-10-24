-- A Kiku wretch is a real corpse-bearing monster, not a summon. Its short
-- remaining lifetime is saved with the actor so a restored game cannot
-- silently turn a dying offering into a permanent monster.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_KIKU_WRETCH,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
