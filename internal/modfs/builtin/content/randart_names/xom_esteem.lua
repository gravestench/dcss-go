-- _xom_esteem_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_xom_esteem_",
    entries = {
        {
            weight = 40,
            text = "@divine_esteem@\nAbsentmindedness",
        },
        {
            weight = 10,
            text = "Amusement",
        },
        {
            weight = 10,
            text = "Attic",
        },
        {
            weight = 10,
            text = "Bemusement",
        },
        {
            weight = 10,
            text = "Best Wishes",
        },
        {
            weight = 10,
            text = "Capriciousness",
        },
        {
            weight = 10,
            text = "Entertainment",
        },
        {
            weight = 10,
            text = "Fair Game",
        },
        {
            weight = 10,
            text = "Flight of Fancy",
        },
        {
            weight = 10,
            text = "Full Attention",
        },
        {
            weight = 10,
            text = "Malicious Joy",
        },
        {
            weight = 10,
            text = "Passing Interest",
        },
        {
            weight = 10,
            text = "Recklessness",
        },
        {
            weight = 10,
            text = "Ringing Laughter",
        },
        {
            weight = 10,
            text = "Sleight of Hands",
        },
        {
            weight = 10,
            text = "Wantonness",
        },
        {
            weight = 10,
            text = "Whimsicality",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
