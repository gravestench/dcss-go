-- mut mertail (MUT_MERTAIL) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MERTAIL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "mertail",
    description =
        "Your morphogenic matrix is unstable, allowing your lower body to shift to\na powerful" ..
        " aquatic tail when in shallow or deep water. It will quickly\nreform into legs once" ..
        " you leave the water. When in merform, your tail allows\nyou to tail-slap foes when" ..
        " launching melee attacks.",
    -- These mut mertail descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your lower body shifts to a powerful aquatic tail in water.",
        "",
        "",
    },
    gain = {
        "Your legs feel aquatic.",
        "",
        "",
    },
    lose = {
        "Your legs no longer feel aquatic.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
