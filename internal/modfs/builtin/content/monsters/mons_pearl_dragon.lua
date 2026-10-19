-- pearl dragon (MONS_PEARL_DRAGON) is a DCSS monster profile with 18 hit dice
-- and speed 12.
-- Its first melee contact is AT_BITE for 35 base damage; combat policy
-- applies defenses and status effects.
-- The AI consults MST_PEARL_DRAGON when choosing a legal spell, then spends
-- this actor's saved energy.

-- Source: crawl-ref/source/mon-data.h

local categories = require("constants.catalog")
local spellbooks = require("ids.monster_spellbooks")

local definition = {
    id = "MONS_PEARL_DRAGON",
    status = "defined",
    name = "pearl dragon",
    glyph = 68,
    colour_id = "ETC_HOLY",
    flags = {
        "M_SEE_INVIS",
        "M_WARM_BLOOD",
        "M_FLIES",
    },
    xp_modifier = 16,
    genus_id = "MONS_DRAGON",
    species_id = "MONS_PEARL_DRAGON",
    holiness = {
        "MH_HOLY",
    },
    willpower = 160,
    -- pearl dragon offers AT_BITE as its first contact; later slots are tried by
    -- the shared melee flow.
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_HOLY",
            damage = 35,
        },
        {
            type_id = "AT_CLAW",
            flavour_id = "AF_HOLY",
            damage = 20,
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
    hd = 18,
    average_hp_10x = 1170,
    ac = 10,
    ev = 15,
    spellbook_id = spellbooks.MST_PEARL_DRAGON,
    leaves_corpse = true,
    shout_id = "S_LOUD_ROAR",
    intelligence_id = "I_ANIMAL",
    habitat_id = "HT_LAND",
    speed = 12,
    -- For pearl dragon, energy costs combine with speed 12 to determine action
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
        id = "TILEP_MONS_PEARL_DRAGON",
        variation_id = "TVARY_NONE",
    },
    corpse_tile_id = "TILE_CORPSE_PEARL_DRAGON",
}

register.definition(categories.MONSTERS, definition)

return definition
