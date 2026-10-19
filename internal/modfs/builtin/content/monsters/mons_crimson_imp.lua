-- crimson imp (MONS_CRIMSON_IMP) is a DCSS monster profile with 3 hit dice
-- and speed 10.
-- Its first melee contact is AT_HIT for 4 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_BLINKER when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_CRIMSON_IMP",
    status = "defined",
    name = "crimson imp",
    glyph = 53,
    colour_id = "RED",
    flags = {
        "M_SPEAKS",
        "M_FAST_REGEN",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 3,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 13,
    genus_id = "MONS_CRIMSON_IMP",
    species_id = "MONS_CRIMSON_IMP",
    holiness = {
        "MH_DEMONIC",
    },
    willpower = 40,
    -- crimson imp offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 4,
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
    hd = 3,
    average_hp_10x = 135,
    ac = 3,
    ev = 14,
    spellbook_id = "MST_BLINKER",
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For crimson imp, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_LITTLE",
    shape_id = "MON_SHAPE_HUMANOID_WINGED",
    tile = {
        id = "TILEP_MONS_CRIMSON_IMP",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
