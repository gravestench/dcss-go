-- mut glowing (MUT_GLOWING) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_GLOWING",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "glowing",
    description =
        "You glow in the dark. Foes hit you more often, your stealth is badly impaired,\nand" ..
        " your outline is easily seen even while you are otherwise invisible.",
    -- These mut glowing descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You glow in the dark.",
        "",
        "",
    },
    gain = {
        "Your body begins glowing.",
        "",
        "",
    },
    lose = {
        "You feel a bit dim.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
