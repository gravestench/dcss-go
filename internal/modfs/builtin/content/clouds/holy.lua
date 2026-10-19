-- blessed fire (ids.CLOUD_HOLY) has spread rate 0 and delegates contact to
-- policy.clouds.effects.holy.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_HOLY,
    name = "blessed fire",
    color = "ETC_HOLY",
    opaque = true,
    harmless = false,
    spread_rate = 0,
    -- Contact damage is rolled from this formula for each affected actor.
    damage = {
        base = 4,
        random = 12,
        extra_player = true,
    },
    effect = "policy.clouds.effects.holy",
}

register.definition(categories.CLOUDS, definition)

return definition
