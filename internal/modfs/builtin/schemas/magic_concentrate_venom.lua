local tactical = require("constants.monster_tactical")

-- The recipient keeps the curare conversion until its source enchant fades.
local schema = {
    id = tactical.CONCENTRATE_VENOM,
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
