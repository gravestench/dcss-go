-- _politics_name_armour_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_politics_name_armour_",
    entries = {
        {
            weight = 10,
            text = "Coronation",
        },
        {
            weight = 10,
            text = "Democracy",
        },
        {
            weight = 10,
            text = "Nobility",
        },
        {
            weight = 10,
            text = "Royalty",
        },
        {
            weight = 10,
            text = "Sovereignty",
        },
        {
            weight = 10,
            text = "the Ban",
        },
        {
            weight = 10,
            text = "the Burgomaster",
        },
        {
            weight = 10,
            text = "the Cast Vote",
        },
        {
            weight = 10,
            text = "the Castellan",
        },
        {
            weight = 10,
            text = "the City",
        },
        {
            weight = 10,
            text = "the Commoners",
        },
        {
            weight = 10,
            text = "the Country",
        },
        {
            weight = 10,
            text = "the Crown",
        },
        {
            weight = 10,
            text = "the Doge",
        },
        {
            weight = 10,
            text = "the Duchess",
        },
        {
            weight = 10,
            text = "the Duke",
        },
        {
            weight = 10,
            text = "the Empire",
        },
        {
            weight = 10,
            text = "the Failed Coup",
        },
        {
            weight = 10,
            text = "the Greedy",
        },
        {
            weight = 10,
            text = "the King",
        },
        {
            weight = 10,
            text = "the Komtur",
        },
        {
            weight = 10,
            text = "the Mutiny",
        },
        {
            weight = 10,
            text = "the Oligarchy",
        },
        {
            weight = 10,
            text = "the Peasants",
        },
        {
            weight = 10,
            text = "the Prince",
        },
        {
            weight = 10,
            text = "the Princeling",
        },
        {
            weight = 10,
            text = "the Princess",
        },
        {
            weight = 10,
            text = "the Queen",
        },
        {
            weight = 10,
            text = "the Rabble",
        },
        {
            weight = 10,
            text = "the Republic",
        },
        {
            weight = 10,
            text = "the Suburbs",
        },
        {
            weight = 10,
            text = "the Townfolk",
        },
        {
            weight = 10,
            text = "the Voivode",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
