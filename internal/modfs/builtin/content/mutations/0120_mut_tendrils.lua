-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1666
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_TENDRILS",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
        "jiyva",
    },
    form_based = true,
    short_description = "tendrils",
    description =
        "When struck in melee, the slimy tendrils covering your body may grab your\nattacker's" ..
        " weapon and yank it from their grasp, disarming them.",
    have = {
        "You are covered in slimy tendrils that may disarm your opponents.",
        "",
        "",
    },
    gain = {
        "Thin, slimy tendrils emerge from your body.",
        "",
        "",
    },
    lose = {
        "Your tendrils retract into your body.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
