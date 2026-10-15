-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2311
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ENGULF",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "engulf",
    description =
        "Your melee attacks may engulf living foes that are your size or smaller.\nThose foes" ..
        " will be silenced and unable to breathe.",
    have = {
        "Your melee attacks may engulf your foes in ooze.",
        "",
        "",
    },
    gain = {
        "You begin exuding ooze.",
        "",
        "",
    },
    lose = {
        "You stop exuding ooze.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
