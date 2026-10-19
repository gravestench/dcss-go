-- mut silence aura (MUT_SILENCE_AURA) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_SILENCE_AURA",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "aura of silence",
    description =
        "You are surrounded by an aura of silence. Those adjacent to you cannot make any" ..
        "\nsound. This prevents most forms of spellcasting and prayer, though demonic\nmagic," ..
        " being noiseless, is unaffected.",
    -- These mut silence aura descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are surrounded by an aura of silence.",
        "",
        "",
    },
    gain = {
        "An unnatural silence shrouds you.",
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
