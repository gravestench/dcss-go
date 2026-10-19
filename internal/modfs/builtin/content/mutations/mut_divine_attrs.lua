-- mut divine attrs (MUT_DIVINE_ATTRS) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DIVINE_ATTRS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "divine attributes",
    description =
        "Your divine heritage dramatically boosts your attribute gain (Strength,\nIntelligence," ..
        " and Dexterity) as you level up relative to other species, both\nin quantity and in" ..
        " how much you can control your development. Every three\nlevels, you choose an" ..
        " attribute to increase by four points.",
    -- These mut divine attrs descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your divine heritage dramatically boosts your attributes as you level up.",
        "",
        "",
    },
    gain = {
        "You feel more divine.",
        "",
        "",
    },
    lose = {
        "You feel more mortal.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
