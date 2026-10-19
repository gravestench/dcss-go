-- _battle_or_war_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_battle_or_war_",
    entries = {
        {
            weight = 10,
            text = "Crusades",
        },
        {
            weight = 10,
            text = "Eternal War",
        },
        {
            weight = 10,
            text = "Iconoclasm",
        },
        {
            weight = 10,
            text = "Plunder",
        },
        {
            weight = 10,
            text = "Ravage",
        },
        {
            weight = 10,
            text = "Regicide",
        },
        {
            weight = 10,
            text = "Skirmishing",
        },
        {
            weight = 10,
            text = "War",
        },
        {
            weight = 10,
            text = "the Doomed Warrior",
        },
        {
            weight = 10,
            text = "the Endless March",
        },
        {
            weight = 10,
            text = "the Eternal Warrior",
        },
        {
            weight = 10,
            text = "the Onslaught",
        },
        {
            weight = 10,
            text = "the Pyrrhic Victory",
        },
        {
            weight = 10,
            text = "the Warrior",
        },
        {
            weight = 10,
            text = "Blood",
        },
        {
            weight = 10,
            text = "Blood-Lust",
        },
        {
            weight = 10,
            text = "Callousness",
        },
        {
            weight = 10,
            text = "Diet Blood",
        },
        {
            weight = 10,
            text = "Fear",
        },
        {
            weight = 10,
            text = "Joyful Slaughter",
        },
        {
            weight = 10,
            text = "Massacring",
        },
        {
            weight = 10,
            text = "Wounding",
        },
        {
            weight = 10,
            text = "Agony",
        },
        {
            weight = 10,
            text = "Hacking and Slashing",
        },
        {
            weight = 10,
            text = "Insufficient Pleasure",
        },
        {
            weight = 10,
            text = "Trauma",
        },
        {
            weight = 10,
            text = "Dullness",
        },
        {
            weight = 10,
            text = "Precise Incision",
        },
        {
            weight = 10,
            text = "Laceration",
        },
        {
            weight = 10,
            text = "Severance",
        },
        {
            weight = 10,
            text = "Truncation",
        },
        {
            weight = 10,
            text = "Death's Door",
        },
        {
            weight = 10,
            text = "Mourning",
        },
        {
            weight = 10,
            text = "the Grave",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
