-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1183
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_POWERED_BY_DEATH",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "powered by death",
    description =
        "Death fuels you, allowing you to heal somewhat for each life you take. Each\nlevel of" ..
        " this mutation increases the healing further.",
    have = {
        "You regenerate a little health from kills.",
        "You regenerate health from kills.",
        "You regenerate a lot of health from kills.",
    },
    gain = {
        "A wave of death washes over you.",
        "The wave of death grows in power.",
        "The wave of death grows in power.",
    },
    lose = {
        "Your control of surrounding life forces is gone.",
        "Your control of surrounding life forces weakens.",
        "Your control of surrounding life forces weakens.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
