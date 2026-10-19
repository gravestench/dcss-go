-- mut cowardice (MUT_COWARDICE) has up to 1 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
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
    -- These mut cowardice descriptions are indexed by the player's effective
    -- mutation level.
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
