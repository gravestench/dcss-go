-- _profession_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_profession_name_",
    entries = {
        {
            weight = 10,
            text = "Apprentice",
        },
        {
            weight = 10,
            text = "Apothecary",
        },
        {
            weight = 10,
            text = "Baker",
        },
        {
            weight = 10,
            text = "Barber Surgeon",
        },
        {
            weight = 10,
            text = "Bard",
        },
        {
            weight = 10,
            text = "Beekeeper",
        },
        {
            weight = 10,
            text = "Beggar",
        },
        {
            weight = 10,
            text = "Blacksmith",
        },
        {
            weight = 10,
            text = "Buccaneer",
        },
        {
            weight = 10,
            text = "Butcher",
        },
        {
            weight = 10,
            text = "Candlemaker",
        },
        {
            weight = 10,
            text = "Carpenter",
        },
        {
            weight = 10,
            text = "Cartwright",
        },
        {
            weight = 10,
            text = "Cobbler",
        },
        {
            weight = 10,
            text = "Cooper",
        },
        {
            weight = 10,
            text = "Ditch-Digger",
        },
        {
            weight = 10,
            text = "Engineer",
        },
        {
            weight = 10,
            text = "Farmer",
        },
        {
            weight = 10,
            text = "Farrier",
        },
        {
            weight = 10,
            text = "Fisher",
        },
        {
            weight = 10,
            text = "Fletcher",
        },
        {
            weight = 10,
            text = "Furrier",
        },
        {
            weight = 10,
            text = "Gardener",
        },
        {
            weight = 10,
            text = "Goldsmith",
        },
        {
            weight = 10,
            text = "Gravedigger",
        },
        {
            weight = 10,
            text = "Guardian",
        },
        {
            weight = 10,
            text = "Guild-Master",
        },
        {
            weight = 10,
            text = "Guilds",
        },
        {
            weight = 10,
            text = "Hunter",
        },
        {
            weight = 10,
            text = "Journeyman",
        },
        {
            weight = 10,
            text = "Learner",
        },
        {
            weight = 10,
            text = "Merchant",
        },
        {
            weight = 10,
            text = "Miller",
        },
        {
            weight = 10,
            text = "Minstrel",
        },
        {
            weight = 10,
            text = "Moneychanger",
        },
        {
            weight = 10,
            text = "Monk",
        },
        {
            weight = 10,
            text = "Pirate",
        },
        {
            weight = 10,
            text = "Playwright",
        },
        {
            weight = 10,
            text = "Sailor",
        },
        {
            weight = 10,
            text = "Scribe",
        },
        {
            weight = 10,
            text = "Silversmith",
        },
        {
            weight = 10,
            text = "Soldier",
        },
        {
            weight = 10,
            text = "Stonemason",
        },
        {
            weight = 10,
            text = "Tanner",
        },
        {
            weight = 10,
            text = "Teacher",
        },
        {
            weight = 10,
            text = "Thinker",
        },
        {
            weight = 10,
            text = "Undertaker",
        },
        {
            weight = 10,
            text = "Watchman",
        },
        {
            weight = 10,
            text = "Weaver",
        },
        {
            weight = 10,
            text = "Wheelwright",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
