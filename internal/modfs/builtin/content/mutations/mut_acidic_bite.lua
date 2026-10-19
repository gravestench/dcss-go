-- mut acidic bite (MUT_ACIDIC_BITE) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ACIDIC_BITE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "acidic bite",
    description =
        "You have acidic saliva, allowing you to bite foes and apply corrosion to them\nwhen" ..
        " launching melee attacks.",
    -- These mut acidic bite descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have acidic saliva.",
        "",
        "",
    },
    gain = {
        "Acid begins to drip from your mouth.",
        "",
        "",
    },
    lose = {
        "Your mouth feels dry.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
