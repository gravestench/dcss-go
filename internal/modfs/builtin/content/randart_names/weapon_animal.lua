-- _weapon_animal_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_wpn.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_weapon_animal_",
    entries = {
        {
            weight = 10,
            text = "Blowfly",
        },
        {
            weight = 10,
            text = "Butterfly",
        },
        {
            weight = 10,
            text = "Dragonfly",
        },
        {
            weight = 10,
            text = "Firefly",
        },
        {
            weight = 10,
            text = "Gnat",
        },
        {
            weight = 10,
            text = "Mosquito",
        },
        {
            weight = 10,
            text = "Moth",
        },
        {
            weight = 10,
            text = "Pill Bug",
        },
        {
            weight = 10,
            text = "Wasp",
        },
        {
            weight = 10,
            text = "Scorpion",
        },
        {
            weight = 10,
            text = "Spider",
        },
        {
            weight = 10,
            text = "Asp",
        },
        {
            weight = 10,
            text = "Rattlesnake",
        },
        {
            weight = 10,
            text = "Viper",
        },
        {
            weight = 10,
            text = "Big Fish",
        },
        {
            weight = 10,
            text = "Eel",
        },
        {
            weight = 10,
            text = "Lamprey",
        },
        {
            weight = 10,
            text = "Salmon",
        },
        {
            weight = 10,
            text = "Shark",
        },
        {
            weight = 10,
            text = "Dove",
        },
        {
            weight = 10,
            text = "Hawk",
        },
        {
            weight = 10,
            text = "Hummingbird",
        },
        {
            weight = 10,
            text = "Fulmar",
        },
        {
            weight = 10,
            text = "Owl",
        },
        {
            weight = 10,
            text = "Penguin",
        },
        {
            weight = 10,
            text = "Puffin",
        },
        {
            weight = 10,
            text = "Shrike",
        },
        {
            weight = 10,
            text = "Stork",
        },
        {
            weight = 10,
            text = "Vulture",
        },
        {
            weight = 10,
            text = "Ass",
        },
        {
            weight = 10,
            text = "Badger",
        },
        {
            weight = 10,
            text = "Bear",
        },
        {
            weight = 10,
            text = "Boar",
        },
        {
            weight = 10,
            text = "Fox",
        },
        {
            weight = 10,
            text = "Goat",
        },
        {
            weight = 10,
            text = "Rat",
        },
        {
            weight = 5,
            text = "Stoat",
        },
        {
            weight = 10,
            text = "Tiger",
        },
        {
            weight = 5,
            text = "Weasel",
        },
        {
            weight = 10,
            text = "Whale",
        },
        {
            weight = 10,
            text = "Wolf",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
