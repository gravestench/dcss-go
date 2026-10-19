-- shambling mangrove (MONS_SHAMBLING_MANGROVE) is a DCSS monster profile with
-- 13 hit dice and speed 8.
-- Its first melee contact is AT_HIT for 41 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SHAMBLING_MANGROVE when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_SHAMBLING_MANGROVE",
    status = "defined",
    name = "shambling mangrove",
    glyph = 102,
    colour_id = "LIGHTRED",
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 15,
    genus_id = "MONS_SHAMBLING_MANGROVE",
    species_id = "MONS_SHAMBLING_MANGROVE",
    holiness = {
        "MH_PLANT",
    },
    willpower = 100,
    -- shambling mangrove offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 41,
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
    hd = 13,
    average_hp_10x = 910,
    ac = 13,
    ev = 3,
    spellbook_id = "MST_SHAMBLING_MANGROVE",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_AMPHIBIOUS",
    speed = 8,
    -- For shambling mangrove, energy costs combine with speed 8 to determine
    -- action cadence, not an unconditional action each turn.
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_PLANT",
    tile = {
        id = "TILEP_MONS_TREANT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
