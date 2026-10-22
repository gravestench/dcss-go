-- Fedhas changes a plant's real attitude after it acts. The change belongs
-- to that monster, so an off-level plant keeps its allegiance across saves.
local attitudes = require("constants.attitude")
local component = require("constants.component")

local schema = {
    id = component.FEDHAS_PLANT,
    version = 1,
    fields = {
        attitude = {
            type = "string",
            default = attitudes.HOSTILE,
        },

        -- Source MF_ATT_CHANGE_ATTEMPT prevents repeated conversion on
        -- every turn. Desertion clears it so rejoining can convert again.
        attempted = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema
