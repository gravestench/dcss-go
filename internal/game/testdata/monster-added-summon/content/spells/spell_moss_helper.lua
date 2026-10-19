-- One mod-owned spell exists only in this sparse overlay. Its content facts
-- are separate from the focused Lua effect that makes it playable.
local categories = require("constants.catalog")

local definition = {
    id = "SPELL_MOSS_HELPER",
    status = "defined",
    name = "Moss Helper",
    level = 1,
}

register.definition(categories.SPELLS, definition)

return definition
