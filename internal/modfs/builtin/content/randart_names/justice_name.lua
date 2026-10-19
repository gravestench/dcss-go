-- _justice_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_justice_name_",
    entries = {
        {
            weight = 10,
            text = "Absolution",
        },
        {
            weight = 10,
            text = "Accidental Termination",
        },
        {
            weight = 10,
            text = "Blind Justice",
        },
        {
            weight = 10,
            text = "Capital Punishment",
        },
        {
            weight = 10,
            text = "Corporal Punishment",
        },
        {
            weight = 10,
            text = "Cruel Justice",
        },
        {
            weight = 10,
            text = "Exoneration",
        },
        {
            weight = 10,
            text = "Extenuating Circumstances",
        },
        {
            weight = 10,
            text = "False Accusations",
        },
        {
            weight = 10,
            text = "Forgiveness",
        },
        {
            weight = 10,
            text = "Guilt",
        },
        {
            weight = 10,
            text = "Innocence",
        },
        {
            weight = 10,
            text = "Judgement",
        },
        {
            weight = 10,
            text = "Punishment",
        },
        {
            weight = 10,
            text = "Tender Mercy",
        },
        {
            weight = 10,
            text = "Tortfeasance",
        },
        {
            weight = 10,
            text = "Trial by Ordeal",
        },
        {
            weight = 10,
            text = "Wrongful Imprisonment",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
