-- negative energy (ids.CLOUD_NEGATIVE_ENERGY) has spread rate 0 and delegates
-- contact to policy.clouds.effects.negative_energy.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_NEGATIVE_ENERGY,
    name = "negative energy",
    color = "ETC_INCARNADINE",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    -- Contact damage is rolled from this formula for each affected actor.
    damage = {
        base = 6,
        random = 16,
        extra_player = true,
    },
    effect = "policy.clouds.effects.negative_energy",
}

register.definition(categories.CLOUDS, definition)

return definition
