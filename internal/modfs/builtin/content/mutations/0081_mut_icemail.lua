-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1107
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ICEMAIL",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "icemail",
    description =
        "You are coated in a protective layer of ice. Fiery attacks can temporarily melt\nthe" ..
        " ice, removing the protection until the ice reforms. Each level of this\nmutation" ..
        " increases the protection imparted.",
    have = {
        "A meltable icy envelope protects you from harm. (AC +",
        "A thick, meltable icy envelope protects you from harm. (AC +",
        "",
    },
    gain = {
        "An icy envelope takes form around you.",
        "Your icy envelope grows thicker.",
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
