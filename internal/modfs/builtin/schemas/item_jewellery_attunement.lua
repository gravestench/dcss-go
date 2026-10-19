local component = require("constants.component")

-- Source: player-equip.cc equips regeneration amulets inert until their
-- resource is full. The active bit belongs to the item being worn.
local schema = {
    id = component.JEWELLERY_ATTUNEMENT,
    version = 1,
    -- The item carries its own active bit because removing and re-equipping it changes attunement.
    fields = {
        active = {
            type = "bool",
            default = false,
        },
    },
}

register.component(schema)

return schema
