-- Kirke's naturally spawned hogs become humans when she dies. The marker is
-- separate from Porkalator's saved original body because these hogs were not
-- spell-transformed monsters and do not have an earlier actor to restore.
local tactical = require("constants.monster_tactical")

local schema = {
    id = tactical.KIRKE_BAND,
    version = 1,
    fields = {
        band_member = {
            type = "bool",
            default = true,
        },
    },
}

register.component(schema)

return schema
