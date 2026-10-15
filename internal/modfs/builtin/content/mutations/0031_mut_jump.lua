-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:416

local categories = require("constants.catalog")

local definition = {
    id = "MUT_JUMP",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "jump",
    have = {
        "You can jump attack at a short distance.",
        "You can jump attack at a medium distance.",
        "You can jump attack at a long distance.",
    },
    gain = {
        "You feel more sure on your feet.",
        "You feel more sure on your feet.",
        "You feel more sure on your feet.",
    },
    lose = {
        "You feel less sure on your feet.",
        "You feel less sure on your feet.",
        "You feel less sure on your feet.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
