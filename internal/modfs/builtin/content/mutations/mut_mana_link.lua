-- mut mana link (MUT_MANA_LINK) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MANA_LINK",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "magic link",
    description = "When low on magic, you restore magic in place of health.",
    -- These mut mana link descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "When low on magic, you restore magic in place of health.",
        "",
        "",
    },
    gain = {
        "You feel your life force and your magical essence meld.",
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
