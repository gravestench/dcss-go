-- A Demonspawn remembers the highest XL it has reached. Ru may lower the
-- current XL without erasing innate traits; this history makes grant flags
-- verifiable when the character is restored or later regains those levels.
local component = require("constants.component")

local schema = {
    id = component.DEMONSPAWN_ANCESTRY,
    version = 1,
    fields = {
        highest_level = {
            type = "int64",
            default = 1,
        },
    },
}

register.component(schema)

return schema
