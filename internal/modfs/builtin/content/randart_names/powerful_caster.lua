-- _powerful_caster_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/randbook.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_powerful_caster_",
    entries = {
        {
            weight = 10,
            text = "Archmage",
        },
        {
            weight = 3,
            text = "Deep Elf Lorekeeper",
        },
        {
            weight = 3,
            text = "Blind Seer",
        },
        {
            weight = 3,
            text = "Prophet",
        },
        {
            weight = 3,
            text = "Loreminder",
        },
        {
            weight = 3,
            text = "High Council",
        },
        {
            weight = 1,
            text = "Greatest Mummy",
        },
        {
            weight = 1,
            text = "Ultimate Wizard",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
