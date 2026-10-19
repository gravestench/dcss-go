-- mut black mark (MUT_BLACK_MARK) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BLACK_MARK",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "black mark",
    description =
        "When you strike a foe in melee, the black mark on your body may debilitate\nthem. This" ..
        " can weaken foes, drain their health, or disrupt their magic.",
    -- These mut black mark descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your melee attacks may debilitate your foes.",
        "",
        "",
    },
    gain = {
        "An ominous black mark forms on your body.",
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
