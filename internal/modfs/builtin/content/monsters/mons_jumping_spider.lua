-- jumping spider (MONS_JUMPING_SPIDER) is a DCSS monster profile with 8 hit
-- dice and speed 15.
-- Its first melee contact is AT_POUNCE for 20 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_JUMPING_SPIDER when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_JUMPING_SPIDER",
    status = "defined",
    name = "jumping spider",
    glyph = 115,
    colour_id = "LIGHTBLUE",
    flags = {
        "M_NO_SKELETON",
        "M_WEB_IMMUNE",
    },
    resistances = {
        {
            id = "MR_RES_POISON",
            level = -1,
        },
    },
    xp_modifier = 6,
    genus_id = "MONS_SPIDER",
    species_id = "MONS_JUMPING_SPIDER",
    holiness = {
        "MH_NATURAL",
    },
    willpower = 20,
    -- jumping spider offers AT_POUNCE as its first contact; later slots are tried
    -- by the shared melee flow.
    attacks = {
        {
            type_id = "AT_POUNCE",
            flavour_id = "AF_ENSNARE",
            damage = 20,
        },
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
            damage = 8,
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
    average_hp_10x = 320,
    ac = 6,
    ev = 12,
    spellbook_id = spellbooks.MST_JUMPING_SPIDER,
    leaves_corpse = true,
    shout_id = "S_FAINT_SKITTER",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 15,
    -- For jumping spider, energy costs combine with speed 15 to determine action
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
    size_id = "SIZE_SMALL",
    shape_id = "MON_SHAPE_ARACHNID",
    tile = {
        id = "TILEP_MONS_JUMPING_SPIDER",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_JUMPING_SPIDER",
}

register.definition(categories.MONSTERS, definition)

return definition
