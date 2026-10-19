-- _jewellery_special_name_ is a weighted DCSS random-name group.
-- Source: crawl-ref/source/dat/database/rand_all.txt
-- Phrase order and weights determine cosmetic selection for one item.
-- A mod can replace this file to change just this group.

local categories = require("constants.catalog")

local definition = {
    id = "_jewellery_special_name_",
    entries = {
        {
            weight = 10,
            text = "Attitude",
        },
        {
            weight = 10,
            text = "Disaster",
        },
        {
            weight = 10,
            text = "Ephemeral Luck",
        },
        {
            weight = 10,
            text = "False Pretenses",
        },
        {
            weight = 10,
            text = "Finality",
        },
        {
            weight = 10,
            text = "Lady Luck",
        },
        {
            weight = 10,
            text = "Moodiness",
        },
        {
            weight = 10,
            text = "Reimbursement",
        },
        {
            weight = 10,
            text = "the Tempest",
        },
        {
            weight = 10,
            text = "Temptation",
        },
        {
            weight = 10,
            text = "Wishful Thinking",
        },
        {
            weight = 10,
            text = "Yendor",
        },
    },
}

register.definition(categories.RANDART_NAMES, definition)

return definition
