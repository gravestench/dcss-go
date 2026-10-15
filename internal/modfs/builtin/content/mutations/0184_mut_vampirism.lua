-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2256
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_VAMPIRISM",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "vampiric",
    description =
        "You are cursed with vampirism, torn between false life and a bloodless,\ndessicated" ..
        " undeath. You can use <input>$cmd[CMD_USE_ABILITY]</input> to\nexsanguinate yourself" ..
        " or to fill once more with blood.",
    have = {
        "You are afflicted with vampirism.",
        "You are afflicted with vampirism and can become a bat while bloodless.",
        "",
    },
    gain = {
        "You feel a craving for blood.",
        "You can now turn into a vampire bat when bloodless.",
        "",
    },
    lose = {
        "Your craving for blood subsides.",
        "You can no longer turn into a bat.",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
