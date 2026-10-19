-- mut daystalker (MUT_DAYSTALKER) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DAYSTALKER",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "+LOS",
    description =
        "The darkness flees at your approach, allowing an extended range of vision and\nranged" ..
        " attack (+1 line of sight), but also allowing you to be seen and\npotentially targeted" ..
        " from further away.",
    -- These mut daystalker descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have an extended range of vision and can be seen from far away.",
        "",
        "",
    },
    gain = {
        "The darkness flees at your approach.",
        "",
        "",
    },
    lose = {
        "The shadows grow bolder once more.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
