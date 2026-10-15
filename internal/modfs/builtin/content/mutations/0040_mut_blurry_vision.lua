-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:542

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BLURRY_VISION",
    status = "removed",
    weight = 0,
    max_level = 3,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "blurry vision",
    have = {
        "Scrolls take you a little longer to read.",
        "Scrolls take you longer to read.",
        "Scrolls take you much longer to read.",
    },
    gain = {
        "Your vision blurs.",
        "Your vision blurs.",
        "Your vision blurs.",
    },
    lose = {
        "Your vision sharpens.",
        "Your vision sharpens a little.",
        "Your vision sharpens a little.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
