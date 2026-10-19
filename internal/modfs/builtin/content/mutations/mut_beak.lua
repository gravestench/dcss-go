-- mut beak (MUT_BEAK) has up to 1 levels and selection weight 1.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_BEAK",
    status = "active",
    weight = 1,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "beak",
    description =
        "You have a beak for a mouth, allowing you to peck at foes when launching melee" ..
        "\nattacks, but preventing you from wearing helmets.",
    -- These mut beak descriptions are indexed by the player's effective mutation
    -- level.
    have = {
        "You have a beak for a mouth.",
        "",
        "",
    },
    gain = {
        "Your mouth lengthens and hardens into a beak!",
        "",
        "",
    },
    lose = {
        "Your beak shortens and softens into a mouth.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
