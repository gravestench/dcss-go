-- mut demonic touch (MUT_DEMONIC_TOUCH) has up to 3 levels and selection
-- weight 0.
-- Level state lives on the player; this record supplies text and selection metadata.
-- Capability effects require separate policy registration.

-- Ported mutation data; edit this committed definition directly.
-- Source: crawl-ref/source/mutation-data.h
-- Source: crawl-ref/source/dat/descript/mutations.txt

local categories = require("constants.catalog")

local definition = {
    id = "MUT_DEMONIC_TOUCH",
    status = "active",
    weight = 0,
    max_level = 3,
    uses = {
        "good",
    },
    form_based = true,
    short_description = "demonic touch",
    description =
        "Your hands glow with unholy energy, allowing you to inflict irresistible damage\nwhen" ..
        " launching melee attacks as long as your off-hand is free. Your touch\nattacks deal" ..
        " damage which ignores armour, and each level of this mutation\nincreases the damage" ..
        " dealt. The third level of this mutation prevents you from\nwearing gloves, and also" ..
        " causes your touch attacks to reduce your foes'\nwillpower.",
    -- These mut demonic touch descriptions are indexed by the player's effective
    -- mutation level.
    have = {
        "Your touch may inflict minor irresistible damage on your foes.",
        "Your touch may inflict irresistible damage on your foes.",
        "Your touch may irresistibly damage your foes and sap their willpower.",
    },
    gain = {
        "Your hands begin to faintly glow with unholy energy.",
        "Your hands glow brighter with unholy energy.",
        "Your hands twist and begin to emit a powerful aura of unholy energy.",
    },
    lose = {
        "",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
