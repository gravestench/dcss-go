-- _other_armour_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_other_armour_name_",
    entries = {
        {
            weight = 10,
            text = "Filth",
        },
        {
            weight = 5,
            text = "Grot",
        },
        {
            weight = 5,
            text = "Grottiness",
        },
        {
            weight = 10,
            text = "Slovenliness",
        },
        {
            weight = 10,
            text = "Bedevilment",
        },
        {
            weight = 10,
            text = "Broken Taboos",
        },
        {
            weight = 10,
            text = "Gestures",
        },
        {
            weight = 10,
            text = "Magic",
        },
        {
            weight = 10,
            text = "Muttered Phrases",
        },
        {
            weight = 10,
            text = "Sorcery",
        },
        {
            weight = 10,
            text = "Words of Power",
        },
        {
            weight = 10,
            text = "the Arcane",
        },
        {
            weight = 10,
            text = "Crawling",
        },
        {
            weight = 10,
            text = "Disaster",
        },
        {
            weight = 10,
            text = "Dogmatism",
        },
        {
            weight = 10,
            text = "Feasting",
        },
        {
            weight = 10,
            text = "Going Fast",
        },
        {
            weight = 10,
            text = "Happy Babbling",
        },
        {
            weight = 10,
            text = "Hedge Wizardry",
        },
        {
            weight = 10,
            text = "Imperfection",
        },
        {
            weight = 10,
            text = "Inevitability",
        },
        {
            weight = 10,
            text = "Insatiable Hunger",
        },
        {
            weight = 10,
            text = "Insurance",
        },
        {
            weight = 10,
            text = "Misanthropy",
        },
        {
            weight = 10,
            text = "Perfidy",
        },
        {
            weight = 10,
            text = "Time Monsters",
        },
        {
            weight = 10,
            text = "Trial and Error",
        },
        {
            weight = 10,
            text = "Unambiguity",
        },
        {
            weight = 10,
            text = "Undesirable Species",
        },
        {
            weight = 10,
            text = "Wasted Space",
        },
        {
            weight = 10,
            text = "Wrong Decisions",
        },
        {
            weight = 10,
            text = "the @_card_@ of @_suit_@",
        },
        {
            weight = 10,
            text = "the Hanged Man",
        },
        {
            weight = 10,
            text = "the Lost Path",
        },
        {
            weight = 10,
            text = "the Moon Troll",
        },
        {
            weight = 10,
            text = "the Orb",
        },
        {
            weight = 10,
            text = "the Orb Guardian",
        },
        {
            weight = 10,
            text = "the Other World",
        },
        {
            weight = 10,
            text = "the Sacrificial Victim",
        },
        {
            weight = 10,
            text = "the Slightly Bent",
        },
        {
            weight = 10,
            text = "the Storm King",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
