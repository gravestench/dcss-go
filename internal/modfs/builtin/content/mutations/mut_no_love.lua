-- mut no love (MUT_NO_LOVE) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_LOVE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "hated by all",
    description =
        "You are hated by all and cannot acquire allies, temporarily or permanently, by\nany" ..
        " means. Simplistic, unthinking magical constructs, such as spectral weapons,\norbs of" ..
        " destruction, and battlespheres, are unaffected.",
    -- These mut no love descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are hated by all.",
        "",
        "",
    },
    gain = {
        "You are now hated by all.",
        "",
        "",
    },
    lose = {
        "You are no longer hated by all.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
