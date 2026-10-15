-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2341
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SHORT_LIFESPAN",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "otherworldly",
    description =
        "You are foreign to this world, easily perceived by dark forces. You have only" ..
        "\none-tenth the normal time on each dungeon floor before Zot finds and ends you.",
    have = {
        "You are easily found by Zot.",
        "",
        "",
    },
    gain = {
        "You feel your time running out.",
        "",
        "",
    },
    lose = {
        "You feel long-lived.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
