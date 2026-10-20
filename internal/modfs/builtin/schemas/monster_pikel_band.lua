-- Pikel's lemures carry a saved origin beyond their temporary follower
-- link. His death dismisses these specific actors across loaded floors.
local component = require("constants.component")

local schema = {
    id = component.PIKEL_BAND,
    version = 1,
    fields = {
        band_member = {
            type = "bool",
        },
    },
}

register.component(schema)

return schema
