-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:707
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TENGU_FLIGHT",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "nimble flight",
    description =
        "You fly quickly through the air, covering ground more quickly than you would on\nfoot." ..
        " Your evasion is also multiplied by this effect.",
    have = {
        "Your magical nature lets you fly swiftly and evasively.",
        "",
        "",
    },
    gain = {
        "Your magical nature develops, letting you fly swiftly and evasively.",
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
