-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:509
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BERSERK",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "berserk",
    description =
        "When attacking foes in melee, you sometimes enter a berserk rage. Each level of\nthis" ..
        " mutation makes it easier for you to lose your temper.",
    have = {
        "You sometimes lose your temper in combat.",
        "You have an uncontrollable temper.",
        "",
    },
    gain = {
        "You feel a little pissed off.",
        "You feel extremely angry at everything!",
        "",
    },
    lose = {
        "You feel a little more calm.",
        "You feel a little less angry.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
