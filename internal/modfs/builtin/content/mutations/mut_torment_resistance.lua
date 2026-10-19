-- mut torment resistance (MUT_TORMENT_RESISTANCE) has up to 2 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TORMENT_RESISTANCE",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "torment resistance",
    description =
        "You are less affected by unholy torment, which would otherwise cut your health\nin" ..
        " half. The second level of this mutation renders you entirely immune.",
    -- These mut torment resistance descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You are resistant to unholy torment.",
        "You are immune to unholy pain and torment.",
        "",
    },
    gain = {
        "You feel a strange anaesthesia.",
        "You feel a very strange anaesthesia.",
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
