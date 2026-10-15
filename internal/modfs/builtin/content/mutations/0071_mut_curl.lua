-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:968
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CURL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "reflexive curl",
    description =
        "You curl up when struck, giving you protection against further attacks until\nyour" ..
        " next action. This effect is guaranteed to happen in response to any\ndirect damage.",
    have = {
        "You curl defensively after being hit. (AC +7*)",
        "",
        "",
    },
    gain = {
        "You now curl defensively after being hit.",
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
