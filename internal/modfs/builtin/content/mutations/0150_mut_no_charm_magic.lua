-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1944

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NO_CHARM_MAGIC",
    status = "removed",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "no charms magic",
    have = {
        "You cannot study or cast removed Charms magic.",
        "",
        "",
    },
    gain = {
        "You can no longer study or cast Charms magic.",
        "",
        "",
    },
    lose = {
        "You can once more study and cast Charms magic.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
