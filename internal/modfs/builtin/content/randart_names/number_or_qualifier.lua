-- _number_or_qualifier_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_number_or_qualifier_",
    entries = {
        {
            weight = 10,
            text = "the Three",
        },
        {
            weight = 10,
            text = "the Four",
        },
        {
            weight = 10,
            text = "the Five",
        },
        {
            weight = 10,
            text = "the Six",
        },
        {
            weight = 10,
            text = "the Seven",
        },
        {
            weight = 10,
            text = "the Eight",
        },
        {
            weight = 10,
            text = "the Nine",
        },
        {
            weight = 10,
            text = "the Ten",
        },
        {
            weight = 10,
            text = "the Eleven",
        },
        {
            weight = 5,
            text = "the Twelve",
        },
        {
            weight = 5,
            text = "the Dozen",
        },
        {
            weight = 10,
            text = "the Thirteen",
        },
        {
            weight = 5,
            text = "the Twenty",
        },
        {
            weight = 10,
            text = "the Fifty",
        },
        {
            weight = 5,
            text = "the Sixty-Six",
        },
        {
            weight = 5,
            text = "the Seventy-Seven",
        },
        {
            weight = 5,
            text = "the Ninety-Nine",
        },
        {
            weight = 5,
            text = "a Hundred",
        },
        {
            weight = 5,
            text = "the Hundredfold",
        },
        {
            weight = 10,
            text = "a Thousand",
        },
        {
            weight = 10,
            text = "a Million",
        },
        {
            weight = 10,
            text = "a Billion",
        },
        {
            weight = 10,
            text = "the",
        },
        {
            weight = 10,
            text = "the Assorted",
        },
        {
            weight = 10,
            text = "the Countless",
        },
        {
            weight = 10,
            text = "the Manifold",
        },
        {
            weight = 10,
            text = "the Many",
        },
        {
            weight = 10,
            text = "the Several",
        },
        {
            weight = 10,
            text = "the Aged",
        },
        {
            weight = 10,
            text = "the Ageless",
        },
        {
            weight = 10,
            text = "the Ancient",
        },
        {
            weight = 10,
            text = "the Battered",
        },
        {
            weight = 10,
            text = "the Bouncing",
        },
        {
            weight = 10,
            text = "the Bruised",
        },
        {
            weight = 10,
            text = "the Crushed",
        },
        {
            weight = 10,
            text = "the Curious",
        },
        {
            weight = 10,
            text = "the Disturbing",
        },
        {
            weight = 10,
            text = "the Endless",
        },
        {
            weight = 10,
            text = "the Exiled",
        },
        {
            weight = 10,
            text = "the Final",
        },
        {
            weight = 10,
            text = "the First",
        },
        {
            weight = 10,
            text = "the Foremost",
        },
        {
            weight = 10,
            text = "the Forgotten",
        },
        {
            weight = 10,
            text = "the Forsaken",
        },
        {
            weight = 10,
            text = "the Hidden",
        },
        {
            weight = 10,
            text = "the Illusory",
        },
        {
            weight = 10,
            text = "the Immovable",
        },
        {
            weight = 10,
            text = "the Inquisitive",
        },
        {
            weight = 10,
            text = "the Insatiable",
        },
        {
            weight = 10,
            text = "the Invisible",
        },
        {
            weight = 10,
            text = "the Jolly",
        },
        {
            weight = 10,
            text = "the Last",
        },
        {
            weight = 10,
            text = "the Lonely",
        },
        {
            weight = 10,
            text = "the Lost",
        },
        {
            weight = 10,
            text = "the Lumpy",
        },
        {
            weight = 10,
            text = "the Modern",
        },
        {
            weight = 10,
            text = "the Neverending",
        },
        {
            weight = 10,
            text = "the Peculiar",
        },
        {
            weight = 10,
            text = "the Postmodern",
        },
        {
            weight = 10,
            text = "the Pure",
        },
        {
            weight = 10,
            text = "the Secret",
        },
        {
            weight = 10,
            text = "the Sneaky",
        },
        {
            weight = 10,
            text = "the Special",
        },
        {
            weight = 10,
            text = "the Thirsty",
        },
        {
            weight = 10,
            text = "the Thoughtful",
        },
        {
            weight = 10,
            text = "the Tired",
        },
        {
            weight = 10,
            text = "the Unstoppable",
        },
        {
            weight = 10,
            text = "the Vanishing",
        },
        {
            weight = 10,
            text = "the Wary",
        },
        {
            weight = 10,
            text = "the Well-Known",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
