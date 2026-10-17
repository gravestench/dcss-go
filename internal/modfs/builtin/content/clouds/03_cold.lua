-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_COLD,
    name = "freezing vapour",
    verbose_name = "freezing vapours",
    color = "COLOUR_UNDEF",
    console_color = "LIGHTCYAN",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    damage = {
        base = 6,
        random = 16,
        extra_player = true,
    },
    effect = "policy.clouds.effects.cold",
}

register.definition(categories.CLOUDS, definition)

return definition
