-- A trap is dynamic world state, separate from its underlying grid feature.
local component = require("constants.component")

local schema = {
    id = component.WORLD_TRAP,
    version = 1,
    -- Charges and reveal state belong to the trap entity, independent of the underlying terrain glyph.
    fields = {
        kind_id = {
            type = "string",
        },

        level_id = {
            type = "int64",
        },

        x = {
            type = "int64",
        },

        y = {
            type = "int64",
        },

        charges = {
            type = "int64",
        },

        revealed = {
            type = "bool",
        },

        source_record = {
            type = "string",
        },
    },
}

register.component(schema)

return schema
