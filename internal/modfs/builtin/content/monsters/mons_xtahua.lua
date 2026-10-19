-- Xtahua (MONS_XTAHUA) is a DCSS monster profile with 20 hit dice and speed
-- 10.
-- Its first melee contact is AT_BITE for 35 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_XTAHUA when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")

local definition = {
    id = "MONS_XTAHUA",
    status = "defined",
    name = "Xtahua",
    glyph = 68,
    colour_id = "RED",
    flags = {
        "M_UNIQUE",
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_SPEAKS",
        "M_GENDER_NEUTRAL",
        "M_CRASH_DOORS",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_FIRE",
            level = 2,
        },
        {
            id = "MR_RES_COLD",
            level = -1,
        },
    },
    xp_modifier = 18,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_FIRE_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 180,
    -- Xtahua offers AT_BITE as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 35,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 17,
        },
        {
            type_id = "AT_TRAMPLE",
            flavour_id = "AF_TRAMPLE",
            damage = 20,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 20,
    average_hp_10x = 1330,
    ac = 15,
    ev = 7,
    spellbook_id = "MST_XTAHUA",
    leaves_corpse = true,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_HUMAN",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For Xtahua, energy costs combine with speed 10 to determine action cadence,
    -- not an unconditional action each turn.
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
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_XTAHUA",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
