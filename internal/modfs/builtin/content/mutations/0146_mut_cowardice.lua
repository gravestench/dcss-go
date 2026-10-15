-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1911
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_COWARDICE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "cowardly",
    description =
        "Seeing threatening monsters fills you with dread, reducing the power of your\nspells" ..
        " and your ability to slay monsters with melee and ranged attacks. Seeing\nmultiple" ..
        " such monsters at once, or extremely threatening monsters, renders this\neven worse.",
    have = {
        "Your cowardice makes you less effective in combat with threatening foes.",
        "",
        "",
    },
    gain = {
        "You have lost your courage.",
        "",
        "",
    },
    lose = {
        "You have regained your courage.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
