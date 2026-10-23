-- Elixir's duration belongs to the player so healing resumes after a save.
-- The ordinary health and magic components remain the resource owners.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_CARD_ELIXIR,
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
