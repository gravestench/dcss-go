-- mut nimble swimmer (MUT_NIMBLE_SWIMMER) has up to 2 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NIMBLE_SWIMMER",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "nimble swimmer",
    description =
        "You can blend into the waves while swimming through water or flying above it,\ngaining" ..
        " Stealth+. The second level of this mutation also grants you improved\nevasion and" ..
        " increases your movement speed when in or above water.",
    -- These mut nimble swimmer descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are camouflaged when in or above water. (Stealth+)",
        "You are very nimble when in or above water. (Stealth+, EV+, Speed+++)",
        "",
    },
    gain = {
        "You feel comfortable near water.",
        "You feel very comfortable near water.",
        "",
    },
    lose = {
        "You feel less comfortable near water.",
        "You feel less comfortable near water.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
