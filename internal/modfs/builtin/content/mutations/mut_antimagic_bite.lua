-- mut antimagic bite (MUT_ANTIMAGIC_BITE) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ANTIMAGIC_BITE",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "antimagic bite",
    description =
        "You have a thirst for magic, allowing you to bite foes when launching melee\nattacks." ..
        " This restores your magical reserves and also disrupts magical foes,\nsometimes" ..
        " leaving them unable to act.",
    -- These mut antimagic bite descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your bite disrupts and absorbs the magic of your enemies.",
        "",
        "",
    },
    gain = {
        "You feel a sudden thirst for magic.",
        "",
        "",
    },
    lose = {
        "Your magical appetite wanes.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
