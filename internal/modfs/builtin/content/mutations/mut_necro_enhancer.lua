-- mut necro enhancer (MUT_NECRO_ENHANCER) has up to 2 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_NECRO_ENHANCER",
    status = "active",
    weight = 0,
    max_level = 2,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "in touch with death",
    description =
        "Your Necromancy spells are more powerful. The second level of this mutation\nenhances" ..
        " your Necromancy spellpower further.",
    -- These mut necro enhancer descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "You are in touch with the powers of death.",
        "You are strongly in touch with the powers of death.",
        "",
    },
    gain = {
        "You feel more in touch with the powers of death.",
        "You feel more in touch with the powers of death.",
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
