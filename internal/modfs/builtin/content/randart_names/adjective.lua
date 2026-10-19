-- _adjective_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_adjective_",
    entries = {
        {
            weight = 10,
            text = "Blue",
        },
        {
            weight = 10,
            text = "Green",
        },
        {
            weight = 10,
            text = "Red",
        },
        {
            weight = 5,
            text = "Amorous",
        },
        {
            weight = 10,
            text = "Antique",
        },
        {
            weight = 10,
            text = "Arcadian",
        },
        {
            weight = 5,
            text = "Avant Garde",
        },
        {
            weight = 10,
            text = "Baleful",
        },
        {
            weight = 10,
            text = "Barnacled",
        },
        {
            weight = 10,
            text = "Beastly",
        },
        {
            weight = 10,
            text = "Bedazzled",
        },
        {
            weight = 10,
            text = "Bellicose",
        },
        {
            weight = 10,
            text = "Beloved",
        },
        {
            weight = 10,
            text = "Bequeathed",
        },
        {
            weight = 10,
            text = "Bespelled",
        },
        {
            weight = 10,
            text = "Bright",
        },
        {
            weight = 10,
            text = "Burning",
        },
        {
            weight = 10,
            text = "Bursted",
        },
        {
            weight = 5,
            text = "Burnt",
        },
        {
            weight = 10,
            text = "Carved",
        },
        {
            weight = 10,
            text = "Caustic",
        },
        {
            weight = 10,
            text = "Clean",
        },
        {
            weight = 10,
            text = "Cleverly Designed",
        },
        {
            weight = 10,
            text = "Charmed",
        },
        {
            weight = 5,
            text = "Charred",
        },
        {
            weight = 10,
            text = "Contumacious",
        },
        {
            weight = 10,
            text = "Damp",
        },
        {
            weight = 10,
            text = "Decaying",
        },
        {
            weight = 10,
            text = "Deeply Unsettling",
        },
        {
            weight = 10,
            text = "Delicate",
        },
        {
            weight = 10,
            text = "Delightful",
        },
        {
            weight = 10,
            text = "Demonic",
        },
        {
            weight = 10,
            text = "Divine",
        },
        {
            weight = 10,
            text = "Doomed",
        },
        {
            weight = 10,
            text = "Dowdy",
        },
        {
            weight = 10,
            text = "Dull",
        },
        {
            weight = 10,
            text = "Durable",
        },
        {
            weight = 10,
            text = "Enormous",
        },
        {
            weight = 10,
            text = "Ethereal",
        },
        {
            weight = 10,
            text = "Exceptional",
        },
        {
            weight = 10,
            text = "Extremely Toothy",
        },
        {
            weight = 10,
            text = "Eye-covered",
        },
        {
            weight = 10,
            text = "Fabulous",
        },
        {
            weight = 10,
            text = "Fae",
        },
        {
            weight = 10,
            text = "Feral",
        },
        {
            weight = 10,
            text = "Ferocious",
        },
        {
            weight = 10,
            text = "Festooned",
        },
        {
            weight = 10,
            text = "Filigreed",
        },
        {
            weight = 10,
            text = "Floral",
        },
        {
            weight = 10,
            text = "Freezing",
        },
        {
            weight = 10,
            text = "Fresh",
        },
        {
            weight = 5,
            text = "Futuristic",
        },
        {
            weight = 10,
            text = "Fuzzy",
        },
        {
            weight = 10,
            text = "Ghostly",
        },
        {
            weight = 10,
            text = "Glamorous",
        },
        {
            weight = 10,
            text = "Golden",
        },
        {
            weight = 10,
            text = "Grand",
        },
        {
            weight = 10,
            text = "Grim",
        },
        {
            weight = 10,
            text = "Hairy",
        },
        {
            weight = 10,
            text = "Haunted",
        },
        {
            weight = 10,
            text = "Histrionic",
        },
        {
            weight = 10,
            text = "Impish",
        },
        {
            weight = 10,
            text = "Indestructible",
        },
        {
            weight = 10,
            text = "Intense",
        },
        {
            weight = 10,
            text = "Irksome",
        },
        {
            weight = 10,
            text = "Jocular",
        },
        {
            weight = 10,
            text = "Lachrymose",
        },
        {
            weight = 10,
            text = "Living",
        },
        {
            weight = 10,
            text = "Majestic",
        },
        {
            weight = 10,
            text = "Meager",
        },
        {
            weight = 5,
            text = "Modern",
        },
        {
            weight = 10,
            text = "Mordant",
        },
        {
            weight = 10,
            text = "Narrow",
        },
        {
            weight = 10,
            text = "Nice",
        },
        {
            weight = 10,
            text = "Noxious",
        },
        {
            weight = 10,
            text = "Oily",
        },
        {
            weight = 10,
            text = "Ornamental",
        },
        {
            weight = 10,
            text = "Painted",
        },
        {
            weight = 10,
            text = "Parsimonious",
        },
        {
            weight = 10,
            text = "Powerful",
        },
        {
            weight = 10,
            text = "Puckish",
        },
        {
            weight = 10,
            text = "Quiescent",
        },
        {
            weight = 10,
            text = "Quick",
        },
        {
            weight = 10,
            text = "Reasonable",
        },
        {
            weight = 10,
            text = "Resonant",
        },
        {
            weight = 10,
            text = "Rotten",
        },
        {
            weight = 10,
            text = "Sandy",
        },
        {
            weight = 10,
            text = "Scuffed",
        },
        {
            weight = 10,
            text = "Sharp",
        },
        {
            weight = 10,
            text = "Shrieking",
        },
        {
            weight = 5,
            text = "Silly",
        },
        {
            weight = 10,
            text = "Slimy",
        },
        {
            weight = 10,
            text = "Solemn",
        },
        {
            weight = 10,
            text = "Soft",
        },
        {
            weight = 10,
            text = "Squeaky",
        },
        {
            weight = 10,
            text = "Stained",
        },
        {
            weight = 10,
            text = "Sufficient",
        },
        {
            weight = 10,
            text = "Tentacled",
        },
        {
            weight = 10,
            text = "Terrible",
        },
        {
            weight = 10,
            text = "Toothy",
        },
        {
            weight = 10,
            text = "Tortured",
        },
        {
            weight = 10,
            text = "Transparent",
        },
        {
            weight = 10,
            text = "Ubiquitous",
        },
        {
            weight = 10,
            text = "Unbearable",
        },
        {
            weight = 10,
            text = "Verdant",
        },
        {
            weight = 10,
            text = "Viny",
        },
        {
            weight = 10,
            text = "Voracious",
        },
        {
            weight = 10,
            text = "Weak",
        },
        {
            weight = 10,
            text = "Wicked",
        },
        {
            weight = 10,
            text = "Wonderful",
        },
        {
            weight = 10,
            text = "Zealous",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
