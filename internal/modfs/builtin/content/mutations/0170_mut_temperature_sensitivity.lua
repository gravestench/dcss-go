-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2141
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TEMPERATURE_SENSITIVITY",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "temperature sensitive",
    description =
        "You are vulnerable to both cold and fire, and you take more damage from those\neffects.",
    have = {
        "You are sensitive to extremes of temperature. (rF-, rC-)",
        "",
        "",
    },
    gain = {
        "You feel sensitive to extremes of temperature.",
        "",
        "",
    },
    lose = {
        "You no longer feel sensitive to extremes of temperature",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
