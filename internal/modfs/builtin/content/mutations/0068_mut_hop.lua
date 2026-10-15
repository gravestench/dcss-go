-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:931
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_HOP",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "strong legs",
    description =
        "You have big, strong legs, allowing you to hop about with" ..
        "\n<input>$cmd[CMD_USE_ABILITY]</input>, though you can't perfectly aim where you" ..
        "\nland. The second level of this mutation allows you to hop farther. Each time\nyou" ..
        " hop, you need to rest for a bit before you can hop again.",
    have = {
        "You can hop short distances.",
        "You can hop long distances.",
        "",
    },
    gain = {
        "",
        "Your legs feel stronger.",
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
