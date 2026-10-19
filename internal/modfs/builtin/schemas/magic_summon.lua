-- Every caster's summoned actor keeps its source, real attitude, and timeout
-- through save and restore. Charm changes temporary behavior elsewhere.
local categories = require("constants.catalog")
local attitude = require("constants.attitude")

local schema = {
    id = "magic.summon",
    version = 4,
    -- Source and owner identify a summon. Real attitude survives charm.
    fields = {
        owner = {
            type = "entity",
        },

        source_category = {
            type = "string",
            default = categories.SPELLS,
        },

        source_id = {
            type = "string",
            default = "",
        },

        expires_aut = {
            type = "int64",
            default = 0,
        },

        heads = {
            type = "int64",
            default = 0,
        },

        attitude = {
            type = "string",
            default = attitude.FRIENDLY,
        },
    },
}

register.component(schema)

return schema
