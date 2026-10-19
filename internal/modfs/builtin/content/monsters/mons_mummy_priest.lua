-- mummy priest (MONS_MUMMY_PRIEST) is a DCSS monster profile with 10 hit dice
-- and speed 8.
-- Its first melee contact is AT_HIT for 30 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_MUMMY_PRIEST when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_MUMMY_PRIEST",
    status = "defined",
    name = "mummy priest",
    glyph = 77,
    colour_id = "RED",
    flags = {
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 1,
        },
        {
            id = "MR_RES_ELEC",
            level = 1,
        },
    },
    xp_modifier = 20,
    genus_id = "MONS_MUMMY",
    species_id = "MONS_MUMMY",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 120,
    -- mummy priest offers AT_HIT as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 30,
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
    hd = 10,
    average_hp_10x = 650,
    ac = 8,
    ev = 7,
    spellbook_id = "MST_MUMMY_PRIEST",
    shout_id = "S_SILENT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 8,
    -- For mummy priest, energy costs combine with speed 8 to determine action
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
    item_use_id = "MONUSE_WEAPONS_ARMOUR",
    size_id = "SIZE_MEDIUM",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_MUMMY_PRIEST",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
