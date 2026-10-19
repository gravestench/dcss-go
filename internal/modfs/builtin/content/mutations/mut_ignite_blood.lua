-- mut ignite blood (MUT_IGNITE_BLOOD) has up to 3 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_IGNITE_BLOOD",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "ignite blood",
    description =
        "Whenever you see blood spilled (yours or others'), it may ignite, bursting into\na" ..
        " cloud of flame. Each level of this mutation makes this more likely.\n# XXX: also" ..
        " mention that this makes people more likely to bleed?",
    -- These mut ignite blood descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your demonic aura sometimes causes spilled blood to erupt in flames.",
        "Your demonic aura often causes spilled blood to erupt in flames.",
        "Your demonic aura causes all spilled blood to erupt in flames.",
    },
    gain = {
        "Your blood heats up.",
        "Your blood runs red-hot!",
        "Your blood burns even hotter!",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
