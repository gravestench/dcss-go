-- _plain_armour_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_plain_armour_name_",
    entries = {
        {
            weight = 10,
            text = "Damnable Contraption",
        },
        {
            weight = 10,
            text = "Earthly Heaven",
        },
        {
            weight = 10,
            text = "Forget-Me-Not",
        },
        {
            weight = 10,
            text = "Hero's Friend",
        },
        {
            weight = 10,
            text = "Put-Me-On",
        },
        {
            weight = 10,
            text = "Trusted Companion",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
