-- _suspicion_no_conflict_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_suspicion_no_conflict_name_",
    entries = {
        {
            weight = 10,
            text = "Doubts",
        },
        {
            weight = 10,
            text = "Incredulity",
        },
        {
            weight = 10,
            text = "Jealousy",
        },
        {
            weight = 10,
            text = "Mistrust",
        },
        {
            weight = 10,
            text = "Paranoia",
        },
        {
            weight = 10,
            text = "Scepticism",
        },
        {
            weight = 10,
            text = "Secrets",
        },
        {
            weight = 10,
            text = "Suspected Treachery",
        },
        {
            weight = 10,
            text = "Suspicion",
        },
        {
            weight = 10,
            text = "Trepidation",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
