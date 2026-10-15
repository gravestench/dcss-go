-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:2089
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MP_WANDS",
    status = "active",
    weight = 7,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "MP-powered wands",
    description =
        "Your wands draw upon your magical reserves, becoming somewhat more powerful in\nthe" ..
        " process. If you have no magic left to draw upon, your wands function as\nnormal.",
    have = {
        "You expend magic power (3 MP) to strengthen your wands.",
        "",
        "",
    },
    gain = {
        "You feel your magical essence link to the dungeon's wands.",
        "",
        "",
    },
    lose = {
        "Your magical essence no longer links to wands of the dungeon.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
