-- mut devour on kill (MUT_DEVOUR_ON_KILL) has up to 1 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEVOUR_ON_KILL",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "devour on kill",
    description =
        "When you kill living creatures you have a chance to devour their life force\nand" ..
        " restore hit points.",
    -- These mut devour on kill descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You thrive by killing the living.",
        "",
        "",
    },
    gain = {
        "You feel hungry for flesh.",
        "",
        "",
    },
    lose = {
        "You feel less hungry for flesh.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
