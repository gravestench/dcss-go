-- God wrath sometimes leaves clouds, burns, or summons after its brief
-- spellcaster vanishes. This owner keeps their original god attribution
-- alive without putting a second actor on the level grid.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_AVATAR_SOURCE,
    version = 1,
    fields = {
        god_id = {
            type = "string",
        },
    },
}

register.component(schema)

return schema
