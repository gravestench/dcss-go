-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:489
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
