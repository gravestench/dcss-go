-- _ashenzari_epithet_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_ashenzari_epithet_",
    entries = {
        {
            weight = 100,
            text = "@_ashenzari_adjective_@ God",
        },
        {
            weight = 50,
            text = "@_ashenzari_bound_adjective_@ Augur",
        },
        {
            weight = 50,
            text = "@_ashenzari_celestial_adjective_@ Augur",
        },
        {
            weight = 50,
            text = "@_ashenzari_bound_adjective_@ Sage",
        },
        {
            weight = 50,
            text = "@_ashenzari_celestial_adjective_@ Sage",
        },
        {
            weight = 50,
            text = "@_ashenzari_bound_adjective_@ Seer",
        },
        {
            weight = 50,
            text = "@_ashenzari_celestial_adjective_@ Seer",
        },
        {
            weight = 10,
            text = "All-Knowing",
        },
        {
            weight = 10,
            text = "Curse-Bearer",
        },
        {
            weight = 10,
            text = "Soothsayer",
        },
        {
            weight = 10,
            text = "Unmoving One",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
