-- Generated from a pinned DCSS mutation table. Refresh deliberately.
-- Revision: e60ba3568b0c26447ad36ec5c7b963eb04b2778f
-- Source: crawl-ref/source/mutation-data.h:1803
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
