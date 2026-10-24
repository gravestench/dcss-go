-- The selected follower persists while the player chooses its item.
-- A saved prompt cannot silently switch to another ally on restore.
local component = require("constants.component")

local schema = {
    id = component.BEOGH_GIFT_CHOICE,
    version = 1,
    fields = {
        follower = {
            type = "entity",
        },
    },
}

register.component(schema)

return schema
