-- Gastronok (MONS_GASTRONOK) is a DCSS monster profile with 20 hit dice and
-- speed 5.
-- Its first melee contact is AT_BITE for 40 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_GASTRONOK when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GASTRONOK",
    status = "defined",
    name = "Gastronok",
    glyph = 119,
    colour_id = "MAGENTA",
    flags = {
        "M_UNIQUE",
        "M_SEE_INVIS",
        "M_SPEAKS",
        "M_NO_WAND",
        "M_MALE",
    },
    xp_modifier = 16,
    genus_id = "MONS_ELEPHANT_SLUG",
    species_id = "MONS_ELEPHANT_SLUG",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 80,
    -- Gastronok offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 40,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 20,
    average_hp_10x = 1500,
    ac = 2,
    ev = 1,
    spellbook_id = "MST_GASTRONOK",
    leaves_corpse = true,
    shout_id = "S_GURGLE",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 5,
    -- For Gastronok, energy costs combine with speed 5 to determine action
    -- cadence, not an unconditional action each turn.
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
        pickup_percent = 100,
    },
    item_use_id = "MONUSE_STARTING_EQUIPMENT",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_SNAIL",
    tile = {
        id = "TILEP_MONS_GASTRONOK",
        variation_id = "TVARY_MOD",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
