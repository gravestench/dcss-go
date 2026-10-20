-- shadow dragon (MONS_SHADOW_DRAGON) is a DCSS monster profile with 17 hit
-- dice and speed 10.
-- Its first melee contact is AT_BITE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_SHADOW_DRAGON when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_SHADOW_DRAGON",
    status = "defined",
    name = "shadow dragon",
    glyph = 68,
    colour_id = "MAGENTA",
    flags = {
        "M_SEE_INVIS",
        "M_COLD_BLOOD",
        "M_FLIES",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = 1,
        },
        {
            id = "MR_RES_COLD",
            level = 2,
        },
        {
            id = "MR_RES_NEG",
            level = 3,
        },
    },
    xp_modifier = 12,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_SHADOW_DRAGON",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 120,
    -- shadow dragon offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_DRAIN",
            damage = 20,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_PLAIN",
            damage = 15,
        },
        {
            type_id = "AT_NONE",
            flavour_id = "AF_PLAIN",
            damage = 0,
        },
    },
    hd = 17,
    average_hp_10x = 1275,
    ac = 15,
    ev = 10,
    spellbook_id = spellbooks.MST_SHADOW_DRAGON,
    leaves_corpse = true,
    shout_id = "S_SILENT",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 10,
    -- For shadow dragon, energy costs combine with speed 10 to determine action
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
    size_id = "SIZE_GIANT",
    shape_id = "MON_SHAPE_QUADRUPED_WINGED",
    tile = {
        id = "TILEP_MONS_SHADOW_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_SHADOW_DRAGON",
}

register.definition(categories.MONSTERS, definition)

return definition
