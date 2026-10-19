-- guardian serpent (MONS_GUARDIAN_SERPENT) is a DCSS monster profile with 8
-- hit dice and speed 15.
-- Its first melee contact is AT_HIT for 26 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_GUARDIAN_SERPENT when choosing a legal spell, then
-- spends this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_GUARDIAN_SERPENT",
    status = "defined",
    name = "guardian serpent",
    glyph = 83,
    colour_id = "WHITE",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
    },
    xp_modifier = 10,
    genus_id = "MONS_GUARDIAN_SERPENT",
    species_id = "MONS_GUARDIAN_SERPENT",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 60,
    -- guardian serpent offers AT_HIT as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = 26,
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
    hd = 8,
    average_hp_10x = 440,
    ac = 6,
    ev = 14,
    spellbook_id = "MST_GUARDIAN_SERPENT",
    leaves_corpse = true,
    shout_id = "S_SHOUT",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For guardian serpent, energy costs combine with speed 15 to determine action
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
    item_use_id = "MONUSE_NOTHING",
    size_id = "SIZE_LARGE",
    shape_id = "MON_SHAPE_SNAKE",
    tile = {
        id = "TILEP_MONS_GUARDIAN_SERPENT",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_GUARDIAN_SERPENT",
}

register.definition(categories.MONSTERS, definition)

return definition
