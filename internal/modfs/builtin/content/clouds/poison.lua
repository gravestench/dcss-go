-- poison gas (ids.CLOUD_POISON) has spread rate 0 and delegates contact to
-- policy.clouds.effects.poison.
-- A placed cloud owns duration and position in world state; this definition
-- supplies type-wide behavior.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_POISON,
    name = "poison gas",
    color = "LIGHTGREEN",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    -- Contact damage is rolled from this formula for each affected actor.
    damage = {
        base = 0,
        random = 10,
        extra_player = false,
    },
    effect = "policy.clouds.effects.poison",
}

register.definition(categories.CLOUDS, definition)

return definition
