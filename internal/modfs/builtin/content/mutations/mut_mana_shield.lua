-- mut mana shield (MUT_MANA_SHIELD) has up to 1 levels and selection weight
-- 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MANA_SHIELD",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {
        "good",
    },
    form_based = false,
    short_description = "magic shield",
    description =
        "When you are harmed, some damage is redirected to deplete your magic reserves\ninstead.",
    -- These mut mana shield descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "When hurt, damage is shared between your health and your magic reserves.",
        "",
        "",
    },
    gain = {
        "You feel your magical essence form a protective shroud around your flesh.",
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
