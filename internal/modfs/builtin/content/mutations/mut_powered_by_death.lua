-- mut powered by death (MUT_POWERED_BY_DEATH) has up to 3 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_POWERED_BY_DEATH",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "powered by death",
    description =
        "Death fuels you, allowing you to heal somewhat for each life you take. Each\nlevel of" ..
        " this mutation increases the healing further.",
    -- These mut powered by death descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "You regenerate a little health from kills.",
        "You regenerate health from kills.",
        "You regenerate a lot of health from kills.",
    },
    gain = {
        "A wave of death washes over you.",
        "The wave of death grows in power.",
        "The wave of death grows in power.",
    },
    lose = {
        "Your control of surrounding life forces is gone.",
        "Your control of surrounding life forces weakens.",
        "Your control of surrounding life forces weakens.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
