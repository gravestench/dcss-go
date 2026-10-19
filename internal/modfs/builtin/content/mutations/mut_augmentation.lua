-- mut augmentation (MUT_AUGMENTATION) has up to 3 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_AUGMENTATION",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "augmentation",
    description =
        "While in good health, you are more powerful, casting spells and slaying foes\nmore" ..
        " effectively. Each level of this mutation increases this effect further.",
    -- These mut augmentation descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your magical and physical power is slightly enhanced at high health.",
        "Your magical and physical power is enhanced at high health.",
        "Your magical and physical power is greatly enhanced at high health.",
    },
    gain = {
        "You feel power flowing into your body.",
        "You feel power rushing into your body.",
        "You feel saturated with power.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
