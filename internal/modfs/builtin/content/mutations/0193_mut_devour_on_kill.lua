-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2335
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEVOUR_ON_KILL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "devour on kill",
    description =
        "When you kill living creatures you have a chance to devour their life force\nand" ..
        " restore hit points.",
    have = {
        "You thrive by killing the living.",
        "",
        "",
    },
    gain = {
        "You feel hungry for flesh.",
        "",
        "",
    },
    lose = {
        "You feel less hungry for flesh.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
