-- _balance_or_order_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_balance_or_order_",
    entries = {
        {
            weight = 10,
            text = "Accord",
        },
        {
            weight = 10,
            text = "Arrival",
        },
        {
            weight = 10,
            text = "Ascent",
        },
        {
            weight = 10,
            text = "Balance",
        },
        {
            weight = 10,
            text = "Bodily Harmony",
        },
        {
            weight = 10,
            text = "Circularity",
        },
        {
            weight = 10,
            text = "Conformity",
        },
        {
            weight = 10,
            text = "Departure",
        },
        {
            weight = 10,
            text = "Descent",
        },
        {
            weight = 10,
            text = "Due Proportion",
        },
        {
            weight = 10,
            text = "Equilibrium",
        },
        {
            weight = 10,
            text = "Equivalence",
        },
        {
            weight = 10,
            text = "Eternal Harmony",
        },
        {
            weight = 10,
            text = "Fragile Peace",
        },
        {
            weight = 10,
            text = "Harmony",
        },
        {
            weight = 10,
            text = "Law",
        },
        {
            weight = 10,
            text = "Linearity",
        },
        {
            weight = 10,
            text = "Moderation",
        },
        {
            weight = 10,
            text = "Peace",
        },
        {
            weight = 10,
            text = "Propriety",
        },
        {
            weight = 10,
            text = "Symmetry",
        },
        {
            weight = 10,
            text = "the Establishment",
        },
        {
            weight = 10,
            text = "the Final Decision",
        },
        {
            weight = 10,
            text = "the Median",
        },
        {
            weight = 10,
            text = "the Middle",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
