-- mut noise dampening (MUT_NOISE_DAMPENING) has up to 1 levels and selection
-- weight 2.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NOISE_DAMPENING",
    status = "active",
    weight = 2,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "noise suppression",
    description =
        "You passively dampen all noise in your surroundings, making it easier to avoid" ..
        "\ndrawing attention to your activities.",
    -- These mut noise dampening descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You passively dampen the noise of your surroundings.",
        "",
        "",
    },
    gain = {
        "You feel your surroundings grow quieter.",
        "",
        "",
    },
    lose = {
        "You feel your surroundings grow louder.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
