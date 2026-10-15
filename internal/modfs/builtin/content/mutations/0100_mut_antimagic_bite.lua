-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1334
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ANTIMAGIC_BITE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "antimagic bite",
    description =
        "You have a thirst for magic, allowing you to bite foes when launching melee\nattacks." ..
        " This restores your magical reserves and also disrupts magical foes,\nsometimes" ..
        " leaving them unable to act.",
    have = {
        "Your bite disrupts and absorbs the magic of your enemies.",
        "",
        "",
    },
    gain = {
        "You feel a sudden thirst for magic.",
        "",
        "",
    },
    lose = {
        "Your magical appetite wanes.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
