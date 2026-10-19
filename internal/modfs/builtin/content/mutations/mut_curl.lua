-- mut curl (MUT_CURL) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CURL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "reflexive curl",
    description =
        "You curl up when struck, giving you protection against further attacks until\nyour" ..
        " next action. This effect is guaranteed to happen in response to any\ndirect damage.",
    -- These mut curl descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You curl defensively after being hit. (AC +7*)",
        "",
        "",
    },
    gain = {
        "You now curl defensively after being hit.",
        "",
        "",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
