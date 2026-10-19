-- transmutation adj is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "transmutation adj",
    entries = {
        {
            weight = 10,
            text = "Altered",
        },
        {
            weight = 10,
            text = "Amorphous",
        },
        {
            weight = 10,
            text = "Changed",
        },
        {
            weight = 10,
            text = "Changing",
        },
        {
            weight = 10,
            text = "Inconstant",
        },
        {
            weight = 10,
            text = "Mercurial",
        },
        {
            weight = 10,
            text = "Metamorphic",
        },
        {
            weight = 10,
            text = "Mutable",
        },
        {
            weight = 10,
            text = "Mutagenic",
        },
        {
            weight = 10,
            text = "Mutated",
        },
        {
            weight = 10,
            text = "Reformed",
        },
        {
            weight = 10,
            text = "Remoulded",
        },
        {
            weight = 10,
            text = "Reshaped",
        },
        {
            weight = 10,
            text = "Shifting",
        },
        {
            weight = 10,
            text = "Unstable",
        },
        {
            weight = 10,
            text = "Transformed",
        },
        {
            weight = 10,
            text = "Transforming",
        },
        {
            weight = 10,
            text = "Transmuted",
        },
        {
            weight = 10,
            text = "Variable",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
