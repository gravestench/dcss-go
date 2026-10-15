-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1326
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ACIDIC_BITE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "acidic bite",
    description =
        "You have acidic saliva, allowing you to bite foes and apply corrosion to them\nwhen" ..
        " launching melee attacks.",
    have = {
        "You have acidic saliva.",
        "",
        "",
    },
    gain = {
        "Acid begins to drip from your mouth.",
        "",
        "",
    },
    lose = {
        "Your mouth feels dry.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
