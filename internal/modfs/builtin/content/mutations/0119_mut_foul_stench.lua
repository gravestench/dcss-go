-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1651
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_FOUL_STENCH",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "foul stench",
    description =
        "Foes who strike you in melee sometimes cause you to emit a cloud of foul\nmiasma," ..
        " slowing and severely poisoning those caught within. This mutation also\ngrants you" ..
        " immunity to miasma (from any source).",
    have = {
        "You may rarely emit foul miasma when damaged in melee.",
        "You sometimes emit foul miasma when damaged in melee.",
        "You frequently emit foul miasma when damaged in melee.",
    },
    gain = {
        "You begin to emit a foul stench of rot and decay.",
        "Your foul stench grows more powerful.",
        "You begin to radiate miasma.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
