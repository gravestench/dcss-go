-- mut devolution (MUT_DEVOLUTION) has up to 2 levels and selection weight 4.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEVOLUTION",
    status = "active",
    weight = 4,
    max_level = 2,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "devolution",
    description =
        "As you gain experience, your body's hidden potential will express itself in the\nform" ..
        " of new detrimental mutations.",
    -- These mut devolution descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You have hidden genetic defects.",
        "You have terrible hidden genetic defects.",
        "",
    },
    gain = {
        "You feel a hidden malignance growing inside you.",
        "The malignance inside you grows.",
        "",
    },
    lose = {
        "You no longer feel a malignance within.",
        "Your genetic malignance weakens.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
