-- mut mana regeneration (MUT_MANA_REGENERATION) has up to 1 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MANA_REGENERATION",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "magic regeneration",
    description = "Your magical reserves regenerate quickly.",
    -- These mut mana regeneration descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You regenerate magic rapidly.",
        "",
        "",
    },
    gain = {
        "Your magic begins to regenerate rapidly.",
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
