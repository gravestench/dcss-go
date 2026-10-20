-- shadow (MONS_SHADOW) is a DCSS monster profile with 6 hit dice and speed
-- 10.
-- Its first melee contact is AT_HIT for 14 base damage; combat policy applies
-- defenses and status effects.
-- The AI consults MST_SHADOW when choosing a legal spell, then spends this
-- actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SHADOW",
    status = "defined",
    name = "shadow",
    glyph = 87,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_INSUBSTANTIAL",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_COLD",
            level = 3,
        },
    },
    xp_modifier = 18,
    genus_id = "MONS_WRAITH",
    species_id = "MONS_SHADOW",
    holiness = {
        "MH_UNDEAD",
    },
    willpower = 40,
    -- shadow offers AT_HIT as its first contact; later slots are tried by the
    -- shared melee flow.
    attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_SHADOWSTAB",
            damage = 14,
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
    hd = 6,
    average_hp_10x = 240,
    ac = 7,
    ev = 10,
    spellbook_id = spellbooks.MST_SHADOW,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For shadow, energy costs combine with speed 10 to determine action cadence,
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
    item_use_id = "MONUSE_OPEN_DOORS",
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_HUMANOID",
    tile = {
        id = "TILEP_MONS_SHADOW",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_ERROR",
}

register.definition(categories.MONSTERS, definition)

return definition
