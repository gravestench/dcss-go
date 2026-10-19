-- _wacky_armour_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_wacky_armour_name_",
    entries = {
        {
            weight = 10,
            text = "Absence",
        },
        {
            weight = 10,
            text = "Anaesthesia",
        },
        {
            weight = 10,
            text = "Baldness",
        },
        {
            weight = 10,
            text = "Compression",
        },
        {
            weight = 10,
            text = "Decompression",
        },
        {
            weight = 10,
            text = "Dramatic Exits",
        },
        {
            weight = 10,
            text = "Duck's Teeth",
        },
        {
            weight = 10,
            text = "Forking Paths",
        },
        {
            weight = 10,
            text = "Good Intentions",
        },
        {
            weight = 10,
            text = "Hadjma",
        },
        {
            weight = 10,
            text = "Hairiness",
        },
        {
            weight = 10,
            text = "Hedging",
        },
        {
            weight = 10,
            text = "Hubris",
        },
        {
            weight = 10,
            text = "Incorporation",
        },
        {
            weight = 10,
            text = "Indecent Exposure",
        },
        {
            weight = 10,
            text = "Indemnity",
        },
        {
            weight = 10,
            text = "Limited Liability",
        },
        {
            weight = 10,
            text = "Loss",
        },
        {
            weight = 10,
            text = "Love and Death",
        },
        {
            weight = 10,
            text = "Mezcal",
        },
        {
            weight = 10,
            text = "Pathos",
        },
        {
            weight = 10,
            text = "Philately",
        },
        {
            weight = 10,
            text = "Plasticity",
        },
        {
            weight = 10,
            text = "Poor Excuses",
        },
        {
            weight = 10,
            text = "Precision Catastrophes",
        },
        {
            weight = 10,
            text = "Space",
        },
        {
            weight = 10,
            text = "Terror",
        },
        {
            weight = 10,
            text = "Thrice Damned Blessings",
        },
        {
            weight = 10,
            text = "Too Many Cooks",
        },
        {
            weight = 10,
            text = "Untold Secrets",
        },
        {
            weight = 10,
            text = "Vlad",
        },
        {
            weight = 10,
            text = "Weirdness",
        },
        {
            weight = 10,
            text = "the Arcane",
        },
        {
            weight = 10,
            text = "the Armadillo",
        },
        {
            weight = 10,
            text = "the Blind Marksman",
        },
        {
            weight = 10,
            text = "the Earth",
        },
        {
            weight = 10,
            text = "the Eternal Fruit",
        },
        {
            weight = 10,
            text = "the Loofah",
        },
        {
            weight = 10,
            text = "the Old and Reckless",
        },
        {
            weight = 10,
            text = "the Onion",
        },
        {
            weight = 10,
            text = "the Pink Corner",
        },
        {
            weight = 10,
            text = "the Road Less Travelled",
        },
        {
            weight = 10,
            text = "the True Pharaoh",
        },
        {
            weight = 10,
            text = "the Unemployed Unperson",
        },
        {
            weight = 10,
            text = "the Vacuum",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
