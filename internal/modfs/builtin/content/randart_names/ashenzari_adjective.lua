-- _ashenzari_adjective_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randname.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_ashenzari_adjective_",
    entries = {
        {
            weight = 50,
            text = "@_ashenzari_bound_adjective_@",
        },
        {
            weight = 50,
            text = "@_ashenzari_knowledge_adjective_@",
        },
        {
            weight = 10,
            text = "@_ashenzari_celestial_adjective_@",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
