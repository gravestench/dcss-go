-- _ashenzari_bound_adjective_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_ashenzari_bound_adjective_",
    entries = {
        {
            weight = 10,
            text = "Bound",
        },
        {
            weight = 10,
            text = "Chained",
        },
        {
            weight = 10,
            text = "Circumscribed",
        },
        {
            weight = 10,
            text = "Cursed",
        },
        {
            weight = 10,
            text = "Ensconced",
        },
        {
            weight = 10,
            text = "Eternal",
        },
        {
            weight = 10,
            text = "Lashed",
        },
        {
            weight = 10,
            text = "Restrained",
        },
        {
            weight = 10,
            text = "Ruined",
        },
        {
            weight = 10,
            text = "Shackled",
        },
        {
            weight = 10,
            text = "Shattered",
        },
        {
            weight = 10,
            text = "Tethered",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
