-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:944
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ROLL",
    status = "active",
    weight = 8,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "roll",
    description =
        "You can roll at nearby foes to attack with <input>$cmd[CMD_USE_ABILITY]</input>.\nEach" ..
        " level of this mutation increases the distance you can roll, though not the\ndamage" ..
        " dealt.",
    have = {
        "You can roll at nearby foes to attack.",
        "You can roll at foes to attack.",
        "You can roll a great distance at foes to attack.",
    },
    gain = {
        "",
        "You feel you can roll further.",
        "You feel you can roll even further.",
    },
    lose = {
        "",
        "You can no longer roll as far.",
        "You can no longer roll as far.",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
