-- mut tendrils (MUT_TENDRILS) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TENDRILS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "tendrils",
    description =
        "When struck in melee, the slimy tendrils covering your body may grab your\nattacker's" ..
        " weapon and yank it from their grasp, disarming them.",
    -- These mut tendrils descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are covered in slimy tendrils that may disarm your opponents.",
        "",
        "",
    },
    gain = {
        "Thin, slimy tendrils emerge from your body.",
        "",
        "",
    },
    lose = {
        "Your tendrils retract into your body.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
