-- mut agile (MUT_AGILE) has up to 2 levels and selection weight 7.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_AGILE",
    status = "active",
    weight = 7,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "agile",
    description =
        "Your reflexes have become unnaturally fast. Each level of this mutation\nprovides +4" ..
        " Dexterity, but the rest of your body can't keep up with your speed,\ngiving -1 to" ..
        " both your Strength and Intelligence for each level.",
    -- These mut agile descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You are agile. (Dex +4, Str/Int -1)",
        "You are very agile. (Dex +8, Str/Int -2)",
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
