-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2173
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_QUADRUMANOUS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "four strong arms",
    description =
        "You have two pairs of two arms, allowing you to wield two-handed weapons with\none" ..
        " pair and a shield with the other. You can even wield extremely large\nweapons like" ..
        " giant clubs, though this takes both arm-pairs. The secondary arms\nin each pair are" ..
        " oddly shaped, preventing you from wearing an extra set of\ngloves or magical rings.",
    have = {
        "Your four strong arms can wield two-handed weapons with a shield.",
        "",
        "",
    },
    gain = {
        "Two of your arms shrink away.",
        "",
        "",
    },
    lose = {
        "You grow two extra arms.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
