-- _flower_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_flower_name_",
    entries = {
        {
            weight = 10,
            text = "Daffodils",
        },
        {
            weight = 10,
            text = "Daisies",
        },
        {
            weight = 10,
            text = "Lilacs",
        },
        {
            weight = 10,
            text = "Tulips",
        },
        {
            weight = 10,
            text = "the Garden",
        },
        {
            weight = 10,
            text = "the Lily",
        },
        {
            weight = 10,
            text = "the Lotus Blossom",
        },
        {
            weight = 10,
            text = "the Rose",
        },
        {
            weight = 10,
            text = "the Thistle",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
