-- spectral mist (ids.CLOUD_SPECTRAL) has spread rate 0 and delegates contact
-- to policy.clouds.effects.spectral.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_SPECTRAL,
    name = "spectral mist",
    color = "ETC_ELECTRICITY",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    -- Contact damage is rolled from this formula for each affected actor.
    damage = {
        base = 4,
        random = 15,
        extra_player = false,
    },
    effect = "policy.clouds.effects.spectral",
}

register.definition(categories.CLOUDS, definition)

return definition
