-- mut gelatinous body (MUT_GELATINOUS_BODY) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_GELATINOUS_BODY",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "gelatinous body",
    description =
        "Your body is rubbery, and your foes like glue. Each level of this mutation\nconfers +1" ..
        " AC and +1 EV.",
    -- These mut gelatinous body descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your rubbery body absorbs attacks. (AC +1, EV +1)",
        "Your pliable body absorbs attacks. (AC +2, EV +2)",
        "Your gelatinous body deflects attacks. (AC +3, EV +3)",
    },
    gain = {
        "Your body becomes stretchy.",
        "Your body becomes more malleable.",
        "Your body becomes viscous.",
    },
    lose = {
        "Your body returns to its normal consistency.",
        "Your body becomes less malleable.",
        "Your body becomes less viscous.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
