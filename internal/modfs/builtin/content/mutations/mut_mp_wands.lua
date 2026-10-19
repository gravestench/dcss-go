-- mut mp wands (MUT_MP_WANDS) has up to 1 levels and selection weight 7.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut mp wands descriptions are indexed by the player's effective
    -- mutation level.
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
