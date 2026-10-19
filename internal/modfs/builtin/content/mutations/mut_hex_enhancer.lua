-- mut hex enhancer (MUT_HEX_ENHANCER) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HEX_ENHANCER",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "bedeviling",
    description = "You cast Hex spells with increased power.",
    -- These mut hex enhancer descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your hexes are more powerful.",
        "",
        "",
    },
    gain = {
        "You feel devilish.",
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
