-- Transporter discoveries belong to the player and survive save/restore.
-- A source-cell key identifies a known one-way destination on its floor.
local component = require("constants.component")

local schema = {
    id = component.TRANSPORTER_KNOWLEDGE,
    version = 1,
    fields = {
        links = {
            type = "map<string,string>",
        },
    },
}

register.component(schema)

return schema
