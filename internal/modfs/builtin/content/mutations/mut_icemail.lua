-- mut icemail (MUT_ICEMAIL) has up to 2 levels and selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_ICEMAIL",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "icemail",
    description =
        "You are coated in a protective layer of ice. Fiery attacks can temporarily melt\nthe" ..
        " ice, removing the protection until the ice reforms. Each level of this\nmutation" ..
        " increases the protection imparted.",
    -- These mut icemail descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "A meltable icy envelope protects you from harm. (AC +",
        "A thick, meltable icy envelope protects you from harm. (AC +",
        "",
    },
    gain = {
        "An icy envelope takes form around you.",
        "Your icy envelope grows thicker.",
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
