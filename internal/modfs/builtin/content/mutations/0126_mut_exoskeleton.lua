-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1715

local categories = require("constants.catalog")

local definition = {
    id = "MUT_EXOSKELETON",
    status = "removed",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "exoskeleton",
    have = {
        "Your body is surrounded by an exoskeleton. (buggy)",
        "Your body is surrounded by a tough exoskeleton. (buggy)",
        "",
    },
    gain = {
        "Your exoskeleton hardens.",
        "Your exoskeleton becomes even harder.",
        "",
    },
    lose = {
        "Your exoskeleton softens.",
        "Your exoskeleton softens.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
