-- _armour_animal_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_arm.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_armour_animal_",
    entries = {
        {
            weight = 10,
            text = "Amoeba",
        },
        {
            weight = 10,
            text = "Ant",
        },
        {
            weight = 10,
            text = "Butterfly",
        },
        {
            weight = 10,
            text = "Cicada",
        },
        {
            weight = 10,
            text = "Cockroach",
        },
        {
            weight = 10,
            text = "Cricket",
        },
        {
            weight = 10,
            text = "Ladybird",
        },
        {
            weight = 10,
            text = "Locust",
        },
        {
            weight = 10,
            text = "Louse",
        },
        {
            weight = 10,
            text = "Mantidfly",
        },
        {
            weight = 10,
            text = "Tick",
        },
        {
            weight = 10,
            text = "Centipede",
        },
        {
            weight = 10,
            text = "Cuttlefish",
        },
        {
            weight = 10,
            text = "Gastropod",
        },
        {
            weight = 10,
            text = "Slug",
        },
        {
            weight = 10,
            text = "Snail",
        },
        {
            weight = 10,
            text = "Trilobite",
        },
        {
            weight = 10,
            text = "Worm",
        },
        {
            weight = 10,
            text = "Barnacle",
        },
        {
            weight = 10,
            text = "Clam",
        },
        {
            weight = 10,
            text = "Lobster",
        },
        {
            weight = 10,
            text = "Quahog",
        },
        {
            weight = 10,
            text = "Tarantula",
        },
        {
            weight = 10,
            text = "Frog",
        },
        {
            weight = 10,
            text = "Komodo Dragon",
        },
        {
            weight = 10,
            text = "Lizard",
        },
        {
            weight = 10,
            text = "Salamander",
        },
        {
            weight = 10,
            text = "Serpent",
        },
        {
            weight = 10,
            text = "Turtle",
        },
        {
            weight = 10,
            text = "Barracuda",
        },
        {
            weight = 10,
            text = "Catfish",
        },
        {
            weight = 10,
            text = "Mackerel",
        },
        {
            weight = 10,
            text = "Marlin",
        },
        {
            weight = 10,
            text = "Salmon",
        },
        {
            weight = 10,
            text = "Sturgeon",
        },
        {
            weight = 10,
            text = "Sunfish",
        },
        {
            weight = 10,
            text = "Trout",
        },
        {
            weight = 10,
            text = "Tuna",
        },
        {
            weight = 10,
            text = "Albatross",
        },
        {
            weight = 10,
            text = "Eagle",
        },
        {
            weight = 10,
            text = "Falcon",
        },
        {
            weight = 10,
            text = "Heron",
        },
        {
            weight = 10,
            text = "Meadowlark",
        },
        {
            weight = 10,
            text = "Nightingale",
        },
        {
            weight = 10,
            text = "Raven",
        },
        {
            weight = 10,
            text = "Robin",
        },
        {
            weight = 10,
            text = "Shrike",
        },
        {
            weight = 10,
            text = "Sparrow",
        },
        {
            weight = 10,
            text = "Swan",
        },
        {
            weight = 10,
            text = "Turtledove",
        },
        {
            weight = 10,
            text = "Bull",
        },
        {
            weight = 10,
            text = "Camelopard",
        },
        {
            weight = 10,
            text = "Catamount",
        },
        {
            weight = 10,
            text = "Dolphin",
        },
        {
            weight = 10,
            text = "Echidna",
        },
        {
            weight = 10,
            text = "Elephant",
        },
        {
            weight = 10,
            text = "Hart",
        },
        {
            weight = 10,
            text = "Hippo",
        },
        {
            weight = 10,
            text = "Kangaroo",
        },
        {
            weight = 10,
            text = "Lion",
        },
        {
            weight = 10,
            text = "Monkey",
        },
        {
            weight = 10,
            text = "Okapi",
        },
        {
            weight = 10,
            text = "Stag",
        },
        {
            weight = 10,
            text = "Stallion",
        },
        {
            weight = 10,
            text = "Zebra",
        },
        {
            weight = 10,
            text = "Circus Animal",
        },
        {
            weight = 10,
            text = "Monkey's Uncle",
        },
        {
            weight = 10,
            text = "Cockatrice",
        },
        {
            weight = 10,
            text = "Dragon",
        },
        {
            weight = 10,
            text = "Griffon",
        },
        {
            weight = 10,
            text = "Kraken",
        },
        {
            weight = 10,
            text = "Chupacabra",
        },
        {
            weight = 10,
            text = "Dropbear",
        },
        {
            weight = 10,
            text = "Jackalope",
        },
        {
            weight = 10,
            text = "Wild Haggis",
        },
        {
            weight = 10,
            text = "Yeti",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
