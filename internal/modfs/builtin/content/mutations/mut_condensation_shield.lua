-- mut condensation shield (MUT_CONDENSATION_SHIELD) has up to 1 levels and
-- selection weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_CONDENSATION_SHIELD",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "condensation shield",
    description =
        "A shield of frost guards you, blocking some incoming attacks. Fiery attacks can" ..
        "\ntemporarily melt the shield.",
    -- These mut condensation shield descriptions are indexed by the player's
    -- effective mutation level.
    have = {
        "A meltable shield of frost defends you. (SH +",
        "",
        "",
    },
    gain = {
        "Frost condenses into a shield before you.",
        "",
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
