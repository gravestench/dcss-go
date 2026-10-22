-- Jiyva's attempt flag and converted side belong to the slime actor.
-- Both survive a level change; neither can live in a Lua module local.
local attitudes = require("constants.attitude")
local component = require("constants.component")

local schema = {
    id = component.JIYVA_SLIME,
    version = 1,
    fields = {
        attitude = {
            type = "string",
            default = attitudes.HOSTILE,
        },

        -- Source MF_ATT_CHANGE_ATTEMPT also remembers a failed attempt
        -- under penance. Clearing penance lets that monster try again.
        attempted = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema
