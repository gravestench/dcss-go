-- mut clever (MUT_CLEVER) has up to 2 levels and selection weight 7.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CLEVER",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "clever",
    description =
        "Your mind has become unnaturally acute. Each level of this mutation provides +4" ..
        "\nIntelligence, but all the blood flowing to your head weakens your constitution," ..
        "\ngiving -1 to both your Strength and Dexterity for each level.",
    -- These mut clever descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "Your mind is acute. (Int +4, Str/Dex -1)",
        "Your mind is very acute. (Int +8, Str/Dex -2)",
        "",
    },
    gain = {
        "",
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
